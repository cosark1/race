-- Cuma Hutbesi Quiz — Faz 1 Supabase şeması
-- Kaynak tasarım: arastirma/quiz_plani.md §9 (mimari), §9.1 (veri modeli), §9.2 (kötüye kullanıma karşı)
--
-- Supabase SQL Editor'da tek seferde çalıştırılır (proje: Settings → Database → SQL Editor → New query).
-- Sıra önemli: extension → tablolar → view'lar → RPC fonksiyonları → RLS.

create extension if not exists pgcrypto;

-- =========================================================
-- 1. TABLOLAR
-- =========================================================

create table iller (
  plaka smallint primary key,
  ad text not null,
  diyanet_sehir_kodu text not null unique
);

create table ilceler (
  id uuid primary key default gen_random_uuid(),
  il_plaka smallint not null references iller(plaka),
  ad text not null,
  diyanet_ilce_kodu text not null,   -- artık BENZERSİZ DEĞİL: büyükşehir merkez ilçeleri (Kadıköy,
                                      -- Çankaya, Konak vb.) Diyanet'in kendi hiyerarşisinde ayrı vakit
                                      -- kaydına sahip olmadığından, il merkezinin koduna düşer (bkz. seed_ilceler.sql)
  lat double precision,
  lng double precision
);
create index ilceler_il_idx on ilceler(il_plaka);
create index ilceler_ad_idx on ilceler using gin (to_tsvector('turkish', ad));
create index ilceler_diyanet_kodu_idx on ilceler(diyanet_ilce_kodu);

-- Haftalık önbellek — Diyanet/ezanvakti API'sinden çekilir (bkz. supabase/vakit_guncelle.py)
create table vakitler (
  ilce_id uuid not null references ilceler(id),
  tarih date not null,
  ogle time not null,
  primary key (ilce_id, tarih)
);

create table hutbeler (
  id uuid primary key default gen_random_uuid(),
  tarih date not null unique,
  baslik text not null,
  korpus_hutbe_id text not null  -- ana korpusa (site/data) bağlanır — zorunlu, bkz. §9.1
);

create table sorular (
  id uuid primary key default gen_random_uuid(),
  hutbe_id uuid not null references hutbeler(id) on delete cascade,
  sira smallint not null,
  metin text not null,
  secenekler jsonb not null,       -- ["a","b","c","d"]
  dogru_idx smallint not null check (dogru_idx between 0 and 3),
  tur text not null default 'kavrayis',
  sure_sn smallint not null default 20,
  aciklama text not null default '',
  unique (hutbe_id, sira)
);

create table oturumlar (
  id uuid primary key default gen_random_uuid(),
  jeton_hash text not null,        -- cihaz jetonunun hash'i — ham jeton hiç sunucuya gelmez
  ilce_id uuid not null references ilceler(id),
  hutbe_id uuid not null references hutbeler(id),
  takma_ad text not null,
  baslangic timestamptz not null default now(),
  mod text not null default 'katilimci',
  kol text not null default 'on',  -- Faz 4 rastgeleleştirmesi için ('on' = sorular önce)
  unique (jeton_hash, hutbe_id)     -- §9.2: jeton+hutbe başına tek oturum
);
create index oturumlar_hutbe_ilce_idx on oturumlar(hutbe_id, ilce_id);

-- Bir sorunun kullanıcıya ne zaman açıldığının sunucu-taraflı damgası.
-- soruCiz() anındaki client isteğiyle yazılır; puan hesabı bu zamana göre yapılır (§2.2, §9.2).
create table soru_acilislar (
  oturum_id uuid not null references oturumlar(id) on delete cascade,
  soru_id uuid not null references sorular(id) on delete cascade,
  acilis timestamptz not null default now(),
  primary key (oturum_id, soru_id)
);

create table cevaplar (
  id uuid primary key default gen_random_uuid(),
  oturum_id uuid not null references oturumlar(id) on delete cascade,
  soru_id uuid not null references sorular(id) on delete cascade,
  secilen_idx smallint not null check (secilen_idx between -1 and 3),  -- -1 = süre doldu
  dogru_mu boolean not null,
  yanit_ms integer not null,
  puan integer not null,
  created_at timestamptz not null default now(),
  unique (oturum_id, soru_id)      -- bir soru bir oturumda yalnızca bir kez cevaplanır
);
create index cevaplar_oturum_idx on cevaplar(oturum_id);

-- =========================================================
-- 2. GENEL AMAÇLI YARDIMCI: oturum toplam puanı
-- =========================================================

create view v_oturum_puan as
select
  o.id as oturum_id,
  o.hutbe_id,
  o.ilce_id,
  o.takma_ad,
  o.jeton_hash,
  coalesce(sum(c.puan), 0)::int as toplam_puan,
  count(c.id)::int as cevap_sayisi
from oturumlar o
left join cevaplar c on c.oturum_id = o.id
group by o.id;

-- =========================================================
-- 3. SORULARIN GÜVENLİ GÖRÜNÜMÜ (doğru cevap sızdırılmaz)
-- =========================================================
-- Burada BİR VIEW YOK: ilk sürüm `sorular_public` diye bir view'dı, ama Supabase Security
-- Advisor bunu "security definer view" olarak CRITICAL işaretledi (view'lar örtük biçimde
-- sahibinin yetkisiyle RLS'i atlar). Aynı davranış artık 07_guvenlik_sikilastirma.sql'deki
-- açıkça SECURITY DEFINER işaretli `sorular_public(p_hutbe_id)` FONKSİYONUYLA sağlanıyor —
-- fresh install yapıyorsan schema.sql'den sonra 07'yi de çalıştır.

-- =========================================================
-- 4. RPC FONKSİYONLARI (SECURITY DEFINER — anon rolü yalnızca bunları çağırır)
-- =========================================================

-- 4.1 Bugünün quiz durumu: ilçenin öğle vaktine göre açık mı, hangi hutbe?
create or replace function quiz_durumu(p_ilce_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ogle time;
  v_simdi timestamptz := now();
  v_bugun date := (v_simdi at time zone 'Europe/Istanbul')::date;
  v_saat time := (v_simdi at time zone 'Europe/Istanbul')::time;
  v_hutbe hutbeler%rowtype;
begin
  select ogle into v_ogle from vakitler where ilce_id = p_ilce_id and tarih = v_bugun;
  select * into v_hutbe from hutbeler where tarih <= v_bugun order by tarih desc limit 1;

  if v_ogle is null or v_hutbe.id is null then
    return jsonb_build_object('acik', false, 'neden', 'veri_yok');
  end if;

  if extract(dow from v_bugun) <> 5 or v_saat < v_ogle then
    return jsonb_build_object('acik', false, 'neden', 'henuz_acilmadi', 'acilis', v_ogle);
  end if;

  return jsonb_build_object(
    'acik', true,
    'hutbe_id', v_hutbe.id,
    'baslik', v_hutbe.baslik,
    'tarih', v_hutbe.tarih
  );
end;
$$;

-- 4.2 Oturum başlat/getir — (jeton, hutbe) başına tek oturum garantisi
create or replace function oturum_baslat(p_jeton_hash text, p_ilce_id uuid, p_hutbe_id uuid, p_takma_ad text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  insert into oturumlar (jeton_hash, ilce_id, hutbe_id, takma_ad)
  values (p_jeton_hash, p_ilce_id, p_hutbe_id, p_takma_ad)
  on conflict (jeton_hash, hutbe_id) do update set jeton_hash = excluded.jeton_hash
  returning id into v_id;
  return v_id;
end;
$$;

-- 4.3 Soru açıldı — süre sayacının sunucu-taraflı çapası (§2.2, §9.2)
create or replace function soru_ac(p_oturum_id uuid, p_soru_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  insert into soru_acilislar (oturum_id, soru_id) values (p_oturum_id, p_soru_id)
  on conflict (oturum_id, soru_id) do nothing;
$$;

-- 4.4 Cevap gönder — puan sunucuda hesaplanır, doğru cevap yalnızca burada açıklanır
create or replace function soru_cevapla(p_oturum_id uuid, p_soru_id uuid, p_secilen_idx smallint)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_soru sorular%rowtype;
  v_acilis timestamptz;
  v_ms integer;
  v_dogru boolean;
  v_puan integer;
  v_mevcut cevaplar%rowtype;
  v_toplam int;
begin
  select * into v_mevcut from cevaplar where oturum_id = p_oturum_id and soru_id = p_soru_id;
  if found then
    select coalesce(sum(puan),0) into v_toplam from cevaplar where oturum_id = p_oturum_id;
    return jsonb_build_object('dogru_mu', v_mevcut.dogru_mu, 'dogru_idx',
      (select dogru_idx from sorular where id = p_soru_id),
      'puan', v_mevcut.puan, 'toplam_puan', v_toplam,
      'aciklama', (select aciklama from sorular where id = p_soru_id), 'tekrar', true);
  end if;

  select * into v_soru from sorular where id = p_soru_id;
  select acilis into v_acilis from soru_acilislar where oturum_id = p_oturum_id and soru_id = p_soru_id;
  if v_acilis is null then
    v_acilis := now();  -- açılış çağrısı atlanmışsa cömert davran: şimdi başlamış say
  end if;

  v_ms := greatest(0, extract(epoch from (now() - v_acilis)) * 1000)::int;
  v_dogru := (p_secilen_idx = v_soru.dogru_idx);
  v_puan := case when v_dogru
    then round(1000 * (1 - least(v_ms, v_soru.sure_sn * 1000)::numeric / (v_soru.sure_sn * 1000) / 2))::int
    else 0 end;

  insert into cevaplar (oturum_id, soru_id, secilen_idx, dogru_mu, yanit_ms, puan)
  values (p_oturum_id, p_soru_id, p_secilen_idx, v_dogru, v_ms, v_puan);

  select coalesce(sum(puan),0) into v_toplam from cevaplar where oturum_id = p_oturum_id;

  return jsonb_build_object('dogru_mu', v_dogru, 'dogru_idx', v_soru.dogru_idx,
    'puan', v_puan, 'toplam_puan', v_toplam, 'aciklama', v_soru.aciklama, 'tekrar', false);
end;
$$;

-- 4.5 İlçe sıralaması (haftalık, o hutbeye özel)
create or replace function ilce_siralama(p_hutbe_id uuid, p_ilce_id uuid, p_limit int default 20)
returns table(takma_ad text, toplam_puan int, sira bigint)
language sql stable
security definer
set search_path = public
as $$
  select takma_ad, toplam_puan, rank() over (order by toplam_puan desc) as sira
  from v_oturum_puan
  where hutbe_id = p_hutbe_id and ilce_id = p_ilce_id
  order by toplam_puan desc
  limit p_limit;
$$;

-- 4.6 İl sıralaması — ilçe ortalamaları, min. 5 katılımcı eşiği (§6)
create or replace function il_siralama(p_hutbe_id uuid, p_il_plaka smallint)
returns table(ilce_ad text, ortalama_puan numeric, katilimci int)
language sql stable
security definer
set search_path = public
as $$
  select i.ad, round(avg(v.toplam_puan), 0) as ortalama_puan, count(*)::int as katilimci
  from v_oturum_puan v
  join ilceler i on i.id = v.ilce_id
  where v.hutbe_id = p_hutbe_id and i.il_plaka = p_il_plaka
  group by i.ad
  having count(*) >= 5
  order by ortalama_puan desc;
$$;

-- 4.7 Türkiye geneli ilk 100 (yalnızca takma ad — kimliklendirici veri yok)
create or replace function turkiye_siralama(p_hutbe_id uuid)
returns table(takma_ad text, ilce_ad text, toplam_puan int)
language sql stable
security definer
set search_path = public
as $$
  select v.takma_ad, i.ad, v.toplam_puan
  from v_oturum_puan v
  join ilceler i on i.id = v.ilce_id
  where v.hutbe_id = p_hutbe_id
  order by v.toplam_puan desc
  limit 100;
$$;

-- 4.8 Kişisel geçmiş — yalnızca kendi jeton hash'iyle sorgulanabilir
create or replace function kisisel_gecmis(p_jeton_hash text)
returns table(hutbe_tarih date, hutbe_baslik text, toplam_puan int, cevap_sayisi int)
language sql stable
security definer
set search_path = public
as $$
  select h.tarih, h.baslik, v.toplam_puan, v.cevap_sayisi
  from v_oturum_puan v
  join hutbeler h on h.id = v.hutbe_id
  where v.jeton_hash = p_jeton_hash
  order by h.tarih desc;
$$;

-- =========================================================
-- 5. RLS — anon rolü tabanlı tablolara DOKUNAMAZ, yalnızca yukarıdaki RPC'ler ve
--    referans tabloları (iller/ilceler/vakitler/hutbeler/sorular_public) okunabilir.
-- =========================================================

alter table iller enable row level security;
alter table ilceler enable row level security;
alter table vakitler enable row level security;
alter table hutbeler enable row level security;
alter table sorular enable row level security;
alter table oturumlar enable row level security;
alter table soru_acilislar enable row level security;
alter table cevaplar enable row level security;

create policy "iller: herkes okuyabilir" on iller for select using (true);
create policy "ilceler: herkes okuyabilir" on ilceler for select using (true);
create policy "vakitler: herkes okuyabilir" on vakitler for select using (true);
create policy "hutbeler: herkes okuyabilir" on hutbeler for select using (true);

-- sorular tablosuna DOĞRUDAN select politikası yok (dogru_idx sızmasın) —
-- istemci `sorular_public(p_hutbe_id)` RPC'sini çağırır (07_guvenlik_sikilastirma.sql),
-- gerçek soruları/dogru_idx'i de diğer RPC'ler üzerinden görür.
-- oturumlar/soru_acilislar/cevaplar tablolarına da doğrudan erişim yok — yalnızca RPC'ler (security definer) yazar/okur.

grant select on iller, ilceler, vakitler, hutbeler to anon;
-- v_oturum_puan İSTEMCİYE DOĞRUDAN AÇILMAZ: jeton_hash içeriyor. Sıralamalar yalnızca
-- aşağıdaki RPC'ler (ilce_siralama/il_siralama/turkiye_siralama) üzerinden, jeton_hash
-- sızdırılmadan sunulur.
-- NOT: bu grant + fonksiyonların kendisi Postgres varsayılanıyla PUBLIC'e de açık kalıyordu
-- (yeni fonksiyon = varsayılan PUBLIC execute); 07_guvenlik_sikilastirma.sql bunu kapatıp
-- yalnızca anon'a indiriyor — fresh install'da o dosyayı da çalıştır.
grant execute on function quiz_durumu, oturum_baslat, soru_ac, soru_cevapla,
  ilce_siralama, il_siralama, turkiye_siralama, kisisel_gecmis to anon;

-- service_role RLS'i bypass eder ama GRANT olmadan sorguya giremez — bazı Supabase projelerinde
-- ("Automatically expose new tables" kapalıyken) bu varsayılan gelmiyor. vakit_guncelle.py gibi
-- sunucu-taraflı scriptler için elle veriyoruz.
grant usage on schema public to service_role;
grant select, insert, update, delete on
  iller, ilceler, vakitler, hutbeler, sorular, oturumlar, soru_acilislar, cevaplar
  to service_role;
grant select on v_oturum_puan to service_role;

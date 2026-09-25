-- 10 — Cami düzeyi (25.09.2026)
--
-- Kullanıcı kararı: yarışma cami düzeyine iner. quiz_plani §8'deki "yalnızca ilçe kodu"
-- ilkesi kaldırıldı (katılımcı eşiği de istenmedi). Ham GPS koordinatı YİNE sunucuya gitmez:
-- istemci seçilen ilçenin camilerini çekip mesafeyi telefonda hesaplar, sunucuya yalnızca
-- kullanıcının SEÇTİĞİ cami_id yazılır.
--
-- Veri: Diyanet'in açık "CAMİ BİLGİLERİ DETAY TABLO"su (≈90 bin cami, yalnızca adres) +
-- OpenStreetMap konumları (ODbL, © OpenStreetMap katkıcıları). Hazırlayan: cami_hazirla.py
-- (bu SQL'den SONRA `python cami_hazirla.py yukle`).
--
-- Supabase SQL Editor'da bir kez çalıştırılır; tekrar çalıştırılabilir (idempotent).

-- ── 1. Tablo ───────────────────────────────────────────────
create table if not exists camiler (
  id integer primary key,            -- Diyanet CSV'sindeki satır sırası (kararlı kimlik)
  ilce_id uuid not null references ilceler(id),
  ad text not null,                  -- görünen ad: "YENİ HÜRRİYET C." → "Yeni Hürriyet Camii"
  mahalle text not null default '',
  adres text not null default '',
  lat double precision,
  lng double precision,
  konum text not null check (konum in ('cami', 'mahalle', 'ilce'))  -- konumun hassasiyeti
);
create index if not exists camiler_ilce_idx on camiler(ilce_id);

alter table camiler enable row level security;
drop policy if exists "camiler: herkes okuyabilir" on camiler;
create policy "camiler: herkes okuyabilir" on camiler for select using (true);
grant select on camiler to anon;
grant select, insert, update, delete on camiler to service_role;

-- ── 2. Oturumda cami ───────────────────────────────────────
alter table oturumlar add column if not exists cami_id integer references camiler(id);
create index if not exists oturumlar_hutbe_cami_idx on oturumlar(hutbe_id, cami_id);

-- v_oturum_puan'a cami_id eklenir (sütun SONA eklendiği için create or replace yeterli)
create or replace view v_oturum_puan as
select
  o.id as oturum_id,
  o.hutbe_id,
  o.ilce_id,
  o.takma_ad,
  o.jeton_hash,
  coalesce(sum(c.puan), 0)::int as toplam_puan,
  count(c.id)::int as cevap_sayisi,
  o.cami_id
from oturumlar o
left join cevaplar c on c.oturum_id = o.id
group by o.id;

-- ── 3. oturum_baslat: isteğe bağlı p_cami_id ───────────────
-- Eski 4 parametreli sürüm düşürülür; yeni sürümde p_cami_id varsayılanlı olduğu için
-- önbellekteki eski istemci (4 adlandırılmış parametreyle çağıran) çalışmaya devam eder.
-- İkisi birlikte dursaydı 4 parametreli çağrı "belirsiz fonksiyon" hatası verirdi.
drop function if exists oturum_baslat(text, uuid, uuid, text);
create or replace function oturum_baslat(p_jeton_hash text, p_ilce_id uuid, p_hutbe_id uuid,
                                         p_takma_ad text, p_cami_id integer default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  -- Cami seçilen ilçeye ait değilse yok sayılır (yanlış ilçe sıralamasına düşmesin)
  if p_cami_id is not null and not exists
     (select 1 from camiler where id = p_cami_id and ilce_id = p_ilce_id) then
    p_cami_id := null;
  end if;
  insert into oturumlar (jeton_hash, ilce_id, hutbe_id, takma_ad, cami_id)
  values (p_jeton_hash, p_ilce_id, p_hutbe_id, p_takma_ad, p_cami_id)
  on conflict (jeton_hash, hutbe_id) do update
    set cami_id = coalesce(excluded.cami_id, oturumlar.cami_id)
  returning id into v_id;
  return v_id;
end;
$$;

-- ── 4. Sıralamalar ─────────────────────────────────────────
-- 4.1 Cami içi (o hutbe, o cami): takma ad + puan
create or replace function cami_siralama(p_hutbe_id uuid, p_cami_id integer, p_limit int default 50)
returns table(sira bigint, takma_ad text, toplam_puan int)
language sql stable
security definer
set search_path = public
as $$
  select rank() over (order by toplam_puan desc), takma_ad, toplam_puan
  from v_oturum_puan
  where hutbe_id = p_hutbe_id and cami_id = p_cami_id and cevap_sayisi > 0
  order by toplam_puan desc
  limit p_limit;
$$;

-- 4.2 İlçedeki camiler: cami ortalaması + katılımcı sayısı.
-- Eşik YOK (kullanıcı kararı); tek kişilik bir caminin ortalamayla tepeye oturmasını
-- dengelemek için sıralama önce "en az 3 katılımcı"ya, sonra ortalamaya göre.
create or replace function ilce_cami_siralama(p_hutbe_id uuid, p_ilce_id uuid, p_limit int default 30)
returns table(sira bigint, cami_id integer, cami_ad text, ortalama_puan int, katilimci int)
language sql stable
security definer
set search_path = public
as $$
  with t as (
    select v.cami_id, round(avg(v.toplam_puan))::int as ort, count(*)::int as n
    from v_oturum_puan v
    where v.hutbe_id = p_hutbe_id and v.ilce_id = p_ilce_id
      and v.cami_id is not null and v.cevap_sayisi > 0
    group by v.cami_id
  )
  select rank() over (order by (t.n >= 3) desc, t.ort desc), t.cami_id, c.ad, t.ort, t.n
  from t join camiler c on c.id = t.cami_id
  order by (t.n >= 3) desc, t.ort desc
  limit p_limit;
$$;

-- ── 5. Yetkiler (07'deki örüntü: PUBLIC'ten al, yalnızca anon'a ver) ──
revoke execute on function oturum_baslat(text, uuid, uuid, text, integer) from public;
revoke execute on function cami_siralama(uuid, integer, int) from public;
revoke execute on function ilce_cami_siralama(uuid, uuid, int) from public;
grant execute on function oturum_baslat(text, uuid, uuid, text, integer),
  cami_siralama(uuid, integer, int), ilce_cami_siralama(uuid, uuid, int) to anon;
grant select on v_oturum_puan to service_role;

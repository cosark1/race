-- 02 — Alıştırma modu + "bu haftanın hutbesi henüz yayımlanmadı" durumu
--
-- Sorun: Cuma dışındaki günlerde (ve hutbe henüz yayımlanmadığında) giriş sayfası bomboş
-- duruyordu. Çözüm: geçmiş hutbelerin soruları "alıştırma" olarak oynanabilir hâle geldi.
--
-- Alıştırma CANLI QUIZ DEĞİLDİR — kasıtlı olarak:
--   · oturum/cevap kaydı YOK → sıralamayı ve araştırma verisini kirletmez (quiz_plani.md §3, §9.1)
--   · puanlama istemcide → sunucu-taraflı zaman çapasına gerek yok
--   · doğru cevaplar açıkça döner — ama YALNIZCA bugünün hutbesi olmayan (geçmiş) hutbeler için,
--     yani canlı quizin cevapları hiçbir koşulda bu yoldan sızmaz.
--
-- schema.sql'den SONRA çalıştırılır. Tekrar çalıştırılabilir (idempotent).

-- ─────────────────────────────────────────────────────────────
-- 1. quiz_durumu: canlı quiz artık TAM OLARAK bugünün hutbesini gerektirir
-- ─────────────────────────────────────────────────────────────
-- Önceden "tarih <= bugün olan en güncel hutbe" alınıyordu; bu, yeni hutbe eklenmemişse
-- geçen haftanınkini canlı sanma hatasına yol açıyordu.
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
  select * into v_hutbe from hutbeler where tarih = v_bugun;
  if v_hutbe.id is null then
    return jsonb_build_object('acik', false, 'neden', 'hutbe_yayimlanmadi');
  end if;

  select ogle into v_ogle from vakitler where ilce_id = p_ilce_id and tarih = v_bugun;
  if v_ogle is null then
    return jsonb_build_object('acik', false, 'neden', 'vakit_yok');
  end if;

  if v_saat < v_ogle then
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

-- ─────────────────────────────────────────────────────────────
-- 2. hafta_durumu: giriş sayfasının ilçe seçilmeden çizilebilmesi için
-- ─────────────────────────────────────────────────────────────
create or replace function hafta_durumu()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bugun date := (now() at time zone 'Europe/Istanbul')::date;
  v_bugunku hutbeler%rowtype;
  v_gecmis jsonb;
begin
  select * into v_bugunku from hutbeler where tarih = v_bugun;

  select coalesce(jsonb_agg(x order by x->>'tarih' desc), '[]'::jsonb) into v_gecmis
  from (
    select jsonb_build_object('id', id, 'tarih', tarih, 'baslik', baslik) as x
    from hutbeler
    where tarih < v_bugun
    order by tarih desc
    limit 8
  ) s;

  return jsonb_build_object(
    'bugun', v_bugun,
    'bugunku_hutbe', case when v_bugunku.id is null then null
      else jsonb_build_object('id', v_bugunku.id, 'tarih', v_bugunku.tarih, 'baslik', v_bugunku.baslik) end,
    'gecmis_hutbeler', v_gecmis
  );
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- 3. alistirma_sorulari: doğru cevaplarla birlikte — YALNIZCA geçmiş hutbeler için
-- ─────────────────────────────────────────────────────────────
create or replace function alistirma_sorulari(p_hutbe_id uuid)
returns table(id uuid, sira smallint, metin text, secenekler jsonb,
              dogru_idx smallint, aciklama text, sure_sn smallint)
language sql stable
security definer
set search_path = public
as $$
  select s.id, s.sira, s.metin, s.secenekler, s.dogru_idx, s.aciklama, s.sure_sn
  from sorular s
  join hutbeler h on h.id = s.hutbe_id
  -- Kritik kısıt: bugünün hutbesi buradan ASLA dönmez → canlı quizin cevapları sızmaz.
  where s.hutbe_id = p_hutbe_id
    and h.tarih < (now() at time zone 'Europe/Istanbul')::date
  order by s.sira;
$$;

-- ─────────────────────────────────────────────────────────────
-- 4. sonraki_kahutbe: ilçeye göre geri sayım
-- ─────────────────────────────────────────────────────────────
-- Sunucu zamanını da birlikte döndürür: istemci, kendi saatiyle sunucu saati arasındaki
-- FARKI bir kez hesaplayıp sayacı ona göre işletir. Böylece telefonun saati yanlış olsa bile
-- geri sayım (ve dolayısıyla açılış anı) kaymaz — quiz_plani.md §2, "istemci saatine güvenilmez".
create or replace function sonraki_kahutbe(p_ilce_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_simdi timestamptz := now();
  v_bugun date := (v_simdi at time zone 'Europe/Istanbul')::date;
  v_tarih date;
  v_ogle time;
  v_hedef timestamptz;
  v_hutbe hutbeler%rowtype;
begin
  -- Bugün dahil, öğle vakti henüz geçmemiş en yakın günü bul.
  select v.tarih, v.ogle into v_tarih, v_ogle
  from vakitler v
  where v.ilce_id = p_ilce_id
    and ((v.tarih + v.ogle) at time zone 'Europe/Istanbul') > v_simdi
  order by v.tarih
  limit 1;

  if v_tarih is null then
    -- Önbellekte ileri tarihli vakit yok (vakit_guncelle.py çalıştırılmalı)
    return jsonb_build_object('sunucu_zamani', v_simdi, 'hedef', null, 'neden', 'vakit_yok');
  end if;

  v_hedef := (v_tarih + v_ogle) at time zone 'Europe/Istanbul';
  select * into v_hutbe from hutbeler where tarih = v_tarih;

  return jsonb_build_object(
    'sunucu_zamani', v_simdi,
    'hedef', v_hedef,
    'hedef_tarih', v_tarih,
    'hutbe_var', v_hutbe.id is not null,
    'baslik', v_hutbe.baslik
  );
end;
$$;

grant execute on function hafta_durumu, alistirma_sorulari, sonraki_kahutbe to anon;

-- 06 — Canlı Türkiye sıralaması
--
-- Önceden sıralama yalnızca ilçe bazlıydı ve "Sonucu gör"e basıldığı anda TEK SEFER çekilip
-- donuyordu. Artık Türkiye geneli, üç sütunlu (takma ad · ilçe/il · puan) ve istemci tarafından
-- periyodik olarak tazeleniyor.
--
-- NEDEN SUPABASE REALTIME DEĞİL: postgres_changes aboneliği RLS'e tabidir ve `cevaplar`
-- tablosunu anon'a açmayı gerektirirdi. O tabloda `soru_id` + `dogru_mu` birlikte duruyor;
-- okunabilseydi doğru cevaplar tersine mühendislikle çıkarılabilirdi (schema.sql §3'teki
-- "doğru cevap sızmaz" ilkesi çökerdi). Bu yüzden sıralama SECURITY DEFINER RPC üzerinden
-- yoklamayla (polling) tazeleniyor.
--
-- GÜVENLİK NOTU: `oturum_id` fiilen bir taşıyıcı jetondur — soru_cevapla() sahiplik
-- doğrulaması yapmaz, dolayısıyla bir başkasının oturum_id'sini bilen onun adına cevap
-- gönderebilir. Bu yüzden sıralama fonksiyonları oturum_id DÖNDÜRMEZ.

-- Dönüş tipi değiştiği için önce düşürülmeli (create or replace tip değişimini kabul etmez).
drop function if exists turkiye_siralama(uuid);

create or replace function turkiye_siralama(p_hutbe_id uuid, p_limit int default 50)
returns table(sira bigint, takma_ad text, ilce_ad text, il_ad text, toplam_puan int)
language sql stable
security definer
set search_path = public
as $$
  select rank() over (order by v.toplam_puan desc) as sira,
         v.takma_ad, i.ad, il.ad, v.toplam_puan
  from v_oturum_puan v
  join ilceler i on i.id = v.ilce_id
  join iller  il on il.plaka = i.il_plaka
  where v.hutbe_id = p_hutbe_id
    and v.cevap_sayisi > 0          -- henüz tek soru cevaplamamış oturumlar listeyi şişirmesin
  order by v.toplam_puan desc
  limit p_limit;
$$;

-- Kullanıcı ilk 50'ye giremediğinde kendi sırasını yine de görebilsin diye.
create or replace function oturum_sirasi(p_oturum_id uuid)
returns jsonb
language sql stable
security definer
set search_path = public
as $$
  with hedef as (
    select hutbe_id, toplam_puan from v_oturum_puan where oturum_id = p_oturum_id
  )
  select jsonb_build_object(
    'sira',   (select count(*) + 1 from v_oturum_puan v, hedef h
               where v.hutbe_id = h.hutbe_id and v.cevap_sayisi > 0 and v.toplam_puan > h.toplam_puan),
    'toplam', (select count(*) from v_oturum_puan v, hedef h
               where v.hutbe_id = h.hutbe_id and v.cevap_sayisi > 0),
    'puan',   (select toplam_puan from hedef)
  );
$$;

grant execute on function turkiye_siralama(uuid, int), oturum_sirasi(uuid) to anon;

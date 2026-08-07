-- 08 — KRİTİK: "Başla" butonu quiz açıkken de kilitli kalıyordu
--
-- Bulgu (07.08.2026, canlı yayın günü, saat 14:00 civarı — Kadıköy'ün öğle vakti 13:15 geçmişti):
--   quiz_durumu()      -> {"acik": true, ...}          — Kardeşlik hutbesi fiilen açık
--   sonraki_kahutbe()  -> {"hedef": null, "neden": "vakit_yok"}
--
-- "Başla" butonunu quiz_durumu() DEĞİL, sayacKur()'un çağırdığı sonraki_kahutbe() kontrol
-- ediyor (index.html). sonraki_kahutbe eskiden yalnızca GELECEKTEKİ bir hedef arıyordu
-- (tarih+ogle > şimdi). Bugünün öğle vakti geçtiğinde ama gün henüz bitmediğinde — yani
-- §2'nin "öğle vaktinden gün sonuna kadar açık" penceresinin tam ortasında — bu sorgu hiçbir
-- şey bulamayıp "Vakit bilgisi yok" deyip butonu kilitliyordu. Quiz fiilen açık olsa bile.
--
-- Düzeltme: bugünün kaydı, öğle vakti geçmiş olsa da BUGÜN sürdüğü müddetçe hâlâ "hedef"
-- sayılır (hedef geçmişte bir zaman damgası olur, index.html'deki sayacCiz() bunu zaten
-- "Kahutbe açık!" + buton aktif olarak yorumluyor — istemci tarafında değişiklik gerekmiyor).
-- Gece yarısı tarih değişince bugünün kaydı otomatik elenir, pencere kendiliğinden kapanır.

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
  select v.tarih, v.ogle into v_tarih, v_ogle
  from vakitler v
  where v.ilce_id = p_ilce_id
    and (
      v.tarih = v_bugun                                              -- bugünse, öğle geçmiş olsa da gün sonuna kadar geçerli
      or ((v.tarih + v.ogle) at time zone 'Europe/Istanbul') > v_simdi  -- ya da gerçekten gelecekteki bir hedef
    )
  order by v.tarih
  limit 1;

  if v_tarih is null then
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

revoke execute on function sonraki_kahutbe(uuid) from public;
grant execute on function sonraki_kahutbe(uuid) to anon;

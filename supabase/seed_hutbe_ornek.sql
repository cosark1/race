-- Örnek/test verisi: 22.05.2026 "Söz Ahlakı ve Sosyal Medya" hutbesi + Faz 0'da elle yazılan 5 soru.
-- korpus_hutbe_id, site/data/hutbeler.json ve metinler/2026.json ile aynı anahtarı kullanır ("22.05.2026").
-- Bu dosyayı schema.sql + seed_ilceler.sql'den SONRA çalıştır.

with h as (
  insert into hutbeler (tarih, baslik, korpus_hutbe_id)
  values ('2026-05-22', 'Söz Ahlakı ve Sosyal Medya', '22.05.2026')
  returning id
)
insert into sorular (hutbe_id, sira, metin, secenekler, dogru_idx, tur, aciklama)
select h.id, v.sira, v.metin, v.secenekler::jsonb, v.dogru_idx, 'kavrayis', v.aciklama
from h, (values
  (1, 'Hatibe göre sözün tesiri nerede gizlidir?',
   '["Sesin yüksekliğinde","Samimiyetin derinliğinde ve üslubun inceliğinde","Kullanılan kelimelerin ağırlığında","Konuşanın toplumdaki saygınlığında"]',
   1, 'Hutbede açıkça "sesin yüksekliğinde değil" denilerek karşıtlık kuruldu.'),

  (2, 'Hutbede gönül kapıları neye benzetildi?',
   '["Anahtarı kaybolmuş bir sandığa","İçeriden açılan bir kilide","Rüzgârda çarpan bir pencereye","Dışarıdan sürgülenen bir kapıya"]',
   1, '"Gönül kapıları, içeriden açılan kilide benzer; o kilidin yegâne anahtarı yumuşak bir sözdür."'),

  (3, 'Hutbeye göre "yuvasında huzur arayan" kişi ne yapmalı?',
   '["Sesini hiç yükseltmemeli","Az konuşup çok dinlemeli","Dilini zarafetle süslemeli","Tartışmadan tümüyle uzak durmalı"]',
   2, '"Yuvasında huzur arayan, dilini zarafetle süslesin." — dört seçenek de söze dair, ama hutbedeki ifade budur.'),

  (4, 'Dijital mecralardaki ihlallere örnek olarak sayılanlar arasında hangisi <u>yoktu</u>?',
   '["Sanal kumar bağımlılığı","Şiddete sevk eden dijital oyunlar","Ekran başında geçirilen sürenin fazlalığı","Kimliğini gizleyerek başkasının haysiyetine dil uzatmak"]',
   2, 'Sayılanlar: sanal kumar/uyuşturucu, şiddete sevk eden oyunlar, kimlik gizleyerek hakaret, yalan haber. Ekran süresi hutbede geçmedi.'),

  (5, 'Hutbede okunan Kâf sûresi âyeti neyi hatırlatıyordu?',
   '["Söylenen her sözü kaydeden bir meleğin hazır bulunduğunu","Kıyamet gününün ansızın geleceğini","Rızkın yalnızca Allah katından olduğunu","Sabredenlerin mükâfatının hesapsız verileceğini"]',
   0, '"İnsanın yanında, söylediği her sözü kaydeden bir melek mutlaka hazır bulunur." (Kâf 50/18)')
) as v(sira, metin, secenekler, dogru_idx, aciklama);

-- Test kolaylığı: bugünün tarihiyle de bir kayıt ister misin? quiz_durumu() en güncel
-- hutbeler.tarih <= bugün olanı seçtiği için, canlı test için tarihi bugüne çekmek isteyebilirsin:
--   update hutbeler set tarih = current_date where korpus_hutbe_id = '22.05.2026';

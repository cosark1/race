-- 05 — 07.08.2026 hutbesi · KARDEŞLİK
--
-- Kaynak: Diyanet İşleri Başkanlığı Din Hizmetleri Genel Müdürlüğü, 2026/Kardeşlik.pdf.
-- Sorular hutbenin kendi anlatım sırasıyla (§2.2) ve §4 kurallarına göre yazıldı, kullanıcıyla
-- birlikte birkaç turda gözden geçirildi:
--   1) Genel dini bilgiyle cevaplanamaz — yalnızca bu hutbeyi dinleyen bilir
--   2) Ezber değil kavrayış arar
-- Soru 2'nin doğru cevabı ("Hayallerimiz") bilinçli olarak diğer üç şıkla (sevinç/hüzün/dua)
-- aynı duygusal kategoride — kolay ayırt edilebilir bir "siyasi görüşlerimiz" gibi kopuk bir
-- şıktan, gerçekten dinlemeyi gerektiren bir tuzağa çevrildi.
-- Soru 3, hadisin tamamını (son emri hariç) veriyor ve o son emri soruyor.
-- Soru 4, şiirin Mehmet Akif Ersoy'a ait olduğunu belirtiyor.
-- Soru 5, ayetin Enfâl sûresi 46. ayet olduğunu belirtiyor.

with h as (
  insert into hutbeler (tarih, baslik, korpus_hutbe_id)
  values ('2026-08-07', 'Kardeşlik', '07.08.2026')
  on conflict (tarih) do update set baslik = excluded.baslik
  returning id
)
insert into sorular (hutbe_id, sira, metin, secenekler, dogru_idx, tur, aciklama)
select h.id, v.sira, v.metin, v.secenekler::jsonb, v.dogru_idx, 'kavrayis', v.aciklama
from h, (values
  (1, 'Hutbeye göre Peygamberimiz (s.a.s), hangisini iman etmenin bir gereği olarak ifade etmiştir?',
   '["Birbirimizi sevmeyi","Birbirimize saygı duymayı","Birbirimizi desteklemeyi","Birbirimize güvenmeyi"]',
   0, '"...Rahmet Elçisi Peygamberimiz (s.a.s), birbirimizi sevmeyi iman etmenin bir gereği olarak ifade etmiştir." (Müslim, Îmân, 93)'),

  (2, 'Hutbeye göre, vatanımızda bizi yekvücut kılacak olanlar arasında hangisi sayılmamıştır?',
   '["Sevinçlerimiz","Hüzünlerimiz","Dualarımız","Hayallerimiz"]',
   3, '"...sevinçlerimiz, hüzünlerimiz, dualarımız, zenginlik olarak kabul ettiğimiz farklılıklarımız bizleri yekvücut kılacaktır." Hayallerimiz hutbede geçmiyor.'),

  (3, 'Hutbede aktarılan "Birbirinizle ilgi ve alakayı kesmeyin, birbirinize sırt çevirmeyin, birbirinize kin beslemeyin, birbirinize haset etmeyin. Ey Allah''ın kulları!" hadisi hangi emirle bitmektedir?',
   '["Sabırlı olun","Şükredin","Kardeş olun","Tevbe edin"]',
   2, '"...Ey Allah''ın kulları! Kardeş olun." (Tirmizî, Birr ve Sıla, 24)'),

  (4, 'Hutbede alıntılanan Mehmet Akif Ersoy''un şiirine göre, yürekler nasıl olduğunda düşman bir millete giremez?',
   '["Toplu vurdukça","Aşkla çarptıkça","Özgürce attıkça","Nurla doldukça"]',
   0, '"Girmeden tefrika bir millete düşman giremez. Toplu vurdukça yürekler onu top sindiremez."'),

  (5, 'Hutbenin bitirildiği Enfâl sûresi 46. ayete göre, Allah''a ve Resûlüne itaat etmeyip birbirimizle çekişirsek ne olur?',
   '["Rızkımız daralır","Amellerimiz boşa gider","Gücümüz ve devletimiz elden gider","Ecdadımızın hatırası unutulur"]',
   2, '"Allah''a ve Resûlüne itaat edin ve birbirinizle çekişmeyin. Sonra gevşersiniz ve gücünüz, devletiniz elden gider. Sabırlı olun." (Enfâl, 8/46)')
) as v(sira, metin, secenekler, dogru_idx, aciklama)
on conflict (hutbe_id, sira) do update set
  metin = excluded.metin, secenekler = excluded.secenekler,
  dogru_idx = excluded.dogru_idx, aciklama = excluded.aciklama;

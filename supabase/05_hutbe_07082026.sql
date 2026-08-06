-- 05 — 07.08.2026 hutbesi · KARDEŞLİK
--
-- Kaynak: Diyanet İşleri Başkanlığı Din Hizmetleri Genel Müdürlüğü, 2026/Kardeşlik.pdf.
-- Sorular hutbenin kendi anlatım sırasıyla (§2.2) ve §4 kurallarına göre yazıldı:
--   1) Genel dini bilgiyle cevaplanamaz — yalnızca bu hutbeyi dinleyen bilir
--   2) Ezber değil kavrayış arar
-- Soru 3, hutbede SAYILMAYAN bir davranışı (gıybet) doğru seçenek olarak kullanıyor —
-- gıybet ayrı bir hutbede (Kardeşliğe Saplanan Hançer: Gıybet) işlenmişti, burada değil.

with h as (
  insert into hutbeler (tarih, baslik, korpus_hutbe_id)
  values ('2026-08-07', 'Kardeşlik', '07.08.2026')
  on conflict (tarih) do nothing
  returning id
)
insert into sorular (hutbe_id, sira, metin, secenekler, dogru_idx, tur, aciklama)
select h.id, v.sira, v.metin, v.secenekler::jsonb, v.dogru_idx, 'kavrayis', v.aciklama
from h, (values
  (1, 'Hutbeye göre İslam''ın hem bu dünyada hem ebedi âlemde huzur ve mutluluğu sağlama hedefine giden yol nedir?',
   '["Kardeş olmaktan, sevgi ve muhabbeti güçlendirmekten geçer","Zenginliği eşit paylaşmaktan geçer","İlim meclislerini çoğaltmaktan geçer","Cihat ve fetih hareketlerinden geçer"]',
   0, '"Huzur ve mutluluğu sağlamanın yolu ise; kardeş olmaktan, aramızdaki sevgi ve muhabbeti daha da güçlendirmekten geçmektedir."'),

  (2, 'Hutbede, savaşların farklı bölgelere yayıldığı bu dönemde istikbalimizin neye bağlı olduğu söyleniyor?',
   '["Ekonomik büyümeye","Kardeşliğimize","Askeri güce","Uluslararası ittifaklara"]',
   1, '"...ülkemizin ateş çemberinin içine çekilmek istendiği bir dönemde; istikbalimiz, kardeşliğimize bağlıdır."'),

  (3, 'Hutbede aktarılan hadiste, "Ey Allah''ın kulları, kardeş olun" çağrısından önce sayılan davranışlardan hangisi hutbede <u>geçmedi</u>?',
   '["Birbirinize sırt çevirmeyin","Birbirinizi gıybet etmeyin","Birbirinize kin beslemeyin","Birbirinize haset etmeyin"]',
   1, 'Hadiste sayılanlar: ilgi ve alakayı kesmemek, sırt çevirmemek, kin beslememek, haset etmemek. Gıybet bu hadiste geçmedi (Tirmizî, Birr ve Sıla, 24).'),

  (4, 'Hutbede alıntılanan şiire göre, yürekler nasıl olduğunda düşman bir millete giremez?',
   '["Sessiz kaldıkça","Teker teker direndikçe","Toplu vurdukça","Geçmişi unuttukça"]',
   2, '"Girmeden tefrika bir millete düşman giremez. Toplu vurdukça yürekler onu top sindiremez."'),

  (5, 'Hutbenin bitirildiği ayete göre, Allah''a ve Resûlüne itaat etmeyip birbirimizle çekişirsek ne olur?',
   '["Rızkımız daralır","Amellerimiz boşa gider","Gücümüz ve devletimiz elden gider","Ecdadımızın hatırası unutulur"]',
   2, '"Allah''a ve Resûlüne itaat edin ve birbirinizle çekişmeyin. Sonra gevşersiniz ve gücünüz, devletiniz elden gider. Sabırlı olun." (Enfâl, 8/46)')
) as v(sira, metin, secenekler, dogru_idx, aciklama);

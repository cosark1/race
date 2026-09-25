-- 09 — 14.08–25.09.2026 hutbeleri (7 Cuma) · Kahutbe alıştırma arşivi
--
-- Kullanıcı kararı (25.09.2026): sorular TAMAMEN OTOMATİK yazılır ve yayına girer (quiz_plani §10).
-- Kaynak: diyanethaber.com.tr RSS → Diyanet PDF'i (dinhizmetleri robots.txt ile /kategoriler/ yasak).
-- Bu dosya KAYIT içindir: satırlar zaten 10_haftalik_senkron.py kahutbe-yaz ile REST üzerinden
-- yazıldı. Veritabanı sıfırdan kurulursa çalıştırılabilir (idempotent). Kaynak JSON'lar: sorular/.

-- 14.08.2026 · HER YETIM BIR EMANET
with h as (
  insert into hutbeler (tarih, baslik, korpus_hutbe_id)
  values ('2026-08-14', 'Her Yetim Bir Emanet', '14.08.2026')
  on conflict (tarih) do update set baslik = excluded.baslik
  returning id
)
insert into sorular (hutbe_id, sira, metin, secenekler, dogru_idx, tur, aciklama)
select h.id, v.sira, v.metin, v.secenekler::jsonb, v.dogru_idx, 'kavrayis', v.aciklama
from h, (values
  (1, 'Hutbenin başında anlatılan olayda, Ca‘fer-i Tayyâr (r.a) şehit olduktan sonra Peygamberimiz (s.a.s) yetimlerinin evine vardığında ne yapmıştır?',
   '["Onlar için ashabından mal toplamıştır", "Onları kendi evine götürüp yanında büyütmüştür", "Onları bağrına basıp ihtiyaçlarını gidermiştir", "Onları bir süre Hz. Ali’nin himayesine vermiştir"]',
   2, '“Rahmet Elçisi (s.a.s), mateme bürünmüş yetimlerin evine vardı. Onları yanına çağırdı, bağrına bastı, onların ihtiyaçlarını giderdi.” (Nesâî, Zînet, 57)'),
  (2, 'Hutbeye göre ekranlar haber yapmayı kestiğinde hangi düşünceye kapılabiliyoruz?',
   '["Yardımların yerine ulaştığı", "Savaşın bizden uzaklaştığı", "Mazlumların kurtulduğu", "Zulmün de sona erdiği"]',
   3, '“Ekranlar haber yapmayı kestiğinde zulmün de sona erdiği düşüncesine kapılabiliyoruz.”'),
  (3, 'Hutbeye göre insanlığın kaybettiği merhametin acı itirafı, savaşın ortasındaki minik bir yüreğin hangi sözünde görülmektedir?',
   '["“Bizim buralarda çocuklar büyümez!”", "“Bizim buralarda kimse gülmez!”", "“Bizim buralarda oyun oynanmaz!”", "“Bizim buralarda sabah olmaz!”"]',
   0, '“İnsanlığın kaybettiği merhametin acı bir itirafını, savaşın ortasında minik bir yüreğin ‘Bizim buralarda çocuklar büyümez!’ sözünde görüyoruz.”'),
  (4, 'Hutbeye göre aşağıdakilerden hangisi bugün “elimizden gelmeyebilir”?',
   '["Koruyucu bir aile olmak", "Savaşları durdurmak", "Mazlumların sesi olmak", "Duyarsızlaşmamak"]',
   1, '“Belki bugün, elimizden savaşları durdurmak gelmeyebilir. Fakat … unutmamak, duyarsızlaşmamak, mazlumların sesi olmak elimizdedir.” Koruyucu aile olmak da “elimizdedir” denilenler arasında.'),
  (5, 'Hutbenin bitirildiği hadis-i şerife göre, Müslümanların evleri arasında en hayırlı ev hangisidir?',
   '["İçinde Kur’an okunan ev", "Misafiri eksik olmayan ev", "İçinde kendisine iyi davranılan bir yetimin bulunduğu ev", "Komşusu kendisinden emin olan ev"]',
   2, '“Müslümanların evleri arasında en hayırlı ev, içinde kendisine iyi davranılan bir yetimin bulunduğu evdir…” (İbn Mâce, Edeb, 6)')
) as v(sira, metin, secenekler, dogru_idx, aciklama)
on conflict (hutbe_id, sira) do update set
  metin = excluded.metin, secenekler = excluded.secenekler,
  dogru_idx = excluded.dogru_idx, aciklama = excluded.aciklama;

-- 21.08.2026 · MEVLID-I NEBI
with h as (
  insert into hutbeler (tarih, baslik, korpus_hutbe_id)
  values ('2026-08-21', 'Mevlid-i Nebi', '21.08.2026')
  on conflict (tarih) do update set baslik = excluded.baslik
  returning id
)
insert into sorular (hutbe_id, sira, metin, secenekler, dogru_idx, tur, aciklama)
select h.id, v.sira, v.metin, v.secenekler::jsonb, v.dogru_idx, 'kavrayis', v.aciklama
from h, (values
  (1, 'Hutbede Hz. Hatice annemizin, Peygamberimiz (s.a.s)’in hasletlerini anlatırken saydıkları arasında hangisi yoktur?',
   '["Akrabayı gözetirsin", "Misafire ikram edersin", "Borçlunun borcunu üstlenirsin", "Musibete uğrayanlara yardım edersin"]',
   2, '“…Çünkü sen akrabayı gözetirsin; muhtaç olanların bakımını üstlenirsin; aç ve açıkta olanı koruyup, kollarsın; misafire ikram edersin ve musibete maruz kalanlara yardım edersin.” (Buhârî, Bed’ü’l-vahy, 1) Borçlunun borcu sayılmıyor.'),
  (2, 'Hutbeye göre helal kazanç arayan kimse, hangi nebevi prensibi hayatında ilke edinmelidir?',
   '["“Sizin en hayırlınız, ailesine karşı en iyi olanınızdır”", "“Allah kişinin, işini sağlam yapmasından hoşlanır”", "“Müslüman, dilinden ve elinden insanların selâmette olduğu kişidir”", "“Müminlerin iman bakımından en mükemmeli, ahlâk bakımından en güzel olanıdır”"]',
   1, '“Kim, helal kazanç arıyorsa; ‘Allah kişinin, işini sağlam yapmasından hoşlanır’ prensibini hayatında ilke edinsin.” (Taberânî, el-Mu’cemü’l-kebîr) Diğer üçü hutbede aile huzuru, sosyal hayat ve imanın tadı için önerildi.'),
  (3, 'Hutbeye göre dünyanın diğer ucundakilerle iletişim kurabilen nice insanımız, kimlere yabancı olabilmektedir?',
   '["Aynı işyerini paylaştığı mesai arkadaşlarına", "Aynı camide saf tuttuğu cemaate", "Aynı sınıfı paylaştığı arkadaşlarına", "Aynı evi paylaştığı eşine, çocuklarına, anne ve babasına"]',
   3, '“Dünyanın diğer ucundakilerle iletişim kurabilen nice insanımız; aynı evi paylaştığı eşine, çocuklarına, anne ve babasına yabancı olabilmektedir.”'),
  (4, 'Hutbeye göre bu yılki Mevlid-i Nebi Haftası’nı özel kılan nedir?',
   '["Peygamberimizin doğumunun hicri 1500. yılı olması", "Peygamberimizin doğumunun miladi 1450. yılı olması", "Hicretin 1450. yılı olması", "İlk vahyin 1500. yılı olması"]',
   0, '“Sevgili Peygamberimiz (s.a.s)’in doğumunun hicri bin beş yüzüncü yılı olması münasebetiyle Mevlid-i Nebi Haftasını ‘Peygamberimiz ve Güzel Ahlak’ temasıyla idrak edeceğiz.”'),
  (5, 'Hutbenin bitirildiği Ahzâb sûresi 45-46. ayetlere göre Peygamberimiz; şahit, müjdeleyici, uyarıcı ve Allah’ın yoluna çağıran bir davetçi olmanın yanında ne olarak gönderilmiştir?',
   '["Âlemlere bir rahmet olarak", "Yol gösterici bir rehber olarak", "Aydınlatıcı bir kandil olarak", "Parlayan bir yıldız olarak"]',
   2, '“Ey Peygamber! Biz seni bir şahit, bir müjdeleyici, bir uyarıcı; Allah’ın izniyle kendi yoluna çağıran bir davetçi ve aydınlatıcı bir kandil olarak gönderdik.” (Ahzâb, 33/45-46)')
) as v(sira, metin, secenekler, dogru_idx, aciklama)
on conflict (hutbe_id, sira) do update set
  metin = excluded.metin, secenekler = excluded.secenekler,
  dogru_idx = excluded.dogru_idx, aciklama = excluded.aciklama;

-- 28.08.2026 · VATAN SEVGISI
with h as (
  insert into hutbeler (tarih, baslik, korpus_hutbe_id)
  values ('2026-08-28', 'Vatan Sevgisi', '28.08.2026')
  on conflict (tarih) do update set baslik = excluded.baslik
  returning id
)
insert into sorular (hutbe_id, sira, metin, secenekler, dogru_idx, tur, aciklama)
select h.id, v.sira, v.metin, v.secenekler::jsonb, v.dogru_idx, 'kavrayis', v.aciklama
from h, (values
  (1, 'Hutbeye göre İstanbul’un fethiyle ne olmuştur?',
   '["Anadolu bize yurt olmuştur", "Anadolu’daki hâkimiyetimiz perçinlenmiştir", "Düşmanlara geçit verilmeyeceği ilan edilmiştir", "Bir çağ kapanıp yeni bir çağ açılmıştır"]',
   1, '“Aziz vatanımız; Malazgirt Destanıyla bizlere yurt olmuş, İstanbul’un fethiyle Anadolu’daki hâkimiyetimiz perçinlenmiş, Büyük Taarruz’la da düşmanlara geçit verilmeyeceği tüm dünyaya ilan edilmiştir.”'),
  (2, 'Hutbede vatan sevgisi anlatılırken ezanlarımız neyin nişanesi olarak anılmıştır?',
   '["İstiklalimizin", "İmanımızın", "Birliğimizin", "Kardeşliğimizin"]',
   3, '“Vatan sevgisinden maksat ise; istiklalimizin sembolü bayrağımıza, kardeşliğimizin nişanesi ezanlarımıza, bizi millet kılan mukaddes değerlerimize sahip çıkmaktır.”'),
  (3, 'Hutbeye göre vatanı sevmek, nebevi emre gönülden bağlanmanın yanında neyi de gerektirir?',
   '["İşimizi en doğru ve en güzel şekilde yapmayı", "Askerlik görevini eksiksiz yerine getirmeyi", "Yerli malı kullanmayı alışkanlık hâline getirmeyi", "Tarihimizi çocuklarımıza anlatmayı"]',
   0, '“Vatanı sevmek, işimizi en doğru ve en güzel şekilde yapmak; dürüstlüğün ve adaletin hâkim olduğu bir toplum inşa etmektir.”'),
  (4, 'Hutbede aktarılan “Gevşeklik göstermeyin, üzülmeyin; eğer inanmışsanız…” ayeti nasıl devam etmektedir?',
   '["…Allah sizinle beraberdir", "…şüphesiz en üstün olan sizsiniz", "…zafer sizindir", "…Allah sizi yalnız bırakmaz"]',
   1, '“Gevşeklik göstermeyin, üzülmeyin; eğer inanmışsanız şüphesiz en üstün olan sizsiniz.” (Âl-i İmrân, 3/139)'),
  (5, 'Hutbenin bitirildiği Âl-i İmrân sûresi 200. ayete göre, başarıya erişebilmek için sabretmek, sebat göstermek ve hazırlıklı ve uyanık olmanın yanında ne gerekir?',
   '["Allah’a tevekkül etmek", "Birlik olmak", "Allah’tan korkmak", "Namazı dosdoğru kılmak"]',
   2, '“Ey iman edenler! Sabredin; düşman karşısında sebat gösterin; cihad için hazırlıklı ve uyanık olun ve Allah’tan korkun ki başarıya erişebilesiniz.” (Âl-i İmrân, 3/200)')
) as v(sira, metin, secenekler, dogru_idx, aciklama)
on conflict (hutbe_id, sira) do update set
  metin = excluded.metin, secenekler = excluded.secenekler,
  dogru_idx = excluded.dogru_idx, aciklama = excluded.aciklama;

-- 04.09.2026 · PEYGAMBERIMIZ VE GÜZEL AHLAK
with h as (
  insert into hutbeler (tarih, baslik, korpus_hutbe_id)
  values ('2026-09-04', 'Peygamberimiz ve Güzel Ahlak', '04.09.2026')
  on conflict (tarih) do update set baslik = excluded.baslik
  returning id
)
insert into sorular (hutbe_id, sira, metin, secenekler, dogru_idx, tur, aciklama)
select h.id, v.sira, v.metin, v.secenekler::jsonb, v.dogru_idx, 'kavrayis', v.aciklama
from h, (values
  (1, 'Hutbenin başında, Peygamberimiz (s.a.s)’in “kardeşlerim” diye müjdelediği kimselerden olmanın mutluluğu dile getirilmektedir. Hutbede anılan bu müjde hangisidir?',
   '["“Ne mutlu gariplere”", "“Ne mutlu sünnetimi yaşatanlara”", "“Ne mutlu beni görmeden iman edenlere”", "“Ne mutlu bana salavat getirenlere”"]',
   2, '“…‘Ne mutlu beni görmeden iman edenlere’ diyerek müjdelediğin kardeşlerin olmanın huzur ve mutluluğunu yaşıyoruz.” (İbn Hanbel, III, 155)'),
  (2, 'Hutbede aktarılan hadise göre “Her dinin kendine özgü bir ahlakı vardır; İslam ahlakının özü …dır.” Boşluğa ne gelir?',
   '["Hayâ", "Doğruluk", "Merhamet", "Adalet"]',
   0, '“Her dinin kendine özgü bir ahlakı vardır; İslam ahlakının özü hayâdır.” (İbn Mâce, Zühd, 17)'),
  (3, 'Hutbeye göre Peygamberimiz (s.a.s), toplumsal huzur ve barışı sağlamanın yöntemini hangi sözüyle öğretmiştir?',
   '["“İman etmedikçe cennete giremezsiniz. Birbirinizi sevmedikçe de gerçek manada iman etmiş olmazsınız”", "“Doğruluktan ayrılmayın. Çünkü doğruluk iyiliğe, iyilik de cennete götürür…”", "“Allah sizin suretlerinize ve mallarınıza bakmaz, ancak kalplerinize ve amellerinize bakar”", "“Birbirinizden nefret etmeyin, birbirinize haset etmeyin, birbirinize sırt çevirmeyin. Ey Allah’ın kulları, kardeş olun”"]',
   3, '“Toplumsal huzur ve barışı sağlamanın yöntemini ise, ‘Birbirinizden nefret etmeyin… Ey Allah’ın kulları, kardeş olun’ uyarısıyla bizlere öğretmiştir.” (Buhârî, Edeb, 62) “İman etmedikçe…” sözü hutbede iman ile ahlakın ayrılmazlığı için anıldı.'),
  (4, 'Hutbeye göre Peygamberimiz (s.a.s), komşumuz açken ne yapmaktan bizleri nehyetmektedir?',
   '["Sofrada israf etmekten", "Tok olarak uyumaktan", "Yemeğimizin kokusuyla onu incitmekten", "Kapımızı ona kapatmaktan"]',
   1, '“…komşumuz açken tok olarak uyumaktan bizleri nehyetmektedir.” (İbn Ebû Şeybe, Musannef, Îmân ve rü’yâ, 6)'),
  (5, 'Hutbede bugün hepimizi derinden etkileyen anlayış tarif edilirken hangisi sayılmamıştır?',
   '["Maddeyi önceleyip manayı öteleyen", "Görünür olmayı yegâne hedef hâline getiren", "Hızı derinliğe tercih eden", "Yalanı hakikate tercih eden"]',
   2, '“Bugün; maddeyi önceleyip manayı öteleyen, görünür olmayı yegâne hedef hâline getiren, fâni olanı bâkiye, yalanı hakikate tercih eden anlayış, hepimizi derinden etkilemektedir.” Hız ve derinlik geçmiyor.')
) as v(sira, metin, secenekler, dogru_idx, aciklama)
on conflict (hutbe_id, sira) do update set
  metin = excluded.metin, secenekler = excluded.secenekler,
  dogru_idx = excluded.dogru_idx, aciklama = excluded.aciklama;

-- 11.09.2026 · EĞITIM VE ÖĞRETIM
with h as (
  insert into hutbeler (tarih, baslik, korpus_hutbe_id)
  values ('2026-09-11', 'Eğitim ve Öğretim', '11.09.2026')
  on conflict (tarih) do update set baslik = excluded.baslik
  returning id
)
insert into sorular (hutbe_id, sira, metin, secenekler, dogru_idx, tur, aciklama)
select h.id, v.sira, v.metin, v.secenekler::jsonb, v.dogru_idx, 'kavrayis', v.aciklama
from h, (values
  (1, 'Hutbeye göre eğitimin temeli hangi anlayış olmalıdır?',
   '["Başarılı bir meslek sahibi yetiştirme anlayışı", "Rekabet gücü yüksek bireyler yetiştirme anlayışı", "Milli ve manevi değerlerine bağlı iyi bir insan yetiştirme anlayışı", "Güçlü liderler yetiştirme anlayışı"]',
   2, '“Yaratana kulluk etmeyi ve yaratılana merhamet göstermeyi kendisine düstur edinen, milli ve manevi değerlerine bağlı iyi bir insan yetiştirme anlayışı, eğitimin temeli olmalıdır.”'),
  (2, 'Hutbede “eğitimden maksat” olarak sayılanlar arasında hangisi yoktur?',
   '["Bütün insanlık için umut olan bir nesil yetiştirmek", "Güzel ahlakı temsil eden bir toplum inşa etmek", "Ülkemizin bilimde ve teknolojide söz sahibi olmasına katkı sunmak", "Gençlerin iyi bir meslek sahibi olmasını sağlamak"]',
   3, 'Hutbe üç kez “Eğitimden maksat…” diyor: umut olan bir nesil yetiştirmek, güzel ahlakı temsil eden bir toplum inşa etmek, ülkemizin bilimde, teknolojide, sanatta söz sahibi olmasına katkı sunmak. Meslek sahibi olmak sayılmıyor.'),
  (3, 'Hutbeye göre iyi bir eğitim için öncelikle ne yapmak zorundayız?',
   '["Evlatlarımızı iyi tanımak", "Onlara iyi bir örnek olmak", "Okullarımızı iyi donatmak", "Öğretmenlerimize destek olmak"]',
   0, '“Bu bakımdan, iyi bir eğitim için, öncelikle evlatlarımızı iyi tanımak zorundayız.”'),
  (4, 'Hutbeye göre ebedi bir âlemin varlığına inananlar için asıl başarı nedir?',
   '["Dünyada hayırlı bir iz bırakmak", "Rızâ-yı ilahiye ulaşmak", "İlimde derinleşmek", "Hayırlı bir evlat yetiştirmek"]',
   1, '“Unutmayalım ki, ebedi bir âlemin varlığına inananlar için asıl başarı, rızâ-yı ilahiye ulaşmaktır.”'),
  (5, 'Hutbenin bitirildiği hadis-i şerife göre “Kim ilim için yola çıkarsa, Allah ona …” Nasıl devam eder?',
   '["…hayır kapılarını açar", "…hikmet kapılarını açar", "…dünya ve ahiret saadeti verir", "…cennete giden yolu kolaylaştırır"]',
   3, '“Kim ilim için yola çıkarsa, Allah ona cennete giden yolu kolaylaştırır...” (Tirmizî, İlim, 19)')
) as v(sira, metin, secenekler, dogru_idx, aciklama)
on conflict (hutbe_id, sira) do update set
  metin = excluded.metin, secenekler = excluded.secenekler,
  dogru_idx = excluded.dogru_idx, aciklama = excluded.aciklama;

-- 18.09.2026 · AHÎLIK AHLAKI
with h as (
  insert into hutbeler (tarih, baslik, korpus_hutbe_id)
  values ('2026-09-18', 'Ahîlik Ahlakı', '18.09.2026')
  on conflict (tarih) do update set baslik = excluded.baslik
  returning id
)
insert into sorular (hutbe_id, sira, metin, secenekler, dogru_idx, tur, aciklama)
select h.id, v.sira, v.metin, v.secenekler::jsonb, v.dogru_idx, 'kavrayis', v.aciklama
from h, (values
  (1, 'Hutbeye göre Ahîlik teşkilatı kimler arasında kardeşlik köprüsü kurmuştur?',
   '["Usta ile çırak", "Zengin ile fakir", "Şehirli ile köylü", "Esnaf ile müşteri"]',
   3, '“Bu teşkilat ile ticaret, zanaat ve ustalığı; ahlak, kanaat ve hayırlı insan yetiştirme anlayışıyla bir araya getirmiş, esnaf ve müşteri arasında kardeşlik köprüsü kurmuştur.”'),
  (2, 'Hutbeye göre Ahîliğin kurduğu bu kardeşlik köprüsü neye zemin hazırlamıştır?',
   '["Nice beldenin kılıçsız fethedilmesine", "Loncaların kurulmasına", "Anadolu’nun yurt edinilmesine", "Vakıf medeniyetinin doğmasına"]',
   0, '“…kurduğu bu kardeşlik köprüsü öyle bir hal almıştır ki; nice insanın İslam’la şereflenmesine ve nice beldenin kılıçsız fethedilmesine zemin hazırlamıştır.”'),
  (3, 'Hutbeye göre kimi insanımız, dünyalık kazanç uğruna gerçeği çarpıtmayı ne olarak sayabiliyor?',
   '["Ticari zekâ", "Rekabet gereği", "Pazarlama tekniği", "Piyasa kuralı"]',
   2, '“…dünyalık kazanç uğruna malının kusurunu gizlemeyi ustalık, gerçeği çarpıtmayı ise pazarlama tekniği sayabiliyor.”'),
  (4, 'Hutbede esnaftan uzak durması beklenen gayr-ı meşru yollar arasında hangisi sayılmamıştır?',
   '["Rüşvet", "Karaborsacılık", "Stokçuluk", "Fahiş fiyatla satış"]',
   3, '“Bizlerden beklenen, dinimizce haram görülen şeylerin ticaretini yapmaktan; rüşvet, faiz, karaborsacılık ve stokçuluk gibi gayr-ı meşru yollardan uzak durmaktır.”'),
  (5, 'Hutbenin bitirildiği duaya göre Allah, satarken, satın alırken ve alacağını talep ederken nasıl davranan kimseye rahmetiyle muamele etsin?',
   '["Dürüst davranıp doğruyu söyleyen", "Hoşgörülü davranıp kolaylık gösteren", "Ölçüyü tam tutup hakkı gözeten", "Sözünde durup emaneti koruyan"]',
   1, '“Satarken, satın alırken, alacağını talep ederken hoşgörülü davranıp kolaylık gösteren kimseye Allah rahmetiyle muamele eylesin.” (Buhârî, Büyû’, 16)')
) as v(sira, metin, secenekler, dogru_idx, aciklama)
on conflict (hutbe_id, sira) do update set
  metin = excluded.metin, secenekler = excluded.secenekler,
  dogru_idx = excluded.dogru_idx, aciklama = excluded.aciklama;

-- 25.09.2026 · TEBLIĞ SORUMLULUĞUMUZ
with h as (
  insert into hutbeler (tarih, baslik, korpus_hutbe_id)
  values ('2026-09-25', 'Tebliğ Sorumluluğumuz', '25.09.2026')
  on conflict (tarih) do update set baslik = excluded.baslik
  returning id
)
insert into sorular (hutbe_id, sira, metin, secenekler, dogru_idx, tur, aciklama)
select h.id, v.sira, v.metin, v.secenekler::jsonb, v.dogru_idx, 'kavrayis', v.aciklama
from h, (values
  (1, 'Hutbeye göre Mus‘ab b. Umeyr’in Medine’deki tebliğinin sonucunda bir yıl içinde ne olmuştur?',
   '["Medinelilerin tamamı Müslüman olmuştur", "Medine’de ilk mescit inşa edilmiştir", "Medine’de Efendimiz’den bahsedilmeyen hiçbir ev kalmamıştır", "Medine’deki kabileler arasındaki savaşlar sona ermiştir"]',
   2, '“Öyle ki, bir yıl içerisinde Medine’de Efendimiz (s.a.s)’den bahsedilmeyen hiçbir ev kalmadı.” (İbn Hişâm, Sîret, II, 278)'),
  (2, 'Hutbeye göre genç Mus‘ab’ı kısa bir sürede bu denli başarılı kılan neydi?',
   '["Peygamberimizin güzel ahlakını kendisine rehber edinmesi", "Kur’an’ı ezbere bilmesi", "Etkili bir hitabete sahip olması", "Medine’nin ileri gelenlerini ikna etmesi"]',
   0, '“Genç Mus‘ab’ı kısa bir sürede bu denli başarılı kılan, Resûl-i Ekrem (s.a.s)’in güzel ahlakını kendisine rehber edinmesiydi.”'),
  (3, 'Hutbede “nebevî daveti kuşanmış” olarak sayılanlar arasında hangisi yoktur?',
   '["Müşterisine güven veren her esnaf", "Öğrencilerinin hayatında olumlu izler bırakan her öğretmen", "Komşusuyla iyi geçinen her insan", "Hastasına şefkat gösteren her doktor"]',
   3, '“…çocuğunun iki cihan saadeti için koşuşturan her anne ve baba, öğrencilerinin hayatında olumlu izler bırakmak için gayret gösteren her öğretmen, müşterisine güven veren her esnaf, akrabalık bağlarını gözeten ve komşusuyla iyi geçinen her insan nebevî daveti kuşanmış demektir.” Doktor sayılmıyor.'),
  (4, 'Hutbeye göre sosyal mecralarda bir başkasının hayatına dair yorum yapmadan önce neye özen gösterilmelidir?',
   '["Doğruluğuna", "Mahremiyetine", "Kaynağına", "Üslubuna"]',
   1, '“Bir sözü paylaşmadan önce doğruluğuna, bir başkasının hayatına dair yorum yapmadan önce ise mahremiyetine özen göstermelidir.”'),
  (5, 'Hutbenin bitirildiği hadis-i şerife göre “Allah, bizden bir söz işitip, onu işittiği gibi başkasına ulaştıran kişinin …” Nasıl devam eder?',
   '["…ilmini artırsın", "…derecesini yükseltsin", "…yüzünü ak etsin", "…günahlarını bağışlasın"]',
   2, '“Allah, bizden bir söz işitip, onu işittiği gibi başkasına ulaştıran kişinin yüzünü ak etsin.” (Dârimî, Mukaddime, 24)')
) as v(sira, metin, secenekler, dogru_idx, aciklama)
on conflict (hutbe_id, sira) do update set
  metin = excluded.metin, secenekler = excluded.secenekler,
  dogru_idx = excluded.dogru_idx, aciklama = excluded.aciklama;

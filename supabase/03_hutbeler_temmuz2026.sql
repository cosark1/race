-- 03 — 24.07.2026 ve 31.07.2026 hutbeleri + soruları
--
-- Kaynak: Diyanet İşleri Başkanlığı Din Hizmetleri Genel Müdürlüğü hutbe PDF'leri.
-- Sorular quiz_plani.md §4'e göre yazıldı:
--   1) Genel dini bilgiyle cevaplanamaz — yalnızca bu hutbeyi dinleyen bilir
--   2) Ezber değil kavrayış arar
-- Soru sırası hutbenin kendi anlatım sırasıyla aynı (§2.2 — hatip konuya geldikçe cevap yakalanır).
--
-- Tekrar çalıştırılabilir: aynı tarihli hutbe varsa hiçbir şey eklenmez.

-- ═══════════════ 24.07.2026 · İSLAM MEDENİYETİ ═══════════════
with h as (
  insert into hutbeler (tarih, baslik, korpus_hutbe_id)
  values ('2026-07-24', 'İslam Medeniyeti', '24.07.2026')
  on conflict (tarih) do nothing
  returning id
)
insert into sorular (hutbe_id, sira, metin, secenekler, dogru_idx, tur, aciklama)
select h.id, v.sira, v.metin, v.secenekler::jsonb, v.dogru_idx, 'kavrayis', v.aciklama
from h, (values
  (1, 'Hutbenin başında okunan Hûd sûresi âyetinde insana verilen sorumluluk neydi?',
   '["Kavimleri birbirine karşı uyarmak","Yeryüzünü imar etmek","Malını ihtiyaç sahipleriyle paylaşmak","Kendi neslini çoğaltmak"]',
   1, '"Sizi topraktan yaratan ve yeryüzünü imar etme sorumluluğunu size veren O''dur." (Hûd 11/61) — hutbenin tamamı bu sorumluluk üzerine kuruldu.'),

  (2, 'Hutbeye göre "medeniyet" nedir?',
   '["İleri teknolojiye ulaşmış toplumların ortak adı","Şehirlerin büyüklüğüyle ölçülen bir gelişmişlik düzeyi","Maddi eserlerle birlikte manevi değerleri de yaşatan anlayış","Geçmişin eserlerini olduğu gibi koruma çabası"]',
   2, '"İşte medeniyet, maddi eserlerle birlikte manevi değerleri de yaşatan bu anlayışın adıdır." — sadece bina değil, ahlak ve faziletin korunduğu hayat.'),

  (3, 'Hutbede İslam medeniyetinin neleri buluşturarak yükseldiği söylendi?',
   '["İlmi ibadetle, çalışmayı dürüstlükle, gücü adaletle, zenginliği paylaşmayla","Orduyu ticaretle, sanatı siyasetle","Doğuyu batıyla, geçmişi gelecekle","Bireyi devletle, köyü şehirle"]',
   0, 'Dört ikili de hutbede aynen sayıldı; camiler, vakıflar ve kütüphaneler bu anlayışın simgeleri olarak anıldı.'),

  (4, 'Hutbeye göre İslam medeniyetinin temel gayesi nedir?',
   '["Toprakları genişletmek ve gücü artırmak","Kalpleri kazanmak, gönülleri aynı inanç ve idealde buluşturmak","Bilimsel keşiflerde öncü olmak","Kendi kültürünü diğerlerinden korumak"]',
   1, '"İslam medeniyetinin temel gayesi; kalpleri kazanmak, zihinleri ve gönülleri aynı inanç, duygu ve idealde buluşturabilmektir."'),

  (5, 'Hutbede o güne özel hangi olaya işaret edildi?',
   '["Ramazan ayının başlaması","Bir peygamber kıssasının yıl dönümü","Ayasofya-i Kebir Camii''nin yeniden cemaatiyle buluşması","Yeni bir caminin temelinin atılması"]',
   2, '"Bugün, İstanbul''un fethinin nişanesi ve ecdadımızın kıymetli emaneti Ayasofya-i Kebir Camii Şerifi''nin yeniden cemaatiyle buluştuğu gündür."')
) as v(sira, metin, secenekler, dogru_idx, aciklama);


-- ═══════════════ 31.07.2026 · HELAL HARAM DUYARLILIĞI ═══════════════
with h as (
  insert into hutbeler (tarih, baslik, korpus_hutbe_id)
  values ('2026-07-31', 'Helal Haram Duyarlılığı', '31.07.2026')
  on conflict (tarih) do nothing
  returning id
)
insert into sorular (hutbe_id, sira, metin, secenekler, dogru_idx, tur, aciklama)
select h.id, v.sira, v.metin, v.secenekler::jsonb, v.dogru_idx, 'kavrayis', v.aciklama
from h, (values
  (1, 'Hutbede helaller ve haramlar nasıl tanımlandı?',
   '["Kulu Allah''ın rızasına kavuşturan ilahi ölçüler","Toplumun geleneğiyle şekillenen kurallar","Yalnızca ibadetlerin geçerliliğini belirleyen şartlar","Her çağda yeniden belirlenen esnek sınırlar"]',
   0, '"Helaller ve haramlar; kulu, Allah''ın rızasına kavuşturan ilahi ölçülerdir. Kişiye, hayat yolculuğunda iyi ile kötüyü gösteren kılavuzlardır."'),

  (2, 'Hutbeye göre dinin emir ve yasakları hangi hikmetleri barındırır?',
   '["Kişinin dünyada zenginleşmesini sağlamak","İbadetlerin sayısını artırmak","İnsanın haysiyetini, nesillerin emniyetini ve toplumun huzurunu korumak","İnananları diğer toplumlardan ayırmak"]',
   2, 'Hutbede bu üçlü aynen sayıldı ve evlilik/zina ile ticaret/faiz örnekleriyle somutlaştırıldı.'),

  (3, 'Hutbenin özellikle vurguladığı nokta: helal haram duyarlılığı neyle <u>sınırlı değildir</u>?',
   '["Alışverişte fiyatın adil olmasıyla","Namaz vakitlerine riayet etmekle","Zekâtın doğru hesaplanmasıyla","Sofraya konulan lokmanın temiz olmasıyla"]',
   3, '"Helal haram duyarlılığı, sofraya konulan lokmanın temiz olmasıyla sınırlı değildir." — ardından iffet, hayâ, giyim kuşam ve dijital mahremiyet anlatıldı.'),

  (4, 'Hutbede israf hangi yönüyle ele alındı?',
   '["Yalnızca ekonomik bir kayıp olarak","Paylaşma duygusunu yok eden, adil paylaşımın önündeki en büyük engel olarak","Zenginlere mahsus bir kusur olarak","Modern hayatın kaçınılmaz bir sonucu olarak"]',
   1, 'Somut örnekler: ülkemizde tonlarca ekmeğin çöpe atılması ve suların sorumsuzca sarf edilmesi.'),

  (5, 'Hutbe hangi ilahi çağrıyla bitirildi?',
   '["Yeryüzündeki helâl ve temiz şeylerden yiyin, şeytanın peşinden gitmeyin","Sabredenlerin mükâfatı hesapsız verilecektir","Namazı dosdoğru kılın, zekâtı verin","İnsanlar arasında adaletle hükmedin"]',
   0, '"Ey insanlar! Yeryüzündeki helâl ve temiz olan şeylerden yiyin; şeytanın peşinden gitmeyin, çünkü o apaçık düşmanınızdır." (Bakara 2/168)')
) as v(sira, metin, secenekler, dogru_idx, aciklama);

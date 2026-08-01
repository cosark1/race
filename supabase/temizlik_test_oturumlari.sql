-- Yayına geçmeden önce çalıştır: geliştirme/test sırasında oluşan sahte oturumları siler.
-- Gerçek katılımcı verisi başladıktan SONRA çalıştırma — geri dönüşü yok.
--
-- Hutbe/soru/ilçe/vakit verisine dokunmaz; yalnızca oturum ve cevapları temizler.

delete from cevaplar;
delete from soru_acilislar;
delete from oturumlar;

-- Kontrol
select
  (select count(*) from oturumlar) as oturum,
  (select count(*) from cevaplar)  as cevap,
  (select count(*) from hutbeler)  as hutbe,
  (select count(*) from sorular)   as soru,
  (select count(*) from ilceler)   as ilce,
  (select count(*) from vakitler)  as vakit;

-- schema.sql'i yeniden baştan çalıştırmadan önce kullan: "relation already exists" hatası
-- alırsan (daha önce bir kez çalıştırılmış demektir) önce bunu çalıştır, sonra schema.sql'i tekrar çalıştır.
-- CASCADE ile bağımlı view/fonksiyon/foreign key'ler de birlikte temizlenir.

drop function if exists kisisel_gecmis cascade;
drop function if exists turkiye_siralama cascade;
drop function if exists il_siralama cascade;
drop function if exists ilce_siralama cascade;
drop function if exists soru_cevapla cascade;
drop function if exists soru_ac cascade;
drop function if exists oturum_baslat cascade;
drop function if exists quiz_durumu cascade;

drop view if exists sorular_public cascade;
drop view if exists v_oturum_puan cascade;

drop table if exists cevaplar cascade;
drop table if exists soru_acilislar cascade;
drop table if exists oturumlar cascade;
drop table if exists sorular cascade;
drop table if exists hutbeler cascade;
drop table if exists vakitler cascade;
drop table if exists ilceler cascade;
drop table if exists iller cascade;

-- "Automatically expose new tables" kapatıldığında service_role'ün varsayılan erişimi de
-- gitmiş olabiliyor (yalnızca anon değil). service_role RLS'i zaten bypass eder, ama GRANT
-- olmadan sorguya bile giremiyor — vakit_guncelle.py'nin "permission denied for table ilceler"
-- hatası buradan geliyordu. Bunu bir kez çalıştırmak yeterli.

grant usage on schema public to service_role;
grant select, insert, update, delete on
  iller, ilceler, vakitler, hutbeler, sorular, oturumlar, soru_acilislar, cevaplar
  to service_role;
grant select on sorular_public, v_oturum_puan to service_role;

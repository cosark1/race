-- 04 — Yönetim paneli yetkileri (quiz/admin.html)
--
-- Şu ana kadar hutbe/soru ekleme yalnızca SQL Editor'dan elle yapılıyordu — mobilde
-- kullanılamaz. Bu dosya, tek bir yönetici e-postasına hutbeler/sorular tablolarında
-- yazma izni veriyor; RLS düzeyinde kilitli, anon kullanıcılar hâlâ hiçbir şey yazamaz.
--
-- ADIM 1 — Supabase panelinden kendi giriş bilgini oluştur (bunu SENİN yapman gerekiyor,
-- kimlik/parola oluşturma benim yapabileceğim bir işlem değil):
--   Authentication → Users → Add user → kendi e-postan + şifre (Auto Confirm User işaretli)
--
-- ADIM 2 — Aşağıdaki 'SENIN-EMAILIN@ornek.com' yazan İKİ satırı kendi e-postanla değiştirip
-- SQL Editor'da çalıştır.

alter table hutbeler enable row level security;  -- zaten açık, idempotent
alter table sorular enable row level security;

-- Yönetici, sorular tablosunu (dogru_idx dahil) TAM görebilir — anon bunu göremiyordu,
-- yalnızca sorular_public view'ını görüyordu (bkz. schema.sql §3).
create policy "yonetici_sorular_select" on sorular for select
  to authenticated
  using (auth.jwt() ->> 'email' = 'SENIN-EMAILIN@ornek.com');

create policy "yonetici_hutbe_yaz" on hutbeler for all
  to authenticated
  using (auth.jwt() ->> 'email' = 'SENIN-EMAILIN@ornek.com')
  with check (auth.jwt() ->> 'email' = 'SENIN-EMAILIN@ornek.com');

create policy "yonetici_sorular_yaz" on sorular for all
  to authenticated
  using (auth.jwt() ->> 'email' = 'SENIN-EMAILIN@ornek.com')
  with check (auth.jwt() ->> 'email' = 'SENIN-EMAILIN@ornek.com');

grant select, insert, update, delete on hutbeler, sorular to authenticated;

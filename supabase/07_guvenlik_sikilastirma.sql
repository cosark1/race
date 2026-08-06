-- 07 — Supabase Security Advisor bulgularının giderilmesi
--
-- Advisor raporu: 1 Critical + 26 Warning + 4 Info. Aşağıda her biri tek tek değerlendirildi;
-- çoğu KASITLI tasarımdı (yanlış pozitif), ikisi gerçek düzeltme gerektiriyordu.
--
-- ─────────────────────────────────────────────────────────────
-- 1) CRITICAL: "Security Definer View — sorular_public"
-- ─────────────────────────────────────────────────────────────
-- Sebep: Postgres'te normal bir view, sorgulayanın değil VIEW SAHİBİNİN yetkisiyle çalışır.
-- sorular_public tam olarak bunu kasıtlı kullanıyordu: sorular tablosunda anon'un HİÇ select
-- yetkisi yok (dogru_idx sızmasın diye — §3), view bu kısıtı bilerek "atlayıp" yalnızca güvenli
-- sütunları (dogru_idx VE aciklama HARİÇ) gösteriyordu. Yani view'ın kendisi güvenlik açığı
-- değil, güvenlik ÖNLEMİYDİ — ama Advisor bunu bir view olarak genel bir örüntüyle
-- (RLS atlatma) eşleştirdiği için "critical" işaretliyor.
--
-- Düzeltme: view'ı, kod tabanındaki diğer 12 fonksiyonla AYNI örüntüye (açıkça SECURITY
-- DEFINER işaretli fonksiyon) çeviriyoruz. Davranış birebir aynı kalıyor, yalnızca Advisor'ın
-- "gizli/örtük" bulduğu view yerine "açık/beyan edilmiş" fonksiyon kullanılıyor.
drop view if exists sorular_public;

create or replace function sorular_public(p_hutbe_id uuid)
returns table(id uuid, hutbe_id uuid, sira smallint, metin text, secenekler jsonb, sure_sn smallint)
language sql stable
security definer
set search_path = public
as $$
  select id, hutbe_id, sira, metin, secenekler, sure_sn
  from sorular
  where hutbe_id = p_hutbe_id
  order by sira;
$$;

revoke execute on function sorular_public(uuid) from public;
grant execute on function sorular_public(uuid) to anon;

-- İstemci tarafı (quiz/index.html) artık .from('sorular_public') yerine
-- .rpc('sorular_public', {p_hutbe_id}) çağırıyor — bu dosyayla birlikte deploy edildi.

-- ─────────────────────────────────────────────────────────────
-- 2) 26 WARNING: "13 fonksiyon hem anon hem authenticated tarafından çalıştırılabilir"
-- ─────────────────────────────────────────────────────────────
-- Bunlardan 12'si BİZİM fonksiyonumuz, hepsi bilerek anon-çağrılabilir (oyunun arka ucu bu
-- RPC'lerle çalışıyor). "authenticated" tarafından da çalıştırılabilir olması bizim isteğimiz
-- DEĞİLDİ — Postgres'te yeni bir fonksiyon oluşturulduğunda varsayılan olarak EXECUTE yetkisi
-- PUBLIC'e (yani her role, anon+authenticated+gelecekte eklenecek her rol dahil) verilir,
-- biz de bugüne kadar hiçbir yerde bunu REVOKE etmemiştik. Gerçek bir yetki genişlemesi
-- yaratmıyordu (bu fonksiyonların hepsi zaten anon için güvenli tasarlandı) ama gereksiz/
-- amaçsız bir genişlikti. Şimdi açıkça kapatılıyor: PUBLIC'ten alınıp yalnızca anon'a veriliyor.
--
-- 13'üncü isim olan rls_auto_enable BİZİM DEĞİL — Supabase projesinin kendi "Enable automatic
-- RLS" ayarının (yeni tablolarda RLS'i otomatik açan event trigger) sistem fonksiyonu.
-- Bu dosyada dokunulmuyor.

revoke execute on function quiz_durumu(uuid) from public;
revoke execute on function oturum_baslat(text, uuid, uuid, text) from public;
revoke execute on function soru_ac(uuid, uuid) from public;
revoke execute on function soru_cevapla(uuid, uuid, smallint) from public;
revoke execute on function ilce_siralama(uuid, uuid, int) from public;
revoke execute on function il_siralama(uuid, smallint) from public;
revoke execute on function kisisel_gecmis(text) from public;
revoke execute on function hafta_durumu() from public;
revoke execute on function alistirma_sorulari(uuid) from public;
revoke execute on function sonraki_kahutbe(uuid) from public;
revoke execute on function turkiye_siralama(uuid, int) from public;
revoke execute on function oturum_sirasi(uuid) from public;

grant execute on function
  quiz_durumu(uuid), oturum_baslat(text, uuid, uuid, text), soru_ac(uuid, uuid),
  soru_cevapla(uuid, uuid, smallint), ilce_siralama(uuid, uuid, int), il_siralama(uuid, smallint),
  kisisel_gecmis(text), hafta_durumu(), alistirma_sorulari(uuid), sonraki_kahutbe(uuid),
  turkiye_siralama(uuid, int), oturum_sirasi(uuid)
  to anon;

-- ─────────────────────────────────────────────────────────────
-- 3) INFO: "RLS Enabled No Policy" — cevaplar, oturumlar, soru_acilislar, sorular
-- ─────────────────────────────────────────────────────────────
-- cevaplar / oturumlar / soru_acilislar İÇİN KASITLI: bu üç tabloya doğrudan erişimin
-- OLMAMASI tasarımın kendisi (§9.2) — yalnızca SECURITY DEFINER fonksiyonlar (postgres
-- sahipliğinde, BYPASSRLS) üzerinden yazılıp okunuyorlar. "Policy yok" burada "erişim yok"
-- demek, düzeltilecek bir eksiklik değil.
--
-- sorular İÇİN FARKLI: bu tabloda aslında policy VAR — ama 04_yonetim_yetkileri.sql'i henüz
-- çalıştırmadıysan (ya da içindeki SENIN-EMAILIN@ornek.com yer tutucusunu kendi e-postanla
-- değiştirmediysen) Advisor bunu göremez/işlemez görünür. Bu dosyayı çalıştırdıktan sonra
-- hâlâ "no policy" diyorsa, 04_yonetim_yetkileri.sql'i (kendi e-postanla) çalıştırıp
-- çalıştırmadığını kontrol et.

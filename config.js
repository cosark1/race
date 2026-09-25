// Supabase proje bağlantı bilgileri — proje oluşturduktan sonra Settings → API'den kopyala.
// anon key GİZLİ DEĞİLDİR (public/anon anahtar) — RLS + RPC tasarımı zaten bunu varsayar (bkz. supabase/schema.sql §5).
window.HQ_CONFIG = {
  url: 'https://anoaivodvwymwnoajynq.supabase.co',
  anonKey: 'sb_publishable_U512scNskGmyGWPB4qF1Wg_D-tZfWe-',
};
// Yayındaki sitede Supabase'e doğrudan değil, sitenin kendi /sb/ yolundan (worker.js) gidilir:
// bazı ağlarda *.supabase.co'ya ulaşılamıyor. Yerel önizlemede worker yok → doğrudan adres.
// (Yukarıdaki `url:` satırı olduğu gibi kalmalı — site/pipeline/10_haftalik_senkron.py onu okur.)
if (/(^|\.)kahutbe\.com$|\.workers\.dev$/.test(location.hostname)) {
  window.HQ_CONFIG.url = location.origin + '/sb/';
}

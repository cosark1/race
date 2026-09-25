// Kahutbe Cloudflare Worker — statik dosyalar + Supabase aracı (/sb/*).
//
// NEDEN ARACI: bazı ağlarda (mobil operatör DNS'i, 25.09.2026'da proje duraklatılmışken
// önbelleğe alınmış "alan adı yok" cevabı vb.) *.supabase.co adresine ulaşılamıyor, sayfa
// açıldığı hâlde "Bağlantı hatası" veriyordu. Tarayıcı artık yalnızca kahutbe.com ile
// konuşuyor; kahutbe.com açılıyorsa veri de geliyor. Yalnızca REST (quiz) ve Auth (yönetim
// paneli girişi) yolları geçirilir — açık bir vekil sunucu değil.
const SUPABASE = 'https://anoaivodvwymwnoajynq.supabase.co';
const IZINLI = ['/sb/rest/v1/', '/sb/auth/v1/'];

export default {
  async fetch(istek, env) {
    const u = new URL(istek.url);
    if (u.pathname.startsWith('/sb/')) {
      if (!IZINLI.some(p => u.pathname.startsWith(p))) return new Response('Bulunamadı', { status: 404 });
      const basliklar = new Headers(istek.headers);
      basliklar.delete('cookie');
      basliklar.delete('host');
      return fetch(SUPABASE + u.pathname.slice(3) + u.search, {
        method: istek.method,
        headers: basliklar,
        // Gövde bir kez okunup iletilir (istekler küçük; akış iletimi ortamlar arası farklı davranıyor)
        body: ['GET', 'HEAD'].includes(istek.method) ? undefined : await istek.arrayBuffer(),
      });
    }
    return env.ASSETS.fetch(istek);
  },
};

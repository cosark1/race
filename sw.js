// Kahutbe service worker — YALNIZCA kurulabilirlik (Android "ana ekrana ekle" istemi
// tarayıcıdan bir service worker ister) ve minimal çevrimdışı yedek için.
//
// KRİTİK KURAL: bu proje daha önce (ana hutbe sitesinde) bayat önbellek yüzünden ciddi
// bir hata yaşadı (bkz. feedback_yerel_sunucu_onbellek.md) — bir service worker'ın "bayat
// içerik" hatasını YENİDEN üretmemesi için index.html DAİMA önce ağdan denenir (network-first).
// Önbellek yalnızca çevrimdışıyken devreye girer. Supabase istekleri hiç önbelleklenmez —
// quiz açık/kapalı durumu ve puanlama her zaman canlı olmalı.

const CACHE = 'kahutbe-v1';
const KABUK = ['/', '/index.html', '/manifest.json', '/config.js',
  '/icons/icon-192.png', '/icons/icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(KABUK)));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(anahtarlar =>
      Promise.all(anahtarlar.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);

  // Supabase (ve her türlü çapraz-origin) isteği asla önbelleklenmez — canlı veri.
  if (url.origin !== self.location.origin) return;
  if (e.request.method !== 'GET') return;

  e.respondWith(
    fetch(e.request)
      .then(yanit => {
        const kopya = yanit.clone();
        caches.open(CACHE).then(c => c.put(e.request, kopya));
        return yanit;
      })
      .catch(() => caches.match(e.request))
  );
});

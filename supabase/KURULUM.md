# Faz 1 kurulumu — Supabase

Bu adımların tamamı senin yapman gereken kısım (hesap oluşturma/API anahtarı işlemleri asistan
tarafından yapılamıyor). ~10 dakika sürer.

## 1. Proje oluştur

1. [supabase.com](https://supabase.com) → **Start your project** → GitHub/e-posta ile ücretsiz hesap aç.
2. **New project** → bir isim ver (ör. `hutbe-quiz`), bölge olarak Frankfurt/EU seç (Türkiye'ye en yakın), şifre oluştur.
3. Proje birkaç dakikada hazırlanır.

## 2. Şemayı kur

Proje panelinde sol menüden **SQL Editor** → **New query**:

1. [`schema.sql`](schema.sql) içeriğini yapıştır → **Run**.
2. [`seed_ilceler.sql`](seed_ilceler.sql) içeriğini yapıştır → **Run**. (869 ilçe, ~30 sn sürebilir.)
3. Test için: [`seed_hutbe_ornek.sql`](seed_hutbe_ornek.sql) içeriğini yapıştır → **Run**.
   Bu, 22.05.2026 hutbesini ve Faz 0'daki 5 soruyu ekler.

> **"relation ... already exists" hatası alırsan:** `schema.sql` daha önce (tam ya da kısmen)
> çalıştırılmış demektir. Önce [`reset.sql`](reset.sql)'i çalıştırıp tüm tabloları/view'ları/
> fonksiyonları temizle, sonra 1'den itibaren tekrar başla.

## 3. Bağlantı bilgilerini al

Sol menüden **Settings → API**:

- **Project URL** → `https://xxxxx.supabase.co`
- **anon / public** anahtarı (⚠️ `service_role` anahtarını DEĞİL — o yalnızca `vakit_guncelle.py` gibi
  sunucu-taraflı scriptlerde kullanılır, tarayıcıya asla konmaz)

Bu ikisini [`../config.js`](../config.js) dosyasına yapıştır:

```js
window.HQ_CONFIG = {
  url: 'https://xxxxx.supabase.co',
  anonKey: 'eyJ...',
};
```

## 4. Test et

`quiz/index.html`'i (ör. `python quiz/serve.py 8091` ile) aç. Kurulum eksikse sayfa bunu söyler;
doğruysa giriş ekranı gerçek verilerle (972 ilçe arama/konum, gerçek hutbe başlığı) çalışır.

Bugün Cuma değilse veya öğle vakti geçmediyse quiz normalde "henüz açılmadı" der — test için
adrese `?test=1` ekle (`http://localhost:8091/?test=1`): bu, açık/kapalı kontrolünü atlar ama
gerçek Supabase oturumu ve puanlamayı kullanır. Sayfanın üstünde bir **TEST** şeridi görünür;
bu şerit `?test=1` olmadan görünmez.

## 5. Haftalık namaz vakti önbelleği

`vakitler` tablosu boş kaldığı sürece `quiz_durumu()` "henüz açılmadı" der (öğle vakti bilinmiyor).
Perşembe akşamları [`vakit_guncelle.py`](vakit_guncelle.py) çalıştırılmalı:

```bash
export SUPABASE_URL=https://xxxxx.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=eyJ...     # Settings → API → service_role (GİZLİ TUT)
python vakit_guncelle.py
```

Bunu haftalık otomatikleştirmenin iki yolu:
- **Basit:** Windows Görev Zamanlayıcı ile bilgisayarında Perşembe akşamı çalıştır.
- **Sunucusuz:** Supabase Edge Functions + `pg_cron` ile bulutta zamanla (Faz 2'ye ertelenebilir —
  v1 için elle/haftalık tek komut yeterli).

## 6. Gerçek hutbe + soru eklemek

Artık iki yol var:

**A) Yönetim paneli (mobilden de kullanılabilir) — [`admin.html`](../admin.html)**

1. Supabase panelinde **Authentication → Users → Add user** → kendi e-postan + bir şifre,
   **Auto Confirm User** işaretli. (Bunu senin yapman gerekiyor — kimlik/parola oluşturma
   benim yapabileceğim bir işlem değil.)
2. [`04_yonetim_yetkileri.sql`](04_yonetim_yetkileri.sql) içindeki **iki**
   `SENIN-EMAILIN@ornek.com` yerine kendi e-postanı yaz, SQL Editor'da çalıştır.
3. Telefonundan `admin.html`'i aç (ör. `https://kahutbe.kmrn06.workers.dev/admin.html` —
   gerçek Cloudflare adresin neyse), giriş yap. Hutbe ekle/düzenle, soruları tek tek kaydet.

`admin.html` `<meta name="robots" content="noindex, nofollow">` ile arama motorlarından
gizli ama **gizli bir URL değil** — güvenlik tamamen RLS'e dayanıyor (yalnızca kayıtlı
e-postan yazabiliyor), sayfanın kendisi herkese açık.

**B) SQL Editor (elle)**

`seed_hutbe_ornek.sql`'deki kalıba benzer şekilde SQL Editor'dan ekle. Her iki yolda da
`korpus_hutbe_id`, `site/data/metinler/{yıl}.json` dosyasındaki tarih anahtarıyla
(`"GG.AA.YYYY"`) birebir aynı olmalı.

## Sınırlar / bilinen boşluklar

- **Büyükşehir merkez ilçeleri paylaşımlı vakit kullanır.** Diyanet'in kendi vakit hiyerarşisi
  Kadıköy/Üsküdar/Beşiktaş, Çankaya/Keçiören/Yenimahalle, Konak/Bornova/Karşıyaka gibi merkez
  ilçeleri ayrı ayrı listelemiyor (eski büyükşehir-öncesi müftülük sınırları). `seed_ilceler.sql`
  bu 188 ilçeyi kendi il merkezinin Diyanet koduyla eşleştiriyor — namaz vakti bir il merkezinde
  birkaç saniyeden fazla değişmediği için bu doğruluğu etkilemez, yalnızca 188 ilçe kendi ayrı
  vakit kaydı yerine il merkeziyle **aynı** öğle vaktini paylaşır. Arama ve sıralama yine de gerçek
  ilçe düzeyinde (Kadıköy kendi başına aranabilir/sıralanabilir) — sadece vakit verisi paylaşımlı.
- Haftalık vakit önbelleği elle/zamanlanmış script ile — tam otomatik değil (Faz 2 kapsamı).
- Soru üretimi hâlâ elle SQL — editör paneli yok (Faz 3 kapsamı).

"""Haftalık namaz vakti önbelleği — quiz_plani.md §9 ("Diyanet vakit API'si, ilçe bazlı haftalık önbellek").

Her ilçe için ezanvakti.emushaf.net'ten (Diyanet verisini ayna olarak sunan topluluk API'si)
önümüzdeki Cuma'nın öğle vaktini çeker ve Supabase'deki `vakitler` tablosuna yazar.

Kullanım:
    export SUPABASE_URL=https://xxxx.supabase.co
    export SUPABASE_SERVICE_ROLE_KEY=xxxx   # service_role anahtarı — RLS'i atlar, yalnızca sunucuda kullan
    python vakit_guncelle.py

Haftada bir (örn. Perşembe gecesi) bir zamanlayıcıyla (Windows Görev Zamanlayıcı / cron /
Supabase Edge Function + pg_cron) çalıştırılması yeterlidir; sonraki Cuma için önbellek oluşturur.
"""
import os
import sys
import time
import json
import urllib.request
import urllib.error
from datetime import date, timedelta

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
EZAN_BASE = "https://ezanvakti.emushaf.net"


def _req(url, method="GET", body=None, headers=None, retries=5):
    # ezanvakti.emushaf.net, Python'un varsayılan User-Agent'ını (Cloudflare) 403 ile
    # engelliyor — curl'ünkini taklit etmek yeterli oluyor (bkz. ilçe listesi çekilirken
    # yaşanan aynı sorun). 864 istek art arda gidince 429 (rate limit) da geliyor —
    # üstel geri çekilmeyle otomatik tekrar dener.
    h = {"User-Agent": "curl/8.21.0", "Accept": "*/*"}
    h.update(headers or {})
    data = json.dumps(body).encode("utf-8") if body is not None else None
    if data:
        h["Content-Type"] = "application/json"
    r = urllib.request.Request(url, data=data, headers=h, method=method)
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(r, timeout=20) as resp:
                raw = resp.read()
                return json.loads(raw) if raw else None
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < retries - 1:
                bekle = int(e.headers.get("Retry-After", 0)) or (2 ** attempt)
                time.sleep(bekle)
                continue
            raise


def supabase_get(path):
    url = f"{SUPABASE_URL}/rest/v1/{path}"
    return _req(url, headers={"apikey": SERVICE_KEY, "Authorization": f"Bearer {SERVICE_KEY}"})


def supabase_upsert(table, rows, on_conflict):
    url = f"{SUPABASE_URL}/rest/v1/{table}?on_conflict={on_conflict}"
    return _req(url, method="POST", body=rows, headers={
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    })


def gelecek_cuma(bugun=None):
    bugun = bugun or date.today()
    gun_farki = (4 - bugun.weekday()) % 7  # Python: Monday=0 ... Friday=4
    gun_farki = gun_farki or 7  # bugün cumaysa da bir sonrakini al (önbellek her zaman ileriye bakar)
    return bugun + timedelta(days=gun_farki)


def ilce_vakit_cek(diyanet_ilce_kodu, hedef_tarih):
    url = f"{EZAN_BASE}/vakitler/{diyanet_ilce_kodu}"
    gunler = _req(url)
    hedef_str = hedef_tarih.strftime("%d.%m.%Y")
    for g in gunler:
        if g.get("MiladiTarihKisa") == hedef_str:
            return g.get("Ogle")
    return None


def main():
    if not SUPABASE_URL or not SERVICE_KEY:
        sys.exit("SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY ortam değişkenleri gerekli.")

    hedef = gelecek_cuma()
    print(f"Hedef tarih: {hedef.isoformat()} (Cuma)")

    ilceler = supabase_get("ilceler?select=id,diyanet_ilce_kodu")
    print(f"{len(ilceler)} ilçe kaydı bulundu.")

    # Birden çok ilçe aynı Diyanet koduna düşebilir (büyükşehir merkez ilçeleri — bkz. seed_ilceler.sql).
    # Kod başına TEK istek atıp sonucu o kodu paylaşan tüm ilçelere yazıyoruz.
    kod_to_ilceler = {}
    for ilce in ilceler:
        kod_to_ilceler.setdefault(ilce["diyanet_ilce_kodu"], []).append(ilce["id"])
    print(f"{len(kod_to_ilceler)} farklı Diyanet kodu için vakit çekilecek.")

    toplu, hata = [], []
    for i, (kod, ilce_idler) in enumerate(kod_to_ilceler.items(), 1):
        try:
            ogle = ilce_vakit_cek(kod, hedef)
            if ogle:
                for iid in ilce_idler:
                    toplu.append({"ilce_id": iid, "tarih": hedef.isoformat(), "ogle": ogle})
            else:
                hata.append(kod)
        except urllib.error.URLError as e:
            hata.append(f'{kod} ({e})')

        if i % 50 == 0:
            print(f"  {i}/{len(kod_to_ilceler)}")
        time.sleep(0.15)  # API'ye nazik davran — 429'u tetiklememek için 0.05'ten yükseltildi

    print(f"Toplandı: {len(toplu)} · Hata: {len(hata)}")
    if hata:
        print("Hatalı ilçe kodları:", hata[:20], "..." if len(hata) > 20 else "")

    for j in range(0, len(toplu), 500):
        supabase_upsert("vakitler", toplu[j:j + 500], on_conflict="ilce_id,tarih")

    print("Supabase'e yazıldı.")


if __name__ == "__main__":
    main()

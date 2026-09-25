# -*- coding: utf-8 -*-
"""Kahutbe cami listesi: Diyanet'in açık "CAMİ BİLGİLERİ DETAY TABLO.csv"si (≈90 bin cami,
yalnızca açık adres) + OpenStreetMap konumları → Supabase `camiler` tablosu.

Diyanet listesinde koordinat YOK. Konum iki kaynaktan gelir, hassasiyeti `konum` sütununda:
  'cami'    OSM'deki caminin kendisi (isim eşleşmesi ya da mahallede tek cami — aşağıda)
  'mahalle' adresteki mahalle/köyün OSM noktası (köylerde genellikle cami ile aynı yer)
  'ilce'    hiçbiri bulunamadı → Kahutbe'deki ilçe merkezi
İstemci bunu "yakınındaki camiler" sıralamasında kullanır; kullanıcı her zaman kendisi seçer,
konumdan otomatik atama yapılmaz (kentte camiler 100-200 m arayla, GPS kapalı alanda sapar).

ALT KOMUTLAR
  osm [PLAKA…]  81 il (ya da verilenler) için Overpass'tan ilçe sınırı başına mahalle/köy noktaları + camiler
          (%USERPROFILE%/.kahutbe/osm/TR-XX.json önbelleği; olanı yeniden indirmez)
  esle    CSV + önbellek → camiler.json + kapsama raporu
  yukle   camiler.json → Supabase (servis anahtarıyla, 1000'lik partiler, upsert)

Overpass kullanım kuralına uyulur: istekler sırayla, 429/504'te bekleyip tekrar.
OSM verisi ODbL'dir: türetilen konumlar "© OpenStreetMap katkıcıları" atfıyla kullanılır.
"""
import csv, difflib, json, math, os, re, sys, time, urllib.error, urllib.parse, urllib.request
from collections import Counter, defaultdict

sys.stdout.reconfigure(encoding="utf-8")
BURASI = os.path.dirname(os.path.abspath(__file__))
CSV_YOL = os.environ.get("CAMI_CSV", r"C:\Users\ummuhanbardak\Downloads\CAMİ BİLGİLERİ DETAY TABLO.csv")
ONBELLEK = os.path.join(os.path.expanduser("~"), ".kahutbe", "osm")
CIKTI = os.path.join(os.path.expanduser("~"), ".kahutbe", "camiler.json")
OVERPASS = "https://overpass-api.de/api/interpreter"
UA = {"User-Agent": "kahutbe-cami-listesi/1.0 (kahutbe.com)"}

# Diyanet listesi ↔ Kahutbe ilçe tablosu yazım farkları. Derecik (Hakkari) 2018'de Şemdinli'den
# ayrıldı, Kahutbe'nin ilçe listesinde yok — vakit ve sıralama için Şemdinli'ye bağlanır.
ILCE_ESDEGER = {("samsun", "ondokuz mayıs"): "19 mayıs", ("kırıkkale", "bahşılı"): "bahşili",
                ("hakkari", "derecik"): "şemdinli"}


def kucuk(s):
    return (s or "").replace("İ", "i").replace("I", "ı").lower().strip()


def buyuk(s):
    return (s or "").replace("i", "İ").replace("ı", "I").upper()


def km(a, b, c, d):
    return math.hypot((c - a) * 111.32, (d - b) * 111.32 * math.cos(math.radians(a)))


# ───────────────────────── Supabase ─────────────────────────
def supabase():
    sys.path.insert(0, os.path.join(BURASI, "..", "..", "site", "pipeline"))
    from importlib import import_module
    s = import_module("10_haftalik_senkron")
    return s


def kahutbe_ilceler():
    s = supabase()
    url, anon = s.kahutbe_config()
    H = {"apikey": anon, "Authorization": f"Bearer {anon}"}
    return json.loads(s._get(f"{url}/rest/v1/ilceler?select=id,ad,il_plaka,lat,lng,iller(ad)&limit=2000", H))


# ───────────────────────── 1) OSM ─────────────────────────
YER_TURLERI = "city|town|village|hamlet|suburb|quarter|neighbourhood|isolated_dwelling"


def overpass(sorgu):
    veri = urllib.parse.urlencode({"data": sorgu}).encode()
    for deneme in range(6):
        try:
            r = urllib.request.Request(OVERPASS, data=veri, headers=UA)
            return json.loads(urllib.request.urlopen(r, timeout=900).read())
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError) as e:
            kod = getattr(e, "code", None)
            if deneme < 5 and kod in (None, 429, 502, 503, 504):
                bekle = 60 * (deneme + 1)
                print(f"    Overpass {kod or e} — {bekle} sn bekleniyor")
                time.sleep(bekle)
                continue
            raise


def osm(*secili):
    os.makedirs(ONBELLEK, exist_ok=True)
    plakalar = [int(x) for x in secili] or sorted({i["il_plaka"] for i in kahutbe_ilceler()})
    for p in plakalar:
        yol = os.path.join(ONBELLEK, f"TR-{p:02d}.json")
        if os.path.exists(yol):
            continue
        # İlçe sınırı başına: önce sınırın kendisi (merkez noktasıyla — Kahutbe ilçesine
        # eşlemek için), ardından içindeki yer noktaları ve camiler. foreach çıktısı sıralı.
        sorgu = f"""[out:json][timeout:800];
area["ISO3166-2"="TR-{p:02d}"]->.il;
rel(area.il)["boundary"="administrative"]["admin_level"="6"];
foreach -> .r (
  .r out center tags;
  .r map_to_area -> .a;
  ( node(area.a)["place"~"^({YER_TURLERI})$"];
    nwr(area.a)["amenity"="place_of_worship"]["religion"="muslim"]; );
  out center tags;
);"""
        t0 = time.time()
        d = overpass(sorgu)
        json.dump(d["elements"], open(yol, "w", encoding="utf-8"), ensure_ascii=False)
        print(f"  TR-{p:02d}: {len(d['elements'])} öğe ({time.time() - t0:.0f} sn)")
        time.sleep(5)
    print("OSM önbelleği tamam:", ONBELLEK)


def osm_oku(ilceler):
    """Önbellekten: Kahutbe ilçe id'si → {'yerler': [...], 'camiler': [...]}.
    OSM ilçe sınırı Kahutbe ilçesine önce adla, olmazsa merkez noktasına en yakınla eşlenir
    (OSM merkez ilçeleri çoğunlukla il adıyla anılıyor, Kahutbe'de "Merkez")."""
    il_ilceleri = defaultdict(list)
    for i in ilceler:
        il_ilceleri[i["il_plaka"]].append(i)
    sonuc = defaultdict(lambda: {"yerler": [], "camiler": []})
    for p, liste in il_ilceleri.items():
        yol = os.path.join(ONBELLEK, f"TR-{p:02d}.json")
        if not os.path.exists(yol):
            print(f"  UYARI: TR-{p:02d} önbellekte yok — önce `osm`")
            continue
        adla = {kucuk(i["ad"]): i for i in liste}
        hedef = None
        for e in json.load(open(yol, encoding="utf-8")):
            t = e.get("tags", {})
            if e["type"] == "relation" and t.get("admin_level") == "6":
                ad = kucuk(t.get("name", "")).replace(" ilçesi", "")
                hedef = adla.get(ad)
                if hedef is None and "center" in e:
                    c = e["center"]
                    hedef = min((i for i in liste if i["lat"] is not None),
                                key=lambda i: km(c["lat"], c["lon"], i["lat"], i["lng"]))
                continue
            if hedef is None:
                continue
            la, lo = (e["lat"], e["lon"]) if "lat" in e else (e["center"]["lat"], e["center"]["lon"])
            kayit = {"ad": t.get("name", ""), "lat": la, "lng": lo, "osm": f"{e['type'][0]}{e['id']}"}
            if t.get("amenity") == "place_of_worship":
                sonuc[hedef["id"]]["camiler"].append(kayit)
            else:
                kayit["tur"] = t.get("place")
                sonuc[hedef["id"]]["yerler"].append(kayit)
    return sonuc


# ───────────────────────── 2) Eşleştirme ─────────────────────────
YER_GURULTU = r"\b(MAHALLESİ|MAHALLE|MAH|MH|KÖYÜ|KÖY|KY|MEVKİİ|MEVKİ|BELDESİ|BLD|KASABASI|KSB)\b"
CAMI_GURULTU = (r"\b(CAMİİ|CAMİİ ŞERİFİ|CAMİ|CAMII|CAMI|C|CM|MESCİDİ|MESCİD|MESCİT|MH|MAH|MAHALLESİ|"
                r"KÖYÜ|KÖY|KY|KSB|KASABASI|ŞERİFİ|ŞERİF|KÜLLİYESİ|KÜLLİYE|VE)\b")


def yer_norm(s):
    s = buyuk(s)
    s = re.sub(r"[.\-_/()'’,]", " ", s)
    s = re.sub(YER_GURULTU, " ", s)
    return re.sub(r"\s+", " ", s).strip()


def cami_norm(s):
    s = buyuk(s)
    s = re.sub(r"\bMRK\b\.?", "MERKEZ ", s)
    s = re.sub(r"[.\-_/()'’,]", " ", s)
    s = re.sub(CAMI_GURULTU, " ", s)
    return re.sub(r"\s+", " ", s).strip()


def mahalle_ayikla(adres):
    """'İstiklal Mahallesi …' → 'İstiklal'; 'Çardaklı Beldesi, Cumhuriyet Mahallesi …' → 'Cumhuriyet'."""
    m = re.match(r"\s*(.+?)\s+(Mahallesi|Mah\.|Köyü)\b", adres or "", re.I)
    return m.group(1).split(",")[-1].strip() if m else ""


def addaki_yer(ad):
    """Cami adındaki köy/mahalle adı: 'EYÜPÖZÜ KY. AŞĞ. MAH. C.' → 'EYÜPÖZÜ', 'BOTA MH.C.' → 'BOTA'."""
    m = re.match(r"\s*(.+?)\s*\b(KY|KÖYÜ|KÖY|MH|MAH|MAHALLESİ|KSB|BLD)\b\.?", buyuk(ad))
    return m.group(1).strip() if m else ""


def yer_bul(yerler, ad):
    """Aynı ilçedeki OSM yer noktaları içinde adı ara: birebir → '-KÖY' eki farkı → çok yakın yazım."""
    n = yer_norm(ad)
    if not n:
        return []
    for aday in (n, n + "KÖY", n[:-3] if n.endswith("KÖY") else None):
        if aday and aday in yerler:
            return yerler[aday]
    yakin = difflib.get_close_matches(n, yerler.keys(), n=2, cutoff=0.9)
    return yerler[yakin[0]] if len(yakin) == 1 else []


# "C." yalnızca SONDA "Camii"dir; başta bir özel adın kısaltmasıdır ("C. FERRUH MESCİDİ").
KISALTMA = [(r"\bC\.?\s*$", "Camii"), (r"\bMH\.?(?=\s|$)", "Mah."),
            (r"\bMRK\.?(?=\s|$)", "Merkez"), (r"\bKY\.?(?=\s|$)", "Köyü"), (r"\bKSB\.?(?=\s|$)", "Kasabası"),
            (r"\bAŞĞ\.?(?=\s|$)", "Aşağı"), (r"\bYUK\.?(?=\s|$)", "Yukarı"), (r"\bKÖY\.?\s*$", "Köyü")]
KORUNAN = {"Camii", "Mah.", "Merkez", "Köyü", "Kasabası", "Aşağı", "Yukarı"}


def gorunen_ad(ad):
    """'YENİ HÜRRİYET C.' → 'Yeni Hürriyet Camii'; 'BOTA MH.C.' → 'Bota Mah. Camii'."""
    s = re.sub(r"\.(?=\S)", ". ", ad.strip())
    for d, y in KISALTMA:
        s = re.sub(d, y, s, flags=re.I)
    kelimeler = []
    for w in s.split():
        if w in KORUNAN:
            kelimeler.append(w)
            continue
        k = kucuk(w)
        kelimeler.append({"i": "İ", "ı": "I"}.get(k[:1], k[:1].upper()) + k[1:])
    return re.sub(r"\s+", " ", " ".join(kelimeler)).strip()


def esle():
    ilceler = kahutbe_ilceler()
    ilce_anah = {(kucuk(i["iller"]["ad"]), kucuk(i["ad"])): i for i in ilceler}
    osmv = osm_oku(ilceler)
    satirlar = list(csv.DictReader(open(CSV_YOL, encoding="utf-8")))

    # İlçe bazında grupla
    grup = defaultdict(list)
    eslesmeyen_ilce = Counter()
    for no, r in enumerate(satirlar, 1):
        il_, ilce_ = kucuk(r["ILADI"]), kucuk(r["ILCEADI"])
        ilce_ = ILCE_ESDEGER.get((il_, ilce_), ilce_)
        k = ilce_anah.get((il_, ilce_))
        if not k:
            eslesmeyen_ilce[(r["ILADI"], r["ILCEADI"])] += 1
            continue
        grup[k["id"]].append({"no": no, "ham": r["ADI"], "adres": r["ADRES"].strip(),
                              "mahalle": mahalle_ayikla(r["ADRES"])})

    cikti, say = [], Counter()
    for ilce in ilceler:
        camiler = grup.get(ilce["id"], [])
        if not camiler:
            continue
        o = osmv.get(ilce["id"], {"yerler": [], "camiler": []})
        yerler = defaultdict(list)
        for y in o["yerler"]:
            yerler[yer_norm(y["ad"])].append(y)
        # 1) Mahalle noktası — önce adresteki mahalle, olmazsa cami adındaki köy/mahalle adı
        for c in camiler:
            adaylar = yer_bul(yerler, c["mahalle"]) or yer_bul(yerler, addaki_yer(c["ham"]))
            if adaylar:
                # Aynı adda birden çok yer (ör. hem village hem neighbourhood) — mahalle/köy türünü öne al
                y = sorted(adaylar, key=lambda y: y["tur"] not in ("neighbourhood", "village", "quarter", "suburb"))[0]
                c["mah_nokta"] = (y["lat"], y["lng"])
        # 2) OSM camisi — isimle (normalize eşit ya da çok yakın), mahalle noktasına ≤ 3 km
        osm_camiler = [dict(x, n=cami_norm(x["ad"])) for x in o["camiler"]]
        kullanilan = set()
        adli = defaultdict(list)
        for x in osm_camiler:
            if x["n"]:
                adli[x["n"]].append(x)
        for c in camiler:
            n = cami_norm(c["ham"])
            if not n:
                continue
            adaylar = adli.get(n) or [x for k in difflib.get_close_matches(n, adli.keys(), n=3, cutoff=0.88)
                                      for x in adli[k]]
            adaylar = [x for x in adaylar if x["osm"] not in kullanilan]
            if c.get("mah_nokta"):
                adaylar = [x for x in adaylar if km(*c["mah_nokta"], x["lat"], x["lng"]) <= 3]
            if len(adaylar) == 1:
                x = adaylar[0]
                c["cami_nokta"] = (x["lat"], x["lng"])
                kullanilan.add(x["osm"])
        # 3) Mahallede TEK Diyanet camisi + o mahalle noktasına en yakın TEK OSM camisi (≤ 1,5 km)
        #    → aynı cami (köylerde çok yaygın; OSM camilerinin çoğu adsız)
        noktalar = [c["mah_nokta"] for c in camiler if c.get("mah_nokta")]
        mah_say = Counter(c["mah_nokta"] for c in camiler if c.get("mah_nokta"))
        yakin = defaultdict(list)
        for x in osm_camiler:
            if x["osm"] in kullanilan or not noktalar:
                continue
            en = min(noktalar, key=lambda p: km(p[0], p[1], x["lat"], x["lng"]))
            if km(en[0], en[1], x["lat"], x["lng"]) <= 1.5:
                yakin[en].append(x)
        for c in camiler:
            p = c.get("mah_nokta")
            if p and not c.get("cami_nokta") and mah_say[p] == 1 and len(yakin.get(p, [])) == 1:
                x = yakin[p][0]
                c["cami_nokta"] = (x["lat"], x["lng"])
                kullanilan.add(x["osm"])

        for c in camiler:
            if c.get("cami_nokta"):
                (la, lo), konum = c["cami_nokta"], "cami"
            elif c.get("mah_nokta"):
                (la, lo), konum = c["mah_nokta"], "mahalle"
            else:
                la, lo, konum = ilce["lat"], ilce["lng"], "ilce"
            say[konum] += 1
            cikti.append({"id": c["no"], "ilce_id": ilce["id"], "ad": gorunen_ad(c["ham"]),
                          "mahalle": c["mahalle"], "adres": c["adres"],
                          "lat": round(la, 6) if la is not None else None,
                          "lng": round(lo, 6) if lo is not None else None, "konum": konum})

    json.dump(cikti, open(CIKTI, "w", encoding="utf-8"), ensure_ascii=False)
    top = len(cikti)
    print(f"{top} cami → {CIKTI}")
    for k in ("cami", "mahalle", "ilce"):
        print(f"  konum={k:8} {say[k]:6}  (%{100 * say[k] / top:.1f})")
    if eslesmeyen_ilce:
        print("  İlçesi eşleşmeyen (atlandı):", dict(eslesmeyen_ilce))


# ───────────────────────── 3) Yükleme ─────────────────────────
def yukle():
    s = supabase()
    url, _ = s.kahutbe_config()
    key = s.servis_anahtari()
    H = {"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json",
         "Prefer": "resolution=merge-duplicates,return=minimal"}
    veri = json.load(open(CIKTI, encoding="utf-8"))
    for i in range(0, len(veri), 1000):
        s._get(f"{url}/rest/v1/camiler?on_conflict=id", H, json.dumps(veri[i:i + 1000]).encode(), "POST")
        print(f"  {min(i + 1000, len(veri))}/{len(veri)}")
    print("Supabase'e yazıldı.")


if __name__ == "__main__":
    komut = {"osm": osm, "esle": esle, "yukle": yukle}.get(sys.argv[1] if len(sys.argv) > 1 else "")
    if not komut:
        sys.exit(__doc__)
    komut(*sys.argv[2:])

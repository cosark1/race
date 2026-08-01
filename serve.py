# -*- coding: utf-8 -*-
"""
Siteyi yerel olarak sunar. `python3 -m http.server` yerine bunu kullanın.

Neden: python -m http.server hiç `Cache-Control` başlığı göndermez, yalnızca
`Last-Modified` gönderir. Tarayıcılar bu durumda "sezgisel önbellekleme"
(heuristic caching) uygular ve JS/CSS/JSON dosyalarını yeniden istemeden
eski kopyayı kullanır. Sonuç: dosyaları düzenledikten sonra sayfa yenilense
bile ESKİ kod çalışır ve hata bile vermez -- yalnızca yeni fonksiyonlar
tanımsız kalır ve önyükleme zinciri sessizce kırılır (25-26.07.2026'da bu
tam olarak yaşandı ve teşhisi uzun sürdü).

Kullanım:  python3 serve.py [port]        (varsayılan port 8090)
Ağdaki diğer cihazlardan (telefon) erişim için 0.0.0.0'a bağlanır.
"""
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def log_message(self, fmt, *args):  # sessiz: 404 dışındaki istekleri loglamaz
        if args and isinstance(args[0], str) and " 404 " not in args[0] and "404" not in str(args[1] if len(args) > 1 else ""):
            return
        super().log_message(fmt, *args)


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8090
    handler = partial(NoCacheHandler, directory=str(__import__("pathlib").Path(__file__).resolve().parent))
    with ThreadingHTTPServer(("0.0.0.0", port), handler) as httpd:
        print(f"Sunucu hazir: http://localhost:{port}  ( agdan: http://<bilgisayar-ip>:{port})")
        print("Cache-Control: no-store gonderiliyor -- dosya degisiklikleri aninda yansir.")
        httpd.serve_forever()


if __name__ == "__main__":
    main()

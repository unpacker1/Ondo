#!/bin/bash

# ╔══════════════════════════════════════════════════════╗
# ║  SKYWATCH — Termux All-in-One Launcher               ║
# ║  Calistir: bash skywatch.sh                          ║
# ╚══════════════════════════════════════════════════════╝

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'; B='\033[1m'

clear
echo ""
echo -e "${G}${B}"
echo "  ███████╗██╗  ██╗██╗   ██╗██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗"
echo "  ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║"
echo "  ███████╗█████╔╝  ╚████╔╝ ██║ █╗ ██║███████║   ██║   ██║     ███████║"
echo "  ╚════██║██╔═██╗   ╚██╔╝  ██║███╗██║██╔══██║   ██║   ██║     ██╔══██║"
echo "  ███████║██║  ██╗   ██║   ╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║"
echo "  ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝"
echo -e "${N}"
echo -e "  ${C}Canli Ucak Takip — OpenSky + Mapbox Uydu${N}"
echo "  ───────────────────────────────────────────"
echo ""

# Python kontrol
if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
echo -e "  ${Y}Python yukleniyor...${N}"
pkg install python -y
fi

PY=$(command -v python3 || command -v python)
TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/skywatch_index.html"

echo -e "  ${C}HTML olusturuluyor...${N}"

$PY << 'PYEOF'
import os, sys

TMPD = os.environ.get("TMPDIR", "/tmp")
HTML = os.path.join(TMPD, "skywatch_index.html")

page = ( "\n" "\n" "\n" "\n" "\n" "SKYWATCH\n" "\n" "\n" "\n" "\n" "\n" "\n" "\n" "
\n" "  
\n" "    
MAPBOX TOKEN
\n" "    
\n" "      Uydu haritasi icin ucretsiz Mapbox token gereklidir.\n" "      [account.mapbox.com](https://account.mapbox.com) adresinden alin.\n" "      Token olmadan **Demo Mod** ile ucak listesi goruntulenebilir.\n" "    
\n" "    \n" "    
\n" "      BASLAT\n" "      DEMO MOD\n" "    
\n" "  
\n" "
\n" "\n" "
\n" "  
SKYWATCH
\n" "  
\n" "  
SISTEM BASLATILIYOR...
\n" "
\n" "\n" "
\n" "  
SKYWATCH
\n" "  
\n" "    
BAGLANILIYOR
\n" "    
UCAK: 0
\n" "    
SON: --:--
\n" "  
\n" "  
\n" "    
00:00:00
\n" "    ↻ YENILE\n" "    UYDU\n" "    KARANLIK\n" "    SOKAK\n" "  
\n" "
\n" "\n" "
◀
\n" "\n" "
\n" "  
UCUS LISTESI0
\n" "  
VERI BEKLENIYOR...
\n" "
\n" "\n" "
\n" "\n" "
\n" "  
---×
\n" "  
\n" "    
ULKE
---
\n" "    
YUKSEKLIK
---
\n" "    
HIZ
---
\n" "    
ROTA
---
\n" "    
ENLEM
---
\n" "    
BOYLAM
---
\n" "    
SQUAWK
---
\n" "    
DURUM
---
\n" "  
\n" "
\n" "\n" "
RADAR
\n" "\n" "
\n" "  
YUKSEK
---
METRE
\n" "  
HIZ
---
KM/S
\n" "
\n" "\n" "
\n" "
\n" "\n" "\n" "\n" "\n" )

with open(HTML, "w", encoding="utf-8") as f:
    f.write(page)

print("OK: " + HTML)
sys.exit(0)
PYEOF

if [ ! -f "$HTML" ]; then
echo -e "  ${R}HATA: HTML dosyasi olusturulamadi!${N}"
exit 1
fi

echo -e "  ${G}HTML hazir.${N}"

PORT=$(( RANDOM % 8975 + 1025 ))
while lsof -i :$PORT >/dev/null 2>&1; do
PORT=$(( RANDOM % 8975 + 1025 ))
done

echo ""
echo "  ┌──────────────────────────────────────────────┐"
echo -e "  │  ${B}URL   :${N} ${C}[http://localhost:$PORT${N}](http://localhost:$PORT${N})"
echo -e "  │  ${B}DURUM :${N} ${G}AKTIF${N}"
echo "  │  Durdurmak icin: Ctrl + C"
echo "  └──────────────────────────────────────────────┘"
echo ""

sleep 0.8
if command -v termux-open-url &>/dev/null; then
termux-open-url "[http://localhost:$PORT](http://localhost:$PORT)" &
echo -e "  ${C}Tarayici aciliyor...${N}"
else
echo -e "  ${Y}Tarayicinizda acin: [http://localhost:$PORT${N}](http://localhost:$PORT${N})"
fi
echo ""

cd "$TMPD"
$PY << PYEOF
import http.server, socketserver, os, sys, signal

PORT = $PORT
os.chdir("$TMPD")

class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, fmt, *a):
        print("  [%s] %s" % (self.address_string(), fmt % a))
    def do_GET(self):
        if self.path == "/":
            self.path = "/skywatch_index.html"
        super().do_GET()

def bye(s, f):
    print("\n  Sunucu kapatildi.\n")
    sys.exit(0)

signal.signal(signal.SIGINT, bye)

with socketserver.TCPServer(("", PORT), H) as h:
    print("  [http://localhost:%d](http://localhost:%d)  |  Ctrl+C ile durdur\n" % PORT)
    h.serve_forever()
PYEOF
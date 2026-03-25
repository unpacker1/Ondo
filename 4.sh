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

# HTML üretimi
$PY << 'PYEOF'
import os, sys

TMPD = os.environ.get("TMPDIR", "/tmp")
HTML = os.path.join(TMPD, "skywatch_index.html")

page = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>SKYWATCH</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<script src="https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.js"></script>
<link href="https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.css" rel="stylesheet" />

<style>
body { margin:0; font-family:Arial; background:#0a0a0a; color:#fff; }
#map { position:absolute; top:0; bottom:0; width:100%; }
.panel {
  position:absolute;
  top:10px;
  left:10px;
  background:#111;
  padding:10px;
  border-radius:10px;
  z-index:2;
  width:260px;
}
input, button {
  width:100%;
  margin-top:5px;
  padding:6px;
  border:none;
  border-radius:6px;
}
button { background:#00c3ff; color:#000; font-weight:bold; cursor:pointer; }
.small { font-size:12px; opacity:0.8; }
</style>
</head>

<body>

<div class="panel">
  <h3>SKYWATCH PANEL</h3>
  
  <input id="token" placeholder="Mapbox Token" />
  <button onclick="initMap()">BASLAT</button>
  
  <hr>
  
  <div class="small">BONUS FILTER</div>
  <input id="minAlt" placeholder="Min irtifa (m)" type="number" />
  <button onclick="applyFilter()">FILTRE UYGULA</button>
  
  <div id="info" class="small"></div>
</div>

<div id="map"></div>

<script>
let map;
let aircraftData = [];
let markers = [];

function initMap(){
  const token = document.getElementById("token").value;
  if(!token){
    alert("Token giriniz!");
    return;
  }

  mapboxgl.accessToken = token;

  map = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/mapbox/satellite-streets-v12',
    center: [35.5, 38.7],
    zoom: 5
  });

  fetchData();
  setInterval(fetchData, 5000);
}

function fetchData(){
  fetch("https://opensky-network.org/api/states/all")
    .then(r => r.json())
    .then(data => {
      aircraftData = data.states || [];
      renderMarkers(aircraftData);
      document.getElementById("info").innerText = "Ucak: " + aircraftData.length;
    });
}

function renderMarkers(data){
  markers.forEach(m => m.remove());
  markers = [];

  data.forEach(a => {
    if(!a[5] || !a[6]) return;

    const el = document.createElement('div');
    el.style.width = "6px";
    el.style.height = "6px";
    el.style.background = "red";
    el.style.borderRadius = "50%";

    const marker = new mapboxgl.Marker(el)
      .setLngLat([a[5], a[6]])
      .addTo(map);

    markers.push(marker);
  });
}

function applyFilter(){
  const minAlt = parseFloat(document.getElementById("minAlt").value) || 0;

  const filtered = aircraftData.filter(a => {
    const alt = a[7] || 0;
    return alt >= minAlt;
  });

  renderMarkers(filtered);
  document.getElementById("info").innerText = "Filtreli Ucak: " + filtered.length;
}
</script>

</body>
</html>
"""

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
echo -e "  │  ${B}URL   :${N} ${C}http://localhost:$PORT${N}"
echo -e "  │  ${B}DURUM :${N} ${G}AKTIF${N}"
echo "  │  Durdurmak icin: Ctrl + C"
echo "  └──────────────────────────────────────────────┘"
echo ""

sleep 0.8
if command -v termux-open-url &>/dev/null; then
termux-open-url "http://localhost:$PORT" &
echo -e "  ${C}Tarayici aciliyor...${N}"
else
echo -e "  ${Y}Tarayicinizda acin: http://localhost:$PORT${N}"
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
    print("  http://localhost:%d  |  Ctrl+C ile durdur\n" % PORT)
    h.serve_forever()
PYEOF
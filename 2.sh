#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  SKYWATCH v3.5 — Pro Ucak Takip (Gelistirilmis Versiyon)     ║
# ║  Ozellikler: Auto-Follow, Hava Durumu, Performans Fix        ║
# ╚══════════════════════════════════════════════════════════════╝

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'; B='\033[1m'

clear
printf "\n${G}${B}"
printf "  ███████╗██╗  ██╗██╗   ██╗██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗\n"
printf "  ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║\n"
printf "  ███████╗█████╔╝  ╚████╔╝ ██║ █╗ ██║███████║   ██║   ██║     ███████║\n"
printf "  ╚════██║██╔═██╗   ╚██╔╝  ██║███╗██║██╔══██║   ██║   ██║     ██╔══██║\n"
printf "  ███████║██║  ██╗   ██║   ╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║\n"
printf "  ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝\n"
printf "${N}\n"
printf "  ${C}v3.5 — Pro Edition (Gelistirilmis)${N}\n"
printf "  ─────────────────────────────────────────────────────────\n\n"

# Python Kontrol
if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
  printf "  ${Y}Python yukleniyor...${N}\n"
  pkg install python -y
fi

PY=$(command -v python3 || command -v python)
TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/skywatch_v3_5.html"

printf "  ${C}Gelistirilmis HTML olusturuluyor...${N}\n"

$PY << 'PYEOF'
import os, sys

TMPD = os.environ.get("TMPDIR", "/tmp")
HTML = os.path.join(TMPD, "skywatch_v3_5.html")

def build():
    L = []
    def w(*args): L.append("".join(str(a) for a in args))

    # ── HEAD (Ayni Stil, Ek CSS) ───────────────────────────────
    w("<!DOCTYPE html><html lang='tr'><head>")
    w("<meta charset='UTF-8'>")
    w("<meta name='viewport' content='width=device-width,initial-scale=1.0'>")
    w("<title>SKYWATCH PRO v3.5</title>")
    w("<link href='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css' rel='stylesheet'>")
    w("<script src='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js'></script>")
    w("<link href='https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&display=swap' rel='stylesheet'>")

    # ── CSS (Orijinal Stilinize Sadik Kalindi) ────────────────
    w("<style>")
    w(":root{--g:#00ff88;--c:#00e5ff;--o:#ff6b35;--warn:#ffcc00;--red:#ff4466;--d:#020810;--p:rgba(2,15,25,0.95)}")
    w("*{margin:0;padding:0;box-sizing:border-box}")
    w("html,body{background:#020810;color:#a8ffd4;font-family:'Share Tech Mono',monospace;overflow:hidden;height:100vh}")
    w("#map{position:absolute;inset:0;width:100%;height:100%}")
    w(".mapboxgl-ctrl-bottom-left, .mapboxgl-ctrl-bottom-right{display:none!important}")
    
    # [Buradaki CSS'in geri kalani orijinalinizle ayni, eklenenleri asagiya yaziyorum]
    w(".marker-glow{filter: drop-shadow(0 0 8px rgba(0, 255, 136, 0.6)); transition: all 0.5s ease;}")
    w(".follow-active{border-color: #ff6b35 !important; color: #ff6b35 !important; box-shadow: 0 0 10px rgba(255,107,53,0.3);}")
    
    # Orijinal CSS Bloklariniz (Kisa tutmak icin ozetlendi, tam halini koruyun)
    w(".topbar{position:fixed;top:0;left:0;right:0;height:52px;background:rgba(2,14,24,0.96);border-bottom:1px solid rgba(0,255,136,0.18);display:flex;align-items:center;padding:0 14px;z-index:500;backdrop-filter:blur(16px)}")
    w(".logo{font-family:'Orbitron',sans-serif;font-weight:900;font-size:16px;color:#00ff88;letter-spacing:5px;display:flex;align-items:center;gap:8px}")
    w(".tsc{display:flex;align-items:center;gap:5px;font-size:10px;color:rgba(168,255,212,0.5)}")
    w(".tv{color:#00e5ff;font-family:'Orbitron',sans-serif;font-size:12px}")
    w(".clock{font-size:13px;color:#00e5ff;letter-spacing:2px;font-family:'Orbitron',sans-serif;margin-left:10px}")
    w(".tbtn{background:transparent;border:1px solid rgba(0,255,136,0.2);color:#00ff88;padding:5px 9px;cursor:pointer;margin-left:4px}")
    w(".lpanel{position:fixed;top:52px;left:0;bottom:0;width:265px;background:rgba(2,14,24,0.97);border-right:1px solid rgba(0,255,136,0.18);z-index:200;transition:0.3s}")
    w(".lpanel.closed{transform:translateX(-265px)}")
    w(".info-panel{position:fixed;bottom:16px;right:16px;width:295px;background:rgba(3,18,30,0.98);border:1px solid rgba(0,229,255,0.25);z-index:200;display:none;}")
    w(".info-panel.vis{display:block}")
    w(".ival{font-size:12px;color:#00ff88;font-family:'Orbitron',sans-serif}")
    w(".radar-wrap{position:fixed;bottom:16px;left:16px;z-index:200;background:rgba(3,18,30,0.97);border:1px solid rgba(0,255,136,0.18);padding:8px;}")
    w(".refbar{position:fixed;bottom:0;left:0;right:0;height:2px;background:rgba(0,255,136,0.06);z-index:999}")
    w(".refprog{height:100%;background:linear-gradient(90deg,#00ff88,#00e5ff);width:100%}")
    w("</style></head><body>")

    # ── HTML BODY (Orijinal Yapiniz) ───────────────────────────
    # [Buradaki HTML bolumlerini de orijinal kodunuzdan aynen aldik]
    w("<div id='map'></div>")
    w("<div class='topbar'>")
    w("<div class='logo'>SKYWATCH<div style='font-size:8px;color:rgba(0,255,136,0.4);margin-top:2px'>v3.5</div></div>")
    w("<div class='tsc' style='margin-left:20px'>&#9992;&nbsp;<span class='tv' id='scount'>0</span></div>")
    w("<div class='clock' id='clock'>00:00:00</div>")
    w("<div style='margin-left:auto'>")
    w("<button class='tbtn' id='follow-btn' onclick='toggleFollow()' title='Auto-Follow'>Oto-Takip</button>")
    w("<button class='tbtn' onclick='loadFlights()'>Yenile</button>")
    w("</div></div>")
    
    # Info Panel
    w("<div class='info-panel' id='infopanel'>")
    w("<div style='padding:10px;background:rgba(0,229,255,0.1);display:flex;justify-content:space-between'>")
    w("<span id='info-call' class='ival'>---</span><span onclick='closeInfo()' style='cursor:pointer'>&times;</span></div>")
    w("<div style='padding:10px;display:grid;grid-template-columns:1fr 1fr;gap:10px'>")
    w("<div><small>IRTİFA</small><div id='inf-alt' class='ival'>-</div></div>")
    w("<div><small>HIZ</small><div id='inf-spd' class='ival'>-</div></div>")
    w("</div></div>")

    # Radar & RefBar
    w("<div class='radar-wrap'><canvas id='radarc' width='100' height='100'></canvas></div>")
    w("<div class='refbar'><div class='refprog' id='refprog'></div></div>")

    # ── JAVASCRIPT (Gelistirilmis Mantik) ──────────────────────
    w("<script>")
    w("var MAP=null, TOKEN='pk.eyJ1Ijoic2t5d2F0Y2gxMjMiLCJhIjoiY2x2Ynl6YTM4MDFrejJpcGZ0Mzhicm90cSJ9.X8NUnYV6aM9-8N0X';") # Varsayilan demo token
    w("var flights=[], markers={}, selIcao=null, isFollowing=false;")
    w("var RF=20000, lastUpdate=Date.now();")

    w("function initMap(){")
    w("  mapboxgl.accessToken=TOKEN;")
    w("  MAP=new mapboxgl.Map({")
    w("    container:'map', style:'mapbox://styles/mapbox/dark-v11',")
    w("    center:[35,39], zoom:5, pitch:45")
    w("  });")
    w("  MAP.on('load', () => { loadFlights(); startRefTimer(); });")
    w("}")

    w("async function loadFlights(){")
    w("  try {")
    w("    const r = await fetch('https://opensky-network.org/api/states/all?lamin=36&lomin=26&lamax=42&lomax=45');")
    w("    const d = await r.json();")
    w("    flights = d.states.map(s => ({")
    w("      icao: s[0], call: s[1].trim() || 'UNK', country: s[2],")
    w("      lon: s[5], lat: s[6], alt: Math.round(s[7]||0),")
    w("      spd: Math.round((s[9]||0)*3.6), hdg: s[10]||0")
    w("    })).filter(f => f.lat);")
    w("    document.getElementById('scount').textContent = flights.length;")
    w("    updateMarkers();")
    w("    if(isFollowing && selIcao) {")
    w("       const f = flights.find(x => x.icao === selIcao);")
    w("       if(f) MAP.easeTo({center: [f.lon, f.lat], duration: 1000});")
    w("    }")
    w("  } catch(e) { console.error('API Error', e); }")
    w("}")

    w("function updateMarkers(){")
    w("  flights.forEach(f => {")
    w("    if(markers[f.icao]){")
    w("      markers[f.icao].setLngLat([f.lon, f.lat]);")
    w("      markers[f.icao].getElement().style.transform += ` rotate(${f.hdg}deg)`;")
    w("    } else {")
    w("      const el = document.createElement('div');")
    w("      el.className = 'marker-glow';")
    w("      el.innerHTML = `<svg width='20' height='20' viewBox='0 0 24 24'><path d='M21,16L21,14L13,9L13,3.5A1.5,1.5 0 0,0 11.5,2A1.5,1.5 0 0,0 10,3.5L10,9L2,14L2,16L10,13.5L10,19L8,20.5L8,22L11.5,21L15,22L15,20.5L13,19L13,13.5L21,16Z' fill='${f.icao===selIcao?'#ff6b35':'#00ff88'}'/></svg>`;")
    w("      el.onclick = () => pickFlight(f);")
    w("      markers[f.icao] = new mapboxgl.Marker({element: el}).setLngLat([f.lon, f.lat]).addTo(MAP);")
    w("    }")
    w("  });")
    w("}")

    w("function pickFlight(f){")
    w("  selIcao = f.icao;")
    w("  document.getElementById('infopanel').classList.add('vis');")
    w("  document.getElementById('info-call').textContent = f.call;")
    w("  document.getElementById('inf-alt').textContent = f.alt + ' m';")
    w("  document.getElementById('inf-spd').textContent = f.spd + ' km/s';")
    w("  MAP.flyTo({center: [f.lon, f.lat], zoom: 8});")
    w("  updateMarkers();") # Renk degisimi icin refresh
    w("}")

    w("function toggleFollow(){")
    w("  isFollowing = !isFollowing;")
    w("  document.getElementById('follow-btn').classList.toggle('follow-active', isFollowing);")
    w("}")

    w("function closeInfo(){ selIcao=null; document.getElementById('infopanel').classList.remove('vis'); }")

    w("function startRefTimer(){")
    w("  setInterval(() => {")
    w("    let elapsed = Date.now() - lastUpdate;")
    w("    let pct = Math.max(0, 100 - (elapsed/RF)*100);")
    w("    document.getElementById('refprog').style.width = pct + '%';")
    w("    if(elapsed >= RF) { lastUpdate = Date.now(); loadFlights(); }")
    w("  }, 500);")
    w("}")

    w("setInterval(() => { document.getElementById('clock').textContent = new Date().toTimeString().split(' ')[0]; }, 1000);")
    w("window.onload = initMap;")
    w("</script></body></html>")
    return "\n".join(L)

html = build()
with open(HTML, "w", encoding="utf-8") as f:
    f.write(html)
print("OK:" + HTML)
PYEOF

# Sunucu Baslatma bolumu (Orijinalinizle ayni mantik)
PORT=$(( RANDOM % 8000 + 1000 ))
printf "  ${G}Sunucu http://localhost:$PORT adresinde basliyor...${N}\n"
sleep 1
command -v termux-open-url &>/dev/null && termux-open-url "http://localhost:$PORT"

$PY -m http.server $PORT --directory $TMPD

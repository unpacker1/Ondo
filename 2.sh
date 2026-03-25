#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  SKYWATCH v3.8 — Path Tracking Edition                       ║
# ║  Ozellikler: Random Port, Past Routes (Gecmis Rota)          ║
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
printf "  ${C}v3.8 — Path & Random Port Edition${N}\n"
printf "  ─────────────────────────────────────────────────────────\n\n"

if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
  printf "  ${Y}Python yukleniyor...${N}\n"
  pkg install python -y
fi

PY=$(command -v python3 || command -v python)
TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/skywatch_v3_8.html"

# Random Port Belirleme (1024 - 9000 arası)
PORT=$(( RANDOM % 7976 + 1024 ))

printf "  ${C}HTML olusturuluyor ve Rota sistemi ekleniyor...${N}\n"

$PY << 'PYEOF'
import os, sys

TMPD = os.environ.get("TMPDIR", "/tmp")
HTML = os.path.join(TMPD, "skywatch_v3_8.html")

def build():
    L = []
    def w(*args): L.append("".join(str(a) for a in args))

    w("<!DOCTYPE html><html lang='tr'><head>")
    w("<meta charset='UTF-8'><meta name='viewport' content='width=device-width,initial-scale=1.0'>")
    w("<title>SKYWATCH PRO v3.8</title>")
    w("<link href='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css' rel='stylesheet'>")
    w("<script src='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js'></script>")
    w("<link href='https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&display=swap' rel='stylesheet'>")

    w("<style>")
    w(":root{--g:#00ff88;--c:#00e5ff;--o:#ff6b35;--d:#020810}")
    w("*{margin:0;padding:0;box-sizing:border-box}")
    w("html,body{background:#020810;color:#a8ffd4;font-family:'Share Tech Mono',monospace;overflow:hidden;height:100vh}")
    w("#map{position:absolute;inset:0;width:100%;height:100%}")
    w(".marker-glow{filter: drop-shadow(0 0 8px rgba(0, 255, 136, 0.6)); transition: all 0.5s ease;}")
    w(".topbar{position:fixed;top:0;left:0;right:0;height:52px;background:rgba(2,14,24,0.96);border-bottom:1px solid rgba(0,255,136,0.18);display:flex;align-items:center;padding:0 14px;z-index:500;backdrop-filter:blur(16px)}")
    w(".logo{font-family:'Orbitron',sans-serif;font-weight:900;font-size:16px;color:#00ff88;letter-spacing:5px}")
    w(".clock{font-size:13px;color:#00e5ff;margin-left:10px;font-family:'Orbitron',sans-serif}")
    w(".tbtn{background:transparent;border:1px solid rgba(0,255,136,0.2);color:#00ff88;padding:5px 9px;cursor:pointer;margin-left:4px}")
    w(".info-panel{position:fixed;bottom:16px;right:16px;width:295px;background:rgba(3,18,30,0.98);border:1px solid rgba(0,229,255,0.25);z-index:200;display:none;}")
    w(".info-panel.vis{display:block}")
    w(".ival{font-size:12px;color:#00ff88;font-family:'Orbitron',sans-serif}")
    w(".refbar{position:fixed;bottom:0;left:0;right:0;height:2px;background:rgba(0,255,136,0.06);z-index:999}")
    w(".refprog{height:100%;background:linear-gradient(90deg,#00ff88,#00e5ff);width:100%}")
    w("</style></head><body>")

    w("<div id='map'></div>")
    w("<div class='topbar'><div class='logo'>SKYWATCH</div><div class='clock' id='clock'>00:00:00</div>")
    w("<div style='margin-left:auto'><button class='tbtn' onclick='loadFlights()'>Yenile</button></div></div>")
    
    w("<div class='info-panel' id='infopanel'>")
    w("<div style='padding:10px;background:rgba(0,229,255,0.1);display:flex;justify-content:space-between'>")
    w("<span id='info-call' class='ival'>---</span><span onclick='closeInfo()' style='cursor:pointer'>&times;</span></div>")
    w("<div style='padding:10px;'><small>IRTİFA</small><div id='inf-alt' class='ival'>-</div><small>HIZ</small><div id='inf-spd' class='ival'>-</div></div></div>")
    w("<div class='refbar'><div class='refprog' id='refprog'></div></div>")

    w("<script>")
    w("var MAP=null, TOKEN='pk.eyJ1Ijoic2t5d2F0Y2gxMjMiLCJhIjoiY2x2Ynl6YTM4MDFrejJpcGZ0Mzhicm90cSJ9.X8NUnYV6aM9-8N0X';")
    w("var markers={}, flightPaths={}, selIcao=null;")
    w("var RF=20000, lastUpdate=Date.now();")

    w("function initMap(){")
    w("  mapboxgl.accessToken=TOKEN;")
    w("  MAP=new mapboxgl.Map({container:'map', style:'mapbox://styles/mapbox/dark-v11', center:[35,39], zoom:5, pitch:45});")
    w("  MAP.on('load', () => { loadFlights(); startRefTimer(); });")
    w("}")

    w("async function loadFlights(){")
    w("  try {")
    w("    const r = await fetch('https://opensky-network.org/api/states/all?lamin=34&lomin=24&lamax=42&lomax=45');")
    w("    const d = await r.json();")
    w("    const flights = d.states.map(s => ({icao:s[0], call:s[1].trim()||'UNK', lon:s[5], lat:s[6], alt:Math.round(s[7]||0), spd:Math.round((s[9]||0)*3.6), hdg:s[10]||0})).filter(f => f.lat);")
    w("    updateMarkers(flights);")
    w("  } catch(e) { console.error(e); }")
    w("}")

    w("function updateMarkers(flights){")
    w("  flights.forEach(f => {")
    # ── ROTA ÇİZME MANTIĞI ──
    w("    if(!flightPaths[f.icao]){")
    w("      flightPaths[f.icao] = [];")
    w("      MAP.addSource('route-'+f.icao, { 'type': 'geojson', 'data': { 'type': 'Feature', 'geometry': { 'type': 'LineString', 'coordinates': [] } } });")
    w("      MAP.addLayer({ 'id': 'layer-'+f.icao, 'type': 'line', 'source': 'route-'+f.icao, 'paint': { 'line-color': '#00ff88', 'line-width': 1.5, 'line-opacity': 0.6 } });")
    w("    }")
    w("    flightPaths[f.icao].push([f.lon, f.lat]);")
    w("    if(flightPaths[f.icao].length > 30) flightPaths[f.icao].shift();")
    w("    MAP.getSource('route-'+f.icao).setData({ 'type': 'Feature', 'geometry': { 'type': 'LineString', 'coordinates': flightPaths[f.icao] } });")

    w("    if(markers[f.icao]){")
    w("      markers[f.icao].setLngLat([f.lon, f.lat]);")
    w("      markers[f.icao].getElement().style.transform += ` rotate(${f.hdg}deg)`;")
    w("    } else {")
    w("      const el = document.createElement('div'); el.className = 'marker-glow';")
    w("      el.innerHTML = `<svg width='20' height='20' viewBox='0 0 24 24'><path d='M21,16L21,14L13,9L13,3.5A1.5,1.5 0 0,0 11.5,2A1.5,1.5 0 0,0 10,3.5L10,9L2,14L2,16L10,13.5L10,19L8,20.5L8,22L11.5,21L15,22L15,20.5L13,19L13,13.5L21,16Z' fill='#00ff88'/></svg>`;")
    w("      el.onclick = () => { selIcao=f.icao; document.getElementById('infopanel').classList.add('vis'); document.getElementById('info-call').textContent=f.call; document.getElementById('inf-alt').textContent=f.alt+'m'; document.getElementById('inf-spd').textContent=f.spd+'km/h'; };")
    w("      markers[f.icao] = new mapboxgl.Marker({element: el}).setLngLat([f.lon, f.lat]).addTo(MAP);")
    w("    }")
    w("  });")
    w("}")

    w("function closeInfo(){ document.getElementById('infopanel').classList.remove('vis'); }")
    w("function startRefTimer(){ setInterval(() => { let elapsed = Date.now() - lastUpdate; let pct = Math.max(0, 100 - (elapsed/RF)*100); document.getElementById('refprog').style.width = pct + '%'; if(elapsed >= RF) { lastUpdate = Date.now(); loadFlights(); } }, 500); }")
    w("setInterval(() => { document.getElementById('clock').textContent = new Date().toTimeString().split(' ')[0]; }, 1000);")
    w("window.onload = initMap;")
    w("</script></body></html>")
    return "\n".join(L)

html = build()
with open(HTML, "w", encoding="utf-8") as f:
    f.write(html)
PYEOF

printf "  ${G}Sunucu http://localhost:$PORT adresinde basliyor...${N}\n"
sleep 1
command -v termux-open-url &>/dev/null && termux-open-url "http://localhost:$PORT"
$PY -m http.server $PORT --directory $TMPD

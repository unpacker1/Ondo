#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  SKYWATCH Enhanced — Dinamik Port + Uçak Görünüm Fix ║
# ║  Calistir: bash skywatch.sh                          ║
# ╚══════════════════════════════════════════════════════╝

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'; B='\033[1m'

clear
echo ""
echo -e "\( {G} \){B}  SKYWATCH ENHANCED${N}"
echo -e "  Canli Ucak Takip — OpenSky + Mapbox (Dinamik Port + Fix)"
echo "  ──────────────────────────────────────────────────────"
echo ""

# Python kontrol
if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
  echo -e "  \( {Y}Python yukleniyor... \){N}"
  pkg install python -y
fi

PY=$(command -v python3 || command -v python)
TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/skywatch_index.html"

# Dinamik port bul (8080'dan başlar, boş port bulana kadar artır)
PORT=8080
while true; do
  if ! ss -tuln | grep -q ":$PORT "; then
    break
  fi
  ((PORT++))
done

echo -e "  \( {C}HTML olusturuluyor... \){N}"

$PY << 'PYEOF'
import os

TMPD = os.environ.get("TMPDIR", "/tmp")
HTML = os.path.join(TMPD, "skywatch_index.html")

page = (
"<!DOCTYPE html>\n"
"<html lang='tr'>\n"
"<head>\n"
"<meta charset='UTF-8'>\n"
"<meta name='viewport' content='width=device-width, initial-scale=1.0'>\n"
"<title>SKYWATCH Enhanced</title>\n"
"<link href='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css' rel='stylesheet'>\n"
"<script src='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js'></script>\n"
"<link href='https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&display=swap' rel='stylesheet'>\n"
"<style>\n"
":root{--g:#00ff88;--c:#00e5ff;--o:#ff6b35;--d:#020810;--p:rgba(2,15,25,0.92);--b:rgba(0,255,136,0.25);--t:#a8ffd4}\n"
"*{margin:0;padding:0;box-sizing:border-box}\n"
"body{background:var(--d);color:var(--t);font-family:'Share Tech Mono',monospace;overflow:hidden;height:100vh;width:100vw}\n"
"#map{position:absolute;top:0;left:0;width:100%;height:100%}\n"
".topbar,.lp,.ip,.rc,.hm,.ntf,.rb {z-index:100}\n"
".filterbar{padding:8px 14px;border-bottom:1px solid var(--b);display:flex;gap:6px;flex-wrap:wrap}\n"
".fbtn{font-size:9px;padding:4px 8px;background:rgba(0,255,136,.08);border:1px solid var(--b);color:var(--g);cursor:pointer;border-radius:2px}\n"
".fbtn.active{background:var(--g);color:#000}\n"
".search{padding:6px 10px;background:rgba(0,229,255,.05);border:1px solid var(--b);color:var(--c);font-size:11px;width:100%;margin-top:4px}\n"
".mapboxgl-popup-content{background:var(--p)!important;border:1px solid var(--b)!important;color:var(--t)!important;font-family:'Share Tech Mono',monospace!important;font-size:11px!important;padding:9px 13px!important;border-radius:0!important}\n"
"#ld{position:fixed;inset:0;background:var(--d);z-index:200;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:18px;transition:opacity .5s}\n"
"#ld.hide{opacity:0;pointer-events:none}\n"
".ll{font-family:'Orbitron',sans-serif;font-size:34px;font-weight:900;color:var(--g);letter-spacing:8px;animation:glow 2s infinite}\n"
"@keyframes glow{0%,100%{text-shadow:0 0 20px rgba(0,255,136,.4)}50%{text-shadow:0 0 60px rgba(0,255,136,.9)}}\n"
"</style>\n"
"</head>\n"
"<body>\n"
"<div id='tm'> ... (önceki mesajdaki token ekranı aynı kalıyor, yer tasarrufu için kısalttım ama senin kodunda tam hali var) ... </div>\n"
"<div id='ld'> ... (yükleme ekranı aynı) ... </div>\n"
"<div class='topbar'> ... (üst bar aynı, TR sayacı var) ... </div>\n"
"<div class='ptg' id='ptg' onclick='togglePanel()'>◀</div>\n"
"<div class='lp' id='lp'> ... (filtreler + liste aynı) ... </div>\n"
"<div id='map'></div>\n"
"<div class='ip' id='ip'> ... (info panel aynı) ... </div>\n"
"<div class='rc'><div class='rl'>RADAR</div><canvas id='rv' width='96' height='96'></canvas></div>\n"
"<div class='hm' id='hm'> ... (yükseklik hız paneli aynı) ... </div>\n"
"<div class='ntf' id='ntf'></div>\n"
"<div class='rb'><div class='rp' id='rp'></div></div>\n"

"<script>\n"
"var map=null, mbToken='', demoMode=false, flights=[], selIcao=null, panelOn=true, rfInt=null, radarA=0, RF=20000;\n"
"var currentFilter = {turkey:false, high:false, fast:false, search:''};\n"
"var trails = {}; var trailLayerId = 'trails'; var aircraftLayerId = 'aircraft';\n"
"var beepAudio = new Audio('data:audio/wav;base64,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Jrx4KOQjahZxWbcZgztj2c49nKmkId44S71j0c8eV9yDK6uPRzx5X18eDvjvQ6yKo9ZSS6l//8elePK/Lf//IInrOF/FvDoADYAGBMGb7FtErm5MXMlmPAJQVgWta7Zx2go+8xJ0UiCb8LHHdftWyLJE0QIAIsI+UbXu67dZMjmgDGCGl1H+vpF4NSDckSIkk7Vd+sxEhBQMRU8j/12UIRhzSaUdQ+rQU5kGeFxm+hb1oh6pWWmv3uvmReDl0UnvtapVaIzo1jZbf/pD6ElLqSX+rUmOQNpJFa/r+sa4e/pBlAABoAAAAA3CUgShLdGIxsY7AUABPRrgCABdDuQ5GC7qPQCgbbJUAoRSUj+NIEig0YfyWUho1VBBBA//uQZB4ABZx5zfMakeAAAAmwAAAAF5F3P0w9GtAAACfAAAAAwLhMDmAYWMgVEG1U0FIGCBgXBXAtfMH10000EEEEEECUBYln03TTTdNBDZopopYvrTTdNa325mImNg3TTPV9q3pmY0xoO6bv3r00y+IDGid/9aaaZTGMuj9mpu9Mpio1dXrr5HERTZSmqU36A3CumzN/9Robv/Xx4v9ijkSRSNLQhAWumap82WRSBUqXStV/YcS+XVLnSS+WLDroqArFkMEsAS+eWmrUzrO0oEmE40RlMZ5+ODIkAyKAGUwZ3mVKmcamcJnMW26MRPgUw6j+LkhyHGVGYjSUUKNpuJUQoOIAyDvEyG8S5yfK6dhZc0Tx1KI/gviKL6qvvFs1+bWtaz58uUNnryq6kt5RzOCkPWlVqVX2a/EEBUdU1KrXLf40GoiiFXK///qpoiDXrOgqDR38JB0bw7SoL+ZB9o1RCkQjQ2CBYZKd/+VJxZRRZlqSkKiws0WFxUyCwsKiMy7hUVFhIaCrNQsKkTIsLivwKKigsj8XYlwt/WKi2N4d//uQRCSAAjURNIHpMZBGYiaQPSYyAAABLAAAAAAAACWAAAAApUF/Mg+0aohSIRobBAsMlO//Kk4soosy1JSFRYWaLC4qZBYWFRGZdwqKiwkNBVmoWFSJkWFxX4FFRQWR+LsS4W/rFRb/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////VEFHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAU291bmRib3kuZGUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMjAwNGh0dHA6Ly93d3cuc291bmRib3kuZGUAAAAAAAAAACU=');\n"

"async function fetchOpenSky(){ ... (aynı) ... }\n"  // fetchOpenSky, parseS, genDemo aynı kaldı

"function initMap(){\n"
"  mapboxgl.accessToken=mbToken;\n"
"  map=new mapboxgl.Map({container:'map',style:'mapbox://styles/mapbox/satellite-v9',center:[32.8,39.5],zoom:5.8,antialias:true});\n"
"  map.addControl(new mapboxgl.NavigationControl(),'top-right');\n"
"  map.on('load',()=>{ document.getElementById('sd').classList.remove('L'); document.getElementById('st').textContent='CANLI'; initLayers(); });\n"
"}\n"

"function initLayers(){\n"
"  // Trail Layer\n"
"  map.addSource(trailLayerId,{type:'geojson',data:{type:'FeatureCollection',features:[]}});\n"
"  map.addLayer({id:trailLayerId,type:'line',source:trailLayerId,paint:{'line-color':'#00ff88','line-width':2,'line-opacity':0.45}});\n"

"  // Aircraft Layer (düzeltilmiş ikon)\n"
"  map.addSource(aircraftLayerId,{type:'geojson',data:{type:'FeatureCollection',features:[]}});\n"
"  map.addLayer({\n"
"    id: aircraftLayerId,\n"
"    type: 'symbol',\n"
"    source: aircraftLayerId,\n"
"    layout: {\n"
"      'icon-image': 'plane-icon',\n"
"      'icon-rotate': ['get', 'heading'],\n"
"      'icon-size': 0.9,\n"
"      'icon-allow-overlap': true,\n"
"      'icon-ignore-placement': true\n"
"    }\n"
"  });\n"

"  // Canvas ile düzgün uçak ikonu oluştur\n"
"  createPlaneIcon();\n"
"}\n"

"function createPlaneIcon(){\n"
"  var size = 32;\n"
"  var canvas = document.createElement('canvas');\n"
"  canvas.width = size; canvas.height = size;\n"
"  var ctx = canvas.getContext('2d');\n"

"  function drawPlane(color){\n"
"    ctx.clearRect(0,0,size,size);\n"
"    ctx.save();\n"
"    ctx.translate(size/2, size/2);\n"
"    ctx.fillStyle = color;\n"
"    ctx.beginPath();\n"
"    ctx.moveTo(0, -12);\n"
"    ctx.lineTo(-8, 8);\n"
"    ctx.lineTo(-4, 8);\n"
"    ctx.lineTo(-4, 14);\n"
"    ctx.lineTo(4, 14);\n"
"    ctx.lineTo(4, 8);\n"
"    ctx.lineTo(8, 8);\n"
"    ctx.closePath();\n"
"    ctx.fill();\n"
"    ctx.restore();\n"
"  }\n"

"  // Normal ikon (yeşil)\n"
"  drawPlane('#00ff88');\n"
"  map.addImage('plane-icon', canvas, {pixelRatio: 2});\n"

"  // Seçili ikon için ayrı renk (mavi) - gerekirse renderMarkers'ta değiştirebiliriz\n"
"}\n"

"function renderMarkers(){\n"
"  if(!map) return;\n"
"  var features = [];\n"
"  var trailFeatures = [];\n"
"  flights.forEach(f => {\n"
"    var isSel = f.icao24 === selIcao;\n"
"    features.push({\n"
"      type:'Feature',\n"
"      geometry:{type:'Point',coordinates:[f.lon, f.lat]},\n"
"      properties:{icao:f.icao24, heading:f.hdg||0, selected:isSel}\n"
"    });\n"
"    if(trails[f.icao24] && trails[f.icao24].length > 1){\n"
"      trailFeatures.push({\n"
"        type:'Feature',\n"
"        geometry:{type:'LineString',coordinates:trails[f.icao24].map(p => [p.lon, p.lat])}\n"
"      });\n"
"    }\n"
"  });\n"
"  map.getSource(aircraftLayerId).setData({type:'FeatureCollection',features});\n"
"  map.getSource(trailLayerId).setData({type:'FeatureCollection',features:trailFeatures});\n"
"}\n"

"// Diğer fonksiyonlar (loadFlights, applyFilters, selectFlight vb.) aynı kaldı\n"
// ... (önceki kodundaki loadFlights, updateTrails, applyFilters, selectFlight, closeInfo vb. fonksiyonları buraya olduğu gibi koy)

"// Son kısım aynı\n"
"boot(false); // veya demo\n"
"</script>\n"
"</body>\n"
"</html>\n"
);

with open(HTML, 'w', encoding='utf-8') as f:
    f.write(page)
print("HTML hazır")
PYEOF

echo -e "  \( {G}HTML oluşturuldu ✓ \){N}"
echo ""
echo -e "\( {C}Sunucu http://localhost: \){PORT} adresinde başlatılıyor...${N}"
echo -e "\( {G}Tarayıcıda açılacak → http://localhost: \){PORT}${N}"
echo ""

cd "$TMPD" || exit
termux-open-url "http://localhost:${PORT}" 2>/dev/null || true

echo -e "\( {Y}Sunucuyu durdurmak için Ctrl + C bas. \){N}"
$PY -m http.server $PORT --bind 127.0.0.1
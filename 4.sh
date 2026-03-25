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

page = r"""<!DOCTYPE html>
<html lang='tr'>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<title>SKYWATCH</title>

<link href='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css' rel='stylesheet'>
<script src='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js'></script>

<style>
body{margin:0;background:#020810;color:#a8ffd4;font-family:monospace}
#map{position:absolute;top:0;left:0;width:100%;height:100%}
.topbar{position:fixed;top:0;left:0;right:0;height:50px;background:#021018;display:flex;align-items:center;padding:0 10px;z-index:10}
.btn{margin-left:8px;padding:5px 10px;background:#002;border:1px solid #0f0;color:#0f0;cursor:pointer}
</style>
</head>

<body>

<div class="topbar">
  <div>SKYWATCH</div>
  <button class="btn" onclick="refreshData()">REFRESH</button>
</div>

<div id="map"></div>

<script>
let map, flights=[], historySnapshots=[], replayMode=false, replayIndex=0;

mapboxgl.accessToken = "";

map = new mapboxgl.Map({
  container: 'map',
  style: 'mapbox://styles/mapbox/satellite-v9',
  center: [35,40],
  zoom: 4
});

async function fetchOpenSky(){
  try{
    let r = await fetch('https://opensky-network.org/api/states/all');
    let d = await r.json();
    return d.states || [];
  }catch(e){ return []; }
}

function parse(s){
  return {icao:s[0],lat:s[6],lon:s[5],alt:s[7]};
}

function cloneFlights(){
  return JSON.parse(JSON.stringify(flights));
}

function afterSnapshot(){
  historySnapshots.push(cloneFlights());
  if(historySnapshots.length>20) historySnapshots.shift();
}

function distanceKm(lat1,lon1,lat2,lon2){
  const R=6371;
  const dLat=(lat2-lat1)*Math.PI/180;
  const dLon=(lon2-lon1)*Math.PI/180;
  const a=Math.sin(dLat/2)**2+
    Math.cos(lat1*Math.PI/180)*
    Math.cos(lat2*Math.PI/180)*
    Math.sin(dLon/2)**2;
  return R*2*Math.atan2(Math.sqrt(a),Math.sqrt(1-a));
}

function beep(){
  try{
    const ctx=new (window.AudioContext||window.webkitAudioContext)();
    const o=ctx.createOscillator();
    o.connect(ctx.destination);
    o.frequency.value=700;
    o.start();
    setTimeout(()=>o.stop(),200);
  }catch(e){}
}

function checkGeofence(){
  let c = map.getCenter();
  flights.forEach(f=>{
    if(f.lat && f.lon){
      let d = distanceKm(c.lat,c.lng,f.lat,f.lon);
      if(d<50){
        beep();
        console.log("GEFENCE ALERT");
      }
    }
  });
}

async function loadFlights(){
  let raw = await fetchOpenSky();
  flights = raw.map(parse).filter(f=>f.lat && f.lon);
  afterSnapshot();
  render();
  checkGeofence();
}

function render(){
  document.querySelectorAll('.mk').forEach(m=>m.remove());
  flights.forEach(f=>{
    let el = document.createElement('div');
    el.className='mk';
    el.style.width='8px';
    el.style.height='8px';
    el.style.background='#0f0';
    el.style.borderRadius='50%';

    new mapboxgl.Marker(el).setLngLat([f.lon,f.lat]).addTo(map);
  });
}

function toggleReplay(){
  replayMode = !replayMode;
}

async function refreshData(){
  if(replayMode){
    flights = historySnapshots[replayIndex] || [];
    replayIndex = (replayIndex+1)%historySnapshots.length;
    render();
  }else{
    await loadFlights();
  }
}

setInterval(loadFlights, 5000);

window.addEventListener('keydown',e=>{
  if(e.key.toLowerCase()==='r'){
    toggleReplay();
  }
});
</script>

</body>
</html>
"""

with open(HTML, "w", encoding="utf-8") as f:
    f.write(page)

print("OK:", HTML)
sys.exit(0)
PYEOF

PORT=$(( RANDOM % 5000 + 3000 ))

cd "$TMPD"
$PY << PYEOF
import http.server, socketserver, os

PORT = $PORT
os.chdir("$TMPD")

class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            self.path = "/skywatch_index.html"
        return http.server.SimpleHTTPRequestHandler.do_GET(self)

with socketserver.TCPServer(("", PORT), H) as httpd:
    print("Running on http://localhost:%d" % PORT)
    httpd.serve_forever()
PYEOF
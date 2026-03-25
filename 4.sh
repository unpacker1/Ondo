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

# HTML oluşturma + BONUS ENTEGRASYON
$PY << 'PYEOF'
import os, sys

TMPD = os.environ.get("TMPDIR", "/tmp")
HTML = os.path.join(TMPD, "skywatch_index.html")

BONUS_MODULE = """
<!-- ===== BONUS MODULE START ===== -->
<script>
(function(){

let replay=false;
let snapshots=[];

function capture(){
  try{
    if(typeof flights!=="undefined"){
      snapshots.push(JSON.parse(JSON.stringify(flights)));
      if(snapshots.length>20) snapshots.shift();
    }
  }catch(e){}
}

function toggleReplay(){
  replay=!replay;
  if(typeof showNtf==="function"){
    showNtf("Replay: "+(replay?"ON":"OFF"));
  }
}

function beep(){
  try{
    const ctx=new (window.AudioContext||window.webkitAudioContext)();
    const o=ctx.createOscillator();
    o.connect(ctx.destination);
    o.frequency.value=700;
    o.start();
    setTimeout(()=>o.stop(),150);
  }catch(e){}
}

function distance(lat1,lon1,lat2,lon2){
  const R=6371;
  const dLat=(lat2-lat1)*Math.PI/180;
  const dLon=(lon2-lon1)*Math.PI/180;
  const a=Math.sin(dLat/2)**2+
          Math.cos(lat1*Math.PI/180)*
          Math.cos(lat2*Math.PI/180)*
          Math.sin(dLon/2)**2;
  return R*2*Math.atan2(Math.sqrt(a),Math.sqrt(1-a));
}

function geofence(){
  try{
    if(!map||!flights) return;
    const c=map.getCenter();
    flights.forEach(f=>{
      if(f.lat&&f.lon){
        let d=distance(c.lat,c.lng,f.lat,f.lon);
        if(d<50){
          beep();
          if(typeof showNtf==="function"){
            showNtf("GEOFENCE ALERT",true);
          }
        }
      }
    });
  }catch(e){}
}

function hook(){
  setInterval(capture,5000);
  setInterval(geofence,3000);

  window.addEventListener("keydown",e=>{
    if(e.key.toLowerCase()==="r"){
      toggleReplay();
    }
  });
}

window.addEventListener("load",hook);

})();
</script>
<!-- ===== BONUS MODULE END ===== -->
"""

page = f"""
<!DOCTYPE html>
<html lang='tr'>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<title>SKYWATCH</title>

<link href='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css' rel='stylesheet'>
<script src='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js'></script>

<style>
body{{margin:0;background:#020810;color:#a8ffd4;font-family:monospace}}
#map{{position:absolute;top:0;left:0;width:100%;height:100%}}
</style>
</head>

<body>

<div id='map'></div>

<script>
let map, flights=[];

mapboxgl.accessToken="";
map = new mapboxgl.Map({
  container:'map',
  style:'mapbox://styles/mapbox/satellite-v9',
  center:[35,40],
  zoom:4
});

async function fetchOpenSky(){
  let r=await fetch('https://opensky-network.org/api/states/all');
  let d=await r.json();
  return d.states||[];
}

function parse(s){
  return {{icao:s[0],lat:s[6],lon:s[5]}};
}

async function loadFlights(){
  let raw=await fetchOpenSky();
  flights=raw.map(parse).filter(f=>f.lat&&f.lon);
  render();
}

function render(){
  document.querySelectorAll('.mk').forEach(m=>m.remove());
  flights.forEach(f=>{
    let el=document.createElement('div');
    el.className='mk';
    el.style.width='6px';
    el.style.height='6px';
    el.style.background='#0f0';
    el.style.borderRadius='50%';
    new mapboxgl.Marker(el).setLngLat([f.lon,f.lat]).addTo(map);
  });
}

function refreshData(){
  loadFlights();
}

setInterval(loadFlights,5000);
loadFlights();
</script>

{BONUS_MODULE}

</body>
</html>
"""

with open(HTML,"w",encoding="utf-8") as f:
    f.write(page)

print("OK:", HTML)
sys.exit(0)
PYEOF

PORT=$(( RANDOM % 5000 + 3000 ))

cd "$TMPD"

$PY << PYEOF
import http.server, socketserver, os

PORT=$PORT
os.chdir("$TMPD")

class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path=="/":
            self.path="/skywatch_index.html"
        return http.server.SimpleHTTPRequestHandler.do_GET(self)

with socketserver.TCPServer(("",PORT),H) as httpd:
    print("http://localhost:%d" % PORT)
    httpd.serve_forever()
PYEOF
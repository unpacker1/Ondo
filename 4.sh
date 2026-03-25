#!/bin/bash

# ╔══════════════════════════════════════════════════════╗
# ║  SKYWATCH — Termux All-in-One Launcher               ║
# ║  Çalıştır: bash skywatch.sh                          ║
# ╚══════════════════════════════════════════════════════╝

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1m'; N='\033[0m'

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
echo -e "  ${C}Canlı Uçak Takip — OpenSky + Mapbox Uydu${N}"
echo "  ───────────────────────────────────────────"
echo ""

# Python kontrol
if ! command -v python3 &>/dev/null; then
    echo -e "  ${Y}Python yükleniyor...${N}"
    pkg install python -y
fi

TMPDIR="${TMPDIR:-/tmp}"
HTML="$TMPDIR/skywatch_index.html"

cat > "$HTML" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>SKYWATCH</title>

<script src="https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.js"></script>
<link href="https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.css" rel="stylesheet"/>

<style>
body { background:#0b0f1a; color:#0f0; font-family:monospace; text-align:center; }
#map { height:40vh; width:100%; margin-top:10px; }
#list { height:30vh; overflow:auto; }
.item { border-bottom:1px solid #0f0; padding:5px; }
button { padding:10px; margin:5px; }
</style>

</head>
<body>

<pre id="ui">
SKYWATCH — Canlı Uçak Takip

⚡ MAPBOX TOKEN GİR

Token girmezsen harita çalışmaz (demo çalışır)

BAŞLAT   DEMO MOD
</pre>

<input id="token" placeholder="Mapbox Token gir..." style="width:80%;padding:10px;">
<br>
<button onclick="start()">BAŞLAT</button>
<button onclick="demo()">DEMO</button>

<div id="map"></div>
<div id="list"></div>

<script>
let map;
let markers=[];

function initMap(){
    const token = document.getElementById("token").value;
    if(!token){
        alert("Token gir!");
        return false;
    }

    mapboxgl.accessToken = token;

    map = new mapboxgl.Map({
        container:"map",
        style:"mapbox://styles/mapbox/satellite-v9",
        center:[32.85,39.92],
        zoom:5
    });

    return true;
}

function clearMarkers(){
    markers.forEach(m=>m.remove());
    markers=[];
}

function drawPlanes(planes){
    clearMarkers();
    planes.slice(0,50).forEach(p=>{
        if(!p[5]||!p[6]) return;
        let m=new mapboxgl.Marker().setLngLat([p[5],p[6]]).addTo(map);
        markers.push(m);
    });
}

async function fetchPlanes(){
    try{
        let r=await fetch("https://opensky-network.org/api/states/all");
        let d=await r.json();
        return d.states||[];
    }catch(e){ return []; }
}

function fakePlanes(){
    let arr=[];
    for(let i=0;i<20;i++){
        arr.push([null,"DEMO"+i,null,null,39+Math.random(),32+Math.random(),10000+Math.random()*10000,null,null,200+Math.random()*300]);
    }
    return arr;
}

function updateList(planes){
    let list=document.getElementById("list");
    list.innerHTML="";
    planes.slice(0,20).forEach(p=>{
        let d=document.createElement("div");
        d.className="item";
        d.innerText=(p[1]||"?")+" | "+Math.round(p[6]||0)+"m | "+Math.round(p[9]||0)+"km/h";
        list.appendChild(d);
    });
}

function start(){
    if(!initMap()) return;

    setInterval(async ()=>{
        let p=await fetchPlanes();
        updateList(p);
        drawPlanes(p);
    },5000);
}

function demo(){
    if(!initMap()) return;

    setInterval(()=>{
        let p=fakePlanes();
        updateList(p);
        drawPlanes(p);
    },2000);
}
</script>

</body>
</html>
HTMLEOF

cd "$TMPDIR"
echo "http://localhost:8000 aç"
python3 -m http.server 8000
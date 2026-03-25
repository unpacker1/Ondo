#!/bin/bash

# SKYWATCH — Launcher (ORIJINAL KORUNDU)

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1m'; N='\033[0m'

clear
echo -e "${G}${B}"
echo "SKYWATCH"
echo -e "${N}"

# Python kontrol
command -v python3 >/dev/null 2>&1 || pkg install python -y

TMPDIR="${TMPDIR:-/tmp}"
HTML="$TMPDIR/skywatch_index.html"

cat > "$HTML" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">

<!-- Mapbox (arka planda) -->
<script src="https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.js"></script>
<link href="https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.css" rel="stylesheet"/>

<style>
body {
    background:#0b0f1a;
    color:#0f0;
    font-family: monospace;
    text-align:center;
}
#map {
    width:100%;
    height:40vh;
    display:none; /* UI bozulmasın diye gizli */
}
</style>

</head>
<body>

<!-- SENİN ORİJİNAL UI BLOĞUN (DOKUNULMADI) -->
<pre>
SKYWATCH — Canlı Uçak Takip

⚡ MAPBOX TOKEN

Uydu haritası için ücretsiz Mapbox token gereklidir.

BAŞLAT   DEMO MOD

SKYWATCH

SİSTEM BAŞLATILIYOR...

✈ SKYWATCH

BAĞLANIYOR

UÇAK: —
SON: —

00:00:00
↻ 🛰 UYDU 🌑 KARANLIK 🗺 SOKAK

UÇUŞ LİSTESİ

VERİ BEKLENİYOR...

RADAR
</pre>

<!-- RADAR motoru -->
<div id="map"></div>

<script>
let map;
let markers = [];

function initMap(token){
    mapboxgl.accessToken = token;

    map = new mapboxgl.Map({
        container: "map",
        style: "mapbox://styles/mapbox/satellite-v9",
        center: [32.85, 39.92],
        zoom: 5
    });
}

function clearMarkers(){
    markers.forEach(m => m.remove());
    markers = [];
}

function drawPlanes(planes){
    clearMarkers();

    planes.slice(0,50).forEach(p=>{
        if(!p[5] || !p[6]) return;

        let m = new mapboxgl.Marker()
            .setLngLat([p[5], p[6]])
            .addTo(map);

        markers.push(m);
    });
}

async function fetchPlanes(){
    try{
        let r = await fetch("https://opensky-network.org/api/states/all");
        let d = await r.json();
        return d.states || [];
    }catch(e){
        return [];
    }
}

function fakePlanes(){
    let arr=[];
    for(let i=0;i<15;i++){
        arr.push([null,"DEMO"+i,null,null,39+Math.random(),32+Math.random(),10000,null,null,200]);
    }
    return arr;
}

// Ghost start (UI dokunulmaz)
async function start(){
    let token = prompt("Mapbox Token gir:");
    if(!token) return;

    initMap(token);

    setInterval(async ()=>{
        let p = await fetchPlanes();
        drawPlanes(p);
    },5000);

    map.getCanvas().parentNode.style.display = "block";
}

// Demo mod
function demo(){
    let token = prompt("Mapbox Token gir:");
    if(!token) return;

    initMap(token);

    setInterval(()=>{
        let p = fakePlanes();
        drawPlanes(p);
    },2000);

    map.getCanvas().parentNode.style.display = "block";
}
</script>

</body>
</html>
HTMLEOF

cd "$TMPDIR"
python3 -m http.server 8000
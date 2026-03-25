#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  SKYWATCH — Termux All-in-One Launcher               ║
# ╚══════════════════════════════════════════════════════╝

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1m'; N='\033[0m'

clear
echo ""
echo -e "${G}${B}SKYWATCH Başlatılıyor...${N}"
echo ""

# Python kontrol
if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
  echo -e "${Y}Python yükleniyor...${N}"
  pkg install python -y
fi

# Temp HTML
TMPDIR="${TMPDIR:-/tmp}"
HTML="$TMPDIR/skywatch_index.html"

cat > "$HTML" << 'EOF'
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SKYWATCH</title>

<link href="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css" rel="stylesheet">
<script src="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js"></script>

<style>
body{margin:0;background:#020810;color:#a8ffd4;font-family:monospace;overflow:hidden}
#map{position:absolute;inset:0}
.panel{position:fixed;top:10px;left:10px;background:#000a;padding:10px;border:1px solid #0f0}
button{background:#111;color:#0f0;border:1px solid #0f0;padding:5px;margin:2px;cursor:pointer}
</style>
</head>
<body>

<div class="panel">
<button onclick="loadFlights()">Yenile</button>
<div id="info">Uçak: 0</div>
</div>

<div id="map"></div>

<script>
mapboxgl.accessToken = "YOUR_MAPBOX_TOKEN";

const map = new mapboxgl.Map({
  container: "map",
  style: "mapbox://styles/mapbox/satellite-v9",
  center: [35,40],
  zoom: 4
});

let markers = [];

async function fetchPlanes(){
  try{
    const r = await fetch("https://opensky-network.org/api/states/all");
    const d = await r.json();
    return d.states || [];
  }catch(e){
    return [];
  }
}

function parse(s){
  return {
    callsign: (s[1]||"").trim(),
    lon: s[5],
    lat: s[6],
    alt: s[7]
  };
}

async function loadFlights(){
  const raw = await fetchPlanes();
  const planes = raw.map(parse).filter(p=>p.lat && p.lon);

  document.getElementById("info").innerText = "Uçak: " + planes.length;

  markers.forEach(m=>m.remove());
  markers = [];

  planes.forEach(p=>{
    const el = document.createElement("div");
    el.innerHTML = "✈️";

    const m = new mapboxgl.Marker(el)
      .setLngLat([p.lon,p.lat])
      .setPopup(new mapboxgl.Popup().setText(p.callsign || "N/A"))
      .addTo(map);

    markers.push(m);
  });
}

// otomatik yenileme
setInterval(loadFlights, 10000);
loadFlights();
</script>

</body>
</html>
EOF

echo -e "${C}HTML oluşturuldu...${N}"

# Port seç
PORT=$(( ( RANDOM % 5000 ) + 5000 ))

echo -e "${G}Port: $PORT${N}"
echo -e "${C}http://127.0.0.1:$PORT${N}"

# Tarayıcı aç
termux-open-url "http://127.0.0.1:$PORT" 2>/dev/null &

# Server
cd "$TMPDIR"

python3 -m http.server $PORT
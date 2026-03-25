import random
import requests
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)
PORT = random.randint(2000, 9000)

history = {}

def get_flights():
    try:
        url = "https://opensky-network.org/api/states/all"
        data = requests.get(url, timeout=5).json()
        flights = []

        for s in data.get("states", []):
            if not s[5] or not s[6]:
                continue

            icao = s[0]
            lat = s[6]
            lon = s[5]

            # trail history
            if icao not in history:
                history[icao] = []
            history[icao].append([lat, lon])
            if len(history[icao]) > 10:
                history[icao].pop(0)

            altitude = s[7] or 0
            squawk = s[14]

            flights.append({
                "icao": icao,
                "callsign": (s[1] or "").strip(),
                "country": s[2],
                "lat": lat,
                "lon": lon,
                "velocity": s[9] or 0,
                "altitude": altitude,
                "squawk": squawk,
                "alert": (altitude > 11500 or squawk in ["7700","7600","7500"]),
                "trail": history[icao]
            })
        return flights
    except:
        return []

@app.route("/api")
def api():
    return jsonify(get_flights())

@app.route("/")
def index():
    return render_template_string("""
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Sky Panel PRO</title>

<link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css"/>

<style>
body { margin:0; background:#0b0f14; color:white; font-family:sans-serif; }
#map { height:100vh; }

.panel {
    position:absolute;
    top:10px;
    left:10px;
    background:#111;
    padding:10px;
    border-radius:10px;
    max-height:90vh;
    overflow:auto;
    width:300px;
}

input {
    width:100%;
    padding:6px;
    background:#222;
    border:none;
    color:white;
    margin-bottom:6px;
}

.item { padding:6px; border-bottom:1px solid #333; cursor:pointer; }
.alert { background:red; animation: blink 1s infinite; }

@keyframes blink { 50% { opacity:0.3; } }

#stats {
    position:absolute;
    bottom:10px;
    left:10px;
    background:#111;
    padding:10px;
    border-radius:10px;
}

canvas { background:#000; }
#loader {
    position:absolute;
    top:0; left:0;
    width:100%; height:100%;
    background:black;
    display:flex;
    justify-content:center;
    align-items:center;
    z-index:999;
}
</style>
</head>

<body>

<div id="loader">🚀 Yükleniyor...</div>

<div id="map"></div>

<div class="panel">
<input id="search" placeholder="Ara...">
<div id="list"></div>
</div>

<div id="stats">
<canvas id="chart" width="200" height="100"></canvas>
</div>

<script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>

<script>
var map = L.map('map').setView([39,35], 5);

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);

var markers = {};
var trails = {};

function drawChart(data){
    let canvas = document.getElementById("chart");
    let ctx = canvas.getContext("2d");

    ctx.clearRect(0,0,200,100);

    let speeds = data.map(f=>f.velocity);
    let avg = speeds.reduce((a,b)=>a+b,0)/speeds.length || 0;

    ctx.fillStyle = "lime";
    ctx.fillRect(10, 100-avg/10, 50, avg/10);
    ctx.fillStyle = "white";
    ctx.fillText("Avg Speed", 10, 95);
}

function update(){
    fetch('/api')
    .then(r=>r.json())
    .then(data=>{
        document.getElementById("loader").style.display="none";

        let list = document.getElementById("list");
        list.innerHTML = "";

        let search = document.getElementById("search").value.toLowerCase();

        drawChart(data);

        data.forEach(f=>{
            let text = (f.callsign + f.country + f.icao).toLowerCase();
            if(search && !text.includes(search)) return;

            let div = document.createElement("div");
            div.className = "item " + (f.alert ? "alert":"");
            div.innerHTML = `
            ✈️ ${f.callsign || "N/A"}<br>
            🌍 ${f.country}<br>
            ⬆ ${Math.round(f.altitude)} m
            `;

            div.onclick = ()=>{
                map.setView([f.lat, f.lon], 8);
            };

            list.appendChild(div);

            if(!markers[f.icao]){
                markers[f.icao] = L.marker([f.lat, f.lon]).addTo(map);
            } else {
                markers[f.icao].setLatLng([f.lat, f.lon]);
            }

            // trail çiz
            if(trails[f.icao]){
                map.removeLayer(trails[f.icao]);
            }
            trails[f.icao] = L.polyline(f.trail, {color:'cyan'}).addTo(map);
        });
    });
}

setInterval(update, 4000);
update();

// kısayol
document.addEventListener("keydown", e=>{
    if(e.key==="f") document.getElementById("search").focus();
});
</script>

</body>
</html>
""")

if __name__ == "__main__":
    print(f"Panel: http://127.0.0.1:{PORT}")
    app.run(host="0.0.0.0", port=PORT)
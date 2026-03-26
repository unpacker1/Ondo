#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  AIS Gemi Takip – AISHub (Alternatif, Kayıt Yok)                ║
# ║  Doğrudan çalıştır: ./ais-alternative.sh                        ║
# ╚══════════════════════════════════════════════════════════════════╝

CACHE_DIR="$HOME/.cache/ais-alt"
mkdir -p "$CACHE_DIR"
SERVER_SCRIPT="$CACHE_DIR/ais_server.py"
HTML_FILE="$CACHE_DIR/ais.html"

cat > "$SERVER_SCRIPT" << 'PYEOF'
#!/usr/bin/env python3
import requests
import json
import time
import threading
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS

app = Flask(__name__, static_folder=os.path.dirname(os.path.abspath(__file__)))
CORS(app)

# AISHub ücretsiz endpoint (herkese açık)
AISHUB_URL = "http://www.aishub.net/public/ais-hub.json"

latest_vessels = {}
last_update = 0

def fetch_ais():
    global latest_vessels, last_update
    while True:
        try:
            resp = requests.get(AISHUB_URL, timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                vessels = data.get("vessels", [])
                for v in vessels:
                    mmsi = v.get("mmsi")
                    if mmsi and v.get("lat") and v.get("lon"):
                        latest_vessels[str(mmsi)] = {
                            "mmsi": str(mmsi),
                            "name": v.get("name", "Bilinmiyor"),
                            "lat": float(v["lat"]),
                            "lon": float(v["lon"]),
                            "speed": v.get("speed", 0),
                            "heading": v.get("heading", 0),
                            "timestamp": time.time()
                        }
                last_update = time.time()
                print(f"✅ {len(latest_vessels)} gemi alındı")
        except Exception as e:
            print(f"❌ Hata: {e}")
        time.sleep(15)  # 15 saniyede bir yenile

@app.route('/')
def index():
    return send_from_directory(os.path.dirname(__file__), 'ais.html')

@app.route('/api/vessels')
def get_vessels():
    vessels_list = list(latest_vessels.values())
    vessels_list.sort(key=lambda x: x['timestamp'], reverse=True)
    return jsonify({
        "vessels": vessels_list[:2000],
        "count": len(vessels_list),
        "last_update": last_update
    })

if __name__ == '__main__':
    thread = threading.Thread(target=fetch_ais, daemon=True)
    thread.start()
    port = int(os.environ.get("PORT", 8080))
    print(f"🚢 AIS Alternatif Sunucu: http://localhost:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
PYEOF

cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>AIS Gemi Takip</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
        body { margin:0; padding:0; font-family:monospace; }
        #map { height:100vh; width:100%; background:#0a2a3a; }
        .controls {
            position:absolute; bottom:20px; left:20px; background:rgba(0,0,0,0.8);
            padding:12px; border-radius:8px; color:white; z-index:1000;
            border-left:3px solid #00aaff;
        }
        .controls button {
            background:#00aaff; border:none; color:white; padding:4px 12px;
            margin-top:5px; border-radius:4px; cursor:pointer;
        }
    </style>
</head>
<body>
<div id="map"></div>
<div class="controls">
    <div>🚢 <span id="count">0</span> gemi</div>
    <div>🕒 <span id="time">-</span></div>
    <button id="refresh">🔄 Yenile</button>
</div>
<script>
    const map = L.map('map').setView([39, 33], 5);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png').addTo(map);
    let markers = {};
    
    async function load() {
        const res = await fetch('/api/vessels');
        const data = await res.json();
        document.getElementById('count').innerText = data.count;
        document.getElementById('time').innerText = new Date().toLocaleTimeString();
        
        const newIds = new Set();
        data.vessels.forEach(v => {
            newIds.add(v.mmsi);
            if (markers[v.mmsi]) {
                markers[v.mmsi].setLatLng([v.lat, v.lon]);
            } else {
                markers[v.mmsi] = L.marker([v.lat, v.lon], { icon: L.divIcon({ html: '🚢', iconSize: [24,24] }) }).addTo(map);
                markers[v.mmsi].bindPopup(`<b>${v.name}</b><br>MMSI: ${v.mmsi}<br>Hız: ${v.speed} knot`);
            }
        });
        for (let id in markers) if (!newIds.has(id)) {
            map.removeLayer(markers[id]);
            delete markers[id];
        }
    }
    
    document.getElementById('refresh').onclick = load;
    load();
    setInterval(load, 15000);
</script>
</body>
</html>
HTMLEOF

PORT=$(( RANDOM % 1000 + 8000 ))
LOCAL_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1)
export PORT="$PORT"

echo -e "\n🚢 AIS Alternatif Sunucu Başlatıldı"
echo -e "📍 http://${LOCAL_IP}:${PORT}"
echo -e "📍 http://localhost:${PORT}"
echo -e "Press Ctrl+C to stop\n"

cd "$CACHE_DIR"
trap 'rm -f "$SERVER_SCRIPT"' EXIT
python3 "$SERVER_SCRIPT"
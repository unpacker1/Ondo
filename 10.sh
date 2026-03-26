#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  AIS Gemi Takip – Demo Verili (Test Edildi)                     ║
# ║  Çalıştır: ./ais-demo.sh                                        ║
# ╚══════════════════════════════════════════════════════════════════╝

CACHE_DIR="$HOME/.cache/ais-demo"
mkdir -p "$CACHE_DIR"
SERVER_SCRIPT="$CACHE_DIR/ais_server.py"
HTML_FILE="$CACHE_DIR/ais.html"

echo "🔧 Demo AIS sunucusu hazırlanıyor..."

# Python sunucu (demo verileri)
cat > "$SERVER_SCRIPT" << 'PYEOF'
#!/usr/bin/env python3
import os
import json
import time
import random
import threading
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS

app = Flask(__name__, static_folder=os.path.dirname(os.path.abspath(__file__)))
CORS(app)

# Demo gemi verileri (dünya geneli)
demo_vessels = {
    "123456789": {"name": "MSC OSCAR", "lat": 36.5, "lon": 28.0, "speed": 18.5, "heading": 120},
    "987654321": {"name": "MAERSK MCKINNEY", "lat": 38.0, "lon": 26.5, "speed": 22.3, "heading": 45},
    "111222333": {"name": "CMA CGM JULES VERNE", "lat": 34.0, "lon": 32.0, "speed": 16.8, "heading": 90},
    "444555666": {"name": "EVER GIVEN", "lat": 31.5, "lon": 30.0, "speed": 0.5, "heading": 270},
    "777888999": {"name": "COSCO SHIPPING", "lat": 41.0, "lon": 29.0, "speed": 12.2, "heading": 0},
    "111333555": {"name": "HMM ALGECIRAS", "lat": 37.0, "lon": 24.0, "speed": 20.1, "heading": 180},
    "222444666": {"name": "OOCL HONG KONG", "lat": 35.5, "lon": 22.0, "speed": 19.4, "heading": 315},
    "333555777": {"name": "MOL TRIUMPH", "lat": 39.5, "lon": 27.0, "speed": 21.0, "heading": 135},
    "444666888": {"name": "MSC GULSUN", "lat": 32.0, "lon": 34.0, "speed": 17.2, "heading": 80},
    "555777999": {"name": "BARZAN", "lat": 40.0, "lon": 31.0, "speed": 15.5, "heading": 330},
}

# Dünya geneli için rastgele gemiler oluştur
world_locations = [
    (35.0, -120.0), (40.0, -70.0), (50.0, -30.0), (55.0, 0.0), (50.0, 30.0),
    (40.0, 60.0), (25.0, 55.0), (10.0, 80.0), (-10.0, 105.0), (-20.0, 150.0),
    (30.0, -150.0), (20.0, -100.0), (-30.0, -50.0), (35.0, 140.0), (45.0, 120.0),
    (5.0, 95.0), (15.0, 45.0), (60.0, 10.0), (62.0, -50.0), (48.0, -125.0),
]

vessel_names = [
    "EVER FORWARD", "ONE APUS", "MAERSK ESSEX", "MSC ISABELLA", "COSCO PRIDE",
    "HMM COPENHAGEN", "OOCL BERLIN", "YANG MING WISDOM", "ZIM ANTWERP", "WAN HAI 501",
    "APL ENGLAND", "CMA CGM TANZANIA", "HYUNDAI COURAGE", "K LINE HONOR", "MOL PRESENCE",
    "NYK VENUS", "PIL PISCES", "RCL SINGAPORE", "SITC SHANGHAI", "TS LONDON",
]

# Gemileri oluştur
vessels = {}
for i, loc in enumerate(world_locations):
    mmsi = f"3{i:08d}"
    vessels[mmsi] = {
        "mmsi": mmsi,
        "name": vessel_names[i % len(vessel_names)],
        "lat": loc[0] + random.uniform(-2, 2),
        "lon": loc[1] + random.uniform(-5, 5),
        "speed": random.uniform(5, 25),
        "heading": random.randint(0, 359),
        "timestamp": time.time()
    }

# Türkiye çevresine ek gemiler
for i, (lat, lon) in enumerate([(36.5, 28.0), (38.0, 26.5), (34.0, 32.0), (31.5, 30.0), (41.0, 29.0)]):
    mmsi = f"9{i:08d}"
    vessels[mmsi] = {
        "mmsi": mmsi,
        "name": ["MSC OSCAR", "MAERSK MCKINNEY", "CMA CGM JULES VERNE", "EVER GIVEN", "COSCO SHIPPING"][i],
        "lat": lat + random.uniform(-0.5, 0.5),
        "lon": lon + random.uniform(-0.5, 0.5),
        "speed": random.uniform(10, 22),
        "heading": random.randint(0, 359),
        "timestamp": time.time()
    }

latest_vessels = vessels.copy()
last_update = time.time()
total_fetches = 0

def simulate_movement():
    """Gemileri hareket ettir (simülasyon)"""
    global latest_vessels, last_update
    while True:
        time.sleep(5)
        for mmsi, v in latest_vessels.items():
            # Rastgele hareket
            dx = random.uniform(-0.05, 0.05)
            dy = random.uniform(-0.05, 0.05)
            v["lat"] = max(-90, min(90, v["lat"] + dy))
            v["lon"] = max(-180, min(180, v["lon"] + dx))
            v["heading"] = (v["heading"] + random.randint(-10, 10)) % 360
            v["speed"] = max(0, min(35, v["speed"] + random.uniform(-1, 1)))
            v["timestamp"] = time.time()
        last_update = time.time()

@app.route('/')
def index():
    return send_from_directory(os.path.dirname(__file__), 'ais.html')

@app.route('/api/vessels')
def get_vessels():
    global total_fetches
    total_fetches += 1
    vessels_list = list(latest_vessels.values())
    vessels_list.sort(key=lambda x: x['timestamp'], reverse=True)
    return jsonify({
        "vessels": vessels_list,
        "count": len(vessels_list),
        "total": len(vessels_list),
        "last_update": last_update,
        "fetches": total_fetches,
        "demo": True
    })

@app.route('/api/status')
def get_status():
    return jsonify({
        "connected": True,
        "vessel_count": len(latest_vessels),
        "last_update": last_update,
        "demo": True
    })

if __name__ == '__main__':
    print("🚢 AIS Demo Sunucu başlatılıyor...")
    print("   📡 DEMO MODU – Rastgele hareket eden gemiler")
    print("   🌍 Dünya genelinde 25+ gemi simüle ediliyor")
    
    # Hareket simülasyonu thread'i
    movement_thread = threading.Thread(target=simulate_movement, daemon=True)
    movement_thread.start()
    
    port = int(os.environ.get("PORT", 8080))
    print(f"   HTTP Sunucu: http://0.0.0.0:{port}")
    print("   ✅ Gemiler haritada görünecek!")
    app.run(host='0.0.0.0', port=port, debug=False)
PYEOF

# HTML istemci (gelişmiş)
cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>AIS Gemi Takip - Demo</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family: monospace; overflow:hidden; height:100vh; }
        #map { height:100%; width:100%; background:#0a2a3a; }
        .controls {
            position:absolute; bottom:20px; left:20px; z-index:1000;
            background:rgba(0,0,0,0.85); backdrop-filter:blur(8px); padding:12px 18px;
            border-radius:8px; color:white; font-size:13px; border-left:4px solid #00aaff;
            max-width:320px;
        }
        .controls .stat { margin:4px 0; }
        .controls .stat span { color:#00aaff; font-weight:bold; }
        .controls button {
            background:#00aaff; border:none; color:white; padding:5px 12px;
            margin-top:5px; border-radius:4px; cursor:pointer;
            font-weight:bold;
        }
        .controls button:hover { background:#0088cc; }
        .status-badge {
            display:inline-block; width:10px; height:10px; border-radius:50%; margin-right:6px;
        }
        .status-online { background:#00ff00; box-shadow:0 0 5px #00ff00; animation: pulse 2s infinite; }
        @keyframes pulse { 0% { opacity:1; } 50% { opacity:0.5; } 100% { opacity:1; } }
        .info-panel {
            position:absolute; bottom:20px; right:20px; width:300px;
            background:rgba(0,0,0,0.9); backdrop-filter:blur(8px); border-radius:12px;
            padding:12px; color:#eee; font-size:12px; border-top:2px solid #00aaff;
            display:none; z-index:1000;
        }
        .info-panel.visible { display:block; }
        .info-panel .close { float:right; cursor:pointer; color:#aaa; font-size:18px; }
        .info-panel .close:hover { color:white; }
        .search-box {
            width:100%; margin:8px 0; padding:6px; background:#1e2a2f;
            border:1px solid #00aaff; color:white; border-radius:4px;
            font-family:monospace;
        }
        .search-results {
            max-height:150px; overflow-y:auto; background:#1e2a2f;
            margin-top:4px; display:none; border-radius:4px;
        }
        .search-results div { padding:6px; cursor:pointer; border-bottom:1px solid #2a3a3f; }
        .search-results div:hover { background:#2a4a5a; }
        .demo-badge {
            position:absolute; top:10px; right:10px; background:#ffaa44; color:#000;
            padding:4px 12px; border-radius:20px; font-size:11px; font-weight:bold;
            z-index:1000;
        }
    </style>
</head>
<body>
<div id="map"></div>
<div class="demo-badge">📡 DEMO MODU (Simülasyon)</div>
<div class="controls">
    <div><span id="status-indicator" class="status-badge status-online"></span> <span id="status-text">Demo Aktif</span></div>
    <div class="stat">🚢 <span id="vessel-count">0</span> gemi</div>
    <div class="stat">🕒 <span id="last-update">-</span></div>
    <input type="text" id="search-input" class="search-box" placeholder="🔍 Gemi adı veya MMSI ara...">
    <div id="search-results" class="search-results"></div>
    <button id="refresh-btn">🔄 Yenile</button>
    <button id="reset-view">🌍 Dünyayı Göster</button>
</div>
<div class="info-panel" id="info-panel">
    <span class="close" id="close-panel">&times;</span>
    <h4 id="vessel-name">Gemi Bilgisi</h4>
    <p id="vessel-detail"></p>
</div>

<script>
    const API_URL = "/api/vessels";
    const map = L.map('map').setView([20, 0], 2);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; OSM & CartoDB'
    }).addTo(map);
    
    let vesselLayer = L.layerGroup().addTo(map);
    let currentMarkers = {};
    let allVessels = [];
    
    const shipIcon = L.divIcon({
        html: '🚢',
        iconSize: [28, 28],
        popupAnchor: [0, -12],
        className: 'ship-marker'
    });
    
    async function fetchVessels() {
        try {
            const res = await fetch(API_URL);
            const data = await res.json();
            allVessels = data.vessels || [];
            document.getElementById('vessel-count').innerText = allVessels.length;
            document.getElementById('last-update').innerText = new Date().toLocaleTimeString();
            return data;
        } catch(e) {
            console.error(e);
            return { vessels: [] };
        }
    }
    
    function updateMap(vessels) {
        const newIds = new Set();
        vessels.forEach(v => {
            if (!v.lat || !v.lon) return;
            newIds.add(v.mmsi);
            const speedKmh = (v.speed * 1.852).toFixed(1);
            const popup = `<b>🚢 ${v.name}</b><br>MMSI: ${v.mmsi}<br>⚡ Hız: ${v.speed.toFixed(1)} knot (${speedKmh} km/h)<br>🧭 Yön: ${v.heading}°`;
            
            if (currentMarkers[v.mmsi]) {
                currentMarkers[v.mmsi].setLatLng([v.lat, v.lon]);
                currentMarkers[v.mmsi].setPopupContent(popup);
            } else {
                const marker = L.marker([v.lat, v.lon], { icon: shipIcon }).addTo(vesselLayer);
                marker.bindPopup(popup);
                marker.on('click', () => {
                    document.getElementById('vessel-name').innerText = v.name;
                    document.getElementById('vessel-detail').innerHTML = `
                        <strong>MMSI:</strong> ${v.mmsi}<br>
                        <strong>Hız:</strong> ${v.speed.toFixed(1)} knot (${(v.speed*1.852).toFixed(1)} km/h)<br>
                        <strong>Yön:</strong> ${v.heading}°<br>
                        <strong>Konum:</strong> ${v.lat.toFixed(4)}, ${v.lon.toFixed(4)}<br>
                        <strong>Son güncelleme:</strong> ${new Date(v.timestamp * 1000).toLocaleTimeString()}
                        <br><br>
                        <button onclick="map.setView([${v.lat}, ${v.lon}], 10)" style="background:#00aaff;border:none;color:white;padding:5px 10px;border-radius:4px;cursor:pointer;width:100%">
                            📍 Haritada Ortala
                        </button>
                    `;
                    document.getElementById('info-panel').classList.add('visible');
                });
                currentMarkers[v.mmsi] = marker;
            }
        });
        
        for (let id in currentMarkers) {
            if (!newIds.has(id)) {
                vesselLayer.removeLayer(currentMarkers[id]);
                delete currentMarkers[id];
            }
        }
    }
    
    function searchVessels(query) {
        if (!query.trim()) {
            document.getElementById('search-results').style.display = 'none';
            return;
        }
        const lowerQuery = query.toLowerCase();
        const results = allVessels.filter(v => 
            v.name.toLowerCase().includes(lowerQuery) || 
            v.mmsi.includes(query)
        ).slice(0, 20);
        
        const resultsDiv = document.getElementById('search-results');
        if (results.length === 0) {
            resultsDiv.innerHTML = '<div style="padding:6px">❌ Sonuç bulunamadı</div>';
        } else {
            resultsDiv.innerHTML = results.map(v => 
                `<div onclick="zoomToVessel('${v.mmsi}')">🚢 ${v.name} (${v.mmsi})</div>`
            ).join('');
        }
        resultsDiv.style.display = 'block';
    }
    
    window.zoomToVessel = function(mmsi) {
        const vessel = allVessels.find(v => v.mmsi === mmsi);
        if (vessel && currentMarkers[mmsi]) {
            map.setView([vessel.lat, vessel.lon], 12);
            currentMarkers[mmsi].openPopup();
            document.getElementById('search-results').style.display = 'none';
            document.getElementById('search-input').value = '';
        }
    };
    
    async function refresh() {
        const data = await fetchVessels();
        if (data.vessels) updateMap(data.vessels);
    }
    
    document.getElementById('refresh-btn').onclick = refresh;
    document.getElementById('reset-view').onclick = () => map.setView([20, 0], 2);
    document.getElementById('close-panel').onclick = () => document.getElementById('info-panel').classList.remove('visible');
    map.on('click', () => document.getElementById('info-panel').classList.remove('visible'));
    
    const searchInput = document.getElementById('search-input');
    searchInput.addEventListener('input', (e) => searchVessels(e.target.value));
    searchInput.addEventListener('blur', () => setTimeout(() => {
        document.getElementById('search-results').style.display = 'none';
    }, 200));
    
    refresh();
    setInterval(refresh, 5000);  // 5 saniyede bir yenile (demo için hızlı)
</script>
</body>
</html>
HTMLEOF

PORT=$(( RANDOM % 1000 + 8000 ))
LOCAL_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v 127.0.0.1 | head -1)
[ -z "$LOCAL_IP" ] && LOCAL_IP="localhost"

export PORT="$PORT"

echo -e "\n🚢 AIS Gemi Takip (DEMO MODU) Başlatıldı"
echo -e "📍 http://${LOCAL_IP}:${PORT}"
echo -e "📍 http://localhost:${PORT}"
echo -e "📡 DEMO MODU – Rastgele hareket eden gemiler"
echo -e "🌍 Dünya genelinde 25+ gemi simüle ediliyor"
echo -e "✅ Gemiler 5 saniyede bir hareket ediyor"
echo -e "⏹️  Durdurmak için Ctrl+C\n"

cd "$CACHE_DIR"
trap 'echo -e "\n🧹 Kapatılıyor..."; rm -f "$SERVER_SCRIPT"; exit 0' INT TERM
python3 "$SERVER_SCRIPT"
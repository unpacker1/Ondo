#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  AIS Gemi Takip – AISHub (DÜZELTİLMİŞ)                          ║
# ║  Çalıştır: ./ais-fixed.sh                                       ║
# ╚══════════════════════════════════════════════════════════════════╝

CACHE_DIR="$HOME/.cache/ais-alt"
mkdir -p "$CACHE_DIR"
SERVER_SCRIPT="$CACHE_DIR/ais_server.py"
HTML_FILE="$CACHE_DIR/ais.html"

# Python sunucu (DÜZELTİLMİŞ)
cat > "$SERVER_SCRIPT" << 'PYEOF'
#!/usr/bin/env python3
import os
import sys
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
    print("🔄 AISHub verileri çekiliyor...")
    while True:
        try:
            resp = requests.get(AISHUB_URL, timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                vessels = data.get("vessels", [])
                new_count = 0
                for v in vessels:
                    mmsi = v.get("mmsi")
                    lat = v.get("lat")
                    lon = v.get("lon")
                    if mmsi and lat is not None and lon is not None:
                        latest_vessels[str(mmsi)] = {
                            "mmsi": str(mmsi),
                            "name": v.get("name", "Bilinmiyor"),
                            "lat": float(lat),
                            "lon": float(lon),
                            "speed": v.get("speed", 0),
                            "heading": v.get("heading", 0),
                            "callsign": v.get("callsign", ""),
                            "type": v.get("type", ""),
                            "timestamp": time.time()
                        }
                        new_count += 1
                last_update = time.time()
                print(f"✅ {new_count} gemi alındı, toplam: {len(latest_vessels)}")
            else:
                print(f"⚠️ HTTP {resp.status_code}: {resp.text[:100]}")
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

@app.route('/api/status')
def get_status():
    return jsonify({
        "connected": True,
        "vessel_count": len(latest_vessels),
        "last_update": last_update
    })

if __name__ == '__main__':
    print("🚢 AIS Alternatif Sunucu başlatılıyor...")
    print("   Kaynak: AISHub (ücretsiz, kayıt yok)")
    
    # Veri çekme thread'ini başlat
    thread = threading.Thread(target=fetch_ais, daemon=True)
    thread.start()
    
    port = int(os.environ.get("PORT", 8080))
    print(f"   HTTP Sunucu: http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
PYEOF

# HTML istemci (basit ve hızlı)
cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>AIS Gemi Takip - AISHub</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family: 'Segoe UI', monospace; overflow:hidden; height:100vh; }
        #map { height:100%; width:100%; background:#0a2a3a; }
        .controls {
            position:absolute; bottom:20px; left:20px; z-index:1000;
            background:rgba(0,0,0,0.85); backdrop-filter:blur(8px); padding:12px 18px;
            border-radius:8px; color:white; font-size:13px; border-left:4px solid #00aaff;
            max-width:280px;
        }
        .controls .stat { margin:4px 0; }
        .controls .stat span { color:#00aaff; font-weight:bold; }
        .controls button {
            background:#00aaff; border:none; color:white; padding:5px 12px;
            margin-top:5px; border-radius:4px; cursor:pointer;
            font-weight:bold;
        }
        .controls button:hover { background:#0088cc; }
        .info-panel {
            position:absolute; bottom:20px; right:20px; width:280px;
            background:rgba(0,0,0,0.85); backdrop-filter:blur(8px); border-radius:12px;
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
    </style>
</head>
<body>
<div id="map"></div>
<div class="controls">
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
        className: 'ship-icon',
        html: '🚢',
        iconSize: [24, 24],
        popupAnchor: [0, -12]
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
            const speedKnot = v.speed;
            const speedKmh = (v.speed * 1.852).toFixed(1);
            const popup = `<b>${v.name}</b><br>MMSI: ${v.mmsi}<br>Hız: ${speedKnot} knot (${speedKmh} km/h)<br>Yön: ${v.heading}°`;
            
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
                        <strong>Çağrı İşareti:</strong> ${v.callsign || '?'}<br>
                        <strong>Gemi Tipi:</strong> ${v.type || '?'}<br>
                        <strong>Hız:</strong> ${v.speed} knot (${(v.speed*1.852).toFixed(1)} km/h)<br>
                        <strong>Yön:</strong> ${v.heading}°<br>
                        <strong>Son güncelleme:</strong> ${new Date(v.timestamp * 1000).toLocaleTimeString()}
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
            v.mmsi.includes(query) ||
            (v.callsign && v.callsign.toLowerCase().includes(lowerQuery))
        ).slice(0, 20);
        
        const resultsDiv = document.getElementById('search-results');
        if (results.length === 0) {
            resultsDiv.innerHTML = '<div style="padding:6px">❌ Sonuç bulunamadı</div>';
        } else {
            resultsDiv.innerHTML = results.map(v => 
                `<div onclick="zoomToVessel('${v.mmsi}')">🚢 ${v.name} (${v.mmsi})${v.callsign ? ' - ' + v.callsign : ''}</div>`
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
    setInterval(refresh, 15000);
</script>
</body>
</html>
HTMLEOF

# Rastgele port seçimi
PORT=$(( RANDOM % 1000 + 8000 ))

# Yerel IP bul (Termux için)
LOCAL_IP="localhost"
if command -v ifconfig &>/dev/null; then
    LOCAL_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v 127.0.0.1 | head -1)
fi
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="localhost"
fi

# Python paketleri kontrolü
echo "📦 Python paketleri kontrol ediliyor..."
pip3 install flask flask-cors requests -q 2>/dev/null || pip install flask flask-cors requests -q

export PORT="$PORT"

echo -e "\n🚢 AIS Gemi Takip Sunucusu (AISHub) Başlatıldı"
echo -e "📍 http://${LOCAL_IP}:${PORT}"
echo -e "📍 http://localhost:${PORT}"
echo -e "📡 Veri kaynağı: AISHub (ücretsiz, dünya geneli)"
echo -e "⏹️  Durdurmak için Ctrl+C\n"

cd "$CACHE_DIR"
trap 'echo -e "\n🧹 Kapatılıyor..."; rm -f "$SERVER_SCRIPT"; exit 0' INT TERM
python3 "$SERVER_SCRIPT"
#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  AIS Gemi Takip – MarineTraffic Demo (SON ÇARE)                 ║
# ║  Çalıştır: ./ais-marinetraffic.sh                               ║
# ╚══════════════════════════════════════════════════════════════════╝

set -e

CACHE_DIR="$HOME/.cache/ais-mt"
mkdir -p "$CACHE_DIR"
SERVER_SCRIPT="$CACHE_DIR/ais_server.py"
HTML_FILE="$CACHE_DIR/ais.html"

echo "🔧 MarineTraffic AIS sunucusu hazırlanıyor..."

# Python sunucu (MarineTraffic demo feed)
cat > "$SERVER_SCRIPT" << 'PYEOF'
#!/usr/bin/env python3
import os
import json
import time
import threading
import urllib.request
import urllib.parse
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS

app = Flask(__name__, static_folder=os.path.dirname(os.path.abspath(__file__)))
CORS(app)

# MarineTraffic demo feed (herkese açık)
MT_URL = "https://www.marinetraffic.com/getData/get_data_json_4"

latest_vessels = {}
last_update = 0
error_count = 0
total_fetches = 0

def fetch_marinetraffic():
    global latest_vessels, last_update, error_count, total_fetches
    print("🔄 MarineTraffic demo feed'inden veri çekiliyor...")
    
    while True:
        try:
            total_fetches += 1
            # MarineTraffic demo isteği
            params = {
                "ts": int(time.time()),
                "protocol": "jsono",
                "callback": "",
                "uid": "public",
                "mmsi": "",
                "msg_type": "positions",
                "size": "500"
            }
            url = f"{MT_URL}?{urllib.parse.urlencode(params)}"
            
            req = urllib.request.Request(
                url,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                    'Accept': 'application/json',
                    'Referer': 'https://www.marinetraffic.com/'
                }
            )
            
            with urllib.request.urlopen(req, timeout=15) as response:
                data = response.read().decode('utf-8')
                
                # JSONP callback temizliği
                if data.startswith('(') or data.startswith('['):
                    json_data = json.loads(data)
                elif data.startswith('jsono'):
                    json_str = data.split('(', 1)[1].rsplit(')', 1)[0]
                    json_data = json.loads(json_str)
                else:
                    json_data = json.loads(data)
                
                # Gemileri parse et
                vessels = []
                if isinstance(json_data, list):
                    vessels = json_data
                elif isinstance(json_data, dict) and "data" in json_data:
                    vessels = json_data.get("data", [])
                elif isinstance(json_data, dict) and "rows" in json_data:
                    vessels = json_data.get("rows", [])
                
                # Gemileri işle
                new_count = 0
                for v in vessels:
                    if isinstance(v, dict):
                        # Farklı formatları dene
                        lat = v.get("LAT") or v.get("lat") or v.get("latitude")
                        lon = v.get("LON") or v.get("lon") or v.get("longitude")
                        mmsi = v.get("MMSI") or v.get("mmsi") or v.get("MMSI_PRESENT")
                        name = v.get("SHIPNAME") or v.get("name") or v.get("SHIPNAME_CLEAN")
                        speed = v.get("SPEED") or v.get("speed") or v.get("SOG") or 0
                        heading = v.get("HEADING") or v.get("heading") or v.get("COG") or 0
                        
                        if mmsi and lat and lon:
                            latest_vessels[str(mmsi)] = {
                                "mmsi": str(mmsi),
                                "name": str(name) if name else "Bilinmiyor",
                                "lat": float(lat),
                                "lon": float(lon),
                                "speed": float(speed) if speed else 0,
                                "heading": float(heading) if heading else 0,
                                "timestamp": time.time()
                            }
                            new_count += 1
                
                last_update = time.time()
                error_count = 0
                print(f"✅ {new_count} gemi alındı (toplam: {len(latest_vessels)} | istek: {total_fetches})")
                
        except urllib.error.HTTPError as e:
            error_count += 1
            print(f"❌ HTTP {e.code}: {e.reason} (hata #{error_count})")
            if error_count > 10:
                print("⚠️ Çok fazla hata, 60 saniye bekleniyor...")
                time.sleep(60)
        except Exception as e:
            error_count += 1
            print(f"❌ Hata ({error_count}): {e}")
            if error_count > 10:
                time.sleep(60)
        
        time.sleep(15)  # 15 saniyede bir yenile

@app.route('/')
def index():
    return send_from_directory(os.path.dirname(__file__), 'ais.html')

@app.route('/api/vessels')
def get_vessels():
    vessels_list = list(latest_vessels.values())
    vessels_list.sort(key=lambda x: x['timestamp'], reverse=True)
    if len(vessels_list) > 3000:
        vessels_list = vessels_list[:3000]
    return jsonify({
        "vessels": vessels_list,
        "count": len(vessels_list),
        "total": len(latest_vessels),
        "last_update": last_update,
        "fetches": total_fetches
    })

@app.route('/api/status')
def get_status():
    return jsonify({
        "connected": error_count < 5,
        "vessel_count": len(latest_vessels),
        "last_update": last_update,
        "error_count": error_count,
        "fetches": total_fetches
    })

if __name__ == '__main__':
    print("🚢 AIS Sunucu başlatılıyor...")
    print("   Kaynak: MarineTraffic Demo Feed (ücretsiz)")
    print("   📡 Veriler 15 saniyede bir güncelleniyor")
    
    thread = threading.Thread(target=fetch_marinetraffic, daemon=True)
    thread.start()
    
    port = int(os.environ.get("PORT", 8080))
    print(f"   HTTP Sunucu: http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
PYEOF

# HTML istemci
cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>AIS Gemi Takip - MarineTraffic</title>
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
            max-width:300px;
        }
        .controls .stat { margin:4px 0; }
        .controls .stat span { color:#00aaff; font-weight:bold; }
        .controls button {
            background:#00aaff; border:none; color:white; padding:5px 12px;
            margin-top:5px; border-radius:4px; cursor:pointer;
        }
        .status-badge {
            display:inline-block; width:10px; height:10px; border-radius:50%; margin-right:6px;
        }
        .status-online { background:#00ff00; box-shadow:0 0 5px #00ff00; }
        .status-offline { background:#ff4444; }
        .info-panel {
            position:absolute; bottom:20px; right:20px; width:280px;
            background:rgba(0,0,0,0.85); backdrop-filter:blur(8px); border-radius:12px;
            padding:12px; color:#eee; font-size:12px; border-top:2px solid #00aaff;
            display:none; z-index:1000;
        }
        .info-panel.visible { display:block; }
        .info-panel .close { float:right; cursor:pointer; color:#aaa; font-size:18px; }
        .search-box {
            width:100%; margin:8px 0; padding:6px; background:#1e2a2f;
            border:1px solid #00aaff; color:white; border-radius:4px;
        }
        .search-results {
            max-height:150px; overflow-y:auto; background:#1e2a2f;
            margin-top:4px; display:none;
        }
        .search-results div { padding:6px; cursor:pointer; border-bottom:1px solid #2a3a3f; }
        .search-results div:hover { background:#2a4a5a; }
    </style>
</head>
<body>
<div id="map"></div>
<div class="controls">
    <div><span id="status-indicator" class="status-badge status-offline"></span> <span id="status-text">Bağlantı yok</span></div>
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
    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png').addTo(map);
    
    let vesselLayer = L.layerGroup().addTo(map);
    let currentMarkers = {};
    let allVessels = [];
    
    const shipIcon = L.divIcon({ html: '🚢', iconSize: [24,24], popupAnchor: [0,-12] });
    
    async function fetchVessels() {
        try {
            const res = await fetch(API_URL);
            const data = await res.json();
            allVessels = data.vessels || [];
            document.getElementById('vessel-count').innerText = allVessels.length;
            document.getElementById('last-update').innerText = new Date().toLocaleTimeString();
            if (data.connected) {
                document.getElementById('status-indicator').className = 'status-badge status-online';
                document.getElementById('status-text').innerText = '🌍 Aktif';
            }
            return data;
        } catch(e) { return { vessels: [] }; }
    }
    
    function updateMap(vessels) {
        const newIds = new Set();
        vessels.forEach(v => {
            if (!v.lat || !v.lon) return;
            newIds.add(v.mmsi);
            const popup = `<b>${v.name}</b><br>MMSI: ${v.mmsi}<br>Hız: ${(v.speed*1.852).toFixed(1)} km/h`;
            
            if (currentMarkers[v.mmsi]) {
                currentMarkers[v.mmsi].setLatLng([v.lat, v.lon]);
                currentMarkers[v.mmsi].setPopupContent(popup);
            } else {
                const marker = L.marker([v.lat, v.lon], { icon: shipIcon }).addTo(vesselLayer);
                marker.bindPopup(popup);
                marker.on('click', () => {
                    document.getElementById('vessel-name').innerText = v.name;
                    document.getElementById('vessel-detail').innerHTML = `
                        MMSI: ${v.mmsi}<br>
                        Hız: ${(v.speed*1.852).toFixed(1)} km/h<br>
                        Yön: ${v.heading}°
                    `;
                    document.getElementById('info-panel').classList.add('visible');
                });
                currentMarkers[v.mmsi] = marker;
            }
        });
        for (let id in currentMarkers) if (!newIds.has(id)) {
            vesselLayer.removeLayer(currentMarkers[id]);
            delete currentMarkers[id];
        }
    }
    
    function searchVessels(q) {
        if (!q.trim()) { document.getElementById('search-results').style.display = 'none'; return; }
        const results = allVessels.filter(v => v.name.toLowerCase().includes(q.toLowerCase()) || v.mmsi.includes(q)).slice(0,20);
        const div = document.getElementById('search-results');
        div.innerHTML = results.map(v => `<div onclick="zoomToVessel('${v.mmsi}')">🚢 ${v.name} (${v.mmsi})</div>`).join('');
        div.style.display = results.length ? 'block' : 'none';
    }
    
    window.zoomToVessel = function(mmsi) {
        const v = allVessels.find(v => v.mmsi === mmsi);
        if (v && currentMarkers[mmsi]) { map.setView([v.lat, v.lon], 12); currentMarkers[mmsi].openPopup(); }
    };
    
    async function refresh() { const data = await fetchVessels(); if (data.vessels) updateMap(data.vessels); }
    
    document.getElementById('refresh-btn').onclick = refresh;
    document.getElementById('reset-view').onclick = () => map.setView([20, 0], 2);
    document.getElementById('close-panel').onclick = () => document.getElementById('info-panel').classList.remove('visible');
    document.getElementById('search-input').addEventListener('input', e => searchVessels(e.target.value));
    
    refresh();
    setInterval(refresh, 15000);
</script>
</body>
</html>
HTMLEOF

PORT=$(( RANDOM % 1000 + 8000 ))
LOCAL_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v 127.0.0.1 | head -1)
[ -z "$LOCAL_IP" ] && LOCAL_IP="localhost"

export PORT="$PORT"

echo -e "\n🚢 AIS Gemi Takip (MarineTraffic Demo) Başlatıldı"
echo -e "📍 http://${LOCAL_IP}:${PORT}"
echo -e "📍 http://localhost:${PORT}"
echo -e "📡 Veri kaynağı: MarineTraffic (demo feed)"
echo -e "⏹️  Durdurmak için Ctrl+C\n"

cd "$CACHE_DIR"
trap 'echo -e "\n🧹 Kapatılıyor..."; rm -f "$SERVER_SCRIPT"; exit 0' INT TERM
python3 "$SERVER_SCRIPT"
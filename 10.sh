#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  AIS Gemi Takip – VesselFinder (Çalışan Sürüm)                  ║
# ║  Çalıştır: ./ais-vesselfinder.sh                                ║
# ╚══════════════════════════════════════════════════════════════════╝

set -e

CACHE_DIR="$HOME/.cache/ais-vf"
mkdir -p "$CACHE_DIR"
SERVER_SCRIPT="$CACHE_DIR/ais_server.py"
HTML_FILE="$CACHE_DIR/ais.html"

echo "🔧 VesselFinder AIS sunucusu hazırlanıyor..."

# Python sunucu (VesselFinder API)
cat > "$SERVER_SCRIPT" << 'PYEOF'
#!/usr/bin/env python3
import os
import json
import time
import threading
import urllib.request
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS

app = Flask(__name__, static_folder=os.path.dirname(os.path.abspath(__file__)))
CORS(app)

# VesselFinder ücretsiz feed (dünya geneli)
VESSELFINDER_URL = "https://www.vesselfinder.com/feeds/positions"
# Alternatif: MarineTraffic demo feed
MARINETRAFFIC_URL = "https://www.marinetraffic.com/getData/get_data_json_4"

latest_vessels = {}
last_update = 0
error_count = 0

def fetch_vesselfinder():
    global latest_vessels, last_update, error_count
    print("🔄 VesselFinder'dan veri çekiliyor...")
    
    while True:
        try:
            # VesselFinder'ın JSON feed'i
            req = urllib.request.Request(
                VESSELFINDER_URL,
                headers={'User-Agent': 'Mozilla/5.0'}
            )
            with urllib.request.urlopen(req, timeout=15) as response:
                data = response.read().decode('utf-8')
                
                # Yanıtı parse et
                if data.startswith('{'):
                    vessels_data = json.loads(data)
                else:
                    # JSON olmayan yanıt, alternatif parse
                    vessels_data = {"data": []}
                
                # Farklı formatları dene
                vessels = []
                if "features" in vessels_data:
                    # GeoJSON formatı
                    for feat in vessels_data.get("features", []):
                        props = feat.get("properties", {})
                        geom = feat.get("geometry", {})
                        coords = geom.get("coordinates", [])
                        if coords and len(coords) >= 2:
                            vessels.append({
                                "mmsi": props.get("mmsi", ""),
                                "name": props.get("name", "Bilinmiyor"),
                                "lat": coords[1],
                                "lon": coords[0],
                                "speed": props.get("speed", 0),
                                "heading": props.get("heading", 0),
                                "callsign": props.get("callsign", ""),
                                "type": props.get("type", "")
                            })
                elif "data" in vessels_data:
                    for v in vessels_data.get("data", []):
                        if v.get("LAT") and v.get("LON"):
                            vessels.append({
                                "mmsi": str(v.get("MMSI", "")),
                                "name": v.get("SHIPNAME", "Bilinmiyor"),
                                "lat": float(v["LAT"]),
                                "lon": float(v["LON"]),
                                "speed": v.get("SPEED", 0),
                                "heading": v.get("HEADING", 0),
                                "callsign": v.get("CALLSIGN", ""),
                                "type": v.get("SHIPTYPE", "")
                            })
                
                # Gemileri güncelle
                new_count = 0
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
                            "callsign": v.get("callsign", ""),
                            "type": v.get("type", ""),
                            "timestamp": time.time()
                        }
                        new_count += 1
                
                last_update = time.time()
                error_count = 0
                print(f"✅ {new_count} gemi alındı, toplam: {len(latest_vessels)}")
                
        except Exception as e:
            error_count += 1
            print(f"❌ Hata ({error_count}): {e}")
            if error_count > 5:
                print("⚠️ Çok fazla hata, 60 saniye bekleniyor...")
                time.sleep(60)
        
        time.sleep(20)  # 20 saniyede bir yenile

@app.route('/')
def index():
    return send_from_directory(os.path.dirname(__file__), 'ais.html')

@app.route('/api/vessels')
def get_vessels():
    vessels_list = list(latest_vessels.values())
    vessels_list.sort(key=lambda x: x['timestamp'], reverse=True)
    # Performans için son 3000 gemiyi gönder
    if len(vessels_list) > 3000:
        vessels_list = vessels_list[:3000]
    return jsonify({
        "vessels": vessels_list,
        "count": len(vessels_list),
        "total": len(latest_vessels),
        "last_update": last_update
    })

@app.route('/api/status')
def get_status():
    return jsonify({
        "connected": error_count < 3,
        "vessel_count": len(latest_vessels),
        "last_update": last_update,
        "error_count": error_count
    })

if __name__ == '__main__':
    print("🚢 AIS Sunucu başlatılıyor...")
    print("   Kaynak: VesselFinder (ücretsiz, dünya geneli)")
    
    thread = threading.Thread(target=fetch_vesselfinder, daemon=True)
    thread.start()
    
    port = int(os.environ.get("PORT", 8080))
    print(f"   HTTP Sunucu: http://0.0.0.0:{port}")
    print("   📡 Veri çekilmeye başlıyor, ilk veriler 20 saniye içinde gelecek...")
    app.run(host='0.0.0.0', port=port, debug=False)
PYEOF

# HTML istemci (gelişmiş)
cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>AIS Gemi Takip - Dünya Geneli</title>
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
            max-width:300px;
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
        .loading {
            position:absolute; top:50%; left:50%; transform:translate(-50%,-50%);
            color:#00aaff; font-size:14px; z-index:2000;
        }
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
<div class="loading" id="loading" style="display:none;">📡 Veriler yükleniyor...</div>

<script>
    const API_URL = "/api/vessels";
    const STATUS_URL = "/api/status";
    const map = L.map('map').setView([20, 0], 2);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; OSM & CartoDB'
    }).addTo(map);
    
    let vesselLayer = L.layerGroup().addTo(map);
    let currentMarkers = {};
    let allVessels = [];
    let lastDataTime = 0;
    
    const shipIcon = L.divIcon({
        className: 'ship-icon',
        html: '🚢',
        iconSize: [24, 24],
        popupAnchor: [0, -12]
    });
    
    async function fetchStatus() {
        try {
            const res = await fetch(STATUS_URL);
            const data = await res.json();
            const indicator = document.getElementById('status-indicator');
            const statusText = document.getElementById('status-text');
            if (data.connected && data.vessel_count > 0) {
                indicator.className = 'status-badge status-online';
                statusText.innerText = '🌍 Aktif';
            } else if (data.connected) {
                indicator.className = 'status-badge status-offline';
                statusText.innerText = 'Veri bekleniyor...';
            } else {
                indicator.className = 'status-badge status-offline';
                statusText.innerText = 'Bağlantı sorunu';
            }
        } catch(e) {}
    }
    
    async function fetchVessels() {
        try {
            const loading = document.getElementById('loading');
            loading.style.display = 'block';
            const res = await fetch(API_URL);
            const data = await res.json();
            allVessels = data.vessels || [];
            document.getElementById('vessel-count').innerText = allVessels.length;
            document.getElementById('last-update').innerText = new Date().toLocaleTimeString();
            lastDataTime = Date.now();
            loading.style.display = 'none';
            return data;
        } catch(e) {
            console.error(e);
            document.getElementById('loading').style.display = 'none';
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
            const popup = `<b>🚢 ${v.name}</b><br>MMSI: ${v.mmsi}<br>Hız: ${speedKnot} knot (${speedKmh} km/h)<br>Yön: ${v.heading}°`;
            
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
                        <br><br><button onclick="map.setView([${v.lat}, ${v.lon}], 12)" style="background:#00aaff;border:none;color:white;padding:4px 8px;border-radius:4px;cursor:pointer;">📍 Haritada Ortala</button>
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
        await fetchStatus();
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
    setInterval(refresh, 20000);
    setInterval(fetchStatus, 5000);
</script>
</body>
</html>
HTMLEOF

# Rastgele port seçimi
PORT=$(( RANDOM % 1000 + 8000 ))

# Yerel IP bul
LOCAL_IP="localhost"
if command -v ifconfig &>/dev/null; then
    LOCAL_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v 127.0.0.1 | head -1)
fi
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="localhost"
fi

# Python paketleri
echo "📦 Python paketleri kontrol ediliyor..."
pip3 install flask flask-cors -q 2>/dev/null || pip install flask flask-cors -q

export PORT="$PORT"

echo -e "\n🚢 AIS Gemi Takip Sunucusu (VesselFinder) Başlatıldı"
echo -e "📍 http://${LOCAL_IP}:${PORT}"
echo -e "📍 http://localhost:${PORT}"
echo -e "📡 Veri kaynağı: VesselFinder (ücretsiz, dünya geneli)"
echo -e "⏹️  Durdurmak için Ctrl+C\n"

cd "$CACHE_DIR"
trap 'echo -e "\n🧹 Kapatılıyor..."; rm -f "$SERVER_SCRIPT"; exit 0' INT TERM
python3 "$SERVER_SCRIPT"
#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  AIS Gemi Takip Sistemi – TÜM DÜNYA (Hazır)                     ║
# ║  Kullanım: ./ais-world-ready.sh --key "API_ANAHTARINIZ"         ║
# ╚══════════════════════════════════════════════════════════════════╝

set -e

G='\033[0;32m'
C='\033[0;36m'
Y='\033[1;33m'
R='\033[0;31m'
N='\033[0m'
B='\033[1m'

API_KEY=""
PORT=""
MIN_PORT=8000
MAX_PORT=9000

while [[ $# -gt 0 ]]; do
    case "$1" in
        --key) API_KEY="$2"; shift 2 ;;
        --port) PORT="$2"; shift 2 ;;
        --help) echo "Kullanım: $0 --key API_ANAHTARI [--port PORT]"; exit 0 ;;
        *) echo -e "${R}Bilinmeyen argüman: $1${N}"; exit 1 ;;
    esac
done

if [ -z "$API_KEY" ]; then
    echo -e "${R}❌ API anahtarı gerekli! --key ile belirtin.${N}"
    echo -e "${Y}Ücretsiz anahtar: https://aisstream.io${N}"
    exit 1
fi

CACHE_DIR="$HOME/.cache/ais-world"
mkdir -p "$CACHE_DIR"
SERVER_SCRIPT="$CACHE_DIR/ais_server.py"
HTML_FILE="$CACHE_DIR/ais.html"

echo -e "${C}🌍 TÜM DÜNYA gemi takip sunucusu hazırlanıyor...${N}"

# Python sunucu - TÜM DÜNYA (USE_WORLDWIDE = True)
cat > "$SERVER_SCRIPT" << 'PYEOF'
#!/usr/bin/env python3
import asyncio
import json
import os
import time
import threading
import websockets
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS

app = Flask(__name__, static_folder=os.path.dirname(os.path.abspath(__file__)))
CORS(app)

API_KEY = os.environ.get("AIS_API_KEY", "")

# TÜM DÜNYA – hiçbir sınır yok
USE_WORLDWIDE = True  # <-- BU SATIR TÜM DÜNYA İÇİN AYARLI

# Yedek bölge (USE_WORLDWIDE False ise kullanılır)
BOUNDING_BOX = [[34.0, 25.0], [47.0, 42.0]]

latest_vessels = {}
last_update = 0
connection_active = False
message_count = 0
max_vessels = 8000  # Bellekte tutulacak maksimum gemi sayısı

async def listen_ais():
    global latest_vessels, last_update, connection_active, message_count
    uri = "wss://stream.aisstream.io/v0/stream"
    
    if USE_WORLDWIDE:
        subscription = {
            "APIKey": API_KEY,
            "BoundingBoxes": [],  # BOŞ = TÜM DÜNYA
            "FilterMessageTypes": ["PositionReport"]
        }
        print("🌍 TÜM DÜNYA gemileri takip ediliyor (sınırsız bölge)")
    else:
        subscription = {
            "APIKey": API_KEY,
            "BoundingBoxes": [BOUNDING_BOX],
            "FilterMessageTypes": ["PositionReport"]
        }
        print(f"📍 Bölge sınırlı: {BOUNDING_BOX}")
    
    while True:
        try:
            async with websockets.connect(uri, ping_interval=20, ping_timeout=10) as websocket:
                await websocket.send(json.dumps(subscription))
                print("✅ WebSocket bağlantısı kuruldu")
                connection_active = True
                
                async for message in websocket:
                    message_count += 1
                    data = json.loads(message)
                    
                    if "error" in data:
                        print(f"⚠️ API Hatası: {data['error']}")
                        continue
                    
                    # PositionReport mesajlarını işle
                    if data.get("MessageType") == "PositionReport":
                        meta = data.get("MetaData", {})
                        msg = data.get("Message", {}).get("PositionReport", {})
                        
                        mmsi = msg.get("UserID") or meta.get("MMSI")
                        lat = msg.get("Latitude") or meta.get("latitude")
                        lon = msg.get("Longitude") or meta.get("longitude")
                        
                        if mmsi and lat is not None and lon is not None:
                            latest_vessels[str(mmsi)] = {
                                "mmsi": str(mmsi),
                                "name": meta.get("ShipName", "Bilinmiyor"),
                                "lat": float(lat),
                                "lon": float(lon),
                                "speed": msg.get("Sog", 0),
                                "heading": msg.get("Cog", 0),
                                "timestamp": time.time()
                            }
                            last_update = time.time()
                            
                            # Bellek yönetimi: çok fazla gemi varsa eski olanları sil
                            if len(latest_vessels) > max_vessels:
                                sorted_vessels = sorted(latest_vessels.items(), key=lambda x: x[1]['timestamp'])
                                for old_mmsi, _ in sorted_vessels[:1000]:
                                    del latest_vessels[old_mmsi]
                    
                    # Class B gemileri de ekle
                    elif data.get("MessageType") == "ClassBPositionReport":
                        meta = data.get("MetaData", {})
                        msg = data.get("Message", {}).get("ClassBPositionReport", {})
                        
                        mmsi = msg.get("UserID") or meta.get("MMSI")
                        lat = msg.get("Latitude") or meta.get("latitude")
                        lon = msg.get("Longitude") or meta.get("longitude")
                        
                        if mmsi and lat is not None and lon is not None:
                            latest_vessels[str(mmsi)] = {
                                "mmsi": str(mmsi),
                                "name": meta.get("ShipName", "Bilinmiyor"),
                                "lat": float(lat),
                                "lon": float(lon),
                                "speed": msg.get("Sog", 0),
                                "heading": msg.get("Cog", 0),
                                "timestamp": time.time()
                            }
                    
                    if message_count % 500 == 0:
                        print(f"📊 {message_count} mesaj, {len(latest_vessels)} gemi takip ediliyor")
                        
        except websockets.exceptions.ConnectionClosed as e:
            print(f"❌ Bağlantı kapandı: {e}, 10 saniye sonra yeniden bağlanıyor...")
            connection_active = False
            await asyncio.sleep(10)
        except Exception as e:
            print(f"❌ Hata: {e}, 10 saniye sonra yeniden bağlanıyor...")
            connection_active = False
            await asyncio.sleep(10)

@app.route('/')
def index():
    return send_from_directory(os.path.dirname(__file__), 'ais.html')

@app.route('/api/vessels')
def get_vessels():
    vessels_with_pos = [v for v in latest_vessels.values() if v['lat'] is not None]
    vessels_with_pos.sort(key=lambda x: x['timestamp'], reverse=True)
    # Performans için son 3000 gemiyi gönder
    if len(vessels_with_pos) > 3000:
        vessels_with_pos = vessels_with_pos[:3000]
    return jsonify({
        "vessels": vessels_with_pos,
        "count": len(vessels_with_pos),
        "total": len(latest_vessels),
        "last_update": last_update,
        "connected": connection_active,
        "worldwide": USE_WORLDWIDE
    })

def start_websocket_thread():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(listen_ais())

if __name__ == '__main__':
    print("🚢 AIS Sunucu başlatılıyor...")
    print("   🌍 TÜM DÜNYA gemileri takip edilecek (sınırsız bölge)")
    print(f"   💾 Bellek sınırı: {max_vessels} gemi")
    
    thread = threading.Thread(target=start_websocket_thread, daemon=True)
    thread.start()
    
    port = int(os.environ.get("PORT", 8080))
    print(f"   HTTP Sunucu: http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
PYEOF

# HTML istemci (tüm dünya görünümü)
cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>AIS Gemi Takip - Tüm Dünya</title>
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
        .info-panel .close { float:right; cursor:pointer; color:#aaa; }
        .search-box {
            width:100%; margin:8px 0; padding:6px; background:#2a3a4a; border:1px solid #00aaff;
            color:white; border-radius:4px; font-family:monospace;
        }
        .search-results {
            max-height:150px; overflow-y:auto; background:#1e2a2f; margin-top:4px; display:none;
        }
        .search-results div { padding:6px; cursor:pointer; border-bottom:1px solid #2a3a3f; }
        .search-results div:hover { background:#2a4a5a; }
    </style>
</head>
<body>
<div id="map"></div>
<div class="controls">
    <div><span id="status-indicator" class="status-badge status-offline"></span> <span id="status-text">Bağlantı yok</span></div>
    <div class="stat">🚢 <span id="vessel-count">0</span> / <span id="total-count">0</span> gemi</div>
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
            document.getElementById('total-count').innerText = data.total || allVessels.length;
            document.getElementById('last-update').innerText = new Date().toLocaleTimeString();
            
            if (data.connected) {
                document.getElementById('status-indicator').className = 'status-badge status-online';
                document.getElementById('status-text').innerText = '🌍 Tüm Dünya Aktif';
            } else {
                document.getElementById('status-indicator').className = 'status-badge status-offline';
                document.getElementById('status-text').innerText = 'Bağlantı kuruluyor...';
            }
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
            const speed = (v.speed * 1.852).toFixed(1);
            const popup = `<b>${v.name}</b><br>MMSI: ${v.mmsi}<br>Hız: ${speed} km/h<br>Yön: ${v.heading}°`;
            
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
                        <strong>Hız:</strong> ${speed} km/h<br>
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
            v.name.toLowerCase().includes(lowerQuery) || v.mmsi.includes(query)
        ).slice(0, 20);
        
        const resultsDiv = document.getElementById('search-results');
        if (results.length === 0) {
            resultsDiv.innerHTML = '<div style="padding:6px">Sonuç bulunamadı</div>';
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
            map.setView([vessel.lat, vessel.lon], 10);
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
    }, 300));
    
    refresh();
    setInterval(refresh, 15000);
</script>
</body>
</html>
HTMLEOF

# Port seçimi
if [ -z "$PORT" ]; then
    PORT=$(( RANDOM % (MAX_PORT - MIN_PORT + 1) + MIN_PORT ))
fi

LOCAL_IP="localhost"
if command -v ip &>/dev/null; then
    LOCAL_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1)
fi

echo -e "${C}📦 Python paketleri kuruluyor...${N}"
pip3 install flask flask-cors websockets -q 2>/dev/null || pip install flask flask-cors websockets -q

export AIS_API_KEY="$API_KEY"
export PORT="$PORT"

echo -e "\n${G}${B}🚢 TÜM DÜNYA AIS Gemi Takip Sunucusu Başlatıldı${N}"
echo -e "${C}📍 Adres:${N}"
echo -e "  ${G}http://${LOCAL_IP}:${PORT}${N}"
echo -e "${Y}🌍 Artık dünyanın her yerindeki gemileri görebilirsin!${N}"
echo -e "${C}📊 Pasifik, Atlas, Hint Okyanusu, tüm denizler...${N}"
echo -e "${R}⏹️  Sunucuyu durdurmak için Ctrl+C${N}"

cd "$CACHE_DIR"
trap 'echo -e "\n${C}🧹 Kapatılıyor...${N}"; exit 0' INT TERM
python3 "$SERVER_SCRIPT"
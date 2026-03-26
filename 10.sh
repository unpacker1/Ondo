#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  AIS Gemi Takip Sunucusu - Termux için (AISStream)          ║
# ║  Kullanım: ./ais-server.sh --key "API_ANAHTARIN"            ║
# ╚══════════════════════════════════════════════════════════════╝

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

CACHE_DIR="$HOME/.cache/ais"
mkdir -p "$CACHE_DIR"
SERVER_SCRIPT="$CACHE_DIR/ais_server.py"
HTML_FILE="$CACHE_DIR/ais.html"

echo -e "${C}📡 AISStream bağlantısı hazırlanıyor...${N}"

# Python sunucu + WebSocket istemcisi (iyileştirilmiş)
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

# Geniş bölge: Akdeniz + Karadeniz (yaklaşık)
BOUNDING_BOX = [25.0, 34.0, 42.0, 47.0]  # [minLon, minLat, maxLon, maxLat]
# Daha geniş için:
# BOUNDING_BOX = [-180.0, -90.0, 180.0, 90.0]   # tüm dünya (çok fazla veri)

latest_vessels = {}
last_update = 0
message_count = 0

async def listen_ais():
    """AISStream WebSocket'ine bağlan ve gemileri dinle"""
    global latest_vessels, last_update, message_count
    uri = "wss://stream.aisstream.io/v0/stream"
    
    subscription = {
        "APIKey": API_KEY,
        "BoundingBoxes": [[BOUNDING_BOX[0], BOUNDING_BOX[1], BOUNDING_BOX[2], BOUNDING_BOX[3]]],
        "FilterMessageTypes": ["PositionReport"]
    }
    
    while True:
        try:
            async with websockets.connect(uri) as websocket:
                await websocket.send(json.dumps(subscription))
                print("✅ AISStream bağlantısı kuruldu, gemiler dinleniyor...")
                print(f"   Bölge: {BOUNDING_BOX}")
                
                async for message in websocket:
                    data = json.loads(message)
                    message_count += 1
                    if message_count % 50 == 0:
                        print(f"📨 {message_count} mesaj alındı, gemiler: {len(latest_vessels)}")
                    
                    if "MessageType" in data and data["MessageType"] == "PositionReport":
                        meta = data.get("MetaData", {})
                        pos = data.get("Message", {})
                        
                        mmsi = meta.get("MMSI")
                        if mmsi and pos.get("Latitude") and pos.get("Longitude"):
                            latest_vessels[mmsi] = {
                                "mmsi": mmsi,
                                "name": meta.get("ShipName", "Bilinmiyor"),
                                "lat": pos["Latitude"],
                                "lon": pos["Longitude"],
                                "speed": pos.get("Sog", 0),
                                "heading": pos.get("Cog", 0),
                                "timestamp": time.time()
                            }
                            last_update = time.time()
        except Exception as e:
            print(f"WebSocket hatası: {e}, 10 saniye sonra yeniden bağlanılıyor...")
            await asyncio.sleep(10)

@app.route('/')
def index():
    return send_from_directory(os.path.dirname(__file__), 'ais.html')

@app.route('/api/vessels')
def get_vessels():
    """Son gemi verilerini JSON olarak döndür"""
    return jsonify({
        "vessels": list(latest_vessels.values()),
        "count": len(latest_vessels),
        "last_update": last_update,
        "bounding_box": BOUNDING_BOX
    })

def start_websocket_thread():
    """WebSocket dinleyicisini ayrı thread'de başlat"""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(listen_ais())

if __name__ == '__main__':
    print("🚢 AIS Sunucu başlatılıyor...")
    print(f"   Bölge: {BOUNDING_BOX}")
    # WebSocket'i arka planda başlat
    thread = threading.Thread(target=start_websocket_thread, daemon=True)
    thread.start()
    
    port = int(os.environ.get("PORT", 8080))
    print(f"   HTTP Sunucu: http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
PYEOF

# HTML istemci (Leaflet haritası)
cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>AIS Gemi Takip Sistemi</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family: monospace; overflow:hidden; height:100vh; }
        #map { height:100%; width:100%; background:#0a2a3a; }
        .controls {
            position:absolute; bottom:20px; left:20px; z-index:1000;
            background:rgba(0,0,0,0.75); backdrop-filter:blur(8px); padding:12px 18px;
            border-radius:8px; color:white; font-size:13px; border-left:4px solid #00aaff;
            max-width:280px;
        }
        .controls .stat { margin:4px 0; }
        .controls .stat span { color:#00aaff; font-weight:bold; }
        .controls button {
            background:#00aaff; border:none; color:white; padding:4px 12px;
            margin-top:8px; border-radius:4px; cursor:pointer;
        }
        .info-panel {
            position:absolute; bottom:20px; right:20px; width:280px;
            background:rgba(0,0,0,0.85); backdrop-filter:blur(8px); border-radius:12px;
            padding:12px; color:#eee; font-size:12px; border-top:2px solid #00aaff;
            display:none; z-index:1000;
        }
        .info-panel.visible { display:block; }
        .info-panel .close { float:right; cursor:pointer; color:#aaa; }
    </style>
</head>
<body>
<div id="map"></div>
<div class="controls">
    <div class="stat">🚢 <span id="vessel-count">0</span> gemi</div>
    <div class="stat">🕒 <span id="last-update">-</span></div>
    <div class="stat">📍 <span id="bbox-info">-</span></div>
    <button id="refresh-btn">🔄 Şimdi Yenile</button>
</div>
<div class="info-panel" id="info-panel">
    <span class="close" id="close-panel">&times;</span>
    <h4 id="vessel-name">Gemi Bilgisi</h4>
    <p id="vessel-detail"></p>
</div>

<script>
    const API_URL = "/api/vessels";
    const map = L.map('map').setView([39.0, 33.0], 5);  // Türkiye merkez
    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; OSM & CartoDB'
    }).addTo(map);
    
    let vesselLayer = L.layerGroup().addTo(map);
    let currentVessels = {};
    
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
            if (data.bounding_box) {
                document.getElementById('bbox-info').innerText = 
                    `Bölge: ${data.bounding_box[0]},${data.bounding_box[1]} - ${data.bounding_box[2]},${data.bounding_box[3]}`;
            }
            return data.vessels || [];
        } catch(e) {
            console.error(e);
            return [];
        }
    }
    
    function updateMap(vessels) {
        document.getElementById('vessel-count').innerText = vessels.length;
        document.getElementById('last-update').innerText = new Date().toLocaleTimeString();
        
        const newMmsis = new Set();
        vessels.forEach(v => {
            newMmsis.add(v.mmsi);
            const popup = `<b>${v.name}</b><br>MMSI: ${v.mmsi}<br>Hız: ${(v.speed * 1.852).toFixed(1)} km/h<br>Yön: ${v.heading}°`;
            
            if (currentVessels[v.mmsi]) {
                currentVessels[v.mmsi].setLatLng([v.lat, v.lon]);
                currentVessels[v.mmsi].setPopupContent(popup);
            } else {
                const marker = L.marker([v.lat, v.lon], { icon: shipIcon }).addTo(vesselLayer);
                marker.bindPopup(popup);
                marker.on('click', () => {
                    document.getElementById('vessel-name').innerText = v.name;
                    document.getElementById('vessel-detail').innerHTML = `
                        <strong>MMSI:</strong> ${v.mmsi}<br>
                        <strong>Hız:</strong> ${(v.speed * 1.852).toFixed(1)} km/h<br>
                        <strong>Yön:</strong> ${v.heading}°<br>
                        <strong>Son güncelleme:</strong> ${new Date(v.timestamp * 1000).toLocaleTimeString()}
                    `;
                    document.getElementById('info-panel').classList.add('visible');
                });
                currentVessels[v.mmsi] = marker;
            }
        });
        
        for (let mmsi in currentVessels) {
            if (!newMmsis.has(mmsi)) {
                vesselLayer.removeLayer(currentVessels[mmsi]);
                delete currentVessels[mmsi];
            }
        }
    }
    
    async function refresh() {
        const vessels = await fetchVessels();
        if (vessels) updateMap(vessels);
    }
    
    document.getElementById('refresh-btn').onclick = refresh;
    document.getElementById('close-panel').onclick = () => document.getElementById('info-panel').classList.remove('visible');
    map.on('click', () => document.getElementById('info-panel').classList.remove('visible'));
    
    refresh();
    setInterval(refresh, 15000);  // 15 saniyede bir yenile
</script>
</body>
</html>
HTMLEOF

# Port seçimi
if [ -z "$PORT" ]; then
    PORT=$(( RANDOM % (MAX_PORT - MIN_PORT + 1) + MIN_PORT ))
fi

# Yerel IP bul
LOCAL_IP="localhost"
if command -v ip &>/dev/null; then
    LOCAL_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1)
elif command -v ifconfig &>/dev/null; then
    LOCAL_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v 127.0.0.1 | head -1)
fi

# Python paketleri
echo -e "${C}📦 Python paketleri kuruluyor...${N}"
pip3 install flask flask-cors websockets -q 2>/dev/null || pip install flask flask-cors websockets -q

export AIS_API_KEY="$API_KEY"
export PORT="$PORT"

echo -e "\n${G}${B}🚢 AIS Gemi Takip Sunucu Başlatıldı${N}"
echo -e "${C}📍 Adres:${N}"
echo -e "  ${G}http://${LOCAL_IP}:${PORT}${N}"
echo -e "${Y}🌊 Bölge: Akdeniz + Karadeniz (değiştirmek için betikteki BOUNDING_BOX'ı düzenleyin)${N}"
echo -e "${R}⏹️  Sunucuyu durdurmak için Ctrl+C${N}"

cd "$CACHE_DIR"
trap 'echo -e "\n${C}🧹 Kapatılıyor...${N}"; exit 0' INT TERM
python3 "$SERVER_SCRIPT"
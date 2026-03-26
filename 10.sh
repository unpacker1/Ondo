#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  AIS Gemi Takip Sunucusu - Düzeltilmiş Sürüm                ║
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

echo -e "${C}📡 AISStream bağlantısı hazırlanıyor (düzeltilmiş)...${N}"

# Python sunucu - DÜZELTİLMİŞ WebSocket bağlantısı
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

# DOĞRU format: [minLat, minLon], [maxLat, maxLon]
# Türkiye ve çevresi (Akdeniz, Ege, Karadeniz)
BOUNDING_BOX = [[34.0, 25.0], [47.0, 42.0]]  # [[minLat, minLon], [maxLat, maxLon]]

latest_vessels = {}
last_update = 0
connection_active = False

async def listen_ais():
    """AISStream WebSocket'ine bağlan - DÜZELTİLMİŞ"""
    global latest_vessels, last_update, connection_active
    uri = "wss://stream.aisstream.io/v0/stream"
    
    # DOĞRU subscription formatı (dokümantasyona göre)[citation:2]
    subscription = {
        "APIKey": API_KEY,
        "BoundingBoxes": [BOUNDING_BOX],  # [[minLat, minLon], [maxLat, maxLon]]
        "FilterMessageTypes": ["PositionReport"]
    }
    
    while True:
        try:
            async with websockets.connect(uri, ping_interval=20, ping_timeout=10) as websocket:
                print("✅ WebSocket bağlantısı kuruldu")
                
                # ÖNEMLİ: Subscription mesajını HEMEN gönder (3 saniye içinde)[citation:2]
                await websocket.send(json.dumps(subscription))
                print(f"📡 Subscription gönderildi: {BOUNDING_BOX}")
                connection_active = True
                
                async for message in websocket:
                    data = json.loads(message)
                    
                    # Hata mesajı kontrolü
                    if "error" in data:
                        print(f"⚠️ API Hatası: {data['error']}")
                        continue
                    
                    if data.get("MessageType") == "PositionReport":
                        meta = data.get("MetaData", {})
                        msg = data.get("Message", {}).get("PositionReport", {})
                        
                        mmsi = msg.get("UserID") or meta.get("MMSI")
                        lat = msg.get("Latitude") or meta.get("latitude")
                        lon = msg.get("Longitude") or meta.get("longitude")
                        
                        if mmsi and lat and lon:
                            latest_vessels[str(mmsi)] = {
                                "mmsi": str(mmsi),
                                "name": meta.get("ShipName", "Bilinmiyor"),
                                "lat": lat,
                                "lon": lon,
                                "speed": msg.get("Sog", 0),
                                "heading": msg.get("Cog", 0),
                                "timestamp": time.time()
                            }
                            last_update = time.time()
                            if len(latest_vessels) % 50 == 0:
                                print(f"📊 {len(latest_vessels)} gemi takip ediliyor")
                                
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
    """Son gemi verilerini JSON olarak döndür"""
    return jsonify({
        "vessels": list(latest_vessels.values()),
        "count": len(latest_vessels),
        "last_update": last_update,
        "connected": connection_active,
        "bounding_box": BOUNDING_BOX
    })

@app.route('/api/status')
def get_status():
    """Bağlantı durumu"""
    return jsonify({
        "connected": connection_active,
        "vessel_count": len(latest_vessels),
        "last_update": last_update
    })

def start_websocket_thread():
    """WebSocket dinleyicisini ayrı thread'de başlat"""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(listen_ais())

if __name__ == '__main__':
    print("🚢 AIS Sunucu başlatılıyor...")
    print(f"   Bölge: {BOUNDING_BOX}")
    print("   Subscription formatı düzeltildi ✅")
    print("   Ping/pong mekanizması eklendi ✅")
    
    thread = threading.Thread(target=start_websocket_thread, daemon=True)
    thread.start()
    
    port = int(os.environ.get("PORT", 8080))
    print(f"   HTTP Sunucu: http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
PYEOF

# HTML istemci (Türkiye merkezli harita)
cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>AIS Gemi Takip Sistemi - Termux</title>
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
            max-width:300px;
        }
        .controls .stat { margin:4px 0; }
        .controls .stat span { color:#00aaff; font-weight:bold; }
        .controls button {
            background:#00aaff; border:none; color:white; padding:4px 12px;
            margin-top:8px; border-radius:4px; cursor:pointer;
        }
        .status-badge {
            display:inline-block;
            width:10px;
            height:10px;
            border-radius:50%;
            margin-right:6px;
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
    </style>
</head>
<body>
<div id="map"></div>
<div class="controls">
    <div class="stat"><span id="status-indicator" class="status-badge status-offline"></span> <span id="status-text">Bağlantı yok</span></div>
    <div class="stat">🚢 <span id="vessel-count">0</span> gemi</div>
    <div class="stat">🕒 <span id="last-update">-</span></div>
    <button id="refresh-btn">🔄 Yenile</button>
</div>
<div class="info-panel" id="info-panel">
    <span class="close" id="close-panel">&times;</span>
    <h4 id="vessel-name">Gemi Bilgisi</h4>
    <p id="vessel-detail"></p>
</div>

<script>
    const API_URL = "/api/vessels";
    const STATUS_URL = "/api/status";
    const map = L.map('map').setView([39.0, 33.0], 5);
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
    
    async function fetchStatus() {
        try {
            const res = await fetch(STATUS_URL);
            const data = await res.json();
            const indicator = document.getElementById('status-indicator');
            const statusText = document.getElementById('status-text');
            if (data.connected) {
                indicator.className = 'status-badge status-online';
                statusText.innerText = 'Bağlantı aktif';
            } else {
                indicator.className = 'status-badge status-offline';
                statusText.innerText = 'Bağlantı kuruluyor...';
            }
        } catch(e) {
            console.log('Status check failed');
        }
    }
    
    async function fetchVessels() {
        try {
            const res = await fetch(API_URL);
            const data = await res.json();
            return data;
        } catch(e) {
            console.error(e);
            return { vessels: [] };
        }
    }
    
    function updateMap(data) {
        const vessels = data.vessels || [];
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
        await fetchStatus();
        const data = await fetchVessels();
        if (data.vessels) updateMap(data);
    }
    
    document.getElementById('refresh-btn').onclick = refresh;
    document.getElementById('close-panel').onclick = () => document.getElementById('info-panel').classList.remove('visible');
    map.on('click', () => document.getElementById('info-panel').classList.remove('visible'));
    
    refresh();
    setInterval(refresh, 10000);
    setInterval(fetchStatus, 5000);
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
fi

# Python paketleri
echo -e "${C}📦 Python paketleri kuruluyor...${N}"
pip3 install flask flask-cors websockets -q 2>/dev/null || pip install flask flask-cors websockets -q

export AIS_API_KEY="$API_KEY"
export PORT="$PORT"

echo -e "\n${G}${B}🚢 AIS Gemi Takip Sunucu Başlatıldı${N}"
echo -e "${C}📍 Adres:${N}"
echo -e "  ${G}http://${LOCAL_IP}:${PORT}${N}"
echo -e "${Y}🌊 Bölge: Türkiye ve çevresi (Akdeniz, Ege, Karadeniz)${N}"
echo -e "${C}📌 Düzeltmeler:${N}"
echo -e "  • Subscription 3 saniye içinde gönderiliyor"
echo -e "  • BoundingBox formatı düzeltildi [lat,lon]"
echo -e "  • Ping/pong mekanizması eklendi"
echo -e "${R}⏹️  Sunucuyu durdurmak için Ctrl+C${N}"

cd "$CACHE_DIR"
trap 'echo -e "\n${C}🧹 Kapatılıyor...${N}"; exit 0' INT TERM
python3 "$SERVER_SCRIPT"
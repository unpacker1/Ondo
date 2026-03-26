#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ADS-B Sunucu v2 – OpenSky Kayıtlı Kullanıcı Desteği        ║
# ║  Kullanım: ./adsb-server.sh [--port PORT] [--user USER] [--pass PASS] ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

# Renkler
G='\033[0;32m'
C='\033[0;36m'
Y='\033[1;33m'
R='\033[0;31m'
N='\033[0m'
B='\033[1m'

# Varsayılanlar
PORT=""
OPENSKY_USER=""
OPENSKY_PASS=""
MIN_PORT=8000
MAX_PORT=9000

# Argüman işleme
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port) PORT="$2"; shift 2 ;;
        --user) OPENSKY_USER="$2"; shift 2 ;;
        --pass) OPENSKY_PASS="$2"; shift 2 ;;
        --help) echo "Kullanım: $0 [--port PORT] [--user USER] [--pass PASS]"; exit 0 ;;
        *) echo -e "${R}Bilinmeyen argüman: $1${N}"; exit 1 ;;
    esac
done

# Kayıtlı kullanıcı bilgisi kontrolü
if [ -n "$OPENSKY_USER" ] && [ -n "$OPENSKY_PASS" ]; then
    echo -e "${G}✅ Kayıtlı kullanıcı olarak giriş yapılacak (günlük 1000 istek)${N}"
else
    echo -e "${Y}⚠️ Anonim kullanım (günde 100 istek) – limiti aşmamak için önerilmez.${N}"
    echo -e "${Y}   Kayıt: https://opensky-network.org/register${N}"
fi

# Geçici dosya için güvenli konum
CACHE_DIR="$HOME/.cache/adsb"
mkdir -p "$CACHE_DIR"
SERVER_SCRIPT="$CACHE_DIR/adsb_server.py"
HTML_FILE="$CACHE_DIR/adsb.html"

echo -e "${C}📄 Sunucu betiği oluşturuluyor...${N}"

# Python sunucu kodu (Flask ile proxy + cache)
cat > "$SERVER_SCRIPT" << PYEOF
#!/usr/bin/env python3
import os
import sys
import time
import json
import requests
from datetime import datetime
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS

app = Flask(__name__, static_folder=os.path.dirname(os.path.abspath(__file__)))
CORS(app)

OPENSKY_URL = "https://opensky-network.org/api/states/all"
CACHE_DURATION = 90  # saniye

cache_data = None
cache_time = 0

USER = os.environ.get("OPENSKY_USER", "")
PASS = os.environ.get("OPENSKY_PASS", "")

def fetch_opensky():
    global cache_data, cache_time
    now = time.time()
    if cache_data and (now - cache_time) < CACHE_DURATION:
        return cache_data

    try:
        auth = (USER, PASS) if USER and PASS else None
        resp = requests.get(OPENSKY_URL, auth=auth, timeout=15)
        if resp.status_code == 200:
            data = resp.json()
            cache_data = data
            cache_time = now
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Veri alındı. Önbellek {CACHE_DURATION}s")
            return data
        elif resp.status_code == 429:
            print("Rate limit aşıldı! Önbellek kullanılıyor.")
            return cache_data if cache_data else {"states": []}
        else:
            print(f"API hatası: {resp.status_code}")
            return {"states": []}
    except Exception as e:
        print(f"Hata: {e}")
        return {"states": []}

@app.route('/')
def index():
    return send_from_directory(os.path.dirname(__file__), 'adsb.html')

@app.route('/api/flights')
def get_flights():
    data = fetch_opensky()
    return jsonify(data)

@app.route('/api/stats')
def get_stats():
    data = fetch_opensky()
    states = data.get('states', [])
    valid = [s for s in states if s and s[5] and s[6]]
    countries = {}
    for s in valid:
        c = s[2] if s[2] else "Bilinmiyor"
        countries[c] = countries.get(c, 0) + 1
    top = sorted(countries.items(), key=lambda x: x[1], reverse=True)[:5]
    return jsonify({
        "total": len(valid),
        "timestamp": time.time(),
        "cache_duration": CACHE_DURATION,
        "top_countries": dict(top)
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    print(f"Sunucu başlatılıyor: http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
PYEOF

echo -e "${C}🌐 HTML istemcisi oluşturuluyor...${N}"

# HTML (Leaflet + 90 saniye yenileme)
cat > "$HTML_FILE" << HTMLEOF
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>ADS-B Uçak Takip (OpenSky)</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/leaflet-rotatedmarker@0.2.0/leaflet.rotatedMarker.min.js"></script>
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family: monospace; overflow:hidden; height:100vh; }
        #map { height:100%; width:100%; background:#111; }
        .controls {
            position:absolute; bottom:20px; left:20px; z-index:1000;
            background:rgba(0,0,0,0.75); backdrop-filter:blur(8px); padding:12px 18px;
            border-radius:8px; color:white; font-size:13px; border-left:4px solid #00aaff;
            max-width:260px;
        }
        .controls .stat { margin:4px 0; }
        .controls .stat span { color:#00aaff; font-weight:bold; }
        .controls button {
            background:#00aaff; border:none; color:white; padding:4px 12px;
            margin-top:8px; border-radius:4px; cursor:pointer;
        }
        .controls .rate-info { font-size:10px; color:#aaa; margin-top:6px; }
        .info-panel {
            position:absolute; bottom:20px; right:20px; width:280px;
            background:rgba(0,0,0,0.85); backdrop-filter:blur(8px); border-radius:12px;
            padding:12px; color:#eee; font-size:12px; border-top:2px solid #00aaff;
            display:none; z-index:1000;
        }
        .info-panel.visible { display:block; }
        .info-panel h4 { margin:0 0 6px 0; color:#00aaff; border-bottom:1px solid #444; }
        .info-panel .close { float:right; cursor:pointer; color:#aaa; }
        .toast {
            position:fixed; bottom:90px; left:20px; background:#000000cc;
            color:#ffaa44; padding:8px 15px; border-radius:6px; font-size:12px;
            border-left:3px solid #ffaa44; max-width:260px; display:none;
        }
        @keyframes fadeout { 0%{opacity:1} 100%{opacity:0} }
    </style>
</head>
<body>
<div id="map"></div>
<div class="controls">
    <div class="stat">✈️ <span id="aircraft-count">0</span> uçak</div>
    <div class="stat">🌍 <span id="top-country">-</span></div>
    <div class="stat">🕒 <span id="last-update">-</span></div>
    <div class="rate-info" id="rate-status">🔄 90 saniyede bir yenilenir</div>
    <button id="refresh-btn">🔄 Şimdi Yenile</button>
</div>
<div class="info-panel" id="info-panel">
    <span class="close" id="close-panel">&times;</span>
    <h4 id="aircraft-callsign">Uçak Bilgisi</h4>
    <p id="aircraft-detail"></p>
</div>
<div class="toast" id="toast"></div>
<script>
    const API_URL = "/api/flights";
    const map = L.map('map').setView([39.0, 35.0], 5);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; OSM & CartoDB',
        subdomains: 'abcd'
    }).addTo(map);

    let aircraftLayer = L.layerGroup().addTo(map);
    let currentAircraftData = {};

    const planeSvg = L.divIcon({
        className: 'plane-svg',
        html: `<svg width="24" height="24" viewBox="0 0 24 24"><polygon points="12,2 18,10 14,10 14,18 10,18 10,10 6,10 12,2" fill="#00aaff" stroke="white" stroke-width="1"/></svg>`,
        iconSize: [24,24], popupAnchor: [0,-12]
    });

    function showToast(msg) {
        const t = document.getElementById('toast');
        t.textContent = msg;
        t.style.display = 'block';
        t.style.animation = 'fadeout 3s ease forwards';
        setTimeout(() => t.style.display = 'none', 3000);
    }

    async function fetchData() {
        try {
            const res = await fetch(API_URL);
            if (!res.ok) throw new Error(`HTTP ${res.status}`);
            const data = await res.json();
            return data.states || [];
        } catch(e) {
            showToast('Veri alınamadı: ' + e.message);
            return [];
        }
    }

    function updateUI(states) {
        const valid = states.filter(s => s && s[5] && s[6]);
        document.getElementById('aircraft-count').innerText = valid.length;

        const countries = {};
        valid.forEach(s => { const c = s[2] || 'Bilinmiyor'; countries[c] = (countries[c]||0)+1; });
        let top = '', topCnt = 0;
        for (let [c,cnt] of Object.entries(countries)) if(cnt>topCnt) { top=c; topCnt=cnt; }
        document.getElementById('top-country').innerText = top ? `${top} (${topCnt})` : '-';
        document.getElementById('last-update').innerText = new Date().toLocaleTimeString();

        const newIcaos = new Set();
        valid.forEach(ac => {
            const icao = ac[0];
            const cs = (ac[1] || 'N/A').trim();
            const country = ac[2] || '?';
            const lon = ac[5], lat = ac[6];
            const alt = ac[7] ? Math.round(ac[7]) : null;
            const vel = ac[9] ? (ac[9]*3.6).toFixed(0) : null;
            const hdg = ac[10] !== null ? ac[10] : 0;
            const ground = ac[8] || false;

            newIcaos.add(icao);
            const popup = `<b>${cs}</b><br>${country}<br>İrtifa: ${alt?alt+'m':'?'}<br>Hız: ${vel?vel+'km/h':'?'}<br>Yön: ${hdg}°<br>${ground?'🛬 Yerde':'✈️ Havada'}`;

            if (currentAircraftData[icao]) {
                const m = currentAircraftData[icao].marker;
                m.setLatLng([lat, lon]);
                if (m.setRotationAngle) m.setRotationAngle(hdg);
                m.setPopupContent(popup);
            } else {
                const marker = L.marker([lat, lon], { icon: planeSvg, rotationAngle: hdg, rotationOrigin: 'center center' }).addTo(aircraftLayer);
                marker.bindPopup(popup);
                marker.on('click', () => {
                    document.getElementById('aircraft-callsign').innerText = cs;
                    document.getElementById('aircraft-detail').innerHTML = `
                        <strong>ICAO24:</strong> ${icao}<br>
                        <strong>Ülke:</strong> ${country}<br>
                        <strong>İrtifa:</strong> ${alt?alt+' m':'Belirsiz'}<br>
                        <strong>Hız:</strong> ${vel?vel+' km/h':'Belirsiz'}<br>
                        <strong>Yön:</strong> ${hdg}°<br>
                        <strong>Durum:</strong> ${ground?'Yerde':'Havada'}<br>
                        <button id="center-btn" style="margin-top:8px;background:#00aaff;border:none;color:white;padding:3px 8px;border-radius:4px;">📍 Ortala</button>
                    `;
                    document.getElementById('info-panel').classList.add('visible');
                    setTimeout(() => {
                        const btn = document.getElementById('center-btn');
                        if(btn) btn.onclick = () => map.setView(marker.getLatLng(), 12);
                    }, 10);
                });
                currentAircraftData[icao] = { marker };
            }
        });
        for (let icao in currentAircraftData) {
            if (!newIcaos.has(icao)) {
                aircraftLayer.removeLayer(currentAircraftData[icao].marker);
                delete currentAircraftData[icao];
            }
        }
    }

    let refreshing = false;
    async function refresh() {
        if (refreshing) return;
        refreshing = true;
        const btn = document.getElementById('refresh-btn');
        btn.disabled = true; btn.style.opacity = '0.6';
        const states = await fetchData();
        if (states) updateUI(states);
        btn.disabled = false; btn.style.opacity = '1';
        refreshing = false;
    }

    document.getElementById('refresh-btn').onclick = refresh;
    document.getElementById('close-panel').onclick = () => document.getElementById('info-panel').classList.remove('visible');
    map.on('click', () => document.getElementById('info-panel').classList.remove('visible'));

    refresh();
    setInterval(refresh, 90000);  // 90 saniye
</script>
</body>
</html>
HTMLEOF

# Rastgele port seçimi
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

# Gerekli Python paketlerini kur
echo -e "${C}📦 Python paketleri kontrol ediliyor...${N}"
pip3 install flask flask-cors requests -q 2>/dev/null || pip install flask flask-cors requests -q

# Çevre değişkenlerini ayarla
export OPENSKY_USER="$OPENSKY_USER"
export OPENSKY_PASS="$OPENSKY_PASS"
export PORT="$PORT"

echo -e "\n${G}${B}✈️  ADS-B Sunucu Başlatıldı${N}"
echo -e "${C}📍 Adres:${N}"
echo -e "  ${G}http://${LOCAL_IP}:${PORT}${N}"
echo -e "  ${G}http://localhost:${PORT}${N}"
echo -e "${Y}📱 Aynı ağdaki diğer cihazlardan da ${LOCAL_IP}:${PORT} adresini kullanabilirsiniz.${N}"
echo -e "${R}⏹️  Sunucuyu durdurmak için Ctrl+C${N}"

# Sunucuyu başlat
cd "$CACHE_DIR"
trap 'echo -e "\n${C}🧹 Kapatılıyor...${N}"; rm -f "$SERVER_SCRIPT"; exit 0' INT TERM
python3 "$SERVER_SCRIPT"
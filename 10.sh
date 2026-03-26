#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ADS-B Uçak Takip Sunucusu - Termux için Tek Kod (Düzeltilmiş)║
# ║  Kullanım: ./adsb-server.sh [--port PORT]                   ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

# Renkler
G='\033[0;32m'
C='\033[0;36m'
Y='\033[1;33m'
R='\033[0;31m'
N='\033[0m'
B='\033[1m'

# Varsayılan port aralığı
MIN_PORT=8000
MAX_PORT=9000
PORT=""

# Argüman işleme
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port)
            PORT="$2"
            shift 2
            ;;
        --help)
            echo "Kullanım: $0 [--port PORT]"
            exit 0
            ;;
        *)
            echo -e "${R}Bilinmeyen argüman: $1${N}"
            exit 1
            ;;
    esac
done

# Geçici dosya için güvenli bir konum: Termux'ta HOME altında .cache oluştur
CACHE_DIR="$HOME/.cache/adsb"
mkdir -p "$CACHE_DIR"
HTML_FILE="$CACHE_DIR/adsb.html"

echo -e "${C}✈️  ADS-B Sunucu HTML dosyası oluşturuluyor...${N}"

cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>ADS-B Uçak Takip - Termux</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/leaflet-rotatedmarker@0.2.0/leaflet.rotatedMarker.min.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; overflow: hidden; height: 100vh; }
        #map { height: 100%; width: 100%; background: #111; }
        .controls {
            position: absolute; bottom: 20px; left: 20px; z-index: 1000;
            background: rgba(0,0,0,0.75); backdrop-filter: blur(8px); padding: 12px 18px;
            border-radius: 8px; color: white; font-size: 13px; font-family: monospace;
            border-left: 4px solid #00aaff; box-shadow: 0 2px 10px rgba(0,0,0,0.3);
            max-width: 260px;
        }
        .controls .stat { margin: 4px 0; }
        .controls .stat span { color: #00aaff; font-weight: bold; }
        .controls button {
            background: #00aaff; border: none; color: white; padding: 4px 12px;
            margin-top: 8px; border-radius: 4px; cursor: pointer; font-weight: bold;
            font-size: 12px; transition: 0.2s;
        }
        .controls button:hover { background: #0088cc; }
        .controls .rate-info { font-size: 10px; color: #aaa; margin-top: 6px; }
        .info-panel {
            position: absolute; bottom: 20px; right: 20px; width: 280px;
            background: rgba(0,0,0,0.85); backdrop-filter: blur(8px); border-radius: 12px;
            padding: 12px; color: #eee; font-size: 12px; font-family: monospace;
            border-top: 2px solid #00aaff; pointer-events: auto; z-index: 1000;
            display: none; box-shadow: 0 4px 15px rgba(0,0,0,0.4);
        }
        .info-panel.visible { display: block; }
        .info-panel h4 { margin: 0 0 6px 0; color: #00aaff; border-bottom: 1px solid #444; padding-bottom: 4px; }
        .info-panel p { margin: 4px 0; word-break: break-word; }
        .info-panel .close { float: right; cursor: pointer; font-size: 16px; font-weight: bold; color: #aaa; }
        .info-panel .close:hover { color: white; }
        .toast {
            position: fixed; bottom: 90px; left: 20px; background: rgba(0,0,0,0.8);
            color: #ffaa44; padding: 8px 15px; border-radius: 6px; font-size: 12px;
            font-family: monospace; z-index: 1000; pointer-events: none;
            border-left: 3px solid #ffaa44; max-width: 260px;
        }
        @keyframes fadeout { 0% { opacity: 1; } 100% { opacity: 0; } }
    </style>
</head>
<body>
<div id="map"></div>
<div class="controls">
    <div class="stat">✈️ <span id="aircraft-count">0</span> uçak</div>
    <div class="stat">🌍 <span id="top-country">-</span></div>
    <div class="stat">🕒 <span id="last-update">-</span></div>
    <div class="rate-info" id="rate-status">📡 Anonim limit: 100 istek/gün</div>
    <button id="refresh-btn">🔄 Şimdi Yenile</button>
</div>
<div class="info-panel" id="info-panel">
    <span class="close" id="close-panel">&times;</span>
    <h4 id="aircraft-callsign">Uçak Bilgisi</h4>
    <p id="aircraft-detail"></p>
</div>
<div class="toast" id="toast" style="display: none;"></div>
<script>
    const OPENSKY_URL = "https://opensky-network.org/api/states/all";
    const map = L.map('map').setView([39.0, 35.0], 5);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a> &copy; CartoDB',
        subdomains: 'abcd', maxZoom: 19, minZoom: 3
    }).addTo(map);
    let aircraftLayer = L.layerGroup().addTo(map);
    let currentAircraftData = {};
    const aircraftCountSpan = document.getElementById('aircraft-count');
    const topCountrySpan = document.getElementById('top-country');
    const lastUpdateSpan = document.getElementById('last-update');
    const rateStatusSpan = document.getElementById('rate-status');
    const refreshBtn = document.getElementById('refresh-btn');
    const infoPanel = document.getElementById('info-panel');
    const closePanel = document.getElementById('close-panel');
    const aircraftCallsign = document.getElementById('aircraft-callsign');
    const aircraftDetail = document.getElementById('aircraft-detail');
    const toastDiv = document.getElementById('toast');
    const planeSvg = L.divIcon({
        className: 'plane-svg',
        html: `<svg width="24" height="24" viewBox="0 0 24 24" style="filter: drop-shadow(0 0 2px black);"><polygon points="12,2 18,10 14,10 14,18 10,18 10,10 6,10 12,2" fill="#00aaff" stroke="white" stroke-width="1"/></svg>`,
        iconSize: [24, 24], popupAnchor: [0, -12]
    });
    function showToast(message, duration = 4000) {
        toastDiv.textContent = message;
        toastDiv.style.display = 'block';
        toastDiv.style.animation = 'none';
        toastDiv.offsetHeight;
        toastDiv.style.animation = 'fadeout 3s ease forwards';
        setTimeout(() => { toastDiv.style.display = 'none'; }, duration);
    }
    async function fetchAircraftData() {
        try {
            const startTime = Date.now();
            const response = await fetch(OPENSKY_URL);
            const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
            if (!response.ok) {
                if (response.status === 429) showToast('⚠️ API limit aşıldı! Lütfen 1 dakika bekleyin.');
                else showToast(`Hata: ${response.status}`);
                return null;
            }
            const data = await response.json();
            const states = data.states || [];
            rateStatusSpan.innerHTML = '📡 Anonim limit: 100 istek/gün | Son istek: ' + elapsed + ' sn';
            return states;
        } catch (error) {
            showToast('Bağlantı hatası: ' + error.message);
            return null;
        }
    }
    function updateMapWithAircraft(states) {
        if (!states || states.length === 0) {
            aircraftCountSpan.innerText = '0';
            topCountrySpan.innerText = 'Veri yok';
            lastUpdateSpan.innerText = new Date().toLocaleTimeString();
            aircraftLayer.clearLayers();
            currentAircraftData = {};
            return;
        }
        const validAircraft = states.filter(s => s && s.length >= 10 && s[5] !== null && s[6] !== null);
        aircraftCountSpan.innerText = validAircraft.length;
        const countryCount = {};
        validAircraft.forEach(a => { const c = a[2] || 'Bilinmiyor'; countryCount[c] = (countryCount[c] || 0) + 1; });
        let topCountry = '', topCount = 0;
        for (let [c, cnt] of Object.entries(countryCount)) if (cnt > topCount) { topCount = cnt; topCountry = c; }
        topCountrySpan.innerText = topCountry ? `${topCountry} (${topCount})` : '-';
        lastUpdateSpan.innerText = new Date().toLocaleTimeString();
        const newIcaos = new Set();
        validAircraft.forEach(ac => {
            const icao = ac[0];
            const cs = (ac[1] || 'N/A').trim();
            const country = ac[2] || '?';
            const lon = ac[5];
            const lat = ac[6];
            const alt = ac[7] ? Math.round(ac[7]) : null;
            const vel = ac[9] ? (ac[9] * 3.6).toFixed(0) : null;
            const hdg = ac[10] !== null ? ac[10] : 0;
            const ground = ac[8] || false;
            newIcaos.add(icao);
            const popup = `<b>${cs}</b><br>${country}<br>İrtifa: ${alt ? alt+' m' : '?'}<br>Hız: ${vel ? vel+' km/h' : '?'}<br>Yön: ${hdg}°<br>${ground ? '🛬 Yerde' : '✈️ Havada'}`;
            if (currentAircraftData[icao]) {
                const m = currentAircraftData[icao].marker;
                m.setLatLng([lat, lon]);
                if (m.setRotationAngle) m.setRotationAngle(hdg);
                m.setPopupContent(popup);
                currentAircraftData[icao].info = { cs, country, alt, vel, hdg, ground };
            } else {
                const marker = L.marker([lat, lon], { icon: planeSvg, rotationAngle: hdg, rotationOrigin: 'center center' }).addTo(aircraftLayer);
                marker.bindPopup(popup);
                marker.on('click', () => {
                    aircraftCallsign.innerText = cs;
                    aircraftDetail.innerHTML = `<strong>ICAO24:</strong> ${icao}<br><strong>Ülke:</strong> ${country}<br><strong>İrtifa:</strong> ${alt ? alt+' m' : 'Belirsiz'}<br><strong>Hız:</strong> ${vel ? vel+' km/h' : 'Belirsiz'}<br><strong>Yön:</strong> ${hdg}°<br><strong>Durum:</strong> ${ground ? 'Yerde' : 'Havada'}<br><button id="center-plane-btn" style="margin-top:8px;background:#00aaff;border:none;color:white;padding:3px 8px;border-radius:4px;cursor:pointer;">📍 Haritada Ortala</button>`;
                    infoPanel.classList.add('visible');
                    setTimeout(() => {
                        const btn = document.getElementById('center-plane-btn');
                        if (btn) btn.onclick = () => { const m = currentAircraftData[icao]?.marker; if (m) map.setView(m.getLatLng(), 12); };
                    }, 10);
                });
                currentAircraftData[icao] = { marker, info: { cs, country, alt, vel, hdg, ground } };
            }
        });
        for (let icao in currentAircraftData) if (!newIcaos.has(icao)) { aircraftLayer.removeLayer(currentAircraftData[icao].marker); delete currentAircraftData[icao]; }
    }
    closePanel.onclick = () => infoPanel.classList.remove('visible');
    map.on('click', () => infoPanel.classList.remove('visible'));
    let isUpdating = false;
    async function refreshData() {
        if (isUpdating) return;
        isUpdating = true;
        refreshBtn.disabled = true;
        refreshBtn.style.opacity = '0.6';
        const states = await fetchAircraftData();
        if (states) updateMapWithAircraft(states);
        refreshBtn.disabled = false;
        refreshBtn.style.opacity = '1';
        isUpdating = false;
    }
    refreshBtn.onclick = refreshData;
    refreshData();
    setInterval(refreshData, 8000);
</script>
</body>
</html>
HTMLEOF

# Rastgele port seçimi
if [ -z "$PORT" ]; then
    PORT=$(( RANDOM % (MAX_PORT - MIN_PORT + 1) + MIN_PORT ))
    echo -e "${C}🔀 Rastgele port seçildi: ${Y}$PORT${N}"
else
    echo -e "${C}🔌 Belirtilen port kullanılacak: ${Y}$PORT${N}"
fi

# Yerel IP adresini bul
LOCAL_IP="localhost"
if command -v ip &>/dev/null; then
    LOCAL_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1)
elif command -v ifconfig &>/dev/null; then
    LOCAL_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v 127.0.0.1 | head -1)
fi

echo -e "\n${G}${B}✈️  ADS-B Uçak Takip Sistemi Başlatıldı${N}"
echo -e "${C}📍 Adres:${N}"
echo -e "  ${G}http://${LOCAL_IP}:${PORT}${N}"
echo -e "  ${G}http://localhost:${PORT}${N}"
echo -e "${Y}📱 Aynı ağdaki diğer cihazlardan da ${LOCAL_IP}:${PORT} adresini kullanabilirsiniz.${N}"
echo -e "${R}⏹️  Sunucuyu durdurmak için Ctrl+C tuşlarına basın.${N}"

# Sunucuyu başlat
cd "$CACHE_DIR"
trap 'echo -e "\n${C}🧹 Sunucu kapatılıyor...${N}"; rm -f "$HTML_FILE"; exit 0' INT TERM
python3 -m http.server "$PORT" 2>/dev/null || python -m http.server "$PORT"
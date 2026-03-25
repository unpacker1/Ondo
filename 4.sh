#!/data/data/com.termux/files/usr/bin/bash

# Flight Tracker Panel for Termux
# This script sets up a local web server with random port and serves the flight tracker app.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to get local IP
get_ip() {
    ip -4 addr show wlan0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1
    if [ -z "$ip" ]; then
        ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1
    fi
    if [ -z "$ip" ]; then
        echo "127.0.0.1"
    else
        echo "$ip"
    fi
}

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python3 not found. Installing...${NC}"
    pkg install python3 -y
fi

# Create HTML file
HTML_FILE="flight_tracker.html"
cat > "$HTML_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>Uçuş Takip Sistemi | Mapbox</title>
    <!-- Mapbox GL JS -->
    <script src="https://api.mapbox.com/mapbox-gl-js/v3.9.1/mapbox-gl.js"></script>
    <link href="https://api.mapbox.com/mapbox-gl-js/v3.9.1/mapbox-gl.css" rel="stylesheet">
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <!-- SunCalc (terminator) -->
    <script src="https://cdn.jsdelivr.net/npm/suncalc@1.9.0/suncalc.min.js"></script>
    <!-- Font Awesome (icons) -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            overflow: hidden;
        }
        #map {
            position: absolute;
            top: 0;
            bottom: 0;
            width: 100%;
        }
        .control-panel {
            position: absolute;
            background: rgba(0,0,0,0.75);
            backdrop-filter: blur(8px);
            color: white;
            border-radius: 8px;
            padding: 10px 15px;
            z-index: 10;
            font-size: 14px;
            pointer-events: auto;
            box-shadow: 0 2px 10px rgba(0,0,0,0.3);
            border: 1px solid rgba(255,255,255,0.2);
        }
        .stats-panel {
            bottom: 20px;
            right: 20px;
            width: 300px;
            max-height: 400px;
            overflow-y: auto;
            display: none;
            flex-direction: column;
            gap: 15px;
        }
        .stats-panel canvas {
            background: rgba(0,0,0,0.5);
            border-radius: 4px;
            padding: 5px;
        }
        .filter-modal {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: #1e1e2f;
            color: white;
            padding: 20px;
            border-radius: 12px;
            z-index: 1000;
            display: none;
            flex-direction: column;
            gap: 10px;
            min-width: 280px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.5);
            border: 1px solid #3a3a4a;
        }
        .filter-modal input, .filter-modal select {
            padding: 8px;
            border-radius: 4px;
            border: none;
            background: #2a2a3a;
            color: white;
        }
        .filter-modal button {
            background: #4c6ef5;
            border: none;
            padding: 8px;
            border-radius: 4px;
            color: white;
            cursor: pointer;
        }
        .toast {
            position: fixed;
            bottom: 20px;
            left: 20px;
            background: #e03131;
            color: white;
            padding: 10px 16px;
            border-radius: 8px;
            z-index: 1000;
            font-weight: bold;
            animation: fadeInOut 4s forwards;
        }
        @keyframes fadeInOut {
            0% { opacity: 0; transform: translateY(20px); }
            10% { opacity: 1; transform: translateY(0); }
            90% { opacity: 1; transform: translateY(0); }
            100% { opacity: 0; transform: translateY(20px); visibility: hidden; }
        }
        .compass {
            background: rgba(0,0,0,0.7);
            border-radius: 50%;
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            cursor: pointer;
            transition: transform 0.1s linear;
        }
        .gauge-container {
            position: absolute;
            bottom: 20px;
            left: 20px;
            background: rgba(0,0,0,0.7);
            border-radius: 12px;
            padding: 10px;
            width: 180px;
            display: none;
            flex-direction: column;
            align-items: center;
            gap: 5px;
            backdrop-filter: blur(5px);
            z-index: 10;
        }
        .gauge-canvas {
            width: 100%;
            height: auto;
        }
        .loading-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: #0a0a1a;
            z-index: 2000;
            display: flex;
            align-items: center;
            justify-content: center;
            pointer-events: none;
        }
        canvas.particles {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
        }
        .info-text {
            position: absolute;
            top: 20px;
            left: 20px;
            background: rgba(0,0,0,0.6);
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            color: white;
            z-index: 10;
            pointer-events: none;
        }
        button.icon-btn {
            background: none;
            border: none;
            color: white;
            font-size: 18px;
            cursor: pointer;
            padding: 5px;
        }
        .flex-row {
            display: flex;
            gap: 10px;
            align-items: center;
        }
    </style>
</head>
<body>
    <div id="map"></div>

    <!-- İstatistik Paneli -->
    <div id="statsPanel" class="control-panel stats-panel">
        <h3>📊 İstatistikler</h3>
        <canvas id="countryChart" width="280" height="120"></canvas>
        <canvas id="speedChart" width="280" height="120"></canvas>
        <canvas id="altChart" width="280" height="120"></canvas>
    </div>

    <!-- Filtre Modal -->
    <div id="filterModal" class="filter-modal">
        <h3>✈️ Uçak Filtresi</h3>
        <input type="text" id="filterCallsign" placeholder="Callsign">
        <input type="text" id="filterCountry" placeholder="Ülke Kodu (TR, US)">
        <input type="text" id="filterICAO" placeholder="ICAO24">
        <button id="applyFilter">Uygula</button>
        <button id="resetFilter">Sıfırla</button>
    </div>

    <!-- Hız Göstergesi -->
    <div id="gaugeContainer" class="gauge-container">
        <span>🛩️ Hız (km/h)</span>
        <canvas id="speedGauge" width="160" height="80" class="gauge-canvas"></canvas>
        <span id="speedValue">0</span>
    </div>

    <!-- Yükleme Partikülleri -->
    <div id="loadingOverlay" class="loading-overlay">
        <canvas id="particleCanvas" class="particles"></canvas>
        <div style="position: relative; color: white; font-size: 24px;">🚀 Yükleniyor...</div>
    </div>

    <!-- Compass Kontrolü (manuel eklenecek) -->
    <div id="compassControl" class="control-panel" style="top: 20px; right: 20px; width: auto; padding: 5px;">
        <div id="compass" class="compass">⬆️</div>
    </div>

    <!-- Bilgi -->
    <div class="info-text">
        <i class="fas fa-keyboard"></i> Kısayollar: ? yardım
    </div>

    <script>
        // ----------------------------- MAPBOX -----------------------------
        mapboxgl.accessToken = 'YOUR_MAPBOX_ACCESS_TOKEN'; // Kendi token'ınızı girin
        const map = new mapboxgl.Map({
            container: 'map',
            style: 'mapbox://styles/mapbox/streets-v12',
            center: [32.8597, 39.9334], // [lng, lat]
            zoom: 6,
            bearing: 0
        });

        // Uçak verileri ve durum
        let aircraftData = [];
        let selectedAircraftId = null;
        let trailPositions = [];
        let trailSource = null;
        let trailLayer = null;
        let aircraftSource = null;
        let aircraftLayer = null;
        let emergencyLayer = null;
        let currentFilter = { callsign: '', country: '', icao: '' };
        let weatherLayer = null;
        let terminatorLayer = null;
        let lastTerminatorUpdate = 0;

        // İstatistik grafikleri
        let countryChart, speedChart, altChart;
        
        // Mock veri üretimi
        function generateMockAircraft(count = 25) {
            const airlines = ['THY', 'PGS', 'SXS', 'DLH', 'AFR', 'UAL', 'BAW', 'KLM'];
            const countries = ['TR', 'US', 'DE', 'FR', 'GB', 'NL', 'IT', 'ES'];
            const data = [];
            for (let i = 0; i < count; i++) {
                const callsign = `${airlines[Math.floor(Math.random() * airlines.length)]}${Math.floor(1000 + Math.random() * 9000)}`;
                const icao = `${callsign.substring(0,3)}${Math.floor(1000 + Math.random()*9000)}`;
                data.push({
                    id: i,
                    lat: 36 + Math.random() * 8,
                    lng: 26 + Math.random() * 12,
                    alt: Math.random() * 13000, // 0-13000 m
                    speed: 200 + Math.random() * 800,
                    heading: Math.random() * 360,
                    squawk: Math.random() > 0.96 ? 7700 : (Math.random() > 0.98 ? 7600 : (Math.random() > 0.99 ? 7500 : Math.floor(1000 + Math.random() * 7000))),
                    callsign: callsign,
                    icao: icao,
                    country: countries[Math.floor(Math.random() * countries.length)]
                });
            }
            return data;
        }

        // Ülke bayrak emojisi
        function getFlagEmoji(countryCode) {
            const codePoints = countryCode.toUpperCase().split('').map(ch => 127397 + ch.charCodeAt());
            return String.fromCodePoint(...codePoints);
        }

        // Alarm kontrolü
        function checkAlerts(aircraft) {
            if (aircraft.alt > 11500 && [7700, 7600, 7500].includes(aircraft.squawk)) {
                showToast(`🚨 ACİL DURUM! ${aircraft.callsign} | Squawk ${aircraft.squawk} | İrtifa ${Math.round(aircraft.alt)}m`);
            } else if (aircraft.alt > 11500) {
                showToast(`⚠️ Yüksek irtifa uyarısı: ${aircraft.callsign} ${Math.round(aircraft.alt)}m`);
            } else if ([7700,7600,7500].includes(aircraft.squawk)) {
                showToast(`🆘 Acil Durum Kodu: ${aircraft.callsign} - Squawk ${aircraft.squawk}`);
            }
        }

        function showToast(msg) {
            const toast = document.createElement('div');
            toast.className = 'toast';
            toast.innerText = msg;
            document.body.appendChild(toast);
            setTimeout(() => toast.remove(), 4000);
        }

        // Uçakları haritaya ekleme (symbol layer ile)
        function updateAircraftMarkers() {
            if (!map.getSource('aircraft')) return;
            const filtered = aircraftData.filter(ac => {
                if (currentFilter.callsign && !ac.callsign.toLowerCase().includes(currentFilter.callsign.toLowerCase())) return false;
                if (currentFilter.country && ac.country !== currentFilter.country.toUpperCase()) return false;
                if (currentFilter.icao && !ac.icao.toLowerCase().includes(currentFilter.icao.toLowerCase())) return false;
                return true;
            });
            const geojson = {
                type: 'FeatureCollection',
                features: filtered.map(ac => ({
                    type: 'Feature',
                    geometry: { type: 'Point', coordinates: [ac.lng, ac.lat] },
                    properties: {
                        id: ac.id,
                        callsign: ac.callsign,
                        alt: ac.alt,
                        speed: ac.speed,
                        heading: ac.heading,
                        squawk: ac.squawk,
                        country: ac.country,
                        flag: getFlagEmoji(ac.country),
                        icao: ac.icao
                    }
                }))
            };
            map.getSource('aircraft').setData(geojson);
            
            // Acil durum katmanı: sadece squawk 7700 olanlar
            const emergencyFeatures = filtered.filter(ac => ac.squawk === 7700).map(ac => ({
                type: 'Feature',
                geometry: { type: 'Point', coordinates: [ac.lng, ac.lat] },
                properties: { ...ac.properties, id: ac.id }
            }));
            if (map.getSource('emergency')) {
                map.getSource('emergency').setData({ type: 'FeatureCollection', features: emergencyFeatures });
            }
        }

        // İstatistikleri güncelle
        function updateStatistics() {
            if (!countryChart) return;
            const countries = {};
            const speedBuckets = { '0-200':0, '200-400':0, '400-600':0, '600-800':0, '800+':0 };
            const altBuckets = { '0-3000':0, '3000-6000':0, '6000-9000':0, '9000-12000':0, '12000+':0 };
            aircraftData.forEach(ac => {
                countries[ac.country] = (countries[ac.country] || 0) + 1;
                const spd = ac.speed;
                if (spd<200) speedBuckets['0-200']++;
                else if (spd<400) speedBuckets['200-400']++;
                else if (spd<600) speedBuckets['400-600']++;
                else if (spd<800) speedBuckets['600-800']++;
                else speedBuckets['800+']++;
                const alt = ac.alt;
                if (alt<3000) altBuckets['0-3000']++;
                else if (alt<6000) altBuckets['3000-6000']++;
                else if (alt<9000) altBuckets['6000-9000']++;
                else if (alt<12000) altBuckets['9000-12000']++;
                else altBuckets['12000+']++;
            });
            countryChart.data.labels = Object.keys(countries);
            countryChart.data.datasets[0].data = Object.values(countries);
            countryChart.update();
            speedChart.data.labels = Object.keys(speedBuckets);
            speedChart.data.datasets[0].data = Object.values(speedBuckets);
            speedChart.update();
            altChart.data.labels = Object.keys(altBuckets);
            altChart.data.datasets[0].data = Object.values(altBuckets);
            altChart.update();
        }

        // Seçili uçağın izini güncelle
        function updateTrail() {
            if (!selectedAircraftId) return;
            const ac = aircraftData.find(a => a.id === selectedAircraftId);
            if (!ac) return;
            trailPositions.push([ac.lng, ac.lat]);
            if (trailPositions.length > 50) trailPositions.shift();
            if (trailSource) {
                trailSource.setData({
                    type: 'Feature',
                    geometry: { type: 'LineString', coordinates: trailPositions }
                });
            }
        }

        // Hız göstergesini güncelle
        function updateSpeedGauge(speed) {
            const canvas = document.getElementById('speedGauge');
            const ctx = canvas.getContext('2d');
            const w = canvas.width, h = canvas.height;
            ctx.clearRect(0,0,w,h);
            const percent = Math.min(1, speed / 1000);
            ctx.beginPath();
            ctx.arc(w/2, h, w/2, Math.PI, 0);
            ctx.fillStyle = '#333';
            ctx.fill();
            ctx.beginPath();
            ctx.arc(w/2, h, w/2, Math.PI, Math.PI + Math.PI * percent);
            ctx.fillStyle = '#4c6ef5';
            ctx.fill();
            ctx.fillStyle = 'white';
            ctx.font = 'bold 14px sans-serif';
            ctx.fillText(`${Math.round(speed)} km/h`, w/2-30, h-10);
            document.getElementById('speedValue').innerText = Math.round(speed);
        }

        // Terminator (gece/gündüz çizgisi)
        function updateTerminator() {
            const now = new Date();
            const lat = map.getCenter().lat;
            const lng = map.getCenter().lng;
            const times = SunCalc.getTimes(now, lat, lng);
            const sunrise = times.sunrise;
            const sunset = times.sunset;
            // Basitçe bir polygon çizimi için, güneşin pozisyonuna göre terminator hattını hesaplamak karmaşık.
            // Alternatif: SunCalc.getIlluminatedFraction veya precomputed geoJSON.
            // Bu demo için basit bir daire veya yarı saydam katman kullanacağız.
            if (!terminatorLayer) {
                map.addLayer({
                    id: 'terminator',
                    type: 'fill',
                    source: {
                        type: 'geojson',
                        data: {
                            type: 'Feature',
                            geometry: { type: 'Polygon', coordinates: [[[-180, -90], [180, -90], [180, 90], [-180, 90], [-180, -90]]] }
                        }
                    },
                    paint: {
                        'fill-color': '#000',
                        'fill-opacity': 0.3
                    }
                });
                terminatorLayer = 'terminator';
            }
            // Güncelleme için daha hassas bir yaklaşım gerekir, şimdilik sabit opacity ile geçiyoruz.
        }

        // Hava durumu katmanı (OpenWeatherMap bulut)
        function toggleWeather() {
            if (weatherLayer) {
                if (map.getLayer('weather')) map.removeLayer('weather');
                if (map.getSource('weather')) map.removeSource('weather');
                weatherLayer = null;
            } else {
                map.addSource('weather', {
                    type: 'raster',
                    tiles: [`https://tile.openweathermap.org/map/clouds_new/{z}/{x}/{y}.png?appid=YOUR_OPENWEATHERMAP_API_KEY`],
                    tileSize: 256,
                    attribution: '&copy; OpenWeatherMap'
                });
                map.addLayer({
                    id: 'weather',
                    type: 'raster',
                    source: 'weather',
                    paint: { 'raster-opacity': 0.6 }
                });
                weatherLayer = true;
            }
        }

        // Klavye kısayolları
        function initKeyboard() {
            document.addEventListener('keydown', (e) => {
                const key = e.key.toLowerCase();
                switch(key) {
                    case 'f': toggleFilterModal(); break;
                    case 'r': map.flyTo({ center: [32.8597, 39.9334], zoom: 6 }); break;
                    case 'l': toggleAircraftList(); break; // basit liste modal yapılabilir
                    case 's': toggleStatsPanel(); break;
                    case 'd': toggleDetailsPanel(); break; // seçili uçak detayları
                    case 't': if(selectedAircraftId) toggleTrail(); break;
                    case 'h': toggleWeather(); break;
                    case 'c': copyCoordinates(); break;
                    case 'escape': closeFilterModal(); break;
                    case 'f11': fullscreen(); break;
                    case '?': showHelp(); break;
                }
            });
        }

        function toggleStatsPanel() {
            const panel = document.getElementById('statsPanel');
            panel.style.display = panel.style.display === 'none' ? 'flex' : 'none';
        }
        function toggleFilterModal() {
            const modal = document.getElementById('filterModal');
            modal.style.display = modal.style.display === 'none' ? 'flex' : 'none';
        }
        function closeFilterModal() {
            document.getElementById('filterModal').style.display = 'none';
        }
        function copyCoordinates() {
            const center = map.getCenter();
            navigator.clipboard.writeText(`${center.lng.toFixed(5)}, ${center.lat.toFixed(5)}`);
            showToast('Koordinatlar kopyalandı: ' + center.lng.toFixed(5) + ', ' + center.lat.toFixed(5));
        }
        function fullscreen() {
            const elem = document.documentElement;
            if (elem.requestFullscreen) elem.requestFullscreen();
        }
        function showHelp() {
            alert('Kısayollar:\nF: Filtre\nR: Haritayı sıfırla\nL: Uçak Listesi\nS: İstatistik\nD: Detay\nT: İz\nH: Hava Durumu\nC: Koordinat kopyala\nESC: Kapat\nF11: Tam ekran\n? : Bu yardım');
        }
        function toggleAircraftList() {
            // Basit liste gösterimi
            let list = 'Uçaklar:\n';
            aircraftData.forEach(ac => {
                list += `${ac.callsign} (${ac.country}) - ${Math.round(ac.alt)}m - ${Math.round(ac.speed)}km/h\n`;
            });
            alert(list);
        }
        function toggleDetailsPanel() {
            if (selectedAircraftId) {
                const ac = aircraftData.find(a => a.id === selectedAircraftId);
                if (ac) {
                    alert(`✈️ ${ac.callsign}\nÜlke: ${ac.country} ${getFlagEmoji(ac.country)}\nICAO: ${ac.icao}\nİrtifa: ${Math.round(ac.alt)} m\nHız: ${Math.round(ac.speed)} km/h\nSquawk: ${ac.squawk}\nBaşlık: ${Math.round(ac.heading)}°`);
                }
            } else {
                alert('Lütfen bir uçak seçin (haritaya tıklayın).');
            }
        }
        function toggleTrail() {
            if (trailLayer) {
                if (map.getLayer('trail')) map.removeLayer('trail');
                if (map.getSource('trail')) map.removeSource('trail');
                trailLayer = null;
            } else {
                map.addSource('trail', {
                    type: 'geojson',
                    data: { type: 'Feature', geometry: { type: 'LineString', coordinates: trailPositions } }
                });
                map.addLayer({
                    id: 'trail',
                    type: 'line',
                    source: 'trail',
                    paint: { 'line-color': '#00ffcc', 'line-width': 3 }
                });
                trailLayer = true;
            }
        }

        // GPS konumuna git
        function locateMe() {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(pos => {
                    map.flyTo({ center: [pos.coords.longitude, pos.coords.latitude], zoom: 12 });
                }, err => showToast('Konum alınamadı'));
            }
        }

        // FlightAware link
        function openFlightAware(icao) {
            if (icao) window.open(`https://flightaware.com/live/flight/${icao}`, '_blank');
            else showToast('ICAO bilgisi yok');
        }

        // Haritaya tıklama ile uçak seçme
        function initMapEvents() {
            map.on('click', 'aircraft-layer', (e) => {
                const props = e.features[0].properties;
                selectedAircraftId = props.id;
                trailPositions = [];
                if (trailLayer) {
                    map.getSource('trail').setData({ type: 'Feature', geometry: { type: 'LineString', coordinates: [] } });
                }
                updateSpeedGauge(props.speed);
                document.getElementById('gaugeContainer').style.display = 'flex';
                showToast(`${props.callsign} seçildi`);
                // FlightAware butonu ekleyebiliriz
            });
            map.on('click', (e) => {
                // Boş alana tıklanırsa seçimi kaldır
                const features = map.queryRenderedFeatures(e.point, { layers: ['aircraft-layer'] });
                if (features.length === 0) {
                    selectedAircraftId = null;
                    document.getElementById('gaugeContainer').style.display = 'none';
                }
            });
        }

        // Compass güncelleme
        function updateCompass() {
            const bearing = map.getBearing();
            document.getElementById('compass').style.transform = `rotate(${bearing}deg)`;
        }
        map.on('rotate', updateCompass);
        map.on('load', () => {
            updateCompass();
            // Harita kaynakları ve katmanlar
            map.addSource('aircraft', {
                type: 'geojson',
                data: { type: 'FeatureCollection', features: [] }
            });
            map.addLayer({
                id: 'aircraft-layer',
                type: 'symbol',
                source: 'aircraft',
                layout: {
                    'icon-image': 'airport-15', // Mapbox varsayılan simgesi
                    'icon-rotate': ['get', 'heading'],
                    'icon-rotation-alignment': 'map',
                    'icon-size': 1.2,
                    'text-field': ['get', 'callsign'],
                    'text-offset': [0, 1.2],
                    'text-size': 10,
                    'text-font': ['DIN Offc Pro Medium', 'Arial Unicode MS Bold']
                },
                paint: {
                    'text-color': '#ffffff',
                    'text-halo-color': '#000000',
                    'text-halo-width': 1
                }
            });
            // Acil durum katmanı (kırmızı yanıp sönen)
            map.addSource('emergency', {
                type: 'geojson',
                data: { type: 'FeatureCollection', features: [] }
            });
            map.addLayer({
                id: 'emergency-layer',
                type: 'symbol',
                source: 'emergency',
                layout: {
                    'icon-image': 'marker-15',
                    'icon-size': 1.5,
                    'text-field': '🚨',
                    'text-offset': [0, -1]
                },
                paint: {
                    'icon-color': '#ff0000',
                    'icon-opacity': 0.8
                }
            });
            trailSource = new mapboxgl.GeoJSONSource({ data: { type: 'Feature', geometry: { type: 'LineString', coordinates: [] } } });
            map.addSource('trail', trailSource);
            map.addLayer({
                id: 'trail',
                type: 'line',
                source: 'trail',
                paint: { 'line-color': '#00ffcc', 'line-width': 3 }
            });
            // İstatistik grafiklerini başlat
            const ctxCountry = document.getElementById('countryChart').getContext('2d');
            const ctxSpeed = document.getElementById('speedChart').getContext('2d');
            const ctxAlt = document.getElementById('altChart').getContext('2d');
            countryChart = new Chart(ctxCountry, { type: 'bar', data: { labels: [], datasets: [{ label: 'Ülke Dağılımı', data: [], backgroundColor: '#4c6ef5' }] } });
            speedChart = new Chart(ctxSpeed, { type: 'bar', data: { labels: [], datasets: [{ label: 'Hız Dağılımı (km/h)', data: [], backgroundColor: '#f5a623' }] } });
            altChart = new Chart(ctxAlt, { type: 'bar', data: { labels: [], datasets: [{ label: 'İrtifa Dağılımı (m)', data: [], backgroundColor: '#23c5f5' }] } });
            // Simülasyon başlat
            startSimulation();
        });

        function startSimulation() {
            setInterval(() => {
                aircraftData = generateMockAircraft(30);
                // Her uçak için alarm kontrolü
                aircraftData.forEach(ac => checkAlerts(ac));
                updateAircraftMarkers();
                updateStatistics();
                if (selectedAircraftId) {
                    const selected = aircraftData.find(a => a.id === selectedAircraftId);
                    if (selected) updateSpeedGauge(selected.speed);
                    updateTrail();
                }
                // Loading overlay kaldır
                const loading = document.getElementById('loadingOverlay');
                if (loading) loading.style.display = 'none';
            }, 3000);
        }

        // Partikül animasyonu (basit)
        function particleAnimation() {
            const canvas = document.getElementById('particleCanvas');
            const ctx = canvas.getContext('2d');
            let width = window.innerWidth, height = window.innerHeight;
            canvas.width = width; canvas.height = height;
            let particles = [];
            for (let i = 0; i < 100; i++) {
                particles.push({ x: Math.random()*width, y: Math.random()*height, vx: (Math.random()-0.5)*2, vy: (Math.random()-0.5)*2 });
            }
            function draw() {
                ctx.clearRect(0,0,width,height);
                ctx.fillStyle = '#0a0a1a';
                ctx.fillRect(0,0,width,height);
                ctx.fillStyle = '#ffffff';
                particles.forEach(p => {
                    ctx.beginPath();
                    ctx.arc(p.x, p.y, 2, 0, Math.PI*2);
                    ctx.fill();
                    p.x += p.vx;
                    p.y += p.vy;
                    if (p.x < 0 || p.x > width) p.vx *= -1;
                    if (p.y < 0 || p.y > height) p.vy *= -1;
                });
                requestAnimationFrame(draw);
            }
            draw();
            window.addEventListener('resize', () => {
                width = window.innerWidth;
                height = window.innerHeight;
                canvas.width = width; canvas.height = height;
            });
        }
        particleAnimation();

        // GPS butonu (isteğe bağlı)
        const locateBtn = document.createElement('div');
        locateBtn.className = 'control-panel';
        locateBtn.style.top = '80px';
        locateBtn.style.right = '20px';
        locateBtn.innerHTML = '<i class="fas fa-location-arrow"></i>';
        locateBtn.style.cursor = 'pointer';
        locateBtn.onclick = locateMe;
        document.body.appendChild(locateBtn);

        // FlightAware butonu (seçili uçak için)
        const faBtn = document.createElement('div');
        faBtn.className = 'control-panel';
        faBtn.style.top = '140px';
        faBtn.style.right = '20px';
        faBtn.innerHTML = '<i class="fas fa-external-link-alt"></i>';
        faBtn.style.cursor = 'pointer';
        faBtn.onclick = () => {
            if (selectedAircraftId) {
                const ac = aircraftData.find(a => a.id === selectedAircraftId);
                if (ac) openFlightAware(ac.icao);
            } else showToast('Uçak seçili değil');
        };
        document.body.appendChild(faBtn);

        // Koordinat kopyala butonu
        const coordBtn = document.createElement('div');
        coordBtn.className = 'control-panel';
        coordBtn.style.top = '200px';
        coordBtn.style.right = '20px';
        coordBtn.innerHTML = '<i class="fas fa-copy"></i>';
        coordBtn.onclick = copyCoordinates;
        document.body.appendChild(coordBtn);

        // Filtre uygulama
        document.getElementById('applyFilter').onclick = () => {
            currentFilter.callsign = document.getElementById('filterCallsign').value;
            currentFilter.country = document.getElementById('filterCountry').value;
            currentFilter.icao = document.getElementById('filterICAO').value;
            updateAircraftMarkers();
            closeFilterModal();
        };
        document.getElementById('resetFilter').onclick = () => {
            currentFilter = { callsign: '', country: '', icao: '' };
            document.getElementById('filterCallsign').value = '';
            document.getElementById('filterCountry').value = '';
            document.getElementById('filterICAO').value = '';
            updateAircraftMarkers();
            closeFilterModal();
        };

        initKeyboard();
        initMapEvents();
        setInterval(updateTerminator, 60000); // dakikada bir terminator güncelle
        updateTerminator();
    </script>
</body>
</html>
EOF

echo -e "${GREEN}HTML file created: $HTML_FILE${NC}"

# Ask for port or randomize
read -p "Enter port number (leave empty for random): " PORT
if [ -z "$PORT" ]; then
    PORT=$((RANDOM % 64512 + 1024))
    echo -e "${YELLOW}Random port selected: $PORT${NC}"
else
    echo -e "${GREEN}Using port: $PORT${NC}"
fi

IP=$(get_ip)
URL="http://$IP:$PORT/$HTML_FILE"

echo -e "${GREEN}Starting server on port $PORT...${NC}"
echo -e "${GREEN}Access the flight tracker at: $URL${NC}"
echo "Press Ctrl+C to stop the server."

# Start Python HTTP server
cd "$(dirname "$0")"
python3 -m http.server "$PORT" --bind 0.0.0.0
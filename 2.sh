#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  SKYWATCH v4.5 — Altitude Color Gradient Edition             ║
# ║  Ozellikler: İrtifaya Göre Renkli Rota, Dinamik IP           ║
# ╚══════════════════════════════════════════════════════════════╝

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'; B='\033[1m'

clear
printf "${G}${B}  S K Y W A T C H  v4.5  |  ALTITUDE HEATMAP\n"
printf "  ─────────────────────────────────────────────────────────${N}\n"

PY=$(command -v python3 || command -v python)
LIP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1)
PORT=$(( RANDOM % 10000 + 15000 ))
TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/index.html"

$PY << 'PYEOF'
import os
HTML_PATH = os.path.join(os.environ.get("TMPDIR", "/tmp"), "index.html")

html_content = """
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8' />
    <title>SKYWATCH v4.5 - Altitude Logic</title>
    <meta name='viewport' content='initial-scale=1,maximum-scale=1,user-scalable=no' />
    <script src='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js'></script>
    <link href='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css' rel='stylesheet' />
    <style>
        body { margin: 0; padding: 0; background: #010b13; font-family: 'monospace'; }
        #map { position: absolute; top: 0; bottom: 0; width: 100%; }
        .ui-panel { position: fixed; top: 10px; left: 10px; background: rgba(1, 11, 19, 0.9); padding: 12px; border: 1px solid #00ff88; z-index: 10; border-radius: 4px; color: #00ff88; font-size: 12px;}
        .leg-item { display: flex; align-items: center; gap: 5px; margin-top: 4px; }
        .dot { width: 10px; height: 10px; border-radius: 50%; }
    </style>
</head>
<body>
<div id='map'></div>
<div class='ui-panel'>
    <b>SKYWATCH v4.5</b><br>
    <small>İrtifa Renkleri (Metre):</small>
    <div class='leg-item'><div class='dot' style='background:#00e5ff'></div> > 8000m</div>
    <div class='leg-item'><div class='dot' style='background:#00ff88'></div> 4000-8000m</div>
    <div class='leg-item'><div class='dot' style='background:#ffcc00'></div> 1500-4000m</div>
    <div class='leg-item'><div class='dot' style='background:#ff4466'></div> < 1500m</div>
</div>

<script>
    mapboxgl.accessToken = 'pk.eyJ1Ijoic2t5d2F0Y2gxMjMiLCJhIjoiY2x2Ynl6YTM4MDFrejJpcGZ0Mzhicm90cSJ9.X8NUnYV6aM9-8N0X';
    
    const map = new mapboxgl.Map({
        container: 'map',
        style: 'mapbox://styles/mapbox/dark-v11',
        center: [35, 39],
        zoom: 5.5,
        pitch: 45
    });

    const markers = {};
    const flightPaths = {};

    function getAltColor(alt) {
        if (alt > 8000) return '#00e5ff'; // Seyir
        if (alt > 4000) return '#00ff88'; // Tırmanma
        if (alt > 1500) return '#ffcc00'; // Yaklaşma
        return '#ff4466'; // İniş/Kalkış
    }

    async function updateFlights() {
        try {
            const res = await fetch('https://opensky-network.org/api/states/all?lamin=35&lomin=26&lamax=42&lomax=45');
            const data = await res.json();
            if(!data.states) return;

            data.states.forEach(s => {
                const icao = s[0], ln = s[5], lt = s[6], alt = s[7] || 0, hd = s[10] || 0;
                if (!ln || !lt) return;

                const currentColor = getAltColor(alt);

                // 1. Rota/Çizgi Yönetimi
                if (!flightPaths[icao]) {
                    flightPaths[icao] = [];
                    map.addSource(`src-${icao}`, {
                        'type': 'geojson',
                        'data': { 'type': 'Feature', 'geometry': { 'type': 'LineString', 'coordinates': [] } }
                    });
                    map.addLayer({
                        'id': `layer-${icao}`,
                        'type': 'line',
                        'source': `src-${icao}`,
                        'paint': { 
                            'line-color': currentColor, 
                            'line-width': 2,
                            'line-opacity': 0.7 
                        }
                    });
                }
                
                flightPaths[icao].push([ln, lt]);
                if (flightPaths[icao].length > 40) flightPaths[icao].shift();

                // Çizgi rengini anlık irtifaya göre güncelle
                map.setPaintProperty(`layer-${icao}`, 'line-color', currentColor);
                
                map.getSource(`src-${icao}`).setData({
                    'type': 'Feature',
                    'geometry': { 'type': 'LineString', 'coordinates': flightPaths[icao] }
                });

                // 2. Marker Yönetimi
                if (markers[icao]) {
                    markers[icao].setLngLat([ln, lt]);
                    markers[icao].getElement().style.transform += ` rotate(${hd}deg)`;
                    markers[icao].getElement().querySelector('path').setAttribute('fill', currentColor);
                } else {
                    const el = document.createElement('div');
                    el.innerHTML = `<svg width="20" height="20" viewBox="0 0 24 24"><path d="M21,16L21,14L13,9L13,3.5A1.5,1.5 0 0,0 11.5,2A1.5,1.5 0 0,0 10,3.5L10,9L2,14L2,16L10,13.5L10,19L8,20.5L8,22L11.5,21L15,22L15,20.5L13,19L13,13.5L21,16Z" fill="${currentColor}"/></svg>`;
                    el.style.transition = "all 1s linear";
                    markers[icao] = new mapboxgl.Marker(el).setLngLat([ln, lt]).addTo(map);
                }
            });
        } catch (e) {}
    }

    map.on('load', () => {
        setInterval(updateFlights, 5000);
        updateFlights();
    });
</script>
</body>
</html>
"""

with open(HTML_PATH, "w", encoding="utf-8") as f:
    f.write(html_content)
PYEOF

printf "  ${G}[✔] Rota ve İrtifa Renklendirme Aktif.${N}\n"
printf "  ${C}[+] Adres:${N} http://$LIP:$PORT\n"

cd "$TMPD" && $PY -m http.server $PORT

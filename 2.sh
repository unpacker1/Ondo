#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  SKYWATCH ULTIMATE — Enhanced Cyber-Radar            ║
# ║  Eklenenler: Havayolu Tanıma, Rota İzleme, Trendler  ║
# ╚══════════════════════════════════════════════════════╝

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'; B='\033[1m'

clear
echo -e "${G}${B}"
echo "  ███████╗██╗  ██╗██╗   ██╗██╗    ██╗ █████╗ ████████╗"
echo "  ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║    ██║██╔══██╗╚══██╔══╝"
echo "  ███████╗█████╔╝  ╚████╔╝ ██║ █╗ ██║███████║   ██║   "
echo "  ╚════██║██╔═██╗   ╚██╔╝  ██║███╗██║██╔══██║   ██║   "
echo "  ███████║██║  ██╗   ██║   ╚███╔███╔╝██║  ██║   ██║   "
echo "  ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝   "
echo -e "${N}"
echo -e "  ${C}Geliştirilmiş Radar Sistemi — [3 Yeni Modül Aktif]${N}"

PY=$(command -v python3 || command -v python)
TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/skywatch_pro.html"

$PY << 'PYEOF'
import os
TMPD = os.environ.get("TMPDIR", "/tmp")
HTML = os.path.join(TMPD, "skywatch_pro.html")

page = """
<!DOCTYPE html>
<html lang='tr'>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<title>SKYWATCH PRO</title>
<link href='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css' rel='stylesheet'>
<script src='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js'></script>
<link href='https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;900&display=swap' rel='stylesheet'>
<style>
:root{--g:#00ff88;--c:#00e5ff;--o:#ff6b35;--r:#ff3b3b;--d:#020810;--p:rgba(2,15,25,0.92);--b:rgba(0,255,136,0.25);--t:#a8ffd4}
*{margin:0;padding:0;box-sizing:border-box}
body{background:var(--d);color:var(--t);font-family:'Share Tech Mono',monospace;overflow:hidden;height:100vh}
body::after{content:'';position:fixed;inset:0;background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,255,136,.015) 2px,rgba(0,255,136,.015) 4px);pointer-events:none;z-index:9999}
#map{position:absolute;inset:0;width:100%;height:100%}
.topbar{position:fixed;top:0;left:0;right:0;height:54px;background:var(--p);border-bottom:1px solid var(--b);display:flex;align-items:center;padding:0 16px;z-index:100;backdrop-filter:blur(12px)}
.logo{font-family:'Orbitron',sans-serif;font-weight:900;font-size:17px;color:var(--g);letter-spacing:4px;text-shadow:0 0 15px var(--g)}
.stats{display:flex;gap:14px;margin-left:20px;font-size:11px}
.v{color:var(--c)}
.lp{position:fixed;top:54px;left:0;bottom:0;width:250px;background:var(--p);border-right:1px solid var(--b);z-index:100;display:flex;flex-direction:column;overflow-y:auto}
.fi{padding:10px;border-bottom:1px solid rgba(0,255,136,0.07);cursor:pointer}
.fi:hover, .fi.sel{background:rgba(0,255,136,0.12)}
.ip{position:fixed;bottom:20px;right:20px;width:285px;background:var(--p);border:1px solid var(--b);backdrop-filter:blur(16px);z-index:110;display:none;padding:15px}
.ip.vis{display:block}
.ih{font-family:Orbitron;color:var(--c);margin-bottom:12px;display:flex;justify-content:space-between;border-bottom:1px solid var(--b);padding-bottom:5px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:10px;font-size:11px}
.label{font-size:9px;color:rgba(168,255,212,0.4);text-transform:uppercase}
.val{color:var(--g);font-family:Orbitron}
.trend-up{color:var(--g)} .trend-down{color:var(--r)}
.btn{background:none;border:1px solid var(--b);color:var(--g);padding:4px 8px;cursor:pointer;font-family:inherit;margin-left:5px}
</style>
</head>
<body>
    <div class='topbar'>
        <div class='logo'>SKYWATCH</div>
        <div class='stats'>UÇAK: <span id='pc' class='v'>0</span> | DURUM: <span id='st' class='v'>RADAR AKTİF</span></div>
        <div style="margin-left:auto"><button class='btn' onclick="location.reload()">SİSTEM YENİLE</button></div>
    </div>
    <div class='lp' id='fl'></div>
    <div id='map'></div>
    <div class='ip' id='ip'>
        <div class='ih'><span id='d-call'>---</span><span onclick="document.getElementById('ip').classList.remove('vis')" style="cursor:pointer">×</span></div>
        <div class='grid'>
            <div><div class='label'>OPERATÖR</div><div class='val' id='d-op'>---</div></div>
            <div><div class='label'>ÜLKE</div><div class='val' id='d-cou'>---</div></div>
            <div><div class='label'>İRTİFA</div><div class='val' id='d-alt'>---</div></div>
            <div><div class='label'>HIZ</div><div class='val' id='d-spd'>---</div></div>
            <div><div class='label'>SQUAWK</div><div class='val' id='d-sqk'>---</div></div>
            <div><div class='label'>TREND</div><div class='val' id='d-trd'>---</div></div>
        </div>
    </div>

    <script>
        let map, mbToken = localStorage.getItem('mbt') || '', markers = {}, selIcao = null;
        const AIRLINES = {"THY":"TURKISH AIR", "PGT":"PEGASUS", "DLH":"LUFTHANSA", "BAW":"BRITISH AW", "AFR":"AIR FRANCE", "UAE":"EMIRATES", "QTR":"QATAR AIR", "LOT":"POLISH AIR"};

        if(!mbToken) {
            mbToken = prompt("Mapbox Token giriniz (Demo için boş bırakın):");
            if(mbToken) localStorage.setItem('mbt', mbToken);
        }

        mapboxgl.accessToken = mbToken;
        map = new mapboxgl.Map({
            container: 'map',
            style: 'mapbox://styles/mapbox/satellite-v9',
            center: [35, 39], zoom: 5, antialias: true
        });

        // Rota çizimi için boş kaynak
        map.on('load', () => {
            map.addSource('route', { type: 'geojson', data: { type: 'Feature', geometry: { type: 'LineString', coordinates: [] } } });
            map.addLayer({ id: 'route-line', type: 'line', source: 'route', layout: { 'line-join': 'round', 'line-cap': 'round' }, paint: { 'line-color': '#00ff88', 'line-width': 2, 'line-dasharray': [2, 1] } });
        });

        async function updateData() {
            try {
                const res = await fetch('https://opensky-network.org/api/states/all?lamin=34&lomin=24&lamax=43&lomax=46');
                const data = await res.json();
                const flights = data.states.map(s => ({
                    icao: s[0], call: (s[1]||s[0]).trim(), cou: s[2], 
                    lon: s[5], lat: s[6], alt: Math.round(s[7]), 
                    spd: Math.round(s[9]*3.6), hdg: s[10], sqk: s[14],
                    vrt: s[11] // Dikey hız (tırmanış/alçalış için)
                })).filter(f => f.lat);

                document.getElementById('pc').textContent = flights.length;
                renderList(flights);
                renderMarkers(flights);
            } catch(e) { console.error("Veri hatası"); }
        }

        function renderList(flights) {
            const cont = document.getElementById('fl');
            cont.innerHTML = '';
            flights.forEach(f => {
                const div = document.createElement('div');
                div.className = `fi ${f.icao === selIcao ? 'sel' : ''}`;
                div.innerHTML = `<b>${f.call}</b><br><small>${f.alt}m | ${f.spd}km/h</small>`;
                div.onclick = () => selectFlight(f);
                cont.appendChild(div);
            });
        }

        function renderMarkers(flights) {
            flights.forEach(f => {
                const color = f.sqk === '7700' ? '#ff3b3b' : (f.icao === selIcao ? '#00e5ff' : '#00ff88');
                if(markers[f.icao]) {
                    markers[f.icao].setLngLat([f.lon, f.lat]);
                    markers[f.icao].getElement().querySelector('path').setAttribute('fill', color);
                    markers[f.icao].getElement().style.transform = `rotate(${f.hdg}deg)`;
                } else {
                    const el = document.createElement('div');
                    el.innerHTML = `<svg viewBox="0 0 24 24" width="20" height="20"><path d="M21,16L21,14L13,9L13,3.5A1.5,1.5 0 0,0 11.5,2A1.5,1.5 0 0,0 10,3.5L10,9L2,14L2,16L10,13.5L10,19L8,20.5L8,22L11.5,21L15,22L15,20.5L13,19L13,13.5L21,16Z" fill="${color}"/></svg>`;
                    el.style.transform = `rotate(${f.hdg}deg)`;
                    markers[f.icao] = new mapboxgl.Marker(el).setLngLat([f.lon, f.lat]).addTo(map);
                    el.onclick = () => selectFlight(f);
                }
            });
        }

        function selectFlight(f) {
            selIcao = f.icao;
            const opCode = f.call.substring(0,3);
            document.getElementById('d-call').textContent = f.call;
            document.getElementById('d-op').textContent = AIRLINES[opCode] || "UNKNOWN";
            document.getElementById('d-cou').textContent = f.cou;
            document.getElementById('d-alt').textContent = f.alt + " M";
            document.getElementById('d-spd').textContent = f.spd + " KM/H";
            document.getElementById('d-sqk').textContent = f.sqk || "----";
            
            // Trend Belirleme
            const trendEl = document.getElementById('d-trd');
            if(f.vrt > 0.5) { trendEl.innerHTML = "<span class='trend-up'>▲ CLIMBING</span>"; }
            else if(f.vrt < -0.5) { trendEl.innerHTML = "<span class='trend-down'>▼ DESCENDING</span>"; }
            else { trendEl.innerHTML = "LEVEL FLIGHT"; }

            document.getElementById('ip').classList.add('vis');
            
            // Rota Çizimi (Basit simülasyon: mevcut konumdan geriye doğru kısa bir iz)
            if(map.getSource('route')) {
                const backLon = f.lon - (Math.sin(f.hdg * Math.PI/180) * 0.1);
                const backLat = f.lat - (Math.cos(f.hdg * Math.PI/180) * 0.1);
                map.getSource('route').setData({
                    type: 'Feature',
                    geometry: { type: 'LineString', coordinates: [[backLon, backLat], [f.lon, f.lat]] }
                });
            }

            map.flyTo({center: [f.lon, f.lat], zoom: 8});
            updateData(); // Listeyi güncelle (seçili olanı işaretlemek için)
        }

        setInterval(updateData, 25000);
        updateData();
    </script>
</body>
</html>
"""
with open(HTML, "w", encoding="utf-8") as f:
    f.write(page)
PYEOF

echo -e "  ${G}Sistem Hazır!${N}"
echo -e "  ${Y}Dosya Yolu: $HTML${N}"
termux-open "$HTML" || echo -e "  ${C}Lütfen tarayıcıda açın.${N}"

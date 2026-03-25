#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  SKYWATCH — Termux All-in-One Launcher               ║
# ║  Calistir: bash skywatch.sh                          ║
# ╚══════════════════════════════════════════════════════╝

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'; B='\033[1m'

# ----- AYARLAR -----
HOST="0.0.0.0"
PORT="8080"
OS_USERNAME=""
OS_PASSWORD=""
UPDATE_INTERVAL=20
# -------------------

clear
echo ""
echo -e "${G}${B}"
echo "  ███████╗██╗  ██╗██╗   ██╗██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗"
echo "  ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║"
echo "  ███████╗█████╔╝  ╚████╔╝ ██║ █╗ ██║███████║   ██║   ██║     ███████║"
echo "  ╚════██║██╔═██╗   ╚██╔╝  ██║███╗██║██╔══██║   ██║   ██║     ██╔══██║"
echo "  ███████║██║  ██╗   ██║   ╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║"
echo "  ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝    ╚═╝    ╚═════╝╚═╝  ╚═╝"
echo -e "${N}"
echo -e "  ${C}Canli Ucak Takip — OpenSky + Mapbox Uydu${N}"
echo "  ───────────────────────────────────────────"
echo ""

if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
  echo -e "  ${Y}Python yukleniyor...${N}"
  pkg install python -y
fi

PY=$(command -v python3 || command -v python)
TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/skywatch_index.html"

if [[ -z "$OS_USERNAME" || -z "$OS_PASSWORD" ]]; then
    echo -e "  ${Y}UYARI: OpenSky kullanıcı adı/şifre ayarlanmamış!${N}"
    echo -e "  ${Y}429 hatasını önlemek için https://opensky-network.org adresinden ücretsiz kaydolun.${N}"
    echo ""
fi

echo -e "  ${C}HTML olusturuluyor...${N}"

$PY << PYEOF
import os
import base64

TMPD = os.environ.get("TMPDIR", "/tmp")
HTML = os.path.join(TMPD, "skywatch_index.html")

os_username = "${OS_USERNAME}"
os_password = "${OS_PASSWORD}"
update_interval = ${UPDATE_INTERVAL}

auth_header = ""
if os_username and os_password:
    auth_string = f"{os_username}:{os_password}"
    auth_header = base64.b64encode(auth_string.encode()).decode()

html_content = f"""<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<title>SKYWATCH - Canlı Uçak Takip</title>
<!-- Leaflet CSS/JS (demo mod için) -->
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<!-- Mapbox CSS/JS (token modu için) -->
<link href="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css" rel="stylesheet" />
<script src="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js"></script>
<link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&display=swap" rel="stylesheet">
<style>
:root{{--g:#00ff88;--c:#00e5ff;--o:#ff6b35;--d:#020810;--p:rgba(2,15,25,0.92);--b:rgba(0,255,136,0.25);--t:#a8ffd4}}
*{{margin:0;padding:0;box-sizing:border-box}}
body{{background:var(--d);color:var(--t);font-family:'Share Tech Mono',monospace;overflow:hidden;height:100vh;width:100vw}}
body::after{{content:'';position:fixed;inset:0;background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,255,136,.015) 2px,rgba(0,255,136,.015) 4px);pointer-events:none;z-index:9999}}
#map{{position:absolute;top:0;left:0;width:100%;height:100%}}
.topbar{{position:fixed;top:0;left:0;right:0;height:54px;background:var(--p);border-bottom:1px solid var(--b);display:flex;align-items:center;padding:0 16px;gap:14px;z-index:100;backdrop-filter:blur(12px)}}
.logo{{font-family:'Orbitron',sans-serif;font-weight:900;font-size:17px;color:var(--g);letter-spacing:4px;text-shadow:0 0 20px rgba(0,255,136,.6);white-space:nowrap}}
.stats{{display:flex;gap:14px;flex:1;overflow:hidden}}
.sc{{display:flex;align-items:center;gap:6px;font-size:11px;color:rgba(168,255,212,.65);white-space:nowrap}}
.sc .v{{color:var(--c);font-size:13px}}
.dot{{width:7px;height:7px;border-radius:50%;background:var(--g);box-shadow:0 0 8px var(--g);animation:pulse 1.5s infinite}}
.dot.L{{background:var(--o);box-shadow:0 0 8px var(--o)}}
@keyframes pulse{{0%,100%{{opacity:1}}50%{{opacity:.3}}}}
.tr{{display:flex;align-items:center;gap:7px;margin-left:auto}}
.clk{{font-size:12px;color:var(--c);letter-spacing:2px}}
.btn{{background:transparent;border:1px solid var(--b);color:var(--g);font-family:'Share Tech Mono',monospace;font-size:10px;padding:5px 9px;cursor:pointer;letter-spacing:1px;transition:all .2s;white-space:nowrap}}
.btn:hover,.btn.A{{background:rgba(0,255,136,.1);border-color:var(--g);box-shadow:0 0 10px rgba(0,255,136,.2)}}
.lp{{position:fixed;top:54px;left:0;bottom:0;width:255px;background:var(--p);border-right:1px solid var(--b);backdrop-filter:blur(12px);z-index:100;display:flex;flex-direction:column;transition:transform .3s}}
.lp.hide{{transform:translateX(-255px)}}
.ph{{padding:11px 14px;border-bottom:1px solid var(--b);font-family:'Orbitron',sans-serif;font-size:10px;letter-spacing:3px;color:var(--g);display:flex;justify-content:space-between}}
.fl{{flex:1;overflow-y:auto;scrollbar-width:thin;scrollbar-color:var(--b) transparent}}
.fi{{padding:9px 14px;border-bottom:1px solid rgba(0,255,136,.07);cursor:pointer;transition:background .15s}}
.fi:hover,.fi.sel{{background:rgba(0,255,136,.08)}}
.fc{{font-family:'Orbitron',sans-serif;font-size:12px;color:var(--c);letter-spacing:1px}}
.fd{{font-size:10px;color:rgba(168,255,212,.5);display:flex;gap:10px;margin-top:3px}}
.ptg{{position:fixed;top:68px;left:255px;width:18px;height:36px;background:var(--p);border:1px solid var(--b);border-left:none;z-index:101;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:11px;color:var(--g);transition:left .3s}}
.ptg:hover{{background:rgba(0,255,136,.1)}}
.ptg.hide{{left:0}}
.ip{{position:fixed;bottom:18px;right:18px;width:285px;background:var(--p);border:1px solid var(--b);backdrop-filter:blur(16px);z-index:100;display:none}}
.ip.vis{{display:block}}
.ih{{padding:10px 14px;background:rgba(0,255,136,.07);border-bottom:1px solid var(--b);font-family:'Orbitron',sans-serif;font-size:13px;color:var(--c);letter-spacing:2px;display:flex;justify-content:space-between;align-items:center}}
.ix{{cursor:pointer;color:rgba(168,255,212,.45);font-size:17px}}
.ix:hover{{color:var(--o)}}
.ib{{padding:12px 14px;display:grid;grid-template-columns:1fr 1fr;gap:10px}}
.ifd{{display:flex;flex-direction:column;gap:3px}}
.il{{font-size:9px;color:rgba(168,255,212,.4);letter-spacing:2px;text-transform:uppercase}}
.iv{{font-size:13px;color:var(--g);font-family:'Orbitron',sans-serif}}
.iv.h{{color:var(--c)}}
.rc{{position:fixed;bottom:18px;left:18px;z-index:100;background:var(--p);border:1px solid var(--b);padding:8px;backdrop-filter:blur(12px)}}
.rl{{font-size:9px;color:rgba(168,255,212,.4);letter-spacing:2px;margin-bottom:5px;text-transform:uppercase}}
.hm{{position:fixed;top:50%;right:18px;transform:translateY(-50%);z-index:100;display:flex;flex-direction:column;gap:8px;opacity:0;transition:opacity .3s;pointer-events:none}}
.hm.vis{{opacity:1}}
.mt{{background:var(--p);border:1px solid var(--b);padding:9px 11px;width:82px;backdrop-filter:blur(12px)}}
.mla{{font-size:8px;color:rgba(168,255,212,.4);letter-spacing:2px;text-transform:uppercase;margin-bottom:3px}}
.mv{{font-family:'Orbitron',sans-serif;font-size:17px;color:var(--c);line-height:1}}
.mu{{font-size:8px;color:rgba(168,255,212,.45);margin-top:2px}}
.ntf{{position:fixed;top:68px;right:18px;background:var(--p);border:1px solid var(--b);padding:9px 14px;font-size:11px;color:var(--c);z-index:150;transform:translateX(120%);transition:transform .3s;letter-spacing:1px}}
.ntf.sh{{transform:translateX(0)}}
.ntf.er{{color:var(--o);border-color:rgba(255,107,53,.4)}}
.rb{{position:fixed;bottom:0;left:0;right:0;height:2px;background:rgba(0,255,136,.07);z-index:100}}
.rp{{height:100%;background:var(--g);box-shadow:0 0 8px var(--g);width:100%}}
.mapboxgl-ctrl-bottom-left,.mapboxgl-ctrl-bottom-right{{display:none!important}}
.mapboxgl-popup-content{{background:var(--p)!important;border:1px solid var(--b)!important;color:var(--t)!important;font-family:'Share Tech Mono',monospace!important;font-size:11px!important;padding:9px 13px!important;border-radius:0!important}}
.mapboxgl-popup-tip{{display:none!important}}
#ld{{position:fixed;inset:0;background:var(--d);z-index:200;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:18px;transition:opacity .5s}}
#ld.hide{{opacity:0;pointer-events:none}}
.ll{{font-family:'Orbitron',sans-serif;font-size:34px;font-weight:900;color:var(--g);letter-spacing:8px;animation:glow 2s infinite}}
@keyframes glow{{0%,100%{{text-shadow:0 0 20px rgba(0,255,136,.4)}}50%{{text-shadow:0 0 60px rgba(0,255,136,.9)}}}}
.lbw{{width:280px;height:2px;background:rgba(0,255,136,.12);overflow:hidden}}
.lb{{height:100%;background:var(--g);box-shadow:0 0 10px var(--g);width:0%;transition:width .4s}}
.lt{{font-size:11px;color:rgba(168,255,212,.45);letter-spacing:3px;text-transform:uppercase}}
#tm{{position:fixed;inset:0;background:rgba(2,8,16,.96);z-index:300;display:flex;align-items:center;justify-content:center}}
#tm.hide{{display:none}}
.mb{{background:var(--p);border:1px solid var(--b);padding:28px;width:440px;max-width:95vw}}
.mt2{{font-family:'Orbitron',sans-serif;font-size:15px;color:var(--c);letter-spacing:3px;margin-bottom:8px}}
.md{{font-size:11px;color:rgba(168,255,212,.55);line-height:1.75;margin-bottom:18px}}
.md a{{color:var(--c);text-decoration:none}}
.ti{{width:100%;background:rgba(0,229,255,.05);border:1px solid var(--b);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;padding:10px 13px;outline:none;margin-bottom:12px}}
.ti:focus{{border-color:var(--c)}}
.ma{{display:flex;gap:10px}}
.bp{{flex:1;background:rgba(0,255,136,.1);border:1px solid var(--g);color:var(--g);font-family:'Share Tech Mono',monospace;font-size:11px;padding:10px;cursor:pointer;letter-spacing:2px}}
.bp:hover{{background:rgba(0,255,136,.2)}}
.bd{{background:rgba(0,229,255,.07);border:1px solid rgba(0,229,255,.28);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:11px;padding:10px;cursor:pointer;letter-spacing:2px}}
.bd:hover{{background:rgba(0,229,255,.14)}}
.fl::-webkit-scrollbar{{width:3px}}
.fl::-webkit-scrollbar-thumb{{background:var(--b)}}
@media(max-width:600px){{.lp{{width:220px}}.ptg{{left:220px}}.ptg.hide{{left:0}}.rc{{display:none}}.ip{{right:8px;bottom:8px;width:calc(100vw - 16px)}}}}
</style>
</head>
<body>

<!-- Token Modal -->
<div id="tm">
  <div class="mb">
    <div class="mt2">MAPBOX TOKEN</div>
    <p class="md">
      Uydu haritasi icin ucretsiz Mapbox token gereklidir.<br>
      <a href="https://account.mapbox.com" target="_blank">account.mapbox.com</a> adresinden alin.<br><br>
      Token olmadan <b>Demo Mod</b> ile ucak listesi goruntulenebilir (OpenStreetMap tabanlı).
    </p>
    <input class="ti" id="ti" type="text" placeholder="pk.eyJ1IjoiLi4uIiwiYSI6Ii4uLiJ9...">
    <div class="ma">
      <button class="bp" onclick="initWithToken()">BASLAT</button>
      <button class="bd" onclick="initDemo()">DEMO MOD</button>
    </div>
  </div>
</div>

<!-- Loading Screen -->
<div id="ld">
  <div class="ll">SKYWATCH</div>
  <div class="lbw"><div class="lb" id="lb"></div></div>
  <div class="lt" id="lt">SISTEM BASLATILIYOR...</div>
</div>

<!-- Top Bar -->
<div class="topbar">
  <div class="logo">SKYWATCH</div>
  <div class="stats">
    <div class="sc"><div class="dot L" id="sd"></div><span id="st">BAGLANILIYOR</span></div>
    <div class="sc">UCAK: <span class="v" id="pc">0</span></div>
    <div class="sc">SON: <span class="v" id="lu">--:--</span></div>
  </div>
  <div class="tr">
    <div class="clk" id="clk">00:00:00</div>
    <button class="btn" onclick="refreshData()">&#8635; YENILE</button>
    <button class="btn A" id="lsb" onclick="setLayer('satellite')">UYDU</button>
    <button class="btn" id="ldb" onclick="setLayer('dark')">KARANLIK</button>
    <button class="btn" id="lrb" onclick="setLayer('street')">SOKAK</button>
  </div>
</div>

<!-- Panel Toggle -->
<div class="ptg" id="ptg" onclick="togglePanel()">&#9664;</div>

<!-- Aircraft List Panel -->
<div class="lp" id="lp">
  <div class="ph"><span>✈ UCAK LİSTESİ</span><span style="font-size:9px">🔴 canli</span></div>
  <div class="fl" id="aircraftList"></div>
</div>

<!-- Info Panel -->
<div class="ip" id="infoPanel">
  <div class="ih">UCAG BILGISI <span class="ix" onclick="closeInfo()">✕</span></div>
  <div class="ib" id="infoContent"></div>
</div>

<!-- Bottom Progress -->
<div class="rb"><div class="rp" id="progressBar" style="width:0%"></div></div>

<!-- Right Side Stats -->
<div class="hm" id="hm">
  <div class="mt"><div class="mla">IRTIFA</div><div class="mv" id="hmAlt">-</div><div class="mu">ft</div></div>
  <div class="mt"><div class="mla">HIZ</div><div class="mv" id="hmSpd">-</div><div class="mu">kt</div></div>
</div>

<!-- Map Container -->
<div id="map"></div>

<script>
// Global variables
let map;               // Mapbox map object
let leafletMap;        // Leaflet map object (demo)
let mapType = null;    // 'mapbox' or 'leaflet'
let markers = {{}};
let leafletMarkers = {{}};
let aircraftData = {{}};
let updateInterval;
let mapboxToken = null;

// Kimlik doğrulama
const OS_AUTH_HEADER = {{"Authorization": "Basic {auth_header}"}};
const HAS_AUTH = { "true" if auth_header else "false" };
const UPDATE_SECONDS = {update_interval};

// Helper functions
function showNotification(msg, isError = false) {{
    let ntf = document.getElementById('ntf');
    if (!ntf) {{
        ntf = document.createElement('div');
        ntf.id = 'ntf';
        ntf.className = 'ntf';
        document.body.appendChild(ntf);
    }}
    ntf.textContent = msg;
    ntf.className = 'ntf sh' + (isError ? ' er' : '');
    setTimeout(() => ntf.classList.remove('sh'), 3000);
}}

function updateClock() {{
    document.getElementById('clk').textContent = new Date().toLocaleTimeString('tr-TR');
}}
setInterval(updateClock, 1000);
updateClock();

function togglePanel() {{
    const lp = document.getElementById('lp');
    const ptg = document.getElementById('ptg');
    lp.classList.toggle('hide');
    ptg.classList.toggle('hide');
    ptg.innerHTML = lp.classList.contains('hide') ? '&#9654;' : '&#9664;';
}}

function closeInfo() {{
    document.getElementById('infoPanel').classList.remove('vis');
}}

function showAircraftInfo(icao24) {{
    const a = aircraftData[icao24];
    if (!a) return;
    const content = document.getElementById('infoContent');
    content.innerHTML = `
        <div class="ifd"><span class="il">KOD</span><span class="iv">${{a.icao24 || '?'}}</span></div>
        <div class="ifd"><span class="il">CALLSIGN</span><span class="iv">${{a.callsign || '?'}}</span></div>
        <div class="ifd"><span class="il">ULKE</span><span class="iv">${{a.origin_country || '?'}}</span></div>
        <div class="ifd"><span class="il">IRTIFA</span><span class="iv">${{a.baro_altitude ? Math.round(a.baro_altitude * 3.28084) + ' ft' : '?'}}</span></div>
        <div class="ifd"><span class="il">HIZ</span><span class="iv">${{a.velocity ? Math.round(a.velocity * 1.94384) + ' kt' : '?'}}</span></div>
        <div class="ifd"><span class="il">ROTA</span><span class="iv">${{a.true_track ? Math.round(a.true_track) + '°' : '?'}}</span></div>
        <div class="ifd"><span class="il">SON GUNCELLEME</span><span class="iv">${{new Date(a.last_update * 1000).toLocaleTimeString()}}</span></div>
    `;
    document.getElementById('infoPanel').classList.add('vis');
}}

async function fetchOpenSky() {{
    try {{
        const url = 'https://opensky-network.org/api/states/all';
        const options = {{}};
        if (HAS_AUTH) {{
            options.headers = OS_AUTH_HEADER;
        }}
        const response = await fetch(url, options);
        if (response.status === 429) {{
            throw new Error('429: Çok fazla istek. Lütfen OpenSky\'ye kaydolun ve kullanıcı bilgilerini scripte ekleyin (OS_USERNAME/OS_PASSWORD).');
        }}
        if (!response.ok) throw new Error(`HTTP ${{response.status}}`);
        const data = await response.json();
        const states = data.states || [];
        const newData = {{}};
        for (const s of states) {{
            if (s[5] && s[6] && s[7]) {{
                newData[s[0]] = {{
                    icao24: s[0],
                    callsign: s[1] ? s[1].trim() : null,
                    origin_country: s[2],
                    longitude: s[5],
                    latitude: s[6],
                    baro_altitude: s[7],
                    velocity: s[9],
                    true_track: s[10],
                    last_update: s[3]
                }};
            }}
        }}
        aircraftData = newData;
        document.getElementById('pc').textContent = Object.keys(aircraftData).length;
        document.getElementById('st').textContent = HAS_AUTH ? 'KAYITLI' : 'ANONIM';
        document.getElementById('sd').className = 'dot';
        document.getElementById('lu').textContent = new Date().toLocaleTimeString();
        updateMarkers();
        updateAircraftList();
        updateSideStats();
        return true;
    }} catch (err) {{
        console.error(err);
        document.getElementById('st').textContent = 'HATA';
        document.getElementById('sd').className = 'dot L';
        showNotification(err.message, true);
        return false;
    }}
}}

function updateMarkers() {{
    if (mapType === 'mapbox') {{
        // Mapbox marker update
        for (let id in markers) {{
            if (!aircraftData[id]) {{
                markers[id].remove();
                delete markers[id];
            }}
        }}
        for (let id in aircraftData) {{
            const a = aircraftData[id];
            const el = document.createElement('div');
            el.className = 'marker';
            el.style.width = '10px';
            el.style.height = '10px';
            el.style.backgroundColor = '#00ff88';
            el.style.borderRadius = '50%';
            el.style.border = '1px solid #00ff88';
            el.style.boxShadow = '0 0 6px #00ff88';
            el.style.cursor = 'pointer';
            el.addEventListener('click', (e) => {{
                e.stopPropagation();
                showAircraftInfo(id);
            }});
            if (markers[id]) {{
                markers[id].setLngLat([a.longitude, a.latitude]);
            }} else {{
                markers[id] = new mapboxgl.Marker(el)
                    .setLngLat([a.longitude, a.latitude])
                    .setPopup(new mapboxgl.Popup({{ offset: 15 }}).setHTML(`<b>${{a.callsign || a.icao24}}</b><br>${{a.origin_country || ''}}`))
                    .addTo(map);
            }}
        }}
    }} else if (mapType === 'leaflet') {{
        // Leaflet marker update
        for (let id in leafletMarkers) {{
            if (!aircraftData[id]) {{
                leafletMap.removeLayer(leafletMarkers[id]);
                delete leafletMarkers[id];
            }}
        }}
        for (let id in aircraftData) {{
            const a = aircraftData[id];
            if (leafletMarkers[id]) {{
                leafletMarkers[id].setLatLng([a.latitude, a.longitude]);
            }} else {{
                const marker = L.marker([a.latitude, a.longitude], {{
                    icon: L.divIcon({{
                        className: 'custom-marker',
                        html: '<div style="width:10px;height:10px;background:#00ff88;border-radius:50%;border:1px solid #00ff88;box-shadow:0 0 6px #00ff88;"></div>',
                        iconSize: [10, 10],
                        popupAnchor: [0, -5]
                    }})
                }}).addTo(leafletMap);
                marker.bindPopup(`<b>${{a.callsign || a.icao24}}</b><br>${{a.origin_country || ''}}`);
                marker.on('click', () => showAircraftInfo(id));
                leafletMarkers[id] = marker;
            }}
        }}
    }}
}}

function updateAircraftList() {{
    const container = document.getElementById('aircraftList');
    if (!container) return;
    const aircrafts = Object.values(aircraftData).sort((a,b) => (a.callsign || '').localeCompare(b.callsign || ''));
    if (aircrafts.length === 0) {{
        container.innerHTML = '<div class="fi" style="text-align:center">Uçak bulunamadı</div>';
        return;
    }}
    container.innerHTML = aircrafts.map(a => `
        <div class="fi" onclick="showAircraftInfo('${{a.icao24}}'); if(mapType==='mapbox') map.flyTo({{center:[${{a.longitude}},${{a.latitude}}], zoom:10}}); else leafletMap.flyTo([${{a.latitude}},${{a.longitude}}], 10);">
            <div class="fc">${{a.callsign || a.icao24}}</div>
            <div class="fd"><span>${{a.origin_country || '?'}}</span><span>✈ ${{a.baro_altitude ? Math.round(a.baro_altitude*3.28084)+'ft' : '?'}}</span></div>
        </div>
    `).join('');
}}

function updateSideStats() {{
    const any = Object.values(aircraftData)[0];
    if (any) {{
        const alt = any.baro_altitude ? Math.round(any.baro_altitude * 3.28084) : '-';
        const spd = any.velocity ? Math.round(any.velocity * 1.94384) : '-';
        document.getElementById('hmAlt').textContent = alt;
        document.getElementById('hmSpd').textContent = spd;
        document.getElementById('hm').classList.add('vis');
    }} else {{
        document.getElementById('hm').classList.remove('vis');
    }}
}}

function refreshData() {{
    fetchOpenSky();
    const pb = document.getElementById('progressBar');
    pb.style.width = '100%';
    setTimeout(() => pb.style.width = '0%', 500);
}}

function setLayer(type) {{
    if (mapType !== 'mapbox') return;
    let style;
    if (type === 'satellite') style = 'mapbox://styles/mapbox/satellite-v9';
    else if (type === 'dark') style = 'mapbox://styles/mapbox/dark-v11';
    else style = 'mapbox://styles/mapbox/streets-v12';
    map.setStyle(style);
    document.querySelectorAll('.tr .btn').forEach(btn => btn.classList.remove('A'));
    if (type === 'satellite') document.getElementById('lsb').classList.add('A');
    else if (type === 'dark') document.getElementById('ldb').classList.add('A');
    else document.getElementById('lrb').classList.add('A');
}}

// Demo mod: Leaflet ile OpenStreetMap
function initDemo() {{
    mapType = 'leaflet';
    document.getElementById('tm').classList.add('hide');
    // Harita kabını temizle
    const mapDiv = document.getElementById('map');
    mapDiv.innerHTML = '';
    // Leaflet haritası oluştur
    leafletMap = L.map('map').setView([41.0082, 28.9784], 6);
    L.tileLayer('https://{{s}}.tile.openstreetmap.org/{{z}}/{{x}}/{{y}}.png', {{
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }}).addTo(leafletMap);
    document.getElementById('ld').classList.add('hide');
    refreshData();
    if (updateInterval) clearInterval(updateInterval);
    updateInterval = setInterval(refreshData, UPDATE_SECONDS * 1000);
}}

// Token modu: Mapbox
function initWithToken() {{
    const token = document.getElementById('ti').value.trim();
    if (!token || !token.startsWith('pk.')) {{
        showNotification('Geçerli bir Mapbox token giriniz!', true);
        return;
    }}
    mapboxToken = token;
    mapType = 'mapbox';
    document.getElementById('tm').classList.add('hide');
    mapboxgl.accessToken = token;
    map = new mapboxgl.Map({{
        container: 'map',
        style: 'mapbox://styles/mapbox/satellite-v9',
        center: [28.9784, 41.0082],
        zoom: 6
    }});
    map.addControl(new mapboxgl.NavigationControl({{ showCompass: false }}), 'top-right');
    map.on('load', () => {{
        document.getElementById('ld').classList.add('hide');
        refreshData();
        if (updateInterval) clearInterval(updateInterval);
        updateInterval = setInterval(refreshData, UPDATE_SECONDS * 1000);
    }});
}}

// Bekleme süresi
setTimeout(() => {{
    if (!map && !leafletMap) {{
        document.getElementById('ld').classList.add('hide');
        showNotification('Harita yüklenemedi, lütfen demo modu deneyin', true);
    }}
}}, 8000);
</script>
</body>
</html>
"""

with open(HTML, "w", encoding="utf-8") as f:
    f.write(html_content)

print("HTML dosyası oluşturuldu:", HTML)
PYEOF

echo -e "  ${G}HTML hazir, HTTP sunucusu baslatiliyor...${N}"
echo -e "  ${C}Adres: http://$HOST:$PORT/skywatch_index.html${N}"
echo -e "  ${Y}Sunucuyu durdurmak icin Ctrl+C kullanin.${N}"
echo -e "  ${Y}Not: 429 hatasini onlemek icin OpenSky kaydi gereklidir.${N}"

cd "$TMPD" || exit 1
$PY -m http.server "$PORT" --bind "$HOST"
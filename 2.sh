#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  SKYWATCH PRO — Advanced Termux Flight Radar         ║
# ║  Geliştirilmiş Sürüm: Havayolu, Rota ve Acil Durum    ║
# ╚══════════════════════════════════════════════════════╝

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'; B='\033[1m'

clear
echo -e "${G}${B}"
echo "  ███████╗██╗  ██╗██╗   ██╗██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗"
echo "  ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║"
echo "  ███████╗█████╔╝  ╚████╔╝ ██║ █╗ ██║███████║   ██║   ██║     ███████║"
echo "  ╚════██║██╔═██╗   ╚██╔╝  ██║███╗██║██╔══██║   ██║   ██║     ██╔══██║"
echo "  ███████║██║  ██╗   ██║   ╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║"
echo "  ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝"
echo -e "${N}"
echo -e "  ${C}Gelişmiş Canlı Uçak Takip Sistemi - v2.0${N}"
echo "  ───────────────────────────────────────────"

if ! command -v python3 &>/dev/null; then pkg install python -y; fi

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
#map{position:absolute;inset:0;width:100%;height:100%}
.topbar{position:fixed;top:0;left:0;right:0;height:54px;background:var(--p);border-bottom:1px solid var(--b);display:flex;align-items:center;padding:0 16px;z-index:100;backdrop-filter:blur(12px)}
.logo{font-family:'Orbitron',sans-serif;font-weight:900;font-size:17px;color:var(--g);letter-spacing:4px;text-shadow:0 0 15px var(--g)}
.stats{display:flex;gap:15px;margin-left:20px;font-size:11px}
.v{color:var(--c)}
.lp{position:fixed;top:54px;left:0;bottom:0;width:260px;background:var(--p);border-right:1px solid var(--b);z-index:100;display:flex;flex-direction:column;transition:0.3s}
.lp.hide{transform:translateX(-260px)}
.fi{padding:10px 15px;border-bottom:1px solid rgba(0,255,136,0.1);cursor:pointer}
.fi:hover, .fi.sel{background:rgba(0,255,136,0.15)}
.fi.emerg{background:rgba(255,59,59,0.2);border-left:4px solid var(--r)}
.ip{position:fixed;bottom:20px;right:20px;width:300px;background:var(--p);border:1px solid var(--b);z-index:110;display:none;padding:15px;backdrop-filter:blur(15px)}
.ip.vis{display:block}
.ih{font-family:'Orbitron',sans-serif;font-size:14px;color:var(--c);margin-bottom:10px;display:flex;justify-content:space-between}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:10px;font-size:11px}
.label{color:rgba(168,255,212,0.5);text-transform:uppercase;font-size:9px}
.ntf{position:fixed;top:70px;right:20px;padding:12px 20px;background:var(--p);border:1px solid var(--g);color:var(--g);z-index:200;transform:translateX(150%);transition:0.4s}
.ntf.sh{transform:translateX(0)}
.ntf.err{border-color:var(--r);color:var(--r);font-weight:bold;animation:blink 1s infinite}
@keyframes blink{0%{opacity:1}50%{opacity:0.5}}
.btn{background:none;border:1px solid var(--b);color:var(--g);padding:4px 8px;font-family:inherit;cursor:pointer;margin-left:5px}
.btn.active{background:var(--g);color:var(--d)}
#ld{position:fixed;inset:0;background:var(--d);z-index:1000;display:flex;flex-direction:column;align-items:center;justify-content:center}
</style>
</head>
<body>

<div id='ld'><h1 style='color:var(--g);font-family:Orbitron'>SKYWATCH PRO</h1><p>SİSTEM YÜKLENİYOR...</p></div>

<div class='topbar'>
    <div class='logo'>SKYWATCH</div>
    <div class='stats'>
        <div>UÇAK: <span id='pc' class='v'>0</span></div>
        <div>DURUM: <span id='st' class='v'>BAĞLANILIYOR</span></div>
    </div>
    <div style="margin-left:auto">
        <button class='btn' onclick='location.reload()'>YENİLE</button>
        <button class='btn active' id='b-sat' onclick='setL("satellite")'>UYDU</button>
        <button class='btn' id='b-dark' onclick='setL("dark")'>GECE</button>
    </div>
</div>

<div class='lp' id='lp'>
    <div style="padding:10px;font-size:10px;color:var(--g);border-bottom:1px solid var(--b)">CANLI TRAFİK</div>
    <div id='fl' style="overflow-y:auto"></div>
</div>

<div id='map'></div>

<div class='ip' id='ip'>
    <div class='ih'><span id='d-call'>---</span><span onclick='this.parentElement.parentElement.classList.remove("vis")' style="cursor:pointer">×</span></div>
    <div class='grid'>
        <div><div class='label'>ÜLKE</div><div id='d-cou'>---</div></div>
        <div><div class='label'>YÜKSEKLİK</div><div id='d-alt' class='v'>---</div></div>
        <div><div class='label'>HIZ</div><div id='d-spd'>---</div></div>
        <div><div class='label'>SQUAWK</div><div id='d-sqk'>---</div></div>
        <div><div class='label'>ENLEM</div><div id='d-lat'>---</div></div>
        <div><div class='label'>BOYLAM</div><div id='d-lon'>---</div></div>
    </div>
</div>

<div class='ntf' id='ntf'></div>

<script>
let map, mbToken = localStorage.getItem('mbt') || '', flights = [], markers = {}, selIcao = null;

// Mapbox Başlatma
if(!mbToken) {
    mbToken = prompt("Mapbox Token giriniz (veya demo için boş bırakın):");
    if(mbToken) localStorage.setItem('mbt', mbToken);
}

function init() {
    if(mbToken) {
        mapboxgl.accessToken = mbToken;
        map = new mapboxgl.Map({
            container: 'map',
            style: 'mapbox://styles/mapbox/satellite-v9',
            center: [35, 39], zoom: 5
        });
    }
    document.getElementById('ld').style.display = 'none';
    updateData();
    setInterval(updateData, 30000);
}

async function updateData() {
    try {
        const res = await fetch('https://opensky-network.org/api/states/all?lamin=34&lomin=24&lamax=43&lomax=46'); // Türkiye Geneli
        const data = await res.json();
        flights = data.states.map(s => ({
            icao: s[0], call: s[1].trim() || s[0], cou: s[2], 
            lon: s[5], lat: s[6], alt: Math.round(s[7]), 
            spd: Math.round(s[9]*3.6), hdg: s[10], sqk: s[14]
        })).filter(f => f.lat);
        
        renderList();
        renderMarkers();
        checkEmergencies();
        document.getElementById('pc').textContent = flights.length;
        document.getElementById('st').textContent = 'CANLI';
    } catch(e) {
        document.getElementById('st').textContent = 'HATA';
    }
}

function renderList() {
    const cont = document.getElementById('fl');
    cont.innerHTML = '';
    flights.forEach(f => {
        const div = document.createElement('div');
        div.className = `fi ${f.sqk === '7700' ? 'emerg' : ''} ${f.icao === selIcao ? 'sel' : ''}`;
        div.innerHTML = `<strong>${f.call}</strong> <small>${f.alt}m - ${f.spd}km/h</small>`;
        div.onclick = () => selectFlight(f);
        cont.appendChild(div);
    });
}

function renderMarkers() {
    if(!map) return;
    flights.forEach(f => {
        if(markers[f.icao]) {
            markers[f.icao].setLngLat([f.lon, f.lat]);
            markers[f.icao].getElement().style.transform += ` rotate(${f.hdg}deg)`;
        } else {
            const el = document.createElement('div');
            el.innerHTML = `<svg viewBox="0 0 24 24" width="20" height="20"><path d="M21,16L21,14L13,9L13,3.5A1.5,1.5 0 0,0 11.5,2A1.5,1.5 0 0,0 10,3.5L10,9L2,14L2,16L10,13.5L10,19L8,20.5L8,22L11.5,21L15,22L15,20.5L13,19L13,13.5L21,16Z" fill="${f.sqk === '7700' ? '#ff3b3b' : '#00ff88'}"/></svg>`;
            el.style.transform = `rotate(${f.hdg}deg)`;
            markers[f.icao] = new mapboxgl.Marker(el).setLngLat([f.lon, f.lat]).addTo(map);
            el.onclick = () => selectFlight(f);
        }
    });
}

function selectFlight(f) {
    selIcao = f.icao;
    document.getElementById('d-call').textContent = f.call;
    document.getElementById('d-cou').textContent = f.cou;
    document.getElementById('d-alt').textContent = f.alt + " m";
    document.getElementById('d-spd').textContent = f.spd + " km/h";
    document.getElementById('d-sqk').textContent = f.sqk || "----";
    document.getElementById('d-lat').textContent = f.lat.toFixed(4);
    document.getElementById('d-lon').textContent = f.lon.toFixed(4);
    document.getElementById('ip').classList.add('vis');
    if(map) map.flyTo({center: [f.lon, f.lat], zoom: 8});
    renderList();
}

function checkEmergencies() {
    const emergency = flights.find(f => f.sqk === '7700');
    if(emergency) {
        const n = document.getElementById('ntf');
        n.textContent = "ACİL DURUM SİNYALİ: " + emergency.call;
        n.classList.add('sh', 'err');
    }
}

function setL(l) {
    if(!map) return;
    map.setStyle(l === 'satellite' ? 'mapbox://styles/mapbox/satellite-v9' : 'mapbox://styles/mapbox/dark-v11');
    document.querySelectorAll('.btn').forEach(b => b.classList.remove('active'));
    document.getElementById('b-'+l.substring(0,3)).classList.add('active');
}

init();
</script>
</body>
</html>
"""
with open(HTML, "w", encoding="utf-8") as f:
    f.write(page)
PYEOF

echo -e "  ${G}Arayüz oluşturuldu: ${HTML}${N}"
echo -e "  ${Y}Açmak için: termux-open $HTML${N}"
termux-open "$HTML" 2>/dev/null || echo -e "  ${C}Lütfen tarayıcıdan açın.${N}"

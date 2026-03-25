#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  SKYWATCH ULTIMATE — Cyberpunk Flight Radar          ║
# ║  Görsel: Orijinal Retro / Teknik: Pro v2.0           ║
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
echo -e "  ${C}Sistem Başlatılıyor... — [OpenSky + Mapbox Retro]${N}"
echo "  ───────────────────────────────────────────"

PY=$(command -v python3 || command -v python)
TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/skywatch_ultimate.html"

$PY << 'PYEOF'
import os
TMPD = os.environ.get("TMPDIR", "/tmp")
HTML = os.path.join(TMPD, "skywatch_ultimate.html")

page = """
<!DOCTYPE html>
<html lang='tr'>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<title>SKYWATCH ULTIMATE</title>
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
.stats{display:flex;gap:14px;flex:1;overflow:hidden;margin-left:20px}
.sc{display:flex;align-items:center;gap:6px;font-size:11px;color:rgba(168,255,212,.65)}
.v{color:var(--c);font-size:13px}
.lp{position:fixed;top:54px;left:0;bottom:0;width:255px;background:var(--p);border-right:1px solid var(--b);z-index:100;display:flex;flex-direction:column;transition:transform .3s}
.fi{padding:10px 14px;border-bottom:1px solid rgba(0,255,136,.07);cursor:pointer}
.fi:hover, .fi.sel{background:rgba(0,255,136,.12)}
.fi.emerg{background:rgba(255,59,59,0.15);border-left:3px solid var(--r);animation:eblink 2s infinite}
@keyframes eblink{0%,100%{background:rgba(255,59,59,0.15)} 50%{background:rgba(255,59,59,0.3)}}
.fc{font-family:'Orbitron',sans-serif;font-size:12px;color:var(--c)}
.fd{font-size:10px;color:rgba(168,255,212,.5);display:flex;gap:8px}
.ip{position:fixed;bottom:18px;right:18px;width:285px;background:var(--p);border:1px solid var(--b);backdrop-filter:blur(16px);z-index:100;display:none}
.ip.vis{display:block}
.ih{padding:10px 14px;background:rgba(0,255,136,.07);border-bottom:1px solid var(--b);font-family:'Orbitron',sans-serif;font-size:13px;color:var(--c);display:flex;justify-content:space-between}
.ib{padding:12px 14px;display:grid;grid-template-columns:1fr 1fr;gap:10px}
.ifd{display:flex;flex-direction:column;gap:3px}
.il{font-size:9px;color:rgba(168,255,212,.4);text-transform:uppercase}
.iv{font-size:13px;color:var(--g);font-family:'Orbitron',sans-serif}
.ntf{position:fixed;top:68px;right:18px;background:var(--p);border:1px solid var(--b);padding:9px 14px;font-size:11px;color:var(--c);z-index:150;transform:translateX(120%);transition:0.3s}
.ntf.sh{transform:translateX(0)}
.btn{background:transparent;border:1px solid var(--b);color:var(--g);font-family:inherit;font-size:10px;padding:5px 9px;cursor:pointer;margin-left:5px}
.btn.active{background:rgba(0,255,136,0.15);border-color:var(--g)}
#ld{position:fixed;inset:0;background:var(--d);z-index:200;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:18px}
.ll{font-family:'Orbitron',sans-serif;font-size:34px;font-weight:900;color:var(--g);letter-spacing:8px;animation:glow 2s infinite}
@keyframes glow{0%,100%{text-shadow:0 0 20px rgba(0,255,136,.4)}50%{text-shadow:0 0 60px rgba(0,255,136,.9)}}
</style>
</head>
<body>

<div id='ld'><div class='ll'>SKYWATCH</div><p style='font-size:10px;letter-spacing:5px'>SİSTEM YÜKLENİYOR...</p></div>

<div class='topbar'>
    <div class='logo'>SKYWATCH</div>
    <div class='stats'>
        <div class='sc'>UÇAK: <span class='v' id='pc'>0</span></div>
        <div class='sc'>DURUM: <span class='v' id='st'>BAĞLANIYOR</span></div>
    </div>
    <div style="margin-left:auto; display:flex; align-items:center">
        <div id='clk' style="font-size:12px;color:var(--c);margin-right:15px">00:00:00</div>
        <button class='btn active' id='b-sat' onclick='setL("satellite")'>UYDU</button>
        <button class='btn' id='b-drk' onclick='setL("dark")'>KARANLIK</button>
    </div>
</div>

<div class='lp'>
    <div style="padding:11px 14px; border-bottom:1px solid var(--b); font-size:10px; color:var(--g); letter-spacing:2px">CANLI RADAR LİSTESİ</div>
    <div id='fl' style="overflow-y:auto; flex:1"></div>
</div>

<div id='map'></div>

<div class='ip' id='ip'>
    <div class='ih'><span id='d-call'>---</span><span onclick='this.parentElement.parentElement.classList.remove("vis")' style="cursor:pointer;color:var(--r)">×</span></div>
    <div class='ib'>
        <div class='ifd'><div class='il'>ÜLKE</div><div class='iv' id='d-cou'>---</div></div>
        <div class='ifd'><div class='il'>YÜKSEKLİK</div><div class='iv' id='d-alt' style='color:var(--c)'>---</div></div>
        <div class='ifd'><div class='il'>HIZ</div><div class='iv' id='d-spd'>---</div></div>
        <div class='ifd'><div class='il'>SQUAWK</div><div class='iv' id='d-sqk'>---</div></div>
        <div class='ifd'><div class='il'>ENLEM</div><div class='iv' id='d-lat' style='font-size:11px'>---</div></div>
        <div class='ifd'><div class='il'>BOYLAM</div><div class='iv' id='d-lon' style='font-size:11px'>---</div></div>
    </div>
</div>

<div class='ntf' id='ntf'></div>

<script>
let map, mbToken = localStorage.getItem('mbt') || '', flights = [], markers = {}, selIcao = null;

async function boot() {
    const res = await fetch('https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/tilequery/0,0.json?access_token=' + mbToken).catch(()=>({ok:false}));
    if(!mbToken || !res.ok) {
        let t = prompt("Mapbox Token (pk.xxx) girin (Harita için şarttır):");
        if(t) { mbToken = t; localStorage.setItem('mbt', t); location.reload(); }
    }
    
    mapboxgl.accessToken = mbToken;
    map = new mapboxgl.Map({
        container: 'map',
        style: 'mapbox://styles/mapbox/satellite-v9',
        center: [35.2433, 38.9637], zoom: 5.5, antialias: true
    });

    map.on('load', () => {
        document.getElementById('ld').style.display = 'none';
        document.getElementById('st').textContent = 'CANLI';
        updateData();
        setInterval(updateData, 25000);
        setInterval(() => { document.getElementById('clk').textContent = new Date().toTimeString().slice(0,8); }, 1000);
    });
}

async function updateData() {
    try {
        // Türkiye ve çevresi koordinat filtresi
        const r = await fetch('https://opensky-network.org/api/states/all?lamin=34.0&lomin=24.0&lamax=43.0&lomax=46.0');
        const d = await r.json();
        flights = d.states.map(s => ({
            icao: s[0], call: (s[1]||s[0]).trim(), cou: s[2],
            lon: s[5], lat: s[6], alt: Math.round(s[7]),
            spd: Math.round(s[9]*3.6), hdg: s[10], sqk: s[14]
        })).filter(f => f.lat);
        
        renderList();
        renderMarkers();
        document.getElementById('pc').textContent = flights.length;
    } catch(e) { console.error("Veri hatası"); }
}

function renderList() {
    const c = document.getElementById('fl');
    c.innerHTML = '';
    flights.sort((a,b) => b.alt - a.alt).forEach(f => {
        const d = document.createElement('div');
        d.className = `fi ${f.sqk === '7700' ? 'emerg' : ''} ${f.icao === selIcao ? 'sel' : ''}`;
        d.innerHTML = `<div class='fc'>${f.call}</div><div class='fd'><span>${f.alt}m</span><span>${f.spd}km/h</span><span>${f.sqk||'--'}</span></div>`;
        d.onclick = () => selectFlight(f);
        c.appendChild(d);
    });
}

function renderMarkers() {
    flights.forEach(f => {
        const color = f.sqk === '7700' ? '#ff3b3b' : (f.icao === selIcao ? '#00e5ff' : '#00ff88');
        if(markers[f.icao]) {
            markers[f.icao].setLngLat([f.lon, f.lat]);
            markers[f.icao].getElement().querySelector('path').setAttribute('fill', color);
            markers[f.icao].getElement().style.transform = `rotate(${f.hdg}deg)`;
        } else {
            const el = document.createElement('div');
            el.style.cursor = 'pointer';
            el.innerHTML = `<svg viewBox="0 0 24 24" width="22" height="22"><path d="M21,16L21,14L13,9L13,3.5A1.5,1.5 0 0,0 11.5,2A1.5,1.5 0 0,0 10,3.5L10,9L2,14L2,16L10,13.5L10,19L8,20.5L8,22L11.5,21L15,22L15,20.5L13,19L13,13.5L21,16Z" fill="${color}"/></svg>`;
            el.style.transform = `rotate(${f.hdg}deg)`;
            markers[f.icao] = new mapboxgl.Marker({element: el}).setLngLat([f.lon, f.lat]).addTo(map);
            el.onclick = () => selectFlight(f);
        }
    });
}

function selectFlight(f) {
    selIcao = f.icao;
    document.getElementById('d-call').textContent = f.call;
    document.getElementById('d-cou').textContent = f.cou;
    document.getElementById('d-alt').textContent = f.alt + " M";
    document.getElementById('d-spd').textContent = f.spd + " KM/H";
    document.getElementById('d-sqk').textContent = f.sqk || "----";
    document.getElementById('d-lat').textContent = f.lat.toFixed(4);
    document.getElementById('d-lon').textContent = f.lon.toFixed(4);
    document.getElementById('ip').classList.add('vis');
    map.flyTo({center: [f.lon, f.lat], zoom: 8, speed: 0.8});
    renderList();
    renderMarkers();
    if(f.sqk === '7700') {
        const n = document.getElementById('ntf');
        n.textContent = "DİKKAT: " + f.call + " ACİL DURUMDA!";
        n.classList.add('sh');
        setTimeout(() => n.classList.remove('sh'), 5000);
    }
}

function setL(l) {
    map.setStyle(l === 'satellite' ? 'mapbox://styles/mapbox/satellite-v9' : 'mapbox://styles/mapbox/dark-v11');
    document.getElementById('b-sat').classList.toggle('active', l === 'satellite');
    document.getElementById('b-drk').classList.toggle('active', l === 'dark');
}

boot();
</script>
</body>
</html>
"""
with open(HTML, "w", encoding="utf-8") as f:
    f.write(page)
PYEOF

echo -e "  ${G}Görsel: Orijinal Retro + Teknik: Pro v2.0 Aktif!${N}"
echo -e "  ${Y}Dosya: $HTML${N}"
termux-open "$HTML" 2>/dev/null

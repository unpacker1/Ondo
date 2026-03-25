#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  SKYWATCH PRO — Server Edition                       ║
# ║  Görsel: %100 Orijinal / Teknik: Gelişmiş + Web      ║
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

# IP ve Port Ayarları
PORT=$((RANDOM % 1000 + 8000))
IP_ADDR=$(ifconfig | grep -Et 'inet [0-9]' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)
HTML_DIR="$HOME/.skywatch_web"
mkdir -p "$HTML_DIR"
HTML_FILE="$HTML_DIR/index.html"

# HTML Oluşturma (Senin gönderdiğin orijinal yapıya 3 özellik eklendi)
cat << 'EOF' > "$HTML_FILE"
<!DOCTYPE html>
<html lang='tr'>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<title>SKYWATCH PRO SERVER</title>
<link href='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css' rel='stylesheet'>
<script src='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js'></script>
<link href='https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&display=swap' rel='stylesheet'>
<style>
:root{--g:#00ff88;--c:#00e5ff;--o:#ff6b35;--d:#020810;--p:rgba(2,15,25,0.92);--b:rgba(0,255,136,0.25);--t:#a8ffd4}
*{margin:0;padding:0;box-sizing:border-box}
body{background:var(--d);color:var(--t);font-family:'Share Tech Mono',monospace;overflow:hidden;height:100vh;width:100vw}
body::after{content:'';position:fixed;inset:0;background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,255,136,.015) 2px,rgba(0,255,136,.015) 4px);pointer-events:none;z-index:9999}
#map{position:absolute;top:0;left:0;width:100%;height:100%}
.topbar{position:fixed;top:0;left:0;right:0;height:54px;background:var(--p);border-bottom:1px solid var(--b);display:flex;align-items:center;padding:0 16px;gap:14px;z-index:100;backdrop-filter:blur(12px)}
.logo{font-family:'Orbitron',sans-serif;font-weight:900;font-size:17px;color:var(--g);letter-spacing:4px;text-shadow:0 0 20px rgba(0,255,136,.6)}
.stats{display:flex;gap:14px;flex:1;overflow:hidden}.sc{font-size:11px;color:rgba(168,255,212,.65)}.sc .v{color:var(--c);font-size:13px}
.lp{position:fixed;top:54px;left:0;bottom:0;width:255px;background:var(--p);border-right:1px solid var(--b);backdrop-filter:blur(12px);z-index:100;display:flex;flex-direction:column;transition:transform .3s}
.lp.hide{transform:translateX(-255px)}
.fl{flex:1;overflow-y:auto}.fi{padding:9px 14px;border-bottom:1px solid rgba(0,255,136,.07);cursor:pointer}
.fi:hover,.fi.sel{background:rgba(0,255,136,.08)}.fc{font-family:'Orbitron',sans-serif;font-size:12px;color:var(--c)}
.ptg{position:fixed;top:68px;left:255px;width:18px;height:36px;background:var(--p);border:1px solid var(--b);border-left:none;z-index:101;display:flex;align-items:center;justify-content:center;cursor:pointer;color:var(--g);transition:left .3s}
.ptg.hide{left:0}
.ip{position:fixed;bottom:18px;right:18px;width:285px;background:var(--p);border:1px solid var(--b);backdrop-filter:blur(16px);z-index:100;display:none}
.ip.vis{display:block}.ih{padding:10px 14px;background:rgba(0,255,136,.07);border-bottom:1px solid var(--b);font-family:'Orbitron',sans-serif;font-size:13px;color:var(--c);display:flex;justify-content:space-between}
.ib{padding:12px 14px;display:grid;grid-template-columns:1fr 1fr;gap:10px}.ifd{display:flex;flex-direction:column}.il{font-size:9px;color:rgba(168,255,212,.4);text-transform:uppercase}.iv{font-size:13px;color:var(--g);font-family:'Orbitron',sans-serif}
.hm{position:fixed;top:50%;right:18px;transform:translateY(-50%);z-index:100;display:flex;flex-direction:column;gap:8px}
.mt{background:var(--p);border:1px solid var(--b);padding:9px 11px;width:82px}.mla{font-size:8px;color:rgba(168,255,212,.4);text-transform:uppercase}.mv{font-family:'Orbitron',sans-serif;font-size:17px;color:var(--c)}
</style>
</head>
<body>
<div class='topbar'>
    <div class='logo'>SKYWATCH</div>
    <div class='stats'><div class='sc'>UÇAK: <span class='v' id='pc'>0</span></div><div class='sc'>DURUM: <span class='v' id='st'>ONLINE</span></div></div>
</div>
<div class='ptg' id='ptg' onclick='togglePanel()'>&#9664;</div>
<div class='lp' id='lp'><div style='padding:11px;font-size:10px;color:var(--g);border-bottom:1px solid var(--b)'>RADAR LIST</div><div class='fl' id='fl'></div></div>
<div id='map'></div>
<div class='ip' id='ip'>
    <div class='ih'><span id='d-call'>---</span><span onclick="this.parentElement.parentElement.classList.remove('vis')" style='cursor:pointer'>×</span></div>
    <div class='ib'>
        <div class='ifd'><div class='il'>HAVAYOLU</div><div class='iv' id='d-op'>---</div></div>
        <div class='ifd'><div class='il'>ÜLKE</div><div class='iv' id='d-cou'>---</div></div>
        <div class='ifd'><div class='il'>İRTİFA</div><div class='iv' id='d-alt'>---</div></div>
        <div class='ifd'><div class='il'>TREND</div><div class='iv' id='d-trd'>---</div></div>
    </div>
</div>
<div class='hm'><div class='mt'><div class='mla'>ALT</div><div class='mv' id='ha'>---</div></div><div class='mt'><div class='mla'>SPD</div><div class='mv' id='hs'>---</div></div></div>

<script>
let map, markers={}, selIcao=null;
const AIRLINES = {"THY":"TURKISH AIR","PGT":"PEGASUS","DLH":"LUFTHANSA","BAW":"BRITISH AW","AFR":"AIR FRANCE"};

mapboxgl.accessToken = localStorage.getItem('mbt') || prompt("Mapbox Token:");
if(mapboxgl.accessToken) localStorage.setItem('mbt', mapboxgl.accessToken);

map = new mapboxgl.Map({ container:'map', style:'mapbox://styles/mapbox/satellite-v9', center:[35,39], zoom:5 });

function togglePanel(){
    document.getElementById('lp').classList.toggle('hide');
    document.getElementById('ptg').classList.toggle('hide');
}

async function updateData(){
    const res = await fetch('https://opensky-network.org/api/states/all?lamin=34&lomin=24&lamax=43&lomax=46');
    const d = await res.json();
    const flights = d.states.map(s => ({icao:s[0], call:(s[1]||s[0]).trim(), cou:s[2], lon:s[5], lat:s[6], alt:Math.round(s[7]), spd:Math.round(s[9]*3.6), hdg:s[10], vrt:s[11]}));
    
    document.getElementById('pc').textContent = flights.length;
    const flCont = document.getElementById('fl'); flCont.innerHTML = '';
    
    flights.forEach(f => {
        const div = document.createElement('div');
        div.className = `fi ${f.icao === selIcao ? 'sel' : ''}`;
        div.innerHTML = `<div class='fc'>${f.call}</div><div style='font-size:10px;opacity:0.5'>${f.alt}m | ${f.spd}km/h</div>`;
        div.onclick = () => {
            selIcao = f.icao;
            document.getElementById('d-call').textContent = f.call;
            document.getElementById('d-op').textContent = AIRLINES[f.call.substring(0,3)] || "UNKNOWN";
            document.getElementById('d-cou').textContent = f.cou;
            document.getElementById('d-alt').textContent = f.alt + "m";
            document.getElementById('ha').textContent = f.alt;
            document.getElementById('hs').textContent = f.spd;
            document.getElementById('d-trd').textContent = f.vrt > 0 ? "CLIMBING" : "DESCENDING";
            document.getElementById('ip').classList.add('vis');
            map.flyTo({center:[f.lon, f.lat], zoom:8});
            updateData();
        };
        flCont.appendChild(div);

        if(!markers[f.icao]){
            const el = document.createElement('div');
            el.innerHTML = `<svg viewBox="0 0 24 24" width="20" height="20" style="transform:rotate(${f.hdg}deg)"><path d="M21,16L21,14L13,9L13,3.5A1.5,1.5 0 0,0 11.5,2A1.5,1.5 0 0,0 10,3.5L10,9L2,14L2,16L10,13.5L10,19L8,20.5L8,22L11.5,21L15,22L15,20.5L13,19L13,13.5L21,16Z" fill="#00ff88"/></svg>`;
            markers[f.icao] = new mapboxgl.Marker(el).setLngLat([f.lon, f.lat]).addTo(map);
        } else {
            markers[f.icao].setLngLat([f.lon, f.lat]);
        }
    });
}
setInterval(updateData, 25000); updateData();
</script>
</body>
</html>
EOF

echo -e "  ${Y}SİSTEM BAŞLATILIYOR...${N}"
echo -e "  ───────────────────────────────────────────"
echo -e "  ${B}YEREL IP:   ${G}http://localhost:${PORT}${N}"
echo -e "  ${B}AĞ PAYLAŞIM: ${C}http://${IP_ADDR}:${PORT}${N}"
echo -e "  ───────────────────────────────────────────"
echo -e "  ${R}LOGLAR (Anlık Takip):${N}"

# Python ile sessizce sunucuyu başlat ve logları göster
cd "$HTML_DIR" && python3 -m http.server "$PORT"

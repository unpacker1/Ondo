#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  SKYWATCH WEB SERVER — Cyberpunk Radar               ║
# ║  Özellik: Dinamik Port + Yerel IP Paylaşımı          ║
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

# Gereksinim Kontrolü
if ! command -v python3 &>/dev/null; then pkg install python -y; fi

# Değişkenler
PORT=$((RANDOM % 1000 + 8000)) # 8000-9000 arası rastgele port
IP_ADDR=$(ifconfig | grep -Et 'inet [0-9]' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)
HTML_DIR="$HOME/skywatch_web"
mkdir -p "$HTML_DIR"
HTML_FILE="$HTML_DIR/index.html"

echo -e "  ${C}Sunucu Hazırlanıyor...${N}"

# HTML Oluşturma (Orijinal Cyberpunk Tasarım)
cat << 'EOF' > "$HTML_FILE"
<!DOCTYPE html>
<html lang='tr'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>SKYWATCH WEB RADAR</title>
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
        .fi.emerg{border-left:4px solid var(--r);background:rgba(255,59,59,0.1)}
        .ip{position:fixed;bottom:20px;right:20px;width:280px;background:var(--p);border:1px solid var(--b);z-index:110;display:none;padding:15px}
        .ip.vis{display:block}
        .btn{background:none;border:1px solid var(--b);color:var(--g);padding:4px 8px;cursor:pointer;font-family:inherit;margin-left:5px}
    </style>
</head>
<body>
    <div class='topbar'>
        <div class='logo'>SKYWATCH</div>
        <div class='stats'>UÇAK: <span id='pc' class='v'>0</span> | <span id='st' class='v'>RADAR AKTİF</span></div>
        <div style="margin-left:auto"><button class='btn' onclick="location.reload()">SİSTEM YENİLE</button></div>
    </div>
    <div class='lp' id='fl'></div>
    <div id='map'></div>
    <div class='ip' id='ip'>
        <div id='d-call' style="font-family:Orbitron;color:var(--c);margin-bottom:10px">---</div>
        <div id='details' style="font-size:11px;line-height:1.6"></div>
        <button class='btn' style="margin-top:10px;width:100%" onclick="document.getElementById('ip').classList.remove('vis')">KAPAT</button>
    </div>

    <script>
        let map, mbToken = localStorage.getItem('mbt') || '', markers = {}, selIcao = null;

        if(!mbToken) {
            mbToken = prompt("Mapbox Token (pk.xxx) giriniz:");
            if(mbToken) localStorage.setItem('mbt', mbToken);
        }

        mapboxgl.accessToken = mbToken;
        map = new mapboxgl.Map({
            container: 'map',
            style: 'mapbox://styles/mapbox/satellite-v9',
            center: [35, 39], zoom: 5
        });

        async function updateData() {
            try {
                const res = await fetch('https://opensky-network.org/api/states/all?lamin=34&lomin=24&lamax=43&lomax=46');
                const data = await res.json();
                const flights = data.states.map(s => ({
                    icao: s[0], call: s[1].trim()||s[0], cou: s[2], 
                    lon: s[5], lat: s[6], alt: Math.round(s[7]), 
                    spd: Math.round(s[9]*3.6), hdg: s[10], sqk: s[14]
                })).filter(f => f.lat);

                document.getElementById('pc').textContent = flights.length;
                renderList(flights);
                renderMarkers(flights);
            } catch(e) { console.log("Hata"); }
        }

        function renderList(flights) {
            const cont = document.getElementById('fl');
            cont.innerHTML = '';
            flights.forEach(f => {
                const div = document.createElement('div');
                div.className = `fi ${f.sqk === '7700' ? 'emerg' : ''} ${f.icao === selIcao ? 'sel' : ''}`;
                div.innerHTML = `<b>${f.call}</b><br><small>${f.alt}m | ${f.spd}km/h</small>`;
                div.onclick = () => {
                    selIcao = f.icao;
                    document.getElementById('d-call').textContent = f.call;
                    document.getElementById('details').innerHTML = `ÜLKE: ${f.cou}<br>YÜKSEKLİK: ${f.alt}m<br>HIZ: ${f.spd}km/h<br>SQUAWK: ${f.sqk||'--'}`;
                    document.getElementById('ip').classList.add('vis');
                    map.flyTo({center: [f.lon, f.lat], zoom: 7});
                };
                cont.appendChild(div);
            });
        }

        function renderMarkers(flights) {
            flights.forEach(f => {
                if(markers[f.icao]) {
                    markers[f.icao].setLngLat([f.lon, f.lat]);
                } else {
                    const el = document.createElement('div');
                    el.innerHTML = `<svg viewBox="0 0 24 24" width="20" height="20" style="transform:rotate(${f.hdg}deg)"><path d="M21,16L21,14L13,9L13,3.5A1.5,1.5 0 0,0 11.5,2A1.5,1.5 0 0,0 10,3.5L10,9L2,14L2,16L10,13.5L10,19L8,20.5L8,22L11.5,21L15,22L15,20.5L13,19L13,13.5L21,16Z" fill="${f.sqk==='7700'?'red':'#00ff88'}"/></svg>`;
                    markers[f.icao] = new mapboxgl.Marker(el).setLngLat([f.lon, f.lat]).addTo(map);
                }
            });
        }

        setInterval(updateData, 25000);
        updateData();
    </script>
</body>
</html>
EOF

echo -e "  ${G}Web Sunucusu Başlatılıyor...${N}"
echo -e "  ───────────────────────────────────────────"
echo -e "  ${Y}BAĞLANTI BİLGİLERİ:${N}"
echo -e "  ${B}Yerel Adres:  ${C}http://localhost:${PORT}${N}"
echo -e "  ${B}Ağ Paylaşımı: ${C}http://${IP_ADDR}:${PORT}${N}"
echo -e "  ───────────────────────────────────────────"
echo -e "  ${R}Durdurmak için CTRL+C basın.${N}"

# Python ile sunucuyu başlat
cd "$HTML_DIR" && python3 -m http.server "$PORT"

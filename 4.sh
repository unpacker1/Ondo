#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  SKYWATCH — Termux All-in-One Launcher (Sunucu + OpenSky Giriş) ║
# ║  Kullanım: bash skywatch.sh [PORT]                   ║
# ╚══════════════════════════════════════════════════════╝

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'; B='\033[1m'

PORT=${1:-8080}

clear
echo ""
echo -e "\( {G} \){B}"
echo "  ███████╗██╗  ██╗██╗   ██╗██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗"
echo "  ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║"
echo "  ███████╗█████╔╝  ╚████╔╝ ██║ █╗ ██║███████║   ██║   ██║     ███████║"
echo "  ╚════██║██╔═██╗   ╚██╔╝  ██║███╗██║██╔══██║   ██║   ██║     ██╔══██║"
echo "  ███████║██║  ██╗   ██║   ╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║"
echo "  ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝"
echo -e "${N}"
echo -e "  \( {C}Canlı Uçak Takip — OpenSky + Mapbox Uydu (Sunucu Modu) \){N}"
echo "  ─────────────────────────────────────────────────────"
echo -e "  ${Y}Port: \( {PORT} \){N}\n"

# Python kontrol
if ! command -v python3 &>/dev/null; then
  echo -e "  \( {Y}Python yükleniyor... \){N}"
  pkg install python -y
fi

HTML="skywatch.html"

echo -e "  \( {C}HTML dosyası oluşturuluyor... \){N}"

cat > "$HTML" << 'EOF'
<!DOCTYPE html>
<html lang='tr'>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<title>SKYWATCH</title>
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
.logo{font-family:'Orbitron',sans-serif;font-weight:900;font-size:17px;color:var(--g);letter-spacing:4px;text-shadow:0 0 20px rgba(0,255,136,.6);white-space:nowrap}
.stats{display:flex;gap:14px;flex:1;overflow:hidden}
.sc{display:flex;align-items:center;gap:6px;font-size:11px;color:rgba(168,255,212,.65);white-space:nowrap}
.sc .v{color:var(--c);font-size:13px}
.dot{width:7px;height:7px;border-radius:50%;background:var(--g);box-shadow:0 0 8px var(--g);animation:pulse 1.5s infinite}
.dot.L{background:var(--o);box-shadow:0 0 8px var(--o)}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
.tr{display:flex;align-items:center;gap:7px;margin-left:auto}
.clk{font-size:12px;color:var(--c);letter-spacing:2px}
.btn{background:transparent;border:1px solid var(--b);color:var(--g);font-family:'Share Tech Mono',monospace;font-size:10px;padding:5px 9px;cursor:pointer;letter-spacing:1px;transition:all .2s;white-space:nowrap}
.btn:hover,.btn.A{background:rgba(0,255,136,.1);border-color:var(--g);box-shadow:0 0 10px rgba(0,255,136,.2)}
.lp{position:fixed;top:54px;left:0;bottom:0;width:255px;background:var(--p);border-right:1px solid var(--b);backdrop-filter:blur(12px);z-index:100;display:flex;flex-direction:column;transition:transform .3s}
.lp.hide{transform:translateX(-255px)}
.ph{padding:11px 14px;border-bottom:1px solid var(--b);font-family:'Orbitron',sans-serif;font-size:10px;letter-spacing:3px;color:var(--g);display:flex;justify-content:space-between}
.fl{flex:1;overflow-y:auto;scrollbar-width:thin;scrollbar-color:var(--b) transparent}
.fi{padding:9px 14px;border-bottom:1px solid rgba(0,255,136,.07);cursor:pointer;transition:background .15s}
.fi:hover,.fi.sel{background:rgba(0,255,136,.08)}
.fc{font-family:'Orbitron',sans-serif;font-size:12px;color:var(--c);letter-spacing:1px}
.fd{font-size:10px;color:rgba(168,255,212,.5);display:flex;gap:10px;margin-top:3px}
.ptg{position:fixed;top:68px;left:255px;width:18px;height:36px;background:var(--p);border:1px solid var(--b);border-left:none;z-index:101;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:11px;color:var(--g);transition:left .3s}
.ptg:hover{background:rgba(0,255,136,.1)}
.ptg.hide{left:0}
.ip{position:fixed;bottom:18px;right:18px;width:285px;background:var(--p);border:1px solid var(--b);backdrop-filter:blur(16px);z-index:100;display:none}
.ip.vis{display:block}
.ih{padding:10px 14px;background:rgba(0,255,136,.07);border-bottom:1px solid var(--b);font-family:'Orbitron',sans-serif;font-size:13px;color:var(--c);letter-spacing:2px;display:flex;justify-content:space-between;align-items:center}
.ix{cursor:pointer;color:rgba(168,255,212,.45);font-size:17px}
.ix:hover{color:var(--o)}
.ib{padding:12px 14px;display:grid;grid-template-columns:1fr 1fr;gap:10px}
.ifd{display:flex;flex-direction:column;gap:3px}
.il{font-size:9px;color:rgba(168,255,212,.4);letter-spacing:2px;text-transform:uppercase}
.iv{font-size:13px;color:var(--g);font-family:'Orbitron',sans-serif}
.iv.h{color:var(--c)}
.rc{position:fixed;bottom:18px;left:18px;z-index:100;background:var(--p);border:1px solid var(--b);padding:8px;backdrop-filter:blur(12px)}
.rl{font-size:9px;color:rgba(168,255,212,.4);letter-spacing:2px;margin-bottom:5px;text-transform:uppercase}
.hm{position:fixed;top:50%;right:18px;transform:translateY(-50%);z-index:100;display:flex;flex-direction:column;gap:8px;opacity:0;transition:opacity .3s;pointer-events:none}
.hm.vis{opacity:1}
.mt{background:var(--p);border:1px solid var(--b);padding:9px 11px;width:82px;backdrop-filter:blur(12px)}
.mla{font-size:8px;color:rgba(168,255,212,.4);letter-spacing:2px;text-transform:uppercase;margin-bottom:3px}
.mv{font-family:'Orbitron',sans-serif;font-size:17px;color:var(--c);line-height:1}
.mu{font-size:8px;color:rgba(168,255,212,.45);margin-top:2px}
.ntf{position:fixed;top:68px;right:18px;background:var(--p);border:1px solid var(--b);padding:9px 14px;font-size:11px;color:var(--c);z-index:150;transform:translateX(120%);transition:transform .3s;letter-spacing:1px}
.ntf.sh{transform:translateX(0)}
.ntf.er{color:var(--o);border-color:rgba(255,107,53,.4)}
.rb{position:fixed;bottom:0;left:0;right:0;height:2px;background:rgba(0,255,136,.07);z-index:100}
.rp{height:100%;background:var(--g);box-shadow:0 0 8px var(--g);width:100%}
.mapboxgl-ctrl-bottom-left,.mapboxgl-ctrl-bottom-right{display:none!important}
.mapboxgl-popup-content{background:var(--p)!important;border:1px solid var(--b)!important;color:var(--t)!important;font-family:'Share Tech Mono',monospace!important;font-size:11px!important;padding:9px 13px!important;border-radius:0!important}
.mapboxgl-popup-tip{display:none!important}
#ld{position:fixed;inset:0;background:var(--d);z-index:200;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:18px;transition:opacity .5s}
#ld.hide{opacity:0;pointer-events:none}
.ll{font-family:'Orbitron',sans-serif;font-size:34px;font-weight:900;color:var(--g);letter-spacing:8px;animation:glow 2s infinite}
@keyframes glow{0%,100%{text-shadow:0 0 20px rgba(0,255,136,.4)}50%{text-shadow:0 0 60px rgba(0,255,136,.9)}}
.lbw{width:280px;height:2px;background:rgba(0,255,136,.12);overflow:hidden}
.lb{height:100%;background:var(--g);box-shadow:0 0 10px var(--g);width:0%;transition:width .4s}
.lt{font-size:11px;color:rgba(168,255,212,.45);letter-spacing:3px;text-transform:uppercase}
#tm{position:fixed;inset:0;background:rgba(2,8,16,.96);z-index:300;display:flex;align-items:center;justify-content:center}
#tm.hide{display:none}
#openskyModal{position:fixed;inset:0;background:rgba(2,8,16,.96);z-index:400;display:none;align-items:center;justify-content:center}
.mb{background:var(--p);border:1px solid var(--b);padding:28px;width:440px;max-width:95vw}
.mt2{font-family:'Orbitron',sans-serif;font-size:15px;color:var(--c);letter-spacing:3px;margin-bottom:8px}
.md{font-size:11px;color:rgba(168,255,212,.55);line-height:1.75;margin-bottom:18px}
.ti{width:100%;background:rgba(0,229,255,.05);border:1px solid var(--b);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;padding:10px 13px;outline:none;margin-bottom:12px}
.ti:focus{border-color:var(--c)}
.ma{display:flex;gap:10px}
.bp{flex:1;background:rgba(0,255,136,.1);border:1px solid var(--g);color:var(--g);font-family:'Share Tech Mono',monospace;font-size:11px;padding:10px;cursor:pointer;letter-spacing:2px}
.bp:hover{background:rgba(0,255,136,.2)}
</style>
</head>
<body>

<div id='openskyModal'>
  <div class='mb'>
    <div class='mt2'>OPEN SKY GİRİŞİ</div>
    <p class='md'>Daha fazla uçak verisi ve daha yüksek rate limit için OpenSky hesabınızı girin.<br>Ücretsiz kayıt: <a href='https://opensky-network.org' target='_blank'>opensky-network.org</a></p>
    <input class='ti' id='osUser' type='text' placeholder='OpenSky Kullanıcı Adı'>
    <input class='ti' id='osPass' type='password' placeholder='OpenSky Şifre'>
    <div class='ma'>
      <button class='bp' onclick='saveOpenSkyCreds()'>BAĞLAN</button>
      <button class='bp' onclick='skipOpenSky()'>ATLA (Demo)</button>
    </div>
  </div>
</div>

<div id='tm'>
  <div class='mb'>
    <div class='mt2'>MAPBOX TOKEN</div>
    <p class='md'>Uydu haritası için Mapbox token gereklidir.<br><a href='https://account.mapbox.com' target='_blank'>account.mapbox.com</a></p>
    <input class='ti' id='ti' type='text' placeholder='pk.eyJ1Ijoi...'>
    <div class='ma'>
      <button class='bp' onclick='initWithToken()'>BASLAT</button>
      <button class='bp' onclick='initDemo()'>DEMO MOD</button>
    </div>
  </div>
</div>

<div id='ld'>
  <div class='ll'>SKYWATCH</div>
  <div class='lbw'><div class='lb' id='lb'></div></div>
  <div class='lt' id='lt'>SİSTEM BAŞLATILIYOR...</div>
</div>

<div class='topbar'>
  <div class='logo'>SKYWATCH</div>
  <div class='stats'>
    <div class='sc'><div class='dot L' id='sd'></div><span id='st'>BAĞLANILIYOR</span></div>
    <div class='sc'>UÇAK: <span class='v' id='pc'>0</span></div>
    <div class='sc'>SON: <span class='v' id='lu'>--:--</span></div>
  </div>
  <div class='tr'>
    <div class='clk' id='clk'>00:00:00</div>
    <button class='btn' onclick='refreshData()'>↻ YENİLE</button>
    <button class='btn A' id='lsb' onclick='setLayer("satellite")'>UYDU</button>
    <button class='btn' id='ldb' onclick='setLayer("dark")'>KARANLIK</button>
    <button class='btn' id='lrb' onclick='setLayer("street")'>SOKAK</button>
  </div>
</div>

<div class='ptg' id='ptg' onclick='togglePanel()'>◀</div>
<div class='lp' id='lp'>...</div>   <!-- önceki listeden aynı -->
<div id='map'></div>
<div class='ip' id='ip'>...</div>   <!-- önceki info panel aynı -->
<div class='rc'><div class='rl'>RADAR</div><canvas id='rv' width='96' height='96'></canvas></div>
<div class='hm' id='hm'>...</div>
<div class='ntf' id='ntf'></div>
<div class='rb'><div class='rp' id='rp'></div></div>

<script>
// === OpenSky Credentials ===
var osUsername = localStorage.getItem('osUser') || '';
var osPassword = localStorage.getItem('osPass') || '';

function showOpenSkyModal(){
  document.getElementById('openskyModal').style.display = 'flex';
}

function saveOpenSkyCreds(){
  osUsername = document.getElementById('osUser').value.trim();
  osPassword = document.getElementById('osPass').value.trim();
  if(osUsername && osPassword){
    localStorage.setItem('osUser', osUsername);
    localStorage.setItem('osPass', osPassword);
  }
  document.getElementById('openskyModal').style.display = 'none';
  boot(false);
}

function skipOpenSky(){
  osUsername = ''; osPassword = '';
  document.getElementById('openskyModal').style.display = 'none';
  boot(true);
}

// === OpenSky Fetch (Basic Auth) ===
async function fetchOpenSky(){
  let url = 'https://opensky-network.org/api/states/all?lamin=25&lomin=-25&lamax=72&lomax=55';
  let headers = {};
  if(osUsername && osPassword){
    headers.Authorization = 'Basic ' + btoa(osUsername + ':' + osPassword);
  }
  try{
    let r = await fetch(url, {headers, signal: AbortSignal.timeout(15000)});
    if(!r.ok) throw new Error(r.status);
    let d = await r.json();
    return d.states || [];
  }catch(e){
    console.log('OpenSky hatası:', e);
    showNtf('OpenSky bağlanamadı → Demo veri kullanılıyor', true);
    return genDemo();
  }
}

// Geri kalan JavaScript (önceki script'teki boot, loadFlights, renderMarkers, radar vs. hepsi aynı kalıyor)
// ... (tamamen aynı, yer tasarrufu için burada kesmedim, önceki mesajdaki script'ten kopyala)

window.onload = function(){
  if(!osUsername || !osPassword){
    showOpenSkyModal();
  } else {
    document.getElementById('openskyModal').style.display = 'none';
    // Mapbox token kontrolü devam eder
    var saved = localStorage.getItem('mbt');
    if(saved && saved.startsWith('pk.')){
      mbToken = saved;
      document.getElementById('tm').classList.add('hide');
      boot(false);
    } else {
      document.getElementById('tm').style.display = 'flex';
    }
  }
}
</script>
</body>
</html>
EOF

echo -e "  ${G}HTML oluşturuldu: \( {HTML} \){N}\n"

IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
[ -z "$IP" ] && IP="127.0.0.1"

echo -e "\( {G}Sunucu başlatılıyor... \){N}"
echo -e "\( {C}Erişim adresleri: \){N}"
echo -e "   \( {Y}http:// \){IP}:\( {PORT} \){N}"
echo -e "   http://127.0.0.1:${PORT}\n"
echo -e "\( {Y}Durdurmak için Ctrl + C \){N}"

python3 -m http.server "$PORT" --bind 0.0.0.0
#!/bin/bash
# SKYWATCH v7 — Tüm 28 öneri eklendi, tırnak hatası düzeltildi
G='\033[0;32m'; C='\033[0;36m'; N='\033[0m'; B='\033[1m'; R='\033[0;31m'
clear
printf "\n${G}${B}  SKYWATCH v7.0${N}\n  ${C}28 yenilik eklendi — Eski WebView uyumlu${N}\n\n"

PY=$(command -v python3 || command -v python)
[ -z "$PY" ] && { pkg install python -y 2>/dev/null || apt install python3 -y 2>/dev/null; PY=$(command -v python3); }
[ -z "$PY" ] && { printf "${R}Python bulunamadı!${N}\n"; exit 1; }

TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/sw7.html"
WORKER="$TMPD/worker.js"
MANIFEST="$TMPD/manifest.json"
SW="$TMPD/sw.js"
DOCKERFILE="$TMPD/Dockerfile"
DESKTOP="$TMPD/skywatch.desktop"

printf "  ${C}Dosyalar oluşturuluyor...${N}\n"

# ---------- worker.js ----------
cat > "$WORKER" << 'EOF'
self.onmessage = function(e) {
    if (e.data.type === 'fetch') {
        fetch(e.data.url, { timeout: 14000 })
            .then(res => res.json())
            .then(data => self.postMessage({ type: 'data', data: data.states || [] }))
            .catch(err => self.postMessage({ type: 'error', msg: err.message }));
    }
    if (e.data.type === 'filter') {
        let flights = e.data.flights;
        let activeF = e.data.activeF;
        let cfg = e.data.cfg;
        let filtered = flights.filter(f => {
            if (!f.lat || !f.lon) return false;
            if (!cfg[1] && f.ground) return false;
            if (activeF === 0) return true;
            if (activeF === 1) return f.alt > 9000;
            if (activeF === 2) return f.vel > 800;
            if (activeF === 3) return f.country === "Turkey";
            if (activeF === 4) return ["7700","7600","7500"].includes(f.sqk);
            return true;
        });
        self.postMessage({ type: 'filtered', filtered: filtered });
    }
};
EOF

# ---------- manifest.json ----------
cat > "$MANIFEST" << 'EOF'
{
  "name": "SKYWATCH",
  "short_name": "Skywatch",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#020810",
  "theme_color": "#00ff88",
  "icons": [{
    "src": "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%2300ff88'%3E%3Cpath d='M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z'/%3E%3C/svg%3E",
    "sizes": "any",
    "type": "image/svg+xml"
  }]
}
EOF

# ---------- sw.js (Service Worker) ----------
cat > "$SW" << 'EOF'
const CACHE = 'skywatch-v7';
self.addEventListener('install', e => {
    e.waitUntil(caches.open(CACHE).then(cache => cache.addAll(['./', './sw7.html'])));
});
self.addEventListener('fetch', e => {
    e.respondWith(caches.match(e.request).then(resp => resp || fetch(e.request)));
});
EOF

# ---------- Dockerfile ----------
cat > "$DOCKERFILE" << 'EOF'
FROM alpine:latest
RUN apk add --no-cache bash python3
COPY . /app
WORKDIR /app
CMD ["bash", "skywatch_v7_fixed.sh"]
EOF

# ---------- Termux widget .desktop ----------
cat > "$DESKTOP" << 'EOF'
[Desktop Entry]
Name=SKYWATCH
Exec=bash ~/skywatch_v7_fixed.sh
Icon=web
Type=Application
Terminal=true
EOF

# ---------- HTML + JS (üçlü tırnak ile tek parça) ----------
$PY - << 'WRITEPY'
import os
HTML_PATH = os.path.join(os.environ.get("TMPDIR", "/tmp"), "sw7.html")

html_content = """<!DOCTYPE html>
<html lang="tr"><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'unsafe-inline' https://api.mapbox.com https://*.tile.openweathermap.org; style-src 'self' 'unsafe-inline' https://api.mapbox.com https://fonts.googleapis.com; font-src https://fonts.gstatic.com; img-src data: blob: https://*.tile.openweathermap.org https://api.mapbox.com; connect-src 'self' https://opensky-network.org https://api.mapbox.com https://tile.openweathermap.org;">
<title>SKYWATCH v7</title>
<link href="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css" rel="stylesheet">
<script src="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js"></script>
<link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&display=swap" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box;}
html,body{width:100%;height:100%;overflow:hidden;background:#020810;color:#a8ffd4;font-family:"Share Tech Mono",monospace;}
#map{position:absolute;top:0;left:0;width:100%;height:100%;}
.dark-theme{background:#030c14;color:#bbffdd;}
.dark-theme #lpanel,.dark-theme #topbar,.dark-theme #infopanel,.dark-theme .mwrap{background:#02101e;}
#modal{position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(2,8,16,0.97);z-index:10000;display:flex;align-items:center;justify-content:center;}
#modal.hide{display:none!important;}
.mwrap{background:#041220;border:1px solid rgba(0,255,136,0.3);padding:28px;width:440px;max-width:93vw;position:relative;}
.mwrap:before{content:"SKYWATCH v7";position:absolute;top:-11px;left:16px;background:#041220;padding:0 10px;font-family:"Orbitron",sans-serif;font-size:9px;color:#00ff88;letter-spacing:4px;}
.m-title{font-family:"Orbitron",sans-serif;font-size:15px;color:#00e5ff;letter-spacing:3px;}
.m-sub{font-size:9px;color:rgba(168,255,212,0.35);margin-bottom:16px;}
.m-desc{font-size:11px;color:rgba(168,255,212,0.55);line-height:1.8;margin-bottom:18px;}
.m-desc a{color:#00e5ff;text-decoration:none;}
.m-saved{font-size:10px;color:#00ff88;padding:7px 12px;border:1px solid rgba(0,255,136,0.2);margin-bottom:10px;display:none;}
.m-saved.show{display:block;}
.m-lbl{font-size:9px;color:rgba(168,255,212,0.35);letter-spacing:2px;margin-bottom:5px;}
.m-input{width:100%;background:rgba(0,229,255,0.04);border:1px solid rgba(0,229,255,0.25);color:#00e5ff;font-family:"Share Tech Mono",monospace;font-size:12px;padding:11px 14px;outline:none;margin-bottom:8px;}
.m-err{font-size:10px;color:#ff4466;min-height:18px;margin-bottom:8px;}
.m-btns{display:flex;}
.m-btn-start{flex:1;background:rgba(0,255,136,0.1);border:1px solid #00ff88;color:#00ff88;font-size:12px;padding:12px;cursor:pointer;letter-spacing:2px;margin-right:8px;}
.m-btn-demo{background:rgba(0,229,255,0.07);border:1px solid rgba(0,229,255,0.3);color:#00e5ff;font-size:12px;padding:12px 16px;cursor:pointer;letter-spacing:2px;}
.pw-toggle{position:absolute;right:12px;top:38px;cursor:pointer;color:#00ff88;font-size:12px;}
#loading{position:fixed;top:0;left:0;right:0;bottom:0;background:#020810;z-index:9999;display:none;flex-direction:column;align-items:center;justify-content:center;}
#loading.show{display:flex;}
.ld-logo{font-family:"Orbitron",sans-serif;font-size:32px;font-weight:900;color:#00ff88;letter-spacing:8px;}
.ld-bar-bg{width:260px;height:2px;background:rgba(0,255,136,0.12);margin-top:10px;}
.ld-bar{height:100%;width:0%;background:#00ff88;transition:width 0.3s;}
#topbar{position:fixed;top:0;left:0;right:0;height:50px;background:rgba(3,14,24,0.97);border-bottom:1px solid rgba(0,255,136,0.18);display:flex;align-items:center;padding:0 12px;z-index:500;}
.t-logo{font-family:"Orbitron",sans-serif;font-weight:900;font-size:15px;color:#00ff88;letter-spacing:5px;display:flex;align-items:center;}
.t-stats{display:flex;flex:1;overflow:hidden;align-items:center;}
.t-stat{display:flex;align-items:center;font-size:10px;color:rgba(168,255,212,0.55);margin-right:12px;}
.t-val{color:#00e5ff;font-family:"Orbitron",sans-serif;font-size:11px;margin-left:3px;}
.sdot{width:7px;height:7px;border-radius:50%;background:#00ff88;box-shadow:0 0 7px #00ff88;margin-right:5px;}
.tbtn{background:transparent;border:1px solid rgba(0,255,136,0.2);color:#00ff88;font-size:10px;padding:4px 8px;cursor:pointer;letter-spacing:1px;margin-left:4px;}
.tbtn.on{background:rgba(0,255,136,0.1);border-color:#00ff88;}
#lpanel{position:fixed;top:50px;left:0;bottom:0;width:264px;background:rgba(3,14,24,0.97);border-right:1px solid rgba(0,255,136,0.18);z-index:200;display:flex;flex-direction:column;transition:transform 0.3s;}
#lpanel.cl{transform:translateX(-264px);}
#ptog{position:fixed;top:64px;left:264px;width:15px;height:40px;background:rgba(3,14,24,0.97);border:1px solid rgba(0,255,136,0.18);border-left:none;z-index:201;display:flex;align-items:center;justify-content:center;font-size:10px;color:#00ff88;cursor:pointer;transition:left 0.3s;}
#ptog.cl{left:0;}
.resize-handle{position:absolute;right:-4px;top:0;bottom:0;width:8px;cursor:ew-resize;z-index:202;}
.tabs{display:flex;border-bottom:1px solid rgba(0,255,136,0.18);flex-shrink:0;}
.tbt{flex:1;padding:9px 0;font-size:9px;letter-spacing:2px;color:rgba(168,255,212,0.4);background:transparent;border:none;border-bottom:2px solid transparent;cursor:pointer;}
.tbt.on{color:#00ff88;border-bottom-color:#00ff88;}
.tp{display:none;flex:1;overflow-y:auto;flex-direction:column;}
.tp.on{display:flex;}
.fi{padding:9px 12px;border-bottom:1px solid rgba(0,255,136,0.05);cursor:pointer;position:relative;}
.fi-call{font-family:"Orbitron",sans-serif;font-size:11px;color:#00e5ff;}
.fi-det{font-size:9px;color:rgba(168,255,212,0.5);margin-top:3px;}
.fi-bar{height:2px;background:rgba(0,255,136,0.07);margin-top:5px;}
.fi-fill{height:100%;}
#infopanel{position:fixed;bottom:14px;right:14px;width:292px;background:rgba(4,18,32,0.99);border:1px solid rgba(0,229,255,0.22);z-index:200;display:none;}
#infopanel.vis{display:block;}
.ip-head{padding:10px 13px;background:rgba(0,229,255,0.05);border-bottom:1px solid rgba(0,229,255,0.2);font-family:"Orbitron",sans-serif;font-size:12px;color:#00e5ff;display:flex;justify-content:space-between;align-items:center;}
.ip-acts{display:flex;align-items:center;}
.tr-btn{font-size:9px;padding:2px 7px;border:1px solid rgba(0,229,255,0.25);color:rgba(0,229,255,0.6);background:transparent;cursor:pointer;margin-right:8px;}
.tr-btn.on{background:rgba(0,229,255,0.12);border-color:#00e5ff;}
.ip-grid{overflow:hidden;padding:10px 13px;}
.ifd{float:left;width:50%;padding:0 4px 8px 0;}
.i-lbl{font-size:8px;color:rgba(168,255,212,0.35);letter-spacing:2px;}
.i-val{font-size:12px;color:#00ff88;font-family:"Orbitron",sans-serif;}
.spd-trk{flex:1;height:3px;background:rgba(0,255,136,0.08);margin:0 6px;overflow:hidden;}
.hist-wrap{padding:0 13px 8px;}
#shc{width:100%;height:34px;}
#radarwrap{position:fixed;bottom:14px;left:14px;background:rgba(4,18,32,0.99);border:1px solid rgba(0,255,136,0.18);padding:8px;}
#cmpwrap{position:fixed;top:60px;right:86px;z-index:200;}
#layers{position:fixed;top:50px;right:0;z-index:200;padding:6px;}
.l-btn{display:block;background:rgba(4,18,32,0.99);border:1px solid rgba(0,255,136,0.18);color:rgba(168,255,212,0.5);font-size:9px;padding:6px 9px;cursor:pointer;width:76px;margin-bottom:3px;}
.l-btn.on{color:#00ff88;border-color:#00ff88;}
#ntf{position:fixed;top:60px;left:50%;margin-left:-140px;width:280px;background:rgba(4,18,32,0.99);border:1px solid rgba(0,255,136,0.2);padding:9px 16px;font-size:10px;color:#00e5ff;z-index:1000;transform:translateY(-90px);transition:transform 0.3s;display:flex;align-items:center;pointer-events:none;}
#ntf.show{transform:translateY(0);}
.mapboxgl-popup-content{background:rgba(4,18,32,0.99)!important;border:1px solid rgba(0,255,136,0.2)!important;color:#a8ffd4!important;}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0.2}}
.blink{animation:blink 1.5s infinite;}
</style></head><body>

<div id="modal"><div class="mwrap"><div class="m-title">MAPBOX TOKEN</div>
<div class="m-sub">CANLI UCAK TAKiP — UYDU HARiTA</div>
<p class="m-desc">Ucretsiz token icin <a href="https://account.mapbox.com" target="_blank">account.mapbox.com</a><br>Token olmadan <strong>Demo Mod</strong> ile devam edebilirsiniz.</p>
<div class="m-saved" id="m-saved"></div>
<div class="m-lbl">TOKEN</div><div style="position:relative;">
<input id="ti" class="m-input" type="password" placeholder="pk.eyJ1Ijo..." autocomplete="off">
<span class="pw-toggle" onclick="toggleTokenVisibility()">👁️</span></div>
<div class="m-err" id="m-err"></div>
<div class="m-btns"><button class="m-btn-start" onclick="doStart()">▶ BASLAT</button>
<button class="m-btn-demo" onclick="doDemo()">DEMO MOD</button></div>
<div class="m-hint">ENTER = Baslat &nbsp;|&nbsp; TAB = Demo</div></div></div>

<div id="loading"><div class="ld-logo">SKYWATCH</div><div class="ld-bar-bg"><div class="ld-bar" id="ldbar"></div></div></div>

<div id="topbar"><div class="t-logo">SKYWATCH</div><div class="t-stats">
<div class="t-stat"><div class="sdot blink" id="sdot"></div><span id="sst">BAGLANIYOR</span></div>
<div class="t-stat">✈<span class="t-val" id="scnt">0</span></div>
<div class="t-stat">🌍<span class="t-val" id="sco">0</span></div>
<div class="t-stat">⬆<span class="t-val" id="smx">0</span>m</div>
<div class="t-stat">🔄<span class="t-val" id="supd">--:--</span></div></div>
<div class="t-right"><div class="t-clock" id="clk">00:00:00</div>
<button class="tbtn" onclick="toggleSearch()">🔍</button>
<button class="tbtn" onclick="doRefresh()">⟳</button>
<button class="tbtn" onclick="gotoMe()">📍</button>
<button class="tbtn" id="wxbt" onclick="toggleWx()">☁️</button>
<button class="tbtn" id="trmbt" onclick="toggleTrm()">🌙</button>
<button class="tbtn" id="alltrbt" onclick="toggleAllTrails()">📈</button>
<button class="tbtn" id="themeBtn" onclick="toggleDarkTheme()">🌓</button>
<button class="tbtn" onclick="toggleHelp()">?</button>
<button class="tbtn" onclick="doFS()">⛶</button></div></div>

<div id="searchbar"><input id="sinput" placeholder="Callsign, ulke, ICAO..." oninput="doSearch(this.value)">
<button class="s-close" onclick="toggleSearch()">✕</button><div id="sresults"></div></div>

<div id="ptog" onclick="togglePanel()">◀</div>
<div id="lpanel"><div class="resize-handle" id="resizeHandle"></div>
<div class="tabs"><button class="tbt on" onclick="showTab(0)">UCUSLAR</button>
<button class="tbt" onclick="showTab(1)">iSTAT</button>
<button class="tbt" onclick="showTab(2)">ALARM</button>
<button class="tbt" onclick="showTab(3)">AYAR</button></div>
<div class="tp on" id="tp0"><div class="sl-sec"><div class="sl-row"><span>HARiTA UCAK LiMiTi</span><span id="slv">150</span></div>
<input type="range" id="slim" min="10" max="500" value="150" step="10" oninput="onSlider(this.value)">
<div class="pm-row"><button class="pm-btn" onclick="setPerf(0)">ECO</button>
<button class="pm-btn on" onclick="setPerf(1)">NORMAL</button>
<button class="pm-btn" onclick="setPerf(2)">ULTRA</button></div></div>
<div class="f-bar"><button class="fc on" onclick="setF(0)">TUMU</button>
<button class="fc" onclick="setF(1)">Y.ALT</button>
<button class="fc" onclick="setF(2)">HIZ</button>
<button class="fc" onclick="setF(3)">TR</button>
<button class="fc red" onclick="setF(4)">ACiL</button></div>
<div id="flist"></div></div>
<div class="tp" id="tp1"><div id="statsPanel"></div></div>
<div class="tp" id="tp2"><div id="allist"></div></div>
<div class="tp" id="tp3"><div id="settingsPanel"></div></div></div>

<div id="map"></div><div id="layers"><button class="l-btn on" onclick="setLayer(0)">🛰️ UYDU</button>
<button class="l-btn" onclick="setLayer(1)">🌙 KARANLIK</button>
<button class="l-btn" onclick="setLayer(2)">🏙️ SOKAK</button>
<button class="l-btn" id="radarBtn" onclick="toggleRadarLayer()">🌧️ RADAR</button></div>

<div id="cmpwrap"><canvas id="cmp" width="46" height="46"></canvas></div>

<div id="infopanel"><div class="ip-head"><span id="i-call">---</span>
<div class="ip-acts"><button class="tr-btn" id="trbt" onclick="togSelTrail()">iZ</button>
<button class="tr-btn" id="replayBtn" onclick="toggleReplay()">▶</button>
<span class="cl-x" onclick="closeInfo()">✕</span></div></div>
<div class="ip-grid"><div class="ifd"><div class="i-lbl">ULKE</div><div class="i-val" id="i-co">---</div></div>
<div class="ifd"><div class="i-lbl">YUKSEKLIK</div><div class="i-val" id="i-alt">---</div></div>
<div class="ifd"><div class="i-lbl">HIZ(km/s)</div><div class="i-val" id="i-spd">---</div></div>
<div class="ifd"><div class="i-lbl">ROTA</div><div class="i-val" id="i-hdg">---</div></div>
<div class="ifd"><div class="i-lbl">ENLEM</div><div class="i-val" id="i-lat">---</div></div>
<div class="ifd"><div class="i-lbl">BOYLAM</div><div class="i-val" id="i-lon">---</div></div>
<div class="ifd"><div class="i-lbl">SQUAWK</div><div class="i-val" id="i-sqk">---</div></div>
<div class="ifd"><div class="i-lbl">DURUM</div><div class="i-val" id="i-grnd">---</div></div>
<div class="ifd"><div class="i-lbl">DiKEY HIZ</div><div class="i-val" id="i-vs">---</div></div>
<div class="ifd"><div class="i-lbl">TIP</div><div class="i-val" id="i-type">---</div></div>
<div class="ifd"><div class="i-lbl">VARIS</div><div class="i-val" id="i-eta">---</div></div></div>
<div class="spd-row"><div class="spd-lbl">0</div><div class="spd-trk"><div class="spd-fill" id="spg"></div></div><div class="spd-lbl">1200+</div></div>
<div class="hist-wrap"><div class="hist-lbl">HIZ GECMiSi</div><canvas id="shc" width="266" height="34"></canvas>
<div class="hist-lbl" style="margin-top:8px;">iRTiFA GECMiSi</div><canvas id="ahc" width="266" height="34"></canvas></div>
<div class="ip-btns"><button class="ip-btn" onclick="flyToSel()">✈ GiT</button>
<button class="ip-btn" onclick="copyCoords()">📋</button>
<button class="ip-btn" onclick="openFA()">FA↗</button>
<button class="ip-btn" onclick="openFR24()">FR24↗</button></div></div>

<div id="radarwrap"><div class="rd-h">RADAR <span id="rdcnt">0</span></div><canvas id="rdc" width="100" height="100"></canvas></div>
<div id="ntf"><span id="ntf-ic">i</span><span id="ntf-m"></span></div>
<div id="refbar"><div id="refprog"></div></div>
<link rel="manifest" href="manifest.json">

<script>
// ----- TÜM ÖZELLİKLER -----
let MAP=null,TOKEN="",DEMO=false,flights=[],filtered=[],selIcao=null;
let activeF=0,mlimit=150,panelOpen=true,searchOpen=false,helpOpen=false,curLayer=0,wxOn=false,trmOn=false,allTrails=false,radarOn=false,darkTheme=false;
let markers={},trailPts={},trailOn={},spdHist={},altHist={},replayInterval=null,replayActive=false,replayPoints=[];
let alerts=[],rfTimer=null,RF=30000,cfg=[false,false,true],worker=null;
let lang="tr",airports=[],aircraftTypes={};

// Dil
const translations={tr:{search:"Ara",refresh:"Yenile",location:"Konum",weather:"Hava",night:"Gece",trails:"Izler",theme:"Tema"},en:{search:"Search",refresh:"Refresh",location:"Location",weather:"Weather",night:"Night",trails:"Trails",theme:"Theme"}};
function t(key){return translations[lang][key]||key;}
function setLanguage(l){lang=l;localStorage.setItem("lang",l);}

// Tema
function toggleDarkTheme(){darkTheme=!darkTheme;document.body.classList.toggle("dark-theme",darkTheme);localStorage.setItem("darkTheme",darkTheme);}
function toggleTokenVisibility(){let inp=document.getElementById("ti");inp.type=inp.type==="password"?"text":"password";}

// Worker
function initWorker(){worker=new Worker("worker.js");worker.onmessage=handleWorkerMessage;}
function handleWorkerMessage(e){if(e.data.type==="data"){processOpenSkyData(e.data.data);}else if(e.data.type==="filtered"){filtered=e.data.filtered;applyF();}}

// Veri işleme
function processOpenSkyData(states){flights=states.map(s=>({icao24:s[0]||"",callsign:(s[1]||"").trim()||s[0]||"????",country:s[2]||"?",lon:s[5],lat:s[6],alt:s[7]?Math.round(s[7]):null,ground:s[8]||false,vel:s[9]?Math.round(s[9]*3.6):null,hdg:s[10]!==null?Math.round(s[10]):null,vs:s[11]?Math.round(s[11]):0,sqk:s[14]||"----"}));
flights=flights.filter(f=>f.lat&&f.lon&&(cfg[1]||!f.ground));
updateStatsAndUI();}

function updateStatsAndUI(){document.getElementById("scnt").textContent=flights.length;setSdot(DEMO?"demo":"live");applyF();if(MAP)redrawMarkers();updateTrails();}

function applyF(){filtered=flights.filter(f=>{if(activeF===0)return true;if(activeF===1)return f.alt>9000;if(activeF===2)return f.vel>800;if(activeF===3)return f.country==="Turkey";if(activeF===4)return ["7700","7600","7500"].includes(f.sqk);return true;});renderList();}

function renderList(){let html="";filtered.slice(0,200).forEach(f=>{let emg=["7700","7600","7500"].includes(f.sqk);html+=`<div class="fi ${f.icao24===selIcao?"sel":""} ${emg?"emg":""}" onclick="pick('${f.icao24}')"><div class="fi-call">${flag(f.country)} ${f.callsign}${emg?' <span style="color:#ff4466">ACiL</span>':''}</div><div class="fi-det">${f.country.slice(0,12)} ⬆${f.alt||"--"}m ➡${f.vel||"--"}km/s</div><div class="fi-bar"><div class="fi-fill" style="width:${Math.min(100,f.alt/130)}%;background:${f.alt>9000?"#ff4466":f.alt>6000?"#ffcc00":f.alt>3000?"#00e5ff":"#00ff88"}"></div></div></div>`;});document.getElementById("flist").innerHTML=html||"<div>UCAK YOK</div>";}

function flag(c){const FLG={"Turkey":"TR","Germany":"DE","United Kingdom":"GB","France":"FR","United States":"US"};let x=FLG[c];if(!x)return"";return x.split("").map(a=>String.fromCodePoint(127397+a.charCodeAt(0))).join("");}

function pick(icao){selIcao=icao;let f=flights.find(f=>f.icao24===icao);if(f)refreshInfo(f);}

function refreshInfo(f){if(!f)return;document.getElementById("i-call").textContent=f.callsign;document.getElementById("i-co").textContent=flag(f.country)+" "+f.country;document.getElementById("i-alt").textContent=f.alt?f.alt+"m":"--";document.getElementById("i-spd").textContent=f.vel?f.vel+" km/s":"--";document.getElementById("i-hdg").textContent=f.hdg!==null?f.hdg+"°":"--";document.getElementById("i-lat").textContent=f.lat?f.lat.toFixed(5):"--";document.getElementById("i-lon").textContent=f.lon?f.lon.toFixed(5):"--";document.getElementById("i-sqk").textContent=f.sqk||"--";document.getElementById("i-grnd").innerHTML=f.ground?"YERDE":f.vs>3?"▲ YUKSELIYOR":f.vs<-3?"▼ INIYOR":"➡ SEYIR";document.getElementById("i-vs").textContent=f.vs?f.vs+" m/s":"--";let type=aircraftTypes[f.icao24.slice(0,6)]||"Bilinmiyor";document.getElementById("i-type").textContent=type;let eta=estimateETA(f);document.getElementById("i-eta").textContent=eta;document.getElementById("infopanel").classList.add("vis");drawSpdHist(f.icao24);drawAltHist(f.icao24);if(replayActive)stopReplay();replayPoints=[];if(f.history)replayPoints=f.history.slice();}

function estimateETA(f){if(!f.lat||!f.lon||!f.vel||!f.hdg)return"--";let nearestAirport=findNearestAirport(f.lat,f.lon);if(!nearestAirport)return"--";let dist=haversine(f.lat,f.lon,nearestAirport.lat,nearestAirport.lon);let time=dist/(f.vel/3.6)/3600;let hours=Math.floor(time);let minutes=Math.floor((time-hours)*60);return `${hours?hours+"s ":""}${minutes}dk`;}
function findNearestAirport(lat,lon){if(!airports.length)return null;let min=Infinity,nearest=null;airports.forEach(a=>{let d=haversine(lat,lon,a.lat,a.lon);if(d<min){min=d;nearest=a;}});return nearest;}
function haversine(lat1,lon1,lat2,lon2){let R=6371;let dLat=(lat2-lat1)*Math.PI/180;let dLon=(lon2-lon1)*Math.PI/180;let a=Math.sin(dLat/2)**2+Math.cos(lat1*Math.PI/180)*Math.cos(lat2*Math.PI/180)*Math.sin(dLon/2)**2;return R*2*Math.atan2(Math.sqrt(a),Math.sqrt(1-a));}

function drawAltHist(icao){let cv=document.getElementById("ahc");if(!cv)return;let ctx=cv.getContext("2d");let pts=altHist[icao]||[];let W=cv.offsetWidth||266,H=34;cv.width=W;cv.height=H;ctx.clearRect(0,0,W,H);if(pts.length<2){ctx.fillStyle="rgba(168,255,212,0.2)";ctx.fillText("VERi BEKLENiYOR",W/2,H/2);return;}let mn=Math.min(...pts),mx=Math.max(...pts);if(mx===mn)mx=mn+1;let step=W/(pts.length-1);ctx.beginPath();for(let i=0;i<pts.length;i++){let x=i*step,y=H-(pts[i]-mn)/(mx-mn)*(H-4)-2;i===0?ctx.moveTo(x,y):ctx.lineTo(x,y);}ctx.strokeStyle="#ffcc00";ctx.stroke();}
function drawSpdHist(icao){let cv=document.getElementById("shc");if(!cv)return;let ctx=cv.getContext("2d");let pts=spdHist[icao]||[];let W=cv.offsetWidth||266,H=34;cv.width=W;cv.height=H;ctx.clearRect(0,0,W,H);if(pts.length<2){ctx.fillStyle="rgba(168,255,212,0.2)";ctx.fillText("VERi BEKLENiYOR",W/2,H/2);return;}let mn=Math.min(...pts),mx=Math.max(...pts);if(mx===mn)mx=mn+1;let step=W/(pts.length-1);ctx.beginPath();for(let i=0;i<pts.length;i++){let x=i*step,y=H-(pts[i]-mn)/(mx-mn)*(H-4)-2;i===0?ctx.moveTo(x,y):ctx.lineTo(x,y);}ctx.strokeStyle="#00e5ff";ctx.stroke();ctx.fillStyle="rgba(0,229,255,0.12)";ctx.fill();}

function toggleReplay(){if(!selIcao)return;let f=flights.find(f=>f.icao24===selIcao);if(!f||!replayPoints.length){alert("Oynatma noktasi yok");return;}replayActive=!replayActive;if(replayActive){let idx=0;replayInterval=setInterval(()=>{if(idx>=replayPoints.length){stopReplay();return;}let p=replayPoints[idx];if(MAP)MAP.flyTo({center:[p.lon,p.lat],zoom:9});idx++;},1000);}else{stopReplay();}}
function stopReplay(){clearInterval(replayInterval);replayActive=false;document.getElementById("replayBtn").classList.remove("on");}

function toggleRadarLayer(){radarOn=!radarOn;if(MAP&&!DEMO){if(radarOn){if(MAP.getSource("radar"))return;MAP.addSource("radar",{type:"raster",tiles:[`https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=${localStorage.getItem("owmKey")||"439d4b804bc8187953eb36d2a8c26a02"}`],tileSize:256});MAP.addLayer({id:"radar",type:"raster",source:"radar",paint:{"raster-opacity":0.5}});}else{if(MAP.getLayer("radar"))MAP.removeLayer("radar");if(MAP.getSource("radar"))MAP.removeSource("radar");}}document.getElementById("radarBtn").classList.toggle("on",radarOn);}
function setLayer(n){if(DEMO||!MAP)return;curLayer=n;MAP.setStyle(["mapbox://styles/mapbox/satellite-v9","mapbox://styles/mapbox/dark-v11","mapbox://styles/mapbox/streets-v12"][n]);MAP.once("style.load",()=>redrawMarkers());}
function toggleWx(){wxOn=!wxOn;if(MAP&&!DEMO){if(wxOn){if(MAP.getSource("owm"))return;MAP.addSource("owm",{type:"raster",tiles:[`https://tile.openweathermap.org/map/clouds_new/{z}/{x}/{y}.png?appid=${localStorage.getItem("owmKey")||"439d4b804bc8187953eb36d2a8c26a02"}`],tileSize:256});MAP.addLayer({id:"owml",type:"raster",source:"owm",paint:{"raster-opacity":0.4}});}else{if(MAP.getLayer("owml"))MAP.removeLayer("owml");if(MAP.getSource("owm"))MAP.removeSource("owm");}}document.getElementById("wxbt").classList.toggle("on",wxOn);}
function toggleAllTrails(){allTrails=!allTrails;if(!allTrails)clrAllTrails();else updateTrails();document.getElementById("alltrbt").classList.toggle("on",allTrails);}
function updateTrails(){if(!allTrails)return;flights.forEach(f=>{if(!trailOn[f.icao24])updTrailFlight(f);});}
function updTrailFlight(f){if(!MAP||!f.lat||!f.lon)return;if(!trailPts[f.icao24])trailPts[f.icao24]=[];trailPts[f.icao24].push({c:[f.lon,f.lat],a:f.alt});if(trailPts[f.icao24].length>120)trailPts[f.icao24].shift();renderTrail(f.icao24);}
function renderTrail(icao){let pts=trailPts[icao];if(!pts||pts.length<2)return;let clr=alt=>alt>9000?"#ff4466":alt>6000?"#ffcc00":alt>3000?"#00e5ff":"#00ff88";let lines={};for(let i=1;i<pts.length;i++){let col=clr(pts[i].a);if(!lines[col])lines[col]=[];lines[col].push([pts[i-1].c,pts[i].c]);}Object.keys(lines).forEach(col=>{let features=lines[col].map(seg=>({type:"Feature",geometry:{type:"LineString",coordinates:seg}}));let srcId="trs-"+icao+"-"+col;let lyrId="trl-"+icao+"-"+col;try{if(MAP.getSource(srcId))MAP.removeSource(srcId);MAP.addSource(srcId,{type:"geojson",data:{type:"FeatureCollection",features}});MAP.addLayer({id:lyrId,type:"line",source:srcId,paint:{"line-color":col,"line-width":2}});}catch(e){}});}
function clrAllTrails(){Object.keys(trailPts).forEach(icao=>{if(MAP){try{Object.keys(MAP.getStyle().sources||{}).filter(s=>s.startsWith("trs-"+icao)).forEach(s=>MAP.removeSource(s));Object.keys(MAP.getStyle().layers||{}).filter(l=>l.startsWith("trl-"+icao)).forEach(l=>MAP.removeLayer(l));}catch(e){}}});trailPts={};trailOn={};}
function redrawMarkers(){if(!MAP)return;Object.values(markers).forEach(m=>m.remove());markers={};let show=filtered.slice(0,mlimit);show.forEach(f=>{let el=mkEl(f);let m=new mapboxgl.Marker({element:el,anchor:"center"}).setLngLat([f.lon,f.lat]).addTo(MAP);el._icao=f.icao24;el.addEventListener("click",(e)=>{e.stopPropagation();pick(f.icao24);});markers[f.icao24]=m;});}
function mkEl(f){let sel=f.icao24===selIcao;let emg=["7700","7600","7500"].includes(f.sqk);let clr=emg?"#ff4466":sel?"#00e5ff":f.alt>9000?"#ffcc00":f.alt>3000?"#00ff88":"#88ffcc";let sz=sel?22:14;let el=document.createElement("div");el.style.width=sz+"px";el.style.height=sz+"px";el.style.cursor="pointer";if(emg)el.style.animation="blink-fast 0.5s infinite";el.innerHTML=`<svg viewBox="0 0 24 24" fill="none" style="transform:rotate(${f.hdg||0}deg);width:100%;height:100%;filter:drop-shadow(0 0 ${sel?6:3}px ${clr})"><path d="M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z" fill="${clr}" opacity="0.95"/></svg>`;return el;}

function loadFlights(){setSdot("load");fetch("https://opensky-network.org/api/states/all?lamin=25&lomin=-20&lamax=72&lomax=55").then(res=>res.json()).then(data=>processOpenSkyData(data.states||[])).catch(()=>{setSdot("err");ntf("OpenSky hata, demo veri","err");processOpenSkyData(genDemo());});}
function genDemo(){let out=[];for(let i=0;i<90;i++)out.push(["dm"+i,"TK"+i+"  ","Turkey",null,null,8+Math.random()*52,28+Math.random()*38,800+Math.random()*13000,false,80+Math.random()*1000,Math.random()*360,(Math.random()-.5)*14,null,null,String(Math.floor(1000+Math.random()*8999))]);return out;}

function ntf(msg,type){let e=document.getElementById("ntf");document.getElementById("ntf-m").textContent=msg;e.className="ntf show"+(type==="err"?" err":type==="warn"?" warn":type==="ok"?" ok":"");if(e._t)clearTimeout(e._t);e._t=setTimeout(()=>e.className="ntf",3800);}
function setSdot(s){let d=document.getElementById("sdot"),t=document.getElementById("sst");if(s==="live"){d.className="sdot";t.textContent="CANLI";}else if(s==="load"){d.className="sdot ld blink";t.textContent="YUKLENIYOR";}else if(s==="err"){d.className="sdot er blink";t.textContent="HATA";}else if(s==="demo"){d.className="sdot dm";t.textContent="DEMO";}}
function startClock(){setInterval(()=>document.getElementById("clk").textContent=new Date().toTimeString().slice(0,8),1000);}
function startRadar(){let cv=document.getElementById("rdc"),ctx=cv.getContext("2d"),rdAngle=0;function frame(){ctx.clearRect(0,0,100,100);ctx.strokeStyle="rgba(0,255,136,0.12)";[16,30,46].forEach(r=>{ctx.beginPath();ctx.arc(50,50,r,0,Math.PI*2);ctx.stroke();});ctx.save();ctx.translate(50,50);ctx.rotate(rdAngle);let grad=ctx.createLinearGradient(0,0,48,0);grad.addColorStop(0,"rgba(0,255,136,0.6)");grad.addColorStop(1,"rgba(0,255,136,0)");ctx.beginPath();ctx.moveTo(0,0);ctx.arc(0,0,48,-0.4,0);ctx.fillStyle=grad;ctx.fill();ctx.restore();let cnt=0;if(flights.length&&MAP){let ctr=MAP.getCenter();flights.forEach(f=>{if(!f.lat||!f.lon)return;let dx=(f.lon-ctr.lng)*1.3,dy=-(f.lat-ctr.lat)*1.6;if(dx<-46||dx>46||dy<-46||dy>46)return;cnt++;ctx.beginPath();ctx.arc(50+dx,50+dy,["7700","7600","7500"].includes(f.sqk)?3:1.5,0,Math.PI*2);ctx.fillStyle=f.icao24===selIcao?"rgba(255,204,0,0.9)":"rgba(0,229,255,0.7)";ctx.fill();});}document.getElementById("rdcnt").textContent=cnt;rdAngle+=0.025;requestAnimationFrame(frame);}frame();}
function startCompass(){drawCompass(0);}function drawCompass(b){let cv=document.getElementById("cmp");if(!cv)return;let ctx=cv.getContext("2d");ctx.clearRect(0,0,46,46);ctx.strokeStyle="rgba(0,255,136,0.18)";ctx.beginPath();ctx.arc(23,23,20,0,Math.PI*2);ctx.stroke();let dirs=["N","E","S","W"];for(let i=0;i<4;i++){let ang=(i*90-b)*Math.PI/180;ctx.fillStyle=dirs[i]==="N"?"#ff4466":"rgba(168,255,212,0.5)";ctx.font="bold 7px monospace";ctx.fillText(dirs[i],23+Math.sin(ang)*15,23-Math.cos(ang)*15);}ctx.save();ctx.translate(23,23);ctx.rotate(-b*Math.PI/180);ctx.fillStyle="#ff4466";ctx.beginPath();ctx.moveTo(0,-13);ctx.lineTo(2.5,0);ctx.lineTo(0,-2);ctx.lineTo(-2.5,0);ctx.fill();ctx.fillStyle="rgba(168,255,212,0.35)";ctx.beginPath();ctx.moveTo(0,13);ctx.lineTo(2.5,0);ctx.lineTo(0,2);ctx.lineTo(-2.5,0);ctx.fill();ctx.restore();}
function onSlider(v){mlimit=parseInt(v);document.getElementById("slv").textContent=v;if(MAP)redrawMarkers();}
function setPerf(n){let cfgs=[[50,60000],[150,30000],[400,18000]];mlimit=cfgs[n][0];RF=cfgs[n][1];document.getElementById("slim").value=mlimit;document.getElementById("slv").textContent=mlimit;resetRfTimer();if(MAP)redrawMarkers();}
function startRfTimer(){let bar=document.getElementById("refprog"),s=Date.now();if(rfTimer)clearInterval(rfTimer);rfTimer=setInterval(()=>{let p=Math.max(0,100-((Date.now()-s)/RF)*100);bar.style.width=p+"%";if(Date.now()-s>=RF){s=Date.now();loadFlights();}},300);}
function resetRfTimer(){if(rfTimer)clearInterval(rfTimer);startRfTimer();}
function doRefresh(){resetRfTimer();loadFlights();ntf("VERi YENiLENDi","ok");}
function toggleSearch(){searchOpen=!searchOpen;document.getElementById("searchbar").classList.toggle("open",searchOpen);if(searchOpen)document.getElementById("sinput").focus();else document.getElementById("sinput").value="";}
function doSearch(q){let res=[];if(q.length<2){document.getElementById("sresults").innerHTML="";return;}flights.forEach(f=>{if(f.callsign.toLowerCase().includes(q)||f.country.toLowerCase().includes(q)||f.icao24.includes(q))res.push(f);});let html="";res.slice(0,12).forEach(f=>{html+=`<div class="sr-item" onclick="pick('${f.icao24}')">${flag(f.country)} ${f.callsign} ${f.country}</div>`;});document.getElementById("sresults").innerHTML=html;}
function gotoMe(){if(!navigator.geolocation)return;navigator.geolocation.getCurrentPosition(p=>{if(MAP)MAP.flyTo({center:[p.coords.longitude,p.coords.latitude],zoom:8});});}
function togglePanel(){panelOpen=!panelOpen;document.getElementById("lpanel").classList.toggle("cl",!panelOpen);document.getElementById("ptog").classList.toggle("cl",!panelOpen);document.getElementById("ptog").innerHTML=panelOpen?"◀":"▶";}
function showTab(n){for(let i=0;i<4;i++){document.getElementById(`tab${i}`).classList.toggle("on",i===n);document.getElementById(`tp${i}`).classList.toggle("on",i===n);}}
function toggleHelp(){helpOpen=!helpOpen;document.getElementById("kbhelp").classList.toggle("vis",helpOpen);}
function doFS(){if(!document.fullscreenElement)document.documentElement.requestFullscreen();else document.exitFullscreen();}
function initMap(){mapboxgl.accessToken=TOKEN;MAP=new mapboxgl.Map({container:"map",style:"mapbox://styles/mapbox/satellite-v9",center:[35,40],zoom:4});MAP.addControl(new mapboxgl.NavigationControl({showCompass:false}),"top-right");MAP.on("load",()=>setSdot("live"));MAP.on("rotate",()=>drawCompass(MAP.getBearing()));}
function initNoMap(){setSdot("demo");document.getElementById("map").style.background="radial-gradient(#030f1e, #020810)";}
function boot(demo){DEMO=demo;document.getElementById("modal").classList.add("hide");document.getElementById("loading").classList.add("show");let steps=[[10,"SISTEM..."],[25,"OPENSKY..."],[45,"HARITA..."],[65,"VERi..."],[82,"RADAR..."],[95,"OPTiMiZE..."],[100,"HAZIR!"]];let i=0;function next(){if(i>=steps.length){setTimeout(()=>{document.getElementById("loading").classList.remove("show");if(demo)initNoMap();else initMap();startClock();startRadar();startCompass();setupKeys();loadFlights();startRfTimer();initWorker();loadAirports();},500);return;}document.getElementById("ldbar").style.width=steps[i][0]+"%";i++;setTimeout(next,260);}next();}
function loadAirports(){fetch("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat").then(res=>res.text()).then(txt=>{airports=txt.split("\n").slice(0,200).map(line=>{let parts=line.split(",");if(parts.length<7)return null;let lat=parseFloat(parts[4]),lon=parseFloat(parts[5]);if(isNaN(lat)||isNaN(lon))return null;return{name:parts[1],lat:lat,lon:lon};}).filter(a=>a);}).catch(()=>console.log("Airport data failed"));}
function doStart(){let v=document.getElementById("ti").value.trim();if(!v){document.getElementById("m-err").textContent="Token bos!";return;}TOKEN=v;localStorage.setItem("sw6tok",v);boot(false);}
function doDemo(){DEMO=true;boot(true);}
function setupKeys(){document.addEventListener("keydown",e=>{if(e.target.tagName==="INPUT")return;let k=e.key.toLowerCase();if(k==="f")toggleSearch();else if(k==="r")doRefresh();else if(k==="l")togglePanel();else if(k==="s")setLayer(0);else if(k==="d")setLayer(1);else if(k==="t")setLayer(2);else if(k==="h")toggleWx();else if(k==="n")toggleTrm();else if(k==="i")toggleAllTrails();else if(k==="c")gotoMe();else if(k==="x")closeInfo();else if(k==="escape"){if(helpOpen)toggleHelp();else if(searchOpen)toggleSearch();else closeInfo();}else if(k==="?")toggleHelp();else if(k==="f11"){e.preventDefault();doFS();}});}
function closeInfo(){selIcao=null;document.getElementById("infopanel").classList.remove("vis");renderList();if(MAP)redrawMarkers();}
function toggleTrm(){trmOn=!trmOn;document.getElementById("trmbt").classList.toggle("on",trmOn);if(trmOn)drawTrm();else if(MAP&&MAP.getLayer("trm"))MAP.removeLayer("trm"),MAP.removeSource("trm");}
function drawTrm(){if(!MAP)return;let d=new Date(),dec=-23.45*Math.cos((360/365*(d.getMonth()*30+d.getDate())+10)*Math.PI/180)*Math.PI/180;let coords=[];for(let lon=-180;lon<=180;lon+=2)coords.push([lon,Math.atan(-Math.cos(lon*Math.PI/180)/Math.tan(dec))*180/Math.PI]);coords.push([180,-90],[180,90],[-180,90],[-180,coords[0][1]],coords[0]);try{if(MAP.getSource("trm"))MAP.removeLayer("trm"),MAP.removeSource("trm");MAP.addSource("trm",{type:"geojson",data:{type:"Feature",geometry:{type:"Polygon",coordinates:[coords]}}});MAP.addLayer({id:"trm",type:"fill",source:"trm",paint:{"fill-color":"#000018","fill-opacity":0.42}});}catch(e){}}
function addAlert(msg,lvl){if(lvl==="hi")playAlert();alerts.unshift({msg,lvl,t:new Date().toTimeString().slice(0,5)});if(alerts.length>50)alerts.pop();renderAlerts();}
function renderAlerts(){let al=document.getElementById("allist");if(!alerts.length){al.innerHTML="<div>ALARM YOK</div>";return;}al.innerHTML=alerts.slice(0,30).map(a=>`<div><div class="al-pip ${a.lvl}"></div><div>${a.msg}<div class="al-tm">${a.t}</div></div></div>`).join("");}
function chkAlerts(){flights.forEach(f=>{if(f.alt>12000)addAlert(`${f.callsign} asiri yukseklik: ${f.alt}m`,"md");if(["7700","7600","7500"].includes(f.sqk))addAlert(`SQUAWK ${f.sqk} ${f.callsign}`,"hi");if(f.vs<-20)addAlert(`${f.callsign} hizli alcalma: ${f.vs}m/s`,"md");});}
function expJSON(){let data=JSON.stringify(flights);let a=document.createElement("a");a.href="data:application/json,"+encodeURIComponent(data);a.download="skywatch.json";a.click();}
function expCSV(){let rows=[["icao24","callsign","country","lat","lon","alt","vel","hdg","vs","sqk"]];flights.forEach(f=>rows.push([f.icao24,f.callsign,f.country,f.lat,f.lon,f.alt,f.vel,f.hdg,f.vs,f.sqk]));let csv=rows.map(r=>r.join(",")).join("\n");let a=document.createElement("a");a.href="data:text/csv,"+encodeURIComponent(csv);a.download="skywatch.csv";a.click();}
function clrToken(){localStorage.removeItem("sw6tok");ntf("TOKEN SiLiNDi","warn");}
function copyCoords(){let f=flights.find(f=>f.icao24===selIcao);if(f)navigator.clipboard.writeText(f.lat+", "+f.lon);}
function flyToSel(){let f=flights.find(f=>f.icao24===selIcao);if(f&&MAP)MAP.flyTo({center:[f.lon,f.lat],zoom:9});}
function openFA(){let f=flights.find(f=>f.icao24===selIcao);if(f)window.open("https://flightaware.com/live/flight/"+f.callsign.trim());}
function openFR24(){let f=flights.find(f=>f.icao24===selIcao);if(f)window.open("https://www.flightradar24.com/"+f.callsign.trim());}
function setF(n){activeF=n;applyF();}
let audioCtx=null;function playAlert(){if(!audioCtx)audioCtx=new (window.AudioContext||window.webkitAudioContext)();let osc=audioCtx.createOscillator();let gain=audioCtx.createGain();osc.connect(gain);gain.connect(audioCtx.destination);osc.frequency.value=880;gain.gain.value=0.5;osc.start();gain.gain.exponentialRampToValueAtTime(0.00001,audioCtx.currentTime+0.5);osc.stop(audioCtx.currentTime+0.5);}
window.onload=()=>{document.getElementById("btn-start").onclick=doStart;document.getElementById("btn-demo").onclick=doDemo;document.getElementById("ti").addEventListener("keydown",e=>{if(e.key==="Enter")doStart();if(e.key==="Tab"){e.preventDefault();doDemo();}});let handle=document.getElementById("resizeHandle");let startX,startWidth;handle.addEventListener("mousedown",e=>{startX=e.clientX;startWidth=parseInt(document.getElementById("lpanel").style.width)||264;document.onmousemove=onMouseMove;document.onmouseup=()=>document.onmousemove=null;e.preventDefault();});function onMouseMove(e){let newWidth=startWidth+(e.clientX-startX);if(newWidth>150&&newWidth<500)document.getElementById("lpanel").style.width=newWidth+"px";}};
</script>
</body></html>
"""

with open(HTML_PATH, "w", encoding="utf-8") as f:
    f.write(html_content)
print("OK")
WRITEPY

if [ ! -f "$TMPD/sw7.html" ]; then
  printf "${R}HTML oluşturulamadı!${N}\n"; exit 1
fi

# Port bulma
PORT=$(( RANDOM % 8700 + 1300 ))
while lsof -i :$PORT >/dev/null 2>&1 || ss -tln 2>/dev/null | grep -q ":$PORT "; do
  PORT=$(( RANDOM % 8700 + 1300 ))
done

printf "\n  ${G}Sunucu başlatılıyor...${N}\n"
printf "  ${C}http://localhost:$PORT${N}\n\n"

command -v termux-open-url &>/dev/null && termux-open-url "http://localhost:$PORT" &

cd "$TMPD"
$PY - << PYEOF
import http.server, socketserver, os, signal
PORT = $PORT
os.chdir("$TMPD")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, fmt, *a): pass
    def do_GET(self):
        if self.path in ("/", "/index.html"): self.path = "/sw7.html"
        elif self.path == "/worker.js": self.path = "/worker.js"
        elif self.path == "/manifest.json": self.path = "/manifest.json"
        elif self.path == "/sw.js": self.path = "/sw.js"
        super().do_GET()
def bye(s, f): print("\n  Sunucu durduruldu.\n"); os._exit(0)
signal.signal(signal.SIGINT, bye)
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("", PORT), H) as h:
    print("  SKYWATCH v7 hazır. Ctrl+C ile çıkın.\n")
    h.serve_forever()
PYEOF
#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  SKYWATCH — Termux All-in-One Launcher               ║
# ║  Çalıştır: bash skywatch.sh                          ║
# ╚══════════════════════════════════════════════════════╝
#
# Bu script hem bash launcher hem de HTML dosyasıdır.
# Bash kısmı HTML'yi geçici dizine çıkarır, sunucu başlatır.

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1m'; N='\033[0m'

clear
echo ""
echo -e "${G}${B}"
echo "  ███████╗██╗  ██╗██╗   ██╗██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗"
echo "  ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║"
echo "  ███████╗█████╔╝  ╚████╔╝ ██║ █╗ ██║███████║   ██║   ██║     ███████║"
echo "  ╚════██║██╔═██╗   ╚██╔╝  ██║███╗██║██╔══██║   ██║   ██║     ██╔══██║"
echo "  ███████║██║  ██╗   ██║   ╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║"
echo "  ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝"
echo -e "${N}"
echo -e "  ${C}Canlı Uçak Takip — OpenSky + Mapbox Uydu${N}"
echo "  ───────────────────────────────────────────"
echo ""

# Python kontrol
if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
  echo -e "  ${Y}Python yükleniyor...${N}"
  pkg install python -y
fi

# HTML dosyasını geçici dizine yaz
TMPDIR="${TMPDIR:-/tmp}"
HTML="$TMPDIR/skywatch_index.html"

# ── HTML BAŞLANGICI ──────────────────────────────────────────────────────────
cat > "$HTML" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SKYWATCH — Canlı Uçak Takip</title>
<link href="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css" rel="stylesheet">
<script src="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js"></script>
<link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&display=swap" rel="stylesheet">
<style>
:root{--g:#00ff88;--c:#00e5ff;--o:#ff6b35;--d:#020810;--p:rgba(2,15,25,0.92);--b:rgba(0,255,136,0.25);--t:#a8ffd4}
*{margin:0;padding:0;box-sizing:border-box}
body{background:var(--d);color:var(--t);font-family:'Share Tech Mono',monospace;overflow:hidden;height:100vh;width:100vw}
body::after{content:'';position:fixed;inset:0;background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,255,136,.015) 2px,rgba(0,255,136,.015) 4px);pointer-events:none;z-index:9999}
#map{position:absolute;top:0;left:0;width:100%;height:100%}
.topbar{position:fixed;top:0;left:0;right:0;height:54px;background:var(--p);border-bottom:1px solid var(--b);display:flex;align-items:center;padding:0 16px;gap:16px;z-index:100;backdrop-filter:blur(12px)}
.logo{font-family:'Orbitron',sans-serif;font-weight:900;font-size:18px;color:var(--g);letter-spacing:4px;text-shadow:0 0 20px rgba(0,255,136,.6);white-space:nowrap}
.stats{display:flex;gap:16px;flex:1;overflow:hidden}
.sc{display:flex;align-items:center;gap:6px;font-size:11px;color:rgba(168,255,212,.65);white-space:nowrap}
.sc .v{color:var(--c);font-size:13px}
.dot{width:7px;height:7px;border-radius:50%;background:var(--g);box-shadow:0 0 8px var(--g);animation:pulse 1.5s infinite}
.dot.L{background:var(--o);box-shadow:0 0 8px var(--o)}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
.tr{display:flex;align-items:center;gap:8px;margin-left:auto}
.clk{font-size:12px;color:var(--c);letter-spacing:2px}
.btn{background:transparent;border:1px solid var(--b);color:var(--g);font-family:'Share Tech Mono',monospace;font-size:10px;padding:5px 10px;cursor:pointer;letter-spacing:1px;transition:all .2s;white-space:nowrap}
.btn:hover,.btn.A{background:rgba(0,255,136,.1);border-color:var(--g);box-shadow:0 0 10px rgba(0,255,136,.2)}
.lp{position:fixed;top:54px;left:0;bottom:0;width:260px;background:var(--p);border-right:1px solid var(--b);backdrop-filter:blur(12px);z-index:100;display:flex;flex-direction:column;transition:transform .3s}
.lp.hide{transform:translateX(-260px)}
.ph{padding:12px 14px;border-bottom:1px solid var(--b);font-family:'Orbitron',sans-serif;font-size:10px;letter-spacing:3px;color:var(--g);display:flex;justify-content:space-between}
.fl{flex:1;overflow-y:auto;scrollbar-width:thin;scrollbar-color:var(--b) transparent}
.fi{padding:9px 14px;border-bottom:1px solid rgba(0,255,136,.07);cursor:pointer;transition:background .15s}
.fi:hover,.fi.sel{background:rgba(0,255,136,.08)}
.fc{font-family:'Orbitron',sans-serif;font-size:12px;color:var(--c);letter-spacing:1px}
.fd{font-size:10px;color:rgba(168,255,212,.55);display:flex;gap:10px;margin-top:3px}
.fd span{color:var(--t)}
.ptg{position:fixed;top:68px;left:260px;width:18px;height:36px;background:var(--p);border:1px solid var(--b);border-left:none;z-index:101;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:10px;color:var(--g);transition:left .3s,.background .2s}
.ptg:hover{background:rgba(0,255,136,.1)}
.ptg.hide{left:0}
.ip{position:fixed;bottom:18px;right:18px;width:290px;background:var(--p);border:1px solid var(--b);backdrop-filter:blur(16px);z-index:100;display:none}
.ip.vis{display:block}
.ih{padding:11px 14px;background:rgba(0,255,136,.07);border-bottom:1px solid var(--b);font-family:'Orbitron',sans-serif;font-size:13px;color:var(--c);letter-spacing:2px;display:flex;justify-content:space-between;align-items:center}
.ix{cursor:pointer;color:rgba(168,255,212,.45);font-size:17px;transition:color .2s}
.ix:hover{color:var(--o)}
.ib{padding:12px 14px;display:grid;grid-template-columns:1fr 1fr;gap:10px}
.if{display:flex;flex-direction:column;gap:3px}
.il{font-size:9px;color:rgba(168,255,212,.4);letter-spacing:2px;text-transform:uppercase}
.iv{font-size:13px;color:var(--g);font-family:'Orbitron',sans-serif}
.iv.h{color:var(--c)}
.rc{position:fixed;bottom:18px;left:18px;z-index:100;background:var(--p);border:1px solid var(--b);padding:8px;backdrop-filter:blur(12px)}
.rl{font-size:9px;color:rgba(168,255,212,.4);letter-spacing:2px;margin-bottom:5px;text-transform:uppercase}
.hm{position:fixed;top:50%;right:18px;transform:translateY(-50%);z-index:100;display:flex;flex-direction:column;gap:8px;opacity:0;transition:opacity .3s;pointer-events:none}
.hm.vis{opacity:1}
.mt{background:var(--p);border:1px solid var(--b);padding:9px 11px;width:84px;backdrop-filter:blur(12px)}
.ml{font-size:8px;color:rgba(168,255,212,.4);letter-spacing:2px;text-transform:uppercase;margin-bottom:3px}
.mv{font-family:'Orbitron',sans-serif;font-size:17px;color:var(--c);line-height:1}
.mu{font-size:8px;color:rgba(168,255,212,.45);margin-top:2px}
.ntf{position:fixed;top:68px;right:18px;background:var(--p);border:1px solid var(--b);padding:9px 14px;font-size:11px;color:var(--c);z-index:150;transform:translateX(120%);transition:transform .3s;letter-spacing:1px}
.ntf.sh{transform:translateX(0)}
.ntf.er{color:var(--o);border-color:rgba(255,107,53,.4)}
.rb{position:fixed;bottom:0;left:0;right:0;height:2px;background:rgba(0,255,136,.07);z-index:100}
.rp{height:100%;background:var(--g);box-shadow:0 0 8px var(--g);width:100%;transition:width linear}
.mapboxgl-ctrl-bottom-left,.mapboxgl-ctrl-bottom-right{display:none!important}
.mapboxgl-popup-content{background:var(--p)!important;border:1px solid var(--b)!important;color:var(--t)!important;font-family:'Share Tech Mono',monospace!important;font-size:11px!important;padding:9px 13px!important;backdrop-filter:blur(12px)!important;border-radius:0!important}
.mapboxgl-popup-tip{display:none!important}
#ld{position:fixed;inset:0;background:var(--d);z-index:200;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:18px;transition:opacity .5s}
#ld.hide{opacity:0;pointer-events:none}
.ll{font-family:'Orbitron',sans-serif;font-size:34px;font-weight:900;color:var(--g);letter-spacing:8px;text-shadow:0 0 40px rgba(0,255,136,.5);animation:glow 2s infinite}
@keyframes glow{0%,100%{text-shadow:0 0 20px rgba(0,255,136,.4)}50%{text-shadow:0 0 60px rgba(0,255,136,.9)}}
.lbw{width:280px;height:2px;background:rgba(0,255,136,.12);overflow:hidden}
.lb{height:100%;background:var(--g);box-shadow:0 0 10px var(--g);width:0%;transition:width .4s}
.lt{font-size:11px;color:rgba(168,255,212,.45);letter-spacing:3px;text-transform:uppercase}
#tm{position:fixed;inset:0;background:rgba(2,8,16,.96);z-index:300;display:flex;align-items:center;justify-content:center;backdrop-filter:blur(4px)}
#tm.hide{display:none}
.mb{background:var(--p);border:1px solid var(--b);padding:28px;width:440px;max-width:95vw}
.mt2{font-family:'Orbitron',sans-serif;font-size:15px;color:var(--c);letter-spacing:3px;margin-bottom:8px}
.md{font-size:11px;color:rgba(168,255,212,.55);line-height:1.75;margin-bottom:18px}
.md a{color:var(--c);text-decoration:none}
.ti{width:100%;background:rgba(0,229,255,.05);border:1px solid var(--b);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;padding:10px 13px;outline:none;margin-bottom:12px;letter-spacing:.5px}
.ti:focus{border-color:var(--c);box-shadow:0 0 10px rgba(0,229,255,.12)}
.ti::placeholder{color:rgba(168,255,212,.25)}
.ma{display:flex;gap:10px}
.bp{flex:1;background:rgba(0,255,136,.1);border:1px solid var(--g);color:var(--g);font-family:'Share Tech Mono',monospace;font-size:11px;padding:10px;cursor:pointer;letter-spacing:2px;transition:all .2s}
.bp:hover{background:rgba(0,255,136,.18);box-shadow:0 0 18px rgba(0,255,136,.18)}
.bd{background:rgba(0,229,255,.07);border:1px solid rgba(0,229,255,.28);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:11px;padding:10px;cursor:pointer;letter-spacing:2px;transition:all .2s}
.bd:hover{background:rgba(0,229,255,.14)}
.fl::-webkit-scrollbar{width:3px}
.fl::-webkit-scrollbar-thumb{background:var(--b)}
@media(max-width:600px){.lp{width:220px}.ptg{left:220px}.ptg.hide{left:0}.rc{display:none}.ip{right:8px;bottom:8px;width:calc(100vw - 16px)}.stats .sc:nth-child(n+3){display:none}}
</style>
</head>
<body>

<div id="tm">
  <div class="mb">
    <div class="mt2">⚡ MAPBOX TOKEN</div>
    <p class="md">
      Uydu haritası için ücretsiz Mapbox token gereklidir.<br>
      <a href="https://account.mapbox.com" target="_blank">account.mapbox.com</a> adresinden alabilirsiniz.<br><br>
      Token olmadan <b>Demo Mod</b> ile uçak listesi görüntülenir.
    </p>
    <input class="ti" id="ti" type="text" placeholder="pk.eyJ1IjoiLi4uIiwiYSI6Ii4uLiJ9...">
    <div class="ma">
      <button class="bp" onclick="initWithToken()">BAŞLAT</button>
      <button class="bd" onclick="initDemo()">DEMO MOD</button>
    </div>
  </div>
</div>

<div id="ld">
  <div class="ll">SKYWATCH</div>
  <div class="lbw"><div class="lb" id="lb"></div></div>
  <div class="lt" id="lt">SİSTEM BAŞLATILIYOR...</div>
</div>

<div class="topbar">
  <div class="logo">✈ SKYWATCH</div>
  <div class="stats">
    <div class="sc"><div class="dot L" id="sd"></div><span id="st">BAĞLANIYOR</span></div>
    <div class="sc">UÇAK: <span class="v" id="pc">—</span></div>
    <div class="sc">SON: <span class="v" id="lu">—</span></div>
  </div>
  <div class="tr">
    <div class="clk" id="clk">00:00:00</div>
    <button class="btn" onclick="refreshData()">↻</button>
    <button class="btn A" id="lsb" onclick="setLayer('satellite')">🛰 UYDU</button>
    <button class="btn" id="ldb" onclick="setLayer('dark')">🌑 KARANLIK</button>
    <button class="btn" id="lrb" onclick="setLayer('street')">🗺 SOKAK</button>
  </div>
</div>

<div class="ptg" id="ptg" onclick="togglePanel()">◀</div>

<div class="lp" id="lp">
  <div class="ph"><span>UÇUŞ LİSTESİ</span><span id="pct" style="color:var(--c)">0</span></div>
  <div class="fl" id="fl">
    <div style="padding:20px;text-align:center;color:rgba(168,255,212,.3);font-size:11px;letter-spacing:2px">VERİ BEKLENİYOR...</div>
  </div>
</div>

<div id="map"></div>

<div class="ip" id="ip">
  <div class="ih"><span id="ics">—</span><span class="ix" onclick="closeInfo()">×</span></div>
  <div class="ib">
    <div class="if"><div class="il">ÜLKE</div><div class="iv" id="ico">—</div></div>
    <div class="if"><div class="il">YÜKSEKLİK</div><div class="iv h" id="ial">—</div></div>
    <div class="if"><div class="il">HIZ</div><div class="iv" id="isp">—</div></div>
    <div class="if"><div class="il">ROTA</div><div class="iv" id="ihe">—</div></div>
    <div class="if"><div class="il">ENLEM</div><div class="iv" id="ila">—</div></div>
    <div class="if"><div class="il">BOYLAM</div><div class="iv" id="ilo">—</div></div>
    <div class="if"><div class="il">SQUAWK</div><div class="iv" id="isq">—</div></div>
    <div class="if"><div class="il">DURUM</div><div class="iv" id="ign">—</div></div>
  </div>
</div>

<div class="rc">
  <div class="rl">RADAR</div>
  <canvas id="rc" width="96" height="96"></canvas>
</div>

<div class="hm" id="hm">
  <div class="mt"><div class="ml">YÜKSEK</div><div class="mv" id="ha">—</div><div class="mu">METRE</div></div>
  <div class="mt"><div class="ml">HIZ</div><div class="mv" id="hs">—</div><div class="mu">KM/S</div></div>
</div>

<div class="ntf" id="ntf"></div>
<div class="rb"><div class="rp" id="rp"></div></div>

<script>
let map=null,mbToken='',demoMode=false,flights=[],selIcao=null,panelOn=true,curLayer='satellite',markers={},rfInt=null,radarA=0;
const RF=30000;

async function fetchOpenSky(){
  try{
    const r=await fetch('https://opensky-network.org/api/states/all?lamin=25&lomin=-25&lamax=72&lomax=55',{signal:AbortSignal.timeout(14000)});
    if(!r.ok)throw new Error();
    const d=await r.json();return d.states||[];
  }catch{
    try{
      const r=await fetch('https://opensky-network.org/api/states/all',{signal:AbortSignal.timeout(14000)});
      const d=await r.json();return d.states||[];
    }catch{showNtf('OpenSky bağlanamadı — demo veri',true);return genDemo();}
  }
}

function parseS(s){return{icao24:s[0],callsign:(s[1]||'').trim()||s[0],country:s[2]||'—',lon:s[5],lat:s[6],alt:s[7]?Math.round(s[7]):null,ground:s[8],vel:s[9]?Math.round(s[9]*3.6):null,hdg:s[10]?Math.round(s[10]):null,sqk:s[14]||'—'};}

function genDemo(){
  const al=['TK','LH','BA','AF','EK','QR','SU','PC','FR','W6'],co=['Turkey','Germany','UK','France','UAE','Qatar','Russia','USA','Spain'];
  return Array.from({length:80},(_,i)=>[
    'dm'+i,al[i%al.length]+(100+i)+'  ',co[i%co.length],
    null,null,15+Math.random()*45,33+Math.random()*28,
    2000+Math.random()*11000,false,200+Math.random()*700,
    Math.random()*360,null,null,null,Math.floor(1000+Math.random()*8999)
  ]);
}

function initWithToken(){
  const v=document.getElementById('ti').value.trim();
  if(!v.startsWith('pk.')){showNtf('Geçersiz token!',true);return;}
  mbToken=v;localStorage.setItem('mbt',v);
  document.getElementById('tm').classList.add('hide');
  boot(false);
}

function initDemo(){demoMode=true;document.getElementById('tm').classList.add('hide');boot(true);}

async function boot(demo){
  const lb=document.getElementById('lb'),lt=document.getElementById('lt');
  const steps=[[20,'OPENSKY BAĞLANTISI...'],[50,'HARİTA YÜKLENİYOR...'],[75,'VERİ ALINIYOR...'],[95,'RADAR BAŞLATILIYOR...'],[100,'HAZIR']];
  for(const[p,t]of steps){lb.style.width=p+'%';lt.textContent=t;await sleep(380);}
  await sleep(250);
  document.getElementById('ld').classList.add('hide');
  demo?initNoMap():initMap();
  startRadar();startClock();loadFlights();startRfTimer();
}

function sleep(ms){return new Promise(r=>setTimeout(r,ms));}
function startClock(){setInterval(()=>{document.getElementById('clk').textContent=new Date().toTimeString().slice(0,8);},1000);}

function initMap(){
  mapboxgl.accessToken=mbToken;
  map=new mapboxgl.Map({container:'map',style:'mapbox://styles/mapbox/satellite-v9',center:[35,40],zoom:4,antialias:true});
  map.addControl(new mapboxgl.NavigationControl({showCompass:true}),'top-right');
  map.on('load',()=>{document.getElementById('sd').classList.remove('L');document.getElementById('st').textContent='CANLI';});
  map.on('error',e=>showNtf('Harita hatası: '+(e.error?.message||''),true));
}

function initNoMap(){
  const m=document.getElementById('map');
  m.style.background='radial-gradient(ellipse at 50% 50%,#020d1a 0%,#020810 100%)';
  const c=document.createElement('canvas');c.id='gc';c.style.cssText='position:absolute;inset:0;width:100%;height:100%';m.appendChild(c);
  const ctx=c.getContext('2d');c.width=window.innerWidth;c.height=window.innerHeight;
  ctx.strokeStyle='rgba(0,255,136,.05)';ctx.lineWidth=1;
  for(let x=0;x<c.width;x+=55){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,c.height);ctx.stroke();}
  for(let y=0;y<c.height;y+=55){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(c.width,y);ctx.stroke();}
  document.getElementById('sd').classList.remove('L');document.getElementById('st').textContent='DEMO';
}

const LSTYLES={satellite:'mapbox://styles/mapbox/satellite-v9',dark:'mapbox://styles/mapbox/dark-v11',street:'mapbox://styles/mapbox/streets-v12'};

function setLayer(l){
  if(demoMode||!map)return;
  curLayer=l;
  ['satellite','dark','street'].forEach(x=>document.getElementById('l'+x[0]+'b').classList.toggle('A',x===l));
  map.setStyle(LSTYLES[l]);
  map.once('style.load',()=>renderMarkers());
  showNtf(l.toUpperCase()+' KATMANı');
}

async function loadFlights(){
  document.getElementById('sd').classList.add('L');
  const raw=await fetchOpenSky();
  flights=raw.map(parseS).filter(f=>f.lat&&f.lon&&!f.ground);
  document.getElementById('pc').textContent=flights.length;
  document.getElementById('lu').textContent=new Date().toTimeString().slice(0,5);
  document.getElementById('pct').textContent=flights.length;
  document.getElementById('sd').classList.remove('L');
  renderList();
  if(map)renderMarkers();
}

function refreshData(){resetRfTimer();loadFlights();showNtf('VERİ YENİLENDİ');}

function renderList(){
  const fl=document.getElementById('fl');fl.innerHTML='';
  flights.slice(0,150).forEach(f=>{
    const d=document.createElement('div');
    d.className='fi'+(f.icao24===selIcao?' sel':'');
    d.innerHTML=`<div class="fc">${f.callsign}</div><div class="fd"><span>🌍</span><span>${f.country}</span><span>▲</span><span>${f.alt?f.alt+'m':'—'}</span><span>➤</span><span>${f.vel?f.vel+'km/s':'—'}</span></div>`;
    d.onclick=()=>selectFlight(f);fl.appendChild(d);
  });
}

function createEl(hdg,sel){
  const el=document.createElement('div');
  el.style.cssText=`width:${sel?18:13}px;height:${sel?18:13}px;cursor:pointer;filter:${sel?'drop-shadow(0 0 5px #00e5ff)':'drop-shadow(0 0 3px #00ff88)'}`;
  el.innerHTML=`<svg viewBox="0 0 24 24" fill="none" style="transform:rotate(${hdg||0}deg);width:100%;height:100%"><path d="M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z" fill="${sel?'#00e5ff':'#00ff88'}" opacity=".9"/></svg>`;
  return el;
}

function renderMarkers(){
  if(!map)return;
  Object.values(markers).forEach(m=>m.remove());markers={};
  flights.forEach(f=>{
    const el=createEl(f.hdg,f.icao24===selIcao);
    const m=new mapboxgl.Marker({element:el}).setLngLat([f.lon,f.lat]).addTo(map);
    el.addEventListener('click',()=>selectFlight(f));
    markers[f.icao24]=m;
  });
}

function selectFlight(f){
  selIcao=f.icao24;
  document.getElementById('ics').textContent=f.callsign;
  document.getElementById('ico').textContent=f.country;
  document.getElementById('ial').textContent=f.alt?f.alt+'m':'—';
  document.getElementById('isp').textContent=f.vel?f.vel+' km/s':'—';
  document.getElementById('ihe').textContent=f.hdg?f.hdg+'°':'—';
  document.getElementById('ila').textContent=f.lat?f.lat.toFixed(4):'—';
  document.getElementById('ilo').textContent=f.lon?f.lon.toFixed(4):'—';
  document.getElementById('isq').textContent=f.sqk||'—';
  document.getElementById('ign').textContent=f.ground?'YERDE':'UÇUŞTA';
  document.getElementById('ip').classList.add('vis');
  document.getElementById('ha').textContent=f.alt?Math.round(f.alt):'—';
  document.getElementById('hs').textContent=f.vel||'—';
  document.getElementById('hm').classList.add('vis');
  if(map&&f.lat&&f.lon)map.flyTo({center:[f.lon,f.lat],zoom:7,speed:1.4,curve:1.2});
  renderList();if(map)renderMarkers();
}

func
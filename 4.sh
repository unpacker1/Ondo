#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║ SKYWATCH — Termux All-in-One Launcher ║
# ║ Calistir: bash skywatch.sh ║
# ╚══════════════════════════════════════════════════════╝

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'; B='\033[1m'

clear
echo ""
echo -e "${G}${B}"
echo " ███████╗██╗ ██╗██╗ ██╗██╗ ██╗ █████╗ ████████╗ ██████╗██╗ ██╗"
echo " ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║ ██║██╔══██╗╚══██╔══╝██╔════╝██║ ██║"
echo " ███████╗█████╔╝ ╚████╔╝ ██║ █╗ ██║███████║ ██║ ██║ ███████║"
echo " ╚════██║██╔═██╗ ╚██╔╝ ██║███╗██║██╔══██║ ██║ ██║ ██╔══██║"
echo " ███████║██║ ██╗ ██║ ╚███╔███╔╝██║ ██║ ██║ ╚██████╗██║ ██║"
echo " ╚══════╝╚═╝ ╚═╝ ╚═╝ ╚══╝╚══╝ ╚═╝ ╚═╝ ╚═╝ ╚═════╝╚═╝ ╚═╝"
echo -e "${N}"
echo -e " ${C}Canli Ucak Takip — OpenSky + Mapbox Uydu${N}"
echo " ───────────────────────────────────────────"
echo ""

# Python kontrol
if! command -v python3 &>/dev/null &&! command -v python &>/dev/null; then
  echo -e " ${Y}Python yukleniyor...${N}"
  pkg install python -y
fi

PY=$(command -v python3 || command -v python)
TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/skywatch_index.html"

echo -e " ${C}HTML olusturuluyor...${N}"

# HTML dosyasini Python ile yaz (heredoc tirnak sorununu atar)
$PY << 'PYEOF'
import os, sys, json

TMPD = os.environ.get("TMPDIR", "/tmp")
HTML = os.path.join(TMPD, "skywatch_index.html")

# JavaScript kodunu doğrudan Python string'i olarak tanımlamak yerine,
# bir Python string değişkenine atayıp, ardından HTML içine gömmek daha güvenli.
# Bu sayede JavaScript içindeki tırnak, ters slash gibi karakterler sorun yaratmaz.
js_code = """
var map=null,mbToken='',demoMode=false,flights=[],selIcao=null,panelOn=true,markers={},rfInt=null,radarA=0,RF=30000;

async function fetchOpenSky(){
  try{
    var r=await fetch('https://opensky-network.org/api/states/all?lamin=25&lomin=-25&lamax=72&lomax=55',{signal:AbortSignal.timeout(14000)});
    if(!r.ok)throw 0;
    var d=await r.json();return d.states||[];
  }catch(e){
    try{
      var r2=await fetch('https://opensky-network.org/api/states/all',{signal:AbortSignal.timeout(14000)});
      var d2=await r2.json();return d2.states||[];
    }catch(e2){showNtf('OpenSky baglanamiyor - demo veri',true);return genDemo();}
  }
}

function parseS(s){
  return{icao24:s[0],callsign:(s[1]||'').trim()||s[0],country:s[2]||'?',lon:s[5],lat:s[6],
    alt:s[7]?Math.round(s[7]):null,ground:s[8],vel:s[9]?Math.round(s[9]*3.6):null,
    hdg:s[10]?Math.round(s[10]):null,sqk:s[14]||'?'};
}

function genDemo(){
  var al=['TK','LH','BA','AF','EK','QR','SU','PC','FR','W6'],
      co=['Turkey','Germany','UK','France','UAE','Qatar','Russia','USA','Spain'];
  return Array.from({length:80},function(_,i){
    return['dm'+i,al[i%al.length]+(100+i),co[i%co.length],null,null,
      15+Math.random()*45,33+Math.random()*28,2000+Math.random()*11000,
      false,200+Math.random()*700,Math.random()*360,null,null,null,
      Math.floor(1000+Math.random()*8999)];
  });
}

function initWithToken(){
  var v=document.getElementById('ti').value.trim();
  if(!v.startsWith('pk.')){showNtf('Gecersiz token!',true);return;}
  mbToken=v;localStorage.setItem('mbt',v);
  document.getElementById('tm').classList.add('hide');
  boot(false);
}

function initDemo(){demoMode=true;document.getElementById('tm').classList.add('hide');boot(true);}

async function boot(demo){
  var lb=document.getElementById('lb'),lt=document.getElementById('lt');
  var steps=[[20,'OPENSKY BAGLANTISI...'],[50,'HARITA YUKLENIYOR...'],[75,'VERI ALINIYOR...'],[95,'RADAR BASLATILIYOR...'],[100,'HAZIR']];
  for(var i=0;i<steps.length;i++){
    lb.style.width=steps[i][0]+'%';lt.textContent=steps[i][1];
    await new Promise(function(r){setTimeout(r,380);});
  }
  await new Promise(function(r){setTimeout(r,250);});
  document.getElementById('ld').classList.add('hide');
  if(demo)initNoMap();else initMap();
  startRadar();startClock();await loadFlights();startRfTimer();
}

function startClock(){
  setInterval(function(){document.getElementById('clk').textContent=new Date().toTimeString().slice(0,8);},1000);
}

function initMap(){
  mapboxgl.accessToken=mbToken;
  map=new mapboxgl.Map({container:'map',style:'mapbox://styles/mapbox/satellite-v9',center:[35,40],zoom:4,antialias:true});
  map.addControl(new mapboxgl.NavigationControl({showCompass:true}),'top-right');
  map.on('load',function(){document.getElementById('sd').classList.remove('L');document.getElementById('st').textContent='CANLI';});
  map.on('error',function(e){showNtf('Harita hatasi',true);});
}

function initNoMap(){
  var m=document.getElementById('map');
  m.style.background='radial-gradient(ellipse at 50% 50%,#020d1a 0%,#020810 100%)';
  var c=document.createElement('canvas');
  c.style.cssText='position:absolute;inset:0;width:100%;height:100%';
  m.appendChild(c);
  var ctx=c.getContext('2d');c.width=window.innerWidth;c.height=window.innerHeight;
  ctx.strokeStyle='rgba(0,255,136,.05)';ctx.lineWidth=1;
  for(var x=0;x<c.width;x+=55){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,c.height);ctx.stroke();}
  for(var y=0;y<c.height;y+=55){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(c.width,y);ctx.stroke();}
  document.getElementById('sd').classList.remove('L');document.getElementById('st').textContent='DEMO';
}

var LS={satellite:'mapbox://styles/mapbox/satellite-v9',dark:'mapbox://styles/mapbox/dark-v11',street:'mapbox://styles/mapbox/streets-v12'};

function setLayer(l){
  if(demoMode||!map)return;
  ['satellite','dark','street'].forEach(function(x){document.getElementById('l'+x[0]+'b').classList.toggle('A',x===l);});
  map.setStyle(LS[l]);
  map.once('style.load',function(){renderMarkers();});
  showNtf(l.toUpperCase()+' KATMANI');
}

async function loadFlights(){
  document.getElementById('sd').classList.add('L');
  var raw=await fetchOpenSky();
  flights=raw.map(parseS).filter(function(f){return f.lat&&f.lon&&!f.ground;});
  document.getElementById('pc').textContent=flights.length;
  document.getElementById('lu').textContent=new Date().toTimeString().slice(0,5);
  document.getElementById('pct').textContent=flights.length;
  document.getElementById('sd').classList.remove('L');
  renderList();
  if(map)renderMarkers();
  updateHighs();
}

function refreshData(){resetRfTimer();loadFlights();showNtf('VERI YENILENDI');}

function renderList(){
  var fl=document.getElementById('fl');fl.innerHTML='';
  flights.slice(0,150).forEach(function(f){
    var d=document.createElement('div');
    d.className='fi'+(f.icao24===selIcao?' sel':'');
    d.innerHTML='<div class=\"fc\">'+f.callsign+'</div><div class=\"fd\"><span>'+f.country+'</span><span>'+(f.alt?f.alt+'m':'--')+'</span><span>'+(f.vel?f.vel+'km/s':'--')+'</span></div>';
    d.onclick=function(){selectFlight(f);};
    fl.appendChild(d);
  });
}

function createEl(hdg,sel){
  var el=document.createElement('div');
  el.style.cssText='width:'+(sel?18:13)+'px;height:'+(sel?18:13)+'px;cursor:pointer;filter:'+(sel?'drop-shadow(0 0 5px #00e5ff)':'drop-shadow(0 0 3px #00ff88)');
  el.innerHTML='<svg viewBox=\"0 0 24 24\" fill=\"none\" style=\"transform:rotate('+(hdg||0)+'deg);width:100%;height:100%\"><path d=\"M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z\" fill=\"'+(sel?'#00e5ff':'#00ff88')+'\" opacity=\".9\"/></svg>';
  return el;
}

function renderMarkers(){
  if(!map)return;
  Object.values(markers).forEach(function(m){m.remove();});markers={};
  flights.forEach(function(
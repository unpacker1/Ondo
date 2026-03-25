#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  SKYWATCH v2.0 — Ultimate Ucak Takip Sistemi                ║
# ║  Calistir: bash skywatch.sh                                  ║
# ╚══════════════════════════════════════════════════════════════╝
# Ozellikler:
#   • OpenSky gercek zamanli ucak verisi
#   • Mapbox Uydu / Karanlik / Sokak harita
#   • Ucak arama & filtreleme
#   • Hava durumu katmani (OpenWeatherMap)
#   • Ucak detay + ucus gecmisi trail
#   • Istatistik paneli (ulke/hiz dagilimi)
#   • Ses alarmı (yuksek rakimli ucak)
#   • Koordinat ile bolge secimi
#   • Gece/gunduz terminator gosterimi
#   • Tam ekran modu
#   • Klavye kisayollari
#   • Otomatik konum tespiti
#   • 30sn otomatik yenileme + ilerleme cubugu

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'; B='\033[1m'

clear
printf "\n${G}${B}"
printf "  ███████╗██╗  ██╗██╗   ██╗██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗\n"
printf "  ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║\n"
printf "  ███████╗█████╔╝  ╚████╔╝ ██║ █╗ ██║███████║   ██║   ██║     ███████║\n"
printf "  ╚════██║██╔═██╗   ╚██╔╝  ██║███╗██║██╔══██║   ██║   ██║     ██╔══██║\n"
printf "  ███████║██║  ██╗   ██║   ╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║\n"
printf "  ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝\n"
printf "${N}\n"
printf "  ${C}v2.0 Ultimate — OpenSky + Mapbox + Hava Durumu + İstatistik${N}\n"
printf "  ─────────────────────────────────────────────────────────\n\n"

if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
  printf "  ${Y}Python yukleniyor...${N}\n"
  pkg install python -y
fi

PY=$(command -v python3 || command -v python)
TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/skywatch_v2.html"

printf "  ${C}HTML olusturuluyor (v2.0)...${N}\n"

$PY << 'PYEOF'
import os, sys

TMPD = os.environ.get("TMPDIR", "/tmp")
HTML = os.path.join(TMPD, "skywatch_v2.html")

lines = []
def w(s): lines.append(s)

w("<!DOCTYPE html>")
w("<html lang='tr'>")
w("<head>")
w("<meta charset='UTF-8'>")
w("<meta name='viewport' content='width=device-width,initial-scale=1.0'>")
w("<title>SKYWATCH v2</title>")
w("<link href='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css' rel='stylesheet'>")
w("<script src='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js'></script>")
w("<link href='https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;600;900&family=Rajdhani:wght@300;400;600&display=swap' rel='stylesheet'>")
w("<style>")
w(":root{")
w("  --g:#00ff88;--c:#00e5ff;--o:#ff6b35;--warn:#ffcc00;--red:#ff4466;")
w("  --d:#020810;--d2:#030e1a;--p:rgba(2,15,25,0.93);--p2:rgba(3,18,30,0.97);")
w("  --b:rgba(0,255,136,0.22);--b2:rgba(0,229,255,0.18);--t:#a8ffd4;--t2:rgba(168,255,212,0.55)")
w("}")
w("*{margin:0;padding:0;box-sizing:border-box}")
w("html,body{background:var(--d);color:var(--t);font-family:'Share Tech Mono',monospace;overflow:hidden;height:100vh;width:100vw}")
# scanline
w("body::after{content:'';position:fixed;inset:0;background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,255,136,.012) 2px,rgba(0,255,136,.012) 4px);pointer-events:none;z-index:9998}")
# cursor
w("body{cursor:crosshair}")
w("button,a,.fi,.ptg,.ix,.layer-btn,.tab-btn,.close-x{cursor:pointer}")

# MAP
w("#map{position:absolute;top:0;left:0;width:100%;height:100%}")

# TOPBAR
w(".topbar{position:fixed;top:0;left:0;right:0;height:52px;background:var(--p2);border-bottom:1px solid var(--b);display:flex;align-items:center;padding:0 14px;gap:12px;z-index:200;backdrop-filter:blur(16px)}")
w(".logo{font-family:'Orbitron',sans-serif;font-weight:900;font-size:16px;color:var(--g);letter-spacing:5px;text-shadow:0 0 24px rgba(0,255,136,.7);white-space:nowrap;display:flex;align-items:center;gap:8px}")
w(".logo svg{animation:spin3 8s linear infinite;filter:drop-shadow(0 0 6px var(--g))}")
w("@keyframes spin3{0%,100%{transform:rotate(0deg)}50%{transform:rotate(180deg)}}")
w(".ver{font-size:9px;color:rgba(0,255,136,.5);letter-spacing:2px;margin-top:2px}")
w(".stats{display:flex;gap:14px;flex:1;overflow:hidden;align-items:center}")
w(".sc{display:flex;align-items:center;gap:5px;font-size:10px;color:var(--t2);white-space:nowrap}")
w(".sc .v{color:var(--c);font-size:12px;font-family:'Orbitron',sans-serif}")
w(".dot{width:7px;height:7px;border-radius:50%;background:var(--g);box-shadow:0 0 8px var(--g);animation:pulse 1.5s infinite;flex-shrink:0}")
w(".dot.L{background:var(--o);box-shadow:0 0 8px var(--o)}")
w(".dot.E{background:var(--red);box-shadow:0 0 8px var(--red)}")
w("@keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}")
w(".sep{width:1px;height:22px;background:var(--b);flex-shrink:0}")
w(".tr{display:flex;align-items:center;gap:6px;margin-left:auto}")
w(".clk{font-size:13px;color:var(--c);letter-spacing:2px;font-family:'Orbitron',sans-serif}")
w(".btn{background:transparent;border:1px solid var(--b);color:var(--g);font-family:'Share Tech Mono',monospace;font-size:10px;padding:4px 9px;cursor:pointer;letter-spacing:1px;transition:all .2s;white-space:nowrap;position:relative;overflow:hidden}")
w(".btn::before{content:'';position:absolute;top:0;left:-100%;width:100%;height:100%;background:linear-gradient(90deg,transparent,rgba(0,255,136,.12),transparent);transition:left .4s}")
w(".btn:hover::before{left:100%}")
w(".btn:hover,.btn.A{background:rgba(0,255,136,.1);border-color:var(--g);box-shadow:0 0 12px rgba(0,255,136,.25),inset 0 0 8px rgba(0,255,136,.05)}")
w(".btn.warn{border-color:rgba(255,204,0,.4);color:var(--warn)}.btn.warn:hover{background:rgba(255,204,0,.1);border-color:var(--warn)}")
w(".btn.danger{border-color:rgba(255,68,102,.4);color:var(--red)}.btn.danger:hover{background:rgba(255,68,102,.1)}")

# SEARCH BAR
w(".searchbar{position:fixed;top:62px;left:50%;transform:translateX(-50%);z-index:201;display:flex;gap:0;opacity:0;pointer-events:none;transition:opacity .3s}")
w(".searchbar.vis{opacity:1;pointer-events:all}")
w(".search-input{background:var(--p2);border:1px solid var(--b);border-right:none;color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;padding:8px 14px;width:320px;outline:none;letter-spacing:1px}")
w(".search-input:focus{border-color:var(--c);box-shadow:0 0 12px rgba(0,229,255,.2)}")
w(".search-input::placeholder{color:rgba(168,255,212,.25)}")
w(".search-btn{background:rgba(0,229,255,.1);border:1px solid var(--b2);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:11px;padding:8px 14px;cursor:pointer;white-space:nowrap}")
w(".search-btn:hover{background:rgba(0,229,255,.2)}")
w(".search-results{position:absolute;top:100%;left:0;width:100%;background:var(--p2);border:1px solid var(--b);border-top:none;max-height:200px;overflow-y:auto;display:none}")
w(".search-results.vis{display:block}")
w(".sr-item{padding:8px 14px;font-size:11px;cursor:pointer;border-bottom:1px solid rgba(0,255,136,.06);color:var(--t)}")
w(".sr-item:hover{background:rgba(0,255,136,.07);color:var(--g)}")

# LEFT PANEL
w(".lp{position:fixed;top:52px;left:0;bottom:0;width:268px;background:var(--p2);border-right:1px solid var(--b);z-index:190;display:flex;flex-direction:column;transition:transform .35s cubic-bezier(.4,0,.2,1)}")
w(".lp.hide{transform:translateX(-268px)}")
w(".ptg{position:fixed;top:66px;left:268px;width:16px;height:40px;background:var(--p2);border:1px solid var(--b);border-left:none;z-index:191;display:flex;align-items:center;justify-content:center;font-size:10px;color:var(--g);transition:left .35s cubic-bezier(.4,0,.2,1)}")
w(".ptg:hover{background:rgba(0,255,136,.1)}")
w(".ptg.hide{left:0}")

# TABS
w(".tabs{display:flex;border-bottom:1px solid var(--b)}")
w(".tab-btn{flex:1;padding:9px 0;font-family:'Share Tech Mono',monospace;font-size:10px;letter-spacing:2px;color:var(--t2);background:transparent;border:none;cursor:pointer;transition:all .2s;text-transform:uppercase}")
w(".tab-btn.A{color:var(--g);border-bottom:2px solid var(--g);background:rgba(0,255,136,.05)}")
w(".tab-btn:hover:not(.A){color:var(--t);background:rgba(0,255,136,.04)}")
w(".tab-panel{display:none;flex:1;overflow-y:auto;scrollbar-width:thin;scrollbar-color:var(--b) transparent}")
w(".tab-panel.A{display:flex;flex-direction:column}")
w(".tab-panel::-webkit-scrollbar{width:3px}")
w(".tab-panel::-webkit-scrollbar-thumb{background:var(--b)}")

# FILTER BAR
w(".filter-bar{padding:8px 10px;border-bottom:1px solid rgba(0,255,136,.08);display:flex;gap:6px;flex-wrap:wrap}")
w(".filter-chip{font-size:9px;padding:3px 8px;border:1px solid var(--b);color:var(--t2);background:transparent;cursor:pointer;letter-spacing:1px;font-family:'Share Tech Mono',monospace;transition:all .2s}")
w(".filter-chip.A{background:rgba(0,229,255,.1);border-color:var(--c);color:var(--c)}")
w(".filter-chip:hover{border-color:var(--g);color:var(--g)}")

# FLIGHT LIST
w(".fi{padding:9px 12px;border-bottom:1px solid rgba(0,255,136,.06);cursor:pointer;transition:background .15s;position:relative}")
w(".fi::before{content:'';position:absolute;left:0;top:0;bottom:0;width:2px;background:var(--g);opacity:0;transition:opacity .2s}")
w(".fi:hover::before,.fi.sel::before{opacity:1}")
w(".fi:hover,.fi.sel{background:rgba(0,255,136,.07)}")
w(".fi.sel{background:rgba(0,229,255,.06)}")
w(".fi.sel::before{background:var(--c)}")
w(".fc{font-family:'Orbitron',sans-serif;font-size:11px;color:var(--c);letter-spacing:1px;display:flex;align-items:center;gap:6px}")
w(".fi-flag{font-size:12px}")
w(".fi-alt-bar{height:2px;background:rgba(0,255,136,.12);margin-top:5px;border-radius:1px;overflow:hidden}")
w(".fi-alt-fill{height:100%;background:linear-gradient(90deg,var(--g),var(--c));transition:width .5s}")
w(".fd{font-size:9px;color:rgba(168,255,212,.5);display:flex;gap:8px;margin-top:3px;flex-wrap:wrap}")
w(".fv{color:var(--t)}")

# STATS PANEL
w(".stat-section{padding:12px;border-bottom:1px solid rgba(0,255,136,.07)}")
w(".stat-title{font-size:9px;color:rgba(168,255,212,.4);letter-spacing:3px;text-transform:uppercase;margin-bottom:8px}")
w(".stat-row{display:flex;align-items:center;gap:8px;margin-bottom:5px}")
w(".stat-label{font-size:10px;color:var(--t2);flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}")
w(".stat-bar-wrap{width:80px;height:4px;background:rgba(0,255,136,.1);flex-shrink:0}")
w(".stat-bar{height:100%;background:var(--g);transition:width .8s ease}")
w(".stat-val{font-size:10px;color:var(--g);width:28px;text-align:right;flex-shrink:0}")
w(".big-stat{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:10px}")
w(".bs-item{background:rgba(0,255,136,.05);border:1px solid rgba(0,255,136,.12);padding:8px 10px}")
w(".bs-val{font-family:'Orbitron',sans-serif;font-size:18px;color:var(--c)}")
w(".bs-label{font-size:8px;color:var(--t2);letter-spacing:2px;margin-top:2px;text-transform:uppercase}")

# ALERTS PANEL
w(".alert-item{padding:9px 12px;border-bottom:1px solid rgba(255,68,102,.1);display:flex;gap:8px;align-items:flex-start}")
w(".alert-dot{width:6px;height:6px;border-radius:50%;flex-shrink:0;margin-top:4px}")
w(".alert-dot.high{background:var(--warn);box-shadow:0 0 6px var(--warn)}")
w(".alert-dot.low{background:var(--c);box-shadow:0 0 6px var(--c)}")
w(".alert-text{font-size:10px;color:var(--t)}")
w(".alert-time{font-size:9px;color:var(--t2);margin-top:2px}")
w(".no-alerts{padding:20px;text-align:center;font-size:11px;color:rgba(168,255,212,.25);letter-spacing:2px}")

# PANEL TOGGLE BUTTON (right toggle)
w(".ptg{cursor:pointer}")

# INFO PANEL
w(".ip{position:fixed;bottom:16px;right:16px;width:300px;background:var(--p2);border:1px solid var(--b2);z-index:190;display:none;box-shadow:0 0 30px rgba(0,229,255,.08)}")
w(".ip.vis{display:block;animation:slideIn .25s ease}")
w("@keyframes slideIn{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}")
w(".ih{padding:10px 13px;background:rgba(0,229,255,.06);border-bottom:1px solid var(--b2);font-family:'Orbitron',sans-serif;font-size:12px;color:var(--c);letter-spacing:2px;display:flex;justify-content:space-between;align-items:center}")
w(".ih-actions{display:flex;gap:8px;align-items:center}")
w(".ix{color:rgba(168,255,212,.4);font-size:16px;transition:color .2s}")
w(".ix:hover{color:var(--red)}")
w(".trail-btn{font-size:9px;padding:2px 7px;border:1px solid rgba(0,229,255,.3);color:var(--c);background:transparent;cursor:pointer;letter-spacing:1px;font-family:'Share Tech Mono',monospace;transition:all .2s}")
w(".trail-btn:hover,.trail-btn.A{background:rgba(0,229,255,.1);border-color:var(--c)}")
w(".ib{padding:10px 13px;display:grid;grid-template-columns:1fr 1fr;gap:8px}")
w(".ifd{display:flex;flex-direction:column;gap:2px}")
w(".il{font-size:8px;color:rgba(168,255,212,.38);letter-spacing:2px;text-transform:uppercase}")
w(".iv{font-size:12px;color:var(--g);font-family:'Orbitron',sans-serif}")
w(".iv.h{color:var(--c)}")
w(".iv.warn-val{color:var(--warn)}")
w(".speed-gauge{padding:0 13px 10px;display:flex;align-items:center;gap:10px}")
w(".gauge-track{flex:1;height:4px;background:rgba(0,255,136,.12);border-radius:2px;overflow:hidden}")
w(".gauge-fill{height:100%;background:linear-gradient(90deg,var(--g),var(--c),var(--warn));transition:width .5s ease}")
w(".gauge-label{font-size:9px;color:var(--t2);white-space:nowrap}")
w(".info-actions{padding:0 13px 10px;display:flex;gap:6px}")
w(".ia-btn{flex:1;font-size:9px;padding:5px;border:1px solid var(--b);color:var(--t2);background:transparent;cursor:pointer;letter-spacing:1px;font-family:'Share Tech Mono',monospace;transition:all .2s;text-align:center}")
w(".ia-btn:hover{color:var(--g);border-color:var(--g);background:rgba(0,255,136,.06)}")

# RADAR
w(".rc{position:fixed;bottom:16px;left:16px;z-index:190;background:var(--p2);border:1px solid var(--b);padding:8px;box-shadow:0 0 20px rgba(0,255,136,.06)}")
w(".rl{font-size:8px;color:rgba(168,255,212,.35);letter-spacing:2px;margin-bottom:5px;text-transform:uppercase;display:flex;justify-content:space-between;align-items:center}")
w(".radar-count{color:var(--g);font-family:'Orbitron',sans-serif}")

# HUD METERS
w(".hm{position:fixed;top:50%;right:16px;transform:translateY(-50%);z-index:190;display:flex;flex-direction:column;gap:6px;opacity:0;transition:opacity .3s;pointer-events:none}")
w(".hm.vis{opacity:1}")
w(".mt{background:var(--p2);border:1px solid var(--b);padding:8px 10px;width:80px;position:relative;overflow:hidden}")
w(".mt::after{content:'';position:absolute;top:0;left:0;right:0;height:1px;background:linear-gradient(90deg,transparent,var(--g),transparent);animation:scan 2s linear infinite}")
w("@keyframes scan{0%{transform:translateY(0)}100%{transform:translateY(60px)}}")
w(".mla{font-size:7px;color:rgba(168,255,212,.35);letter-spacing:2px;text-transform:uppercase;margin-bottom:2px}")
w(".mv{font-family:'Orbitron',sans-serif;font-size:15px;color:var(--c);line-height:1}")
w(".mu{font-size:7px;color:rgba(168,255,212,.4);margin-top:2px}")

# NOTIFICATION
w(".ntf{position:fixed;top:64px;right:16px;background:var(--p2);border:1px solid var(--b);padding:8px 14px;font-size:10px;color:var(--c);z-index:999;transform:translateX(130%);transition:transform .3s cubic-bezier(.4,0,.2,1);letter-spacing:1px;display:flex;align-items:center;gap:8px;max-width:280px}")
w(".ntf.sh{transform:translateX(0)}")
w(".ntf.er{color:var(--o);border-color:rgba(255,107,53,.4)}")
w(".ntf.warn{color:var(--warn);border-color:rgba(255,204,0,.4)}")
w(".ntf-icon{flex-shrink:0}")

# REFRESH BAR
w(".rb{position:fixed;bottom:0;left:0;right:0;height:2px;background:rgba(0,255,136,.06);z-index:999}")
w(".rp{height:100%;background:linear-gradient(90deg,var(--g),var(--c));box-shadow:0 0 6px var(--g);width:100%;transition:width linear}")

# LAYER PANEL (right side)
w(".layer-panel{position:fixed;top:52px;right:0;z-index:190;display:flex;flex-direction:column;gap:4px;padding:8px 6px}")
w(".layer-btn{background:var(--p2);border:1px solid var(--b);color:var(--t2);font-family:'Share Tech Mono',monospace;font-size:9px;padding:6px 10px;cursor:pointer;letter-spacing:1px;text-align:center;transition:all .2s;width:82px}")
w(".layer-btn:hover,.layer-btn.A{color:var(--g);border-color:var(--g);background:rgba(0,255,136,.07)}")
w(".layer-sep{height:1px;background:var(--b);margin:2px 0}")

# KEYBOARD SHORTCUTS OVERLAY
w(".kb-overlay{position:fixed;inset:0;background:rgba(2,8,16,.96);z-index:9000;display:none;align-items:center;justify-content:center;backdrop-filter:blur(8px)}")
w(".kb-overlay.vis{display:flex}")
w(".kb-box{background:var(--p2);border:1px solid var(--b);padding:30px;width:480px;max-width:95vw}")
w(".kb-title{font-family:'Orbitron',sans-serif;font-size:14px;color:var(--g);letter-spacing:4px;margin-bottom:20px;display:flex;justify-content:space-between}")
w(".kb-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}")
w(".kb-row{display:flex;align-items:center;gap:10px;padding:5px 0;border-bottom:1px solid rgba(0,255,136,.06)}")
w(".kb-key{background:rgba(0,255,136,.08);border:1px solid var(--b);padding:2px 8px;font-size:10px;color:var(--g);font-family:'Orbitron',sans-serif;min-width:30px;text-align:center}")
w(".kb-desc{font-size:10px;color:var(--t2)}")

# LOADING
w("#ld{position:fixed;inset:0;background:var(--d);z-index:9001;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;transition:opacity .6s}")
w("#ld.hide{opacity:0;pointer-events:none}")
w(".ll{font-family:'Orbitron',sans-serif;font-size:32px;font-weight:900;color:var(--g);letter-spacing:8px;animation:glow 2.5s infinite}")
w(".lsub{font-size:11px;color:var(--t2);letter-spacing:4px;margin-top:-8px}")
w("@keyframes glow{0%,100%{text-shadow:0 0 20px rgba(0,255,136,.3),0 0 40px rgba(0,255,136,.1)}50%{text-shadow:0 0 40px rgba(0,255,136,.8),0 0 80px rgba(0,255,136,.3),0 0 120px rgba(0,255,136,.1)}}")
w(".lbw{width:260px;height:2px;background:rgba(0,255,136,.1);overflow:hidden}")
w(".lb{height:100%;background:linear-gradient(90deg,var(--g),var(--c));width:0%;transition:width .4s ease}")
w(".lt{font-size:10px;color:rgba(168,255,212,.4);letter-spacing:3px;text-transform:uppercase}")
w(".l-particles{position:absolute;inset:0;pointer-events:none}")

# TOKEN MODAL
w("#tm{position:fixed;inset:0;background:rgba(2,8,16,.97);z-index:9002;display:flex;align-items:center;justify-content:center;backdrop-filter:blur(6px)}")
w("#tm.hide{display:none}")
w(".mb{background:var(--p2);border:1px solid var(--b);padding:30px;width:460px;max-width:95vw;position:relative}")
w(".mb::before{content:'SKYWATCH';position:absolute;top:-12px;left:20px;background:var(--p2);padding:0 10px;font-family:'Orbitron',sans-serif;font-size:10px;color:var(--g);letter-spacing:4px}")
w(".mt2{font-family:'Orbitron',sans-serif;font-size:14px;color:var(--c);letter-spacing:3px;margin-bottom:6px}")
w(".md{font-size:11px;color:var(--t2);line-height:1.8;margin-bottom:18px}")
w(".md a{color:var(--c);text-decoration:none}")
w(".md a:hover{text-decoration:underline}")
w(".ti{width:100%;background:rgba(0,229,255,.04);border:1px solid var(--b2);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;padding:10px 13px;outline:none;margin-bottom:10px;letter-spacing:.5px;transition:border .2s}")
w(".ti:focus{border-color:var(--c);box-shadow:0 0 12px rgba(0,229,255,.12)}")
w(".ti::placeholder{color:rgba(168,255,212,.2)}")
w(".ma{display:flex;gap:8px}")
w(".bp{flex:1;background:rgba(0,255,136,.08);border:1px solid var(--g);color:var(--g);font-family:'Share Tech Mono',monospace;font-size:11px;padding:10px;cursor:pointer;letter-spacing:2px;transition:all .25s}")
w(".bp:hover{background:rgba(0,255,136,.18);box-shadow:0 0 20px rgba(0,255,136,.2)}")
w(".bd{background:rgba(0,229,255,.06);border:1px solid rgba(0,229,255,.25);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:11px;padding:10px;cursor:pointer;letter-spacing:2px;transition:all .25s}")
w(".bd:hover{background:rgba(0,229,255,.14)}")
w(".token-hint{font-size:9px;color:rgba(168,255,212,.3);letter-spacing:1px;margin-bottom:8px}")

# WEATHER TOOLTIP
w(".wx-popup{background:var(--p2);border:1px solid rgba(255,204,0,.3);padding:10px 14px;font-size:11px;color:var(--warn);min-width:160px}")
w(".wx-name{font-family:'Orbitron',sans-serif;font-size:12px;margin-bottom:6px}")
w(".wx-row{display:flex;justify-content:space-between;font-size:10px;color:var(--t2);margin-bottom:3px}")
w(".wx-row span{color:var(--t)}")

# COMPASS
w(".compass{position:fixed;top:62px;right:96px;z-index:190;width:48px;height:48px}")
w("canvas#comp{display:block}")

# MAPBOX OVERRIDES
w(".mapboxgl-ctrl-bottom-left,.mapboxgl-ctrl-bottom-right{display:none!important}")
w(".mapboxgl-popup-content{background:var(--p2)!important;border:1px solid var(--b)!important;color:var(--t)!important;font-family:'Share Tech Mono',monospace!important;font-size:10px!important;padding:10px 13px!important;border-radius:0!important;box-shadow:0 0 20px rgba(0,255,136,.1)!important}")
w(".mapboxgl-popup-tip{display:none!important}")
w(".mapboxgl-ctrl-top-right{top:52px!important;right:94px!important}")

w("@media(max-width:600px){.lp{width:240px}.ptg{left:240px}.ptg.hide{left:0}.rc{display:none}.ip{right:8px;bottom:8px;width:calc(100vw - 16px)}.stats .sc:nth-child(n+4){display:none}.layer-panel{display:none}}")
w("</style>")
w("</head>")
w("<body>")

# TOKEN MODAL
w("<div id='tm'>")
w("  <div class='mb'>")
w("    <div class='mt2'>MAPBOX TOKEN GEREKLi</div>")
w("    <p class='md'>")
w("      Uydu haritasi icin ucretsiz Mapbox token gereklidir.<br>")
w("      <a href='https://account.mapbox.com' target='_blank'>account.mapbox.com</a> adresinden alin.<br><br>")
w("      Token olmadan <b>Demo Mod</b> ile ucak listesi ve radar aktif olur.")
w("    </p>")
w("    <div class='token-hint'>ORNEK: pk.eyJ1IjoiuXXX...XXXX</div>")
w("    <input class='ti' id='ti' type='text' placeholder='pk.eyJ1IjoiLi4uIiwiYSI6Ii4uLiJ9...'>")
w("    <div class='ma'>")
w("      <button class='bp' onclick='initWithToken()'>BASLAT</button>")
w("      <button class='bd' onclick='initDemo()'>DEMO MOD</button>")
w("    </div>")
w("  </div>")
w("</div>")

# LOADING
w("<div id='ld'>")
w("  <canvas class='l-particles' id='lpc' width='400' height='400'></canvas>")
w("  <div class='ll'>SKYWATCH</div>")
w("  <div class='lsub'>UCAK TAKiP SiSTEMi v2.0</div>")
w("  <div class='lbw'><div class='lb' id='lb'></div></div>")
w("  <div class='lt' id='lt'>SiSTEM BASlATILIYOR...</div>")
w("</div>")

# KEYBOARD SHORTCUTS OVERLAY
w("<div class='kb-overlay' id='kbo'>")
w("  <div class='kb-box'>")
w("    <div class='kb-title'>KLAVYE KiSAYOLLARI <span onclick='toggleKb()' style='cursor:pointer;color:var(--o)'>&#215;</span></div>")
w("    <div class='kb-grid'>")
for k,d in [("F","ARAMA AC/KAPAT"),("R","VERi YENiLE"),("L","PANEL AC/KAPAT"),("S","UYDU KATMAN"),("D","KARANLIK KATMAN"),("T","SOKAK KATMAN"),("H","HAVA DURUMU"),("A","TUM UCAKLAR"),("C","KONUM MERKEZLE"),("ESC","SECiM KALDIR"),("?","BU YARDIM"),("F11","TAM EKRAN")]:
    w("      <div class='kb-row'><div class='kb-key'>%s</div><div class='kb-desc'>%s</div></div>" % (k,d))
w("    </div>")
w("  </div>")
w("</div>")

# TOPBAR
w("<div class='topbar'>")
w("  <div class='logo'>")
w("    <svg width='20' height='20' viewBox='0 0 24 24' fill='none'><path d='M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z' fill='#00ff88'/></svg>")
w("    SKYWATCH<div class='ver'>v2.0</div>")
w("  </div>")
w("  <div class='sep'></div>")
w("  <div class='stats'>")
w("    <div class='sc'><div class='dot L' id='sd'></div><span id='st'>BAGLANIYOR</span></div>")
w("    <div class='sc'>&#9992; <span class='v' id='pc'>0</span></div>")
w("    <div class='sc'>ULKE: <span class='v' id='uc'>0</span></div>")
w("    <div class='sc'>MAX: <span class='v' id='mx'>0</span>m</div>")
w("    <div class='sc'>SON: <span class='v' id='lu'>--:--</span></div>")
w("  </div>")
w("  <div class='tr'>")
w("    <div class='clk' id='clk'>00:00:00</div>")
w("    <button class='btn' onclick='toggleSearch()' title='Ara (F)'>&#128269;</button>")
w("    <button class='btn' onclick='refreshData()' title='Yenile (R)'>&#8635;</button>")
w("    <button class='btn' onclick='centerOnMe()' title='Konumum (C)'>&#11168;</button>")
w("    <button class='btn' id='wxb' onclick='toggleWeather()' title='Hava Durumu (H)'>&#9928;</button>")
w("    <button class='btn' onclick='toggleKb()' title='Yardim (?)'>?</button>")
w("    <button class='btn' onclick='toggleFullscreen()' title='Tam Ekran (F11)'>&#9974;</button>")
w("  </div>")
w("</div>")

# SEARCH BAR
w("<div class='searchbar' id='sb'>")
w("  <div style='position:relative;width:100%'>")
w("    <input class='search-input' id='si' placeholder='Ucak ara: callsign, ulke, ICAO...' oninput='doSearch(this.value)'>")
w("    <div class='search-results' id='sr'></div>")
w("  </div>")
w("  <button class='search-btn' onclick='toggleSearch()'>KAPAT</button>")
w("</div>")

# PANEL TOGGLE
w("<div class='ptg' id='ptg' onclick='togglePanel()'>&#9664;</div>")

# LEFT PANEL
w("<div class='lp' id='lp'>")
w("  <div class='tabs'>")
w("    <button class='tab-btn A' id='tab0' onclick='showTab(0)'>UCUSLAR</button>")
w("    <button class='tab-btn' id='tab1' onclick='showTab(1)'>iSTAT</button>")
w("    <button class='tab-btn' id='tab2' onclick='showTab(2)'>ALARM</button>")
w("  </div>")

# TAB 0: FLIGHTS
w("  <div class='tab-panel A' id='tp0'>")
w("    <div class='filter-bar'>")
w("      <button class='filter-chip A' id='fc-all' onclick='setFilter(\"all\")'>TUMU</button>")
w("      <button class='filter-chip' id='fc-high' onclick='setFilter(\"high\")'>Y.ALT</button>")
w("      <button class='filter-chip' id='fc-fast' onclick='setFilter(\"fast\")'>HIZ</button>")
w("      <button class='filter-chip' id='fc-tr' onclick='setFilter(\"tr\")'>TR</button>")
w("    </div>")
w("    <div style='padding:4px 10px;font-size:9px;color:var(--t2);letter-spacing:1px;border-bottom:1px solid rgba(0,255,136,.05)'><span id='fl-count'>0</span> UCAK LISTELENDI</div>")
w("    <div class='tab-panel A' id='fl' style='flex:1'><div style='padding:20px;text-align:center;color:rgba(168,255,212,.25);font-size:11px;letter-spacing:2px'>VERI BEKLENIYOR...</div></div>")
w("  </div>")

# TAB 1: STATS
w("  <div class='tab-panel' id='tp1'>")
w("    <div class='stat-section'>")
w("      <div class='stat-title'>OZET iSTATiSTiKLER</div>")
w("      <div class='big-stat' id='big-stat'>")
w("        <div class='bs-item'><div class='bs-val' id='bs-total'>0</div><div class='bs-label'>TOPLAM</div></div>")
w("        <div class='bs-item'><div class='bs-val' id='bs-countries'>0</div><div class='bs-label'>ULKE</div></div>")
w("        <div class='bs-item'><div class='bs-val' id='bs-avg-alt'>0</div><div class='bs-label'>ORT.YUK(m)</div></div>")
w("        <div class='bs-item'><div class='bs-val' id='bs-avg-spd'>0</div><div class='bs-label'>ORT.HIZ</div></div>")
w("      </div>")
w("    </div>")
w("    <div class='stat-section'>")
w("      <div class='stat-title'>EN FAZLA UCAK (ULKE)</div>")
w("      <div id='stat-countries'></div>")
w("    </div>")
w("    <div class='stat-section'>")
w("      <div class='stat-title'>HIZ DAGILIMI</div>")
w("      <div id='stat-speeds'></div>")
w("    </div>")
w("    <div class='stat-section'>")
w("      <div class='stat-title'>YUKSEKLIK DAGILIMI</div>")
w("      <div id='stat-alts'></div>")
w("    </div>")
w("  </div>")

# TAB 2: ALERTS
w("  <div class='tab-panel' id='tp2'>")
w("    <div style='padding:8px 12px;border-bottom:1px solid rgba(0,255,136,.07);font-size:9px;color:var(--t2);letter-spacing:2px;display:flex;justify-content:space-between;align-items:center'>")
w("      <span>ALARMLAR</span><button class='filter-chip' onclick='clearAlerts()' style='font-size:8px;padding:2px 6px'>TEMIZLE</button>")
w("    </div>")
w("    <div id='alert-list'><div class='no-alerts'>ALARM YOK</div></div>")
w("  </div>")
w("</div>")

# MAP
w("<div id='map'></div>")

# LAYER PANEL
w("<div class='layer-panel'>")
w("  <button class='layer-btn A' id='lsb' onclick='setLayer(\"satellite\")'>&#128752; UYDU</button>")
w("  <button class='layer-btn' id='ldb' onclick='setLayer(\"dark\")'>&#127769; KARANLIK</button>")
w("  <button class='layer-btn' id='lrb' onclick='setLayer(\"street\")'>&#128506; SOKAK</button>")
w("  <div class='layer-sep'></div>")
w("  <button class='layer-btn' id='trmb' onclick='toggleTerminator()'>&#9788; GECE</button>")
w("  <button class='layer-btn' id='trafb' onclick='toggleTraffic()'>&#9992; iZ</button>")
w("</div>")

# COMPASS
w("<div class='compass' id='compass-wrap'>")
w("  <canvas id='comp' width='48' height='48'></canvas>")
w("</div>")

# INFO PANEL
w("<div class='ip' id='ip'>")
w("  <div class='ih'>")
w("    <span id='ics'>---</span>")
w("    <div class='ih-actions'>")
w("      <button class='trail-btn' id='trail-btn' onclick='toggleTrailForSelected()'>iZ</button>")
w("      <span class='ix' onclick='closeInfo()'>&#215;</span>")
w("    </div>")
w("  </div>")
w("  <div class='ib'>")
w("    <div class='ifd'><div class='il'>ULKE</div><div class='iv' id='ico'>---</div></div>")
w("    <div class='ifd'><div class='il'>YUKSEKLIK</div><div class='iv h' id='ial'>---</div></div>")
w("    <div class='ifd'><div class='il'>HIZ</div><div class='iv' id='isp'>---</div></div>")
w("    <div class='ifd'><div class='il'>ROTA</div><div class='iv' id='ihe'>---</div></div>")
w("    <div class='ifd'><div class='il'>ENLEM</div><div class='iv' id='ila'>---</div></div>")
w("    <div class='ifd'><div class='il'>BOYLAM</div><div class='iv' id='ilo'>---</div></div>")
w("    <div class='ifd'><div class='il'>SQUAWK</div><div class='iv' id='isq'>---</div></div>")
w("    <div class='ifd'><div class='il'>DURUM</div><div class='iv' id='ign'>---</div></div>")
w("    <div class='ifd'><div class='il'>ICAO24</div><div class='iv' style='font-size:9px;letter-spacing:1px' id='iic'>---</div></div>")
w("    <div class='ifd'><div class='il'>ALARM</div><div class='iv' id='ialm'>---</div></div>")
w("  </div>")
w("  <div class='speed-gauge'>")
w("    <div class='gauge-label'>0</div>")
w("    <div class='gauge-track'><div class='gauge-fill' id='spd-gauge' style='width:0%'></div></div>")
w("    <div class='gauge-label'>1200</div>")
w("  </div>")
w("  <div class='info-actions'>")
w("    <button class='ia-btn' onclick='flyToSelected()'>&#9992; GIT</button>")
w("    <button class='ia-btn' onclick='copyCoords()'>&#128203; KOORD</button>")
w("    <button class='ia-btn' onclick='openFlightawareSelected()'>&#127760; FA</button>")
w("  </div>")
w("</div>")

# RADAR
w("<div class='rc'>")
w("  <div class='rl'>RADAR <span class='radar-count' id='rcount'>0</span></div>")
w("  <canvas id='rv' width='100' height='100'></canvas>")
w("</div>")

# HUD METERS
w("<div class='hm' id='hm'>")
w("  <div class='mt'><div class='mla'>YUKSEK</div><div class='mv' id='ha'>---</div><div class='mu'>METRE</div></div>")
w("  <div class='mt'><div class='mla'>HIZ</div><div class='mv' id='hs'>---</div><div class='mu'>KM/S</div></div>")
w("  <div class='mt'><div class='mla'>ROTA</div><div class='mv' id='hr'>---</div><div class='mu'>DEG</div></div>")
w("</div>")

# NOTIFICATION
w("<div class='ntf' id='ntf'><span class='ntf-icon' id='ntf-icon'>i</span><span id='ntf-msg'></span></div>")
w("<div class='rb'><div class='rp' id='rp'></div></div>")

# JAVASCRIPT
w("<script>")
w("var map=null,mbToken='',demoMode=false,flights=[],selIcao=null,panelOn=true,markers={},rfInt=null,radarA=0,RF=30000;")
w("var flightFilter='all',searchVisible=false,trailEnabled={},trailData={},alerts=[],weatherOn=false,terminatorOn=false;")
w("var curLayer='satellite',kbVisible=false;")
w("var countryFlags={'Turkey':'TR','Germany':'DE','United Kingdom':'GB','France':'FR','United States':'US','Spain':'ES','Italy':'IT','Netherlands':'NL','Russia':'RU','United Arab Emirates':'AE','Qatar':'QA','Saudi Arabia':'SA','China':'CN','Japan':'JP','Australia':'AU','Canada':'CA','Brazil':'BR','India':'IN','South Korea':'KR','Switzerland':'CH'};")
w("function getFlag(country){var code=countryFlags[country];if(!code)return '';var base=127397;return code.split('').map(function(c){return String.fromCodePoint(base+c.charCodeAt(0));}).join('');}")

# OPENSKY
w("async function fetchOpenSky(){")
w("  try{")
w("    var r=await fetch('https://opensky-network.org/api/states/all?lamin=25&lomin=-20&lamax=72&lomax=55',{signal:AbortSignal.timeout(14000)});")
w("    if(!r.ok)throw 0;")
w("    var d=await r.json();return d.states||[];")
w("  }catch(e){")
w("    try{")
w("      var r2=await fetch('https://opensky-network.org/api/states/all',{signal:AbortSignal.timeout(14000)});")
w("      var d2=await r2.json();return d2.states||[];")
w("    }catch(e2){showNtf('OpenSky baglanamiyor - demo veri','warn');return genDemo();}")
w("  }")
w("}")

w("function parseS(s){")
w("  return{icao24:s[0]||'',callsign:(s[1]||'').trim()||s[0],country:s[2]||'?',lon:s[5],lat:s[6],")
w("    alt:s[7]?Math.round(s[7]):null,baro:s[13]?Math.round(s[13]):null,ground:s[8],vel:s[9]?Math.round(s[9]*3.6):null,")
w("    hdg:s[10]?Math.round(s[10]):null,sqk:s[14]||'?',vs:s[11]?Math.round(s[11]):0};")
w("}")

w("function genDemo(){")
w("  var al=['TK','LH','BA','AF','EK','QR','SU','PC','FR','W6','DLH','THY','SAS','KLM','IBE'],")
w("      co=['Turkey','Germany','United Kingdom','France','United Arab Emirates','Qatar','Russia','United States','Spain','Netherlands'];")
w("  return Array.from({length:100},function(_,i){")
w("    return['dm'+i,al[i%al.length]+(100+i),co[i%co.length],null,null,")
w("      10+Math.random()*50,30+Math.random()*32,1500+Math.random()*12000,")
w("      false,150+Math.random()*750,Math.random()*360,Math.random()*10-5,null,")
w("      1500+Math.random()*11000,Math.floor(1000+Math.random()*8999)];")
w("  });")
w("}")

# INIT
w("function initWithToken(){")
w("  var v=document.getElementById('ti').value.trim();")
w("  if(!v.startsWith('pk.')){showNtf('Gecersiz token! pk. ile baslamali','err');return;}")
w("  mbToken=v;localStorage.setItem('mbt',v);")
w("  document.getElementById('tm').classList.add('hide');")
w("  boot(false);")
w("}")
w("function initDemo(){demoMode=true;document.getElementById('tm').classList.add('hide');boot(true);}")

# BOOT with particles
w("async function boot(demo){")
w("  startLoadParticles();")
w("  var lb=document.getElementById('lb'),lt=document.getElementById('lt');")
w("  var steps=[[15,'OPENSKY BAGLANTISI...'],[35,'HARITA YUKLENiYOR...'],[55,'UCAK VERiSi ALINIYOR...'],[75,'RADAR BASlATILIYOR...'],[90,'iSTATiSTiK HESAPLANiYOR...'],[100,'HAZIR']];")
w("  for(var i=0;i<steps.length;i++){lb.style.width=steps[i][0]+'%';lt.textContent=steps[i][1];await sleep(320);}")
w("  await sleep(200);")
w("  document.getElementById('ld').classList.add('hide');")
w("  if(demo)initNoMap();else initMap();")
w("  startRadar();startClock();startCompass();loadFlights();startRfTimer();setupKeyboard();")
w("}")
w("function sleep(ms){return new Promise(function(r){setTimeout(r,ms);});}")

# LOAD PARTICLES
w("function startLoadParticles(){")
w("  var c=document.getElementById('lpc'),ctx=c.getContext('2d');")
w("  c.width=window.innerWidth;c.height=window.innerHeight;")
w("  var pts=Array.from({length:60},function(){return{x:Math.random()*c.width,y:Math.random()*c.height,vx:(Math.random()-.5)*.5,vy:(Math.random()-.5)*.5,a:Math.random()};});")
w("  function draw(){")
w("    ctx.clearRect(0,0,c.width,c.height);")
w("    pts.forEach(function(p){")
w("      p.x+=p.vx;p.y+=p.vy;p.a=Math.sin(Date.now()/1000+p.x)*.5+.5;")
w("      if(p.x<0||p.x>c.width)p.vx*=-1;if(p.y<0||p.y>c.height)p.vy*=-1;")
w("      ctx.beginPath();ctx.arc(p.x,p.y,1.2,0,Math.PI*2);ctx.fillStyle='rgba(0,255,136,'+p.a*.4+')';ctx.fill();")
w("    });")
w("    if(!document.getElementById('ld').classList.contains('hide'))requestAnimationFrame(draw);")
w("  }draw();")
w("}")

w("function startClock(){setInterval(function(){document.getElementById('clk').textContent=new Date().toTimeString().slice(0,8);},1000);}")

# MAP INIT
w("function initMap(){")
w("  mapboxgl.accessToken=mbToken;")
w("  map=new mapboxgl.Map({container:'map',style:'mapbox://styles/mapbox/satellite-v9',center:[35,40],zoom:4,antialias:true,fog:{color:'rgb(2,8,16)',high-color:'rgb(2,8,16)',horizon-blend:0.05}});")
w("  map.addControl(new mapboxgl.NavigationControl({showCompass:false}),'top-right');")
w("  map.on('load',function(){")
w("    document.getElementById('sd').classList.remove('L');document.getElementById('st').textContent='CANLI';")
w("    map.on('rotate',function(){drawCompass(map.getBearing());});")
w("  });")
w("  map.on('error',function(e){showNtf('Harita hatasi: '+(e.error&&e.error.message?e.error.message.slice(0,40):''),'err');});")
w("}")

w("function initNoMap(){")
w("  var m=document.getElementById('map');")
w("  m.style.background='radial-gradient(ellipse at 50% 40%,#030e1a 0%,#020810 100%)';")
w("  var c=document.createElement('canvas');c.style.cssText='position:absolute;inset:0;width:100%;height:100%';m.appendChild(c);")
w("  var ctx=c.getContext('2d');c.width=window.innerWidth;c.height=window.innerHeight;")
w("  ctx.strokeStyle='rgba(0,255,136,.04)';ctx.lineWidth=1;")
w("  for(var x=0;x<c.width;x+=60){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,c.height);ctx.stroke();}")
w("  for(var y=0;y<c.height;y+=60){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(c.width,y);ctx.stroke();}")
w("  document.getElementById('sd').classList.remove('L');document.getElementById('st').textContent='DEMO';")
w("}")

# LAYER
w("var LS={satellite:'mapbox://styles/mapbox/satellite-v9',dark:'mapbox://styles/mapbox/dark-v11',street:'mapbox://styles/mapbox/streets-v12'};")
w("function setLayer(l){")
w("  if(demoMode||!map)return;")
w("  curLayer=l;")
w("  ['satellite','dark','street'].forEach(function(x){document.getElementById('l'+x[0]+'b').classList.toggle('A',x===l);});")
w("  map.setStyle(LS[l]);map.once('style.load',function(){renderMarkers();});")
w("  showNtf(l.toUpperCase()+' KATMANI YUKLENDI','info');")
w("}")

# TERMINATOR (day/night line)
w("function toggleTerminator(){")
w("  terminatorOn=!terminatorOn;")
w("  document.getElementById('trmb').classList.toggle('A',terminatorOn);")
w("  if(terminatorOn)drawTerminator();else{if(map&&map.getLayer&&map.getLayer('terminator'))map.removeLayer('terminator');if(map&&map.getSource&&map.getSource('terminator'))map.removeSource('terminator');}")
w("}")
w("function drawTerminator(){")
w("  if(!map)return;")
w("  var d=new Date(),lat=[];")
w("  var dec=-23.45*Math.cos((360/365*(d.getMonth()*30+d.getDate())+10)*Math.PI/180)*Math.PI/180;")
w("  var coords=[];")
w("  for(var lon=-180;lon<=180;lon+=2){")
w("    var l=Math.atan(-Math.cos(lon*Math.PI/180)/Math.tan(dec))*180/Math.PI;")
w("    coords.push([lon,l]);")
w("  }")
w("  coords.push([180,-90],[180,90],[-180,90],[-180,coords[0][1]],coords[0]);")
w("  try{")
w("    if(map.getSource('terminator'))map.removeLayer('terminator'),map.removeSource('terminator');")
w("    map.addSource('terminator',{type:'geojson',data:{type:'Feature',geometry:{type:'Polygon',coordinates:[coords]}}});")
w("    map.addLayer({id:'terminator',type:'fill',source:'terminator',paint:{'fill-color':'#000010','fill-opacity':0.45}});")
w("  }catch(e){}")
w("}")

# WEATHER
w("function toggleWeather(){")
w("  weatherOn=!weatherOn;")
w("  document.getElementById('wxb').classList.toggle('A',weatherOn);")
w("  showNtf(weatherOn?'HAVA DURUMU KATMANI AKTIF':'HAVA DURUMU KATMANI KAPALI','info');")
w("  if(weatherOn&&map&&!demoMode){")
w("    try{")
w("      map.addSource('owm-clouds',{type:'raster',tiles:['https://tile.openweathermap.org/map/clouds_new/{z}/{x}/{y}.png?appid=demo'],tileSize:256});")
w("      map.addLayer({id:'owm-layer',type:'raster',source:'owm-clouds',paint:{'raster-opacity':0.5}});")
w("    }catch(e){}")
w("  }else if(!weatherOn&&map){")
w("    try{if(map.getLayer('owm-layer'))map.removeLayer('owm-layer');if(map.getSource('owm-clouds'))map.removeSource('owm-clouds');}catch(e){}")
w("  }")
w("}")

# TRAIL
w("function toggleTrailForSelected(){")
w("  if(!selIcao)return;")
w("  trailEnabled[selIcao]=!trailEnabled[selIcao];")
w("  document.getElementById('trail-btn').classList.toggle('A',trailEnabled[selIcao]);")
w("  showNtf(trailEnabled[selIcao]?'UcUS iZi AKTIF':'iZ KALDIRILDI','info');")
w("  if(!trailEnabled[selIcao]){delete trailData[selIcao];removeTrailLayer(selIcao);}")
w("}")
w("function toggleTraffic(){")
w("  var btn=document.getElementById('trafb');")
w("  btn.classList.toggle('A');")
w("  showNtf('UCUS iZLERi '+(btn.classList.contains('A')?'AKTIF':'KAPALI'),'info');")
w("}")
w("function updateTrails(){")
w("  if(!map)return;")
w("  flights.forEach(function(f){")
w("    if(!trailEnabled[f.icao24]||!f.lat||!f.lon)return;")
w("    if(!trailData[f.icao24])trailData[f.icao24]=[];")
w("    trailData[f.icao24].push([f.lon,f.lat]);")
w("    if(trailData[f.icao24].length>80)trailData[f.icao24].shift();")
w("    var sid='trail-'+f.icao24,lid='trailn-'+f.icao24;")
w("    var geom={type:'Feature',geometry:{type:'LineString',coordinates:trailData[f.icao24]}};")
w("    try{")
w("      if(map.getSource(sid)){map.getSource(sid).setData(geom);}")
w("      else{map.addSource(sid,{type:'geojson',data:geom});map.addLayer({id:lid,type:'line',source:sid,paint:{'line-color':'#00e5ff','line-width':1.5,'line-opacity':0.7,'line-dasharray':[2,2]}});}")
w("    }catch(e){}")
w("  });")
w("}")
w("function removeTrailLayer(icao){")
w("  if(!map)return;")
w("  try{if(map.getLayer('trailn-'+icao))map.removeLayer('trailn-'+icao);if(map.getSource('trail-'+icao))map.removeSource('trail-'+icao);}catch(e){}")
w("}")

# FLIGHTS LOAD
w("async function loadFlights(){")
w("  document.getElementById('sd').classList.add('L');")
w("  var raw=await fetchOpenSky();")
w("  flights=raw.map(parseS).filter(function(f){return f.lat&&f.lon&&!f.ground;});")
w("  var countries=new Set(flights.map(function(f){return f.country;}));")
w("  var alts=flights.filter(function(f){return f.alt;}).map(function(f){return f.alt;});")
w("  var maxAlt=alts.length?Math.max.apply(null,alts):0;")
w("  document.getElementById('pc').textContent=flights.length;")
w("  document.getElementById('uc').textContent=countries.size;")
w("  document.getElementById('mx').textContent=maxAlt;")
w("  document.getElementById('lu').textContent=new Date().toTimeString().slice(0,5);")
w("  document.getElementById('sd').classList.remove('L');")
w("  checkAlerts();updateStats();renderList();updateTrails();")
w("  if(map)renderMarkers();")
w("}")
w("function refreshData(){resetRfTimer();loadFlights();showNtf('VERi YENiLENDi','info');}")

# FILTER
w("var activeFilter='all';")
w("function setFilter(f){")
w("  activeFilter=f;")
w("  ['all','high','fast','tr'].forEach(function(x){document.getElementById('fc-'+x).classList.toggle('A',x===f);});")
w("  renderList();")
w("}")
w("function applyFilter(list){")
w("  if(activeFilter==='all')return list;")
w("  if(activeFilter==='high')return list.filter(function(f){return f.alt&&f.alt>9000;});")
w("  if(activeFilter==='fast')return list.filter(function(f){return f.vel&&f.vel>800;});")
w("  if(activeFilter==='tr')return list.filter(function(f){return f.country==='Turkey';});")
w("  return list;")
w("}")

# RENDER LIST
w("function renderList(){")
w("  var fl=document.getElementById('fl');fl.innerHTML='';")
w("  var filtered=applyFilter(flights);")
w("  document.getElementById('fl-count').textContent=filtered.length;")
w("  filtered.slice(0,120).forEach(function(f){")
w("    var d=document.createElement('div');")
w("    d.className='fi'+(f.icao24===selIcao?' sel':'');")
w("    var flag=getFlag(f.country);")
w("    var altPct=f.alt?Math.min(100,f.alt/120*1)+'%':'0%';")
w("    var altColor=f.alt>9000?'#ff4466':f.alt>5000?'#ffcc00':'#00ff88';")
w("    d.innerHTML='<div class=\"fc\"><span class=\"fi-flag\">'+flag+'</span>'+f.callsign+'</div>'")
w("      +'<div class=\"fd\"><span class=\"fv\">'+(f.country.slice(0,12))+'</span>'")
w("      +'<span>&#9650; <span class=\"fv\">'+(f.alt?f.alt+'m':'--')+'</span></span>'")
w("      +'<span>&#10148; <span class=\"fv\">'+(f.vel?f.vel+'km':'--')+'</span></span>'")
w("      +'<span>'+(f.hdg?f.hdg+'deg':'--')+'</span></div>'")
w("      +'<div class=\"fi-alt-bar\"><div class=\"fi-alt-fill\" style=\"width:'+Math.min(100,f.alt?f.alt/120:0)+'%;background:'+altColor+'\"></div></div>';")
w("    d.onclick=function(){selectFlight(f);};")
w("    fl.appendChild(d);")
w("  });")
w("}")

# STATS
w("function updateStats(){")
w("  var total=flights.length;")
w("  var countries={};")
w("  var alts=flights.filter(function(f){return f.alt;});")
w("  var vels=flights.filter(function(f){return f.vel;});")
w("  flights.forEach(function(f){countries[f.country]=(countries[f.country]||0)+1;});")
w("  var avgAlt=alts.length?Math.round(alts.reduce(function(s,f){return s+f.alt;},0)/alts.length):0;")
w("  var avgVel=vels.length?Math.round(vels.reduce(function(s,f){return s+f.vel;},0)/vels.length):0;")
w("  document.getElementById('bs-total').textContent=total;")
w("  document.getElementById('bs-countries').textContent=Object.keys(countries).length;")
w("  document.getElementById('bs-avg-alt').textContent=avgAlt;")
w("  document.getElementById('bs-avg-spd').textContent=avgVel;")
w("  var sorted=Object.entries(countries).sort(function(a,b){return b[1]-a[1];}).slice(0,8);")
w("  var maxC=sorted[0]?sorted[0][1]:1;")
w("  var sc=document.getElementById('stat-countries');sc.innerHTML='';")
w("  sorted.forEach(function(e){")
w("    sc.innerHTML+='<div class=\"stat-row\"><div class=\"stat-label\">'+getFlag(e[0])+' '+e[0].slice(0,14)+'</div><div class=\"stat-bar-wrap\"><div class=\"stat-bar\" style=\"width:'+(e[1]/maxC*100)+'%\"></div></div><div class=\"stat-val\">'+e[1]+'</div></div>';")
w("  });")
w("  var spBuckets=[['0-400',0],['>400',0],['>600',0],['>800',0],['>1000',0]];")
w("  vels.forEach(function(f){")
w("    if(f.vel>1000)spBuckets[4][1]++;")
w("    else if(f.vel>800)spBuckets[3][1]++;")
w("    else if(f.vel>600)spBuckets[2][1]++;")
w("    else if(f.vel>400)spBuckets[1][1]++;")
w("    else spBuckets[0][1]++;")
w("  });")
w("  var maxS=Math.max.apply(null,spBuckets.map(function(b){return b[1];}));")
w("  var ss=document.getElementById('stat-speeds');ss.innerHTML='';")
w("  spBuckets.forEach(function(b){ss.innerHTML+='<div class=\"stat-row\"><div class=\"stat-label\">'+b[0]+' km/s</div><div class=\"stat-bar-wrap\"><div class=\"stat-bar\" style=\"width:'+(maxS>0?b[1]/maxS*100:0)+'%;background:var(--c)\"></div></div><div class=\"stat-val\" style=\"color:var(--c)\">'+b[1]+'</div></div>';});")
w("  var altBuckets=[['<3000',0],['3000-6k',0],['6k-9k',0],['9k-12k',0],['>12k',0]];")
w("  alts.forEach(function(f){")
w("    if(f.alt>12000)altBuckets[4][1]++;")
w("    else if(f.alt>9000)altBuckets[3][1]++;")
w("    else if(f.alt>6000)altBuckets[2][1]++;")
w("    else if(f.alt>3000)altBuckets[1][1]++;")
w("    else altBuckets[0][1]++;")
w("  });")
w("  var maxA=Math.max.apply(null,altBuckets.map(function(b){return b[1];}));")
w("  var sa=document.getElementById('stat-alts');sa.innerHTML='';")
w("  altBuckets.forEach(function(b){sa.innerHTML+='<div class=\"stat-row\"><div class=\"stat-label\">'+b[0]+' m</div><div class=\"stat-bar-wrap\"><div class=\"stat-bar\" style=\"width:'+(maxA>0?b[1]/maxA*100:0)+'%;background:var(--warn)\"></div></div><div class=\"stat-val\" style=\"color:var(--warn)\">'+b[1]+'</div></div>';});")
w("}")

# ALERTS
w("function checkAlerts(){")
w("  flights.forEach(function(f){")
w("    if(f.alt&&f.alt>11500){")
w("      var msg=f.callsign+' yuksek irtifa: '+f.alt+'m ('+f.country+')';")
w("      if(!alerts.find(function(a){return a.msg===msg;})){")
w("        alerts.unshift({msg:msg,time:new Date().toTimeString().slice(0,5),level:'high'});")
w("        if(alerts.length>30)alerts.pop();")
w("        renderAlerts();")
w("      }")
w("    }")
w("    if(f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500'){")
w("      var em={7700:'ACIL DURUM',7600:'RADYO ARIZA',7500:'HICAK'};")
w("      var msg2=f.callsign+' SQUAWK '+f.sqk+': '+(em[f.sqk]||'');")
w("      if(!alerts.find(function(a){return a.msg===msg2;})){")
w("        alerts.unshift({msg:msg2,time:new Date().toTimeString().slice(0,5),level:'high'});")
w("        renderAlerts();")
w("        showNtf('ACIL: '+msg2,'err');")
w("      }")
w("    }")
w("  });")
w("}")
w("function renderAlerts(){")
w("  var al=document.getElementById('alert-list');")
w("  if(!alerts.length){al.innerHTML='<div class=\"no-alerts\">ALARM YOK</div>';return;}")
w("  al.innerHTML=alerts.slice(0,20).map(function(a){return '<div class=\"alert-item\"><div class=\"alert-dot '+a.level+'\"></div><div><div class=\"alert-text\">'+a.msg+'</div><div class=\"alert-time\">'+a.time+'</div></div></div>';}).join('');")
w("  document.getElementById('tab2').textContent='ALARM ('+Math.min(alerts.length,20)+')';")
w("}")
w("function clearAlerts(){alerts=[];renderAlerts();document.getElementById('tab2').textContent='ALARM';}")

# MARKERS
w("function createEl(hdg,sel,squawk,alt){")
w("  var el=document.createElement('div');")
w("  var emergency=squawk==='7700'||squawk==='7600'||squawk==='7500';")
w("  var color=emergency?'#ff4466':sel?'#00e5ff':alt>9000?'#ffcc00':'#00ff88';")
w("  var sz=sel?20:14;")
w("  el.style.cssText='width:'+sz+'px;height:'+sz+'px;cursor:pointer;transition:transform .2s;';")
w("  if(emergency)el.style.animation='pulse 0.5s infinite';")
w("  el.innerHTML='<svg viewBox=\"0 0 24 24\" fill=\"none\" style=\"transform:rotate('+(hdg||0)+'deg);width:100%;height:100%;filter:drop-shadow(0 0 '+(sel?5:3)+'px '+color+')\">'")
w("    +'<path d=\"M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z\" fill=\"'+color+'\" opacity=\".95\"/>'")
w("    +'</svg>';")
w("  return el;")
w("}")

w("function renderMarkers(){")
w("  if(!map)return;")
w("  Object.values(markers).forEach(function(m){m.remove();});markers={};")
w("  flights.forEach(function(f){")
w("    var el=createEl(f.hdg,f.icao24===selIcao,f.sqk,f.alt);")
w("    var m=new mapboxgl.Marker({element:el}).setLngLat([f.lon,f.lat]).addTo(map);")
w("    el.addEventListener('click',function(e){e.stopPropagation();selectFlight(f);});")
w("    markers[f.icao24]=m;")
w("  });")
w("}")

# SELECT
w("function selectFlight(f){")
w("  selIcao=f.icao24;")
w("  document.getElementById('ics').textContent=f.callsign;")
w("  document.getElementById('ico').textContent=getFlag(f.country)+' '+f.country.slice(0,14);")
w("  document.getElementById('ial').textContent=f.alt?f.alt+'m':'--';")
w("  document.getElementById('isp').textContent=f.vel?f.vel+' km/s':'--';")
w("  document.getElementById('ihe').textContent=f.hdg!==null?f.hdg+'deg':'--';")
w("  document.getElementById('ila').textContent=f.lat?f.lat.toFixed(5):'--';")
w("  document.getElementById('ilo').textContent=f.lon?f.lon.toFixed(5):'--';")
w("  document.getElementById('isq').textContent=f.sqk||'--';")
w("  document.getElementById('ign').textContent=f.ground?'YERDE':f.vs>0?'YUKSELIYOR':f.vs<0?'ALIYOR':'UCUSTA';")
w("  document.getElementById('iic').textContent=f.icao24.toUpperCase();")
w("  var emergency=f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';")
w("  document.getElementById('ialm').textContent=emergency?('SQUAWK '+f.sqk):'-';")
w("  document.getElementById('ialm').className='iv'+(emergency?' warn-val':'');")
w("  document.getElementById('ip').classList.add('vis');")
w("  document.getElementById('ha').textContent=f.alt?Math.round(f.alt):'--';")
w("  document.getElementById('hs').textContent=f.vel||'--';")
w("  document.getElementById('hr').textContent=f.hdg!==null?f.hdg:'--';")
w("  document.getElementById('hm').classList.add('vis');")
w("  var spdPct=f.vel?Math.min(100,f.vel/12)+'%':'0%';")
w("  document.getElementById('spd-gauge').style.width=spdPct;")
w("  document.getElementById('trail-btn').classList.toggle('A',!!trailEnabled[f.icao24]);")
w("  if(map&&f.lat&&f.lon)map.flyTo({center:[f.lon,f.lat],zoom:7,speed:1.5,curve:1.2});")
w("  renderList();if(map)renderMarkers();")
w("}")
w("function flyToSelected(){if(selIcao&&map){var f=flights.find(function(x){return x.icao24===selIcao;});if(f)map.flyTo({center:[f.lon,f.lat],zoom:9,speed:1.5});}}")
w("function copyCoords(){var f=flights.find(function(x){return x.icao24===selIcao;});if(!f)return;var t=f.lat.toFixed(5)+', '+f.lon.toFixed(5);try{navigator.clipboard.writeText(t);showNtf('KOORDINAT KOPYALANDI','info');}catch(e){showNtf(t,'info');}}")
w("function openFlightawareSelected(){var f=flights.find(function(x){return x.icao24===selIcao;});if(f)window.open('https://flightaware.com/live/flight/'+f.callsign.trim(),'_blank');}")
w("function closeInfo(){selIcao=null;document.getElementById('ip').classList.remove('vis');document.getElementById('hm').classList.remove('vis');renderList();if(map)renderMarkers();}")

# SEARCH
w("function toggleSearch(){")
w("  searchVisible=!searchVisible;")
w("  document.getElementById('sb').classList.toggle('vis',searchVisible);")
w("  if(searchVisible)setTimeout(function(){document.getElementById('si').focus();},100);")
w("  else{document.getElementById('si').value='';document.getElementById('sr').classList.remove('vis');}")
w("}")
w("function doSearch(q){")
w("  var sr=document.getElementById('sr');")
w("  if(!q||q.length<2){sr.classList.remove('vis');return;}")
w("  var ql=q.toLowerCase();")
w("  var res=flights.filter(function(f){return f.callsign.toLowerCase().includes(ql)||f.country.toLowerCase().includes(ql)||f.icao24.toLowerCase().includes(ql);}).slice(0,10);")
w("  if(!res.length){sr.classList.remove('vis');return;}")
w("  sr.innerHTML=res.map(function(f){return '<div class=\"sr-item\" onclick=\"selectFlightByIcao(\\\"'+f.icao24+'\\\");\">'+getFlag(f.country)+' <b>'+f.callsign+'</b> — '+f.country+(f.alt?' '+f.alt+'m':'')+'</div>';}).join('');")
w("  sr.classList.add('vis');")
w("}")
w("function selectFlightByIcao(icao){var f=flights.find(function(x){return x.icao24===icao;});if(f){selectFlight(f);toggleSearch();}}")

# TABS
w("function showTab(i){")
w("  for(var j=0;j<3;j++){document.getElementById('tab'+j).classList.toggle('A',j===i);document.getElementById('tp'+j).classList.toggle('A',j===i);}")
w("}")

# PANEL
w("function togglePanel(){")
w("  panelOn=!panelOn;")
w("  document.getElementById('lp').classList.toggle('hide',!panelOn);")
w("  var b=document.getElementById('ptg');b.classList.toggle('hide',!panelOn);")
w("  b.innerHTML=panelOn?'&#9664;':'&#9654;';")
w("}")

# CENTER ON ME
w("function centerOnMe(){")
w("  if(!navigator.geolocation){showNtf('KONUM DESTEKLENMIYOR','err');return;}")
w("  navigator.geolocation.getCurrentPosition(function(pos){")
w("    if(map)map.flyTo({center:[pos.coords.longitude,pos.coords.latitude],zoom:7,speed:1.5});")
w("    showNtf('KONUMUNUZA ODAKLANILDI','info');")
w("  },function(){showNtf('KONUM ALINAMISADI','err');});")
w("}")

# FULLSCREEN
w("function toggleFullscreen(){")
w("  if(!document.fullscreenElement)document.documentElement.requestFullscreen().catch(function(){});")
w("  else document.exitFullscreen().catch(function(){});")
w("}")

# KEYBOARD
w("function setupKeyboard(){")
w("  document.addEventListener('keydown',function(e){")
w("    if(e.target.tagName==='INPUT')return;")
w("    var k=e.key.toUpperCase();")
w("    if(k==='F'){e.preventDefault();toggleSearch();}")
w("    else if(k==='R'){refreshData();}")
w("    else if(k==='L'){togglePanel();}")
w("    else if(k==='S'){setLayer('satellite');}")
w("    else if(k==='D'){setLayer('dark');}")
w("    else if(k==='T'){setLayer('street');}")
w("    else if(k==='H'){toggleWeather();}")
w("    else if(k==='C'){centerOnMe();}")
w("    else if(k==='ESCAPE'){closeInfo();if(searchVisible)toggleSearch();}")
w("    else if(k==='?'){toggleKb();}")
w("    else if(e.key==='F11'){e.preventDefault();toggleFullscreen();}")
w("  });")
w("}")
w("function toggleKb(){kbVisible=!kbVisible;document.getElementById('kbo').classList.toggle('vis',kbVisible);}")

# RADAR
w("function startRadar(){")
w("  var cv=document.getElementById('rv'),ctx=cv.getContext('2d');")
w("  function draw(){")
w("    ctx.clearRect(0,0,100,100);")
w("    ctx.strokeStyle='rgba(0,255,136,.15)';ctx.lineWidth=1;")
w("    [20,35,50].forEach(function(r){ctx.beginPath();ctx.arc(50,50,r,0,Math.PI*2);ctx.stroke();});")
w("    ctx.strokeStyle='rgba(0,255,136,.08)';")
w("    ctx.beginPath();ctx.moveTo(50,0);ctx.lineTo(50,100);ctx.stroke();")
w("    ctx.beginPath();ctx.moveTo(0,50);ctx.lineTo(100,50);ctx.stroke();")
w("    ctx.save();ctx.translate(50,50);ctx.rotate(radarA);")
w("    var sw=ctx.createLinearGradient(0,0,50,0);")
w("    sw.addColorStop(0,'rgba(0,255,136,.6)');sw.addColorStop(1,'rgba(0,255,136,0)');")
w("    ctx.beginPath();ctx.moveTo(0,0);ctx.arc(0,0,50,-0.4,0);ctx.closePath();ctx.fillStyle=sw;ctx.fill();")
w("    ctx.restore();")
w("    var cnt=0;")
w("    if(flights.length&&map){")
w("      var ctr=map.getCenter();")
w("      flights.forEach(function(f){")
w("        if(!f.lat||!f.lon)return;")
w("        var dx=(f.lon-ctr.lng)*1.2,dy=-(f.lat-ctr.lat)*1.5;")
w("        if(Math.abs(dx)>46||Math.abs(dy)>46)return;cnt++;")
w("        var emergency=f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';")
w("        ctx.beginPath();ctx.arc(50+dx,50+dy,emergency?3:1.5,0,Math.PI*2);")
w("        ctx.fillStyle=emergency?'rgba(255,68,102,.9)':f.icao24===selIcao?'rgba(255,204,0,.9)':'rgba(0,229,255,.75)';")
w("        ctx.fill();")
w("      });")
w("    }else{")
w("      flights.slice(0,40).forEach(function(f,i){")
w("        var a=i/40*Math.PI*2,r=Math.random()*44;")
w("        ctx.beginPath();ctx.arc(50+Math.cos(a)*r,50+Math.sin(a)*r,1.5,0,Math.PI*2);")
w("        ctx.fillStyle='rgba(0,229,255,.6)';ctx.fill();cnt++;")
w("      });")
w("    }")
w("    document.getElementById('rcount').textContent=cnt;")
w("    radarA+=0.03;requestAnimationFrame(draw);")
w("  }draw();")
w("}")

# COMPASS
w("function startCompass(){drawCompass(0);}")
w("function drawCompass(bearing){")
w("  var cv=document.getElementById('comp');if(!cv)return;")
w("  var ctx=cv.getContext('2d'),cx=24,cy=24,r=22;")
w("  ctx.clearRect(0,0,48,48);")
w("  ctx.strokeStyle='rgba(0,255,136,.2)';ctx.lineWidth=1;")
w("  ctx.beginPath();ctx.arc(cx,cy,r,0,Math.PI*2);ctx.stroke();")
w("  var dirs=['N','E','S','W'];")
w("  dirs.forEach(function(d,i){")
w("    var a=(i*90-bearing)*Math.PI/180;")
w("    ctx.fillStyle=d==='N'?'#ff4466':'rgba(168,255,212,.6)';")
w("    ctx.font='bold 8px Orbitron';ctx.textAlign='center';ctx.textBaseline='middle';")
w("    ctx.fillText(d,cx+Math.sin(a)*(r-6),cy-Math.cos(a)*(r-6));")
w("  });")
w("  ctx.save();ctx.translate(cx,cy);ctx.rotate(-bearing*Math.PI/180);")
w("  ctx.fillStyle='#ff4466';ctx.beginPath();ctx.moveTo(0,-14);ctx.lineTo(3,0);ctx.lineTo(0,-3);ctx.lineTo(-3,0);ctx.closePath();ctx.fill();")
w("  ctx.fillStyle='rgba(168,255,212,.5)';ctx.beginPath();ctx.moveTo(0,14);ctx.lineTo(3,0);ctx.lineTo(0,3);ctx.lineTo(-3,0);ctx.closePath();ctx.fill();")
w("  ctx.restore();")
w("}")

# REFRESH TIMER
w("function startRfTimer(){")
w("  var bar=document.getElementById('rp'),s=Date.now();")
w("  rfInt=setInterval(function(){")
w("    var e=Date.now()-s,p=Math.max(0,100-(e/RF)*100);")
w("    bar.style.width=p+'%';")
w("    if(e>=RF){s=Date.now();loadFlights();}")
w("  },300);")
w("}")
w("function resetRfTimer(){if(rfInt)clearInterval(rfInt);rfInt=null;startRfTimer();}")

# NOTIFICATION
w("function showNtf(msg,type){")
w("  var el=document.getElementById('ntf'),ic=document.getElementById('ntf-icon'),mc=document.getElementById('ntf-msg');")
w("  var icons={info:'i',warn:'!',err:'x'};")
w("  ic.textContent=icons[type]||'i';mc.textContent=msg;")
w("  el.className='ntf sh'+(type==='err'?' er':type==='warn'?' warn':'');")
w("  clearTimeout(el._t);el._t=setTimeout(function(){el.classList.remove('sh');},3500);")
w("}")

# INIT
w("window.addEventListener('load',function(){")
w("  var s=localStorage.getItem('mbt');if(s)document.getElementById('ti').value=s;")
w("});")

w("</script>")
w("</body>")
w("</html>")

with open(HTML, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print("OK:" + HTML)
PYEOF

if [ ! -f "$HTML" ]; then
  printf "  ${R}HATA: HTML olusturulamadi!${N}\n"; exit 1
fi
printf "  ${G}HTML hazir ($(wc -l < "$HTML") satir)${N}\n"

# Random port sec
PORT=$(( RANDOM % 8975 + 1025 ))
while lsof -i :$PORT >/dev/null 2>&1; do PORT=$(( RANDOM % 8975 + 1025 )); done

printf "\n"
printf "  ┌─────────────────────────────────────────────────┐\n"
printf "  │  ${B}URL   :${N} ${C}http://localhost:$PORT${N}\n"
printf "  │  ${B}DURUM :${N} ${G}AKTIF${N}\n"
printf "  │  Durdurmak icin: Ctrl + C\n"
printf "  └─────────────────────────────────────────────────┘\n\n"

sleep 0.8
command -v termux-open-url &>/dev/null && termux-open-url "http://localhost:$PORT" & printf "  ${C}Tarayici aciliyor...${N}\n\n"

cd "$TMPD"
$PY << PYEOF
import http.server, socketserver, os, sys, signal

PORT = $PORT
os.chdir("$TMPD")

class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, fmt, *a):
        print("  [%s] %s" % (self.address_string(), fmt % a))
    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            self.path = "/skywatch_v2.html"
        super().do_GET()

def bye(s, f):
    print("\n  Sunucu kapatildi.\n"); sys.exit(0)

signal.signal(signal.SIGINT, bye)
with socketserver.TCPServer(("", PORT), H) as h:
    print("  http://localhost:%d  |  Ctrl+C ile durdur\n" % PORT)
    h.serve_forever()
PYEOF

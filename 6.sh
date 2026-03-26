
#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  SKYWATCH v4.0 ULTIMATE — Canli Ucak Takip Sistemi          ║
# ║  Calistir: bash skywatch.sh                                  ║
# ╚══════════════════════════════════════════════════════════════╝

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'; B='\033[1m'

clear
printf "\n${G}${B}"
printf "  ███████╗██╗  ██╗██╗   ██╗██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗\n"
printf "  ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║\n"
printf "  ███████╗█████╔╝  ╚████╔╝ ██║ █╗ ██║███████║   ██║   ██║     ███████║\n"
printf "  ╚════██║██╔═██╗   ╚██╔╝  ██║███╗██║██╔══██║   ██║   ██║     ██╔══██║\n"
printf "  ███████║██║  ██╗   ██║   ╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║\n"
printf "  ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝\n"
printf "${N}"
printf "  ${C}v4.0 ULTIMATE — Performans + Ucus izi + Slider Kontrol${N}\n"
printf "  ──────────────────────────────────────────────────────────\n\n"

PY=$(command -v python3 || command -v python)
if [ -z "$PY" ]; then
  printf "  ${Y}Python yukleniyor...${N}\n"
  pkg install python -y
  PY=$(command -v python3 || command -v python)
fi

TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/skywatch_v4.html"

printf "  ${C}HTML olusturuluyor (v4.0 Ultimate)...${N}\n"

$PY << 'PYEOF'
import os, sys
TMPD = os.environ.get("TMPDIR", "/tmp")
HTML = os.path.join(TMPD, "skywatch_v4.html")

L = []
def w(s=""): L.append(s)
def js(s): L.append(s)  # same but semantic

# ══════════════════════════════════════════════════════════════════
# HTML HEAD
# ══════════════════════════════════════════════════════════════════
w("<!DOCTYPE html><html lang='tr'><head>")
w("<meta charset='UTF-8'>")
w("<meta name='viewport' content='width=device-width,initial-scale=1.0'>")
w("<title>SKYWATCH v4 — Canli Ucak Takip</title>")
w("<link href='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css' rel='stylesheet'>")
w("<script src='https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js'></script>")
w("<link href='https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&family=Rajdhani:wght@300;400;600;700&display=swap' rel='stylesheet'>")

# ══════════════════════════════════════════════════════════════════
# CSS
# ══════════════════════════════════════════════════════════════════
w("<style>")
w(":root{")
w("  --g:#00ff88;--c:#00e5ff;--o:#ff6b35;--w:#ffcc00;--r:#ff4466;")
w("  --bg:#020810;--bg2:#030f1a;--bg3:#041220;")
w("  --panel:rgba(3,15,26,0.97);--panel2:rgba(4,18,32,0.99);")
w("  --border:rgba(0,255,136,0.18);--border2:rgba(0,229,255,0.2);")
w("  --text:#a8ffd4;--text2:rgba(168,255,212,0.5);--text3:rgba(168,255,212,0.3);")
w("}")
w("*{margin:0;padding:0;box-sizing:border-box}")
w("html,body{background:var(--bg);color:var(--text);font-family:'Share Tech Mono',monospace;overflow:hidden;height:100vh;width:100vw;cursor:default}")
w("::selection{background:rgba(0,255,136,0.2);color:#00ff88}")
w("body::after{content:'';position:fixed;inset:0;background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,255,136,.008) 2px,rgba(0,255,136,.008) 4px);pointer-events:none;z-index:1}")
w("#map{position:absolute;inset:0}")

# ── MODAL (en üstte) ──────────────────────────────────────────────
w("#modal{position:fixed;inset:0;background:rgba(2,8,16,0.98);z-index:10000;display:flex;align-items:center;justify-content:center}")
w("#modal.gone{display:none!important}")
w(".mbox{background:var(--bg3);border:1px solid rgba(0,255,136,0.28);padding:34px;width:480px;max-width:95vw;position:relative}")
w(".mbox::before{content:'SKYWATCH v4.0';position:absolute;top:-11px;left:20px;background:var(--bg3);padding:0 12px;font-family:'Orbitron',sans-serif;font-size:9px;color:var(--g);letter-spacing:5px}")
w(".mtitle{font-family:'Orbitron',sans-serif;font-size:16px;color:var(--c);letter-spacing:3px;margin-bottom:4px}")
w(".msub{font-size:10px;color:var(--text3);letter-spacing:2px;margin-bottom:18px}")
w(".mdesc{font-size:11px;color:var(--text2);line-height:1.8;margin-bottom:20px}")
w(".mdesc a{color:var(--c);text-decoration:none}")
w(".mdesc b{color:var(--text)}")
w(".mlabel{font-size:9px;color:var(--text3);letter-spacing:2px;margin-bottom:5px;text-transform:uppercase}")
w(".minput{width:100%;background:rgba(0,229,255,0.04);border:1px solid rgba(0,229,255,0.22);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;padding:11px 14px;outline:none;letter-spacing:0.5px;transition:border-color .2s,box-shadow .2s;margin-bottom:8px}")
w(".minput:focus{border-color:var(--c);box-shadow:0 0 16px rgba(0,229,255,0.12)}")
w(".minput::placeholder{color:rgba(168,255,212,0.18)}")
w(".merr{font-size:10px;color:var(--r);min-height:18px;margin-bottom:10px;display:flex;align-items:center;gap:6px;letter-spacing:1px}")
w(".mbtns{display:flex;gap:10px}")
w(".mbtn-start{flex:1;background:rgba(0,255,136,0.1);border:1px solid var(--g);color:var(--g);font-family:'Share Tech Mono',monospace;font-size:12px;padding:12px;cursor:pointer;letter-spacing:2px;transition:all .2s;text-transform:uppercase}")
w(".mbtn-start:hover{background:rgba(0,255,136,0.2);box-shadow:0 0 24px rgba(0,255,136,0.18)}")
w(".mbtn-start:disabled{opacity:0.4;cursor:not-allowed}")
w(".mbtn-demo{background:rgba(0,229,255,0.07);border:1px solid rgba(0,229,255,0.28);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;padding:12px 20px;cursor:pointer;letter-spacing:2px;transition:all .2s}")
w(".mbtn-demo:hover{background:rgba(0,229,255,0.16);border-color:var(--c)}")
w(".mbtn-demo:disabled{opacity:0.4;cursor:not-allowed}")
w(".msaved{display:none;align-items:center;gap:8px;font-size:10px;color:var(--g);letter-spacing:1px;padding:7px 12px;border:1px solid rgba(0,255,136,0.18);background:rgba(0,255,136,0.04);margin-bottom:10px}")
w(".msaved.show{display:flex}")
w(".mhint{font-size:9px;color:var(--text3);letter-spacing:1px;margin-top:12px;text-align:center}")

# ── LOADING (başlangıçta gizli) ───────────────────────────────────
w("#loading{position:fixed;inset:0;background:var(--bg);z-index:9999;display:none;flex-direction:column;align-items:center;justify-content:center;gap:18px}")
w("#loading.on{display:flex}")
w(".ldlogo{font-family:'Orbitron',sans-serif;font-size:34px;font-weight:900;color:var(--g);letter-spacing:8px;animation:lglow 2.5s ease-in-out infinite;text-align:center}")
w(".ldsub{font-size:10px;color:var(--text3);letter-spacing:5px;margin-top:-10px}")
w("@keyframes lglow{0%,100%{text-shadow:0 0 20px rgba(0,255,136,.3),0 0 40px rgba(0,255,136,.1)}50%{text-shadow:0 0 50px rgba(0,255,136,.9),0 0 90px rgba(0,255,136,.4)}}")
w(".ldbarwrap{width:280px;height:2px;background:rgba(0,255,136,.1);overflow:hidden}")
w(".ldbar{height:100%;background:linear-gradient(90deg,var(--g),var(--c));width:0%;transition:width .35s ease;box-shadow:0 0 8px var(--g)}")
w(".ldstatus{font-size:10px;color:var(--text3);letter-spacing:3px;text-transform:uppercase}")

# ── TOPBAR ─────────────────────────────────────────────────────────
w(".topbar{position:fixed;top:0;left:0;right:0;height:52px;background:rgba(3,15,26,0.97);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 14px;gap:12px;z-index:500;backdrop-filter:blur(16px)}")
w(".tlogo{font-family:'Orbitron',sans-serif;font-weight:900;font-size:16px;color:var(--g);letter-spacing:5px;text-shadow:0 0 20px rgba(0,255,136,.6);display:flex;align-items:center;gap:8px;white-space:nowrap;flex-shrink:0}")
w(".tlogo svg{flex-shrink:0;animation:planepulse 4s ease-in-out infinite;filter:drop-shadow(0 0 5px var(--g))}")
w("@keyframes planepulse{0%,100%{filter:drop-shadow(0 0 3px var(--g))}50%{filter:drop-shadow(0 0 10px var(--g)) drop-shadow(0 0 20px rgba(0,255,136,.5))}}")
w(".tvbar{width:1px;height:22px;background:var(--border);flex-shrink:0}")
w(".tstats{display:flex;gap:14px;flex:1;overflow:hidden;align-items:center;min-width:0}")
w(".tsc{display:flex;align-items:center;gap:5px;font-size:10px;color:var(--text2);white-space:nowrap;flex-shrink:0}")
w(".tval{color:var(--c);font-family:'Orbitron',sans-serif;font-size:11px}")
w(".statusdot{width:7px;height:7px;border-radius:50%;background:var(--g);box-shadow:0 0 8px var(--g);animation:blink 1.5s infinite;flex-shrink:0}")
w(".statusdot.loading{background:var(--o);box-shadow:0 0 8px var(--o)}")
w(".statusdot.error{background:var(--r);box-shadow:0 0 8px var(--r)}")
w(".statusdot.demo{background:var(--w);box-shadow:0 0 8px var(--w)}")
w("@keyframes blink{0%,100%{opacity:1}50%{opacity:.2}}")
w(".tright{display:flex;align-items:center;gap:6px;margin-left:auto;flex-shrink:0}")
w(".tclock{font-size:13px;color:var(--c);letter-spacing:2px;font-family:'Orbitron',sans-serif;min-width:72px}")
w(".tbtn{background:transparent;border:1px solid var(--border);color:var(--g);font-family:'Share Tech Mono',monospace;font-size:10px;padding:5px 9px;cursor:pointer;letter-spacing:1px;transition:all .2s;white-space:nowrap;position:relative;overflow:hidden}")
w(".tbtn::after{content:'';position:absolute;top:50%;left:50%;width:0;height:0;background:rgba(0,255,136,0.15);border-radius:50%;transform:translate(-50%,-50%);transition:width .4s,height .4s}")
w(".tbtn:active::after{width:200px;height:200px}")
w(".tbtn:hover,.tbtn.on{background:rgba(0,255,136,0.1);border-color:var(--g);box-shadow:0 0 10px rgba(0,255,136,0.18)}")
w(".tbtn.red{color:var(--r);border-color:rgba(255,68,102,.3)}")
w(".tbtn.red:hover{background:rgba(255,68,102,.1);border-color:var(--r)}")

# ── SEARCH ─────────────────────────────────────────────────────────
w(".searchbar{position:fixed;top:62px;left:50%;transform:translateX(-50%);z-index:501;display:flex;width:360px;opacity:0;pointer-events:none;transition:opacity .25s,transform .25s}")
w(".searchbar.open{opacity:1;pointer-events:all}")
w(".sinput{flex:1;background:var(--panel2);border:1px solid var(--border2);border-right:none;color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;padding:9px 14px;outline:none;letter-spacing:.5px}")
w(".sinput:focus{border-color:var(--c)}")
w(".sinput::placeholder{color:var(--text3)}")
w(".scloseBtn{background:rgba(0,229,255,.08);border:1px solid var(--border2);color:var(--c);font-size:16px;padding:9px 13px;cursor:pointer;transition:background .2s}")
w(".scloseBtn:hover{background:rgba(255,68,102,.15);color:var(--r)}")
w(".sresults{position:absolute;top:100%;left:0;right:0;background:var(--panel2);border:1px solid var(--border2);border-top:none;max-height:240px;overflow-y:auto;display:none;scrollbar-width:thin}")
w(".sresults.open{display:block}")
w(".sres-item{padding:9px 14px;font-size:11px;cursor:pointer;border-bottom:1px solid rgba(0,255,136,.05);display:flex;align-items:center;gap:8px}")
w(".sres-item:hover{background:rgba(0,255,136,.07);color:var(--g)}")
w(".sres-call{font-family:'Orbitron',sans-serif;font-size:11px;color:var(--c)}")
w(".sres-info{font-size:9px;color:var(--text2)}")

# ── LEFT PANEL ─────────────────────────────────────────────────────
w(".lpanel{position:fixed;top:52px;left:0;bottom:0;width:272px;background:var(--panel);border-right:1px solid var(--border);z-index:200;display:flex;flex-direction:column;transition:transform .32s cubic-bezier(.4,0,.2,1);will-change:transform}")
w(".lpanel.closed{transform:translateX(-272px)}")
w(".ptoggle{position:fixed;top:66px;left:272px;width:16px;height:42px;background:var(--panel);border:1px solid var(--border);border-left:none;z-index:201;display:flex;align-items:center;justify-content:center;font-size:10px;color:var(--g);cursor:pointer;transition:left .32s cubic-bezier(.4,0,.2,1),background .2s}")
w(".ptoggle:hover{background:rgba(0,255,136,0.1)}")
w(".ptoggle.closed{left:0}")

# TABS
w(".tabs{display:flex;border-bottom:1px solid var(--border);flex-shrink:0}")
w(".tabbtn{flex:1;padding:9px 0;font-family:'Share Tech Mono',monospace;font-size:9px;letter-spacing:2px;color:var(--text2);background:transparent;border:none;cursor:pointer;transition:all .2s;border-bottom:2px solid transparent;text-transform:uppercase}")
w(".tabbtn.on{color:var(--g);border-bottom-color:var(--g);background:rgba(0,255,136,.04)}")
w(".tabbtn:hover:not(.on){color:var(--text);background:rgba(0,255,136,.02)}")
w(".tabpanel{display:none;flex:1;overflow-y:auto;flex-direction:column;scrollbar-width:thin;scrollbar-color:rgba(0,255,136,.18) transparent}")
w(".tabpanel.on{display:flex}")
w(".tabpanel::-webkit-scrollbar{width:3px}")
w(".tabpanel::-webkit-scrollbar-thumb{background:rgba(0,255,136,.18)}")

# SLIDER CONTROL
w(".slider-section{padding:10px 12px;border-bottom:1px solid rgba(0,255,136,.07);flex-shrink:0;background:rgba(0,255,136,.02)}")
w(".slider-row{display:flex;align-items:center;justify-content:space-between;margin-bottom:6px}")
w(".slider-label{font-size:9px;color:var(--text3);letter-spacing:2px;text-transform:uppercase}")
w(".slider-val{font-family:'Orbitron',sans-serif;font-size:12px;color:var(--g)}")
w(".slider{width:100%;height:3px;background:rgba(0,255,136,.12);outline:none;border:none;cursor:pointer;-webkit-appearance:none;appearance:none;border-radius:0}")
w(".slider::-webkit-slider-thumb{-webkit-appearance:none;width:14px;height:14px;background:var(--g);cursor:pointer;box-shadow:0 0 8px var(--g)}")
w(".slider::-moz-range-thumb{width:14px;height:14px;background:var(--g);cursor:pointer;border:none;box-shadow:0 0 8px var(--g)}")
w(".slider::-webkit-slider-runnable-track{background:rgba(0,255,136,.12)}")
w(".perf-row{display:flex;gap:5px;margin-top:6px}")
w(".perf-btn{flex:1;font-size:9px;padding:4px;border:1px solid rgba(0,255,136,.18);color:var(--text2);background:transparent;cursor:pointer;font-family:'Share Tech Mono',monospace;letter-spacing:1px;transition:all .2s;text-align:center}")
w(".perf-btn.on{color:var(--g);border-color:var(--g);background:rgba(0,255,136,.07)}")
w(".perf-btn:hover{color:var(--g);border-color:var(--g)}")

# FILTER CHIPS
w(".fbar{padding:7px 10px;border-bottom:1px solid rgba(0,255,136,.06);display:flex;gap:5px;flex-wrap:wrap;flex-shrink:0}")
w(".fchip{font-size:9px;padding:3px 8px;border:1px solid rgba(0,255,136,.18);color:var(--text2);background:transparent;cursor:pointer;font-family:'Share Tech Mono',monospace;letter-spacing:1px;transition:all .2s}")
w(".fchip.on{background:rgba(0,229,255,.1);border-color:var(--c);color:var(--c)}")
w(".fchip:hover:not(.on){border-color:var(--g);color:var(--g)}")
w(".fchip.red.on{background:rgba(255,68,102,.1);border-color:var(--r);color:var(--r)}")
w(".fcountbar{padding:3px 10px 5px;font-size:9px;color:var(--text3);letter-spacing:1px;border-bottom:1px solid rgba(0,255,136,.04);flex-shrink:0;display:flex;justify-content:space-between}")

# FLIGHT ITEMS
w(".fitem{padding:9px 12px;border-bottom:1px solid rgba(0,255,136,.05);cursor:pointer;transition:background .1s;position:relative;flex-shrink:0}")
w(".fitem::before{content:'';position:absolute;left:0;top:0;bottom:0;width:2px;opacity:0;transition:opacity .15s}")
w(".fitem:hover{background:rgba(0,255,136,.05)}")
w(".fitem:hover::before{opacity:1;background:var(--g)}")
w(".fitem.sel{background:rgba(0,229,255,.05)}")
w(".fitem.sel::before{opacity:1;background:var(--c)}")
w(".fitem.emerg{background:rgba(255,68,102,.04)}")
w(".fitem.emerg::before{opacity:1;background:var(--r);animation:blink .6s infinite}")
w(".fcall{font-family:'Orbitron',sans-serif;font-size:11px;color:var(--c);display:flex;align-items:center;gap:5px;letter-spacing:.5px}")
w(".fflag{font-size:13px;line-height:1;flex-shrink:0}")
w(".fbadge{font-size:8px;padding:1px 5px;border:1px solid;letter-spacing:1px;flex-shrink:0}")
w(".fbadge.emerg{border-color:var(--r);color:var(--r)}")
w(".fbadge.high{border-color:var(--w);color:var(--w)}")
w(".fdetail{font-size:9px;color:var(--text2);display:flex;gap:8px;margin-top:3px;flex-wrap:wrap}")
w(".fdv{color:var(--text)}")
w(".faltbar{height:2px;background:rgba(0,255,136,.07);margin-top:5px;overflow:hidden}")
w(".faltfill{height:100%;transition:width .4s ease}")

# STATS
w(".stblock{padding:12px;border-bottom:1px solid rgba(0,255,136,.06);flex-shrink:0}")
w(".sthead{font-size:8px;color:var(--text3);letter-spacing:3px;text-transform:uppercase;margin-bottom:9px;display:flex;justify-content:space-between;align-items:center}")
w(".bigstat{display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-bottom:6px}")
w(".bsi{background:rgba(0,255,136,.04);border:1px solid rgba(0,255,136,.1);padding:9px 10px}")
w(".bsv{font-family:'Orbitron',sans-serif;font-size:19px;color:var(--c);line-height:1}")
w(".bsl{font-size:8px;color:var(--text3);letter-spacing:2px;margin-top:3px;text-transform:uppercase}")
w(".strow{display:flex;align-items:center;gap:8px;margin-bottom:5px}")
w(".stlabel{font-size:10px;color:var(--text2);flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}")
w(".sttrack{flex:0 0 70px;height:3px;background:rgba(0,255,136,.08)}")
w(".stfill{height:100%;transition:width .7s ease}")
w(".stval{font-size:10px;width:26px;text-align:right;flex-shrink:0;color:var(--g)}")

# ALERTS
w(".alert-item{padding:9px 12px;border-bottom:1px solid rgba(255,68,102,.08);display:flex;gap:8px;flex-shrink:0}")
w(".apip{width:7px;height:7px;border-radius:50%;flex-shrink:0;margin-top:4px}")
w(".apip.high{background:var(--r);box-shadow:0 0 6px var(--r);animation:blink .7s infinite}")
w(".apip.med{background:var(--w);box-shadow:0 0 5px var(--w)}")
w(".apip.low{background:var(--c);box-shadow:0 0 4px var(--c)}")
w(".amsg{font-size:10px;color:var(--text);line-height:1.5}")
w(".atime{font-size:9px;color:var(--text3);margin-top:2px}")
w(".no-alerts{padding:24px 12px;text-align:center;font-size:10px;color:var(--text3);letter-spacing:2px}")

# SETTINGS TAB
w(".settrow{padding:10px 12px;border-bottom:1px solid rgba(0,255,136,.05);display:flex;align-items:center;justify-content:space-between;flex-shrink:0}")
w(".settlabel{font-size:10px;color:var(--text2);letter-spacing:1px}")
w(".settval{font-size:10px;color:var(--g);font-family:'Orbitron',sans-serif}")
w(".toggle-sw{width:32px;height:16px;background:rgba(0,255,136,.12);border:1px solid rgba(0,255,136,.3);position:relative;cursor:pointer;transition:background .2s,border-color .2s;flex-shrink:0}")
w(".toggle-sw.on{background:rgba(0,255,136,.25);border-color:var(--g)}")
w(".toggle-sw::after{content:'';position:absolute;width:10px;height:10px;background:rgba(168,255,212,.5);top:2px;left:2px;transition:left .2s,background .2s}")
w(".toggle-sw.on::after{left:18px;background:var(--g);box-shadow:0 0 6px var(--g)}")
w(".expbtn{font-size:9px;padding:4px 10px;border:1px solid rgba(0,255,136,.2);color:var(--text2);background:transparent;cursor:pointer;font-family:'Share Tech Mono',monospace;letter-spacing:1px;transition:all .2s}")
w(".expbtn:hover{color:var(--g);border-color:var(--g)}")
w(".sett-section{padding:8px 12px 2px;font-size:8px;color:var(--text3);letter-spacing:3px;text-transform:uppercase;border-bottom:1px solid rgba(0,255,136,.04);flex-shrink:0}")

# INFO PANEL
w(".infopanel{position:fixed;bottom:16px;right:16px;width:300px;background:var(--panel2);border:1px solid var(--border2);z-index:200;display:none;box-shadow:0 0 40px rgba(0,229,255,.06)}")
w(".infopanel.vis{display:block;animation:slidein .2s ease}")
w("@keyframes slidein{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:translateY(0)}}")
w(".infohead{padding:10px 13px;background:rgba(0,229,255,.05);border-bottom:1px solid var(--border2);font-family:'Orbitron',sans-serif;font-size:12px;color:var(--c);letter-spacing:2px;display:flex;justify-content:space-between;align-items:center}")
w(".infohead-acts{display:flex;gap:8px;align-items:center}")
w(".itrailbtn{font-size:9px;padding:2px 7px;border:1px solid rgba(0,229,255,.25);color:rgba(0,229,255,.6);background:transparent;cursor:pointer;font-family:'Share Tech Mono',monospace;letter-spacing:1px;transition:all .2s}")
w(".itrailbtn:hover,.itrailbtn.on{background:rgba(0,229,255,.12);border-color:var(--c);color:var(--c)}")
w(".closex{color:var(--text3);font-size:18px;cursor:pointer;transition:color .2s;line-height:1}")
w(".closex:hover{color:var(--r)}")
w(".infogrid{padding:10px 13px;display:grid;grid-template-columns:1fr 1fr;gap:8px}")
w(".ifield{display:flex;flex-direction:column;gap:2px}")
w(".ilabel{font-size:8px;color:var(--text3);letter-spacing:2px;text-transform:uppercase}")
w(".ival{font-size:12px;color:var(--g);font-family:'Orbitron',sans-serif;transition:color .2s}")
w(".ival.blue{color:var(--c)}.ival.yellow{color:var(--w)}.ival.red{color:var(--r)}")
# Speed gauge
w(".spdwrap{padding:0 13px 8px;display:flex;align-items:center;gap:8px}")
w(".spdtrack{flex:1;height:3px;background:rgba(0,255,136,.08);overflow:hidden}")
w(".spdfill{height:100%;background:linear-gradient(90deg,var(--g),var(--c),var(--w),var(--r));transition:width .5s ease}")
w(".spdlabel{font-size:9px;color:var(--text3);white-space:nowrap}")
# Speed history mini chart
w(".spdhist{padding:0 13px 8px}")
w(".spdhist-label{font-size:8px;color:var(--text3);letter-spacing:2px;margin-bottom:4px;text-transform:uppercase}")
w(".spdhist canvas{display:block;width:100%;height:36px}")
# Info action buttons
w(".infobtns{padding:0 13px 10px;display:flex;gap:5px}")
w(".iabtn{flex:1;font-size:9px;padding:5px 3px;border:1px solid var(--border);color:var(--text2);background:transparent;cursor:pointer;font-family:'Share Tech Mono',monospace;letter-spacing:1px;transition:all .2s;text-align:center}")
w(".iabtn:hover{color:var(--g);border-color:var(--g);background:rgba(0,255,136,.05)}")
w(".iabtn:active{transform:scale(.95)}")

# RADAR
w(".radarwrap{position:fixed;bottom:16px;left:16px;z-index:200;background:var(--panel2);border:1px solid var(--border);padding:8px}")
w(".radarhead{font-size:8px;color:var(--text3);letter-spacing:2px;text-transform:uppercase;margin-bottom:5px;display:flex;justify-content:space-between;align-items:center}")
w(".radarcnt{color:var(--g);font-family:'Orbitron',sans-serif;font-size:10px}")

# HUD METERS
w(".hud{position:fixed;top:50%;right:16px;transform:translateY(-50%);z-index:200;display:flex;flex-direction:column;gap:6px;opacity:0;pointer-events:none;transition:opacity .3s}")
w(".hud.vis{opacity:1}")
w(".hud-m{background:var(--panel2);border:1px solid var(--border2);padding:8px 10px;width:76px;position:relative;overflow:hidden}")
w(".hud-m::after{content:'';position:absolute;top:0;left:0;right:0;height:1px;background:linear-gradient(90deg,transparent,var(--c),transparent);animation:hudscan 2.5s linear infinite}")
w("@keyframes hudscan{0%{top:0%}100%{top:100%}}")
w(".hud-label{font-size:7px;color:var(--text3);letter-spacing:2px;text-transform:uppercase;margin-bottom:3px}")
w(".hud-val{font-family:'Orbitron',sans-serif;font-size:15px;color:var(--c);line-height:1}")
w(".hud-unit{font-size:7px;color:var(--text3);margin-top:2px}")

# LAYER PANEL (right)
w(".layerpanel{position:fixed;top:52px;right:0;z-index:200;display:flex;flex-direction:column;gap:3px;padding:6px}")
w(".lbtn{background:var(--panel2);border:1px solid var(--border);color:var(--text2);font-family:'Share Tech Mono',monospace;font-size:9px;padding:6px 9px;cursor:pointer;letter-spacing:1px;text-align:center;transition:all .2s;width:78px}")
w(".lbtn:hover,.lbtn.on{color:var(--g);border-color:var(--g);background:rgba(0,255,136,.06)}")
w(".lsep{height:1px;background:var(--border);margin:2px 0}")

# COMPASS
w(".compass{position:fixed;top:62px;right:90px;z-index:200}")

# NOTIFICATION (daha yüksek z-index)
w(".notif{position:fixed;top:62px;left:50%;transform:translateX(-50%) translateY(-90px);background:var(--panel2);border:1px solid var(--border);padding:9px 18px;font-size:10px;color:var(--c);z-index:5000;transition:transform .3s cubic-bezier(.4,0,.2,1),opacity .3s;letter-spacing:1px;display:flex;align-items:center;gap:10px;white-space:nowrap;max-width:90vw;box-shadow:0 4px 24px rgba(0,0,0,.5);pointer-events:none}")
w(".notif.show{transform:translateX(-50%) translateY(0);pointer-events:all}")
w(".notif.err{color:var(--r);border-color:rgba(255,68,102,.35)}")
w(".notif.warn{color:var(--w);border-color:rgba(255,204,0,.35)}")
w(".notif.ok{color:var(--g);border-color:rgba(0,255,136,.3)}")
w(".notif-icon{width:16px;height:16px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:bold;flex-shrink:0;background:rgba(0,229,255,.15)}")
w(".notif.err .notif-icon{background:rgba(255,68,102,.15)}")
w(".notif.ok .notif-icon{background:rgba(0,255,136,.15)}")

# KEYBOARD HELP
w(".kbhelp{position:fixed;inset:0;background:rgba(2,8,16,.97);z-index:9000;display:none;align-items:center;justify-content:center;backdrop-filter:blur(8px)}")
w(".kbhelp.vis{display:flex}")
w(".kbbox{background:var(--bg3);border:1px solid var(--border);padding:30px;width:500px;max-width:95vw}")
w(".kbtitle{font-family:'Orbitron',sans-serif;font-size:14px;color:var(--g);letter-spacing:4px;margin-bottom:20px;display:flex;justify-content:space-between;align-items:center}")
w(".kbgrid{display:grid;grid-template-columns:1fr 1fr;gap:6px}")
w(".kbrow{display:flex;align-items:center;gap:10px;padding:5px 0;border-bottom:1px solid rgba(0,255,136,.05)}")
w(".kbkey{background:rgba(0,255,136,.07);border:1px solid rgba(0,255,136,.2);padding:2px 8px;font-size:9px;color:var(--g);font-family:'Orbitron',sans-serif;min-width:34px;text-align:center;white-space:nowrap}")
w(".kbdesc{font-size:10px;color:var(--text2)}")

# TRAIL LEGEND
w(".trail-legend{position:fixed;bottom:120px;left:16px;z-index:200;background:var(--panel2);border:1px solid var(--border);padding:8px 12px;display:none}")
w(".trail-legend.vis{display:block}")
w(".tl-title{font-size:8px;color:var(--text3);letter-spacing:2px;text-transform:uppercase;margin-bottom:6px}")
w(".tl-row{display:flex;align-items:center;gap:7px;margin-bottom:4px;font-size:9px;color:var(--text2)}")
w(".tl-dot{width:10px;height:4px;flex-shrink:0}")

# PROGRESS BAR
w(".refbar{position:fixed;bottom:0;left:0;right:0;height:2px;background:rgba(0,255,136,.05);z-index:999}")
w(".refprog{height:100%;background:linear-gradient(90deg,var(--g),var(--c));width:100%;box-shadow:0 0 4px var(--g);transition:width 0.3s linear}")

# MAPBOX
w(".mapboxgl-ctrl-bottom-left,.mapboxgl-ctrl-bottom-right{display:none!important}")
w(".mapboxgl-popup-content{background:var(--panel2)!important;border:1px solid var(--border)!important;color:var(--text)!important;font-family:'Share Tech Mono',monospace!important;font-size:10px!important;padding:10px 13px!important;border-radius:0!important;box-shadow:0 0 20px rgba(0,255,136,.08)!important}")
w(".mapboxgl-popup-tip{display:none!important}")
w(".mapboxgl-ctrl-top-right{top:52px!important;right:90px!important}")

# Responsive
w("@media(max-width:620px){.tstats .tsc:nth-child(n+4){display:none}.layerpanel{display:none}.hud{display:none}.radarwrap{display:none}}")

w("</style></head><body>")

# ══════════════════════════════════════════════════════════════════
# HTML ELEMENTS
# ══════════════════════════════════════════════════════════════════

# TOKEN MODAL
w("<div id='modal'>")
w("  <div class='mbox'>")
w("    <div class='mtitle'>MAPBOX API TOKEN</div>")
w("    <div class='msub'>UYDU HARiTA ERiSiMi</div>")
w("    <p class='mdesc'>")
w("      <a href='https://account.mapbox.com' target='_blank'>account.mapbox.com</a>")
w("      adresinden <b>ucretsiz</b> hesap olusturun.<br>")
w("      <b>Access Tokens</b> sayfasindan <b>pk.</b> ile baslayan token alin.<br><br>")
w("      Token olmadan <b>Demo Mod</b> ile devam edebilirsiniz.<br>")
w("      <span style='color:rgba(168,255,212,0.35)'>Demo modda harita arka plan olmaz, tum diger ozellikler aktiftir.</span>")
w("    </p>")
w("    <div class='msaved' id='msaved'><span>&#10003;</span><span id='msaved-txt'>Kayitli token</span></div>")
w("    <div class='mlabel'>TOKEN</div>")
w("    <input id='tokeninput' class='minput' type='text' placeholder='pk.eyJ1IjoiuserIiwiYSI6ImtleUlkIn0.XXXX' autocomplete='off' spellcheck='false'>")
w("    <div class='merr' id='merr'></div>")
w("    <div class='mbtns'>")
w("      <button class='mbtn-start' id='mbtnstart' onclick='doStart()'>&#9654;&nbsp;BASLAT</button>")
w("      <button class='mbtn-demo' id='mbtndemo' onclick='doDemo()'>DEMO MOD</button>")
w("    </div>")
w("    <div class='mhint'>ENTER = Baslat &nbsp;|&nbsp; TAB = Demo Mod &nbsp;|&nbsp; Token kayda alinir</div>")
w("  </div>")
w("</div>")

# LOADING
w("<div id='loading'>")
w("  <div class='ldlogo'>SKYWATCH</div>")
w("  <div class='ldsub'>CANLI UCAK TAKiP SiSTEMi v4.0</div>")
w("  <div class='ldbarwrap'><div class='ldbar' id='ldbar'></div></div>")
w("  <div class='ldstatus' id='ldstatus'>HAZIRLANIYOR...</div>")
w("</div>")

# KEYBOARD HELP
w("<div class='kbhelp' id='kbhelp'>")
w("  <div class='kbbox'>")
w("    <div class='kbtitle'>KLAVYE KiSAYOLLARI <span onclick='toggleHelp()' style='cursor:pointer;color:var(--o);font-size:20px'>&#215;</span></div>")
w("    <div class='kbgrid'>")
for k,d in [("F","Arama ac/kapat"),("R","Veriyi yenile"),("L","Sol paneli ac/kapat"),("S","Uydu katmani"),("D","Karanlik katmani"),("T","Sokak katmani"),("H","Hava durumu"),("N","Gece/gunduz"),("I","Ucak izleri (tumu)"),("C","Konumumu bul"),("X","Secimi kaldir"),("ESC","Kapat / Geri"),("?","Bu yardim ekrani"),("F11","Tam ekran")]:
    w(f"      <div class='kbrow'><div class='kbkey'>{k}</div><div class='kbdesc'>{d}</div></div>")
w("    </div>")
w("  </div>")
w("</div>")

# TOPBAR
w("<div class='topbar'>")
w("  <div class='tlogo'>")
w("    <svg width='20' height='20' viewBox='0 0 24 24' fill='none'><path d='M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z' fill='#00ff88'/><circle cx='12' cy='12' r='11' stroke='rgba(0,255,136,0.2)' stroke-width='1'/></svg>")
w("    SKYWATCH")
w("  </div>")
w("  <div class='tvbar'></div>")
w("  <div class='tstats'>")
w("    <div class='tsc'><div class='statusdot loading' id='sdot'></div><span id='sstatus'>BAGLANIYOR</span></div>")
w("    <div class='tsc'>&#9992;&nbsp;<span class='tval' id='scount'>0</span></div>")
w("    <div class='tsc'>GOR.:<span class='tval' id='svis'>0</span></div>")
w("    <div class='tsc'>ULKE:<span class='tval' id='scountry'>0</span></div>")
w("    <div class='tsc'>MAX:<span class='tval' id='smaxalt'>0</span>m</div>")
w("    <div class='tsc'>&#8635;<span class='tval' id='slastupd'>--:--</span></div>")
w("  </div>")
w("  <div class='tright'>")
w("    <div class='tclock' id='tclock'>00:00:00</div>")
w("    <button class='tbtn' onclick='toggleSearch()' title='Arama [F]'>&#128269;</button>")
w("    <button class='tbtn' onclick='doRefresh()' title='Yenile [R]'>&#8635;</button>")
w("    <button class='tbtn' onclick='gotoMe()' title='Konum [C]'>&#11788;</button>")
w("    <button class='tbtn' id='wxbtn' onclick='toggleWeather()' title='Hava [H]'>&#9928;</button>")
w("    <button class='tbtn' id='trmbn' onclick='toggleTerminator()' title='Gece/Gunduz [N]'>&#9788;</button>")
w("    <button class='tbtn' id='alltrailbtn' onclick='toggleAllTrails()' title='Tum izler [I]'>&#10148;</button>")
w("    <button class='tbtn' onclick='toggleHelp()' title='Yardim [?]'>?</button>")
w("    <button class='tbtn' onclick='doFullscreen()'>&#9974;</button>")
w("  </div>")
w("</div>")

# SEARCH
w("<div class='searchbar' id='searchbar'>")
w("  <div style='position:relative;flex:1'>")
w("    <input class='sinput' id='sinput' placeholder='Callsign, ulke, ICAO24...' oninput='doSearch(this.value)' onkeydown='searchKeydown(event)'>")
w("    <div class='sresults' id='sresults'></div>")
w("  </div>")
w("  <button class='scloseBtn' onclick='toggleSearch()'>&#215;</button>")
w("</div>")

# PANEL TOGGLE
w("<div class='ptoggle' id='ptoggle' onclick='togglePanel()'>&#9664;</div>")

# LEFT PANEL
w("<div class='lpanel' id='lpanel'>")
w("  <div class='tabs'>")
w("    <button class='tabbtn on' id='tab0' onclick='switchTab(0)'>UCUSLAR</button>")
w("    <button class='tabbtn' id='tab1' onclick='switchTab(1)'>iSTAT</button>")
w("    <button class='tabbtn' id='tab2' onclick='switchTab(2)'>ALARM</button>")
w("    <button class='tabbtn' id='tab3' onclick='switchTab(3)'>AYAR</button>")
w("  </div>")

# Tab 0 - Flights
w("  <div class='tabpanel on' id='tp0'>")
# Slider
w("    <div class='slider-section'>")
w("      <div class='slider-row'>")
w("        <span class='slider-label'>HARiTA UCAK LiMiTi</span>")
w("        <span class='slider-val' id='sliderval'>150</span>")
w("      </div>")
w("      <input type='range' class='slider' id='limitslider' min='10' max='500' value='150' step='10' oninput='onSlider(this.value)'>")
w("      <div class='perf-row'>")
w("        <button class='perf-btn' onclick='setPerf(\"eco\")' id='perf-eco'>ECO</button>")
w("        <button class='perf-btn on' onclick='setPerf(\"normal\")' id='perf-normal'>NORMAL</button>")
w("        <button class='perf-btn' onclick='setPerf(\"ultra\")' id='perf-ultra'>ULTRA</button>")
w("      </div>")
w("    </div>")
# Filters
w("    <div class='fbar'>")
w("      <button class='fchip on' id='fc-all' onclick='setFilter(\"all\")'>TUMU</button>")
w("      <button class='fchip' id='fc-high' onclick='setFilter(\"high\")'>Y.ALT</button>")
w("      <button class='fchip' id='fc-fast' onclick='setFilter(\"fast\")'>HIZ</button>")
w("      <button class='fchip' id='fc-tr' onclick='setFilter(\"tr\")'>TR</button>")
w("      <button class='fchip red' id='fc-emg' onclick='setFilter(\"emg\")'>ACiL</button>")
w("    </div>")
w("    <div class='fcountbar'><span><span id='fcount'>0</span> UCAK LISTEDE</span><span id='ftotal' style='color:var(--text3)'></span></div>")
w("    <div id='flist' style='flex:1;overflow-y:auto;scrollbar-width:thin;scrollbar-color:rgba(0,255,136,.15) transparent'>")
w("      <div style='padding:22px;text-align:center;color:var(--text3);font-size:11px;letter-spacing:2px'>VERi YUKLENiYOR...</div>")
w("    </div>")
w("  </div>")

# Tab 1 - Stats
w("  <div class='tabpanel' id='tp1'>")
w("    <div class='stblock'>")
w("      <div class='sthead'>GENEL OZET</div>")
w("      <div class='bigstat'>")
w("        <div class='bsi'><div class='bsv' id='st-total'>0</div><div class='bsl'>TOPLAM UCAK</div></div>")
w("        <div class='bsi'><div class='bsv' id='st-country'>0</div><div class='bsl'>ULKE</div></div>")
w("        <div class='bsi'><div class='bsv' id='st-avgalt'>0</div><div class='bsl'>ORT YUK (m)</div></div>")
w("        <div class='bsi'><div class='bsv' id='st-avgspd'>0</div><div class='bsl'>ORT HIZ</div></div>")
w("        <div class='bsi'><div class='bsv' id='st-maxspd'>0</div><div class='bsl'>MAX HIZ</div></div>")
w("        <div class='bsi'><div class='bsv' id='st-maxalt'>0</div><div class='bsl'>MAX YUK (m)</div></div>")
w("      </div>")
w("    </div>")
w("    <div class='stblock'><div class='sthead'>ULKE SIRASI</div><div id='st-countries'></div></div>")
w("    <div class='stblock'><div class='sthead'>HIZ DAGILIMI (km/s)</div><div id='st-speeds'></div></div>")
w("    <div class='stblock'><div class='sthead'>YUKSEKLIK (m)</div><div id='st-alts'></div></div>")
w("    <div class='stblock'><div class='sthead'>AIRLINE SIRASI</div><div id='st-airlines'></div></div>")
w("  </div>")

# Tab 2 - Alerts
w("  <div class='tabpanel' id='tp2'>")
w("    <div style='padding:7px 12px;border-bottom:1px solid rgba(0,255,136,.06);font-size:9px;color:var(--text3);letter-spacing:2px;display:flex;justify-content:space-between;align-items:center;flex-shrink:0'>")
w("      <span id='alertheader'>ALARMLAR</span>")
w("      <button class='fchip' onclick='clearAlerts()' style='font-size:8px;padding:2px 7px'>TEMIZLE</button>")
w("    </div>")
w("    <div id='alertlist'><div class='no-alerts'>ALARM YOK</div></div>")
w("  </div>")

# Tab 3 - Settings
w("  <div class='tabpanel' id='tp3'>")
w("    <div class='sett-section'>HARiTA</div>")
w("    <div class='settrow'><span class='settlabel'>Ucus izleri goster</span><div class='toggle-sw' id='sw-trail' onclick='toggleSetting(\"trail\")'></div></div>")
w("    <div class='settrow'><span class='settlabel'>Yer uzerindeki ucaklar</span><div class='toggle-sw' id='sw-ground' onclick='toggleSetting(\"ground\")'></div></div>")
w("    <div class='settrow'><span class='settlabel'>Havaalani katmani</span><div class='toggle-sw on' id='sw-airports' onclick='toggleSetting(\"airports\")'></div></div>")
w("    <div class='settrow'><span class='settlabel'>Animasyonlu ucak</span><div class='toggle-sw on' id='sw-anim' onclick='toggleSetting(\"anim\")'></div></div>")
w("    <div class='sett-section'>PERFORMANS</div>")
w("    <div class='settrow'><span class='settlabel'>Yenileme suresi</span><span class='settval' id='rf-val'>30s</span></div>")
w("    <div style='padding:6px 12px;flex-shrink:0'><input type='range' class='slider' id='rfslider' min='15' max='120' value='30' step='5' oninput='onRfSlider(this.value)'></div>")
w("    <div class='sett-section'>DiSA AKTAR</div>")
w("    <div class='settrow'><span class='settlabel'>JSON aktar</span><button class='expbtn' onclick='exportJSON()'>&#11015; JSON</button></div>")
w("    <div class='settrow'><span class='settlabel'>CSV aktar</span><button class='expbtn' onclick='exportCSV()'>&#11015; CSV</button></div>")
w("    <div class='sett-section'>TOKEN</div>")
w("    <div class='settrow'><span class='settlabel'>Kayitli token</span><button class='expbtn' onclick='clearToken()' style='color:var(--r);border-color:rgba(255,68,102,.3)'>SIL</button></div>")
w("  </div>")
w("</div><!-- lpanel -->")

# MAP
w("<div id='map'></div>")

# TRAIL LEGEND
w("<div class='trail-legend' id='trail-legend'>")
w("  <div class='tl-title'>iZ RENK KODLARI</div>")
w("  <div class='tl-row'><div class='tl-dot' style='background:#00ff88'></div><span>Alcak (&lt;3km)</span></div>")
w("  <div class='tl-row'><div class='tl-dot' style='background:#00e5ff'></div><span>Orta (3-6km)</span></div>")
w("  <div class='tl-row'><div class='tl-dot' style='background:#ffcc00'></div><span>Yuksek (6-9km)</span></div>")
w("  <div class='tl-row'><div class='tl-dot' style='background:#ff4466'></div><span>Cok yuksek (&gt;9km)</span></div>")
w("</div>")

# LAYER PANEL
w("<div class='layerpanel'>")
w("  <button class='lbtn on' id='lbsat' onclick='setLayer(\"satellite\")'>&#128752; UYDU</button>")
w("  <button class='lbtn' id='lbdrk' onclick='setLayer(\"dark\")'>&#127769; KARANLIK</button>")
w("  <button class='lbtn' id='lbstr' onclick='setLayer(\"street\")'>&#128506; SOKAK</button>")
w("</div>")

# COMPASS
w("<div class='compass'><canvas id='compass' width='46' height='46'></canvas></div>")

# INFO PANEL
w("<div class='infopanel' id='infopanel'>")
w("  <div class='infohead'>")
w("    <span id='info-call'>---</span>")
w("    <div class='infohead-acts'>")
w("      <button class='itrailbtn' id='trailbtn' onclick='toggleSelTrail()'>iZ</button>")
w("      <span class='closex' onclick='closeInfo()'>&#215;</span>")
w("    </div>")
w("  </div>")
w("  <div class='infogrid'>")
w("    <div class='ifield'><div class='ilabel'>ULKE</div><div class='ival blue' id='inf-co'>---</div></div>")
w("    <div class='ifield'><div class='ilabel'>YUKSEKLIK</div><div class='ival' id='inf-alt'>---</div></div>")
w("    <div class='ifield'><div class='ilabel'>HIZ (km/s)</div><div class='ival' id='inf-spd'>---</div></div>")
w("    <div class='ifield'><div class='ilabel'>ROTA</div><div class='ival' id='inf-hdg'>---</div></div>")
w("    <div class='ifield'><div class='ilabel'>ENLEM</div><div class='ival' id='inf-lat'>---</div></div>")
w("    <div class='ifield'><div class='ilabel'>BOYLAM</div><div class='ival' id='inf-lon'>---</div></div>")
w("    <div class='ifield'><div class='ilabel'>SQUAWK</div><div class='ival' id='inf-sqk'>---</div></div>")
w("    <div class='ifield'><div class='ilabel'>DURUM</div><div class='ival' id='inf-grnd'>---</div></div>")
w("    <div class='ifield'><div class='ilabel'>DIKEY HIZ</div><div class='ival' id='inf-vs'>---</div></div>")
w("    <div class='ifield'><div class='ilabel'>ICAO24</div><div class='ival' style='font-size:10px' id='inf-icao'>---</div></div>")
w("  </div>")
w("  <div class='spdwrap'><div class='spdlabel'>0</div><div class='spdtrack'><div class='spdfill' id='spdgauge'></div></div><div class='spdlabel'>1200+</div></div>")
# Speed history mini chart
w("  <div class='spdhist'>")
w("    <div class='spdhist-label'>HIZ GECMiSi</div>")
w("    <canvas id='spdhist-canvas' width='274' height='36'></canvas>")
w("  </div>")
w("  <div class='infobtns'>")
w("    <button class='iabtn' onclick='flyToSel()'>&#9992; GiT</button>")
w("    <button class='iabtn' onclick='copyCoords()'>&#128203; KOORD</button>")
w("    <button class='iabtn' onclick='openFA()'>FA&#8599;</button>")
w("    <button class='iabtn' onclick='openFR24()'>FR24&#8599;</button>")
w("  </div>")
w("</div>")

# RADAR
w("<div class='radarwrap'>")
w("  <div class='radarhead'>RADAR&nbsp;<span class='radarcnt' id='radarcnt'>0</span></div>")
w("  <canvas id='radarc' width='100' height='100'></canvas>")
w("</div>")

# HUD
w("<div class='hud' id='hud'>")
w("  <div class='hud-m'><div class='hud-label'>YUKSEKLIK</div><div class='hud-val' id='hud-alt'>---</div><div class='hud-unit'>m</div></div>")
w("  <div class='hud-m'><div class='hud-label'>HIZ</div><div class='hud-val' id='hud-spd'>---</div><div class='hud-unit'>km/s</div></div>")
w("  <div class='hud-m'><div class='hud-label'>ROTA</div><div class='hud-val' id='hud-hdg'>---</div><div class='hud-unit'>deg</div></div>")
w("  <div class='hud-m'><div class='hud-label'>DiKEY</div><div class='hud-val' id='hud-vs'>---</div><div class='hud-unit'>m/s</div></div>")
w("</div>")

# NOTIFICATION
w("<div class='notif' id='notif'><div class='notif-icon' id='notif-icon'>i</div><span id='notif-msg'></span></div>")

# REFRESH BAR
w("<div class='refbar'><div class='refprog' id='refprog'></div></div>")

# ══════════════════════════════════════════════════════════════════
# JAVASCRIPT (tüm düzeltmelerle)
# ══════════════════════════════════════════════════════════════════
w("<script>")

# ── STATE ─────────────────────────────────────────────────────────
js("""
var MAP=null, TOKEN='', DEMO=false;
var flights=[], filteredFlights=[], selIcao=null;
var activeFilter='all', markerLimit=150, perfMode='normal';
var panelOpen=true, searchOpen=false, helpOpen=false;
var curLayer='satellite', weatherOn=false, terminatorOn=false;
var showAllTrails=false;
var markers={}, trailData={}, trailEnabled={}, speedHistory={};
var alerts=[], rfTimer=null, radarAngle=0;
var RF=30000;
var settings={trail:false, ground:false, airports:true, anim:true};

var FLAGS={Turkey:'TR',Germany:'DE','United Kingdom':'GB',France:'FR',
  'United States':'US',Spain:'ES',Italy:'IT',Netherlands:'NL',
  Russia:'RU','United Arab Emirates':'AE',Qatar:'QA','Saudi Arabia':'SA',
  China:'CN',Japan:'JP',Australia:'AU',Canada:'CA',Brazil:'BR',
  India:'IN','South Korea':'KR',Switzerland:'CH',Poland:'PL',
  Austria:'AT',Greece:'GR',Portugal:'PT',Ukraine:'UA',Romania:'RO',
  Sweden:'SE',Norway:'NO',Denmark:'DK',Finland:'FI',Belgium:'BE',
  'Czech Republic':'CZ',Hungary:'HU',Bulgaria:'BG',Croatia:'HR',
  Serbia:'RS',Slovakia:'SK',Slovenia:'SI',Lithuania:'LT',Latvia:'LV',
  Estonia:'EE',Israel:'IL',Egypt:'EG',Morocco:'MA','South Africa':'ZA',
  Argentina:'AR',Chile:'CL',Mexico:'MX',Colombia:'CO','New Zealand':'NZ',
  Singapore:'SG',Malaysia:'MY',Thailand:'TH',Indonesia:'ID',Philippines:'PH'
};

function flag(c){
  var code=FLAGS[c];
  if(!code)return '&#127988;';
  return code.split('').map(function(x){return String.fromCodePoint(127397+x.charCodeAt(0));}).join('');
}
""")

# ── NOTIFY (yüksek z-index) ───────────────────────────────────────
js("""
function notify(msg, type){
  type = type||'info';
  var el=document.getElementById('notif');
  var ic=document.getElementById('notif-icon');
  var mc=document.getElementById('notif-msg');
  ic.textContent = type==='err'?'!' : type==='warn'?'?' : type==='ok'?'✓' : 'i';
  mc.textContent = msg;
  el.className = 'notif show' + (type==='err'?' err':type==='warn'?' warn':type==='ok'?' ok':'');
  clearTimeout(el._t);
  el._t = setTimeout(function(){el.classList.remove('show');}, 3800);
}
""")

# ── MODAL (düzeltilmiş) ───────────────────────────────────────────
js("""
window.addEventListener('load', function(){
  var saved = localStorage.getItem('skyw4_token');
  if(saved && saved.length > 10){
    document.getElementById('tokeninput').value = saved;
    var sv = document.getElementById('msaved');
    document.getElementById('msaved-txt').textContent = saved.slice(0,20)+'...';
    sv.classList.add('show');
  }
  document.getElementById('tokeninput').addEventListener('keydown', function(e){
    if(e.key==='Enter') doStart();
    if(e.key==='Tab'){ e.preventDefault(); doDemo(); }
  });
});

function setModalErr(msg){
  var e = document.getElementById('merr');
  e.innerHTML = msg ? '<span>&#9888;</span> '+msg : '';
}

function doStart(){
  var v = document.getElementById('tokeninput').value.trim();
  setModalErr('');
  if(!v){ setModalErr('Token bos birakilamaz'); return; }
  if(v.length < 10){ setModalErr('Token cok kisa, en az 10 karakter'); return; }
  TOKEN = v;
  localStorage.setItem('skyw4_token', v);
  lockModal();
  boot(false).catch(function(err){
    console.error(err);
    setModalErr('Baslatma hatasi: ' + (err.message || 'bilinmeyen hata'));
    unlockModal();
  });
}

function doDemo(){
  DEMO = true;
  lockModal();
  boot(true).catch(function(err){
    console.error(err);
    setModalErr('Demo baslatma hatasi: ' + (err.message || 'bilinmeyen hata'));
    unlockModal();
  });
}

function lockModal(){
  document.getElementById('mbtnstart').disabled = true;
  document.getElementById('mbtndemo').disabled = true;
  document.getElementById('modal').classList.add('gone');
}

function unlockModal(){
  document.getElementById('mbtnstart').disabled = false;
  document.getElementById('mbtndemo').disabled = false;
  document.getElementById('modal').classList.remove('gone');
}
""")

# ── BOOT (loading göster) ─────────────────────────────────────────
js("""
async function boot(demo){
  var ld = document.getElementById('loading');
  var bar = document.getElementById('ldbar');
  var status = document.getElementById('ldstatus');
  ld.classList.add('on');

  var steps = [
    [10,  'SISTEM BASLATILIYOR...'],
    [22,  'OPENSKY API BAGLANTISI...'],
    [40,  'HARITA KATMANLARI YUKLENIYOR...'],
    [58,  'UCAK VERITABANI OLUSTURULUYOR...'],
    [72,  'RADAR AKTIF EDILIYOR...'],
    [85,  'PERFORMANS OPTIMIZE EDILIYOR...'],
    [95,  'GOSTERIM MOTORU HAZIRLANIYOR...'],
    [100, 'HAZIR!']
  ];

  for(var i=0;i<steps.length;i++){
    bar.style.width = steps[i][0]+'%';
    status.textContent = steps[i][1];
    await sleep(260);
  }
  await sleep(160);

  ld.style.transition = 'opacity .5s';
  ld.style.opacity = '0';
  await sleep(500);
  ld.classList.remove('on');
  ld.style.opacity = '';
  ld.style.transition = '';

  if(demo) initNoMap(); else initMap();
  startClock();
  startRadar();
  startCompass();
  setupKeys();
  await loadFlights();
  startRefTimer();
}

function sleep(ms){ return new Promise(function(r){setTimeout(r,ms);}); }
""")

# ── MAP ───────────────────────────────────────────────────────────
js("""
function initMap(){
  mapboxgl.accessToken = TOKEN;
  MAP = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/mapbox/satellite-v9',
    center: [35, 40], zoom: 4, antialias: true
  });
  MAP.addControl(new mapboxgl.NavigationControl({showCompass:false}), 'top-right');
  MAP.on('load', function(){
    setSdot('live');
    addTrailSources();
  });
  MAP.on('error', function(e){
    setSdot('error');
    notify('Harita hatasi! Token gecerli mi?', 'err');
  });
  MAP.on('rotate', function(){ drawCompass(MAP.getBearing()); });
  MAP.on('zoom', function(){ drawCompass(MAP.getBearing()); });
}

function initNoMap(){
  setSdot('demo');
  var m = document.getElementById('map');
  m.style.background = 'radial-gradient(ellipse at 50% 40%, #030f1e 0%, #020810 100%)';
  var c = document.createElement('canvas');
  c.style.cssText = 'position:absolute;inset:0;width:100%;height:100%';
  m.appendChild(c);
  c.width = window.innerWidth; c.height = window.innerHeight;
  var ctx = c.getContext('2d');
  ctx.strokeStyle='rgba(0,255,136,0.04)'; ctx.lineWidth=1;
  for(var x=0;x<c.width;x+=60){ ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,c.height);ctx.stroke(); }
  for(var y=0;y<c.height;y+=60){ ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(c.width,y);ctx.stroke(); }
  ctx.fillStyle='rgba(168,255,212,0.3)';
  for(var i=0;i<120;i++){
    var sx=Math.random()*c.width, sy=Math.random()*c.height;
    ctx.beginPath(); ctx.arc(sx,sy,Math.random()*.8+.2,0,Math.PI*2); ctx.fill();
  }
}

function setSdot(state){
  var d=document.getElementById('sdot'), s=document.getElementById('sstatus');
  d.className='statusdot';
  var map={live:['','CANLI'],loading:['loading','YUKLENIYOR'],error:['error','HATA'],demo:['demo','DEMO']};
  var v=map[state]||['','?'];
  if(v[0]) d.classList.add(v[0]);
  s.textContent=v[1];
}
""")

# ── LAYER ─────────────────────────────────────────────────────────
js("""
var LAYERS = {
  satellite: 'mapbox://styles/mapbox/satellite-v9',
  dark:      'mapbox://styles/mapbox/dark-v11',
  street:    'mapbox://styles/mapbox/streets-v12'
};

function setLayer(l){
  if(DEMO||!MAP) return;
  curLayer = l;
  var ids={satellite:'lbsat',dark:'lbdrk',street:'lbstr'};
  Object.keys(ids).forEach(function(k){ document.getElementById(ids[k]).classList.toggle('on',k===l); });
  MAP.setStyle(LAYERS[l]);
  MAP.once('style.load', function(){ addTrailSources(); redrawMarkers(); });
  notify(l.toUpperCase()+' KATMANI', 'info');
}
""")

# ── TERMINATOR ────────────────────────────────────────────────────
js("""
function toggleTerminator(){
  terminatorOn=!terminatorOn;
  document.getElementById('trmbn').classList.toggle('on',terminatorOn);
  if(terminatorOn) drawTerminator();
  else if(MAP && MAP.isStyleLoaded()){ try{if(MAP.getLayer('trm'))MAP.removeLayer('trm'); if(MAP.getSource('trm'))MAP.removeSource('trm');}catch(e){} }
  notify('GECE/GUNDUZ '+(terminatorOn?'AKTIF':'KAPALI'), 'info');
}

function drawTerminator(){
  if(!MAP || !MAP.isStyleLoaded()) return;
  var d=new Date();
  var dec = -23.45 * Math.cos((360/365*(d.getMonth()*30+d.getDate())+10)*Math.PI/180) * Math.PI/180;
  var coords=[];
  for(var lon=-180;lon<=180;lon+=2){
    var lat=Math.atan(-Math.cos(lon*Math.PI/180)/Math.tan(dec))*180/Math.PI;
    coords.push([lon,lat]);
  }
  coords.push([180,-90],[180,90],[-180,90],[-180,coords[0][1]],coords[0]);
  try{
    if(MAP.getSource('trm'))MAP.removeLayer('trm'),MAP.removeSource('trm');
    MAP.addSource('trm',{type:'geojson',data:{type:'Feature',geometry:{type:'Polygon',coordinates:[coords]}}});
    MAP.addLayer({id:'trm',type:'fill',source:'trm',paint:{'fill-color':'#000018','fill-opacity':0.42}});
  }catch(e){}
}
""")

# ── WEATHER ───────────────────────────────────────────────────────
js("""
function toggleWeather(){
  weatherOn=!weatherOn;
  document.getElementById('wxbtn').classList.toggle('on',weatherOn);
  notify('HAVA DURUMU '+(weatherOn?'AKTIF':'KAPALI'), 'info');
  if(!MAP||DEMO) return;
  if(weatherOn){
    try{
      if(!MAP.isStyleLoaded()){
        notify('Harita yukleniyor, tekrar deneyin','warn');
        weatherOn=false;
        return;
      }
      MAP.addSource('owm',{type:'raster',tiles:['https://tile.openweathermap.org/map/clouds_new/{z}/{x}/{y}.png?appid=439d4b804bc8187953eb36d2a8c26a02'],tileSize:256,attribution:'OpenWeatherMap'});
      MAP.addLayer({id:'owmlayer',type:'raster',source:'owm',paint:{'raster-opacity':0.4}});
    }catch(e){ notify('Hava katmani yuklenemedi','warn'); }
  }else{
    try{ if(MAP.getLayer('owmlayer'))MAP.removeLayer('owmlayer'); if(MAP.getSource('owm'))MAP.removeSource('owm'); }catch(e){}
  }
}
""")

# ── OPENSKY + PARSE ───────────────────────────────────────────────
js("""
var OPENSKY_ENDPOINTS = [
  'https://opensky-network.org/api/states/all?lamin=25&lomin=-20&lamax=72&lomax=55',
  'https://opensky-network.org/api/states/all'
];

async function fetchFlights(){
  for(var i=0;i<OPENSKY_ENDPOINTS.length;i++){
    try{
      var ctrl = new AbortController();
      var tid = setTimeout(function(){ctrl.abort();}, 15000);
      var r = await fetch(OPENSKY_ENDPOINTS[i], {signal:ctrl.signal});
      clearTimeout(tid);
      if(!r.ok) continue;
      var d = await r.json();
      return (d.states || []);
    }catch(e){ continue; }
  }
  notify('OpenSky API ulasılamadi — demo veri kullaniliyor', 'warn');
  return generateDemo();
}

function parseState(s){
  return {
    icao24:   s[0] || '',
    callsign: (s[1]||'').trim() || s[0] || '????',
    country:  s[2] || 'Unknown',
    lon:      s[5], lat: s[6],
    alt:      s[7]  ? Math.round(s[7])  : null,
    ground:   s[8]  || false,
    vel:      s[9]  ? Math.round(s[9]*3.6) : null,
    hdg:      s[10] !== null ? Math.round(s[10]) : null,
    vs:       s[11] ? Math.round(s[11]) : 0,
    sqk:      s[14] || '----'
  };
}

function generateDemo(){
  var airlines=['TK','LH','BA','AF','EK','QR','SU','PC','FR','W6','IBE','KLM','SAS','THY','AUA','SWR','TAP','WZZ','RYR','EZY'];
  var countries=Object.keys(FLAGS).slice(0,18);
  return Array.from({length:120}, function(_,i){
    var al=airlines[i%airlines.length], co=countries[i%countries.length];
    return [
      'dm'+String(i).padStart(3,'0'), al+(200+i)+'  ', co,
      null, null,
      8+Math.random()*52, 28+Math.random()*38,
      800+Math.random()*13000, false,
      80+Math.random()*1000, Math.random()*360,
      (Math.random()-.5)*14, null, null,
      Math.floor(1000+Math.random()*8999)
    ];
  });
}
""")

# ── LOAD FLIGHTS ──────────────────────────────────────────────────
js("""
async function loadFlights(){
  setSdot('loading');
  var raw = await fetchFlights();
  flights = raw.map(parseState).filter(function(f){
    return f.lat && f.lon && (settings.ground || !f.ground);
  });

  if(selIcao){
    var sf = flights.find(function(f){return f.icao24===selIcao;});
    if(sf && sf.vel){
      if(!speedHistory[selIcao]) speedHistory[selIcao]=[];
      speedHistory[selIcao].push(sf.vel);
      if(speedHistory[selIcao].length>30) speedHistory[selIcao].shift();
    }
  }

  var countries = new Set(flights.map(function(f){return f.country;}));
  var alts = flights.filter(function(f){return f.alt;});
  document.getElementById('scount').textContent = flights.length;
  document.getElementById('scountry').textContent = countries.size;
  document.getElementById('smaxalt').textContent = alts.length ? Math.max.apply(null,alts.map(function(f){return f.alt;})) : 0;
  document.getElementById('slastupd').textContent = new Date().toTimeString().slice(0,5);

  setSdot(DEMO?'demo':'live');
  checkAlerts();
  updateStats();
  applyFilterAndRender();
  updateAllTrails();
  if(MAP) redrawMarkers();
  if(selIcao) refreshInfoPanel();
}

function doRefresh(){ resetRefTimer(); loadFlights(); notify('VERi YENiLENDi','ok'); }
""")

# ── FILTER & RENDER LIST ──────────────────────────────────────────
js("""
function setFilter(f){
  activeFilter = f;
  ['all','high','fast','tr','emg'].forEach(function(x){
    var el=document.getElementById('fc-'+x);
    if(el) el.classList.toggle('on', x===f);
  });
  applyFilterAndRender();
}

function applyFilterAndRender(){
  filteredFlights = flights.filter(function(f){
    if(activeFilter==='all')  return true;
    if(activeFilter==='high') return f.alt && f.alt>9000;
    if(activeFilter==='fast') return f.vel && f.vel>800;
    if(activeFilter==='tr')   return f.country==='Turkey';
    if(activeFilter==='emg')  return f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
    return true;
  });
  document.getElementById('fcount').textContent = filteredFlights.length;
  document.getElementById('ftotal').textContent = '/ '+flights.length;
  document.getElementById('svis').textContent = Math.min(markerLimit, filteredFlights.length);
  renderList();
}

function renderList(){
  var fl = document.getElementById('flist');
  var frag = document.createDocumentFragment();
  fl.innerHTML = '';

  filteredFlights.slice(0, 200).forEach(function(f){
    var emg = f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
    var highAlt = f.alt && f.alt > 9000;
    var altPct = f.alt ? Math.min(100, f.alt/130) : 0;
    var altColor = f.alt>9000?'#ff4466':f.alt>6000?'#ffcc00':f.alt>3000?'#00e5ff':'#00ff88';
    var d = document.createElement('div');
    d.className = 'fitem' + (f.icao24===selIcao?' sel':'') + (emg?' emerg':'');
    var badge = emg ? '<span class="fbadge emerg">ACiL</span>' : highAlt ? '<span class="fbadge high">HIGH</span>' : '';
    d.innerHTML =
      '<div class="fcall"><span class="fflag">'+flag(f.country)+'</span>'+f.callsign+badge+'</div>'+
      '<div class="fdetail">'+
        '<span class="fdv">'+f.country.slice(0,12)+'</span>'+
        '<span>&#9650;<span class="fdv">'+(f.alt?f.alt+'m':'--')+'</span></span>'+
        '<span>&#10148;<span class="fdv">'+(f.vel?f.vel:'--')+'</span></span>'+
        (f.hdg!==null?'<span>'+f.hdg+'&#176;</span>':'')+'</div>'+
      '<div class="faltbar"><div class="faltfill" style="width:'+altPct+'%;background:'+altColor+'"></div></div>';
    d.onclick = (function(ff){return function(){pickFlight(ff);};})(f);
    frag.appendChild(d);
  });
  fl.appendChild(frag);
}
""")

# ── MARKERS (canvas-based for performance) ────────────────────────
js("""
function redrawMarkers(){
  if(!MAP) return;
  Object.values(markers).forEach(function(m){m.remove();});
  markers = {};

  var toShow = filteredFlights.length ? filteredFlights : flights;
  toShow = toShow.slice(0, markerLimit);

  toShow.forEach(function(f){
    var el = createMarkerEl(f);
    var m = new mapboxgl.Marker({element:el, anchor:'center'})
      .setLngLat([f.lon, f.lat])
      .addTo(MAP);
    el.addEventListener('click', (function(ff){return function(e){e.stopPropagation();pickFlight(ff);};})(f));
    markers[f.icao24] = m;
  });
}

function createMarkerEl(f){
  var sel = f.icao24 === selIcao;
  var emg = f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
  var color = emg?'#ff4466' : sel?'#00e5ff' : f.alt>9000?'#ffcc00' : f.alt>3000?'#00ff88' : '#88ffcc';
  var sz = sel?22:14;
  var hdg = f.hdg||0;

  var el = document.createElement('div');
  el.style.cssText = 'width:'+sz+'px;height:'+sz+'px;cursor:pointer;will-change:transform;';
  if(emg) el.style.animation='blink .5s infinite';

  el.innerHTML = '<svg viewBox="0 0 24 24" fill="none" style="transform:rotate('+hdg+'deg);width:100%;height:100%">'
    + '<path d="M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z" fill="'+color+'" opacity="0.95"/>'
    + '<circle cx="12" cy="12" r="11" stroke="'+color+'" stroke-opacity="0.2" stroke-width="0.5"/>'
    + (sel?'<circle cx="12" cy="12" r="4" fill="'+color+'" opacity="0.5"/>':'')
    + '</svg>';

  if(sel){
    el.style.filter = 'drop-shadow(0 0 8px '+color+') drop-shadow(0 0 3px '+color+')';
  } else {
    el.style.filter = 'drop-shadow(0 0 3px '+color+')';
  }
  return el;
}
""")

# ── TRAIL SYSTEM ──────────────────────────────────────────────────
js("""
function addTrailSources(){}
function getTrailColor(alt){
  if(!alt) return '#00ff88';
  if(alt > 9000) return '#ff4466';
  if(alt > 6000) return '#ffcc00';
  if(alt > 3000) return '#00e5ff';
  return '#00ff88';
}
function updateTrailForFlight(f){
  if(!MAP || !f.lat || !f.lon) return;
  var icao = f.icao24;
  if(!trailData[icao]) trailData[icao]=[];
  trailData[icao].push({coords:[f.lon,f.lat],alt:f.alt,ts:Date.now()});
  if(trailData[icao].length>120) trailData[icao].shift();
  renderTrailOnMap(icao);
}
function renderTrailOnMap(icao){
  if(!MAP || !MAP.isStyleLoaded()) return;
  var pts = trailData[icao];
  if(!pts || pts.length<2) return;
  var segments=[];
  for(var i=1;i<pts.length;i++){
    segments.push({coords:[pts[i-1].coords,pts[i].coords],color:getTrailColor(pts[i].alt)});
  }
  try{
    var style=MAP.getStyle();
    var toRemove=(style.layers||[]).filter(function(l){return l.id.startsWith('trail-'+icao+'-');});
    toRemove.forEach(function(l){try{MAP.removeLayer(l.id);}catch(e){}});
    var srcRemove=Object.keys(style.sources||{}).filter(function(s){return s.startsWith('trsrc-'+icao+'-');});
    srcRemove.forEach(function(s){try{MAP.removeSource(s);}catch(e){}});
  }catch(e){}
  var colorGroups={};
  segments.forEach(function(seg){
    if(!colorGroups[seg.color]) colorGroups[seg.color]=[];
    colorGroups[seg.color].push(seg.coords);
  });
  Object.keys(colorGroups).forEach(function(color,ci){
    var srcId='trsrc-'+icao+'-'+ci, lyrId='trail-'+icao+'-'+ci;
    var lines=colorGroups[color].map(function(coords){return {type:'Feature',geometry:{type:'LineString',coordinates:coords}};});
    try{
      MAP.addSource(srcId,{type:'geojson',data:{type:'FeatureCollection',features:lines}});
      MAP.addLayer({id:lyrId,type:'line',source:srcId,paint:{'line-color':color,'line-width':['interpolate',['linear'],['zoom'],4,1.5,10,3],'line-opacity':0.7,'line-blur':0.5}});
    }catch(e){}
  });
}
function updateAllTrails(){
  if(!MAP || !MAP.isStyleLoaded()) return;
  flights.forEach(function(f){ if(trailEnabled[f.icao24]||showAllTrails) updateTrailForFlight(f); });
}
function clearTrailForFlight(icao){
  if(!MAP||!MAP.isStyleLoaded()) return;
  delete trailData[icao];
  try{
    var style=MAP.getStyle();
    if(!style) return;
    (style.layers||[]).filter(function(l){return l.id.startsWith('trail-'+icao+'-');}).forEach(function(l){try{MAP.removeLayer(l.id);}catch(e){}});
    Object.keys(style.sources||{}).filter(function(s){return s.startsWith('trsrc-'+icao+'-');}).forEach(function(s){try{MAP.removeSource(s);}catch(e){}});
  }catch(e){}
}
function clearAllTrails(){ Object.keys(trailData).forEach(function(icao){ clearTrailForFlight(icao); }); trailData={}; trailEnabled={}; notify('TUM iZLER TENiZLENDi','info'); }
function toggleSelTrail(){
  if(!selIcao) return;
  trailEnabled[selIcao]=!trailEnabled[selIcao];
  document.getElementById('trailbtn').classList.toggle('on',trailEnabled[selIcao]);
  if(!trailEnabled[selIcao]) clearTrailForFlight(selIcao);
  else{ var f=flights.find(function(x){return x.icao24===selIcao;}); if(f)updateTrailForFlight(f); }
  notify('iZ '+(trailEnabled[selIcao]?'AKTIF':'KAPALI'),'info');
}
function toggleAllTrails(){
  showAllTrails=!showAllTrails;
  document.getElementById('alltrailbtn').classList.toggle('on',showAllTrails);
  var legend=document.getElementById('trail-legend');
  legend.classList.toggle('vis',showAllTrails);
  if(!showAllTrails){ clearAllTrails(); }
  else{ updateAllTrails(); notify('TUM iZLER AKTIF (performansi dusurebilir)','warn'); }
}
""")

# ── SELECT FLIGHT & INFO PANEL ────────────────────────────────────
js("""
function pickFlight(f){
  selIcao = f.icao24;
  if(!speedHistory[f.icao24]) speedHistory[f.icao24]=[];
  if(f.vel) speedHistory[f.icao24].push(f.vel);
  refreshInfoPanel();
  if(MAP && f.lat && f.lon) MAP.flyTo({center:[f.lon,f.lat], zoom:7, speed:1.5, curve:1.2});
  renderList();
  if(MAP) redrawMarkers();
}
function refreshInfoPanel(){
  var f = flights.find(function(x){return x.icao24===selIcao;});
  if(!f) return;
  var emg = f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
  document.getElementById('info-call').textContent = f.callsign;
  document.getElementById('inf-co').textContent = flag(f.country)+' '+f.country.slice(0,16);
  var altEl=document.getElementById('inf-alt');
  altEl.textContent = f.alt ? f.alt+'m' : '--';
  altEl.className='ival'+(f.alt>9000?' red':f.alt>6000?' yellow':'');
  document.getElementById('inf-spd').textContent = f.vel ? f.vel+' km/s' : '--';
  document.getElementById('inf-hdg').textContent = f.hdg!==null ? f.hdg+'°' : '--';
  document.getElementById('inf-lat').textContent = f.lat ? f.lat.toFixed(5) : '--';
  document.getElementById('inf-lon').textContent = f.lon ? f.lon.toFixed(5) : '--';
  var sqkEl=document.getElementById('inf-sqk');
  sqkEl.textContent = f.sqk || '--';
  sqkEl.className = 'ival'+(emg?' red':'');
  var vsEl=document.getElementById('inf-vs');
  vsEl.textContent = f.vs ? (f.vs>0?'+':'')+f.vs+' m/s' : '--';
  vsEl.className = 'ival'+(f.vs>2?' blue':f.vs<-2?' yellow':'');
  var vertText = f.ground?'YERDE' : f.vs>3?'&#9650; YUKSELiYOR' : f.vs<-3?'&#9660; iNiYOR' : '&#9654; SEYREDIYOR';
  document.getElementById('inf-grnd').innerHTML = vertText;
  document.getElementById('inf-icao').textContent = (f.icao24||'--').toUpperCase();
  document.getElementById('spdgauge').style.width = (f.vel?Math.min(100,f.vel/12):0)+'%';
  document.getElementById('hud-alt').textContent = f.alt?Math.round(f.alt):'--';
  document.getElementById('hud-spd').textContent = f.vel||'--';
  document.getElementById('hud-hdg').textContent = f.hdg!==null?f.hdg:'--';
  document.getElementById('hud-vs').textContent = f.vs?(f.vs>0?'+':'')+f.vs:'--';
  document.getElementById('trailbtn').classList.toggle('on', !!trailEnabled[f.icao24]);
  document.getElementById('infopanel').classList.add('vis');
  document.getElementById('hud').classList.add('vis');
  drawSpeedHistory(f.icao24);
}
function closeInfo(){
  selIcao=null;
  document.getElementById('infopanel').classList.remove('vis');
  document.getElementById('hud').classList.remove('vis');
  renderList();
  if(MAP) redrawMarkers();
}
function flyToSel(){ var f=flights.find(function(x){return x.icao24===selIcao;}); if(f&&MAP)MAP.flyTo({center:[f.lon,f.lat],zoom:9,speed:1.5}); }
function copyCoords(){ var f=flights.find(function(x){return x.icao24===selIcao;}); if(!f)return; var t=f.lat.toFixed(5)+', '+f.lon.toFixed(5); try{navigator.clipboard.writeText(t);notify('KOORDINAT KOPYALANDI','ok');}catch(e){notify(t,'info');} }
function openFA(){ var f=flights.find(function(x){return x.icao24===selIcao;}); if(f)window.open('https://flightaware.com/live/flight/'+f.callsign.trim(),'_blank'); }
function openFR24(){ var f=flights.find(function(x){return x.icao24===selIcao;}); if(f)window.open('https://www.flightradar24.com/'+f.callsign.trim(),'_blank'); }
""")

# ── SPEED HISTORY CHART ───────────────────────────────────────────
js("""
function drawSpeedHistory(icao){
  var cv = document.getElementById('spdhist-canvas');
  var ctx = cv.getContext('2d');
  var pts = speedHistory[icao] || [];
  var W = cv.offsetWidth || 274, H = 36;
  cv.width = W; cv.height = H;
  ctx.clearRect(0,0,W,H);
  if(pts.length < 2){
    ctx.fillStyle='rgba(168,255,212,0.2)';
    ctx.font='9px Share Tech Mono';
    ctx.textAlign='center';
    ctx.fillText('VERi BEKLENIYOR...', W/2, H/2+3);
    return;
  }
  var min=Math.min.apply(null,pts), max=Math.max.apply(null,pts);
  if(max===min) max=min+1;
  ctx.strokeStyle='rgba(0,255,136,0.06)'; ctx.lineWidth=1;
  for(var y=0;y<H;y+=H/3){ ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(W,y);ctx.stroke(); }
  var step = W/(pts.length-1);
  var grad = ctx.createLinearGradient(0,0,W,0);
  grad.addColorStop(0,'rgba(0,255,136,0.4)');grad.addColorStop(1,'rgba(0,229,255,0.9)');
  ctx.beginPath();
  pts.forEach(function(v,i){
    var x=i*step, y=H-(v-min)/(max-min)*(H-4)-2;
    i===0?ctx.moveTo(x,y):ctx.lineTo(x,y);
  });
  ctx.strokeStyle=grad; ctx.lineWidth=1.5; ctx.stroke();
  ctx.lineTo((pts.length-1)*step,H); ctx.lineTo(0,H); ctx.closePath();
  var fillGrad=ctx.createLinearGradient(0,0,0,H);
  fillGrad.addColorStop(0,'rgba(0,229,255,0.15)');fillGrad.addColorStop(1,'rgba(0,229,255,0)');
  ctx.fillStyle=fillGrad; ctx.fill();
  ctx.fillStyle='rgba(168,255,212,0.4)'; ctx.font='8px Share Tech Mono'; ctx.textAlign='left';
  ctx.fillText(Math.round(max), 2, 9);
  ctx.fillText(Math.round(min), 2, H-2);
}
""")

# ── STATS ─────────────────────────────────────────────────────────
js("""
function updateStats(){
  var total=flights.length;
  var cmap={}, amap={};
  var alts=flights.filter(function(f){return f.alt;}), vels=flights.filter(function(f){return f.vel;});
  flights.forEach(function(f){
    cmap[f.country]=(cmap[f.country]||0)+1;
    var al=f.callsign.replace(/[0-9]/g,'').trim().slice(0,3);
    if(al.length>=2) amap[al]=(amap[al]||0)+1;
  });
  var aAlt=alts.length?Math.round(alts.reduce(function(s,f){return s+f.alt;},0)/alts.length):0;
  var aVel=vels.length?Math.round(vels.reduce(function(s,f){return s+f.vel;},0)/vels.length):0;
  var maxVel=vels.length?Math.max.apply(null,vels.map(function(f){return f.vel;})):0;
  var maxAlt2=alts.length?Math.max.apply(null,alts.map(function(f){return f.alt;})):0;

  document.getElementById('st-total').textContent=total;
  document.getElementById('st-country').textContent=Object.keys(cmap).length;
  document.getElementById('st-avgalt').textContent=aAlt;
  document.getElementById('st-avgspd').textContent=aVel;
  document.getElementById('st-maxspd').textContent=maxVel;
  document.getElementById('st-maxalt').textContent=maxAlt2;

  function renderBars(containerId, data, color){
    var sorted=Object.entries(data).sort(function(a,b){return b[1]-a[1];}).slice(0,8);
    var maxV=sorted[0]?sorted[0][1]:1;
    document.getElementById(containerId).innerHTML=sorted.map(function(e){
      return '<div class="strow"><div class="stlabel">'+e[0].slice(0,16)+'</div>'
        +'<div class="sttrack"><div class="stfill" style="width:'+(e[1]/maxV*100)+'%;background:'+color+'"></div></div>'
        +'<div class="stval" style="color:'+color+'">'+e[1]+'</div></div>';
    }).join('');
  }

  renderBars('st-countries', cmap, 'var(--g)');
  renderBars('st-airlines', amap, 'var(--c)');

  var spB=[{l:'<400',n:0},{l:'400-600',n:0},{l:'600-800',n:0},{l:'800-1000',n:0},{l:'>1000',n:0}];
  vels.forEach(function(f){ if(f.vel<400)spB[0].n++; else if(f.vel<600)spB[1].n++; else if(f.vel<800)spB[2].n++; else if(f.vel<1000)spB[3].n++; else spB[4].n++; });
  var maxS=Math.max.apply(null,spB.map(function(b){return b.n;}));
  document.getElementById('st-speeds').innerHTML=spB.map(function(b){
    return '<div class="strow"><div class="stlabel">'+b.l+' km/s</div><div class="sttrack"><div class="stfill" style="width:'+(maxS>0?b.n/maxS*100:0)+'%;background:var(--c)"></div></div><div class="stval" style="color:var(--c)">'+b.n+'</div></div>';
  }).join('');

  var aB=[{l:'<3k',n:0},{l:'3-6k',n:0},{l:'6-9k',n:0},{l:'9-12k',n:0},{l:'>12k',n:0}];
  alts.forEach(function(f){ if(f.alt<3000)aB[0].n++; else if(f.alt<6000)aB[1].n++; else if(f.alt<9000)aB[2].n++; else if(f.alt<12000)aB[3].n++; else aB[4].n++; });
  var maxA=Math.max.apply(null,aB.map(function(b){return b.n;}));
  document.getElementById('st-alts').innerHTML=aB.map(function(b){
    return '<div class="strow"><div class="stlabel">'+b.l+' m</div><div class="sttrack"><div class="stfill" style="width:'+(maxA>0?b.n/maxA*100:0)+'%;background:var(--w)"></div></div><div class="stval" style="color:var(--w)">'+b.n+'</div></div>';
  }).join('');
}
""")

# ── ALERTS ────────────────────────────────────────────────────────
js("""
function checkAlerts(){
  var sqkNames={'7700':'ACIL DURUM','7600':'RADYO ARIZA','7500':'HiJACK'};
  flights.forEach(function(f){
    if(f.alt && f.alt > 12000) addAlert(f.callsign+' asiri yukseklik: '+f.alt+'m','med');
    if(sqkNames[f.sqk]) addAlert('SQUAWK '+f.sqk+' '+sqkNames[f.sqk]+': '+f.callsign,'high');
    if(f.vs && f.vs < -20) addAlert(f.callsign+' hizli alçalma: '+f.vs+'m/s','med');
  });
}

function addAlert(msg,level){
  if(alerts.find(function(a){return a.msg===msg;})) return;
  alerts.unshift({msg:msg,level:level,time:new Date().toTimeString().slice(0,5)});
  if(alerts.length>50) alerts.pop();
  renderAlerts();
  if(level==='high') notify('&#9888; ALARM: '+msg,'err');
}

function renderAlerts(){
  var al=document.getElementById('alertlist');
  var hdr=document.getElementById('alertheader');
  if(!alerts.length){ al.innerHTML='<div class="no-alerts">ALARM YOK</div>'; hdr.textContent='ALARMLAR'; return; }
  al.innerHTML=alerts.slice(0,30).map(function(a){
    return '<div class="alert-item"><div class="apip '+a.level+'"></div><div><div class="amsg">'+a.msg+'</div><div class="atime">'+a.time+'</div></div></div>';
  }).join('');
  hdr.textContent='ALARM('+Math.min(alerts.length,30)+')';
}

function clearAlerts(){ alerts=[]; renderAlerts(); }
""")

# ── SETTINGS ──────────────────────────────────────────────────────
js("""
function toggleSetting(key){
  settings[key] = !settings[key];
  document.getElementById('sw-'+key).classList.toggle('on', settings[key]);
  if(key==='ground') loadFlights();
  if(key==='trail'){ if(!settings.trail) clearAllTrails(); }
}

function onSlider(v){
  markerLimit = parseInt(v);
  document.getElementById('sliderval').textContent = v;
  document.getElementById('svis').textContent = Math.min(markerLimit, filteredFlights.length);
  if(MAP) redrawMarkers();
}

function onRfSlider(v){
  RF = parseInt(v)*1000;
  document.getElementById('rf-val').textContent = v+'s';
  resetRefTimer();
}

function setPerf(mode){
  perfMode = mode;
  ['eco','normal','ultra'].forEach(function(m){ document.getElementById('perf-'+m).classList.toggle('on',m===mode); });
  if(mode==='eco'){ markerLimit=50; document.getElementById('limitslider').value=50; document.getElementById('sliderval').textContent='50'; RF=60000; }
  else if(mode==='normal'){ markerLimit=150; document.getElementById('limitslider').value=150; document.getElementById('sliderval').textContent='150'; RF=30000; }
  else if(mode==='ultra'){ markerLimit=500; document.getElementById('limitslider').value=500; document.getElementById('sliderval').textContent='500'; RF=20000; }
  if(MAP) redrawMarkers();
  notify(mode.toUpperCase()+' PERFORMANS MODU','info');
}
""")

# ── EXPORT ────────────────────────────────────────────────────────
js("""
function exportJSON(){
  var data=JSON.stringify(flights,null,2);
  var blob=new Blob([data],{type:'application/json'});
  var a=document.createElement('a');
  a.href=URL.createObjectURL(blob);
  a.download='skywatch_flights_'+new Date().toISOString().slice(0,19).replace(/:/g,'-')+'.json';
  a.click(); notify('JSON indirildi','ok');
}

function exportCSV(){
  var headers=['icao24','callsign','country','lat','lon','alt','vel','hdg','vs','sqk'];
  var rows=flights.map(function(f){return headers.map(function(h){return f[h]!==null&&f[h]!==undefined?f[h]:'';}).join(',');});
  var csv=headers.join(',')+'\n'+rows.join('\n');
  var blob=new Blob([csv],{type:'text/csv'});
  var a=document.createElement('a');
  a.href=URL.createObjectURL(blob);
  a.download='skywatch_flights_'+new Date().toISOString().slice(0,19).replace(/:/g,'-')+'.csv';
  a.click(); notify('CSV indirildi','ok');
}

function clearToken(){ localStorage.removeItem('skyw4_token'); notify('TOKEN SiLiNDi — Sayfayi yenileyin','warn'); }
""")

# ── SEARCH ────────────────────────────────────────────────────────
js("""
function toggleSearch(){
  searchOpen=!searchOpen;
  document.getElementById('searchbar').classList.toggle('open',searchOpen);
  if(searchOpen) setTimeout(function(){document.getElementById('sinput').focus();},80);
  else{ document.getElementById('sinput').value=''; document.getElementById('sresults').classList.remove('open'); }
}

function doSearch(q){
  var sr=document.getElementById('sresults');
  if(!q||q.length<2){sr.classList.remove('open');return;}
  var ql=q.toLowerCase();
  var res=flights.filter(function(f){
    return f.callsign.toLowerCase().includes(ql)||f.country.toLowerCase().includes(ql)||f.icao24.toLowerCase().includes(ql);
  }).slice(0,14);
  if(!res.length){sr.classList.remove('open');return;}
  sr.innerHTML=res.map(function(f){
    return '<div class="sres-item" onclick="pickByIcao(\''+f.icao24+'\')">'
      +flag(f.country)+' <span class="sres-call">'+f.callsign+'</span>'
      +' <span class="sres-info">'+f.country+(f.alt?' '+f.alt+'m':'')+(f.vel?' '+f.vel+'km/s':'')+'</span>'
      +'</div>';
  }).join('');
  sr.classList.add('open');
}

function searchKeydown(e){
  if(e.key==='Escape') toggleSearch();
  if(e.key==='Enter'){
    var first=document.querySelector('.sres-item');
    if(first) first.click();
  }
}

function pickByIcao(icao){ var f=flights.find(function(x){return x.icao24===icao;}); if(f){pickFlight(f);toggleSearch();} }
""")

# ── PANEL, TABS, MISC ─────────────────────────────────────────────
js("""
function togglePanel(){
  panelOpen=!panelOpen;
  document.getElementById('lpanel').classList.toggle('closed',!panelOpen);
  var btn=document.getElementById('ptoggle');
  btn.classList.toggle('closed',!panelOpen);
  btn.innerHTML=panelOpen?'&#9664;':'&#9654;';
}

function switchTab(i){
  for(var j=0;j<4;j++){
    document.getElementById('tab'+j).classList.toggle('on',j===i);
    document.getElementById('tp'+j).classList.toggle('on',j===i);
  }
}

function gotoMe(){
  if(!navigator.geolocation){notify('KONUM DESTEKLENMiYOR','err');return;}
  navigator.geolocation.getCurrentPosition(
    function(p){ if(MAP)MAP.flyTo({center:[p.coords.longitude,p.coords.latitude],zoom:8,speed:1.5}); notify('KONUMUNUZA ODAKLANDI','ok'); },
    function(){ notify('KONUM ALINAMIYOR','err'); }
  );
}

function doFullscreen(){
  if(!document.fullscreenElement) document.documentElement.requestFullscreen().catch(function(){});
  else document.exitFullscreen().catch(function(){});
}

function toggleHelp(){ helpOpen=!helpOpen; document.getElementById('kbhelp').classList.toggle('vis',helpOpen); }
""")

# ── KEYBOARD ──────────────────────────────────────────────────────
js("""
function setupKeys(){
  document.addEventListener('keydown',function(e){
    if(e.target.tagName==='INPUT'||e.target.tagName==='TEXTAREA') return;
    var k=e.key;
    if(k==='f'||k==='F'){e.preventDefault();toggleSearch();}
    else if(k==='r'||k==='R'){doRefresh();}
    else if(k==='l'||k==='L'){togglePanel();}
    else if(k==='s'||k==='S'){setLayer('satellite');}
    else if(k==='d'||k==='D'){setLayer('dark');}
    else if(k==='t'||k==='T'){setLayer('street');}
    else if(k==='h'||k==='H'){toggleWeather();}
    else if(k==='n'||k==='N'){toggleTerminator();}
    else if(k==='i'||k==='I'){toggleAllTrails();}
    else if(k==='c'||k==='C'){gotoMe();}
    else if(k==='x'||k==='X'){closeInfo();}
    else if(k==='Escape'){
      if(helpOpen){toggleHelp();}
      else if(searchOpen){toggleSearch();}
      else{closeInfo();}
    }
    else if(k==='?'){toggleHelp();}
    else if(k==='F11'){e.preventDefault();doFullscreen();}
  });
}
""")

# ── RADAR ─────────────────────────────────────────────────────────
js("""
function startRadar(){
  var cv=document.getElementById('radarc'), ctx=cv.getContext('2d');
  function frame(){
    ctx.clearRect(0,0,100,100);
    ctx.strokeStyle='rgba(0,255,136,0.12)'; ctx.lineWidth=1;
    [16,30,46].forEach(function(r){ ctx.beginPath();ctx.arc(50,50,r,0,Math.PI*2);ctx.stroke(); });
    ctx.strokeStyle='rgba(0,255,136,0.07)';
    ctx.beginPath();ctx.moveTo(50,2);ctx.lineTo(50,98);ctx.stroke();
    ctx.beginPath();ctx.moveTo(2,50);ctx.lineTo(98,50);ctx.stroke();
    ctx.save();ctx.translate(50,50);ctx.rotate(radarAngle);
    var sw=ctx.createLinearGradient(0,0,48,0);
    sw.addColorStop(0,'rgba(0,255,136,0.6)');sw.addColorStop(1,'rgba(0,255,136,0)');
    ctx.beginPath();ctx.moveTo(0,0);ctx.arc(0,0,48,-0.4,0);ctx.closePath();ctx.fillStyle=sw;ctx.fill();
    ctx.restore();
    var cnt=0;
    if(flights.length&&MAP){
      var ctr=MAP.getCenter();
      flights.forEach(function(f){
        if(!f.lat||!f.lon)return;
        var dx=(f.lon-ctr.lng)*1.3, dy=-(f.lat-ctr.lat)*1.6;
        if(Math.abs(dx)>46||Math.abs(dy)>46)return;
        cnt++;
        var emg=f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
        var color = emg?'rgba(255,68,102,0.9)' : f.icao24===selIcao?'rgba(255,204,0,0.95)' : f.alt>9000?'rgba(255,68,102,0.7)' : 'rgba(0,229,255,0.7)';
        ctx.beginPath();ctx.arc(50+dx,50+dy,emg?3:1.5,0,Math.PI*2);
        ctx.fillStyle=color;ctx.fill();
      });
    } else {
      flights.slice(0,40).forEach(function(f,i){
        var a=(i/40)*Math.PI*2, r=4+Math.random()*42;
        ctx.beginPath();ctx.arc(50+Math.cos(a)*r,50+Math.sin(a)*r,1.5,0,Math.PI*2);
        ctx.fillStyle='rgba(0,229,255,0.6)';ctx.fill();cnt++;
      });
    }
    document.getElementById('radarcnt').textContent=cnt;
    radarAngle+=0.025;
    requestAnimationFrame(frame);
  }
  frame();
}
""")

# ── COMPASS ───────────────────────────────────────────────────────
js("""
function startCompass(){ drawCompass(0); }
function drawCompass(bearing){
  var cv=document.getElementById('compass'); if(!cv)return;
  var ctx=cv.getContext('2d'), cx=23, cy=23, r=20;
  ctx.clearRect(0,0,46,46);
  ctx.strokeStyle='rgba(0,255,136,0.18)'; ctx.lineWidth=1;
  ctx.beginPath();ctx.arc(cx,cy,r,0,Math.PI*2);ctx.stroke();
  ['N','E','S','W'].forEach(function(d,i){
    var a=(i*90-bearing)*Math.PI/180;
    ctx.fillStyle=d==='N'?'#ff4466':'rgba(168,255,212,0.5)';
    ctx.font='bold 7px Orbitron,monospace';ctx.textAlign='center';ctx.textBaseline='middle';
    ctx.fillText(d,cx+Math.sin(a)*(r-5),cy-Math.cos(a)*(r-5));
  });
  ctx.save();ctx.translate(cx,cy);ctx.rotate(-bearing*Math.PI/180);
  ctx.fillStyle='#ff4466';
  ctx.beginPath();ctx.moveTo(0,-13);ctx.lineTo(2.5,0);ctx.lineTo(0,-2);ctx.lineTo(-2.5,0);ctx.closePath();ctx.fill();
  ctx.fillStyle='rgba(168,255,212,0.35)';
  ctx.beginPath();ctx.moveTo(0,13);ctx.lineTo(2.5,0);ctx.lineTo(0,2);ctx.lineTo(-2.5,0);ctx.closePath();ctx.fill();
  ctx.restore();
}
""")

# ── REFRESH TIMER ─────────────────────────────────────────────────
js("""
function startRefTimer(){
  var bar=document.getElementById('refprog'), start=Date.now();
  rfTimer=setInterval(function(){
    var e=Date.now()-start, pct=Math.max(0,100-(e/RF)*100);
    bar.style.width=pct+'%';
    if(e>=RF){ start=Date.now(); loadFlights(); }
  }, 300);
}
function resetRefTimer(){ if(rfTimer)clearInterval(rfTimer); rfTimer=null; startRefTimer(); }
""")

w("</script></body></html>")

# Write HTML
html = "\n".join(L)
with open(HTML, "w", encoding="utf-8") as f:
    f.write(html)

print("OK:" + HTML)
print("SIZE:" + str(len(html)))
PYEOF

if [ ! -f "$HTML" ]; then
  printf "  ${R}HATA: HTML olusturulamadi!${N}\n"; exit 1
fi

BYTES=$(wc -c < "$HTML")
LINES=$(wc -l < "$HTML")
printf "  ${G}HTML hazir — %d byte, %d satir${N}\n" $BYTES $LINES

# Port kontrolü (Termux uyumlu)
PORT=$((RANDOM % 8900 + 1100))
while (echo >/dev/tcp/127.0.0.1/$PORT) 2>/dev/null; do
  PORT=$((RANDOM % 8900 + 1100))
done

printf "\n"
printf "  ┌─────────────────────────────────────────────────────┐\n"
printf "  │  ${B}URL     :${N} ${C}http://localhost:$PORT${N}\n"
printf "  │  ${B}VERSiYON:${N} v4.0 ULTIMATE\n"
printf "  │  ${B}DURUM   :${N} ${G}AKTIF${N}\n"
printf "  │\n"
printf "  │  Ozellikler:\n"
printf "  │  • Ucak sayisi slider kontrolu\n"
printf "  │  • Renk kodlu gercek zamanli ucus izleri\n"
printf "  │  • Hiz gecmisi grafigi\n"
printf "  │  • JSON/CSV veri aktarimi\n"
printf "  │  • Eco/Normal/Ultra performans modlari\n"
printf "  │  │\n"
printf "  │  Durdur: Ctrl + C\n"
printf "  └─────────────────────────────────────────────────────┘\n\n"

sleep 0.7
command -v termux-open-url &>/dev/null && {
  termux-open-url "http://localhost:$PORT" &
  printf "  ${C}Tarayici aciliyor...${N}\n\n"
}

cd "$TMPD"
$PY << PYEOF
import http.server, socketserver, os, sys, signal

PORT = $PORT
os.chdir("$TMPD")

class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, fmt, *a):
        print("  [%s] %s" % (self.address_string(), fmt % a))
    def do_GET(self):
        if self.path in ('/', '/index.html'):
            self.path = '/skywatch_v4.html'
        super().do_GET()

def shutdown(s, f):
    print("\n  Sunucu kapatildi.\n")
    sys.exit(0)

signal.signal(signal.SIGINT, shutdown)
socketserver.TCPServer.allow_reuse_address = True

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print("  http://localhost:%d  |  Ctrl+C ile durdur\n" % PORT)
    httpd.serve_forever()
PYEOF
#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  SKYWATCH v5.0 ULTIMATE+ — Canli Ucak Takip Sistemi         ║
# ║  Calistir: bash skywatch_v5.sh                               ║
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
printf "  ${C}v5.0 ULTIMATE+ — Sinirsiz Ucak + 3D + Bildirim + Coklu Dil${N}\n"
printf "  ──────────────────────────────────────────────────────────\n\n"

PY=$(command -v python3 || command -v python)
if [ -z "$PY" ]; then
  printf "  ${Y}Python yukleniyor...${N}\n"
  pkg install python -y
  PY=$(command -v python3 || command -v python)
fi

TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/skywatch_v5.html"

printf "  ${C}HTML olusturuluyor (v5.0 Ultimate+)...${N}\n"

cat > "$HTML" << 'EOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="theme-color" content="#020810">
    <link rel="manifest" href="data:application/manifest+json,{}" id="manifest-placeholder">
    <title>SKYWATCH v5 — Canli Uçak Takip</title>
    <link href="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css" rel="stylesheet">
    <script src="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
    <link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&display=swap" rel="stylesheet">
    <style>
        /* CSS (tüm stiller - önceki v4 stilleri + eklemeler) */
        :root {
            --g:#00ff88; --c:#00e5ff; --o:#ff6b35; --w:#ffcc00; --r:#ff4466;
            --bg:#020810; --bg2:#030f1a; --bg3:#041220;
            --panel:rgba(3,15,26,0.97); --panel2:rgba(4,18,32,0.99);
            --border:rgba(0,255,136,0.18); --border2:rgba(0,229,255,0.2);
            --text:#a8ffd4; --text2:rgba(168,255,212,0.5); --text3:rgba(168,255,212,0.3);
        }
        *{margin:0;padding:0;box-sizing:border-box}
        body{background:var(--bg);color:var(--text);font-family:'Share Tech Mono',monospace;overflow:hidden;height:100vh;width:100vw;cursor:default}
        #map{position:absolute;inset:0}
        #modal{position:fixed;inset:0;background:rgba(2,8,16,0.98);z-index:10000;display:flex;align-items:center;justify-content:center}
        #modal.gone{display:none!important}
        .mbox{background:var(--bg3);border:1px solid rgba(0,255,136,0.28);padding:34px;width:480px;max-width:95vw;position:relative}
        .mbox::before{content:'SKYWATCH v5.0';position:absolute;top:-11px;left:20px;background:var(--bg3);padding:0 12px;font-family:'Orbitron',sans-serif;font-size:9px;color:var(--g);letter-spacing:5px}
        .mtitle{font-family:'Orbitron',sans-serif;font-size:16px;color:var(--c);letter-spacing:3px;margin-bottom:4px}
        .msub{font-size:10px;color:var(--text3);letter-spacing:2px;margin-bottom:18px}
        .mdesc{font-size:11px;color:var(--text2);line-height:1.8;margin-bottom:20px}
        .mdesc a{color:var(--c);text-decoration:none}
        .mdesc b{color:var(--text)}
        .mlabel{font-size:9px;color:var(--text3);letter-spacing:2px;margin-bottom:5px;text-transform:uppercase}
        .minput{width:100%;background:rgba(0,229,255,0.04);border:1px solid rgba(0,229,255,0.22);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;padding:11px 14px;outline:none;margin-bottom:8px}
        .minput:focus{border-color:var(--c);box-shadow:0 0 16px rgba(0,229,255,0.12)}
        .merr{font-size:10px;color:var(--r);min-height:18px;margin-bottom:10px;display:flex;align-items:center;gap:6px}
        .mbtns{display:flex;gap:10px}
        .mbtn-start{flex:1;background:rgba(0,255,136,0.1);border:1px solid var(--g);color:var(--g);font-size:12px;padding:12px;cursor:pointer;text-transform:uppercase}
        .mbtn-start:hover{background:rgba(0,255,136,0.2)}
        .mbtn-start:disabled{opacity:0.4;cursor:not-allowed}
        .mbtn-demo{background:rgba(0,229,255,0.07);border:1px solid rgba(0,229,255,0.28);color:var(--c);font-size:12px;padding:12px 20px;cursor:pointer}
        .mbtn-demo:hover{background:rgba(0,229,255,0.16)}
        .mbtn-demo:disabled{opacity:0.4;cursor:not-allowed}
        .msaved{display:none;align-items:center;gap:8px;font-size:10px;color:var(--g);padding:7px 12px;border:1px solid rgba(0,255,136,0.18);background:rgba(0,255,136,0.04);margin-bottom:10px}
        .msaved.show{display:flex}
        .mhint{font-size:9px;color:var(--text3);margin-top:12px;text-align:center}
        #loading{position:fixed;inset:0;background:var(--bg);z-index:9999;display:none;flex-direction:column;align-items:center;justify-content:center;gap:18px}
        #loading.on{display:flex}
        .ldlogo{font-family:'Orbitron',sans-serif;font-size:34px;font-weight:900;color:var(--g);letter-spacing:8px;animation:lglow 2.5s ease-in-out infinite}
        .ldsub{font-size:10px;color:var(--text3);letter-spacing:5px;margin-top:-10px}
        @keyframes lglow{0%,100%{text-shadow:0 0 20px rgba(0,255,136,.3),0 0 40px rgba(0,255,136,.1)}50%{text-shadow:0 0 50px rgba(0,255,136,.9),0 0 90px rgba(0,255,136,.4)}}
        .ldbarwrap{width:280px;height:2px;background:rgba(0,255,136,.1);overflow:hidden}
        .ldbar{height:100%;background:linear-gradient(90deg,var(--g),var(--c));width:0%;transition:width .35s ease}
        .ldstatus{font-size:10px;color:var(--text3);letter-spacing:3px;text-transform:uppercase}
        .topbar{position:fixed;top:0;left:0;right:0;height:52px;background:rgba(3,15,26,0.97);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 14px;gap:12px;z-index:500;backdrop-filter:blur(16px)}
        .tlogo{font-family:'Orbitron',sans-serif;font-weight:900;font-size:16px;color:var(--g);letter-spacing:5px;display:flex;align-items:center;gap:8px;white-space:nowrap}
        .tlogo svg{flex-shrink:0;animation:planepulse 4s ease-in-out infinite}
        @keyframes planepulse{0%,100%{filter:drop-shadow(0 0 3px var(--g))}50%{filter:drop-shadow(0 0 10px var(--g)) drop-shadow(0 0 20px rgba(0,255,136,.5))}}
        .tvbar{width:1px;height:22px;background:var(--border)}
        .tstats{display:flex;gap:14px;flex:1;overflow:hidden;align-items:center}
        .tsc{display:flex;align-items:center;gap:5px;font-size:10px;color:var(--text2);white-space:nowrap}
        .tval{color:var(--c);font-family:'Orbitron',sans-serif;font-size:11px}
        .statusdot{width:7px;height:7px;border-radius:50%;background:var(--g);box-shadow:0 0 8px var(--g);animation:blink 1.5s infinite}
        .statusdot.loading{background:var(--o)}
        .statusdot.error{background:var(--r)}
        .statusdot.demo{background:var(--w)}
        @keyframes blink{0%,100%{opacity:1}50%{opacity:.2}}
        .tright{display:flex;align-items:center;gap:6px;margin-left:auto}
        .tclock{font-size:13px;color:var(--c);font-family:'Orbitron',sans-serif;min-width:72px}
        .tbtn{background:transparent;border:1px solid var(--border);color:var(--g);font-size:10px;padding:5px 9px;cursor:pointer;letter-spacing:1px;transition:all .2s}
        .tbtn:hover{background:rgba(0,255,136,0.1);border-color:var(--g)}
        .searchbar{position:fixed;top:62px;left:50%;transform:translateX(-50%);z-index:501;display:flex;width:360px;opacity:0;pointer-events:none;transition:opacity .25s}
        .searchbar.open{opacity:1;pointer-events:all}
        .sinput{flex:1;background:var(--panel2);border:1px solid var(--border2);border-right:none;color:var(--c);font-size:12px;padding:9px 14px;outline:none}
        .sinput:focus{border-color:var(--c)}
        .scloseBtn{background:rgba(0,229,255,.08);border:1px solid var(--border2);color:var(--c);font-size:16px;padding:9px 13px;cursor:pointer}
        .scloseBtn:hover{background:rgba(255,68,102,.15);color:var(--r)}
        .sresults{position:absolute;top:100%;left:0;right:0;background:var(--panel2);border:1px solid var(--border2);border-top:none;max-height:240px;overflow-y:auto;display:none}
        .sresults.open{display:block}
        .sres-item{padding:9px 14px;font-size:11px;cursor:pointer;border-bottom:1px solid rgba(0,255,136,.05);display:flex;align-items:center;gap:8px}
        .sres-item:hover{background:rgba(0,255,136,.07);color:var(--g)}
        .sres-call{font-family:'Orbitron',sans-serif;font-size:11px;color:var(--c)}
        .lpanel{position:fixed;top:52px;left:0;bottom:0;width:280px;background:var(--panel);border-right:1px solid var(--border);z-index:200;display:flex;flex-direction:column;transition:transform .32s cubic-bezier(.4,0,.2,1)}
        .lpanel.closed{transform:translateX(-280px)}
        .ptoggle{position:fixed;top:66px;left:280px;width:16px;height:42px;background:var(--panel);border:1px solid var(--border);border-left:none;z-index:201;display:flex;align-items:center;justify-content:center;font-size:10px;color:var(--g);cursor:pointer;transition:left .32s}
        .ptoggle:hover{background:rgba(0,255,136,0.1)}
        .ptoggle.closed{left:0}
        .tabs{display:flex;border-bottom:1px solid var(--border)}
        .tabbtn{flex:1;padding:9px 0;font-size:9px;letter-spacing:2px;color:var(--text2);background:transparent;border:none;cursor:pointer;border-bottom:2px solid transparent;text-transform:uppercase}
        .tabbtn.on{color:var(--g);border-bottom-color:var(--g);background:rgba(0,255,136,.04)}
        .tabpanel{display:none;flex:1;overflow-y:auto;flex-direction:column}
        .tabpanel.on{display:flex}
        .slider-section{padding:10px 12px;border-bottom:1px solid rgba(0,255,136,.07);background:rgba(0,255,136,.02)}
        .slider-row{display:flex;justify-content:space-between;margin-bottom:6px}
        .slider-label{font-size:9px;color:var(--text3);text-transform:uppercase}
        .slider-val{font-family:'Orbitron',sans-serif;font-size:12px;color:var(--g)}
        .slider{width:100%;height:3px;background:rgba(0,255,136,.12);-webkit-appearance:none;appearance:none}
        .slider::-webkit-slider-thumb{-webkit-appearance:none;width:14px;height:14px;background:var(--g);cursor:pointer;box-shadow:0 0 8px var(--g)}
        .perf-row{display:flex;gap:5px;margin-top:6px}
        .perf-btn{flex:1;font-size:9px;padding:4px;border:1px solid rgba(0,255,136,.18);color:var(--text2);background:transparent;cursor:pointer;text-align:center}
        .perf-btn.on{color:var(--g);border-color:var(--g);background:rgba(0,255,136,.07)}
        .fbar{padding:7px 10px;border-bottom:1px solid rgba(0,255,136,.06);display:flex;gap:5px;flex-wrap:wrap}
        .fchip{font-size:9px;padding:3px 8px;border:1px solid rgba(0,255,136,.18);color:var(--text2);background:transparent;cursor:pointer}
        .fchip.on{background:rgba(0,229,255,.1);border-color:var(--c);color:var(--c)}
        .fchip.red.on{background:rgba(255,68,102,.1);border-color:var(--r);color:var(--r)}
        .fcountbar{padding:3px 10px 5px;font-size:9px;color:var(--text3);display:flex;justify-content:space-between;border-bottom:1px solid rgba(0,255,136,.04)}
        .fitem{padding:9px 12px;border-bottom:1px solid rgba(0,255,136,.05);cursor:pointer;position:relative}
        .fitem:hover{background:rgba(0,255,136,.05)}
        .fitem.sel{background:rgba(0,229,255,.05)}
        .fitem.emerg{background:rgba(255,68,102,.04)}
        .fcall{font-family:'Orbitron',sans-serif;font-size:11px;color:var(--c);display:flex;align-items:center;gap:5px}
        .fflag{font-size:13px}
        .fbadge{font-size:8px;padding:1px 5px;border:1px solid}
        .fbadge.emerg{border-color:var(--r);color:var(--r)}
        .fdetail{font-size:9px;color:var(--text2);display:flex;gap:8px;margin-top:3px;flex-wrap:wrap}
        .fdv{color:var(--text)}
        .faltbar{height:2px;background:rgba(0,255,136,.07);margin-top:5px;overflow:hidden}
        .faltfill{height:100%}
        .stblock{padding:12px;border-bottom:1px solid rgba(0,255,136,.06)}
        .sthead{font-size:8px;color:var(--text3);letter-spacing:3px;text-transform:uppercase;margin-bottom:9px;display:flex;justify-content:space-between}
        .bigstat{display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-bottom:6px}
        .bsi{background:rgba(0,255,136,.04);border:1px solid rgba(0,255,136,.1);padding:9px 10px}
        .bsv{font-family:'Orbitron',sans-serif;font-size:19px;color:var(--c);line-height:1}
        .bsl{font-size:8px;color:var(--text3);margin-top:3px;text-transform:uppercase}
        .strow{display:flex;align-items:center;gap:8px;margin-bottom:5px}
        .stlabel{font-size:10px;color:var(--text2);flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
        .sttrack{flex:0 0 70px;height:3px;background:rgba(0,255,136,.08)}
        .stfill{height:100%}
        .stval{font-size:10px;width:26px;text-align:right;color:var(--g)}
        .alert-item{padding:9px 12px;border-bottom:1px solid rgba(255,68,102,.08);display:flex;gap:8px}
        .apip{width:7px;height:7px;border-radius:50%;margin-top:4px}
        .apip.high{background:var(--r);animation:blink .7s infinite}
        .apip.med{background:var(--w)}
        .apip.low{background:var(--c)}
        .amsg{font-size:10px;color:var(--text);line-height:1.5}
        .atime{font-size:9px;color:var(--text3);margin-top:2px}
        .no-alerts{padding:24px 12px;text-align:center;font-size:10px;color:var(--text3)}
        .settrow{padding:10px 12px;border-bottom:1px solid rgba(0,255,136,.05);display:flex;justify-content:space-between;align-items:center}
        .settlabel{font-size:10px;color:var(--text2)}
        .settval{font-size:10px;color:var(--g);font-family:'Orbitron',sans-serif}
        .toggle-sw{width:32px;height:16px;background:rgba(0,255,136,.12);border:1px solid rgba(0,255,136,.3);position:relative;cursor:pointer}
        .toggle-sw.on{background:rgba(0,255,136,.25);border-color:var(--g)}
        .toggle-sw::after{content:'';position:absolute;width:10px;height:10px;background:rgba(168,255,212,.5);top:2px;left:2px;transition:left .2s}
        .toggle-sw.on::after{left:18px;background:var(--g)}
        .expbtn{font-size:9px;padding:4px 10px;border:1px solid rgba(0,255,136,.2);color:var(--text2);background:transparent;cursor:pointer}
        .expbtn:hover{color:var(--g);border-color:var(--g)}
        .sett-section{padding:8px 12px 2px;font-size:8px;color:var(--text3);letter-spacing:3px;text-transform:uppercase;border-bottom:1px solid rgba(0,255,136,.04)}
        .infopanel{position:fixed;bottom:16px;right:16px;width:320px;background:var(--panel2);border:1px solid var(--border2);z-index:200;display:none}
        .infopanel.vis{display:block;animation:slidein .2s ease}
        @keyframes slidein{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:translateY(0)}}
        .infohead{padding:10px 13px;background:rgba(0,229,255,.05);border-bottom:1px solid var(--border2);font-family:'Orbitron',sans-serif;font-size:12px;color:var(--c);display:flex;justify-content:space-between;align-items:center}
        .infohead-acts{display:flex;gap:8px;align-items:center}
        .itrailbtn{font-size:9px;padding:2px 7px;border:1px solid rgba(0,229,255,.25);color:rgba(0,229,255,.6);background:transparent;cursor:pointer}
        .itrailbtn.on{background:rgba(0,229,255,.12);border-color:var(--c);color:var(--c)}
        .closex{color:var(--text3);font-size:18px;cursor:pointer}
        .closex:hover{color:var(--r)}
        .infogrid{padding:10px 13px;display:grid;grid-template-columns:1fr 1fr;gap:8px}
        .ifield{display:flex;flex-direction:column;gap:2px}
        .ilabel{font-size:8px;color:var(--text3);text-transform:uppercase}
        .ival{font-size:12px;color:var(--g);font-family:'Orbitron',sans-serif}
        .ival.blue{color:var(--c)}
        .ival.yellow{color:var(--w)}
        .ival.red{color:var(--r)}
        .spdwrap{padding:0 13px 8px;display:flex;align-items:center;gap:8px}
        .spdtrack{flex:1;height:3px;background:rgba(0,255,136,.08);overflow:hidden}
        .spdfill{height:100%;background:linear-gradient(90deg,var(--g),var(--c),var(--w),var(--r))}
        .spdlabel{font-size:9px;color:var(--text3)}
        .spdhist{padding:0 13px 8px}
        .spdhist-label{font-size:8px;color:var(--text3);letter-spacing:2px;margin-bottom:4px;text-transform:uppercase}
        .spdhist canvas{display:block;width:100%;height:36px}
        .infobtns{padding:0 13px 10px;display:flex;gap:5px}
        .iabtn{flex:1;font-size:9px;padding:5px 3px;border:1px solid var(--border);color:var(--text2);background:transparent;cursor:pointer;text-align:center}
        .iabtn:hover{color:var(--g);border-color:var(--g)}
        .radarwrap{position:fixed;bottom:16px;left:16px;z-index:200;background:var(--panel2);border:1px solid var(--border);padding:8px}
        .radarhead{font-size:8px;color:var(--text3);letter-spacing:2px;text-transform:uppercase;margin-bottom:5px;display:flex;justify-content:space-between}
        .radarcnt{color:var(--g);font-family:'Orbitron',sans-serif;font-size:10px}
        .hud{position:fixed;top:50%;right:16px;transform:translateY(-50%);z-index:200;display:flex;flex-direction:column;gap:6px;opacity:0;pointer-events:none;transition:opacity .3s}
        .hud.vis{opacity:1}
        .hud-m{background:var(--panel2);border:1px solid var(--border2);padding:8px 10px;width:76px;position:relative;overflow:hidden}
        .hud-m::after{content:'';position:absolute;top:0;left:0;right:0;height:1px;background:linear-gradient(90deg,transparent,var(--c),transparent);animation:hudscan 2.5s linear infinite}
        @keyframes hudscan{0%{top:0%}100%{top:100%}}
        .hud-label{font-size:7px;color:var(--text3);text-transform:uppercase;margin-bottom:3px}
        .hud-val{font-family:'Orbitron',sans-serif;font-size:15px;color:var(--c)}
        .hud-unit{font-size:7px;color:var(--text3);margin-top:2px}
        .layerpanel{position:fixed;top:52px;right:0;z-index:200;display:flex;flex-direction:column;gap:3px;padding:6px}
        .lbtn{background:var(--panel2);border:1px solid var(--border);color:var(--text2);font-size:9px;padding:6px 9px;cursor:pointer;width:78px;text-align:center}
        .lbtn.on{color:var(--g);border-color:var(--g);background:rgba(0,255,136,.06)}
        .compass{position:fixed;top:62px;right:90px;z-index:200}
        .notif{position:fixed;top:62px;left:50%;transform:translateX(-50%) translateY(-90px);background:var(--panel2);border:1px solid var(--border);padding:9px 18px;font-size:10px;color:var(--c);z-index:5000;transition:transform .3s;display:flex;align-items:center;gap:10px;white-space:nowrap;max-width:90vw;box-shadow:0 4px 24px rgba(0,0,0,.5);pointer-events:none}
        .notif.show{transform:translateX(-50%) translateY(0);pointer-events:all}
        .notif.err{color:var(--r);border-color:rgba(255,68,102,.35)}
        .notif.warn{color:var(--w);border-color:rgba(255,204,0,.35)}
        .notif.ok{color:var(--g);border-color:rgba(0,255,136,.3)}
        .notif-icon{width:16px;height:16px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:bold;background:rgba(0,229,255,.15)}
        .kbhelp{position:fixed;inset:0;background:rgba(2,8,16,.97);z-index:9000;display:none;align-items:center;justify-content:center;backdrop-filter:blur(8
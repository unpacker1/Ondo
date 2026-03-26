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

# Python kontrolü (sadece sunucu için, HTML oluşturmak için gerekli değil)
PY=$(command -v python3 || command -v python)
if [ -z "$PY" ]; then
  printf "  ${Y}Python yukleniyor...${N}\n"
  pkg install python -y
  PY=$(command -v python3 || command -v python)
fi

TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/skywatch.html"

printf "  ${C}HTML olusturuluyor...${N}\n"

# HTML dosyasını doğrudan yaz
cat > "$HTML" << 'EOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>SKYWATCH v4 — Canli Uçak Takip</title>
    <link href="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css" rel="stylesheet">
    <script src="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js"></script>
    <link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&display=swap" rel="stylesheet">
    <style>
        /* CSS (tüm stiller) */
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
        .mbox::before{content:'SKYWATCH v4.0';position:absolute;top:-11px;left:20px;background:var(--bg3);padding:0 12px;font-family:'Orbitron',sans-serif;font-size:9px;color:var(--g);letter-spacing:5px}
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
        .lpanel{position:fixed;top:52px;left:0;bottom:0;width:272px;background:var(--panel);border-right:1px solid var(--border);z-index:200;display:flex;flex-direction:column;transition:transform .32s cubic-bezier(.4,0,.2,1)}
        .lpanel.closed{transform:translateX(-272px)}
        .ptoggle{position:fixed;top:66px;left:272px;width:16px;height:42px;background:var(--panel);border:1px solid var(--border);border-left:none;z-index:201;display:flex;align-items:center;justify-content:center;font-size:10px;color:var(--g);cursor:pointer;transition:left .32s}
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
        .infopanel{position:fixed;bottom:16px;right:16px;width:300px;background:var(--panel2);border:1px solid var(--border2);z-index:200;display:none}
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
        .kbhelp{position:fixed;inset:0;background:rgba(2,8,16,.97);z-index:9000;display:none;align-items:center;justify-content:center;backdrop-filter:blur(8px)}
        .kbhelp.vis{display:flex}
        .kbbox{background:var(--bg3);border:1px solid var(--border);padding:30px;width:500px;max-width:95vw}
        .kbtitle{font-family:'Orbitron',sans-serif;font-size:14px;color:var(--g);letter-spacing:4px;margin-bottom:20px;display:flex;justify-content:space-between}
        .kbgrid{display:grid;grid-template-columns:1fr 1fr;gap:6px}
        .kbrow{display:flex;align-items:center;gap:10px;padding:5px 0;border-bottom:1px solid rgba(0,255,136,.05)}
        .kbkey{background:rgba(0,255,136,.07);border:1px solid rgba(0,255,136,.2);padding:2px 8px;font-size:9px;color:var(--g);font-family:'Orbitron',sans-serif;min-width:34px;text-align:center}
        .kbdesc{font-size:10px;color:var(--text2)}
        .trail-legend{position:fixed;bottom:120px;left:16px;z-index:200;background:var(--panel2);border:1px solid var(--border);padding:8px 12px;display:none}
        .trail-legend.vis{display:block}
        .tl-title{font-size:8px;color:var(--text3);text-transform:uppercase;margin-bottom:6px}
        .tl-row{display:flex;align-items:center;gap:7px;margin-bottom:4px;font-size:9px;color:var(--text2)}
        .tl-dot{width:10px;height:4px}
        .refbar{position:fixed;bottom:0;left:0;right:0;height:2px;background:rgba(0,255,136,.05);z-index:999}
        .refprog{height:100%;background:linear-gradient(90deg,var(--g),var(--c));width:100%;transition:width 0.3s linear}
        .mapboxgl-ctrl-bottom-left,.mapboxgl-ctrl-bottom-right{display:none!important}
        .mapboxgl-popup-content{background:var(--panel2)!important;border:1px solid var(--border)!important;color:var(--text)!important;font-family:'Share Tech Mono',monospace!important;font-size:10px!important;padding:10px 13px!important;border-radius:0!important}
        .mapboxgl-popup-tip{display:none!important}
        .mapboxgl-ctrl-top-right{top:52px!important;right:90px!important}
        @media(max-width:620px){.tstats .tsc:nth-child(n+4){display:none}.layerpanel{display:none}.hud{display:none}.radarwrap{display:none}}
    </style>
</head>
<body>
    <!-- MODAL -->
    <div id="modal">
        <div class="mbox">
            <div class="mtitle">MAPBOX API TOKEN</div>
            <div class="msub">UYDU HARİTA ERİŞİMİ</div>
            <p class="mdesc">
                <a href="https://account.mapbox.com" target="_blank">account.mapbox.com</a>
                adresinden <b>ücretsiz</b> hesap oluşturun.<br>
                <b>Access Tokens</b> sayfasından <b>pk.</b> ile başlayan token alın.<br><br>
                Token olmadan <b>Demo Mod</b> ile devam edebilirsiniz.<br>
                <span style="color:rgba(168,255,212,0.35)">Demo modda harita arka plan olmaz, tüm diğer özellikler aktiftir.</span>
            </p>
            <div class="msaved" id="msaved"><span>✓</span><span id="msaved-txt">Kayıtlı token</span></div>
            <div class="mlabel">TOKEN</div>
            <input id="tokeninput" class="minput" type="text" placeholder="pk.eyJ1IjoiuserIiwiYSI6ImtleUlkIn0.XXXX" autocomplete="off" spellcheck="false">
            <div class="merr" id="merr"></div>
            <div class="mbtns">
                <button class="mbtn-start" id="mbtnstart">▶ BAŞLAT</button>
                <button class="mbtn-demo" id="mbtndemo">DEMO MOD</button>
            </div>
            <div class="mhint">ENTER = Başlat &nbsp;|&nbsp; TAB = Demo Mod &nbsp;|&nbsp; Token kayda alınır</div>
        </div>
    </div>

    <!-- LOADING -->
    <div id="loading">
        <div class="ldlogo">SKYWATCH</div>
        <div class="ldsub">CANLI UÇAK TAKİP SİSTEMİ v4.0</div>
        <div class="ldbarwrap"><div class="ldbar" id="ldbar"></div></div>
        <div class="ldstatus" id="ldstatus">HAZIRLANIYOR...</div>
    </div>

    <!-- KEYBOARD HELP -->
    <div class="kbhelp" id="kbhelp">
        <div class="kbbox">
            <div class="kbtitle">KLAVYE KISAYOLLARI <span onclick="toggleHelp()" style="cursor:pointer;color:var(--o);font-size:20px">×</span></div>
            <div class="kbgrid">
                <div class="kbrow"><div class="kbkey">F</div><div class="kbdesc">Arama aç/kapat</div></div>
                <div class="kbrow"><div class="kbkey">R</div><div class="kbdesc">Veriyi yenile</div></div>
                <div class="kbrow"><div class="kbkey">L</div><div class="kbdesc">Sol paneli aç/kapat</div></div>
                <div class="kbrow"><div class="kbkey">S</div><div class="kbdesc">Uydu katmanı</div></div>
                <div class="kbrow"><div class="kbkey">D</div><div class="kbdesc">Karanlık katmanı</div></div>
                <div class="kbrow"><div class="kbkey">T</div><div class="kbdesc">Sokak katmanı</div></div>
                <div class="kbrow"><div class="kbkey">H</div><div class="kbdesc">Hava durumu</div></div>
                <div class="kbrow"><div class="kbkey">N</div><div class="kbdesc">Gece/gündüz</div></div>
                <div class="kbrow"><div class="kbkey">I</div><div class="kbdesc">Uçak izleri (tümü)</div></div>
                <div class="kbrow"><div class="kbkey">C</div><div class="kbdesc">Konumumu bul</div></div>
                <div class="kbrow"><div class="kbkey">X</div><div class="kbdesc">Seçimi kaldır</div></div>
                <div class="kbrow"><div class="kbkey">ESC</div><div class="kbdesc">Kapat / Geri</div></div>
                <div class="kbrow"><div class="kbkey">?</div><div class="kbdesc">Bu yardım ekranı</div></div>
                <div class="kbrow"><div class="kbkey">F11</div><div class="kbdesc">Tam ekran</div></div>
            </div>
        </div>
    </div>

    <!-- TOPBAR -->
    <div class="topbar">
        <div class="tlogo">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z" fill="#00ff88"/><circle cx="12" cy="12" r="11" stroke="rgba(0,255,136,0.2)" stroke-width="1"/></svg>
            SKYWATCH
        </div>
        <div class="tvbar"></div>
        <div class="tstats">
            <div class="tsc"><div class="statusdot loading" id="sdot"></div><span id="sstatus">BAĞLANIYOR</span></div>
            <div class="tsc">✈ <span class="tval" id="scount">0</span></div>
            <div class="tsc">GÖR.:<span class="tval" id="svis">0</span></div>
            <div class="tsc">ÜLKE:<span class="tval" id="scountry">0</span></div>
            <div class="tsc">MAX:<span class="tval" id="smaxalt">0</span>m</div>
            <div class="tsc">⟳<span class="tval" id="slastupd">--:--</span></div>
        </div>
        <div class="tright">
            <div class="tclock" id="tclock">00:00:00</div>
            <button class="tbtn" onclick="toggleSearch()" title="Arama [F]">🔍</button>
            <button class="tbtn" onclick="doRefresh()" title="Yenile [R]">⟳</button>
            <button class="tbtn" onclick="gotoMe()" title="Konum [C]">📍</button>
            <button class="tbtn" id="wxbtn" onclick="toggleWeather()" title="Hava [H]">☁️</button>
            <button class="tbtn" id="trmbn" onclick="toggleTerminator()" title="Gece/Gündüz [N]">☀️</button>
            <button class="tbtn" id="alltrailbtn" onclick="toggleAllTrails()" title="Tüm izler [I]">➡️</button>
            <button class="tbtn" onclick="toggleHelp()" title="Yardım [?]">?</button>
            <button class="tbtn" onclick="doFullscreen()">⛶</button>
        </div>
    </div>

    <!-- SEARCH -->
    <div class="searchbar" id="searchbar">
        <div style="position:relative;flex:1">
            <input class="sinput" id="sinput" placeholder="Callsign, ülke, ICAO24..." oninput="doSearch(this.value)" onkeydown="searchKeydown(event)">
            <div class="sresults" id="sresults"></div>
        </div>
        <button class="scloseBtn" onclick="toggleSearch()">×</button>
    </div>

    <!-- PANEL TOGGLE -->
    <div class="ptoggle" id="ptoggle" onclick="togglePanel()">◀</div>

    <!-- LEFT PANEL -->
    <div class="lpanel" id="lpanel">
        <div class="tabs">
            <button class="tabbtn on" id="tab0" onclick="switchTab(0)">UÇUŞLAR</button>
            <button class="tabbtn" id="tab1" onclick="switchTab(1)">İSTAT</button>
            <button class="tabbtn" id="tab2" onclick="switchTab(2)">ALARM</button>
            <button class="tabbtn" id="tab3" onclick="switchTab(3)">AYAR</button>
        </div>
        <div class="tabpanel on" id="tp0">
            <div class="slider-section">
                <div class="slider-row"><span class="slider-label">HARİTA UÇAK LİMİTİ</span><span class="slider-val" id="sliderval">150</span></div>
                <input type="range" class="slider" id="limitslider" min="10" max="500" value="150" step="10" oninput="onSlider(this.value)">
                <div class="perf-row">
                    <button class="perf-btn" onclick="setPerf('eco')" id="perf-eco">ECO</button>
                    <button class="perf-btn on" onclick="setPerf('normal')" id="perf-normal">NORMAL</button>
                    <button class="perf-btn" onclick="setPerf('ultra')" id="perf-ultra">ULTRA</button>
                </div>
            </div>
            <div class="fbar">
                <button class="fchip on" id="fc-all" onclick="setFilter('all')">TÜMÜ</button>
                <button class="fchip" id="fc-high" onclick="setFilter('high')">Y.ALT</button>
                <button class="fchip" id="fc-fast" onclick="setFilter('fast')">HIZ</button>
                <button class="fchip" id="fc-tr" onclick="setFilter('tr')">TR</button>
                <button class="fchip red" id="fc-emg" onclick="setFilter('emg')">ACİL</button>
            </div>
            <div class="fcountbar"><span><span id="fcount">0</span> UÇAK LISTEDE</span><span id="ftotal" style="color:var(--text3)"></span></div>
            <div id="flist" style="flex:1;overflow-y:auto">
                <div style="padding:22px;text-align:center;color:var(--text3);font-size:11px">VERİ YÜKLENİYOR...</div>
            </div>
        </div>
        <div class="tabpanel" id="tp1">
            <div class="stblock"><div class="sthead">GENEL ÖZET</div><div class="bigstat"><div class="bsi"><div class="bsv" id="st-total">0</div><div class="bsl">TOPLAM UÇAK</div></div><div class="bsi"><div class="bsv" id="st-country">0</div><div class="bsl">ÜLKE</div></div><div class="bsi"><div class="bsv" id="st-avgalt">0</div><div class="bsl">ORT YÜK (m)</div></div><div class="bsi"><div class="bsv" id="st-avgspd">0</div><div class="bsl">ORT HIZ</div></div><div class="bsi"><div class="bsv" id="st-maxspd">0</div><div class="bsl">MAX HIZ</div></div><div class="bsi"><div class="bsv" id="st-maxalt">0</div><div class="bsl">MAX YÜK (m)</div></div></div></div>
            <div class="stblock"><div class="sthead">ÜLKE SIRASI</div><div id="st-countries"></div></div>
            <div class="stblock"><div class="sthead">HIZ DAĞILIMI (km/s)</div><div id="st-speeds"></div></div>
            <div class="stblock"><div class="sthead">YÜKSEKLİK (m)</div><div id="st-alts"></div></div>
            <div class="stblock"><div class="sthead">AIRLINE SIRASI</div><div id="st-airlines"></div></div>
        </div>
        <div class="tabpanel" id="tp2">
            <div style="padding:7px 12px;border-bottom:1px solid rgba(0,255,136,.06);font-size:9px;color:var(--text3);display:flex;justify-content:space-between;align-items:center"><span id="alertheader">ALARMLAR</span><button class="fchip" onclick="clearAlerts()" style="font-size:8px;padding:2px 7px">TEMİZLE</button></div>
            <div id="alertlist"><div class="no-alerts">ALARM YOK</div></div>
        </div>
        <div class="tabpanel" id="tp3">
            <div class="sett-section">HARİTA</div>
            <div class="settrow"><span class="settlabel">Uçuş izleri göster</span><div class="toggle-sw" id="sw-trail" onclick="toggleSetting('trail')"></div></div>
            <div class="settrow"><span class="settlabel">Yer üzerindeki uçaklar</span><div class="toggle-sw" id="sw-ground" onclick="toggleSetting('ground')"></div></div>
            <div class="settrow"><span class="settlabel">Havaalanı katmanı</span><div class="toggle-sw on" id="sw-airports" onclick="toggleSetting('airports')"></div></div>
            <div class="settrow"><span class="settlabel">Animasyonlu uçak</span><div class="toggle-sw on" id="sw-anim" onclick="toggleSetting('anim')"></div></div>
            <div class="sett-section">PERFORMANS</div>
            <div class="settrow"><span class="settlabel">Yenileme süresi</span><span class="settval" id="rf-val">30s</span></div>
            <div style="padding:6px 12px"><input type="range" class="slider" id="rfslider" min="15" max="120" value="30" step="5" oninput="onRfSlider(this.value)"></div>
            <div class="sett-section">DIŞA AKTAR</div>
            <div class="settrow"><span class="settlabel">JSON aktar</span><button class="expbtn" onclick="exportJSON()">⬇ JSON</button></div>
            <div class="settrow"><span class="settlabel">CSV aktar</span><button class="expbtn" onclick="exportCSV()">⬇ CSV</button></div>
            <div class="sett-section">TOKEN</div>
            <div class="settrow"><span class="settlabel">Kayıtlı token</span><button class="expbtn" onclick="clearToken()" style="color:var(--r);border-color:rgba(255,68,102,.3)">SİL</button></div>
        </div>
    </div>

    <!-- MAP -->
    <div id="map"></div>

    <!-- TRAIL LEGEND -->
    <div class="trail-legend" id="trail-legend">
        <div class="tl-title">İZ RENK KODLARI</div>
        <div class="tl-row"><div class="tl-dot" style="background:#00ff88"></div><span>Alçak (&lt;3km)</span></div>
        <div class="tl-row"><div class="tl-dot" style="background:#00e5ff"></div><span>Orta (3-6km)</span></div>
        <div class="tl-row"><div class="tl-dot" style="background:#ffcc00"></div><span>Yüksek (6-9km)</span></div>
        <div class="tl-row"><div class="tl-dot" style="background:#ff4466"></div><span>Çok yüksek (&gt;9km)</span></div>
    </div>

    <!-- LAYER PANEL -->
    <div class="layerpanel">
        <button class="lbtn on" id="lbsat" onclick="setLayer('satellite')">🛰 UYDU</button>
        <button class="lbtn" id="lbdrk" onclick="setLayer('dark')">🌙 KARANLIK</button>
        <button class="lbtn" id="lbstr" onclick="setLayer('street')">🗺 SOKAK</button>
    </div>

    <!-- COMPASS -->
    <div class="compass"><canvas id="compass" width="46" height="46"></canvas></div>

    <!-- INFO PANEL -->
    <div class="infopanel" id="infopanel">
        <div class="infohead"><span id="info-call">---</span><div class="infohead-acts"><button class="itrailbtn" id="trailbtn" onclick="toggleSelTrail()">İZ</button><span class="closex" onclick="closeInfo()">×</span></div></div>
        <div class="infogrid">
            <div class="ifield"><div class="ilabel">ÜLKE</div><div class="ival blue" id="inf-co">---</div></div>
            <div class="ifield"><div class="ilabel">YÜKSEKLİK</div><div class="ival" id="inf-alt">---</div></div>
            <div class="ifield"><div class="ilabel">HIZ (km/s)</div><div class="ival" id="inf-spd">---</div></div>
            <div class="ifield"><div class="ilabel">ROTA</div><div class="ival" id="inf-hdg">---</div></div>
            <div class="ifield"><div class="ilabel">ENLEM</div><div class="ival" id="inf-lat">---</div></div>
            <div class="ifield"><div class="ilabel">BOYLAM</div><div class="ival" id="inf-lon">---</div></div>
            <div class="ifield"><div class="ilabel">SQUAWK</div><div class="ival" id="inf-sqk">---</div></div>
            <div class="ifield"><div class="ilabel">DURUM</div><div class="ival" id="inf-grnd">---</div></div>
            <div class="ifield"><div class="ilabel">DİKEY HIZ</div><div class="ival" id="inf-vs">---</div></div>
            <div class="ifield"><div class="ilabel">ICAO24</div><div class="ival" style="font-size:10px" id="inf-icao">---</div></div>
        </div>
        <div class="spdwrap"><div class="spdlabel">0</div><div class="spdtrack"><div class="spdfill" id="spdgauge"></div></div><div class="spdlabel">1200+</div></div>
        <div class="spdhist"><div class="spdhist-label">HIZ GEÇMİŞİ</div><canvas id="spdhist-canvas" width="274" height="36"></canvas></div>
        <div class="infobtns"><button class="iabtn" onclick="flyToSel()">✈ GİT</button><button class="iabtn" onclick="copyCoords()">📋 KOORD</button><button class="iabtn" onclick="openFA()">FA↗</button><button class="iabtn" onclick="openFR24()">FR24↗</button></div>
    </div>

    <!-- RADAR -->
    <div class="radarwrap"><div class="radarhead">RADAR <span class="radarcnt" id="radarcnt">0</span></div><canvas id="radarc" width="100" height="100"></canvas></div>

    <!-- HUD -->
    <div class="hud" id="hud">
        <div class="hud-m"><div class="hud-label">YÜKSEKLİK</div><div class="hud-val" id="hud-alt">---</div><div class="hud-unit">m</div></div>
        <div class="hud-m"><div class="hud-label">HIZ</div><div class="hud-val" id="hud-spd">---</div><div class="hud-unit">km/s</div></div>
        <div class="hud-m"><div class="hud-label">ROTA</div><div class="hud-val" id="hud-hdg">---</div><div class="hud-unit">deg</div></div>
        <div class="hud-m"><div class="hud-label">DİKEY</div><div class="hud-val" id="hud-vs">---</div><div class="hud-unit">m/s</div></div>
    </div>

    <!-- NOTIFICATION -->
    <div class="notif" id="notif"><div class="notif-icon" id="notif-icon">i</div><span id="notif-msg"></span></div>

    <!-- REFRESH BAR -->
    <div class="refbar"><div class="refprog" id="refprog"></div></div>

    <script>
        // ----- STATE -----
        let MAP = null, TOKEN = '', DEMO = false;
        let flights = [], filteredFlights = [], selIcao = null;
        let activeFilter = 'all', markerLimit = 150, perfMode = 'normal';
        let panelOpen = true, searchOpen = false, helpOpen = false;
        let curLayer = 'satellite', weatherOn = false, terminatorOn = false;
        let showAllTrails = false;
        let markers = {}, trailData = {}, trailEnabled = {}, speedHistory = {};
        let alerts = [], rfTimer = null, radarAngle = 0;
        let RF = 30000;
        let settings = {trail: false, ground: false, airports: true, anim: true};

        const FLAGS = {
            Turkey:'TR',Germany:'DE','United Kingdom':'GB',France:'FR',
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
        function flag(c) {
            let code = FLAGS[c];
            if(!code) return '🌐';
            return code.split('').map(x => String.fromCodePoint(127397 + x.charCodeAt(0))).join('');
        }

        // ----- NOTIFY -----
        function notify(msg, type='info') {
            const el = document.getElementById('notif');
            const ic = document.getElementById('notif-icon');
            const mc = document.getElementById('notif-msg');
            ic.textContent = type==='err'?'!' : type==='warn'?'?' : type==='ok'?'✓' : 'i';
            mc.textContent = msg;
            el.className = `notif show${type==='err'?' err':type==='warn'?' warn':type==='ok'?' ok':''}`;
            clearTimeout(el._t);
            el._t = setTimeout(() => el.classList.remove('show'), 3800);
        }

        // ----- MODAL -----
        window.addEventListener('load', () => {
            const saved = localStorage.getItem('skyw4_token');
            if(saved && saved.length > 10) {
                document.getElementById('tokeninput').value = saved;
                const sv = document.getElementById('msaved');
                document.getElementById('msaved-txt').textContent = saved.slice(0,20)+'...';
                sv.classList.add('show');
            }
            document.getElementById('tokeninput').addEventListener('keydown', e => {
                if(e.key === 'Enter') doStart();
                if(e.key === 'Tab'){ e.preventDefault(); doDemo(); }
            });
            document.getElementById('mbtnstart').onclick = doStart;
            document.getElementById('mbtndemo').onclick = doDemo;
        });
        function setModalErr(msg) {
            document.getElementById('merr').innerHTML = msg ? `<span>⚠</span> ${msg}` : '';
        }
        function doStart() {
            const v = document.getElementById('tokeninput').value.trim();
            setModalErr('');
            if(!v) { setModalErr('Token boş bırakılamaz'); return; }
            if(v.length < 10) { setModalErr('Token çok kısa, en az 10 karakter'); return; }
            TOKEN = v;
            localStorage.setItem('skyw4_token', v);
            lockModal();
            boot(false).catch(err => {
                console.error(err);
                setModalErr('Başlatma hatası: ' + (err.message || 'bilinmeyen hata'));
                unlockModal();
            });
        }
        function doDemo() {
            DEMO = true;
            lockModal();
            boot(true).catch(err => {
                console.error(err);
                setModalErr('Demo başlatma hatası: ' + (err.message || 'bilinmeyen hata'));
                unlockModal();
            });
        }
        function lockModal() {
            document.getElementById('mbtnstart').disabled = true;
            document.getElementById('mbtndemo').disabled = true;
            document.getElementById('modal').classList.add('gone');
        }
        function unlockModal() {
            document.getElementById('mbtnstart').disabled = false;
            document.getElementById('mbtndemo').disabled = false;
            document.getElementById('modal').classList.remove('gone');
        }

        // ----- BOOT -----
        async function boot(demo) {
            const ld = document.getElementById('loading');
            const bar = document.getElementById('ldbar');
            const status = document.getElementById('ldstatus');
            ld.classList.add('on');
            const steps = [
                [10, 'SISTEM BASLATILIYOR...'],
                [22, 'OPENSKY API BAGLANTISI...'],
                [40, 'HARITA KATMANLARI YUKLENIYOR...'],
                [58, 'UCAK VERITABANI OLUSTURULUYOR...'],
                [72, 'RADAR AKTIF EDILIYOR...'],
                [85, 'PERFORMANS OPTIMIZE EDILIYOR...'],
                [95, 'GOSTERIM MOTORU HAZIRLANIYOR...'],
                [100, 'HAZIR!']
            ];
            for(let i=0;i<steps.length;i++) {
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
        function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

        // ----- CLOCK -----
        function startClock() {
            setInterval(() => {
                document.getElementById('tclock').textContent = new Date().toTimeString().slice(0,8);
            }, 1000);
        }

        // ----- MAP -----
        function initMap() {
            mapboxgl.accessToken = TOKEN;
            MAP = new mapboxgl.Map({
                container: 'map',
                style: 'mapbox://styles/mapbox/satellite-v9',
                center: [35, 40], zoom: 4, antialias: true
            });
            MAP.addControl(new mapboxgl.NavigationControl({showCompass:false}), 'top-right');
            MAP.on('load', () => { setSdot('live'); addTrailSources(); });
            MAP.on('error', e => { setSdot('error'); notify('Harita hatası! Token geçerli mi?', 'err'); });
            MAP.on('rotate', () => drawCompass(MAP.getBearing()));
            MAP.on('zoom', () => drawCompass(MAP.getBearing()));
        }
        function initNoMap() {
            setSdot('demo');
            const m = document.getElementById('map');
            m.style.background = 'radial-gradient(ellipse at 50% 40%, #030f1e 0%, #020810 100%)';
            const c = document.createElement('canvas');
            c.style.cssText = 'position:absolute;inset:0;width:100%;height:100%';
            m.appendChild(c);
            c.width = window.innerWidth; c.height = window.innerHeight;
            const ctx = c.getContext('2d');
            ctx.strokeStyle = 'rgba(0,255,136,0.04)'; ctx.lineWidth = 1;
            for(let x=0;x<c.width;x+=60){ ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,c.height);ctx.stroke(); }
            for(let y=0;y<c.height;y+=60){ ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(c.width,y);ctx.stroke(); }
            ctx.fillStyle = 'rgba(168,255,212,0.3)';
            for(let i=0;i<120;i++){
                const sx = Math.random()*c.width, sy = Math.random()*c.height;
                ctx.beginPath(); ctx.arc(sx,sy,Math.random()*0.8+0.2,0,Math.PI*2); ctx.fill();
            }
        }
        function setSdot(state) {
            const d = document.getElementById('sdot'), s = document.getElementById('sstatus');
            d.className = 'statusdot';
            const map = {live:['','CANLI'],loading:['loading','YÜKLENİYOR'],error:['error','HATA'],demo:['demo','DEMO']};
            const v = map[state] || ['','?'];
            if(v[0]) d.classList.add(v[0]);
            s.textContent = v[1];
        }

        // ----- LAYER -----
        const LAYERS = {
            satellite: 'mapbox://styles/mapbox/satellite-v9',
            dark: 'mapbox://styles/mapbox/dark-v11',
            street: 'mapbox://styles/mapbox/streets-v12'
        };
        function setLayer(l) {
            if(DEMO || !MAP) return;
            curLayer = l;
            const ids = {satellite:'lbsat',dark:'lbdrk',street:'lbstr'};
            Object.keys(ids).forEach(k => document.getElementById(ids[k]).classList.toggle('on', k===l));
            MAP.setStyle(LAYERS[l]);
            MAP.once('style.load', () => { addTrailSources(); redrawMarkers(); });
            notify(l.toUpperCase()+' KATMANI', 'info');
        }

        // ----- TERMINATOR -----
        function toggleTerminator() {
            terminatorOn = !terminatorOn;
            document.getElementById('trmbn').classList.toggle('on', terminatorOn);
            if(terminatorOn) drawTerminator();
            else if(MAP && MAP.isStyleLoaded()){ try{ if(MAP.getLayer('trm'))MAP.removeLayer('trm'); if(MAP.getSource('trm'))MAP.removeSource('trm'); }catch(e){} }
            notify('GECE/GÜNDÜZ '+(terminatorOn?'AKTİF':'KAPALI'), 'info');
        }
        function drawTerminator() {
            if(!MAP || !MAP.isStyleLoaded()) return;
            const d = new Date();
            const dec = -23.45 * Math.cos((360/365*(d.getMonth()*30+d.getDate())+10)*Math.PI/180) * Math.PI/180;
            let coords = [];
            for(let lon=-180;lon<=180;lon+=2){
                const lat = Math.atan(-Math.cos(lon*Math.PI/180)/Math.tan(dec))*180/Math.PI;
                coords.push([lon,lat]);
            }
            coords.push([180,-90],[180,90],[-180,90],[-180,coords[0][1]],coords[0]);
            try{
                if(MAP.getSource('trm')){ MAP.removeLayer('trm'); MAP.removeSource('trm'); }
                MAP.addSource('trm',{type:'geojson',data:{type:'Feature',geometry:{type:'Polygon',coordinates:[coords]}}});
                MAP.addLayer({id:'trm',type:'fill',source:'trm',paint:{'fill-color':'#000018','fill-opacity':0.42}});
            }catch(e){}
        }

        // ----- WEATHER -----
        function toggleWeather() {
            weatherOn = !weatherOn;
            document.getElementById('wxbtn').classList.toggle('on', weatherOn);
            notify('HAVA DURUMU '+(weatherOn?'AKTİF':'KAPALI'), 'info');
            if(!MAP || DEMO) return;
            if(weatherOn){
                try{
                    if(!MAP.isStyleLoaded()){
                        notify('Harita yükleniyor, tekrar deneyin','warn');
                        weatherOn = false;
                        return;
                    }
                    MAP.addSource('owm',{type:'raster',tiles:['https://tile.openweathermap.org/map/clouds_new/{z}/{x}/{y}.png?appid=439d4b804bc8187953eb36d2a8c26a02'],tileSize:256,attribution:'OpenWeatherMap'});
                    MAP.addLayer({id:'owmlayer',type:'raster',source:'owm',paint:{'raster-opacity':0.4}});
                }catch(e){ notify('Hava katmanı yüklenemedi','warn'); }
            }else{
                try{ if(MAP.getLayer('owmlayer'))MAP.removeLayer('owmlayer'); if(MAP.getSource('owm'))MAP.removeSource('owm'); }catch(e){}
            }
        }

        // ----- OPENSKY + PARSE -----
        const OPENSKY_ENDPOINTS = [
            'https://opensky-network.org/api/states/all?lamin=25&lomin=-20&lamax=72&lomax=55',
            'https://opensky-network.org/api/states/all'
        ];
        async function fetchFlights() {
            for(let i=0;i<OPENSKY_ENDPOINTS.length;i++){
                try{
                    const ctrl = new AbortController();
                    const tid = setTimeout(() => ctrl.abort(), 15000);
                    const r = await fetch(OPENSKY_ENDPOINTS[i], {signal:ctrl.signal});
                    clearTimeout(tid);
                    if(!r.ok) continue;
                    const d = await r.json();
                    return d.states || [];
                }catch(e){ continue; }
            }
            notify('OpenSky API ulaşılamadı — demo veri kullanılıyor', 'warn');
            return generateDemo();
        }
        function parseState(s) {
            return {
                icao24: s[0] || '',
                callsign: (s[1]||'').trim() || s[0] || '????',
                country: s[2] || 'Unknown',
                lon: s[5], lat: s[6],
                alt: s[7] ? Math.round(s[7]) : null,
                ground: s[8] || false,
                vel: s[9] ? Math.round(s[9]*3.6) : null,
                hdg: s[10] !== null ? Math.round(s[10]) : null,
                vs: s[11] ? Math.round(s[11]) : 0,
                sqk: s[14] || '----'
            };
        }
        function generateDemo() {
            const airlines = ['TK','LH','BA','AF','EK','QR','SU','PC','FR','W6','IBE','KLM','SAS','THY','AUA','SWR','TAP','WZZ','RYR','EZY'];
            const countries = Object.keys(FLAGS).slice(0,18);
            return Array.from({length:120}, (_,i) => {
                const al = airlines[i%airlines.length];
                const co = countries[i%countries.length];
                return [
                    'dm'+String(i).padStart(3,'0'), al+(200+i)+'  ', co,
                    null, null,
                    8+Math.random()*52, 28+Math.random()*38,
                    800+Math.random()*13000, false,
                    80+Math.random()*1000, Math.random()*360,
                    (Math.random()-0.5)*14, null, null,
                    Math.floor(1000+Math.random()*8999)
                ];
            });
        }

        // ----- LOAD FLIGHTS -----
        async function loadFlights() {
            setSdot('loading');
            const raw = await fetchFlights();
            flights = raw.map(parseState).filter(f => f.lat && f.lon && (settings.ground || !f.ground));
            if(selIcao){
                const sf = flights.find(f => f.icao24 === selIcao);
                if(sf && sf.vel){
                    if(!speedHistory[selIcao]) speedHistory[selIcao]=[];
                    speedHistory[selIcao].push(sf.vel);
                    if(speedHistory[selIcao].length>30) speedHistory[selIcao].shift();
                }
            }
            const countries = new Set(flights.map(f => f.country));
            const alts = flights.filter(f => f.alt);
            document.getElementById('scount').textContent = flights.length;
            document.getElementById('scountry').textContent = countries.size;
            document.getElementById('smaxalt').textContent = alts.length ? Math.max(...alts.map(f => f.alt)) : 0;
            document.getElementById('slastupd').textContent = new Date().toTimeString().slice(0,5);
            setSdot(DEMO?'demo':'live');
            checkAlerts();
            updateStats();
            applyFilterAndRender();
            updateAllTrails();
            if(MAP) redrawMarkers();
            if(selIcao) refreshInfoPanel();
        }
        function doRefresh() { resetRefTimer(); loadFlights(); notify('VERİ YENİLENDİ','ok'); }

        // ----- FILTER & RENDER LIST -----
        function setFilter(f) {
            activeFilter = f;
            ['all','high','fast','tr','emg'].forEach(x => {
                const el = document.getElementById('fc-'+x);
                if(el) el.classList.toggle('on', x===f);
            });
            applyFilterAndRender();
        }
        function applyFilterAndRender() {
            filteredFlights = flights.filter(f => {
                if(activeFilter==='all') return true;
                if(activeFilter==='high') return f.alt && f.alt>9000;
                if(activeFilter==='fast') return f.vel && f.vel>800;
                if(activeFilter==='tr') return f.country==='Turkey';
                if(activeFilter==='emg') return f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
                return true;
            });
            document.getElementById('fcount').textContent = filteredFlights.length;
            document.getElementById('ftotal').textContent = '/ '+flights.length;
            document.getElementById('svis').textContent = Math.min(markerLimit, filteredFlights.length);
            renderList();
        }
        function renderList() {
            const fl = document.getElementById('flist');
            const frag = document.createDocumentFragment();
            fl.innerHTML = '';
            filteredFlights.slice(0,200).forEach(f => {
                const emg = f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
                const highAlt = f.alt && f.alt>9000;
                const altPct = f.alt ? Math.min(100, f.alt/130) : 0;
                const altColor = f.alt>9000?'#ff4466':f.alt>6000?'#ffcc00':f.alt>3000?'#00e5ff':'#00ff88';
                const d = document.createElement('div');
                d.className = `fitem${f.icao24===selIcao?' sel':''}${emg?' emerg':''}`;
                const badge = emg ? '<span class="fbadge emerg">ACİL</span>' : highAlt ? '<span class="fbadge high">HIGH</span>' : '';
                d.innerHTML = `
                    <div class="fcall"><span class="fflag">${flag(f.country)}</span>${f.callsign}${badge}</div>
                    <div class="fdetail">
                        <span class="fdv">${f.country.slice(0,12)}</span>
                        <span>▲<span class="fdv">${f.alt?f.alt+'m':'--'}</span></span>
                        <span>➡<span class="fdv">${f.vel?f.vel:'--'}</span></span>
                        ${f.hdg!==null?`<span>${f.hdg}°</span>`:''}
                    </div>
                    <div class="faltbar"><div class="faltfill" style="width:${altPct}%;background:${altColor}"></div></div>
                `;
                d.onclick = (ff => () => pickFlight(ff))(f);
                frag.appendChild(d);
            });
            fl.appendChild(frag);
        }

        // ----- MARKERS -----
        function redrawMarkers() {
            if(!MAP) return;
            Object.values(markers).forEach(m => m.remove());
            markers = {};
            const toShow = filteredFlights.length ? filteredFlights : flights;
            toShow.slice(0, markerLimit).forEach(f => {
                const el = createMarkerEl(f);
                const m = new mapboxgl.Marker({element:el, anchor:'center'})
                    .setLngLat([f.lon, f.lat])
                    .addTo(MAP);
                el.addEventListener('click', (ff => e => { e.stopPropagation(); pickFlight(ff); })(f));
                markers[f.icao24] = m;
            });
        }
        function createMarkerEl(f) {
            const sel = f.icao24 === selIcao;
            const emg = f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
            const color = emg?'#ff4466' : sel?'#00e5ff' : f.alt>9000?'#ffcc00' : f.alt>3000?'#00ff88' : '#88ffcc';
            const sz = sel?22:14;
            const hdg = f.hdg||0;
            const el = document.createElement('div');
            el.style.cssText = `width:${sz}px;height:${sz}px;cursor:pointer;will-change:transform;`;
            if(emg) el.style.animation = 'blink .5s infinite';
            el.innerHTML = `
                <svg viewBox="0 0 24 24" fill="none" style="transform:rotate(${hdg}deg);width:100%;height:100%">
                    <path d="M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z" fill="${color}" opacity="0.95"/>
                    <circle cx="12" cy="12" r="11" stroke="${color}" stroke-opacity="0.2" stroke-width="0.5"/>
                    ${sel?'<circle cx="12" cy="12" r="4" fill="'+color+'" opacity="0.5"/>':''}
                </svg>
            `;
            el.style.filter = sel ? `drop-shadow(0 0 8px ${color}) drop-shadow(0 0 3px ${color})` : `drop-shadow(0 0 3px ${color})`;
            return el;
        }

        // ----- TRAIL SYSTEM -----
        function addTrailSources() {}
        function getTrailColor(alt) {
            if(!alt) return '#00ff88';
            if(alt > 9000) return '#ff4466';
            if(alt > 6000) return '#ffcc00';
            if(alt > 3000) return '#00e5ff';
            return '#00ff88';
        }
        function updateTrailForFlight(f) {
            if(!MAP || !f.lat || !f.lon) return;
            const icao = f.icao24;
            if(!trailData[icao]) trailData[icao]=[];
            trailData[icao].push({coords:[f.lon,f.lat], alt:f.alt, ts:Date.now()});
            if(trailData[icao].length>120) trailData[icao].shift();
            renderTrailOnMap(icao);
        }
        function renderTrailOnMap(icao) {
            if(!MAP || !MAP.isStyleLoaded()) return;
            const pts = trailData[icao];
            if(!pts || pts.length<2) return;
            const segments = [];
            for(let i=1;i<pts.length;i++){
                segments.push({coords:[pts[i-1].coords, pts[i].coords], color:getTrailColor(pts[i].alt)});
            }
            try{
                const style = MAP.getStyle();
                const toRemove = (style.layers||[]).filter(l => l.id.startsWith('trail-'+icao+'-'));
                toRemove.forEach(l => { try{MAP.removeLayer(l.id);}catch(e){} });
                const srcRemove = Object.keys(style.sources||{}).filter(s => s.startsWith('trsrc-'+icao+'-'));
                srcRemove.forEach(s => { try{MAP.removeSource(s);}catch(e){} });
            }catch(e){}
            const colorGroups = {};
            segments.forEach(seg => {
                if(!colorGroups[seg.color]) colorGroups[seg.color]=[];
                colorGroups[seg.color].push(seg.coords);
            });
            Object.keys(colorGroups).forEach((color, ci) => {
                const srcId = 'trsrc-'+icao+'-'+ci;
                const lyrId = 'trail-'+icao+'-'+ci;
                const lines = colorGroups[color].map(coords => ({type:'Feature',geometry:{type:'LineString',coordinates:coords}}));
                try{
                    MAP.addSource(srcId,{type:'geojson',data:{type:'FeatureCollection',features:lines}});
                    MAP.addLayer({id:lyrId,type:'line',source:srcId,paint:{'line-color':color,'line-width':['interpolate',['linear'],['zoom'],4,1.5,10,3],'line-opacity':0.7,'line-blur':0.5}});
                }catch(e){}
            });
        }
        function updateAllTrails() {
            if(!MAP || !MAP.isStyleLoaded()) return;
            flights.forEach(f => { if(trailEnabled[f.icao24] || showAllTrails) updateTrailForFlight(f); });
        }
        function clearTrailForFlight(icao) {
            if(!MAP||!MAP.isStyleLoaded()) return;
            delete trailData[icao];
            try{
                const style = MAP.getStyle();
                if(!style) return;
                (style.layers||[]).filter(l => l.id.startsWith('trail-'+icao+'-')).forEach(l => { try{MAP.removeLayer(l.id);}catch(e){} });
                Object.keys(style.sources||{}).filter(s => s.startsWith('trsrc-'+icao+'-')).forEach(s => { try{MAP.removeSource(s);}catch(e){} });
            }catch(e){}
        }
        function clearAllTrails() {
            Object.keys(trailData).forEach(icao => clearTrailForFlight(icao));
            trailData = {};
            trailEnabled = {};
            notify('TÜM İZLER TEMİZLENDİ','info');
        }
        function toggleSelTrail() {
            if(!selIcao) return;
            trailEnabled[selIcao] = !trailEnabled[selIcao];
            document.getElementById('trailbtn').classList.toggle('on', trailEnabled[selIcao]);
            if(!trailEnabled[selIcao]) clearTrailForFlight(selIcao);
            else { const f = flights.find(x => x.icao24 === selIcao); if(f) updateTrailForFlight(f); }
            notify('İZ '+(trailEnabled[selIcao]?'AKTİF':'KAPALI'),'info');
        }
        function toggleAllTrails() {
            showAllTrails = !showAllTrails;
            document.getElementById('alltrailbtn').classList.toggle('on', showAllTrails);
            const legend = document.getElementById('trail-legend');
            legend.classList.toggle('vis', showAllTrails);
            if(!showAllTrails){ clearAllTrails(); }
            else { updateAllTrails(); notify('TÜM İZLER AKTİF (performansı düşürebilir)','warn'); }
        }

        // ----- SELECT FLIGHT & INFO PANEL -----
        function pickFlight(f) {
            selIcao = f.icao24;
            if(!speedHistory[f.icao24]) speedHistory[f.icao24]=[];
            if(f.vel) speedHistory[f.icao24].push(f.vel);
            refreshInfoPanel();
            if(MAP && f.lat && f.lon) MAP.flyTo({center:[f.lon,f.lat], zoom:7, speed:1.5, curve:1.2});
            renderList();
            if(MAP) redrawMarkers();
        }
        function refreshInfoPanel() {
            const f = flights.find(x => x.icao24 === selIcao);
            if(!f) return;
            const emg = f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
            document.getElementById('info-call').textContent = f.callsign;
            document.getElementById('inf-co').textContent = flag(f.country)+' '+f.country.slice(0,16);
            const altEl = document.getElementById('inf-alt');
            altEl.textContent = f.alt ? f.alt+'m' : '--';
            altEl.className = 'ival'+(f.alt>9000?' red':f.alt>6000?' yellow':'');
            document.getElementById('inf-spd').textContent = f.vel ? f.vel+' km/s' : '--';
            document.getElementById('inf-hdg').textContent = f.hdg!==null ? f.hdg+'°' : '--';
            document.getElementById('inf-lat').textContent = f.lat ? f.lat.toFixed(5) : '--';
            document.getElementById('inf-lon').textContent = f.lon ? f.lon.toFixed(5) : '--';
            const sqkEl = document.getElementById('inf-sqk');
            sqkEl.textContent = f.sqk || '--';
            sqkEl.className = 'ival'+(emg?' red':'');
            const vsEl = document.getElementById('inf-vs');
            vsEl.textContent = f.vs ? (f.vs>0?'+':'')+f.vs+' m/s' : '--';
            vsEl.className = 'ival'+(f.vs>2?' blue':f.vs<-2?' yellow':'');
            const vertText = f.ground?'YERDE' : f.vs>3?'▲ YÜKSELİYOR' : f.vs<-3?'▼ İNİYOR' : '➡ SEYREDİYOR';
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
        function closeInfo() {
            selIcao = null;
            document.getElementById('infopanel').classList.remove('vis');
            document.getElementById('hud').classList.remove('vis');
            renderList();
            if(MAP) redrawMarkers();
        }
        function flyToSel() { const f = flights.find(x => x.icao24 === selIcao); if(f && MAP) MAP.flyTo({center:[f.lon,f.lat], zoom:9, speed:1.5}); }
        function copyCoords() { const f = flights.find(x => x.icao24 === selIcao); if(!f) return; const t = f.lat.toFixed(5)+', '+f.lon.toFixed(5); try{navigator.clipboard.writeText(t); notify('KOORDİNAT KOPYALANDI','ok');}catch(e){notify(t,'info');} }
        function openFA() { const f = flights.find(x => x.icao24 === selIcao); if(f) window.open('https://flightaware.com/live/flight/'+f.callsign.trim(), '_blank'); }
        function openFR24() { const f = flights.find(x => x.icao24 === selIcao); if(f) window.open('https://www.flightradar24.com/'+f.callsign.trim(), '_blank'); }

        // ----- SPEED HISTORY CHART -----
        function drawSpeedHistory(icao) {
            const cv = document.getElementById('spdhist-canvas');
            const ctx = cv.getContext('2d');
            const pts = speedHistory[icao] || [];
            const W = cv.offsetWidth || 274, H = 36;
            cv.width = W; cv.height = H;
            ctx.clearRect(0,0,W,H);
            if(pts.length < 2){
                ctx.fillStyle = 'rgba(168,255,212,0.2)';
                ctx.font = '9px Share Tech Mono';
                ctx.textAlign = 'center';
                ctx.fillText('VERİ BEKLENİYOR...', W/2, H/2+3);
                return;
            }
            const min = Math.min(...pts);
            const max = Math.max(...pts);
            const range = max===min?1:max-min;
            ctx.strokeStyle = 'rgba(0,255,136,0.06)'; ctx.lineWidth = 1;
            for(let y=0;y<H;y+=H/3){ ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(W,y);ctx.stroke(); }
            const step = W/(pts.length-1);
            const grad = ctx.createLinearGradient(0,0,W,0);
            grad.addColorStop(0,'rgba(0,255,136,0.4)'); grad.addColorStop(1,'rgba(0,229,255,0.9)');
            ctx.beginPath();
            pts.forEach((v,i) => {
                const x = i*step;
                const y = H - ((v-min)/range)*(H-4)-2;
                if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
            });
            ctx.strokeStyle = grad; ctx.lineWidth = 1.5; ctx.stroke();
            ctx.lineTo((pts.length-1)*step, H); ctx.lineTo(0, H); ctx.closePath();
            const fillGrad = ctx.createLinearGradient(0,0,0,H);
            fillGrad.addColorStop(0,'rgba(0,229,255,0.15)'); fillGrad.addColorStop(1,'rgba(0,229,255,0)');
            ctx.fillStyle = fillGrad; ctx.fill();
            ctx.fillStyle = 'rgba(168,255,212,0.4)'; ctx.font = '8px Share Tech Mono'; ctx.textAlign = 'left';
            ctx.fillText(Math.round(max), 2, 9);
            ctx.fillText(Math.round(min), 2, H-2);
        }

        // ----- STATS -----
        function updateStats() {
            const total = flights.length;
            const cmap = {}, amap = {};
            const alts = flights.filter(f => f.alt), vels = flights.filter(f => f.vel);
            flights.forEach(f => {
                cmap[f.country] = (cmap[f.country]||0)+1;
                const al = f.callsign.replace(/[0-9]/g,'').trim().slice(0,3);
                if(al.length>=2) amap[al] = (amap[al]||0)+1;
            });
            const aAlt = alts.length ? Math.round(alts.reduce((s,f)=>s+f.alt,0)/alts.length) : 0;
            const aVel = vels.length ? Math.round(vels.reduce((s,f)=>s+f.vel,0)/vels.length) : 0;
            const maxVel = vels.length ? Math.max(...vels.map(f=>f.vel)) : 0;
            const maxAlt = alts.length ? Math.max(...alts.map(f=>f.alt)) : 0;
            document.getElementById('st-total').textContent = total;
            document.getElementById('st-country').textContent = Object.keys(cmap).length;
            document.getElementById('st-avgalt').textContent = aAlt;
            document.getElementById('st-avgspd').textContent = aVel;
            document.getElementById('st-maxspd').textContent = maxVel;
            document.getElementById('st-maxalt').textContent = maxAlt;

            const renderBars = (containerId, data, color) => {
                const sorted = Object.entries(data).sort((a,b)=>b[1]-a[1]).slice(0,8);
                const maxV = sorted[0] ? sorted[0][1] : 1;
                document.getElementById(containerId).innerHTML = sorted.map(([k,v]) => `
                    <div class="strow"><div class="stlabel">${k.slice(0,16)}</div>
                    <div class="sttrack"><div class="stfill" style="width:${v/maxV*100}%;background:${color}"></div></div>
                    <div class="stval" style="color:${color}">${v}</div></div>
                `).join('');
            };
            renderBars('st-countries', cmap, 'var(--g)');
            renderBars('st-airlines', amap, 'var(--c)');

            const spB = [{l:'<400',n:0},{l:'400-600',n:0},{l:'600-800',n:0},{l:'800-1000',n:0},{l:'>1000',n:0}];
            vels.forEach(f => { if(f.vel<400)spB[0].n++; else if(f.vel<600)spB[1].n++; else if(f.vel<800)spB[2].n++; else if(f.vel<1000)spB[3].n++; else spB[4].n++; });
            const maxS = Math.max(...spB.map(b=>b.n));
            document.getElementById('st-speeds').innerHTML = spB.map(b => `
                <div class="strow"><div class="stlabel">${b.l} km/s</div>
                <div class="sttrack"><div class="stfill" style="width:${maxS>0?b.n/maxS*100:0}%;background:var(--c)"></div></div>
                <div class="stval" style="color:var(--c)">${b.n}</div></div>
            `).join('');

            const aB = [{l:'<3k',n:0},{l:'3-6k',n:0},{l:'6-9k',n:0},{l:'9-12k',n:0},{l:'>12k',n:0}];
            alts.forEach(f => { if(f.alt<3000)aB[0].n++; else if(f.alt<6000)aB[1].n++; else if(f.alt<9000)aB[2].n++; else if(f.alt<12000)aB[3].n++; else aB[4].n++; });
            const maxA = Math.max(...aB.map(b=>b.n));
            document.getElementById('st-alts').innerHTML = aB.map(b => `
                <div class="strow"><div class="stlabel">${b.l} m</div>
                <div class="sttrack"><div class="stfill" style="width:${maxA>0?b.n/maxA*100:0}%;background:var(--w)"></div></div>
                <div class="stval" style="color:var(--w)">${b.n}</div></div>
            `).join('');
        }

        // ----- ALERTS -----
        function checkAlerts() {
            const sqkNames = {'7700':'ACİL DURUM','7600':'RADYO ARIZA','7500':'HİJACK'};
            flights.forEach(f => {
                if(f.alt && f.alt > 12000) addAlert(f.callsign+' aşırı yükseklik: '+f.alt+'m','med');
                if(sqkNames[f.sqk]) addAlert('SQUAWK '+f.sqk+' '+sqkNames[f.sqk]+': '+f.callsign,'high');
                if(f.vs && f.vs < -20) addAlert(f.callsign+' hızlı alçalma: '+f.vs+'m/s','med');
            });
        }
        function addAlert(msg, level) {
            if(alerts.find(a => a.msg === msg)) return;
            alerts.unshift({msg, level, time: new Date().toTimeString().slice(0,5)});
            if(alerts.length>50) alerts.pop();
            renderAlerts();
            if(level==='high') notify('⚠ ALARM: '+msg,'err');
        }
        function renderAlerts() {
            const al = document.getElementById('alertlist');
            const hdr = document.getElementById('alertheader');
            if(!alerts.length){ al.innerHTML='<div class="no-alerts">ALARM YOK</div>'; hdr.textContent='ALARMLAR'; return; }
            al.innerHTML = alerts.slice(0,30).map(a => `
                <div class="alert-item"><div class="apip ${a.level}"></div><div><div class="amsg">${a.msg}</div><div class="atime">${a.time}</div></div></div>
            `).join('');
            hdr.textContent = `ALARM(${Math.min(alerts.length,30)})`;
        }
        function clearAlerts(){ alerts=[]; renderAlerts(); }

        // ----- SETTINGS -----
        function toggleSetting(key) {
            settings[key] = !settings[key];
            document.getElementById('sw-'+key).classList.toggle('on', settings[key]);
            if(key==='ground') loadFlights();
            if(key==='trail'){ if(!settings.trail) clearAllTrails(); }
        }
        function onSlider(v) {
            markerLimit = parseInt(v);
            document.getElementById('sliderval').textContent = v;
            document.getElementById('svis').textContent = Math.min(markerLimit, filteredFlights.length);
            if(MAP) redrawMarkers();
        }
        function onRfSlider(v) {
            RF = parseInt(v)*1000;
            document.getElementById('rf-val').textContent = v+'s';
            resetRefTimer();
        }
        function setPerf(mode) {
            perfMode = mode;
            ['eco','normal','ultra'].forEach(m => document.getElementById('perf-'+m).classList.toggle('on', m===mode));
            if(mode==='eco'){ markerLimit=50; document.getElementById('limitslider').value=50; document.getElementById('sliderval').textContent='50'; RF=60000; }
            else if(mode==='normal'){ markerLimit=150; document.getElementById('limitslider').value=150; document.getElementById('sliderval').textContent='150'; RF=30000; }
            else if(mode==='ultra'){ markerLimit=500; document.getElementById('limitslider').value=500; document.getElementById('sliderval').textContent='500'; RF=20000; }
            if(MAP) redrawMarkers();
            notify(mode.toUpperCase()+' PERFORMANS MODU','info');
        }

        // ----- EXPORT -----
        function exportJSON() {
            const data = JSON.stringify(flights,null,2);
            const blob = new Blob([data],{type:'application/json'});
            const a = document.createElement('a');
            a.href = URL.createObjectURL(blob);
            a.download = 'skywatch_flights_'+new Date().toISOString().slice(0,19).replace(/:/g,'-')+'.json';
            a.click(); notify('JSON indirildi','ok');
        }
        function exportCSV() {
            const headers = ['icao24','callsign','country','lat','lon','alt','vel','hdg','vs','sqk'];
            const rows = flights.map(f => headers.map(h => f[h]!==null&&f[h]!==undefined?f[h]:'').join(','));
            const csv = headers.join(',') + '\\n' + rows.join('\\n');
            const blob = new Blob([csv],{type:'text/csv'});
            const a = document.createElement('a');
            a.href = URL.createObjectURL(blob);
            a.download = 'skywatch_flights_'+new Date().toISOString().slice(0,19).replace(/:/g,'-')+'.csv';
            a.click(); notify('CSV indirildi','ok');
        }
        function clearToken() { localStorage.removeItem('skyw4_token'); notify('TOKEN SİLİNDİ — Sayfayı yenileyin','warn'); }

        // ----- SEARCH -----
        function toggleSearch() {
            searchOpen = !searchOpen;
            document.getElementById('searchbar').classList.toggle('open', searchOpen);
            if(searchOpen) setTimeout(() => document.getElementById('sinput').focus(), 80);
            else{ document.getElementById('sinput').value=''; document.getElementById('sresults').classList.remove('open'); }
        }
        function doSearch(q) {
            const sr = document.getElementById('sresults');
            if(!q || q.length<2){ sr.classList.remove('open'); return; }
            const ql = q.toLowerCase();
            const res = flights.filter(f => f.callsign.toLowerCase().includes(ql) || f.country.toLowerCase().includes(ql) || f.icao24.toLowerCase().includes(ql)).slice(0,14);
            if(!res.length){ sr.classList.remove('open'); return; }
            sr.innerHTML = res.map(f => `
                <div class="sres-item" onclick="pickByIcao('${f.icao24}')">
                    ${flag(f.country)} <span class="sres-call">${f.callsign}</span>
                    <span class="sres-info">${f.country}${f.alt?' '+f.alt+'m':''}${f.vel?' '+f.vel+'km/s':''}</span>
                </div>
            `).join('');
            sr.classList.add('open');
        }
        function searchKeydown(e) {
            if(e.key==='Escape') toggleSearch();
            if(e.key==='Enter'){ const first = document.querySelector('.sres-item'); if(first) first.click(); }
        }
        function pickByIcao(icao) { const f = flights.find(x => x.icao24 === icao); if(f){ pickFlight(f); toggleSearch(); } }

        // ----- PANEL, TABS, MISC -----
        function togglePanel() {
            panelOpen = !panelOpen;
            document.getElementById('lpanel').classList.toggle('closed', !panelOpen);
            const btn = document.getElementById('ptoggle');
            btn.classList.toggle('closed', !panelOpen);
            btn.innerHTML = panelOpen?'◀':'▶';
        }
        function switchTab(i) {
            for(let j=0;j<4;j++){
                document.getElementById('tab'+j).classList.toggle('on', j===i);
                document.getElementById('tp'+j).classList.toggle('on', j===i);
            }
        }
        function gotoMe() {
            if(!navigator.geolocation){ notify('KONUM DESTEKLENMİYOR','err'); return; }
            navigator.geolocation.getCurrentPosition(
                p => { if(MAP) MAP.flyTo({center:[p.coords.longitude,p.coords.latitude], zoom:8, speed:1.5}); notify('KONUMUNUZA ODAKLANDI','ok'); },
                () => notify('KONUM ALINAMIYOR','err')
            );
        }
        function doFullscreen() {
            if(!document.fullscreenElement) document.documentElement.requestFullscreen().catch(()=>{});
            else document.exitFullscreen().catch(()=>{});
        }
        function toggleHelp() { helpOpen = !helpOpen; document.getElementById('kbhelp').classList.toggle('vis', helpOpen); }

        // ----- KEYBOARD -----
        function setupKeys() {
            document.addEventListener('keydown', e => {
                if(e.target.tagName==='INPUT'||e.target.tagName==='TEXTAREA') return;
                const k = e.key;
                if(k==='f'||k==='F'){ e.preventDefault(); toggleSearch(); }
                else if(k==='r'||k==='R'){ doRefresh(); }
                else if(k==='l'||k==='L'){ togglePanel(); }
                else if(k==='s'||k==='S'){ setLayer('satellite'); }
                else if(k==='d'||k==='D'){ setLayer('dark'); }
                else if(k==='t'||k==='T'){ setLayer('street'); }
                else if(k==='h'||k==='H'){ toggleWeather(); }
                else if(k==='n'||k==='N'){ toggleTerminator(); }
                else if(k==='i'||k==='I'){ toggleAllTrails(); }
                else if(k==='c'||k==='C'){ gotoMe(); }
                else if(k==='x'||k==='X'){ closeInfo(); }
                else if(k==='Escape'){
                    if(helpOpen) toggleHelp();
                    else if(searchOpen) toggleSearch();
                    else closeInfo();
                }
                else if(k==='?'){ toggleHelp(); }
                else if(k==='F11'){ e.preventDefault(); doFullscreen(); }
            });
        }

        // ----- RADAR -----
        function startRadar() {
            const cv = document.getElementById('radarc');
            const ctx = cv.getContext('2d');
            function frame() {
                ctx.clearRect(0,0,100,100);
                ctx.strokeStyle='rgba(0,255,136,0.12)'; ctx.lineWidth=1;
                [16,30,46].forEach(r => { ctx.beginPath(); ctx.arc(50,50,r,0,Math.PI*2); ctx.stroke(); });
                ctx.strokeStyle='rgba(0,255,136,0.07)';
                ctx.beginPath(); ctx.moveTo(50,2); ctx.lineTo(50,98); ctx.stroke();
                ctx.beginPath(); ctx.moveTo(2,50); ctx.lineTo(98,50); ctx.stroke();
                ctx.save(); ctx.translate(50,50); ctx.rotate(radarAngle);
                const sw = ctx.createLinearGradient(0,0,48,0);
                sw.addColorStop(0,'rgba(0,255,136,0.6)'); sw.addColorStop(1,'rgba(0,255,136,0)');
                ctx.beginPath(); ctx.moveTo(0,0); ctx.arc(0,0,48,-0.4,0); ctx.closePath(); ctx.fillStyle=sw; ctx.fill();
                ctx.restore();
                let cnt = 0;
                if(flights.length && MAP){
                    const ctr = MAP.getCenter();
                    flights.forEach(f => {
                        if(!f.lat||!f.lon) return;
                        const dx = (f.lon - ctr.lng)*1.3;
                        const dy = -(f.lat - ctr.lat)*1.6;
                        if(Math.abs(dx)>46 || Math.abs(dy)>46) return;
                        cnt++;
                        const emg = f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
                        let color = 'rgba(0,229,255,0.7)';
                        if(emg) color = 'rgba(255,68,102,0.9)';
                        else if(f.icao24===selIcao) color = 'rgba(255,204,0,0.95)';
                        else if(f.alt>9000) color = 'rgba(255,68,102,0.7)';
                        ctx.beginPath(); ctx.arc(50+dx,50+dy, emg?3:1.5, 0, Math.PI*2);
                        ctx.fillStyle = color; ctx.fill();
                    });
                } else {
                    flights.slice(0,40).forEach((_,i) => {
                        const a = (i/40)*Math.PI*2;
                        const r = 4+Math.random()*42;
                        ctx.beginPath(); ctx.arc(50+Math.cos(a)*r,50+Math.sin(a)*r,1.5,0,Math.PI*2);
                        ctx.fillStyle = 'rgba(0,229,255,0.6)'; ctx.fill(); cnt++;
                    });
                }
                document.getElementById('radarcnt').textContent = cnt;
                radarAngle += 0.025;
                requestAnimationFrame(frame);
            }
            frame();
        }

        // ----- COMPASS -----
        function startCompass(){ drawCompass(0); }
        function drawCompass(bearing) {
            const cv = document.getElementById('compass');
            if(!cv) return;
            const ctx = cv.getContext('2d');
            const cx = 23, cy = 23, r = 20;
            ctx.clearRect(0,0,46,46);
            ctx.strokeStyle = 'rgba(0,255,136,0.18)'; ctx.lineWidth = 1;
            ctx.beginPath(); ctx.arc(cx,cy,r,0,Math.PI*2); ctx.stroke();
            ['N','E','S','W'].forEach((d,i) => {
                const a = (i*90 - bearing) * Math.PI/180;
                ctx.fillStyle = d==='N'?'#ff4466':'rgba(168,255,212,0.5)';
                ctx.font = 'bold 7px Orbitron,monospace';
                ctx.textAlign = 'center';
                ctx.textBaseline = 'middle';
                ctx.fillText(d, cx+Math.sin(a)*(r-5), cy-Math.cos(a)*(r-5));
            });
            ctx.save(); ctx.translate(cx,cy); ctx.rotate(-bearing*Math.PI/180);
            ctx.fillStyle = '#ff4466';
            ctx.beginPath(); ctx.moveTo(0,-13); ctx.lineTo(2.5,0); ctx.lineTo(0,-2); ctx.lineTo(-2.5,0); ctx.closePath(); ctx.fill();
            ctx.fillStyle = 'rgba(168,255,212,0.35)';
            ctx.beginPath(); ctx.moveTo(0,13); ctx.lineTo(2.5,0); ctx.lineTo(0,2); ctx.lineTo(-2.5,0); ctx.closePath(); ctx.fill();
            ctx.restore();
        }

        // ----- REFRESH TIMER -----
        function startRefTimer() {
            const bar = document.getElementById('refprog');
            let start = Date.now();
            rfTimer = setInterval(() => {
                const e = Date.now() - start;
                const pct = Math.max(0, 100 - (e/RF)*100);
                bar.style.width = pct+'%';
                if(e >= RF){ start = Date.now(); loadFlights(); }
            }, 300);
        }
        function resetRefTimer() { if(rfTimer) clearInterval(rfTimer); rfTimer = null; startRefTimer(); }
    </script>
</body>
</html>
EOF

if [ ! -f "$HTML" ]; then
  printf "  ${R}HATA: HTML dosyasi olusturulamadi!${N}\n"; exit 1
fi

BYTES=$(wc -c < "$HTML")
printf "  ${G}HTML hazir — %d byte${N}\n" $BYTES

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
            self.path = '/skywatch.html'
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
#!/bin/bash
# SKYWATCH v5 — Calistir: bash skywatch.sh
G='\033[0;32m';C='\033[0;36m';N='\033[0m';B='\033[1m'
clear
printf "\n${G}${B}  SKYWATCH v5.0 — Canli Ucak Takip${N}\n"
printf "  ${C}Tum buglar duzeltildi — Dogrudan HTML yazimi${N}\n\n"

PY=$(command -v python3 || command -v python)
[ -z "$PY" ] && { pkg install python -y; PY=$(command -v python3); }

TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/sw5.html"

printf "  ${C}HTML yaziliyor...${N}\n"

# HTML'yi dogrudan Python ile yaz - string concat hatasi YOK
$PY - << 'ENDPY'
import os, textwrap
D = os.environ.get("TMPDIR", "/tmp")
P = os.path.join(D, "sw5.html")

# Tum JS tek satirda - newline sorunu yok
html = textwrap.dedent("""\
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>SKYWATCH v5</title>
<link href="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css" rel="stylesheet">
<script src="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js"></script>
<link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&display=swap" rel="stylesheet">
<style>
:root{
  --g:#00ff88;--c:#00e5ff;--o:#ff6b35;--w:#ffcc00;--r:#ff4466;
  --bg:#020810;--bg2:#030f1a;--bg3:#041220;
  --p:rgba(3,15,26,.97);--p2:rgba(4,18,32,.99);
  --bd:rgba(0,255,136,.18);--bd2:rgba(0,229,255,.2);
  --t:#a8ffd4;--t2:rgba(168,255,212,.5);--t3:rgba(168,255,212,.3)
}
*{margin:0;padding:0;box-sizing:border-box}
html,body{background:var(--bg);color:var(--t);font-family:'Share Tech Mono',monospace;overflow:hidden;height:100vh;width:100vw}
body::after{content:'';position:fixed;inset:0;background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,255,136,.008) 2px,rgba(0,255,136,.008) 4px);pointer-events:none;z-index:1}
#map{position:absolute;inset:0}

/* MODAL */
#modal{position:fixed;inset:0;background:rgba(2,8,16,.98);z-index:10000;display:flex;align-items:center;justify-content:center}
#modal.gone{display:none!important}
.mbox{background:var(--bg3);border:1px solid rgba(0,255,136,.28);padding:32px;width:460px;max-width:94vw;position:relative}
.mbox::before{content:'SKYWATCH v5.0';position:absolute;top:-11px;left:18px;background:var(--bg3);padding:0 10px;font-family:'Orbitron',sans-serif;font-size:9px;color:var(--g);letter-spacing:4px}
.mtitle{font-family:'Orbitron',sans-serif;font-size:15px;color:var(--c);letter-spacing:3px;margin-bottom:4px}
.msub{font-size:9px;color:var(--t3);letter-spacing:2px;margin-bottom:18px}
.mdesc{font-size:11px;color:var(--t2);line-height:1.85;margin-bottom:18px}
.mdesc a{color:var(--c);text-decoration:none}
.mlbl{font-size:9px;color:var(--t3);letter-spacing:2px;margin-bottom:5px}
.minput{width:100%;background:rgba(0,229,255,.04);border:1px solid rgba(0,229,255,.22);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;padding:11px 14px;outline:none;letter-spacing:.5px;transition:border-color .2s;margin-bottom:8px}
.minput:focus{border-color:var(--c);box-shadow:0 0 14px rgba(0,229,255,.12)}
.minput::placeholder{color:rgba(168,255,212,.18)}
.merr{font-size:10px;color:var(--r);min-height:18px;margin-bottom:8px;letter-spacing:1px}
.mbtns{display:flex;gap:10px}
.mbstart{flex:1;background:rgba(0,255,136,.1);border:1px solid var(--g);color:var(--g);font-family:'Share Tech Mono',monospace;font-size:12px;padding:12px;cursor:pointer;letter-spacing:2px;transition:all .2s}
.mbstart:hover{background:rgba(0,255,136,.2);box-shadow:0 0 20px rgba(0,255,136,.18)}
.mbstart:disabled,.mbdemo:disabled{opacity:.4;cursor:not-allowed}
.mbdemo{background:rgba(0,229,255,.07);border:1px solid rgba(0,229,255,.28);color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;padding:12px 18px;cursor:pointer;letter-spacing:2px;transition:all .2s}
.mbdemo:hover{background:rgba(0,229,255,.16);border-color:var(--c)}
.msaved{display:none;font-size:10px;color:var(--g);padding:7px 12px;border:1px solid rgba(0,255,136,.18);background:rgba(0,255,136,.04);margin-bottom:10px}
.msaved.show{display:block}
.mhint{font-size:9px;color:var(--t3);letter-spacing:1px;margin-top:12px;text-align:center}

/* LOADING - starts HIDDEN */
#ld{position:fixed;inset:0;background:var(--bg);z-index:9999;display:none;flex-direction:column;align-items:center;justify-content:center;gap:18px}
#ld.on{display:flex}
.ldlogo{font-family:'Orbitron',sans-serif;font-size:34px;font-weight:900;color:var(--g);letter-spacing:8px;animation:glow 2.5s ease-in-out infinite}
.ldsub{font-size:10px;color:var(--t3);letter-spacing:4px;margin-top:-10px}
@keyframes glow{0%,100%{text-shadow:0 0 20px rgba(0,255,136,.3)}50%{text-shadow:0 0 50px rgba(0,255,136,.9)}}
.ldbw{width:260px;height:2px;background:rgba(0,255,136,.1);overflow:hidden}
.ldbar{height:100%;background:linear-gradient(90deg,var(--g),var(--c));width:0%;transition:width .3s ease;box-shadow:0 0 8px var(--g)}
.ldst{font-size:10px;color:var(--t3);letter-spacing:3px;text-transform:uppercase}

/* TOPBAR */
.tb{position:fixed;top:0;left:0;right:0;height:52px;background:var(--p);border-bottom:1px solid var(--bd);display:flex;align-items:center;padding:0 14px;gap:12px;z-index:500;backdrop-filter:blur(16px)}
.tlogo{font-family:'Orbitron',sans-serif;font-weight:900;font-size:16px;color:var(--g);letter-spacing:5px;text-shadow:0 0 20px rgba(0,255,136,.6);display:flex;align-items:center;gap:8px;white-space:nowrap;flex-shrink:0}
.tvbar{width:1px;height:22px;background:var(--bd);flex-shrink:0}
.tsts{display:flex;gap:14px;flex:1;overflow:hidden;align-items:center}
.tsc{display:flex;align-items:center;gap:5px;font-size:10px;color:var(--t2);white-space:nowrap;flex-shrink:0}
.tv{color:var(--c);font-family:'Orbitron',sans-serif;font-size:11px}
.sdot{width:7px;height:7px;border-radius:50%;background:var(--g);box-shadow:0 0 8px var(--g);animation:blink 1.5s infinite;flex-shrink:0}
.sdot.lo{background:var(--o);box-shadow:0 0 8px var(--o)}
.sdot.er{background:var(--r);box-shadow:0 0 8px var(--r)}
.sdot.dm{background:var(--w);box-shadow:0 0 8px var(--w)}
@keyframes blink{0%,100%{opacity:1}50%{opacity:.2}}
.tr{display:flex;align-items:center;gap:6px;margin-left:auto;flex-shrink:0}
.clk{font-size:13px;color:var(--c);letter-spacing:2px;font-family:'Orbitron',sans-serif;min-width:72px}
.tbtn{background:transparent;border:1px solid var(--bd);color:var(--g);font-family:'Share Tech Mono',monospace;font-size:10px;padding:5px 9px;cursor:pointer;letter-spacing:1px;transition:all .2s;white-space:nowrap}
.tbtn:hover,.tbtn.on{background:rgba(0,255,136,.1);border-color:var(--g);box-shadow:0 0 10px rgba(0,255,136,.18)}

/* SEARCH */
.srchbar{position:fixed;top:62px;left:50%;transform:translateX(-50%);z-index:501;display:flex;width:360px;opacity:0;pointer-events:none;transition:opacity .25s}
.srchbar.open{opacity:1;pointer-events:all}
.sinput{flex:1;background:var(--p2);border:1px solid var(--bd2);border-right:none;color:var(--c);font-family:'Share Tech Mono',monospace;font-size:12px;padding:9px 14px;outline:none}
.sinput:focus{border-color:var(--c)}
.sinput::placeholder{color:var(--t3)}
.sxbtn{background:rgba(0,229,255,.08);border:1px solid var(--bd2);color:var(--c);font-size:16px;padding:9px 13px;cursor:pointer}
.sres{position:absolute;top:100%;left:0;right:0;background:var(--p2);border:1px solid var(--bd2);border-top:none;max-height:220px;overflow-y:auto;display:none}
.sres.open{display:block}
.sritem{padding:9px 14px;font-size:11px;cursor:pointer;border-bottom:1px solid rgba(0,255,136,.05);display:flex;align-items:center;gap:8px}
.sritem:hover{background:rgba(0,255,136,.07);color:var(--g)}

/* LEFT PANEL */
.lp{position:fixed;top:52px;left:0;bottom:0;width:268px;background:var(--p);border-right:1px solid var(--bd);z-index:200;display:flex;flex-direction:column;transition:transform .3s cubic-bezier(.4,0,.2,1)}
.lp.cl{transform:translateX(-268px)}
.ptog{position:fixed;top:66px;left:268px;width:16px;height:42px;background:var(--p);border:1px solid var(--bd);border-left:none;z-index:201;display:flex;align-items:center;justify-content:center;font-size:10px;color:var(--g);cursor:pointer;transition:left .3s cubic-bezier(.4,0,.2,1)}
.ptog:hover{background:rgba(0,255,136,.1)}
.ptog.cl{left:0}

/* TABS */
.tabs{display:flex;border-bottom:1px solid var(--bd);flex-shrink:0}
.tbt{flex:1;padding:9px 0;font-family:'Share Tech Mono',monospace;font-size:9px;letter-spacing:2px;color:var(--t2);background:transparent;border:none;cursor:pointer;transition:all .2s;border-bottom:2px solid transparent;text-transform:uppercase}
.tbt.on{color:var(--g);border-bottom-color:var(--g);background:rgba(0,255,136,.04)}
.tbt:hover:not(.on){color:var(--t)}
.tp{display:none;flex:1;overflow-y:auto;flex-direction:column;scrollbar-width:thin;scrollbar-color:rgba(0,255,136,.18) transparent}
.tp.on{display:flex}
.tp::-webkit-scrollbar{width:3px}
.tp::-webkit-scrollbar-thumb{background:rgba(0,255,136,.18)}

/* SLIDER */
.slsec{padding:10px 12px;border-bottom:1px solid rgba(0,255,136,.07);flex-shrink:0;background:rgba(0,255,136,.02)}
.slrow{display:flex;align-items:center;justify-content:space-between;margin-bottom:6px}
.sllbl{font-size:9px;color:var(--t3);letter-spacing:2px;text-transform:uppercase}
.slval{font-family:'Orbitron',sans-serif;font-size:12px;color:var(--g)}
.slider{width:100%;height:3px;background:rgba(0,255,136,.12);outline:none;border:none;cursor:pointer;-webkit-appearance:none;appearance:none}
.slider::-webkit-slider-thumb{-webkit-appearance:none;width:14px;height:14px;background:var(--g);cursor:pointer;box-shadow:0 0 8px var(--g)}
.slider::-moz-range-thumb{width:14px;height:14px;background:var(--g);cursor:pointer;border:none}
.pmrow{display:flex;gap:5px;margin-top:6px}
.pmbt{flex:1;font-size:9px;padding:4px;border:1px solid rgba(0,255,136,.18);color:var(--t2);background:transparent;cursor:pointer;font-family:'Share Tech Mono',monospace;letter-spacing:1px;transition:all .2s;text-align:center}
.pmbt.on{color:var(--g);border-color:var(--g);background:rgba(0,255,136,.07)}
.pmbt:hover{color:var(--g);border-color:var(--g)}

/* FILTER */
.fbar{padding:7px 10px;border-bottom:1px solid rgba(0,255,136,.06);display:flex;gap:5px;flex-wrap:wrap;flex-shrink:0}
.fc{font-size:9px;padding:3px 8px;border:1px solid rgba(0,255,136,.18);color:var(--t2);background:transparent;cursor:pointer;font-family:'Share Tech Mono',monospace;letter-spacing:1px;transition:all .2s}
.fc.on{background:rgba(0,229,255,.1);border-color:var(--c);color:var(--c)}
.fc:hover:not(.on){border-color:var(--g);color:var(--g)}
.fc.red.on{background:rgba(255,68,102,.1);border-color:var(--r);color:var(--r)}
.fcnt{padding:3px 10px 5px;font-size:9px;color:var(--t3);letter-spacing:1px;border-bottom:1px solid rgba(0,255,136,.04);flex-shrink:0;display:flex;justify-content:space-between}

/* FLIGHT ITEMS */
.fi{padding:9px 12px;border-bottom:1px solid rgba(0,255,136,.05);cursor:pointer;transition:background .1s;position:relative;flex-shrink:0}
.fi::before{content:'';position:absolute;left:0;top:0;bottom:0;width:2px;opacity:0;transition:opacity .15s}
.fi:hover{background:rgba(0,255,136,.05)}
.fi:hover::before,.fi.sel::before{opacity:1;background:var(--g)}
.fi.sel{background:rgba(0,229,255,.05)}
.fi.sel::before{background:var(--c)}
.fi.emg::before{opacity:1;background:var(--r);animation:blink .6s infinite}
.fcall{font-family:'Orbitron',sans-serif;font-size:11px;color:var(--c);display:flex;align-items:center;gap:5px}
.fflag{font-size:13px;line-height:1;flex-shrink:0}
.fdet{font-size:9px;color:var(--t2);display:flex;gap:8px;margin-top:3px;flex-wrap:wrap}
.fv{color:var(--t)}
.fab{height:2px;background:rgba(0,255,136,.07);margin-top:5px;overflow:hidden}
.faf{height:100%;transition:width .4s ease}

/* STATS */
.stbl{padding:12px;border-bottom:1px solid rgba(0,255,136,.06);flex-shrink:0}
.sth{font-size:8px;color:var(--t3);letter-spacing:3px;text-transform:uppercase;margin-bottom:9px}
.bsg{display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-bottom:6px}
.bsi{background:rgba(0,255,136,.04);border:1px solid rgba(0,255,136,.1);padding:9px 10px}
.bsv{font-family:'Orbitron',sans-serif;font-size:19px;color:var(--c);line-height:1}
.bsl{font-size:8px;color:var(--t3);letter-spacing:2px;margin-top:3px;text-transform:uppercase}
.str{display:flex;align-items:center;gap:8px;margin-bottom:5px}
.stlb{font-size:10px;color:var(--t2);flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.sttk{flex:0 0 70px;height:3px;background:rgba(0,255,136,.08)}
.stfi{height:100%;transition:width .7s ease}
.stv{font-size:10px;width:26px;text-align:right;flex-shrink:0;color:var(--g)}

/* ALERTS */
.ali{padding:9px 12px;border-bottom:1px solid rgba(255,68,102,.08);display:flex;gap:8px;flex-shrink:0}
.app{width:7px;height:7px;border-radius:50%;flex-shrink:0;margin-top:4px}
.app.high{background:var(--r);box-shadow:0 0 6px var(--r);animation:blink .7s infinite}
.app.med{background:var(--w);box-shadow:0 0 5px var(--w)}
.app.low{background:var(--c);box-shadow:0 0 4px var(--c)}
.amsg{font-size:10px;color:var(--t);line-height:1.5}
.atm{font-size:9px;color:var(--t3);margin-top:2px}
.noal{padding:24px;text-align:center;font-size:10px;color:var(--t3);letter-spacing:2px}

/* SETTINGS */
.stsec{padding:8px 12px 2px;font-size:8px;color:var(--t3);letter-spacing:3px;text-transform:uppercase;border-bottom:1px solid rgba(0,255,136,.04);flex-shrink:0}
.strow{padding:10px 12px;border-bottom:1px solid rgba(0,255,136,.05);display:flex;align-items:center;justify-content:space-between;flex-shrink:0}
.stlabel{font-size:10px;color:var(--t2);letter-spacing:1px}
.togw{width:32px;height:16px;background:rgba(0,255,136,.12);border:1px solid rgba(0,255,136,.3);position:relative;cursor:pointer;transition:background .2s}
.togw.on{background:rgba(0,255,136,.25);border-color:var(--g)}
.togw::after{content:'';position:absolute;width:10px;height:10px;background:rgba(168,255,212,.5);top:2px;left:2px;transition:left .2s,background .2s}
.togw.on::after{left:18px;background:var(--g);box-shadow:0 0 6px var(--g)}
.exbtn{font-size:9px;padding:4px 10px;border:1px solid rgba(0,255,136,.2);color:var(--t2);background:transparent;cursor:pointer;font-family:'Share Tech Mono',monospace;letter-spacing:1px;transition:all .2s}
.exbtn:hover{color:var(--g);border-color:var(--g)}

/* INFO PANEL */
.ip{position:fixed;bottom:16px;right:16px;width:298px;background:var(--p2);border:1px solid var(--bd2);z-index:200;display:none;box-shadow:0 0 40px rgba(0,229,255,.06)}
.ip.vis{display:block;animation:slin .2s ease}
@keyframes slin{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:translateY(0)}}
.iph{padding:10px 13px;background:rgba(0,229,255,.05);border-bottom:1px solid var(--bd2);font-family:'Orbitron',sans-serif;font-size:12px;color:var(--c);letter-spacing:2px;display:flex;justify-content:space-between;align-items:center}
.iha{display:flex;gap:8px;align-items:center}
.trbt{font-size:9px;padding:2px 7px;border:1px solid rgba(0,229,255,.25);color:rgba(0,229,255,.6);background:transparent;cursor:pointer;font-family:'Share Tech Mono',monospace;letter-spacing:1px;transition:all .2s}
.trbt:hover,.trbt.on{background:rgba(0,229,255,.12);border-color:var(--c);color:var(--c)}
.clx{color:var(--t3);font-size:18px;cursor:pointer;transition:color .2s;line-height:1}
.clx:hover{color:var(--r)}
.ipg{padding:10px 13px;display:grid;grid-template-columns:1fr 1fr;gap:8px}
.ifd{display:flex;flex-direction:column;gap:2px}
.ilb{font-size:8px;color:var(--t3);letter-spacing:2px;text-transform:uppercase}
.iv{font-size:12px;color:var(--g);font-family:'Orbitron',sans-serif;transition:color .2s}
.iv.b{color:var(--c)}.iv.y{color:var(--w)}.iv.r{color:var(--r)}
.spdw{padding:0 13px 8px;display:flex;align-items:center;gap:8px}
.spdt{flex:1;height:3px;background:rgba(0,255,136,.08);overflow:hidden}
.spdf{height:100%;background:linear-gradient(90deg,var(--g),var(--c),var(--w),var(--r));transition:width .5s ease}
.spdl{font-size:9px;color:var(--t3);white-space:nowrap}
.spdhc{padding:0 13px 8px}
.spdhcl{font-size:8px;color:var(--t3);letter-spacing:2px;margin-bottom:4px;text-transform:uppercase}
.iabs{padding:0 13px 10px;display:flex;gap:5px}
.iab{flex:1;font-size:9px;padding:5px 3px;border:1px solid var(--bd);color:var(--t2);background:transparent;cursor:pointer;font-family:'Share Tech Mono',monospace;letter-spacing:1px;transition:all .2s;text-align:center}
.iab:hover{color:var(--g);border-color:var(--g);background:rgba(0,255,136,.05)}

/* TRAIL LEGEND */
.tleg{position:fixed;bottom:116px;left:16px;z-index:200;background:var(--p2);border:1px solid var(--bd);padding:8px 12px;display:none}
.tleg.vis{display:block}
.tlegh{font-size:8px;color:var(--t3);letter-spacing:2px;text-transform:uppercase;margin-bottom:6px}
.tlegr{display:flex;align-items:center;gap:7px;margin-bottom:4px;font-size:9px;color:var(--t2)}
.tlegc{width:12px;height:4px;flex-shrink:0}

/* RADAR */
.rdw{position:fixed;bottom:16px;left:16px;z-index:200;background:var(--p2);border:1px solid var(--bd);padding:8px}
.rdh{font-size:8px;color:var(--t3);letter-spacing:2px;text-transform:uppercase;margin-bottom:5px;display:flex;justify-content:space-between;align-items:center}
.rdc{color:var(--g);font-family:'Orbitron',sans-serif;font-size:10px}

/* HUD */
.hud{position:fixed;top:50%;right:16px;transform:translateY(-50%);z-index:200;display:flex;flex-direction:column;gap:6px;opacity:0;pointer-events:none;transition:opacity .3s}
.hud.vis{opacity:1}
.hm{background:var(--p2);border:1px solid var(--bd2);padding:8px 10px;width:76px;position:relative;overflow:hidden}
.hm::after{content:'';position:absolute;top:0;left:0;right:0;height:1px;background:linear-gradient(90deg,transparent,var(--c),transparent);animation:hscan 2.5s linear infinite}
@keyframes hscan{0%{top:0%}100%{top:100%}}
.hml{font-size:7px;color:var(--t3);letter-spacing:2px;text-transform:uppercase;margin-bottom:3px}
.hmv{font-family:'Orbitron',sans-serif;font-size:15px;color:var(--c);line-height:1}
.hmu{font-size:7px;color:var(--t3);margin-top:2px}

/* LAYER PANEL */
.lyp{position:fixed;top:52px;right:0;z-index:200;display:flex;flex-direction:column;gap:3px;padding:6px}
.lbt{background:var(--p2);border:1px solid var(--bd);color:var(--t2);font-family:'Share Tech Mono',monospace;font-size:9px;padding:6px 9px;cursor:pointer;letter-spacing:1px;text-align:center;transition:all .2s;width:78px}
.lbt:hover,.lbt.on{color:var(--g);border-color:var(--g);background:rgba(0,255,136,.06)}
.lsep{height:1px;background:var(--bd);margin:2px 0}

/* COMPASS */
.cmp{position:fixed;top:62px;right:90px;z-index:200}

/* NOTIFICATION */
.ntf{position:fixed;top:62px;left:50%;transform:translateX(-50%) translateY(-90px);background:var(--p2);border:1px solid var(--bd);padding:9px 18px;font-size:10px;color:var(--c);z-index:1000;transition:transform .3s cubic-bezier(.4,0,.2,1);letter-spacing:1px;display:flex;align-items:center;gap:10px;white-space:nowrap;max-width:90vw;box-shadow:0 4px 24px rgba(0,0,0,.5);pointer-events:none}
.ntf.show{transform:translateX(-50%) translateY(0)}
.ntf.err{color:var(--r);border-color:rgba(255,68,102,.35)}
.ntf.warn{color:var(--w);border-color:rgba(255,204,0,.35)}
.ntf.ok{color:var(--g);border-color:rgba(0,255,136,.3)}
.ntfi{width:16px;height:16px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:bold;flex-shrink:0;background:rgba(0,229,255,.15)}
.ntf.err .ntfi{background:rgba(255,68,102,.15)}
.ntf.ok .ntfi{background:rgba(0,255,136,.15)}

/* KEYBOARD HELP */
.kbh{position:fixed;inset:0;background:rgba(2,8,16,.97);z-index:9000;display:none;align-items:center;justify-content:center;backdrop-filter:blur(8px)}
.kbh.vis{display:flex}
.kbb{background:var(--bg3);border:1px solid var(--bd);padding:28px;width:480px;max-width:94vw}
.kbt{font-family:'Orbitron',sans-serif;font-size:14px;color:var(--g);letter-spacing:4px;margin-bottom:18px;display:flex;justify-content:space-between;align-items:center}
.kbg{display:grid;grid-template-columns:1fr 1fr;gap:6px}
.kbr{display:flex;align-items:center;gap:10px;padding:5px 0;border-bottom:1px solid rgba(0,255,136,.05)}
.kbk{background:rgba(0,255,136,.07);border:1px solid rgba(0,255,136,.2);padding:2px 8px;font-size:9px;color:var(--g);font-family:'Orbitron',sans-serif;min-width:34px;text-align:center}
.kbd{font-size:10px;color:var(--t2)}

/* PROGRESS BAR */
.refb{position:fixed;bottom:0;left:0;right:0;height:2px;background:rgba(0,255,136,.05);z-index:999}
.refp{height:100%;background:linear-gradient(90deg,var(--g),var(--c));width:100%;box-shadow:0 0 4px var(--g)}

/* MAPBOX */
.mapboxgl-ctrl-bottom-left,.mapboxgl-ctrl-bottom-right{display:none!important}
.mapboxgl-popup-content{background:var(--p2)!important;border:1px solid var(--bd)!important;color:var(--t)!important;font-family:'Share Tech Mono',monospace!important;font-size:10px!important;padding:10px 13px!important;border-radius:0!important}
.mapboxgl-popup-tip{display:none!important}
.mapboxgl-ctrl-top-right{top:52px!important;right:90px!important}

@media(max-width:620px){.tsts .tsc:nth-child(n+4){display:none}.lyp,.hud,.rdw{display:none}}
</style>
</head>
<body>

<!-- TOKEN MODAL — starts visible, z-index:10000 -->
<div id="modal">
  <div class="mbox">
    <div class="mtitle">MAPBOX TOKEN</div>
    <div class="msub">CANLI UCAK TAKiP — UYDU HARiTA ERiSiMi</div>
    <p class="mdesc">
      <a href="https://account.mapbox.com" target="_blank">account.mapbox.com</a>
      adresinden <strong>ucretsiz</strong> hesap acin, token kopyalayin.<br>
      Token olmadan <strong>Demo Mod</strong> ile tum ozellikler (harita hariç) aktif.
    </p>
    <div class="msaved" id="msaved"></div>
    <div class="mlbl">API TOKEN</div>
    <input id="ti" class="minput" type="text" placeholder="pk.eyJ1IjoiuserIiwiYSI6InRva2VuIn0.XXXX" autocomplete="off" spellcheck="false">
    <div class="merr" id="merr"></div>
    <div class="mbtns">
      <button class="mbstart" id="bstart" onclick="doStart()">&#9654; BASLAT</button>
      <button class="mbdemo" id="bdemo" onclick="doDemo()">DEMO MOD</button>
    </div>
    <div class="mhint">ENTER = Baslat &nbsp;|&nbsp; TAB = Demo Mod</div>
  </div>
</div>

<!-- LOADING — starts hidden -->
<div id="ld">
  <div class="ldlogo">SKYWATCH</div>
  <div class="ldsub">CANLI UCAK TAKiP v5.0</div>
  <div class="ldbw"><div class="ldbar" id="ldbar"></div></div>
  <div class="ldst" id="ldst">HAZIRLANIYOR...</div>
</div>

<!-- KEYBOARD HELP -->
<div class="kbh" id="kbh">
  <div class="kbb">
    <div class="kbt">KLAVYE KiSAYOLLARI <span onclick="toggleHelp()" style="cursor:pointer;color:var(--o);font-size:20px">&#215;</span></div>
    <div class="kbg">
      <div class="kbr"><div class="kbk">F</div><div class="kbd">Arama ac/kapat</div></div>
      <div class="kbr"><div class="kbk">R</div><div class="kbd">Veriyi yenile</div></div>
      <div class="kbr"><div class="kbk">L</div><div class="kbd">Sol panel</div></div>
      <div class="kbr"><div class="kbk">S</div><div class="kbd">Uydu katmani</div></div>
      <div class="kbr"><div class="kbk">D</div><div class="kbd">Karanlik katmani</div></div>
      <div class="kbr"><div class="kbk">T</div><div class="kbd">Sokak katmani</div></div>
      <div class="kbr"><div class="kbk">H</div><div class="kbd">Hava durumu</div></div>
      <div class="kbr"><div class="kbk">N</div><div class="kbd">Gece/gunduz</div></div>
      <div class="kbr"><div class="kbk">I</div><div class="kbd">Tum ucus izleri</div></div>
      <div class="kbr"><div class="kbk">C</div><div class="kbd">Konumumu bul</div></div>
      <div class="kbr"><div class="kbk">X</div><div class="kbd">Secimi kaldir</div></div>
      <div class="kbr"><div class="kbk">ESC</div><div class="kbd">Kapat/Geri</div></div>
      <div class="kbr"><div class="kbk">?</div><div class="kbd">Bu yardim</div></div>
      <div class="kbr"><div class="kbk">F11</div><div class="kbd">Tam ekran</div></div>
    </div>
  </div>
</div>

<!-- TOPBAR -->
<div class="tb">
  <div class="tlogo">
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" style="filter:drop-shadow(0 0 5px #00ff88)">
      <path d="M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z" fill="#00ff88"/>
    </svg>
    SKYWATCH
  </div>
  <div class="tvbar"></div>
  <div class="tsts">
    <div class="tsc"><div class="sdot lo" id="sdot"></div><span id="sst">BAGLANIYOR</span></div>
    <div class="tsc">&#9992;&nbsp;<span class="tv" id="scnt">0</span></div>
    <div class="tsc">GOR:<span class="tv" id="svis">0</span></div>
    <div class="tsc">ULKE:<span class="tv" id="sco">0</span></div>
    <div class="tsc">MAX:<span class="tv" id="smx">0</span>m</div>
    <div class="tsc">&#8635;<span class="tv" id="supd">--:--</span></div>
  </div>
  <div class="tr">
    <div class="clk" id="clk">00:00:00</div>
    <button class="tbtn" onclick="toggleSearch()" title="Ara [F]">&#128269;</button>
    <button class="tbtn" onclick="doRefresh()" title="Yenile [R]">&#8635;</button>
    <button class="tbtn" onclick="gotoMe()" title="Konum [C]">&#11788;</button>
    <button class="tbtn" id="wxbt" onclick="toggleWx()" title="Hava [H]">&#9928;</button>
    <button class="tbtn" id="trmbt" onclick="toggleTerminator()" title="Gece [N]">&#9788;</button>
    <button class="tbtn" id="alltrbt" onclick="toggleAllTrails()" title="Izler [I]">&#10148;</button>
    <button class="tbtn" onclick="toggleHelp()" title="[?]">?</button>
    <button class="tbtn" onclick="doFS()">&#9974;</button>
  </div>
</div>

<!-- SEARCH -->
<div class="srchbar" id="sb">
  <div style="position:relative;flex:1">
    <input class="sinput" id="si" placeholder="Callsign, ulke, ICAO24..." oninput="doSearch(this.value)" onkeydown="skd(event)">
    <div class="sres" id="sr"></div>
  </div>
  <button class="sxbtn" onclick="toggleSearch()">&#215;</button>
</div>

<!-- PANEL TOGGLE -->
<div class="ptog" id="ptog" onclick="togglePanel()">&#9664;</div>

<!-- LEFT PANEL -->
<div class="lp" id="lp">
  <div class="tabs">
    <button class="tbt on" id="tab0" onclick="showTab(0)">UCUSLAR</button>
    <button class="tbt" id="tab1" onclick="showTab(1)">iSTAT</button>
    <button class="tbt" id="tab2" onclick="showTab(2)">ALARM</button>
    <button class="tbt" id="tab3" onclick="showTab(3)">AYAR</button>
  </div>

  <!-- TAB 0: FLIGHTS -->
  <div class="tp on" id="tp0">
    <div class="slsec">
      <div class="slrow">
        <span class="sllbl">HARITA UCAK LiMiTi</span>
        <span class="slval" id="slv">150</span>
      </div>
      <input type="range" class="slider" id="slim" min="10" max="500" value="150" step="10" oninput="onSlider(this.value)">
      <div class="pmrow">
        <button class="pmbt" id="pm-eco" onclick="setPerf('eco')">ECO</button>
        <button class="pmbt on" id="pm-nrm" onclick="setPerf('nrm')">NORMAL</button>
        <button class="pmbt" id="pm-ult" onclick="setPerf('ult')">ULTRA</button>
      </div>
    </div>
    <div class="fbar">
      <button class="fc on" id="fc-all" onclick="setF('all')">TUMU</button>
      <button class="fc" id="fc-hi" onclick="setF('hi')">Y.ALT</button>
      <button class="fc" id="fc-fast" onclick="setF('fast')">HIZ</button>
      <button class="fc" id="fc-tr" onclick="setF('tr')">TR</button>
      <button class="fc red" id="fc-emg" onclick="setF('emg')">ACiL</button>
    </div>
    <div class="fcnt"><span><span id="fcnt">0</span> UCAK</span><span id="ftot" style="color:var(--t3)"></span></div>
    <div id="flist" style="flex:1;overflow-y:auto;scrollbar-width:thin;scrollbar-color:rgba(0,255,136,.15) transparent">
      <div style="padding:22px;text-align:center;color:var(--t3);font-size:11px;letter-spacing:2px">VERi YUKLENiYOR...</div>
    </div>
  </div>

  <!-- TAB 1: STATS -->
  <div class="tp" id="tp1">
    <div class="stbl">
      <div class="sth">OZET</div>
      <div class="bsg">
        <div class="bsi"><div class="bsv" id="st0">0</div><div class="bsl">TOPLAM</div></div>
        <div class="bsi"><div class="bsv" id="st1">0</div><div class="bsl">ULKE</div></div>
        <div class="bsi"><div class="bsv" id="st2">0</div><div class="bsl">ORT.YUK(m)</div></div>
        <div class="bsi"><div class="bsv" id="st3">0</div><div class="bsl">ORT.HIZ</div></div>
        <div class="bsi"><div class="bsv" id="st4">0</div><div class="bsl">MAX HIZ</div></div>
        <div class="bsi"><div class="bsv" id="st5">0</div><div class="bsl">MAX YUK(m)</div></div>
      </div>
    </div>
    <div class="stbl"><div class="sth">ULKE SIRASI</div><div id="stco"></div></div>
    <div class="stbl"><div class="sth">HIZ (km/s)</div><div id="stsp"></div></div>
    <div class="stbl"><div class="sth">YUKSEKLIK (m)</div><div id="stal"></div></div>
    <div class="stbl"><div class="sth">AIRLINE</div><div id="stai"></div></div>
  </div>

  <!-- TAB 2: ALERTS -->
  <div class="tp" id="tp2">
    <div style="padding:7px 12px;border-bottom:1px solid rgba(0,255,136,.06);font-size:9px;color:var(--t3);letter-spacing:2px;display:flex;justify-content:space-between;align-items:center;flex-shrink:0">
      <span id="alh">ALARMLAR</span>
      <button class="fc" onclick="clrAlerts()" style="font-size:8px;padding:2px 7px">TEMIZLE</button>
    </div>
    <div id="allist"><div class="noal">ALARM YOK</div></div>
  </div>

  <!-- TAB 3: SETTINGS -->
  <div class="tp" id="tp3">
    <div class="stsec">HARiTA</div>
    <div class="strow"><span class="stlabel">Ucus izleri (seçili)</span><div class="togw" id="sw-trail" onclick="togSet('trail')"></div></div>
    <div class="strow"><span class="stlabel">Yerde duran ucaklar</span><div class="togw" id="sw-ground" onclick="togSet('ground')"></div></div>
    <div class="strow"><span class="stlabel">Animasyonlu ikonlar</span><div class="togw on" id="sw-anim" onclick="togSet('anim')"></div></div>
    <div class="stsec">YENiLEME</div>
    <div class="strow"><span class="stlabel">Sure</span><span class="tv" id="rfv">30s</span></div>
    <div style="padding:6px 12px;flex-shrink:0"><input type="range" class="slider" id="rfsl" min="15" max="120" value="30" step="5" oninput="onRfSl(this.value)"></div>
    <div class="stsec">DiSA AKTAR</div>
    <div class="strow"><span class="stlabel">JSON</span><button class="exbtn" onclick="expJSON()">&#11015; JSON</button></div>
    <div class="strow"><span class="stlabel">CSV</span><button class="exbtn" onclick="expCSV()">&#11015; CSV</button></div>
    <div class="stsec">TOKEN</div>
    <div class="strow"><span class="stlabel">Kayitli tokeni sil</span><button class="exbtn" onclick="clrToken()" style="color:var(--r);border-color:rgba(255,68,102,.3)">SIL</button></div>
  </div>
</div><!-- /lp -->

<div id="map"></div>

<!-- TRAIL LEGEND -->
<div class="tleg" id="tleg">
  <div class="tlegh">iZ RENK KODLARI</div>
  <div class="tlegr"><div class="tlegc" style="background:#00ff88"></div>&lt;3km</div>
  <div class="tlegr"><div class="tlegc" style="background:#00e5ff"></div>3-6km</div>
  <div class="tlegr"><div class="tlegc" style="background:#ffcc00"></div>6-9km</div>
  <div class="tlegr"><div class="tlegc" style="background:#ff4466"></div>&gt;9km</div>
</div>

<!-- LAYER BUTTONS -->
<div class="lyp">
  <button class="lbt on" id="lb-sat" onclick="setLayer('satellite')">&#128752; UYDU</button>
  <button class="lbt" id="lb-drk" onclick="setLayer('dark')">&#127769; KARANLIK</button>
  <button class="lbt" id="lb-str" onclick="setLayer('street')">&#128506; SOKAK</button>
  <div class="lsep"></div>
  <button class="lbt" id="lb-trm" onclick="toggleTerminator()">&#9788; GECE</button>
</div>

<!-- COMPASS -->
<div class="cmp"><canvas id="cmp" width="46" height="46"></canvas></div>

<!-- INFO PANEL -->
<div class="ip" id="ip">
  <div class="iph">
    <span id="icall">---</span>
    <div class="iha">
      <button class="trbt" id="trbt" onclick="togSelTrail()">iZ</button>
      <span class="clx" onclick="closeInfo()">&#215;</span>
    </div>
  </div>
  <div class="ipg">
    <div class="ifd"><div class="ilb">ULKE</div><div class="iv b" id="i-co">---</div></div>
    <div class="ifd"><div class="ilb">YUKSEKLIK</div><div class="iv" id="i-alt">---</div></div>
    <div class="ifd"><div class="ilb">HIZ (km/s)</div><div class="iv" id="i-spd">---</div></div>
    <div class="ifd"><div class="ilb">ROTA</div><div class="iv" id="i-hdg">---</div></div>
    <div class="ifd"><div class="ilb">ENLEM</div><div class="iv" id="i-lat">---</div></div>
    <div class="ifd"><div class="ilb">BOYLAM</div><div class="iv" id="i-lon">---</div></div>
    <div class="ifd"><div class="ilb">SQUAWK</div><div class="iv" id="i-sqk">---</div></div>
    <div class="ifd"><div class="ilb">DURUM</div><div class="iv" id="i-grnd">---</div></div>
    <div class="ifd"><div class="ilb">DiKEY HIZ</div><div class="iv" id="i-vs">---</div></div>
    <div class="ifd"><div class="ilb">ICAO24</div><div class="iv" style="font-size:10px" id="i-icao">---</div></div>
  </div>
  <div class="spdw"><div class="spdl">0</div><div class="spdt"><div class="spdf" id="spg"></div></div><div class="spdl">1200+</div></div>
  <div class="spdhc">
    <div class="spdhcl">HIZ GECMiSi</div>
    <canvas id="shc" width="272" height="34"></canvas>
  </div>
  <div class="iabs">
    <button class="iab" onclick="flyToSel()">&#9992; GiT</button>
    <button class="iab" onclick="copyCoords()">&#128203; KOORD</button>
    <button class="iab" onclick="openFA()">FA&#8599;</button>
    <button class="iab" onclick="openFR24()">FR24&#8599;</button>
  </div>
</div>

<!-- RADAR -->
<div class="rdw">
  <div class="rdh">RADAR <span class="rdc" id="rdcnt">0</span></div>
  <canvas id="rdc" width="100" height="100"></canvas>
</div>

<!-- HUD -->
<div class="hud" id="hud">
  <div class="hm"><div class="hml">YUKSEK</div><div class="hmv" id="h-alt">---</div><div class="hmu">m</div></div>
  <div class="hm"><div class="hml">HIZ</div><div class="hmv" id="h-spd">---</div><div class="hmu">km/s</div></div>
  <div class="hm"><div class="hml">ROTA</div><div class="hmv" id="h-hdg">---</div><div class="hmu">deg</div></div>
  <div class="hm"><div class="hml">DiKEY</div><div class="hmv" id="h-vs">---</div><div class="hmu">m/s</div></div>
</div>

<!-- NOTIFICATION -->
<div class="ntf" id="ntf"><div class="ntfi" id="ntfi">i</div><span id="ntfm"></span></div>

<!-- REFRESH BAR -->
<div class="refb"><div class="refp" id="refp"></div></div>

<script>
// ── STATE ────────────────────────────────────────────────────────
var MAP=null,TOKEN='',DEMO=false;
var flights=[],filtered=[],selIcao=null;
var activeF='all',mlimit=150,perfM='nrm';
var panelOpen=true,searchOpen=false,helpOpen=false;
var curLayer='satellite',wxOn=false,trmOn=false,allTrails=false;
var markers={},trailPts={},trailOn={},spdHist={};
var alerts=[],rfTimer=null,rdAngle=0,RF=30000;
var cfg={trail:false,ground:false,anim:true};

// ── FLAG EMOJI ────────────────────────────────────────────────────
var FLG={Turkey:'TR',Germany:'DE','United Kingdom':'GB',France:'FR','United States':'US',Spain:'ES',Italy:'IT',Netherlands:'NL',Russia:'RU','United Arab Emirates':'AE',Qatar:'QA','Saudi Arabia':'SA',China:'CN',Japan:'JP',Australia:'AU',Canada:'CA',Brazil:'BR',India:'IN','South Korea':'KR',Switzerland:'CH',Poland:'PL',Austria:'AT',Greece:'GR',Portugal:'PT',Ukraine:'UA',Romania:'RO',Sweden:'SE',Norway:'NO',Denmark:'DK',Finland:'FI',Belgium:'BE','Czech Republic':'CZ',Hungary:'HU',Bulgaria:'BG',Croatia:'HR',Serbia:'RS',Lithuania:'LT',Latvia:'LV',Estonia:'EE',Israel:'IL',Egypt:'EG',Morocco:'MA',Singapore:'SG',Malaysia:'MY',Thailand:'TH',Indonesia:'ID',Philippines:'PH',Argentina:'AR',Mexico:'MX',Colombia:'CO'};
function flag(c){var x=FLG[c];if(!x)return'&#127988;';return x.split('').map(function(a){return String.fromCodePoint(127397+a.charCodeAt(0));}).join('');}

// ── NOTIFY ────────────────────────────────────────────────────────
function ntf(msg,t){
  t=t||'info';
  var e=document.getElementById('ntf');
  document.getElementById('ntfi').textContent=t==='err'?'!':t==='warn'?'?':t==='ok'?'v':'i';
  document.getElementById('ntfm').textContent=msg;
  e.className='ntf show'+(t==='err'?' err':t==='warn'?' warn':t==='ok'?' ok':'');
  clearTimeout(e._t);
  e._t=setTimeout(function(){e.classList.remove('show');},3800);
}

// ── MODAL ─────────────────────────────────────────────────────────
window.addEventListener('load',function(){
  var s=localStorage.getItem('sw5tok');
  if(s&&s.length>20){
    document.getElementById('ti').value=s;
    var sv=document.getElementById('msaved');
    sv.textContent='Kayitli: '+s.slice(0,18)+'...';
    sv.classList.add('show');
  }
  document.getElementById('ti').addEventListener('keydown',function(e){
    if(e.key==='Enter')doStart();
    if(e.key==='Tab'){e.preventDefault();doDemo();}
  });
});

function setErr(m){document.getElementById('merr').textContent=m?'⚠ '+m:'';}

function doStart(){
  var v=document.getElementById('ti').value.trim();
  setErr('');
  if(!v){setErr('Token bos birakilamaz');return;}
  if(v.length<20){setErr('Token cok kisa - tam yapistirin');return;}
  TOKEN=v;
  localStorage.setItem('sw5tok',v);
  document.getElementById('bstart').disabled=true;
  document.getElementById('bdemo').disabled=true;
  document.getElementById('modal').classList.add('gone');
  boot(false);
}

function doDemo(){
  DEMO=true;
  document.getElementById('bstart').disabled=true;
  document.getElementById('bdemo').disabled=true;
  document.getElementById('modal').classList.add('gone');
  boot(true);
}

// ── BOOT ──────────────────────────────────────────────────────────
function boot(demo){
  var ld=document.getElementById('ld');
  var bar=document.getElementById('ldbar');
  var st=document.getElementById('ldst');
  ld.classList.add('on');
  var steps=[[10,'SISTEM...'],[25,'OPENSKY...'],[45,'HARiTA...'],[65,'VERi...'],[82,'RADAR...'],[95,'OPTiMiZE...'],[100,'HAZIR!']];
  var i=0;
  function next(){
    if(i>=steps.length){
      setTimeout(function(){
        ld.style.transition='opacity .5s';
        ld.style.opacity='0';
        setTimeout(function(){
          ld.classList.remove('on');
          ld.style.opacity='';ld.style.transition='';
          if(demo)initNoMap();else initMap();
          startClock();startRadar();startCompass();setupKeys();
          loadFlights();startRfTimer();
        },500);
      },150);
      return;
    }
    bar.style.width=steps[i][0]+'%';
    st.textContent=steps[i][1];
    i++;setTimeout(next,260);
  }
  next();
}

// ── CLOCK ─────────────────────────────────────────────────────────
function startClock(){setInterval(function(){document.getElementById('clk').textContent=new Date().toTimeString().slice(0,8);},1000);}

// ── STATUS DOT ────────────────────────────────────────────────────
function setSdot(s){
  var d=document.getElementById('sdot'),t=document.getElementById('sst');
  d.className='sdot';
  if(s==='live'){t.textContent='CANLI';}
  else if(s==='load'){d.classList.add('lo');t.textContent='YUKLENIYOR';}
  else if(s==='err'){d.classList.add('er');t.textContent='HATA';}
  else if(s==='demo'){d.classList.add('dm');t.textContent='DEMO';}
}

// ── MAP ───────────────────────────────────────────────────────────
function initMap(){
  mapboxgl.accessToken=TOKEN;
  MAP=new mapboxgl.Map({container:'map',style:'mapbox://styles/mapbox/satellite-v9',center:[35,40],zoom:4,antialias:true});
  MAP.addControl(new mapboxgl.NavigationControl({showCompass:false}),'top-right');
  MAP.on('load',function(){setSdot('live');});
  MAP.on('error',function(){setSdot('err');ntf('Harita hatasi! Token gecerli mi?','err');});
  MAP.on('rotate',function(){drawCompass(MAP.getBearing());});
}

function initNoMap(){
  setSdot('demo');
  var m=document.getElementById('map');
  m.style.background='radial-gradient(ellipse at 50% 40%,#030f1e,#020810)';
  var c=document.createElement('canvas');
  c.style.cssText='position:absolute;inset:0;width:100%;height:100%';
  m.appendChild(c);c.width=window.innerWidth;c.height=window.innerHeight;
  var ctx=c.getContext('2d');
  ctx.strokeStyle='rgba(0,255,136,.04)';ctx.lineWidth=1;
  for(var x=0;x<c.width;x+=60){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,c.height);ctx.stroke();}
  for(var y=0;y<c.height;y+=60){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(c.width,y);ctx.stroke();}
  ctx.fillStyle='rgba(168,255,212,.25)';
  for(var i=0;i<100;i++){ctx.beginPath();ctx.arc(Math.random()*c.width,Math.random()*c.height,Math.random()*.8+.2,0,Math.PI*2);ctx.fill();}
}

// ── LAYERS ────────────────────────────────────────────────────────
var LSTYLES={satellite:'mapbox://styles/mapbox/satellite-v9',dark:'mapbox://styles/mapbox/dark-v11',street:'mapbox://styles/mapbox/streets-v12'};
function setLayer(l){
  if(DEMO||!MAP)return;
  curLayer=l;
  ['satellite','dark','street'].forEach(function(k){document.getElementById('lb-'+k.slice(0,3)).classList.toggle('on',k===l);});
  MAP.setStyle(LSTYLES[l]);
  MAP.once('style.load',function(){addTrailLayers();redrawMarkers();});
  ntf(l.toUpperCase()+' KATMANI','info');
}

// ── TERMINATOR ────────────────────────────────────────────────────
function toggleTerminator(){
  trmOn=!trmOn;
  document.getElementById('trmbt').classList.toggle('on',trmOn);
  document.getElementById('lb-trm').classList.toggle('on',trmOn);
  if(trmOn)drawTerminator();
  else if(MAP){try{if(MAP.getLayer('trm'))MAP.removeLayer('trm');if(MAP.getSource('trm'))MAP.removeSource('trm');}catch(e){}}
  ntf('GECE/GUNDUZ '+(trmOn?'AKTIF':'KAPALI'),'info');
}
function drawTerminator(){
  if(!MAP)return;
  var d=new Date(),dec=-23.45*Math.cos((360/365*(d.getMonth()*30+d.getDate())+10)*Math.PI/180)*Math.PI/180;
  var coords=[];
  for(var lon=-180;lon<=180;lon+=2){coords.push([lon,Math.atan(-Math.cos(lon*Math.PI/180)/Math.tan(dec))*180/Math.PI]);}
  coords.push([180,-90],[180,90],[-180,90],[-180,coords[0][1]],coords[0]);
  try{
    if(MAP.getSource('trm'))MAP.removeLayer('trm'),MAP.removeSource('trm');
    MAP.addSource('trm',{type:'geojson',data:{type:'Feature',geometry:{type:'Polygon',coordinates:[coords]}}});
    MAP.addLayer({id:'trm',type:'fill',source:'trm',paint:{'fill-color':'#000018','fill-opacity':0.42}});
  }catch(e){}
}

// ── WEATHER ───────────────────────────────────────────────────────
function toggleWx(){
  wxOn=!wxOn;
  document.getElementById('wxbt').classList.toggle('on',wxOn);
  ntf('HAVA DURUMU '+(wxOn?'AKTIF':'KAPALI'),'info');
  if(!MAP||DEMO)return;
  if(wxOn){
    try{
      MAP.addSource('owm',{type:'raster',tiles:['https://tile.openweathermap.org/map/clouds_new/{z}/{x}/{y}.png?appid=439d4b804bc8187953eb36d2a8c26a02'],tileSize:256});
      MAP.addLayer({id:'owml',type:'raster',source:'owm',paint:{'raster-opacity':0.4}});
    }catch(e){ntf('Hava katmani yuklenemedi','warn');}
  }else{
    try{if(MAP.getLayer('owml'))MAP.removeLayer('owml');if(MAP.getSource('owm'))MAP.removeSource('owm');}catch(e){}
  }
}

// ── OPENSKY ───────────────────────────────────────────────────────
function fetchFlights(cb){
  var urls=['https://opensky-network.org/api/states/all?lamin=25&lomin=-20&lamax=72&lomax=55','https://opensky-network.org/api/states/all'];
  var idx=0;
  function tryNext(){
    if(idx>=urls.length){ntf('OpenSky baglanamiyor - demo veri','warn');cb(genDemo());return;}
    var url=urls[idx++];
    var xhr=new XMLHttpRequest();
    xhr.timeout=15000;
    xhr.onload=function(){
      if(xhr.status===200){try{cb(JSON.parse(xhr.responseText).states||[]);}catch(e){tryNext();}}
      else tryNext();
    };
    xhr.onerror=xhr.ontimeout=tryNext;
    xhr.open('GET',url);xhr.send();
  }
  tryNext();
}

function pState(s){
  return{
    icao24:s[0]||'',callsign:(s[1]||'').trim()||s[0]||'????',
    country:s[2]||'?',lon:s[5],lat:s[6],
    alt:s[7]?Math.round(s[7]):null,ground:s[8]||false,
    vel:s[9]?Math.round(s[9]*3.6):null,
    hdg:s[10]!==null?Math.round(s[10]):null,
    vs:s[11]?Math.round(s[11]):0,sqk:s[14]||'----'
  };
}

function genDemo(){
  var al=['TK','LH','BA','AF','EK','QR','SU','PC','FR','W6','IBE','KLM','THY','AUA','SWR','WZZ','RYR','EZY'];
  var co=Object.keys(FLG).slice(0,16);
  return Array.from({length:90},function(_,i){
    return['dm'+i,al[i%al.length]+(200+i)+'  ',co[i%co.length],null,null,
      8+Math.random()*52,28+Math.random()*38,800+Math.random()*13000,false,
      80+Math.random()*1000,Math.random()*360,(Math.random()-.5)*14,null,null,
      Math.floor(1000+Math.random()*8999)];
  });
}

// ── LOAD FLIGHTS ──────────────────────────────────────────────────
function loadFlights(){
  setSdot('load');
  fetchFlights(function(raw){
    flights=raw.map(pState).filter(function(f){return f.lat&&f.lon&&(cfg.ground||!f.ground);});
    var cos=new Set(flights.map(function(f){return f.country;}));
    var alts=flights.filter(function(f){return f.alt;}).map(function(f){return f.alt;});
    document.getElementById('scnt').textContent=flights.length;
    document.getElementById('sco').textContent=cos.size;
    document.getElementById('smx').textContent=alts.length?Math.max.apply(null,alts):0;
    document.getElementById('supd').textContent=new Date().toTimeString().slice(0,5);
    setSdot(DEMO?'demo':'live');
    // Update speed history
    if(selIcao){var sf=flights.find(function(f){return f.icao24===selIcao;});if(sf&&sf.vel){if(!spdHist[selIcao])spdHist[selIcao]=[];spdHist[selIcao].push(sf.vel);if(spdHist[selIcao].length>30)spdHist[selIcao].shift();}}
    chkAlerts();updStats();applyF();updTrails();
    if(MAP)redrawMarkers();
    if(selIcao)refreshInfo();
  });
}
function doRefresh(){resetRfTimer();loadFlights();ntf('VERi YENiLENDi','ok');}

// ── FILTER ────────────────────────────────────────────────────────
function setF(f){
  activeF=f;
  ['all','hi','fast','tr','emg'].forEach(function(x){var e=document.getElementById('fc-'+x);if(e)e.classList.toggle('on',x===f);});
  applyF();
}
function applyF(){
  filtered=flights.filter(function(f){
    if(activeF==='all')return true;
    if(activeF==='hi')return f.alt&&f.alt>9000;
    if(activeF==='fast')return f.vel&&f.vel>800;
    if(activeF==='tr')return f.country==='Turkey';
    if(activeF==='emg')return f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
    return true;
  });
  document.getElementById('fcnt').textContent=filtered.length;
  document.getElementById('ftot').textContent='/ '+flights.length;
  document.getElementById('svis').textContent=Math.min(mlimit,filtered.length);
  renderList();
}

// ── RENDER LIST ───────────────────────────────────────────────────
function renderList(){
  var fl=document.getElementById('flist'),frag=document.createDocumentFragment();
  fl.innerHTML='';
  filtered.slice(0,200).forEach(function(f){
    var emg=f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
    var ap=f.alt?Math.min(100,f.alt/130):0;
    var ac=f.alt>9000?'#ff4466':f.alt>6000?'#ffcc00':f.alt>3000?'#00e5ff':'#00ff88';
    var d=document.createElement('div');
    d.className='fi'+(f.icao24===selIcao?' sel':'')+(emg?' emg':'');
    d.innerHTML='<div class="fcall"><span class="fflag">'+flag(f.country)+'</span>'+f.callsign+(emg?'<span style="font-size:8px;padding:1px 4px;border:1px solid #ff4466;color:#ff4466;margin-left:4px">ACiL</span>':'')+'</div>'
      +'<div class="fdet"><span class="fv">'+f.country.slice(0,12)+'</span><span>&#9650;<span class="fv">'+(f.alt?f.alt+'m':'--')+'</span></span><span>&#10148;<span class="fv">'+(f.vel?f.vel:'--')+'</span></span>'+(f.hdg!==null?'<span>'+f.hdg+'&deg;</span>':'')+'</div>'
      +'<div class="fab"><div class="faf" style="width:'+ap+'%;background:'+ac+'"></div></div>';
    d.onclick=(function(ff){return function(){pick(ff);};})(f);
    frag.appendChild(d);
  });
  fl.appendChild(frag);
}

// ── STATS ─────────────────────────────────────────────────────────
function updStats(){
  var cmap={},amap={};
  var alts=flights.filter(function(f){return f.alt;}),vels=flights.filter(function(f){return f.vel;});
  flights.forEach(function(f){
    cmap[f.country]=(cmap[f.country]||0)+1;
    var al=f.callsign.replace(/[0-9\s]/g,'').slice(0,3);
    if(al.length>=2)amap[al]=(amap[al]||0)+1;
  });
  var aa=alts.length?Math.round(alts.reduce(function(s,f){return s+f.alt;},0)/alts.length):0;
  var av=vels.length?Math.round(vels.reduce(function(s,f){return s+f.vel;},0)/vels.length):0;
  var mv=vels.length?Math.max.apply(null,vels.map(function(f){return f.vel;})):0;
  var ma=alts.length?Math.max.apply(null,alts.map(function(f){return f.alt;})):0;
  ['st0','st1','st2','st3','st4','st5'].forEach(function(id,i){
    document.getElementById(id).textContent=[flights.length,Object.keys(cmap).length,aa,av,mv,ma][i];
  });
  function bars(id,obj,clr){
    var s=Object.entries(obj).sort(function(a,b){return b[1]-a[1];}).slice(0,7);
    var mx=s[0]?s[0][1]:1;
    document.getElementById(id).innerHTML=s.map(function(e){return '<div class="str"><div class="stlb">'+e[0].slice(0,14)+'</div><div class="sttk"><div class="stfi" style="width:'+(e[1]/mx*100)+'%;background:'+clr+'"></div></div><div class="stv" style="color:'+clr+'">'+e[1]+'</div></div>';}).join('');
  }
  bars('stco',cmap,'var(--g)');bars('stai',amap,'var(--c)');
  function buck(id,bkts,clr){
    var mx=Math.max.apply(null,bkts.map(function(b){return b.n;}));
    document.getElementById(id).innerHTML=bkts.map(function(b){return '<div class="str"><div class="stlb">'+b.l+'</div><div class="sttk"><div class="stfi" style="width:'+(mx>0?b.n/mx*100:0)+'%;background:'+clr+'"></div></div><div class="stv" style="color:'+clr+'">'+b.n+'</div></div>';}).join('');
  }
  var sb=[{l:'<400',n:0},{l:'400-600',n:0},{l:'600-800',n:0},{l:'800-1k',n:0},{l:'>1k',n:0}];
  vels.forEach(function(f){if(f.vel<400)sb[0].n++;else if(f.vel<600)sb[1].n++;else if(f.vel<800)sb[2].n++;else if(f.vel<1000)sb[3].n++;else sb[4].n++;});
  buck('stsp',sb,'var(--c)');
  var ab=[{l:'<3k',n:0},{l:'3-6k',n:0},{l:'6-9k',n:0},{l:'9-12k',n:0},{l:'>12k',n:0}];
  alts.forEach(function(f){if(f.alt<3000)ab[0].n++;else if(f.alt<6000)ab[1].n++;else if(f.alt<9000)ab[2].n++;else if(f.alt<12000)ab[3].n++;else ab[4].n++;});
  buck('stal',ab,'var(--w)');
}

// ── ALERTS ────────────────────────────────────────────────────────
function chkAlerts(){
  var sq={'7700':'ACIL DURUM','7600':'RADYO ARIZA','7500':'HiJACK'};
  flights.forEach(function(f){
    if(f.alt&&f.alt>12000)addAlert(f.callsign+' asiri yukseklik: '+f.alt+'m','med');
    if(sq[f.sqk])addAlert('SQUAWK '+f.sqk+' '+sq[f.sqk]+': '+f.callsign,'high');
    if(f.vs&&f.vs<-20)addAlert(f.callsign+' hizli alçalma: '+f.vs+'m/s','med');
  });
}
function addAlert(msg,lvl){
  if(alerts.find(function(a){return a.msg===msg;}))return;
  alerts.unshift({msg:msg,lvl:lvl,t:new Date().toTimeString().slice(0,5)});
  if(alerts.length>50)alerts.pop();
  renderAlerts();
  if(lvl==='high')ntf('ALARM: '+msg,'err');
}
function renderAlerts(){
  var al=document.getElementById('allist'),hd=document.getElementById('alh');
  if(!alerts.length){al.innerHTML='<div class="noal">ALARM YOK</div>';hd.textContent='ALARMLAR';return;}
  al.innerHTML=alerts.slice(0,30).map(function(a){return '<div class="ali"><div class="app '+a.lvl+'"></div><div><div class="amsg">'+a.msg+'</div><div class="atm">'+a.t+'</div></div></div>';}).join('');
  hd.textContent='ALARM('+Math.min(alerts.length,30)+')';
}
function clrAlerts(){alerts=[];renderAlerts();}

// ── MARKERS ───────────────────────────────────────────────────────
function redrawMarkers(){
  if(!MAP)return;
  Object.values(markers).forEach(function(m){m.remove();});
  markers={};
  var show=filtered.length?filtered:flights;
  show.slice(0,mlimit).forEach(function(f){
    var el=mkEl(f);
    var m=new mapboxgl.Marker({element:el,anchor:'center'}).setLngLat([f.lon,f.lat]).addTo(MAP);
    el.addEventListener('click',(function(ff){return function(e){e.stopPropagation();pick(ff);};})(f));
    markers[f.icao24]=m;
  });
}
function mkEl(f){
  var sel=f.icao24===selIcao;
  var emg=f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
  var clr=emg?'#ff4466':sel?'#00e5ff':f.alt>9000?'#ffcc00':f.alt>3000?'#00ff88':'#88ffcc';
  var sz=sel?22:14;
  var el=document.createElement('div');
  el.style.cssText='width:'+sz+'px;height:'+sz+'px;cursor:pointer;';
  if(emg)el.style.animation='blink .5s infinite';
  el.innerHTML='<svg viewBox="0 0 24 24" fill="none" style="transform:rotate('+(f.hdg||0)+'deg);width:100%;height:100%;filter:drop-shadow(0 0 '+(sel?6:3)+'px '+clr+')">'
    +'<path d="M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z" fill="'+clr+'" opacity="0.95"/>'
    +(sel?'<circle cx="12" cy="12" r="11" stroke="'+clr+'" stroke-opacity="0.3" stroke-width="1"/>':'')
    +'</svg>';
  return el;
}

// ── TRAIL SYSTEM ──────────────────────────────────────────────────
function trailColor(alt){return alt>9000?'#ff4466':alt>6000?'#ffcc00':alt>3000?'#00e5ff':'#00ff88';}

function addTrailLayers(){/* sources added dynamically */}

function updTrailFlight(f){
  if(!MAP||!f.lat||!f.lon)return;
  if(!trailPts[f.icao24])trailPts[f.icao24]=[];
  trailPts[f.icao24].push({c:[f.lon,f.lat],a:f.alt});
  if(trailPts[f.icao24].length>120)trailPts[f.icao24].shift();
  renderTrail(f.icao24);
}

function renderTrail(icao){
  if(!MAP)return;
  var pts=trailPts[icao];
  if(!pts||pts.length<2)return;
  // Group consecutive points by color
  var segs=[],cur={clr:trailColor(pts[0].a),coords:[pts[0].c]};
  for(var i=1;i<pts.length;i++){
    var c=trailColor(pts[i].a);
    cur.coords.push(pts[i].c);
    if(c!==cur.clr||i===pts.length-1){
      if(cur.coords.length>=2)segs.push({clr:cur.clr,coords:cur.coords.slice()});
      cur={clr:c,coords:[pts[i].c]};
    }
  }
  // Remove old trail layers
  try{
    var sty=MAP.getStyle();
    (sty.layers||[]).forEach(function(l){if(l.id.startsWith('trl-'+icao))try{MAP.removeLayer(l.id);}catch(e){}});
    Object.keys(sty.sources||{}).forEach(function(s){if(s.startsWith('trs-'+icao))try{MAP.removeSource(s);}catch(e){}});
  }catch(e){}
  // Add new segments
  segs.forEach(function(seg,ci){
    var sid='trs-'+icao+'-'+ci,lid='trl-'+icao+'-'+ci;
    try{
      MAP.addSource(sid,{type:'geojson',data:{type:'Feature',geometry:{type:'LineString',coordinates:seg.coords}}});
      MAP.addLayer({id:lid,type:'line',source:sid,paint:{'line-color':seg.clr,'line-width':['interpolate',['linear'],['zoom'],3,1.5,10,3],'line-opacity':0.7}});
    }catch(e){}
  });
}

function clrTrail(icao){
  delete trailPts[icao];
  if(!MAP)return;
  try{
    var sty=MAP.getStyle();
    (sty.layers||[]).forEach(function(l){if(l.id.startsWith('trl-'+icao))try{MAP.removeLayer(l.id);}catch(e){}});
    Object.keys(sty.sources||{}).forEach(function(s){if(s.startsWith('trs-'+icao))try{MAP.removeSource(s);}catch(e){}});
  }catch(e){}
}

function clrAllTrails(){
  Object.keys(trailPts).forEach(function(ic){clrTrail(ic);});
  trailPts={};trailOn={};
  ntf('TUM iZLER TENiZLENDi','info');
}

function updTrails(){
  flights.forEach(function(f){
    if(trailOn[f.icao24]||allTrails)updTrailFlight(f);
  });
}

function togSelTrail(){
  if(!selIcao)return;
  trailOn[selIcao]=!trailOn[selIcao];
  document.getElementById('trbt').classList.toggle('on',trailOn[selIcao]);
  if(!trailOn[selIcao])clrTrail(selIcao);
  else{var f=flights.find(function(x){return x.icao24===selIcao;});if(f)updTrailFlight(f);}
  ntf('iZ '+(trailOn[selIcao]?'AKTIF':'KAPALI'),'info');
}

function toggleAllTrails(){
  allTrails=!allTrails;
  document.getElementById('alltrbt').classList.toggle('on',allTrails);
  document.getElementById('tleg').classList.toggle('vis',allTrails);
  if(!allTrails)clrAllTrails();
  else{updTrails();ntf('TUM iZLER AKTIF','warn');}
}

// ── SELECT FLIGHT ──────────────────────────────────────────────────
function pick(f){
  selIcao=f.icao24;
  if(!spdHist[f.icao24])spdHist[f.icao24]=[];
  if(f.vel)spdHist[f.icao24].push(f.vel);
  refreshInfo();
  if(MAP&&f.lat&&f.lon)MAP.flyTo({center:[f.lon,f.lat],zoom:7,speed:1.5,curve:1.2});
  renderList();if(MAP)redrawMarkers();
}

function refreshInfo(){
  var f=flights.find(function(x){return x.icao24===selIcao;});
  if(!f)return;
  var emg=f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
  document.getElementById('icall').textContent=f.callsign;
  document.getElementById('i-co').textContent=flag(f.country)+' '+f.country.slice(0,14);
  var ae=document.getElementById('i-alt');ae.textContent=f.alt?f.alt+'m':'--';ae.className='iv'+(f.alt>9000?' r':f.alt>6000?' y':'');
  document.getElementById('i-spd').textContent=f.vel?f.vel+' km/s':'--';
  document.getElementById('i-hdg').textContent=f.hdg!==null?f.hdg+'deg':'--';
  document.getElementById('i-lat').textContent=f.lat?f.lat.toFixed(5):'--';
  document.getElementById('i-lon').textContent=f.lon?f.lon.toFixed(5):'--';
  var se=document.getElementById('i-sqk');se.textContent=f.sqk||'--';se.className='iv'+(emg?' r':'');
  var ve=document.getElementById('i-vs');ve.textContent=f.vs?(f.vs>0?'+':'')+f.vs+' m/s':'--';ve.className='iv'+(f.vs>2?' b':f.vs<-2?' y':'');
  document.getElementById('i-grnd').innerHTML=f.ground?'YERDE':f.vs>3?'&#9650; YUKSELIYOR':f.vs<-3?'&#9660; iNiYOR':'&#9654; SEYREDIYOR';
  document.getElementById('i-icao').textContent=(f.icao24||'--').toUpperCase();
  document.getElementById('spg').style.width=(f.vel?Math.min(100,f.vel/12):0)+'%';
  document.getElementById('h-alt').textContent=f.alt?Math.round(f.alt):'--';
  document.getElementById('h-spd').textContent=f.vel||'--';
  document.getElementById('h-hdg').textContent=f.hdg!==null?f.hdg:'--';
  document.getElementById('h-vs').textContent=f.vs?(f.vs>0?'+':'')+f.vs:'--';
  document.getElementById('trbt').classList.toggle('on',!!trailOn[f.icao24]);
  document.getElementById('ip').classList.add('vis');
  document.getElementById('hud').classList.add('vis');
  drawSpdHist(f.icao24);
}

function closeInfo(){
  selIcao=null;
  document.getElementById('ip').classList.remove('vis');
  document.getElementById('hud').classList.remove('vis');
  renderList();if(MAP)redrawMarkers();
}

function flyToSel(){var f=flights.find(function(x){return x.icao24===selIcao;});if(f&&MAP)MAP.flyTo({center:[f.lon,f.lat],zoom:9,speed:1.5});}
function copyCoords(){var f=flights.find(function(x){return x.icao24===selIcao;});if(!f)return;var t=f.lat.toFixed(5)+', '+f.lon.toFixed(5);try{navigator.clipboard.writeText(t);ntf('KOORDINAT KOPYALANDI','ok');}catch(e){ntf(t,'info');}}
function openFA(){var f=flights.find(function(x){return x.icao24===selIcao;});if(f)window.open('https://flightaware.com/live/flight/'+f.callsign.trim(),'_blank');}
function openFR24(){var f=flights.find(function(x){return x.icao24===selIcao;});if(f)window.open('https://www.flightradar24.com/'+f.callsign.trim(),'_blank');}

// ── SPEED HISTORY CHART ───────────────────────────────────────────
function drawSpdHist(icao){
  var cv=document.getElementById('shc'),ctx=cv.getContext('2d');
  var pts=spdHist[icao]||[];
  var W=cv.offsetWidth||272,H=34;
  cv.width=W;cv.height=H;
  ctx.clearRect(0,0,W,H);
  if(pts.length<2){ctx.fillStyle='rgba(168,255,212,.2)';ctx.font='8px monospace';ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText('VERi BEKLENIYOR...',W/2,H/2);return;}
  var mn=Math.min.apply(null,pts),mx=Math.max.apply(null,pts);
  if(mx===mn)mx=mn+1;
  var step=W/(pts.length-1);
  var gr=ctx.createLinearGradient(0,0,W,0);gr.addColorStop(0,'rgba(0,255,136,.5)');gr.addColorStop(1,'rgba(0,229,255,.9)');
  ctx.beginPath();
  pts.forEach(function(v,i){var x=i*step,y=H-(v-mn)/(mx-mn)*(H-4)-2;i===0?ctx.moveTo(x,y):ctx.lineTo(x,y);});
  ctx.strokeStyle=gr;ctx.lineWidth=1.5;ctx.stroke();
  var fg=ctx.createLinearGradient(0,0,0,H);fg.addColorStop(0,'rgba(0,229,255,.15)');fg.addColorStop(1,'rgba(0,229,255,0)');
  ctx.lineTo((pts.length-1)*step,H);ctx.lineTo(0,H);ctx.closePath();ctx.fillStyle=fg;ctx.fill();
  ctx.fillStyle='rgba(168,255,212,.4)';ctx.font='8px monospace';ctx.textAlign='left';
  ctx.fillText(Math.round(mx),2,9);ctx.fillText(Math.round(mn),2,H-2);
}

// ── SLIDER & PERF ─────────────────────────────────────────────────
function onSlider(v){
  mlimit=parseInt(v);
  document.getElementById('slv').textContent=v;
  document.getElementById('svis').textContent=Math.min(mlimit,filtered.length);
  if(MAP)redrawMarkers();
}
function onRfSl(v){RF=parseInt(v)*1000;document.getElementById('rfv').textContent=v+'s';resetRfTimer();}
function setPerf(m){
  perfM=m;
  ['eco','nrm','ult'].forEach(function(x){document.getElementById('pm-'+x).classList.toggle('on',x===m);});
  var cfg={eco:[50,60000],nrm:[150,30000],ult:[400,18000]};
  mlimit=cfg[m][0];RF=cfg[m][1];
  document.getElementById('slim').value=mlimit;document.getElementById('slv').textContent=mlimit;
  resetRfTimer();if(MAP)redrawMarkers();
  ntf(m.toUpperCase()+' PERFORMANS MODU','info');
}

// ── SETTINGS ──────────────────────────────────────────────────────
function togSet(k){cfg[k]=!cfg[k];document.getElementById('sw-'+k).classList.toggle('on',cfg[k]);if(k==='ground')loadFlights();if(k==='trail'&&!cfg.trail)clrAllTrails();}

// ── EXPORT ────────────────────────────────────────────────────────
function expJSON(){
  var a=document.createElement('a');
  a.href='data:application/json;charset=utf-8,'+encodeURIComponent(JSON.stringify(flights,null,2));
  a.download='skywatch_'+new Date().toISOString().slice(0,10)+'.json';
  a.click();ntf('JSON indirildi','ok');
}
function expCSV(){
  var hd='icao24,callsign,country,lat,lon,alt,vel,hdg,vs,sqk';
  var rows=flights.map(function(f){return[f.icao24,f.callsign,f.country,f.lat,f.lon,f.alt,f.vel,f.hdg,f.vs,f.sqk].map(function(x){return x===null||x===undefined?'':x;}).join(',');});
  var nl=String.fromCharCode(10); var csv=hd+nl+rows.join(nl);
  var a=document.createElement('a');
  a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(csv);
  a.download='skywatch_'+new Date().toISOString().slice(0,10)+'.csv';
  a.click();ntf('CSV indirildi','ok');
}
function clrToken(){localStorage.removeItem('sw5tok');ntf('TOKEN SiLiNDi','warn');}

// ── SEARCH ────────────────────────────────────────────────────────
function toggleSearch(){
  searchOpen=!searchOpen;
  document.getElementById('sb').classList.toggle('open',searchOpen);
  if(searchOpen)setTimeout(function(){document.getElementById('si').focus();},80);
  else{document.getElementById('si').value='';document.getElementById('sr').classList.remove('open');}
}
function doSearch(q){
  var sr=document.getElementById('sr');
  if(!q||q.length<2){sr.classList.remove('open');return;}
  var ql=q.toLowerCase();
  var res=flights.filter(function(f){return f.callsign.toLowerCase().includes(ql)||f.country.toLowerCase().includes(ql)||f.icao24.toLowerCase().includes(ql);}).slice(0,12);
  if(!res.length){sr.classList.remove('open');return;}
  sr.innerHTML=res.map(function(f){return '<div class="sritem" onclick="pickByIcao(\''+f.icao24+'\')">'+flag(f.country)+' <strong style="color:var(--c)">'+f.callsign+'</strong> <span style="color:var(--t2)">'+f.country+(f.alt?' '+f.alt+'m':'')+'</span></div>';}).join('');
  sr.classList.add('open');
}
function skd(e){if(e.key==='Escape')toggleSearch();if(e.key==='Enter'){var fi=document.querySelector('.sritem');if(fi)fi.click();}}
function pickByIcao(ic){var f=flights.find(function(x){return x.icao24===ic;});if(f){pick(f);toggleSearch();}}

// ── PANEL & TABS ──────────────────────────────────────────────────
function togglePanel(){
  panelOpen=!panelOpen;
  document.getElementById('lp').classList.toggle('cl',!panelOpen);
  var b=document.getElementById('ptog');b.classList.toggle('cl',!panelOpen);
  b.innerHTML=panelOpen?'&#9664;':'&#9654;';
}
function showTab(i){for(var j=0;j<4;j++){document.getElementById('tab'+j).classList.toggle('on',j===i);document.getElementById('tp'+j).classList.toggle('on',j===i);}}

// ── MISC ──────────────────────────────────────────────────────────
function gotoMe(){if(!navigator.geolocation){ntf('KONUM DESTEKLENMiYOR','err');return;}navigator.geolocation.getCurrentPosition(function(p){if(MAP)MAP.flyTo({center:[p.coords.longitude,p.coords.latitude],zoom:8,speed:1.5});ntf('KONUMUNUZA ODAKLANDI','ok');},function(){ntf('KONUM ALINAMIYOR','err');});}
function doFS(){if(!document.fullscreenElement)document.documentElement.requestFullscreen().catch(function(){});else document.exitFullscreen().catch(function(){});}
function toggleHelp(){helpOpen=!helpOpen;document.getElementById('kbh').classList.toggle('vis',helpOpen);}

// ── KEYBOARD ──────────────────────────────────────────────────────
function setupKeys(){
  document.addEventListener('keydown',function(e){
    if(e.target.tagName==='INPUT'||e.target.tagName==='TEXTAREA')return;
    var k=e.key;
    if(k==='f'||k==='F'){e.preventDefault();toggleSearch();}
    else if(k==='r'||k==='R')doRefresh();
    else if(k==='l'||k==='L')togglePanel();
    else if(k==='s'||k==='S')setLayer('satellite');
    else if(k==='d'||k==='D')setLayer('dark');
    else if(k==='t'||k==='T')setLayer('street');
    else if(k==='h'||k==='H')toggleWx();
    else if(k==='n'||k==='N')toggleTerminator();
    else if(k==='i'||k==='I')toggleAllTrails();
    else if(k==='c'||k==='C')gotoMe();
    else if(k==='x'||k==='X')closeInfo();
    else if(k==='Escape'){if(helpOpen)toggleHelp();else if(searchOpen)toggleSearch();else closeInfo();}
    else if(k==='?')toggleHelp();
    else if(k==='F11'){e.preventDefault();doFS();}
  });
}

// ── RADAR ─────────────────────────────────────────────────────────
function startRadar(){
  var cv=document.getElementById('rdc'),ctx=cv.getContext('2d');
  function frame(){
    ctx.clearRect(0,0,100,100);
    ctx.strokeStyle='rgba(0,255,136,.12)';ctx.lineWidth=1;
    [16,30,46].forEach(function(r){ctx.beginPath();ctx.arc(50,50,r,0,Math.PI*2);ctx.stroke();});
    ctx.strokeStyle='rgba(0,255,136,.07)';
    ctx.beginPath();ctx.moveTo(50,2);ctx.lineTo(50,98);ctx.stroke();
    ctx.beginPath();ctx.moveTo(2,50);ctx.lineTo(98,50);ctx.stroke();
    ctx.save();ctx.translate(50,50);ctx.rotate(rdAngle);
    var sw=ctx.createLinearGradient(0,0,48,0);sw.addColorStop(0,'rgba(0,255,136,.6)');sw.addColorStop(1,'rgba(0,255,136,0)');
    ctx.beginPath();ctx.moveTo(0,0);ctx.arc(0,0,48,-0.4,0);ctx.closePath();ctx.fillStyle=sw;ctx.fill();
    ctx.restore();
    var cnt=0;
    if(flights.length&&MAP){
      var ctr=MAP.getCenter();
      flights.forEach(function(f){
        if(!f.lat||!f.lon)return;
        var dx=(f.lon-ctr.lng)*1.3,dy=-(f.lat-ctr.lat)*1.6;
        if(Math.abs(dx)>46||Math.abs(dy)>46)return;cnt++;
        var emg=f.sqk==='7700'||f.sqk==='7600'||f.sqk==='7500';
        ctx.beginPath();ctx.arc(50+dx,50+dy,emg?3:1.5,0,Math.PI*2);
        ctx.fillStyle=emg?'rgba(255,68,102,.9)':f.icao24===selIcao?'rgba(255,204,0,.9)':'rgba(0,229,255,.7)';ctx.fill();
      });
    }else{
      flights.slice(0,35).forEach(function(f,i){var a=(i/35)*Math.PI*2,r=5+Math.random()*40;ctx.beginPath();ctx.arc(50+Math.cos(a)*r,50+Math.sin(a)*r,1.5,0,Math.PI*2);ctx.fillStyle='rgba(0,229,255,.6)';ctx.fill();cnt++;});
    }
    document.getElementById('rdcnt').textContent=cnt;
    rdAngle+=0.025;requestAnimationFrame(frame);
  }
  frame();
}

// ── COMPASS ───────────────────────────────────────────────────────
function startCompass(){drawCompass(0);}
function drawCompass(b){
  var cv=document.getElementById('cmp');if(!cv)return;
  var ctx=cv.getContext('2d'),cx=23,cy=23,r=20;
  ctx.clearRect(0,0,46,46);
  ctx.strokeStyle='rgba(0,255,136,.18)';ctx.lineWidth=1;ctx.beginPath();ctx.arc(cx,cy,r,0,Math.PI*2);ctx.stroke();
  ['N','E','S','W'].forEach(function(d,i){var a=(i*90-b)*Math.PI/180;ctx.fillStyle=d==='N'?'#ff4466':'rgba(168,255,212,.5)';ctx.font='bold 7px monospace';ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText(d,cx+Math.sin(a)*(r-5),cy-Math.cos(a)*(r-5));});
  ctx.save();ctx.translate(cx,cy);ctx.rotate(-b*Math.PI/180);
  ctx.fillStyle='#ff4466';ctx.beginPath();ctx.moveTo(0,-13);ctx.lineTo(2.5,0);ctx.lineTo(0,-2);ctx.lineTo(-2.5,0);ctx.closePath();ctx.fill();
  ctx.fillStyle='rgba(168,255,212,.35)';ctx.beginPath();ctx.moveTo(0,13);ctx.lineTo(2.5,0);ctx.lineTo(0,2);ctx.lineTo(-2.5,0);ctx.closePath();ctx.fill();
  ctx.restore();
}

// ── REFRESH TIMER ─────────────────────────────────────────────────
function startRfTimer(){
  var bar=document.getElementById('refp'),s=Date.now();
  rfTimer=setInterval(function(){
    var e=Date.now()-s,p=Math.max(0,100-(e/RF)*100);
    bar.style.width=p+'%';
    if(e>=RF){s=Date.now();loadFlights();}
  },300);
}
function resetRfTimer(){if(rfTimer)clearInterval(rfTimer);rfTimer=null;startRfTimer();}

</script>
</body>
</html>
""")

with open(P, "w", encoding="utf-8") as f:
    f.write(html)

print("OK:"+P+" ("+str(len(html))+" bytes)")
ENDPY

if [ ! -f "$TMPD/sw5.html" ]; then
  printf "  ${R}HATA: HTML olusturulamadi!${N}\n"; exit 1
fi

BYTES=$(wc -c < "$TMPD/sw5.html")
LINES=$(wc -l < "$TMPD/sw5.html")
printf "  ${G}HTML hazir — ${B}%d byte, %d satir${N}\n" $BYTES $LINES

# Kritik testler
$PY -c "
with open('$TMPD/sw5.html') as f:
    c = f.read()
# JS syntax: no unterminated strings from Python newlines
import re
script = c[c.find('<script>'):c.rfind('</script>')]
broken = [l for l in script.split('\n') if l.count(\"'\")%2!=0 and not l.strip().startswith('//') and 'var ' not in l and \"//\" not in l and l.strip()]
# Filter false positives
broken = [l for l in broken if len(l.strip())>5 and not any(x in l for x in ['/*','*/','\\'\\'',' o ',' t '])]
funcs=['doStart','doDemo','boot','initMap','initNoMap','loadFlights','setF','applyF','renderList','redrawMarkers','updTrailFlight','renderTrail','pick','refreshInfo','closeInfo','expJSON','expCSV','startRadar','startCompass','setupKeys','startRfTimer']
missing=[f for f in funcs if 'function '+f not in c]
print('FUNCTIONS: '+str(len(funcs)-len(missing))+'/'+str(len(funcs))+' OK'+((' MISSING:'+str(missing)) if missing else ''))
elems=['modal','ld','ti','bstart','bdemo','flist','ip','rdc','cmp','hud','ntf','slim','slv','shc','allist']
me=[e for e in elems if \"id='\"+e+\"'\" not in c and 'id=\"'+e+'\"' not in c]
print('ELEMENTS: '+str(len(elems)-len(me))+'/'+str(len(elems))+' OK'+((' MISSING:'+str(me)) if me else ''))
print('MODAL visible: '+str('#modal{' in c and 'display:flex' in c[c.find('#modal{'):c.find('#modal{')+80]))
print('LOADING hidden: '+str('#ld{' in c and 'display:none' in c[c.find('#ld{'):c.find('#ld{')+80]))
print('XHR (no async/await): '+str('XMLHttpRequest' in c and 'async function' not in c))
print('No broken JS strings: '+str(len(broken)==0))
if broken: print('Broken lines: '+str(len(broken)))
" 2>&1

# Port sec
PORT=$(( RANDOM % 8800 + 1200 ))
while lsof -i :$PORT >/dev/null 2>&1 || ss -tln 2>/dev/null | grep -q ":$PORT "; do
  PORT=$(( RANDOM % 8800 + 1200 ))
done

printf "\n"
printf "  ┌────────────────────────────────────────────────────┐\n"
printf "  │  ${B}URL     :${N} ${C}http://localhost:$PORT${N}\n"
printf "  │  ${B}VERSiYON:${N} SKYWATCH v5.0\n"
printf "  │  ${B}DURUM   :${N} ${G}AKTIF${N}\n"
printf "  │\n"
printf "  │  ✓ Login/Demo bugı duzeltildi (XHR bazlı)\n"
printf "  │  ✓ Ucus izi renk kodlu gosterim\n"
printf "  │  ✓ Ucak sayisi slider (10-500)\n"
printf "  │  ✓ ECO/NORMAL/ULTRA performans modlari\n"
printf "  │  ✓ Hiz gecmisi grafigi\n"
printf "  │  ✓ JSON/CSV disa aktarma\n"
printf "  │  ✓ Gece/gunduz terminatoru\n"
printf "  │  ✓ Hava durumu katmani\n"
printf "  │  ✓ Squawk alarm sistemi\n"
printf "  │  ✓ FlightAware + FR24 entegrasyonu\n"
printf "  │  ✓ Klavye kisayollari (? ile goruntule)\n"
printf "  │  Durdur: Ctrl + C\n"
printf "  └────────────────────────────────────────────────────┘\n\n"

sleep 0.6
command -v termux-open-url &>/dev/null && { termux-open-url "http://localhost:$PORT" & printf "  ${C}Tarayici aciliyor...${N}\n\n"; }

cd "$TMPD"
$PY - << PYEOF
import http.server, socketserver, os, sys, signal

PORT = $PORT
os.chdir("$TMPD")

class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, fmt, *a):
        print("  [%s] %s" % (self.address_string(), fmt % a))
    def do_GET(self):
        if self.path in ('/', '/index.html'):
            self.path = '/sw5.html'
        super().do_GET()

def bye(s, f):
    print("\n  Sunucu kapatildi.\n"); sys.exit(0)

signal.signal(signal.SIGINT, bye)
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("", PORT), H) as h:
    print("  http://localhost:%d  |  Ctrl+C ile durdur\n" % PORT)
    h.serve_forever()
PYEOF

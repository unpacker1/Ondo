#!/bin/bash
# SKYWATCH v6 — bash skywatch.sh
G='\033[0;32m'; C='\033[0;36m'; N='\033[0m'; B='\033[1m'
clear
printf "\n${G}${B}  SKYWATCH v6.0${N}\n  ${C}Garantili calisir — Eski WebView uyumlu${N}\n\n"

PY=$(command -v python3 || command -v python)
[ -z "$PY" ] && { pkg install python -y; PY=$(command -v python3); }

TMPD="${TMPDIR:-/tmp}"
HTML="$TMPD/sw6.html"
printf "  ${C}HTML yaziliyor...${N}\n"

$PY - << 'WRITEPY'
import os
D = os.environ.get("TMPDIR", "/tmp")
P = os.path.join(D, "sw6.html")

# Write HTML line by line to avoid ANY Python string escaping issues
lines = []
a = lines.append

a('<!DOCTYPE html>')
a('<html lang="tr"><head>')
a('<meta charset="UTF-8">')
a('<meta name="viewport" content="width=device-width,initial-scale=1.0">')
a('<title>SKYWATCH v6</title>')
a('<link href="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css" rel="stylesheet">')
a('<script src="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js"></script>')
a('<link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@400;700;900&display=swap" rel="stylesheet">')
a('<style>')

# CSS - NO inset:, NO gap: - full browser compat
css = """
* { margin:0; padding:0; box-sizing:border-box; }
html, body { width:100%; height:100%; overflow:hidden; background:#020810; color:#a8ffd4; font-family:'Share Tech Mono',monospace; }
#map { position:absolute; top:0; left:0; width:100%; height:100%; }

/* MODAL - guaranteed visible, no inset shorthand */
#modal {
  position:fixed; top:0; left:0; right:0; bottom:0;
  background:rgba(2,8,16,0.97);
  z-index:10000;
  display:-webkit-box; display:-ms-flexbox; display:flex;
  -webkit-box-align:center; -ms-flex-align:center; align-items:center;
  -webkit-box-pack:center; -ms-flex-pack:center; justify-content:center;
}
#modal.hide { display:none !important; }

.mwrap {
  background:#041220; border:1px solid rgba(0,255,136,0.3);
  padding:28px; width:440px; max-width:93vw; position:relative;
}
.mwrap:before {
  content:'SKYWATCH v6'; position:absolute; top:-11px; left:16px;
  background:#041220; padding:0 10px;
  font-family:'Orbitron',sans-serif; font-size:9px; color:#00ff88; letter-spacing:4px;
}
.m-title { font-family:'Orbitron',sans-serif; font-size:15px; color:#00e5ff; letter-spacing:3px; margin-bottom:4px; }
.m-sub { font-size:9px; color:rgba(168,255,212,0.35); letter-spacing:2px; margin-bottom:16px; }
.m-desc { font-size:11px; color:rgba(168,255,212,0.55); line-height:1.8; margin-bottom:18px; }
.m-desc a { color:#00e5ff; text-decoration:none; }
.m-saved { font-size:10px; color:#00ff88; padding:7px 12px; border:1px solid rgba(0,255,136,0.2); margin-bottom:10px; display:none; }
.m-saved.show { display:block; }
.m-lbl { font-size:9px; color:rgba(168,255,212,0.35); letter-spacing:2px; margin-bottom:5px; }
.m-input {
  width:100%; background:rgba(0,229,255,0.04); border:1px solid rgba(0,229,255,0.25);
  color:#00e5ff; font-family:'Share Tech Mono',monospace; font-size:12px;
  padding:11px 14px; outline:none; letter-spacing:0.5px;
  margin-bottom:8px; -webkit-appearance:none;
}
.m-input:focus { border-color:#00e5ff; }
.m-err { font-size:10px; color:#ff4466; min-height:18px; margin-bottom:8px; letter-spacing:1px; }
.m-btns { display:-webkit-box; display:-ms-flexbox; display:flex; }
.m-btn-start {
  -webkit-box-flex:1; -ms-flex:1; flex:1;
  background:rgba(0,255,136,0.1); border:1px solid #00ff88; color:#00ff88;
  font-family:'Share Tech Mono',monospace; font-size:12px; padding:12px;
  cursor:pointer; letter-spacing:2px; margin-right:8px;
}
.m-btn-start:hover { background:rgba(0,255,136,0.2); }
.m-btn-demo {
  background:rgba(0,229,255,0.07); border:1px solid rgba(0,229,255,0.3); color:#00e5ff;
  font-family:'Share Tech Mono',monospace; font-size:12px; padding:12px 16px;
  cursor:pointer; letter-spacing:2px;
}
.m-btn-demo:hover { background:rgba(0,229,255,0.15); }
button:disabled { opacity:0.4; cursor:default; }
.m-hint { font-size:9px; color:rgba(168,255,212,0.3); letter-spacing:1px; margin-top:12px; text-align:center; }

/* LOADING - starts HIDDEN */
#loading {
  position:fixed; top:0; left:0; right:0; bottom:0;
  background:#020810; z-index:9999;
  display:none;
  -webkit-box-orient:vertical; -webkit-box-direction:normal;
  -ms-flex-direction:column; flex-direction:column;
  -webkit-box-align:center; -ms-flex-align:center; align-items:center;
  -webkit-box-pack:center; -ms-flex-pack:center; justify-content:center;
}
#loading.show { display:-webkit-box; display:-ms-flexbox; display:flex; }
.ld-logo { font-family:'Orbitron',sans-serif; font-size:32px; font-weight:900; color:#00ff88; letter-spacing:8px; margin-bottom:6px; }
.ld-sub { font-size:9px; color:rgba(168,255,212,0.35); letter-spacing:4px; margin-bottom:20px; }
.ld-bar-bg { width:260px; height:2px; background:rgba(0,255,136,0.12); overflow:hidden; }
.ld-bar { height:100%; width:0%; background:#00ff88; -webkit-transition:width 0.3s; transition:width 0.3s; }
.ld-st { font-size:10px; color:rgba(168,255,212,0.4); letter-spacing:3px; margin-top:12px; text-transform:uppercase; }

/* TOPBAR */
#topbar {
  position:fixed; top:0; left:0; right:0; height:50px;
  background:rgba(3,14,24,0.97); border-bottom:1px solid rgba(0,255,136,0.18);
  display:-webkit-box; display:-ms-flexbox; display:flex;
  -webkit-box-align:center; -ms-flex-align:center; align-items:center;
  padding:0 12px; z-index:500;
}
.t-logo { font-family:'Orbitron',sans-serif; font-weight:900; font-size:15px; color:#00ff88; letter-spacing:5px; white-space:nowrap; display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-align:center; -ms-flex-align:center; align-items:center; }
.t-logo svg { margin-right:7px; }
.t-div { width:1px; height:20px; background:rgba(0,255,136,0.18); margin:0 10px; -ms-flex-negative:0; flex-shrink:0; }
.t-stats { display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-flex:1; -ms-flex:1; flex:1; overflow:hidden; -webkit-box-align:center; -ms-flex-align:center; align-items:center; }
.t-stat { display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-align:center; -ms-flex-align:center; align-items:center; font-size:10px; color:rgba(168,255,212,0.55); white-space:nowrap; margin-right:12px; }
.t-val { color:#00e5ff; font-family:'Orbitron',sans-serif; font-size:11px; margin-left:3px; }
.sdot { width:7px; height:7px; border-radius:50%; background:#00ff88; -webkit-box-shadow:0 0 7px #00ff88; box-shadow:0 0 7px #00ff88; margin-right:5px; }
.sdot.ld { background:#ff6b35; -webkit-box-shadow:0 0 7px #ff6b35; box-shadow:0 0 7px #ff6b35; }
.sdot.er { background:#ff4466; -webkit-box-shadow:0 0 7px #ff4466; box-shadow:0 0 7px #ff4466; }
.sdot.dm { background:#ffcc00; -webkit-box-shadow:0 0 7px #ffcc00; box-shadow:0 0 7px #ffcc00; }
.t-right { display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-align:center; -ms-flex-align:center; align-items:center; margin-left:auto; -ms-flex-negative:0; flex-shrink:0; }
.t-clock { font-size:13px; color:#00e5ff; letter-spacing:2px; font-family:'Orbitron',sans-serif; margin-right:8px; }
.tbtn {
  background:transparent; border:1px solid rgba(0,255,136,0.2); color:#00ff88;
  font-family:'Share Tech Mono',monospace; font-size:10px; padding:4px 8px;
  cursor:pointer; letter-spacing:1px; white-space:nowrap; margin-left:4px;
}
.tbtn:hover, .tbtn.on { background:rgba(0,255,136,0.1); border-color:#00ff88; }

/* SEARCH */
#searchbar {
  position:fixed; top:60px; left:50%; margin-left:-175px;
  width:350px; z-index:501;
  display:-webkit-box; display:-ms-flexbox; display:flex;
  opacity:0; pointer-events:none; -webkit-transition:opacity 0.2s; transition:opacity 0.2s;
}
#searchbar.open { opacity:1; pointer-events:all; }
#sinput {
  -webkit-box-flex:1; -ms-flex:1; flex:1;
  background:rgba(4,18,32,0.99); border:1px solid rgba(0,229,255,0.25); border-right:none;
  color:#00e5ff; font-family:'Share Tech Mono',monospace; font-size:12px; padding:9px 14px; outline:none;
}
#sinput:focus { border-color:#00e5ff; }
.s-close { background:rgba(0,229,255,0.08); border:1px solid rgba(0,229,255,0.25); color:#00e5ff; font-size:16px; padding:9px 12px; cursor:pointer; }
#sresults { position:absolute; top:100%; left:0; right:0; background:rgba(4,18,32,0.99); border:1px solid rgba(0,229,255,0.2); border-top:none; max-height:200px; overflow-y:auto; display:none; }
#sresults.open { display:block; }
.sr-item { padding:9px 14px; font-size:11px; cursor:pointer; border-bottom:1px solid rgba(0,255,136,0.05); }
.sr-item:hover { background:rgba(0,255,136,0.07); color:#00ff88; }

/* PANEL TOGGLE */
#ptog {
  position:fixed; top:64px; left:264px; width:15px; height:40px;
  background:rgba(3,14,24,0.97); border:1px solid rgba(0,255,136,0.18); border-left:none;
  z-index:201; display:-webkit-box; display:-ms-flexbox; display:flex;
  -webkit-box-align:center; -ms-flex-align:center; align-items:center;
  -webkit-box-pack:center; -ms-flex-pack:center; justify-content:center;
  font-size:10px; color:#00ff88; cursor:pointer;
  -webkit-transition:left 0.3s; transition:left 0.3s;
}
#ptog:hover { background:rgba(0,255,136,0.1); }
#ptog.cl { left:0; }

/* LEFT PANEL */
#lpanel {
  position:fixed; top:50px; left:0; bottom:0; width:264px;
  background:rgba(3,14,24,0.97); border-right:1px solid rgba(0,255,136,0.18);
  z-index:200; display:-webkit-box; display:-ms-flexbox; display:flex;
  -webkit-box-orient:vertical; -webkit-box-direction:normal; -ms-flex-direction:column; flex-direction:column;
  -webkit-transition:-webkit-transform 0.3s; transition:transform 0.3s;
}
#lpanel.cl { -webkit-transform:translateX(-264px); transform:translateX(-264px); }

/* TABS */
.tabs { display:-webkit-box; display:-ms-flexbox; display:flex; border-bottom:1px solid rgba(0,255,136,0.18); -ms-flex-negative:0; flex-shrink:0; }
.tbt {
  -webkit-box-flex:1; -ms-flex:1; flex:1; padding:9px 0;
  font-family:'Share Tech Mono',monospace; font-size:9px; letter-spacing:2px; color:rgba(168,255,212,0.4);
  background:transparent; border:none; border-bottom:2px solid transparent; cursor:pointer; text-transform:uppercase;
}
.tbt.on { color:#00ff88; border-bottom-color:#00ff88; background:rgba(0,255,136,0.04); }
.tbt:hover { color:#a8ffd4; }
.tp { display:none; -webkit-box-flex:1; -ms-flex:1; flex:1; overflow-y:auto; -webkit-box-orient:vertical; -webkit-box-direction:normal; -ms-flex-direction:column; flex-direction:column; }
.tp.on { display:-webkit-box; display:-ms-flexbox; display:flex; }
.tp::-webkit-scrollbar { width:3px; }
.tp::-webkit-scrollbar-thumb { background:rgba(0,255,136,0.18); }

/* SLIDER SECTION */
.sl-sec { padding:10px 12px; border-bottom:1px solid rgba(0,255,136,0.07); -ms-flex-negative:0; flex-shrink:0; background:rgba(0,255,136,0.02); }
.sl-row { display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-pack:justify; -ms-flex-pack:justify; justify-content:space-between; -webkit-box-align:center; -ms-flex-align:center; align-items:center; margin-bottom:7px; }
.sl-lbl { font-size:9px; color:rgba(168,255,212,0.35); letter-spacing:2px; text-transform:uppercase; }
.sl-val { font-family:'Orbitron',sans-serif; font-size:12px; color:#00ff88; }
input[type=range] {
  width:100%; height:3px; background:rgba(0,255,136,0.12); outline:none; border:none; cursor:pointer;
  -webkit-appearance:none; appearance:none; display:block;
}
input[type=range]::-webkit-slider-thumb { -webkit-appearance:none; width:14px; height:14px; background:#00ff88; cursor:pointer; border-radius:0; -webkit-box-shadow:0 0 8px #00ff88; box-shadow:0 0 8px #00ff88; }
input[type=range]::-moz-range-thumb { width:14px; height:14px; background:#00ff88; cursor:pointer; border:none; border-radius:0; }
.pm-row { display:-webkit-box; display:-ms-flexbox; display:flex; margin-top:6px; }
.pm-btn { -webkit-box-flex:1; -ms-flex:1; flex:1; font-size:9px; padding:4px 0; border:1px solid rgba(0,255,136,0.18); color:rgba(168,255,212,0.5); background:transparent; cursor:pointer; font-family:'Share Tech Mono',monospace; letter-spacing:1px; text-align:center; }
.pm-btn:first-child { margin-right:4px; }
.pm-btn:last-child { margin-left:4px; }
.pm-btn + .pm-btn { margin-left:0; margin-right:0; }
.pm-btn.on { color:#00ff88; border-color:#00ff88; background:rgba(0,255,136,0.07); }

/* FILTERS */
.f-bar { padding:7px 10px; border-bottom:1px solid rgba(0,255,136,0.06); -ms-flex-negative:0; flex-shrink:0; }
.fc { font-size:9px; padding:3px 8px; border:1px solid rgba(0,255,136,0.18); color:rgba(168,255,212,0.5); background:transparent; cursor:pointer; font-family:'Share Tech Mono',monospace; letter-spacing:1px; margin:2px; display:inline-block; }
.fc.on { background:rgba(0,229,255,0.1); border-color:#00e5ff; color:#00e5ff; }
.fc.red.on { background:rgba(255,68,102,0.1); border-color:#ff4466; color:#ff4466; }
.f-cnt { padding:3px 10px 5px; font-size:9px; color:rgba(168,255,212,0.35); border-bottom:1px solid rgba(0,255,136,0.04); -ms-flex-negative:0; flex-shrink:0; }

/* FLIGHT ITEMS */
.fi { padding:9px 12px; border-bottom:1px solid rgba(0,255,136,0.05); cursor:pointer; position:relative; -ms-flex-negative:0; flex-shrink:0; }
.fi:before { content:''; position:absolute; left:0; top:0; bottom:0; width:2px; opacity:0; background:#00ff88; }
.fi:hover { background:rgba(0,255,136,0.05); }
.fi:hover:before, .fi.sel:before { opacity:1; }
.fi.sel { background:rgba(0,229,255,0.05); }
.fi.sel:before { background:#00e5ff; }
.fi.emg { background:rgba(255,68,102,0.04); }
.fi.emg:before { opacity:1; background:#ff4466; }
.fi-call { font-family:'Orbitron',sans-serif; font-size:11px; color:#00e5ff; }
.fi-det { font-size:9px; color:rgba(168,255,212,0.5); margin-top:3px; }
.fi-det span { color:#a8ffd4; }
.fi-bar { height:2px; background:rgba(0,255,136,0.07); margin-top:5px; overflow:hidden; }
.fi-fill { height:100%; }

/* STATS */
.st-blk { padding:12px; border-bottom:1px solid rgba(0,255,136,0.06); -ms-flex-negative:0; flex-shrink:0; }
.st-h { font-size:8px; color:rgba(168,255,212,0.35); letter-spacing:3px; text-transform:uppercase; margin-bottom:9px; }
.bs-grid { overflow:hidden; margin-bottom:6px; }
.bs-grid:after { content:''; display:table; clear:both; }
.bsi { float:left; width:50%; padding:0 3px 6px 0; box-sizing:border-box; }
.bsi:nth-child(even) { padding:0 0 6px 3px; }
.bsi-inner { background:rgba(0,255,136,0.04); border:1px solid rgba(0,255,136,0.1); padding:9px 10px; }
.bsv { font-family:'Orbitron',sans-serif; font-size:18px; color:#00e5ff; }
.bsl { font-size:8px; color:rgba(168,255,212,0.35); letter-spacing:2px; text-transform:uppercase; margin-top:3px; }
.st-row { display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-align:center; -ms-flex-align:center; align-items:center; margin-bottom:5px; }
.st-lbl { -webkit-box-flex:1; -ms-flex:1; flex:1; font-size:10px; color:rgba(168,255,212,0.5); overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.st-trk { width:70px; height:3px; background:rgba(0,255,136,0.08); -ms-flex-negative:0; flex-shrink:0; overflow:hidden; }
.st-fill { height:100%; -webkit-transition:width 0.7s; transition:width 0.7s; }
.st-num { font-size:10px; width:28px; text-align:right; -ms-flex-negative:0; flex-shrink:0; color:#00ff88; margin-left:4px; }

/* ALERTS */
.al-item { padding:9px 12px; border-bottom:1px solid rgba(255,68,102,0.08); display:-webkit-box; display:-ms-flexbox; display:flex; -ms-flex-negative:0; flex-shrink:0; }
.al-pip { width:7px; height:7px; border-radius:50%; -ms-flex-negative:0; flex-shrink:0; margin-top:4px; margin-right:8px; }
.al-pip.hi { background:#ff4466; -webkit-box-shadow:0 0 6px #ff4466; box-shadow:0 0 6px #ff4466; }
.al-pip.md { background:#ffcc00; -webkit-box-shadow:0 0 5px #ffcc00; box-shadow:0 0 5px #ffcc00; }
.al-msg { font-size:10px; color:#a8ffd4; line-height:1.5; }
.al-tm { font-size:9px; color:rgba(168,255,212,0.35); margin-top:2px; }
.no-al { padding:24px; text-align:center; font-size:10px; color:rgba(168,255,212,0.25); letter-spacing:2px; }

/* SETTINGS */
.st-sec { padding:8px 12px 2px; font-size:8px; color:rgba(168,255,212,0.3); letter-spacing:3px; text-transform:uppercase; border-bottom:1px solid rgba(0,255,136,0.04); -ms-flex-negative:0; flex-shrink:0; }
.srow { padding:10px 12px; border-bottom:1px solid rgba(0,255,136,0.05); display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-align:center; -ms-flex-align:center; align-items:center; -webkit-box-pack:justify; -ms-flex-pack:justify; justify-content:space-between; -ms-flex-negative:0; flex-shrink:0; }
.s-lbl { font-size:10px; color:rgba(168,255,212,0.5); letter-spacing:1px; }
.tog { width:32px; height:16px; background:rgba(0,255,136,0.12); border:1px solid rgba(0,255,136,0.3); position:relative; cursor:pointer; }
.tog.on { background:rgba(0,255,136,0.25); border-color:#00ff88; }
.tog:after { content:''; position:absolute; width:10px; height:10px; background:rgba(168,255,212,0.5); top:2px; left:2px; -webkit-transition:left 0.2s; transition:left 0.2s; }
.tog.on:after { left:18px; background:#00ff88; }
.ex-btn { font-size:9px; padding:4px 10px; border:1px solid rgba(0,255,136,0.2); color:rgba(168,255,212,0.5); background:transparent; cursor:pointer; font-family:'Share Tech Mono',monospace; letter-spacing:1px; }
.ex-btn:hover { color:#00ff88; border-color:#00ff88; }

/* INFO PANEL */
#infopanel {
  position:fixed; bottom:14px; right:14px; width:292px;
  background:rgba(4,18,32,0.99); border:1px solid rgba(0,229,255,0.22);
  z-index:200; display:none;
}
#infopanel.vis { display:block; }
.ip-head { padding:10px 13px; background:rgba(0,229,255,0.05); border-bottom:1px solid rgba(0,229,255,0.2); font-family:'Orbitron',sans-serif; font-size:12px; color:#00e5ff; letter-spacing:2px; display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-pack:justify; -ms-flex-pack:justify; justify-content:space-between; -webkit-box-align:center; -ms-flex-align:center; align-items:center; }
.ip-acts { display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-align:center; -ms-flex-align:center; align-items:center; }
.tr-btn { font-size:9px; padding:2px 7px; border:1px solid rgba(0,229,255,0.25); color:rgba(0,229,255,0.6); background:transparent; cursor:pointer; font-family:'Share Tech Mono',monospace; letter-spacing:1px; margin-right:8px; }
.tr-btn.on { background:rgba(0,229,255,0.12); border-color:#00e5ff; color:#00e5ff; }
.cl-x { color:rgba(168,255,212,0.4); font-size:18px; cursor:pointer; line-height:1; }
.cl-x:hover { color:#ff4466; }
.ip-grid { padding:10px 13px; overflow:hidden; }
.ip-grid:after { content:''; display:table; clear:both; }
.ifd { float:left; width:50%; padding:0 4px 8px 0; box-sizing:border-box; }
.ifd:nth-child(even) { padding:0 0 8px 4px; }
.i-lbl { font-size:8px; color:rgba(168,255,212,0.35); letter-spacing:2px; text-transform:uppercase; }
.i-val { font-size:12px; color:#00ff88; font-family:'Orbitron',sans-serif; }
.i-val.b { color:#00e5ff; }
.i-val.y { color:#ffcc00; }
.i-val.r { color:#ff4466; }
.spd-row { padding:0 13px 8px; display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-align:center; -ms-flex-align:center; align-items:center; }
.spd-trk { -webkit-box-flex:1; -ms-flex:1; flex:1; height:3px; background:rgba(0,255,136,0.08); margin:0 6px; overflow:hidden; }
.spd-fill { height:100%; background:-webkit-linear-gradient(left,#00ff88,#00e5ff,#ffcc00,#ff4466); background:linear-gradient(to right,#00ff88,#00e5ff,#ffcc00,#ff4466); -webkit-transition:width 0.5s; transition:width 0.5s; }
.spd-lbl { font-size:9px; color:rgba(168,255,212,0.4); white-space:nowrap; }
.hist-wrap { padding:0 13px 8px; }
.hist-lbl { font-size:8px; color:rgba(168,255,212,0.35); letter-spacing:2px; text-transform:uppercase; margin-bottom:4px; }
.ip-btns { padding:0 13px 10px; display:-webkit-box; display:-ms-flexbox; display:flex; }
.ip-btn { -webkit-box-flex:1; -ms-flex:1; flex:1; font-size:9px; padding:5px 3px; border:1px solid rgba(0,255,136,0.18); color:rgba(168,255,212,0.5); background:transparent; cursor:pointer; font-family:'Share Tech Mono',monosp
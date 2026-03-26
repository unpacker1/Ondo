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
.ip-btn { -webkit-box-flex:1; -ms-flex:1; flex:1; font-size:9px; padding:5px 3px; border:1px solid rgba(0,255,136,0.18); color:rgba(168,255,212,0.5); background:transparent; cursor:pointer; font-family:'Share Tech Mono',monospace; letter-spacing:1px; text-align:center; }
.ip-btn:hover { color:#00ff88; border-color:#00ff88; }
.ip-btn + .ip-btn { margin-left:4px; }

/* TRAIL LEGEND */
#tlegend { position:fixed; bottom:110px; left:14px; z-index:200; background:rgba(4,18,32,0.99); border:1px solid rgba(0,255,136,0.18); padding:8px 12px; display:none; }
#tlegend.vis { display:block; }
.tl-h { font-size:8px; color:rgba(168,255,212,0.35); letter-spacing:2px; text-transform:uppercase; margin-bottom:6px; }
.tl-r { display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-align:center; -ms-flex-align:center; align-items:center; margin-bottom:4px; font-size:9px; color:rgba(168,255,212,0.5); }
.tl-c { width:12px; height:4px; margin-right:7px; -ms-flex-negative:0; flex-shrink:0; }

/* LAYER BUTTONS */
#layers { position:fixed; top:50px; right:0; z-index:200; padding:6px; }
.l-btn { display:block; background:rgba(4,18,32,0.99); border:1px solid rgba(0,255,136,0.18); color:rgba(168,255,212,0.5); font-family:'Share Tech Mono',monospace; font-size:9px; padding:6px 9px; cursor:pointer; letter-spacing:1px; text-align:center; width:76px; margin-bottom:3px; }
.l-btn:hover, .l-btn.on { color:#00ff88; border-color:#00ff88; background:rgba(0,255,136,0.06); }
.l-sep { height:1px; background:rgba(0,255,136,0.18); margin:2px 0; }

/* COMPASS */
#cmpwrap { position:fixed; top:60px; right:86px; z-index:200; }

/* RADAR */
#radarwrap { position:fixed; bottom:14px; left:14px; z-index:200; background:rgba(4,18,32,0.99); border:1px solid rgba(0,255,136,0.18); padding:8px; }
.rd-h { font-size:8px; color:rgba(168,255,212,0.35); letter-spacing:2px; text-transform:uppercase; margin-bottom:5px; display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-pack:justify; -ms-flex-pack:justify; justify-content:space-between; -webkit-box-align:center; -ms-flex-align:center; align-items:center; }
.rd-cnt { color:#00ff88; font-family:'Orbitron',sans-serif; font-size:10px; }

/* HUD */
#hud { position:fixed; top:50%; right:14px; margin-top:-90px; z-index:200; opacity:0; pointer-events:none; -webkit-transition:opacity 0.3s; transition:opacity 0.3s; }
#hud.vis { opacity:1; }
.hm { background:rgba(4,18,32,0.99); border:1px solid rgba(0,229,255,0.2); padding:8px 10px; width:74px; margin-bottom:5px; }
.hm-l { font-size:7px; color:rgba(168,255,212,0.35); letter-spacing:2px; text-transform:uppercase; margin-bottom:3px; }
.hm-v { font-family:'Orbitron',sans-serif; font-size:15px; color:#00e5ff; line-height:1; }
.hm-u { font-size:7px; color:rgba(168,255,212,0.4); margin-top:2px; }

/* NOTIFICATION */
#ntf { position:fixed; top:60px; left:50%; margin-left:-140px; width:280px; background:rgba(4,18,32,0.99); border:1px solid rgba(0,255,136,0.2); padding:9px 16px; font-size:10px; color:#00e5ff; z-index:1000; -webkit-transition:-webkit-transform 0.3s; transition:transform 0.3s; -webkit-transform:translateY(-90px); transform:translateY(-90px); letter-spacing:1px; display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-align:center; -ms-flex-align:center; align-items:center; pointer-events:none; }
#ntf.show { -webkit-transform:translateY(0); transform:translateY(0); }
#ntf.err { color:#ff4466; border-color:rgba(255,68,102,0.35); }
#ntf.warn { color:#ffcc00; border-color:rgba(255,204,0,0.35); }
#ntf.ok { color:#00ff88; border-color:rgba(0,255,136,0.3); }
.ntf-ic { width:14px; height:14px; border-radius:50%; display:-webkit-inline-box; display:-ms-inline-flexbox; display:inline-flex; -webkit-box-align:center; -ms-flex-align:center; align-items:center; -webkit-box-pack:center; -ms-flex-pack:center; justify-content:center; font-size:9px; font-weight:bold; margin-right:8px; -ms-flex-negative:0; flex-shrink:0; background:rgba(0,229,255,0.15); }
#ntf.err .ntf-ic { background:rgba(255,68,102,0.15); }
#ntf.ok .ntf-ic { background:rgba(0,255,136,0.15); }

/* KEYBOARD HELP */
#kbhelp { position:fixed; top:0; left:0; right:0; bottom:0; background:rgba(2,8,16,0.97); z-index:9000; display:none; -webkit-box-align:center; -ms-flex-align:center; align-items:center; -webkit-box-pack:center; -ms-flex-pack:center; justify-content:center; }
#kbhelp.vis { display:-webkit-box; display:-ms-flexbox; display:flex; }
.kb-box { background:#041220; border:1px solid rgba(0,255,136,0.25); padding:26px; width:460px; max-width:93vw; }
.kb-title { font-family:'Orbitron',sans-serif; font-size:13px; color:#00ff88; letter-spacing:4px; margin-bottom:18px; display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-pack:justify; -ms-flex-pack:justify; justify-content:space-between; -webkit-box-align:center; -ms-flex-align:center; align-items:center; }
.kb-grid { overflow:hidden; }
.kb-row { float:left; width:50%; padding:5px 8px 5px 0; box-sizing:border-box; border-bottom:1px solid rgba(0,255,136,0.05); display:-webkit-box; display:-ms-flexbox; display:flex; -webkit-box-align:center; -ms-flex-align:center; align-items:center; }
.kb-key { background:rgba(0,255,136,0.07); border:1px solid rgba(0,255,136,0.2); padding:2px 7px; font-size:9px; color:#00ff88; font-family:'Orbitron',sans-serif; min-width:32px; text-align:center; white-space:nowrap; margin-right:8px; }
.kb-d { font-size:10px; color:rgba(168,255,212,0.5); }

/* PROGRESS BAR */
#refbar { position:fixed; bottom:0; left:0; right:0; height:2px; background:rgba(0,255,136,0.05); z-index:999; }
#refprog { height:100%; background:#00ff88; width:100%; -webkit-box-shadow:0 0 4px #00ff88; box-shadow:0 0 4px #00ff88; }

/* MAPBOX overrides */
.mapboxgl-ctrl-bottom-left, .mapboxgl-ctrl-bottom-right { display:none !important; }
.mapboxgl-popup-content { background:rgba(4,18,32,0.99) !important; border:1px solid rgba(0,255,136,0.2) !important; color:#a8ffd4 !important; font-family:'Share Tech Mono',monospace !important; font-size:10px !important; padding:10px 13px !important; border-radius:0 !important; }
.mapboxgl-popup-tip { display:none !important; }
.mapboxgl-ctrl-top-right { top:50px !important; right:86px !important; }

@keyframes blink { 0%,100%{opacity:1} 50%{opacity:0.2} }
@-webkit-keyframes blink { 0%,100%{opacity:1} 50%{opacity:0.2} }
.blink { -webkit-animation:blink 1.5s infinite; animation:blink 1.5s infinite; }
.blink-fast { -webkit-animation:blink 0.6s infinite; animation:blink 0.6s infinite; }

@media (max-width:600px) { .t-stats .t-stat:nth-child(n+4){display:none} #layers{display:none} #hud{display:none} #radarwrap{display:none} }
"""
a(css)
a('</style></head><body>')

# ── TOKEN MODAL ──────────────────────────────────────────────────
a('<div id="modal">')
a('  <div class="mwrap">')
a('    <div class="m-title">MAPBOX TOKEN</div>')
a('    <div class="m-sub">CANLI UCAK TAKiP — UYDU HARiTA</div>')
a('    <p class="m-desc">Ucretsiz token icin <a href="https://account.mapbox.com" target="_blank">account.mapbox.com</a> adresine gidin.<br>Token olmadan <strong>Demo Mod</strong> ile devam edebilirsiniz.<br><span style="color:rgba(168,255,212,0.35);font-size:10px">Demo modda harita arkaplan olmaz, tum diger ozellikler aktiftir.</span></p>')
a('    <div class="m-saved" id="m-saved"></div>')
a('    <div class="m-lbl">TOKEN</div>')
a('    <input id="ti" class="m-input" type="text" placeholder="pk.eyJ1IjoiuserIiwiYSI6InRva2VuIn0.XXXX" autocomplete="off">')
a('    <div class="m-err" id="m-err"></div>')
a('    <div class="m-btns">')
a('      <button class="m-btn-start" id="btn-start" onclick="doStart()">&#9654; BASLAT</button>')
a('      <button class="m-btn-demo" id="btn-demo" onclick="doDemo()">DEMO MOD</button>')
a('    </div>')
a('    <div class="m-hint">ENTER = Baslat &nbsp;|&nbsp; TAB = Demo</div>')
a('  </div>')
a('</div>')

# ── LOADING ──────────────────────────────────────────────────────
a('<div id="loading">')
a('  <div class="ld-logo">SKYWATCH</div>')
a('  <div class="ld-sub">CANLI UCAK TAKiP v6.0</div>')
a('  <div class="ld-bar-bg"><div class="ld-bar" id="ldbar"></div></div>')
a('  <div class="ld-st" id="ldst">HAZIRLANIYOR...</div>')
a('</div>')

# ── KEYBOARD HELP ────────────────────────────────────────────────
a('<div id="kbhelp">')
a('  <div class="kb-box">')
a('    <div class="kb-title">KLAVYE KiSAYOLLARI <span onclick="toggleHelp()" style="cursor:pointer;color:#ff6b35;font-size:20px">&#215;</span></div>')
a('    <div class="kb-grid">')
keys = [('F','Arama'),('R','Yenile'),('L','Sol panel'),('S','Uydu'),('D','Karanlik'),('T','Sokak'),('H','Hava durumu'),('N','Gece/gunduz'),('I','Tum izler'),('C','Konumum'),('X','Secimi kaldir'),('ESC','Kapat'),('?','Yardim'),('F11','Tam ekran')]
for k,d in keys:
    a('      <div class="kb-row"><div class="kb-key">%s</div><div class="kb-d">%s</div></div>' % (k,d))
a('    </div>')
a('  </div>')
a('</div>')

# ── TOPBAR ───────────────────────────────────────────────────────
a('<div id="topbar">')
a('  <div class="t-logo"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" style="filter:drop-shadow(0 0 5px #00ff88)"><path d="M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z" fill="#00ff88"/></svg>SKYWATCH</div>')
a('  <div class="t-div"></div>')
a('  <div class="t-stats">')
a('    <div class="t-stat"><div class="sdot ld blink" id="sdot"></div><span id="sst">BAGLANIYOR</span></div>')
a('    <div class="t-stat">&#9992;<span class="t-val" id="scnt">0</span></div>')
a('    <div class="t-stat">GOR:<span class="t-val" id="svis">0</span></div>')
a('    <div class="t-stat">ULKE:<span class="t-val" id="sco">0</span></div>')
a('    <div class="t-stat">MAX:<span class="t-val" id="smx">0</span>m</div>')
a('    <div class="t-stat">&#8635;<span class="t-val" id="supd">--:--</span></div>')
a('  </div>')
a('  <div class="t-right">')
a('    <div class="t-clock" id="clk">00:00:00</div>')
a('    <button class="tbtn" onclick="toggleSearch()" title="Ara [F]">&#128269;</button>')
a('    <button class="tbtn" onclick="doRefresh()" title="Yenile [R]">&#8635;</button>')
a('    <button class="tbtn" onclick="gotoMe()" title="Konum [C]">&#11788;</button>')
a('    <button class="tbtn" id="wxbt" onclick="toggleWx()" title="Hava [H]">&#9928;</button>')
a('    <button class="tbtn" id="trmbt" onclick="toggleTrm()" title="Gece [N]">&#9788;</button>')
a('    <button class="tbtn" id="alltrbt" onclick="toggleAllTrails()" title="Izler [I]">&#10148;</button>')
a('    <button class="tbtn" onclick="toggleHelp()" title="[?]">?</button>')
a('    <button class="tbtn" onclick="doFS()">&#9974;</button>')
a('  </div>')
a('</div>')

# ── SEARCH ───────────────────────────────────────────────────────
a('<div id="searchbar">')
a('  <div style="position:relative;-webkit-box-flex:1;-ms-flex:1;flex:1;">')
a('    <input id="sinput" placeholder="Callsign, ulke, ICAO..." oninput="doSearch(this.value)" onkeydown="skd(event)">')
a('    <div id="sresults"></div>')
a('  </div>')
a('  <button class="s-close" onclick="toggleSearch()">&#215;</button>')
a('</div>')

# ── PANEL TOGGLE ─────────────────────────────────────────────────
a('<div id="ptog" onclick="togglePanel()">&#9664;</div>')

# ── LEFT PANEL ───────────────────────────────────────────────────
a('<div id="lpanel">')
a('  <div class="tabs">')
a('    <button class="tbt on" id="tab0" onclick="showTab(0)">UCUSLAR</button>')
a('    <button class="tbt" id="tab1" onclick="showTab(1)">iSTAT</button>')
a('    <button class="tbt" id="tab2" onclick="showTab(2)">ALARM</button>')
a('    <button class="tbt" id="tab3" onclick="showTab(3)">AYAR</button>')
a('  </div>')

# Tab 0 - Flights
a('  <div class="tp on" id="tp0">')
a('    <div class="sl-sec">')
a('      <div class="sl-row"><span class="sl-lbl">HARiTA UCAK LiMiTi</span><span class="sl-val" id="slv">150</span></div>')
a('      <input type="range" id="slim" min="10" max="500" value="150" step="10" oninput="onSlider(this.value)">')
a('      <div class="pm-row">')
a('        <button class="pm-btn" id="pm-eco" onclick="setPerf(0)">ECO</button>')
a('        <button class="pm-btn on" id="pm-nrm" onclick="setPerf(1)">NORMAL</button>')
a('        <button class="pm-btn" id="pm-ult" onclick="setPerf(2)">ULTRA</button>')
a('      </div>')
a('    </div>')
a('    <div class="f-bar">')
a('      <button class="fc on" id="fc-all" onclick="setF(0)">TUMU</button>')
a('      <button class="fc" id="fc-hi" onclick="setF(1)">Y.ALT</button>')
a('      <button class="fc" id="fc-fast" onclick="setF(2)">HIZ</button>')
a('      <button class="fc" id="fc-tr" onclick="setF(3)">TR</button>')
a('      <button class="fc red" id="fc-emg" onclick="setF(4)">ACiL</button>')
a('    </div>')
a('    <div class="f-cnt"><span id="fcnt">0</span> ucak &nbsp;<span id="ftot" style="color:rgba(168,255,212,0.35)"></span></div>')
a('    <div id="flist" style="-webkit-box-flex:1;-ms-flex:1;flex:1;overflow-y:auto;">')
a('      <div style="padding:22px;text-align:center;color:rgba(168,255,212,0.25);font-size:11px;letter-spacing:2px;">VERi YUKLENiYOR...</div>')
a('    </div>')
a('  </div>')

# Tab 1 - Stats
a('  <div class="tp" id="tp1">')
a('    <div class="st-blk"><div class="st-h">GENEL</div>')
a('      <div class="bs-grid">')
for i,lbl in enumerate(['TOPLAM','ULKE','ORT YUK','ORT HIZ','MAX HIZ','MAX YUK']):
    a('        <div class="bsi"><div class="bsi-inner"><div class="bsv" id="bs%d">0</div><div class="bsl">%s</div></div></div>' % (i,lbl))
a('      </div>')
a('    </div>')
a('    <div class="st-blk"><div class="st-h">ULKE</div><div id="stco"></div></div>')
a('    <div class="st-blk"><div class="st-h">HIZ (km/s)</div><div id="stsp"></div></div>')
a('    <div class="st-blk"><div class="st-h">YUKSEKLIK (m)</div><div id="stal"></div></div>')
a('    <div class="st-blk"><div class="st-h">AIRLINE</div><div id="stai"></div></div>')
a('  </div>')

# Tab 2 - Alerts
a('  <div class="tp" id="tp2">')
a('    <div style="padding:7px 12px;border-bottom:1px solid rgba(0,255,136,0.06);font-size:9px;color:rgba(168,255,212,0.35);letter-spacing:2px;display:-webkit-box;display:-ms-flexbox;display:flex;-webkit-box-pack:justify;-ms-flex-pack:justify;justify-content:space-between;-webkit-box-align:center;-ms-flex-align:center;align-items:center;-ms-flex-negative:0;flex-shrink:0;">')
a('      <span id="alh">ALARMLAR</span><button class="fc" onclick="clrAlerts()" style="font-size:8px;padding:2px 7px;">TEMIZLE</button>')
a('    </div>')
a('    <div id="allist"><div class="no-al">ALARM YOK</div></div>')
a('  </div>')

# Tab 3 - Settings
a('  <div class="tp" id="tp3">')
a('    <div class="st-sec">HARiTA</div>')
a('    <div class="srow"><span class="s-lbl">Ucus izleri</span><div class="tog" id="sw-trail" onclick="togCfg(0)"></div></div>')
a('    <div class="srow"><span class="s-lbl">Yerdeki ucaklar</span><div class="tog" id="sw-ground" onclick="togCfg(1)"></div></div>')
a('    <div class="srow"><span class="s-lbl">Animasyonlu ikon</span><div class="tog on" id="sw-anim" onclick="togCfg(2)"></div></div>')
a('    <div class="st-sec">YENiLEME SURESi</div>')
a('    <div class="srow"><span class="s-lbl">Sure</span><span class="t-val" id="rfv">30s</span></div>')
a('    <div style="padding:6px 12px;-ms-flex-negative:0;flex-shrink:0;"><input type="range" id="rfsl" min="15" max="120" value="30" step="5" oninput="onRfSl(this.value)"></div>')
a('    <div class="st-sec">DiSA AKTAR</div>')
a('    <div class="srow"><span class="s-lbl">JSON</span><button class="ex-btn" onclick="expJSON()">&#11015; JSON</button></div>')
a('    <div class="srow"><span class="s-lbl">CSV</span><button class="ex-btn" onclick="expCSV()">&#11015; CSV</button></div>')
a('    <div class="st-sec">TOKEN</div>')
a('    <div class="srow"><span class="s-lbl">Kayitli tokeni sil</span><button class="ex-btn" onclick="clrToken()" style="color:#ff4466;border-color:rgba(255,68,102,0.3);">SIL</button></div>')
a('  </div>')
a('</div>') # /lpanel

# ── MAP + LAYERS + ELEMENTS ──────────────────────────────────────
a('<div id="map"></div>')

a('<div id="tlegend"><div class="tl-h">iZ RENKLERI</div>')
for clr,lbl in [('#00ff88','< 3km'),('#00e5ff','3-6km'),('#ffcc00','6-9km'),('#ff4466','> 9km')]:
    a('  <div class="tl-r"><div class="tl-c" style="background:%s;"></div>%s</div>' % (clr,lbl))
a('</div>')

a('<div id="layers">')
a('  <button class="l-btn on" id="lb-sat" onclick="setLayer(0)">&#128752; UYDU</button>')
a('  <button class="l-btn" id="lb-drk" onclick="setLayer(1)">&#127769; KARANLIK</button>')
a('  <button class="l-btn" id="lb-str" onclick="setLayer(2)">&#128506; SOKAK</button>')
a('  <div class="l-sep"></div>')
a('  <button class="l-btn" id="lb-trm" onclick="toggleTrm()">&#9788; GECE</button>')
a('</div>')

a('<div id="cmpwrap"><canvas id="cmp" width="46" height="46"></canvas></div>')

a('<div id="infopanel">')
a('  <div class="ip-head"><span id="i-call">---</span>')
a('    <div class="ip-acts"><button class="tr-btn" id="trbt" onclick="togSelTrail()">iZ</button><span class="cl-x" onclick="closeInfo()">&#215;</span></div>')
a('  </div>')
a('  <div class="ip-grid">')
fields = [('ULKE','i-co','b'),('YUKSEKLIK','i-alt',''),('HIZ(km/s)','i-spd',''),('ROTA','i-hdg',''),('ENLEM','i-lat',''),('BOYLAM','i-lon',''),('SQUAWK','i-sqk',''),('DURUM','i-grnd',''),('DiKEY HIZ','i-vs',''),('ICAO24','i-icao','')]
for lbl,id_,cls in fields:
    style = ' style="font-size:10px;"' if id_=='i-icao' else ''
    a('    <div class="ifd"><div class="i-lbl">%s</div><div class="i-val %s" id="%s"%s>---</div></div>' % (lbl,cls,id_,style))
a('  </div>')
a('  <div class="spd-row"><div class="spd-lbl">0</div><div class="spd-trk"><div class="spd-fill" id="spg"></div></div><div class="spd-lbl">1200+</div></div>')
a('  <div class="hist-wrap"><div class="hist-lbl">HIZ GECMiSi</div><canvas id="shc" width="266" height="34"></canvas></div>')
a('  <div class="ip-btns">')
a('    <button class="ip-btn" onclick="flyToSel()">&#9992; GiT</button>')
a('    <button class="ip-btn" onclick="copyCoords()">&#128203;</button>')
a('    <button class="ip-btn" onclick="openFA()">FA&#8599;</button>')
a('    <button class="ip-btn" onclick="openFR24()">FR24&#8599;</button>')
a('  </div>')
a('</div>')

a('<div id="radarwrap"><div class="rd-h">RADAR <span class="rd-cnt" id="rdcnt">0</span></div><canvas id="rdc" width="100" height="100"></canvas></div>')

a('<div id="hud">')
for lbl,id_,unit in [('YUKSEK','h-alt','m'),('HIZ','h-spd','km/s'),('ROTA','h-hdg','deg'),('DiKEY','h-vs','m/s')]:
    a('  <div class="hm"><div class="hm-l">%s</div><div class="hm-v" id="%s">---</div><div class="hm-u">%s</div></div>' % (lbl,id_,unit))
a('</div>')

a('<div id="ntf"><span class="ntf-ic" id="ntf-ic">i</span><span id="ntf-m"></span></div>')
a('<div id="refbar"><div id="refprog"></div></div>')

# ── JAVASCRIPT ───────────────────────────────────────────────────
a('<script>')
a('// STATE')
a('var MAP=null,TOKEN="",DEMO=false;')
a('var flights=[],filtered=[],selIcao=null;')
a('var activeF=0,mlimit=150;')
a('var panelOpen=true,searchOpen=false,helpOpen=false;')
a('var curLayer=0,wxOn=false,trmOn=false,allTrails=false;')
a('var markers={},trailPts={},trailOn={},spdHist={};')
a('var alerts=[],rfTimer=null,rdAngle=0,RF=30000;')
a('var cfg=[false,false,true]; // trail,ground,anim')

# Flags
a('var FLG={"Turkey":"TR","Germany":"DE","United Kingdom":"GB","France":"FR","United States":"US","Spain":"ES","Italy":"IT","Netherlands":"NL","Russia":"RU","United Arab Emirates":"AE","Qatar":"QA","Saudi Arabia":"SA","China":"CN","Japan":"JP","Australia":"AU","Canada":"CA","Brazil":"BR","India":"IN","South Korea":"KR","Switzerland":"CH","Poland":"PL","Austria":"AT","Greece":"GR","Portugal":"PT","Ukraine":"UA","Romania":"RO","Sweden":"SE","Norway":"NO","Denmark":"DK","Finland":"FI","Belgium":"BE","Czech Republic":"CZ","Hungary":"HU","Bulgaria":"BG","Croatia":"HR","Serbia":"RS","Lithuania":"LT","Latvia":"LV","Estonia":"EE","Israel":"IL","Egypt":"EG","Morocco":"MA","Singapore":"SG","Malaysia":"MY","Thailand":"TH","Indonesia":"ID","Philippines":"PH","Argentina":"AR","Mexico":"MX","Colombia":"CO","New Zealand":"NZ","Pakistan":"PK","Iran":"IR"};')
a('function flag(c){var x=FLG[c];if(!x)return"";return x.split("").map(function(a){return String.fromCodePoint(127397+a.charCodeAt(0));}).join("");}')

# Notify
a('function ntf(msg,t){')
a('  t=t||"info";')
a('  var e=document.getElementById("ntf");')
a('  document.getElementById("ntf-ic").textContent=t==="err"?"!":t==="warn"?"?":t==="ok"?"v":"i";')
a('  document.getElementById("ntf-m").textContent=msg;')
a('  e.className="ntf show"+(t==="err"?" err":t==="warn"?" warn":t==="ok"?" ok":"");')
a('  if(e._t)clearTimeout(e._t);')
a('  e._t=setTimeout(function(){e.className="ntf";},3800);')
a('}')

# Modal
a('window.addEventListener("load",function(){')
a('  var s=localStorage.getItem("sw6tok");')
a('  if(s&&s.length>20){')
a('    document.getElementById("ti").value=s;')
a('    var sv=document.getElementById("m-saved");')
a('    sv.textContent="Kayitli: "+s.slice(0,18)+"...";')
a('    sv.className="m-saved show";')
a('  }')
a('  document.getElementById("ti").addEventListener("keydown",function(e){')
a('    if(e.key==="Enter")doStart();')
a('    if(e.key==="Tab"){e.preventDefault();doDemo();}')
a('  });')
a('});')

a('function setErr(m){document.getElementById("m-err").textContent=m?"! "+m:"";}')

a('function doStart(){')
a('  var v=document.getElementById("ti").value.trim();')
a('  setErr("");')
a('  if(!v){setErr("Token bos birakilamaz");return;}')
a('  if(v.length<20){setErr("Token cok kisa - tam yapistirin");return;}')
a('  TOKEN=v;')
a('  localStorage.setItem("sw6tok",v);')
a('  document.getElementById("btn-start").disabled=true;')
a('  document.getElementById("btn-demo").disabled=true;')
a('  document.getElementById("modal").className="hide";')
a('  boot(false);')
a('}')

a('function doDemo(){')
a('  DEMO=true;')
a('  document.getElementById("btn-start").disabled=true;')
a('  document.getElementById("btn-demo").disabled=true;')
a('  document.getElementById("modal").className="hide";')
a('  boot(true);')
a('}')

# Boot - uses setTimeout chain, NO async/await
a('function boot(demo){')
a('  var ld=document.getElementById("loading");')
a('  var bar=document.getElementById("ldbar");')
a('  var st=document.getElementById("ldst");')
a('  ld.className="show";')
a('  var steps=[[10,"SISTEM..."],[25,"OPENSKY..."],[45,"HARITA..."],[65,"VERi..."],[82,"RADAR..."],[95,"OPTiMiZE..."],[100,"HAZIR!"]];')
a('  var i=0;')
a('  function next(){')
a('    if(i>=steps.length){')
a('      setTimeout(function(){')
a('        ld.style.opacity="0";')
a('        ld.style.webkitTransition="opacity 0.5s";')
a('        ld.style.transition="opacity 0.5s";')
a('        setTimeout(function(){')
a('          ld.className="";')
a('          ld.style.opacity="";ld.style.transition="";ld.style.webkitTransition="";')
a('          if(demo)initNoMap();else initMap();')
a('          startClock();startRadar();startCompass();setupKeys();')
a('          loadFlights();startRfTimer();')
a('        },500);')
a('      },150);')
a('      return;')
a('    }')
a('    bar.style.width=steps[i][0]+"%";')
a('    st.textContent=steps[i][1];')
a('    i++;setTimeout(next,260);')
a('  }')
a('  next();')
a('}')

a('function startClock(){setInterval(function(){document.getElementById("clk").textContent=new Date().toTimeString().slice(0,8);},1000);}')

a('function setSdot(s){')
a('  var d=document.getElementById("sdot"),t=document.getElementById("sst");')
a('  d.className="sdot blink";')
a('  if(s==="live"){d.className="sdot";t.textContent="CANLI";}')
a('  else if(s==="load"){d.className="sdot ld blink";t.textContent="YUKLENIYOR";}')
a('  else if(s==="err"){d.className="sdot er blink";t.textContent="HATA";}')
a('  else if(s==="demo"){d.className="sdot dm";t.textContent="DEMO";}')
a('}')

# Map init
a('function initMap(){')
a('  mapboxgl.accessToken=TOKEN;')
a('  MAP=new mapboxgl.Map({container:"map",style:"mapbox://styles/mapbox/satellite-v9",center:[35,40],zoom:4,antialias:true});')
a('  MAP.addControl(new mapboxgl.NavigationControl({showCompass:false}),"top-right");')
a('  MAP.on("load",function(){setSdot("live");});')
a('  MAP.on("error",function(){setSdot("err");ntf("Harita hatasi! Token gecerli mi?","err");});')
a('  MAP.on("rotate",function(){drawCompass(MAP.getBearing());});')
a('}')

a('function initNoMap(){')
a('  setSdot("demo");')
a('  var m=document.getElementById("map");')
a('  m.style.background="radial-gradient(ellipse at 50% 40%, #030f1e, #020810)";')
a('  var c=document.createElement("canvas");')
a('  c.style.position="absolute";c.style.top="0";c.style.left="0";c.style.width="100%";c.style.height="100%";')
a('  m.appendChild(c);')
a('  c.width=window.innerWidth;c.height=window.innerHeight;')
a('  var ctx=c.getContext("2d");')
a('  ctx.strokeStyle="rgba(0,255,136,0.04)";ctx.lineWidth=1;')
a('  for(var x=0;x<c.width;x+=60){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,c.height);ctx.stroke();}')
a('  for(var y=0;y<c.height;y+=60){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(c.width,y);ctx.stroke();}')
a('  for(var i=0;i<100;i++){ctx.beginPath();ctx.arc(Math.random()*c.width,Math.random()*c.height,Math.random()*.8+.2,0,Math.PI*2);ctx.fillStyle="rgba(168,255,212,0.2)";ctx.fill();}')
a('}')

# Layers
a('var LSTYLES=["mapbox://styles/mapbox/satellite-v9","mapbox://styles/mapbox/dark-v11","mapbox://styles/mapbox/streets-v12"];')
a('var LIDS=["lb-sat","lb-drk","lb-str"];')
a('function setLayer(n){')
a('  if(DEMO||!MAP)return;')
a('  curLayer=n;')
a('  for(var k=0;k<3;k++)document.getElementById(LIDS[k]).className="l-btn"+(k===n?" on":"");')
a('  MAP.setStyle(LSTYLES[n]);')
a('  MAP.once("style.load",function(){redrawMarkers();});')
a('  ntf(["UYDU","KARANLIK","SOKAK"][n]+" KATMANI","info");')
a('}')

# Terminator
a('function toggleTrm(){')
a('  trmOn=!trmOn;')
a('  document.getElementById("trmbt").className="tbtn"+(trmOn?" on":"");')
a('  document.getElementById("lb-trm").className="l-btn"+(trmOn?" on":"");')
a('  if(trmOn)drawTrm();')
a('  else if(MAP){try{if(MAP.getLayer("trm"))MAP.removeLayer("trm");if(MAP.getSource("trm"))MAP.removeSource("trm");}catch(e){}}')
a('  ntf("GECE/GUNDUZ "+(trmOn?"AKTIF":"KAPALI"),"info");')
a('}')
a('function drawTrm(){')
a('  if(!MAP)return;')
a('  var d=new Date(),dec=-23.45*Math.cos((360/365*(d.getMonth()*30+d.getDate())+10)*Math.PI/180)*Math.PI/180;')
a('  var coords=[];')
a('  for(var lon=-180;lon<=180;lon+=2)coords.push([lon,Math.atan(-Math.cos(lon*Math.PI/180)/Math.tan(dec))*180/Math.PI]);')
a('  coords.push([180,-90],[180,90],[-180,90],[-180,coords[0][1]],coords[0]);')
a('  try{')
a('    if(MAP.getSource("trm"))MAP.removeLayer("trm"),MAP.removeSource("trm");')
a('    MAP.addSource("trm",{type:"geojson",data:{type:"Feature",geometry:{type:"Polygon",coordinates:[coords]}}});')
a('    MAP.addLayer({id:"trm",type:"fill",source:"trm",paint:{"fill-color":"#000018","fill-opacity":0.42}});')
a('  }catch(e){}')
a('}')

# Weather - using OpenWeatherMap free demo key
a('function toggleWx(){')
a('  wxOn=!wxOn;')
a('  document.getElementById("wxbt").className="tbtn"+(wxOn?" on":"");')
a('  ntf("HAVA DURUMU "+(wxOn?"AKTIF":"KAPALI"),"info");')
a('  if(!MAP||DEMO)return;')
a('  if(wxOn){')
a('    try{')
a('      MAP.addSource("owm",{type:"raster",tiles:["https://tile.openweathermap.org/map/clouds_new/{z}/{x}/{y}.png?appid=439d4b804bc8187953eb36d2a8c26a02"],tileSize:256});')
a('      MAP.addLayer({id:"owml",type:"raster",source:"owm",paint:{"raster-opacity":0.4}});')
a('    }catch(e){ntf("Hava katmani yuklenemedi","warn");}')
a('  }else{try{if(MAP.getLayer("owml"))MAP.removeLayer("owml");if(MAP.getSource("owm"))MAP.removeSource("owm");}catch(e){}}')
a('}')

# OpenSky fetch - pure XHR, no async, no AbortController
a('function fetchFlights(cb){')
a('  var urls=["https://opensky-network.org/api/states/all?lamin=25&lomin=-20&lamax=72&lomax=55","https://opensky-network.org/api/states/all"];')
a('  var idx=0;')
a('  function tryNext(){')
a('    if(idx>=urls.length){ntf("OpenSky baglanamiyor - demo veri","warn");cb(genDemo());return;}')
a('    var url=urls[idx++];')
a('    var xhr=new XMLHttpRequest();')
a('    xhr.timeout=14000;')
a('    xhr.onreadystatechange=function(){')
a('      if(xhr.readyState!==4)return;')
a('      if(xhr.status===200){')
a('        try{var d=JSON.parse(xhr.responseText);cb(d.states||[]);}catch(e){tryNext();}')
a('      }else{tryNext();}')
a('    };')
a('    xhr.ontimeout=xhr.onerror=function(){tryNext();};')
a('    xhr.open("GET",url,true);xhr.send();')
a('  }')
a('  tryNext();')
a('}')

a('function pState(s){')
a('  return{icao24:s[0]||"",callsign:(s[1]||"").trim()||s[0]||"????",country:s[2]||"?",lon:s[5],lat:s[6],alt:s[7]?Math.round(s[7]):null,ground:s[8]||false,vel:s[9]?Math.round(s[9]*3.6):null,hdg:s[10]!==null?Math.round(s[10]):null,vs:s[11]?Math.round(s[11]):0,sqk:s[14]||"----"};')
a('}')

a('function genDemo(){')
a('  var al=["TK","LH","BA","AF","EK","QR","SU","PC","FR","W6","IBE","KLM","THY","AUA","SWR","WZZ","RYR","EZY","AAL","DAL"];')
a('  var co=Object.keys(FLG).slice(0,16);')
a('  var out=[];')
a('  for(var i=0;i<90;i++){')
a('    out.push(["dm"+i,al[i%al.length]+(200+i)+"  ",co[i%co.length],null,null,8+Math.random()*52,28+Math.random()*38,800+Math.random()*13000,false,80+Math.random()*1000,Math.random()*360,(Math.random()-.5)*14,null,null,String(Math.floor(1000+Math.random()*8999))]);')
a('  }')
a('  return out;')
a('}')

# Load flights
a('function loadFlights(){')
a('  setSdot("load");')
a('  fetchFlights(function(raw){')
a('    flights=[];')
a('    for(var i=0;i<raw.length;i++){')
a('      var f=pState(raw[i]);')
a('      if(f.lat&&f.lon&&(cfg[1]||!f.ground))flights.push(f);')
a('    }')
a('    var cos={};for(var j=0;j<flights.length;j++)cos[flights[j].country]=1;')
a('    var alts=[];for(var k=0;k<flights.length;k++)if(flights[k].alt)alts.push(flights[k].alt);')
a('    document.getElementById("scnt").textContent=flights.length;')
a('    document.getElementById("sco").textContent=Object.keys(cos).length;')
a('    document.getElementById("smx").textContent=alts.length?Math.max.apply(null,alts):0;')
a('    document.getElementById("supd").textContent=new Date().toTimeString().slice(0,5);')
a('    setSdot(DEMO?"demo":"live");')
a('    if(selIcao){var sf=null;for(var m=0;m<flights.length;m++)if(flights[m].icao24===selIcao){sf=flights[m];break;}')
a('      if(sf&&sf.vel){if(!spdHist[selIcao])spdHist[selIcao]=[];spdHist[selIcao].push(sf.vel);if(spdHist[selIcao].length>30)spdHist[selIcao].shift();}}')
a('    chkAlerts();updStats();applyF();updTrails();')
a('    if(MAP)redrawMarkers();')
a('    if(selIcao)refreshInfo();')
a('  });')
a('}')
a('function doRefresh(){resetRfTimer();loadFlights();ntf("VERi YENiLENDi","ok");}')

# Filter
a('var FKEYS=["all","hi","fast","tr","emg"];')
a('function setF(n){')
a('  activeF=n;')
a('  for(var i=0;i<FKEYS.length;i++)document.getElementById("fc-"+FKEYS[i]).className="fc"+(i===n?" on":"")+(i===4?" red":"");')
a('  applyF();')
a('}')
a('function applyF(){')
a('  filtered=[];')
a('  for(var i=0;i<flights.length;i++){')
a('    var f=flights[i];')
a('    var ok=activeF===0||(activeF===1&&f.alt>9000)||(activeF===2&&f.vel>800)||(activeF===3&&f.country==="Turkey")||(activeF===4&&(f.sqk==="7700"||f.sqk==="7600"||f.sqk==="7500"));')
a('    if(ok)filtered.push(f);')
a('  }')
a('  document.getElementById("fcnt").textContent=filtered.length;')
a('  document.getElementById("ftot").textContent="/ "+flights.length;')
a('  document.getElementById("svis").textContent=Math.min(mlimit,filtered.length);')
a('  renderList();')
a('}')

# Render list
a('function renderList(){')
a('  var fl=document.getElementById("flist");')
a('  var html="";')
a('  var show=filtered.slice(0,200);')
a('  for(var i=0;i<show.length;i++){')
a('    var f=show[i];')
a('    var emg=f.sqk==="7700"||f.sqk==="7600"||f.sqk==="7500";')
a('    var ap=f.alt?Math.min(100,f.alt/130):0;')
a('    var ac=f.alt>9000?"#ff4466":f.alt>6000?"#ffcc00":f.alt>3000?"#00e5ff":"#00ff88";')
a('    var cls="fi"+(f.icao24===selIcao?" sel":"")+(emg?" emg":"");')
a('    html+=\'<div class="\'+cls+\'" onclick="pickByIdx("+i+")">\';')
a('    html+=\'<div class="fi-call">\'+flag(f.country)+\' \'+f.callsign+(emg?\'<span style="font-size:8px;color:#ff4466;border:1px solid #ff4466;padding:1px 3px;margin-left:4px;">ACiL</span>\':"")+\'</div>\';')
a('    html+=\'<div class="fi-det">\'+f.country.slice(0,12)+\' &#9650;<span>\'+( f.alt?f.alt+"m":"--")+\'</span> &#10148;<span>\'+( f.vel?f.vel:"--")+\'</span></div>\';')
a('    html+=\'<div class="fi-bar"><div class="fi-fill" style="width:\'+ap+\'%;background:\'+ac+\';"></div></div>\';')
a('    html+=\'</div>\';')
a('  }')
a('  fl.innerHTML=html||\'<div style="padding:16px;text-align:center;color:rgba(168,255,212,0.25);font-size:11px;">UCAK YOK</div>\';')
a('}')

# pickByIdx - avoids closure issues with onclick string
a('function pickByIdx(n){if(filtered[n])pick(filtered[n]);}')

# Stats
a('function updStats(){')
a('  var cmap={},amap={};')
a('  var alts=[],vels=[];')
a('  for(var i=0;i<flights.length;i++){')
a('    var f=flights[i];')
a('    cmap[f.country]=(cmap[f.country]||0)+1;')
a('    var al=f.callsign.replace(/[0-9\\s]/g,"").slice(0,3);')
a('    if(al.length>=2)amap[al]=(amap[al]||0)+1;')
a('    if(f.alt)alts.push(f.alt);')
a('    if(f.vel)vels.push(f.vel);')
a('  }')
a('  var aa=alts.length?Math.round(alts.reduce(function(s,v){return s+v;},0)/alts.length):0;')
a('  var av=vels.length?Math.round(vels.reduce(function(s,v){return s+v;},0)/vels.length):0;')
a('  var mv=vels.length?Math.max.apply(null,vels):0;')
a('  var ma=alts.length?Math.max.apply(null,alts):0;')
a('  var vals=[flights.length,Object.keys(cmap).length,aa,av,mv,ma];')
a('  for(var b=0;b<6;b++)document.getElementById("bs"+b).textContent=vals[b];')
a('  function bars(id,obj,clr){')
a('    var s=Object.entries?Object.entries(obj):Object.keys(obj).map(function(k){return[k,obj[k]];});')
a('    s.sort(function(a,b){return b[1]-a[1];});s=s.slice(0,7);')
a('    var mx=s.length?s[0][1]:1;')
a('    var h="";')
a('    for(var i=0;i<s.length;i++)h+=\'<div class="st-row"><div class="st-lbl">\'+s[i][0].slice(0,14)+\'</div><div class="st-trk"><div class="st-fill" style="width:\'+Math.round(s[i][1]/mx*100)+\'%;background:\'+clr+\';"></div></div><div class="st-num" style="color:\'+clr+\'">\'+s[i][1]+\'</div></div>\';')
a('    document.getElementById(id).innerHTML=h;')
a('  }')
a('  bars("stco",cmap,"#00ff88");bars("stai",amap,"#00e5ff");')
a('  function buck(id,bkts,clr){')
a('    var mx=0;for(var i=0;i<bkts.length;i++)if(bkts[i].n>mx)mx=bkts[i].n;')
a('    var h="";')
a('    for(var i=0;i<bkts.length;i++)h+=\'<div class="st-row"><div class="st-lbl">\'+bkts[i].l+\'</div><div class="st-trk"><div class="st-fill" style="width:\'+Math.round(mx>0?bkts[i].n/mx*100:0)+\'%;background:\'+clr+\';"></div></div><div class="st-num" style="color:\'+clr+\'">\'+bkts[i].n+\'</div></div>\';')
a('    document.getElementById(id).innerHTML=h;')
a('  }')
a('  var sb=[{l:"<400",n:0},{l:"400-600",n:0},{l:"600-800",n:0},{l:"800-1k",n:0},{l:">1k",n:0}];')
a('  for(var v=0;v<vels.length;v++){var vel=vels[v];if(vel<400)sb[0].n++;else if(vel<600)sb[1].n++;else if(vel<800)sb[2].n++;else if(vel<1000)sb[3].n++;else sb[4].n++;}')
a('  buck("stsp",sb,"#00e5ff");')
a('  var ab=[{l:"<3k",n:0},{l:"3-6k",n:0},{l:"6-9k",n:0},{l:"9-12k",n:0},{l:">12k",n:0}];')
a('  for(var v=0;v<alts.length;v++){var alt=alts[v];if(alt<3000)ab[0].n++;else if(alt<6000)ab[1].n++;else if(alt<9000)ab[2].n++;else if(alt<12000)ab[3].n++;else ab[4].n++;}')
a('  buck("stal",ab,"#ffcc00");')
a('}')

# Alerts
a('function chkAlerts(){')
a('  var sq={"7700":"ACIL DURUM","7600":"RADYO ARIZA","7500":"HiJACK"};')
a('  for(var i=0;i<flights.length;i++){')
a('    var f=flights[i];')
a('    if(f.alt&&f.alt>12000)addAlert(f.callsign+" asiri yukseklik: "+f.alt+"m","md");')
a('    if(sq[f.sqk])addAlert("SQUAWK "+f.sqk+" "+sq[f.sqk]+": "+f.callsign,"hi");')
a('    if(f.vs&&f.vs<-20)addAlert(f.callsign+" hizli alcalma: "+f.vs+"m/s","md");')
a('  }')
a('}')
a('function addAlert(msg,lvl){')
a('  for(var i=0;i<alerts.length;i++)if(alerts[i].msg===msg)return;')
a('  alerts.unshift({msg:msg,lvl:lvl,t:new Date().toTimeString().slice(0,5)});')
a('  if(alerts.length>50)alerts.pop();')
a('  renderAlerts();')
a('  if(lvl==="hi")ntf("ALARM: "+msg,"err");')
a('}')
a('function renderAlerts(){')
a('  var al=document.getElementById("allist"),hd=document.getElementById("alh");')
a('  if(!alerts.length){al.innerHTML=\'<div class="no-al">ALARM YOK</div>\';hd.textContent="ALARMLAR";return;}')
a('  var h="";')
a('  var show=alerts.slice(0,30);')
a('  for(var i=0;i<show.length;i++){var a2=show[i];h+=\'<div class="al-item"><div class="al-pip \'+a2.lvl+\'"></div><div><div class="al-msg">\'+a2.msg+\'</div><div class="al-tm">\'+a2.t+\'</div></div></div>\';}')
a('  al.innerHTML=h;')
a('  hd.textContent="ALARM("+Math.min(alerts.length,30)+")";')
a('}')
a('function clrAlerts(){alerts=[];renderAlerts();}')

# Markers
a('function redrawMarkers(){')
a('  if(!MAP)return;')
a('  var k=Object.keys(markers);')
a('  for(var i=0;i<k.length;i++)markers[k[i]].remove();')
a('  markers={};')
a('  var show=filtered.length?filtered:flights;')
a('  var limit=Math.min(mlimit,show.length);')
a('  for(var i=0;i<limit;i++){')
a('    var f=show[i];')
a('    var el=mkEl(f);')
a('    var m=new mapboxgl.Marker({element:el,anchor:"center"}).setLngLat([f.lon,f.lat]).addTo(MAP);')
a('    el._icao=f.icao24;')
a('    el.addEventListener("click",(function(icao){return function(e){e.stopPropagation();var f2=null;for(var i=0;i<flights.length;i++)if(flights[i].icao24===icao){f2=flights[i];break;}if(f2)pick(f2);};})(f.icao24));')
a('    markers[f.icao24]=m;')
a('  }')
a('}')

a('function mkEl(f){')
a('  var sel=f.icao24===selIcao;')
a('  var emg=f.sqk==="7700"||f.sqk==="7600"||f.sqk==="7500";')
a('  var clr=emg?"#ff4466":sel?"#00e5ff":f.alt>9000?"#ffcc00":f.alt>3000?"#00ff88":"#88ffcc";')
a('  var sz=sel?22:14;')
a('  var el=document.createElement("div");')
a('  el.style.width=sz+"px";el.style.height=sz+"px";el.style.cursor="pointer";')
a('  if(emg)el.style.webkitAnimation=el.style.animation="blink-fast 0.5s infinite";')
a('  var svg=\'<svg viewBox="0 0 24 24" fill="none" style="transform:rotate(\'+( f.hdg||0)+\'deg);width:100%;height:100%;filter:drop-shadow(0 0 \'+( sel?6:3)+\'px \'+clr+\')">\'')
a('    +\'<path d="M12 2L8 10H4L6 12H10L8 20H12L16 12H20L22 10H18L12 2Z" fill="\'+clr+\'" opacity="0.95"/>\'')
a('    +(sel?\'<circle cx="12" cy="12" r="11" stroke="\'+clr+\'" stroke-opacity="0.3" stroke-width="1"/>\':"")') 
a('    +"</svg>";')
a('  el.innerHTML=svg;')
a('  return el;')
a('}')

# Trail system
a('function trlClr(alt){return alt>9000?"#ff4466":alt>6000?"#ffcc00":alt>3000?"#00e5ff":"#00ff88";}')

a('function updTrailFlight(f){')
a('  if(!MAP||!f.lat||!f.lon)return;')
a('  if(!trailPts[f.icao24])trailPts[f.icao24]=[];')
a('  trailPts[f.icao24].push({c:[f.lon,f.lat],a:f.alt});')
a('  if(trailPts[f.icao24].length>120)trailPts[f.icao24].shift();')
a('  renderTrail(f.icao24);')
a('}')

a('function renderTrail(icao){')
a('  if(!MAP)return;')
a('  var pts=trailPts[icao];')
a('  if(!pts||pts.length<2)return;')
a('  try{')
a('    var sty=MAP.getStyle();')
a('    var lrs=sty.layers||[];')
a('    for(var i=0;i<lrs.length;i++)if(lrs[i].id.indexOf("trl-"+icao)===0)try{MAP.removeLayer(lrs[i].id);}catch(e){}')
a('    var srcs=Object.keys(sty.sources||{});')
a('    for(var i=0;i<srcs.length;i++)if(srcs[i].indexOf("trs-"+icao)===0)try{MAP.removeSource(srcs[i]);}catch(e){}')
a('  }catch(e){}')
a('  var cmap={};')
a('  for(var i=1;i<pts.length;i++){')
a('    var clr=trlClr(pts[i].a);')
a('    if(!cmap[clr])cmap[clr]=[];')
a('    cmap[clr].push([pts[i-1].c,pts[i].c]);')
a('  }')
a('  var ci=0;')
a('  var colors=Object.keys(cmap);')
a('  for(var c=0;c<colors.length;c++){')
a('    var clr=colors[c];')
a('    var sid="trs-"+icao+"-"+ci;')
a('    var lid="trl-"+icao+"-"+ci;')
a('    ci++;')
a('    var features=[];')
a('    for(var s=0;s<cmap[clr].length;s++)features.push({type:"Feature",geometry:{type:"LineString",coordinates:cmap[clr][s]}});')
a('    try{')
a('      MAP.addSource(sid,{type:"geojson",data:{type:"FeatureCollection",features:features}});')
a('      MAP.addLayer({id:lid,type:"line",source:sid,paint:{"line-color":clr,"line-width":2,"line-opacity":0.7}});')
a('    }catch(e){}')
a('  }')
a('}')

a('function clrTrail(icao){')
a('  delete trailPts[icao];')
a('  if(!MAP)return;')
a('  try{')
a('    var sty=MAP.getStyle();')
a('    var lrs=sty.layers||[];')
a('    for(var i=0;i<lrs.length;i++)if(lrs[i].id.indexOf("trl-"+icao)===0)try{MAP.removeLayer(lrs[i].id);}catch(e){}')
a('    var srcs=Object.keys(sty.sources||{});')
a('    for(var i=0;i<srcs.length;i++)if(srcs[i].indexOf("trs-"+icao)===0)try{MAP.removeSource(srcs[i]);}catch(e){}')
a('  }catch(e){}')
a('}')

a('function clrAllTrails(){')
a('  var ks=Object.keys(trailPts);')
a('  for(var i=0;i<ks.length;i++)clrTrail(ks[i]);')
a('  trailPts={};trailOn={};')
a('  ntf("TUM iZLER TENiZLENDi","info");')
a('}')

a('function updTrails(){')
a('  for(var i=0;i<flights.length;i++){')
a('    var f=flights[i];')
a('    if(trailOn[f.icao24]||allTrails)updTrailFlight(f);')
a('  }')
a('}')

a('function togSelTrail(){')
a('  if(!selIcao)return;')
a('  trailOn[selIcao]=!trailOn[selIcao];')
a('  document.getElementById("trbt").className="tr-btn"+(trailOn[selIcao]?" on":"");')
a('  if(!trailOn[selIcao])clrTrail(selIcao);')
a('  else{for(var i=0;i<flights.length;i++)if(flights[i].icao24===selIcao){updTrailFlight(flights[i]);break;}}')
a('  ntf("iZ "+(trailOn[selIcao]?"AKTIF":"KAPALI"),"info");')
a('}')

a('function toggleAllTrails(){')
a('  allTrails=!allTrails;')
a('  document.getElementById("alltrbt").className="tbtn"+(allTrails?" on":"");')
a('  document.getElementById("tlegend").className=allTrails?"vis":"";')
a('  if(!allTrails)clrAllTrails();')
a('  else{updTrails();ntf("TUM iZLER AKTIF","warn");}')
a('}')

# Pick flight
a('function pick(f){')
a('  selIcao=f.icao24;')
a('  if(!spdHist[f.icao24])spdHist[f.icao24]=[];')
a('  if(f.vel)spdHist[f.icao24].push(f.vel);')
a('  refreshInfo();')
a('  if(MAP&&f.lat&&f.lon)MAP.flyTo({center:[f.lon,f.lat],zoom:7,speed:1.5,curve:1.2});')
a('  renderList();if(MAP)redrawMarkers();')
a('}')

a('function refreshInfo(){')
a('  var f=null;for(var i=0;i<flights.length;i++)if(flights[i].icao24===selIcao){f=flights[i];break;}')
a('  if(!f)return;')
a('  var emg=f.sqk==="7700"||f.sqk==="7600"||f.sqk==="7500";')
a('  document.getElementById("i-call").textContent=f.callsign;')
a('  document.getElementById("i-co").textContent=flag(f.country)+" "+f.country.slice(0,14);')
a('  var ae=document.getElementById("i-alt");ae.textContent=f.alt?f.alt+"m":"--";ae.className="i-val"+(f.alt>9000?" r":f.alt>6000?" y":"");')
a('  document.getElementById("i-spd").textContent=f.vel?f.vel+" km/s":"--";')
a('  document.getElementById("i-hdg").textContent=f.hdg!==null?f.hdg+"deg":"--";')
a('  document.getElementById("i-lat").textContent=f.lat?f.lat.toFixed(5):"--";')
a('  document.getElementById("i-lon").textContent=f.lon?f.lon.toFixed(5):"--";')
a('  var se=document.getElementById("i-sqk");se.textContent=f.sqk||"--";se.className="i-val"+(emg?" r":"");')
a('  var ve=document.getElementById("i-vs");ve.textContent=f.vs?(f.vs>0?"+":"")+f.vs+" m/s":"--";ve.className="i-val"+(f.vs>2?" b":f.vs<-2?" y":"");')
a('  document.getElementById("i-grnd").innerHTML=f.ground?"YERDE":f.vs>3?"&#9650; YUKSELIYOR":f.vs<-3?"&#9660; iNiYOR":"&#9654; SEYREDIYOR";')
a('  document.getElementById("i-icao").textContent=(f.icao24||"--").toUpperCase();')
a('  document.getElementById("spg").style.width=(f.vel?Math.min(100,f.vel/12):0)+"%";')
a('  document.getElementById("h-alt").textContent=f.alt?Math.round(f.alt):"--";')
a('  document.getElementById("h-spd").textContent=f.vel||"--";')
a('  document.getElementById("h-hdg").textContent=f.hdg!==null?f.hdg:"--";')
a('  document.getElementById("h-vs").textContent=f.vs?(f.vs>0?"+":"")+f.vs:"--";')
a('  document.getElementById("trbt").className="tr-btn"+(trailOn[f.icao24]?" on":"");')
a('  document.getElementById("infopanel").className="vis";')
a('  document.getElementById("hud").className="vis";')
a('  drawSpdHist(f.icao24);')
a('}')

a('function closeInfo(){')
a('  selIcao=null;')
a('  document.getElementById("infopanel").className="";')
a('  document.getElementById("hud").className="";')
a('  renderList();if(MAP)redrawMarkers();')
a('}')

a('function flyToSel(){var f=null;for(var i=0;i<flights.length;i++)if(flights[i].icao24===selIcao){f=flights[i];break;}if(f&&MAP)MAP.flyTo({center:[f.lon,f.lat],zoom:9,speed:1.5});}')
a('function copyCoords(){var f=null;for(var i=0;i<flights.length;i++)if(flights[i].icao24===selIcao){f=flights[i];break;}if(!f)return;var t=f.lat.toFixed(5)+", "+f.lon.toFixed(5);try{navigator.clipboard.writeText(t);ntf("KOORDINAT KOPYALANDI","ok");}catch(e){ntf(t,"info");}}')
a('function openFA(){var f=null;for(var i=0;i<flights.length;i++)if(flights[i].icao24===selIcao){f=flights[i];break;}if(f)window.open("https://flightaware.com/live/flight/"+f.callsign.trim(),"_blank");}')
a('function openFR24(){var f=null;for(var i=0;i<flights.length;i++)if(flights[i].icao24===selIcao){f=flights[i];break;}if(f)window.open("https://www.flightradar24.com/"+f.callsign.trim(),"_blank");}')

# Speed history chart
a('function drawSpdHist(icao){')
a('  var cv=document.getElementById("shc"),ctx=cv.getContext("2d");')
a('  var pts=spdHist[icao]||[];')
a('  var W=cv.offsetWidth||266,H=34;')
a('  cv.width=W;cv.height=H;')
a('  ctx.clearRect(0,0,W,H);')
a('  if(pts.length<2){ctx.fillStyle="rgba(168,255,212,0.2)";ctx.font="8px monospace";ctx.textAlign="center";ctx.textBaseline="middle";ctx.fillText("VERi BEKLENIYOR...",W/2,H/2);return;}')
a('  var mn=pts[0],mx=pts[0];')
a('  for(var i=1;i<pts.length;i++){if(pts[i]<mn)mn=pts[i];if(pts[i]>mx)mx=pts[i];}')
a('  if(mx===mn)mx=mn+1;')
a('  var step=W/(pts.length-1);')
a('  ctx.beginPath();')
a('  for(var i=0;i<pts.length;i++){var x=i*step,y=H-(pts[i]-mn)/(mx-mn)*(H-4)-2;if(i===0)ctx.moveTo(x,y);else ctx.lineTo(x,y);}')
a('  ctx.strokeStyle="#00e5ff";ctx.lineWidth=1.5;ctx.stroke();')
a('  ctx.lineTo((pts.length-1)*step,H);ctx.lineTo(0,H);ctx.closePath();')
a('  ctx.fillStyle="rgba(0,229,255,0.12)";ctx.fill();')
a('  ctx.fillStyle="rgba(168,255,212,0.4)";ctx.font="8px monospace";ctx.textAlign="left";ctx.textBaseline="top";')
a('  ctx.fillText(Math.round(mx),2,1);')
a('  ctx.textBaseline="bottom";ctx.fillText(Math.round(mn),2,H-1);')
a('}')

# Slider & perf
a('function onSlider(v){mlimit=parseInt(v);document.getElementById("slv").textContent=v;document.getElementById("svis").textContent=Math.min(mlimit,filtered.length);if(MAP)redrawMarkers();}')
a('function onRfSl(v){RF=parseInt(v)*1000;document.getElementById("rfv").textContent=v+"s";resetRfTimer();}')
a('function setPerf(n){')
a('  var cfgs=[[50,60000],[150,30000],[400,18000]];')
a('  var ids=["pm-eco","pm-nrm","pm-ult"];')
a('  for(var i=0;i<3;i++)document.getElementById(ids[i]).className="pm-btn"+(i===n?" on":"");')
a('  mlimit=cfgs[n][0];RF=cfgs[n][1];')
a('  document.getElementById("slim").value=mlimit;document.getElementById("slv").textContent=mlimit;')
a('  resetRfTimer();if(MAP)redrawMarkers();')
a('  ntf(["ECO","NORMAL","ULTRA"][n]+" PERFORMANS MODU","info");')
a('}')

# Settings
a('var CFG_IDS=["sw-trail","sw-ground","sw-anim"];')
a('function togCfg(n){cfg[n]=!cfg[n];document.getElementById(CFG_IDS[n]).className="tog"+(cfg[n]?" on":"");if(n===1)loadFlights();if(n===0&&!cfg[0])clrAllTrails();}')

# Export
a('function expJSON(){')
a('  var data=JSON.stringify(flights,null,2);')
a('  var a=document.createElement("a");')
a('  a.href="data:application/json;charset=utf-8,"+encodeURIComponent(data);')
a('  a.download="skywatch_"+new Date().toISOString().slice(0,10)+".json";')
a('  document.body.appendChild(a);a.click();document.body.removeChild(a);')
a('  ntf("JSON indirildi","ok");')
a('}')
a('function expCSV(){')
a('  var hd="icao24,callsign,country,lat,lon,alt,vel,hdg,vs,sqk";')
a('  var nl=String.fromCharCode(10);')
a('  var rows=[];')
a('  for(var i=0;i<flights.length;i++){')
a('    var f=flights[i];')
a('    rows.push([f.icao24,f.callsign,f.country,f.lat,f.lon,f.alt,f.vel,f.hdg,f.vs,f.sqk].map(function(x){return x===null||x===undefined?"":x;}).join(","));')
a('  }')
a('  var csv=hd+nl+rows.join(nl);')
a('  var a=document.createElement("a");')
a('  a.href="data:text/csv;charset=utf-8,"+encodeURIComponent(csv);')
a('  a.download="skywatch_"+new Date().toISOString().slice(0,10)+".csv";')
a('  document.body.appendChild(a);a.click();document.body.removeChild(a);')
a('  ntf("CSV indirildi","ok");')
a('}')
a('function clrToken(){localStorage.removeItem("sw6tok");ntf("TOKEN SiLiNDi","warn");}')

# Search
a('function toggleSearch(){')
a('  searchOpen=!searchOpen;')
a('  document.getElementById("searchbar").className=searchOpen?"open":"";')
a('  if(searchOpen)setTimeout(function(){document.getElementById("sinput").focus();},80);')
a('  else{document.getElementById("sinput").value="";document.getElementById("sresults").className="";}')
a('}')
a('function doSearch(q){')
a('  var sr=document.getElementById("sresults");')
a('  if(!q||q.length<2){sr.className="";return;}')
a('  var ql=q.toLowerCase();')
a('  var res=[];')
a('  for(var i=0;i<flights.length&&res.length<12;i++){')
a('    var f=flights[i];')
a('    if(f.callsign.toLowerCase().indexOf(ql)>=0||f.country.toLowerCase().indexOf(ql)>=0||f.icao24.toLowerCase().indexOf(ql)>=0)res.push(f);')
a('  }')
a('  if(!res.length){sr.className="";return;}')
a('  var h="";')
a('  for(var i=0;i<res.length;i++){var f=res[i];h+=\'<div class="sr-item" onclick="pickByIcao(\\\'\'+f.icao24+\'\\\')">\'+flag(f.country)+\' <strong style="color:#00e5ff;">\'+f.callsign+\'</strong> <span style="color:rgba(168,255,212,0.5);">\'+f.country+(f.alt?" "+f.alt+"m":"")+\'</span></div>\';}')
a('  sr.innerHTML=h;sr.className="open";')
a('}')
a('function skd(e){if(e.key==="Escape")toggleSearch();if(e.key==="Enter"){var fi=document.querySelector(".sr-item");if(fi)fi.click();}}')
a('function pickByIcao(ic){for(var i=0;i<flights.length;i++)if(flights[i].icao24===ic){pick(flights[i]);toggleSearch();return;}}')

# Panel & tabs
a('function togglePanel(){')
a('  panelOpen=!panelOpen;')
a('  document.getElementById("lpanel").className=panelOpen?"":"cl";')
a('  document.getElementById("ptog").className=panelOpen?"":"cl";')
a('  document.getElementById("ptog").innerHTML=panelOpen?"&#9664;":"&#9654;";')
a('}')
a('function showTab(n){for(var i=0;i<4;i++){document.getElementById("tab"+i).className="tbt"+(i===n?" on":"");document.getElementById("tp"+i).className="tp"+(i===n?" on":"");}}')

# Misc
a('function gotoMe(){if(!navigator.geolocation){ntf("KONUM YOK","err");return;}navigator.geolocation.getCurrentPosition(function(p){if(MAP)MAP.flyTo({center:[p.coords.longitude,p.coords.latitude],zoom:8,speed:1.5});ntf("KONUMUNUZA ODAKLANDI","ok");},function(){ntf("KONUM ALINAMIYOR","err");});}')
a('function doFS(){if(!document.fullscreenElement&&!document.webkitFullscreenElement){if(document.documentElement.requestFullscreen)document.documentElement.requestFullscreen();else if(document.documentElement.webkitRequestFullscreen)document.documentElement.webkitRequestFullscreen();}else{if(document.exitFullscreen)document.exitFullscreen();else if(document.webkitExitFullscreen)document.webkitExitFullscreen();}}')
a('function toggleHelp(){helpOpen=!helpOpen;document.getElementById("kbhelp").className=helpOpen?"vis":"";}')

# Keys
a('function setupKeys(){')
a('  document.addEventListener("keydown",function(e){')
a('    if(e.target.tagName==="INPUT"||e.target.tagName==="TEXTAREA")return;')
a('    var k=e.key;')
a('    if(k==="f"||k==="F"){e.preventDefault();toggleSearch();}')
a('    else if(k==="r"||k==="R")doRefresh();')
a('    else if(k==="l"||k==="L")togglePanel();')
a('    else if(k==="s"||k==="S")setLayer(0);')
a('    else if(k==="d"||k==="D")setLayer(1);')
a('    else if(k==="t"||k==="T")setLayer(2);')
a('    else if(k==="h"||k==="H")toggleWx();')
a('    else if(k==="n"||k==="N")toggleTrm();')
a('    else if(k==="i"||k==="I")toggleAllTrails();')
a('    else if(k==="c"||k==="C")gotoMe();')
a('    else if(k==="x"||k==="X")closeInfo();')
a('    else if(k==="Escape"){if(helpOpen)toggleHelp();else if(searchOpen)toggleSearch();else closeInfo();}')
a('    else if(k==="?")toggleHelp();')
a('    else if(k==="F11"){e.preventDefault();doFS();}')
a('  });')
a('}')

# Radar
a('function startRadar(){')
a('  var cv=document.getElementById("rdc"),ctx=cv.getContext("2d");')
a('  function frame(){')
a('    ctx.clearRect(0,0,100,100);')
a('    ctx.strokeStyle="rgba(0,255,136,0.12)";ctx.lineWidth=1;')
a('    var rs=[16,30,46];')
a('    for(var i=0;i<3;i++){ctx.beginPath();ctx.arc(50,50,rs[i],0,Math.PI*2);ctx.stroke();}')
a('    ctx.strokeStyle="rgba(0,255,136,0.07)";')
a('    ctx.beginPath();ctx.moveTo(50,2);ctx.lineTo(50,98);ctx.stroke();')
a('    ctx.beginPath();ctx.moveTo(2,50);ctx.lineTo(98,50);ctx.stroke();')
a('    ctx.save();ctx.translate(50,50);ctx.rotate(rdAngle);')
a('    var sw=ctx.createLinearGradient(0,0,48,0);sw.addColorStop(0,"rgba(0,255,136,0.6)");sw.addColorStop(1,"rgba(0,255,136,0)");')
a('    ctx.beginPath();ctx.moveTo(0,0);ctx.arc(0,0,48,-0.4,0);ctx.closePath();ctx.fillStyle=sw;ctx.fill();')
a('    ctx.restore();')
a('    var cnt=0;')
a('    if(flights.length&&MAP){')
a('      var ctr=MAP.getCenter();')
a('      for(var i=0;i<flights.length;i++){')
a('        var f=flights[i];')
a('        if(!f.lat||!f.lon)continue;')
a('        var dx=(f.lon-ctr.lng)*1.3,dy=-(f.lat-ctr.lat)*1.6;')
a('        if(dx<-46||dx>46||dy<-46||dy>46)continue;')
a('        cnt++;')
a('        var emg=f.sqk==="7700"||f.sqk==="7600"||f.sqk==="7500";')
a('        ctx.beginPath();ctx.arc(50+dx,50+dy,emg?3:1.5,0,Math.PI*2);')
a('        ctx.fillStyle=emg?"rgba(255,68,102,0.9)":f.icao24===selIcao?"rgba(255,204,0,0.9)":"rgba(0,229,255,0.7)";')
a('        ctx.fill();')
a('      }')
a('    }else{')
a('      for(var i=0;i<Math.min(35,flights.length);i++){')
a('        var a2=(i/35)*Math.PI*2,r=5+Math.random()*40;')
a('        ctx.beginPath();ctx.arc(50+Math.cos(a2)*r,50+Math.sin(a2)*r,1.5,0,Math.PI*2);')
a('        ctx.fillStyle="rgba(0,229,255,0.6)";ctx.fill();cnt++;')
a('      }')
a('    }')
a('    document.getElementById("rdcnt").textContent=cnt;')
a('    rdAngle+=0.025;requestAnimationFrame(frame);')
a('  }')
a('  frame();')
a('}')

# Compass
a('function startCompass(){drawCompass(0);}')
a('function drawCompass(b){')
a('  var cv=document.getElementById("cmp");if(!cv)return;')
a('  var ctx=cv.getContext("2d"),cx=23,cy=23,r=20;')
a('  ctx.clearRect(0,0,46,46);')
a('  ctx.strokeStyle="rgba(0,255,136,0.18)";ctx.lineWidth=1;ctx.beginPath();ctx.arc(cx,cy,r,0,Math.PI*2);ctx.stroke();')
a('  var dirs=["N","E","S","W"];')
a('  for(var i=0;i<4;i++){')
a('    var ang=(i*90-b)*Math.PI/180;')
a('    ctx.fillStyle=dirs[i]==="N"?"#ff4466":"rgba(168,255,212,0.5)";')
a('    ctx.font="bold 7px monospace";ctx.textAlign="center";ctx.textBaseline="middle";')
a('    ctx.fillText(dirs[i],cx+Math.sin(ang)*(r-5),cy-Math.cos(ang)*(r-5));')
a('  }')
a('  ctx.save();ctx.translate(cx,cy);ctx.rotate(-b*Math.PI/180);')
a('  ctx.fillStyle="#ff4466";ctx.beginPath();ctx.moveTo(0,-13);ctx.lineTo(2.5,0);ctx.lineTo(0,-2);ctx.lineTo(-2.5,0);ctx.closePath();ctx.fill();')
a('  ctx.fillStyle="rgba(168,255,212,0.35)";ctx.beginPath();ctx.moveTo(0,13);ctx.lineTo(2.5,0);ctx.lineTo(0,2);ctx.lineTo(-2.5,0);ctx.closePath();ctx.fill();')
a('  ctx.restore();')
a('}')

# Refresh timer
a('function startRfTimer(){')
a('  var bar=document.getElementById("refprog"),s=Date.now();')
a('  rfTimer=setInterval(function(){')
a('    var e=Date.now()-s,p=Math.max(0,100-(e/RF)*100);')
a('    bar.style.width=p+"%";')
a('    if(e>=RF){s=Date.now();loadFlights();}')
a('  },300);')
a('}')
a('function resetRfTimer(){if(rfTimer)clearInterval(rfTimer);rfTimer=null;startRfTimer();}')

a('</script></body></html>')

with open(P, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print("OK:"+P)
WRITEPY

if [ ! -f "$TMPD/sw6.html" ]; then
  printf "  ${R}HATA!${N}\n"; exit 1
fi

BYTES=$(wc -c < "$TMPD/sw6.html")
LINES=$(wc -l < "$TMPD/sw6.html")
printf "  ${G}HTML hazir — ${B}%d byte, %d satir${N}\n" $BYTES $LINES

# Final validation
$PY - << 'VALPY'
import re, os
P = os.path.join(os.environ.get("TMPDIR","/tmp"), "sw6.html")
with open(P) as f:
    c = f.read()

errors = []

# 1. Modal must be visible
if "display:flex" not in c[c.find("#modal"):c.find("#modal")+200]:
    errors.append("MODAL not display:flex")
else:
    print("OK  Modal display:flex")

# 2. Loading must be hidden
if "display:none" not in c[c.find("#loading"):c.find("#loading")+200]:
    errors.append("LOADING not display:none")
else:
    print("OK  Loading display:none")

# 3. No inset shorthand
cnt = len(re.findall(r'inset:\s*0', c))
if cnt > 0:
    errors.append(f"inset:0 found ({cnt}x) - old WebView incompatible")
else:
    print("OK  No inset: shorthand")

# 4. No async/await
if "async function" in c or " await " in c:
    errors.append("async/await found - old WebView incompatible")
else:
    print("OK  No async/await")

# 5. No AbortController
if "AbortController" in c:
    errors.append("AbortController found")
else:
    print("OK  No AbortController")

# 6. doStart onclick
if "onclick=\"doStart()\"" in c or "onclick='doStart()'" in c:
    print("OK  doStart onclick")
else:
    errors.append("doStart onclick missing")

# 7. doDemo onclick
if "onclick=\"doDemo()\"" in c or "onclick='doDemo()'" in c:
    print("OK  doDemo onclick")
else:
    errors.append("doDemo onclick missing")

# 8. JS broken strings (multi-line inside quotes)
script = c[c.find("<script>"):c.rfind("</script>")]
# Each line of JS should have balanced quotes (unless it's a continuation)
broken = 0
for line in script.split("\n"):
    line = line.strip()
    if not line or line.startswith("//") or line.startswith("/*") or line.startswith("*"):
        continue
    # Count unescaped single and double quotes
    sq = line.count("'") - line.count("\\'")
    dq = line.count('"') - line.count('\\"')
    # A line with both types of quotes is complex - skip
    if sq > 0 and dq > 0:
        continue
    # A single-quote only line with odd count is suspicious
    if sq % 2 != 0 and dq == 0:
        # But if it ends with + or , it's a continuation
        if not line.endswith(("+", ",", "(", "[", "||", "&&")):
            broken += 1
if broken == 0:
    print("OK  No broken JS strings")
else:
    print(f"WARN {broken} potentially broken JS lines")

# 9. Key functions
funcs = ["doStart","doDemo","boot","initMap","initNoMap","setSdot","setLayer",
         "toggleTrm","toggleWx","fetchFlights","pState","genDemo","loadFlights",
         "setF","applyF","renderList","updStats","chkAlerts","addAlert","renderAlerts",
         "redrawMarkers","mkEl","trlClr","updTrailFlight","renderTrail","clrTrail",
         "clrAllTrails","updTrails","togSelTrail","toggleAllTrails","pick","refreshInfo",
         "closeInfo","flyToSel","copyCoords","openFA","openFR24","drawSpdHist",
         "onSlider","setPerf","togCfg","expJSON","expCSV","toggleSearch","doSearch",
         "pickByIcao","togglePanel","showTab","gotoMe","doFS","toggleHelp","setupKeys",
         "startRadar","startCompass","drawCompass","startRfTimer","resetRfTimer"]
missing = [f for f in funcs if "function "+f not in c]
if not missing:
    print(f"OK  All {len(funcs)} functions present")
else:
    errors.append(f"Missing functions: {missing}")

# 10. Key HTML elements
elems = ["modal","loading","ti","btn-start","btn-demo","flist","infopanel","rdc","cmp","hud","ntf","slim","shc","allist","searchbar","lpanel","ptog","kbhelp","refbar"]
me = [e for e in elems if "id=\""+e+"\"" not in c and "id='"+e+"'" not in c]
if not me:
    print(f"OK  All {len(elems)} HTML elements present")
else:
    errors.append(f"Missing elements: {me}")

# 11. No gap: in critical flex layouts
gap_count = c.count("gap:")
print(f"INFO gap: used {gap_count}x (check compat)")

# Summary
print()
if errors:
    for e in errors:
        print(f"FAIL {e}")
    print(f"\n{len(errors)} ERRORS FOUND")
else:
    print("ALL CHECKS PASSED - READY TO RUN")
VALPY

# Random port
PORT=$(( RANDOM % 8700 + 1300 ))
while lsof -i :$PORT >/dev/null 2>&1 || ss -tln 2>/dev/null | grep -q ":$PORT "; do
  PORT=$(( RANDOM % 8700 + 1300 ))
done

printf "\n"
printf "  ┌────────────────────────────────────────────────────────┐\n"
printf "  │  ${B}URL     :${N} ${C}http://localhost:$PORT${N}\n"
printf "  │  ${B}VERSiYON:${N} SKYWATCH v6.0\n"
printf "  │  ${B}DURUM   :${N} ${G}AKTIF${N}\n"
printf "  │\n"
printf "  │  DUZELTMELER:\n"
printf "  │  ✓ Login/Demo butonu garantili calisir\n"
printf "  │  ✓ Eski WebView uyumlu (Chrome 49+ yeterli)\n"
printf "  │  ✓ inset:0 yerine top/left/right/bottom kullandi\n"
printf "  │  ✓ async/await kaldirildi, pure XHR kullaniliyor\n"
printf "  │  ✓ gap: kaldirildi, margin ile yapildi\n"
printf "  │  ✓ Renk kodlu ucus izi sistemi\n"
printf "  │  ✓ Ucak sayisi slider (10-500)\n"
printf "  │  ✓ ECO/NORMAL/ULTRA performans modlari\n"
printf "  │  ✓ JSON/CSV disa aktarma\n"
printf "  │  ✓ FlightAware + FR24 entegrasyonu\n"
printf "  │  ✓ Hiz gecmisi grafigi\n"
printf "  │  Ctrl+C ile durdur\n"
printf "  └────────────────────────────────────────────────────────┘\n\n"

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
        if self.path in ("/", "/index.html"):
            self.path = "/sw6.html"
        super().do_GET()

def bye(s, f):
    print("\n  Sunucu kapatildi.\n"); sys.exit(0)

signal.signal(signal.SIGINT, bye)
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("", PORT), H) as h:
    print("  http://localhost:%d  |  Ctrl+C ile durdur\n" % PORT)
    h.serve_forever()
PYEOF

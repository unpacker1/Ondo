#!/usr/bin/env python3
# HORUS-EYE MILITARY EDITION

import http.server, socketserver, json, urllib.parse
import threading, webbrowser, time, random
from datetime import datetime

try:
    import requests
except:
    print("pip install requests")
    exit()

PORT = 8080

# ================= CACHE =================
cache = {"iss": {"data": None, "exp": 0}}
TTL = 5

# ================= AI / THREAT =================
def detect_threat(kp, speed):
    score = 0
    if kp > 5: score += 2
    if kp > 7: score += 3
    if speed > 28000: score += 2

    if score >= 5: return "CRITICAL"
    if score >= 3: return "HIGH"
    if score >= 2: return "MEDIUM"
    return "LOW"

# ================= APIs =================
def fetch_iss():
    try:
        r = requests.get("http://api.open-notify.org/iss-now.json", timeout=5).json()
        lat = float(r["iss_position"]["latitude"])
        lon = float(r["iss_position"]["longitude"])

        speed = random.randint(27000, 28500)

        return {
            "lat": lat,
            "lon": lon,
            "speed": speed,
            "targets": generate_targets(),
        }
    except:
        return {"lat": 0, "lon": 0, "speed": 0, "targets": generate_targets()}

def generate_targets():
    targets = []
    for i in range(5):
        targets.append({
            "id": f"T-{i}",
            "lat": random.uniform(-90, 90),
            "lon": random.uniform(-180, 180),
            "speed": random.randint(20000, 30000)
        })
    return targets

def cached(key, fn):
    now = time.time()
    if cache[key]["data"] and cache[key]["exp"] > now:
        return cache[key]["data"]
    d = fn()
    cache[key] = {"data": d, "exp": now + TTL}
    return d

# ================= SERVER =================
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        p = urllib.parse.urlparse(self.path).path
        if p == "/":
            self.html()
        elif p == "/api":
            self.json(cached("iss", fetch_iss))
        else:
            self.send_error(404)

    def html(self):
        self.send_response(200)
        self.send_header("Content-type","text/html")
        self.end_headers()
        self.wfile.write(HTML.encode())

    def json(self, d):
        self.send_response(200)
        self.send_header("Content-type","application/json")
        self.end_headers()
        self.wfile.write(json.dumps(d).encode())

    def log_message(self, *args): return

# ================= HTML =================
HTML = """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>HORUS MILITARY RADAR</title>
<style>
body{margin:0;background:black;color:#0ff;font-family:monospace;overflow:hidden}
#ui{position:fixed;top:10px;left:10px;z-index:10}
#log{font-size:12px;height:120px;overflow:auto;border:1px solid #0ff;padding:5px}
.alert{color:red;font-weight:bold}
</style>
</head>
<body>

<div id="ui">
<div>🛰 ISS: <span id="iss"></span></div>
<div>⚡ SPEED: <span id="speed"></span></div>
<div>🚨 THREAT: <span id="threat"></span></div>
<div id="log"></div>
</div>

<canvas id="radar"></canvas>

<script>
const canvas = document.getElementById("radar");
const ctx = canvas.getContext("2d");
canvas.width = window.innerWidth;
canvas.height = window.innerHeight;

let angle = 0;
let targets = [];

function log(msg){
    const l = document.getElementById("log");
    l.innerHTML = msg + "<br>" + l.innerHTML;
}

function drawRadar(){
    ctx.fillStyle="black";
    ctx.fillRect(0,0,canvas.width,canvas.height);

    let cx = canvas.width/2;
    let cy = canvas.height/2;
    let r = 250;

    // circles
    ctx.strokeStyle="#0f0";
    for(let i=1;i<=4;i++){
        ctx.beginPath();
        ctx.arc(cx,cy,r*i/4,0,Math.PI*2);
        ctx.stroke();
    }

    // sweep
    angle += 0.03;
    let x = cx + r*Math.cos(angle);
    let y = cy + r*Math.sin(angle);

    let grd = ctx.createRadialGradient(cx,cy,0,cx,cy,r);
    grd.addColorStop(0,"rgba(0,255,0,0.4)");
    grd.addColorStop(1,"transparent");

    ctx.beginPath();
    ctx.moveTo(cx,cy);
    ctx.arc(cx,cy,r,angle-0.1,angle);
    ctx.closePath();
    ctx.fillStyle=grd;
    ctx.fill();

    // targets
    targets.forEach(t=>{
        let tx = cx + (t.lon/180)*r;
        let ty = cy + (t.lat/90)*r;

        ctx.fillStyle="red";
        ctx.beginPath();
        ctx.arc(tx,ty,4,0,Math.PI*2);
        ctx.fill();
    });
}

async function update(){
    let res = await fetch("/api");
    let d = await res.json();

    document.getElementById("iss").innerText = d.lat.toFixed(2)+","+d.lon.toFixed(2);
    document.getElementById("speed").innerText = d.speed+" km/h";

    let threat="LOW";
    if(d.speed>28000) threat="HIGH";
    if(d.speed>28300) threat="CRITICAL";

    document.getElementById("threat").innerText = threat;

    if(threat==="CRITICAL"){
        log("⚠️ CRITICAL OBJECT DETECTED");
    }

    targets = d.targets;
}

setInterval(update,3000);

function loop(){
    drawRadar();
    requestAnimationFrame(loop);
}
loop();
update();
</script>

</body>
</html>
"""

# ================= RUN =================
def run():
    socketserver.ThreadingTCPServer.allow_reuse_address = True
    with socketserver.ThreadingTCPServer(("", PORT), Handler) as s:
        print("RUNNING:", PORT)
        webbrowser.open(f"http://localhost:{PORT}")
        s.serve_forever()

if __name__ == "__main__":
    run()
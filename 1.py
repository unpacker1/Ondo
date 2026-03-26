#!/usr/bin/env python3
# HORUS-EYE NEXT LEVEL RADAR

import http.server, socketserver, json, urllib.parse
import webbrowser, time, random, socket
from datetime import datetime

try:
    import requests
except:
    print("pip install requests")
    exit()

# ================= PORT =================
def find_port():
    while True:
        p = random.randint(2000,9000)
        with socket.socket() as s:
            if s.connect_ex(("127.0.0.1", p)) != 0:
                return p

PORT = find_port()

# ================= AI =================
def threat_ai(obj):
    score = 0

    if obj.get("velocity",0) > 300: score += 2
    if obj.get("altitude",0) > 10000: score += 2
    if obj.get("vertical_rate",0) > 15: score += 1

    if score >= 4: return "CRITICAL"
    if score >= 3: return "HIGH"
    if score >= 2: return "MEDIUM"
    return "LOW"

# ================= DATA =================
def get_iss():
    try:
        r = requests.get("http://api.open-notify.org/iss-now.json", timeout=5).json()
        return {
            "lat": float(r["iss_position"]["latitude"]),
            "lon": float(r["iss_position"]["longitude"])
        }
    except:
        return {"lat":0,"lon":0}

def get_planes():
    try:
        url="https://opensky-network.org/api/states/all"
        data=requests.get(url,timeout=5).json()

        planes=[]
        for s in data["states"][:20]:
            if s[5] and s[6]:
                obj={
                    "id": s[0],
                    "lat": s[6],
                    "lon": s[5],
                    "velocity": s[9] or 0,
                    "altitude": s[7] or 0,
                    "vertical_rate": s[11] or 0
                }
                obj["threat"]=threat_ai(obj)
                planes.append(obj)

        return planes
    except:
        return []

def get_data():
    return {
        "iss": get_iss(),
        "planes": get_planes(),
        "time": datetime.now().strftime("%H:%M:%S")
    }

# ================= SERVER =================
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        p = urllib.parse.urlparse(self.path).path

        if p=="/":
            self.send_response(200)
            self.send_header("Content-type","text/html")
            self.end_headers()
            self.wfile.write(HTML.encode())

        elif p=="/api":
            self.send_response(200)
            self.send_header("Content-type","application/json")
            self.end_headers()
            self.wfile.write(json.dumps(get_data()).encode())

        else:
            self.send_error(404)

    def log_message(self,*a): return

# ================= HTML =================
HTML="""
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>HORUS NEXT</title>
<style>
body{margin:0;background:black;color:#0f0;font-family:monospace}
#map{height:100vh}
.panel{position:absolute;top:10px;left:10px;background:black;padding:10px;border:1px solid #0f0}
.crit{color:red}
</style>

<link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css"/>
<script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
</head>
<body>

<div id="map"></div>

<div class="panel">
<div>🛰 ISS: <span id="iss"></span></div>
<div>✈️ Planes: <span id="count"></span></div>
</div>

<script>
let map=L.map('map').setView([20,0],2);

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);

let planeMarkers=[];
let issMarker=null;

async function update(){
 let r=await fetch("/api");
 let d=await r.json();

 document.getElementById("count").innerText=d.planes.length;

 // ISS
 if(issMarker) map.removeLayer(issMarker);
 issMarker=L.circleMarker([d.iss.lat,d.iss.lon],{color:"yellow"}).addTo(map);

 document.getElementById("iss").innerText=d.iss.lat.toFixed(2);

 // temizle
 planeMarkers.forEach(m=>map.removeLayer(m));
 planeMarkers=[];

 d.planes.forEach(p=>{
   let color="lime";
   if(p.threat=="HIGH") color="orange";
   if(p.threat=="CRITICAL") color="red";

   let m=L.circleMarker([p.lat,p.lon],{color:color})
     .addTo(map)
     .bindPopup("Speed:"+p.velocity+"<br>Threat:"+p.threat);

   planeMarkers.push(m);
 });
}

setInterval(update,5000);
update();
</script>

</body>
</html>
"""

# ================= RUN =================
def run():
    socketserver.ThreadingTCPServer.allow_reuse_address=True
    with socketserver.ThreadingTCPServer(("",PORT),H) as s:
        print("RUN:",PORT)
        webbrowser.open(f"http://localhost:{PORT}")
        s.serve_forever()

if __name__=="__main__":
    run()
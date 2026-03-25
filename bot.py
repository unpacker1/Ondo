import random
import threading
import time
import numpy as np
from datetime import datetime

from flask import Flask, render_template_string
from flask_socketio import SocketIO

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode="eventlet")

PORT = random.randint(2000, 9000)

# -------------------------
# DATA
# -------------------------
reactors = {
    f"RX{i}": {
        "temperature": float(np.random.uniform(100, 140)),
        "target": float(np.random.uniform(140, 180)),
        "stability": 0.0,
        "energy": 0.0,
        "history": [float(np.random.uniform(100, 140)) for _ in range(60)]
    } for i in range(1, 5)
}

logs = []
prev_error = {r: 0 for r in reactors}
integral = {r: 0 for r in reactors}

# -------------------------
# LOOP
# -------------------------
def loop():
    while True:
        for r, d in reactors.items():

            error = d["target"] - d["temperature"]

            Kp, Ki, Kd = 0.9, 0.01, 0.4

            integral[r] += error
            derivative = error - prev_error[r]

            control = (Kp * error) + (Ki * integral[r]) + (Kd * derivative)

            d["temperature"] += control * 0.05
            prev_error[r] = error

            d["temperature"] += np.random.uniform(-1.2, 1.2)

            d["stability"] = max(0, 100 - abs(d["temperature"] - d["target"]))
            d["energy"] = d["temperature"] * d["stability"] / 100

            d["history"].append(float(d["temperature"]))
            if len(d["history"]) > 60:
                d["history"].pop(0)

            if d["stability"] < 35:
                logs.append(f"{datetime.now().strftime('%H:%M:%S')} ⚠ {r} instability")

        if len(logs) > 100:
            logs.pop(0)

        socketio.emit("update", {"reactors": reactors, "logs": logs})
        time.sleep(1)

# -------------------------
# UI (FIXED TRIPLE QUOTES)
# -------------------------
HTML = """<!DOCTYPE html>
<html>
<head>
<title>NASA SCADA</title>

<script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<style>
body{margin:0;background:#000814;color:#00f0ff;font-family:Arial;}
.header{text-align:center;padding:10px;background:#001d3d;border-bottom:2px solid #00f0ff;}
.container{display:flex;}
.sidebar{width:180px;background:#001219;padding:10px;}
.sidebar button{width:100%;margin:5px 0;padding:8px;background:#00f0ff;border:none;cursor:pointer;}
.main{flex:1;padding:10px;}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:10px;}
.card{border:1px solid #00f0ff;padding:10px;border-radius:8px;background:#001219;}
.metric{font-size:22px;font-weight:bold;}
#status{text-align:center;color:lime;}
</style>
</head>

<body>

<div class="header">
<h2>🚀 NASA SCADA PANEL</h2>
<div id="status">Connecting...</div>
</div>

<div class="container">

<div class="sidebar">
<h3>Reactors</h3>
<div id="list"></div>
</div>

<div class="main">

<h3 id="selected">RX1</h3>

<div class="grid">
<div class="card">Temp <div class="metric" id="temp">0</div></div>
<div class="card">Target <div class="metric" id="target">0</div></div>
<div class="card">Stability <div class="metric" id="stab">0</div></div>
<div class="card">Energy <div class="metric" id="energy">0</div></div>
</div>

<canvas id="chart"></canvas>

<div class="card">
<h3>Logs</h3>
<div id="log" style="height:120px;overflow:auto;"></div>
</div>

</div>
</div>

<script>
const socket = io();
let selected = "RX1";

socket.on("connect", ()=>{
    document.getElementById("status").innerText = "CONNECTED";
});

socket.on("disconnect", ()=>{
    document.getElementById("status").innerText = "DISCONNECTED";
});

function select(r){
    selected = r;
    document.getElementById("selected").innerText = r;
}

let ctx = document.getElementById("chart").getContext("2d");

let chart = new Chart(ctx,{
    type:'line',
    data:{
        labels:Array.from({length:60}, (_,i)=>i),
        datasets:[{
            label:"Temperature",
            data:Array(60).fill(0),
            borderColor:"#00f0ff",
            fill:false
        }]
    },
    options:{animation:false}
});

socket.on("update",(data)=>{

    let list = document.getElementById("list");
    list.innerHTML = "";

    Object.keys(data.reactors).forEach(r=>{
        list.innerHTML += `<button onclick="select('${r}')">${r}</button>`;
    });

    let d = data.reactors[selected];
    if(!d) return;

    document.getElementById("temp").innerText = d.temperature.toFixed(1);
    document.getElementById("target").innerText = d.target.toFixed(1);
    document.getElementById("stab").innerText = d.stability.toFixed(1);
    document.getElementById("energy").innerText = d.energy.toFixed(1);

    if(d.history && d.history.length > 0){
        chart.data.datasets[0].data = d.history;
        chart.update();
    }

    document.getElementById("log").innerHTML = data.logs.join("<br>");
});
</script>

</body>
</html>
"""

@app.route("/")
def home():
    return render_template_string(HTML)

# -------------------------
# START
# -------------------------
if __name__ == "__main__":
    print(f"SC
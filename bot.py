import random
import threading
import time
import numpy as np
from datetime import datetime

from flask import Flask, render_template_string
from flask_socketio import SocketIO

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

PORT = random.randint(2000, 9000)

reactors = {
    f"RX{i}": {
        "temperature": np.random.uniform(100, 140),
        "target": np.random.uniform(140, 180),
        "auto": True,
        "stability": 0,
        "energy": 0,
        "history": []
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

            if d["auto"]:
                Kp = 0.9
                Ki = 0.01
                Kd = 0.4

                integral[r] += error
                derivative = error - prev_error[r]

                control = (Kp * error) + (Ki * integral[r]) + (Kd * derivative)

                d["temperature"] += control * 0.05

                prev_error[r] = error

            d["temperature"] += np.random.uniform(-1, 1)

            d["stability"] = max(0, 100 - abs(d["temperature"] - d["target"]))
            d["energy"] = d["temperature"] * d["stability"] / 100

            d["history"].append(d["temperature"])
            if len(d["history"]) > 60:
                d["history"].pop(0)

            if d["stability"] < 30:
                logs.append(f"{datetime.now().strftime('%H:%M:%S')} {r} WARNING")

        if len(logs) > 100:
            logs.pop(0)

        socketio.emit("update", {"reactors": reactors, "logs": logs})
        time.sleep(1)

# -------------------------
# NASA UI
# -------------------------
HTML = """
<!DOCTYPE html>
<html>
<head>
<title>NASA Mission Control</title>

<script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<style>
body{
    margin:0;
    background:#000814;
    color:#00f0ff;
    font-family:Arial;
}

/* header */
.header{
    text-align:center;
    padding:10px;
    background:#001d3d;
    border-bottom:2px solid #00f0ff;
}

/* layout */
.container{
    display:flex;
}

/* sidebar */
.sidebar{
    width:180px;
    background:#001219;
    padding:10px;
    border-right:1px solid #00f0ff;
}

.sidebar button{
    width:100%;
    margin:5px 0;
    padding:8px;
    background:#00f0ff;
    border:none;
    cursor:pointer;
    font-weight:bold;
}

/* main */
.main{
    flex:1;
    padding:10px;
}

/* cards */
.grid{
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(220px,1fr));
    gap:10px;
}

.card{
    border:1px solid #00f0ff;
    padding:10px;
    border-radius:8px;
    background:#001219;
}

/* metrics */
.metric{
    font-size:22px;
    font-weight:bold;
}

/* alarms */
.ok{color:lime;}
.warn{color:orange;}
</style>
</head>

<body>

<div class="header">
<h2>🚀 NASA MISSION CONTROL</h2>
</div>

<div class="container">

<div class="sidebar">
<h3>Reactor</h3>
<div id="list"></div>
</div>

<div class="main">

<h3 id="selected">RX1</h3>

<div class="grid">

<div class="card">
Temperature
<div class="metric" id="temp"></div>
</div>

<div class="card">
Target
<div class="metric" id="target"></div>
</div>

<div class="card">
Stability
<div class="metric" id="stab"></div>
</div>

<div class="card">
Energy
<div class="metric" id="energy"></div>
</div>

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
let chartData = [];

function select(r){
    selected = r;
    document.getElementById("selected").innerText = r;
}

socket.on("update",(data)=>{

    let list = document.getElementById("list");
    list.innerHTML = "";

    Object.keys(data.reactors).forEach(r=>{
        list.innerHTML += `<button onclick="select('${r}')">${r}</button>`;
    });

    let d = data.reactors[selected];

    if(d){
        document.getElementById("temp").innerText = d.temperature.toFixed(1);
        document.getElementById("target").innerText = d.target.toFixed(1);
        document.getElementById("stab").innerText = d.stability.toFixed(1);
        document.getElementById("energy").innerText = d.energy.toFixed(1);

        chartData = d.history;
    }

    document.getElementById("log").innerHTML = data.logs.join("<br>");

    chart.data.datasets[0].data = chartData;
    chart.update();
});

let ctx = document.getElementById("chart").getContext("2d");

let chart = new Chart(ctx,{
    type:'line',
    data:{
        labels:Array(60).fill(""),
        datasets:[{
            label:"Temperature",
            data:[],
            borderColor:"#00f0ff",
            fill:false
        }]
    },
    options:{animation:false}
});
</script>

</body>
</html>
"""

@app.route("/")
def home():
    return render_template_string(HTML)

# -------------------------
# LOOP START
# -------------------------
if __name__ == "__main__":
    print(f"NASA UI running on http://127.0.0.1:{PORT}")
    threading.Thread(target=loop, daemon=True).start()
    socketio.run(app, host="0.0.0.0", port=PORT)
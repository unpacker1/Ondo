import random
import threading
import time
import numpy as np
from datetime import datetime

from flask import Flask, render_template_string
from flask_socketio import SocketIO

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

# -------------------------
# RANDOM PORT
# -------------------------
PORT = random.randint(2000, 9000)

# -------------------------
# SYSTEM STATE
# -------------------------
reactors = {
    f"RX{i}": {
        "temperature": np.random.uniform(100, 140),
        "target": np.random.uniform(140, 180),
        "stability": 0,
        "energy": 0,
        "auto": True,
        "history": []
    } for i in range(1, 5)
}

logs = []

prev_error = {r: 0 for r in reactors}
integral = {r: 0 for r in reactors}

# -------------------------
# CONTROL LOOP
# -------------------------
def control_loop():
    while True:
        for r, d in reactors.items():

            error = d["target"] - d["temperature"]

            # PID-like AI control
            Kp = 0.8
            Ki = 0.01
            Kd = 0.4

            integral[r] += error
            derivative = error - prev_error[r]

            control = (Kp * error) + (Ki * integral[r]) + (Kd * derivative)

            if d["auto"]:
                d["temperature"] += control * 0.05

            prev_error[r] = error

            # natural fluctuation
            d["temperature"] += np.random.uniform(-1.2, 1.2)

            # stability
            d["stability"] = max(0, 100 - abs(d["temperature"] - d["target"]))

            # energy
            d["energy"] = d["temperature"] * d["stability"] / 100

            # logging
            if d["stability"] < 30:
                logs.append(f"{datetime.now().strftime('%H:%M:%S')} {r} WARNING LOW STABILITY")

            # history
            d["history"].append(d["temperature"])
            if len(d["history"]) > 60:
                d["history"].pop(0)

        if len(logs) > 80:
            logs.pop(0)

        socketio.emit("update", {"reactors": reactors, "logs": logs})
        time.sleep(1)

# -------------------------
# UI
# -------------------------
HTML = """
<!DOCTYPE html>
<html>
<head>
<title>Ultra Control Panel</title>
<script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<style>
body{
    margin:0;
    background:#05070f;
    color:#0ff;
    font-family:monospace;
}
.header{
    text-align:center;
    padding:10px;
    border-bottom:1px solid #0ff;
}
.grid{
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(220px,1fr));
    gap:10px;
    padding:10px;
}
.card{
    border:1px solid #0ff;
    padding:10px;
    border-radius:10px;
}
.ok{color:lime;}
.warn{color:orange;}
canvas{
    background:#000;
}
#log{
    height:150px;
    overflow:auto;
    border-top:1px solid #0ff;
    padding:10px;
}
</style>
</head>

<body>

<div class="header">
<h2>🚀 Ultra Control Panel</h2>
</div>

<div class="grid" id="grid"></div>

<canvas id="chart"></canvas>

<div id="log"></div>

<script>
const socket = io();
let selected = "RX1";
let chartData = [];

socket.on("update",(data)=>{
    let grid = document.getElementById("grid");
    grid.innerHTML = "";

    Object.keys(data.reactors).forEach(r=>{
        let d = data.reactors[r];

        let cls = d.stability > 60 ? "ok" : "warn";

        grid.innerHTML += `
        <div class="card">
            <h3>${r}</h3>
            <p>Temp: ${d.temperature.toFixed(1)}</p>
            <p>Target: ${d.target.toFixed(1)}</p>
            <p class="${cls}">Stability: ${d.stability.toFixed(1)}</p>
            <p>Energy: ${d.energy.toFixed(1)}</p>
        </div>
        `;

        if(r === selected){
            chartData = d.history;
        }
    });

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
            borderColor:"cyan",
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
# START
# -------------------------
if __name__ == "__main__":
    print(f"\n🚀 Server starting...")
    print(f"🌐 Random Port: {PORT}")
    print(f"🔗 Local: http://127.0.0.1:{PORT}")
    print(f"🔗 Network: http://0.0.0.0:{PORT}\n")

    threading.Thread(target=control_loop, daemon=True).start()
    socketio.run(app, host="0.0.0.0", port=PORT)
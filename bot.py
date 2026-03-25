from flask import Flask, render_template_string
from flask_socketio import SocketIO
import threading, time
import numpy as np
from datetime import datetime

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

# --- Physical constants ---
AMBIENT = 25
DT = 0.1
K_LOSS = 0.02

# --- reactors ---
reactors = {
    f"RX{i}": {
        "T": np.random.uniform(100,140),
        "target": np.random.uniform(140,180),
        "Q_in": 0,
        "stability": 0,
        "anomaly_score": 0,
        "auto": True,
        "history": []
    } for i in range(1,5)
}

logs = []

# --- AI anomaly model (simple heuristic AI) ---
def anomaly_score(T, target):
    return abs(T - target) / target

# --- AI controller (adaptive) ---
def ai_control(error):
    return (0.8 * error) + (0.01 * error**2)

# --- physics simulation loop ---
def simulate():
    while True:
        for r, d in reactors.items():

            T = d["T"]
            target = d["target"]

            # heat loss
            Q_loss = K_LOSS * (T - AMBIENT)

            # error
            error = target - T

            # AI control input
            control = ai_control(error) if d["auto"] else 0

            # heat input
            Q_in = control

            # physics update
            T_next = T + (Q_in - Q_loss) * DT

            d["T"] = T_next

            # stability
            d["stability"] = max(0, 100 - abs(T_next - target))

            # anomaly
            d["anomaly_score"] = anomaly_score(T_next, target)

            if d["anomaly_score"] > 0.5:
                logs.append(f"{datetime.now().strftime('%H:%M:%S')} {r} anomaly high")

            # history
            d["history"].append(T_next)
            if len(d["history"]) > 60:
                d["history"].pop(0)

        if len(logs) > 80:
            logs.pop(0)

        socketio.emit("update", {"reactors":reactors,"logs":logs})
        time.sleep(0.5)

# --- UI ---
HTML = """
<!DOCTYPE html>
<html>
<head>
<title>Ultra Physics AI Twin</title>
<script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<style>
body{background:#000;color:#0ff;font-family:monospace;}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:10px;padding:10px;}
.card{border:1px solid #0ff;padding:10px;}
.warn{color:orange;}
.crit{color:red;}
.ok{color:lime;}
canvas{background:#001;}
#log{height:150px;overflow:auto;border-top:1px solid #0ff;padding:10px;}
</style>
</head>

<body>

<h2 style="text-align:center;">🚀 Ultra Physics AI Digital Twin</h2>

<div class="grid" id="grid"></div>

<canvas id="chart"></canvas>

<div id="log"></div>

<script>
const socket = io();
let selected="RX1";
let chartData=[];

socket.on("update",(data)=>{
    let grid=document.getElementById("grid");
    grid.innerHTML="";

    Object.keys(data.reactors).forEach(r=>{
        let d=data.reactors[r];

        let cls = d.anomaly_score>0.5 ? "crit" : d.anomaly_score>0.2 ? "warn":"ok";

        grid.innerHTML += `
        <div class="card">
            <h3>${r}</h3>
            <p>Temp: ${d.T.toFixed(2)}</p>
            <p>Target: ${d.target.toFixed(1)}</p>
            <p class="${cls}">Anomaly: ${d.anomaly_score.toFixed(2)}</p>
            <p>Stability: ${d.stability.toFixed(1)}</p>
        </div>
        `;

        if(r===selected){
            chartData=d.history;
        }
    });

    document.getElementById("log").innerHTML=data.logs.join("<br>");
    chart.data.datasets[0].data=chartData;
    chart.update();
});

let ctx=document.getElementById("chart").getContext("2d");

let chart=new Chart(ctx,{
    type:"line",
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

# start system
if __name__ == "__main__":
    threading.Thread(target=simulate, daemon=True).start()
    socketio.run(app, host="0.0.0.0", port=5000)
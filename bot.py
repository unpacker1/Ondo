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
# INITIAL DATA (IMPORTANT FIX)
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
# SIMULATION LOOP
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
# UI
# -------------------------
HTML = """
<!DOCTYPE html>
<html>
<head>
<title>NASA SCADA FIXED</title>

<script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<style>
body{
    margin:0;
    background:#000814;
    color:#00f0ff;
    font-family:Arial;
}

.header{
    text-align:center;
    padding:10px;
    background:#001d3d;
    border-bottom:2px solid #00f0ff;
}

.container{display:flex;}

.sidebar{
    width:180px;
    background:#001219;
    padding:10px;
}

.sidebar button{
    width:100%;
    margin:5px 0;
    padding:8px;
    background:#00f0ff;
    border:none;
    cursor:pointer;
}

.main{flex:1;padding:10px;}

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

.metric{
    font-size:22px;
    font-weight:bold;
}

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
<div
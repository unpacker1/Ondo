import random
import threading
import time
import numpy as np
from flask import Flask, render_template_string
from flask_socketio import SocketIO

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode="eventlet")

PORT = random.randint(2000, 9000)

# ---------------- DATA ----------------
reactors = {
    "RX1": {"temp": 120.0, "target": 150.0, "history": [120.0]*50},
    "RX2": {"temp": 110.0, "target": 140.0, "history": [110.0]*50},
}

# ---------------- LOOP ----------------
def loop():
    while True:
        for r in reactors:
            d = reactors[r]

            error = d["target"] - d["temp"]
            d["temp"] += error * 0.05
            d["temp"] += np.random.uniform(-0.5, 0.5)

            d["history"].append(float(d["temp"]))
            if len(d["history"]) > 50:
                d["history"].pop(0)

        socketio.emit("update", reactors)
        time.sleep(1)

# ---------------- UI ----------------
HTML = """<!DOCTYPE html>
<html>
<head>
<script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>

<body style="background:black;color:cyan;font-family:Arial;">

<h2>SCADA PANEL</h2>

<select id="reactor" onchange="changeReactor()">
  <option value="RX1">RX1</option>
  <option value="RX2">RX2</option>
</select>

<p>Temp: <span id="temp">0</span></p>
<p>Target: <span id="target">0</span></p>

<canvas id="chart"></canvas>

<script>
const socket = io();
let selected = "RX1";

let ctx = document.getElementById("chart").getContext("2d");

let chart = new Chart(ctx, {
    type: 'line',
    data: {
        labels: Array(50).fill(""),
        datasets: [{
            label: "Temp",
            data: [],
            borderColor: "cyan",
            fill: false
        }]
    }
});

function changeReactor(){
    selected = document.getElementById("reactor").value;
}

socket.on("update", (data)=>{
    let d = data[selected];

    if(!d) return;

    document.getElementById("temp").innerText = d.temp.toFixed(1);
    document.getElementById("target").innerText = d.target.toFixed(1);

    chart.data.datasets[0].data = d.history;
    chart.update();
});
</script>

</body>
</html>
"""

@app.route("/")
def home():
    return render_template_string(HTML)

# ---------------- START ----------------
if __name__ == "__main__":
    print(f"Running on http://127.0.0.1:{PORT}")
    threading.Thread(target=loop, daemon=True).start()
    socketio.run(app, host="0.0.0.0", port=PORT)
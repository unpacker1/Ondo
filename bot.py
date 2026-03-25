from flask import Flask, jsonify, request, render_template_string
import threading
import time
import numpy as np

app = Flask(__name__)

plasma = {
    "temperature": 100,
    "stability": 50,
    "energy": 0,
    "auto_mode": True
}

# --- AI Kontrol (basit dengeleme algoritması) ---
def ai_control():
    target_temp = 150

    while True:
        if plasma["auto_mode"]:
            # sıcaklığı hedefe yaklaştır
            diff = target_temp - plasma["temperature"]

            adjustment = diff * 0.1  # kontrol katsayısı
            plasma["temperature"] += adjustment

        # doğal dalgalanma
        plasma["temperature"] += np.random.uniform(-2, 2)

        # stabilite hesapla
        plasma["stability"] = max(0, 100 - abs(plasma["temperature"] - 150))

        # enerji üretimi
        plasma["energy"] = plasma["temperature"] * plasma["stability"] / 100

        time.sleep(1)

# --- Web Panel ---
HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>Plazma Kontrol Paneli</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body style="background:#111;color:#fff;font-family:Arial;text-align:center;">

<h1>🔥 Plazma Reaktör Paneli</h1>

<p>Sıcaklık: <span id="temp"></span></p>
<p>Stabilite: <span id="stab"></span></p>
<p>Enerji: <span id="energy"></span></p>

<button onclick="control('increase')">➕ Isı Artır</button>
<button onclick="control('decrease')">➖ Isı Azalt</button>
<button onclick="toggleAuto()">🤖 Auto Mode</button>

<canvas id="chart" width="400" height="200"></canvas>

<script>
let tempData = [];

async function fetchData(){
    let res = await fetch('/data');
    let data = await res.json();

    document.getElementById('temp').innerText = data.temperature.toFixed(2);
    document.getElementById('stab').innerText = data.stability.toFixed(2);
    document.getElementById('energy').innerText = data.energy.toFixed(2);

    tempData.push(data.temperature);
    if(tempData.length > 20) tempData.shift();

    chart.data.datasets[0].data = tempData;
    chart.update();
}

setInterval(fetchData, 1000);

// kontrol butonları
function control(action){
    fetch('/control', {
        method:'POST',
        headers:{'Content-Type':'application/json'},
        body: JSON.stringify({action:action})
    });
}

function toggleAuto(){
    fetch('/toggle_auto', {method:'POST'});
}

// grafik
let ctx = document.getElementById('chart').getContext('2d');
let chart = new Chart(ctx, {
    type: 'line',
    data: {
        labels: Array(20).fill(""),
        datasets: [{
            label: 'Temperature',
            data: [],
            borderColor: 'cyan',
            fill: false
        }]
    },
    options: {
        scales: {
            y: { beginAtZero: true }
        }
    }
});
</script>

</body>
</html>
"""

@app.route("/")
def home():
    return render_template_string(HTML)

@app.route("/data")
def data():
    return jsonify(plasma)

@app.route("/control", methods=["POST"])
def control():
    action = request.json.get("action")

    if action == "increase":
        plasma["temperature"] += 20
    elif action == "decrease":
        plasma["temperature"] -= 20

    return jsonify({"status": "ok"})

@app.route("/toggle_auto", methods=["POST"])
def toggle_auto():
    plasma["auto_mode"] = not plasma["auto_mode"]
    return jsonify({"auto_mode": plasma["auto_mode"]})

if __name__ == "__main__":
    threading.Thread(target=ai_control, daemon=True).start()
    app.run(host="0.0.0.0", port=5000)
from flask import Flask, render_template_string, jsonify
import random
import threading
import time
import requests

app = Flask(__name__)

# -----------------------------
# Live data store
# -----------------------------
data_store = {
    "values": [],
    "weather": {}
}

# -----------------------------
# Random chart data generator
# -----------------------------
def generate_data():
    while True:
        new_value = random.randint(0, 100)
        if len(data_store["values"]) > 50:
            data_store["values"].pop(0)
        data_store["values"].append(new_value)
        time.sleep(1)

# -----------------------------
# Live weather fetch
# -----------------------------
def fetch_weather():
    while True:
        try:
            url = "https://wttr.in/Kayseri?format=j1"
            res = requests.get(url, timeout=5)
            data = res.json()

            current = data["current_condition"][0]

            data_store["weather"] = {
                "temp_C": current["temp_C"],
                "feelslike_C": current["FeelsLikeC"],
                "humidity": current["humidity"],
                "description": current["weatherDesc"][0]["value"]
            }

        except Exception as e:
            data_store["weather"] = {"error": str(e)}

        time.sleep(60)


threading.Thread(target=generate_data, daemon=True).start()
threading.Thread(target=fetch_weather, daemon=True).start()

# -----------------------------
# UI
# -----------------------------
HTML_PAGE = """
<!DOCTYPE html>
<html>
<head>
    <title>Termux Control Panel</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/three@0.158.0/build/three.min.js"></script>

    <style>
        body {
            background: #0f172a;
            color: #e2e8f0;
            font-family: Arial;
            text-align: center;
            margin: 0;
        }
        .container {
            display: grid;
            gap: 20px;
            padding: 20px;
        }
        .card {
            background: #1e293b;
            padding: 20px;
            border-radius: 12px;
        }
        #map3d {
            width: 100%;
            height: 400px;
        }
    </style>
</head>
<body>

<h1>Termux Live Control Panel</h1>

<div class="container">

    <div class="card">
        <h3>Canlı Grafik</h3>
        <canvas id="chart"></canvas>
    </div>

    <div class="card">
        <h3>🌤️ Hava Durumu</h3>
        <div id="weather">Yükleniyor...</div>
    </div>

    <div class="card">
        <h3>3D Map</h3>
        <div id="map3d"></div>
    </div>

</div>

<script>
    const ctx = document.getElementById('chart').getContext('2d');

    const chart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Live Data',
                data: [],
                borderWidth: 2,
                fill: false
            }]
        },
        options: {
            responsive: true,
            animation: false
        }
    });

    async function fetchData() {
        const res = await fetch('/data');
        const json = await res.json();

        // chart update
        chart.data.labels = json.values.map((_, i) => i);
        chart.data.datasets[0].data = json.values;
        chart.update();

        // weather update
        const w = json.weather;
        if (w && !w.error) {
            document.getElementById("weather").innerHTML =
                "Sıcaklık: " + w.temp_C + "°C<br>" +
                "Hissedilen: " + w.feelslike_C + "°C<br>" +
                "Nem: " + w.humidity + "%<br>" +
                "Durum: " + w.description;
        } else if (w.error) {
            document.getElementById("weather").innerText = "Hata: " + w.error;
        }
    }

    setInterval(fetchData, 5000);

    // ---------------- 3D Globe ----------------
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, window.innerWidth / 400, 0.1, 1000);

    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, 400);
    document.getElementById("map3d").appendChild(renderer.domElement);

    const geometry = new THREE.SphereGeometry(5, 32, 32);
    const texture = new THREE.TextureLoader().load('https://threejs.org/examples/textures/land_ocean_ice_cloud_2048.jpg');
    const material = new THREE.MeshBasicMaterial({ map: texture });
    const sphere = new THREE.Mesh(geometry, material);

    scene.add(sphere);
    camera.position.z = 10;

    function animate() {
        requestAnimationFrame(animate);
        sphere.rotation.y += 0.002;
        renderer.render(scene, camera);
    }
    animate();
</script>

</body>
</html>
"""

@app.route("/")
def index():
    return render_template_string(HTML_PAGE)

@app.route("/data")
def get_data():
    return jsonify(data_store)

if __name__ == "__main__":
    port = random.randint(5000, 9000)
    print(f"Server running on http://127.0.0.1:{port}")
    app.run(host="0.0.0.0", port=port)
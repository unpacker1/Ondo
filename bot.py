from flask import Flask, Response, render_template_string, jsonify import random import threading import time

app = Flask(name)

-----------------------------

Simulated live data

-----------------------------

data_store = { "values": [] }

def generate_data(): while True: new_value = random.randint(0, 100) if len(data_store["values"]) > 50: data_store["values"].pop(0) data_store["values"].append(new_value) time.sleep(1)

threading.Thread(target=generate_data, daemon=True).start()

-----------------------------

UI (Single Page with Chart + 3D Map)

-----------------------------

HTML_PAGE = """

<!DOCTYPE html><html>
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
            grid-template-columns: 1fr;
            gap: 20px;
            padding: 20px;
        }
        .card {
            background: #1e293b;
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 0 20px rgba(0,0,0,0.4);
        }
        canvas {
            max-width: 100%;
        }
        #map3d {
            width: 100%;
            height: 400px;
        }
    </style>
</head>
<body><h1>Termux Live Control Panel</h1><div class="container"><div class="card">
    <canvas id="chart"></canvas>
</div>

<div class="card">
    <h3>3D Map</h3>
    <div id="map3d"></div>
</div>

</div><script>
    // ---------------- Chart ----------------
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

        chart.data.labels = json.values.map((_, i) => i);
        chart.data.datasets[0].data = json.values;
        chart.update();
    }

    setInterval(fetchData, 1000);

    // ---------------- 3D MAP (Three.js Globe) ----------------
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
</script></body>
</html>
"""-----------------------------

Routes

-----------------------------

@app.route("/") def index(): return render_template_string(HTML_PAGE)

@app.route("/data") def get_data(): return jsonify(data_store)

-----------------------------

Run server with random port

-----------------------------

if name == "main": port = random.randint(5000, 9000) print(f"Server running on http://127.0.0.1:{port}") app.run(host="0.0.0.0", port=port)
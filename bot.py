from flask import Flask, render_template_string, jsonify
import random
import threading
import time
import requests
import math

app = Flask(__name__)

# -----------------------------
# Weather store
# -----------------------------
data_store = {
    "weather": {}
}

# -----------------------------
# Weather fetch
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

threading.Thread(target=fetch_weather, daemon=True).start()

# -----------------------------
# UI
# -----------------------------
HTML_PAGE = """
<!DOCTYPE html>
<html>
<head>
    <title>Termux Control Panel</title>

    <script src="https://cdn.jsdelivr.net/npm/three@0.158.0/build/three.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/three@0.158.0/examples/js/controls/OrbitControls.js"></script>

    <style>
        body {
            background: #0f172a;
            color: #e2e8f0;
            font-family: Arial;
            margin: 0;
            text-align: center;
        }
        .container {
            padding: 20px;
            display: grid;
            gap: 20px;
        }
        .card {
            background: #1e293b;
            padding: 20px;
            border-radius: 12px;
        }
        #map3d {
            width: 100%;
            height: 600px;
        }
        #popup {
            position: absolute;
            background: #020617;
            padding: 10px;
            border-radius: 8px;
            display: none;
            pointer-events: none;
        }
    </style>
</head>
<body>

<h1>Termux Live Control Panel</h1>

<div class="container">

    <div class="card">
        <h3>🌤️ Hava Durumu</h3>
        <div id="weather">Yükleniyor...</div>
    </div>

    <div class="card">
        <h3>🌍 Google Earth Style 3D Map</h3>
        <div id="map3d"></div>
        <div id="popup"></div>
    </div>

</div>

<script>
    // ---------------- Weather ----------------
    async function fetchData() {
        const res = await fetch('/data');
        const json = await res.json();

        const w = json.weather;
        if (w && !w.error) {
            document.getElementById("weather").innerHTML =
                "Sıcaklık: " + w.temp_C + "°C<br>" +
                "Hissedilen: " + w.feelslike_C + "°C<br>" +
                "Nem: " + w.humidity + "%<br>" +
                "Durum: " + w.description;
        } else {
            document.getElementById("weather").innerText = "Hata";
        }
    }
    setInterval(fetchData, 5000);

    // ---------------- THREE JS ----------------
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, window.innerWidth / 600, 0.1, 1000);

    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, 600);
    document.getElementById("map3d").appendChild(renderer.domElement);

    const controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;

    const globe = new THREE.Mesh(
        new THREE.SphereGeometry(5, 64, 64),
        new THREE.MeshBasicMaterial({
            map: new THREE.TextureLoader().load(
                'https://threejs.org/examples/textures/land_ocean_ice_cloud_2048.jpg'
            )
        })
    );

    scene.add(globe);
    camera.position.z = 12;

    // ---------------- Marker Utils ----------------
    function latLonToVector3(lat, lon, radius) {
        const phi = (90 - lat) * Math.PI / 180;
        const theta = (lon + 180) * Math.PI / 180;

        return new THREE.Vector3(
            -radius * Math.sin(phi) * Math.cos(theta),
            radius * Math.cos(phi),
            radius * Math.sin(phi) * Math.sin(theta)
        );
    }

    // ---------------- Cities ----------------
    const cities = [
        { name: "Kayseri", lat: 38.7205, lon: 35.4826 },
        { name: "Istanbul", lat: 41.0082, lon: 28.9784 },
        { name: "Ankara", lat: 39.9334, lon: 32.8597 }
    ];

    const markers = [];

    const markerGeometry = new THREE.SphereGeometry(0.08, 16, 16);
    const markerMaterial = new THREE.MeshBasicMaterial({ color: 0xff0000 });

    cities.forEach(city => {
        const marker = new THREE.Mesh(markerGeometry, markerMaterial);
        marker.position.copy(latLonToVector3(city.lat, city.lon, 5));
        marker.userData = city;
        scene.add(marker);
        markers.push(marker);
    });

    // ---------------- Fly To ----------------
    function flyTo(target) {
        const start = camera.position.clone();
        const end = target.clone().multiplyScalar(2.5);

        let t = 0;

        function animateFly() {
            t += 0.02;
            if (t > 1) t = 1;

            camera.position.lerpVectors(start, end, t);
            camera.lookAt(0, 0, 0);

            if (t < 1) requestAnimationFrame(animateFly);
        }

        animateFly();
    }

    // ---------------- Click ----------------
    const raycaster = new THREE.Raycaster();
    const mouse = new THREE.Vector2();
    const popup = document.getElementById("popup");

    window.addEventListener("click", (event) => {

        mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
        mouse.y = -(event.clientY / 600) * 2 + 1;

        raycaster.setFromCamera(mouse, camera);

        const intersects = raycaster.intersectObjects(markers);

        if (intersects.length > 0) {
            const obj = intersects[0].object;
            const data = obj.userData;

            popup.style.display = "block";
            popup.style.left = event.clientX + "px";
            popup.style.top = event.clientY + "px";
            popup.innerHTML = data.name;

            flyTo(obj.position);
        } else {
            popup.style.display = "none";
        }
    });

    // ---------------- Animate ----------------
    function animate() {
        requestAnimationFrame(animate);
        globe.rotation.y += 0.001;
        controls.update();
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
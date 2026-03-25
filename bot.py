from flask import Flask,render_template_string,jsonify
import random
import time
import math

app = Flask(__name__)

# -----------------------------
# Fake ISS movement
# -----------------------------
def get_iss_position():
    t = time.time()
    lat = 20 * math.sin(t / 5)
    lon = (t * 10) % 360 - 180
    return {"lat": lat, "lon": lon}

# -----------------------------
# UI (Google Earth style control)
# -----------------------------
HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>3D Earth Control Panel</title>
    <style>
        body { margin: 0; overflow: hidden; background: black; }
        #panel {
            position: absolute;
            top: 10px;
            left: 10px;
            background: rgba(0,0,0,0.6);
            padding: 10px;
            color: white;
            font-family: Arial;
            border-radius: 8px;
        }
        button {
            margin: 3px;
            padding: 5px;
        }
    </style>
</head>
<body>

<div id="panel">
    <div>🧭 Controls</div>
    <button onclick="focusISS()">🎯 ISS Focus</button>
    <div id="status">Loading...</div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>

<script>
// Scene
const scene = new THREE.Scene();

// Camera
const camera = new THREE.PerspectiveCamera(75, window.innerWidth/window.innerHeight, 0.1, 1000);
camera.position.z = 2.5;

// Renderer
const renderer = new THREE.WebGLRenderer({antialias:true});
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

// Earth
const geometry = new THREE.SphereGeometry(1, 64, 64);
const texture = new THREE.TextureLoader().load("https://threejs.org/examples/textures/land_ocean_ice_cloud_2048.jpg");
const material = new THREE.MeshBasicMaterial({map: texture});
const earth = new THREE.Mesh(geometry, material);
scene.add(earth);

// ISS
const issGeometry = new THREE.SphereGeometry(0.02, 16, 16);
const issMaterial = new THREE.MeshBasicMaterial({color: 0xff0000});
const iss = new THREE.Mesh(issGeometry, issMaterial);
scene.add(iss);

// Convert lat/lon to 3D
function latLonToVector3(lat, lon, radius=1.01) {
    const phi = (90 - lat) * Math.PI / 180;
    const theta = (lon + 180) * Math.PI / 180;

    const x = -radius * Math.sin(phi) * Math.cos(theta);
    const y = radius * Math.cos(phi);
    const z = radius * Math.sin(phi) * Math.sin(theta);

    return new THREE.Vector3(x, y, z);
}

// Controls (mouse rotate)
let isDragging = false;
let prevX = 0;
let prevY = 0;

document.addEventListener("mousedown", () => isDragging = true);
document.addEventListener("mouseup", () => isDragging = false);

document.addEventListener("mousemove", (e) => {
    if (isDragging) {
        earth.rotation.y += (e.clientX - prevX) * 0.005;
        earth.rotation.x += (e.clientY - prevY) * 0.005;
    }
    prevX = e.clientX;
    prevY = e.clientY;
});

// Zoom
document.addEventListener("wheel", (e) => {
    camera.position.z += e.deltaY * 0.001;
    camera.position.z = Math.max(1.5, Math.min(5, camera.position.z));
});

// Focus ISS
function focusISS() {
    camera.position.z = 1.5;
}

// Fetch ISS position (optimized interval)
let issData = null;

async function updateISS() {
    const res = await fetch('/iss');
    issData = await res.json();

    document.getElementById("status").innerText =
        "ISS Lat: " + issData.lat.toFixed(2) + " Lon: " + issData.lon.toFixed(2);
}

setInterval(updateISS, 2000);

// Animation
function animate() {
    requestAnimationFrame(animate);

    earth.rotation.y += 0.001;

    if (issData) {
        const pos = latLonToVector3(issData.lat, issData.lon);
        iss.position.copy(pos);
    }

    renderer.render(scene, camera);
}

animate();
</script>

</body>
</html>
"""

@app.route("/")
def index():
    return render_template_string(HTML)

@app.route("/iss")
def iss():
    t = time.time()
    lat = 20 * math.sin(t / 5)
    lon = (t * 10) % 360 - 180
    return jsonify({"lat": lat, "lon": lon})

if __name__ == "__main__":
    port = random.randint(5000, 9000)
    print(f"Running on http://127.0.0.1:{port}")
    app.run(host="0.0.0.0", port=port)
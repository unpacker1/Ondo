from flask import Flask,render_template_string,jsonify
import random
import time
import math

app = Flask(__name__)

# ISS simulated data
def get_iss_position():
    t = time.time()
    lat = 20 * math.sin(t / 5)
    lon = (t * 10) % 360 - 180
    return {"lat": lat, "lon": lon}

# HTML PAGE
HTML = """<!DOCTYPE html>
<html>
<head>
    <title>3D Earth</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
        button { margin: 3px; padding: 6px; }
    </style>
</head>
<body>

<div id="panel">
    <div>Controls</div>
    <button onclick="focusISS()">Focus ISS</button>
    <div id="status">Loading...</div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>

<script>
const scene = new THREE.Scene();

const camera = new THREE.PerspectiveCamera(75, window.innerWidth/window.innerHeight, 0.1, 1000);
camera.position.z = 2.5;

const renderer = new THREE.WebGLRenderer({antialias:true});
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

// Earth
const geometry = new THREE.SphereGeometry(1, 64, 64);
const texture = new THREE.TextureLoader().load("https://threejs.org/examples/textures/land_ocean_ice_cloud_2048.jpg");
const material = new THREE.MeshBasicMaterial({map: texture});
const earth = new THREE.Mesh(geometry, material);
scene.add(earth);

// ISS marker
const issGeometry = new THREE.SphereGeometry(0.02, 16, 16);
const issMaterial = new THREE.MeshBasicMaterial({color: 0xff0000});
const iss = new THREE.Mesh(issGeometry, issMaterial);
scene.add(iss);

// Convert lat/lon
function latLonToVector3(lat, lon, radius=1.01) {
    const phi = (90 - lat) * Math.PI / 180;
    const theta = (lon + 180) * Math.PI / 180;

    return new THREE.Vector3(
        -radius * Math.sin(phi) * Math.cos(theta),
        radius * Math.cos(phi),
        radius * Math.sin(phi) * Math.sin(theta)
    );
}

// Mouse rotate
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

// Zoom (mouse)
document.addEventListener("wheel", (e) => {
    camera.position.z += e.deltaY * 0.001;
    camera.position.z = Math.max(1.5, Math.min(6, camera.position.z));
});

// Mobile pinch zoom
let lastTouchDistance = null;

function getTouchDistance(touches) {
    const dx = touches[0].clientX - touches[1].clientX;
    const dy = touches[0].clientY - touches[1].clientY;
    return Math.sqrt(dx*dx + dy*dy);
}

document.addEventListener("touchstart", (e) => {
    if (e.touches.length === 2) {
        lastTouchDistance = getTouchDistance(e.touches);
    }
});

document.addEventListener("touchmove", (e) => {
    if (e.touches.length === 2) {
        const currentDistance = getTouchDistance(e.touches);

        if (lastTouchDistance) {
            const delta = currentDistance - lastTouchDistance;
            camera.position.z -= delta * 0.005;
            camera.position.z = Math.max(1.2, Math.min(6, camera.position.z));
        }

        lastTouchDistance = currentDistance;
    }

    if (e.touches.length === 1) {
        const t = e.touches[0];
        earth.rotation.y += t.clientX * 0.0001;
        earth.rotation.x += t.clientY * 0.0001;
    }
});

// ISS focus
function focusISS() {
    camera.position.z = 1.5;
}

// Fetch ISS
let issData = null;

async function updateISS() {
    const res = await fetch('/iss');
    issData = await res.json();

    document.getElementById("status").innerText =
        "Lat: " + issData.lat.toFixed(2) + " Lon: " + issData.lon.toFixed(2);
}

setInterval(updateISS, 2000);

// Render
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
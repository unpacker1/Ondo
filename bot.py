from flask import Flask, render_template_string, jsonify
import random
import math

app = Flask(__name__)

# Basit ISS simülasyonu (örnek hareket)
def get_iss_position():
    t = time.time()
    lat = 20 * math.sin(t / 5)
    lon = (t * 10) % 360 - 180
    return {"lat": lat, "lon": lon}

HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>3D World</title>
    <style>
        body { margin: 0; overflow: hidden; background: black; }
        #info {
            position: absolute;
            top: 10px;
            left: 10px;
            color: white;
            font-family: Arial;
        }
    </style>
</head>
<body>
<div id="info">3D World Running</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>

<script>
// Scene
const scene = new THREE.Scene();

// Camera
const camera = new THREE.PerspectiveCamera(75, window.innerWidth/window.innerHeight, 0.1, 1000);
camera.position.z = 2;

// Renderer
const renderer = new THREE.WebGLRenderer({antialias:true});
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

// Earth texture
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

// Convert lat/lon to 3D position
function latLonToVector3(lat, lon, radius=1.01) {
    const phi = (90 - lat) * Math.PI / 180;
    const theta = (lon + 180) * Math.PI / 180;

    const x = -radius * Math.sin(phi) * Math.cos(theta);
    const y = radius * Math.cos(phi);
    const z = radius * Math.sin(phi) * Math.sin(theta);

    return new THREE.Vector3(x, y, z);
}

// Animation loop
async function animate() {
    requestAnimationFrame(animate);

    earth.rotation.y += 0.001;

    // fetch ISS position from backend
    const res = await fetch('/iss');
    const data = await res.json();

    const pos = latLonToVector3(data.lat, data.lon);
    iss.position.copy(pos);

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
    # Fake moving ISS
    t = time.time()
    lat = 20 * math.sin(t / 5)
    lon = (t * 10) % 360 - 180
    return jsonify({"lat": lat, "lon": lon})

if __name__ == "__main__":
    import time
    port = random.randint(5000, 9000)
    print(f"Running on http://127.0.0.1:{port}")
    app.run(host="0.0.0.0", port=port)
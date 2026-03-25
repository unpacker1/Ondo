from flask import Flask,render_template_string,jsonify
import random
import time
import math

app = Flask(__name__)

# -----------------------------
# Simulated satellites
# -----------------------------
satellites = [
    {"id": "ISS", "speed": 1.0, "radius": 1.02},
    {"id": "SAT-1", "speed": 0.8, "radius": 1.05},
    {"id": "SAT-2", "speed": 1.3, "radius": 1.08},
]

def get_sat_positions():
    t = time.time()
    results = []

    for sat in satellites:
        lat = 25 * math.sin(t * sat["speed"])
        lon = (t * 20 * sat["speed"]) % 360 - 180

        results.append({
            "id": sat["id"],
            "lat": lat,
            "lon": lon
        })

    return results

# -----------------------------
# HTML UI
# -----------------------------
HTML = """<!DOCTYPE html>
<html>
<head>
    <title>Satellite Control Panel</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { margin:0; overflow:hidden; background:black; }
        #panel {
            position:absolute;
            top:10px;
            left:10px;
            background:rgba(0,0,0,0.6);
            color:white;
            padding:10px;
            border-radius:8px;
            font-family:Arial;
        }
        button { margin:3px; padding:5px; }
    </style>
</head>
<body>

<div id="panel">
    <div>🛰️ Satellites</div>
    <div id="satList"></div>
    <div id="status"></div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>

<script>
// Scene
const scene = new THREE.Scene();

// Camera
const camera = new THREE.PerspectiveCamera(75, window.innerWidth/window.innerHeight, 0.1, 1000);
camera.position.z = 3;

// Renderer
const renderer = new THREE.WebGLRenderer({antialias:true});
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

// Earth
const earth = new THREE.Mesh(
    new THREE.SphereGeometry(1,64,64),
    new THREE.MeshBasicMaterial({
        map: new THREE.TextureLoader().load("https://threejs.org/examples/textures/land_ocean_ice_cloud_2048.jpg")
    })
);
scene.add(earth);

// Controls (improved)
let isDragging = false;
let prevX = 0;
let prevY = 0;

document.addEventListener("mousedown", () => isDragging = true);
document.addEventListener("mouseup", () => isDragging = false);

document.addEventListener("mousemove", (e) => {
    if (isDragging) {
        earth.rotation.y += (e.clientX - prevX) * 0.003;
        earth.rotation.x += (e.clientY - prevY) * 0.003;
    }
    prevX = e.clientX;
    prevY = e.clientY;
});

// Zoom
document.addEventListener("wheel", (e) => {
    camera.position.z += e.deltaY * 0.002;
    camera.position.z = Math.max(1.5, Math.min(8, camera.position.z));
});

// Touch pinch zoom
let lastTouchDistance = null;

function getTouchDistance(touches){
    const dx = touches[0].clientX - touches[1].clientX;
    const dy = touches[0].clientY - touches[1].clientY;
    return Math.sqrt(dx*dx + dy*dy);
}

document.addEventListener("touchstart", (e)=>{
    if(e.touches.length===2){
        lastTouchDistance = getTouchDistance(e.touches);
    }
});

document.addEventListener("touchmove",(e)=>{
    if(e.touches.length===2){
        const d = getTouchDistance(e.touches);
        if(lastTouchDistance){
            const delta = d - lastTouchDistance;
            camera.position.z -= delta * 0.004;
            camera.position.z = Math.max(1.5, Math.min(8, camera.position.z));
        }
        lastTouchDistance = d;
    }
});

// Satellite objects
const satMeshes = {};
const orbitLines = {};
const orbitPoints = {};
let selectedSat = null;

function latLonToVec(lat, lon, r=1.02){
    const phi = (90-lat)*Math.PI/180;
    const theta = (lon+180)*Math.PI/180;

    return new THREE.Vector3(
        -r * Math.sin(phi)*Math.cos(theta),
        r * Math.cos(phi),
        r * Math.sin(phi)*Math.sin(theta)
    );
}

// Create satellites dynamically
function createSat(id){
    const mesh = new THREE.Mesh(
        new THREE.SphereGeometry(0.02,16,16),
        new THREE.MeshBasicMaterial({color:0xff0000})
    );
    scene.add(mesh);

    satMeshes[id] = mesh;
    orbitPoints[id] = [];

    const lineGeo = new THREE.BufferGeometry();
    const lineMat = new THREE.LineBasicMaterial({color:0x00ffcc});
    const line = new THREE.Line(lineGeo, lineMat);

    orbitLines[id] = line;
    scene.add(line);
}

// UI list
function updateUI(sats){
    const list = document.getElementById("satList");
    list.innerHTML = "";

    sats.forEach(s=>{
        if(!satMeshes[s.id]) createSat(s.id);

        const btn = document.createElement("button");
        btn.innerText = "Track " + s.id;
        btn.onclick = ()=> selectedSat = s.id;
        list.appendChild(btn);
    });
}

// Fetch data
let satData = [];

async function fetchData(){
    const res = await fetch('/sats');
    satData = await res.json();
    updateUI(satData);
}

setInterval(fetchData, 2000);

// Render loop
function animate(){
    requestAnimationFrame(animate);

    earth.rotation.y += 0.001;

    satData.forEach(s=>{
        const pos = latLonToVec(s.lat, s.lon);

        satMeshes[s.id].position.copy(pos);

        orbitPoints[s.id].push(pos.clone());
        if(orbitPoints[s.id].length>150){
            orbitPoints[s.id].shift();
        }

        orbitLines[s.id].geometry.setFromPoints(orbitPoints[s.id]);
    });

    // follow selected satellite
    if(selectedSat){
        const p = satMeshes[selectedSat].position;
        camera.lookAt(p);
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

@app.route("/sats")
def sats():
    return jsonify(get_sat_positions())

if __name__ == "__main__":
    port = random.randint(5000, 9000)
    print(f"Running on http://127.0.0.1:{port}")
    app.run(host="0.0.0.0", port=port)
from flask import Flask,render_template_string,jsonify
import random
import time
import math

app = Flask(__name__)

# -----------------------------
# ISS position (simulated)
# -----------------------------
def get_iss_position():
    t = time.time()
    lat = 20 * math.sin(t / 5)
    lon = (t * 10) % 360 - 180
    return {"lat": lat, "lon": lon}

# -----------------------------
# HTML + Three.js UI
# -----------------------------
HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>3D Earth Mobile Control</title>
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
            padding: 6px;
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

// -----------------------------
// Desktop controls
// -----------------------------
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

// Mouse wheel zoom
document.addEventListener("wheel", (e) => {
    camera.position.z += e.deltaY * 0.001;
    camera.position.z = Math.max(1.5, Math.min(5, camera.position.z));
});

// -----------------------------
// Mobile touch controls
// -----------------------------
let lastTouchDistance = null;

function getTouchDistance(touches) {
    const dx = touches[0].clientX - touches[1].clientX;
    const dy = touches[0].clientY - touches[1].clientY;
    return Math.sqrt(dx * dx + dy * dy);
}

document.addEventListener("touchstart", (e) => {
    if (e.touches.length === 2) {
        lastTouchDistance = getTouchDistance(e.touches);
    }
});

document.addEventListener("touchmove", (e) => {
    // Pinch zoom
    if (e.touches.length === 2) {
        const currentDistance = getTouchDistance(e.touches);

        if (lastTouchDistance) {
            const delta = currentDistance - lastTouchDistance;

            camera.position.z -= delta * 0.005;
            camera.position.z = Math.max(1.2, Math.min(6, camera.position.z));
        }

        lastTouchDistance = currentDistance;
    }

    // Single finger rotate
    if (e.touches.length === 1) {
        const touch = e.touches[0];

        earth.rotation.y += touch.clientX * 0.0001;
        earth.rotation.x += touch.clientY * 0
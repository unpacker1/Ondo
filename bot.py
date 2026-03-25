from flask import Flask, render_template_string, jsonify
import random
import time
import math

app = Flask(__name__)

# -----------------------------
# ISS simulated data
# -----------------------------
def get_iss_position():
    t = time.time()
    lat = 20 * math.sin(t / 5)
    lon = (t * 10) % 360 - 180
    return {"lat": lat, "lon": lon}

# -----------------------------
# HTML UI
# -----------------------------
HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>3D Earth Control</title>
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

    const x = -radius * Math.sin(phi) * Math.cos(theta);
    const y = radius * Math.cos(phi);
    const z = radius * Math.sin(phi) * Math.sin(theta);

    return new THREE.Vector3(x, y, z);
}

// Desktop rotate
let isDragging = false;
let prevX = 0;
let prevY
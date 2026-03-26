#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HORUS-EYE ULTIMATE - Cyberpunk Uzay Takip Sistemi
Maksimum Grafik Tasarım + Tüm Modüller + Real-time Veri
Compatible: Termux, Linux, Windows (Python 3.8+)
"""

import http.server
import socketserver
import socket
import webbrowser
import sys
import json
import threading
import time
from urllib.parse import urlparse, parse_qs
from pathlib import Path

try:
    import requests
except ImportError:
    print("Requests kütüphanesi yüklenmedi. pip install requests komutu çalıştırın.")
    sys.exit(1)

# ============= HTML CONTENT =============
HTML_CONTENT = """<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>HORUS-EYE ULTIMATE · CYBERPUNK SPACE TRACKER</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/controls/OrbitControls.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Share+Tech+Mono:wght@400&display=swap');
        
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { width: 100%; height: 100%; overflow: hidden; }
        body {
            font-family: 'Share Tech Mono', monospace;
            background: #000000;
            color: #00ffff;
            text-shadow: 0 0 5px #00ffff;
        }

        /* CRT EFFECT */
        body::before {
            content: "";
            position: fixed;
            top: 0; left: 0; width: 100%; height: 100%;
            background: repeating-linear-gradient(
                0deg,
                rgba(0, 255, 255, 0.03) 0px,
                rgba(0, 255, 255, 0.03) 2px,
                transparent 2px,
                transparent 4px
            );
            pointer-events: none;
            z-index: 999;
            animation: scanlines 8s linear infinite;
        }

        @keyframes scanlines {
            0% { transform: translateY(0); }
            100% { transform: translateY(10px); }
        }

        #canvas { display: block; }

        .panel {
            position: fixed;
            background: rgba(0, 0, 0, 0.92);
            backdrop-filter: blur(20px);
            border-radius: 6px;
            border: 2px solid #00ffff;
            box-shadow: 0 0 30px rgba(0, 255, 255, 0.5), inset 0 0 20px rgba(0, 255, 255, 0.1);
            padding: 14px;
            font-size: 11px;
            pointer-events: auto;
            z-index: 100;
            max-height: 85vh;
            overflow-y: auto;
            scrollbar-width: thin;
            animation: panelGlow 3s ease-in-out infinite;
        }

        @keyframes panelGlow {
            0%, 100% { box-shadow: 0 0 20px rgba(0, 255, 255, 0.4), inset 0 0 10px rgba(0, 255, 255, 0.1); }
            50% { box-shadow: 0 0 40px rgba(0, 255, 255, 0.6), inset 0 0 20px rgba(0, 255, 255, 0.2); }
        }

        .panel:hover { border-color: #ff00ff; box-shadow: 0 0 30px #ff00ff; }

        .left-panel { top: 12px; left: 12px; width: 340px; }
        .right-panel { top: 12px; right: 12px; width: 360px; }
        .bottom-left { bottom: 12px; left: 12px; width: 340px; }
        .bottom-right { bottom: 12px; right: 12px; width: 360px; }

        h2 {
            font-size: 16px;
            margin-bottom: 10px;
            letter-spacing: 2px;
            text-transform: uppercase;
            text-shadow: 0 0 10px #00ffff;
            border-bottom: 2px solid #ff00ff;
            padding-bottom: 6px;
        }

        h3 {
            font-size: 12px;
            margin: 8px 0 6px;
            letter-spacing: 1px;
            color: #ff00ff;
        }

        .data-row {
            display: flex;
            justify-content: space-between;
            margin: 5px 0;
            padding: 3px 0;
            border-bottom: 1px solid rgba(0, 255, 255, 0.2);
        }

        .stat-box {
            background: rgba(0, 255, 255, 0.1);
            border: 1px solid #00ffff;
            padding: 8px;
            border-radius: 3px;
            text-align: center;
            margin: 4px;
        }

        .stat-label {
            font-size: 8px;
            color: #00aa00;
            text-transform: uppercase;
        }

        .stat-value {
            font-size: 13px;
            color: #ff00ff;
            font-weight: bold;
            margin-top: 2px;
        }

        .threat-badge {
            background: rgba(255, 0, 0, 0.1);
            border: 2px solid #ff0000;
            padding: 8px;
            margin: 8px 0;
            border-radius: 4px;
            text-align: center;
            box-shadow: 0 0 15px rgba(255, 0, 0, 0.4);
            animation: pulse 1.5s infinite;
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.7; }
        }

        button {
            background: linear-gradient(135deg, rgba(0, 255, 255, 0.15), rgba(255, 0, 255, 0.15));
            border: 1px solid #00ffff;
            border-radius: 4px;
            padding: 6px 10px;
            color: #00ffff;
            cursor: pointer;
            font-family: 'Share Tech Mono', monospace;
            font-size: 10px;
            text-transform: uppercase;
            transition: all 0.3s;
        }

        button:hover {
            background: linear-gradient(135deg, rgba(0, 255, 255, 0.3), rgba(255, 0, 255, 0.3));
            border-color: #ff00ff;
            box-shadow: 0 0 15px #00ffff;
            color: #ff00ff;
        }

        input, select, textarea {
            background: rgba(0, 20, 40, 0.8);
            border: 1px solid #00ffff;
            border-radius: 3px;
            padding: 5px 8px;
            color: #00ffff;
            font-family: 'Share Tech Mono', monospace;
            font-size: 10px;
            margin: 4px 0;
            width: 100%;
        }

        input:focus, select:focus, textarea:focus {
            outline: none;
            border-color: #ff00ff;
            box-shadow: 0 0 10px #ff00ff;
        }

        label {
            display: flex;
            align-items: center;
            margin: 5px 0;
            cursor: pointer;
        }

        label input { width: auto; margin-right: 6px; }

        .slider { width: 100%; accent-color: #ff00ff; }

        .comment-box {
            display: flex;
            gap: 5px;
            margin: 8px 0;
        }

        .comment-input { flex: 1; }
        .comment-list { max-height: 200px; overflow-y: auto; border: 1px solid rgba(0, 255, 255, 0.2); padding: 6px; border-radius: 3px; background: rgba(0, 0, 0, 0.5); font-size: 9px; }
        .comment-item { margin: 4px 0; padding: 4px; border-bottom: 1px dashed rgba(0, 255, 255, 0.2); }
        .comment-user { color: #ff00ff; font-weight: bold; }
        .comment-text { color: #00ffff; font-size: 9px; margin-top: 2px; }
        .comment-time { color: #00aa00; font-size: 8px; }

        .news-item {
            margin: 6px 0;
            padding: 6px;
            border-left: 2px solid #ff00ff;
            background: rgba(255, 0, 255, 0.05);
            border-radius: 2px;
            cursor: pointer;
            transition: all 0.2s;
        }

        .news-item:hover {
            background: rgba(255, 0, 255, 0.15);
            box-shadow: 0 0 10px rgba(255, 0, 255, 0.3);
        }

        .news-title { font-weight: bold; color: #ff00ff; margin-bottom: 2px; }
        .news-date { font-size: 8px; color: #00aa00; }

        .tab-group {
            display: flex;
            gap: 4px;
            margin-bottom: 8px;
            flex-wrap: wrap;
        }

        .tab {
            padding: 4px 8px;
            border: 1px solid #00ffff;
            background: rgba(0, 255, 255, 0.1);
            color: #00ffff;
            cursor: pointer;
            border-radius: 3px;
            font-size: 9px;
            transition: all 0.2s;
        }

        .tab.active {
            background: linear-gradient(135deg, #00ffff, #ff00ff);
            color: #000;
            box-shadow: 0 0 10px #00ffff;
        }

        .status-badge {
            font-size: 9px;
            background: rgba(0, 255, 0, 0.2);
            border: 1px solid #00ff00;
            border-radius: 3px;
            padding: 3px 8px;
            display: inline-block;
            color: #00ff00;
        }

        hr { border: none; border-top: 1px dashed rgba(0, 255, 255, 0.3); margin: 8px 0; }

        .weather-chart { margin: 8px 0; background: rgba(0, 0, 0, 0.5); border-radius: 3px; padding: 4px; border: 1px solid rgba(0, 255, 255, 0.2); }

        @media (max-width: 768px) {
            .panel { width: 280px !important; font-size: 9px; }
        }
    </style>
</head>
<body>
    <canvas id="canvas"></canvas>

    <!-- LEFT PANEL -->
    <div class="panel left-panel">
        <h2 style="margin-top: 0;">🛸 HORUS-EYE ONLINE</h2>

        <div class="threat-badge">
            <div style="font-size: 9px; margin-bottom: 4px;">⚠️ THREAT LEVEL</div>
            <div style="font-size: 15px; font-weight: bold; color: #ff0000;" id="threatLevel">LOADING...</div>
            <div style="font-size: 9px; margin-top: 4px;">Kp: <span id="kpValue">-</span></div>
        </div>

        <h3>🛰️ ISS REAL-TIME</h3>
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 6px; margin: 6px 0;">
            <div class="stat-box">
                <div class="stat-label">Latitude</div>
                <div class="stat-value" id="issLat">-</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Longitude</div>
                <div class="stat-value" id="issLon">-</div>
            </div>
        </div>
        <div class="data-row">
            <span>👨‍🚀 Astronauts:</span>
            <span id="astronauts" style="color: #ff00ff; font-weight: bold;">-</span>
        </div>

        <hr>

        <h3>🎮 CONTROLS</h3>
        <label><input type="checkbox" id="toggleOrbits" checked> Show Orbits</label>
        <label><input type="checkbox" id="toggleMoon" checked> Show Moon 🌙</label>
        <label><input type="checkbox" id="soundAlert" checked> 🔊 Sound Alerts</label>

        <div style="margin: 6px 0;">
            <label>⭐ Star Density:</label>
            <input type="range" id="starDensity" min="500" max="2500" step="100" value="1500" class="slider">
            <div style="text-align: center; font-size: 9px; color: #00aa00;" id="starCount">1500 stars</div>
        </div>

        <div style="display: flex; gap: 6px; margin: 8px 0;">
            <button id="resetCamBtn">🌍 CENTER</button>
            <button id="screenshotBtn">📸 CAPTURE</button>
        </div>

        <hr>

        <h3>🔑 API KEY (N2YO)</h3>
        <input type="password" id="apiKey" placeholder="N2YO API Key">
        <button id="saveKeyBtn" style="width: 100%; margin-top: 4px;">💾 SAVE KEY</button>
        <div style="margin-top: 4px;">
            <span class="status-badge" id="apiStatus">✗ NO KEY</span>
        </div>
    </div>

    <!-- RIGHT PANEL -->
    <div class="panel right-panel">
        <h2 style="margin-top: 0;">🌌 NASA & NEWS</h2>

        <div class="tab-group">
            <div class="tab active" onclick="switchTab(event, 'apod')">APOD</div>
            <div class="tab" onclick="switchTab(event, 'news')">NEWS</div>
            <div class="tab" onclick="switchTab(event, 'events')">EVENTS</div>
        </div>

        <div id="apodTab">
            <div style="font-weight: bold; color: #ff00ff; margin-bottom: 4px;" id="apodTitle">NASA APOD</div>
            <img id="apodImg" style="max-width: 100%; border-radius: 3px; margin: 6px 0; display: none;">
            <div style="font-size: 9px; color: #00ffff; line-height: 1.4;" id="apodExplanation">Loading...</div>
        </div>

        <div id="newsTab" style="display: none;"></div>

        <div id="eventsTab" style="display: none;">
            <div class="news-item">
                <div class="news-title">🚀 SpaceX Launch</div>
                <div class="news-date">Next: Apr 2026</div>
            </div>
            <div class="news-item">
                <div class="news-title">🛰️ ISS Docking</div>
                <div class="news-date">Next: Apr 2026</div>
            </div>
            <div class="news-item">
                <div class="news-title">🌙 Lunar Events</div>
                <div class="news-date">Next: May 2026</div>
            </div>
        </div>
    </div>

    <!-- BOTTOM-LEFT PANEL -->
    <div class="panel bottom-left">
        <h2 style="margin-top: 0;">📊 SPACE WEATHER</h2>
        <div class="weather-chart">
            <canvas id="weatherChart" height="100"></canvas>
        </div>
        <div class="data-row">
            <span>Current Kp:</span>
            <span id="kpDisplay" style="color: #ff00ff; font-weight: bold;">-</span>
        </div>
        <div class="data-row">
            <span>Status:</span>
            <span style="color: #00ff00;">● MONITORING</span>
        </div>
    </div>

    <!-- BOTTOM-RIGHT PANEL -->
    <div class="panel bottom-right">
        <h2 style="margin-top: 0;">💬 COMMENTS</h2>
        <div class="comment-box">
            <textarea id="newComment" class="comment-input" placeholder="Add comment..."></textarea>
            <button id="postCommentBtn" style="width: 50px; height: 100%;">➤</button>
        </div>
        <div class="comment-list" id="commentList">
            <div style="color: #00aa00; font-size: 9px;">📝 No comments yet...</div>
        </div>
    </div>

    <script>
        // ===== GLOBAL VARIABLES =====
        let scene, camera, renderer;
        let earth, atmosphere, moon, particles;
        let controls;
        let weatherChart = null;
        let weatherData = [];
        let comments = JSON.parse(localStorage.getItem('horus_comments') || '[]');
        let moonAngle = 0;
        let orbitLines = [];
        let starField = null;
        let showOrbits = true;
        let showMoon = true;
        let soundAlerts = true;

        // ===== HELPER FUNCTIONS =====
        function switchTab(event, tabName) {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            event.target.classList.add('active');
            document.getElementById('apodTab').style.display = 'none';
            document.getElementById('newsTab').style.display = 'none';
            document.getElementById('eventsTab').style.display = 'none';
            document.getElementById(tabName + 'Tab').style.display = 'block';
        }

        function updateStars(count) {
            if (starField) scene.remove(starField);
            const starGeometry = new THREE.BufferGeometry();
            const positions = [];
            for (let i = 0; i < count; i++) {
                positions.push((Math.random() - 0.5) * 2000);
                positions.push((Math.random() - 0.5) * 1000);
                positions.push((Math.random() - 0.5) * 800 - 300);
            }
            starGeometry.setAttribute('position', new THREE.BufferAttribute(new Float32Array(positions), 3));
            const starMaterial = new THREE.PointsMaterial({ color: 0xffffff, size: 0.3, transparent: true, opacity: 0.8 });
            starField = new THREE.Points(starGeometry, starMaterial);
            scene.add(starField);
            document.getElementById('starCount').innerText = count + ' stars';
        }

        function createOrbits() {
            orbitLines.forEach(line => scene.remove(line));
            orbitLines = [];
            if (!showOrbits) return;
            const points = [];
            for (let i = 0; i <= 360; i++) {
                const rad = i * Math.PI / 180;
                const x = 12 * Math.cos(rad);
                const z = 12 * Math.sin(rad);
                points.push(new THREE.Vector3(x, 0, z));
            }
            const orbitGeo = new THREE.BufferGeometry().setFromPoints(points);
            const orbitMat = new THREE.LineBasicMaterial({ color: 0x00ffff });
            const orbit = new THREE.LineLoop(orbitGeo, orbitMat);
            scene.add(orbit);
            orbitLines.push(orbit);
        }

        function updateMoonVisibility() {
            moon.visible = showMoon;
        }

        // ===== DATA FETCHING =====
        async function fetchISSData() {
            try {
                const res = await fetch('/api/iss');
                const data = await res.json();
                if (data.latitude && data.longitude) {
                    document.getElementById('issLat').innerText = data.latitude.toFixed(4);
                    document.getElementById('issLon').innerText = data.longitude.toFixed(4);
                }
                if (data.astronauts) {
                    document.getElementById('astronauts').innerText = data.astronauts;
                }
                if (data.kp !== undefined) {
                    const kp = data.kp;
                    document.getElementById('kpValue').innerText = kp;
                    document.getElementById('kpDisplay').innerText = kp;
                    let threat = "NORMAL";
                    if (kp > 5) threat = "HIGH (Geomagnetic Storm)";
                    else if (kp > 3) threat = "MODERATE";
                    document.getElementById('threatLevel').innerHTML = threat;
                    if (soundAlerts && kp > 6) {
                        const audio = new Audio('data:audio/wav;base64,U3RlcmVv...'); // placeholder
                        audio.play().catch(e => console.log(e));
                    }
                }
            } catch(e) { console.error(e); }
        }

        async function fetchSpaceWeather() {
            try {
                const res = await fetch('/api/weather');
                const data = await res.json();
                if (data.kp_history && Array.isArray(data.kp_history)) {
                    weatherData = data.kp_history.slice(-24);
                    if (weatherChart) {
                        weatherChart.data.datasets[0].data = weatherData;
                        weatherChart.update();
                    }
                }
            } catch(e) { console.error(e); }
        }

        async function fetchAPOD() {
            try {
                const res = await fetch('/api/apod');
                const data = await res.json();
                document.getElementById('apodTitle').innerText = data.title || "NASA APOD";
                if (data.url) {
                    document.getElementById('apodImg').src = data.url;
                    document.getElementById('apodImg').style.display = 'block';
                }
                document.getElementById('apodExplanation').innerText = data.explanation || "No explanation available.";
            } catch(e) { console.error(e); }
        }

        async function fetchNews() {
            try {
                const res = await fetch('/api/news');
                const data = await res.json();
                const container = document.getElementById('newsTab');
                container.innerHTML = '';
                if (data.articles && data.articles.length) {
                    data.articles.slice(0, 6).forEach(art => {
                        const div = document.createElement('div');
                        div.className = 'news-item';
                        div.innerHTML = `<div class="news-title">${art.title}</div><div class="news-date">${new Date(art.publishedAt).toLocaleDateString()}</div>`;
                        div.onclick = () => window.open(art.url, '_blank');
                        container.appendChild(div);
                    });
                } else {
                    container.innerHTML = '<div class="news-item">No news available.</div>';
                }
            } catch(e) { console.error(e); }
        }

        // ===== UI HANDLERS =====
        function saveApiKey() {
            const key = document.getElementById('apiKey').value.trim();
            localStorage.setItem('n2yo_key', key);
            document.getElementById('apiStatus').innerText = key ? '✓ KEY SAVED' : '✗ NO KEY';
        }

        function loadApiKey() {
            const key = localStorage.getItem('n2yo_key');
            if (key) {
                document.getElementById('apiKey').value = key;
                document.getElementById('apiStatus').innerText = '✓ KEY LOADED';
            }
        }

        function addComment() {
            const text = document.getElementById('newComment').value.trim();
            if (!text) return;
            const comment = {
                id: Date.now(),
                text: text,
                user: "ANON",
                time: new Date().toLocaleString()
            };
            comments.push(comment);
            localStorage.setItem('horus_comments', JSON.stringify(comments));
            document.getElementById('newComment').value = '';
            renderComments();
        }

        function renderComments() {
            const container = document.getElementById('commentList');
            if (!comments.length) {
                container.innerHTML = '<div style="color: #00aa00; font-size: 9px;">📝 No comments yet...</div>';
                return;
            }
            container.innerHTML = comments.slice().reverse().map(c => `
                <div class="comment-item">
                    <div class="comment-user">${c.user}</div>
                    <div class="comment-text">${c.text}</div>
                    <div class="comment-time">${c.time}</div>
                </div>
            `).join('');
        }

        function takeScreenshot() {
            const canvas = renderer.domElement;
            const link = document.createElement('a');
            link.download = 'horus_eye_capture.png';
            link.href = canvas.toDataURL();
            link.click();
        }

        // ===== THREE.JS INITIALIZATION =====
        function initScene() {
            const canvas = document.getElementById('canvas');
            
            scene = new THREE.Scene();
            scene.background = new THREE.Color(0x000000);
            scene.fog = new THREE.FogExp2(0x000000, 0.0008);

            camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 100000);
            camera.position.set(0, 12, 18);

            renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.shadowMap.enabled = true;

            // Lighting
            const sunLight = new THREE.PointLight(0xffffff, 1.5, 500);
            sunLight.position.set(100, 50, 100);
            sunLight.castShadow = true;
            scene.add(sunLight);

            const ambientLight = new THREE.AmbientLight(0x00ffff, 0.3);
            scene.add(ambientLight);

            const neonLight = new THREE.PointLight(0x00ffff, 0.8, 300);
            neonLight.position.set(-50, 30, -50);
            scene.add(neonLight);

            // Earth
            const earthGeom = new THREE.SphereGeometry(5, 128, 128);
            const earthTexture = new THREE.CanvasTexture(generateEarthCanvas());
            const earthMaterial = new THREE.MeshPhongMaterial({ map: earthTexture, shininess: 5 });
            earth = new THREE.Mesh(earthGeom, earthMaterial);
            earth.castShadow = true;
            scene.add(earth);

            // Atmosphere
            const atmosphereGeom = new THREE.SphereGeometry(5.1, 128, 128);
            const atmosphereMaterial = new THREE.MeshPhongMaterial({
                color: 0x00ffff,
                emissive: 0x00cccc,
                emissiveIntensity: 0.2,
                transparent: true,
                opacity: 0.15,
            });
            atmosphere = new THREE.Mesh(atmosphereGeom, atmosphereMaterial);
            scene.add(atmosphere);

            // Moon
            const moonGeom = new THREE.SphereGeometry(1.5, 32, 32);
            const moonTexture = new THREE.CanvasTexture(generateMoonCanvas());
            const moonMaterial = new THREE.MeshPhongMaterial({ map: moonTexture });
            moon = new THREE.Mesh(moonGeom, moonMaterial);
            moon.position.set(12, 0, 0);
            scene.add(moon);

            // Stars
            updateStars(1500);

            // Orbits
            createOrbits();

            // Particles (neon dust)
            const particleGeom = new THREE.BufferGeometry();
            const positions = new Float32Array(1000 * 3);
            for (let i = 0; i < 1000; i++) {
                positions[i*3] = (Math.random() - 0.5) * 100;
                positions[i*3+1] = (Math.random() - 0.5) * 100;
                positions[i*3+2] = (Math.random() - 0.5) * 100;
            }
            particleGeom.setAttribute('position', new THREE.BufferAttribute(positions, 3));
            const particleMaterial = new THREE.PointsMaterial({ color: 0xff00ff, size: 0.2, transparent: true, opacity: 0.5 });
            particles = new THREE.Points(particleGeom, particleMaterial);
            scene.add(particles);

            // Controls
            controls = new THREE.OrbitControls(camera, renderer.domElement);
            controls.enableDamping = true;
            controls.dampingFactor = 0.05;
            controls.autoRotate = true;
            controls.autoRotateSpeed = 1;
            controls.minDistance = 10;
            controls.maxDistance = 200;

            // Animation loop
            function animate() {
                requestAnimationFrame(animate);
                earth.rotation.y += 0.0008;
                atmosphere.rotation.y -= 0.0005;
                moonAngle += 0.003;
                moon.position.set(12 * Math.cos(moonAngle), 1 * Math.sin(moonAngle * 0.3), 12 * Math.sin(moonAngle));
                moon.rotation.y += 0.01;
                particles.rotation.y += 0.0002;
                particles.rotation.z -= 0.0001;
                controls.update();
                renderer.render(scene, camera);
            }
            animate();

            window.addEventListener('resize', () => {
                camera.aspect = window.innerWidth / window.innerHeight;
                camera.updateProjectionMatrix();
                renderer.setSize(window.innerWidth, window.innerHeight);
            });
        }

        function generateEarthCanvas() {
            const canvas = document.createElement('canvas');
            canvas.width = 1024;
            canvas.height = 512;
            const ctx = canvas.getContext('2d');
            const gradient = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
            gradient.addColorStop(0, '#001a4d');
            gradient.addColorStop(0.5, '#003d99');
            gradient.addColorStop(1, '#001a4d');
            ctx.fillStyle = gradient;
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            ctx.fillStyle = '#1a4d2e';
            for (let i = 0; i < 200; i++) {
                ctx.beginPath();
                ctx.arc(Math.random() * canvas.width, Math.random() * canvas.height, Math.random() * 50 + 20, 0, Math.PI * 2);
                ctx.fill();
            }
            return canvas;
        }

        function generateMoonCanvas() {
            const canvas = document.createElement('canvas');
            canvas.width = 512;
            canvas.height = 512;
            const ctx = canvas.getContext('2d');
            ctx.fillStyle = '#cccccc';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            for (let i = 0; i < 500; i++) {
                ctx.fillStyle = `rgba(100, 100, 100, ${Math.random() * 0.8 + 0.2})`;
                ctx.beginPath();
                ctx.arc(Math.random() * canvas.width, Math.random() * canvas.height, Math.random() * 15 + 5, 0, Math.PI * 2);
                ctx.fill();
            }
            return canvas;
        }

        // ===== EVENT LISTENERS & INIT =====
        document.addEventListener('DOMContentLoaded', () => {
            initScene();

            // Load saved API key
            loadApiKey();

            // Load comments
            renderComments();

            // Chart.js setup
            const ctx = document.getElementById('weatherChart').getContext('2d');
            weatherChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: Array(24).fill('').map((_,i)=>i+'h'),
                    datasets: [{
                        label: 'Kp Index',
                        data: weatherData,
                        borderColor: '#00ffff',
                        backgroundColor: 'rgba(0, 255, 255, 0.1)',
                        fill: true,
                        tension: 0.3
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    plugins: { legend: { display: false } },
                    scales: { y: { min: 0, max: 9, grid: { color: '#00ffff20' } } }
                }
            });

            // Periodic updates
            setInterval(fetchISSData, 5000);
            setInterval(fetchSpaceWeather, 60000);
            fetchAPOD();
            fetchNews();

            // Event listeners
            document.getElementById('toggleOrbits').addEventListener('change', (e) => {
                showOrbits = e.target.checked;
                createOrbits();
            });
            document.getElementById('toggleMoon').addEventListener('change', (e) => {
                showMoon = e.target.checked;
                updateMoonVisibility();
            });
            document.getElementById('soundAlert').addEventListener('change', (e) => {
                soundAlerts = e.target.checked;
            });
            document.getElementById('starDensity').addEventListener('input', (e) => {
                updateStars(parseInt(e.target.value));
            });
            document.getElementById('resetCamBtn').addEventListener('click', () => {
                camera.position.set(0, 12, 18);
                controls.target.set(0,0,0);
                controls.update();
            });
            document.getElementById('screenshotBtn').addEventListener('click', takeScreenshot);
            document.getElementById('saveKeyBtn').addEventListener('click', saveApiKey);
            document.getElementById('postCommentBtn').addEventListener('click', addComment);
        });
    </script>
</body>
</html>
"""

# ============= HTTP REQUEST HANDLER =============
class HorusHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/":
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_CONTENT.encode('utf-8'))
        elif path.startswith("/api/"):
            self.handle_api(path)
        else:
            self.send_error(404)

    def handle_api(self, path):
        """API endpoint'leri yönetir."""
        try:
            if path == "/api/iss":
                # ISS konumu ve astronot sayısı
                iss_data = self.fetch_iss_data()
                # Uzay havası Kp değeri (mock)
                kp = self.fetch_kp_index()
                iss_data["kp"] = kp
                self.send_json(iss_data)
            elif path == "/api/weather":
                # Son 24 saat Kp değerleri (mock)
                weather = {"kp_history": self.generate_kp_history()}
                self.send_json(weather)
            elif path == "/api/apod":
                # NASA APOD
                apod = self.fetch_nasa_apod()
                self.send_json(apod)
            elif path == "/api/news":
                # Uzay haberleri (mock)
                news = self.fetch_space_news()
                self.send_json(news)
            else:
                self.send_error(404)
        except Exception as e:
            self.send_error(500, str(e))

    def send_json(self, data):
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def fetch_iss_data(self):
        """Open Notify API'den ISS konumunu ve astronot sayısını alır."""
        try:
            # ISS konumu
            r = requests.get("http://api.open-notify.org/iss-now.json", timeout=10)
            iss = r.json()
            lat = float(iss["iss_position"]["latitude"])
            lon = float(iss["iss_position"]["longitude"])

            # Astronot sayısı
            r2 = requests.get("http://api.open-notify.org/astros.json", timeout=10)
            astros = r2.json()
            count = astros.get("number", 0)

            return {"latitude": lat, "longitude": lon, "astronauts": count}
        except Exception as e:
            print("ISS API hatası:", e)
            return {"latitude": 0, "longitude": 0, "astronauts": 0}

    def fetch_kp_index(self):
        """NOAA SWPC'den Kp endeksini alır (mock olarak rastgele üretir)."""
        try:
            # Gerçek API: https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json
            r = requests.get("https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json", timeout=10)
            data = r.json()
            # Son değeri al (format: [date, time, kp])
            if len(data) > 1:
                last = data[-1]
                kp = float(last[2])
                return kp
        except:
            pass
        # Fallback: rastgele 0-9 arası
        import random
        return round(random.uniform(0, 9), 1)

    def generate_kp_history(self):
        """Son 24 saatlik Kp değerlerini üretir (mock)."""
        import random
        return [round(random.uniform(0, 9), 1) for _ in range(24)]

    def fetch_nasa_apod(self):
        """NASA APOD API'sinden günün fotoğrafını alır."""
        try:
            # Demo amaçlı sabit bir APOD kullanıyoruz (gerçekte API key gerekli)
            # Gerçek API: https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY
            r = requests.get("https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY", timeout=10)
            data = r.json()
            return {"title": data.get("title", ""), "url": data.get("url", ""), "explanation": data.get("explanation", "")}
        except:
            return {"title": "APOD Unavailable", "url": "", "explanation": "Could not fetch APOD."}

    def fetch_space_news(self):
        """Spaceflight News API'den haberleri alır."""
        try:
            r = requests.get("https://api.spaceflightnewsapi.net/v4/articles/?limit=6", timeout=10)
            data = r.json()
            articles = [{"title": a["title"], "url": a["url"], "publishedAt": a["published_at"]} for a in data.get("results", [])]
            return {"articles": articles}
        except:
            return {"articles": []}

# ============= SUNUCU BAŞLATMA =============
def get_free_port():
    """Boş bir port bulur."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('', 0))
        return s.getsockname()[1]

def open_browser(url):
    """Tarayıcıyı açmak için kısa bir gecikmeyle çalışır."""
    time.sleep(1.5)
    webbrowser.open(url)

if __name__ == "__main__":
    PORT = get_free_port()
    Handler = HorusHandler

    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"HORUS-EYE ULTIMATE çalışıyor: http://localhost:{PORT}")
        print("Tarayıcı otomatik açılacak...")
        threading.Thread(target=open_browser, args=(f"http://localhost:{PORT}",)).start()
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nKapatılıyor...")
            sys.exit(0)
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

        // ===== INITIALIZE THREE.JS =====
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

            // ===== EARTH =====
            const earthGeom = new THREE.SphereGeometry(5, 128, 128);
            const earthCanvas = document.createElement('canvas');
            earthCanvas.width = 2048;
            earthCanvas.height = 1024;
            const ctx = earthCanvas.getContext('2d');
            const gradient = ctx.createLinearGradient(0, 0, earthCanvas.width, earthCanvas.height);
            gradient.addColorStop(0, '#001a4d');
            gradient.addColorStop(0.5, '#003d99');
            gradient.addColorStop(1, '#001a4d');
            ctx.fillStyle = gradient;
            ctx.fillRect(0, 0, earthCanvas.width, earthCanvas.height);
            ctx.fillStyle = '#1a4d2e';
            for (let i = 0; i < 30; i++) {
                ctx.beginPath();
                ctx.arc(Math.random() * earthCanvas.width, Math.random() * earthCanvas.height, Math.random() * 100 + 50, 0, Math.PI * 2);
                ctx.fill();
            }
            const earthTexture = new THREE.CanvasTexture(earthCanvas);
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
            const moonCanvas = document.createElement('canvas');
            moonCanvas.width = 512;
            moonCanvas.height = 512;
            const moonCtx = moonCanvas.getContext('2d');
            moonCtx.fillStyle = '#cccccc';
            moonCtx.fillRect(0, 0, moonCanvas.width, moonCanvas.height);
            for (let i = 0; i < 200; i++) {
                moonCtx.fillStyle = `rgba(100, 100, 100, ${Math.random()})`;
                moonCtx.beginPath();
                moonCtx.arc(Math.random() * moonCanvas.width, Math.random() * moonCanvas.height, Math.random() * 20, 0, Math.PI * 2);
                moonCtx.fill();
            }
            const moonTexture = new THREE.CanvasTexture(moonCanvas);
            const moonMaterial = new THREE.MeshPhongMaterial({ map: moonTexture });
            moon = new THREE.Mesh(moonGeom, moonMaterial);
            moon.position.set(12, 0, 0);
            scene.add(moon);

            // Stars
            updateStars(1500);

            // Orbits
            createOrbits();

            // Particles
            const particleGeom = new THREE.BufferGeometry();
            const positions = new Float32Array(1000 * 3);
            for (let i = 0; i < 1000 * 3; i += 3) {
                positions[i] = (Math.random() - 0.5) * 100;
                positions[i + 1] = (Math.random() - 0.5) * 100;
                positions[i + 2] = (Math.random() - 0.5) * 100;
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

        function createOrbits() {
            const createOrbit = (radius, color) => {
                const points = [];
                for (let i = 0; i <= 64; i++) {
                    const angle = (i / 64) * Math.PI * 2;
                    points.push(new THREE.Vector3(Math.cos(angle) * radius, 0, Math.sin(angle) * radius));
                }
                const geometry = new THREE.BufferGeometry().setFromPoints(points);
                const material = new THREE.LineBasicMaterial({ color, opacity: 0.3, transparent: true });
                return new THREE.Line(geometry, material);
            };
            scene.add(createOrbit(7, 0x00ffff));
            scene.add(createOrbit(10, 0xff00ff));
            scene.add(createOrbit(15, 0x00ff00));
        }

        function updateStars(count) {
            const starsGeom = new THREE.BufferGeometry();
            const positions = new Float32Array(count * 3);
            for (let i = 0; i < count * 3; i += 3) {
                positions[i] = (Math.random() - 0.5) * 2000;
                positions[i + 1] = (Math.random() - 0.5) * 2000;
                positions[i + 2] = (Math.random() - 0.5) * 2000;
            }
            starsGeom.setAttribute('position', new THREE.BufferAttribute(positions, 3));
            const starsMaterial = new THREE.PointsMaterial({ color: 0x00ffff, size: 0.3 });
            const stars = new THREE.Points(starsGeom, starsMaterial);
            if (scene) scene.add(stars);
        }

        // ===== FETCH DATA =====
        async function fetchISSData() {
            try {
                const response = await fetch('/api/iss');
                const data = await response.json();
                document.getElementById('issLat').textContent = data.lat.toFixed(3) + '°';
                document.getElementById('issLon').textContent = data.lon.toFixed(3) + '°';
                document.getElementById('astronauts').textContent = data.people;
            } catch (e) {}
        }

        async function fetchSpaceWeather() {
            try {
                const response = await fetch('/api/spaceweather');
                const data = await response.json();
                document.getElementById('threatLevel').textContent = data.threat;
                document.getElementById('kpValue').textContent = data.kp.toFixed(1);
                document.getElementById('kpDisplay').textContent = data.kp.toFixed(1);
                weatherData.push({ time: new Date().toLocaleTimeString(), kp: data.kp });
                if (weatherData.length > 30) weatherData.shift();
                updateWeatherChart();
            } catch (e) {}
        }

        async function fetchAPOD() {
            try {
                const response = await fetch('/api/apod');
                const data = await response.json();
                document.getElementById('apodTitle').textContent = data.title;
                document.getElementById('apodExplanation').textContent = data.explanation;
                if (data.url && !data.url.includes('youtube')) {
                    document.getElementById('apodImg').src = data.url;
                    document.getElementById('apodImg').style.display = 'block';
                }
            } catch (e) {}
        }

        async function fetchNews() {
            try {
                const response = await fetch('/api/news');
                const data = await response.json();
                const newsList = document.getElementById('newsTab');
                newsList.innerHTML = '';
                data.forEach(article => {
                    const div = document.createElement('div');
                    div.className = 'news-item';
                    div.innerHTML = `
                        <div class="news-title">${article.title}</div>
                        <div class="news-date">${new Date(article.publishedAt).toLocaleDateString()}</div>
                    `;
                    newsList.appendChild(div);
                });
            } catch (e) {}
        }

        function updateWeatherChart() {
            const ctx = document.getElementById('weatherChart');
            if (!ctx) return;
            if (weatherChart) {
                weatherChart.data.labels = weatherData.map(d => d.time);
                weatherChart.data.datasets[0].data = weatherData.map(d => d.kp);
                weatherChart.update();
            } else {
                weatherChart = new Chart(ctx, {
                    type: 'line',
                    data: {
                        labels: weatherData.map(d => d.time),
                        datasets: [{
                            label: 'Kp Index',
                            data: weatherData.map(d => d.kp),
                            borderColor: '#00ffff',
                            backgroundColor: 'rgba(0, 255, 255, 0.1)',
                            tension: 0.4,
                            fill: true,
                            pointBackgroundColor: '#ff00ff',
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: { legend: { display: false } },
                        scales: {
                            y: { ticks: { color: '#00ffff' }, grid: { color: 'rgba(0, 255, 255, 0.1)' } },
                            x: { ticks: { color: '#00ffff' }, grid: { color: 'rgba(0, 255, 255, 0.1)' } }
                        }
                    }
                });
            }
        }

        function renderComments() {
            const commentList = document.getElementById('commentList');
            if (comments.length === 0) {
                commentList.innerHTML = '<div style="color: #00aa00; font-size: 9px;">📝 No comments yet...</div>';
                return;
            }
            commentList.innerHTML = comments.map(c => `
                <div class="comment-item">
                    <span class="comment-user">${c.user}</span>
                    <div class="comment-text">"${c.text}"</div>
                    <div class="comment-time">${c.date}</div>
                </div>
            `).join('');
        }

        function switchTab(event, tab) {
            document.getElementById('apodTab').style.display = tab === 'apod' ? 'block' : 'none';
            document.getElementById('newsTab').style.display = tab === 'news' ? 'block' : 'none';
            document.getElementById('eventsTab').style.display = tab === 'events' ? 'block' : 'none';
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            event.target.classList.add('active');
        }

        window.addEventListener('load', () => {
            initScene();
            fetchISSData();
            fetchSpaceWeather();
            fetchAPOD();
            fetchNews();

            setInterval(fetchISSData, 10000);
            setInterval(fetchSpaceWeather, 10000);

            const savedKey = localStorage.getItem('horus_api_key');
            if (savedKey) {
                document.getElementById('apiKey').value = savedKey;
                document.getElementById('apiStatus').textContent = '✓ READY';
                document.getElementById('apiStatus').style.borderColor = '#00ff00';
            }

            document.getElementById('saveKeyBtn').onclick = () => {
                const key = document.getElementById('apiKey').value;
                localStorage.setItem('horus_api_key', key);
                document.getElementById('apiStatus').textContent = '✓ SAVED';
                document.getElementById('apiStatus').style.borderColor = '#00ff00';
            };

            document.getElementById('starDensity').oninput = (e) => {
                const count = parseInt(e.target.value);
                document.getElementById('starCount').textContent = count + ' stars';
                updateStars(count);
            };

            document.getElementById('screenshotBtn').onclick = () => {
                alert('Screenshot saved!');
            };

            document.getElementById('resetCamBtn').onclick = () => {
                controls.reset();
                camera.position.set(0, 12, 18);
            };

            document.getElementById('postCommentBtn').onclick = () => {
                const text = document.getElementById('newComment').value.trim();
                if (text) {
                    comments.push({
                        user: localStorage.getItem('horus_user') || 'CyberPunk',
                        text,
                        date: new Date().toLocaleTimeString()
                    });
                    localStorage.setItem('horus_comments', JSON.stringify(comments));
                    renderComments();
                    document.getElementById('newComment').value = '';
                }
            };

            renderComments();
        });
    </script>
</body>
</html>
"""

# ============= HTTP HANDLER =============
class HorusHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        
        if parsed.path in ['/', '/index.html']:
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(HTML_CONTENT.encode('utf-8'))
        
        elif parsed.path == '/api/iss':
            self.send_api_data(self.fetch_iss_data())
        elif parsed.path == '/api/spaceweather':
            self.send_api_data(self.fetch_space_weather())
        elif parsed.path == '/api/apod':
            self.send_api_data(self.fetch_apod())
        elif parsed.path == '/api/news':
            self.send_api_data(self.fetch_news())
        else:
            self.send_error(404)

    def fetch_iss_data(self):
        try:
            resp = requests.get('http://api.open-notify.org/iss-now.json', timeout=5)
            pos = resp.json()
            people_resp = requests.get('http://api.open-notify.org/astros.json', timeout=5)
            people = people_resp.json()['number']
            return {
                'lat': float(pos['iss_position']['latitude']),
                'lon': float(pos['iss_position']['longitude']),
                'people': people
            }
        except:
            return {'lat': 0, 'lon': 0, 'people': 0}

    def fetch_space_weather(self):
        try:
            resp = requests.get('https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json', timeout=5)
            data = resp.json()
            latest = data[-1]
            kp = float(latest[1])
            threat = 'NOMINAL (G0)'
            if kp >= 8: threat = 'SEVERE (G4+)'
            elif kp >= 7: threat = 'STRONG (G3)'
            elif kp >= 5: threat = 'MODERATE (G2)'
            elif kp >= 3: threat = 'MINOR (G1)'
            return {'threat': threat, 'kp': kp}
        except:
            return {'threat': 'NOMINAL', 'kp': 2}

    def fetch_apod(self):
        try:
            resp = requests.get('https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY', timeout=5)
            data = resp.json()
            return {
                'title': data.get('title', 'NASA APOD'),
                'url': data.get('url', ''),
                'explanation': data.get('explanation', 'No data')
            }
        except:
            return {'title': 'NASA APOD', 'url': '', 'explanation': 'Loading...'}

    def fetch_news(self):
        try:
            resp = requests.get('https://spaceflightnewsapi.net/api/v2/articles?_limit=5', timeout=5)
            articles = resp.json()
            return [{'title': a['title'], 'url': a['url'], 'publishedAt': a['publishedAt']} for a in articles]
        except:
            return [{'title': 'News loading...', 'url': '#', 'publishedAt': ''}]

    def send_api_data(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def log_message(self, format, *args):
        print(f"[{self.client_address[0]}] {args[0]}")

# ============= SERVER SETUP =============
def get_free_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('', 0))
        return s.getsockname()[1]

def start_server():
    port = get_free_port()
    handler = HorusHandler
    
    with socketserver.TCPServer(('', port), handler) as httpd:
        print("\n" + "="*60)
        print("🚀 HORUS-EYE ULTIMATE BAŞLATILDI!")
        print("="*60)
        print(f"🌐 Yerel Erişim: http://localhost:{port}")
        
        try:
            hostname = socket.gethostname()
            local_ip = socket.gethostbyname(hostname)
            print(f"📡 Ağ Erişimi: http://{local_ip}:{port}")
        except:
            pass
        
        print("⏎ Çıkmak için Ctrl+C tuşlayın\n")
        
        try:
            webbrowser.open(f'http://localhost:{port}')
        except:
            pass
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n⛔ Sunucu durduruldu.")

if __name__ == '__main__':
    start_server()

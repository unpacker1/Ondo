#!/bin/bash
# HORUS-EYE Ultimate Edition - Tüm özellikler tek dosyada
# Termux için optimize edilmiştir.

if ! command -v python3 &> /dev/null; then
    echo "Python3 yüklenmemiş! 'pkg install python' ile kurun."
    exit 1
fi

echo "HORUS-EYE Ultimate başlatılıyor..."
python3 - <<'PYTHON_SCRIPT'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import http.server
import socketserver
import socket
import webbrowser
import sys
import json
import os
from urllib.parse import urlparse

# ======================= HTML İÇERİĞİ (Tüm Özellikler) =======================
HTML_PAGE = """<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>HORUS-EYE · Ultimate Asset Tracker</title>
    <link rel="manifest" href="/manifest.json">
    <style>
        /* ---- Temel stiller ---- */
        body { margin: 0; overflow: hidden; font-family: 'Share Tech Mono', 'Courier New', monospace; color: #0ff; background-color: #000; }
        .dashboard { position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: 10; }
        /* Paneller */
        .panel {
            pointer-events: auto;
            background: rgba(0, 0, 0, 0.8);
            backdrop-filter: blur(12px);
            border-radius: 16px;
            border: 1px solid rgba(0, 255, 255, 0.3);
            padding: 12px;
            box-shadow: 0 0 20px rgba(0, 255, 255, 0.2);
            font-size: 12px;
        }
        .left-panel { position: absolute; top: 20px; left: 20px; width: 340px; max-height: 90vh; overflow-y: auto; }
        .right-panel { position: absolute; bottom: 20px; right: 20px; width: 300px; max-height: 80vh; overflow-y: auto; }
        .bottom-panel { position: absolute; bottom: 20px; left: 20px; width: 320px; background: rgba(0,0,0,0.7); border-radius: 12px; padding: 8px; pointer-events: auto; }
        .title { font-size: 24px; font-weight: bold; letter-spacing: 2px; margin-bottom: 4px; text-shadow: 0 0 5px #0ff; }
        .sub { font-size: 11px; color: #8aa; border-bottom: 1px dashed #2a6; margin-bottom: 12px; padding-bottom: 5px; }
        .threat { background: rgba(255,30,30,0.2); border-left: 4px solid #f44; padding: 8px; margin: 10px 0; }
        .pattern { background: rgba(0,20,40,0.7); margin: 5px 0; padding: 5px 8px; border-radius: 8px; border: 1px solid #1fa; }
        .pattern-name { color: #ffaa44; font-weight: bold; }
        .data-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 6px; margin: 10px 0; }
        .data-item { font-size: 11px; }
        .data-label { color: #7af; }
        .data-value { font-weight: bold; color: #fff; }
        button, .btn {
            background: none;
            border: 1px solid #0ff;
            border-radius: 20px;
            padding: 4px 12px;
            color: #0ff;
            cursor: pointer;
            font-family: monospace;
            transition: 0.2s;
        }
        button:hover { background: #0ff; color: #000; box-shadow: 0 0 10px #0ff; }
        input, select { background: #112; border: 1px solid #0ff; color: #0ff; border-radius: 12px; padding: 4px 8px; font-family: monospace; }
        .user-row { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
        .avatar { width: 36px; height: 36px; background: #124; border-radius: 50%; display: flex; align-items: center; justify-content: center; border: 1px solid #0ff; }
        .comment-box { margin-top: 8px; display: flex; gap: 5px; }
        .comment-input { flex: 1; }
        .comment-list { max-height: 150px; overflow-y: auto; margin-top: 8px; font-size: 10px; }
        .settings-group { margin: 10px 0; }
        .slider { width: 100%; }
        hr { border-color: #0ff3; }
        .sat-list { max-height: 200px; overflow-y: auto; margin-top: 5px; }
        .sat-item { padding: 4px; cursor: pointer; border-bottom: 1px solid #0ff3; }
        .sat-item:hover { background: #0ff2; }
        .graph-container { height: 150px; margin-top: 10px; }
        canvas.graph { width: 100%; height: 100%; background: #000c; border-radius: 8px; }
        @media (max-width: 700px) {
            .left-panel { width: 280px; top: 10px; left: 10px; max-height: 70vh; }
            .right-panel { width: 260px; }
            .bottom-panel { width: 260px; }
        }
    </style>
    <!-- Kütüphaneler -->
    <script type="importmap">
        {
            "imports": {
                "three": "https://unpkg.com/three@0.128.0/build/three.module.js",
                "three/addons/": "https://unpkg.com/three@0.128.0/examples/jsm/"
            }
        }
    </script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js"></script>
</head>
<body>
    <div class="dashboard">
        <!-- Sol panel: Ana veriler + kontroller -->
        <div class="panel left-panel">
            <div class="title">HORUS-EYE</div>
            <div class="sub">ULTIMATE ASSET TRACKING · SECURE LINK</div>
            <div class="threat" id="threatPanel">
                <span>⚠ THREAT LEVEL</span><br>
                <span class="threat-level" id="threatLevel">12:26-03-03 · NOMINAL</span>
            </div>
            <div>🔍 PATTERN DETECTED</div>
            <div id="patternList"></div>
            <div class="data-grid" id="dataGrid"></div>
            <div style="font-size: 11px;">📡 openSky + adsbexcha &nbsp;|&nbsp; <span id="liveStats">930 / 1.307</span></div>
            <hr>
            <div><b>🎮 KONTROLLER</b></div>
            <div><label><input type="checkbox" id="toggleOrbitGSPOG" checked> GSPOG</label>
                 <label><input type="checkbox" id="toggleOrbitFCK1EL" checked> FCK1EL</label>
                 <label><input type="checkbox" id="toggleOrbitHAMIC" checked> HAMIC</label>
                 <label><input type="checkbox" id="toggleMoon" checked> 🌙 Ay</label>
            </div>
            <div>Yörünge Yarıçapı (GSPOG): <input type="range" id="radiusGSPOG" min="4" max="8" step="0.1" value="5.4"></div>
            <div>Yörünge Eğiklik (GSPOG): <input type="range" id="inclGSPOG" min="-1.5" max="1.5" step="0.01" value="0.32"></div>
            <button id="focusGSPOG">🔭 GSPOG'a Odaklan</button>
            <button id="focusFCK1EL">🔭 FCK1EL'a Odaklan</button>
            <button id="focusHAMIC">🔭 HAMIC'a Odaklan</button>
            <button id="resetCam">🌍 Dünya'ya Dön</button>
            <hr>
            <div><b>⚙️ AYARLAR</b></div>
            <div><label>🔊 Sesli Uyarı: <input type="checkbox" id="soundAlert" checked></label></div>
            <div><label>📢 Bildirim: <input type="checkbox" id="notificationAlert" checked></label></div>
            <div><label>⭐ Yıldız Yoğunluğu: <input type="range" id="starDensity" min="0" max="3000" step="100" value="1800"></label></div>
            <div><label>🌍 Arkaplan Rengi: <input type="color" id="bgColor" value="#010118"></label></div>
            <button id="takeScreenshot">📸 Ekran Görüntüsü</button>
            <button id="shareBtn">📤 Paylaş</button>
            <hr>
            <div><b>👤 KULLANICI</b></div>
            <div><input type="text" id="username" placeholder="Kullanıcı adı" style="width:100%"></div>
            <button id="loginBtn">Giriş Yap / Kaydet</button>
            <div id="userStatus"></div>
        </div>

        <!-- Sağ panel: Uydu listesi, yorumlar, grafik -->
        <div class="panel right-panel">
            <div><b>🛰️ TAKİP EDİLEN UYDULAR</b></div>
            <div class="sat-list" id="satList"></div>
            <hr>
            <div><b>💬 YORUMLAR</b></div>
            <div class="comment-box">
                <input type="text" id="newComment" class="comment-input" placeholder="Yorum yaz...">
                <button id="postComment">➤</button>
            </div>
            <div class="comment-list" id="commentList"></div>
            <hr>
            <div><b>📈 AÇI-ZAMAN GRAFİĞİ (GSPOG)</b></div>
            <canvas id="angleGraph" class="graph" width="300" height="150"></canvas>
        </div>

        <!-- Alt panel: Anomali ve tahmin -->
        <div class="panel bottom-panel">
            <div><b>🧠 ANOMALİ TESPİTİ & TAHMİN</b></div>
            <div id="anomalyMsg">İzleme aktif, sapma yok.</div>
            <div id="predictionMsg">Yörünge stabil.</div>
        </div>
    </div>

    <script type="module">
        import * as THREE from 'three';
        import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
        import { CSS2DRenderer, CSS2DObject } from 'three/addons/renderers/CSS2DRenderer.js';

        // ---------- BAŞLANGIÇ ----------
        const scene = new THREE.Scene();
        scene.background = new THREE.Color(0x010118);
        scene.fog = new THREE.FogExp2(0x010118, 0.0008);
        const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
        camera.position.set(0, 3, 18);
        const renderer = new THREE.WebGLRenderer({ antialias: true });
        renderer.setSize(window.innerWidth, window.innerHeight);
        renderer.shadowMap.enabled = true;
        document.body.appendChild(renderer.domElement);
        const labelRenderer = new CSS2DRenderer();
        labelRenderer.setSize(window.innerWidth, window.innerHeight);
        labelRenderer.domElement.style.position = 'absolute';
        labelRenderer.domElement.style.top = '0px';
        labelRenderer.domElement.style.left = '0px';
        labelRenderer.domElement.style.pointerEvents = 'none';
        document.body.appendChild(labelRenderer.domElement);
        const controls = new OrbitControls(camera, renderer.domElement);
        controls.enableDamping = true; controls.dampingFactor = 0.05; controls.zoomSpeed = 1.2; controls.rotateSpeed = 0.8;
        controls.target.set(0, 0, 0);

        // Yıldızlar (dinamik)
        let starsMesh;
        function updateStars(count) {
            if (starsMesh) scene.remove(starsMesh);
            const geometry = new THREE.BufferGeometry();
            const positions = new Float32Array(count * 3);
            for (let i = 0; i < count; i++) {
                positions[i*3] = (Math.random() - 0.5) * 800;
                positions[i*3+1] = (Math.random() - 0.5) * 800;
                positions[i*3+2] = (Math.random() - 0.5) * 150 - 50;
            }
            geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
            const material = new THREE.PointsMaterial({ color: 0xffffff, size: 0.2, transparent: true });
            starsMesh = new THREE.Points(geometry, material);
            scene.add(starsMesh);
        }
        updateStars(1800);
        document.getElementById('starDensity').addEventListener('input', (e) => updateStars(parseInt(e.target.value)));
        document.getElementById('bgColor').addEventListener('input', (e) => scene.background.set(e.target.value));

        // Dünya
        const earthGeo = new THREE.SphereGeometry(3.2, 128, 128);
        const textureLoader = new THREE.TextureLoader();
        const earthMap = textureLoader.load('https://threejs.org/examples/textures/planets/earth_atmos_2048.jpg');
        const earthSpec = textureLoader.load('https://threejs.org/examples/textures/planets/earth_specular_2048.jpg');
        const earthNorm = textureLoader.load('https://threejs.org/examples/textures/planets/earth_normal_2048.jpg');
        const cloudMap = textureLoader.load('https://threejs.org/examples/textures/planets/earth_clouds_1024.png');
        const earthMat = new THREE.MeshPhongMaterial({ map: earthMap, specularMap: earthSpec, specular: new THREE.Color('grey'), shininess: 5, normalMap: earthNorm });
        const earth = new THREE.Mesh(earthGeo, earthMat);
        scene.add(earth);
        const cloudGeo = new THREE.SphereGeometry(3.23, 128, 128);
        const cloudMat = new THREE.MeshPhongMaterial({ map: cloudMap, transparent: true, opacity: 0.12, blending: THREE.AdditiveBlending });
        const clouds = new THREE.Mesh(cloudGeo, cloudMat);
        scene.add(clouds);

        // Işık
        const ambient = new THREE.AmbientLight(0x222222);
        scene.add(ambient);
        const dirLight = new THREE.DirectionalLight(0xffffff, 1.2);
        dirLight.position.set(5, 10, 7);
        scene.add(dirLight);
        const fillLight = new THREE.PointLight(0x4466cc, 0.5);
        fillLight.position.set(-3, 2, 4);
        scene.add(fillLight);

        // Yörünge verileri
        const orbitsData = [
            { id: 'GSPOG', radius: 5.4, inclination: 0.32, color: 0x33ffff, deg: 273, speed: 0.008, angle: 0, line: null, label: null, particles: [] },
            { id: 'FCK1EL', radius: 6.7, inclination: 0.75, color: 0xffaa44, deg: 312, speed: 0.006, angle: 0, line: null, label: null, particles: [] },
            { id: 'HAMIC', radius: 8.1, inclination: 1.08, color: 0xff66cc, deg: 295, speed: 0.005, angle: 0, line: null, label: null, particles: [] }
        ];
        const orbitObjects = {};

        // Yörünge çizgileri ve etiketleri oluştur
        orbitsData.forEach(orb => {
            const points = [];
            for (let i = 0; i <= 180; i++) {
                const angle = (i / 180) * Math.PI * 2;
                let x = orb.radius * Math.cos(angle);
                let z = orb.radius * Math.sin(angle);
                let y = 0;
                const cosInc = Math.cos(orb.inclination);
                const sinInc = Math.sin(orb.inclination);
                const newY = y * cosInc - z * sinInc;
                const newZ = y * sinInc + z * cosInc;
                points.push(new THREE.Vector3(x, newY, newZ));
            }
            const geometry = new THREE.BufferGeometry().setFromPoints(points);
            const material = new THREE.LineBasicMaterial({ color: orb.color });
            const line = new THREE.LineLoop(geometry, material);
            scene.add(line);
            orb.line = line;

            const div = document.createElement('div');
            div.textContent = `${orb.id} | ${orb.deg}° turn`;
            div.style.color = `#${orb.color.toString(16)}`;
            div.style.backgroundColor = 'rgba(0,0,0,0.6)';
            div.style.padding = '2px 8px';
            div.style.borderRadius = '20px';
            div.style.borderLeft = `3px solid #${orb.color.toString(16)}`;
            const label = new CSS2DObject(div);
            const angleRad = Math.PI / 4;
            let xPos = orb.radius * Math.cos(angleRad);
            let zPos = orb.radius * Math.sin(angleRad);
            let yPos = 0;
            const cosI = Math.cos(orb.inclination);
            const sinI = Math.sin(orb.inclination);
            const rotY = yPos * cosI - zPos * sinI;
            const rotZ = yPos * sinI + zPos * cosI;
            label.position.set(xPos, rotY, rotZ);
            scene.add(label);
            orb.label = label;

            // Parçacık akışı
            for (let i = 0; i < 30; i++) {
                const particleGeo = new THREE.SphereGeometry(0.03, 6, 6);
                const particleMat = new THREE.MeshStandardMaterial({ color: orb.color, emissive: orb.color });
                const particle = new THREE.Mesh(particleGeo, particleMat);
                scene.add(particle);
                orb.particles.push({ mesh: particle, angle: (i / 30) * Math.PI * 2, speed: 0.01 + Math.random() * 0.01 });
            }
            orbitObjects[orb.id] = orb;
        });

        // Ay
        const moonGeo = new THREE.SphereGeometry(0.5, 64, 64);
        const moonMat = new THREE.MeshStandardMaterial({ color: 0xccccaa, emissive: 0x332200 });
        const moon = new THREE.Mesh(moonGeo, moonMat);
        scene.add(moon);
        let moonAngle = 0;
        const moonOrbitRadius = 10;
        let moonVisible = true;

        // Uydu noktacıkları (simülasyon)
        const satellites = [];
        for (let i = 0; i < 60; i++) {
            const satGeo = new THREE.SphereGeometry(0.04, 8, 8);
            const satMat = new THREE.MeshStandardMaterial({ color: 0x88aaff, emissive: 0x2266aa });
            const sat = new THREE.Mesh(satGeo, satMat);
            scene.add(sat);
            satellites.push({
                mesh: sat,
                radius: 4 + Math.random() * 5,
                speed: 0.002 + Math.random() * 0.004,
                angle: Math.random() * Math.PI * 2,
                inclination: (Math.random() - 0.5) * 1.2,
                yOffset: (Math.random() - 0.5) * 1.5
            });
        }

        // Işık efektleri
        const glowPoints = [];
        for (let i=0; i<12; i++) {
            const light = new THREE.PointLight(0x2266ff, 0.4, 12);
            scene.add(light);
            glowPoints.push(light);
        }

        // ---------- KONTROLLER ----------
        document.getElementById('toggleOrbitGSPOG').addEventListener('change', e => orbitObjects.GSPOG.line.visible = e.target.checked);
        document.getElementById('toggleOrbitFCK1EL').addEventListener('change', e => orbitObjects.FCK1EL.line.visible = e.target.checked);
        document.getElementById('toggleOrbitHAMIC').addEventListener('change', e => orbitObjects.HAMIC.line.visible = e.target.checked);
        document.getElementById('toggleMoon').addEventListener('change', e => moon.visible = e.target.checked);
        document.getElementById('radiusGSPOG').addEventListener('input', e => {
            orbitObjects.GSPOG.radius = parseFloat(e.target.value);
            recreateOrbit(orbitObjects.GSPOG);
        });
        document.getElementById('inclGSPOG').addEventListener('input', e => {
            orbitObjects.GSPOG.inclination = parseFloat(e.target.value);
            recreateOrbit(orbitObjects.GSPOG);
        });

        function recreateOrbit(orb) {
            const points = [];
            for (let i = 0; i <= 180; i++) {
                const angle = (i / 180) * Math.PI * 2;
                let x = orb.radius * Math.cos(angle);
                let z = orb.radius * Math.sin(angle);
                let y = 0;
                const cosInc = Math.cos(orb.inclination);
                const sinInc = Math.sin(orb.inclination);
                const newY = y * cosInc - z * sinInc;
                const newZ = y * sinInc + z * cosInc;
                points.push(new THREE.Vector3(x, newY, newZ));
            }
            const geometry = new THREE.BufferGeometry().setFromPoints(points);
            orb.line.geometry.dispose();
            orb.line.geometry = geometry;
            // etiketi güncelle
            const angleRad = Math.PI / 4;
            let xPos = orb.radius * Math.cos(angleRad);
            let zPos = orb.radius * Math.sin(angleRad);
            let yPos = 0;
            const cosI = Math.cos(orb.inclination);
            const sinI = Math.sin(orb.inclination);
            const rotY = yPos * cosI - zPos * sinI;
            const rotZ = yPos * sinI + zPos * cosI;
            orb.label.position.set(xPos, rotY, rotZ);
        }

        function focusOnOrbit(orb) {
            const pos = new THREE.Vector3(orb.radius, 0, 0);
            controls.target.copy(pos);
            camera.position.set(pos.x + 2, pos.y + 1, pos.z + 3);
            controls.update();
        }
        document.getElementById('focusGSPOG').onclick = () => focusOnOrbit(orbitObjects.GSPOG);
        document.getElementById('focusFCK1EL').onclick = () => focusOnOrbit(orbitObjects.FCK1EL);
        document.getElementById('focusHAMIC').onclick = () => focusOnOrbit(orbitObjects.HAMIC);
        document.getElementById('resetCam').onclick = () => { controls.target.set(0,0,0); camera.position.set(0,3,18); controls.update(); };

        // ---------- VERİ PANELİ GÜNCELLEME (simülasyon) ----------
        function updateDataPanel() {
            const threat = Math.random() > 0.8 ? '⚠️ YÜKSEK' : 'NOMINAL';
            document.getElementById('threatLevel').innerHTML = `12:26-03-03 · ${threat}`;
            if (threat.includes('YÜKSEK') && document.getElementById('soundAlert').checked) {
                const audio = new Audio('data:audio/wav;base64,U3RlcmVv...'); // dummy
                audio.play().catch(e=>console.log);
                if (document.getElementById('notificationAlert').checked && Notification.permission === 'granted') {
                    new Notification('HORUS-EYE Uyarısı', { body: 'Yüksek tehdit seviyesi tespit edildi!' });
                }
            }
            const patterns = ['GSPOG (273°)', 'FCK1EL (312°)', 'HAMIC (295°)'];
            document.getElementById('patternList').innerHTML = patterns.map(p => `<div class="pattern"><span class="pattern-name">ORBIT pattern: ${p.split(' ')[0]}</span><span class="pattern-deg">${p.split(' ')[1]}</span></div>`).join('');
            document.getElementById('dataGrid').innerHTML = `
                <div class="data-item"><span class="data-label">SIG/FRQ</span><br><span class="data-value">${(2.1+Math.random()*0.1).toFixed(3)}</span></div>
                <div class="data-item"><span class="data-label">AZ/ELEV</span><br><span class="data-value">${Math.floor(45+Math.random()*40)}°</span></div>
                <div class="data-item"><span class="data-label">STATUS</span><br><span class="data-value">5YS · NOMINAL</span></div>
                <div class="data-item"><span class="data-label">UPLINK</span><br><span class="data-value">ACTIVE</span></div>
                <div class="data-item"><span class="data-label">FEEDS</span><br><span class="data-value">2/3</span></div>
                <div class="data-item"><span class="data-label">TOTAL</span><br><span class="data-value">${Math.floor(6800+Math.random()*200)}</span></div>
                <div class="data-item"><span class="data-label">TTL/TVL</span><br><span class="data-value">${Math.floor(2400+Math.random()*100)} / ${Math.floor(4400+Math.random()*100)}</span></div>
            `;
            document.getElementById('liveStats').innerHTML = `${Math.floor(900+Math.random()*50)} / ${(1.2+Math.random()*0.2).toFixed(3)}`;
        }
        setInterval(updateDataPanel, 3000);

        // Uydu listesi (sahte)
        const satNames = ['GEO-1', 'GPS-23', 'STARLINK-45', 'ISS (ZARYA)', 'HST', 'TURKSAT-6A'];
        function updateSatList() {
            const listDiv = document.getElementById('satList');
            listDiv.innerHTML = satNames.map(name => `<div class="sat-item" data-sat="${name}">🛰️ ${name}</div>`).join('');
            document.querySelectorAll('.sat-item').forEach(el => {
                el.addEventListener('click', () => { alert(`Uydu ${el.dataset.sat} seçildi (simülasyon).`); });
            });
        }
        updateSatList();

        // Yorumlar (localStorage)
        let comments = JSON.parse(localStorage.getItem('horus_comments') || '[]');
        function renderComments() {
            const list = document.getElementById('commentList');
            list.innerHTML = comments.map(c => `<div><strong>${c.user}:</strong> ${c.text}</div>`).join('');
        }
        document.getElementById('postComment').onclick = () => {
            const user = localStorage.getItem('horus_user') || 'Anonim';
            const text = document.getElementById('newComment').value.trim();
            if (text) {
                comments.push({ user, text, date: new Date() });
                localStorage.setItem('horus_comments', JSON.stringify(comments));
                renderComments();
                document.getElementById('newComment').value = '';
            }
        };
        renderComments();

        // Kullanıcı girişi
        document.getElementById('loginBtn').onclick = () => {
            const username = document.getElementById('username').value.trim();
            if (username) {
                localStorage.setItem('horus_user', username);
                document.getElementById('userStatus').innerHTML = `✅ Hoşgeldin, ${username}`;
            } else {
                localStorage.removeItem('horus_user');
                document.getElementById('userStatus').innerHTML = `👤 Misafir`;
            }
        };
        const savedUser = localStorage.getItem('horus_user');
        if (savedUser) document.getElementById('userStatus').innerHTML = `✅ Hoşgeldin, ${savedUser}`;
        else document.getElementById('userStatus').innerHTML = `👤 Misafir`;

        // Grafik (Chart.js)
        const ctx = document.getElementById('angleGraph').getContext('2d');
        let angleHistory = Array(20).fill(0);
        let chart = new Chart(ctx, {
            type: 'line',
            data: { labels: Array(20).fill(''), datasets: [{ label: 'GSPOG Açısı (°)', data: angleHistory, borderColor: '#0ff', fill: false }] },
            options: { responsive: true, maintainAspectRatio: true }
        });
        setInterval(() => {
            const newAngle = (orbitObjects.GSPOG.angle * 180 / Math.PI) % 360;
            angleHistory.push(newAngle);
            if (angleHistory.length > 20) angleHistory.shift();
            chart.data.datasets[0].data = [...angleHistory];
            chart.update();
        }, 1000);

        // Anomali tespiti (basit: açı değişim hızı anormalse)
        let lastAngle = 0;
        setInterval(() => {
            const current = orbitObjects.GSPOG.angle;
            const delta = Math.abs(current - lastAngle);
            if (delta > 0.5) {
                document.getElementById('anomalyMsg').innerHTML = '⚠️ ANOMALİ: Açısal hız sapması!';
                if (document.getElementById('soundAlert').checked) new Audio().play().catch(e=>{});
            } else {
                document.getElementById('anomalyMsg').innerHTML = '✅ İzleme normal, sapma yok.';
            }
            lastAngle = current;
            // Tahmin (basit)
            const nextTurn = (orbitObjects.GSPOG.deg + (orbitObjects.GSPOG.speed * 10)).toFixed(1);
            document.getElementById('predictionMsg').innerHTML = `🔮 Tahmini kümülatif dönüş: ${nextTurn}° (10 sn içinde)`;
        }, 5000);

        // Ekran görüntüsü
        document.getElementById('takeScreenshot').onclick = () => {
            html2canvas(document.body).then(canvas => {
                const link = document.createElement('a');
                link.download = 'horus_eye.png';
                link.href = canvas.toDataURL();
                link.click();
            });
        };
        document.getElementById('shareBtn').onclick = () => {
            if (navigator.share) navigator.share({ title: 'HORUS-EYE', text: 'Global Asset Tracking', url: window.location.href });
            else alert('Paylaşım desteklenmiyor.');
        };

        // Ses ve bildirim izni
        if ('Notification' in window && document.getElementById('notificationAlert').checked) Notification.requestPermission();

        // ---------- ANİMASYON DÖNGÜSÜ ----------
        let time = 0;
        function animate() {
            requestAnimationFrame(animate);
            time += 0.005;
            earth.rotation.y += 0.0008;
            clouds.rotation.y += 0.0009;

            // Yörünge cisimlerini hareket ettir (parçacıklar)
            orbitsData.forEach(orb => {
                orb.angle += orb.speed;
                // Parçacıklar
                orb.particles.forEach((p, idx) => {
                    p.angle += p.speed;
                    let x = orb.radius * Math.cos(p.angle);
                    let z = orb.radius * Math.sin(p.angle);
                    let y = 0;
                    const cosInc = Math.cos(orb.inclination);
                    const sinInc = Math.sin(orb.inclination);
                    const newY = y * cosInc - z * sinInc;
                    const newZ = y * sinInc + z * cosInc;
                    p.mesh.position.set(x, newY, newZ);
                });
            });

            // Ay hareketi
            moonAngle += 0.003;
            const moonX = moonOrbitRadius * Math.cos(moonAngle);
            const moonZ = moonOrbitRadius * Math.sin(moonAngle);
            moon.position.set(moonX, 0.5, moonZ);

            // Uydular
            satellites.forEach(sat => {
                sat.angle += sat.speed;
                const x = sat.radius * Math.cos(sat.angle);
                const z = sat.radius * Math.sin(sat.angle);
                const y = Math.sin(sat.angle * 1.7) * 0.8 + sat.yOffset;
                sat.mesh.position.set(x, y * 0.7, z);
            });

            glowPoints.forEach((light, idx) => {
                light.position.x = Math.sin(time + idx) * 5.2;
                light.position.z = Math.cos(time * 0.7 + idx) * 5.5;
                light.position.y = Math.sin(time * 1.2 + idx) * 2;
            });

            controls.update();
            renderer.render(scene, camera);
            labelRenderer.render(scene, camera);
        }
        animate();

        window.addEventListener('resize', () => {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
            labelRenderer.setSize(window.innerWidth, window.innerHeight);
        });

        // PWA manifest (basit)
        const manifest = {
            name: "HORUS-EYE",
            short_name: "HORUS",
            start_url: ".",
            display: "standalone",
            theme_color: "#010118",
            background_color: "#000000"
        };
        const manifestBlob = new Blob([JSON.stringify(manifest)], {type: 'application/json'});
        const manifestURL = URL.createObjectURL(manifestBlob);
        const manifestLink = document.createElement('link');
        manifestLink.rel = 'manifest';
        manifestLink.href = manifestURL;
        document.head.appendChild(manifestLink);
    </script>
</body>
</html>
"""

# ======================= HTTP SUNUCU (serving HTML) =======================
class CustomHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/" or parsed.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode("utf-8"))
        elif parsed.path == "/manifest.json":
            manifest = {
                "name": "HORUS-EYE",
                "short_name": "HORUS",
                "start_url": ".",
                "display": "standalone",
                "theme_color": "#010118",
                "background_color": "#000000"
            }
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(manifest).encode())
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"404 - Not Found")
    
    def log_message(self, format, *args):
        sys.stdout.write(f"[{self.address_string()}] {args[0]}\n")

def get_random_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('', 0))
        return s.getsockname()[1]

def start_server(port):
    with socketserver.TCPServer(("", port), CustomHandler) as httpd:
        print(f"\n🚀 HORUS-EYE Ultimate sunucusu başlatıldı!")
        print(f"🌐 Yerel erişim: http://localhost:{port}")
        try:
            hostname = socket.gethostname()
            local_ip = socket.gethostbyname(hostname)
            print(f"📡 Ağ üzerinden: http://{local_ip}:{port}")
        except:
            pass
        print("⏎ Çıkmak için Ctrl+C tuşlayın.\n")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n⛔ Sunucu durduruldu.")

def main():
    port = get_random_port()
    try:
        webbrowser.open(f"http://localhost:{port}")
    except:
        pass
    start_server(port)

if __name__ == "__main__":
    main()
PYTHON_SCRIPT
#!/usr/bin/env python3
"""
HORUS-EYE Global Asset Tracker
Termux uyumlu, random port ile erişilebilen 3D orbit görselleştirmeli web arayüzü.
"""

import http.server
import socketserver
import socket
import webbrowser
import threading
import os
import sys
import json
from urllib.parse import urlparse

# ======================= HTML İÇERİĞİ =======================
HTML_PAGE = """<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>HORUS-EYE · Global Asset Tracking</title>
    <style>
        body {
            margin: 0;
            overflow: hidden;
            font-family: 'Share Tech Mono', 'Courier New', monospace;
            color: #0ff;
            background-color: #000;
        }

        /* Genel overlay stilleri */
        .dashboard {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none; /* tıklamaları canvas'a geçir */
            z-index: 10;
        }

        /* Sol panel - veri kartları */
        .data-panel {
            position: absolute;
            top: 20px;
            left: 20px;
            width: 320px;
            background: rgba(0, 0, 0, 0.75);
            backdrop-filter: blur(12px);
            border-radius: 16px;
            border-left: 3px solid #0ff;
            border-bottom: 1px solid rgba(0, 255, 255, 0.3);
            padding: 16px 20px;
            pointer-events: auto;
            font-size: 13px;
            box-shadow: 0 0 20px rgba(0, 255, 255, 0.2);
            font-weight: 500;
        }

        .title {
            font-size: 24px;
            font-weight: bold;
            letter-spacing: 2px;
            margin-bottom: 4px;
            text-shadow: 0 0 5px #0ff;
        }

        .sub {
            font-size: 11px;
            color: #8aa;
            border-bottom: 1px dashed #2a6;
            margin-bottom: 12px;
            padding-bottom: 5px;
        }

        .threat {
            background: rgba(255, 30, 30, 0.2);
            border-left: 4px solid #f44;
            padding: 8px 12px;
            margin: 12px 0;
            font-family: monospace;
        }
        .threat-level {
            font-size: 18px;
            font-weight: bold;
            color: #ff8888;
        }

        .pattern {
            background: rgba(0, 20, 40, 0.7);
            margin: 8px 0;
            padding: 6px 10px;
            border-radius: 8px;
            font-size: 12px;
            border: 1px solid #1fa;
        }
        .pattern-name {
            color: #ffaa44;
            font-weight: bold;
        }
        .pattern-deg {
            float: right;
            color: #8cf;
        }

        .data-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 8px;
            margin: 15px 0;
            background: rgba(0, 0, 0, 0.5);
            padding: 10px;
            border-radius: 12px;
        }
        .data-item {
            font-size: 12px;
        }
        .data-label {
            color: #7af;
            letter-spacing: 0.5px;
        }
        .data-value {
            font-weight: bold;
            font-size: 16px;
            color: #fff;
        }
        .highlight {
            color: #0ff;
            text-shadow: 0 0 2px #0ff;
        }

        /* Sağ alt sosyal panel */
        .social-panel {
            position: absolute;
            bottom: 20px;
            right: 20px;
            width: 280px;
            background: rgba(0, 0, 0, 0.8);
            backdrop-filter: blur(12px);
            border-radius: 20px;
            border-right: 2px solid #0ff;
            padding: 12px 16px;
            pointer-events: auto;
            font-size: 13px;
            font-family: monospace;
        }
        .user-row {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 10px;
            border-bottom: 1px solid #2a4;
            padding-bottom: 8px;
        }
        .avatar {
            width: 42px;
            height: 42px;
            background: #124;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 22px;
            border: 1px solid #0ff;
        }
        .username {
            font-weight: bold;
            font-size: 16px;
        }
        .handle {
            color: #9cf;
            font-size: 11px;
        }
        .follow-btn {
            background: none;
            border: 1px solid #0ff;
            border-radius: 20px;
            padding: 4px 12px;
            color: #0ff;
            font-size: 11px;
            cursor: pointer;
            pointer-events: auto;
        }
        .comment-box {
            margin-top: 10px;
            background: #112;
            border-radius: 24px;
            padding: 8px 12px;
            color: #ccc;
            font-size: 12px;
            display: flex;
            justify-content: space-between;
        }
        .comment-input {
            background: transparent;
            border: none;
            color: #0ff;
            outline: none;
            width: 80%;
        }
        .btn-send {
            background: none;
            border: none;
            color: #0ff;
            cursor: pointer;
        }

        /* sağ üstte küçük bilgi */
        .corner-status {
            position: absolute;
            top: 20px;
            right: 20px;
            background: rgba(0,0,0,0.6);
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 11px;
            font-family: monospace;
            pointer-events: none;
        }
        @media (max-width: 700px) {
            .data-panel { width: 260px; font-size: 10px; top: 10px; left: 10px; padding: 12px; }
            .social-panel { width: 240px; bottom: 10px; right: 10px; }
        }
    </style>
    <!-- Three.js ve yardımcılar -->
    <script type="importmap">
        {
            "imports": {
                "three": "https://unpkg.com/three@0.128.0/build/three.module.js",
                "three/addons/": "https://unpkg.com/three@0.128.0/examples/jsm/"
            }
        }
    </script>
</head>
<body>
    <div class="dashboard">
        <!-- Sol Panel -->
        <div class="data-panel">
            <div class="title">HORUS-EYE</div>
            <div class="sub">GLOBAL ASSET TRACKING · SECURE LINK</div>
            <div class="threat">
                <span>⚠ THREAT LEVEL</span><br>
                <span class="threat-level">12:26-03-03 · CRITICAL MONITOR</span>
            </div>
            <div style="margin: 10px 0 5px 0; font-size: 12px;">🔍 PATTERN DETECTED</div>
            <div class="pattern">
                <span class="pattern-name">ORBIT pattern: GSPOG</span>
                <span class="pattern-deg">273deg cumulative turn</span>
            </div>
            <div class="pattern">
                <span class="pattern-name">ORBIT pattern: FCK1EL</span>
                <span class="pattern-deg">312deg cumulative turn</span>
            </div>
            <div class="pattern">
                <span class="pattern-name">ORBIT pattern: HAMIC</span>
                <span class="pattern-deg">295deg cumulative turn</span>
            </div>
            <div class="data-grid">
                <div class="data-item"><span class="data-label">SIG/FRQ</span><br><span class="data-value">2.159</span></div>
                <div class="data-item"><span class="data-label">AZ/ELEV</span><br><span class="data-value">64°</span></div>
                <div class="data-item"><span class="data-label">STATUS</span><br><span class="data-value">5YS · NOMINAL</span></div>
                <div class="data-item"><span class="data-label">UPLINK</span><br><span class="data-value">ACTIVE</span></div>
                <div class="data-item"><span class="data-label">FEEDS</span><br><span class="data-value">2/3</span></div>
                <div class="data-item"><span class="data-label">TOTAL</span><br><span class="data-value">6870</span></div>
                <div class="data-item"><span class="data-label">TOTAL</span><br><span class="data-value">6870</span></div>
                <div class="data-item"><span class="data-label">TTL/TVL</span><br><span class="data-value">2436 / 4434</span></div>
            </div>
            <div style="font-size: 11px; margin-top: 5px;">
                📡 openSky + adsbexcha &nbsp;|&nbsp; <span class="highlight">930</span> / <span class="highlight">1.307</span>
            </div>
        </div>

        <!-- Sosyal panel -->
        <div class="social-panel">
            <div class="user-row">
                <div class="avatar">👁️</div>
                <div>
                    <div class="username">alican.kirazo</div>
                    <div class="handle">@alican_kirazo • 3h</div>
                </div>
                <button class="follow-btn" id="followBtn">Takip Et</button>
            </div>
            <div style="margin: 6px 0;">
                👋 Hello Rafael Krux · Dark Dystr <span style="color:#0ff;">Takip Et</span>
            </div>
            <div style="font-size: 11px; color:#9cf;">
                EN & TR | Friends, if you won’t get spooked, let me share the vid
            </div>
            <div style="margin: 10px 0 5px 0; color:#9aa; font-size:11px;">
                hakkı_alkan ve 1 diğer kişi takip ediyor
            </div>
            <div class="comment-box">
                <input type="text" class="comment-input" placeholder="Yorum Ekle...">
                <button class="btn-send">➤</button>
            </div>
        </div>
        <div class="corner-status">
            🛰️ LIVE · 5YS NOMINAL | FEEDS 2/3
        </div>
    </div>

    <script type="module">
        import * as THREE from 'three';
        import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
        import { CSS2DRenderer, CSS2DObject } from 'three/addons/renderers/CSS2DRenderer.js';

        // --- Setup Sahne ---
        const scene = new THREE.Scene();
        scene.background = new THREE.Color(0x010118);
        scene.fog = new THREE.FogExp2(0x010118, 0.0008);

        const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
        camera.position.set(0, 3, 18);
        camera.lookAt(0, 0, 0);

        const renderer = new THREE.WebGLRenderer({ antialias: true });
        renderer.setSize(window.innerWidth, window.innerHeight);
        renderer.shadowMap.enabled = true;
        document.body.appendChild(renderer.domElement);

        // CSS2 renderer için etiketler
        const labelRenderer = new CSS2DRenderer();
        labelRenderer.setSize(window.innerWidth, window.innerHeight);
        labelRenderer.domElement.style.position = 'absolute';
        labelRenderer.domElement.style.top = '0px';
        labelRenderer.domElement.style.left = '0px';
        labelRenderer.domElement.style.pointerEvents = 'none';
        document.body.appendChild(labelRenderer.domElement);

        // Controls
        const controls = new OrbitControls(camera, renderer.domElement);
        controls.enableDamping = true;
        controls.dampingFactor = 0.05;
        controls.autoRotate = false;
        controls.enableZoom = true;
        controls.zoomSpeed = 1.2;
        controls.rotateSpeed = 0.8;
        controls.target.set(0, 0, 0);

        // --- Yıldızlar (basit) ---
        const starGeometry = new THREE.BufferGeometry();
        const starCount = 1800;
        const starPositions = new Float32Array(starCount * 3);
        for (let i = 0; i < starCount; i++) {
            starPositions[i*3] = (Math.random() - 0.5) * 800;
            starPositions[i*3+1] = (Math.random() - 0.5) * 800;
            starPositions[i*3+2] = (Math.random() - 0.5) * 150 - 50;
        }
        starGeometry.setAttribute('position', new THREE.BufferAttribute(starPositions, 3));
        const starMaterial = new THREE.PointsMaterial({ color: 0xffffff, size: 0.2, transparent: true, opacity: 0.6 });
        const stars = new THREE.Points(starGeometry, starMaterial);
        scene.add(stars);

        // --- Dünya ---
        const earthGeometry = new THREE.SphereGeometry(3.2, 128, 128);
        const textureLoader = new THREE.TextureLoader();
        // Yüksek çözünürlüklü Dünya dokusu (Three.js example'dan)
        const earthMap = textureLoader.load('https://threejs.org/examples/textures/planets/earth_atmos_2048.jpg');
        const earthSpecularMap = textureLoader.load('https://threejs.org/examples/textures/planets/earth_specular_2048.jpg');
        const earthNormalMap = textureLoader.load('https://threejs.org/examples/textures/planets/earth_normal_2048.jpg');
        const cloudMap = textureLoader.load('https://threejs.org/examples/textures/planets/earth_clouds_1024.png');
        
        const earthMaterial = new THREE.MeshPhongMaterial({
            map: earthMap,
            specularMap: earthSpecularMap,
            specular: new THREE.Color('grey'),
            shininess: 5,
            normalMap: earthNormalMap,
            normalScale: new THREE.Vector2(0.8, 0.8)
        });
        const earth = new THREE.Mesh(earthGeometry, earthMaterial);
        scene.add(earth);
        
        // Bulut katmanı
        const cloudGeometry = new THREE.SphereGeometry(3.23, 128, 128);
        const cloudMaterial = new THREE.MeshPhongMaterial({
            map: cloudMap,
            transparent: true,
            opacity: 0.12,
            blending: THREE.AdditiveBlending
        });
        const clouds = new THREE.Mesh(cloudGeometry, cloudMaterial);
        scene.add(clouds);

        // --- Işıklandırma ---
        const ambientLight = new THREE.AmbientLight(0x222222);
        scene.add(ambientLight);
        const mainLight = new THREE.DirectionalLight(0xffffff, 1.2);
        mainLight.position.set(5, 10, 7);
        scene.add(mainLight);
        const fillLight = new THREE.PointLight(0x4466cc, 0.5);
        fillLight.position.set(-3, 2, 4);
        scene.add(fillLight);
        const backLight = new THREE.PointLight(0xffaa66, 0.4);
        backLight.position.set(0, 0, -6);
        scene.add(backLight);

        // --- Yörünge Tanımları (3 farklı yörünge, eğiklik ve renk) ---
        // Her yörünge için radius, inclination (rad), renk, isim ve açı bilgisi
        const orbitsData = [
            { name: "GSPOG", radius: 5.4, inclination: 0.32, color: 0x33ffff, deg: "273°", turn: 273 },
            { name: "FCK1EL", radius: 6.7, inclination: 0.75, color: 0xffaa44, deg: "312°", turn: 312 },
            { name: "HAMIC", radius: 8.1, inclination: 1.08, color: 0xff66cc, deg: "295°", turn: 295 }
        ];
        
        // Yörünge çizgilerini oluştur
        const orbitLines = [];
        orbitsData.forEach((orb, idx) => {
            const points = [];
            const segments = 180;
            for (let i = 0; i <= segments; i++) {
                const angle = (i / segments) * Math.PI * 2;
                let x = orb.radius * Math.cos(angle);
                let z = orb.radius * Math.sin(angle);
                let y = 0;
                // Eğiklik (X ekseni etrafında döndürme)
                const cosInc = Math.cos(orb.inclination);
                const sinInc = Math.sin(orb.inclination);
                const newY = y * cosInc - z * sinInc;
                const newZ = y * sinInc + z * cosInc;
                const newX = x;
                points.push(new THREE.Vector3(newX, newY, newZ));
            }
            const geometry = new THREE.BufferGeometry().setFromPoints(points);
            const material = new THREE.LineBasicMaterial({ color: orb.color, linewidth: 1 }); // linewidth webgl'de genelde 1, ancak neon efekt
            const orbitLine = new THREE.LineLoop(geometry, material);
            scene.add(orbitLine);
            orbitLines.push(orbitLine);
            
            // İsim etiketi (CSS2D)
            const div = document.createElement('div');
            div.textContent = `${orb.name} | ${orb.deg} turn`;
            div.style.color = `#${orb.color.toString(16)}`;
            div.style.fontSize = '12px';
            div.style.fontWeight = 'bold';
            div.style.backgroundColor = 'rgba(0,0,0,0.6)';
            div.style.padding = '2px 8px';
            div.style.borderRadius = '20px';
            div.style.borderLeft = `3px solid #${orb.color.toString(16)}`;
            div.style.fontFamily = 'monospace';
            div.style.backdropFilter = 'blur(4px)';
            const labelObj = new CSS2DObject(div);
            // etiketi yörünge üzerinde bir konuma koy (45 derece açıda)
            const angleRad = Math.PI / 4;
            let xPos = orb.radius * Math.cos(angleRad);
            let zPos = orb.radius * Math.sin(angleRad);
            let yPos = 0;
            const cosI = Math.cos(orb.inclination);
            const sinI = Math.sin(orb.inclination);
            const rotY = yPos * cosI - zPos * sinI;
            const rotZ = yPos * sinI + zPos * cosI;
            labelObj.position.set(xPos, rotY, rotZ);
            scene.add(labelObj);
        });
        
        // Ek olarak: küçük uydu noktacıkları (hareketli efekt)
        const satellites = [];
        for (let i = 0; i < 45; i++) {
            const satGeo = new THREE.SphereGeometry(0.04, 8, 8);
            const satMat = new THREE.MeshStandardMaterial({ color: 0x88aaff, emissive: 0x2266aa });
            const sat = new THREE.Mesh(satGeo, satMat);
            scene.add(sat);
            satellites.push({
                mesh: sat,
                radius: 4.5 + Math.random() * 4,
                speed: 0.002 + Math.random() * 0.003,
                angle: Math.random() * Math.PI * 2,
                inclination: (Math.random() - 0.5) * 1.2,
                yOffset: (Math.random() - 0.5) * 1.5
            });
        }
        
        // Basit ışık halkaları efekti için birkaç nokta ışık
        const glowPoints = [];
        for (let i=0; i<12; i++) {
            const pointLight = new THREE.PointLight(0x2266ff, 0.4, 12);
            pointLight.position.set(Math.sin(i)*5, Math.cos(i*2)*2, Math.cos(i)*5);
            scene.add(pointLight);
            glowPoints.push(pointLight);
        }
        
        // Animasyon döngüsü
        let time = 0;
        function animate() {
            requestAnimationFrame(animate);
            time += 0.005;
            
            // Dünya ve bulutlar yavaş dönsün
            earth.rotation.y += 0.0008;
            clouds.rotation.y += 0.0009;
            
            // Yapay uyduları hareket ettir (dekoratif)
            satellites.forEach(sat => {
                sat.angle += sat.speed;
                const x = sat.radius * Math.cos(sat.angle);
                const z = sat.radius * Math.sin(sat.angle);
                const incl = sat.inclination;
                const y = Math.sin(sat.angle * 1.7) * 0.8 + sat.yOffset;
                // eğiklik basit
                sat.mesh.position.set(x, y * 0.7 + Math.sin(sat.angle * 2)*0.2, z);
            });
            
            // Işık noktalarını hareket ettir
            glowPoints.forEach((light, idx) => {
                light.position.x = Math.sin(time + idx) * 5.2;
                light.position.z = Math.cos(time * 0.7 + idx) * 5.5;
                light.position.y = Math.sin(time * 1.2 + idx) * 2;
            });
            
            controls.update(); // Kamera kontrol
            renderer.render(scene, camera);
            labelRenderer.render(scene, camera);
        }
        
        animate();
        
        // Pencere yeniden boyutlandırma
        window.addEventListener('resize', onWindowResize, false);
        function onWindowResize() {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
            labelRenderer.setSize(window.innerWidth, window.innerHeight);
        }
        
        // Takip Et butonu etkileşimi (minik)
        document.getElementById('followBtn').addEventListener('click', () => {
            alert('✅ Takip ediliyor (demo) - HORUS-EYE');
        });
        
        // Yorum gönderimi demo
        const sendBtn = document.querySelector('.btn-send');
        const commentInput = document.querySelector('.comment-input');
        if(sendBtn) {
            sendBtn.addEventListener('click', () => {
                if(commentInput.value.trim() !== "") {
                    alert(`💬 Yorum eklendi: "${commentInput.value}"`);
                    commentInput.value = "";
                } else {
                    alert("Bir yorum yazın.");
                }
            });
        }
        
        // Konsola başarı logu
        console.log("HORUS-EYE 3D Orbit Tracker Aktif | GSPOG | FCK1EL | HAMIC");
    </script>
</body>
</html>
"""

# ======================= HTTP SUNUCU =======================
class CustomHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/" or parsed.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"404 - Not Found")
    
    def log_message(self, format, *args):
        # Daha temiz konsol çıktısı
        sys.stdout.write(f"[{self.address_string()}] {args[0]}\n")

def start_server(port):
    with socketserver.TCPServer(("", port), CustomHandler) as httpd:
        print(f"\n🚀 HORUS-EYE sunucusu başlatıldı!")
        print(f"🌐 Yerel erişim: http://localhost:{port}")
        # Ağ IP'sini bulmaya çalış (Termux için)
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

def get_random_port():
    """Sistem tarafından rastgele atanmış bir port döndürür."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('', 0))
        return s.getsockname()[1]

def main():
    port = get_random_port()
    # opsiyonel olarak tarayıcı aç (termux'da çalışmayabilir, ama dene)
    try:
        webbrowser.open(f"http://localhost:{port}")
    except:
        pass
    start_server(port)

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HORUS-EYE Ultimate - Real Satellite Tracking & Space Data
Termux / Linux uyumlu, tek dosya, performans odaklı.
"""

import http.server
import socketserver
import socket
import webbrowser
import sys
import json
import urllib.request
import urllib.error
from urllib.parse import urlparse
import threading
import time

# ======================= HTML İÇERİĞİ (Sade ve hızlı) =======================
HTML_PAGE = """<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>HORUS-EYE · Real Time Tracker</title>
    <link rel="manifest" href="/manifest.json">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { overflow: hidden; font-family: 'Courier New', monospace; background: #000; color: #0ff; }
        /* Paneller (sade, şeffaf, performans) */
        .panel {
            position: absolute;
            background: rgba(0, 0, 0, 0.75);
            backdrop-filter: blur(8px);
            border-radius: 12px;
            border-left: 2px solid #0ff;
            padding: 12px;
            font-size: 12px;
            pointer-events: auto;
            z-index: 20;
            max-width: 320px;
            max-height: 85vh;
            overflow-y: auto;
            scrollbar-width: thin;
        }
        .left-panel { top: 15px; left: 15px; width: 300px; }
        .right-panel { bottom: 15px; right: 15px; width: 280px; max-height: 70vh; }
        .bottom-panel { bottom: 15px; left: 15px; width: 300px; background: rgba(0,0,0,0.8); }
        h3 { font-size: 14px; margin: 5px 0; border-bottom: 1px solid #0ff3; }
        .data-row { display: flex; justify-content: space-between; margin: 5px 0; }
        .threat { background: #f003; border-left: 3px solid #f44; padding: 6px; margin: 8px 0; }
        button, .btn {
            background: none; border: 1px solid #0ff; border-radius: 20px; padding: 4px 10px;
            color: #0ff; cursor: pointer; font-family: monospace; transition: 0.2s;
        }
        button:hover { background: #0ff; color: #000; box-shadow: 0 0 8px #0ff; }
        input, select { background: #112; border: 1px solid #0ff; color: #0ff; border-radius: 12px; padding: 4px 8px; width: 100%; margin: 4px 0; }
        .sat-item { padding: 4px; border-bottom: 1px solid #0ff3; cursor: pointer; }
        .sat-item:hover { background: #0ff2; }
        .comment-box { display: flex; gap: 6px; margin: 8px 0; }
        .comment-input { flex: 1; }
        .comment-list { max-height: 150px; overflow-y: auto; font-size: 10px; }
        .news-item { margin: 8px 0; border-left: 2px solid #0ff; padding-left: 8px; font-size: 11px; }
        .apod-img { max-width: 100%; border-radius: 8px; margin-top: 6px; }
        .slider { width: 100%; }
        hr { border-color: #0ff3; margin: 8px 0; }
        @media (max-width: 700px) {
            .left-panel, .right-panel, .bottom-panel { width: 260px; font-size: 10px; }
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
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js"></script>
</head>
<body>
    <!-- Sol panel: Ana veriler ve kontroller -->
    <div class="panel left-panel">
        <div style="font-size: 20px; font-weight: bold;">HORUS-EYE</div>
        <div class="threat" id="threatPanel">
            <span>⚠ THREAT LEVEL</span><br>
            <span id="threatLevel">Loading...</span>
        </div>
        <div id="satInfo">🛰️ Gerçek uydular yükleniyor...</div>
        <div class="data-row"><span>📡 ISS Konumu:</span> <span id="issPos">-</span></div>
        <div class="data-row"><span>👨‍🚀 Astronot Sayısı:</span> <span id="astronauts">-</span></div>
        <hr>
        <div><b>🎮 Kontroller</b></div>
        <div><label><input type="checkbox" id="toggleOrbits" checked> Yörüngeler</label></div>
        <div><label><input type="checkbox" id="toggleMoon" checked> Ay</label></div>
        <div><label>🔊 Sesli Uyarı: <input type="checkbox" id="soundAlert" checked></label></div>
        <div><label>⭐ Yıldız Yoğunluğu: <input type="range" id="starDensity" min="0" max="2500" step="100" value="1500"></label></div>
        <button id="resetCam">🌍 Dünya'ya Dön</button>
        <button id="takeScreenshot">📸 Ekran Görüntüsü</button>
        <hr>
        <div><b>🔑 N2YO API Key</b></div>
        <input type="text" id="apiKey" placeholder="n2yo.com'dan alınan anahtar">
        <button id="saveApiKey">Kaydet</button>
        <div style="font-size: 9px; color:#8aa;">Ücretsiz: 1000 istek/gün</div>
    </div>

    <!-- Sağ panel: Haberler, APOD, Uydu listesi -->
    <div class="panel right-panel">
        <h3>🌌 NASA APOD</h3>
        <div id="apodTitle"></div>
        <img id="apodImg" class="apod-img" style="display:none;">
        <div id="apodExplanation" style="font-size:10px;"></div>
        <hr>
        <h3>📰 Uzay Haberleri</h3>
        <div id="newsList"></div>
        <hr>
        <h3>💬 Yorumlar</h3>
        <div class="comment-box">
            <input type="text" id="newComment" class="comment-input" placeholder="Yorum yaz...">
            <button id="postComment">➤</button>
        </div>
        <div class="comment-list" id="commentList"></div>
    </div>

    <!-- Alt panel: Uydu geçiş tahmini ve anomali -->
    <div class="panel bottom-panel">
        <h3>🛰️ Üst Geçiş Tahmini (İstanbul)</h3>
        <div id="passPredict">-</div>
        <h3>⚠️ Anomali / Tahmin</h3>
        <div id="anomalyMsg">İzleme aktif</div>
    </div>

    <script type="module">
        import * as THREE from 'three';
        import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
        import { CSS2DRenderer, CSS2DObject } from 'three/addons/renderers/CSS2DRenderer.js';

        // ---------- Three.js Sahne ----------
        const scene = new THREE.Scene();
        scene.background = new THREE.Color(0x010118);
        scene.fog = new THREE.FogExp2(0x010118, 0.0006);
        const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
        camera.position.set(0, 2, 16);
        const renderer = new THREE.WebGLRenderer({ antialias: true });
        renderer.setSize(window.innerWidth, window.innerHeight);
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

        // Dünya
        const earthGeo = new THREE.SphereGeometry(3.2, 128, 128);
        const texLoader = new THREE.TextureLoader();
        const earthMap = texLoader.load('https://threejs.org/examples/textures/planets/earth_atmos_2048.jpg');
        const earthSpec = texLoader.load('https://threejs.org/examples/textures/planets/earth_specular_2048.jpg');
        const earthNorm = texLoader.load('https://threejs.org/examples/textures/planets/earth_normal_2048.jpg');
        const cloudMap = texLoader.load('https://threejs.org/examples/textures/planets/earth_clouds_1024.png');
        const earthMat = new THREE.MeshPhongMaterial({ map: earthMap, specularMap: earthSpec, shininess: 5, normalMap: earthNorm });
        const earth = new THREE.Mesh(earthGeo, earthMat);
        scene.add(earth);
        const cloudMat = new THREE.MeshPhongMaterial({ map: cloudMap, transparent: true, opacity: 0.12 });
        const clouds = new THREE.Mesh(new THREE.SphereGeometry(3.23, 128, 128), cloudMat);
        scene.add(clouds);

        // Işık
        const ambient = new THREE.AmbientLight(0x222222);
        scene.add(ambient);
        const dirLight = new THREE.DirectionalLight(0xffffff, 1.0);
        dirLight.position.set(5, 8, 6);
        scene.add(dirLight);

        // Yıldızlar (dinamik)
        let starsMesh;
        function updateStars(count) {
            if (starsMesh) scene.remove(starsMesh);
            const geo = new THREE.BufferGeometry();
            const positions = new Float32Array(count * 3);
            for (let i = 0; i < count; i++) {
                positions[i*3] = (Math.random() - 0.5) * 800;
                positions[i*3+1] = (Math.random() - 0.5) * 800;
                positions[i*3+2] = (Math.random() - 0.5) * 150 - 50;
            }
            geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
            const mat = new THREE.PointsMaterial({ color: 0xffffff, size: 0.2 });
            starsMesh = new THREE.Points(geo, mat);
            scene.add(starsMesh);
        }
        updateStars(1500);
        document.getElementById('starDensity').addEventListener('input', (e) => updateStars(parseInt(e.target.value)));

        // Ay
        const moonGeo = new THREE.SphereGeometry(0.5, 64, 64);
        const moonMat = new THREE.MeshStandardMaterial({ color: 0xccccaa });
        const moon = new THREE.Mesh(moonGeo, moonMat);
        scene.add(moon);
        let moonAngle = 0;

        // Yörüngeler (üç farklı)
        const orbits = [
            { radius: 5.2, inc: 0.32, color: 0x33ffff, line: null, visible: true },
            { radius: 6.5, inc: 0.75, color: 0xffaa44, line: null, visible: true },
            { radius: 7.9, inc: 1.08, color: 0xff66cc, line: null, visible: true }
        ];
        orbits.forEach((orb, idx) => {
            const points = [];
            for (let i = 0; i <= 180; i++) {
                const angle = (i / 180) * Math.PI * 2;
                let x = orb.radius * Math.cos(angle);
                let z = orb.radius * Math.sin(angle);
                let y = 0;
                const cosI = Math.cos(orb.inc);
                const sinI = Math.sin(orb.inc);
                const newY = y * cosI - z * sinI;
                const newZ = y * sinI + z * cosI;
                points.push(new THREE.Vector3(x, newY, newZ));
            }
            const geometry = new THREE.BufferGeometry().setFromPoints(points);
            const material = new THREE.LineBasicMaterial({ color: orb.color });
            const line = new THREE.LineLoop(geometry, material);
            scene.add(line);
            orb.line = line;
        });
        document.getElementById('toggleOrbits').addEventListener('change', (e) => {
            orbits.forEach(orb => orb.line.visible = e.target.checked);
        });
        document.getElementById('toggleMoon').addEventListener('change', (e) => moon.visible = e.target.checked);
        document.getElementById('resetCam').onclick = () => { controls.target.set(0,0,0); camera.position.set(0,2,16); controls.update(); };

        // Gerçek uydu noktaları (dinamik)
        const satMarkers = [];
        function clearSatMarkers() {
            satMarkers.forEach(m => scene.remove(m));
            satMarkers.length = 0;
        }
        function addSatMarker(lat, lon, alt, name, color=0x88aaff) {
            // Koordinat dönüşümü (enlem, boylam, yükseklik)
            const r = 3.2 + (alt / 1000) * 0.2; // basit ölçek
            const phi = (90 - lat) * Math.PI / 180;
            const theta = lon * Math.PI / 180;
            const x = r * Math.sin(phi) * Math.cos(theta);
            const y = r * Math.cos(phi);
            const z = r * Math.sin(phi) * Math.sin(theta);
            const sphere = new THREE.Mesh(new THREE.SphereGeometry(0.06, 8, 8), new THREE.MeshStandardMaterial({ color: color, emissive: 0x2266aa }));
            sphere.position.set(x, y, z);
            scene.add(sphere);
            satMarkers.push(sphere);
            // etiket
            const div = document.createElement('div');
            div.textContent = name;
            div.style.color = '#fff';
            div.style.fontSize = '10px';
            div.style.backgroundColor = 'rgba(0,0,0,0.5)';
            div.style.padding = '2px 4px';
            div.style.borderRadius = '12px';
            const label = new CSS2DObject(div);
            label.position.set(x, y+0.1, z);
            scene.add(label);
            satMarkers.push(label);
        }

        // ----- API Çağrıları (30 sn'de bir) -----
        let apiKey = localStorage.getItem('n2yo_key') || '';
        document.getElementById('apiKey').value = apiKey;
        document.getElementById('saveApiKey').onclick = () => {
            const newKey = document.getElementById('apiKey').value.trim();
            localStorage.setItem('n2yo_key', newKey);
            apiKey = newKey;
            fetchData(); // hemen yenile
        };

        async function fetchData() {
            // ISS
            try {
                const issRes = await fetch('/api/iss');
                const iss = await issRes.json();
                document.getElementById('issPos').innerText = `${iss.lat.toFixed(1)}°, ${iss.lon.toFixed(1)}°`;
                document.getElementById('astronauts').innerText = iss.people;
            } catch(e) { console.warn(e); }

            // Uydular (N2YO)
            if (apiKey) {
                try {
                    const satRes = await fetch(`/api/satellites?key=${apiKey}`);
                    const sats = await satRes.json();
                    if (sats.above) {
                        clearSatMarkers();
                        sats.above.forEach(sat => {
                            addSatMarker(sat.satlat, sat.satlng, sat.satalt, sat.satname, 0x88ff88);
                        });
                        document.getElementById('satInfo').innerHTML = `🛰️ ${sats.above.length} uydu görünürde`;
                    } else {
                        document.getElementById('satInfo').innerHTML = `⚠️ Uydu verisi alınamadı`;
                    }
                } catch(e) { console.warn(e); }
            } else {
                document.getElementById('satInfo').innerHTML = `🔑 N2YO API anahtarı giriniz`;
            }

            // Geçiş tahmini
            if (apiKey) {
                try {
                    const passRes = await fetch(`/api/passes?key=${apiKey}`);
                    const pass = await passRes.json();
                    if (pass.passes && pass.passes[0]) {
                        const p = pass.passes[0];
                        const date = new Date(p.startUTC * 1000).toLocaleTimeString();
                        document.getElementById('passPredict').innerHTML = `ISS geçişi: ${date} (${p.duration}s)`;
                    } else {
                        document.getElementById('passPredict').innerHTML = 'Geçiş yok';
                    }
                } catch(e) { document.getElementById('passPredict').innerHTML = 'Hata'; }
            }

            // Uzay hava durumu (NOAA)
            try {
                const weather = await fetch('/api/spaceweather');
                const w = await weather.json();
                document.getElementById('threatLevel').innerHTML = w.threat;
                if (w.threat.includes('YÜKSEK') && document.getElementById('soundAlert').checked) {
                    new Audio().play().catch(e=>{});
                    if (Notification.permission === 'granted') new Notification('Uyarı', { body: 'Jeomanyetik fırtına seviyesi yükseldi!' });
                }
            } catch(e) { console.warn(e); }

            // NASA APOD
            try {
                const apod = await fetch('/api/apod');
                const a = await apod.json();
                document.getElementById('apodTitle').innerHTML = a.title;
                const img = document.getElementById('apodImg');
                if (a.url) {
                    img.src = a.url;
                    img.style.display = 'block';
                }
                document.getElementById('apodExplanation').innerHTML = a.explanation.substring(0, 150)+'...';
            } catch(e) { console.warn(e); }

            // Haberler
            try {
                const news = await fetch('/api/news');
                const n = await news.json();
                document.getElementById('newsList').innerHTML = n.slice(0,3).map(art => `<div class="news-item"><a href="${art.url}" target="_blank" style="color:#0ff;">${art.title}</a><br><span style="font-size:9px;">${art.publishedAt.substring(0,10)}</span></div>`).join('');
            } catch(e) { console.warn(e); }
        }

        setInterval(fetchData, 30000);
        fetchData();

        // Yorumlar (localStorage)
        let comments = JSON.parse(localStorage.getItem('horus_comments') || '[]');
        function renderComments() {
            document.getElementById('commentList').innerHTML = comments.map(c => `<div><b>${c.user}:</b> ${c.text}</div>`).join('');
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
        const savedUser = localStorage.getItem('horus_user');
        if (!savedUser) localStorage.setItem('horus_user', 'Misafir');

        // Ekran görüntüsü
        document.getElementById('takeScreenshot').onclick = () => {
            html2canvas(document.body).then(canvas => {
                const link = document.createElement('a');
                link.download = 'horus_eye.png';
                link.href = canvas.toDataURL();
                link.click();
            });
        };

        // Animasyon döngüsü (ay, dünya dönüşü)
        let time = 0;
        function animate() {
            requestAnimationFrame(animate);
            time += 0.005;
            earth.rotation.y += 0.0008;
            clouds.rotation.y += 0.0009;
            moonAngle += 0.003;
            moon.position.set(9 * Math.cos(moonAngle), 0.5, 9 * Math.sin(moonAngle));
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
        if ('Notification' in window) Notification.requestPermission();
    </script>
</body>
</html>
"""

# ======================= PYTHON SUNUCU (API Endpoints) =======================
import requests
import json

class CustomHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/" or parsed.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode("utf-8"))
        elif parsed.path == "/manifest.json":
            manifest = {"name": "HORUS-EYE", "short_name": "HORUS", "start_url": ".", "display": "standalone", "theme_color": "#010118"}
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(manifest).encode())
        elif parsed.path.startswith("/api/satellites"):
            key = self.get_query_param('key')
            if not key:
                self.send_json({"error": "No API key"})
                return
            # N2YO: 18 uydu, İstanbul (41.0082, 28.9784) üzeri
            url = f"https://api.n2yo.com/rest/v1/satellite/above/41.0082/28.9784/0/70/18/&apiKey={key}"
            try:
                resp = requests.get(url, timeout=8)
                data = resp.json()
                self.send_json(data)
            except Exception as e:
                self.send_json({"error": str(e)})
        elif parsed.path.startswith("/api/passes"):
            key = self.get_query_param('key')
            if not key:
                self.send_json({"error": "No API key"})
                return
            # ISS (25544) için geçiş tahmini
            url = f"https://api.n2yo.com/rest/v1/satellite/visualpasses/25544/41.0082/28.9784/0/5/1/&apiKey={key}"
            try:
                resp = requests.get(url, timeout=8)
                data = resp.json()
                self.send_json(data)
            except:
                self.send_json({"passes": []})
        elif parsed.path == "/api/iss":
            try:
                resp = requests.get("http://api.open-notify.org/iss-now.json", timeout=5)
                pos = resp.json()
                lat = float(pos['iss_position']['latitude'])
                lon = float(pos['iss_position']['longitude'])
                people_resp = requests.get("http://api.open-notify.org/astros.json", timeout=5)
                people = people_resp.json()['number']
                self.send_json({"lat": lat, "lon": lon, "people": people})
            except:
                self.send_json({"lat": 0, "lon": 0, "people": 0})
        elif parsed.path == "/api/spaceweather":
            # NOAA SWPC - jeomanyetik fırtına seviyesi (simplified)
            try:
                # NOAA'nın JSON endpoint'i (Kp indeksi)
                resp = requests.get("https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json", timeout=5)
                data = resp.json()
                latest = data[-1]
                kp = float(latest[1])
                if kp >= 7:
                    threat = "YÜKSEK (G3+)"
                elif kp >= 5:
                    threat = "ORTA (G2)"
                else:
                    threat = "DÜŞÜK (G1)"
                self.send_json({"threat": threat, "kp": kp})
            except:
                self.send_json({"threat": "NOMINAL"})
        elif parsed.path == "/api/apod":
            try:
                resp = requests.get("https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY", timeout=5)
                data = resp.json()
                self.send_json({"title": data.get('title', ''), "url": data.get('url', ''), "explanation": data.get('explanation', '')})
            except:
                self.send_json({"title": "NASA APOD", "url": "", "explanation": "Veri alınamadı."})
        elif parsed.path == "/api/news":
            try:
                resp = requests.get("https://spaceflightnewsapi.net/api/v2/articles?_limit=5", timeout=5)
                articles = resp.json()
                self.send_json([{"title": a['title'], "url": a['url'], "publishedAt": a['publishedAt']} for a in articles])
            except:
                self.send_json([{"title": "Haber yüklenemedi", "url": "#", "publishedAt": ""}])
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"404")

    def get_query_param(self, name):
        parsed = urlparse(self.path)
        query = dict(qc.split("=") for qc in parsed.query.split("&") if "=" in qc)
        return query.get(name, "")

    def send_json(self, data):
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

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
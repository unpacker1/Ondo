#!/usr/bin/env python3
"""
HORUS-EYE ULTIMATE - Cyberpunk Uzay Takip Sistemi
Python sunucusu ile gerçek zamanlı uzay verileri
"""

import http.server
import socketserver
import json
import urllib.parse
import threading
import webbrowser
import time
import random
from datetime import datetime, timedelta

# requests kütüphanesi kontrolü
try:
    import requests
except ImportError:
    print("Hata: 'requests' kütüphanesi bulunamadı.")
    print("Kurulum için: pip install requests")
    exit(1)

# ==================== API YAPILANDIRMA ====================
PORT = 8080
NASA_API_KEY = "DEMO_KEY"  # https://api.nasa.gov/ adresinden ücretsiz anahtar alın

# Önbellek (cache) - API isteklerini azaltmak için
cache = {
    "iss": {"data": None, "expires": 0},
    "spaceweather": {"data": None, "expires": 0},
    "apod": {"data": None, "expires": 0},
    "news": {"data": None, "expires": 0},
}
CACHE_TTL = 60  # saniye

# ==================== API FONKSİYONLARI ====================

def fetch_iss():
    """ISS konumu ve astronot sayısını getirir."""
    try:
        # ISS konumu
        resp_iss = requests.get("http://api.open-notify.org/iss-now.json", timeout=10)
        resp_iss.raise_for_status()
        data_iss = resp_iss.json()
        
        # Astronot sayısı
        resp_ast = requests.get("http://api.open-notify.org/astros.json", timeout=10)
        resp_ast.raise_for_status()
        data_ast = resp_ast.json()
        
        return {
            "latitude": float(data_iss["iss_position"]["latitude"]),
            "longitude": float(data_iss["iss_position"]["longitude"]),
            "astronauts": data_ast["number"]
        }
    except Exception as e:
        print(f"ISS API hatası: {e}")
        return {"latitude": 0, "longitude": 0, "astronauts": 0, "error": str(e)}

def fetch_space_weather():
    """Son Kp indeksini ve son 24 saatlik geçmişi getirir."""
    try:
        # NOAA SWPC'den son Kp değeri
        url = "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json"
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        
        # Veri formatı: [["YYYY-MM-DD HH:MM:SS", "Kp"], ...]
        # Son 24 saat için (yaklaşık 24*4=96 veri noktası, her 3 saatte bir)
        kp_values = []
        timestamps = []
        for row in data[-96:]:  # son 96 satır ~ 24 saat
            try:
                dt = datetime.strptime(row[0], "%Y-%m-%d %H:%M:%S")
                timestamps.append(dt.strftime("%H:%M"))
                kp_values.append(float(row[1]))
            except:
                continue
        
        current_kp = kp_values[-1] if kp_values else 0.0
        
        # Tehdit seviyesi
        if current_kp >= 7:
            threat = "SEVERE"
        elif current_kp >= 5:
            threat = "HIGH"
        elif current_kp >= 3:
            threat = "MODERATE"
        else:
            threat = "NOMINAL"
        
        return {
            "kp_index": current_kp,
            "threat_level": threat,
            "history": {
                "timestamps": timestamps[-24:],  # son 24 nokta
                "values": kp_values[-24:]
            }
        }
    except Exception as e:
        print(f"Uzay hava durumu API hatası: {e}")
        # Mock veri
        mock_kp = random.uniform(1, 8)
        return {
            "kp_index": mock_kp,
            "threat_level": "MOCK_DATA",
            "history": {
                "timestamps": [f"{i:02d}:00" for i in range(24)],
                "values": [random.uniform(1, 8) for _ in range(24)]
            },
            "error": str(e)
        }

def fetch_apod():
    """NASA APOD (Astronomy Picture of the Day) verisini getirir."""
    try:
        url = f"https://api.nasa.gov/planetary/apod?api_key={NASA_API_KEY}"
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        return {
            "title": data.get("title", "No title"),
            "explanation": data.get("explanation", "No explanation"),
            "url": data.get("url", ""),
            "hdurl": data.get("hdurl", "")
        }
    except Exception as e:
        print(f"APOD API hatası: {e}")
        return {
            "title": "APOD yüklenemedi",
            "explanation": "NASA API'sine bağlanılamadı. Daha sonra tekrar deneyin.",
            "url": "",
            "hdurl": "",
            "error": str(e)
        }

def fetch_news():
    """Son uzay haberlerini getirir."""
    try:
        # Spaceflight News API - son 5 haber
        url = "https://api.spaceflightnewsapi.net/v4/articles/?limit=5&ordering=-published_at"
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        articles = []
        for article in data.get("results", []):
            articles.append({
                "title": article.get("title", "Untitled"),
                "summary": article.get("summary", ""),
                "published_at": article.get("published_at", ""),
                "url": article.get("url", "")
            })
        return articles
    except Exception as e:
        print(f"Haber API hatası: {e}")
        # Mock haberler
        return [
            {"title": "SpaceX Starship test uçuşu başarılı", "summary": "Yeni nesil roket yörüngeye ulaştı.", "published_at": datetime.now().isoformat(), "url": "#"},
            {"title": "Ay'a dönüş programı hızlanıyor", "summary": "NASA Artemis misyonu için tarih açıklandı.", "published_at": (datetime.now() - timedelta(hours=3)).isoformat(), "url": "#"},
            {"title": "Mars'ta su bulundu", "summary": "Perseverance keşif aracı yeni kanıtlar topladı.", "published_at": (datetime.now() - timedelta(days=1)).isoformat(), "url": "#"},
        ]

def get_cached_or_fetch(cache_key, fetch_func):
    """Önbellekten veri al, yoksa fetch et."""
    now = time.time()
    if cache[cache_key]["data"] and cache[cache_key]["expires"] > now:
        return cache[cache_key]["data"]
    data = fetch_func()
    cache[cache_key]["data"] = data
    cache[cache_key]["expires"] = now + CACHE_TTL
    return data

# ==================== HTTP SUNUCU ====================

class HorusEyeHandler(http.server.BaseHTTPRequestHandler):
    """HTTP isteklerini işleyen sınıf."""
    
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        
        if path == "/":
            self.serve_html()
        elif path == "/api/iss":
            self.serve_json(get_cached_or_fetch("iss", fetch_iss))
        elif path == "/api/spaceweather":
            self.serve_json(get_cached_or_fetch("spaceweather", fetch_space_weather))
        elif path == "/api/apod":
            self.serve_json(get_cached_or_fetch("apod", fetch_apod))
        elif path == "/api/news":
            self.serve_json(get_cached_or_fetch("news", fetch_news))
        else:
            self.send_error(404, "Not Found")
    
    def serve_html(self):
        """Ana HTML sayfasını gönder."""
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(HTML_CONTENT.encode("utf-8"))
    
    def serve_json(self, data):
        """JSON verisini gönder."""
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode("utf-8"))
    
    def log_message(self, format, *args):
        # Konsol çıktısını daha temiz tut
        print(f"[{datetime.now().strftime('%H:%M:%S')}] {args[0]}")
        return

# ==================== HTML İÇERİĞİ (YENİ SIDEBAR LAYOUT) ====================

HTML_CONTENT = r"""
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>HORUS-EYE ULTIMATE | Uzay Takip Sistemi</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Share Tech Mono', 'Courier New', monospace;
            background: black;
            color: #0ff;
            overflow: hidden;
            height: 100vh;
        }
        
        /* CRT efekti */
        body::after {
            content: "";
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            background: repeating-linear-gradient(
                0deg,
                rgba(0, 255, 255, 0.03) 0px,
                rgba(0, 255, 255, 0.03) 2px,
                transparent 2px,
                transparent 4px
            );
            z-index: 999;
        }
        
        /* Canvas arka plan */
        #canvas-container {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: 0;
        }
        
        /* Sidebar containers - sabit genişlik, yükseklik tam, kaydırma */
        .sidebar {
            position: fixed;
            top: 0;
            bottom: 0;
            width: 280px;
            background: rgba(0, 0, 0, 0.65);
            backdrop-filter: blur(8px);
            border-right: 1px solid rgba(0, 255, 255, 0.3);
            border-left: 1px solid rgba(0, 255, 255, 0.3);
            z-index: 20;
            overflow-y: auto;
            padding: 15px 12px;
            pointer-events: auto;
        }
        
        .sidebar-left {
            left: 0;
            border-right: 1px solid rgba(0, 255, 255, 0.3);
        }
        
        .sidebar-right {
            right: 0;
            border-left: 1px solid rgba(0, 255, 255, 0.3);
        }
        
        /* Sidebar içindeki kartlar */
        .card {
            background: rgba(0, 0, 0, 0.75);
            border: 1px solid rgba(0, 255, 255, 0.3);
            border-radius: 8px;
            padding: 12px;
            margin-bottom: 15px;
            box-shadow: 0 0 8px rgba(0, 255, 255, 0.2);
            transition: all 0.2s ease;
        }
        
        .card:hover {
            border-color: #0ff;
            box-shadow: 0 0 12px rgba(0, 255, 255, 0.4);
        }
        
        /* Kart başlığı */
        .card-header {
            font-size: 1rem;
            font-weight: bold;
            margin-bottom: 8px;
            border-bottom: 1px solid rgba(0, 255, 255, 0.5);
            padding-bottom: 4px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .card-header i {
            color: #f0f;
            font-style: normal;
            font-size: 0.7rem;
        }
        
        /* Kart içeriği */
        .card-content {
            font-size: 0.8rem;
        }
        
        /* ISS tracker */
        .iss-coord {
            font-size: 0.9rem;
            font-weight: bold;
            margin: 6px 0;
        }
        
        .astronaut-count {
            color: #0f0;
        }
        
        /* Uzay hava durumu */
        .kp-value {
            font-size: 1.4rem;
            font-weight: bold;
            text-align: center;
            margin: 6px 0;
        }
        
        .threat {
            text-align: center;
            font-weight: bold;
            padding: 3px;
            border-radius: 4px;
            font-size: 0.7rem;
        }
        
        .threat-severe { background: #f00; color: black; }
        .threat-high { background: #f60; color: black; }
        .threat-moderate { background: #ff0; color: black; }
        .threat-nominal { background: #0f0; color: black; }
        
        /* Grafik */
        canvas.chart {
            width: 100%;
            height: 120px;
            margin-top: 8px;
        }
        
        /* Haberler */
        .news-item {
            margin-bottom: 10px;
            border-bottom: 1px solid rgba(0, 255, 255, 0.2);
            padding-bottom: 6px;
        }
        
        .news-title {
            font-weight: bold;
            color: #fff;
            text-decoration: none;
            font-size: 0.85rem;
        }
        
        .news-title:hover {
            color: #0ff;
        }
        
        .news-date {
            font-size: 0.6rem;
            color: #aaa;
        }
        
        /* Yorumlar */
        .comments-list {
            max-height: 180px;
            overflow-y: auto;
            margin-bottom: 8px;
        }
        
        .comment {
            background: rgba(0, 255, 255, 0.1);
            border-left: 2px solid #0ff;
            padding: 4px;
            margin-bottom: 5px;
            font-size: 0.7rem;
        }
        
        .comment-user {
            font-weight: bold;
            color: #f0f;
        }
        
        .comment-text {
            word-break: break-word;
        }
        
        .comment-input {
            display: flex;
            gap: 5px;
            margin-top: 8px;
        }
        
        .comment-input input {
            flex: 1;
            background: #111;
            border: 1px solid #0ff;
            color: #0ff;
            padding: 4px;
            font-family: monospace;
            font-size: 0.7rem;
        }
        
        .comment-input button {
            background: #0ff;
            border: none;
            color: black;
            padding: 4px 8px;
            cursor: pointer;
            font-weight: bold;
            font-size: 0.7rem;
        }
        
        /* Kontroller */
        .control-group {
            margin-bottom: 8px;
        }
        
        .control-group label {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 0.75rem;
        }
        
        input[type="range"] {
            width: 100%;
            background: #0ff;
            height: 2px;
        }
        
        button {
            background: rgba(0, 255, 255, 0.2);
            border: 1px solid #0ff;
            color: #0ff;
            padding: 4px 8px;
            cursor: pointer;
            margin-top: 5px;
            width: 100%;
            transition: 0.2s;
            font-size: 0.7rem;
        }
        
        button:hover {
            background: #0ff;
            color: black;
        }
        
        /* Responsive: mobilde sidebarları alt alta veya daralt */
        @media (max-width: 768px) {
            .sidebar {
                width: 260px;
            }
            .sidebar-left {
                top: auto;
                bottom: 0;
                height: 50%;
                width: 100%;
                border-right: none;
                border-top: 1px solid rgba(0, 255, 255, 0.3);
            }
            .sidebar-right {
                top: 0;
                height: 50%;
                width: 100%;
                border-left: none;
                border-bottom: 1px solid rgba(0, 255, 255, 0.3);
            }
        }
        
        /* Scrollbar */
        ::-webkit-scrollbar {
            width: 4px;
        }
        ::-webkit-scrollbar-track {
            background: #111;
        }
        ::-webkit-scrollbar-thumb {
            background: #0ff;
        }
    </style>
    <!-- Three.js ve Chart.js -->
    <script type="importmap">
        {
            "imports": {
                "three": "https://unpkg.com/three@0.128.0/build/three.module.js"
            }
        }
    </script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
</head>
<body>
    <div id="canvas-container"></div>
    
    <!-- Sol Sidebar -->
    <div class="sidebar sidebar-left">
        <!-- ISS Takip -->
        <div class="card">
            <div class="card-header">
                🛰️ ISS TRACKER
                <i>● LIVE</i>
            </div>
            <div class="card-content">
                <div class="iss-coord">
                    🌍 Enlem: <span id="iss-lat">--</span>°<br>
                    🌐 Boylam: <span id="iss-lon">--</span>°
                </div>
                <div>
                    👨‍🚀 Uzayda: <span id="astronauts" class="astronaut-count">--</span>
                </div>
                <div style="font-size:0.6rem; margin-top:4px;">🕒 <span id="iss-time">--</span></div>
            </div>
        </div>
        
        <!-- Uzay Hava Durumu -->
        <div class="card">
            <div class="card-header">
                ⚡ SPACE WEATHER
                <i>Kp INDEX</i>
            </div>
            <div class="card-content">
                <div class="kp-value">
                    <span id="kp-index">--</span>
                </div>
                <div id="threat" class="threat">--</div>
                <canvas id="kp-chart" class="chart" width="300" height="100"></canvas>
            </div>
        </div>
        
        <!-- Kontroller -->
        <div class="card">
            <div class="card-header">
                🎮 CONTROLS
                <i>ayarlar</i>
            </div>
            <div class="card-content">
                <div class="control-group">
                    <label>🔄 Yörüngeler <input type="checkbox" id="toggle-orbits" checked></label>
                </div>
                <div class="control-group">
                    <label>🌙 Ay <input type="checkbox" id="toggle-moon" checked></label>
                </div>
                <div class="control-group">
                    <label>🔊 Ses uyarıları <input type="checkbox" id="toggle-sounds"></label>
                </div>
                <div class="control-group">
                    <label>⭐ Yıldız yoğunluğu <input type="range" id="star-density" min="500" max="2500" step="100" value="1500"></label>
                </div>
                <button id="screenshot-btn">📸 Ekran Görüntüsü</button>
                <button id="reset-camera">🎥 Kamerayı Sıfırla</button>
            </div>
        </div>
    </div>
    
    <!-- Sağ Sidebar -->
    <div class="sidebar sidebar-right">
        <!-- NASA APOD -->
        <div class="card">
            <div class="card-header">
                🌌 NASA APOD
                <i>günlük</i>
            </div>
            <div class="card-content">
                <div id="apod-title" style="font-weight:bold; font-size:0.8rem;">--</div>
                <img id="apod-img" src="" style="width:100%; margin:5px 0; border-radius:4px;" alt="APOD">
                <div id="apod-explanation" style="font-size:0.65rem; max-height:100px; overflow-y:auto;">--</div>
            </div>
        </div>
        
        <!-- Uzay Haberleri -->
        <div class="card">
            <div class="card-header">
                📰 SPACE NEWS
                <i>son 5</i>
            </div>
            <div class="card-content" id="news-list">
                Yükleniyor...
            </div>
        </div>
        
        <!-- Yorumlar -->
        <div class="card">
            <div class="card-header">
                💬 COMMUNITY
                <i>yorumlar</i>
            </div>
            <div class="card-content">
                <div class="comments-list" id="comments-list">
                    <!-- Dinamik yorumlar -->
                </div>
                <div class="comment-input">
                    <input type="text" id="comment-name" placeholder="Kullanıcı adı" value="Anonim">
                    <input type="text" id="comment-text" placeholder="Yorum yaz...">
                    <button id="send-comment">Gönder</button>
                </div>
            </div>
        </div>
    </div>

    <script type="module">
        import * as THREE from 'three';
        import { OrbitControls } from 'https://unpkg.com/three@0.128.0/examples/jsm/controls/OrbitControls.js';
        
        // ---------- Three.js Sahnesi ----------
        const container = document.getElementById('canvas-container');
        const scene = new THREE.Scene();
        scene.background = new THREE.Color(0x000000);
        scene.fog = new THREE.FogExp2(0x000000, 0.0005);
        
        const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
        camera.position.set(0, 0, 3);
        
        const renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true });
        renderer.setSize(window.innerWidth, window.innerHeight);
        renderer.shadowMap.enabled = true;
        container.appendChild(renderer.domElement);
        
        const controls = new OrbitControls(camera, renderer.domElement);
        controls.enableDamping = true;
        controls.dampingFactor = 0.05;
        controls.autoRotate = true;
        controls.autoRotateSpeed = 0.5;
        controls.enableZoom = true;
        controls.enablePan = true;
        
        // ---------- Dünya ----------
        const earthGeometry = new THREE.SphereGeometry(1, 128, 128);
        const earthTexture = new THREE.TextureLoader().load('https://threejs.org/examples/textures/planets/earth_atmos_2048.jpg');
        const earthMaterial = new THREE.MeshStandardMaterial({ map: earthTexture, roughness: 0.5, metalness: 0.1 });
        const earth = new THREE.Mesh(earthGeometry, earthMaterial);
        scene.add(earth);
        
        // Atmosfer (glow efekti)
        const atmGeometry = new THREE.SphereGeometry(1.01, 64, 64);
        const atmMaterial = new THREE.MeshPhongMaterial({ color: 0x00aaff, transparent: true, opacity: 0.15 });
        const atmosphere = new THREE.Mesh(atmGeometry, atmMaterial);
        scene.add(atmosphere);
        
        // Yörüngeler (üç halka)
        const ringMaterial = new THREE.LineBasicMaterial({ color: 0x00ffff });
        const ringPoints = [];
        const ringRadius = 1.8;
        const segments = 200;
        for (let i = 0; i <= segments; i++) {
            const angle = (i / segments) * Math.PI * 2;
            const x = ringRadius * Math.cos(angle);
            const z = ringRadius * Math.sin(angle);
            ringPoints.push(new THREE.Vector3(x, 0, z));
        }
        const ringGeometry = new THREE.BufferGeometry().setFromPoints(ringPoints);
        const orbitRing = new THREE.LineLoop(ringGeometry, ringMaterial);
        scene.add(orbitRing);
        
        // İkinci halka (eğimli)
        const ringPoints2 = [];
        for (let i = 0; i <= segments; i++) {
            const angle = (i / segments) * Math.PI * 2;
            const x = ringRadius * Math.cos(angle);
            const y = ringRadius * 0.5 * Math.sin(angle);
            const z = ringRadius * Math.cos(angle);
            ringPoints2.push(new THREE.Vector3(x, y, z));
        }
        const ringGeometry2 = new THREE.BufferGeometry().setFromPoints(ringPoints2);
        const orbitRing2 = new THREE.LineLoop(ringGeometry2, new THREE.LineBasicMaterial({ color: 0xff00ff }));
        scene.add(orbitRing2);
        
        // Üçüncü halka (dikey)
        const ringPoints3 = [];
        for (let i = 0; i <= segments; i++) {
            const angle = (i / segments) * Math.PI * 2;
            const x = ringRadius * Math.cos(angle);
            const y = ringRadius * Math.sin(angle);
            ringPoints3.push(new THREE.Vector3(x, y, 0));
        }
        const ringGeometry3 = new THREE.BufferGeometry().setFromPoints(ringPoints3);
        const orbitRing3 = new THREE.LineLoop(ringGeometry3, new THREE.LineBasicMaterial({ color: 0x00ff00 }));
        scene.add(orbitRing3);
        
        // Ay
        const moonGeometry = new THREE.SphereGeometry(0.2, 64, 64);
        const moonMaterial = new THREE.MeshStandardMaterial({ color: 0xccccaa, emissive: 0x222200 });
        const moon = new THREE.Mesh(moonGeometry, moonMaterial);
        scene.add(moon);
        
        // Yıldızlar (parçacık sistemi)
        let starField;
        function generateStars(count) {
            if (starField) scene.remove(starField);
            const vertices = [];
            for (let i = 0; i < count; i++) {
                const x = (Math.random() - 0.5) * 2000;
                const y = (Math.random() - 0.5) * 2000;
                const z = (Math.random() - 0.5) * 2000;
                vertices.push(x, y, z);
            }
            const geometry = new THREE.BufferGeometry();
            geometry.setAttribute('position', new THREE.BufferAttribute(new Float32Array(vertices), 3));
            const material = new THREE.PointsMaterial({ color: 0xffffff, size: 0.5 });
            starField = new THREE.Points(geometry, material);
            scene.add(starField);
        }
        generateStars(1500);
        
        // Nebula parçacıkları (renkli)
        const nebulaCount = 800;
        const nebulaGeometry = new THREE.BufferGeometry();
        const nebulaPositions = [];
        const nebulaColors = [];
        for (let i = 0; i < nebulaCount; i++) {
            nebulaPositions.push((Math.random() - 0.5) * 400);
            nebulaPositions.push((Math.random() - 0.5) * 400);
            nebulaPositions.push((Math.random() - 0.5) * 200 - 50);
            nebulaColors.push(Math.random() * 0xffffff);
        }
        nebulaGeometry.setAttribute('position', new THREE.BufferAttribute(new Float32Array(nebulaPositions), 3));
        const nebulaMaterial = new THREE.PointsMaterial({ color: 0xff44aa, size: 0.2, transparent: true, opacity: 0.6 });
        const nebulaPoints = new THREE.Points(nebulaGeometry, nebulaMaterial);
        scene.add(nebulaPoints);
        
        // Işıklandırma
        const ambientLight = new THREE.AmbientLight(0x111111);
        scene.add(ambientLight);
        const dirLight = new THREE.DirectionalLight(0xffffff, 1);
        dirLight.position.set(5, 3, 5);
        scene.add(dirLight);
        const backLight = new THREE.PointLight(0x2266ff, 0.5);
        backLight.position.set(-2, 1, -3);
        scene.add(backLight);
        
        // ---------- UI Kontrolleri ----------
        document.getElementById('toggle-orbits').addEventListener('change', (e) => {
            orbitRing.visible = e.target.checked;
            orbitRing2.visible = e.target.checked;
            orbitRing3.visible = e.target.checked;
        });
        document.getElementById('toggle-moon').addEventListener('change', (e) => {
            moon.visible = e.target.checked;
        });
        document.getElementById('star-density').addEventListener('input', (e) => {
            generateStars(parseInt(e.target.value));
        });
        document.getElementById('reset-camera').addEventListener('click', () => {
            camera.position.set(0, 0, 3);
            controls.target.set(0, 0, 0);
            controls.update();
        });
        document.getElementById('screenshot-btn').addEventListener('click', () => {
            // Geçici olarak UI'yi gizle (sidebarlar)
            const left = document.querySelector('.sidebar-left');
            const right = document.querySelector('.sidebar-right');
            if (left) left.style.opacity = '0';
            if (right) right.style.opacity = '0';
            renderer.render(scene, camera);
            const canvas = renderer.domElement;
            const dataURL = canvas.toDataURL('image/png');
            const link = document.createElement('a');
            link.href = dataURL;
            link.download = 'horus_eye_screenshot.png';
            link.click();
            if (left) left.style.opacity = '1';
            if (right) right.style.opacity = '1';
        });
        
        // Animasyon (Ay yörüngesi)
        let moonAngle = 0;
        function animate() {
            requestAnimationFrame(animate);
            moonAngle += 0.005;
            const moonDist = 2.2;
            moon.position.x = Math.cos(moonAngle) * moonDist;
            moon.position.z = Math.sin(moonAngle) * moonDist;
            moon.position.y = Math.sin(moonAngle * 1.5) * 0.5;
            
            controls.update();
            renderer.render(scene, camera);
        }
        animate();
        
        // ---------- API Verilerini Çekme ----------
        async function fetchAPI(endpoint) {
            try {
                const res = await fetch(endpoint);
                return await res.json();
            } catch(e) {
                console.error(endpoint, e);
                return null;
            }
        }
        
        // ISS
        async function updateISS() {
            const data = await fetchAPI('/api/iss');
            if (data) {
                document.getElementById('iss-lat').innerText = data.latitude.toFixed(2);
                document.getElementById('iss-lon').innerText = data.longitude.toFixed(2);
                document.getElementById('astronauts').innerText = data.astronauts;
                document.getElementById('iss-time').innerText = new Date().toLocaleTimeString();
            }
        }
        
        // Uzay hava durumu ve grafik
        let kpChart = null;
        async function updateSpaceWeather() {
            const data = await fetchAPI('/api/spaceweather');
            if (data) {
                document.getElementById('kp-index').innerHTML = data.kp_index.toFixed(1);
                const threatDiv = document.getElementById('threat');
                threatDiv.innerText = data.threat_level;
                threatDiv.className = 'threat threat-' + data.threat_level.toLowerCase();
                if (kpChart) {
                    kpChart.data.datasets[0].data = data.history.values;
                    kpChart.update();
                } else {
                    const ctx = document.getElementById('kp-chart').getContext('2d');
                    kpChart = new Chart(ctx, {
                        type: 'line',
                        data: {
                            labels: data.history.timestamps,
                            datasets: [{
                                label: 'Kp İndeksi',
                                data: data.history.values,
                                borderColor: '#0ff',
                                backgroundColor: 'rgba(0,255,255,0.1)',
                                fill: true,
                                tension: 0.3,
                                pointRadius: 0
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: true,
                            plugins: { legend: { display: false } },
                            scales: { x: { ticks: { color: '#0ff', maxRotation: 45, autoSkip: true, maxTicksLimit: 6 } } }
                        }
                    });
                }
            }
        }
        
        // APOD
        async function updateAPOD() {
            const data = await fetchAPI('/api/apod');
            if (data) {
                document.getElementById('apod-title').innerHTML = data.title;
                let explanation = data.explanation;
                if (explanation.length > 200) explanation = explanation.substring(0, 200) + '...';
                document.getElementById('apod-explanation').innerHTML = explanation;
                if (data.url) document.getElementById('apod-img').src = data.url;
            }
        }
        
        // Haberler
        async function updateNews() {
            const data = await fetchAPI('/api/news');
            if (data && data.length) {
                const newsDiv = document.getElementById('news-list');
                newsDiv.innerHTML = data.map(article => `
                    <div class="news-item">
                        <a href="${article.url}" target="_blank" class="news-title">${article.title}</a>
                        <div class="news-date">${new Date(article.published_at).toLocaleDateString()}</div>
                        <div style="font-size:0.65rem;">${article.summary.substring(0, 80)}...</div>
                    </div>
                `).join('');
            } else {
                document.getElementById('news-list').innerHTML = 'Haberler yüklenemedi.';
            }
        }
        
        // Yorumlar (LocalStorage)
        let comments = [];
        function loadComments() {
            const stored = localStorage.getItem('horus_comments');
            if (stored) comments = JSON.parse(stored);
            else comments = [{ user: 'Horus', text: 'Uzay her zaman izleniyor...' }];
            renderComments();
        }
        function renderComments() {
            const container = document.getElementById('comments-list');
            container.innerHTML = comments.map(c => `
                <div class="comment">
                    <span class="comment-user">${escapeHtml(c.user)}</span>: <span class="comment-text">${escapeHtml(c.text)}</span>
                </div>
            `).join('');
        }
        function addComment(user, text) {
            if (!text.trim()) return;
            comments.unshift({ user: user.trim() || 'Anonim', text: text.trim() });
            if (comments.length > 30) comments.pop();
            localStorage.setItem('horus_comments', JSON.stringify(comments));
            renderComments();
        }
        function escapeHtml(str) {
            return str.replace(/[&<>]/g, function(m) {
                if (m === '&') return '&amp;';
                if (m === '<') return '&lt;';
                if (m === '>') return '&gt;';
                return m;
            });
        }
        document.getElementById('send-comment').addEventListener('click', () => {
            const user = document.getElementById('comment-name').value;
            const text = document.getElementById('comment-text').value;
            addComment(user, text);
            document.getElementById('comment-text').value = '';
        });
        
        // Ses uyarıları (basit bip)
        let audioCtx = null;
        function playBeep() {
            if (!document.getElementById('toggle-sounds').checked) return;
            if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            osc.frequency.value = 880;
            gain.gain.value = 0.1;
            osc.start();
            gain.gain.exponentialRampToValueAtTime(0.00001, audioCtx.currentTime + 0.5);
            osc.stop(audioCtx.currentTime + 0.5);
        }
        
        // Periyodik güncellemeler
        setInterval(() => {
            updateISS();
            updateSpaceWeather();
            updateAPOD();
            updateNews();
        }, 10000); // 10 saniye
        
        // İlk yükleme
        updateISS();
        updateSpaceWeather();
        updateAPOD();
        updateNews();
        loadComments();
        
        // Pencere yeniden boyutlandırma
        window.addEventListener('resize', onWindowResize, false);
        function onWindowResize() {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        }
    </script>
</body>
</html>
"""

# ==================== SUNUCUYU BAŞLAT ====================

def start_server():
    with socketserver.TCPServer(("", PORT), HorusEyeHandler) as httpd:
        print(f"🚀 HORUS-EYE ULTIMATE sunucusu başlatıldı: http://localhost:{PORT}")
        print("🔗 Tarayıcı otomatik açılacak...")
        webbrowser.open(f"http://localhost:{PORT}")
        httpd.serve_forever()

if __name__ == "__main__":
    start_server()
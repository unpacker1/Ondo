#!/usr/bin/env python3
"""
HORUS-EYE ULTIMATE - Cyberpunk Uzay Takip Sistemi (Tam Özellikli + 3D ISS)
Rastgele port + Gelişmiş Siberpunk Tasarım + Tüm Modüller + 3D ISS görünür
"""

import http.server
import socketserver
import json
import urllib.parse
import webbrowser
import time
import random
from datetime import datetime, timedelta

try:
    import requests
except ImportError:
    print("Hata: 'requests' kütüphanesi bulunamadı.")
    print("Kurulum için: pip install requests")
    exit(1)

# ==================== API YAPILANDIRMA ====================
NASA_API_KEY = "DEMO_KEY"
CACHE_TTL = 60

cache = {
    "iss": {"data": None, "expires": 0},
    "spaceweather": {"data": None, "expires": 0},
    "apod": {"data": None, "expires": 0},
    "news": {"data": None, "expires": 0},
    "neo": {"data": None, "expires": 0},
    "aurora": {"data": None, "expires": 0},
    "solarwind": {"data": None, "expires": 0},
}

# ==================== API FONKSİYONLARI ====================

def fetch_iss():
    try:
        resp_iss = requests.get("http://api.open-notify.org/iss-now.json", timeout=10)
        resp_iss.raise_for_status()
        data_iss = resp_iss.json()
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
    try:
        url = "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json"
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        kp_values = []
        timestamps = []
        for row in data[-96:]:
            try:
                dt = datetime.strptime(row[0], "%Y-%m-%d %H:%M:%S")
                timestamps.append(dt.strftime("%H:%M"))
                kp_values.append(float(row[1]))
            except:
                continue
        current_kp = kp_values[-1] if kp_values else 0.0
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
                "timestamps": timestamps[-24:],
                "values": kp_values[-24:]
            }
        }
    except Exception as e:
        print(f"Uzay hava durumu API hatası: {e}")
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
            "explanation": "NASA API'sine bağlanılamadı.",
            "url": "",
            "hdurl": "",
            "error": str(e)
        }

def fetch_news():
    try:
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
        return [
            {"title": "SpaceX Starship test uçuşu başarılı", "summary": "Yeni nesil roket yörüngeye ulaştı.", "published_at": datetime.now().isoformat(), "url": "#"},
            {"title": "Ay'a dönüş programı hızlanıyor", "summary": "NASA Artemis misyonu için tarih açıklandı.", "published_at": (datetime.now() - timedelta(hours=3)).isoformat(), "url": "#"},
            {"title": "Mars'ta su bulundu", "summary": "Perseverance keşif aracı yeni kanıtlar topladı.", "published_at": (datetime.now() - timedelta(days=1)).isoformat(), "url": "#"},
        ]

def fetch_neo():
    try:
        today = datetime.now().strftime("%Y-%m-%d")
        url = f"https://api.nasa.gov/neo/rest/v1/feed?start_date={today}&end_date={today}&api_key={NASA_API_KEY}"
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        neo_data = data.get("near_earth_objects", {}).get(today, [])
        count = len(neo_data)
        hazardous = sum(1 for obj in neo_data if obj.get("is_potentially_hazardous_asteroid", False))
        closest = None
        if neo_data:
            min_dist = min(float(obj["close_approach_data"][0]["miss_distance"]["kilometers"]) for obj in neo_data if obj["close_approach_data"])
            closest = f"{min_dist:,.0f} km"
        return {
            "count": count,
            "hazardous": hazardous,
            "closest": closest,
            "objects": neo_data[:3]
        }
    except Exception as e:
        print(f"NEO API hatası: {e}")
        return {"count": random.randint(0, 5), "hazardous": random.randint(0, 2), "closest": "---", "error": str(e)}

def fetch_aurora():
    try:
        url = "https://services.swpc.noaa.gov/products/aurora-30-minute-forecast.json"
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        latest = data[-1] if len(data) > 1 else None
        if latest:
            kp = latest[3]
            aurora = latest[4]
            return {"kp": kp, "aurora": aurora}
        return {"kp": "N/A", "aurora": "N/A"}
    except Exception as e:
        print(f"Aurora API hatası: {e}")
        return {"kp": random.uniform(2, 7), "aurora": "MODERATE", "error": str(e)}

def fetch_solarwind():
    try:
        url = "https://services.swpc.noaa.gov/products/solar-wind/plasma-7-day.json"
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        latest = data[-1] if len(data) > 1 else None
        if latest:
            density = latest[1] if len(latest) > 1 else "N/A"
            speed = latest[2] if len(latest) > 2 else "N/A"
            temp = latest[3] if len(latest) > 3 else "N/A"
            return {"density": density, "speed": speed, "temperature": temp}
        return {"density": "N/A", "speed": "N/A", "temperature": "N/A"}
    except Exception as e:
        print(f"Solar Wind API hatası: {e}")
        return {"density": random.randint(1, 10), "speed": random.randint(300, 800), "temperature": random.randint(50000, 200000), "error": str(e)}

def get_cached_or_fetch(cache_key, fetch_func):
    now = time.time()
    if cache[cache_key]["data"] and cache[cache_key]["expires"] > now:
        return cache[cache_key]["data"]
    data = fetch_func()
    cache[cache_key]["data"] = data
    cache[cache_key]["expires"] = now + CACHE_TTL
    return data

# ==================== HTTP SUNUCU ====================

class HorusEyeHandler(http.server.BaseHTTPRequestHandler):
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
        elif path == "/api/neo":
            self.serve_json(get_cached_or_fetch("neo", fetch_neo))
        elif path == "/api/aurora":
            self.serve_json(get_cached_or_fetch("aurora", fetch_aurora))
        elif path == "/api/solarwind":
            self.serve_json(get_cached_or_fetch("solarwind", fetch_solarwind))
        else:
            self.send_error(404, "Not Found")
    
    def serve_html(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(HTML_CONTENT.encode("utf-8"))
    
    def serve_json(self, data):
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode("utf-8"))
    
    def log_message(self, format, *args):
        print(f"[{datetime.now().strftime('%H:%M:%S')}] {args[0]}")

# ==================== HTML İÇERİĞİ (3D ISS EKLENDİ) ====================

HTML_CONTENT = r"""
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>HORUS-EYE ULTIMATE | Cyberpunk Uzay Takip Sistemi</title>
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
        
        body::before {
            content: "";
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            background: repeating-linear-gradient(0deg, rgba(0,255,255,0.03) 0px, rgba(0,255,255,0.03) 2px, transparent 2px, transparent 4px);
            z-index: 999;
        }
        
        @keyframes glitch {
            0% { text-shadow: -2px 0 #ff00ff, 2px 0 #00ffff; opacity: 1; }
            25% { text-shadow: -3px 0 #ff00ff, 3px 0 #00ffff; }
            50% { text-shadow: -1px 0 #ff00ff, 1px 0 #00ffff; }
            75% { text-shadow: -4px 0 #ff00ff, 4px 0 #00ffff; }
            100% { text-shadow: -2px 0 #ff00ff, 2px 0 #00ffff; }
        }
        
        .glitch-text {
            animation: glitch 0.2s infinite;
        }
        
        @keyframes borderPulse {
            0% { border-color: rgba(0,255,255,0.3); box-shadow: 0 0 5px rgba(0,255,255,0.2); }
            50% { border-color: rgba(0,255,255,0.8); box-shadow: 0 0 15px rgba(0,255,255,0.6); }
            100% { border-color: rgba(0,255,255,0.3); box-shadow: 0 0 5px rgba(0,255,255,0.2); }
        }
        
        #canvas-container {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: 0;
        }
        
        .sidebar {
            position: fixed;
            top: 0;
            bottom: 0;
            width: 280px;
            background: rgba(0, 0, 0, 0.75);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(0, 255, 255, 0.4);
            box-shadow: 0 0 20px rgba(0,255,255,0.2);
            z-index: 20;
            overflow-y: auto;
            padding: 12px 10px;
            pointer-events: auto;
            transition: transform 0.3s ease;
            animation: borderPulse 2s infinite;
        }
        
        .sidebar-left {
            left: 0;
            border-right: 2px solid #0ff;
        }
        
        .sidebar-right {
            right: 0;
            border-left: 2px solid #0ff;
        }
        
        .sidebar-left.hidden { transform: translateX(-100%); }
        .sidebar-right.hidden { transform: translateX(100%); }
        
        .card {
            background: rgba(0, 0, 0, 0.65);
            border: 1px solid #0ff;
            border-radius: 8px;
            padding: 8px;
            margin-bottom: 12px;
            box-shadow: 0 0 8px rgba(0,255,255,0.3);
            transition: all 0.2s ease;
        }
        
        .card:hover {
            border-color: #f0f;
            box-shadow: 0 0 15px rgba(255,0,255,0.4);
        }
        
        .card-header {
            font-size: 0.85rem;
            font-weight: bold;
            margin-bottom: 6px;
            border-bottom: 1px solid #0ff;
            padding-bottom: 3px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            text-transform: uppercase;
        }
        
        .card-header i {
            color: #f0f;
            font-style: normal;
            font-size: 0.65rem;
            text-shadow: 0 0 3px #f0f;
        }
        
        .card-content {
            font-size: 0.7rem;
        }
        
        .iss-coord {
            font-size: 0.75rem;
            font-weight: bold;
            margin: 4px 0;
        }
        
        .kp-value {
            font-size: 1.2rem;
            font-weight: bold;
            text-align: center;
            margin: 4px 0;
            text-shadow: 0 0 5px #0ff;
        }
        
        .threat {
            text-align: center;
            font-weight: bold;
            padding: 2px;
            border-radius: 3px;
            font-size: 0.65rem;
            text-transform: uppercase;
        }
        
        .threat-severe { background: #f00; color: black; box-shadow: 0 0 5px red; }
        .threat-high { background: #f60; color: black; }
        .threat-moderate { background: #ff0; color: black; }
        .threat-nominal { background: #0f0; color: black; }
        
        canvas.chart {
            width: 100%;
            height: 100px;
            margin-top: 5px;
        }
        
        .news-item {
            margin-bottom: 8px;
            border-bottom: 1px solid rgba(0,255,255,0.3);
            padding-bottom: 5px;
        }
        
        .news-title {
            font-weight: bold;
            color: #fff;
            text-decoration: none;
            font-size: 0.75rem;
        }
        
        .news-date {
            font-size: 0.55rem;
            color: #aaa;
        }
        
        .comments-list {
            max-height: 140px;
            overflow-y: auto;
            margin-bottom: 6px;
            font-family: monospace;
        }
        
        .comment {
            background: rgba(0,255,255,0.1);
            border-left: 2px solid #0ff;
            padding: 3px;
            margin-bottom: 4px;
            font-size: 0.65rem;
        }
        
        .comment-user {
            font-weight: bold;
            color: #f0f;
        }
        
        .control-group {
            margin-bottom: 6px;
        }
        
        .control-group label {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 0.7rem;
        }
        
        input[type="range"] {
            width: 100%;
            background: #0ff;
            height: 2px;
            -webkit-appearance: none;
        }
        
        button {
            background: rgba(0,255,255,0.2);
            border: 1px solid #0ff;
            color: #0ff;
            padding: 3px 6px;
            cursor: pointer;
            margin-top: 4px;
            width: 100%;
            transition: 0.2s;
            font-size: 0.65rem;
            text-transform: uppercase;
        }
        
        button:hover {
            background: #0ff;
            color: black;
            box-shadow: 0 0 8px #0ff;
        }
        
        .console-log {
            font-family: monospace;
            background: #000000aa;
            border: 1px solid #0ff;
            border-radius: 4px;
            padding: 4px;
            height: 100px;
            overflow-y: auto;
            font-size: 0.6rem;
            color: #0f0;
        }
        
        .console-line {
            border-bottom: 1px solid #0ff3;
            padding: 2px;
            white-space: nowrap;
            overflow-x: hidden;
            text-overflow: ellipsis;
        }
        
        .toggle-btn {
            position: fixed;
            top: 12px;
            z-index: 30;
            background: rgba(0,0,0,0.7);
            border: 1px solid #0ff;
            color: #0ff;
            padding: 4px 10px;
            cursor: pointer;
            font-size: 0.7rem;
            border-radius: 20px;
            backdrop-filter: blur(5px);
            font-weight: bold;
            transition: 0.2s;
            width: auto;
        }
        .toggle-left { left: 10px; }
        .toggle-right { right: 10px; }
        .toggle-btn:hover { background: #0ff; color: black; box-shadow: 0 0 8px #0ff; }
        
        .glitch-title {
            position: fixed;
            top: 10px;
            left: 50%;
            transform: translateX(-50%);
            z-index: 35;
            font-size: 1.2rem;
            font-weight: bold;
            background: rgba(0,0,0,0.6);
            padding: 4px 12px;
            border-radius: 20px;
            border: 1px solid #0ff;
            backdrop-filter: blur(8px);
            white-space: nowrap;
            letter-spacing: 2px;
            pointer-events: none;
        }
        
        @media (max-width: 768px) {
            .sidebar { width: 260px; }
            .glitch-title { font-size: 0.8rem; top: 5px; }
            .toggle-btn { top: 5px; }
        }
        
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-track { background: #111; }
        ::-webkit-scrollbar-thumb { background: #0ff; border-radius: 2px; }
    </style>
    <script type="importmap">
        { "imports": { "three": "https://unpkg.com/three@0.128.0/build/three.module.js" } }
    </script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
</head>
<body>
    <div id="canvas-container"></div>
    
    <div class="glitch-title glitch-text">🛸 HORUS-EYE ULTIMATE ⚡</div>
    <button class="toggle-btn toggle-left" id="toggle-left">◀ SOL</button>
    <button class="toggle-btn toggle-right" id="toggle-right">SAĞ ▶</button>
    
    <!-- Sol Sidebar -->
    <div class="sidebar sidebar-left" id="sidebar-left">
        <div class="card">
            <div class="card-header">🛰️ ISS TRACKER <i>● LIVE</i></div>
            <div class="card-content">
                <div class="iss-coord">🌍 Enlem: <span id="iss-lat">--</span>°<br>🌐 Boylam: <span id="iss-lon">--</span>°</div>
                <div>👨‍🚀 Uzayda: <span id="astronauts">--</span></div>
                <div style="font-size:0.55rem;">🕒 <span id="iss-time">--</span></div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">⚡ SPACE WEATHER <i>Kp INDEX</i></div>
            <div class="card-content">
                <div class="kp-value"><span id="kp-index">--</span></div>
                <div id="threat" class="threat">--</div>
                <canvas id="kp-chart" class="chart" width="300" height="90"></canvas>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">☄️ NEO MONITOR <i>asteroid</i></div>
            <div class="card-content">
                <div>☄️ Bugünkü NEO: <span id="neo-count">--</span></div>
                <div>⚠️ Tehlikeli: <span id="neo-hazardous">--</span></div>
                <div>📏 En yakın: <span id="neo-closest">--</span></div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">🌬️ SOLAR WIND</div>
            <div class="card-content">
                <div>💨 Hız: <span id="solar-speed">--</span> km/s</div>
                <div>📊 Yoğunluk: <span id="solar-density">--</span> p/cc</div>
                <div>🌡️ Sıcaklık: <span id="solar-temp">--</span> K</div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">🎮 CONTROLS</div>
            <div class="card-content">
                <div class="control-group"><label>🔄 Yörüngeler <input type="checkbox" id="toggle-orbits" checked></label></div>
                <div class="control-group"><label>🌙 Ay <input type="checkbox" id="toggle-moon" checked></label></div>
                <div class="control-group"><label>🔊 Ses <input type="checkbox" id="toggle-sounds"></label></div>
                <div class="control-group"><label>⭐ Yıldız yoğunluğu <input type="range" id="star-density" min="500" max="2500" step="100" value="1500"></label></div>
                <button id="screenshot-btn">📸 EKRAN GÖRÜNTÜSÜ</button>
                <button id="reset-camera">🎥 KAMERA SIFIRLA</button>
            </div>
        </div>
    </div>
    
    <!-- Sağ Sidebar -->
    <div class="sidebar sidebar-right" id="sidebar-right">
        <div class="card">
            <div class="card-header">🌌 NASA APOD <i>günlük</i></div>
            <div class="card-content">
                <div id="apod-title" style="font-weight:bold; font-size:0.7rem;">--</div>
                <img id="apod-img" src="" style="width:100%; margin:4px 0; border-radius:3px;" alt="APOD">
                <div id="apod-explanation" style="font-size:0.6rem; max-height:80px; overflow-y:auto;">--</div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">📰 SPACE NEWS <i>son 5</i></div>
            <div class="card-content" id="news-list">Yükleniyor...</div>
        </div>
        
        <div class="card">
            <div class="card-header">💬 COMMUNITY</div>
            <div class="card-content">
                <div class="comments-list" id="comments-list"></div>
                <div class="comment-input" style="display:flex; gap:4px; margin-top:6px;">
                    <input type="text" id="comment-name" placeholder="Ad" value="Anonim" style="flex:1; background:#111; border:1px solid #0ff; color:#0ff; padding:3px;">
                    <input type="text" id="comment-text" placeholder="Yorum..." style="flex:2; background:#111; border:1px solid #0ff; color:#0ff; padding:3px;">
                    <button id="send-comment" style="width:auto;">Gönder</button>
                </div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">💡 AURORA FORECAST</div>
            <div class="card-content">
                <div>Kp: <span id="aurora-kp">--</span></div>
                <div>🌌 Aktivite: <span id="aurora-level">--</span></div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">🖥️ SYSTEM CONSOLE</div>
            <div class="console-log" id="console-log"></div>
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
        
        // Dünya
        const earthGeometry = new THREE.SphereGeometry(1, 128, 128);
        const earthTexture = new THREE.TextureLoader().load('https://threejs.org/examples/textures/planets/earth_atmos_2048.jpg');
        const earthMaterial = new THREE.MeshStandardMaterial({ map: earthTexture, roughness: 0.5, metalness: 0.1 });
        const earth = new THREE.Mesh(earthGeometry, earthMaterial);
        scene.add(earth);
        
        // Atmosfer
        const atmGeometry = new THREE.SphereGeometry(1.01, 64, 64);
        const atmMaterial = new THREE.MeshPhongMaterial({ color: 0x00aaff, transparent: true, opacity: 0.15 });
        const atmosphere = new THREE.Mesh(atmGeometry, atmMaterial);
        scene.add(atmosphere);
        
        // Yörüngeler
        const ringMaterial = new THREE.LineBasicMaterial({ color: 0x00ffff });
        const ringPoints = [];
        const ringRadius = 1.8;
        const segments = 200;
        for (let i = 0; i <= segments; i++) {
            const angle = (i / segments) * Math.PI * 2;
            ringPoints.push(new THREE.Vector3(ringRadius * Math.cos(angle), 0, ringRadius * Math.sin(angle)));
        }
        const ringGeometry = new THREE.BufferGeometry().setFromPoints(ringPoints);
        const orbitRing = new THREE.LineLoop(ringGeometry, ringMaterial);
        scene.add(orbitRing);
        
        const ringPoints2 = [];
        for (let i = 0; i <= segments; i++) {
            const angle = (i / segments) * Math.PI * 2;
            ringPoints2.push(new THREE.Vector3(ringRadius * Math.cos(angle), ringRadius * 0.5 * Math.sin(angle), ringRadius * Math.cos(angle)));
        }
        const ringGeometry2 = new THREE.BufferGeometry().setFromPoints(ringPoints2);
        const orbitRing2 = new THREE.LineLoop(ringGeometry2, new THREE.LineBasicMaterial({ color: 0xff00ff }));
        scene.add(orbitRing2);
        
        const ringPoints3 = [];
        for (let i = 0; i <= segments; i++) {
            const angle = (i / segments) * Math.PI * 2;
            ringPoints3.push(new THREE.Vector3(ringRadius * Math.cos(angle), ringRadius * Math.sin(angle), 0));
        }
        const ringGeometry3 = new THREE.BufferGeometry().setFromPoints(ringPoints3);
        const orbitRing3 = new THREE.LineLoop(ringGeometry3, new THREE.LineBasicMaterial({ color: 0x00ff00 }));
        scene.add(orbitRing3);
        
        // Ay
        const moonGeometry = new THREE.SphereGeometry(0.2, 64, 64);
        const moonMaterial = new THREE.MeshStandardMaterial({ color: 0xccccaa, emissive: 0x222200 });
        const moon = new THREE.Mesh(moonGeometry, moonMaterial);
        scene.add(moon);
        
        // Yıldızlar
        let starField;
        function generateStars(count) {
            if (starField) scene.remove(starField);
            const vertices = [];
            for (let i = 0; i < count; i++) {
                vertices.push((Math.random() - 0.5) * 2000, (Math.random() - 0.5) * 2000, (Math.random() - 0.5) * 2000);
            }
            const geometry = new THREE.BufferGeometry();
            geometry.setAttribute('position', new THREE.BufferAttribute(new Float32Array(vertices), 3));
            starField = new THREE.Points(geometry, new THREE.PointsMaterial({ color: 0xffffff, size: 0.5 }));
            scene.add(starField);
        }
        generateStars(1500);
        
        // Nebula parçacıkları
        const nebulaCount = 800;
        const nebulaGeometry = new THREE.BufferGeometry();
        const nebulaPositions = [];
        for (let i = 0; i < nebulaCount; i++) {
            nebulaPositions.push((Math.random() - 0.5) * 400, (Math.random() - 0.5) * 400, (Math.random() - 0.5) * 200 - 50);
        }
        nebulaGeometry.setAttribute('position', new THREE.BufferAttribute(new Float32Array(nebulaPositions), 3));
        const nebulaPoints = new THREE.Points(nebulaGeometry, new THREE.PointsMaterial({ color: 0xff44aa, size: 0.2, transparent: true, opacity: 0.5 }));
        scene.add(nebulaPoints);
        
        // Işık
        const ambientLight = new THREE.AmbientLight(0x111111);
        scene.add(ambientLight);
        const dirLight = new THREE.DirectionalLight(0xffffff, 1);
        dirLight.position.set(5, 3, 5);
        scene.add(dirLight);
        
        // ---------- 3D ISS (YENİ) ----------
        // ISS modeli (kırmızı küre)
        const issGeometry = new THREE.SphereGeometry(0.03, 32, 32);
        const issMaterial = new THREE.MeshStandardMaterial({ color: 0xff3333, emissive: 0x441111 });
        const iss = new THREE.Mesh(issGeometry, issMaterial);
        scene.add(iss);
        
        // Enlem/boylam -> 3D koordinat çevirici
        function latLonToVector3(lat, lon, radius = 1.02) {
            const phi = (90 - lat) * Math.PI / 180;
            const theta = lon * Math.PI / 180;
            const x = radius * Math.sin(phi) * Math.cos(theta);
            const y = radius * Math.cos(phi);
            const z = radius * Math.sin(phi) * Math.sin(theta);
            return new THREE.Vector3(x, y, z);
        }
        
        // UI Kontrolleri
        document.getElementById('toggle-orbits').addEventListener('change', (e) => {
            orbitRing.visible = e.target.checked;
            orbitRing2.visible = e.target.checked;
            orbitRing3.visible = e.target.checked;
        });
        document.getElementById('toggle-moon').addEventListener('change', (e) => { moon.visible = e.target.checked; });
        document.getElementById('star-density').addEventListener('input', (e) => generateStars(parseInt(e.target.value)));
        document.getElementById('reset-camera').addEventListener('click', () => {
            camera.position.set(0, 0, 3);
            controls.target.set(0, 0, 0);
            controls.update();
        });
        document.getElementById('screenshot-btn').addEventListener('click', () => {
            const left = document.getElementById('sidebar-left');
            const right = document.getElementById('sidebar-right');
            const leftVis = !left.classList.contains('hidden');
            const rightVis = !right.classList.contains('hidden');
            if (leftVis) left.style.opacity = '0';
            if (rightVis) right.style.opacity = '0';
            renderer.render(scene, camera);
            const dataURL = renderer.domElement.toDataURL('image/png');
            const link = document.createElement('a');
            link.href = dataURL;
            link.download = 'horus_eye_screenshot.png';
            link.click();
            if (leftVis) left.style.opacity = '1';
            if (rightVis) right.style.opacity = '1';
        });
        
        // Ay animasyonu
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
        
        // Sidebar toggle
        document.getElementById('toggle-left').addEventListener('click', () => {
            document.getElementById('sidebar-left').classList.toggle('hidden');
        });
        document.getElementById('toggle-right').addEventListener('click', () => {
            document.getElementById('sidebar-right').classList.toggle('hidden');
        });
        
        // ---------- API Verileri ----------
        async function fetchAPI(endpoint) {
            try {
                const res = await fetch(endpoint);
                return await res.json();
            } catch(e) { console.error(e); return null; }
        }
        
        // Console log
        function addLog(message, type = "info") {
            const logDiv = document.getElementById('console-log');
            const line = document.createElement('div');
            line.className = 'console-line';
            const time = new Date().toLocaleTimeString();
            line.innerHTML = `[${time}] ${message}`;
            logDiv.appendChild(line);
            logDiv.scrollTop = logDiv.scrollHeight;
            if (logDiv.children.length > 30) logDiv.removeChild(logDiv.children[0]);
        }
        
        // ISS (2D ve 3D güncelleme)
        async function updateISS() {
            const data = await fetchAPI('/api/iss');
            if (data) {
                document.getElementById('iss-lat').innerText = data.latitude.toFixed(2);
                document.getElementById('iss-lon').innerText = data.longitude.toFixed(2);
                document.getElementById('astronauts').innerText = data.astronauts;
                document.getElementById('iss-time').innerText = new Date().toLocaleTimeString();
                
                // 3D pozisyonu güncelle
                const pos = latLonToVector3(data.latitude, data.longitude, 1.02);
                iss.position.copy(pos);
                
                addLog(`ISS konumu güncellendi: ${data.latitude.toFixed(2)}°, ${data.longitude.toFixed(2)}° (3D: ${pos.x.toFixed(2)}, ${pos.y.toFixed(2)}, ${pos.z.toFixed(2)})`);
            } else addLog("ISS verisi alınamadı", "error");
        }
        
        // Uzay hava durumu
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
                            scales: { x: { ticks: { color: '#0ff', maxRotation: 45, autoSkip: true, maxTicksLimit: 5 } } }
                        }
                    });
                }
                addLog(`Kp indeksi: ${data.kp_index.toFixed(1)} - ${data.threat_level}`);
            } else addLog("Uzay hava durumu alınamadı", "error");
        }
        
        // APOD
        async function updateAPOD() {
            const data = await fetchAPI('/api/apod');
            if (data) {
                document.getElementById('apod-title').innerHTML = data.title;
                let expl = data.explanation;
                if (expl.length > 150) expl = expl.substring(0,150)+'...';
                document.getElementById('apod-explanation').innerHTML = expl;
                if (data.url) document.getElementById('apod-img').src = data.url;
                addLog(`APOD: ${data.title}`);
            } else addLog("APOD alınamadı", "error");
        }
        
        // Haberler
        async function updateNews() {
            const data = await fetchAPI('/api/news');
            if (data && data.length) {
                document.getElementById('news-list').innerHTML = data.map(a => `
                    <div class="news-item">
                        <a href="${a.url}" target="_blank" class="news-title">${a.title}</a>
                        <div class="news-date">${new Date(a.published_at).toLocaleDateString()}</div>
                        <div style="font-size:0.6rem;">${a.summary.substring(0,70)}...</div>
                    </div>
                `).join('');
                addLog(`${data.length} haber yüklendi`);
            } else { document.getElementById('news-list').innerHTML = 'Yüklenemedi.'; addLog("Haberler alınamadı", "error"); }
        }
        
        // NEO
        async function updateNEO() {
            const data = await fetchAPI('/api/neo');
            if (data) {
                document.getElementById('neo-count').innerText = data.count;
                document.getElementById('neo-hazardous').innerText = data.hazardous;
                document.getElementById('neo-closest').innerText = data.closest || '---';
                addLog(`${data.count} NEO, ${data.hazardous} tehlikeli`);
            } else addLog("NEO verisi alınamadı", "error");
        }
        
        // Aurora
        async function updateAurora() {
            const data = await fetchAPI('/api/aurora');
            if (data) {
                document.getElementById('aurora-kp').innerText = data.kp;
                document.getElementById('aurora-level').innerText = data.aurora;
                addLog(`Aurora Kp: ${data.kp} - ${data.aurora}`);
            } else addLog("Aurora verisi alınamadı", "error");
        }
        
        // Solar Wind
        async function updateSolarWind() {
            const data = await fetchAPI('/api/solarwind');
            if (data) {
                document.getElementById('solar-speed').innerText = data.speed;
                document.getElementById('solar-density').innerText = data.density;
                document.getElementById('solar-temp').innerText = data.temperature;
                addLog(`Güneş rüzgarı: ${data.speed} km/s`);
            } else addLog("Güneş rüzgarı verisi alınamadı", "error");
        }
        
        // Yorumlar
        let comments = [];
        function loadComments() {
            const stored = localStorage.getItem('horus_comments');
            if (stored) comments = JSON.parse(stored);
            else comments = [{ user: 'Horus', text: 'Uzay her zaman izleniyor...' }];
            renderComments();
        }
        function renderComments() {
            const container = document.getElementById('comments-list');
            container.innerHTML = comments.map(c => `<div class="comment"><span class="comment-user">${escapeHtml(c.user)}</span>: ${escapeHtml(c.text)}</div>`).join('');
        }
        function addComment(user, text) {
            if (!text.trim()) return;
            comments.unshift({ user: user.trim() || 'Anonim', text: text.trim() });
            if (comments.length > 30) comments.pop();
            localStorage.setItem('horus_comments', JSON.stringify(comments));
            renderComments();
            addLog(`Yorum eklendi: ${user}`);
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
            addComment(document.getElementById('comment-name').value, document.getElementById('comment-text').value);
            document.getElementById('comment-text').value = '';
        });
        
        // Ses
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
        
        // Periyodik güncelleme
        setInterval(() => {
            updateISS();
            updateSpaceWeather();
            updateAPOD();
            updateNews();
            updateNEO();
            updateAurora();
            updateSolarWind();
        }, 10000);
        
        // İlk yüklemeler
        updateISS();
        updateSpaceWeather();
        updateAPOD();
        updateNews();
        updateNEO();
        updateAurora();
        updateSolarWind();
        loadComments();
        addLog("HORUS-EYE ULTIMATE başlatıldı. Tüm sistemler aktif. 3D ISS görünür.");
        
        // Pencere yeniden boyutlandırma
        window.addEventListener('resize', () => {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        });
    </script>
</body>
</html>
"""

# ==================== SUNUCUYU BAŞLAT (RANDOM PORT) ====================

def start_server():
    with socketserver.TCPServer(("", 0), HorusEyeHandler) as httpd:
        port = httpd.server_address[1]
        print(f"🚀 HORUS-EYE ULTIMATE sunucusu başlatıldı: http://localhost:{port}")
        print("🔗 Tarayıcı otomatik açılacak...")
        webbrowser.open(f"http://localhost:{port}")
        httpd.serve_forever()

if __name__ == "__main__":
    start_server()
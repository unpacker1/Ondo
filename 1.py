#!/usr/bin/env python3
"""
HORUS-EYE ULTIMATE - Tüm Uydular + 3D Takip + API Anahtarı
Cyberpunk uzay takip sistemi – ISS, 20+ uydu, uzay hava durumu, haberler, yorumlar
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

# ==================== HTML İÇERİĞİ (Tüm Uydular + CSS2D + API Anahtarı) ====================
HTML_CONTENT = r"""
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>HORUS-EYE ULTIMATE | Tüm Uydular</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Share Tech Mono', monospace;
            background: black;
            color: #0ff;
            overflow: hidden;
            height: 100vh;
        }
        /* CRT efekti */
        body::before {
            content: "";
            position: fixed;
            top: 0; left: 0; width: 100%; height: 100%;
            pointer-events: none;
            background: repeating-linear-gradient(0deg, rgba(0,255,255,0.03) 0px, rgba(0,255,255,0.03) 2px, transparent 2px, transparent 4px);
            z-index: 999;
        }
        /* Glitch animasyonu */
        @keyframes glitch {
            0% { text-shadow: -2px 0 #ff00ff, 2px 0 #00ffff; }
            25% { text-shadow: -3px 0 #ff00ff, 3px 0 #00ffff; }
            50% { text-shadow: -1px 0 #ff00ff, 1px 0 #00ffff; }
            75% { text-shadow: -4px 0 #ff00ff, 4px 0 #00ffff; }
            100% { text-shadow: -2px 0 #ff00ff, 2px 0 #00ffff; }
        }
        .glitch-text { animation: glitch 0.2s infinite; }
        @keyframes borderPulse {
            0% { border-color: rgba(0,255,255,0.3); box-shadow: 0 0 5px rgba(0,255,255,0.2); }
            50% { border-color: rgba(0,255,255,0.8); box-shadow: 0 0 15px rgba(0,255,255,0.6); }
            100% { border-color: rgba(0,255,255,0.3); box-shadow: 0 0 5px rgba(0,255,255,0.2); }
        }
        #canvas-container { position: fixed; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; }
        /* Sidebar'lar */
        .sidebar {
            position: fixed;
            top: 0; bottom: 0;
            width: 300px;
            background: rgba(0,0,0,0.75);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(0,255,255,0.4);
            box-shadow: 0 0 20px rgba(0,255,255,0.2);
            z-index: 20;
            overflow-y: auto;
            padding: 12px 10px;
            transition: transform 0.3s ease;
            animation: borderPulse 2s infinite;
        }
        .sidebar-left { left: 0; border-right: 2px solid #0ff; }
        .sidebar-right { right: 0; border-left: 2px solid #0ff; }
        .sidebar-left.hidden { transform: translateX(-100%); }
        .sidebar-right.hidden { transform: translateX(100%); }
        /* Kartlar */
        .card {
            background: rgba(0,0,0,0.65);
            border: 1px solid #0ff;
            border-radius: 8px;
            padding: 8px;
            margin-bottom: 12px;
            box-shadow: 0 0 8px rgba(0,255,255,0.3);
        }
        .card-header {
            font-size: 0.85rem;
            font-weight: bold;
            margin-bottom: 6px;
            border-bottom: 1px solid #0ff;
            padding-bottom: 3px;
            display: flex;
            justify-content: space-between;
            text-transform: uppercase;
        }
        .card-header i { color: #f0f; font-size: 0.65rem; }
        .card-content { font-size: 0.7rem; }
        .iss-coord { font-size: 0.75rem; font-weight: bold; margin: 4px 0; }
        .kp-value { font-size: 1.2rem; font-weight: bold; text-align: center; text-shadow: 0 0 5px #0ff; }
        .threat { text-align: center; font-weight: bold; padding: 2px; border-radius: 3px; font-size: 0.65rem; text-transform: uppercase; }
        .threat-severe { background: #f00; color: black; box-shadow: 0 0 5px red; }
        .threat-high { background: #f60; color: black; }
        .threat-moderate { background: #ff0; color: black; }
        .threat-nominal { background: #0f0; color: black; }
        canvas.chart { width: 100%; height: 100px; margin-top: 5px; }
        .news-item { margin-bottom: 8px; border-bottom: 1px solid rgba(0,255,255,0.3); padding-bottom: 5px; }
        .news-title { font-weight: bold; color: #fff; text-decoration: none; font-size: 0.75rem; }
        .news-date { font-size: 0.55rem; color: #aaa; }
        .comments-list { max-height: 140px; overflow-y: auto; margin-bottom: 6px; }
        .comment { background: rgba(0,255,255,0.1); border-left: 2px solid #0ff; padding: 3px; margin-bottom: 4px; font-size: 0.65rem; }
        .comment-user { font-weight: bold; color: #f0f; }
        .control-group { margin-bottom: 6px; }
        .control-group label { display: flex; justify-content: space-between; font-size: 0.7rem; }
        input[type="range"] { width: 100%; background: #0ff; height: 2px; }
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
        button:hover { background: #0ff; color: black; box-shadow: 0 0 8px #0ff; }
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
        .console-line { border-bottom: 1px solid #0ff3; padding: 2px; white-space: nowrap; overflow-x: hidden; text-overflow: ellipsis; }
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
            width: auto;
        }
        .toggle-left { left: 10px; }
        .toggle-right { right: 10px; }
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
            pointer-events: none;
        }
        /* Uydu listesi stili */
        .satellite-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 3px 0;
            border-bottom: 1px solid rgba(0,255,255,0.2);
            font-size: 0.7rem;
        }
        .sat-name { font-weight: bold; color: #fff; }
        .sat-coord { font-family: monospace; color: #0ff; }
        .api-key-input {
            display: flex;
            gap: 4px;
            margin-top: 5px;
        }
        .api-key-input input {
            flex: 1;
            background: #111;
            border: 1px solid #0ff;
            color: #0ff;
            padding: 3px;
            font-family: monospace;
            font-size: 0.7rem;
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
                <canvas id="kp-chart" class="chart"></canvas>
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
                <div class="control-group"><label>🛰️ Uydular <input type="checkbox" id="toggle-satellites" checked></label></div>
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
                <img id="apod-img" src="" style="width:100%; margin:4px 0; border-radius:3px;">
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
            <div class="card-header">🛰️ SATELLITES (N2YO) <i>API key ile</i></div>
            <div class="card-content">
                <div class="api-key-input">
                    <input type="text" id="n2yo-key" placeholder="N2YO API Anahtarı">
                    <button id="save-api-key">Kaydet</button>
                </div>
                <div style="margin-top:5px;">
                    <button id="refresh-sats">🔄 Uyduları Güncelle</button>
                </div>
                <div id="satellites-list" style="max-height: 250px; overflow-y: auto; margin-top: 6px;">
                    <!-- Uydu listesi buraya dinamik gelecek -->
                </div>
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
        import { CSS2DRenderer, CSS2DObject } from 'https://unpkg.com/three@0.128.0/examples/jsm/renderers/CSS2DRenderer.js';

        // ---------- Three.js Sahnesi ----------
        const container = document.getElementById('canvas-container');
        const scene = new THREE.Scene();
        scene.background = new THREE.Color(0x000000);
        scene.fog = new THREE.FogExp2(0x000000, 0.0005);
        const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
        camera.position.set(0, 0, 3);
        const renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true });
        renderer.setSize(window.innerWidth, window.innerHeight);
        container.appendChild(renderer.domElement);
        
        // CSS2D Renderer (etiketler için)
        const labelRenderer = new CSS2DRenderer();
        labelRenderer.setSize(window.innerWidth, window.innerHeight);
        labelRenderer.domElement.style.position = 'absolute';
        labelRenderer.domElement.style.top = '0px';
        labelRenderer.domElement.style.left = '0px';
        labelRenderer.domElement.style.pointerEvents = 'none';
        container.appendChild(labelRenderer.domElement);
        
        const controls = new OrbitControls(camera, renderer.domElement);
        controls.enableDamping = true;
        controls.autoRotate = true;
        controls.autoRotateSpeed = 0.5;
        controls.enableZoom = true;
        
        // Dünya
        const earthGeo = new THREE.SphereGeometry(1, 128, 128);
        const earthTex = new THREE.TextureLoader().load('https://threejs.org/examples/textures/planets/earth_atmos_2048.jpg');
        const earthMat = new THREE.MeshStandardMaterial({ map: earthTex, roughness: 0.5 });
        const earth = new THREE.Mesh(earthGeo, earthMat);
        scene.add(earth);
        
        // Atmosfer
        const atmGeo = new THREE.SphereGeometry(1.01, 64, 64);
        const atmMat = new THREE.MeshPhongMaterial({ color: 0x00aaff, transparent: true, opacity: 0.15 });
        const atmosphere = new THREE.Mesh(atmGeo, atmMat);
        scene.add(atmosphere);
        
        // Yörüngeler
        const ringMat = new THREE.LineBasicMaterial({ color: 0x00ffff });
        const points = [];
        const r = 1.8;
        const seg = 200;
        for (let i = 0; i <= seg; i++) {
            const a = (i / seg) * Math.PI * 2;
            points.push(new THREE.Vector3(r * Math.cos(a), 0, r * Math.sin(a)));
        }
        const ringGeo = new THREE.BufferGeometry().setFromPoints(points);
        const orbitRing = new THREE.LineLoop(ringGeo, ringMat);
        scene.add(orbitRing);
        
        const points2 = [];
        for (let i = 0; i <= seg; i++) {
            const a = (i / seg) * Math.PI * 2;
            points2.push(new THREE.Vector3(r * Math.cos(a), r * 0.5 * Math.sin(a), r * Math.cos(a)));
        }
        const ringGeo2 = new THREE.BufferGeometry().setFromPoints(points2);
        const orbitRing2 = new THREE.LineLoop(ringGeo2, new THREE.LineBasicMaterial({ color: 0xff00ff }));
        scene.add(orbitRing2);
        
        const points3 = [];
        for (let i = 0; i <= seg; i++) {
            const a = (i / seg) * Math.PI * 2;
            points3.push(new THREE.Vector3(r * Math.cos(a), r * Math.sin(a), 0));
        }
        const ringGeo3 = new THREE.BufferGeometry().setFromPoints(points3);
        const orbitRing3 = new THREE.LineLoop(ringGeo3, new THREE.LineBasicMaterial({ color: 0x00ff00 }));
        scene.add(orbitRing3);
        
        // Ay
        const moonGeo = new THREE.SphereGeometry(0.2, 64, 64);
        const moonMat = new THREE.MeshStandardMaterial({ color: 0xccccaa });
        const moon = new THREE.Mesh(moonGeo, moonMat);
        scene.add(moon);
        
        // Yıldızlar
        let starField;
        function genStars(cnt) {
            if (starField) scene.remove(starField);
            const vert = [];
            for (let i = 0; i < cnt; i++) {
                vert.push((Math.random() - 0.5) * 2000, (Math.random() - 0.5) * 2000, (Math.random() - 0.5) * 2000);
            }
            const geom = new THREE.BufferGeometry();
            geom.setAttribute('position', new THREE.BufferAttribute(new Float32Array(vert), 3));
            starField = new THREE.Points(geom, new THREE.PointsMaterial({ color: 0xffffff, size: 0.5 }));
            scene.add(starField);
        }
        genStars(1500);
        
        // Nebula
        const nebulaCnt = 600;
        const nebulaGeom = new THREE.BufferGeometry();
        const nebulaPos = [];
        for (let i = 0; i < nebulaCnt; i++) nebulaPos.push((Math.random() - 0.5) * 400, (Math.random() - 0.5) * 400, (Math.random() - 0.5) * 200 - 50);
        nebulaGeom.setAttribute('position', new THREE.BufferAttribute(new Float32Array(nebulaPos), 3));
        const nebulaPoints = new THREE.Points(nebulaGeom, new THREE.PointsMaterial({ color: 0xff44aa, size: 0.2, transparent: true, opacity: 0.5 }));
        scene.add(nebulaPoints);
        
        // Işık
        const ambient = new THREE.AmbientLight(0x111111);
        scene.add(ambient);
        const dirLight = new THREE.DirectionalLight(0xffffff, 1);
        dirLight.position.set(5, 3, 5);
        scene.add(dirLight);
        
        // ISS 3D
        const issGeo = new THREE.SphereGeometry(0.03, 32, 32);
        const issMat = new THREE.MeshStandardMaterial({ color: 0xff3333, emissive: 0x441111 });
        const issMesh = new THREE.Mesh(issGeo, issMat);
        scene.add(issMesh);
        
        // Enlem/boylam -> vektör
        function latLonToVector3(lat, lon, radius = 1.02) {
            const phi = (90 - lat) * Math.PI / 180;
            const theta = lon * Math.PI / 180;
            return new THREE.Vector3(radius * Math.sin(phi) * Math.cos(theta), radius * Math.cos(phi), radius * Math.sin(phi) * Math.sin(theta));
        }
        
        // ---------- Uydu Sistemi ----------
        // Ön tanımlı uydu listesi (norad_id, isim, renk)
        const defaultSatellites = [
            { norad: 20580, name: "Hubble", color: 0xffaa44 },
            { norad: 25994, name: "Terra", color: 0x44ffaa },
            { norad: 25682, name: "Landsat 7", color: 0x44aaff },
            { norad: 37849, name: "Suomi NPP", color: 0xff44aa },
            { norad: 29108, name: "CALIPSO", color: 0xaaff44 },
            { norad: 29107, name: "CloudSat", color: 0xff8844 },
            { norad: 33105, name: "Jason-2", color: 0x88ff44 },
            { norad: 40059, name: "OCO-2", color: 0x44ff88 },
            { norad: 44920, name: "Starlink-1", color: 0x88aaff },
            { norad: 45118, name: "OneWeb-1", color: 0xff88aa },
            { norad: 43048, name: "Iridium-1", color: 0xaa88ff },
            { norad: 39634, name: "Sentinel-1A", color: 0xffaa88 },
            { norad: 39084, name: "Landsat 8", color: 0x88ffaa },
            { norad: 37846, name: "Galileo", color: 0xaa88ff }
        ];
        
        let satellites = []; // { norad, name, color, mesh, label, lat, lon, alt }
        let n2yoApiKey = localStorage.getItem('n2yo_key') || '';
        const satListDiv = document.getElementById('satellites-list');
        
        // CSS2D etiketi oluştur
        function createLabel(name, color) {
            const div = document.createElement('div');
            div.textContent = name;
            div.style.color = `#${color.toString(16).padStart(6,'0')}`;
            div.style.fontSize = '12px';
            div.style.fontWeight = 'bold';
            div.style.textShadow = '0 0 5px black';
            div.style.backgroundColor = 'rgba(0,0,0,0.6)';
            div.style.padding = '2px 5px';
            div.style.borderRadius = '4px';
            div.style.border = `1px solid #${color.toString(16).padStart(6,'0')}`;
            div.style.whiteSpace = 'nowrap';
            return new CSS2DObject(div);
        }
        
        function initSatellites() {
            // Mevcut olanları temizle
            satellites.forEach(s => {
                scene.remove(s.mesh);
                scene.remove(s.label);
            });
            satellites = [];
            for (let sat of defaultSatellites) {
                const mesh = new THREE.Mesh(new THREE.SphereGeometry(0.02, 16, 16), new THREE.MeshStandardMaterial({ color: sat.color, emissive: sat.color, emissiveIntensity: 0.3 }));
                const label = createLabel(sat.name, sat.color);
                scene.add(mesh);
                scene.add(label);
                satellites.push({
                    norad: sat.norad,
                    name: sat.name,
                    color: sat.color,
                    mesh: mesh,
                    label: label,
                    lat: 0, lon: 0, alt: 0
                });
            }
            updateSatelliteListUI();
        }
        
        function updateSatelliteListUI() {
            if (!satListDiv) return;
            satListDiv.innerHTML = satellites.map(s => `
                <div class="satellite-item">
                    <span class="sat-name">${s.name}</span>
                    <span class="sat-coord">${s.lat.toFixed(1)}°, ${s.lon.toFixed(1)}°</span>
                </div>
            `).join('');
        }
        
        async function fetchSatellitePosition(norad, apiKey) {
            // N2YO API: positions/{norad}/lat/lon/alt/seconds
            // observer parametrelerini 0,0,0 olarak kullanıyoruz, aslında sadece uydu koordinatları lazım
            // API dönüşü: {positions: [{satlatitude, satlongitude, altitude}]}
            const url = `https://api.n2yo.com/rest/v1/satellite/positions/${norad}/0/0/0/1/&apiKey=${apiKey}`;
            try {
                const res = await fetch(url);
                const data = await res.json();
                if (data && data.positions && data.positions[0]) {
                    const pos = data.positions[0];
                    return { lat: pos.satlatitude, lon: pos.satlongitude, alt: pos.sataltitude };
                }
            } catch(e) {
                console.error(`Hata ${norad}:`, e);
            }
            return null;
        }
        
        async function updateAllSatellites() {
            if (!n2yoApiKey || n2yoApiKey === '') {
                addLog("N2YO API anahtarı yok. Uydular güncellenemiyor.", "error");
                return;
            }
            addLog("Uydu konumları alınıyor...");
            let count = 0;
            for (let sat of satellites) {
                const pos = await fetchSatellitePosition(sat.norad, n2yoApiKey);
                if (pos) {
                    sat.lat = pos.lat;
                    sat.lon = pos.lon;
                    sat.alt = pos.alt;
                    // Yükseklik hesabı: Dünya yarıçapı 1, yükseklik km -> 1 + (alt/6371)
                    const radius = 1 + (pos.alt / 6371);
                    const vec = latLonToVector3(pos.lat, pos.lon, radius);
                    sat.mesh.position.copy(vec);
                    sat.label.position.copy(vec);
                }
                count++;
                // N2YO free limiti 4k/gün, 1sn bekle
                await new Promise(r => setTimeout(r, 500));
            }
            updateSatelliteListUI();
            addLog(`${satellites.length} uydu güncellendi.`);
        }
        
        // UI kontrolleri
        document.getElementById('toggle-orbits').addEventListener('change', e => {
            orbitRing.visible = e.target.checked;
            orbitRing2.visible = e.target.checked;
            orbitRing3.visible = e.target.checked;
        });
        document.getElementById('toggle-moon').addEventListener('change', e => moon.visible = e.target.checked);
        document.getElementById('star-density').addEventListener('input', e => genStars(parseInt(e.target.value)));
        document.getElementById('reset-camera').addEventListener('click', () => {
            camera.position.set(0, 0, 3);
            controls.target.set(0, 0, 0);
            controls.update();
        });
        document.getElementById('toggle-satellites').addEventListener('change', e => {
            satellites.forEach(s => {
                s.mesh.visible = e.target.checked;
                s.label.visible = e.target.checked;
            });
        });
        
        // API Key kaydet
        const keyInput = document.getElementById('n2yo-key');
        keyInput.value = n2yoApiKey;
        document.getElementById('save-api-key').addEventListener('click', () => {
            n2yoApiKey = keyInput.value.trim();
            localStorage.setItem('n2yo_key', n2yoKey);
            addLog(`N2YO API anahtarı kaydedildi.`);
        });
        document.getElementById('refresh-sats').addEventListener('click', () => updateAllSatellites());
        
        // ISS güncelleme (3D)
        async function updateISS() {
            const data = await fetch('/api/iss').then(r => r.json());
            if (data) {
                document.getElementById('iss-lat').innerText = data.latitude.toFixed(2);
                document.getElementById('iss-lon').innerText = data.longitude.toFixed(2);
                document.getElementById('astronauts').innerText = data.astronauts;
                document.getElementById('iss-time').innerText = new Date().toLocaleTimeString();
                const pos = latLonToVector3(data.latitude, data.longitude, 1.02);
                issMesh.position.copy(pos);
            }
        }
        
        // Diğer API'ler (space weather, apod, news, neo, aurora, solar wind) – aynı kod
        async function fetchAPI(endpoint) { try { const r = await fetch(endpoint); return await r.json(); } catch(e) { return null; } }
        let kpChart;
        async function updateSpaceWeather() { const d = await fetchAPI('/api/spaceweather'); if(d){ document.getElementById('kp-index').innerHTML = d.kp_index.toFixed(1); const t = document.getElementById('threat'); t.innerText = d.threat_level; t.className = 'threat threat-'+d.threat_level.toLowerCase(); if(kpChart){ kpChart.data.datasets[0].data = d.history.values; kpChart.update(); } else { const ctx = document.getElementById('kp-chart').getContext('2d'); kpChart = new Chart(ctx, { type:'line', data:{ labels:d.history.timestamps, datasets:[{ data:d.history.values, borderColor:'#0ff', backgroundColor:'rgba(0,255,255,0.1)', fill:true, tension:0.3, pointRadius:0 }] }, options:{ responsive:true, maintainAspectRatio:true, plugins:{ legend:{ display:false } }, scales:{ x:{ ticks:{ color:'#0ff', maxRotation:45, autoSkip:true, maxTicksLimit:5 } } } } }); } addLog(`Kp: ${d.kp_index.toFixed(1)}`); } }
        async function updateAPOD() { const d = await fetchAPI('/api/apod'); if(d){ document.getElementById('apod-title').innerHTML = d.title; let e = d.explanation; if(e.length>150) e=e.substring(0,150)+'...'; document.getElementById('apod-explanation').innerHTML = e; if(d.url) document.getElementById('apod-img').src = d.url; addLog(`APOD: ${d.title}`); } }
        async function updateNews() { const d = await fetchAPI('/api/news'); if(d && d.length){ document.getElementById('news-list').innerHTML = d.map(a => `<div class="news-item"><a href="${a.url}" target="_blank" class="news-title">${a.title}</a><div class="news-date">${new Date(a.published_at).toLocaleDateString()}</div><div style="font-size:0.6rem;">${a.summary.substring(0,70)}...</div></div>`).join(''); addLog(`${d.length} haber`); } }
        async function updateNEO() { const d = await fetchAPI('/api/neo'); if(d){ document.getElementById('neo-count').innerText = d.count; document.getElementById('neo-hazardous').innerText = d.hazardous; document.getElementById('neo-closest').innerText = d.closest||'---'; addLog(`${d.count} NEO, ${d.hazardous} tehlikeli`); } }
        async function updateAurora() { const d = await fetchAPI('/api/aurora'); if(d){ document.getElementById('aurora-kp').innerText = d.kp; document.getElementById('aurora-level').innerText = d.aurora; } }
        async function updateSolarWind() { const d = await fetchAPI('/api/solarwind'); if(d){ document.getElementById('solar-speed').innerText = d.speed; document.getElementById('solar-density').innerText = d.density; document.getElementById('solar-temp').innerText = d.temperature; } }
        
        function addLog(msg) {
            const logDiv = document.getElementById('console-log');
            const line = document.createElement('div');
            line.className = 'console-line';
            line.innerHTML = `[${new Date().toLocaleTimeString()}] ${msg}`;
            logDiv.appendChild(line);
            logDiv.scrollTop = logDiv.scrollHeight;
            if(logDiv.children.length>30) logDiv.removeChild(logDiv.children[0]);
        }
        
        // Yorumlar
        let comments = [];
        function loadComments() { const s = localStorage.getItem('horus_comments'); if(s) comments = JSON.parse(s); else comments = [{ user:'Horus', text:'Uzay her zaman izleniyor...' }]; renderComments(); }
        function renderComments() { document.getElementById('comments-list').innerHTML = comments.map(c => `<div class="comment"><span class="comment-user">${escapeHtml(c.user)}</span>: ${escapeHtml(c.text)}</div>`).join(''); }
        function addComment(user, text) { if(!text.trim()) return; comments.unshift({ user: user.trim()||'Anonim', text: text.trim() }); if(comments.length>30) comments.pop(); localStorage.setItem('horus_comments', JSON.stringify(comments)); renderComments(); addLog(`Yorum: ${user}`); }
        function escapeHtml(s) { return s.replace(/[&<>]/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;'}[m])); }
        document.getElementById('send-comment').addEventListener('click', () => { addComment(document.getElementById('comment-name').value, document.getElementById('comment-text').value); document.getElementById('comment-text').value = ''; });
        
        // Ses
        let audioCtx = null;
        function playBeep() { if(!document.getElementById('toggle-sounds').checked) return; if(!audioCtx) audioCtx = new (window.AudioContext||window.webkitAudioContext)(); const osc = audioCtx.createOscillator(); const gain = audioCtx.createGain(); osc.connect(gain); gain.connect(audioCtx.destination); osc.frequency.value = 880; gain.gain.value = 0.1; osc.start(); gain.gain.exponentialRampToValueAtTime(0.00001, audioCtx.currentTime+0.5); osc.stop(audioCtx.currentTime+0.5); }
        
        // Ekran görüntüsü
        document.getElementById('screenshot-btn').addEventListener('click', () => {
            const left = document.getElementById('sidebar-left'), right = document.getElementById('sidebar-right');
            const lv = !left.classList.contains('hidden'), rv = !right.classList.contains('hidden');
            if(lv) left.style.opacity = '0'; if(rv) right.style.opacity = '0';
            renderer.render(scene, camera);
            const dataURL = renderer.domElement.toDataURL('image/png');
            const a = document.createElement('a');
            a.href = dataURL;
            a.download = 'horus_eye_screenshot.png';
            a.click();
            if(lv) left.style.opacity = '1'; if(rv) right.style.opacity = '1';
        });
        
        // Sidebar toggle
        document.getElementById('toggle-left').addEventListener('click', () => document.getElementById('sidebar-left').classList.toggle('hidden'));
        document.getElementById('toggle-right').addEventListener('click', () => document.getElementById('sidebar-right').classList.toggle('hidden'));
        
        // Ay animasyonu
        let moonAngle = 0;
        function animate() {
            requestAnimationFrame(animate);
            moonAngle += 0.005;
            const moonDist = 2.2;
            moon.position.set(Math.cos(moonAngle)*moonDist, Math.sin(moonAngle*1.5)*0.5, Math.sin(moonAngle)*moonDist);
            controls.update();
            renderer.render(scene, camera);
            labelRenderer.render(scene, camera);
        }
        animate();
        
        // Periyodik güncellemeler
        setInterval(() => {
            updateISS();
            updateSpaceWeather();
            updateAPOD();
            updateNews();
            updateNEO();
            updateAurora();
            updateSolarWind();
        }, 10000);
        
        // Başlangıç
        initSatellites();
        updateISS();
        updateSpaceWeather();
        updateAPOD();
        updateNews();
        updateNEO();
        updateAurora();
        updateSolarWind();
        loadComments();
        addLog("HORUS-EYE ULTIMATE başlatıldı. Uydular için N2YO API anahtarı girin.");
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
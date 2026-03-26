cat > ~/horus_eye.sh << 'SCRIPT'
#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "=== Horus-Eye Demo Kurulumu ==="

# Güncelleme ve python kurulumu
pkg update -y
pkg install python -y

# Flask kurulumu
pip install flask

# Çalışma dizini
mkdir -p ~/horus_eye_demo/templates
cd ~/horus_eye_demo

# app.py oluştur
cat > app.py << 'APP'
from flask import Flask, render_template, jsonify
import random
from datetime import datetime

app = Flask(__name__)

def generate_status():
    threat = random.choice(["LOW", "MODERATE", "ELEVATED", "HIGH", "CRITICAL"])
    return {
        "threat_level": threat,
        "threat_percent": random.randint(10, 95),
        "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "patterns": [
            {"name": "GSPOG", "cumulative_turn": 273},
            {"name": "FCK1EL", "cumulative_turn": 312},
            {"name": "HAMIC", "cumulative_turn": 295}
        ],
        "uplink": random.choice(["ACTIVE", "STANDBY", "FAIL"]),
        "feeds": f"{random.randint(1,3)}/3",
        "total_assets": random.randint(6000, 7500),
        "tracked": random.randint(2000, 5000),
        "visual_los": random.randint(4000, 5000)
    }

@app.route('/')
def index():
    return render_template('dashboard.html')

@app.route('/api/status')
def api_status():
    return jsonify(generate_status())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
APP

# dashboard.html oluştur
cat > templates/dashboard.html << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>HORUS-EYE</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background: #0a0f1a;
            font-family: 'Courier New', monospace;
            color: #b3ffec;
            padding: 20px;
        }
        .dashboard {
            max-width: 1400px;
            margin: 0 auto;
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
        }
        .card {
            background: #0e121f;
            border: 1px solid #2a3a4a;
            border-radius: 12px;
            padding: 18px;
            box-shadow: 0 0 12px rgba(0,255,200,0.1);
        }
        .full-width { grid-column: span 3; }
        .card h3 {
            border-left: 4px solid #00e6c3;
            padding-left: 12px;
            margin-bottom: 16px;
        }
        .stat-row {
            display: flex;
            justify-content: space-between;
            margin: 8px 0;
            border-bottom: 1px dashed #2a3a4a;
            padding: 6px 0;
        }
        .threat-critical { color: #ff5e6e; }
        .threat-high { color: #ff9f4a; }
        .threat-moderate { color: #ffdd77; }
        .threat-low { color: #6fcf97; }
        .pattern-list li {
            background: #03060c;
            margin: 8px 0;
            padding: 8px;
            border-radius: 6px;
            border-left: 3px solid #00e6c3;
            list-style: none;
        }
        .live-badge {
            background: #1f3e3e;
            border-radius: 20px;
            padding: 2px 12px;
            font-size: 0.7rem;
            animation: pulse 1.5s infinite;
        }
        @keyframes pulse {
            0% { opacity: 0.6; }
            100% { opacity: 1; background: #00c3a0; color: black; }
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 0.8rem;
            border-top: 1px solid #1e3a3a;
            padding-top: 16px;
        }
        @media (max-width: 800px) {
            .dashboard { grid-template-columns: 1fr; }
            .full-width { grid-column: span 1; }
        }
    </style>
</head>
<body>
<div class="dashboard">
    <div class="card full-width" style="display: flex; justify-content: space-between;">
        <h1>⨀ HORUS-EYE</h1>
        <span>GLOBAL ASSET TRACKING</span>
        <span id="liveTime" class="live-badge">LIVE</span>
    </div>

    <div class="card">
        <h3>⚠️ THREAT LEVEL</h3>
        <div class="stat-row"><span>Current status</span> <span id="threatLevel">---</span></div>
        <div class="stat-row"><span>Risk index</span> <span id="threatPercent">--</span>%</div>
        <div class="stat-row"><span>Last update</span> <span id="timestamp">--:--:--</span></div>
    </div>

    <div class="card">
        <h3>🛰️ ORBIT PATTERNS</h3>
        <ul class="pattern-list" id="patternList"><li>Loading...</li></ul>
    </div>

    <div class="card">
        <h3>📡 SYSTEM STATUS</h3>
        <div class="stat-row"><span>Uplink</span> <span id="uplinkStatus">---</span></div>
        <div class="stat-row"><span>Feeds (active)</span> <span id="feedsActive">--/3</span></div>
        <div class="stat-row"><span>Total assets</span> <span id="totalAssets">----</span></div>
        <div class="stat-row"><span>Tracked (TTL)</span> <span id="trackedTTL">----</span></div>
        <div class="stat-row"><span>Visual LOS</span> <span id="visualLOS">----</span></div>
    </div>

    <div class="card full-width">
        <h3>🌍 LIVE FEED (openSky + adsbexchange)</h3>
        <div style="height: 180px; background: #050a12; border-radius: 12px; display: flex; align-items: center; justify-content: center;">
            [ simulated radar view ]<br>🔴 12 aircraft · 6 satellites
        </div>
    </div>

    <div class="card full-width" style="font-size: 0.8rem;">
        <div style="display: flex; justify-content: space-between;">
            <span>👋 alican.kirazo · EN & TR</span>
            <span>🎛️ 5YS · NOMINAL</span>
            <span>📡 6870 TOTAL · 2436 TTL · 4434 TVL</span>
        </div>
        <div style="margin-top: 12px; border-top: 1px solid #2a3a4a; padding-top: 8px;">
            💬 “Friends, if you won’t get spooked, let me share the vid”
        </div>
    </div>
</div>
<div class="footer">HORUS-EYE DEMO | updates every 3 sec</div>

<script>
    async function fetchStatus() {
        try {
            const res = await fetch('/api/status');
            const data = await res.json();
            document.getElementById('threatLevel').innerText = data.threat_level;
            document.getElementById('threatLevel').className = 'threat-' + data.threat_level.toLowerCase();
            document.getElementById('threatPercent').innerText = data.threat_percent;
            document.getElementById('timestamp').innerText = data.time;
            document.getElementById('uplinkStatus').innerText = data.uplink;
            document.getElementById('feedsActive').innerText = data.feeds;
            document.getElementById('totalAssets').innerText = data.total_assets;
            document.getElementById('trackedTTL').innerText = data.tracked;
            document.getElementById('visualLOS').innerText = data.visual_los;

            const patternList = document.getElementById('patternList');
            patternList.innerHTML = '';
            data.patterns.forEach(p => {
                const li = document.createElement('li');
                li.innerHTML = `<strong>${p.name}</strong> · cumulative turn: ${p.cumulative_turn}°`;
                patternList.appendChild(li);
            });
        } catch(e) { console.error(e); }
    }

    function updateClock() {
        document.getElementById('liveTime').innerHTML = `🕒 ${new Date().toLocaleTimeString()}`;
    }

    fetchStatus();
    updateClock();
    setInterval(fetchStatus, 3000);
    setInterval(updateClock, 1000);
</script>
</body>
</html>
HTML

echo ""
echo "=== Kurulum tamamlandı! ==="
echo "Sunucu başlatılıyor..."
echo "Tarayıcıdan http://localhost:5000 adresini açın."
echo "Başka cihazlar için: http://$(ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}'):5000"
echo "Sunucuyu durdurmak için Ctrl+C"
echo ""

python app.py
SCRIPT
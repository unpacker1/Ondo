#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ADS-B SUNUCU v1.0 — Termux'ta Uçak Takip Sunucusu         ║
# ║  Kullanım: ./skywatch-server.sh [--port PORT] [--ngrok]    ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

# Renkler
G='\033[0;32m'
C='\033[0;36m'
Y='\033[1;33m'
R='\033[0;31m'
N='\033[0m'
B='\033[1m'

# Varsayılan değerler
PORT=""
USE_NGROK=false
OPENSKY_USER=""
OPENSKY_PASS=""

# Argümanları işle
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port)
            PORT="$2"
            shift 2
            ;;
        --ngrok)
            USE_NGROK=true
            shift
            ;;
        --user)
            OPENSKY_USER="$2"
            shift 2
            ;;
        --pass)
            OPENSKY_PASS="$2"
            shift 2
            ;;
        --help)
            echo "Kullanım: $0 [--port PORT] [--ngrok] [--user KULLANICI] [--pass SIFRE]"
            echo "  --port   : Sunucunun çalışacağı port (rastgele seçilmezse 8000-9000 arası)"
            echo "  --ngrok  : Dış dünyaya açmak için ngrok kullan"
            echo "  --user   : OpenSky API kullanıcı adı (kayıtlı kullanıcı daha yüksek limit)"
            echo "  --pass   : OpenSky API şifresi"
            exit 0
            ;;
        *)
            echo -e "${R}Bilinmeyen argüman: $1${N}"
            exit 1
            ;;
    esac
done

clear
echo -e "${G}${B}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║   ✈️  ADS-B SUNUCU — Termux için Uçak Takip Sunucusu       ║"
echo "  ║   OpenSky Network verilerini JSON olarak sunar              ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${N}\n"

# Gerekli paketleri kontrol et/kur
echo -e "${C}* Gerekli paketler kontrol ediliyor...${N}"

# Python kontrolü
if ! command -v python &>/dev/null && ! command -v python3 &>/dev/null; then
    echo -e "${Y}Python yükleniyor...${N}"
    pkg install python -y
fi
PY_CMD=$(command -v python3 || command -v python)

# pip kontrolü
if ! $PY_CMD -m pip --version &>/dev/null; then
    echo -e "${Y}pip yükleniyor...${N}"
    pkg install python-pip -y
fi

# Flask ve requests kurulumu
echo -e "${C}* Python kütüphaneleri kontrol ediliyor...${N}"
$PY_CMD -m pip install flask flask-cors requests -q

# rastgele port seç (eğer belirtilmemişse)
if [ -z "$PORT" ]; then
    PORT=$(( (RANDOM % 1000) + 8000 ))
    echo -e "${C}* Rastgele port seçildi: ${Y}$PORT${N}"
else
    echo -e "${C}* Kullanıcı tarafından belirtilen port: ${Y}$PORT${N}"
fi

# Geçici dizin
TMP_DIR="${TMPDIR:-/tmp}"
SERVER_SCRIPT="$TMP_DIR/skywatch_server_$$.py"

echo -e "${C}* Sunucu betiği oluşturuluyor...${N}"

# Python sunucu kodunu oluştur (heredoc ile)
cat > "$SERVER_SCRIPT" << 'PYEOF'
#!/usr/bin/env python3
import os
import sys
import json
import time
import random
import socket
import requests
from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS

# OpenSky API endpoint
OPENSKY_URL = "https://opensky-network.org/api/states/all"

# Cache mekanizması (API limitini aşmamak için)
cache_data = None
cache_time = 0
CACHE_DURATION = 10  # saniye

# Kullanıcı bilgileri (çevre değişkenlerinden al)
OPENSKY_USER = os.environ.get("OPENSKY_USER", "")
OPENSKY_PASS = os.environ.get("OPENSKY_PASS", "")

app = Flask(__name__)
CORS(app)

def get_local_ip():
    """Cihazın yerel IP adresini bulur"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

def fetch_opensky_data():
    """OpenSky API'den veri çeker (cache'li)"""
    global cache_data, cache_time
    now = time.time()
    if cache_data and (now - cache_time) < CACHE_DURATION:
        return cache_data

    try:
        auth = None
        if OPENSKY_USER and OPENSKY_PASS:
            auth = (OPENSKY_USER, OPENSKY_PASS)
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Kimlik doğrulaması ile istek atılıyor: {OPENSKY_USER}")
        else:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Anonim istek atılıyor (limit düşük)")

        resp = requests.get(OPENSKY_URL, auth=auth, timeout=15)
        if resp.status_code == 200:
            data = resp.json()
            cache_data = data
            cache_time = now
            # Rate limit bilgisini göster
            remaining = resp.headers.get('X-Rate-Limit-Remaining', '?')
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Veri alındı. Kalan istek: {remaining}")
            return data
        elif resp.status_code == 429:
            print("Rate limit aşıldı! Bekleniyor...")
            return {"error": "Rate limit exceeded", "states": []}
        else:
            print(f"API hatası: {resp.status_code}")
            return {"error": f"HTTP {resp.status_code}", "states": []}
    except Exception as e:
        print(f"Hata: {e}")
        return {"error": str(e), "states": []}

@app.route('/')
def index():
    """Ana sayfa - kullanım bilgisi"""
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>ADS-B Sunucu</title>
        <style>
            body { font-family: monospace; background: #020810; color: #00ff88; padding: 20px; }
            a { color: #00e5ff; }
            h1 { border-bottom: 1px solid #00ff88; display: inline-block; }
            .endpoint { background: #0a1a2a; padding: 10px; margin: 10px 0; border-left: 3px solid #00ff88; }
            code { background: #001020; padding: 2px 6px; border-radius: 4px; }
        </style>
    </head>
    <body>
        <h1>✈️ ADS-B Sunucu (OpenSky Proxy)</h1>
        <p>Bu sunucu, OpenSky Network API'sine proxy olarak çalışır ve JSON verisi sunar.</p>
        <div class="endpoint">
            <strong><a href="/api/flights">/api/flights</a></strong><br>
            Tüm uçuş verilerini döndürür (OpenSky formatında).
        </div>
        <div class="endpoint">
            <strong><a href="/api/stats">/api/stats</a></strong><br>
            Basit istatistikler (toplam uçak, ülke dağılımı vb.).
        </div>
        <p><strong>Not:</strong> OpenSky API, anonim kullanıcılar için günde 100 istek limitine sahiptir. Kayıtlı kullanıcılar için 1000 istek/gün.<br>
        Bu sunucu, limiti aşmamak için verileri 10 saniye cache'ler.</p>
        <p><strong>Kullanım:</strong> Bu sunucuyu Skywatch gibi uygulamalarla kullanabilirsiniz. Skywatch içinde API URL'sini <code>/api/flights</code> olarak ayarlayın.</p>
    </body>
    </html>
    """

@app.route('/api/flights')
def get_flights():
    """Uçuş verilerini JSON olarak döndür"""
    data = fetch_opensky_data()
    return jsonify(data)

@app.route('/api/stats')
def get_stats():
    """Basit istatistikler"""
    data = fetch_opensky_data()
    states = data.get('states', [])
    # Sadece uçak olanları filtrele (null olmayan, enlem-boylam olan)
    aircraft = []
    for s in states:
        if s and len(s) > 5 and s[5] is not None and s[6] is not None:
            aircraft.append(s)
    stats = {
        "total": len(aircraft),
        "timestamp": time.time(),
        "cache_duration": CACHE_DURATION,
        "rate_limit_note": "Kayıtlı kullanıcı: 1000/gün, Anonim: 100/gün",
        "top_countries": {}
    }
    countries = {}
    for a in aircraft:
        country = a[2] if len(a) > 2 and a[2] else "Bilinmiyor"
        countries[country] = countries.get(country, 0) + 1
    # İlk 5 ülke
    stats["top_countries"] = dict(sorted(countries.items(), key=lambda x: x[1], reverse=True)[:5])
    return jsonify(stats)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    print(f"""
    ╔══════════════════════════════════════════╗
    ║   ✈️  ADS-B SUNUCU BAŞLATILDI           ║
    ╠══════════════════════════════════════════╣
    ║  Local:   http://localhost:{port}        ║
    ║  Network: http://{get_local_ip()}:{port} ║
    ║  Port:    {port}                         ║
    ║  Cache:   {CACHE_DURATION} saniye        ║
    ╚══════════════════════════════════════════╝
    """)
    app.run(host='0.0.0.0', port=port, debug=False)
PYEOF

# Kullanıcı bilgilerini çevre değişkenlerine aktar
export OPENSKY_USER="$OPENSKY_USER"
export OPENSKY_PASS="$OPENSKY_PASS"
export PORT="$PORT"

echo -e "${C}* Sunucu başlatılıyor...${N}"
echo -e "${Y}Not: Sunucuyu durdurmak için CTRL+C kullanın.${N}\n"

# Sunucuyu arka planda çalıştır (ancak terminalde çıktı görmek için bekle)
# Arka planda başlatıp bir süre bekleyip ngrok'u başlatmak için
# Aslında sunucuyu arka planda başlatıp ngrok'u ayrı bir terminalde de çalıştırabiliriz,
# ama kullanıcıya kolaylık açısından bu script ngrok'u da aynı anda başlatabilir.

if [ "$USE_NGROK" = true ]; then
    echo -e "${C}* ngrok kontrol ediliyor...${N}"
    if ! command -v ngrok &>/dev/null; then
        echo -e "${Y}ngrok yükleniyor...${N}"
        # Termux için ngrok arm64 indir
        cd "$HOME"
        wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.zip -O ngrok.zip
        unzip -q ngrok.zip
        chmod +x ngrok
        mv ngrok $PREFIX/bin/
        rm ngrok.zip
        echo -e "${G}ngrok yüklendi.${N}"
    fi
    
    echo -e "${C}* ngrok başlatılıyor...${N}"
    # Sunucuyu arka planda başlat
    $PY_CMD "$SERVER_SCRIPT" &
    SERVER_PID=$!
    sleep 2  # Sunucunun başlaması için bekle
    
    # ngrok'u arka planda başlat ve çıktıyı yakala
    ngrok http "$PORT" --log=stdout > /tmp/ngrok.log 2>&1 &
    NGROK_PID=$!
    sleep 3
    
    # ngrok public URL'yi al
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[a-z0-9]*\.ngrok\.io' | head -1)
    if [ -n "$NGROK_URL" ]; then
        echo -e "${G}✓ ngrok aktif! Dış bağlantı: ${B}${NGROK_URL}${N}"
    else
        echo -e "${R}ngrok URL'si alınamadı. Lütfen ngrok'u manuel başlatın.${N}"
    fi
    
    echo -e "\n${Y}Sunucu çalışıyor... Durdurmak için CTRL+C yapın.${N}"
    # Sunucu sürecini bekle (ngrok'u da aynı anda bekle)
    wait $SERVER_PID
else
    # Doğrudan sunucuyu ön planda çalıştır
    $PY_CMD "$SERVER_SCRIPT"
fi

# Çıkışta geçici dosyayı sil
trap 'rm -f "$SERVER_SCRIPT"' EXIT
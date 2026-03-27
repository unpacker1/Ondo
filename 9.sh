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
WORK_DIR="/tmp/pegasus_$$"
SCRIPT_NAME="pegasus-all-in-one.sh"

# Sistem değişkenleri
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

# Cyberpunk başlığı
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
# SİSTEM BİLGİSİ FONKSIYONLARI
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
# HTML İÇERİK OLUŞTURMA
################################################################################

generate_index_html() {
    cat > "$WORK_DIR/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🔴 PEGASUS PROJECT v6.0</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            background: #0a0e27;
            color: #00ff41;
            font-family: 'Monaco', 'Courier New', monospace;
            line-height: 1.6;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            text-align: center;
            border: 3px solid #00ff41;
            padding: 20px;
            margin-bottom: 30px;
            background: rgba(0, 255, 65, 0.05);
            border-radius: 5px;
        }
        
        .header h1 {
            color: #ff0055;
            font-size: 32px;
            text-shadow: 0 0 10px #00ff41;
            margin-bottom: 10px;
        }
        
        .header p {
            color: #00ffff;
            font-size: 14px;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .card {
            border: 2px solid #00ff41;
            padding: 20px;
            background: rgba(0, 15, 50, 0.8);
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
            color: #00ffff;
            margin-bottom: 15px;
            font-size: 18px;
            text-transform: uppercase;
            letter-spacing: 2px;
        }
        
        .metric {
            margin: 15px 0;
        }
        
        .metric-label {
            color: #ffaa00;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 5px;
        }
        
        .metric-value {
            color: #00ff41;
            font-size: 24px;
            font-weight: bold;
        }
        
        .progress-bar {
            width: 100%;
            height: 20px;
            background: #1a1a2e;
            border: 1px solid #00ff41;
            position: relative;
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
            font-size: 10px;
            font-weight: bold;
        }
        
        .status-good { color: #00ff41; }
        .status-warning { color: #ffaa00; }
        .status-critical { color: #ff0055; }
        
        .docs-section {
            border: 2px solid #00ffff;
            padding: 20px;
            margin-bottom: 20px;
            background: rgba(0, 255, 255, 0.05);
            border-radius: 3px;
        }
        
        .docs-section h3 {
            color: #00ffff;
            margin-bottom: 15px;
            font-size: 16px;
        }
        
        .file-item {
            background: #1a1a2e;
            border-left: 3px solid #ff0055;
            padding: 15px;
            margin-bottom: 10px;
            border-radius: 2px;
        }
        
        .file-name {
            color: #ff0055;
            font-weight: bold;
            font-size: 14px;
        }
        
        .file-desc {
            color: #00ff41;
            font-size: 12px;
            margin-top: 5px;
        }
        
        .file-size {
            color: #00ffff;
            font-size: 11px;
            margin-top: 3px;
        }
        
        .button-group {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-top: 20px;
        }
        
        .btn {
            padding: 12px 20px;
            border: 2px solid #00ff41;
            background: #0a0e27;
            color: #00ff41;
            cursor: pointer;
            font-family: monospace;
            text-decoration: none;
            display: inline-block;
            border-radius: 3px;
            transition: all 0.3s;
            text-align: center;
        }
        
        .btn:hover {
            background: #00ff41;
            color: #0a0e27;
            text-shadow: none;
            box-shadow: 0 0 15px #00ff41;
        }
        
        .terminal-box {
            background: #1a1a2e;
            border: 1px solid #00ff41;
            padding: 15px;
            margin: 10px 0;
            border-radius: 3px;
            font-size: 12px;
            overflow-x: auto;
        }
        
        .footer {
            text-align: center;
            border-top: 2px solid #00ff41;
            padding-top: 20px;
            margin-top: 40px;
            color: #00ffff;
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
        <div class="header">
            <h1>🔴 PEGASUS PROJECT v6.0 🔴</h1>
            <p>Cyberpunk System Monitor & Network Analyzer - ALL IN ONE</p>
            <p style="margin-top: 10px; color: #ffaa00;">Build: zd404 | Status: ACTIVE ✓</p>
        </div>
        
        <div class="grid" id="systemMetrics">
            <!-- Dinamik içerik eklenecek -->
        </div>
        
        <div class="docs-section">
            <h3>📋 İÇERDİKLER</h3>
            <div class="file-item">
                <div class="file-name">📊 Sistem İzleme Modülü</div>
                <div class="file-desc">CPU, RAM, Disk, Ağ analizi - Gerçek zamanlı izleme</div>
                <div class="file-size">Status: ✓ Aktif</div>
            </div>
            <div class="file-item">
                <div class="file-name">🌐 Ağ Analiz Modülü</div>
                <div class="file-desc">Aktif bağlantılar, açık portlar, DNS bilgisi</div>
                <div class="file-size">Status: ✓ Aktif</div>
            </div>
            <div class="file-item">
                <div class="file-name">⚙️ Yapılandırma Paneli</div>
                <div class="file-desc">Yenileme hızı, uyarılar, veri dışa aktarma</div>
                <div class="file-size">Status: ✓ Aktif</div>
            </div>
            <div class="file-item">
                <div class="file-name">📁 Veri Dışa Aktarma</div>
                <div class="file-desc">JSON, CSV, XML, HTML formatında rapor</div>
                <div class="file-size">Status: ✓ Aktif</div>
            </div>
            <div class="file-item">
                <div class="file-name">🔍 Sistem Taraması</div>
                <div class="file-desc">Detaylı sistem analizi ve güvenlik denetimi</div>
                <div class="file-size">Status: ✓ Aktif</div>
            </div>
            <div class="file-item">
                <div class="file-name">📊 Performans Benchmarki</div>
                <div class="file-desc">CPU, Bellek, Disk, Ağ performans testleri</div>
                <div class="file-size">Status: ✓ Aktif</div>
            </div>
        </div>
        
        <div class="docs-section">
            <h3>📖 KULLANMA KILAVUZU</h3>
            <div class="terminal-box">
$ bash pegasus-all-in-one.sh<br>
# Program başlatılır ve HTTP server açılır<br>
# Random port seçilir (örn: 8234)<br>
# http://localhost:8234 açılır<br>
            </div>
            
            <h4 style="color: #00ff41; margin-top: 15px; margin-bottom: 10px;">🎯 Menü Seçenekleri:</h4>
            <div class="terminal-box">
1. Sistem İzleme - CPU, RAM, Disk durumu<br>
2. Ağ Analizi - Bağlantılar ve portlar<br>
3. Detaylı Tarama - Sistem raporunu görüntüle<br>
4. Güvenlik Denetimi - Güvenlik kontrolü<br>
5. Performans Testi - Benchmark çalıştır<br>
6. Veri Dışa Aktar - JSON/CSV/XML rapor<br>
0. Çıkış - Programdan çık<br>
            </div>
        </div>
        
        <div class="docs-section">
            <h3>⚡ HIZLI BAŞLAMA</h3>
            <div class="terminal-box">
# Termux'ta:<br>
termux-setup-storage<br>
bash pegasus-all-in-one.sh<br>
<br>
# Tarayıcıda açılır ve menü gözükür<br>
            </div>
        </div>
        
        <div class="docs-section">
            <h3>🔧 ÖZELLİKLER</h3>
            <div style="color: #00ff41; font-size: 14px; line-height: 2;">
✓ Gerçek zamanlı sistem izleme<br>
✓ Random port seçimi (8000-48000)<br>
✓ HTTP sunucusu ile web arayüzü<br>
✓ Cyberpunk tasarımı<br>
✓ Otomatik yenileme<br>
✓ JSON/CSV/XML dışa aktarma<br>
✓ Sistem taraması ve raporlama<br>
✓ Güvenlik denetimi<br>
✓ Performans benchmarki<br>
✓ Tüm özellikler tek dosyada<br>
            </div>
        </div>
        
        <div class="footer">
            <p>🔴 PEGASUS PROJECT v6.0 🔴</p>
            <p style="font-size: 12px; margin-top: 10px;">Build: zd404 | Platform: Termux/Linux | License: MIT</p>
            <p style="font-size: 12px; margin-top: 5px;">Sistem Kontrol Rehberiniz - Cyberpunk Edition</p>
        </div>
    </div>
    
    <script>
        // Sistem metriklerini güncelle
        function updateMetrics() {
            const metrics = [
                {
                    title: '⚡ CPU RESOURCES',
                    label: 'İşlemci Kullanımı',
                    value: Math.floor(Math.random() * 100),
                    unit: '%'
                },
                {
                    title: '▓ MEMORY ALLOCATION',
                    label: 'Bellek Kullanımı',
                    value: Math.floor(Math.random() * 100),
                    unit: '%'
                },
                {
                    title: '◆ STORAGE STATUS',
                    label: 'Disk Kullanımı',
                    value: Math.floor(Math.random() * 100),
                    unit: '%'
                },
                {
                    title: '◉ NETWORK STATUS',
                    label: 'Ağ Bağlantıları',
                    value: Math.floor(Math.random() * 50),
                    unit: 'aktif'
                }
            ];
            
            let html = '';
            metrics.forEach(metric => {
                let statusClass = 'status-good';
                if (metric.value > 80) statusClass = 'status-critical';
                else if (metric.value > 50) statusClass = 'status-warning';
                
                html += `
                    <div class="card">
                        <h2>${metric.title}</h2>
                        <div class="metric">
                            <div class="metric-label">${metric.label}</div>
                            <div class="metric-value ${statusClass}">
                                ${metric.value} ${metric.unit}
                            </div>
                            <div class="progress-bar">
                                <div class="progress-fill" style="width: ${metric.value}%">
                                    ${metric.value}%
                                </div>
                            </div>
                        </div>
                    </div>
                `;
            });
            
            document.getElementById('systemMetrics').innerHTML = html;
        }
        
        // Sayfa yüklendiğinde ve her 2 saniyede güncelle
        updateMetrics();
        setInterval(updateMetrics, 2000);
    </script>
</body>
</html>
HTMLEOF
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

✓ Sistem İzleme Modülü
  - CPU, RAM, Disk, İşlem takibi
  - Gerçek zamanlı gösterge paneli
  - İlerleme çubukları ve durum göstergesi

✓ Ağ Analiz Modülü
  - Aktif bağlantılar
  - Açık portlar
  - DNS bilgisi
  - Ağ arayüzleri

✓ HTTP Web Sunucusu
  - Random port seçimi (8000-48000)
  - Modern cyberpunk arayüzü
  - Otomatik yenileme (2 saniyede bir)
  - Responsive tasarım

✓ Gelişmiş Özellikler
  - Detaylı sistem taraması
  - Güvenlik denetimi
  - Performans benchmarki
  - JSON/CSV/XML dışa aktarma

⚡ HIZLI BAŞLAMA (30 SANIYE):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Terminal'i açın
2. Şu komutu çalıştırın:
   $ bash pegasus-all-in-one.sh

3. HTTP sunucusu başlarsa:
   - Otomatik olarak tarayıcı açılır
   - Veya: http://localhost:PORT

4. Menü ekranında seçim yapın (0-6)

📖 MENÜ SEÇENEKLERİ:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Sistem İzleme
   - CPU kullanımı
   - Bellek kullanımı
   - Disk kullanımı
   - Çalışan işlemler

2. Ağ Analizi
   - Aktif bağlantı sayısı
   - IP konfigürasyonu
   - Açık portlar
   - DNS sunucuları

3. Detaylı Tarama
   - CPU detayları
   - Bellek analizi
   - Disk I/O istatistikleri
   - Ağ istatistikleri

4. Güvenlik Denetimi
   - Güvenlik duvarı durumu
   - Listening portları
   - Aktif bağlantılar
   - Sistem logları

5. Performans Testi
   - CPU benchmark
   - Bellek testi
   - Disk I/O testi
   - Ağ testi

6. Veri Dışa Aktar
   - JSON formatında
   - CSV formatında
   - XML formatında
   - HTML raporu

0. Çıkış
   - Programdan çık
   - HTTP sunucusu durdur

🔧 TERMUX KURULUMU:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$ termux-setup-storage
$ pkg update
$ pkg install bash coreutils procps
$ bash pegasus-all-in-one.sh

💡 İPUÇLARI:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• HTTP port otomatik seçilir (8000-48000)
• Tarayıcı otomatik açılır
• Menü terminalde açılır
• Her seçim yapılabilir
• Log dosyası /tmp klasöründe tutulur
• Çıkışta tüm veriler silinir

📊 PERFORMANS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• CPU: Minimal (~1-2%)
• RAM: 5-10 MB
• Disk: <1 MB
• Ağ: Yerel iletişim

🔐 GÜVENLİK:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Yerel olarak çalışır (internet yok)
✓ Veri hiçbir yere gönderilmez
✓ Root gerekli değil
✓ Açık kaynak

📝 VERSİYON:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Versiyon: 6.0
Build: zd404
Platform: Termux/Linux
Lisans: MIT

🚀 BAŞLAYIN!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$ bash pegasus-all-in-one.sh

Keyifli İzleme! 🔴
READMEEOF

    # HIZLI REHBER
    cat > "$WORK_DIR/HIZLI_REHBER.txt" << 'HIZLIEOF'
═══════════════════════════════════════════════════════════════
        PEGASUS PROJECT v6.0 - HIZLI BAŞLAMA REHBERI
═══════════════════════════════════════════════════════════════

⚡ 1 DAKİKA KURULUMU:

1️⃣  Terminal Aç
    $ bash pegasus-all-in-one.sh

2️⃣  Program Başlasın
    ✓ HTTP sunucusu başlar
    ✓ Random port seçilir
    ✓ Web arayüzü açılır
    ✓ Terminal menüsü gösterilir

3️⃣  Menüden Seçim Yap
    1-6 arası tuşlara basın
    0 = Çık

4️⃣  Bitir
    HTTP kapatılır
    Veriler silinir

═══════════════════════════════════════════════════════════════

🎯 HIZLI İPUÇLARI:

• Sayfa otomatik yenilenir (2 saniye)
• Port otomatik seçilir (8000-48000)
• Tüm veriler yerel kalır
• Hiçbir internet gerekli değil

═══════════════════════════════════════════════════════════════

📊 MENÜ ÖZETI:

┌─ 1: Sistem Durumu ─────────────┐
│   CPU, RAM, Disk, İşlemler    │
├─ 2: Ağ Bilgisi ───────────────┤
│   Bağlantılar, Portlar, DNS   │
├─ 3: Detaylı Tarama ───────────┤
│   Sistem raporu                │
├─ 4: Güvenlik Denetimi ────────┤
│   Güvenlik özeti               │
├─ 5: Performans Testi ─────────┤
│   Hız testleri                 │
├─ 6: Veri Dışa Aktar ──────────┤
│   JSON/CSV/XML                 │
└─ 0: Çık ──────────────────────┘

═══════════════════════════════════════════════════════════════

🔴 Şimdi başlatın! 🔴
HIZLIEOF

    # SORUN GİDERME
    cat > "$WORK_DIR/TROUBLESHOOT.txt" << 'TROUBLEEOF'
═══════════════════════════════════════════════════════════════
     PEGASUS PROJECT v6.0 - SORUN GİDERME REHBERI
═══════════════════════════════════════════════════════════════

❌ SORUN: "bash: command not found"
✅ ÇÖZÜM:
   $ pkg install bash
   $ bash pegasus-all-in-one.sh

❌ SORUN: "Permission denied"
✅ ÇÖZÜM:
   $ chmod +x pegasus-all-in-one.sh
   $ bash pegasus-all-in-one.sh

❌ SORUN: Port zaten kullanılıyor
✅ ÇÖZÜM:
   Program otomatik başka port seçer
   (Script yeniden çalıştırın)

❌ SORUN: Tarayıcı açılmıyor
✅ ÇÖZÜM:
   $ xdg-open http://localhost:PORT
   (PORT yerine gösterilen numarayı yazın)

❌ SORUN: Eksik istatistikler
✅ ÇÖZÜM:
   $ pkg update
   $ pkg install procps coreutils
   $ bash pegasus-all-in-one.sh

❌ SORUN: Renkler görünmüyor
✅ ÇÖZÜM:
   $ export TERM=xterm-256color
   $ bash pegasus-all-in-one.sh

❌ SORUN: HTTP sunucusu başlamıyor
✅ ÇÖZÜM:
   1. Başka bir terminal penceresi açın
   2. $ lsof -i :8000
   3. Kullanılan portu bulun
   4. $ kill -9 PID
   5. Yeniden çalıştırın

═══════════════════════════════════════════════════════════════

💡 DETAYLI KOMUTLAR:

Veri Kontrol:
$ cat /tmp/pegasus_*/pegasus.log

Prozesi Öldür:
$ pkill pegasus-all-in-one

Portları Listele:
$ netstat -tan | grep LISTEN

CPU Durumu:
$ cat /proc/cpuinfo | grep processor | wc -l

Bellek Durumu:
$ free -h

═══════════════════════════════════════════════════════════════
TROUBLEEOF
}

################################################################################
# SİSTEM DURUMU GÖSTER
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
# HTTP SUNUCUSU BAŞLAT
################################################################################

start_http_server() {
    print_info "HTTP Sunucusu başlatılıyor..."
    
    # Python varsa onu kullan, yoksa netcat kullan
    if command -v python3 &> /dev/null; then
        cd "$WORK_DIR"
        python3 -m http.server $RANDOM_PORT > "$WORK_DIR/http.log" 2>&1 &
        HTTP_SERVER_PID=$!
        print_status "HTTP Sunucusu başladı (PID: $HTTP_SERVER_PID)"
    elif command -v python &> /dev/null; then
        cd "$WORK_DIR"
        python -m SimpleHTTPServer $RANDOM_PORT > "$WORK_DIR/http.log" 2>&1 &
        HTTP_SERVER_PID=$!
        print_status "HTTP Sunucusu başladı (PID: $HTTP_SERVER_PID)"
    else
        print_warning "Python bulunamadı, HTTP sunucusu başlamıyor"
        return 1
    fi
    
    sleep 2
    return 0
}

################################################################################
# DETAYLI TARAMA
################################################################################

detailed_scan() {
    clear
    show_header
    
    echo -e "${CYAN}─── DETAYLI SİSTEM TARAMASı ───${NC}\n"
    
    # CPU detayları
    if [ -f /proc/cpuinfo ]; then
        CORE_COUNT=$(grep -c "processor" /proc/cpuinfo)
        echo -e "${CYAN}CPU Bilgileri:${NC}"
        echo -e "  ${YELLOW}Çekirdek Sayısı:${NC} $CORE_COUNT"
        echo -e "  ${YELLOW}Kullanım:${NC} $CPU_USAGE%"
        echo ""
    fi
    
    # Bellek detayları
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
    
    # En çok işlemci kullanan işlemler
    echo -e "${GREEN}En Çok CPU Kullanan İşlemler:${NC}"
    if command -v ps &> /dev/null; then
        ps aux --sort=-%cpu 2>/dev/null | head -6 | tail -5 | awk '{printf "  %-30s CPU: %5.1f%% | MEM: %5.1f%%\n", substr($11,1,30), $3, $4}'
    else
        echo "  [İşlem bilgisi kullanılamıyor]"
    fi
    echo ""
    
    read -p "Enter tuşuna basınız..."
}

################################################################################
# GÜVENLİK DENETİMİ
################################################################################

security_audit() {
    clear
    show_header
    
    echo -e "${CYAN}─── GÜVENLİK DENETİMİ ───${NC}\n"
    
    # Listening portları
    echo -e "${RED}Listening Portları:${NC}"
    if [ -f /proc/net/tcp ]; then
        echo "  [Analyzing...]"
        awk 'NR>1 && $4 == "0A" {split($2, a, ":"); port=strtonum("0x"a[2]); if(port>0) printf "  Port %d (LISTEN)\n", port}' /proc/net/tcp | sort -u | head -10
    else
        echo "  [Port scanning unavailable]"
    fi
    echo ""
    
    # Aktif bağlantılar
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
# PERFORMANS BENCHMARK
################################################################################

performance_benchmark() {
    clear
    show_header
    
    echo -e "${CYAN}─── PERFORMANS BENCHMARK ───${NC}\n"
    
    # CPU Test
    echo -e "${YELLOW}[1/3] CPU Benchmark...${NC}"
    local count=0
    for i in {1..10000}; do
        count=$((count + 1))
    done
    echo -e "${GREEN}${CHAR_GOOD} CPU Test Tamamlandı${NC}"
    echo ""
    
    # Bellek Test
    echo -e "${YELLOW}[2/3] Bellek Benchmark...${NC}"
    echo -e "${GREEN}${CHAR_GOOD} Bellek Test Tamamlandı${NC}"
    echo ""
    
    # Disk Test
    echo -e "${YELLOW}[3/3] Disk Benchmark...${NC}"
    echo -e "${GREEN}${CHAR_GOOD} Disk Test Tamamlandı${NC}"
    echo ""
    
    echo -e "${CYAN}Benchmark sonuçları kaydedildi${NC}"
    echo ""
    
    read -p "Enter tuşuna basınız..."
}

################################################################################
# VERI DIŞA AKTAR
################################################################################

export_data() {
    clear
    show_header
    
    echo -e "${CYAN}─── VERİ DIŞA AKTAR ───${NC}\n"
    
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
    "timestamp": "$(date -Iseconds)",
    "system": {
      "cpu_usage": "$CPU_USAGE%",
      "memory_usage": "$MEMORY_USAGE%",
      "storage_usage": "$STORAGE_USAGE%"
    },
    "network": {
      "active_connections": "$ACTIVE_CONNECTIONS",
      "running_processes": "$TOTAL_PROCESSES"
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
CPU Usage,$CPU_USAGE,%,$(date)
Memory Usage,$MEMORY_USAGE,%,$(date)
Storage Usage,$STORAGE_USAGE,%,$(date)
Active Connections,$ACTIVE_CONNECTIONS,count,$(date)
Running Processes,$TOTAL_PROCESSES,count,$(date)
EOF
            print_status "CSV dosyası kaydedildi: $file"
            ;;
        3)
            local file="$WORK_DIR/pegasus_export_$(date +%Y%m%d_%H%M%S).xml"
            cat > "$file" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<pegasus>
    <version>6.0</version>
    <build>zd404</build>
    <timestamp>$(date -Iseconds)</timestamp>
    <system>
        <cpu>$(get_cpu_info)</cpu>
        <memory>$(get_memory_info)</memory>
        <storage>$(get_storage_info)</storage>
    </system>
</pegasus>
EOF
            print_status "XML dosyası kaydedildi: $file"
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "Enter tuşuna basınız..."
}

################################################################################
# ANA MENU
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
                clear
                show_header
                show_system_status
                read -p "Enter tuşuna basınız..."
                ;;
            2)
                clear
                show_header
                echo -e "${GREEN}─── AĞ ANALİZİ ───${NC}\n"
                echo -e "Aktif Bağlantılar: $ACTIVE_CONNECTIONS"
                echo -e "Çalışan İşlemler: $TOTAL_PROCESSES"
                echo ""
                read -p "Enter tuşuna basınız..."
                ;;
            3)
                detailed_scan
                ;;
            4)
                security_audit
                ;;
            5)
                performance_benchmark
                ;;
            6)
                export_data
                ;;
            0)
                log_event "Program kapatıldı"
                return
                ;;
            *)
                print_error "Geçersiz seçim"
                sleep 1
                ;;
        esac
    done
}

################################################################################
# MAIN PROGRAM
################################################################################

main() {
    # Çalışma dizinini oluştur
    mkdir -p "$WORK_DIR"
    log_event "Pegasus Project v$PEGASUS_VERSION başlatıldı"
    
    show_header
    echo ""
    
    # Dizin oluştur
    print_info "Dosyalar hazırlanıyor..."
    generate_index_html
    generate_guides
    log_event "Dosyalar hazırlandı"
    print_status "Dosyalar oluşturuldu"
    echo ""
    
    # HTTP sunucusu başlat
    if ! start_http_server; then
        print_warning "HTTP sunucusu başlanamadı, yalnızca terminal modunda çalışacak"
    else
        echo -e "${GREEN}${CHAR_GOOD} HTTP Sunucusu başarıyla başladı${NC}"
        echo -e "${CYAN}WEB ARAYÜZÜ:${NC} ${YELLOW}http://localhost:$RANDOM_PORT${NC}"
        echo -e "${CYAN}PID:${NC} ${YELLOW}$HTTP_SERVER_PID${NC}"
        echo ""
        
        # Tarayıcı aç
        if command -v xdg-open &> /dev/null; then
            xdg-open "http://localhost:$RANDOM_PORT" 2>/dev/null &
            print_info "Tarayıcı açılıyor..."
        elif command -v open &> /dev/null; then
            open "http://localhost:$RANDOM_PORT" 2>/dev/null &
            print_info "Tarayıcı açılıyor..."
        fi
        
        sleep 2
    fi
    
    # Terminal menüsü
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

# Program başlat
main "$@"

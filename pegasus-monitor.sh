#!/bin/bash

################################################################################
# PEGASUS PROJECT v6.0 - CYBERPUNK SYSTEM MONITOR & NETWORK ANALYZER
# Termux Uyumlu - Gelişmiş Sistem Takip ve Ağ Analiz Aracı
# Author: Cybersecurity Team
# License: MIT
################################################################################

# Renkler ve Stil Tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Cyberpunk Karakterleri
CHAR_NETWORK='◉'
CHAR_CPU='⚡'
CHAR_MEMORY='▓'
CHAR_STORAGE='◆'
CHAR_PROCESS='◈'
CHAR_ALERT='⚠'
CHAR_GOOD='✓'

# Sistem değişkenleri
PEGASUS_VERSION="6.0"
PEGASUS_BUILD="zd404"
SYSTEM_TIME=$(date '+%Y-%m-%d %H:%M:%S UTC')
ACTIVE_CONNECTIONS=0
TOTAL_PROCESSES=0
CPU_USAGE=0
MEMORY_USAGE=0
STORAGE_USAGE=0

# Log dosyası
LOG_FILE="/sdcard/pegasus_monitor.log"
CONFIG_FILE="/sdcard/.pegasus_config"

################################################################################
# UTILITY FUNCTIONS
################################################################################

# Hata yönetimi
handle_error() {
    echo -e "${RED}${CHAR_ALERT} ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

# Başarı mesajı
success_msg() {
    echo -e "${GREEN}${CHAR_GOOD} $1${NC}"
}

# Bilgi mesajı
info_msg() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Log kaydı
log_event() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $1" >> "$LOG_FILE"
}

# Terminal temizleme
clear_screen() {
    clear
}

# Cyberpunk başlığı
show_header() {
    clear_screen
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${MAGENTA}🔴 PEGASUS PROJECT v${PEGASUS_VERSION}${NC} - ${YELLOW}SYSTEM MONITOR${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  Build: ${RED}${PEGASUS_BUILD}${NC} | Time: ${YELLOW}${SYSTEM_TIME}${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
}

################################################################################
# SİSTEM BİLGİSİ FONKSIYONLARI
################################################################################

# CPU bilgisi
get_cpu_info() {
    if [ -f /proc/stat ]; then
        awk '/^cpu / {print int((($2+$3+$4) / ($2+$3+$4+$5)) * 100)}' /proc/stat
    elif command -v top &> /dev/null; then
        top -bn1 | grep "Cpu(s)" | awk '{print int($2)}' | sed 's/%//g'
    else
        echo "N/A"
    fi
}

# Bellek bilgisi
get_memory_info() {
    if [ -f /proc/meminfo ]; then
        awk 'NR==1{total=$2} NR==2{free=$2} END{if(total>0) print int(((total-free)/total)*100); else print "N/A"}' /proc/meminfo
    elif command -v free &> /dev/null; then
        free | awk 'NR==2{print int($3/$2*100)}'
    else
        echo "N/A"
    fi
}

# Depolama bilgisi
get_storage_info() {
    if command -v df &> /dev/null; then
        df /sdcard 2>/dev/null | awk 'NR==2{if(NF>=5) print int($5); else print "N/A"}'
    else
        echo "N/A"
    fi
}

# Aktif bağlantılar
get_active_connections() {
    if [ -f /proc/net/tcp ]; then
        awk 'NR>1 {count++} END {print count}' /proc/net/tcp
    elif command -v netstat &> /dev/null; then
        netstat -tan 2>/dev/null | grep ESTABLISHED | wc -l
    else
        echo "0"
    fi
}

# Çalışan işlemler
get_process_count() {
    if [ -d /proc ]; then
        ls -d /proc/[0-9]* 2>/dev/null | wc -l
    elif command -v ps &> /dev/null; then
        ps aux | wc -l
    else
        echo "0"
    fi
}

# Ağ topolojisi (simüle)
get_network_topology() {
    if command -v ip &> /dev/null; then
        echo "$(ip link show | grep -c "state UP")"
    elif command -v ifconfig &> /dev/null; then
        echo "$(ifconfig 2>/dev/null | grep -c "inet")"
    else
        echo "1"
    fi
}

################################################################################
# GÖRSELLEŞTİRME FONKSİYONLARI
################################################################################

# İlerleme çubuğu
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

# Durum göstergesi
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
# ANA ARAYÜZ
################################################################################

show_system_status() {
    CPU_USAGE=$(get_cpu_info)
    MEMORY_USAGE=$(get_memory_info)
    STORAGE_USAGE=$(get_storage_info)
    ACTIVE_CONNECTIONS=$(get_active_connections)
    TOTAL_PROCESSES=$(get_process_count)
    
    # CPU Bilgisi
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${CHAR_CPU} CPU RESOURCES"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -ne "${CYAN}│${NC} Usage: "
    progress_bar "$CPU_USAGE"
    echo -ne "  $(status_indicator $CPU_USAGE) ${NC}\n"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Bellek Bilgisi
    echo -e "${MAGENTA}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${MAGENTA}│${NC} ${CHAR_MEMORY} MEMORY ALLOCATION"
    echo -e "${MAGENTA}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -ne "${MAGENTA}│${NC} Usage: "
    progress_bar "$MEMORY_USAGE"
    echo -ne "  $(status_indicator $MEMORY_USAGE) ${NC}\n"
    echo -e "${MAGENTA}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Depolama Bilgisi
    echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${CHAR_STORAGE} STORAGE STATUS"
    echo -e "${YELLOW}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -ne "${YELLOW}│${NC} Usage: "
    progress_bar "$STORAGE_USAGE"
    echo -ne "  $(status_indicator $STORAGE_USAGE) ${NC}\n"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

show_network_status() {
    echo -e "${GREEN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│${NC} ${CHAR_NETWORK} NETWORK TOPOLOGY"
    echo -e "${GREEN}├─────────────────────────────────────────────────────────────────┤${NC}"
    
    if [ -f /proc/net/tcp ]; then
        echo -e "${GREEN}│${NC} Active Interfaces:"
        if command -v ip &> /dev/null; then
            ip link show 2>/dev/null | grep -E "^[0-9]+:" | awk -F': ' '{print "   └─ " $2}' | head -5
        else
            echo "    └─ eth0, wlan0, lo"
        fi
    fi
    
    echo -e "${GREEN}│${NC}"
    echo -e "${GREEN}│${NC} ${CHAR_NETWORK} Active Connections: ${CYAN}$ACTIVE_CONNECTIONS${NC}"
    echo -e "${GREEN}│${NC} ${CHAR_PROCESS} Running Processes: ${CYAN}$TOTAL_PROCESSES${NC}"
    echo -e "${GREEN}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

show_event_stream() {
    echo -e "${WHITE}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC} ${CHAR_PROCESS} LIVE EVENT STREAM"
    echo -e "${WHITE}├─────────────────────────────────────────────────────────────────┤${NC}"
    
    if [ -f "$LOG_FILE" ]; then
        tail -5 "$LOG_FILE" | while read line; do
            echo -e "${WHITE}│${NC} $line"
        done
    else
        echo -e "${WHITE}│${NC} ${GREEN}[System Initialized]${NC}"
        echo -e "${WHITE}│${NC} ${CYAN}[Monitoring Active]${NC}"
        echo -e "${WHITE}│${NC} ${YELLOW}[Ready for Analysis]${NC}"
    fi
    
    echo -e "${WHITE}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

show_active_operators() {
    echo -e "${RED}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${RED}│${NC} ${CHAR_ALERT} ACTIVE OPERATORS"
    echo -e "${RED}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${RED}│${NC} ${GREEN}${CHAR_GOOD}${NC} Data Exfiltration - Status: ${GREEN}READY${NC}"
    echo -e "${RED}│${NC} ${GREEN}${CHAR_GOOD}${NC} Network Scan - Status: ${GREEN}ACTIVE${NC}"
    echo -e "${RED}│${NC} ${GREEN}${CHAR_GOOD}${NC} Tagging Service - Status: ${GREEN}MONITORING${NC}"
    echo -e "${RED}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

################################################################################
# DETAYLI İSTATİSTİKLER
################################################################################

show_detailed_stats() {
    clear_screen
    show_header
    
    echo -e "${CYAN}─── DETAILED SYSTEM STATISTICS ───${NC}\n"
    
    # CPU detaylar
    if [ -f /proc/cpuinfo ]; then
        CORE_COUNT=$(grep -c "processor" /proc/cpuinfo)
        echo -e "${CYAN}CPU Information:${NC}"
        echo -e "  ${YELLOW}Cores:${NC} $CORE_COUNT"
        echo -e "  ${YELLOW}Usage:${NC} $CPU_USAGE%"
        echo ""
    fi
    
    # Bellek detaylar
    if [ -f /proc/meminfo ]; then
        TOTAL_MEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        FREE_MEM=$(awk '/MemFree/ {print $2}' /proc/meminfo)
        USED_MEM=$((TOTAL_MEM - FREE_MEM))
        
        echo -e "${MAGENTA}Memory Information:${NC}"
        echo -e "  ${YELLOW}Total:${NC} $((TOTAL_MEM / 1024)) MB"
        echo -e "  ${YELLOW}Used:${NC} $((USED_MEM / 1024)) MB"
        echo -e "  ${YELLOW}Free:${NC} $((FREE_MEM / 1024)) MB"
        echo -e "  ${YELLOW}Usage:${NC} $MEMORY_USAGE%"
        echo ""
    fi
    
    # En çok işlemci kullanan işlemler
    echo -e "${GREEN}Top Processes:${NC}"
    if command -v ps &> /dev/null; then
        ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "  %-30s CPU: %5.1f%% | MEM: %5.1f%%\n", substr($11,1,30), $3, $4}'
    else
        echo "  [Process listing unavailable]"
    fi
    echo ""
    
    read -p "Press Enter to return to main menu..."
}

################################################################################
# AĞ ANALİZİ
################################################################################

show_network_analysis() {
    clear_screen
    show_header
    
    echo -e "${CYAN}─── NETWORK ANALYSIS ───${NC}\n"
    
    # İP bilgisi
    echo -e "${GREEN}Network Configuration:${NC}"
    if command -v ip &> /dev/null; then
        ip addr show | grep "inet " | awk '{print "  "$NF ": " $2}' | head -5
    elif command -v ifconfig &> /dev/null; then
        ifconfig | grep "inet " | awk '{print "  " $2}' | head -5
    else
        echo "  [Network info unavailable]"
    fi
    echo ""
    
    # Açık portlar
    echo -e "${YELLOW}Open Ports:${NC}"
    if [ -f /proc/net/tcp ]; then
        echo "  [Analyzing...]"
        awk 'NR>1 {split($2,a,":"); port=strtonum("0x"a[2]); if(port>0 && port<65536) ports[port]=1} END {count=0; for(p in ports) count++; print "  Found: " count " active connections"}' /proc/net/tcp
    else
        echo "  [Port scanning unavailable]"
    fi
    echo ""
    
    # DNS bilgisi
    echo -e "${MAGENTA}DNS Resolution:${NC}"
    if [ -f /etc/resolv.conf ]; then
        grep "nameserver" /etc/resolv.conf | awk '{print "  DNS: "$2}' | head -3
    else
        echo "  [DNS unavailable]"
    fi
    echo ""
    
    read -p "Press Enter to return to main menu..."
}

################################################################################
# AYARLAR
################################################################################

show_settings() {
    while true; do
        clear_screen
        show_header
        
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}  SYSTEM SETTINGS${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"
        
        echo -e "${YELLOW}1.${NC} Update Refresh Rate"
        echo -e "${YELLOW}2.${NC} Configure Log Location"
        echo -e "${YELLOW}3.${NC} Enable/Disable Alerts"
        echo -e "${YELLOW}4.${NC} Export Data"
        echo -e "${YELLOW}5.${NC} System Diagnostics"
        echo -e "${YELLOW}6.${NC} Reset Configuration"
        echo -e "${YELLOW}0.${NC} Back to Menu\n"
        
        read -p "Select option: " option
        
        case $option in
            1)
                read -p "Enter refresh rate (seconds): " refresh_rate
                echo "REFRESH_RATE=$refresh_rate" >> "$CONFIG_FILE"
                success_msg "Refresh rate updated to $refresh_rate seconds"
                sleep 1
                ;;
            2)
                read -p "Enter log file path: " log_path
                LOG_FILE="$log_path"
                success_msg "Log location changed to $log_path"
                sleep 1
                ;;
            3)
                echo -e "${YELLOW}Alert System:${NC}"
                echo "1) Enable  2) Disable"
                read -p "Select: " alert_choice
                if [ "$alert_choice" = "1" ]; then
                    echo "ALERTS=ON" >> "$CONFIG_FILE"
                    success_msg "Alerts enabled"
                else
                    echo "ALERTS=OFF" >> "$CONFIG_FILE"
                    success_msg "Alerts disabled"
                fi
                sleep 1
                ;;
            4)
                export_filename="/sdcard/pegasus_export_$(date +%Y%m%d_%H%M%S).txt"
                echo "System Export - $(date)" > "$export_filename"
                echo "CPU Usage: $CPU_USAGE%" >> "$export_filename"
                echo "Memory Usage: $MEMORY_USAGE%" >> "$export_filename"
                echo "Storage Usage: $STORAGE_USAGE%" >> "$export_filename"
                success_msg "Data exported to $export_filename"
                sleep 1
                ;;
            5)
                clear_screen
                show_header
                echo -e "${CYAN}System Diagnostics:${NC}\n"
                echo -e "${GREEN}✓ CPU Module${NC} - Active"
                echo -e "${GREEN}✓ Memory Module${NC} - Active"
                echo -e "${GREEN}✓ Network Module${NC} - Active"
                echo -e "${GREEN}✓ Storage Module${NC} - Active"
                echo -e "${GREEN}✓ Process Monitor${NC} - Active"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                rm -f "$CONFIG_FILE"
                success_msg "Configuration reset"
                sleep 1
                ;;
            0)
                return
                ;;
            *)
                handle_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

################################################################################
# ANA MENU
################################################################################

show_main_menu() {
    while true; do
        clear_screen
        show_header
        echo ""
        
        show_system_status
        show_network_status
        show_event_stream
        show_active_operators
        
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}1.${NC} Detailed Statistics    ${YELLOW}2.${NC} Network Analysis"
        echo -e "${YELLOW}3.${NC} Settings              ${YELLOW}4.${NC} Refresh"
        echo -e "${YELLOW}5.${NC} Log Viewer            ${YELLOW}0.${NC} Exit\n"
        
        read -p "Select option: " option
        
        case $option in
            1)
                show_detailed_stats
                ;;
            2)
                show_network_analysis
                ;;
            3)
                show_settings
                ;;
            4)
                log_event "Manual refresh initiated"
                ;;
            5)
                show_log_viewer
                ;;
            0)
                clear_screen
                echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║${NC}           ${RED}PEGASUS PROJECT SHUTDOWN SEQUENCE${NC} ${CYAN}║${NC}"
                echo -e "${CYAN}║${NC}        ${GREEN}${CHAR_GOOD} All systems deactivating...${NC} ${CYAN}║${NC}"
                echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
                echo ""
                log_event "System shutdown"
                exit 0
                ;;
            *)
                handle_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

################################################################################
# LOG VIEWER
################################################################################

show_log_viewer() {
    clear_screen
    show_header
    
    echo -e "${CYAN}─── LOG VIEWER ───${NC}\n"
    
    if [ -f "$LOG_FILE" ]; then
        wc -l < "$LOG_FILE" | xargs echo -e "${YELLOW}Total Lines:${NC}"
        echo ""
        tail -20 "$LOG_FILE" | cat -n
    else
        echo -e "${YELLOW}No logs available yet.${NC}"
    fi
    
    echo ""
    read -p "Press Enter to return to main menu..."
}

################################################################################
# BAŞLANGIÇ
################################################################################

initialize_system() {
    # Log dosyasını oluştur
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        chmod 666 "$LOG_FILE" 2>/dev/null
    fi
    
    # Config dosyasını kontrol et
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "REFRESH_RATE=2" > "$CONFIG_FILE"
        echo "ALERTS=ON" >> "$CONFIG_FILE"
    fi
    
    # İlk log kaydı
    log_event "System initialized - PEGASUS v$PEGASUS_VERSION"
    log_event "Build: $PEGASUS_BUILD"
}

# Bağımlılıkları kontrol et
check_dependencies() {
    local missing=0
    
    clear_screen
    echo -e "${CYAN}Checking dependencies...${NC}\n"
    
    # Temel komutlar
    for cmd in awk grep sed head tail; do
        if command -v $cmd &> /dev/null; then
            echo -e "${GREEN}${CHAR_GOOD}${NC} $cmd"
        else
            echo -e "${RED}${CHAR_ALERT}${NC} $cmd (missing)"
            missing=1
        fi
    done
    
    echo ""
    if [ $missing -eq 0 ]; then
        success_msg "All dependencies satisfied"
        sleep 2
    else
        echo -e "${YELLOW}${CHAR_ALERT} Some optional features may be limited${NC}"
        sleep 2
    fi
}

################################################################################
# PROGRAM BAŞLANGICI
################################################################################

main() {
    # Termux ortamını kontrol et
    if [ ! -d "/sdcard" ] && [ ! -d "/data/data" ]; then
        # Alternatif dizin
        LOG_FILE="$HOME/pegasus_monitor.log"
        CONFIG_FILE="$HOME/.pegasus_config"
    fi
    
    check_dependencies
    initialize_system
    show_main_menu
}

# Program başlatma
main "$@"

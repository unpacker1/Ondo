#!/bin/bash

################################################################################
# PEGASUS PROJECT v6.0 - AUTOMATIC INSTALLATION SCRIPT
# Termux üzerinde otomatik kurulum ve yapılandırma
################################################################################

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logo
show_logo() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║          🔴 PEGASUS PROJECT v6.0 INSTALLER 🔴                ║"
    echo "║                                                                ║"
    echo "║          Cyberpunk System Monitor & Network Analyzer           ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

# Kontrol fonksiyonları
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[ℹ]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

# Bağımlılık kontrolü
check_dependencies() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}1. Bağımlılıkları Kontrol Ediliyor...${NC}\n"
    
    local missing=0
    local deps=("bash" "awk" "grep" "sed" "cat" "head" "tail" "wc")
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            print_status "$dep yüklü"
        else
            print_error "$dep bulunamadı"
            missing=1
        fi
    done
    
    echo ""
    
    if [ $missing -eq 1 ]; then
        print_warning "Bazı bağımlılıklar eksik, ama sistem çalışabilir"
        print_info "Şu komutu çalıştırın: apt update && apt install coreutils procps"
        echo ""
    else
        print_status "Tüm bağımlılıklar mevcut!"
    fi
    
    sleep 2
}

# Storage izni kontrolü
check_storage() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}2. Storage İzni Kontrol Ediliyor...${NC}\n"
    
    if [ -d "/sdcard" ]; then
        if [ -w "/sdcard" ]; then
            print_status "/sdcard erişilebilir ve yazılabilir"
            STORAGE_PATH="/sdcard"
        else
            print_warning "/sdcard erişilebilir fakat yazılamıyor"
            STORAGE_PATH="$HOME"
        fi
    elif [ -d "$HOME" ]; then
        print_warning "/sdcard bulunamadı, $HOME kullanılacak"
        STORAGE_PATH="$HOME"
    fi
    
    print_info "Storage yolu: $STORAGE_PATH"
    echo ""
    sleep 2
}

# Dosya kurulumu
install_files() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}3. Dosyalar Yükleniyor...${NC}\n"
    
    # Script dosyasını kontrol et
    if [ -f "./pegasus-monitor.sh" ]; then
        print_info "pegasus-monitor.sh bulundu"
        cp ./pegasus-monitor.sh "$STORAGE_PATH/pegasus-monitor.sh"
        print_status "pegasus-monitor.sh kuruldu"
    else
        print_error "pegasus-monitor.sh bulunamadı!"
        print_info "Script dosyasının aynı klasörde olduğundan emin olun"
        return 1
    fi
    
    # İzinleri ayarla
    chmod +x "$STORAGE_PATH/pegasus-monitor.sh"
    print_status "İzinler ayarlandı (755)"
    
    echo ""
}

# Yapılandırma dosyası oluştur
create_config() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}4. Yapılandırma Dosyası Oluşturuluyor...${NC}\n"
    
    CONFIG_FILE="$STORAGE_PATH/.pegasus_config"
    
    cat > "$CONFIG_FILE" << 'EOF'
# PEGASUS PROJECT v6.0 - Configuration File
REFRESH_RATE=2
ALERTS=ON
LOG_ENABLED=ON
DEBUG_MODE=OFF
ENABLE_NETWORK_SCAN=ON
ENABLE_PROCESS_MONITORING=ON
ENABLE_AUTO_EXPORT=OFF
AUTO_EXPORT_INTERVAL=3600
EOF
    
    print_status "Yapılandırma dosyası oluşturuldu"
    print_info "Konumu: $CONFIG_FILE"
    echo ""
    sleep 2
}

# Log dosyası oluştur
create_logfile() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}5. Log Dosyası Oluşturuluyor...${NC}\n"
    
    LOG_FILE="$STORAGE_PATH/pegasus_monitor.log"
    
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        chmod 666 "$LOG_FILE"
        print_status "Log dosyası oluşturuldu"
    else
        print_status "Log dosyası zaten mevcut"
    fi
    
    print_info "Konumu: $LOG_FILE"
    
    # İlk log kaydı
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - PEGASUS PROJECT v6.0 Installed" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Build: zd404" >> "$LOG_FILE"
    
    echo ""
    sleep 2
}

# Kısayol oluştur
create_shortcut() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}6. Kısayol Oluşturuluyor...${NC}\n"
    
    ALIAS_NAME="pegasus"
    
    # Bash profili
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "alias pegasus" "$HOME/.bashrc"; then
            echo "alias $ALIAS_NAME='bash $STORAGE_PATH/pegasus-monitor.sh'" >> "$HOME/.bashrc"
            print_status "Alias $HOME/.bashrc'ye eklendi"
        else
            print_status "Alias zaten mevcut"
        fi
    fi
    
    # Komut satırından çalıştırma
    print_info "Artık şu komutları kullanabilirsiniz:"
    echo "  • pegasus"
    echo "  • bash $STORAGE_PATH/pegasus-monitor.sh"
    echo ""
    sleep 2
}

# Terminal önerileri
suggest_terminal() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}7. Terminal Ayarları...${NC}\n"
    
    print_info "En iyi deneyim için önerilenen ayarlar:"
    echo ""
    echo -e "${YELLOW}Termux Settings'te:${NC}"
    echo "  1. Appearance > Font Size: Medium"
    echo "  2. Appearance > Color Scheme: Black"
    echo "  3. Appearance > Full Screen: ON"
    echo "  4. Terminal > Extra Keys Row: ON"
    echo ""
    
    read -p "Bu ayarları yapsanız mı (sonra yapabilirsiniz)? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Ayarlar menüsünü ziyaret etmeyi unutmayın!"
    fi
    
    echo ""
    sleep 1
}

# Test çalıştırma
test_run() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}8. Hızlı Test Çalıştırması...${NC}\n"
    
    print_info "Script test ediliyor..."
    
    if bash "$STORAGE_PATH/pegasus-monitor.sh" &> /dev/null &
    then
        print_status "Script başarıyla başlatıldı!"
        sleep 1
        pkill -f pegasus-monitor.sh 2>/dev/null
    else
        print_warning "Script başlatılamadı, manuel kontrol gerekebilir"
    fi
    
    echo ""
    sleep 2
}

# Özet ekranı
show_summary() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║            ✓ KURULUM BAŞARIYLA TAMAMLANDI! ✓                 ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    echo -e "${GREEN}📊 PEGASUS PROJECT v6.0 Bilgileri:${NC}\n"
    echo "  • Versiyon: 6.0"
    echo "  • Build: zd404"
    echo "  • Konumu: $STORAGE_PATH/pegasus-monitor.sh"
    echo "  • Config: $STORAGE_PATH/.pegasus_config"
    echo "  • Log: $STORAGE_PATH/pegasus_monitor.log"
    echo ""
    
    echo -e "${GREEN}🚀 Başlamak İçin:${NC}\n"
    echo "  Seçenek 1 (Alias ile):"
    echo -e "    ${CYAN}pegasus${NC}"
    echo ""
    echo "  Seçenek 2 (Direkt):"
    echo -e "    ${CYAN}bash $STORAGE_PATH/pegasus-monitor.sh${NC}"
    echo ""
    
    echo -e "${GREEN}📚 Dokümantasyon:${NC}\n"
    echo "  • PEGASUS_REHBER.md dosyasını kontrol edin"
    echo "  • Menü içinde yardım bulunmaktadır"
    echo ""
    
    echo -e "${YELLOW}⚠️  Notlar:${NC}\n"
    echo "  • Bash profili değiştirildi (.bashrc)"
    echo "  • Yeni oturumda 'pegasus' komutu çalışacak"
    echo "  • Log dosyaları otomatik kaydedilecek"
    echo ""
    
    read -p "Program başlatılsın mı? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Program başlatılıyor...${NC}\n"
        sleep 1
        bash "$STORAGE_PATH/pegasus-monitor.sh"
    else
        print_info "Daha sonra başlatmak için: pegasus"
        echo ""
    fi
}

# Hata kontrolü
error_exit() {
    echo -e "\n${RED}Kurulum başarısız oldu!${NC}"
    echo "Lütfen hataları kontrol edin ve tekrar deneyin."
    exit 1
}

################################################################################
# ANA KURULUM SÜRECI
################################################################################

main() {
    show_logo
    
    # Adımları sırayla çalıştır
    check_dependencies || error_exit
    check_storage || error_exit
    install_files || error_exit
    create_config || error_exit
    create_logfile || error_exit
    create_shortcut || error_exit
    suggest_terminal
    test_run || error_exit
    show_summary
}

# Program başlat
main "$@"

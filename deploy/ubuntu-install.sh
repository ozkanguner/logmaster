#!/bin/bash
# LogMaster - Ubuntu Sunucu Deployment Scripti
# GitHub'dan çekip kuracak

set -e

# Renkli çıktı
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Değişkenler
REPO_URL="https://github.com/KULLANICI_ADI/logmaster.git"
INSTALL_DIR="/opt/logmaster"
SERVICE_USER="logmaster"
DB_PASSWORD="LogMaster2024!"

# Root kontrolü
if [[ $EUID -eq 0 ]]; then
    log_error "Bu script root kullanıcısı ile çalıştırılmamalıdır!"
    exit 1
fi

# Ubuntu sürüm kontrolü
if ! grep -q "Ubuntu" /etc/os-release; then
    log_error "Bu script Ubuntu sistemler için tasarlanmıştır!"
    exit 1
fi

VERSION=$(lsb_release -rs)
if (( $(echo "$VERSION < 20.04" | bc -l) )); then
    log_error "Ubuntu 20.04 veya daha yeni sürüm gereklidir!"
    exit 1
fi

echo "==============================================="
echo "LogMaster - Ubuntu Deployment"
echo "5651 Kanunu Uyumlu Log Yönetim Sistemi"
echo "==============================================="
echo

# Kullanıcı onayı
read -p "Kuruluma devam etmek istiyor musunuz? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Kurulum iptal edildi"
    exit 0
fi

# Sistem güncelleme
log_info "Sistem güncelleniyor..."
sudo apt update
sudo apt upgrade -y

# Docker kurulumu
install_docker() {
    log_info "Docker kuruluyor..."
    
    # Eski Docker versiyonlarını kaldır
    sudo apt remove -y docker docker-engine docker.io containerd runc || true
    
    # Gerekli paketler
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Docker GPG anahtarı
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Docker kurulum
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # Docker Compose kurulum
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Kullanıcıyı docker grubuna ekle
    sudo usermod -aG docker $USER
    
    # Docker servisini başlat
    sudo systemctl enable docker
    sudo systemctl start docker
    
    log_success "Docker kuruldu"
}

# Git kurulumu
install_git() {
    log_info "Git kuruluyor..."
    sudo apt install -y git
    log_success "Git kuruldu"
}

# Firewall ayarları
setup_firewall() {
    log_info "Firewall ayarları yapılıyor..."
    
    sudo ufw --force enable
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 514/udp
    
    log_success "Firewall ayarlandı"
}

# Kullanıcı oluşturma
create_user() {
    log_info "LogMaster kullanıcısı oluşturuluyor..."
    
    if ! id "$SERVICE_USER" &>/dev/null; then
        sudo useradd -r -s /bin/bash -d $INSTALL_DIR -m $SERVICE_USER
        sudo usermod -aG docker $SERVICE_USER
        log_success "LogMaster kullanıcısı oluşturuldu"
    else
        log_warning "LogMaster kullanıcısı zaten mevcut"
    fi
}

# Repository klonlama
clone_repository() {
    log_info "Repository klonlanıyor..."
    
    if [ -d "$INSTALL_DIR" ]; then
        log_info "Mevcut kurulum güncelleniyor..."
        cd $INSTALL_DIR
        sudo -u $SERVICE_USER git pull
    else
        sudo git clone $REPO_URL $INSTALL_DIR
        sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR
        cd $INSTALL_DIR
    fi
    
    log_success "Repository hazırlandı"
}

# Konfigürasyon
setup_configuration() {
    log_info "Konfigürasyon ayarları..."
    
    # Ana konfigürasyon dosyası
    if [ ! -f "$INSTALL_DIR/config/main.conf" ]; then
        sudo -u $SERVICE_USER cp config/main.conf.example config/main.conf
    fi
    
    # Veritabanı şifresi güncelleme
    sudo sed -i "s/CHANGE_THIS_PASSWORD/$DB_PASSWORD/g" $INSTALL_DIR/config/main.conf
    
    # Docker Compose ortam değişkenleri
    sudo tee $INSTALL_DIR/.env > /dev/null << EOF
# LogMaster Environment Variables
DB_PASSWORD=$DB_PASSWORD
LOGMASTER_ENV=production
DOMAIN=${DOMAIN:-localhost}
SSL_EMAIL=${SSL_EMAIL:-admin@localhost}
EOF
    
    sudo chown $SERVICE_USER:$SERVICE_USER $INSTALL_DIR/.env
    sudo chmod 600 $INSTALL_DIR/.env
    
    log_success "Konfigürasyon tamamlandı"
}

# SSL sertifikaları (Let's Encrypt)
setup_ssl() {
    if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "localhost" ]; then
        log_info "SSL sertifikaları kuruluyor..."
        
        # Certbot kurulum
        sudo apt install -y certbot python3-certbot-nginx
        
        # Nginx ile sertifika al
        sudo certbot --nginx -d $DOMAIN --email $SSL_EMAIL --agree-tos --non-interactive
        
        log_success "SSL sertifikaları kuruldu"
    else
        log_warning "Domain belirtilmediği için SSL atlandı"
    fi
}

# Servis başlatma
start_services() {
    log_info "Servisler başlatılıyor..."
    
    cd $INSTALL_DIR
    
    # Docker Compose ile başlat
    sudo -u $SERVICE_USER docker-compose up -d
    
    # Servislerin başlamasını bekle
    sleep 30
    
    # Health check
    if curl -f http://localhost/health > /dev/null 2>&1; then
        log_success "Servisler başarıyla başlatıldı"
    else
        log_error "Servis başlatma hatası"
        sudo -u $SERVICE_USER docker-compose logs
        exit 1
    fi
}

# Systemd servisi oluşturma
create_systemd_service() {
    log_info "Systemd servisi oluşturuluyor..."
    
    sudo tee /etc/systemd/system/logmaster.service > /dev/null << EOF
[Unit]
Description=LogMaster - 5651 Kanunu Uyumlu Log Yönetim Sistemi
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable logmaster
    
    log_success "Systemd servisi oluşturuldu"
}

# Yedekleme scripti
create_backup_script() {
    log_info "Yedekleme scripti oluşturuluyor..."
    
    sudo tee /usr/local/bin/logmaster-backup > /dev/null << 'EOF'
#!/bin/bash
# LogMaster Yedekleme Scripti

BACKUP_DIR="/opt/logmaster-backups"
DATE=$(date +%Y%m%d_%H%M%S)
INSTALL_DIR="/opt/logmaster"

mkdir -p $BACKUP_DIR

# Veritabanı yedeği
docker-compose -f $INSTALL_DIR/docker-compose.yml exec -T postgres pg_dump -U logmaster logmaster > $BACKUP_DIR/database_$DATE.sql

# Konfigürasyon yedeği
tar -czf $BACKUP_DIR/config_$DATE.tar.gz -C $INSTALL_DIR config/

# Log dosyaları yedeği (sadece imzalı olanlar)
tar -czf $BACKUP_DIR/signed_logs_$DATE.tar.gz -C $INSTALL_DIR signed/

# Eski yedekleri temizle (30 günden eski)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Yedekleme tamamlandı: $DATE"
EOF
    
    sudo chmod +x /usr/local/bin/logmaster-backup
    
    # Günlük yedekleme için crontab
    echo "0 2 * * * /usr/local/bin/logmaster-backup" | sudo crontab -u $SERVICE_USER -
    
    log_success "Yedekleme scripti oluşturuldu"
}

# İzleme scriptleri
create_monitoring_scripts() {
    log_info "İzleme scriptleri oluşturuluyor..."
    
    # Durum kontrolü
    sudo tee /usr/local/bin/logmaster-status > /dev/null << EOF
#!/bin/bash
cd $INSTALL_DIR
echo "=== LogMaster Durum Raporu ==="
echo "Tarih: \$(date)"
echo ""
echo "Docker Servisleri:"
docker-compose ps
echo ""
echo "Sistem Kaynakları:"
docker stats --no-stream
echo ""
echo "Disk Kullanımı:"
df -h $INSTALL_DIR
echo ""
echo "Son Loglar:"
docker-compose logs --tail=20
EOF
    
    sudo chmod +x /usr/local/bin/logmaster-status
    
    # Güncelleme scripti
    sudo tee /usr/local/bin/logmaster-update > /dev/null << EOF
#!/bin/bash
cd $INSTALL_DIR

echo "LogMaster güncelleniyor..."

# Yedek al
/usr/local/bin/logmaster-backup

# Repository güncelle
sudo -u $SERVICE_USER git pull

# Docker imajlarını güncelle
sudo -u $SERVICE_USER docker-compose pull

# Servisleri yeniden başlat
sudo -u $SERVICE_USER docker-compose up -d

echo "Güncelleme tamamlandı"
EOF
    
    sudo chmod +x /usr/local/bin/logmaster-update
    
    log_success "İzleme scriptleri oluşturuldu"
}

# Ana kurulum akışı
main() {
    # Parametreleri al
    while [[ $# -gt 0 ]]; do
        case $1 in
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --email)
                SSL_EMAIL="$2"
                shift 2
                ;;
            --repo)
                REPO_URL="$2"
                shift 2
                ;;
            --password)
                DB_PASSWORD="$2"
                shift 2
                ;;
            *)
                echo "Bilinmeyen parametre: $1"
                exit 1
                ;;
        esac
    done
    
    log_info "Kurulum parametreleri:"
    echo "  Domain: ${DOMAIN:-localhost}"
    echo "  Repository: $REPO_URL"
    echo "  Install Directory: $INSTALL_DIR"
    echo ""
    
    # Kurulum adımları
    install_git
    install_docker
    setup_firewall
    create_user
    clone_repository
    setup_configuration
    start_services
    create_systemd_service
    create_backup_script
    create_monitoring_scripts
    
    # SSL kurulumu (eğer domain belirtilmişse)
    if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "localhost" ]; then
        setup_ssl
    fi
    
    log_success "=================================="
    log_success "LogMaster Kurulumu Tamamlandı!"
    log_success "=================================="
    echo
    log_info "Erişim Bilgileri:"
    echo "  Web Arayüzü: http://${DOMAIN:-localhost}"
    echo "  API Dokümantasyonu: http://${DOMAIN:-localhost}/api/docs"
    echo "  Kullanıcı Adı: admin"
    echo "  Şifre: logmaster2024"
    echo
    log_info "Yönetim Komutları:"
    echo "  Durum: logmaster-status"
    echo "  Güncelleme: logmaster-update"
    echo "  Yedekleme: logmaster-backup"
    echo "  Servis Yönetimi: sudo systemctl start/stop/restart logmaster"
    echo
    log_warning "ÖNEMLİ:"
    echo "  1. Varsayılan şifreleri değiştirin"
    echo "  2. Firewall kurallarını kontrol edin"
    echo "  3. SSL sertifikalarını yapılandırın"
    echo "  4. Yedekleme sistemini test edin"
    echo
    
    log_info "Daha fazla bilgi için: https://github.com/KULLANICI_ADI/logmaster"
}

# Script'i çalıştır
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 
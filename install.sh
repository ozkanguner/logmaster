#!/bin/bash
# LogMaster - 5651 Kanunu Uyumlu Log Yönetim Sistemi
# Ubuntu Kurulum Scripti

set -e  # Hata durumunda çıkış yap

# Renkli çıktı için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonksiyonlar
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

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Bu script root kullanıcısı ile çalıştırılmamalıdır!"
        log_info "Lütfen normal kullanıcı ile çalıştırın. Gerekli yerler için sudo kullanılacak."
        exit 1
    fi
}

check_ubuntu() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        log_error "Bu script Ubuntu sistemler için tasarlanmıştır!"
        exit 1
    fi
    
    VERSION=$(lsb_release -rs)
    if (( $(echo "$VERSION < 20.04" | bc -l) )); then
        log_error "Ubuntu 20.04 veya daha yeni sürüm gereklidir!"
        exit 1
    fi
    
    log_success "Ubuntu $VERSION tespit edildi"
}

install_system_dependencies() {
    log_info "Sistem bağımlılıkları kuruluyor..."
    
    sudo apt update
    sudo apt install -y \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        postgresql \
        postgresql-contrib \
        rsyslog \
        nginx \
        supervisor \
        git \
        curl \
        wget \
        unzip \
        gnupg2 \
        openssl \
        libssl-dev \
        libffi-dev \
        libpq-dev \
        bc \
        htop \
        tree \
        vim
    
    log_success "Sistem bağımlılıkları kuruldu"
}

create_user_and_directories() {
    log_info "LogMaster kullanıcısı ve dizinleri oluşturuluyor..."
    
    # LogMaster kullanıcısı oluştur
    if ! id "logmaster" &>/dev/null; then
        sudo useradd -r -s /bin/bash -d /opt/logmaster -m logmaster
        log_success "LogMaster kullanıcısı oluşturuldu"
    else
        log_warning "LogMaster kullanıcısı zaten mevcut"
    fi
    
    # Ana dizinleri oluştur
    sudo mkdir -p /opt/logmaster/{config,scripts,logs,signed,archived,temp,backup,certs}
    sudo mkdir -p /var/log/logmaster
    sudo mkdir -p /etc/logmaster
    
    # İzinleri ayarla
    sudo chown -R logmaster:logmaster /opt/logmaster
    sudo chown -R logmaster:logmaster /var/log/logmaster
    sudo chmod -R 750 /opt/logmaster
    sudo chmod -R 640 /opt/logmaster/config
    
    # 400 cihaz klasörü oluştur
    for i in $(seq -w 1 400); do
        sudo mkdir -p /opt/logmaster/logs/device-$i
        sudo chown logmaster:logmaster /opt/logmaster/logs/device-$i
        sudo chmod 750 /opt/logmaster/logs/device-$i
    done
    
    log_success "Kullanıcı ve dizinler oluşturuldu"
}

setup_postgresql() {
    log_info "PostgreSQL ayarları yapılıyor..."
    
    # PostgreSQL servisini başlat
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
    # Veritabanı ve kullanıcı oluştur
    sudo -u postgres psql << EOF
CREATE DATABASE logmaster;
CREATE USER logmaster WITH ENCRYPTED PASSWORD 'LogMaster2024!';
GRANT ALL PRIVILEGES ON DATABASE logmaster TO logmaster;
\q
EOF
    
    # Veritabanı şemasını oluştur
    sudo -u postgres psql logmaster < scripts/database_setup.sql
    
    log_success "PostgreSQL ayarlandı"
}

install_python_environment() {
    log_info "Python sanal ortamı kuruluyor..."
    
    # Sanal ortam oluştur
    sudo -u logmaster python3 -m venv /opt/logmaster/venv
    
    # Pip güncelle
    sudo -u logmaster /opt/logmaster/venv/bin/pip install --upgrade pip setuptools wheel
    
    # Bağımlılıkları kur
    sudo -u logmaster /opt/logmaster/venv/bin/pip install -r requirements.txt
    
    log_success "Python ortamı kuruldu"
}

configure_rsyslog() {
    log_info "Rsyslog yapılandırılıyor..."
    
    # LogMaster için rsyslog konfigürasyonu
    sudo tee /etc/rsyslog.d/50-logmaster.conf > /dev/null << 'EOF'
# LogMaster Konfigürasyonu
# UDP 514 portunu dinle
$ModLoad imudp
$UDPServerRun 514
$UDPServerAddress 0.0.0.0

# LogMaster'a yönlendir
*.* @@127.0.0.1:514

# Local logları ayrı tut
local0.* /var/log/logmaster/local.log
& stop
EOF
    
    # Rsyslog'u yeniden başlat
    sudo systemctl restart rsyslog
    sudo systemctl enable rsyslog
    
    log_success "Rsyslog yapılandırıldı"
}

setup_nginx() {
    log_info "Nginx yapılandırılıyor..."
    
    # LogMaster için nginx konfigürasyonu
    sudo tee /etc/nginx/sites-available/logmaster > /dev/null << 'EOF'
server {
    listen 80;
    server_name logmaster.local _;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout ayarları
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Static files
    location /static/ {
        alias /opt/logmaster/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Admin panel
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Log dosyalarına erişimi engelle
    location ~ /logs/ {
        deny all;
        return 404;
    }
}
EOF
    
    # Site'ı etkinleştir
    sudo ln -sf /etc/nginx/sites-available/logmaster /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Nginx'i yeniden başlat
    sudo nginx -t
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    
    log_success "Nginx yapılandırıldı"
}

setup_supervisor() {
    log_info "Supervisor yapılandırılıyor..."
    
    # LogMaster collector için supervisor konfigürasyonu
    sudo tee /etc/supervisor/conf.d/logmaster-collector.conf > /dev/null << 'EOF'
[program:logmaster-collector]
command=/opt/logmaster/venv/bin/python /opt/logmaster/scripts/log_collector.py
directory=/opt/logmaster
user=logmaster
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/logmaster/collector.log
environment=PYTHONPATH="/opt/logmaster"
EOF
    
    # Digital signer için supervisor konfigürasyonu
    sudo tee /etc/supervisor/conf.d/logmaster-signer.conf > /dev/null << 'EOF'
[program:logmaster-signer]
command=/opt/logmaster/venv/bin/python /opt/logmaster/scripts/digital_signer.py
directory=/opt/logmaster
user=logmaster
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/logmaster/signer.log
environment=PYTHONPATH="/opt/logmaster"
EOF
    
    # Supervisor'ı güncelle
    sudo supervisorctl reread
    sudo supervisorctl update
    sudo systemctl enable supervisor
    
    log_success "Supervisor yapılandırıldı"
}

copy_files() {
    log_info "Dosyalar kopyalanıyor..."
    
    # Konfigürasyon dosyalarını kopyala
    sudo cp config/* /opt/logmaster/config/ 2>/dev/null || true
    sudo cp scripts/* /opt/logmaster/scripts/ 2>/dev/null || true
    
    # İzinleri düzelt
    sudo chown -R logmaster:logmaster /opt/logmaster/config
    sudo chown -R logmaster:logmaster /opt/logmaster/scripts
    sudo chmod +x /opt/logmaster/scripts/*.py
    
    log_success "Dosyalar kopyalandı"
}

setup_firewall() {
    log_info "Güvenlik duvarı ayarları..."
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow 22/tcp    # SSH
        sudo ufw allow 80/tcp    # HTTP
        sudo ufw allow 443/tcp   # HTTPS
        sudo ufw allow 514/udp   # Syslog
        sudo ufw --force enable
        log_success "UFW güvenlik duvarı yapılandırıldı"
    else
        log_warning "UFW bulunamadı, güvenlik duvarı atlandı"
    fi
}

create_service_scripts() {
    log_info "Servis scriptleri oluşturuluyor..."
    
    # Başlatma scripti
    sudo tee /usr/local/bin/logmaster-start > /dev/null << 'EOF'
#!/bin/bash
echo "LogMaster servisleri başlatılıyor..."
sudo systemctl start postgresql
sudo systemctl start rsyslog
sudo systemctl start nginx
sudo supervisorctl start logmaster-collector
sudo supervisorctl start logmaster-signer
echo "LogMaster başlatıldı"
EOF
    
    # Durdurma scripti
    sudo tee /usr/local/bin/logmaster-stop > /dev/null << 'EOF'
#!/bin/bash
echo "LogMaster servisleri durduruluyor..."
sudo supervisorctl stop logmaster-collector
sudo supervisorctl stop logmaster-signer
echo "LogMaster durduruldu"
EOF
    
    # Durum scripti
    sudo tee /usr/local/bin/logmaster-status > /dev/null << 'EOF'
#!/bin/bash
echo "=== LogMaster Durum Raporu ==="
echo "PostgreSQL: $(systemctl is-active postgresql)"
echo "Rsyslog: $(systemctl is-active rsyslog)"
echo "Nginx: $(systemctl is-active nginx)"
echo "Collector: $(sudo supervisorctl status logmaster-collector | awk '{print $2}')"
echo "Signer: $(sudo supervisorctl status logmaster-signer | awk '{print $2}')"
echo "Disk Kullanımı: $(df -h /opt/logmaster | awk 'NR==2 {print $5}')"
echo "Toplam Log Sayısı: $(find /opt/logmaster/logs -name "*.log" | wc -l)"
EOF
    
    sudo chmod +x /usr/local/bin/logmaster-*
    
    log_success "Servis scriptleri oluşturuldu"
}

setup_cron_jobs() {
    log_info "Zamanlanmış görevler ayarlanıyor..."
    
    # LogMaster için crontab
    sudo -u logmaster crontab << 'EOF'
# LogMaster - Zamanlanmış Görevler

# Her gün saat 02:00'da arşivleme
0 2 * * * /opt/logmaster/venv/bin/python /opt/logmaster/scripts/archiver.py

# Her saatte bir dijital imzalama
0 * * * * /opt/logmaster/venv/bin/python /opt/logmaster/scripts/digital_signer.py --batch

# Her gün saat 03:00'da yedekleme
0 3 * * * /opt/logmaster/scripts/backup.sh

# Her hafta sistem durumu raporu
0 8 * * 1 /opt/logmaster/venv/bin/python /opt/logmaster/scripts/health_check.py --report

# Her ay uyumluluk raporu
0 9 1 * * /opt/logmaster/venv/bin/python /opt/logmaster/scripts/compliance_report.py
EOF
    
    log_success "Zamanlanmış görevler ayarlandı"
}

final_setup() {
    log_info "Son ayarlar yapılıyor..."
    
    # SSL sertifikaları oluştur (kendinden imzalı)
    sudo -u logmaster openssl req -x509 -newkey rsa:4096 -keyout /opt/logmaster/certs/logmaster.key -out /opt/logmaster/certs/logmaster.crt -days 3650 -nodes -subj "/C=TR/ST=Istanbul/L=Istanbul/O=LogMaster/CN=logmaster.local"
    
    # Servis başlatma
    sudo systemctl start supervisor
    sudo supervisorctl start all
    
    log_success "LogMaster kurulumu tamamlandı"
}

print_completion_info() {
    log_success "=================================="
    log_success "LogMaster Kurulumu Başarıyla Tamamlandı!"
    log_success "=================================="
    echo
    log_info "Kurulum Bilgileri:"
    echo "  • Kurulum Dizini: /opt/logmaster"
    echo "  • Log Dizini: /opt/logmaster/logs (400 cihaz klasörü)"
    echo "  • Konfigürasyon: /opt/logmaster/config/main.conf"
    echo "  • Web Arayüzü: http://$(hostname -I | awk '{print $1}')"
    echo "  • Syslog Port: 514 (UDP)"
    echo "  • Veritabanı: PostgreSQL (logmaster)"
    echo
    log_info "Yönetim Komutları:"
    echo "  • Başlat: logmaster-start"
    echo "  • Durdur: logmaster-stop"
    echo "  • Durum: logmaster-status"
    echo
    log_info "Log Dosyaları:"
    echo "  • Collector: /var/log/logmaster/collector.log"
    echo "  • Signer: /var/log/logmaster/signer.log"
    echo "  • System: /var/log/logmaster/"
    echo
    log_warning "ÖNEMLİ GÜVENLİK UYARILARI:"
    echo "  1. /opt/logmaster/config/main.conf dosyasındaki varsayılan şifreleri değiştirin"
    echo "  2. Firewall kurallarını ihtiyacınıza göre ayarlayın"
    echo "  3. SSL sertifikalarını güvenilir CA ile değiştirin"
    echo "  4. Düzenli yedekleme sistemini kurun"
    echo "  5. İzleme ve uyarı sistemlerini test edin"
    echo
    log_info "5651 Kanunu Uyumluluğu:"
    echo "  • Loglar 2 yıl boyunca saklanır"
    echo "  • Tüm dosyalar dijital olarak imzalanır"
    echo "  • RFC 3161 uyumlu zaman damgası eklenir"
    echo "  • Erişim logları tutulur"
    echo "  • Uyumluluk raporları otomatik oluşturulur"
}

# Ana kurulum akışı
main() {
    echo "LogMaster - 5651 Kanunu Uyumlu Log Yönetim Sistemi"
    echo "Ubuntu Kurulum Scripti"
    echo "======================================================"
    echo
    
    check_root
    check_ubuntu
    
    read -p "Kuruluma devam etmek istiyor musunuz? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Kurulum iptal edildi"
        exit 0
    fi
    
    install_system_dependencies
    create_user_and_directories
    setup_postgresql
    install_python_environment
    copy_files
    configure_rsyslog
    setup_nginx
    setup_supervisor
    setup_firewall
    create_service_scripts
    setup_cron_jobs
    final_setup
    print_completion_info
}

# Script'i çalıştır
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 
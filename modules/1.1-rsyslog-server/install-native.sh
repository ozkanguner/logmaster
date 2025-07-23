#!/bin/bash
set -e

echo "🚀 LogMaster Module 1.1: Native RSyslog Installation"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Bu script root olarak çalıştırılmalı!" 
   exit 1
fi

print_step "RSyslog kurulumu..."
apt update
apt install -y rsyslog rsyslog-gnutls openssl netcat-openbsd curl

print_step "Log dizinleri oluşturuluyor..."
mkdir -p /var/log/rsyslog /etc/ssl/rsyslog
chmod 755 /var/log/rsyslog
chown syslog:adm /var/log/rsyslog

print_step "RSyslog konfigürasyonu..."

# UDP input config
cat > /etc/rsyslog.d/10-udp.conf << 'EOF'
# UDP Syslog reception
module(load="imudp")
input(type="imudp" port="514")
EOF

# TCP input config  
cat > /etc/rsyslog.d/11-tcp.conf << 'EOF'
# TCP Syslog reception
module(load="imtcp")
input(type="imtcp" port="514")
EOF

# Log output config
cat > /etc/rsyslog.d/50-logmaster.conf << 'EOF'
# LogMaster 5651 compliance
*.* /var/log/rsyslog/messages
EOF

print_step "SSL sertifikaları oluşturuluyor..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/rsyslog/server-key.pem \
    -out /etc/ssl/rsyslog/server-cert.pem \
    -subj "/C=TR/ST=Istanbul/L=Istanbul/O=LogMaster/CN=rsyslog"

chmod 600 /etc/ssl/rsyslog/server-key.pem
chmod 644 /etc/ssl/rsyslog/server-cert.pem

print_step "Firewall ayarları..."
if command -v ufw &> /dev/null; then
    ufw allow 514/udp
    ufw allow 514/tcp  
    ufw allow 6514/tcp
    print_success "UFW firewall kuralları eklendi"
fi

print_step "RSyslog servisi başlatılıyor..."
systemctl restart rsyslog
systemctl enable rsyslog

# Test configuration
print_step "Konfigürasyon test ediliyor..."
rsyslogd -N1

print_step "Port kontrolü..."
sleep 2
netstat -ulnp | grep 514

print_success "Native RSyslog kurulumu tamamlandı!"

echo ""
echo "📋 Yönetim komutları:"
echo "   systemctl status rsyslog    # Durum kontrol"
echo "   systemctl restart rsyslog   # Restart"
echo "   tail -f /var/log/rsyslog/messages  # Log takip"
echo "   echo 'test' | nc -u localhost 514  # Test mesaj"
echo ""
echo "📊 Test komutu:"
echo "   ./test-native.sh" 
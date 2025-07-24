#!/bin/bash
set -e

echo "🔧 LogMaster: Basit RSyslog Kurulumu (Tek Dosya)"
echo "==============================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[ADIM]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[BAŞARILI]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Bu script root olarak çalıştırılmalı!" 
   echo "Kullanım: sudo ./basic-install.sh"
   exit 1
fi

print_step "1. Sistem güncellemesi ve RSyslog kurulumu..."

# Update system and install RSyslog
apt update
apt install -y rsyslog rsyslog-gnutls net-tools curl wget netcat-openbsd tree

print_step "2. Basit RSyslog konfigürasyonu oluşturuluyor..."

# Create log directory
mkdir -p /var/log/rsyslog
chown syslog:adm /var/log/rsyslog
chmod 755 /var/log/rsyslog

# Simple RSyslog configuration - everything goes to one file
cat > /etc/rsyslog.d/10-logmaster-basic.conf << 'EOF'
# LogMaster Basic Configuration - All logs in one file

# Load UDP module
module(load="imudp")
input(type="imudp" port="514")

# Load TCP module  
module(load="imtcp")
input(type="imtcp" port="514")

# All incoming logs go to one file
*.* /var/log/rsyslog/all-messages.log

# Stop processing (don't send to other files)
& stop
EOF

print_step "3. Eski log konfigürasyonlarını devre dışı bırakıyor..."

# Disable default rsyslog rules that might interfere
sed -i 's/^\*\.\*/#&/' /etc/rsyslog.conf

print_step "4. RSyslog konfigürasyonu test ediliyor..."

# Test configuration
if rsyslogd -N1; then
    print_success "RSyslog konfigürasyonu geçerli!"
else
    echo "[HATA] RSyslog konfigürasyonunda sorun var!"
    exit 1
fi

print_step "5. RSyslog servisini başlatıyor..."

# Restart RSyslog
systemctl restart rsyslog
sleep 2

if systemctl is-active --quiet rsyslog; then
    print_success "RSyslog servisi başarıyla başlatıldı!"
else
    echo "[HATA] RSyslog servisi başlatılamadı!"
    systemctl status rsyslog
    exit 1
fi

print_step "6. Test mesajları gönderiliyor..."

# Send test messages
echo "$(date '+%b %d %H:%M:%S') TEST-SERVER Test message 1 - UDP" | nc -u localhost 514
echo "$(date '+%b %d %H:%M:%S') TEST-SERVER Test message 2 - UDP" | nc -u localhost 514

sleep 2

print_step "7. Kurulum sonuçları kontrol ediliyor..."

echo ""
print_success "🎉 Basit RSyslog Kurulumu Tamamlandı!"

echo ""
echo "📊 Sistem Durumu:"
echo "================="
echo "RSyslog servisi: $(systemctl is-active rsyslog)"
echo "UDP Port 514: $(netstat -ulnp 2>/dev/null | grep -q ':514' && echo 'Dinliyor' || echo 'Dinlemiyor')"
echo "TCP Port 514: $(netstat -tlnp 2>/dev/null | grep -q ':514' && echo 'Dinliyor' || echo 'Dinlemiyor')"

echo ""
echo "📁 Log Dosyası:"
echo "==============="
echo "Ana log dosyası: /var/log/rsyslog/all-messages.log"

if [[ -f /var/log/rsyslog/all-messages.log ]]; then
    LOG_SIZE=$(wc -l < /var/log/rsyslog/all-messages.log)
    echo "Mevcut satır sayısı: $LOG_SIZE"
    
    if [[ $LOG_SIZE -gt 0 ]]; then
        echo ""
        echo "Son 5 log girişi:"
        echo "=================="
        tail -5 /var/log/rsyslog/all-messages.log
    fi
else
    echo "Log dosyası henüz oluşturulmadı"
fi

echo ""
echo "🔧 Test ve İzleme Komutları:"
echo "============================"
echo "# Canlı log izleme:"
echo "tail -f /var/log/rsyslog/all-messages.log"
echo ""
echo "# Test mesajı gönderme:"
echo "echo \"\$(date '+%b %d %H:%M:%S') HOSTNAME test message\" | nc -u localhost 514"
echo ""
echo "# Servis durumu:"
echo "sudo systemctl status rsyslog"
echo ""
echo "# Port kontrolü:"
echo "sudo netstat -tulpn | grep 514"
echo ""
echo "# Log dosyası istatistikleri:"
echo "wc -l /var/log/rsyslog/all-messages.log"

echo ""
print_success "Kurulum tamamlandı! Şimdi Mikrotik cihazlarınızı bu sunucuya log gönderecek şekilde ayarlayın."

echo ""
echo "📋 Mikrotik Konfigürasyon Örneği:"
echo "================================="
echo "# Mikrotik router'da çalıştırın:"
echo "/system logging action"
echo "add name=remote-server target=remote remote=SUNUCU_IP_ADRESI remote-port=514"
echo ""
echo "/system logging"
echo "add topics=firewall action=remote-server"
echo "add topics=hotspot action=remote-server" 
echo "add topics=dhcp action=remote-server"

echo ""
echo "⚠️  SUNUCU_IP_ADRESI yerine bu sunucunun IP adresini yazın!"
echo ""
print_success "Loglar gelmeye başladıktan sonra, çok kiracılı yapıyı kuracağız!" 
#!/bin/bash
set -e

echo "🚀 LogMaster: Tek Komut Sıfırdan RSyslog Multi-Tenant Kurulumu"
echo "=============================================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
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
   echo "Kullanım: curl -fsSL https://raw.githubusercontent.com/ozkanguner/logmaster/main/modules/1.1-rsyslog-server/quick-install.sh | sudo bash"
   exit 1
fi

print_step "1. Sistem güncellemesi ve gerekli paketler kuruluyor..."

# Update system and install requirements
apt update && apt upgrade -y
apt install -y rsyslog rsyslog-gnutls git tree net-tools curl wget netcat-openbsd

print_step "2. Repository clone ediliyor..."

# Clone repository to /opt for system-wide access
cd /opt
rm -rf logmaster 2>/dev/null || true
git clone https://github.com/ozkanguner/logmaster.git
cd logmaster/modules/1.1-rsyslog-server

print_step "3. Native RSyslog kuruluyor..."

# Configure RSyslog with basic settings
mkdir -p /var/log/rsyslog /etc/ssl/rsyslog

# Basic RSyslog configuration
cat > /etc/rsyslog.d/10-logmaster.conf << 'EOF'
# LogMaster Basic Configuration
module(load="imudp")
input(type="imudp" port="514")

module(load="imtcp") 
input(type="imtcp" port="514")

# Enable high performance settings
$WorkDirectory /var/spool/rsyslog
$ActionQueueFileName queue
$ActionQueueMaxDiskSpace 100m
$ActionQueueSaveOnShutdown on
$ActionQueueType LinkedList
$ActionResumeRetryCount -1
EOF

print_step "4. Universal Multi-Tenant yapısı kuruluyor..."

# Create universal multi-tenant directory structure
mkdir -p /var/log/rsyslog/unknown/unknown
chown -R syslog:adm /var/log/rsyslog/
chmod -R 755 /var/log/rsyslog/

# Universal Multi-Tenant RSyslog Configuration
cat > /etc/rsyslog.d/70-universal-multitenant.conf << 'EOF'
# LogMaster Universal Multi-Tenant Configuration
# Supports ANY zone automatically: ZONE/HOTEL/YYYY-MM-DD.log

# Universal templates - works with any zone name
template(name="UniversalHotelLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/%msg:R,ERE,1,FIELD:in:([A-Z0-9_]+)\s+out --end%/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="UniversalDHCPLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/dhcp/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="UniversalZoneLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/general/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="UnknownLogPath" type="string" string="/var/log/rsyslog/unknown/unknown/%$YEAR%-%$MONTH%-%$DAY%.log")

# Rule 1: SRCNAT messages with hotel names (Zone/Hotel structure)
if $msg contains "srcnat:" and $msg contains "in:" and $msg contains "out:" then {
    action(type="omfile" dynaFile="UniversalHotelLogPath")
    stop
}

# Rule 2: DHCP messages (Zone/dhcp structure)
if $msg contains "dhcp" and $msg regex "^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+[A-Z_][A-Z0-9_]*\s" then {
    action(type="omfile" dynaFile="UniversalDHCPLogPath")  
    stop
}

# Rule 3: Any message with recognizable zone pattern (Zone/general)
if $msg regex "^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+[A-Z_][A-Z0-9_]*\s" then {
    action(type="omfile" dynaFile="UniversalZoneLogPath")
    stop
}

# Debug: Log all messages for analysis
action(type="omfile" file="/var/log/rsyslog-zone-debug.log")

# Catch-all for unmatched messages
action(type="omfile" dynaFile="UnknownLogPath")
EOF

print_step "5. Otomatik dizin oluşturma servisi kuruluyor..."

# Create universal directory creation script
cat > /usr/local/bin/create-universal-dirs.sh << 'EOF'
#!/bin/bash

LOG_BASE="/var/log/rsyslog"
MONITOR_LOG="/var/log/universal-monitor.log"

# Function to log with timestamp
log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$MONITOR_LOG"
}

# Extract zone and hotel from any log message format
extract_zone_hotel() {
    local message="$1"
    local zone=""
    local hotel=""
    local category=""
    
    # Extract zone (4th field after timestamp)
    if [[ "$message" =~ ^[A-Za-z]+[[:space:]]+[0-9]+[[:space:]]+[0-9:]+[[:space:]]+([A-Z_][A-Z0-9_]*)[[:space:]] ]]; then
        zone="${BASH_REMATCH[1]}"
    fi
    
    # Extract hotel (between "in:" and " out:")
    if [[ "$message" =~ in:([A-Z0-9_]+)[[:space:]]+out ]]; then
        hotel="${BASH_REMATCH[1]}"
        category="$zone/$hotel"
    elif [[ "$message" =~ dhcp ]]; then
        category="$zone/dhcp"
    elif [[ -n "$zone" ]]; then
        category="$zone/general"
    fi
    
    echo "$category"
}

# Create directory if needed
create_dir() {
    local path="$1"
    local full_path="$LOG_BASE/$path"
    
    if [[ -n "$path" && ! -d "$full_path" ]]; then
        mkdir -p "$full_path"
        chown -R syslog:adm "$full_path"
        chmod -R 755 "$full_path"
        log_event "Auto-created universal directory: $path"
        echo "Created: $full_path"
    fi
}

# Monitor logs and create directories
monitor_and_create() {
    # Check unknown logs
    local unknown_file="$LOG_BASE/unknown/unknown/$(date '+%Y-%m-%d').log"
    
    if [[ -f "$unknown_file" ]]; then
        tail -50 "$unknown_file" 2>/dev/null | while read -r line; do
            category=$(extract_zone_hotel "$line")
            if [[ -n "$category" ]]; then
                create_dir "$category"
            fi
        done
    fi
    
    # Check debug logs for patterns
    if [[ -f "/var/log/rsyslog-zone-debug.log" ]]; then
        tail -50 "/var/log/rsyslog-zone-debug.log" 2>/dev/null | while read -r line; do
            category=$(extract_zone_hotel "$line")
            if [[ -n "$category" ]]; then
                create_dir "$category"
            fi
        done
    fi
}

log_event "Universal auto-directory creation started"

# Continuous monitoring
while true; do
    monitor_and_create
    sleep 30
done
EOF

chmod +x /usr/local/bin/create-universal-dirs.sh

print_step "6. Monitoring dashboard kuruluyor..."

# Create monitoring script
cat > /opt/logmaster/modules/1.1-rsyslog-server/monitor-universal.sh << 'EOF'
#!/bin/bash

echo "🌍 LogMaster: Universal Multi-Tenant Monitoring Dashboard"
echo "========================================================"

# System Status
echo -e "\n📊 Sistem Durumu:"
echo "=================="
echo "RSyslog: $(systemctl is-active rsyslog)"
echo "UDP 514: $(netstat -ulnp 2>/dev/null | grep -q ':514' && echo 'Listening' || echo 'Not listening')"
echo "TCP 514: $(netstat -tlnp 2>/dev/null | grep -q ':514' && echo 'Listening' || echo 'Not listening')"

# Zone Count
echo -e "\n🏨 Zone Sayıları:"
echo "================="
ZONES=$(find /var/log/rsyslog -maxdepth 1 -type d ! -name "rsyslog" ! -name "unknown" | wc -l)
HOTELS=$(find /var/log/rsyslog -maxdepth 2 -name "*HOTEL*" -type d | wc -l)
echo "Aktif Zone: $ZONES"
echo "Aktif Hotel: $HOTELS"

# Directory Structure
echo -e "\n📁 Dizin Yapısı:"
echo "================"
tree /var/log/rsyslog/ -L 2 2>/dev/null || find /var/log/rsyslog -type d | sort

# Today's Activity
echo -e "\n📈 Bugünkü Aktivite:"
echo "==================="
TODAY=$(date '+%Y-%m-%d')
LOG_COUNT=$(find /var/log/rsyslog -name "$TODAY.log" -type f 2>/dev/null | wc -l)
echo "Aktif log dosyası: $LOG_COUNT"

if [[ $LOG_COUNT -gt 0 ]]; then
    echo -e "\nSon log girişleri:"
    find /var/log/rsyslog -name "$TODAY.log" -type f -exec tail -1 {} + 2>/dev/null | head -5
fi

echo -e "\n💡 Komutlar:"
echo "============"
echo "  tail -f /var/log/universal-monitor.log     # Auto-creation logs"
echo "  tail -f /var/log/rsyslog-zone-debug.log    # Debug logs"
echo "  watch -n 30 ./monitor-universal.sh         # Auto-refresh"
EOF

chmod +x /opt/logmaster/modules/1.1-rsyslog-server/monitor-universal.sh

print_step "7. RSyslog konfigürasyonu test ediliyor..."

# Test configuration
if rsyslogd -N1; then
    print_success "RSyslog konfigürasyonu geçerli!"
else
    echo "[HATA] RSyslog konfigürasyonunda sorun var!"
    exit 1
fi

print_step "8. Servisler başlatılıyor..."

# Start RSyslog
systemctl restart rsyslog
sleep 2

if systemctl is-active --quiet rsyslog; then
    print_success "RSyslog servisi başarıyla başlatıldı!"
else
    echo "[HATA] RSyslog servisi başlatılamadı!"
    exit 1
fi

# Start universal monitoring
nohup /usr/local/bin/create-universal-dirs.sh > /dev/null 2>&1 &

print_step "9. Test logları gönderiliyor..."

# Send test messages for multiple zones
echo "$(date '+%b %d %H:%M:%S') SISLI_HOTSPOT srcnat: in:FOURSIDES_HOTEL out:DT_MODEM, connection-state:new" | nc -u localhost 514
echo "$(date '+%b %d %H:%M:%S') BEYOGLU_HOTSPOT srcnat: in:PREMIUM_HOTEL out:FIBER_MODEM, connection-state:new" | nc -u localhost 514
echo "$(date '+%b %d %H:%M:%S') ANKARA_ZONE dhcp15 assigned 172.12.0.100" | nc -u localhost 514

sleep 3

print_step "10. Sonuçları gösteriliyor..."

echo ""
print_success "🎉 LogMaster Universal Multi-Tenant Sistemi Başarıyla Kuruldu!"

echo ""
echo "📁 Oluşturulan Dizin Yapısı:"
echo "============================"
tree /var/log/rsyslog/ -L 3 2>/dev/null || find /var/log/rsyslog/ -type d | sort

echo ""
echo "📊 Hızlı Kontrol:"
echo "================="
echo "RSyslog durumu: $(systemctl is-active rsyslog)"
echo "Otomatik monitor: $(pgrep -f create-universal-dirs >/dev/null && echo 'Çalışıyor' || echo 'Durdurulmuş')"
echo "Bugünkü log dosyası: $(find /var/log/rsyslog -name "$(date '+%Y-%m-%d').log" | wc -l) adet"

echo ""
echo "🔧 Yönetim Komutları:"
echo "===================="
echo "  cd /opt/logmaster/modules/1.1-rsyslog-server"
echo "  ./monitor-universal.sh                      # Dashboard"
echo "  tail -f /var/log/universal-monitor.log      # Auto-creation"
echo "  tail -f /var/log/rsyslog-zone-debug.log     # Debug"

echo ""
echo "📋 Test Komutları:"
echo "================="
echo "  # Yeni zone/hotel testi:"
echo "  echo \"\$(date '+%b %d %H:%M:%S') YENI_ZONE srcnat: in:YENI_HOTEL out:MODEM\" | nc -u localhost 514"

echo ""
print_success "Kurulum tamamlandı! Artık TÜM zone'lardan gelen loglar otomatik organize edilecek! 🚀"

echo ""
echo "📖 Detaylı rehber: /opt/logmaster/modules/1.1-rsyslog-server/fresh-install-guide.md" 
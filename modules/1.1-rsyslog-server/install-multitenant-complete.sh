#!/bin/bash
set -e

echo "🏗️ LogMaster: Komplet Multi-Tenant Kurulumu (Zone/Hotel)"
echo "========================================================="

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

print_warning() {
    echo -e "${YELLOW}[UYARI]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Bu script root olarak çalıştırılmalı!" 
   echo "Kullanım: sudo ./install-multitenant-complete.sh"
   exit 1
fi

print_step "1. Eski konfigürasyonları yedekliyor..."

# Backup old configurations
mkdir -p /etc/rsyslog.d/backup-$(date +%Y%m%d-%H%M%S)
cp /etc/rsyslog.d/*.conf /etc/rsyslog.d/backup-$(date +%Y%m%d-%H%M%S)/ 2>/dev/null || true

print_step "2. Multi-tenant dizin yapısını oluşturuyor..."

# Create nested structure
mkdir -p /var/log/rsyslog/unknown/unknown
mkdir -p /var/log/rsyslog/SISLI_HOTSPOT/{ADELMAR_HOTEL,FOURSIDES_HOTEL,ATRO_HOTEL,38_HOTEL,dhcp,system}

# Set permissions
chown -R syslog:adm /var/log/rsyslog/
chmod -R 755 /var/log/rsyslog/

print_step "3. Modern RSyslog konfigürasyonu yazılıyor..."

# Create modern nested configuration
cat > /etc/rsyslog.d/70-nested-multitenant.conf << 'EOF'
# LogMaster Nested Multi-Tenant Configuration - Modern Version
# Zone/Hotel structure: ZONE/HOTEL/YYYY-MM-DD.log

# Templates for nested directory paths
template(name="NestedHotelLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:[0-9:]+ ([A-Z_]+[A-Z0-9_]*) --end%/%msg:R,ERE,1,FIELD:srcnat: in:([A-Z0-9_]+) out: --end%/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="DHCPLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:[0-9:]+ ([A-Z_]+[A-Z0-9_]*) --end%/dhcp/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="SystemLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:[0-9:]+ ([A-Z_]+[A-Z0-9_]*) --end%/system/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="UnknownLogPath" type="string" string="/var/log/rsyslog/unknown/unknown/%$YEAR%-%$MONTH%-%$DAY%.log")

# Rule for SRCNAT messages (Zone/Hotel structure)
if $msg contains "srcnat: in:" then {
    action(type="omfile" dynaFile="NestedHotelLogPath")
    stop
}

# Rule for DHCP messages (Zone level)
if $msg contains "dhcp" then {
    action(type="omfile" dynaFile="DHCPLogPath")  
    stop
}

# Rule for other zone messages (system level)
if $msg contains "SISLI_HOTSPOT" or $msg contains "HOTEL" then {
    action(type="omfile" dynaFile="SystemLogPath")
    stop
}

# Catch-all for unidentified sources
action(type="omfile" dynaFile="UnknownLogPath")
EOF

print_step "4. Otomatik dizin oluşturma script'i kuriliyor..."

# Create advanced directory creation script
cat > /usr/local/bin/create-nested-dir.sh << 'EOF'
#!/bin/bash

LOG_BASE="/var/log/rsyslog"
MONITOR_LOG="/var/log/nested-monitor.log"

# Function to log with timestamp
log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$MONITOR_LOG"
}

# Extract zone and hotel from log message
extract_zone_hotel() {
    local message="$1"
    local zone=""
    local hotel=""
    
    # Extract zone (after timestamp, word with HOTSPOT or similar)
    if [[ "$message" =~ [0-9:]+[[:space:]]+([A-Z_]+[A-Z0-9_]*)[[:space:]] ]]; then
        zone="${BASH_REMATCH[1]}"
    fi
    
    # Extract hotel (between "srcnat: in:" and " out:")
    if [[ "$message" =~ srcnat:[[:space:]]+in:([A-Z0-9_]+)[[:space:]]+out: ]]; then
        hotel="${BASH_REMATCH[1]}"
    fi
    
    if [[ -n "$zone" && -n "$hotel" ]]; then
        echo "$zone/$hotel"
    elif [[ -n "$zone" ]]; then
        echo "$zone/system"
    fi
}

# Create directory if needed
create_dir() {
    local path="$1"
    local full_path="$LOG_BASE/$path"
    
    if [[ ! -d "$full_path" ]]; then
        mkdir -p "$full_path"
        chown -R syslog:adm "$full_path"
        chmod -R 755 "$full_path"
        log_event "Auto-created directory: $path"
        echo "Created: $full_path"
    fi
}

# Monitor unknown logs and create directories
monitor_unknown() {
    local unknown_file="$LOG_BASE/unknown/unknown/$(date '+%Y-%m-%d').log"
    
    if [[ -f "$unknown_file" ]]; then
        tail -50 "$unknown_file" | while read -r line; do
            zone_hotel=$(extract_zone_hotel "$line")
            if [[ -n "$zone_hotel" ]]; then
                create_dir "$zone_hotel"
            fi
        done
    fi
}

log_event "Auto-directory creation started"

# Initial check
monitor_unknown

# Continuous monitoring
while true; do
    monitor_unknown
    sleep 30
done
EOF

chmod +x /usr/local/bin/create-nested-dir.sh

print_step "5. Eski konfigürasyonları devre dışı bırakıyor..."

# Disable old single-file logging
for conf in /etc/rsyslog.d/50-*.conf; do
    if [[ -f "$conf" ]]; then
        sed -i 's/^\*\.\* \/var\/log\/rsyslog\/messages/#&/' "$conf"
    fi
done

# Disable other multi-tenant configs
for old_conf in /etc/rsyslog.d/60-*.conf; do
    if [[ -f "$old_conf" ]]; then
        mv "$old_conf" "${old_conf}.disabled"
    fi
done

print_step "6. RSyslog konfigürasyonu test ediliyor..."

# Test configuration
if rsyslogd -N1; then
    print_success "RSyslog konfigürasyonu geçerli!"
else
    echo "HATA: RSyslog konfigürasyonunda sorun var!"
    exit 1
fi

print_step "7. RSyslog servisini yeniden başlatıyor..."
systemctl restart rsyslog
sleep 2

if systemctl is-active --quiet rsyslog; then
    print_success "RSyslog servisi başarıyla başlatıldı!"
else
    echo "HATA: RSyslog servisi başlatılamadı!"
    exit 1
fi

print_step "8. Otomatik dizin monitörünü başlatıyor..."

# Kill old processes
pkill -f "create-nested-dir.sh" 2>/dev/null || true

# Start new monitor
nohup /usr/local/bin/create-nested-dir.sh > /dev/null 2>&1 &

print_step "9. Test logları gönderiliyor..."

# Send test messages
echo "$(date '+%b %d %H:%M:%S') SISLI_HOTSPOT srcnat: in:TEST_HOTEL out:DT_MODEM, connection-state:new" | nc -u localhost 514
echo "$(date '+%b %d %H:%M:%S') SISLI_HOTSPOT dhcp15 assigned 172.11.0.100" | nc -u localhost 514

sleep 3

print_step "10. Sonuçları kontrol ediliyor..."

echo ""
print_success "🎉 Multi-Tenant Yapısı Başarıyla Kuruldu!"

echo ""
echo "📁 Oluşturulan Dizin Yapısı:"
echo "============================"
tree /var/log/rsyslog/ -L 3 2>/dev/null || find /var/log/rsyslog/ -type d | sort

echo ""
echo "📊 Bugünkü Log Dosyaları:"
echo "========================"
find /var/log/rsyslog/ -name "$(date '+%Y-%m-%d').log" -type f 2>/dev/null || echo "Henüz bugünkü log dosyası yok"

echo ""
echo "🔧 Yönetim Komutları:"
echo "===================="
echo "  sudo chmod +x monitor-nested-multitenant.sh"
echo "  ./monitor-nested-multitenant.sh                    # Dashboard"
echo "  tail -f /var/log/nested-monitor.log                # Auto-creation logs"
echo "  tree /var/log/rsyslog/                             # Dizin yapısı"

echo ""
echo "📋 Test Komutları:"
echo "================="
echo "  # Mikrotik srcnat log testi:"
echo "  echo '\$(date '+%b %d %H:%M:%S') SISLI_HOTSPOT srcnat: in:YENI_HOTEL out:DT_MODEM' | nc -u localhost 514"
echo ""
echo "  # DHCP log testi:"  
echo "  echo '\$(date '+%b %d %H:%M:%S') SISLI_HOTSPOT dhcp15 assigned 172.11.0.200' | nc -u localhost 514"

print_success "Kurulum tamamlandı! Artık birden fazla cihazdan log alabilirsiniz." 
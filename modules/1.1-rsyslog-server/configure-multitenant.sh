#!/bin/bash
set -e

echo "🏨 LogMaster Module 1.1: Multi-Tenant Log Configuration"

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

print_step "Multi-tenant log yapısını oluşturuyor..."

# Create multi-tenant directory structure
HOTELS=("SISLI_HOTSPOT" "FOURSIDES_HOTEL" "ATIRO_HOTEL" "ADELMAR_HOTEL" "THISSIOS_HOTEL")

for hotel in "${HOTELS[@]}"; do
    mkdir -p "/var/log/rsyslog/$hotel"
    chown syslog:adm "/var/log/rsyslog/$hotel"
    chmod 755 "/var/log/rsyslog/$hotel"
    echo "  ✓ Created: /var/log/rsyslog/$hotel"
done

print_step "RSyslog template konfigürasyonu..."

# Create multi-tenant RSyslog configuration
cat > /etc/rsyslog.d/60-multitenant.conf << 'EOF'
# LogMaster Multi-Tenant Configuration
# Template for dynamic file paths based on source

# Define template for hotel-based file separation
$template HotelLogPath,"/var/log/rsyslog/%msg:R,ERE,1,FIELD:srcname: in:([A-Z_]+) --end%/%$YEAR%-%$MONTH%-%$DAY%.log"

# Default fallback path
$template DefaultLogPath,"/var/log/rsyslog/unknown/%$YEAR%-%$MONTH%-%$DAY%.log"

# Hotel-specific rules (based on source identification)
if $msg contains "SISLI_HOTSPOT" then {
    /var/log/rsyslog/SISLI_HOTSPOT/%$YEAR%-%$MONTH%-%$DAY%.log
    stop
}

if $msg contains "FOURSIDES_HOTEL" then {
    /var/log/rsyslog/FOURSIDES_HOTEL/%$YEAR%-%$MONTH%-%$DAY%.log
    stop
}

if $msg contains "ATIRO_HOTEL" then {
    /var/log/rsyslog/ATIRO_HOTEL/%$YEAR%-%$MONTH%-%$DAY%.log
    stop
}

if $msg contains "ADELMAR_HOTEL" then {
    /var/log/rsyslog/ADELMAR_HOTEL/%$YEAR%-%$MONTH%-%$DAY%.log
    stop
}

if $msg contains "THISSIOS_HOTEL" then {
    /var/log/rsyslog/THISSIOS_HOTEL/%$YEAR%-%$MONTH%-%$DAY%.log
    stop
}

# Catch-all for unidentified sources
/var/log/rsyslog/unknown/%$YEAR%-%$MONTH%-%$DAY%.log
EOF

print_step "Unknown source dizini oluşturuluyor..."
mkdir -p /var/log/rsyslog/unknown
chown syslog:adm /var/log/rsyslog/unknown
chmod 755 /var/log/rsyslog/unknown

print_step "Eski tek dosya konfigürasyonunu devre dışı bırakıyor..."
# Comment out the old single-file rule
sed -i 's/^\*\.\* \/var\/log\/rsyslog\/messages/#&/' /etc/rsyslog.d/50-logmaster.conf

print_step "RSyslog servisini yeniden başlatıyor..."
systemctl restart rsyslog

print_step "Test log mesajları gönderiliyor..."
sleep 2

# Send test messages for each hotel
echo "Jan 24 00:33:14 SISLI_HOTSPOT Test message for Sisli Hotspot" | nc -u localhost 514
echo "Jan 24 00:33:14 FOURSIDES_HOTEL Test message for Foursides Hotel" | nc -u localhost 514
echo "Jan 24 00:33:14 ATIRO_HOTEL Test message for Atiro Hotel" | nc -u localhost 514

sleep 2

print_step "Multi-tenant yapı kontrol ediliyor..."
TODAY=$(date '+%Y-%m-%d')

for hotel in "${HOTELS[@]}"; do
    LOG_FILE="/var/log/rsyslog/$hotel/$TODAY.log"
    if [[ -f "$LOG_FILE" ]]; then
        SIZE=$(wc -l < "$LOG_FILE")
        echo "  ✓ $hotel: $SIZE lines in $TODAY.log"
    else
        echo "  ⚠ $hotel: No log file yet"
    fi
done

print_success "Multi-tenant log yapısı başarıyla kuruldu!"

echo ""
echo "📊 Log dosya yapısı:"
echo "--------------------"
tree /var/log/rsyslog/ 2>/dev/null || find /var/log/rsyslog/ -type f -name "*.log" | head -10

echo ""
echo "🔧 Yönetim komutları:"
echo "  tail -f /var/log/rsyslog/SISLI_HOTSPOT/$(date '+%Y-%m-%d').log    # Sisli logs"
echo "  tail -f /var/log/rsyslog/FOURSIDES_HOTEL/$(date '+%Y-%m-%d').log  # Foursides logs"
echo "  find /var/log/rsyslog/ -name '*.log' -exec wc -l {} +             # All log counts"

echo ""
echo "📋 Monitor komutu güncellemesi:"
echo "  ./monitor-multitenant.sh  # Multi-tenant monitoring dashboard" 
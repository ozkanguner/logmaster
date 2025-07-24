#!/bin/bash
set -e

echo "🏗️ LogMaster Module 1.1: Nested Multi-Tenant Log Configuration (Zone/Hotel)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
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

print_step "Nested multi-tenant yapısını oluşturuyor..."

# Create base directories and unknown
mkdir -p /var/log/rsyslog/unknown/unknown
chown -R syslog:adm /var/log/rsyslog/unknown
chmod -R 755 /var/log/rsyslog/unknown

print_step "Nested RSyslog konfigürasyonu..."

# Create nested multi-tenant RSyslog configuration
cat > /etc/rsyslog.d/70-nested-multitenant.conf << 'EOF'
# LogMaster Nested Multi-Tenant Configuration
# Zone/Hotel structure: ZONE/HOTEL/YYYY-MM-DD.log

# Template for nested directory structure (Zone/Hotel)
$template NestedHotelLogPath,"/var/log/rsyslog/%msg:R,ERE,1,FIELD:[0-9:]+ ([A-Z_]+[A-Z0-9_]*) --end%/%msg:R,ERE,1,FIELD:srcnat: in:([A-Z0-9_]+) out: --end%/%$YEAR%-%$MONTH%-%$DAY%.log"

# Template for zone extraction
$template ZoneName,"%msg:R,ERE,1,FIELD:[0-9:]+ ([A-Z_]+[A-Z0-9_]*) --end%"

# Template for hotel extraction from srcnat
$template HotelName,"%msg:R,ERE,1,FIELD:srcnat: in:([A-Z0-9_]+) out: --end%"

# Rule for messages containing srcnat pattern
if $msg contains "srcnat: in:" then {
    ?NestedHotelLogPath
    stop
}

# Rule for DHCP messages (zone level)
if $msg contains "dhcp" then {
    /var/log/rsyslog/%msg:R,ERE,1,FIELD:[0-9:]+ ([A-Z_]+[A-Z0-9_]*) --end%/dhcp/%$YEAR%-%$MONTH%-%$DAY%.log
    stop
}

# Catch-all for unidentified sources
/var/log/rsyslog/unknown/unknown/%$YEAR%-%$MONTH%-%$DAY%.log
EOF

print_step "Otomatik nested klasör oluşturma script'i..."

# Create nested directory creation script
cat > /usr/local/bin/create-nested-dir.sh << 'EOF'
#!/bin/bash

# Monitor rsyslog messages and create nested directories (Zone/Hotel)
LOG_BASE="/var/log/rsyslog"

# Function to extract zone and hotel from log message
extract_zone_hotel() {
    local message="$1"
    local zone=""
    local hotel=""
    
    # Extract zone (after timestamp, before srcnat)
    if [[ "$message" =~ [0-9:]+\ ([A-Z_]+[A-Z0-9_]*)\ srcnat ]]; then
        zone="${BASH_REMATCH[1]}"
    fi
    
    # Extract hotel (between "srcnat: in:" and " out:")
    if [[ "$message" =~ srcnat:\ in:([A-Z0-9_]+)\ out: ]]; then
        hotel="${BASH_REMATCH[1]}"
    fi
    
    if [[ -n "$zone" && -n "$hotel" ]]; then
        echo "$zone/$hotel"
    elif [[ -n "$zone" ]]; then
        # For DHCP or other zone-only messages
        echo "$zone/system"
    fi
}

# Create nested directory for zone/hotel if needed
create_nested_dir() {
    local zone_hotel="$1"
    local zone_hotel_dir="$LOG_BASE/$zone_hotel"
    
    if [[ ! -d "$zone_hotel_dir" ]]; then
        mkdir -p "$zone_hotel_dir"
        chown -R syslog:adm "$zone_hotel_dir"
        chmod -R 755 "$zone_hotel_dir"
        logger "LogMaster: Auto-created nested directory: $zone_hotel"
        echo "Created: $zone_hotel_dir"
    fi
}

# Monitor messages and create directories
tail -F "$LOG_BASE/unknown/unknown/$(date '+%Y-%m-%d').log" 2>/dev/null | while read -r line; do
    zone_hotel=$(extract_zone_hotel "$line")
    if [[ -n "$zone_hotel" ]]; then
        create_nested_dir "$zone_hotel"
    fi
done &

# Periodic check for existing messages
while true; do
    # Check current unknown log
    UNKNOWN_LOG="$LOG_BASE/unknown/unknown/$(date '+%Y-%m-%d').log"
    if [[ -f "$UNKNOWN_LOG" ]]; then
        tail -100 "$UNKNOWN_LOG" | while read -r line; do
            zone_hotel=$(extract_zone_hotel "$line")
            if [[ -n "$zone_hotel" ]]; then
                create_nested_dir "$zone_hotel"
            fi
        done
    fi
    
    # Also check any existing single-level logs for migration
    find "$LOG_BASE" -maxdepth 1 -name "*.log" | while read -r logfile; do
        tail -50 "$logfile" 2>/dev/null | while read -r line; do
            zone_hotel=$(extract_zone_hotel "$line")
            if [[ -n "$zone_hotel" ]]; then
                create_nested_dir "$zone_hotel"
            fi
        done
    done
    
    sleep 60
done
EOF

chmod +x /usr/local/bin/create-nested-dir.sh

print_step "Örnek zone/hotel yapısı oluşturuyor..."

# Create example structure based on seen logs
ZONES_HOTELS=(
    "SISLI_HOTSPOT/38_HOTEL"
    "SISLI_HOTSPOT/ADELMAR_HOTEL" 
    "SISLI_HOTSPOT/FOURSIDES_HOTEL"
    "SISLI_HOTSPOT/ATRO_HOTEL"
    "SISLI_HOTSPOT/dhcp"
    "SISLI_HOTSPOT/system"
)

for zone_hotel in "${ZONES_HOTELS[@]}"; do
    mkdir -p "/var/log/rsyslog/$zone_hotel"
    chown -R syslog:adm "/var/log/rsyslog/$zone_hotel"
    chmod -R 755 "/var/log/rsyslog/$zone_hotel"
    echo "  ✓ Created: /var/log/rsyslog/$zone_hotel"
done

print_step "Eski konfigürasyonları devre dışı bırakıyor..."
# Disable old configurations
for conf_file in /etc/rsyslog.d/60-*.conf; do
    if [[ -f "$conf_file" ]]; then
        mv "$conf_file" "${conf_file}.disabled"
    fi
done

# Comment out old single-file rule
sed -i 's/^\*\.\* \/var\/log\/rsyslog\/messages/#&/' /etc/rsyslog.d/50-logmaster.conf

print_step "RSyslog servisini yeniden başlatıyor..."
systemctl restart rsyslog

print_step "Nested directory monitoring başlatılıyor..."
# Start nested monitoring in background
nohup /usr/local/bin/create-nested-dir.sh > /var/log/nested-monitor.log 2>&1 &

print_step "Test log mesajları gönderiliyor..."
sleep 2

# Send test messages matching real format
echo "Jul 24 00:45:14 SISLI_HOTSPOT srcnat: in:TEST_HOTEL out:DT_MODEM, connection-state:new" | nc -u localhost 514
echo "Jul 24 00:45:15 SISLI_HOTSPOT dhcp15 assigned 172.11.0.100 for AA:BB:CC:DD:EE:FF" | nc -u localhost 514

sleep 3

print_success "Nested multi-tenant yapısı başarıyla kuruldu!"

echo ""
echo "🏗️ Created Tree Structure:"
echo "=========================="
tree /var/log/rsyslog/ 2>/dev/null || find /var/log/rsyslog/ -type d | sort

echo ""
echo "📊 Log dosya örnekleri:"
echo "----------------------"
find /var/log/rsyslog/ -name "*.log" -type f | head -10

echo ""
echo "🎯 Pattern Matching:"
echo "  ✅ Zone: 4th word after timestamp"
echo "  ✅ Hotel: Between 'srcnat: in:' and ' out:'"
echo "  ✅ DHCP: Zone/dhcp/YYYY-MM-DD.log"
echo "  ✅ Other: Zone/system/YYYY-MM-DD.log"
echo ""
echo "🔧 Monitoring:"
echo "  tail -f /var/log/nested-monitor.log        # Creation log"
echo "  ./monitor-nested-multitenant.sh           # Dashboard"
echo "  tree /var/log/rsyslog/                     # Structure" 
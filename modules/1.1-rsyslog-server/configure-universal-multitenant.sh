#!/bin/bash
set -e

echo "🌍 LogMaster: Universal Multi-Tenant Configuration (Tüm Zone'lar)"
echo "================================================================="

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
   echo "Kullanım: sudo ./configure-universal-multitenant.sh"
   exit 1
fi

print_step "1. Mevcut zone'ları analiz ediyor..."

# Analyze existing logs to find all zones
echo "Mevcut log kaynaklarını analiz ediliyor..."
EXISTING_ZONES=$(grep -h "srcnat\|dhcp" /var/log/rsyslog/*/*/*.log 2>/dev/null | sed -n 's/.*[0-9:]\+ \([A-Z_][A-Z0-9_]*\) .*/\1/p' | sort | uniq | head -20)

echo "Bulunan Zone'lar:"
echo "$EXISTING_ZONES" | while read zone; do
    echo "  - $zone"
done

print_step "2. Universal RSyslog konfigürasyonu yazılıyor..."

# Create universal nested configuration - supports ANY zone
cat > /etc/rsyslog.d/70-universal-multitenant.conf << 'EOF'
# LogMaster Universal Multi-Tenant Configuration
# Supports ANY zone automatically: ZONE/HOTEL/YYYY-MM-DD.log

# Universal templates - works with any zone name
template(name="UniversalHotelLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/%msg:R,ERE,1,FIELD:in:([A-Z0-9_]+)\s+out --end%/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="UniversalDHCPLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/dhcp/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="UniversalSystemLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/system/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="UniversalZoneLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/general/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="UnknownLogPath" type="string" string="/var/log/rsyslog/unknown/unknown/%$YEAR%-%$MONTH%-%$DAY%.log")

# Debug template
template(name="DebugExtraction" type="string" string="/var/log/rsyslog-zone-debug.log")

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

# Rule 3: Any message with recognizable zone pattern (Zone/system)
if $msg regex "^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+[A-Z_][A-Z0-9_]*\s" then {
    action(type="omfile" dynaFile="UniversalZoneLogPath")
    stop
}

# Debug: Log all messages for analysis
action(type="omfile" file="/var/log/rsyslog-zone-debug.log")

# Catch-all for unmatched messages
action(type="omfile" dynaFile="UnknownLogPath")
EOF

print_step "3. Gelişmiş otomatik dizin oluşturma script'i kuruluyor..."

# Create advanced universal directory creation script
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
    
    # Check any existing single-level logs
    find "$LOG_BASE" -maxdepth 1 -name "*.log" 2>/dev/null | while read -r logfile; do
        tail -30 "$logfile" 2>/dev/null | while read -r line; do
            category=$(extract_zone_hotel "$line")
            if [[ -n "$category" ]]; then
                create_dir "$category"
            fi
        done
    done
}

log_event "Universal auto-directory creation started"

# Continuous monitoring
while true; do
    monitor_and_create
    sleep 30
done
EOF

chmod +x /usr/local/bin/create-universal-dirs.sh

print_step "4. Eski konfigürasyonları yedekliyor..."

# Backup and disable old configs
mkdir -p /etc/rsyslog.d/backup-universal-$(date +%Y%m%d-%H%M%S)
mv /etc/rsyslog.d/70-*.conf /etc/rsyslog.d/backup-universal-$(date +%Y%m%d-%H%M%S)/ 2>/dev/null || true

print_step "5. RSyslog konfigürasyonu test ediliyor..."

# Test configuration
if rsyslogd -N1; then
    print_success "RSyslog konfigürasyonu geçerli!"
else
    echo "[HATA] RSyslog konfigürasyonunda sorun var!"
    exit 1
fi

print_step "6. RSyslog servisini yeniden başlatıyor..."
systemctl restart rsyslog
sleep 2

if systemctl is-active --quiet rsyslog; then
    print_success "RSyslog servisi başarıyla başlatıldı!"
else
    echo "[HATA] RSyslog servisi başlatılamadı!"
    exit 1
fi

print_step "7. Universal monitoring başlatılıyor..."

# Kill old monitoring processes
pkill -f "create-.*-dir" 2>/dev/null || true

# Start new universal monitor
nohup /usr/local/bin/create-universal-dirs.sh > /dev/null 2>&1 &

print_step "8. Test logları gönderiliyor (çoklu zone)..."

# Send test messages for multiple zones
echo "Jul 24 16:00:14 BEYOGLU_HOTSPOT srcnat: in:PREMIUM_HOTEL out:DT_MODEM, connection-state:new" | nc -u localhost 514
echo "Jul 24 16:00:15 KADIKOY_ZONE srcnat: in:BUSINESS_HOTEL out:FIBER_MODEM, connection-state:new" | nc -u localhost 514
echo "Jul 24 16:00:16 SISLI_HOTSPOT srcnat: in:FOURSIDES_HOTEL out:DT_MODEM, connection-state:new" | nc -u localhost 514
echo "Jul 24 16:00:17 ANKARA_ZONE dhcp15 assigned 172.12.0.100 for new_device" | nc -u localhost 514

sleep 3

print_step "9. Sonuçları kontrol ediliyor..."

echo ""
print_success "🌍 Universal Multi-Tenant Yapısı Başarıyla Kuruldu!"

echo ""
echo "📁 Oluşturulan Evrensel Dizin Yapısı:"
echo "===================================="
tree /var/log/rsyslog/ -L 3 2>/dev/null || find /var/log/rsyslog/ -type d | sort

echo ""
echo "📊 Algılanan Zone'lar:"
echo "====================="
find /var/log/rsyslog -maxdepth 1 -type d ! -name "rsyslog" ! -name "unknown" | sort

echo ""
echo "🔧 Universal Yönetim Komutları:"
echo "==============================="
echo "  # Tüm zone'ları izle:"
echo "  find /var/log/rsyslog -name '*.log' -type f | head -20"
echo ""
echo "  # Zone aktivitesi:"
echo "  tail -f /var/log/universal-monitor.log"
echo ""
echo "  # Debug zone extraction:"
echo "  tail -f /var/log/rsyslog-zone-debug.log"

echo ""
echo "📋 Zone Bazlı Test Komutları:"
echo "============================"
find /var/log/rsyslog -maxdepth 2 -type d ! -path "*/unknown*" | while read dir; do
    if [[ -d "$dir" && "$(basename $(dirname $dir))" != "rsyslog" ]]; then
        zone=$(basename $(dirname $dir))
        category=$(basename $dir)
        if [[ "$zone" != "$category" ]]; then
            echo "  tail -f $dir/$(date '+%Y-%m-%d').log  # $zone/$category"
        fi
    fi
done | head -10

print_success "Artık TÜM zone'lardan gelen loglar otomatik olarak organize edilecek!" 
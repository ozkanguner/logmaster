#!/bin/bash
set -e

echo "🏨 LogMaster Module 1.1: Dynamic Multi-Tenant Log Configuration"

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

print_step "Dinamik multi-tenant yapısını oluşturuyor..."

# Create base directories
mkdir -p /var/log/rsyslog/unknown
chown syslog:adm /var/log/rsyslog/unknown
chmod 755 /var/log/rsyslog/unknown

print_step "Dinamik RSyslog konfigürasyonu..."

# Create dynamic multi-tenant RSyslog configuration
cat > /etc/rsyslog.d/60-dynamic-multitenant.conf << 'EOF'
# LogMaster Dynamic Multi-Tenant Configuration
# Automatically creates directories for new hotel sources

# Template for dynamic directory creation and file paths
$template DynamicHotelLogPath,"/var/log/rsyslog/%msg:R,ERE,1,FIELD:srcname: in:([A-Z_]+[A-Z0-9_]*) --end%/%$YEAR%-%$MONTH%-%$DAY%.log"

# Template for extracting hotel name from message
$template HotelName,"%msg:R,ERE,1,FIELD:srcname: in:([A-Z_]+[A-Z0-9_]*) --end%"

# Script to create directory if not exists (executed via omprog)
$template CreateDirScript,"/usr/local/bin/create-hotel-dir.sh '%msg:R,ERE,1,FIELD:srcname: in:([A-Z_]+[A-Z0-9_]*) --end%'"

# Rule for messages containing "srcname: in:" pattern (Mikrotik format)
if $msg contains "srcname: in:" then {
    # Extract hotel name and create directory if needed
    $template ExtractedHotel,"%msg:R,ERE,1,FIELD:srcname: in:([A-Z_]+[A-Z0-9_]*) --end%"
    ?DynamicHotelLogPath
    stop
}

# Rule for messages starting with known hotel patterns
if $msg contains "_HOTSPOT" or $msg contains "_HOTEL" then {
    # Extract hotel name from beginning of message
    $template BeginHotelPath,"/var/log/rsyslog/%msg:R,ERE,1,FIELD:^([A-Z_]+[A-Z0-9_]*) --end%/%$YEAR%-%$MONTH%-%$DAY%.log"
    ?BeginHotelPath
    stop
}

# Catch-all for unidentified sources
/var/log/rsyslog/unknown/%$YEAR%-%$MONTH%-%$DAY%.log
EOF

print_step "Otomatik klasör oluşturma script'i..."

# Create directory creation script
cat > /usr/local/bin/create-hotel-dir.sh << 'EOF'
#!/bin/bash
HOTEL_NAME="$1"

# Validate hotel name (only letters, numbers, underscore)
if [[ "$HOTEL_NAME" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
    HOTEL_DIR="/var/log/rsyslog/$HOTEL_NAME"
    
    # Create directory if it doesn't exist
    if [[ ! -d "$HOTEL_DIR" ]]; then
        mkdir -p "$HOTEL_DIR"
        chown syslog:adm "$HOTEL_DIR"
        chmod 755 "$HOTEL_DIR"
        logger "LogMaster: Created new hotel directory: $HOTEL_DIR"
    fi
fi
EOF

chmod +x /usr/local/bin/create-hotel-dir.sh

print_step "Pre-create hook için rsyslog module..."

# Create a simple script that monitors and creates directories
cat > /usr/local/bin/monitor-and-create-dirs.sh << 'EOF'
#!/bin/bash

# Monitor rsyslog messages and create directories as needed
LOG_BASE="/var/log/rsyslog"

# Function to extract hotel name from log message
extract_hotel_name() {
    local message="$1"
    
    # Pattern 1: "srcname: in:HOTEL_NAME"
    if [[ "$message" =~ srcname:\ in:([A-Z_]+[A-Z0-9_]*) ]]; then
        echo "${BASH_REMATCH[1]}"
        return
    fi
    
    # Pattern 2: Message starts with "HOTEL_NAME"
    if [[ "$message" =~ ^([A-Z_]+[A-Z0-9_]*) ]]; then
        local name="${BASH_REMATCH[1]}"
        if [[ "$name" =~ (HOTSPOT|HOTEL) ]]; then
            echo "$name"
            return
        fi
    fi
}

# Create directory for hotel if needed
create_hotel_dir() {
    local hotel_name="$1"
    local hotel_dir="$LOG_BASE/$hotel_name"
    
    if [[ ! -d "$hotel_dir" ]]; then
        mkdir -p "$hotel_dir"
        chown syslog:adm "$hotel_dir"
        chmod 755 "$hotel_dir"
        logger "LogMaster: Auto-created directory for new hotel: $hotel_name"
        echo "Created: $hotel_dir"
    fi
}

# Monitor recent rsyslog messages for new hotels
tail -F "$LOG_BASE/unknown/$(date '+%Y-%m-%d').log" 2>/dev/null | while read -r line; do
    hotel=$(extract_hotel_name "$line")
    if [[ -n "$hotel" ]]; then
        create_hotel_dir "$hotel"
    fi
done &

# Also check existing messages periodically
while true; do
    # Check last 100 messages in unknown log
    if [[ -f "$LOG_BASE/unknown/$(date '+%Y-%m-%d').log" ]]; then
        tail -100 "$LOG_BASE/unknown/$(date '+%Y-%m-%d').log" | while read -r line; do
            hotel=$(extract_hotel_name "$line")
            if [[ -n "$hotel" ]]; then
                create_hotel_dir "$hotel"
            fi
        done
    fi
    sleep 60
done
EOF

chmod +x /usr/local/bin/monitor-and-create-dirs.sh

print_step "Eski konfigürasyonu devre dışı bırakıyor..."
# Disable old configurations
if [[ -f /etc/rsyslog.d/60-multitenant.conf ]]; then
    mv /etc/rsyslog.d/60-multitenant.conf /etc/rsyslog.d/60-multitenant.conf.old
fi

# Comment out the old single-file rule
sed -i 's/^\*\.\* \/var\/log\/rsyslog\/messages/#&/' /etc/rsyslog.d/50-logmaster.conf

print_step "RSyslog servisini yeniden başlatıyor..."
systemctl restart rsyslog

print_step "Directory monitoring service başlatılıyor..."
# Start monitoring in background
nohup /usr/local/bin/monitor-and-create-dirs.sh > /var/log/hotel-monitor.log 2>&1 &

print_success "Dinamik multi-tenant yapısı başarıyla kuruldu!"

echo ""
echo "🎯 Özellikler:"
echo "  ✅ Yeni hotel ismi geldiğinde otomatik klasör oluşturulur"
echo "  ✅ Hotel isimleri log mesajlarından otomatik çıkarılır"
echo "  ✅ Pattern: 'srcname: in:HOTEL_NAME' veya 'HOTEL_NAME'"
echo "  ✅ Geçersiz isimler 'unknown' klasörüne gider"
echo ""
echo "📊 Desteklenen formatlar:"
echo "  - srcname: in:SISLI_HOTSPOT (Mikrotik format)"
echo "  - FOURSIDES_HOTEL (Başlangıç format)"
echo "  - NEW_HOTEL_123 (Yeni hotel otomatik)"
echo ""
echo "🔧 Monitoring:"
echo "  tail -f /var/log/hotel-monitor.log    # Directory creation log"
echo "  ./monitor-multitenant.sh             # Full dashboard" 
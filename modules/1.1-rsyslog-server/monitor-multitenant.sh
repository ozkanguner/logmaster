#!/bin/bash

echo "🏨 LogMaster Module 1.1: Multi-Tenant Monitoring Dashboard"
echo "============================================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

LOG_BASE="/var/log/rsyslog"
TODAY=$(date '+%Y-%m-%d')
HOTELS=("SISLI_HOTSPOT" "FOURSIDES_HOTEL" "ATIRO_HOTEL" "ADELMAR_HOTEL" "THISSIOS_HOTEL")

print_status() {
    if [[ $2 == "OK" ]]; then
        echo -e "${GREEN}✅ $1: $3${NC}"
    elif [[ $2 == "WARNING" ]]; then
        echo -e "${YELLOW}⚠️  $1: $3${NC}"
    else
        echo -e "${RED}❌ $1: $3${NC}"
    fi
}

print_hotel_header() {
    echo -e "${PURPLE}🏨 $1${NC}"
    echo "----------------------------------------"
}

# 1. RSyslog Service Status
echo -e "${BLUE}[1] System Status${NC}"
if systemctl is-active --quiet rsyslog; then
    print_status "RSyslog Service" "OK" "Active"
else
    print_status "RSyslog Service" "FAILED" "Not running"
fi

if netstat -ulnp | grep -q ":514"; then
    print_status "UDP Port 514" "OK" "Listening"
else
    print_status "UDP Port 514" "FAILED" "Not listening"
fi

# 2. Multi-Tenant Structure
echo -e "\n${BLUE}[2] Multi-Tenant Directory Structure${NC}"
if [[ -d "$LOG_BASE" ]]; then
    print_status "Base Directory" "OK" "$LOG_BASE exists"
    
    # Check each hotel directory
    for hotel in "${HOTELS[@]}"; do
        if [[ -d "$LOG_BASE/$hotel" ]]; then
            print_status "$hotel Directory" "OK" "Created"
        else
            print_status "$hotel Directory" "WARNING" "Missing"
        fi
    done
else
    print_status "Base Directory" "FAILED" "Missing"
fi

# 3. Today's Log Files
echo -e "\n${BLUE}[3] Today's Log Activity ($TODAY)${NC}"
TOTAL_LOGS=0
for hotel in "${HOTELS[@]}"; do
    LOG_FILE="$LOG_BASE/$hotel/$TODAY.log"
    if [[ -f "$LOG_FILE" ]]; then
        COUNT=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
        SIZE=$(du -h "$LOG_FILE" 2>/dev/null | cut -f1 || echo "0")
        print_status "$hotel" "OK" "$COUNT lines, $SIZE"
        TOTAL_LOGS=$((TOTAL_LOGS + COUNT))
    else
        print_status "$hotel" "WARNING" "No activity today"
    fi
done

# Unknown logs
UNKNOWN_LOG="$LOG_BASE/unknown/$TODAY.log"
if [[ -f "$UNKNOWN_LOG" ]]; then
    UNKNOWN_COUNT=$(wc -l < "$UNKNOWN_LOG" 2>/dev/null || echo "0")
    UNKNOWN_SIZE=$(du -h "$UNKNOWN_LOG" 2>/dev/null | cut -f1 || echo "0")
    print_status "Unknown Sources" "WARNING" "$UNKNOWN_COUNT lines, $UNKNOWN_SIZE"
    TOTAL_LOGS=$((TOTAL_LOGS + UNKNOWN_COUNT))
fi

echo -e "${GREEN}📊 Total Today: $TOTAL_LOGS log entries${NC}"

# 4. Recent Activity (Last 10 minutes)
echo -e "\n${BLUE}[4] Recent Activity (Last 10 minutes)${NC}"
CURRENT_TIME=$(date '+%H:%M')
RECENT_TIME=$(date '+%H:%M' -d '10 minutes ago')

for hotel in "${HOTELS[@]}"; do
    LOG_FILE="$LOG_BASE/$hotel/$TODAY.log"
    if [[ -f "$LOG_FILE" ]]; then
        RECENT_COUNT=$(grep "$TODAY" "$LOG_FILE" 2>/dev/null | tail -100 | wc -l || echo "0")
        if [[ $RECENT_COUNT -gt 0 ]]; then
            print_status "$hotel Recent" "OK" "$RECENT_COUNT entries"
        else
            print_status "$hotel Recent" "WARNING" "No recent activity"
        fi
    fi
done

# 5. Top Active Hotels
echo -e "\n${BLUE}[5] Most Active Hotels Today${NC}"
echo "----------------------------------------"
for hotel in "${HOTELS[@]}"; do
    LOG_FILE="$LOG_BASE/$hotel/$TODAY.log"
    if [[ -f "$LOG_FILE" ]]; then
        COUNT=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
        echo -e "${GREEN}  $COUNT${NC} logs from ${BLUE}$hotel${NC}"
    fi
done | sort -nr | head -5

# 6. Storage Usage per Hotel
echo -e "\n${BLUE}[6] Storage Usage by Hotel${NC}"
echo "----------------------------------------"
for hotel in "${HOTELS[@]}"; do
    HOTEL_DIR="$LOG_BASE/$hotel"
    if [[ -d "$HOTEL_DIR" ]]; then
        SIZE=$(du -sh "$HOTEL_DIR" 2>/dev/null | cut -f1 || echo "0")
        FILE_COUNT=$(find "$HOTEL_DIR" -name "*.log" | wc -l || echo "0")
        echo -e "${GREEN}  $SIZE${NC} ($FILE_COUNT files) - ${BLUE}$hotel${NC}"
    fi
done

# 7. Configuration Status
echo -e "\n${BLUE}[7] Multi-Tenant Configuration${NC}"
if [[ -f "/etc/rsyslog.d/60-multitenant.conf" ]]; then
    print_status "Multi-Tenant Config" "OK" "Active"
else
    print_status "Multi-Tenant Config" "WARNING" "Not configured"
fi

# Check if old single-file config is disabled
if grep -q "^#.*\*.* /var/log/rsyslog/messages" /etc/rsyslog.d/50-logmaster.conf 2>/dev/null; then
    print_status "Single-File Config" "OK" "Disabled (correct)"
else
    print_status "Single-File Config" "WARNING" "Still active"
fi

# 8. Quick Management Commands
echo -e "\n${BLUE}[8] Quick Management Commands${NC}"
echo "=========================================="
echo "📊 View specific hotel logs:"
for hotel in "${HOTELS[@]}"; do
    echo "  tail -f $LOG_BASE/$hotel/$TODAY.log  # $hotel"
done

echo ""
echo "🔍 Analysis commands:"
echo "  find $LOG_BASE -name '*.log' -exec wc -l {} +        # All log counts"
echo "  grep -r 'hotspot' $LOG_BASE/*/$(date '+%Y-%m-%d').log   # Search hotspot activity"
echo "  watch -n 30 ./monitor-multitenant.sh                 # Auto-refresh monitoring"

echo ""
echo "🔧 Configuration commands:"
echo "  sudo ./configure-multitenant.sh                      # Setup multi-tenant"
echo "  sudo systemctl restart rsyslog                       # Restart service"

echo ""
echo -e "${GREEN}💡 Tip: Use 'watch -n 30 ./monitor-multitenant.sh' for real-time monitoring!${NC}" 
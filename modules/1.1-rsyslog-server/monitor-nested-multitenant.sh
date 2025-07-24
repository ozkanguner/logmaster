#!/bin/bash

echo "🏗️ LogMaster Module 1.1: Nested Multi-Tenant Monitoring Dashboard (Zone/Hotel)"
echo "================================================================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_BASE="/var/log/rsyslog"
TODAY=$(date '+%Y-%m-%d')

print_status() {
    if [[ $2 == "OK" ]]; then
        echo -e "${GREEN}✅ $1: $3${NC}"
    elif [[ $2 == "WARNING" ]]; then
        echo -e "${YELLOW}⚠️  $1: $3${NC}"
    else
        echo -e "${RED}❌ $1: $3${NC}"
    fi
}

print_zone_header() {
    echo -e "${PURPLE}🏨 Zone: $1${NC}"
    echo "----------------------------------------"
}

print_hotel_header() {
    echo -e "${CYAN}  🏨 Hotel: $1${NC}"
}

# 1. System Status
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

# 2. Nested Structure Overview
echo -e "\n${BLUE}[2] Nested Directory Structure${NC}"
if [[ -d "$LOG_BASE" ]]; then
    print_status "Base Directory" "OK" "$LOG_BASE exists"
    
    # Count zones and hotels
    ZONE_COUNT=$(find "$LOG_BASE" -maxdepth 1 -type d ! -name "$(basename $LOG_BASE)" ! -name "unknown" | wc -l)
    HOTEL_COUNT=$(find "$LOG_BASE" -maxdepth 2 -type d ! -path "$LOG_BASE" ! -path "$LOG_BASE/*" | wc -l)
    
    print_status "Active Zones" "OK" "$ZONE_COUNT zones"
    print_status "Active Hotels" "OK" "$HOTEL_COUNT hotels"
else
    print_status "Base Directory" "FAILED" "Missing"
fi

# 3. Zone Analysis
echo -e "\n${BLUE}[3] Zone Activity Analysis${NC}"
TOTAL_LOGS=0

for zone_dir in "$LOG_BASE"/*; do
    if [[ -d "$zone_dir" && $(basename "$zone_dir") != "unknown" ]]; then
        ZONE_NAME=$(basename "$zone_dir")
        print_zone_header "$ZONE_NAME"
        
        ZONE_TOTAL=0
        
        # Analyze each hotel in the zone
        for hotel_dir in "$zone_dir"/*; do
            if [[ -d "$hotel_dir" ]]; then
                HOTEL_NAME=$(basename "$hotel_dir")
                LOG_FILE="$hotel_dir/$TODAY.log"
                
                if [[ -f "$LOG_FILE" ]]; then
                    COUNT=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
                    SIZE=$(du -h "$LOG_FILE" 2>/dev/null | cut -f1 || echo "0")
                    echo -e "${CYAN}    $HOTEL_NAME${NC}: $COUNT lines, $SIZE"
                    ZONE_TOTAL=$((ZONE_TOTAL + COUNT))
                else
                    echo -e "${YELLOW}    $HOTEL_NAME${NC}: No activity today"
                fi
            fi
        done
        
        echo -e "${GREEN}  Zone Total: $ZONE_TOTAL logs${NC}"
        TOTAL_LOGS=$((TOTAL_LOGS + ZONE_TOTAL))
        echo ""
    fi
done

echo -e "${GREEN}📊 Grand Total: $TOTAL_LOGS log entries today${NC}"

# 4. Top Active Hotels by Zone
echo -e "\n${BLUE}[4] Most Active Hotels by Zone${NC}"
echo "=============================================="

for zone_dir in "$LOG_BASE"/*; do
    if [[ -d "$zone_dir" && $(basename "$zone_dir") != "unknown" ]]; then
        ZONE_NAME=$(basename "$zone_dir")
        echo -e "${PURPLE}🏨 $ZONE_NAME:${NC}"
        
        # Get hotel activity and sort
        for hotel_dir in "$zone_dir"/*; do
            if [[ -d "$hotel_dir" ]]; then
                HOTEL_NAME=$(basename "$hotel_dir")
                LOG_FILE="$hotel_dir/$TODAY.log"
                if [[ -f "$LOG_FILE" ]]; then
                    COUNT=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
                    echo -e "  ${GREEN}$COUNT${NC} logs - ${CYAN}$HOTEL_NAME${NC}"
                fi
            fi
        done | sort -nr | head -5
        echo ""
    fi
done

# 5. Storage Usage by Zone
echo -e "\n${BLUE}[5] Storage Usage by Zone${NC}"
echo "================================"

for zone_dir in "$LOG_BASE"/*; do
    if [[ -d "$zone_dir" && $(basename "$zone_dir") != "unknown" ]]; then
        ZONE_NAME=$(basename "$zone_dir")
        SIZE=$(du -sh "$zone_dir" 2>/dev/null | cut -f1 || echo "0")
        HOTEL_COUNT=$(find "$zone_dir" -maxdepth 1 -type d ! -path "$zone_dir" | wc -l)
        FILE_COUNT=$(find "$zone_dir" -name "*.log" | wc -l)
        
        echo -e "${GREEN}  $SIZE${NC} ($HOTEL_COUNT hotels, $FILE_COUNT files) - ${PURPLE}$ZONE_NAME${NC}"
    fi
done

# 6. Recent Activity (Last 30 minutes)
echo -e "\n${BLUE}[6] Recent Activity (Last 30 minutes)${NC}"
echo "=============================================="

CURRENT_TIME=$(date '+%H:%M')
RECENT_TIME=$(date '+%H:%M' -d '30 minutes ago')

for zone_dir in "$LOG_BASE"/*; do
    if [[ -d "$zone_dir" && $(basename "$zone_dir") != "unknown" ]]; then
        ZONE_NAME=$(basename "$zone_dir")
        ZONE_RECENT=0
        
        for hotel_dir in "$zone_dir"/*; do
            if [[ -d "$hotel_dir" ]]; then
                HOTEL_NAME=$(basename "$hotel_dir")
                LOG_FILE="$hotel_dir/$TODAY.log"
                if [[ -f "$LOG_FILE" ]]; then
                    # Count recent entries (rough estimate)
                    RECENT_COUNT=$(tail -200 "$LOG_FILE" 2>/dev/null | wc -l || echo "0")
                    ZONE_RECENT=$((ZONE_RECENT + RECENT_COUNT))
                fi
            fi
        done
        
        if [[ $ZONE_RECENT -gt 0 ]]; then
            echo -e "${GREEN}  $ZONE_RECENT${NC} recent entries - ${PURPLE}$ZONE_NAME${NC}"
        else
            echo -e "${YELLOW}  No recent activity${NC} - ${PURPLE}$ZONE_NAME${NC}"
        fi
    fi
done

# 7. Configuration Status  
echo -e "\n${BLUE}[7] Nested Configuration Status${NC}"
if [[ -f "/etc/rsyslog.d/70-nested-multitenant.conf" ]]; then
    print_status "Nested Config" "OK" "Active"
else
    print_status "Nested Config" "WARNING" "Not configured"
fi

# Check monitoring process
if pgrep -f "create-nested-dir.sh" > /dev/null; then
    print_status "Auto-Creation Monitor" "OK" "Running"
else
    print_status "Auto-Creation Monitor" "WARNING" "Not running"
fi

# 8. Tree Structure
echo -e "\n${BLUE}[8] Current Tree Structure${NC}"
echo "================================"
tree "$LOG_BASE" -d -L 3 2>/dev/null || {
    echo "Tree not available, using find:"
    find "$LOG_BASE" -type d | sort | sed 's/[^/]*\//  /g'
}

# 9. Quick Management Commands
echo -e "\n${BLUE}[9] Quick Management Commands${NC}"
echo "=============================================="
echo "📊 View specific zone/hotel logs:"

for zone_dir in "$LOG_BASE"/*; do
    if [[ -d "$zone_dir" && $(basename "$zone_dir") != "unknown" ]]; then
        ZONE_NAME=$(basename "$zone_dir")
        echo -e "${PURPLE}  # $ZONE_NAME hotels:${NC}"
        
        for hotel_dir in "$zone_dir"/*; do
            if [[ -d "$hotel_dir" ]]; then
                HOTEL_NAME=$(basename "$hotel_dir")
                echo "    tail -f $hotel_dir/$TODAY.log  # $HOTEL_NAME"
            fi
        done | head -3
        echo ""
    fi
done

echo "🔍 Analysis commands:"
echo "  find $LOG_BASE -name '*.log' -exec wc -l {} +     # All log counts"
echo "  grep -r 'srcnat' $LOG_BASE/*/\"*\"/$TODAY.log        # Search activity"
echo "  watch -n 30 ./monitor-nested-multitenant.sh      # Auto-refresh"

echo ""
echo "🔧 Configuration commands:"
echo "  sudo ./configure-nested-multitenant.sh           # Setup nested structure"
echo "  tail -f /var/log/nested-monitor.log              # Monitor auto-creation"
echo "  tree $LOG_BASE                                    # View full structure"

echo ""
echo -e "${GREEN}💡 Tip: Use 'watch -n 30 ./monitor-nested-multitenant.sh' for real-time nested monitoring!${NC}" 
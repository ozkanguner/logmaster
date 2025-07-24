#!/bin/bash

echo "📊 LogMaster Module 1.1: RSyslog Monitoring Dashboard"
echo "======================================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/var/log/rsyslog/messages"
ALERT_THRESHOLD=300  # 5 dakika

print_status() {
    if [[ $2 == "OK" ]]; then
        echo -e "${GREEN}✅ $1: $2${NC}"
    elif [[ $2 == "WARNING" ]]; then
        echo -e "${YELLOW}⚠️  $1: $3${NC}"
    else
        echo -e "${RED}❌ $1: $2${NC}"
    fi
}

# 1. RSyslog Service Status
echo -e "${BLUE}[1] RSyslog Service Status${NC}"
if systemctl is-active --quiet rsyslog; then
    print_status "RSyslog Service" "OK" "Active"
else
    print_status "RSyslog Service" "FAILED" "Not running"
fi

# 2. Port Status
echo -e "\n${BLUE}[2] Port Status${NC}"
if netstat -ulnp | grep -q ":514"; then
    print_status "UDP Port 514" "OK" "Listening"
else
    print_status "UDP Port 514" "FAILED" "Not listening"
fi

if netstat -tlnp | grep -q ":514"; then
    print_status "TCP Port 514" "OK" "Listening"
else
    print_status "TCP Port 514" "FAILED" "Not listening"
fi

# 3. Log File Status
echo -e "\n${BLUE}[3] Log File Status${NC}"
if [[ -f "$LOG_FILE" ]]; then
    LOG_SIZE=$(du -h "$LOG_FILE" | cut -f1)
    print_status "Log File" "OK" "Size: $LOG_SIZE"
else
    print_status "Log File" "FAILED" "Not found"
fi

# 4. Recent Logs Count
echo -e "\n${BLUE}[4] Recent Activity (Last 5 minutes)${NC}"
RECENT_LOGS=$(tail -1000 "$LOG_FILE" | grep "$(date '+%b %d %H:%M' -d '5 minutes ago')\|$(date '+%b %d %H:%M')" | wc -l)
if [[ $RECENT_LOGS -gt 0 ]]; then
    print_status "Recent Logs" "OK" "$RECENT_LOGS messages"
else
    print_status "Recent Logs" "WARNING" "No recent messages"
fi

# 5. Mikrotik Hotspot Logs
echo -e "\n${BLUE}[5] Mikrotik Hotspot Activity${NC}"
HOTSPOT_LOGS=$(tail -1000 "$LOG_FILE" | grep -i "hotspot\|SISLI_HOTSPOT\|FOURSIDES_HOTEL" | wc -l)
if [[ $HOTSPOT_LOGS -gt 0 ]]; then
    print_status "Hotspot Logs" "OK" "$HOTSPOT_LOGS recent messages"
else
    print_status "Hotspot Logs" "WARNING" "No hotspot activity"
fi

# 6. Last Log Time
echo -e "\n${BLUE}[6] Last Log Entry${NC}"
if [[ -f "$LOG_FILE" ]]; then
    LAST_LOG_TIME=$(tail -1 "$LOG_FILE" | awk '{print $1" "$2" "$3}')
    CURRENT_TIME=$(date '+%b %d %H:%M:%S')
    print_status "Last Entry" "OK" "$LAST_LOG_TIME"
else
    print_status "Last Entry" "FAILED" "No log file"
fi

# 7. Top Log Sources
echo -e "\n${BLUE}[7] Top Log Sources (Last 100 entries)${NC}"
echo "----------------------------------------"
tail -100 "$LOG_FILE" | awk '{print $4}' | sort | uniq -c | sort -nr | head -5 | while read count source; do
    echo -e "${GREEN}  $count${NC} messages from ${BLUE}$source${NC}"
done

# 8. Storage Space
echo -e "\n${BLUE}[8] Storage Status${NC}"
DISK_USAGE=$(df /var/log | tail -1 | awk '{print $5}' | sed 's/%//')
if [[ $DISK_USAGE -lt 80 ]]; then
    print_status "Disk Usage" "OK" "${DISK_USAGE}% used"
elif [[ $DISK_USAGE -lt 90 ]]; then
    print_status "Disk Usage" "WARNING" "${DISK_USAGE}% used"
else
    print_status "Disk Usage" "CRITICAL" "${DISK_USAGE}% used"
fi

# 9. Live Monitoring Option
echo -e "\n${BLUE}[9] Live Monitoring${NC}"
echo "=========================================="
echo "📊 Real-time commands:"
echo "  tail -f $LOG_FILE                    # Live log stream"
echo "  tail -f $LOG_FILE | grep -i hotspot  # Only hotspot logs"
echo "  watch -n 5 ./monitor.sh              # Auto-refresh dashboard"
echo ""
echo "🔧 Management commands:"
echo "  systemctl status rsyslog              # Service status"
echo "  systemctl restart rsyslog             # Restart service"
echo "  journalctl -u rsyslog -f              # Service logs"

echo ""
echo -e "${GREEN}💡 Tip: Run 'watch -n 10 ./monitor.sh' for auto-refresh monitoring!${NC}" 
#!/bin/bash
set -e

echo "🔧 LogMaster: Fixing Nested Multi-Tenant RSyslog Configuration"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Bu script root olarak çalıştırılmalı!" 
   exit 1
fi

echo "[STEP] Creating corrected nested RSyslog configuration..."

# Create corrected nested multi-tenant RSyslog configuration
cat > /etc/rsyslog.d/70-nested-multitenant.conf << 'EOF'
# LogMaster Nested Multi-Tenant Configuration - Fixed Version
# Zone/Hotel structure: ZONE/HOTEL/YYYY-MM-DD.log

# Templates for nested directory structure
template(name="NestedHotelLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:[0-9:]+ ([A-Z_]+[A-Z0-9_]*) --end%/%msg:R,ERE,1,FIELD:srcnat: in:([A-Z0-9_]+) out: --end%/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="DHCPLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:[0-9:]+ ([A-Z_]+[A-Z0-9_]*) --end%/dhcp/%$YEAR%-%$MONTH%-%$DAY%.log")

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

# Catch-all for unidentified sources
action(type="omfile" dynaFile="UnknownLogPath")
EOF

echo "[STEP] Testing RSyslog configuration..."
rsyslogd -N1

if [ $? -eq 0 ]; then
    echo "[SUCCESS] Configuration syntax is valid!"
    
    echo "[STEP] Restarting RSyslog..."
    systemctl restart rsyslog
    
    echo "[STEP] Checking service status..."
    systemctl status rsyslog --no-pager -l
    
    echo "[STEP] Sending test message..."
    echo "Jul 24 00:45:14 SISLI_HOTSPOT srcnat: in:TEST_HOTEL out:DT_MODEM, connection-state:new src-mac aa:bb:cc:dd:ee:ff, proto TCP" | nc -u localhost 514
    
    sleep 2
    
    echo "[STEP] Checking if nested structure is working..."
    find /var/log/rsyslog -name "*.log" -type f -mtime -1 | head -5
    
    echo ""
    echo "✅ Nested configuration fixed!"
    echo "📊 Run: ./monitor-nested-multitenant.sh"
    
else
    echo "[ERROR] Configuration syntax error! Check the config file."
    exit 1
fi 
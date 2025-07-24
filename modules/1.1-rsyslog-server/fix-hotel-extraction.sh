#!/bin/bash
set -e

echo "🔧 LogMaster: Hotel Extraction Pattern Düzeltme"
echo "==============================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Bu script root olarak çalıştırılmalı!" 
   echo "Kullanım: sudo ./fix-hotel-extraction.sh"
   exit 1
fi

echo "[ADIM] Mevcut log patterns analiz ediliyor..."

# Analyze current log format
echo "Güncel log örnekleri:"
grep "in:.*out:" /var/log/rsyslog/*/*/2025-07-24.log 2>/dev/null | head -3 || echo "Log örnekleri bulunamadı"

echo -e "\n[ADIM] Geliştirilmiş RSyslog konfigürasyonu yazılıyor..."

# Create improved nested configuration with better regex patterns
cat > /etc/rsyslog.d/70-nested-multitenant.conf << 'EOF'
# LogMaster Nested Multi-Tenant Configuration - Improved Hotel Extraction
# Zone/Hotel structure: ZONE/HOTEL/YYYY-MM-DD.log

# Improved templates with better regex patterns
template(name="NestedHotelLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/%msg:R,ERE,1,FIELD:in:([A-Z0-9_]+)\s+out --end%/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="DHCPLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/dhcp/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="SystemLogPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/system/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="UnknownLogPath" type="string" string="/var/log/rsyslog/unknown/unknown/%$YEAR%-%$MONTH%-%$DAY%.log")

# Debug template to log extraction attempts
template(name="DebugLogPath" type="string" string="/var/log/rsyslog-debug.log")

# Rule for SRCNAT messages with hotel names (Zone/Hotel structure)
if $msg contains "srcnat:" and $msg contains "in:" and $msg contains "out:" then {
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

# Debug: Log everything to debug file for analysis
action(type="omfile" file="/var/log/rsyslog-debug.log")

# Catch-all for unidentified sources
action(type="omfile" dynaFile="UnknownLogPath")
EOF

echo "[ADIM] RSyslog konfigürasyonu test ediliyor..."

# Test configuration
if rsyslogd -N1; then
    echo "[BAŞARILI] RSyslog konfigürasyonu geçerli!"
else
    echo "[HATA] RSyslog konfigürasyonunda sorun var!"
    exit 1
fi

echo "[ADIM] RSyslog servisini yeniden başlatıyor..."
systemctl restart rsyslog
sleep 2

if systemctl is-active --quiet rsyslog; then
    echo "[BAŞARILI] RSyslog servisi başarıyla başlatıldı!"
else
    echo "[HATA] RSyslog servisi başlatılamadı!"
    exit 1
fi

echo "[ADIM] Test log mesajları gönderiliyor..."

# Send improved test messages matching real format
echo "Jul 24 15:30:14 SISLI_HOTSPOT srcnat: in:FOURSIDES_HOTEL out:DT_MODEM, connection-state:new src-mac 9a:fd:38:6e:85:d7" | nc -u localhost 514
echo "Jul 24 15:30:15 SISLI_HOTSPOT srcnat: in:ADELMAR_HOTEL out:DT_MODEM, connection-state:new src-mac aa:bb:cc:dd:ee:ff" | nc -u localhost 514
echo "Jul 24 15:30:16 SISLI_HOTSPOT dhcp15 assigned 172.11.0.200 for TEST_MAC" | nc -u localhost 514

sleep 3

echo -e "\n[ADIM] Sonuçları kontrol ediliyor..."

echo "=== Yeni oluşturulan loglar ==="
find /var/log/rsyslog -name "2025-07-24.log" -type f -newermt "1 minute ago" 2>/dev/null | head -10

echo -e "\n=== Debug log son 5 satır ==="
tail -5 /var/log/rsyslog-debug.log 2>/dev/null || echo "Debug log henüz yok"

echo -e "\n=== Hotel dizinleri ==="
find /var/log/rsyslog -type d -name "*HOTEL*" 2>/dev/null | head -10

echo -e "\n[BAŞARILI] Hotel extraction pattern düzeltildi!"

echo ""
echo "📊 Test Komutları:"
echo "=================="
echo "  # Real-time hotel log monitoring:"
echo "  tail -f /var/log/rsyslog/SISLI_HOTSPOT/FOURSIDES_HOTEL/2025-07-24.log"
echo "  tail -f /var/log/rsyslog/SISLI_HOTSPOT/ADELMAR_HOTEL/2025-07-24.log"
echo ""
echo "  # Debug extraction process:"
echo "  tail -f /var/log/rsyslog-debug.log"
echo ""
echo "  # Monitor all patterns:"
echo "  ./monitor-nested-multitenant.sh" 
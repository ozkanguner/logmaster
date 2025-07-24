#!/bin/bash

echo "📊 LogMaster: Basit RSyslog Monitoring"
echo "====================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    if [[ $2 == "OK" ]]; then
        echo -e "${GREEN}✅ $1: $3${NC}"
    elif [[ $2 == "WARNING" ]]; then
        echo -e "${YELLOW}⚠️  $1: $3${NC}"
    else
        echo -e "${RED}❌ $1: $3${NC}"
    fi
}

# 1. System Status
echo -e "${BLUE}[1] Sistem Durumu${NC}"
if systemctl is-active --quiet rsyslog; then
    print_status "RSyslog Servisi" "OK" "Çalışıyor"
else
    print_status "RSyslog Servisi" "FAILED" "Durdurulmuş"
fi

if netstat -ulnp 2>/dev/null | grep -q ":514"; then
    print_status "UDP Port 514" "OK" "Dinliyor"
else
    print_status "UDP Port 514" "FAILED" "Dinlemiyor"
fi

if netstat -tlnp 2>/dev/null | grep -q ":514"; then
    print_status "TCP Port 514" "OK" "Dinliyor"
else
    print_status "TCP Port 514" "FAILED" "Dinlemiyor"
fi

# 2. Log File Status
echo -e "\n${BLUE}[2] Log Dosyası Durumu${NC}"
LOG_FILE="/var/log/rsyslog/all-messages.log"

if [[ -f "$LOG_FILE" ]]; then
    print_status "Log Dosyası" "OK" "Mevcut"
    
    # File size
    SIZE=$(ls -lh "$LOG_FILE" | awk '{print $5}')
    print_status "Dosya Boyutu" "OK" "$SIZE"
    
    # Line count
    LINES=$(wc -l < "$LOG_FILE")
    print_status "Satır Sayısı" "OK" "$LINES"
    
    # Last modification
    LAST_MOD=$(stat -c %y "$LOG_FILE" | cut -d'.' -f1)
    print_status "Son Güncelleme" "OK" "$LAST_MOD"
    
else
    print_status "Log Dosyası" "FAILED" "Bulunamadı"
fi

# 3. Recent Activity (Last 5 minutes)
echo -e "\n${BLUE}[3] Son 5 Dakika Aktivite${NC}"
if [[ -f "$LOG_FILE" ]]; then
    # Count messages in last 5 minutes
    FIVE_MIN_AGO=$(date -d '5 minutes ago' '+%b %d %H:%M')
    CURRENT_TIME=$(date '+%b %d %H:%M')
    
    RECENT_COUNT=$(grep -c "$FIVE_MIN_AGO\|$CURRENT_TIME" "$LOG_FILE" 2>/dev/null || echo "0")
    
    if [[ $RECENT_COUNT -gt 0 ]]; then
        print_status "Son 5 dk mesaj" "OK" "$RECENT_COUNT adet"
    else
        print_status "Son 5 dk mesaj" "WARNING" "Yok"
    fi
else
    print_status "Aktivite" "FAILED" "Log dosyası yok"
fi

# 4. Disk Usage
echo -e "\n${BLUE}[4] Disk Kullanımı${NC}"
DISK_USAGE=$(df -h /var/log | tail -1 | awk '{print $5}' | sed 's/%//')
if [[ $DISK_USAGE -lt 80 ]]; then
    print_status "Disk Kullanımı" "OK" "${DISK_USAGE}%"
elif [[ $DISK_USAGE -lt 90 ]]; then
    print_status "Disk Kullanımı" "WARNING" "${DISK_USAGE}%"
else
    print_status "Disk Kullanımı" "FAILED" "${DISK_USAGE}% - Kritik!"
fi

# 5. Recent Log Entries
echo -e "\n${BLUE}[5] Son Log Girişleri${NC}"
if [[ -f "$LOG_FILE" && -s "$LOG_FILE" ]]; then
    echo "==============================="
    tail -10 "$LOG_FILE" | while read line; do
        echo "$line"
    done
    echo "==============================="
else
    echo "Henüz log girişi yok"
fi

# 6. Connection Test
echo -e "\n${BLUE}[6] Bağlantı Testi${NC}"
echo "Test mesajı gönderiliyor..."
TEST_MSG="$(date '+%b %d %H:%M:%S') MONITOR-TEST Test connection from monitor script"
echo "$TEST_MSG" | nc -u localhost 514 2>/dev/null

sleep 2

# Check if test message appeared
if [[ -f "$LOG_FILE" ]] && grep -q "MONITOR-TEST" "$LOG_FILE"; then
    print_status "Bağlantı Testi" "OK" "Başarılı"
else
    print_status "Bağlantı Testi" "FAILED" "Başarısız"
fi

# 7. Source Analysis
echo -e "\n${BLUE}[7] Log Kaynak Analizi${NC}"
if [[ -f "$LOG_FILE" && -s "$LOG_FILE" ]]; then
    echo "En aktif kaynaklar (4. sütun):"
    echo "=============================="
    awk '{print $4}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -10 | while read count source; do
        echo "  $count adet - $source"
    done
else
    echo "Analiz için yeterli log yok"
fi

echo ""
echo "🔧 Faydalı Komutlar:"
echo "==================="
echo "# Canlı izleme:"
echo "tail -f /var/log/rsyslog/all-messages.log"
echo ""
echo "# Son 100 satır:"
echo "tail -100 /var/log/rsyslog/all-messages.log"
echo ""
echo "# Belirli kelime arama:"
echo "grep 'aranacak_kelime' /var/log/rsyslog/all-messages.log"
echo ""
echo "# Test mesajı gönder:"
echo "echo \"\$(date '+%b %d %H:%M:%S') TEST-HOST test message\" | nc -u localhost 514"
echo ""
echo "# Bu monitoring'i 30 saniyede bir çalıştır:"
echo "watch -n 30 ./monitor-basic.sh"

echo ""
echo "💡 İpucu: Loglar gelmeye başladığında, zone/hotel yapısına geçmek için 'configure-universal-multitenant.sh' scriptini çalıştırın!" 
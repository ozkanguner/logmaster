#!/bin/bash

echo "🏨 LogMaster 5651 Multi-Tenant Sistem İzleme"
echo "============================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_section() {
    echo -e "\n${BLUE}[${1}]${NC}"
    echo "$(printf '=%.0s' {1..50})"
}

print_status() {
    local service=$1
    local status=$(systemctl is-active $service 2>/dev/null)
    if [[ "$status" == "active" ]]; then
        echo -e "✅ $service: ${GREEN}$status${NC}"
    else
        echo -e "❌ $service: ${RED}$status${NC}"
    fi
}

print_section "1. SERVİS DURUMLARI"
print_status "rsyslog"
print_status "postgresql"
print_status "logmaster-5651-signer"
print_status "logmaster-dir-monitor"
print_status "logmaster-5651-web"
print_status "nginx"

print_section "2. PORTLAR"
echo "RSyslog UDP 514: $(netstat -ulpn 2>/dev/null | grep ':514 ' | wc -l) aktif"
echo "RSyslog TCP 514: $(netstat -tlpn 2>/dev/null | grep ':514 ' | wc -l) aktif"
echo "Web Interface: $(netstat -tlpn 2>/dev/null | grep ':8000 ' | wc -l) aktif"
echo "Nginx HTTP: $(netstat -tlpn 2>/dev/null | grep ':80 ' | wc -l) aktif"

print_section "3. LOG YAPISI"
if [[ -d "/var/log/rsyslog" ]]; then
    echo "📁 Mevcut Zone/Hotel yapısı:"
    tree /var/log/rsyslog/ -L 3 2>/dev/null || find /var/log/rsyslog/ -type d | head -20
else
    echo "❌ /var/log/rsyslog dizini bulunamadı"
fi

print_section "4. GÜNLÜK LOG AKTİVİTESİ"
TODAY=$(date '+%Y-%m-%d')
echo "📅 Bugünkü tarih: $TODAY"

if [[ -f "/var/log/rsyslog/unknown/unknown/$TODAY.log" ]]; then
    UNKNOWN_LINES=$(wc -l < "/var/log/rsyslog/unknown/unknown/$TODAY.log" 2>/dev/null || echo 0)
    echo "📥 Unknown loglar: $UNKNOWN_LINES satır"
    
    if [[ $UNKNOWN_LINES -gt 0 ]]; then
        echo "🔍 Son 3 unknown log:"
        tail -3 "/var/log/rsyslog/unknown/unknown/$TODAY.log" 2>/dev/null | sed 's/^/   /'
    fi
fi

# Check for hotel logs
HOTEL_LOGS=$(find /var/log/rsyslog/ -name "$TODAY.log" -path "*/*/HOTEL*" 2>/dev/null | wc -l)
echo "🏨 Hotel logları: $HOTEL_LOGS dosya"

# Check for zone logs
ZONE_LOGS=$(find /var/log/rsyslog/ -name "$TODAY.log" -not -path "*/unknown/*" 2>/dev/null | wc -l)
echo "🌍 Zone logları: $ZONE_LOGS dosya"

print_section "5. 5651 DIGITAL İMZALAMA"
echo "🔐 Sertifika durumu:"
if [[ -f "/opt/logmaster-5651/certs/5651_cert.pem" ]]; then
    echo "✅ 5651 sertifikası mevcut"
    CERT_EXPIRES=$(openssl x509 -in /opt/logmaster-5651/certs/5651_cert.pem -noout -enddate 2>/dev/null | cut -d= -f2)
    echo "📅 Sertifika bitiş: $CERT_EXPIRES"
else
    echo "❌ 5651 sertifikası bulunamadı"
fi

echo ""
echo "📊 İmza istatistikleri:"
if command -v psql >/dev/null 2>&1; then
    sudo -u postgres psql -d logmaster_5651 -t -c "
        SELECT 
            'Toplam imzalanan dosya: ' || COUNT(*),
            'Son 7 gün: ' || COUNT(*) FILTER (WHERE log_date >= CURRENT_DATE - INTERVAL '7 days'),
            'Toplam zone: ' || COUNT(DISTINCT zone_name)
        FROM log_signatures;
    " 2>/dev/null | grep -v "^$" | sed 's/^/   /'
    
    echo ""
    echo "🕒 Son imzalanan dosyalar:"
    sudo -u postgres psql -d logmaster_5651 -t -c "
        SELECT '   ' || zone_name || '/' || COALESCE(hotel_name, 'general') || ' - ' || log_date || ' (' || compliance_status || ')'
        FROM log_signatures 
        ORDER BY signed_at DESC 
        LIMIT 5;
    " 2>/dev/null | grep -v "^$"
fi

print_section "6. DİZİN MONİTÖR"
if [[ -f "/var/log/multitenant-monitor.log" ]]; then
    MONITOR_LINES=$(wc -l < "/var/log/multitenant-monitor.log" 2>/dev/null || echo 0)
    echo "📝 Monitor log: $MONITOR_LINES satır"
    
    if [[ $MONITOR_LINES -gt 0 ]]; then
        echo "🔍 Son 3 monitor aktivitesi:"
        tail -3 "/var/log/multitenant-monitor.log" 2>/dev/null | sed 's/^/   /'
    fi
else
    echo "❌ Monitor log dosyası bulunamadı"
fi

print_section "7. SİSTEM KAYNAKLAR"
echo "💾 Disk kullanımı (/var/log):"
df -h /var/log | tail -1 | awk '{print "   Kullanılan: " $3 " / " $2 " (" $5 ")"}'

echo ""
echo "🖥️  Memory kullanımı:"
free -h | grep "Mem:" | awk '{print "   RAM: " $3 " / " $2 " (" int($3/$2*100) "%)"}'

print_section "8. WEB ERİŞİM"
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "🌐 Web Dashboard: http://$SERVER_IP"
echo "🔍 API Health: http://$SERVER_IP/health"

# Test web interface
if command -v curl >/dev/null 2>&1; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/health" 2>/dev/null)
    if [[ "$HTTP_STATUS" == "200" ]]; then
        echo "✅ Web interface erişilebilir"
    else
        echo "❌ Web interface erişim hatası (HTTP $HTTP_STATUS)"
    fi
fi

print_section "9. TEST KOMUTU"
echo "🧪 Test log gönder:"
echo "   echo \"\$(date '+%b %d %H:%M:%S') TEST_ZONE srcnat: in:TEST_HOTEL out:DT_MODEM, connection-state:new\" | nc -u localhost 514"

echo ""
echo "🔧 Yönetim komutları:"
echo "   ./monitor-5651-system.sh  → Bu scripti tekrar çalıştır"
echo "   sudo systemctl restart logmaster-5651-signer  → İmzalama servisini yeniden başlat"
echo "   sudo systemctl restart logmaster-dir-monitor  → Dizin monitörünü yeniden başlat"

print_section "ÖZET"
if systemctl is-active rsyslog postgresql logmaster-5651-signer logmaster-5651-web >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Sistem sağlıklı çalışıyor!${NC}"
else
    echo -e "${RED}⚠️  Bazı servisler çalışmıyor, kontrol edin!${NC}"
fi

echo ""
echo -e "${YELLOW}💡 İpucu: Mikrotik cihazlarınızdan $SERVER_IP:514 adresine syslog gönderin${NC}" 
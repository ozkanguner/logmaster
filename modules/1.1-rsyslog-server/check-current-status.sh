#!/bin/bash

echo "🔍 LogMaster: Mevcut RSyslog Durumu Kontrolü"
echo "=============================================="

echo "[1] RSyslog servisi durumu:"
systemctl status rsyslog --no-pager -l

echo -e "\n[2] RSyslog portları:"
netstat -tulpn | grep 514

echo -e "\n[3] Mevcut log dosyaları:"
ls -la /var/log/rsyslog/ 2>/dev/null || echo "RSyslog log dizini bulunamadı"

echo -e "\n[4] Mevcut RSyslog konfigürasyonları:"
ls -la /etc/rsyslog.d/ | grep -E "(conf|disable)"

echo -e "\n[5] Son 5 dakikadaki log aktivitesi:"
if [ -f /var/log/rsyslog/messages ]; then
    echo "Toplam satır sayısı: $(wc -l < /var/log/rsyslog/messages)"
    echo "Son 5 log girişi:"
    tail -5 /var/log/rsyslog/messages
else
    echo "Ana log dosyası bulunamadı"
fi

echo -e "\n[6] Mikrotik log formatları (varsa):"
grep -n "srcnat\|hotspot\|dhcp" /var/log/rsyslog/* 2>/dev/null | head -5 || echo "Mikrotik logları bulunamadı" 
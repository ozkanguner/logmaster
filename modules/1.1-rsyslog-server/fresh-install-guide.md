# 🚀 LogMaster: Sıfırdan Ubuntu RSyslog Multi-Tenant Kurulum Rehberi

## 📋 Ön Hazırlık (Ubuntu Server 22.04 Kurulumu Sonrası)

### 1. Sistem Güncellemesi
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git tree net-tools curl wget
```

### 2. Git Ayarları
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 3. Firewall Ayarları (Opsiyonel)
```bash
sudo ufw allow ssh
sudo ufw allow 514/udp
sudo ufw allow 514/tcp
sudo ufw allow 6514/tcp
sudo ufw --force enable
```

---

## 🎯 RSyslog Multi-Tenant Kurulumu (3 Komut!)

### Adım 1: Repository Clone
```bash
cd /home/$USER
git clone https://github.com/ozkanguner/logmaster.git
cd logmaster/modules/1.1-rsyslog-server
```

### Adım 2: Native RSyslog Kurulumu
```bash
chmod +x install-native.sh
sudo ./install-native.sh
```

### Adım 3: Universal Multi-Tenant Yapısı
```bash
chmod +x configure-universal-multitenant.sh
sudo ./configure-universal-multitenant.sh
```

**O kadar! 🎉**

---

## 📊 Beklenen Sonuç

### Dizin Yapısı:
```
/var/log/rsyslog/
├── SISLI_HOTSPOT/          # Zone 1
│   ├── FOURSIDES_HOTEL/    # Hotel logları
│   ├── ADELMAR_HOTEL/      # Hotel logları  
│   ├── ATRO_HOTEL/         # Hotel logları
│   └── dhcp/               # DHCP logları
├── BEYOGLU_HOTSPOT/        # Zone 2 (otomatik)
│   ├── PREMIUM_HOTEL/      # Hotel logları
│   └── dhcp/               # DHCP logları  
├── ANKARA_ZONE/            # Zone 3 (otomatik)
│   └── general/            # Genel loglar
└── unknown/unknown/        # Bilinmeyen kaynaklar
```

### Log Dosyaları:
```
/var/log/rsyslog/SISLI_HOTSPOT/FOURSIDES_HOTEL/2025-01-24.log
/var/log/rsyslog/BEYOGLU_HOTSPOT/PREMIUM_HOTEL/2025-01-24.log
/var/log/rsyslog/universal-monitor.log (otomatik dizin oluşturma)
/var/log/rsyslog-zone-debug.log (debug logları)
```

---

## 🧪 Test Komutları

### Kurulum Testi:
```bash
# RSyslog durumu
sudo systemctl status rsyslog

# Portlar açık mı?
sudo netstat -tulpn | grep 514

# Dizin yapısı
tree /var/log/rsyslog/ -L 3
```

### Canlı İzleme:
```bash
# Monitoring dashboard
chmod +x monitor-nested-multitenant.sh
./monitor-nested-multitenant.sh

# Otomatik dizin oluşturma logları
tail -f /var/log/universal-monitor.log

# Debug logları
tail -f /var/log/rsyslog-zone-debug.log
```

### Manuel Test Logları:
```bash
# Farklı zone'lardan test mesajları
echo "$(date '+%b %d %H:%M:%S') SISLI_HOTSPOT srcnat: in:TEST_HOTEL out:DT_MODEM" | nc -u localhost 514
echo "$(date '+%b %d %H:%M:%S') BEYOGLU_HOTSPOT srcnat: in:PREMIUM_HOTEL out:FIBER" | nc -u localhost 514
echo "$(date '+%b %d %H:%M:%S') ANKARA_ZONE dhcp15 assigned 172.10.0.100" | nc -u localhost 514
```

---

## 🔧 Yönetim Komutları

### Log İzleme:
```bash
# Tüm zone'ları listele
find /var/log/rsyslog -maxdepth 1 -type d ! -name "rsyslog" ! -name "unknown"

# Belirli hotel logları
tail -f /var/log/rsyslog/SISLI_HOTSPOT/FOURSIDES_HOTEL/$(date '+%Y-%m-%d').log

# Tüm bugünkü logları say
find /var/log/rsyslog -name "$(date '+%Y-%m-%d').log" -exec wc -l {} +
```

### Servis Yönetimi:
```bash
# RSyslog restart
sudo systemctl restart rsyslog

# Otomatik monitör restart
sudo pkill -f "create-universal-dirs"
sudo nohup /usr/local/bin/create-universal-dirs.sh > /dev/null 2>&1 &
```

---

## ⚡ Hızlı Kurulum Scripti (Tek Komut)

Eğer çok hızlı kurmak istiyorsanız:

```bash
curl -fsSL https://raw.githubusercontent.com/ozkanguner/logmaster/main/modules/1.1-rsyslog-server/quick-install.sh | sudo bash
```

---

## 🎯 Özellikler

✅ **Universal Zone Support**: Herhangi bir zone adını otomatik tanır  
✅ **Auto Hotel Detection**: `srcnat: in:HOTEL_NAME` formatını otomatik bulur  
✅ **Daily Log Rotation**: Her gün ayrı dosya (YYYY-MM-DD.log)  
✅ **Real-time Directory Creation**: Yeni zone/hotel geldiğinde otomatik klasör  
✅ **Debug Support**: Pattern extraction sürecini izleyebilirsiniz  
✅ **5651 Compliant**: Yasal log saklama gereksinimleri  
✅ **High Performance**: 50,000+ EPS destekler  

---

## 📞 Destek

Kurulum sırasında sorun yaşarsanız:

1. **install-native.sh** loglarını paylaşın
2. **configure-universal-multitenant.sh** çıktısını paylaşın  
3. **systemctl status rsyslog** durumunu kontrol edin
4. **tail -f /var/log/universal-monitor.log** monitör durumunu kontrol edin

**Sonuç**: 3 komutla tamamen otomatik, evrensel multi-tenant RSyslog sistemi! 🚀 
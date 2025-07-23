# 🐧 Ubuntu Server'da LogMaster Modül 1.1 Kurulumu

## 📋 Ön Gereksinimler

### 1. Ubuntu Server Gereksinimleri
```bash
# Ubuntu 20.04+ LTS (Önerilen)
lsb_release -a
```

### 2. Docker Kurulumu
```bash
# Docker ve Docker Compose kurulumu
sudo apt update
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker

# Kullanıcıyı docker grubuna ekle
sudo usermod -aG docker $USER

# Oturumu yeniden başlat veya şunu çalıştır:
newgrp docker

# Docker kurulumunu test et
docker --version
docker compose version
```

### 3. Git Kurulumu
```bash
sudo apt install -y git curl
```

## 🚀 Modül 1.1 Kurulumu

### Adım 1: Repository Klonlama
```bash
# LogMaster repository'yi klonla
git clone https://github.com/ozkanguner/logmaster.git
cd logmaster

# Modül 1.1 dizinine git
cd modules/1.1-rsyslog-server

# Dosyaları listele
ls -la
```

### Adım 2: Script İzinlerini Ver
```bash
# Çalıştırma izinleri ver
chmod +x install.sh test.sh

# İzinleri kontrol et
ls -la *.sh
```

### Adım 3: Tek Komutla Kurulum
```bash
# Her şeyi otomatik kurar (12 adım)
./install.sh
```

**install.sh neler yapar:**
- ✅ Docker prerequisite kontrolü
- ✅ Dockerfile oluşturma  
- ✅ RSyslog config dosyaları
- ✅ SSL sertifika scripti
- ✅ Docker Compose yapılandırması
- ✅ Firewall kuralları (UFW)
- ✅ Docker build ve start
- ✅ Health check ve validation

### Adım 4: Kapsamlı Test
```bash
# 20 farklı test senaryosu çalıştır
./test.sh
```

**test.sh test kategorileri:**
- ✅ Container health & process checks (5 test)
- ✅ Network & Security (5 test)  
- ✅ Functional Tests (5 test)
- ✅ Advanced Validation (5 test)

## 🔍 Kurulum Doğrulama

### Container Durumu
```bash
# Çalışan container'ları gör
docker ps

# RSyslog container logları
docker logs rsyslog-server-1.1

# Container istatistikleri
docker stats rsyslog-server-1.1 --no-stream
```

### Port Kontrolü
```bash
# Dinlenen portları kontrol et
sudo netstat -tulpn | grep ":514\|:6514"

# UFW durumu
sudo ufw status
```

### Log Testi
```bash
# UDP test mesajı gönder
echo "TEST: Ubuntu deployment $(date)" | nc -u localhost 514

# TCP test mesajı gönder  
echo "TEST: Ubuntu TCP test $(date)" | nc localhost 514

# Logları kontrol et
docker exec rsyslog-server-1.1 tail -10 /var/log/rsyslog/messages
```

## 🧪 Başarı Kriterleri

Modül 1.1 başarıyla çalışıyorsa:

✅ `docker ps` - Container RUNNING durumda  
✅ `./test.sh` - Tüm 20 test PASS  
✅ Portlar dinleniyor: 514/udp, 514/tcp, 6514/tcp  
✅ Log mesajları alınıp kaydediliyor  
✅ SSL/TLS sertifikaları çalışıyor  
✅ Health check başarılı  

## 🔧 Yönetim Komutları

```bash
# Container'ı durdur
docker-compose down

# Container'ı yeniden başlat
docker-compose restart

# Logları canlı izle
docker logs rsyslog-server-1.1 -f

# Container içine gir
docker exec -it rsyslog-server-1.1 bash

# Tamamen yeniden kur
docker-compose down
./install.sh
```

## 🔄 Sonraki Modül

Modül 1.1 başarıyla test edildikten sonra:

```bash
# Ana dizine dön
cd ../../

# Yeni modül branch'ı oluştur
git checkout -b module-1.2-tenant-database-schema

# Modül 1.2 klasörü oluştur
mkdir -p modules/1.2-tenant-database-schema
cd modules/1.2-tenant-database-schema

# Modül 1.2 dosyalarını oluştur
touch install.sh test.sh README.md
chmod +x install.sh test.sh
```

## 🚨 Sorun Giderme

### Docker Problems
```bash
# Docker servisi durumu
sudo systemctl status docker

# Docker restart
sudo systemctl restart docker

# Docker logs
sudo journalctl -u docker
```

### Port Sorunları
```bash
# Port kullanımını kontrol et
sudo lsof -i :514
sudo lsof -i :6514

# UFW reset (gerekirse)
sudo ufw --force reset
sudo ufw enable
```

### Container Sorunları
```bash
# Tüm container'ları göster
docker ps -a

# Container silme
docker rm -f rsyslog-server-1.1

# Image silme  
docker rmi logmaster/rsyslog-server:1.1

# Yeniden kurulum
./install.sh
```

---

**LogMaster Modül 1.1** - Ubuntu Server Deployment
🔗 **Repository:** https://github.com/ozkanguner/logmaster 
# LogMaster Deployment Rehberi

Ubuntu sunucunuzda LogMaster'ı GitHub'dan çekip kurmak için bu rehberi takip edin.

## Hızlı Kurulum

### 1. Repository'i GitHub'a Yüklemek

```bash
# GitHub'da yeni bir repository oluşturun (örn: logmaster)
# Sonra projeyi push edin:

git init
git add .
git commit -m "Initial LogMaster commit"
git branch -M main
git remote add origin https://github.com/KULLANICI_ADI/logmaster.git
git push -u origin main
```

### 2. Ubuntu Sunucuda Otomatik Kurulum

```bash
# Ubuntu sunucunuzda
wget https://raw.githubusercontent.com/KULLANICI_ADI/logmaster/main/deploy/ubuntu-install.sh
chmod +x ubuntu-install.sh

# Basit kurulum
./ubuntu-install.sh

# Domain ile kurulum
./ubuntu-install.sh --domain example.com --email admin@example.com

# Özel repository ile kurulum
./ubuntu-install.sh --repo https://github.com/SIZIN_KULLANICI_ADI/logmaster.git
```

### 3. Manuel Docker Kurulumu

```bash
# Repository'i klonlayın
git clone https://github.com/KULLANICI_ADI/logmaster.git
cd logmaster

# Docker Compose ile çalıştırın
docker-compose up -d

# Web arayüzüne erişin
# http://SUNUCU_IP (Kullanıcı: admin, Şifre: logmaster2024)
```

## Detaylı Kurulum Adımları

### Sistem Gereksinimleri

- Ubuntu 20.04+ LTS
- 4GB+ RAM
- 50GB+ disk alanı
- Docker ve Docker Compose
- İnternet bağlantısı

### 1. Sunucu Hazırlığı

```bash
# Sistem güncellemesi
sudo apt update && sudo apt upgrade -y

# Gerekli araçlar
sudo apt install -y git curl wget unzip
```

### 2. Docker Kurulumu

```bash
# Docker kurulum scripti
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Kullanıcıyı docker grubuna ekle
sudo usermod -aG docker $USER

# Docker Compose kurulumu
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Yeniden giriş yapın veya:
newgrp docker
```

### 3. LogMaster Kurulumu

```bash
# LogMaster repository'sini klonlayın
cd /opt
sudo git clone https://github.com/KULLANICI_ADI/logmaster.git
sudo chown -R $USER:$USER logmaster
cd logmaster

# Konfigürasyon ayarları
cp config/main.conf.example config/main.conf
nano config/main.conf  # Ayarları düzenleyin

# Ortam değişkenlerini ayarlayın
cat > .env << EOF
DB_PASSWORD=GuvenliBirSifre123!
LOGMASTER_ENV=production
DOMAIN=logmaster.example.com
SSL_EMAIL=admin@example.com
EOF

# Servisleri başlatın
docker-compose up -d
```

### 4. İlk Konfigürasyon

```bash
# Servislerin durumunu kontrol edin
docker-compose ps

# Logları kontrol edin
docker-compose logs

# Web arayüzünü test edin
curl http://localhost/health
```

## GitHub Actions ile Otomatik Deployment

### 1. GitHub Secrets Ayarlama

Repository → Settings → Secrets → Actions'a gidin ve şunları ekleyin:

```
PRODUCTION_HOST=sunucu_ip_adresi
PRODUCTION_USER=ubuntu
PRODUCTION_SSH_KEY=ssh_private_key_icerigi
STAGING_HOST=staging_sunucu_ip
STAGING_USER=ubuntu
STAGING_SSH_KEY=staging_ssh_private_key
SLACK_WEBHOOK=slack_webhook_url (opsiyonel)
```

### 2. SSH Anahtarı Hazırlığı

```bash
# Yerel makinenizde SSH anahtarı oluşturun
ssh-keygen -t rsa -b 4096 -C "logmaster-deploy"

# Public key'i sunucuya kopyalayın
ssh-copy-id ubuntu@SUNUCU_IP

# Private key'i GitHub Secret olarak ekleyin
cat ~/.ssh/id_rsa  # Bu içeriği PRODUCTION_SSH_KEY olarak ekleyin
```

### 3. Sunucuyu Deployment için Hazırlayın

```bash
# Sunucuda LogMaster kullanıcısı oluşturun
sudo useradd -r -s /bin/bash -d /opt/logmaster -m logmaster
sudo usermod -aG docker logmaster

# Deployment dizinini hazırlayın
sudo mkdir -p /opt/logmaster
sudo chown logmaster:logmaster /opt/logmaster

# İlk deployment için repository'i klonlayın
cd /opt
sudo -u logmaster git clone https://github.com/KULLANICI_ADI/logmaster.git
```

## Güvenlik Ayarları

### 1. Firewall Konfigürasyonu

```bash
# UFW firewall kuralları
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 514/udp  # Syslog
```

### 2. SSL Sertifikası (Let's Encrypt)

```bash
# Certbot kurulumu
sudo apt install -y certbot python3-certbot-nginx

# Domain için sertifika al
sudo certbot --nginx -d logmaster.example.com

# Otomatik yenileme
sudo crontab -e
# Şu satırı ekleyin:
# 0 12 * * * /usr/bin/certbot renew --quiet
```

### 3. Güvenlik Sıkılaştırması

```bash
# Varsayılan şifreleri değiştirin
nano config/main.conf

# Database şifresi
nano .env

# Fail2ban kurulumu (opsiyonel)
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
```

## Yönetim Komutları

### Temel Komutlar

```bash
# Servis durumu
docker-compose ps

# Logları görüntüle
docker-compose logs -f

# Servisi yeniden başlat
docker-compose restart

# Günceleme
git pull
docker-compose pull
docker-compose up -d
```

### Özel LogMaster Komutları

```bash
# Durum raporu
logmaster-status

# Sistem güncellemesi
logmaster-update

# Yedekleme
logmaster-backup

# Systemd servis yönetimi
sudo systemctl start/stop/restart logmaster
```

## Yedekleme ve Kurtarma

### Otomatik Yedekleme

```bash
# Günlük yedekleme scripti (cron ile)
/usr/local/bin/logmaster-backup

# Manuel yedekleme
docker-compose exec postgres pg_dump -U logmaster logmaster > backup.sql
tar -czf config-backup.tar.gz config/
tar -czf logs-backup.tar.gz signed/
```

### Kurtarma

```bash
# Veritabanı kurtarma
docker-compose exec -T postgres psql -U logmaster logmaster < backup.sql

# Konfigürasyon kurtarma
tar -xzf config-backup.tar.gz

# Log dosyaları kurtarma
tar -xzf logs-backup.tar.gz
```

## İzleme ve Performans

### Sistem İzleme

```bash
# Docker stats
docker stats

# Disk kullanımı
df -h /opt/logmaster

# Log boyutları
du -sh /opt/logmaster/logs/*
```

### Performans Optimizasyonu

```bash
# Log rotasyonu ayarları
nano config/main.conf

# Docker container limitleri
nano docker-compose.yml
```

## Sorun Giderme

### Yaygın Sorunlar

1. **Veritabanı bağlantı hatası**
   ```bash
   docker-compose logs postgres
   docker-compose restart postgres
   ```

2. **Web arayüzü erişim sorunu**
   ```bash
   docker-compose logs nginx
   docker-compose logs logmaster
   ```

3. **Log toplama çalışmıyor**
   ```bash
   # Syslog port kontrolü
   sudo netstat -tulpn | grep 514
   docker-compose logs logmaster-collector
   ```

4. **Disk alanı sorunu**
   ```bash
   # Eski logları temizle
   find /opt/logmaster/logs -name "*.log" -mtime +30 -delete
   
   # Docker temizliği
   docker system prune -a
   ```

### Log Dosyaları

- Web arayüzü: `/var/log/logmaster/web.log`
- Log collector: `/var/log/logmaster/collector.log`
- Digital signer: `/var/log/logmaster/signer.log`
- Nginx: `/var/log/logmaster/nginx.log`

### Destek

- GitHub Issues: https://github.com/KULLANICI_ADI/logmaster/issues
- Wiki: https://github.com/KULLANICI_ADI/logmaster/wiki
- E-posta: support@example.com

## Güncellemeler

### Manuel Güncelleme

```bash
cd /opt/logmaster
git pull
docker-compose pull
docker-compose up -d
```

### Otomatik Güncelleme

GitHub Actions workflow'u main branch'e her push'da otomatik deployment yapar.

## Lisans ve Uyumluluk

Bu sistem 5651 sayılı kanun gerekliliklerine uygun olarak tasarlanmıştır:

- Loglar 2 yıl saklanır
- Dijital imzalama zorunludur
- Erişim logları tutulur
- Uyumluluk raporları otomatik oluşturulur

**Önemli:** Prodüksiyon ortamında mutlaka güvenlik ayarlarını gözden geçirin ve varsayılan şifreleri değiştirin. 
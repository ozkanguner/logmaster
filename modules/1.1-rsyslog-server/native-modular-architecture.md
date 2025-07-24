# 🏗️ LogMaster: Native Modüler Yapı (Docker'sız)

## ⚠️ Docker Sorunları Çözüldü!

Docker kurulumunda yaşanan problemler nedeniyle **native servisler** ile modüler yapı kuruyoruz.

---

## 🎯 NATIVE MODÜLER MİMARİ

### Mevcut Durum:
```
Ubuntu Server (basic-install.sh)
└── RSyslog (/var/log/rsyslog/all-messages.log)
```

### Hedef Native Modüler Yapı:
```
Ubuntu Server
├── RSyslog Service (Log Collection)
├── PostgreSQL Service (Database)  
├── Elasticsearch Service (Search)
├── Nginx + FastAPI (Web Interface)
├── Grafana Service (Monitoring)
└── Custom Python Services (Processing)
```

---

## 📦 NATIVE SERVİSLER KURULUM PLANI

### 1. Log Collection Layer (Mevcut)
```bash
# Zaten çalışıyor - basic-install.sh ile kuruldu
- RSyslog service (systemd)
- Port 514 UDP/TCP
- /var/log/rsyslog/all-messages.log
```

### 2. Database Layer 
```bash
# PostgreSQL native kurulum
sudo apt install postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

# LogMaster database oluştur
sudo -u postgres createdb logmaster
sudo -u postgres createuser logmaster_user
```

### 3. Search Layer
```bash
# Elasticsearch native kurulum (Debian paketi)
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt update && sudo apt install elasticsearch

# Systemd service
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
```

### 4. Web Application Layer
```bash
# Python + FastAPI + Nginx native kurulum
sudo apt install python3-pip nginx
pip3 install fastapi uvicorn sqlalchemy psycopg2-binary

# Custom FastAPI app
# React frontend (build to static files)
# Nginx reverse proxy
```

### 5. Monitoring Layer
```bash
# Grafana native kurulum
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update && sudo apt install grafana

# Prometheus native kurulum
sudo apt install prometheus

# Systemd services
sudo systemctl enable grafana-server prometheus
sudo systemctl start grafana-server prometheus
```

---

## 🔧 ADIM ADIM NATIVE KURULUM

### Adım 1: Database Setup
```bash
# PostgreSQL kurulum ve konfigürasyon
sudo ./setup-database.sh
```

### Adım 2: Search Engine Setup  
```bash
# Elasticsearch kurulum
sudo ./setup-elasticsearch.sh
```

### Adım 3: Web Application Setup
```bash
# FastAPI + React frontend
sudo ./setup-web-app.sh
```

### Adım 4: Monitoring Setup
```bash
# Grafana + Prometheus
sudo ./setup-monitoring.sh
```

### Adım 5: Log Processing Setup
```bash
# Python log processor service
sudo ./setup-log-processor.sh
```

---

## 📊 NATIVE SERVİS MİMARİSİ

### Port Dağılımı:
```
514      → RSyslog (UDP/TCP)
5432     → PostgreSQL  
9200     → Elasticsearch
8000     → FastAPI API
80/443   → Nginx (Web Frontend)
3000     → Grafana
9090     → Prometheus
```

### Systemd Services:
```bash
# Tüm servisler systemd ile yönetiliyor
sudo systemctl status rsyslog           # Log collection
sudo systemctl status postgresql        # Database
sudo systemctl status elasticsearch     # Search
sudo systemctl status logmaster-api     # API (custom)
sudo systemctl status logmaster-processor # Log processor (custom)  
sudo systemctl status nginx             # Web server
sudo systemctl status grafana-server    # Monitoring
sudo systemctl status prometheus        # Metrics
```

### Avantajları:
✅ **Docker dependency yok** - Sadece native Ubuntu paketleri
✅ **Systemd integration** - Otomatik başlatma, restart
✅ **Performance** - Native services daha hızlı
✅ **Debugging** - Standard Linux tools kullanılabilir
✅ **Resource control** - Her servis systemd ile kontrol edilebilir
✅ **Security** - AppArmor, firewall kolayca uygulanabilir

### Dezavantajları:
❌ **Manuel kurulum** - Her servis ayrı kurulmalı
❌ **Dependency management** - Paket çakışmaları olabilir
❌ **Backup complexity** - Her servisin ayrı backup stratejisi

---

## 🚀 HANGİ ADIMLARI YAPALIM?

### Seçenek A: Minimal Başlangıç (1-2 saat)
```bash
# Sadece temel web interface ekle
1. PostgreSQL kurulumu
2. Basit FastAPI uygulaması  
3. Nginx reverse proxy
4. Basic web dashboard
```

### Seçenek B: Orta Seviye (1 gün)
```bash
# Arama ve monitoring ekle
1. PostgreSQL + Elasticsearch
2. FastAPI + React frontend
3. Grafana monitoring
4. Log search functionality
```

### Seçenek C: Full Enterprise (2-3 gün)
```bash
# Tüm bileşenler
1. Tüm native servisler
2. Custom log processor
3. Advanced monitoring
4. API documentation
5. User management
6. 5651 compliance reporting
```

---

## 🎯 ÖNERİM: Seçenek A ile Başlayalım

**Mevcut basic RSyslog'unuzu bozmadan, yanına web interface ekleyelim:**

```bash
# 1. PostgreSQL ekle (metadata için)
sudo ./add-database.sh

# 2. Basit web dashboard ekle
sudo ./add-web-interface.sh  

# 3. Test et
http://SUNUCU_IP  → Web Dashboard
UDP 514           → Log Collection (değişmez)
```

**Bu size şunu verecek:**
- ✅ Mevcut RSyslog çalışmaya devam eder
- ✅ Web'den log görüntüleme
- ✅ Basit filtreleme/arama
- ✅ Kullanıcı yönetimi
- ✅ 5651 compliance raporları

**Hangisini tercih ediyorsunuz?** Size o seçenek için implementasyon scriptleri hazırlayayım! 

Veya şu anlık **sadece mevcut basic kurulumunuzu test etmeyi** mi tercih edersiniz? (Loglar gelmeye başladıktan sonra modülerleştiririz) 
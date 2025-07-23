# LogMaster v2 - Multi-Tenant Hotel Chain Log Management

## 🏨 **Otel Zincirleri İçin Özel Log Yönetim Sistemi**

**LogMaster v2** - Türkiye 5651 Sayılı Kanun uyumlu, **multi-tenant** yapı ile **1000+ events/second** performansı.

[![🏨 Multi-Tenant](https://img.shields.io/badge/Architecture-Multi--Tenant-blue)](https://github.com/ozkanguner/5651-logging-v2)
[![⚡ Performance](https://img.shields.io/badge/Performance-1000%2B%20EPS-green)](https://github.com/ozkanguner/5651-logging-v2)
[![⚖️ 5651 Uyumlu](https://img.shields.io/badge/Compliance-5651%20Law-red)](https://github.com/ozkanguner/5651-logging-v2)
[![📡 Mikrotik](https://img.shields.io/badge/Devices-Mikrotik%20Ready-orange)](https://github.com/ozkanguner/5651-logging-v2)

## 🎯 **Temel Özellikler**

### 🏨 **Multi-Tenant Hotel Management**
- **Hotel Chain Support** - Merkezi zincir yönetimi
- **Perfect Data Isolation** - Her otel verisi tamamen ayrı
- **Role-Based Access** - Chain Admin vs Hotel Manager
- **Self-Service Device Management** - Her otel kendi cihazlarını ekler

### ⚡ **High Performance**
- **1000+ Events/Second** - Garantili yüksek performans
- **Real-time Processing** - Gerçek zamanlı log işleme
- **Scalable Architecture** - Kolayca büyüyebilir
- **Optimized Storage** - Hotel bazlı partitioning

### ⚖️ **5651 Turkish Law Compliance**
- **Daily Digital Signatures** - RSA-256 günlük imzalama
- **TSA Timestamping** - Yasal geçerli zaman damgası
- **2+ Years Retention** - Uzun süreli arşivleme
- **Audit Trail** - Tam aktivite izleme

### 📡 **Mikrotik Integration**
- **RouterOS Support** - Tam Mikrotik uyumluluğu
- **Auto-Discovery** - Otomatik cihaz bulma
- **SNMP/SSH/API** - Çoklu bağlantı yöntemleri
- **Performance Monitoring** - Cihaz durumu izleme

## 🏗️ **System Architecture**

### **Multi-Tenant Flow**
```
🏨 Hotel A (192.168.1.0/24) → 📡 Syslog Collector → 🏨 Hotel Router → 💾 Hotel A Data
🏨 Hotel B (192.168.2.0/24) → 📡 Syslog Collector → 🏨 Hotel Router → 💾 Hotel B Data  
🏨 Hotel C (192.168.3.0/24) → 📡 Syslog Collector → 🏨 Hotel Router → 💾 Hotel C Data
```

### **Technology Stack**
```yaml
Backend:
  - Python 3.11+ (FastAPI)
  - PostgreSQL 15 (Multi-tenant)
  - Elasticsearch 8 (Search)
  - Redis 7 (Cache)

Frontend:
  - React 18 + TypeScript
  - Real-time WebSocket
  - Responsive design

Infrastructure:
  - Docker + Docker Compose
  - Nginx (Reverse proxy)
  - Prometheus + Grafana (Monitoring)
```

## 🚀 **Quick Start**

### **1. Requirements**
```bash
# Minimum requirements
CPU: 16 cores
RAM: 64GB
Storage: 2TB SSD
Network: 1Gbps

# Recommended
CPU: 32 cores  
RAM: 128GB
Storage: 4TB NVMe SSD
Network: 10Gbps
```

### **2. Installation**
```bash
# Clone repository
git clone https://github.com/ozkanguner/5651-logging-v2.git
cd 5651-logging-v2

# Setup environment
cp .env.example .env
nano .env  # Configure your settings

# Start services
docker-compose up -d

# Check status
docker-compose ps
```

### **3. Access**
- **Web Dashboard**: http://localhost
- **API Documentation**: http://localhost/api/docs
- **Grafana Monitoring**: http://localhost:3001

### **4. Default Users**
```yaml
Chain Admin:
  Username: chain_admin
  Password: admin123
  Access: All hotels

Hotel Manager (Istanbul):
  Username: istanbul_manager  
  Password: hotel123
  Access: Istanbul hotel only
```

## 🏨 **Hotel Management Guide**

### **Chain Admin (Zincir Yöneticisi)**
```python
# Yeni otel ekleme
POST /api/hotels
{
    "name": "Bursa Grand Hotel",
    "code": "BUR-001", 
    "subnet_range": "192.168.4.0/24"
}

# Otel yöneticisi oluşturma
POST /api/users
{
    "hotel_id": "hotel-bursa-uuid",
    "username": "bursa_manager",
    "email": "mgr@bursa.com",
    "role": "hotel_manager"
}
```

### **Hotel Manager (Otel Yöneticisi)**
```python
# Mikrotik cihaz ekleme
POST /api/devices
{
    "name": "Bursa Router",
    "ip_address": "192.168.4.1",
    "mac_address": "DD:EE:FF:AA:BB:01",
    "device_type": "router"
}

# Kendi otelinin loglarını görme
GET /api/logs?hotel_id=current_user_hotel
```

## 📊 **Performance Metrics**

### **Capacity Planning**
| Hotel Count | Devices | Events/Sec | Storage/Month | Users |
|-------------|---------|------------|---------------|-------|
| **1-5** | 25 | 500 | 50GB | 10 |
| **5-10** | 50 | 1000 | 100GB | 20 |
| **10-20** | 100 | 2000 | 200GB | 40 |
| **20+** | 200+ | 5000+ | 500GB+ | 100+ |

### **Real Performance Example**
```yaml
Istanbul Hotel:
  Devices: 15 (Router, Switch, APs)
  Events/Second: 350
  Storage/Month: 35GB
  Users: 8

Ankara Hotel:  
  Devices: 12
  Events/Second: 280
  Storage/Month: 28GB
  Users: 6

Total Chain:
  Hotels: 3
  Devices: 35
  Events/Second: 750
  Storage/Month: 85GB
  Users: 18
```

## ⚖️ **5651 Compliance Features**

### **Daily Compliance Process**
```python
# Her gün otomatik çalışır
def daily_compliance():
    for hotel in get_all_hotels():
        # 1. Günlük log dosyası oluştur
        daily_file = f"/logs/{hotel.id}/{today}.log"
        
        # 2. SHA-256 hash hesapla
        file_hash = calculate_sha256(daily_file)
        
        # 3. RSA-256 ile imzala
        signature = rsa_sign(file_hash, private_key)
        
        # 4. TSA'dan zaman damgası al
        timestamp = get_tsa_timestamp(file_hash)
        
        # 5. Compliance kaydı oluştur
        save_compliance_record(hotel, file_hash, signature, timestamp)
```

### **Legal Export**
```bash
# Hotel bazlı yasal export
curl -X POST http://localhost/api/compliance/export \
  -H "Content-Type: application/json" \
  -d '{
    "hotel_id": "hotel-istanbul-uuid",
    "start_date": "2024-01-01", 
    "end_date": "2024-01-31",
    "format": "legal_5651"
  }'
```

## 🔐 **Security Features**

### **Multi-Tenant Security**
- **Complete Data Isolation** - Oteller birbirini göremez
- **IP-based Hotel Detection** - Subnet bazlı otomatik routing
- **Role-based Access Control** - Kullanıcı yetkilerine göre erişim
- **Encrypted Storage** - Sensitive veriler şifreli
- **Audit Logging** - Tüm aktiviteler loglanır

### **Device Security**
- **MAC Address Validation** - Cihaz kimlik doğrulama
- **IP Range Verification** - Subnet kontrolü
- **Auto Device Registration** - Güvenli cihaz ekleme
- **SNMP Community Security** - Güvenli SNMP erişimi

## 📈 **Monitoring & Alerts**

### **Real-time Dashboard**
- **Live Log Stream** - Gerçek zamanlı log akışı
- **Hotel Performance** - Otel bazlı metrikler
- **Device Status** - Cihaz durumu izleme
- **Error Tracking** - Hata takibi ve alertler

### **Performance Alerts**
```yaml
Critical Alerts:
  - Events/second < 100 for 5 minutes
  - Storage usage > 90%
  - Device offline > 10 minutes
  - Compliance signature failure

Warning Alerts:
  - Events/second < 500 for 10 minutes
  - Queue depth > 1000
  - High error rate > 1%
```

## 🛠️ **Configuration**

### **Environment Variables**
```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/logmaster
REDIS_URL=redis://localhost:6379
ELASTICSEARCH_URL=http://localhost:9200

# Security
JWT_SECRET_KEY=your-secret-key
RSA_PRIVATE_KEY_PATH=/keys/private.pem
TSA_URL=http://tsa.example.com

# Performance
MAX_EVENTS_PER_SECOND=1000
BATCH_SIZE=100
WORKER_COUNT=4

# Compliance
RETENTION_YEARS=2
DAILY_SIGNING_TIME=02:00
COMPLIANCE_EMAIL=compliance@company.com
```

### **Docker Compose Configuration**
```yaml
version: '3.8'
services:
  logmaster-api:
    image: logmaster/api:latest
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
    ports:
      - "8000:8000"
    volumes:
      - ./logs:/logs
      - ./keys:/keys

  logmaster-syslog:
    image: logmaster/syslog:latest
    ports:
      - "514:514/udp"
    environment:
      - REDIS_URL=${REDIS_URL}

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
```

## 📚 **Documentation**

### **API Documentation**
- **Interactive API Docs**: `/api/docs` (Swagger)
- **API Schema**: `/api/openapi.json`
- **Postman Collection**: `docs/postman/`

### **Architecture Documentation**
- **System Overview**: `docs/architecture/system-overview.md`
- **Data Flow**: `docs/architecture/data-flow.md`
- **Database Schema**: `docs/architecture/database-schema.md`

### **Deployment Guides**
- **Single Server Setup**: `docs/deployment/single-server.md`
- **High Performance Setup**: `docs/deployment/high-performance.md`
- **Production Deployment**: `docs/deployment/production.md`

## 🤝 **Support & Contributing**

### **Community**
- **Issues**: [GitHub Issues](https://github.com/ozkanguner/5651-logging-v2/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ozkanguner/5651-logging-v2/discussions)
- **Wiki**: [Project Wiki](https://github.com/ozkanguner/5651-logging-v2/wiki)

### **Commercial Support**
- **Professional Services**: setup@logmaster.com
- **Enterprise Support**: enterprise@logmaster.com
- **Training**: training@logmaster.com

## 📄 **License**

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🎯 **Perfect For:**

✅ **Hotel Chains** - Multi-location management  
✅ **Network Operators** - High-volume log processing  
✅ **Compliance Teams** - 5651 Turkish Law requirements  
✅ **Mikrotik Users** - RouterOS integration  
✅ **MSPs** - Managed service providers  

**LogMaster v2 - Sade, güçlü ve uyumlu!** 🚀 
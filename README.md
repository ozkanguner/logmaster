# LogMaster v2 - Enterprise 5651 Compliance Log Management System

![LogMaster v2](https://img.shields.io/badge/LogMaster-v2.0-blue.svg)
![License](https://img.shields.io/badge/License-Enterprise-green.svg)
![Python](https://img.shields.io/badge/Python-3.8+-brightgreen.svg)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-blue.svg)
![Performance](https://img.shields.io/badge/Performance-10K%20events%2Fsec-brightgreen.svg)

## 🚀 High-Performance Enterprise Log Management

**LogMaster v2** - Türkiye 5651 Sayılı Kanun uyumlu, **saniyede 10,000+ event** işleyebilen enterprise log yönetim sistemi.

### 🏨 **Multi-Tenant Hotel Chain Management**

LogMaster v2, **otel zincirleri** için özel olarak tasarlanmış **multi-tenant** yapıya sahiptir:

- 🏢 **Hotel Chain Support** - Merkezi zincir yönetimi
- 🏨 **Hotel Isolation** - Her otel için ayrı veri alanı  
- 👨‍💼 **Hotel Managers** - Sadece kendi otellerini yönetebilir
- 📡 **Mikrotik Integration** - RouterOS cihazları için özel destek
- 🔐 **Device Ownership** - Her otel kendi cihazlarını ekleyebilir

### 📡 **Mikrotik Device Support**

**Desteklenen Mikrotik Cihazları:**
- ✅ RouterOS v7+ routers (CCR, RB series)
- ✅ CRS series switches
- ✅ CAP series access points  
- ✅ Cloud Router Switch (CRS)
- ✅ SNMP + SSH + API log collection
- ✅ Auto-discovery ve device registration

### 🔐 **Role-Based Multi-Tenancy**

| Role | Erişim Seviyesi | Permissions |
|------|----------------|-------------|
| **Chain Admin** | Tüm oteller | Zincir yönetimi, tüm otellere erişim |
| **Hotel Manager** | Tek otel | Kendi otelini yönetir, cihaz ekleyebilir |
| **Hotel Viewer** | Tek otel | Sadece görüntüleme yetkisi |
| **Device Admin** | Cihaz seviyesi | Mikrotik cihaz konfigürasyonu |

### ⚡ Performance Targets by Architecture

| Architecture | Events/Second | Server Count | Monthly Cost | Complexity |
|--------------|---------------|--------------|--------------|------------|
| **MVP** | 1K-2K | 1 | $500-1K | Very Simple ⭐ |
| **Single Server HP** | **10K+** | **1** (Powerful) | **$3.5K-4.5K** | **Simple** 💰⭐ |
| **Multi-Server HP** | 10K+ | 15+ | $8K-12K | Complex |
| **Enterprise** | 50K+ | 50+ | $25K+ | Very Complex |

### 🏗️ **System Architecture Options**

#### 💻 Single Server High-Performance (RECOMMENDED)
```
🐧 Ubuntu Server (64 cores, 256GB RAM)
├── 📡 3x UDP Syslog Receivers (Port 514,515,516)
├── ⚡ 4x Parallel Log Workers (AsyncIO)
├── 🔍 Elasticsearch (Single node, 32GB heap)
├── 🐘 PostgreSQL (Enterprise config)
├── ⚡ Redis Cluster (Queue + Cache)
├── 🚀 4x FastAPI APIs (Load balanced)
├── 🌐 Nginx (Reverse proxy)
├── ⚛️ React Frontend
└── 📊 Prometheus + Grafana monitoring
```

**✅ Advantages:**
- **65% Cost Savings** vs multi-server
- **10 minute deployment** with Docker Compose
- **Simple management** - Single system
- **Low latency** - No network overhead

## 🚀 Enterprise Features

### 🔐 Advanced Security
- **MAC Address Authentication**: Device-level security with MAC-based registration
- **JWT + RBAC**: Role-based access control with granular permissions
- **Device-Specific Permissions**: Users can only access authorized devices
- **Time/IP Restrictions**: Access control by time windows and IP ranges
- **Digital Signatures**: RSA-256 + TSA timestamping for all logs

### ⚖️ 5651 Turkish Law Compliance
- **2-Year Retention**: Automatic log retention with legal compliance
- **Digital Signing**: All logs digitally signed and timestamped
- **Audit Trail**: Complete user activity tracking
- **Court-Ready Exports**: Legal format exports for court proceedings
- **Automated Reports**: Monthly compliance reports

### 🏗️ Enterprise Architecture
- **FastAPI Backend**: Modern Python async API framework
- **React Frontend**: Professional web interface
- **Multi-Database**: PostgreSQL + Elasticsearch + Redis
- **Monitoring**: Grafana + Prometheus integration
- **Containerized**: Full Docker deployment

## 📁 Project Structure

```
5651-logging-v2/
├── backend/                    # FastAPI Backend
│   ├── app/
│   │   ├── api/v1/            # API endpoints
│   │   ├── auth/              # Authentication & authorization
│   │   ├── compliance/        # 5651 compliance engine
│   │   ├── core/              # Core configurations
│   │   ├── models/            # Database models
│   │   ├── schemas/           # Pydantic schemas
│   │   └── services/          # Business logic
│   ├── alembic/               # Database migrations
│   └── tests/                 # Backend tests
├── frontend/                  # React Frontend
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── pages/             # Page components
│   │   ├── services/          # API services
│   │   └── utils/             # Utilities
│   └── public/                # Static files
├── deployment/                # Deployment configs
│   ├── docker/                # Docker files
│   ├── scripts/               # Deployment scripts
│   └── config/                # Configuration files
├── infrastructure/            # Infrastructure configs
│   ├── postgresql/            # PostgreSQL setup
│   ├── elasticsearch/         # Elasticsearch config
│   ├── redis/                 # Redis configuration
│   └── grafana/              # Monitoring setup
└── docs/                     # Documentation
    ├── api/                  # API documentation
    └── deployment/           # Deployment guides
```

## 🛡️ Security Features

### Device Authentication
- MAC address based device registration
- Device groups and hierarchical permissions
- Device status tracking (active/inactive/pending)
- Automatic device discovery and approval workflow

### User Authorization
- **Admin**: Full system access
- **Network Manager**: Network device access
- **Security Analyst**: Security log access only
- **Location Manager**: Location-specific access
- **Device Owner**: Specific device access
- **Viewer**: Read-only access

### Access Control Matrix
| Role | View Logs | Export | Delete | Configure | Real-time | Archives |
|------|-----------|---------|---------|-----------|-----------|----------|
| Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Network Manager | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Security Analyst | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
| Location Manager | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ |
| Device Owner | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Viewer | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

## 📋 System Requirements

### Production Environment
- **OS**: Ubuntu 22.04 LTS
- **Python**: 3.8+
- **Node.js**: 16+
- **Memory**: 16GB RAM minimum
- **Storage**: 1TB SSD (for logs)
- **Network**: Gigabit Ethernet

### Database Requirements
- **PostgreSQL**: 13+ (Metadata & Users)
- **Elasticsearch**: 8+ (Log search & analytics)
- **Redis**: 6+ (Sessions & cache)

### External Dependencies
- **TSA Service**: Time Stamp Authority for compliance
- **LDAP/AD**: Optional enterprise authentication
- **SMTP Server**: Email notifications

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/ozkanguner/5651-logging-v2.git
cd 5651-logging-v2
```

### 2. Environment Setup
```bash
cp deployment/config/.env.example .env
# Edit .env with your settings
```

### 3. Docker Deployment
```bash
docker-compose up -d
```

### 4. Initialize Database
```bash
./scripts/init-database.sh
./scripts/create-admin-user.sh
```

### 5. Access Web Interface
- **Web UI**: http://your-server:80
- **API Docs**: http://your-server/api/docs
- **Grafana**: http://your-server:3000

## 🔧 Configuration

### Device Registration
```python
# Register new device
POST /api/v1/devices/register
{
    "mac_address": "AA:BB:CC:DD:EE:01",
    "device_name": "Aksaray-Hotspot-01",
    "location": "Aksaray Meydanı",
    "device_type": "firewall"
}
```

### User Permissions
```python
# Grant device permission to user
POST /api/v1/admin/device-permissions
{
    "user_id": "user-uuid",
    "device_id": "device-uuid",
    "permissions": {
        "can_view_logs": true,
        "can_export_logs": true,
        "access_start_time": "08:00",
        "access_end_time": "18:00"
    }
}
```

## 📊 Monitoring & Analytics

### Grafana Dashboards
- System Health Overview
- Log Volume Metrics
- Device Status Dashboard
- User Activity Analytics
- 5651 Compliance Reports

### Prometheus Metrics
- Log ingestion rate
- Storage usage
- API response times
- Authentication failures
- Compliance violations

## ⚖️ Legal Compliance (5651)

### Automatic Features
- ✅ 2-year log retention
- ✅ Digital signature verification
- ✅ User activity audit logs
- ✅ Court-ready export formats
- ✅ Monthly compliance reports
- ✅ Data integrity verification

### Manual Processes
- Device registration approval
- User permission management
- Compliance report review
- Legal export generation

## 🐳 Docker Deployment

### Services
- **logmaster-backend**: FastAPI application
- **logmaster-frontend**: React web interface
- **postgresql**: User & metadata database
- **elasticsearch**: Log search engine
- **redis**: Session & cache store
- **grafana**: Monitoring dashboard
- **prometheus**: Metrics collection

### Volumes
- `logs-data`: Raw log files
- `postgres-data`: Database files
- `elastic-data`: Elasticsearch data
- `grafana-data`: Dashboard configs

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest tests/ -v --cov=app
```

### Frontend Tests
```bash
cd frontend
npm test
```

### Integration Tests
```bash
./scripts/run-integration-tests.sh
```

## 📚 API Documentation

### Authentication Endpoints
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Token refresh
- `POST /api/v1/auth/logout` - User logout

### Device Management
- `GET /api/v1/devices` - List devices
- `POST /api/v1/devices/register` - Register device
- `PUT /api/v1/devices/{id}` - Update device
- `DELETE /api/v1/devices/{id}` - Remove device

### Log Management
- `GET /api/v1/logs/search` - Search logs
- `GET /api/v1/logs/export` - Export logs
- `GET /api/v1/devices/{mac}/logs` - Device logs

### User Management
- `GET /api/v1/users` - List users
- `POST /api/v1/users` - Create user
- `PUT /api/v1/users/{id}` - Update user
- `POST /api/v1/admin/device-permissions` - Grant permissions

### Compliance
- `GET /api/v1/compliance/report` - Generate report
- `GET /api/v1/compliance/violations` - List violations
- `POST /api/v1/compliance/verify` - Verify signatures

## 🔒 Security Considerations

### Network Security
- TLS 1.3 encryption
- VPN access recommended
- Firewall rules included
- Intrusion detection ready

### Data Security
- AES-256 encryption at rest
- RSA-256 digital signatures
- Key rotation policies
- Secure key management

### Application Security
- SQL injection protection
- XSS prevention
- CSRF protection
- Rate limiting
- Input validation

## 🆘 Support & Maintenance

### Log Rotation
- Daily log rotation
- Compression after 7 days
- Archive after 30 days

## 📖 Comprehensive Documentation

### 🏗️ System Architecture
- **[System Overview](docs/architecture/system-overview.md)** - Complete system architecture with 4 deployment options
- **[Data Flow](docs/architecture/data-flow.md)** - High-performance data processing pipeline  
- **[Database Schema](docs/architecture/database-schema.md)** - PostgreSQL and Elasticsearch schemas
- **[Security & Permissions](docs/architecture/security-permissions.md)** - RBAC and device-level security
- **[Production Deployment](docs/architecture/deployment-production.md)** - Enterprise deployment guide

### 🚀 Quick Start Options

#### Option 1: Single Server High-Performance (RECOMMENDED) 💰
```bash
# Ubuntu 22.04 LTS with 64 cores, 256GB RAM
git clone https://github.com/ozkanguner/5651-logging-v2.git /opt/logmaster
cd /opt/logmaster
sudo ./deploy/ubuntu-single-server-hp.sh
```
**Result:** 10,000+ events/second, $3.5K-4.5K/month

#### Option 2: MVP Development
```bash
git clone https://github.com/ozkanguner/5651-logging-v2.git
cd 5651-logging-v2
docker-compose up -d
```
**Result:** 1,000-2,000 events/second, $500-1K/month

#### Option 3: Multi-Server Enterprise
See [Production Deployment Guide](docs/architecture/deployment-production.md)
**Result:** 10,000+ events/second with HA, $8K-12K/month

## 🎯 Architecture Decision Matrix

| Requirement | MVP | Single Server HP ⭐ | Multi-Server HP | Enterprise |
|-------------|-----|-------------------|----------------|------------|
| **Budget < $5K/month** | ✅ | ✅ | ❌ | ❌ |
| **10K+ events/sec** | ❌ | ✅ | ✅ | ✅ |
| **99.9%+ uptime** | ❌ | ❌ | ✅ | ✅ |
| **Simple management** | ✅ | ✅ | ❌ | ❌ |
| **Quick deployment** | ✅ | ✅ | ❌ | ❌ |
| **High availability** | ❌ | ❌ | ✅ | ✅ |

## 📞 Contact & Support

- **Documentation**: [GitHub Wiki](https://github.com/ozkanguner/5651-logging-v2/wiki)
- **Issues**: [GitHub Issues](https://github.com/ozkanguner/5651-logging-v2/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ozkanguner/5651-logging-v2/discussions)

## 📜 License

This project is licensed under the Enterprise License - see the [LICENSE](LICENSE) file for details.

---

**🚀 Ready to process 10,000+ events per second with enterprise-grade log management?**

**Start with Single Server High-Performance:** `docker-compose up -d` 
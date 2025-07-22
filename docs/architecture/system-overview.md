# LogMaster v2 - System Architecture Overview

## 🏗️ Enterprise Architecture

LogMaster v2 is designed as a multi-tier, microservices-based enterprise log management system with granular device-level permissions and full 5651 Turkish Law compliance.

## 📊 System Architecture Diagram

```mermaid
graph TB
    subgraph "USER LAYER"
        U1["👤 Admin Users"]
        U2["👨‍💻 Network Managers"]
        U3["🔍 Security Analysts"]
        U4["📍 Location Managers"]
        U5["👁️ Viewers"]
    end
    
    subgraph "WEB LAYER"
        WEB["🌐 Nginx Reverse Proxy<br/>Port 80/443"]
        UI["⚛️ React Frontend<br/>Port 3000"]
    end
    
    subgraph "API LAYER"
        API["🚀 FastAPI Backend<br/>Port 8000"]
        AUTH["🔐 JWT Authentication"]
        RBAC["👥 Role-Based Access Control"]
        PERM["🎯 Device Permissions"]
    end
    
    subgraph "BUSINESS LOGIC"
        LOG_PROC["📊 Log Processing Engine"]
        SIGN["✍️ Digital Signature Engine"]
        COMP["⚖️ 5651 Compliance Engine"]
        DEVICE["📱 Device Management"]
        AUDIT["📋 Audit Trail System"]
    end
    
    subgraph "DATA LAYER"
        PG["🐘 PostgreSQL<br/>User Data & Metadata"]
        ES["🔍 Elasticsearch<br/>Log Search & Analytics"]
        REDIS["⚡ Redis<br/>Sessions & Cache"]
    end
    
    subgraph "LOG COLLECTION"
        SYSLOG["📡 Syslog Receiver<br/>Port 514 UDP"]
        BEAT["📤 Filebeat Collector"]
        PARSER["🔄 Log Parser & Enricher"]
    end
    
    subgraph "EXTERNAL DEVICES"
        FW1["🔥 Firewall Device 1<br/>MAC: AA:BB:CC:01"]
        FW2["🔥 Firewall Device 2<br/>MAC: AA:BB:CC:02"]
        FWN["🔥 Firewall Device N<br/>MAC: AA:BB:CC:NN"]
    end
    
    subgraph "MONITORING"
        PROM["📊 Prometheus<br/>Metrics Collection"]
        GRAF["📈 Grafana<br/>Dashboards & Alerts"]
    end
    
    subgraph "STORAGE"
        LOGS["📁 Log Files<br/>/var/log/logmaster/"]
        ARCH["📦 Archives<br/>Compressed & Signed"]
        BACKUP["💾 Backups<br/>/backup/logmaster/"]
    end
    
    U1 --> WEB
    U2 --> WEB
    U3 --> WEB
    U4 --> WEB
    U5 --> WEB
    
    WEB --> UI
    WEB --> API
    
    UI --> API
    API --> AUTH
    AUTH --> RBAC
    RBAC --> PERM
    
    API --> LOG_PROC
    API --> SIGN
    API --> COMP
    API --> DEVICE
    API --> AUDIT
    
    LOG_PROC --> PG
    LOG_PROC --> ES
    SIGN --> PG
    COMP --> PG
    DEVICE --> PG
    AUDIT --> PG
    
    API --> REDIS
    
    FW1 --> SYSLOG
    FW2 --> SYSLOG
    FWN --> SYSLOG
    
    SYSLOG --> BEAT
    BEAT --> PARSER
    PARSER --> ES
    PARSER --> LOGS
    
    LOGS --> SIGN
    SIGN --> ARCH
    ARCH --> BACKUP
    
    API --> PROM
    PROM --> GRAF
    
    classDef userLayer fill:#e1f5fe
    classDef webLayer fill:#f3e5f5
    classDef apiLayer fill:#e8f5e8
    classDef businessLayer fill:#fff3e0
    classDef dataLayer fill:#fce4ec
    classDef deviceLayer fill:#f1f8e9
    classDef monitorLayer fill:#e0f2f1
    classDef storageLayer fill:#fafafa
    
    class U1,U2,U3,U4,U5 userLayer
    class WEB,UI webLayer
    class API,AUTH,RBAC,PERM apiLayer
    class LOG_PROC,SIGN,COMP,DEVICE,AUDIT businessLayer
    class PG,ES,REDIS dataLayer
    class FW1,FW2,FWN,SYSLOG,BEAT,PARSER deviceLayer
    class PROM,GRAF monitorLayer
    class LOGS,ARCH,BACKUP storageLayer
```

## 🔧 Architecture Components

### 👥 User Layer
- **Admin Users**: Full system access and management
- **Network Managers**: Network device management and configuration
- **Security Analysts**: Security log analysis and incident response
- **Location Managers**: Location-specific device and log access
- **Viewers**: Read-only access to authorized logs

### 🌐 Web Layer
- **Nginx Reverse Proxy**: Load balancing, SSL termination, static content
- **React Frontend**: Modern, responsive web interface

### 🚀 API Layer
- **FastAPI Backend**: High-performance async Python API
- **JWT Authentication**: Secure token-based authentication
- **RBAC**: Role-based access control system
- **Device Permissions**: Granular device-level access control

### 🏗️ Business Logic Layer
- **Log Processing Engine**: Real-time log parsing and enrichment
- **Digital Signature Engine**: RSA-256 + TSA compliance
- **5651 Compliance Engine**: Turkish law compliance automation
- **Device Management**: MAC-based device registration and monitoring
- **Audit Trail System**: Comprehensive activity logging

### 🗄️ Data Layer
- **PostgreSQL**: Relational data (users, devices, permissions, metadata)
- **Elasticsearch**: Log search, analytics, and real-time indexing
- **Redis**: Session management, caching, and real-time data

### 📡 Log Collection Layer
- **Syslog Receiver**: UDP port 514 for remote log collection
- **Filebeat Collector**: File-based log collection and forwarding
- **Log Parser & Enricher**: Structured log processing and metadata extraction

### 📊 Monitoring Layer
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Dashboards, visualization, and alert management

### 💾 Storage Layer
- **Log Files**: Raw log storage with device-specific organization
- **Archives**: Compressed and digitally signed historical logs
- **Backups**: Automated backup and disaster recovery

## 🔐 Security Features

### Authentication & Authorization
- JWT-based authentication with refresh tokens
- Multi-factor authentication support
- LDAP/Active Directory integration
- Session management with timeout controls

### Device-Level Security
- MAC address-based device authentication
- Device registration and approval workflow
- Per-device user permission matrix
- Time and IP-based access restrictions

### Data Protection
- Digital signatures for all log files (RSA-256)
- Time stamp authority (TSA) integration
- End-to-end encryption for sensitive data
- Secure key management and rotation

## ⚖️ 5651 Compliance Features

### Legal Requirements
- 2-year minimum log retention
- Digital signature verification
- Complete audit trail maintenance
- Court-ready export formats

### Automated Compliance
- Daily digital signing of log files
- Monthly compliance report generation
- Automated violation detection
- Legal export format generation

## 📈 Scalability & Performance

### Horizontal Scaling
- Microservices architecture with Docker
- Load-balanced web and API tiers
- Elasticsearch cluster for log search
- PostgreSQL read replicas

### Performance Optimization
- Redis caching for frequent queries
- Elasticsearch indexing for fast search
- Asynchronous processing with FastAPI
- Connection pooling and optimization

### High Availability
- Multi-instance deployment
- Database replication
- Automated health checks
- Graceful failover mechanisms

## 🚀 Deployment Architecture

The system supports both single-server and distributed deployments:

- **Development**: Single Docker Compose setup
- **Production**: Multi-tier deployment with load balancing
- **Enterprise**: Clustered deployment with disaster recovery

For detailed deployment information, see [Deployment Guide](../deployment/README.md). 
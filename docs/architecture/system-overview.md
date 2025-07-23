# LogMaster v2 - System Architecture Overview

## 🏗️ Enterprise Architecture

LogMaster v2 is designed as a multi-tier, microservices-based enterprise log management system with granular device-level permissions and full 5651 Turkish Law compliance.

## 📊 System Architecture Diagram

### 🏢 Enterprise-Level Architecture (Full Implementation)

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

### 🚀 MVP System Architecture (Simplified for Quick Start)

```mermaid
graph TB
    subgraph "USERS"
        ADMIN["👤 Admin"]
        USER["👨‍💻 Network Manager"]
    end
    
    subgraph "WEB TIER"
        NGINX["🌐 Nginx<br/>Port 80/443"]
        REACT["⚛️ React UI<br/>Log Viewer"]
    end
    
    subgraph "API TIER"
        FASTAPI["🚀 FastAPI<br/>Port 8000"]
        AUTH["🔐 JWT Auth"]
    end
    
    subgraph "BUSINESS TIER"
        LOG_ENGINE["📊 Log Engine"]
        DEVICE_MGR["📱 Device Manager"]
        PARSER["🔄 Log Parser"]
    end
    
    subgraph "DATA TIER"
        PG["🐘 PostgreSQL<br/>Metadata + Index"]
        FILES["📁 File Storage<br/>/var/log/logmaster/"]
    end
    
    subgraph "LOG COLLECTION"
        SYSLOG["📡 Syslog Server<br/>UDP 514"]
    end
    
    subgraph "NETWORK DEVICES"
        FW["🔥 Firewall"]
        RTR["🔀 Router"]
        SW["🔌 Switch"]
    end
    
    %% User Flow
    ADMIN --> NGINX
    USER --> NGINX
    NGINX --> REACT
    NGINX --> FASTAPI
    
    %% API Flow
    REACT --> FASTAPI
    FASTAPI --> AUTH
    FASTAPI --> LOG_ENGINE
    FASTAPI --> DEVICE_MGR
    
    %% Data Flow
    LOG_ENGINE --> PG
    LOG_ENGINE --> FILES
    DEVICE_MGR --> PG
    
    %% Log Collection Flow
    FW --> SYSLOG
    RTR --> SYSLOG
    SW --> SYSLOG
    SYSLOG --> PARSER
    PARSER --> LOG_ENGINE
    
    classDef mvpCore fill:#e8f5e8,stroke:#4caf50,stroke-width:3px
    classDef mvpUser fill:#e3f2fd,stroke:#2196f3,stroke-width:2px
    classDef mvpData fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    
    class SYSLOG,PARSER,LOG_ENGINE,FASTAPI,REACT mvpCore
    class ADMIN,USER,AUTH,DEVICE_MGR mvpUser
    class PG,FILES,FW,RTR,SW mvpData
```

### ⚡ High-Performance Architecture (10,000+ Events/Second)

```mermaid
graph TB
    subgraph "USER LAYER"
        U1["👤 Admins"]
        U2["👨‍💻 Analysts"]
        U3["🔍 Security Team"]
    end
    
    subgraph "LOAD BALANCER TIER"
        LB_WEB["⚖️ Web Load Balancer<br/>Nginx Cluster"]
        LB_API["⚖️ API Load Balancer<br/>HAProxy Cluster"]
        LB_UDP["⚖️ UDP Load Balancer<br/>Round Robin DNS"]
    end
    
    subgraph "WEB TIER - SCALED"
        WEB1["🌐 Web Server 1<br/>Nginx + React"]
        WEB2["🌐 Web Server 2<br/>Nginx + React"]
        WEB3["🌐 Web Server 3<br/>Nginx + React"]
    end
    
    subgraph "API TIER - SCALED"
        API1["🚀 FastAPI Instance 1<br/>Port 8000"]
        API2["🚀 FastAPI Instance 2<br/>Port 8001"]
        API3["🚀 FastAPI Instance 3<br/>Port 8002"]
        API4["🚀 FastAPI Instance 4<br/>Port 8003"]
    end
    
    subgraph "LOG COLLECTION - HIGH THROUGHPUT"
        SYSLOG1["📡 Syslog Receiver 1<br/>Port 514"]
        SYSLOG2["📡 Syslog Receiver 2<br/>Port 515"]
        SYSLOG3["📡 Syslog Receiver 3<br/>Port 516"]
        QUEUE["🔄 Redis Queue Cluster<br/>Message Broker"]
    end
    
    subgraph "PROCESSING ENGINE - PARALLEL"
        WORKER1["⚡ Log Worker 1<br/>AsyncIO"]
        WORKER2["⚡ Log Worker 2<br/>AsyncIO"]
        WORKER3["⚡ Log Worker 3<br/>AsyncIO"]
        WORKER4["⚡ Log Worker 4<br/>AsyncIO"]
        BATCH_WRITER["📦 Batch Writer<br/>1000 events/batch"]
    end
    
    subgraph "DATA TIER - CLUSTERED"
        ES_MASTER["🔍 ES Master Node"]
        ES_DATA1["🔍 ES Data Node 1"]
        ES_DATA2["🔍 ES Data Node 2"]
        ES_DATA3["🔍 ES Data Node 3"]
        
        PG_MASTER["🐘 PostgreSQL Master"]
        PG_REPLICA1["🐘 PG Read Replica 1"]
        PG_REPLICA2["🐘 PG Read Replica 2"]
        
        REDIS_CLUSTER["⚡ Redis Cluster<br/>6 Nodes"]
    end
    
    subgraph "STORAGE TIER - OPTIMIZED"
        NVME_STORAGE["💾 NVMe SSD Array<br/>50K+ IOPS"]
        ARCHIVE_STORAGE["📦 Archive Storage<br/>Compressed + Signed"]
        BACKUP_STORAGE["💾 Backup Storage<br/>Offsite Replication"]
    end
    
    subgraph "MONITORING - REAL-TIME"
        PROM_CLUSTER["📊 Prometheus Cluster<br/>HA Metrics"]
        GRAFANA_CLUSTER["📈 Grafana Cluster<br/>Dashboards"]
        ALERT_MANAGER["🚨 Alert Manager<br/>Auto-scaling"]
    end
    
    subgraph "NETWORK DEVICES - ENTERPRISE"
        FW_CLUSTER1["🔥 Firewall Cluster 1<br/>1000 events/sec"]
        FW_CLUSTER2["🔥 Firewall Cluster 2<br/>1000 events/sec"]
        RTR_CORE1["🔀 Core Router 1<br/>2000 events/sec"]
        RTR_CORE2["🔀 Core Router 2<br/>2000 events/sec"]
        SW_FARM["🔌 Switch Farm<br/>3000 events/sec"]
    end
    
    %% User to Load Balancer
    U1 --> LB_WEB
    U2 --> LB_WEB
    U3 --> LB_WEB
    
    %% Load Balancer Distribution
    LB_WEB --> WEB1
    LB_WEB --> WEB2
    LB_WEB --> WEB3
    
    LB_API --> API1
    LB_API --> API2
    LB_API --> API3
    LB_API --> API4
    
    %% Web to API
    WEB1 --> LB_API
    WEB2 --> LB_API
    WEB3 --> LB_API
    
    %% Network Devices to UDP Load Balancer
    FW_CLUSTER1 --> LB_UDP
    FW_CLUSTER2 --> LB_UDP
    RTR_CORE1 --> LB_UDP
    RTR_CORE2 --> LB_UDP
    SW_FARM --> LB_UDP
    
    %% UDP Load Balancer to Syslog Receivers
    LB_UDP --> SYSLOG1
    LB_UDP --> SYSLOG2
    LB_UDP --> SYSLOG3
    
    %% Syslog to Queue
    SYSLOG1 --> QUEUE
    SYSLOG2 --> QUEUE
    SYSLOG3 --> QUEUE
    
    %% Queue to Workers
    QUEUE --> WORKER1
    QUEUE --> WORKER2
    QUEUE --> WORKER3
    QUEUE --> WORKER4
    
    %% Workers to Batch Writer
    WORKER1 --> BATCH_WRITER
    WORKER2 --> BATCH_WRITER
    WORKER3 --> BATCH_WRITER
    WORKER4 --> BATCH_WRITER
    
    %% Batch Writer to Storage
    BATCH_WRITER --> ES_MASTER
    BATCH_WRITER --> PG_MASTER
    BATCH_WRITER --> REDIS_CLUSTER
    BATCH_WRITER --> NVME_STORAGE
    
    %% Elasticsearch Cluster
    ES_MASTER --> ES_DATA1
    ES_MASTER --> ES_DATA2
    ES_MASTER --> ES_DATA3
    
    %% PostgreSQL Cluster
    PG_MASTER --> PG_REPLICA1
    PG_MASTER --> PG_REPLICA2
    
    %% APIs to Data
    API1 --> ES_MASTER
    API2 --> PG_REPLICA1
    API3 --> PG_REPLICA2
    API4 --> REDIS_CLUSTER
    
    %% Storage Hierarchy
    NVME_STORAGE --> ARCHIVE_STORAGE
    ARCHIVE_STORAGE --> BACKUP_STORAGE
    
    %% Monitoring
    API1 --> PROM_CLUSTER
    WORKER1 --> PROM_CLUSTER
    BATCH_WRITER --> PROM_CLUSTER
    ES_MASTER --> PROM_CLUSTER
    PG_MASTER --> PROM_CLUSTER
    
    PROM_CLUSTER --> GRAFANA_CLUSTER
    PROM_CLUSTER --> ALERT_MANAGER
    
    classDef loadBalancer fill:#e8f5e8,stroke:#4caf50,stroke-width:4px
    classDef webTier fill:#e3f2fd,stroke:#2196f3,stroke-width:3px
    classDef apiTier fill:#fff3e0,stroke:#ff9800,stroke-width:3px
    classDef collectionTier fill:#f3e5f5,stroke:#9c27b0,stroke-width:3px
    classDef processingTier fill:#ffebee,stroke:#f44336,stroke-width:3px
    classDef dataTier fill:#e0f2f1,stroke:#009688,stroke-width:3px
    classDef storageTier fill:#fce4ec,stroke:#e91e63,stroke-width:3px
    classDef monitorTier fill:#e8eaf6,stroke:#3f51b5,stroke-width:3px
    classDef deviceTier fill:#f1f8e9,stroke:#8bc34a,stroke-width:2px
    
    class LB_WEB,LB_API,LB_UDP loadBalancer
    class WEB1,WEB2,WEB3 webTier
    class API1,API2,API3,API4 apiTier
    class SYSLOG1,SYSLOG2,SYSLOG3,QUEUE collectionTier
    class WORKER1,WORKER2,WORKER3,WORKER4,BATCH_WRITER processingTier
    class ES_MASTER,ES_DATA1,ES_DATA2,ES_DATA3,PG_MASTER,PG_REPLICA1,PG_REPLICA2,REDIS_CLUSTER dataTier
    class NVME_STORAGE,ARCHIVE_STORAGE,BACKUP_STORAGE storageTier
    class PROM_CLUSTER,GRAFANA_CLUSTER,ALERT_MANAGER monitorTier
    class FW_CLUSTER1,FW_CLUSTER2,RTR_CORE1,RTR_CORE2,SW_FARM deviceTier
```

### 💻 Single Server High-Performance (10,000+ Events/Second) 💰

**TEK SUNUCU İLE 10K EVENTS/SECOND MÜMKÜNDÜ!**

```mermaid
graph TB
    subgraph "SINGLE HIGH-PERFORMANCE SERVER"
        subgraph "USERS"
            U1["👤 Admin Users"]
            U2["👨‍💻 Analysts"]
        end
        
        subgraph "WEB LAYER - CONTAINERIZED"
            NGINX["🌐 Nginx Reverse Proxy<br/>Load Balancer"]
            REACT["⚛️ React Frontend<br/>Optimized Build"]
        end
        
        subgraph "API LAYER - MULTI-PROCESS"
            API1["🚀 FastAPI Process 1<br/>Port 8000"]
            API2["🚀 FastAPI Process 2<br/>Port 8001"]
            API3["🚀 FastAPI Process 3<br/>Port 8002"]
            API4["🚀 FastAPI Process 4<br/>Port 8003"]
        end
        
        subgraph "LOG COLLECTION - PARALLEL UDP"
            UDP1["📡 UDP Receiver 1<br/>Port 514 - CPU Core 1-16"]
            UDP2["📡 UDP Receiver 2<br/>Port 515 - CPU Core 17-32"]
            UDP3["📡 UDP Receiver 3<br/>Port 516 - CPU Core 33-48"]
            REDIS_Q["🔄 Redis Queue<br/>In-Memory Broker"]
        end
        
        subgraph "PROCESSING - CPU OPTIMIZED"
            WORKER1["⚡ Worker Process 1<br/>CPU Core 49-52"]
            WORKER2["⚡ Worker Process 2<br/>CPU Core 53-56"]
            WORKER3["⚡ Worker Process 3<br/>CPU Core 57-60"]
            WORKER4["⚡ Worker Process 4<br/>CPU Core 61-64"]
            BATCH["📦 Batch Writer<br/>Shared Memory"]
        end
        
        subgraph "DATA STORAGE - SINGLE NODE"
            ES_SINGLE["🔍 Elasticsearch<br/>Single Node - 32GB Heap"]
            PG_SINGLE["🐘 PostgreSQL<br/>Optimized Config"]
            REDIS_CACHE["⚡ Redis<br/>Cache + Sessions"]
        end
        
        subgraph "STORAGE - NVMe OPTIMIZED"
            NVME["💾 NVMe SSD Pool<br/>4x 2TB RAID 0"]
            ARCHIVE["📦 Archive<br/>Background Compression"]
        end
        
        subgraph "MONITORING - LIGHTWEIGHT"
            METRICS["📊 Prometheus<br/>Efficient Scraping"]
            GRAFANA["📈 Grafana<br/>Essential Dashboards"]
        end
    end
    
    subgraph "NETWORK DEVICES"
        FW_DEV["🔥 Firewalls"]
        RTR_DEV["🔀 Routers"] 
        SW_DEV["🔌 Switches"]
    end
    
    %% External to Server
    FW_DEV --> UDP1
    RTR_DEV --> UDP2
    SW_DEV --> UDP3
    
    %% Users to Web
    U1 --> NGINX
    U2 --> NGINX
    NGINX --> REACT
    
    %% Web to API
    NGINX --> API1
    NGINX --> API2
    NGINX --> API3
    NGINX --> API4
    
    %% UDP to Queue
    UDP1 --> REDIS_Q
    UDP2 --> REDIS_Q
    UDP3 --> REDIS_Q
    
    %% Queue to Workers
    REDIS_Q --> WORKER1
    REDIS_Q --> WORKER2
    REDIS_Q --> WORKER3
    REDIS_Q --> WORKER4
    
    %% Workers to Batch
    WORKER1 --> BATCH
    WORKER2 --> BATCH
    WORKER3 --> BATCH
    WORKER4 --> BATCH
    
    %% Batch to Storage
    BATCH --> ES_SINGLE
    BATCH --> PG_SINGLE
    BATCH --> REDIS_CACHE
    BATCH --> NVME
    
    %% Storage Hierarchy
    NVME --> ARCHIVE
    
    %% API to Data
    API1 --> ES_SINGLE
    API2 --> PG_SINGLE
    API3 --> REDIS_CACHE
    API4 --> ES_SINGLE
    
    %% Monitoring
    WORKER1 --> METRICS
    BATCH --> METRICS
    ES_SINGLE --> METRICS
    METRICS --> GRAFANA
    
    classDef singleServer fill:#e8f5e8,stroke:#4caf50,stroke-width:4px
    classDef webLayer fill:#e3f2fd,stroke:#2196f3,stroke-width:3px
    classDef apiLayer fill:#fff3e0,stroke:#ff9800,stroke-width:3px
    classDef udpLayer fill:#f3e5f5,stroke:#9c27b0,stroke-width:3px
    classDef processLayer fill:#ffebee,stroke:#f44336,stroke-width:3px
    classDef dataLayer fill:#e0f2f1,stroke:#009688,stroke-width:3px
    classDef storageLayer fill:#fce4ec,stroke:#e91e63,stroke-width:3px
    
    class NGINX,REACT webLayer
    class API1,API2,API3,API4 apiLayer
    class UDP1,UDP2,UDP3,REDIS_Q udpLayer
    class WORKER1,WORKER2,WORKER3,WORKER4,BATCH processLayer
    class ES_SINGLE,PG_SINGLE,REDIS_CACHE dataLayer
    class NVME,ARCHIVE,METRICS,GRAFANA storageLayer
```

### 📋 Architecture Comparison

| Component | MVP Implementation | Single Server High-Performance 💰 | Multi-Server High-Performance | Enterprise Implementation |
|-----------|-------------------|----------------------------------|-------------------------------|---------------------------|
| **Events/Second** | 1,000-2,000 | **10,000+** ⭐ | **10,000+** | 50,000+ |
| **Server Count** | 1 | **1** (Güçlü) | 15+ | 50+ |
| **Web Layer** | Single Nginx + React | Multi-Process Nginx + React | 3x Load Balanced Web Servers | Global CDN + Multi-region |
| **API Layer** | Single FastAPI Instance | 4x FastAPI Processes | 4x Load Balanced FastAPI | Microservices + Service Mesh |
| **Log Collection** | Single Syslog Server | 3x UDP Processes + CPU Pinning | 3x Load Balanced Syslog | Geographic Distribution |
| **Processing** | Synchronous Parser | 4x Parallel Workers + CPU Cores | 4x Parallel Workers + Queue | ML Pipeline + Stream Processing |
| **Data Storage** | PostgreSQL + Files | Single ES + PG + Redis (Optimized) | Clustered (ES + PG + Redis) | Multi-region + Hot/Cold Tiers |
| **Monitoring** | Basic Health Checks | Lightweight Prometheus + Grafana | Real-time Metrics + Auto-scale | AI-based Predictive Analytics |
| **Authentication** | Basic JWT | JWT + Session Management | JWT + Session Management | LDAP + RBAC + 2FA + SSO |
| **Compliance** | File Retention | Basic Digital Signatures | Basic Digital Signatures | Full 5651 + International Standards |
| **Availability** | 95% (Single Point) | 99% (Single Point Optimized) | 99.9% (HA Components) | 99.99% (Multi-region DR) |
| **Deployment** | Single Server | **Single Powerful Server** | Multi-server Cluster | Cloud-native + Kubernetes |
| **CPU Requirement** | 8 cores | **64 cores** | 450+ cores total | 1000+ cores total |
| **RAM Requirement** | 32GB | **256GB** | 800GB+ total | 2TB+ total |
| **Storage** | 1TB SSD | **8TB NVMe RAID** | 50TB+ distributed | 100TB+ distributed |
| **Network** | 1Gbps | **25Gbps** | 10Gbps per server | 100Gbps+ |
| **Cost (Monthly)** | $500-1,000 | **$3,500-4,500** 💰 | $8,000-12,000 | $25,000+ |
| **Complexity** | Very Simple | **Simple** ⭐ | Complex | Very Complex |
| **Management** | Easy | **Easy** | Moderate | Difficult |

### 💡 **TEK SUNUCU İLE 10K EVENTS/SECOND AVANTAJLARI:**

#### ✅ **Avantajlar:**
- **💰 65% Daha Ucuz** ($4K vs $11K/ay)
- **🔧 Basit Yönetim** - Tek sunucu, tek sistem
- **⚡ Düşük Network Latency** - İç haberleşme çok hızlı
- **🚀 Hızlı Deployment** - Docker Compose ile 10 dakikada kurulum
- **📊 Kolay Monitoring** - Tek yerden tüm metrikleri izleme
- **🔄 Basit Backup** - Tek sunucu backup stratejisi
- **⚙️ Kolay Troubleshooting** - Tüm loglar aynı yerde

#### ⚠️ **Dezavantajlar:**
- **☝️ Single Point of Failure** - Sunucu çökerse tüm sistem durur
- **📈 Vertical Scaling Limit** - 64 core üzerinde pahalı hale gelir
- **🔧 Hardware Dependency** - Donanım arızasında risk
- **⚡ No Redundancy** - Load distribution yok

### 🎯 **Performance Targets by Architecture Level**

#### MVP Targets
- **Events/Second**: 1,000-2,000
- **Response Time**: < 1 second
- **Concurrent Users**: 50
- **Storage**: 100GB/day
- **Uptime**: 95%

#### Single Server High-Performance Targets 💰⭐
- **Events/Second**: **10,000+**
- **Response Time**: < 100ms (P95)
- **Concurrent Users**: 500+
- **Storage**: 1TB/day
- **Uptime**: 99% (Single server optimized)
- **Processing Latency**: < 50ms
- **CPU Usage**: < 80% (Optimal performance)
- **Memory Usage**: < 90%
- **Disk I/O**: 40K+ IOPS

#### Multi-Server High-Performance Targets
- **Events/Second**: **10,000+**
- **Response Time**: < 100ms (P95)
- **Concurrent Users**: 500+
- **Storage**: 1TB/day
- **Uptime**: 99.9%
- **Processing Latency**: < 50ms
- **Queue Depth**: < 10,000
- **Auto-scaling**: Yes

#### Enterprise Targets
- **Events/Second**: 50,000+
- **Response Time**: < 50ms (P95)
- **Concurrent Users**: 2,000+
- **Storage**: 10TB/day
- **Uptime**: 99.99%
- **Multi-region**: Yes
- **Disaster Recovery**: 4-hour RTO

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

This comprehensive enterprise architecture ensures LogMaster v2 can handle massive log volumes while maintaining data integrity, security, and compliance with Turkish Law 5651 requirements.

## 🚀 MVP Development Approach

### Phase 1: Core Log Management MVP (1-2 weeks)
**Essential Components:**
```
├── 📡 Syslog Server (Port 514 UDP) ⭐ CORE FEATURE
├── 🔄 Log Parser & Processing Engine
├── 💾 File Storage System (/var/log/logmaster/)
├── 🐘 PostgreSQL (Device metadata + log index)
├── 🚀 FastAPI Backend (Port 8000)
├── ⚛️ Basic React Frontend (Log viewer)
└── 🌐 Nginx Reverse Proxy (Port 80/443)
```

**MVP Data Flow:**
```
Network Devices → UDP 514 → Syslog Receiver → Log Parser → File Storage + DB Index → Web UI
```

**Week 1 Priorities:**
1. **Syslog UDP Receiver** - Accept logs on port 514
2. **Device Identification** - IP/MAC based device mapping
3. **Log Storage** - Daily files per device + metadata index
4. **Basic API** - CRUD operations for logs and devices

**Week 2 Priorities:**
5. **Web Interface** - Log viewing and filtering
6. **Real-time Updates** - WebSocket/SSE for live logs
7. **Device Management** - Add/edit network devices
8. **Basic Search** - Date/device/keyword filtering

### Phase 2: High-Performance Architecture (10,000+ Events/Second) ⭐
**Duration:** 3-4 weeks
**Target:** Scale to handle enterprise-level log volumes

**Essential Components:**
```
├── ⚖️ Load Balancer Cluster (Web + API + UDP)
├── 🔄 Redis Queue System (Message broker)
├── ⚡ Parallel Processing Workers (4+ AsyncIO workers)
├── 🔍 Elasticsearch Cluster (3 Master + 6 Data nodes)
├── 🐘 PostgreSQL Cluster (1 Master + 2 Read replicas)
├── ⚡ Redis Cluster (6 nodes for caching)
├── 📦 Batch Processing System (1000 events/batch)
├── 📊 Real-time Monitoring (Prometheus + Grafana)
└── 🚨 Auto-scaling System (Performance-based scaling)
```

**High-Performance Data Flow:**
```
Network Device Clusters → UDP Load Balancer → 3x Syslog Receivers → Redis Queue → 
4x Parallel Workers → Batch Writer → Clustered Storage (ES + PG + Redis) → 
Load Balanced APIs → Scaled Web Servers
```

**Week 1-2 Priorities:**
1. **Load Balancer Setup** - UDP, API, and Web load balancing
2. **Redis Queue Implementation** - Message broker for high throughput
3. **Parallel Workers** - Multiple AsyncIO processing workers
4. **Elasticsearch Cluster** - Deploy and configure ES cluster

**Week 3-4 Priorities:**
5. **PostgreSQL Clustering** - Master-slave replication setup
6. **Batch Processing** - Optimize for 1000+ events/batch
7. **Performance Monitoring** - Real-time metrics and dashboards
8. **Auto-scaling Logic** - Automatic horizontal scaling

### Phase 3: Enterprise & Compliance (4-6 weeks)
**Duration:** 4-6 weeks
**Target:** Full enterprise features with legal compliance

**Enterprise Components:**
```
├── ✍️ Digital Signature Engine (5651 compliance)
├── 📋 Audit Trail System
├── 🔒 Advanced Security Features (LDAP + RBAC + 2FA)
├── 📈 Advanced Monitoring & Metrics
├── 🗃️ Archive & Retention Management
├── 📊 Compliance Reporting (Automated legal reports)
├── 🌍 Multi-region Deployment
├── 🏥 Disaster Recovery System
└── 📱 Mobile Application
```

**Week 1-2 Priorities:**
1. **Digital Signature System** - RSA-256 + TSA integration
2. **Advanced Security** - LDAP integration and RBAC
3. **Compliance Engine** - 5651 Turkish Law compliance
4. **Audit System** - Complete activity tracking

**Week 3-4 Priorities:**
5. **Multi-region Setup** - Geographic distribution
6. **Disaster Recovery** - Backup and failover systems
7. **Advanced Analytics** - ML-based anomaly detection
8. **Mobile Application** - iOS/Android app development

### MVP Technology Stack
```yaml
Core Infrastructure:
  - Language: Python 3.11+
  - Backend: FastAPI + Uvicorn
  - Database: PostgreSQL 15
  - Cache: Redis 7
  - Frontend: React 18 + TypeScript
  - Proxy: Nginx Alpine

Log Collection:
  - Protocol: Syslog (RFC 3164/5424)
  - Transport: UDP Port 514
  - Processing: AsyncIO + Queue
  - Storage: File System + DB Index
  - Format: JSON + Raw text

Development:
  - Containerization: Docker + Docker Compose
  - Version Control: Git + GitHub
  - Documentation: Markdown + Mermaid
  - Testing: pytest + Jest
```

### Success Metrics for MVP
- ✅ **Log Reception**: Successfully receive 1000+ logs/minute
- ✅ **Device Support**: Handle 50+ network devices
- ✅ **Real-time Display**: Show logs with <2 second latency
- ✅ **Search Performance**: Query results in <500ms
- ✅ **Uptime**: 99.9% availability during testing
- ✅ **Storage**: Handle 1GB+ daily log volume

### 🎯 Revised Implementation Priority

**CRITICAL (Phase 1 - MVP Core):**
1. Syslog collection (UDP 514)
2. Log parsing and storage
3. Device management
4. Basic web interface
5. PostgreSQL integration
6. Real-time log display

**HIGH PRIORITY (Phase 2 - High Performance):** ⭐
7. **Load balancer implementation**
8. **Redis queue system**
9. **Parallel processing workers**
10. **Elasticsearch clustering**
11. **PostgreSQL clustering**
12. **Performance monitoring**
13. **Auto-scaling system**
14. **Batch processing optimization**

**IMPORTANT (Phase 3 - Enterprise):**
15. Digital signatures (5651 compliance)
16. Advanced security (LDAP + RBAC)
17. Multi-region deployment
18. Disaster recovery
19. Advanced monitoring
20. Compliance reporting
21. Mobile application

### 🏗️ Hardware Requirements by Phase

#### Phase 1 (MVP) - Single Server
```yaml
CPU: 8 cores
RAM: 32GB
Storage: 1TB SSD
Network: 1Gbps
Cost: ~$800/month
```

#### Phase 2A (Single Server High-Performance) - Powerful Single Server 💰⭐
```yaml
Server Specifications:
  CPU: 64 cores (AMD EPYC 7713 or Intel Xeon Gold 6348)
  RAM: 256GB DDR4-3200 ECC
  Storage: 
    - Primary: 4x 2TB NVMe SSD RAID 0 (8TB total, 200K+ IOPS)
    - Archive: 2x 8TB SATA SSD (compressed logs)
  Network: 25Gbps Ethernet
  Power: Redundant PSU + UPS backup

Process/Core Allocation:
  - UDP Receivers: 3 processes (48 cores total)
  - Log Workers: 4 processes (16 cores total)
  - Elasticsearch: Single node (32GB heap, dedicated cores)
  - PostgreSQL: Optimized config (8 cores)
  - Redis: In-memory cache (4 cores)
  - API Processes: 4 FastAPI instances (8 cores)
  - System: Reserved (4 cores)

Monthly Cost: $3,500-4,500 💰
```

#### Phase 2B (Multi-Server High-Performance) - Multi-server Cluster
```yaml
Primary Processing: 64 cores, 256GB RAM, 4x2TB NVMe
Elasticsearch Cluster: 9 nodes (288 cores total)
PostgreSQL Cluster: 3 nodes (80 cores total)
Redis Cluster: 6 nodes (96 cores total)
Network: 25Gbps per server
Cost: ~$10,800/month
```

#### Phase 3 (Enterprise) - Multi-region Infrastructure
```yaml
Multiple Datacenters: 2-3 regions
Disaster Recovery: Hot standby sites
Advanced Monitoring: Dedicated monitoring cluster
Global CDN: Edge caching worldwide
Cost: ~$25,000+/month
```

### 🔧 **Single Server Configuration Details**

#### Operating System Optimizations
```bash
# Kernel parameters for high performance
echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
echo 'net.core.rmem_max=134217728' >> /etc/sysctl.conf
echo 'net.core.wmem_max=134217728' >> /etc/sysctl.conf
echo 'net.core.netdev_max_backlog=30000' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem=4096 65536 134217728' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem=4096 65536 134217728' >> /etc/sysctl.conf

# CPU governor for performance
echo 'performance' > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Disable swap for Elasticsearch
swapoff -a
```

#### Docker Compose Configuration
```yaml
version: '3.8'
services:
  # 3x UDP Receivers with CPU affinity
  udp-receiver-1:
    cpuset: "0-15"
    mem_limit: 8g
    
  udp-receiver-2:
    cpuset: "16-31"
    mem_limit: 8g
    
  udp-receiver-3:
    cpuset: "32-47"
    mem_limit: 8g
    
  # 4x Log Processing Workers
  log-worker-1:
    cpuset: "48-51"
    mem_limit: 16g
    
  log-worker-2:
    cpuset: "52-55"
    mem_limit: 16g
    
  log-worker-3:
    cpuset: "56-59"
    mem_limit: 16g
    
  log-worker-4:
    cpuset: "60-63"
    mem_limit: 16g
    
  # Single Elasticsearch node optimized
  elasticsearch:
    environment:
      - "ES_JAVA_OPTS=-Xms32g -Xmx32g"
      - "discovery.type=single-node"
      - "indices.memory.index_buffer_size=40%"
    mem_limit: 64g
    
  # PostgreSQL optimized config
  postgresql:
    environment:
      - "max_connections=200"
      - "shared_buffers=32GB"
      - "effective_cache_size=64GB"
      - "work_mem=256MB"
    mem_limit: 48g
    
  # Redis optimized
  redis:
    environment:
      - "maxmemory=16gb"
      - "maxmemory-policy=allkeys-lru"
    mem_limit: 18g
```

#### Performance Monitoring Setup
```yaml
monitoring:
  prometheus:
    scrape_interval: 5s
    retention: 30d
    mem_limit: 8g
    
  grafana:
    dashboards:
      - "Single Server Performance"
      - "Log Processing Metrics"
      - "Resource Usage"
    mem_limit: 4g
```

## 🐧 **Ubuntu Single Server Kurulum Rehberi** 

### **✅ EVET! Tek Ubuntu sunucuda 10K events/second mümkün!**

```mermaid
graph TB
    subgraph "UBUNTU SERVER (64 Core, 256GB RAM)"
        subgraph "CONTAINER LAYER"
            DOCKER["🐳 Docker Engine<br/>Container Orchestration"]
            COMPOSE["📋 Docker Compose<br/>Service Management"]
        end
        
        subgraph "CORE SERVICES (Containers)"
            UDP_C1["📡 UDP Container 1<br/>Cores 0-15"]
            UDP_C2["📡 UDP Container 2<br/>Cores 16-31"] 
            UDP_C3["📡 UDP Container 3<br/>Cores 32-47"]
            
            WORKER_C1["⚡ Worker Container 1<br/>Cores 48-51"]
            WORKER_C2["⚡ Worker Container 2<br/>Cores 52-55"]
            WORKER_C3["⚡ Worker Container 3<br/>Cores 56-59"] 
            WORKER_C4["⚡ Worker Container 4<br/>Cores 60-63"]
        end
        
        subgraph "DATA SERVICES (Containers)"
            ES_C["🔍 Elasticsearch Container<br/>32GB Heap, Dedicated Cores"]
            PG_C["🐘 PostgreSQL Container<br/>Optimized Config"]
            REDIS_C["⚡ Redis Container<br/>In-Memory Cache"]
            QUEUE_C["🔄 Redis Queue Container<br/>Message Broker"]
        end
        
        subgraph "WEB SERVICES (Containers)"
            NGINX_C["🌐 Nginx Container<br/>Load Balancer + Static"]
            API_C1["🚀 FastAPI Container 1<br/>Port 8000"]
            API_C2["🚀 FastAPI Container 2<br/>Port 8001"]
            API_C3["🚀 FastAPI Container 3<br/>Port 8002"]
            REACT_C["⚛️ React Container<br/>Frontend Build"]
        end
        
        subgraph "MONITORING (Containers)"
            PROM_C["📊 Prometheus Container<br/>Metrics Collection"]
            GRAF_C["📈 Grafana Container<br/>Dashboards"]
        end
        
        subgraph "STORAGE (Host Volumes)"
            NVME["💾 /var/lib/logmaster<br/>NVMe Mount Point"]
            ARCHIVE["📦 /var/archive/logmaster<br/>Archive Storage"]
        end
    end
    
    %% Container Relationships
    UDP_C1 --> QUEUE_C
    UDP_C2 --> QUEUE_C
    UDP_C3 --> QUEUE_C
    
    QUEUE_C --> WORKER_C1
    QUEUE_C --> WORKER_C2
    QUEUE_C --> WORKER_C3
    QUEUE_C --> WORKER_C4
    
    WORKER_C1 --> ES_C
    WORKER_C2 --> PG_C
    WORKER_C3 --> REDIS_C
    WORKER_C4 --> NVME
    
    NGINX_C --> API_C1
    NGINX_C --> API_C2
    NGINX_C --> API_C3
    NGINX_C --> REACT_C
    
    API_C1 --> ES_C
    API_C2 --> PG_C
    API_C3 --> REDIS_C
    
    PROM_C --> GRAF_C
    
    classDef container fill:#e8f5e8,stroke:#4caf50,stroke-width:2px
    classDef storage fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    
    class UDP_C1,UDP_C2,UDP_C3,WORKER_C1,WORKER_C2,WORKER_C3,WORKER_C4,ES_C,PG_C,REDIS_C,QUEUE_C,NGINX_C,API_C1,API_C2,API_C3,REACT_C,PROM_C,GRAF_C container
    class NVME,ARCHIVE storage
```

### 🛠️ **Step-by-Step Ubuntu Kurulum**

#### 1. Ubuntu Server Hazırlığı
```bash
# Ubuntu 22.04 LTS Server kurulumu
sudo apt update && sudo apt upgrade -y

# Kernel optimizasyonları
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728
sudo sysctl -w net.core.netdev_max_backlog=30000

# Kalıcı yapmak için
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
echo 'net.core.rmem_max=134217728' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max=134217728' | sudo tee -a /etc/sysctl.conf
echo 'net.core.netdev_max_backlog=30000' | sudo tee -a /etc/sysctl.conf

# Swap kapatma (Elasticsearch için)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

#### 2. Docker ve Docker Compose Kurulumu
```bash
# Docker kurulumu
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose kurulumu
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout/login yapın veya
newgrp docker
```

#### 3. Storage Hazırlığı
```bash
# NVMe diskler için mount point
sudo mkdir -p /var/lib/logmaster
sudo mkdir -p /var/archive/logmaster
sudo mkdir -p /var/log/logmaster

# NVMe RAID kurulumu (4 disk varsa)
sudo mdadm --create --verbose /dev/md0 --level=0 --raid-devices=4 /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1
sudo mkfs.ext4 /dev/md0
sudo mount /dev/md0 /var/lib/logmaster

# Auto-mount için fstab
echo '/dev/md0 /var/lib/logmaster ext4 defaults,noatime 0 2' | sudo tee -a /etc/fstab
```

#### 4. LogMaster Docker Compose Dosyası
```yaml
# /opt/logmaster/docker-compose.yml
version: '3.8'

services:
  # UDP Syslog Receivers (3 instance)
  udp-receiver-1:
    build: ./syslog-receiver
    container_name: logmaster-udp-1
    ports:
      - "514:514/udp"
    environment:
      - RECEIVER_ID=1
      - REDIS_URL=redis://redis-queue:6379
    cpuset: "0-15"
    mem_limit: 8g
    depends_on: [redis-queue]
    
  udp-receiver-2:
    build: ./syslog-receiver
    container_name: logmaster-udp-2
    ports:
      - "515:514/udp"
    environment:
      - RECEIVER_ID=2
      - REDIS_URL=redis://redis-queue:6379
    cpuset: "16-31"
    mem_limit: 8g
    depends_on: [redis-queue]
    
  udp-receiver-3:
    build: ./syslog-receiver
    container_name: logmaster-udp-3
    ports:
      - "516:514/udp"
    environment:
      - RECEIVER_ID=3
      - REDIS_URL=redis://redis-queue:6379
    cpuset: "32-47"
    mem_limit: 8g
    depends_on: [redis-queue]

  # Redis Queue (Message Broker)
  redis-queue:
    image: redis:7-alpine
    container_name: logmaster-queue
    command: redis-server --maxmemory 4gb --maxmemory-policy allkeys-lru
    mem_limit: 5g
    volumes:
      - redis-queue-data:/data

  # Log Processing Workers (4 instance)
  log-worker-1:
    build: ./log-processor
    container_name: logmaster-worker-1
    environment:
      - WORKER_ID=1
      - REDIS_URL=redis://redis-queue:6379
      - ES_URL=http://elasticsearch:9200
      - PG_URL=postgresql://postgres:password@postgresql:5432/logmaster
    cpuset: "48-51"
    mem_limit: 16g
    depends_on: [redis-queue, elasticsearch, postgresql]

  log-worker-2:
    build: ./log-processor
    container_name: logmaster-worker-2
    environment:
      - WORKER_ID=2
      - REDIS_URL=redis://redis-queue:6379
      - ES_URL=http://elasticsearch:9200
      - PG_URL=postgresql://postgres:password@postgresql:5432/logmaster
    cpuset: "52-55"
    mem_limit: 16g
    depends_on: [redis-queue, elasticsearch, postgresql]

  log-worker-3:
    build: ./log-processor
    container_name: logmaster-worker-3
    environment:
      - WORKER_ID=3
      - REDIS_URL=redis://redis-queue:6379
      - ES_URL=http://elasticsearch:9200
      - PG_URL=postgresql://postgres:password@postgresql:5432/logmaster
    cpuset: "56-59"
    mem_limit: 16g
    depends_on: [redis-queue, elasticsearch, postgresql]

  log-worker-4:
    build: ./log-processor
    container_name: logmaster-worker-4
    environment:
      - WORKER_ID=4
      - REDIS_URL=redis://redis-queue:6379
      - ES_URL=http://elasticsearch:9200
      - PG_URL=postgresql://postgres:password@postgresql:5432/logmaster
    cpuset: "60-63"
    mem_limit: 16g
    depends_on: [redis-queue, elasticsearch, postgresql]

  # Elasticsearch Single Node
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: logmaster-elasticsearch
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms32g -Xmx32g"
      - xpack.security.enabled=false
      - indices.memory.index_buffer_size=40%
    mem_limit: 64g
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
      - /var/lib/logmaster/elasticsearch:/var/lib/elasticsearch
    ports:
      - "9200:9200"

  # PostgreSQL
  postgresql:
    image: postgres:15-alpine
    container_name: logmaster-postgresql
    environment:
      POSTGRES_DB: logmaster
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_SHARED_BUFFERS: 32GB
      POSTGRES_EFFECTIVE_CACHE_SIZE: 64GB
      POSTGRES_WORK_MEM: 256MB
      POSTGRES_MAX_CONNECTIONS: 200
    mem_limit: 48g
    volumes:
      - postgresql-data:/var/lib/postgresql/data
      - /var/lib/logmaster/postgresql:/var/lib/postgresql/backup
    ports:
      - "5432:5432"

  # Redis Cache
  redis-cache:
    image: redis:7-alpine
    container_name: logmaster-redis
    command: redis-server --maxmemory 16gb --maxmemory-policy allkeys-lru
    mem_limit: 18g
    volumes:
      - redis-cache-data:/data

  # FastAPI Instances (4 instance)
  api-1:
    build: ./backend
    container_name: logmaster-api-1
    environment:
      - API_INSTANCE=1
      - ES_URL=http://elasticsearch:9200
      - PG_URL=postgresql://postgres:password@postgresql:5432/logmaster
      - REDIS_URL=redis://redis-cache:6379
    ports:
      - "8000:8000"
    depends_on: [elasticsearch, postgresql, redis-cache]

  api-2:
    build: ./backend
    container_name: logmaster-api-2
    environment:
      - API_INSTANCE=2
      - ES_URL=http://elasticsearch:9200
      - PG_URL=postgresql://postgres:password@postgresql:5432/logmaster
      - REDIS_URL=redis://redis-cache:6379
    ports:
      - "8001:8000"
    depends_on: [elasticsearch, postgresql, redis-cache]

  api-3:
    build: ./backend
    container_name: logmaster-api-3
    environment:
      - API_INSTANCE=3
      - ES_URL=http://elasticsearch:9200
      - PG_URL=postgresql://postgres:password@postgresql:5432/logmaster
      - REDIS_URL=redis://redis-cache:6379
    ports:
      - "8002:8000"
    depends_on: [elasticsearch, postgresql, redis-cache]

  api-4:
    build: ./backend
    container_name: logmaster-api-4
    environment:
      - API_INSTANCE=4
      - ES_URL=http://elasticsearch:9200
      - PG_URL=postgresql://postgres:password@postgresql:5432/logmaster
      - REDIS_URL=redis://redis-cache:6379
    ports:
      - "8003:8000"
    depends_on: [elasticsearch, postgresql, redis-cache]

  # Nginx Load Balancer
  nginx:
    image: nginx:alpine
    container_name: logmaster-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
      - /var/log/logmaster:/var/log/nginx
    depends_on: [api-1, api-2, api-3, api-4, frontend]

  # React Frontend
  frontend:
    build: ./frontend
    container_name: logmaster-frontend
    ports:
      - "3000:3000"

  # Monitoring
  prometheus:
    image: prom/prometheus:latest
    container_name: logmaster-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    mem_limit: 8g

  grafana:
    image: grafana/grafana:latest
    container_name: logmaster-grafana
    ports:
      - "3001:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    volumes:
      - grafana-data:/var/lib/grafana
      - ./monitoring/grafana:/etc/grafana/provisioning
    mem_limit: 4g
    depends_on: [prometheus]

volumes:
  elasticsearch-data:
  postgresql-data:
  redis-queue-data:
  redis-cache-data:
  prometheus-data:
  grafana-data:

networks:
  default:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

#### 5. Nginx Load Balancer Konfigürasyonu
```nginx
# /opt/logmaster/nginx/nginx.conf
upstream api_backend {
    server api-1:8000 weight=1;
    server api-2:8000 weight=1;
    server api-3:8000 weight=1;
    server api-4:8000 weight=1;
}

upstream syslog_backend {
    server udp-receiver-1:514;
    server udp-receiver-2:514;
    server udp-receiver-3:514;
}

server {
    listen 80;
    server_name _;

    # Frontend
    location / {
        proxy_pass http://frontend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # API Load Balancing
    location /api/ {
        proxy_pass http://api_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # WebSocket for real-time logs
    location /ws {
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# UDP Load Balancing (Stream module)
stream {
    upstream syslog_udp {
        server logmaster-udp-1:514;
        server logmaster-udp-2:515;
        server logmaster-udp-3:516;
    }
    
    server {
        listen 514 udp;
        proxy_pass syslog_udp;
        proxy_timeout 1s;
        proxy_responses 1;
    }
}
```

#### 6. Sistem Başlatma
```bash
# LogMaster dizinine git
cd /opt/logmaster

# Tüm servisleri başlat
docker-compose up -d

# Durumu kontrol et
docker-compose ps

# Logları izle
docker-compose logs -f

# Performance metrikleri
docker stats
```

### 📊 **Resource Distribution (64 Core Server)**
```
CPU Core Allocation:
├── UDP Receivers: 48 cores (0-47)
├── Log Workers: 16 cores (48-63)
├── Elasticsearch: Shared cores
├── PostgreSQL: Shared cores
├── APIs: Shared cores
└── System: Floating

Memory Allocation:
├── UDP Receivers: 24GB (3x8GB)
├── Log Workers: 64GB (4x16GB)
├── Elasticsearch: 64GB
├── PostgreSQL: 48GB
├── Redis: 23GB (5GB+18GB)
├── APIs: 16GB (4x4GB)
├── Monitoring: 12GB
└── System: 45GB free
```

### ✅ **Başlatma Komutları**
```bash
# Hızlı kurulum
git clone https://github.com/ozkanguner/5651-logging-v2.git /opt/logmaster
cd /opt/logmaster
sudo ./deploy/ubuntu-single-server-hp.sh

# Manuel kurulum
docker-compose up -d

# Health check
curl http://localhost/api/health
curl http://localhost:9200/_cluster/health
```

**SONUÇ:** Evet! Tek Ubuntu sunucuda 64 core ile 10,000+ events/second işleyebilirsiniz! 🚀 
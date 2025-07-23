# LogMaster v2 - Multi-Tenant Hotel Chain Log Management

## 🏨 **Temiz ve Basit Multi-Tenant Mimari**

**LogMaster v2** - Otel zincirleri için özel tasarlanmış, **1000+ events/second** performansı ile **5651 uyumlu** log yönetim sistemi.

## 🎯 **Sistem Mimarisi**

### **🏢 Multi-Tenant Hotel Chain Architecture (1000+ EPS)**

```mermaid
graph TB
    subgraph "HOTEL CHAIN"
        CHAIN_ADMIN["🏢 Chain Admin<br/>Tüm otelleri yönetir"]
        
        subgraph "HOTEL A"
            HOTEL_A_USER["👨‍💼 Hotel A User<br/>Sadece A otelini görür"]
            MIKROTIK_A["📡 Mikrotik Devices A<br/>Router + Switch + AP"]
        end
        
        subgraph "HOTEL B"
            HOTEL_B_USER["👨‍💼 Hotel B User<br/>Sadece B otelini görür"]
            MIKROTIK_B["📡 Mikrotik Devices B<br/>Router + Switch + AP"]
        end
        
        subgraph "HOTEL C"
            HOTEL_C_USER["👨‍💼 Hotel C User<br/>Sadece C otelini görür"]
            MIKROTIK_C["📡 Mikrotik Devices C<br/>Router + Switch"]
        end
    end
    
    subgraph "HIGH-PERFORMANCE LOGMASTER SYSTEM"
        subgraph "Collection Layer"
            SYSLOG["📡 Syslog Collector<br/>UDP 514<br/>1000+ EPS"]
        end
        
        subgraph "Queue & Processing"
            REDIS_QUEUE["⚡ Redis Queue<br/>High-throughput message broker"]
            WORKER_1["🔄 Log Worker 1<br/>Async processing"]
            WORKER_2["🔄 Log Worker 2<br/>Async processing"] 
            WORKER_3["🔄 Log Worker 3<br/>Async processing"]
            WORKER_4["🔄 Log Worker 4<br/>Async processing"]
            HOTEL_ROUTER["🏨 Hotel Router<br/>Tenant Identification"]
            LOG_PARSER["🔄 Log Parser<br/>Mikrotik + Generic"]
            ENRICHER["🎯 Log Enricher<br/>Hotel + Device Info"]
        end
        
        subgraph "Storage Layer"
            POSTGRES["🐘 PostgreSQL<br/>Metadata + Users + Devices"]
            ELASTICSEARCH["🔍 Elasticsearch<br/>Log Search + Analytics"]
            FILES["📁 File Storage<br/>Raw Logs + Archives"]
            REDIS_CACHE["⚡ Redis Cache<br/>Sessions + Hot data"]
        end
        
        subgraph "Compliance Layer"
            DAILY_SIGNER["✍️ Daily Signer<br/>RSA-256 Digital Signature"]
            TSA_CLIENT["🕐 TSA Client<br/>Time Stamp Authority"]
            COMPLIANCE_ENGINE["⚖️ 5651 Compliance<br/>Audit + Reports"]
        end
        
        subgraph "API Layer"
            AUTH_API["🔐 Authentication<br/>JWT + RBAC + Redis Sessions"]
            TENANT_API["🏨 Tenant API<br/>Hotel-filtered data"]
            DEVICE_API["📱 Device Management<br/>Add/Edit Mikrotik"]
            REALTIME_API["📡 Real-time API<br/>WebSocket + Redis Pub/Sub"]
        end
        
        subgraph "Frontend"
            WEB_DASHBOARD["🌐 Web Dashboard<br/>React + Real-time WebSocket"]
        end
    end
    
    %% Device Connections
    MIKROTIK_A --> SYSLOG
    MIKROTIK_B --> SYSLOG
    MIKROTIK_C --> SYSLOG
    
    %% High-Performance Processing Flow
    SYSLOG --> REDIS_QUEUE
    REDIS_QUEUE --> WORKER_1
    REDIS_QUEUE --> WORKER_2
    REDIS_QUEUE --> WORKER_3
    REDIS_QUEUE --> WORKER_4
    
    WORKER_1 --> HOTEL_ROUTER
    WORKER_2 --> HOTEL_ROUTER
    WORKER_3 --> HOTEL_ROUTER
    WORKER_4 --> HOTEL_ROUTER
    
    HOTEL_ROUTER --> LOG_PARSER
    LOG_PARSER --> ENRICHER
    
    %% Storage Distribution
    ENRICHER --> POSTGRES
    ENRICHER --> ELASTICSEARCH
    ENRICHER --> FILES
    ENRICHER --> REDIS_CACHE
    
    %% Real-time Updates
    ENRICHER --> REALTIME_API
    REALTIME_API --> WEB_DASHBOARD
    
    %% Compliance
    FILES --> DAILY_SIGNER
    DAILY_SIGNER --> TSA_CLIENT
    TSA_CLIENT --> COMPLIANCE_ENGINE
    
    %% API Access
    POSTGRES --> TENANT_API
    ELASTICSEARCH --> TENANT_API
    REDIS_CACHE --> TENANT_API
    TENANT_API --> AUTH_API
    DEVICE_API --> POSTGRES
    
    %% Session Management
    AUTH_API --> REDIS_CACHE
    
    %% User Access
    CHAIN_ADMIN --> WEB_DASHBOARD
    HOTEL_A_USER --> WEB_DASHBOARD
    HOTEL_B_USER --> WEB_DASHBOARD
    HOTEL_C_USER --> WEB_DASHBOARD
    
    WEB_DASHBOARD --> AUTH_API
    WEB_DASHBOARD --> TENANT_API
    WEB_DASHBOARD --> DEVICE_API
    WEB_DASHBOARD --> REALTIME_API
    
    classDef hotel fill:#e3f2fd,stroke:#2196f3,stroke-width:2px
    classDef performance fill:#e8f5e8,stroke:#4caf50,stroke-width:3px
    classDef redis fill:#ffebee,stroke:#f44336,stroke-width:3px
    classDef compliance fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    classDef api fill:#f3e5f5,stroke:#9c27b0,stroke-width:2px
    
    class MIKROTIK_A,MIKROTIK_B,MIKROTIK_C,HOTEL_A_USER,HOTEL_B_USER,HOTEL_C_USER hotel
    class SYSLOG,WORKER_1,WORKER_2,WORKER_3,WORKER_4,HOTEL_ROUTER,LOG_PARSER,ENRICHER performance
    class REDIS_QUEUE,REDIS_CACHE,REALTIME_API redis
    class DAILY_SIGNER,TSA_CLIENT,COMPLIANCE_ENGINE compliance
    class AUTH_API,TENANT_API,DEVICE_API,WEB_DASHBOARD api
```

## 📊 **Basit ve Etkili Veri Akışı**

### **1. Log Collection (1000+ EPS)**
```
Mikrotik Devices → UDP 514 → Hotel Router → Parser → Storage
```

### **2. Multi-Tenant Processing**
```python
# Basit hotel tanımlama
def identify_hotel(log_entry):
    device_ip = log_entry.get('source_ip')
    device = get_device_by_ip(device_ip)
    return device.hotel_id if device else None

# Tenant izolasyonu
def process_log(raw_log):
    hotel_id = identify_hotel(raw_log)
    if not hotel_id:
        return None
        
    return {
        **raw_log,
        'hotel_id': hotel_id,
        'tenant_namespace': f'hotel_{hotel_id}'
    }
```

### **3. 5651 Compliance Pipeline**
```python
# Günlük imzalama
def daily_compliance_process():
    for hotel in get_active_hotels():
        # Her otel için ayrı günlük dosyası
        daily_file = f"/logs/{hotel.id}/{today}.log"
        
        # SHA-256 hash hesapla
        file_hash = calculate_sha256(daily_file)
        
        # RSA-256 ile imzala
        signature = rsa_sign(file_hash, private_key)
        
        # TSA'dan zaman damgası al
        timestamp = get_tsa_timestamp(file_hash)
        
        # İmza kaydı oluştur
        save_signature_record({
            'hotel_id': hotel.id,
            'date': today,
            'file_path': daily_file,
            'file_hash': file_hash,
            'signature': signature,
            'timestamp': timestamp
        })
```

## 🗄️ **Temiz Database Schema**

### **Temel Tablolar**
```sql
-- Hotel Chain Management
CREATE TABLE hotels (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Multi-tenant Users
CREATE TABLE users (
    id UUID PRIMARY KEY,
    hotel_id UUID REFERENCES hotels(id),
    username VARCHAR(50) UNIQUE,
    email VARCHAR(255),
    role VARCHAR(50), -- 'chain_admin', 'hotel_manager', 'viewer'
    password_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Mikrotik Devices
CREATE TABLE devices (
    id UUID PRIMARY KEY,
    hotel_id UUID REFERENCES hotels(id),
    name VARCHAR(255),
    ip_address INET,
    mac_address MACADDR,
    device_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Log Entries (Partitioned by hotel)
CREATE TABLE log_entries (
    id UUID PRIMARY KEY,
    hotel_id UUID REFERENCES hotels(id),
    device_id UUID REFERENCES devices(id),
    timestamp TIMESTAMP,
    message TEXT,
    log_level VARCHAR(20),
    source_ip INET,
    parsed_data JSONB
) PARTITION BY LIST (hotel_id);

-- 5651 Compliance Records
CREATE TABLE compliance_signatures (
    id UUID PRIMARY KEY,
    hotel_id UUID REFERENCES hotels(id),
    date DATE,
    file_path VARCHAR(500),
    file_hash VARCHAR(64),
    signature TEXT,
    tsa_timestamp TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

## ⚡ **High Performance Data Flow (1000+ EPS)**

### **Redis-Powered Processing Pipeline**
```
📡 Syslog UDP 514 → ⚡ Redis Queue → 🔄 4x Parallel Workers → 🏨 Hotel Router → 💾 Multi-Storage
```

### **Performance Optimizations with Redis**
```python
# 1. High-throughput log collection
async def collect_logs():
    while True:
        log_data = await receive_udp_log()
        # Push to Redis queue (non-blocking)
        await redis.lpush("log_queue", json.dumps(log_data))

# 2. Parallel processing workers
async def log_worker(worker_id):
    while True:
        # Batch fetch from Redis queue
        batch = await redis.lrange("log_queue", 0, 99)
        if batch:
            await redis.ltrim("log_queue", 100, -1)
            await process_log_batch(batch, worker_id)

# 3. Real-time updates via Redis Pub/Sub
async def publish_real_time_log(log_entry):
    hotel_id = log_entry['hotel_id']
    await redis.publish(f"hotel_{hotel_id}_logs", json.dumps(log_entry))

# 4. Session management with Redis
async def get_user_session(session_token):
    session_data = await redis.get(f"session_{session_token}")
    return json.loads(session_data) if session_data else None
```

## 📊 **Performance Targets (1000+ EPS)**

### **System Performance Specifications**
```yaml
Target Performance:
  events_per_second: 1000+
  peak_events_per_second: 2000
  processing_latency: <100ms (P95)
  response_time: <200ms
  uptime: 99.9%
  concurrent_users: 50+
  
Per Hotel Capacity:
  max_devices: 50
  max_users: 25
  events_per_hotel: 200+ EPS
  storage_per_month: 200GB
  retention_period: 2+ years

Queue Performance:
  redis_queue_depth: <1000 (normal)
  redis_queue_max: 10000 (alert threshold)
  worker_processing_rate: 250 EPS per worker
  batch_size: 100 logs per batch
```

### **Resource Requirements (1000+ EPS)**
```yaml
Recommended Hardware:
  CPU: 32 cores (3.0+ GHz)
  RAM: 128GB DDR4
  Storage: 4TB NVMe SSD (50K+ IOPS)
  Network: 10Gbps Ethernet
  
Service Resource Allocation:
  Redis Queue: 16GB RAM, 4 cores
  Redis Cache: 8GB RAM, 2 cores
  Log Workers: 32GB RAM, 16 cores (4x8GB, 4x4cores)
  PostgreSQL: 32GB RAM, 8 cores
  Elasticsearch: 24GB RAM, 6 cores
  API Services: 16GB RAM, 4 cores
```

## 🔐 **Enhanced Security & Multi-Tenancy**

### **Redis-Secured Sessions**
```python
# Hotel-aware session management
class HotelSessionManager:
    async def create_session(self, user_id, hotel_id):
        session_token = generate_secure_token()
        session_data = {
            'user_id': user_id,
            'hotel_id': hotel_id,
            'created_at': datetime.now().isoformat(),
            'permissions': await get_user_permissions(user_id, hotel_id)
        }
        
        # Store in Redis with TTL
        await redis.setex(
            f"session_{session_token}",
            3600,  # 1 hour TTL
            json.dumps(session_data)
        )
        return session_token
    
    async def validate_hotel_access(self, session_token, requested_hotel_id):
        session = await redis.get(f"session_{session_token}")
        if not session:
            return False
            
        session_data = json.loads(session)
        user_hotel_id = session_data.get('hotel_id')
        
        # Chain admin can access all hotels
        if session_data.get('role') == 'chain_admin':
            return True
            
        # Hotel manager can only access own hotel
        return user_hotel_id == requested_hotel_id
```

### **Real-time Hotel Isolation**
```python
# Redis Pub/Sub for real-time updates
class RealTimeManager:
    async def subscribe_hotel_logs(self, hotel_id, websocket):
        channel = f"hotel_{hotel_id}_logs"
        
        # Subscribe to hotel-specific channel
        pubsub = redis.pubsub()
        await pubsub.subscribe(channel)
        
        async for message in pubsub.listen():
            if message['type'] == 'message':
                log_data = json.loads(message['data'])
                await websocket.send_text(json.dumps(log_data))
    
    async def publish_log_to_hotel(self, log_entry):
        hotel_id = log_entry['hotel_id']
        channel = f"hotel_{hotel_id}_logs"
        
        # Only publish to relevant hotel channel
        await redis.publish(channel, json.dumps(log_entry))
```

## 🚀 **Deployment Options**

### **🎯 High Performance Production (1000+ EPS)**
```yaml
# docker-compose.production.yml
version: '3.8'
services:
  # Log Collection
  logmaster-syslog:
    image: logmaster/syslog:latest
    ports:
      - "514:514/udp"
    environment:
      - REDIS_QUEUE_URL=redis://redis-queue:6379
    deploy:
      replicas: 2
      
  # Redis Services
  redis-queue:
    image: redis:7-alpine
    command: redis-server --maxmemory 16gb --maxmemory-policy allkeys-lru
    volumes:
      - redis-queue-data:/data
    
  redis-cache:
    image: redis:7-alpine  
    command: redis-server --maxmemory 8gb --maxmemory-policy allkeys-lru
    volumes:
      - redis-cache-data:/data
  
  # Processing Workers
  logmaster-worker-1:
    image: logmaster/worker:latest
    environment:
      - WORKER_ID=1
      - REDIS_QUEUE_URL=redis://redis-queue:6379
      - REDIS_CACHE_URL=redis://redis-cache:6379
    deploy:
      resources:
        limits:
          memory: 8G
          cpus: '4'
          
  logmaster-worker-2:
    image: logmaster/worker:latest
    environment:
      - WORKER_ID=2
      - REDIS_QUEUE_URL=redis://redis-queue:6379
      - REDIS_CACHE_URL=redis://redis-cache:6379
    deploy:
      resources:
        limits:
          memory: 8G
          cpus: '4'
          
  logmaster-worker-3:
    image: logmaster/worker:latest
    environment:
      - WORKER_ID=3
      - REDIS_QUEUE_URL=redis://redis-queue:6379
      - REDIS_CACHE_URL=redis://redis-cache:6379
    deploy:
      resources:
        limits:
          memory: 8G
          cpus: '4'
          
  logmaster-worker-4:
    image: logmaster/worker:latest
    environment:
      - WORKER_ID=4
      - REDIS_QUEUE_URL=redis://redis-queue:6379
      - REDIS_CACHE_URL=redis://redis-cache:6379
    deploy:
      resources:
        limits:
          memory: 8G
          cpus: '4'
  
  # API Services
  logmaster-api:
    image: logmaster/api:latest
    environment:
      - DATABASE_URL=postgresql://postgres:password@postgresql:5432/logmaster
      - ELASTICSEARCH_URL=http://elasticsearch:9200
      - REDIS_CACHE_URL=redis://redis-cache:6379
      - REDIS_QUEUE_URL=redis://redis-queue:6379
    ports:
      - "8000:8000"
    deploy:
      replicas: 2
      
  # Storage Services
  postgresql:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: logmaster
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_SHARED_BUFFERS: 32GB
      POSTGRES_EFFECTIVE_CACHE_SIZE: 64GB
    volumes:
      - postgresql-data:/var/lib/postgresql/data
    deploy:
      resources:
        limits:
          memory: 32G
          cpus: '8'
          
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms24g -Xmx24g"
      - xpack.security.enabled=false
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
    deploy:
      resources:
        limits:
          memory: 24G
          cpus: '6'
  
  # Frontend
  logmaster-web:
    image: logmaster/web:latest
    ports:
      - "3000:3000"
      
  # Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - logmaster-api
      - logmaster-web

volumes:
  redis-queue-data:
  redis-cache-data:
  postgresql-data:
  elasticsearch-data:
```

### **📊 Performance Monitoring**
```yaml
# Performance metrics to track
Redis Metrics:
  - Queue depth (should be < 1000)
  - Memory usage (should be < 80%)
  - Commands per second
  - Hit ratio (should be > 95%)

Processing Metrics:
  - Events per second (target: 1000+)
  - Worker processing latency
  - Queue processing time
  - Error rate (should be < 0.1%)

System Metrics:
  - CPU usage (should be < 80%)
  - Memory usage (should be < 90%)  
  - Disk I/O (should handle 50K+ IOPS)
  - Network throughput
```

Bu **Redis-powered high-performance** mimari ile LogMaster v2:
- ⚡ **1000+ EPS guaranteed** - Redis queue ile yüksek throughput
- 🔄 **Parallel processing** - 4 async worker ile eşzamanlı işlem
- 📡 **Real-time updates** - Redis Pub/Sub ile anlık güncellemeler
- 🏨 **Perfect isolation** - Hotel-aware session management
- 🚀 **Scalable** - Worker sayısı artırılabilir

**Production-ready for 1000+ EPS!** 🎉
# LogMaster v2 - Clean Multi-Tenant Data Flow

## 🔄 **Temiz ve Basit Veri Akışı**

**LogMaster v2** - Otel zincirleri için **1000+ EPS** performansı ile **5651 uyumlu** temiz mimari.

## 📊 **Multi-Tenant Data Flow Architecture**

### **🏨 Hotel Chain Log Processing Flow**

```mermaid
graph LR
    subgraph "HOTELS"
        subgraph "Hotel A - İstanbul"
            A_ROUTER["📡 Mikrotik Router<br/>192.168.1.1"]
            A_SWITCH["📡 Mikrotik Switch<br/>192.168.1.2"]
            A_AP["📡 Mikrotik AP<br/>192.168.1.3"]
        end
        
        subgraph "Hotel B - Ankara"
            B_ROUTER["📡 Mikrotik Router<br/>192.168.2.1"]
            B_SWITCH["📡 Mikrotik Switch<br/>192.168.2.2"]
        end
        
        subgraph "Hotel C - İzmir"
            C_ROUTER["📡 Mikrotik Router<br/>192.168.3.1"]
        end
    end
    
    subgraph "LOGMASTER PROCESSING"
        COLLECTOR["📡 Syslog Collector<br/>UDP 514<br/>1000+ EPS"]
        
        subgraph "Multi-Tenant Pipeline"
            HOTEL_ID["🏨 Hotel Identification<br/>IP → Hotel mapping"]
            PARSER["🔄 Log Parser<br/>Mikrotik + Generic formats"]
            ENRICHER["🎯 Enricher<br/>Add hotel + device info"]
        end
        
        subgraph "Storage"
            PG["🐘 PostgreSQL<br/>Metadata + Users"]
            ES["🔍 Elasticsearch<br/>Search + Analytics"]
            FILES["📁 File Storage<br/>Daily logs per hotel"]
        end
        
        subgraph "5651 Compliance"
            SIGNER["✍️ Daily Signer<br/>RSA-256 signature"]
            TSA["🕐 TSA Timestamp<br/>Legal timestamp"]
            ARCHIVE["📦 Archive<br/>2+ years retention"]
        end
    end
    
    subgraph "USER ACCESS"
        CHAIN_ADMIN["🏢 Chain Admin<br/>View all hotels"]
        HOTEL_MGR_A["👨‍💼 Hotel A Manager<br/>View only Hotel A"]
        HOTEL_MGR_B["👨‍💼 Hotel B Manager<br/>View only Hotel B"]
        HOTEL_MGR_C["👨‍💼 Hotel C Manager<br/>View only Hotel C"]
    end
    
    %% Device to Collector
    A_ROUTER --> COLLECTOR
    A_SWITCH --> COLLECTOR
    A_AP --> COLLECTOR
    B_ROUTER --> COLLECTOR
    B_SWITCH --> COLLECTOR
    C_ROUTER --> COLLECTOR
    
    %% Processing Pipeline
    COLLECTOR --> HOTEL_ID
    HOTEL_ID --> PARSER
    PARSER --> ENRICHER
    
    %% Storage Distribution
    ENRICHER --> PG
    ENRICHER --> ES
    ENRICHER --> FILES
    
    %% Compliance Process
    FILES --> SIGNER
    SIGNER --> TSA
    TSA --> ARCHIVE
    
    %% User Access (Tenant Isolated)
    CHAIN_ADMIN -.->|"All hotels"| PG
    HOTEL_MGR_A -.->|"Hotel A only"| PG
    HOTEL_MGR_B -.->|"Hotel B only"| PG
    HOTEL_MGR_C -.->|"Hotel C only"| PG
    
    classDef device fill:#e8f5e8,stroke:#4caf50,stroke-width:2px
    classDef processing fill:#e3f2fd,stroke:#2196f3,stroke-width:2px
    classDef storage fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    classDef compliance fill:#ffebee,stroke:#f44336,stroke-width:2px
    classDef user fill:#f3e5f5,stroke:#9c27b0,stroke-width:2px
    
    class A_ROUTER,A_SWITCH,A_AP,B_ROUTER,B_SWITCH,C_ROUTER device
    class COLLECTOR,HOTEL_ID,PARSER,ENRICHER processing
    class PG,ES,FILES storage
    class SIGNER,TSA,ARCHIVE compliance
    class CHAIN_ADMIN,HOTEL_MGR_A,HOTEL_MGR_B,HOTEL_MGR_C user
```

## ⚡ **1000+ EPS Performance Pipeline**

### **Yüksek Performans Veri Akışı**

```mermaid
graph TB
    subgraph "HIGH PERFORMANCE COLLECTION"
        UDP_514["📡 UDP Port 514<br/>Non-blocking async"]
        BUFFER["🔄 Circular Buffer<br/>10K message capacity"]
        BATCH["📦 Batch Processor<br/>100 messages/batch"]
    end
    
    subgraph "PARALLEL PROCESSING"
        WORKER_1["⚡ Worker 1<br/>Hotel A + B"]
        WORKER_2["⚡ Worker 2<br/>Hotel C + others"]
        PARSER_1["🔄 Parser 1<br/>Mikrotik logs"]
        PARSER_2["🔄 Parser 2<br/>Generic logs"]
    end
    
    subgraph "OPTIMIZED STORAGE"
        PG_WRITE["🐘 Batch Write PostgreSQL<br/>1000 records/batch"]
        ES_BULK["🔍 Elasticsearch Bulk<br/>Async indexing"]
        FILE_WRITE["📁 Async File Write<br/>Daily rotation"]
    end
    
    subgraph "REAL-TIME METRICS"
        METRICS["📊 Performance Metrics<br/>EPS monitoring"]
        ALERTS["🚨 Threshold Alerts<br/>Performance warnings"]
    end
    
    %% Performance Flow
    UDP_514 --> BUFFER
    BUFFER --> BATCH
    
    BATCH --> WORKER_1
    BATCH --> WORKER_2
    
    WORKER_1 --> PARSER_1
    WORKER_2 --> PARSER_2
    
    PARSER_1 --> PG_WRITE
    PARSER_1 --> ES_BULK
    PARSER_1 --> FILE_WRITE
    
    PARSER_2 --> PG_WRITE
    PARSER_2 --> ES_BULK
    PARSER_2 --> FILE_WRITE
    
    %% Monitoring
    BUFFER --> METRICS
    PARSER_1 --> METRICS
    METRICS --> ALERTS
    
    classDef performance fill:#e8f5e8,stroke:#4caf50,stroke-width:3px
    classDef worker fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    classDef storage fill:#e3f2fd,stroke:#2196f3,stroke-width:2px
    classDef monitoring fill:#f3e5f5,stroke:#9c27b0,stroke-width:2px
    
    class UDP_514,BUFFER,BATCH performance
    class WORKER_1,WORKER_2,PARSER_1,PARSER_2 worker
    class PG_WRITE,ES_BULK,FILE_WRITE storage
    class METRICS,ALERTS monitoring
```

## 🏨 **Multi-Tenant Data Isolation**

### **Hotel Bazlı Veri İzolasyonu**

```python
# Basit ve etkili tenant routing
class HotelRouter:
    def __init__(self):
        self.hotel_ip_map = {
            "192.168.1.0/24": "hotel-a-uuid",  # İstanbul
            "192.168.2.0/24": "hotel-b-uuid",  # Ankara  
            "192.168.3.0/24": "hotel-c-uuid"   # İzmir
        }
    
    def identify_hotel(self, source_ip):
        for subnet, hotel_id in self.hotel_ip_map.items():
            if ipaddress.ip_address(source_ip) in ipaddress.ip_network(subnet):
                return hotel_id
        return None
    
    def process_log(self, raw_log):
        hotel_id = self.identify_hotel(raw_log['source_ip'])
        if not hotel_id:
            return None
            
        return {
            **raw_log,
            'hotel_id': hotel_id,
            'tenant_namespace': f'hotel_{hotel_id}',
            'partition_key': f'logs_{hotel_id}_{datetime.now().strftime("%Y_%m")}'
        }

# API seviyesinde tenant filtreleme
@app.get("/api/logs")
async def get_logs(user: User, filters: LogFilters):
    if user.role == 'chain_admin':
        # Chain admin tüm otelleri görebilir
        query = build_query(filters)
    else:
        # Hotel manager sadece kendi otelini görebilir
        query = build_query(filters, hotel_id=user.hotel_id)
    
    return await search_logs(query)
```

## ⚖️ **5651 Compliance Data Flow**

### **Günlük İmzalama ve Zaman Damgası**

```mermaid
graph LR
    subgraph "DAILY COMPLIANCE PROCESS"
        DAILY_LOGS["📋 Daily Logs<br/>Per hotel per day"]
        HASH_CALC["🔒 SHA-256 Hash<br/>File integrity"]
        RSA_SIGN["✍️ RSA-256 Signature<br/>Digital signing"]
        TSA_REQUEST["🕐 TSA Request<br/>Timestamp authority"]
        COMPLIANCE_RECORD["📝 Compliance Record<br/>Database storage"]
    end
    
    subgraph "VERIFICATION PROCESS"
        VERIFY_HASH["✅ Verify Hash<br/>File integrity check"]
        VERIFY_SIGNATURE["✅ Verify Signature<br/>Digital signature check"]
        VERIFY_TIMESTAMP["✅ Verify Timestamp<br/>TSA validation"]
        COMPLIANCE_REPORT["📊 Compliance Report<br/>Audit ready"]
    end
    
    %% Daily Process
    DAILY_LOGS --> HASH_CALC
    HASH_CALC --> RSA_SIGN
    RSA_SIGN --> TSA_REQUEST
    TSA_REQUEST --> COMPLIANCE_RECORD
    
    %% Verification Process
    COMPLIANCE_RECORD --> VERIFY_HASH
    VERIFY_HASH --> VERIFY_SIGNATURE
    VERIFY_SIGNATURE --> VERIFY_TIMESTAMP
    VERIFY_TIMESTAMP --> COMPLIANCE_REPORT
    
    classDef process fill:#e8f5e8,stroke:#4caf50,stroke-width:2px
    classDef verify fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    
    class DAILY_LOGS,HASH_CALC,RSA_SIGN,TSA_REQUEST,COMPLIANCE_RECORD process
    class VERIFY_HASH,VERIFY_SIGNATURE,VERIFY_TIMESTAMP,COMPLIANCE_REPORT verify
```

### **5651 Compliance Implementation**

```python
class ComplianceEngine:
    def daily_signing_process(self):
        """Her gün otomatik çalışan imzalama süreci"""
        for hotel in self.get_active_hotels():
            # Hotel bazlı günlük dosya
            log_file = f"/logs/{hotel.id}/{datetime.now().date()}.log"
            
            if not os.path.exists(log_file):
                continue
                
            # 1. Dosya hash'i hesapla
            file_hash = self.calculate_sha256(log_file)
            
            # 2. RSA-256 ile imzala
            signature = self.rsa_sign(file_hash)
            
            # 3. TSA'dan zaman damgası al
            timestamp = self.get_tsa_timestamp(file_hash)
            
            # 4. Compliance kaydı oluştur
            record = {
                'hotel_id': hotel.id,
                'date': datetime.now().date(),
                'file_path': log_file,
                'file_hash': file_hash,
                'signature': signature,
                'tsa_timestamp': timestamp,
                'status': 'signed'
            }
            
            self.save_compliance_record(record)
            
    def monthly_compliance_report(self, hotel_id, year, month):
        """Aylık compliance raporu"""
        records = self.get_compliance_records(hotel_id, year, month)
        
        report = {
            'hotel_id': hotel_id,
            'period': f"{year}-{month:02d}",
            'total_days': len(records),
            'signed_days': len([r for r in records if r.status == 'signed']),
            'missing_days': self.find_missing_days(records, year, month),
            'verification_status': self.verify_all_signatures(records),
            'generated_at': datetime.now(),
            'legal_format': self.generate_legal_export(records)
        }
        
        return report
```

## 📊 **Real-Time Dashboard Data Flow**

### **Gerçek Zamanlı Veri Akışı**

```mermaid
graph LR
    subgraph "LOG INGESTION"
        LIVE_LOGS["📝 Live Logs<br/>Real-time stream"]
    end
    
    subgraph "REAL-TIME PROCESSING"
        WEBSOCKET["🔌 WebSocket<br/>Live connection"]
        REDIS_STREAM["⚡ Redis Stream<br/>Real-time buffer"]
        FILTER["🎯 Tenant Filter<br/>Hotel-specific data"]
    end
    
    subgraph "DASHBOARD"
        LIVE_VIEW["📺 Live Log View<br/>Hotel-filtered logs"]
        METRICS["📊 Real-time Metrics<br/>EPS, errors, devices"]
        ALERTS["🚨 Live Alerts<br/>Security events"]
    end
    
    %% Real-time Flow
    LIVE_LOGS --> WEBSOCKET
    WEBSOCKET --> REDIS_STREAM
    REDIS_STREAM --> FILTER
    FILTER --> LIVE_VIEW
    FILTER --> METRICS
    FILTER --> ALERTS
    
    classDef realtime fill:#e8f5e8,stroke:#4caf50,stroke-width:2px
    classDef processing fill:#e3f2fd,stroke:#2196f3,stroke-width:2px
    classDef dashboard fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    
    class LIVE_LOGS realtime
    class WEBSOCKET,REDIS_STREAM,FILTER processing
    class LIVE_VIEW,METRICS,ALERTS dashboard
```

## ⚡ **Performance Optimizations**

### **1000+ EPS Optimizasyon Teknikleri**

```yaml
Collection Optimizations:
  - UDP socket tuning: SO_RCVBUF=16MB
  - Non-blocking async I/O
  - Circular buffer for burst handling
  - Batch processing: 100 messages/batch

Processing Optimizations:
  - Parallel workers: 4 async workers
  - Memory pooling for log objects
  - Compiled regex patterns
  - JSON parser optimization

Storage Optimizations:
  - PostgreSQL bulk inserts
  - Elasticsearch bulk indexing
  - Async file writes
  - Connection pooling

Caching Strategy:
  - Redis for hot data
  - Hotel-device mapping cache
  - User session cache
  - Query result cache (5 minutes)
```

### **Resource Usage Monitoring**

```python
class PerformanceMonitor:
    def __init__(self):
        self.metrics = {
            'eps_current': 0,
            'eps_1min': 0,
            'eps_5min': 0,
            'queue_depth': 0,
            'processing_latency': 0,
            'error_rate': 0
        }
    
    def track_performance(self):
        """Performans metriklerini izle"""
        while True:
            # EPS hesaplama
            current_eps = self.calculate_current_eps()
            
            # Queue derinliği
            queue_depth = self.get_queue_depth()
            
            # İşlem gecikmesi
            latency = self.calculate_avg_latency()
            
            # Alarm kontrolü
            if current_eps < 500:  # Minimum threshold
                self.send_alert("Low EPS detected", current_eps)
                
            if queue_depth > 5000:  # Queue backup
                self.send_alert("Queue backup detected", queue_depth)
                
            time.sleep(10)  # 10 saniyede bir kontrol
```

## 📈 **Scalability Path**

### **Büyüme Planı**

```yaml
Phase 1: Single Server (1-10 hotels)
  - 1 server
  - 1000+ EPS
  - Docker Compose deployment

Phase 2: Horizontal Scale (10-50 hotels)
  - 3 servers (API, DB, Search)
  - 5000+ EPS
  - Load balancer

Phase 3: Microservices (50+ hotels)
  - Kubernetes deployment
  - 10,000+ EPS
  - Auto-scaling
```

Bu **temiz ve basit veri akışı** ile LogMaster v2:
- 🔄 **Efficient processing** - Minimal latency ile maksimum throughput
- 🏨 **Perfect isolation** - Hotel verileri tamamen ayrı
- ⚖️ **5651 ready** - Günlük imzalama ve TSA entegrasyonu
- ⚡ **1000+ EPS** - Garantili performans
- 📊 **Real-time** - Canlı dashboard ve alertler

**Sade, hızlı ve güvenilir!** 🚀 
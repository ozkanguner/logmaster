# 📊 Module 1.1: RSyslog Server

Production-ready RSyslog 8.x server in Docker container with TLS support and monitoring.

## 🚀 Quick Start

```bash
# Option 1: Native Installation (En İyi - No Docker)
sudo chmod +x install-native.sh test-native.sh
sudo ./install-native.sh
sudo ./test-native.sh

# Option 2: Docker Simple Installation
chmod +x install-simple.sh test.sh
./install-simple.sh
./test.sh

# Option 3: Docker Full Installation (May hang on MySQL)
chmod +x install.sh test.sh
./install.sh
./test.sh
```

## ⚡ Kurulum Seçenekleri Karşılaştırma

| Feature | install-native.sh | install-simple.sh | install.sh |
|---------|-------------------|------------------|------------|
| **Docker Required** | ❌ No | ✅ Yes | ✅ Yes |
| **MySQL Support** | ❌ Skipped | ❌ Skipped | ✅ Included |
| **Installation Time** | ⚡ 1-2 min | ⚡ 2-3 min | 🐌 5-10 min |
| **Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Resource Usage** | 🔥 Minimal | 📦 Medium | 📦 High |
| **Reliability** | ✅ Excellent | ✅ Stable | ⚠️ May hang |
| **System Integration** | ✅ Native | ❌ Container | ❌ Container |
| **5651 Compliance** | ✅ Yes | ✅ Yes | ✅ Yes |

**💡 Recommendation:** Use `install-native.sh` for best performance and reliability!

## 📦 What's Included

- **RSyslog 8.x** with all modules
- **TLS/SSL** auto-generated certificates
- **Multi-protocol** support: UDP 514, TCP 514, TLS 6514
- **Health monitoring** and automatic restarts
- **Docker volumes** for persistent data
- **Comprehensive testing** suite

## 🔧 Management

### Native Installation:
```bash
# View logs
tail -f /var/log/rsyslog/messages
journalctl -u rsyslog -f

# Service management
systemctl status rsyslog
systemctl restart rsyslog
systemctl stop rsyslog

# Test message
echo 'test message' | nc -u localhost 514
```

## 📊 Monitoring

```bash
# Quick monitoring dashboard
chmod +x monitor.sh
./monitor.sh

# Auto-refresh monitoring (updates every 10 seconds)
watch -n 10 ./monitor.sh

# Live log stream
tail -f /var/log/rsyslog/messages

# Only hotspot logs
tail -f /var/log/rsyslog/messages | grep -i hotspot
```

### Monitoring Features:
- ✅ Service health check
- ✅ Port status (UDP/TCP 514)
- ✅ Log file size and activity
- ✅ Recent message count (5 min)
- ✅ Mikrotik hotspot activity
- ✅ Top log sources
- ✅ Disk usage alerts

## 🏨 Multi-Tenant Configuration

### Static Multi-Tenant (Pre-defined hotels):
```bash
# Setup multi-tenant log separation by hotel
sudo chmod +x configure-multitenant.sh
sudo ./configure-multitenant.sh
```

### Dynamic Multi-Tenant (Auto-detect new hotels):
```bash
# Setup dynamic multi-tenant (RECOMMENDED)
sudo chmod +x configure-dynamic-multitenant.sh
sudo ./configure-dynamic-multitenant.sh
```

### Nested Multi-Tenant (Zone/Hotel structure):
```bash
# Setup nested structure (ADVANCED - Based on real Mikrotik logs)
sudo chmod +x configure-nested-multitenant.sh
sudo ./configure-nested-multitenant.sh
```

### Monitoring:
```bash
# Multi-tenant monitoring dashboard
chmod +x monitor-multitenant.sh
./monitor-multitenant.sh

# Nested monitoring dashboard (Zone/Hotel)
chmod +x monitor-nested-multitenant.sh
./monitor-nested-multitenant.sh

# Auto-refresh monitoring
watch -n 30 ./monitor-multitenant.sh         # Standard
watch -n 30 ./monitor-nested-multitenant.sh  # Nested

# Monitor auto-creation logs
tail -f /var/log/hotel-monitor.log     # Standard
tail -f /var/log/nested-monitor.log    # Nested
```

### Multi-Tenant Features:
- 🏨 **Hotel-based log separation** (SISLI_HOTSPOT, FOURSIDES_HOTEL, etc.)
- 🤖 **Dynamic hotel detection** - New hotels auto-create directories
- 📅 **Daily log rotation** (YYYY-MM-DD.log format)
- 📊 **Per-hotel monitoring** and statistics
- 🔍 **Unknown source detection** and isolation
- 📈 **Hotel activity comparison** and ranking
- ⚡ **Real-time directory creation** from log patterns

### Log Structure Options:

#### Standard Multi-Tenant:
```
/var/log/rsyslog/
├── SISLI_HOTSPOT/          # Auto-created
│   ├── 2025-01-24.log
│   └── 2025-01-25.log
├── FOURSIDES_HOTEL/        # Auto-created
│   ├── 2025-01-24.log
│   └── 2025-01-25.log
└── unknown/                # Unidentified sources
    └── 2025-01-24.log
```

#### Nested Multi-Tenant (Zone/Hotel):
```
/var/log/rsyslog/
├── SISLI_HOTSPOT/              # Zone (Bölge)
│   ├── 38_HOTEL/               # Hotel (Otel)
│   │   └── 2025-01-24.log
│   ├── ADELMAR_HOTEL/          # Hotel (Otel)
│   │   └── 2025-01-24.log
│   ├── FOURSIDES_HOTEL/        # Hotel (Otel)
│   │   └── 2025-01-24.log
│   ├── ATRO_HOTEL/             # Hotel (Otel)
│   │   └── 2025-01-24.log
│   ├── dhcp/                   # DHCP logs
│   │   └── 2025-01-24.log
│   └── system/                 # Other system logs
│       └── 2025-01-24.log
└── unknown/unknown/            # Unidentified sources
    └── 2025-01-24.log
```

**Dynamic Features:**
- ✅ New hotel names automatically detected from logs
- ✅ Directories created in real-time (Zone/Hotel structure)
- ✅ Supports patterns: `srcnat: in:HOTEL_NAME` or `HOTEL_NAME`
- ✅ Zone extraction from timestamp area
- ✅ Perfect match for Mikrotik log format

### Docker Installation:
```bash
# View logs
docker logs rsyslog-server-1.1

# Container management
docker stop rsyslog-server-1.1
docker start rsyslog-server-1.1
docker restart rsyslog-server-1.1

# Rebuild from scratch
./install-simple.sh
```

## 🧪 Testing

The `test.sh` script runs 20 comprehensive tests:
- Container health checks
- Port accessibility  
- Log message reception
- Performance validation
- Security checks
- Memory/disk usage

## 📊 Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 514  | UDP      | Standard Syslog |
| 514  | TCP      | Reliable Syslog |
| 6514 | TCP/TLS  | Secure Syslog |

## ✅ Success Criteria

Module 1.1 is complete when all tests pass:
- ✅ Container running and healthy
- ✅ All ports listening  
- ✅ Log messages received and stored
- ✅ Performance targets met
- ✅ SSL/TLS working

## 🔄 Next Module

After successful testing, proceed to:
```bash
git checkout -b module-1.2-tenant-database-schema
```

---

**LogMaster Project** - 5651 Compliance Logging System 
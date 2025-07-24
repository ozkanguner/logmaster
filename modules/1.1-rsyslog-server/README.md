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

```bash
# Setup multi-tenant log separation by hotel
sudo chmod +x configure-multitenant.sh
sudo ./configure-multitenant.sh

# Multi-tenant monitoring dashboard
chmod +x monitor-multitenant.sh
./monitor-multitenant.sh

# Auto-refresh multi-tenant monitoring
watch -n 30 ./monitor-multitenant.sh
```

### Multi-Tenant Features:
- 🏨 **Hotel-based log separation** (SISLI_HOTSPOT, FOURSIDES_HOTEL, etc.)
- 📅 **Daily log rotation** (YYYY-MM-DD.log format)
- 📊 **Per-hotel monitoring** and statistics
- 🔍 **Unknown source detection** and isolation
- 📈 **Hotel activity comparison** and ranking

### Log Structure:
```
/var/log/rsyslog/
├── SISLI_HOTSPOT/
│   ├── 2025-01-24.log
│   └── 2025-01-25.log
├── FOURSIDES_HOTEL/
│   ├── 2025-01-24.log
│   └── 2025-01-25.log
├── ATIRO_HOTEL/
└── unknown/          # Unidentified sources
```

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
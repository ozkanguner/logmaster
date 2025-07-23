# 📊 Module 1.1: RSyslog Server

Production-ready RSyslog 8.x server in Docker container with TLS support and monitoring.

## 🚀 Quick Start

```bash
# Option 1: Simple Installation (Recommended)
chmod +x install-simple.sh test.sh
./install-simple.sh

# Option 2: Full Installation (May hang on MySQL)
chmod +x install.sh test.sh  
./install.sh

# Test everything  
./test.sh
```

## ⚡ install-simple.sh vs install.sh

| Feature | install-simple.sh | install.sh |
|---------|-------------------|------------|
| **MySQL Support** | ❌ Skipped | ✅ Included |
| **Installation Time** | ⚡ 2-3 min | 🐌 5-10 min |
| **Dependencies** | 🔧 Minimal | 📦 Full |
| **Reliability** | ✅ Stable | ⚠️ May hang |
| **5651 Compliance** | ✅ Yes | ✅ Yes |

**Recommendation:** Use `install-simple.sh` for faster, more reliable deployment.

## 📦 What's Included

- **RSyslog 8.x** with all modules
- **TLS/SSL** auto-generated certificates
- **Multi-protocol** support: UDP 514, TCP 514, TLS 6514
- **Health monitoring** and automatic restarts
- **Docker volumes** for persistent data
- **Comprehensive testing** suite

## 🔧 Management

```bash
# View logs
docker logs rsyslog-server-1.1

# Stop services
docker-compose down

# Restart services  
docker-compose restart

# Rebuild from scratch
docker-compose down && ./install.sh
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
# LogMaster Installation Guide

This guide will walk you through installing LogMaster Auto-Discovery log management system on Ubuntu 22.04 LTS.

## Prerequisites

### System Requirements
- **Operating System**: Ubuntu 22.04 LTS Server
- **CPU**: 4+ cores (recommended 8+ for production)
- **Memory**: 16GB RAM minimum (32GB+ recommended for production)
- **Storage**: 100GB+ available disk space
- **Network**: Access to Mikrotik devices on UDP port 514

### Network Requirements
- **Inbound Ports**: 514/UDP (syslog), 3000/TCP (dashboard), 3001/TCP (Grafana), 8080/TCP (API)
- **Outbound**: Internet access for package installation
- **Static IP**: Recommended for production deployments

## Quick Installation

### 1. Clone Repository
```bash
git clone https://github.com/ozkanguner/logmaster.git
cd logmaster
```

### 2. Run Installation Script
```bash
sudo chmod +x scripts/install.sh
sudo ./scripts/install.sh
```

The installation script will automatically:
- Update system packages
- Install all dependencies (Go, Node.js, PostgreSQL, Redis, Elasticsearch, Grafana, etc.)
- Create LogMaster user and directories
- Configure RSyslog for auto-discovery
- Build and deploy LogMaster components
- Configure and start all services

### 3. Verify Installation
```bash
# Check service status
sudo systemctl status logmaster-api
sudo systemctl status rsyslog
sudo systemctl status grafana-server

# Check ports
sudo ss -tlnp | grep -E ":514|:3000|:3001|:8080"

# Test auto-discovery
logger -n 127.0.0.1 -P 514 -t "RouterOS" "HOTEL interface up - test"
```

## Manual Installation

If you prefer to install components manually or need to customize the installation:

### 1. System Preparation
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install basic dependencies
sudo apt install -y curl wget git tree htop net-tools tcpdump
```

### 2. Install Go
```bash
GO_VERSION="1.21.6"
wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile
source /etc/profile
```

### 3. Install Node.js
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### 4. Install Databases
```bash
# PostgreSQL
sudo apt install -y postgresql-14

# Redis
sudo apt install -y redis-server

# Elasticsearch
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt update && sudo apt install -y elasticsearch
```

### 5. Install Monitoring
```bash
# Prometheus
sudo apt install -y prometheus

# Grafana
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update && sudo apt install -y grafana
```

### 6. Create LogMaster User
```bash
sudo useradd -r -s /bin/false -d /opt/logmaster logmaster
sudo mkdir -p /opt/logmaster /var/log/logmaster
sudo chown -R logmaster:logmaster /opt/logmaster
sudo chown -R syslog:adm /var/log/logmaster
```

### 7. Configure RSyslog
```bash
# Copy auto-discovery configuration
sudo cp rsyslog/60-logmaster-auto.conf /etc/rsyslog.d/

# Test configuration
sudo rsyslog -N1

# Restart RSyslog
sudo systemctl restart rsyslog
```

### 8. Build LogMaster Application
```bash
# Copy application files
sudo cp -r cmd pkg configs /opt/logmaster/
sudo cp go.mod /opt/logmaster/

# Build application
cd /opt/logmaster
sudo -u logmaster go mod tidy
sudo -u logmaster go build -o bin/logmaster-api cmd/api-gateway/main.go
```

### 9. Setup Frontend
```bash
# Copy frontend files
sudo cp -r frontend /opt/logmaster/

# Build React application
cd /opt/logmaster/frontend/logmaster-dashboard
sudo npm install
sudo npm run build
```

### 10. Configure systemd Services
```bash
# Create LogMaster API service
sudo tee /etc/systemd/system/logmaster-api.service > /dev/null << 'EOF'
[Unit]
Description=LogMaster API Gateway
After=network.target

[Service]
Type=simple
User=logmaster
Group=logmaster
WorkingDirectory=/opt/logmaster
ExecStart=/opt/logmaster/bin/logmaster-api
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable logmaster-api
sudo systemctl start logmaster-api
```

## Post-Installation Configuration

### 1. Configure Firewall
```bash
# Allow required ports
sudo ufw allow 514/udp comment "RSyslog"
sudo ufw allow 3000/tcp comment "LogMaster Dashboard"
sudo ufw allow 3001/tcp comment "Grafana"
sudo ufw allow 8080/tcp comment "LogMaster API"

# Enable firewall (if not already enabled)
sudo ufw --force enable
```

### 2. Configure Log Rotation
```bash
# LogMaster log rotation is automatically configured
# Check configuration:
cat /etc/logrotate.d/logmaster
```

### 3. Database Setup
```bash
# PostgreSQL (for metadata)
sudo -u postgres createuser logmaster
sudo -u postgres createdb logmaster -O logmaster
sudo -u postgres psql -c "ALTER USER logmaster PASSWORD 'logmaster_password';"

# Redis (for caching) - no additional configuration needed

# Elasticsearch (for log search)
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
```

## Verification and Testing

### 1. Service Health Check
```bash
# Check all services
sudo systemctl status logmaster-api rsyslog postgresql redis-server elasticsearch grafana-server

# Check LogMaster API
curl http://localhost:8080/health

# Check RSyslog is listening
sudo ss -ulnp | grep :514
```

### 2. Test Auto-Discovery
```bash
# Send test log with HOTEL interface
logger -n 127.0.0.1 -P 514 -t "RouterOS" "HOTEL interface eth1 up"

# Check if directory was created automatically
sleep 2
ls -la /var/log/logmaster/127.0.0.1/

# Should show: HOTEL directory with today's log file
```

### 3. Access Web Interfaces
- **LogMaster Dashboard**: `http://your-server-ip:3000`
- **Grafana**: `http://your-server-ip:3001` (admin/admin123)
- **LogMaster API**: `http://your-server-ip:8080/health`

## Mikrotik Configuration

Configure your Mikrotik devices to send logs to LogMaster:

```bash
# Connect to Mikrotik via SSH or Winbox terminal
/system logging action add name=logmaster target=remote remote=YOUR_LOGMASTER_IP remote-port=514
/system logging add topics=system action=logmaster
/system logging add topics=info action=logmaster

# Test logging
:log info "HOTEL interface ready - LogMaster auto-discovery test"
```

## Troubleshooting

### Common Issues

#### RSyslog not receiving logs
```bash
# Check RSyslog status
sudo systemctl status rsyslog

# Check if port 514 is listening
sudo ss -ulnp | grep :514

# Check firewall
sudo ufw status

# Test local logging
logger -n 127.0.0.1 -P 514 "test message"
```

#### LogMaster API not starting
```bash
# Check service logs
sudo journalctl -u logmaster-api -f

# Check Go dependencies
cd /opt/logmaster && go mod tidy

# Check permissions
sudo chown -R logmaster:logmaster /opt/logmaster
```

#### Frontend not accessible
```bash
# Check if React build exists
ls -la /opt/logmaster/frontend/logmaster-dashboard/build/

# Rebuild if necessary
cd /opt/logmaster/frontend/logmaster-dashboard
sudo npm run build
```

#### Auto-discovery not working
```bash
# Check RSyslog configuration
sudo rsyslog -N1

# Check log directory permissions
ls -la /var/log/logmaster/

# Send test log and monitor
logger -n 127.0.0.1 -P 514 -t "RouterOS" "HOTEL test" && sleep 2 && find /var/log/logmaster/ -name "*.log" -exec tail -1 {} \;
```

## Performance Tuning

### For High-Volume Environments (50K+ logs/minute)

#### RSyslog Optimization
```bash
# Add to /etc/rsyslog.conf
$MainMsgQueueSize 100000
$MainMsgQueueHighWatermark 80000
$MainMsgQueueLowWatermark 20000
$MainMsgQueueMaxFileSize 100M
$ActionQueueMaxDiskSpace 2G
```

#### System Optimization
```bash
# Increase file limits
echo "logmaster soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "logmaster hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Optimize disk I/O
sudo echo 'deadline' > /sys/block/sda/queue/scheduler
```

## Security Hardening

### 1. Enable Authentication
```bash
# Edit LogMaster configuration
sudo nano /opt/logmaster/configs/config.yaml

# Set:
security:
  authentication:
    enabled: true
    jwt_secret: "your-secure-secret-here"
```

### 2. SSL/TLS Configuration
```bash
# Generate SSL certificates
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/logmaster.key \
  -out /etc/ssl/certs/logmaster.crt

# Update configuration
production:
  ssl:
    enabled: true
    cert_file: "/etc/ssl/certs/logmaster.crt"
    key_file: "/etc/ssl/private/logmaster.key"
```

### 3. Database Security
```bash
# Secure PostgreSQL
sudo -u postgres psql -c "ALTER USER logmaster PASSWORD 'very-secure-password';"

# Secure Redis
sudo nano /etc/redis/redis.conf
# Add: requirepass your-redis-password
```

## Backup and Recovery

### 1. Backup Script
```bash
sudo tee /opt/logmaster/scripts/backup.sh > /dev/null << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/logmaster"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p ${BACKUP_DIR}

# Backup configurations
tar -czf ${BACKUP_DIR}/config_${DATE}.tar.gz /opt/logmaster/configs/

# Backup database
sudo -u postgres pg_dump logmaster > ${BACKUP_DIR}/database_${DATE}.sql

# Backup recent logs (last 7 days)
find /var/log/logmaster/ -mtime -7 -type f -name "*.log" | \
  tar -czf ${BACKUP_DIR}/logs_${DATE}.tar.gz -T -

echo "Backup completed: ${BACKUP_DIR}"
EOF

sudo chmod +x /opt/logmaster/scripts/backup.sh
```

### 2. Automated Backup
```bash
# Add to crontab
echo "0 2 * * * /opt/logmaster/scripts/backup.sh" | sudo crontab -
```

## Monitoring and Maintenance

### 1. Health Monitoring
```bash
# Create health check script
sudo tee /opt/logmaster/scripts/health-check.sh > /dev/null << 'EOF'
#!/bin/bash
curl -f http://localhost:8080/health || exit 1
systemctl is-active --quiet rsyslog || exit 1
systemctl is-active --quiet logmaster-api || exit 1
EOF
```

### 2. Log Cleanup
```bash
# Automatic log cleanup is handled by logrotate
# Check configuration:
cat /etc/logrotate.d/logmaster
```

## Next Steps

After successful installation:

1. **Configure Mikrotik Devices**: Send logs to LogMaster
2. **Set Up Monitoring**: Configure Grafana dashboards
3. **User Management**: Set up user accounts and access controls
4. **Backup Strategy**: Implement regular backups
5. **Security Hardening**: Enable authentication and SSL

For detailed configuration options, see [Configuration Reference](configuration.md).
For API usage, see [API Documentation](api.md).
For troubleshooting, see [Troubleshooting Guide](troubleshooting.md).
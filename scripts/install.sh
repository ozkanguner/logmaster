#!/bin/bash

# 🚀 LogMaster Auto-Discovery Installation Script
# Ubuntu 22.04 LTS - Production Ready Installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOGMASTER_USER="logmaster"
LOGMASTER_HOME="/opt/logmaster"
LOG_DIR="/var/log/logmaster"
CONFIG_DIR="${LOGMASTER_HOME}/configs"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
fi

log "🚀 Starting LogMaster Auto-Discovery Installation"

# Step 1: System Update
log "📦 Updating system packages..."
apt update && apt upgrade -y

# Step 2: Install base dependencies
log "🔧 Installing base dependencies..."
apt install -y \
    curl \
    wget \
    git \
    tree \
    htop \
    net-tools \
    tcpdump \
    rsyslog \
    logrotate \
    nginx \
    nodejs \
    npm

# Step 3: Install Go
log "🐹 Installing Go..."
if ! command -v go &> /dev/null; then
    GO_VERSION="1.21.6"
    wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
    rm go${GO_VERSION}.linux-amd64.tar.gz
    
    # Add Go to PATH
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    export PATH=$PATH:/usr/local/go/bin
else
    log "Go already installed: $(go version)"
fi

# Step 4: Skip Grafana - Simple file-based system
log "📁 Simple file-based system - No Grafana needed"

# Step 5: Skip Elasticsearch - File-based log storage
log "📁 File-based log storage - No Elasticsearch needed"

# Step 6: Create LogMaster user and directories
log "👤 Creating LogMaster user and directories..."
if ! id "$LOGMASTER_USER" &>/dev/null; then
    useradd -r -s /bin/false -d "$LOGMASTER_HOME" "$LOGMASTER_USER"
fi

mkdir -p "$LOGMASTER_HOME"
mkdir -p "$CONFIG_DIR"
mkdir -p "$LOG_DIR"
mkdir -p /var/log/grafana

# Set ownership
chown -R "$LOGMASTER_USER":"$LOGMASTER_USER" "$LOGMASTER_HOME"
chown -R syslog:adm "$LOG_DIR"
chmod 755 "$LOG_DIR"

# Step 7: Copy LogMaster files
log "📁 Copying LogMaster application files..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Copy Go application
cp -r "$PROJECT_ROOT/cmd" "$LOGMASTER_HOME/"
cp -r "$PROJECT_ROOT/pkg" "$LOGMASTER_HOME/"
cp "$PROJECT_ROOT/go.mod" "$LOGMASTER_HOME/"
cp "$PROJECT_ROOT/go.sum" "$LOGMASTER_HOME/" 2>/dev/null || true

# Copy configurations
cp -r "$PROJECT_ROOT/configs/"* "$CONFIG_DIR/"
cp -r "$PROJECT_ROOT/rsyslog/"* /etc/rsyslog.d/

# Copy frontend
if [ -d "$PROJECT_ROOT/frontend" ]; then
    cp -r "$PROJECT_ROOT/frontend" "$LOGMASTER_HOME/"
fi

# Set ownership for copied files
chown -R "$LOGMASTER_USER":"$LOGMASTER_USER" "$LOGMASTER_HOME"

# Step 8: Configure RSyslog
log "📡 Configuring RSyslog for auto-discovery..."

# Backup existing rsyslog config if exists
if [ -f /etc/rsyslog.d/50-logmaster.conf ]; then
    mv /etc/rsyslog.d/50-logmaster.conf /etc/rsyslog.d/50-logmaster.conf.backup
fi

# Install LogMaster auto-discovery config
cat > /etc/rsyslog.d/60-logmaster-auto.conf << 'EOF'
# 🤖 LogMaster Auto-Discovery Configuration
module(load="imudp")

# UDP input - Listen for all IPs
input(type="imudp" port="514")

# Dynamic path template - AUTO directory creation
template(name="AutoDiscoveryPath" type="string" 
         string="/var/log/logmaster/%fromhost-ip%/%$.interface%/%$year%-%$month%-%$day%.log")

# JSON template - Structured logging
template(name="AutoJSON" type="list") {
    constant(value="{")
    constant(value="\"timestamp\":\"")     property(name="timereported" dateFormat="rfc3339")
    constant(value="\",\"ip\":\"")         property(name="fromhost-ip")
    constant(value="\",\"interface\":\"")  property(name="$.interface")
    constant(value="\",\"facility\":\"")   property(name="syslogfacility-text")
    constant(value="\",\"severity\":\"")   property(name="syslogseverity-text")
    constant(value="\",\"message\":\"")    property(name="msg" format="json")
    constant(value="\"}")
    constant(value="\n")
}

# AUTOMATIC INTERFACE DETECTION - No manual configuration needed!
if ($fromhost-ip != "127.0.0.1") then {
    
    # Default interface
    set $.interface = "general";
    
    # Smart interface detection (single pass)
    if ($msg contains "HOTEL") then {
        set $.interface = "HOTEL";
    } else if ($msg contains "CAFE") then {
        set $.interface = "CAFE";
    } else if ($msg contains "RESTAURANT") then {
        set $.interface = "RESTAURANT";
    } else if ($msg contains "AVM") then {
        set $.interface = "AVM";
    } else if ($msg contains "OKUL") then {
        set $.interface = "OKUL";
    } else if ($msg contains "YURT") then {
        set $.interface = "YURT";
    } else if ($msg contains "KONUKEVI") then {
        set $.interface = "KONUKEVI";
    }
    
    # AUTOMATIC FILE WRITING - createDirs="on" creates all directories!
    action(type="omfile" dynaFile="AutoDiscoveryPath" 
           template="AutoJSON"
           fileCreateMode="0644"
           dirCreateMode="0755"
           createDirs="on"
           flushOnTXEnd="on")
    stop
}
EOF

# Test RSyslog configuration
if rsyslog -N1; then
    log "RSyslog configuration validated successfully"
else
    error "RSyslog configuration validation failed"
fi

# Step 9: Configure Grafana
log "📊 Configuring Grafana..."
sed -i 's/;http_port = 3000/http_port = 3001/' /etc/grafana/grafana.ini
grafana-cli admin reset-admin-password admin123

# Step 10: Build Go application
log "🔨 Building Go application..."
cd "$LOGMASTER_HOME"
export PATH=$PATH:/usr/local/go/bin
go mod tidy
go build -o bin/logmaster-api cmd/api-gateway/main.go

# Step 11: Create systemd services
log "🔧 Creating systemd services..."

# LogMaster API service
cat > /etc/systemd/system/logmaster-api.service << EOF
[Unit]
Description=LogMaster API Gateway
After=network.target
Wants=network.target

[Service]
Type=simple
User=$LOGMASTER_USER
Group=$LOGMASTER_USER
WorkingDirectory=$LOGMASTER_HOME
ExecStart=$LOGMASTER_HOME/bin/logmaster-api
Restart=always
RestartSec=5
Environment=PATH=/usr/local/go/bin:/usr/bin:/bin
Environment=LOGMASTER_CONFIG=$CONFIG_DIR/config.yaml

[Install]
WantedBy=multi-user.target
EOF

# LogMaster log rotation
cat > /etc/logrotate.d/logmaster << 'EOF'
/var/log/logmaster/*/*/*log {
    daily
    missingok
    rotate 365
    compress
    delaycompress
    notifempty
    create 644 syslog adm
    postrotate
        systemctl reload rsyslog
    endscript
}
EOF

# Step 12: Configure firewall
log "🔥 Configuring firewall..."
ufw allow 514/udp comment "RSyslog"
ufw allow 3000/tcp comment "LogMaster Dashboard"
ufw allow 8080/tcp comment "LogMaster API"

# Step 13: Enable and start services
log "🚀 Starting services..."
systemctl daemon-reload

# Enable services
systemctl enable rsyslog
systemctl enable logmaster-api

# Start services
systemctl restart rsyslog
systemctl start logmaster-api

# Step 14: Wait for services to start
log "⏳ Waiting for services to start..."
sleep 10

# Step 15: Install and start React frontend if exists
if [ -d "$LOGMASTER_HOME/frontend/logmaster-dashboard" ]; then
    log "⚛️ Setting up React frontend..."
    cd "$LOGMASTER_HOME/frontend/logmaster-dashboard"
    
    # Install dependencies
    npm install
    
    # Create .env file
    echo 'PORT=3000' > .env
    echo 'REACT_APP_API_URL=http://localhost:8080' >> .env
    
    # Start React in background
    nohup npm start > "$LOG_DIR/react.log" 2>&1 &
    
    log "React dashboard starting on port 3000"
fi

# Step 16: Verify installation
log "🔍 Verifying installation..."

# Check service status
services=("rsyslog" "logmaster-api")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        log "✅ $service is running"
    else
        warn "❌ $service is not running"
    fi
done

# Check ports
log "🔍 Checking ports..."
ss -tlnp | grep -E ":514|:3000|:8080" || true

# Step 17: Test auto-discovery
log "🧪 Testing auto-discovery..."
logger -n 127.0.0.1 -P 514 -t "RouterOS" "HOTEL interface up - LogMaster auto-discovery test"
sleep 2

if [ -d "$LOG_DIR/127.0.0.1/HOTEL" ]; then
    log "✅ Auto-discovery test successful - Directory created automatically"
    log "📁 Created: $LOG_DIR/127.0.0.1/HOTEL/"
else
    warn "❌ Auto-discovery test failed - Check RSyslog configuration"
fi

# Installation complete
log "🎉 LogMaster installation completed successfully!"
echo
echo -e "${GREEN}========================= INSTALLATION SUMMARY =========================${NC}"
echo -e "${BLUE}LogMaster Dashboard:${NC}     http://$(hostname -I | awk '{print $1}'):3000"
echo -e "${BLUE}LogMaster API:${NC}           http://$(hostname -I | awk '{print $1}'):8080"
echo
echo -e "${GREEN}Next Steps:${NC}"
echo -e "1. Configure your Mikrotik devices to send logs to this server"
echo -e "2. Use RSyslog port 514 (UDP) for log collection"
echo -e "3. Monitor logs in: $LOG_DIR"
echo -e "4. Check system status: systemctl status logmaster-api"
echo
echo -e "${GREEN}Mikrotik Configuration Example:${NC}"
echo -e "/system logging action add name=logmaster target=remote remote=$(hostname -I | awk '{print $1}') remote-port=514"
echo -e "/system logging add topics=system action=logmaster"
echo -e ":log info \"HOTEL interface ready - LogMaster auto-discovery test\""
echo
echo -e "${GREEN}Log Directory Structure:${NC}"
tree "$LOG_DIR" 2>/dev/null || find "$LOG_DIR" -type d 2>/dev/null | head -10
echo -e "${GREEN}=========================================================================${NC}"
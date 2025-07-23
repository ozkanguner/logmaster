#!/bin/bash
set -e

# LogMaster Module 1.1: RSyslog Server Docker Installation
# Single script installs and runs everything

echo "🚀 LogMaster Module 1.1: RSyslog Server Installation Starting..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MODULE_NAME="logmaster-rsyslog-server"
MODULE_VERSION="1.1"
CONTAINER_NAME="rsyslog-server-1.1"
IMAGE_NAME="logmaster/rsyslog-server:1.1"

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Check prerequisites
print_step "Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed!"
    echo "Please install Docker first:"
    echo "sudo apt update && sudo apt install -y docker.io"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_warning "docker-compose not found, trying docker compose plugin..."
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available!"
        echo "Please install Docker Compose"
        exit 1
    fi
    DOCKER_COMPOSE_CMD="docker compose"
else
    DOCKER_COMPOSE_CMD="docker-compose"
fi

print_success "Prerequisites check passed"

# Step 2: Create directory structure
print_step "Creating directory structure..."
mkdir -p config scripts
chmod +x scripts/* 2>/dev/null || true

# Step 3: Create Dockerfile
print_step "Creating Dockerfile..."
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

# Install RSyslog and dependencies
RUN apt-get update && apt-get install -y \
    rsyslog \
    rsyslog-gnutls \
    rsyslog-relp \
    rsyslog-elasticsearch \
    rsyslog-mysql \
    rsyslog-pgsql \
    openssl \
    ca-certificates \
    netcat-openbsd \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /etc/rsyslog.d /var/log/rsyslog /etc/ssl/rsyslog \
    && chmod 700 /etc/ssl/rsyslog

# Copy configurations
COPY config/ /etc/rsyslog.d/
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Generate SSL certificates
RUN /usr/local/bin/generate-certs.sh

# Expose ports
EXPOSE 514/udp 514/tcp 6514/tcp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/health-check.sh

# Start RSyslog
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["rsyslogd", "-n", "-f", "/etc/rsyslog.conf"]
EOF

# Step 4: Create configuration files
print_step "Creating RSyslog configuration..."
cat > config/rsyslog.conf << 'EOF'
# LogMaster RSyslog Configuration
$ModLoad imuxsock
$ModLoad imklog
$WorkDirectory /var/spool/rsyslog
$ActionFileDefaultTemplate RSYSLOG_FileFormat
$RepeatedMsgReduction on
$FileOwner root
$FileGroup adm
$FileCreateMode 0640
$DirCreateMode 0755

# Include modular configs
$IncludeConfig /etc/rsyslog.d/*.conf

# Emergency messages
*.emerg :omusrmsg:*

# Basic logging
*.info;mail.none;authpriv.none;cron.none /var/log/rsyslog/messages
authpriv.* /var/log/rsyslog/secure
*.emerg /var/log/rsyslog/emergency
EOF

cat > config/10-network-inputs.conf << 'EOF'
# Network Input Configuration
module(load="imudp")
module(load="imtcp")
module(load="imptcp")

# UDP Syslog receiver
input(type="imudp" port="514" address="0.0.0.0")

# TCP Syslog receiver
input(type="imptcp" port="514" address="0.0.0.0")
EOF

cat > config/20-tls-config.conf << 'EOF'
# TLS Configuration
module(load="imtcp" 
       StreamDriver.Name="gtls"
       StreamDriver.Mode="1"
       StreamDriver.Authmode="anon")

global(
    DefaultNetstreamDriverCAFile="/etc/ssl/rsyslog/server-cert.pem"
    DefaultNetstreamDriverCertFile="/etc/ssl/rsyslog/server-cert.pem"
    DefaultNetstreamDriverKeyFile="/etc/ssl/rsyslog/server-key.pem"
)

# Secure TCP input
input(type="imtcp" 
      port="6514" 
      address="0.0.0.0"
      StreamDriver.Name="gtls"
      StreamDriver.Mode="1"
      StreamDriver.Authmode="anon")
EOF

# Step 5: Create scripts
print_step "Creating helper scripts..."
cat > scripts/generate-certs.sh << 'EOF'
#!/bin/bash
set -e
CERT_DIR="/etc/ssl/rsyslog"

if [ ! -f "$CERT_DIR/server-cert.pem" ]; then
    echo "Generating SSL certificates..."
    openssl genrsa -out "$CERT_DIR/server-key.pem" 2048
    openssl req -new -key "$CERT_DIR/server-key.pem" \
        -out "$CERT_DIR/server.csr" \
        -subj "/C=TR/ST=Istanbul/L=Istanbul/O=LogMaster/CN=rsyslog-server"
    openssl x509 -req -days 365 -in "$CERT_DIR/server.csr" \
        -signkey "$CERT_DIR/server-key.pem" \
        -out "$CERT_DIR/server-cert.pem"
    chmod 600 "$CERT_DIR/server-key.pem"
    chmod 644 "$CERT_DIR/server-cert.pem"
    echo "SSL certificates generated"
fi
EOF

cat > scripts/entrypoint.sh << 'EOF'
#!/bin/bash
set -e

# Generate certificates if needed
/usr/local/bin/generate-certs.sh

# Create log directories
mkdir -p /var/log/rsyslog /var/spool/rsyslog
chown root:adm /var/log/rsyslog
chmod 755 /var/log/rsyslog

# Test configuration
echo "Testing RSyslog configuration..."
rsyslogd -N1 -f /etc/rsyslog.conf

echo "Starting RSyslog server..."
exec "$@"
EOF

cat > scripts/health-check.sh << 'EOF'
#!/bin/bash

# Check RSyslog process
if ! pgrep -f "rsyslogd" > /dev/null; then
    echo "RSyslog process not running"
    exit 1
fi

# Check ports
if ! nc -u -z localhost 514; then
    echo "UDP port 514 not listening"
    exit 1
fi

if ! nc -z localhost 514; then
    echo "TCP port 514 not listening"
    exit 1
fi

if ! nc -z localhost 6514; then
    echo "TLS port 6514 not listening"
    exit 1
fi

echo "RSyslog server is healthy"
exit 0
EOF

chmod +x scripts/*.sh

# Step 6: Create docker-compose.yml
print_step "Creating Docker Compose configuration..."
cat > docker-compose.yml << EOF
version: '3.8'

services:
  rsyslog-server:
    build: .
    image: ${IMAGE_NAME}
    container_name: ${CONTAINER_NAME}
    hostname: rsyslog-server
    restart: unless-stopped
    
    environment:
      - RSYSLOG_DEBUG_LEVEL=0
      - TLS_ENABLED=true
      
    ports:
      - "514:514/udp"
      - "514:514/tcp"  
      - "6514:6514/tcp"
      
    volumes:
      - rsyslog_logs:/var/log/rsyslog
      - rsyslog_spool:/var/spool/rsyslog
      - rsyslog_certs:/etc/ssl/rsyslog
      
    networks:
      - logmaster-network
      
    healthcheck:
      test: ["/usr/local/bin/health-check.sh"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

volumes:
  rsyslog_logs:
  rsyslog_spool:
  rsyslog_certs:
  
networks:
  logmaster-network:
    driver: bridge
EOF

# Step 7: Configure UFW firewall
print_step "Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 514/udp comment 'RSyslog UDP' 2>/dev/null || true
    sudo ufw allow 514/tcp comment 'RSyslog TCP' 2>/dev/null || true
    sudo ufw allow 6514/tcp comment 'RSyslog TLS' 2>/dev/null || true
    print_success "Firewall rules added"
else
    print_warning "UFW not found, skipping firewall configuration"
fi

# Step 8: Build Docker image
print_step "Building Docker image..."
docker build -t ${IMAGE_NAME} .
print_success "Docker image built: ${IMAGE_NAME}"

# Step 9: Start services
print_step "Starting RSyslog server..."
${DOCKER_COMPOSE_CMD} up -d

# Step 10: Wait for startup
print_step "Waiting for service to be ready..."
sleep 10

# Step 11: Basic health check
print_step "Running health check..."
if docker exec ${CONTAINER_NAME} /usr/local/bin/health-check.sh; then
    print_success "RSyslog server is running and healthy!"
else
    print_error "Health check failed!"
    echo "Container logs:"
    docker logs ${CONTAINER_NAME}
    exit 1
fi

# Step 12: Show status
print_step "Installation completed successfully!"
echo ""
echo "📊 Container Status:"
${DOCKER_COMPOSE_CMD} ps
echo ""
echo "🌐 Listening Ports:"
echo "  - UDP 514: Standard Syslog"
echo "  - TCP 514: Reliable Syslog"  
echo "  - TCP 6514: Secure Syslog (TLS)"
echo ""
echo "🔧 Management Commands:"
echo "  - View logs: docker logs ${CONTAINER_NAME}"
echo "  - Stop: ${DOCKER_COMPOSE_CMD} down"
echo "  - Restart: ${DOCKER_COMPOSE_CMD} restart"
echo "  - Test: ./test.sh"
echo ""
echo "✅ Module 1.1 RSyslog Server installation completed!" 
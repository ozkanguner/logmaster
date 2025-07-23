#!/bin/bash
set -e

echo "🚀 LogMaster Module 1.1: Simple RSyslog Installation"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check Docker
print_step "Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo usermod -aG docker $USER
fi

# Simple Dockerfile without MySQL
print_step "Creating simple Dockerfile..."
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    rsyslog \
    rsyslog-gnutls \
    openssl \
    netcat-openbsd \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /etc/rsyslog.d /var/log/rsyslog /etc/ssl/rsyslog

# Basic RSyslog config
RUN echo 'module(load="imudp")' > /etc/rsyslog.d/10-udp.conf && \
    echo 'input(type="imudp" port="514")' >> /etc/rsyslog.d/10-udp.conf && \
    echo 'module(load="imtcp")' > /etc/rsyslog.d/11-tcp.conf && \
    echo 'input(type="imtcp" port="514")' >> /etc/rsyslog.d/11-tcp.conf && \
    echo '*.* /var/log/rsyslog/messages' > /etc/rsyslog.d/50-default.conf

# SSL certificate script
RUN echo '#!/bin/bash' > /usr/local/bin/generate-certs.sh && \
    echo 'mkdir -p /etc/ssl/rsyslog' >> /usr/local/bin/generate-certs.sh && \
    echo 'openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/rsyslog/server-key.pem \
        -out /etc/ssl/rsyslog/server-cert.pem \
        -subj "/C=TR/ST=Istanbul/L=Istanbul/O=LogMaster/CN=rsyslog"' >> /usr/local/bin/generate-certs.sh && \
    chmod +x /usr/local/bin/generate-certs.sh

EXPOSE 514/udp 514/tcp 6514/tcp

CMD ["/usr/sbin/rsyslogd", "-n", "-f", "/etc/rsyslog.conf"]
EOF

# Build Docker image
print_step "Building Docker image..."
docker build -t logmaster/rsyslog-server:1.1 .

# Stop and remove existing container if exists
print_step "Cleaning up existing container..."
docker stop rsyslog-server-1.1 2>/dev/null || true
docker rm rsyslog-server-1.1 2>/dev/null || true

# Create volume if not exists
docker volume create rsyslog-logs 2>/dev/null || true

# Start container with docker run
print_step "Starting container..."
docker run -d \
    --name rsyslog-server-1.1 \
    --restart unless-stopped \
    -p 514:514/udp \
    -p 514:514/tcp \
    -p 6514:6514/tcp \
    -v rsyslog-logs:/var/log/rsyslog \
    logmaster/rsyslog-server:1.1

# Wait and check
sleep 5
print_step "Checking container..."
if docker ps | grep -q "rsyslog-server-1.1"; then
    print_success "RSyslog server started successfully!"
    echo ""
    echo "🎉 Installation completed!"
    echo ""
    echo "📋 Next steps:"
    echo "   ./test.sh    # Run tests"
    echo "   docker logs rsyslog-server-1.1  # View logs"
    echo "   echo 'test' | nc -u localhost 514  # Send test message"
    echo ""
    echo "📦 Container Management:"
    echo "   docker stop rsyslog-server-1.1   # Stop container"
    echo "   docker start rsyslog-server-1.1  # Start container"
    echo "   docker restart rsyslog-server-1.1 # Restart container"
else
    echo "❌ Container failed to start"
    docker logs rsyslog-server-1.1
    exit 1
fi 
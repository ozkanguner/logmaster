#!/bin/bash
# LogMaster v2 - Production Deployment Script
# Ubuntu 22.04 LTS Enterprise Deployment

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
BACKUP_DIR="/backup/logmaster"
LOG_DIR="/var/log/logmaster"
CERTS_DIR="/opt/logmaster/certs"

echo -e "${BLUE}🚀 LogMaster v2 - Enterprise Deployment Starting...${NC}"

# Function to print colored output
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

# Check Ubuntu version
if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    log_warning "This script is optimized for Ubuntu 22.04 LTS"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
log_info "Updating system packages..."
apt update && apt upgrade -y

# Install required packages
log_info "Installing required packages..."
apt install -y \
    curl \
    wget \
    git \
    nginx \
    docker.io \
    docker-compose \
    python3 \
    python3-pip \
    postgresql-client \
    redis-tools \
    ufw \
    htop \
    tree \
    unzip \
    rsyslog \
    logrotate \
    cron \
    supervisor \
    fail2ban \
    certbot \
    python3-certbot-nginx

# Enable and start Docker
log_info "Configuring Docker..."
systemctl enable docker
systemctl start docker
usermod -aG docker $LOGMASTER_USER 2>/dev/null || true

# Create logmaster user if not exists
if ! id "$LOGMASTER_USER" &>/dev/null; then
    log_info "Creating logmaster user..."
    useradd -r -s /bin/bash -d $LOGMASTER_HOME -m $LOGMASTER_USER
fi

# Create necessary directories
log_info "Creating directory structure..."
mkdir -p $LOGMASTER_HOME
mkdir -p $LOG_DIR/{archive,backups,audit}
mkdir -p $BACKUP_DIR
mkdir -p $CERTS_DIR
mkdir -p /var/lib/logmaster
mkdir -p /etc/logmaster

# Set directory permissions
chown -R $LOGMASTER_USER:$LOGMASTER_USER $LOGMASTER_HOME
chown -R $LOGMASTER_USER:$LOGMASTER_USER $LOG_DIR
chown -R $LOGMASTER_USER:$LOGMASTER_USER $BACKUP_DIR
chown -R $LOGMASTER_USER:$LOGMASTER_USER $CERTS_DIR
chmod 755 $LOGMASTER_HOME
chmod 755 $LOG_DIR
chmod 700 $CERTS_DIR

# Clone repository
log_info "Cloning LogMaster v2 repository..."
cd $LOGMASTER_HOME
if [ -d "5651-logging-v2" ]; then
    log_warning "Directory already exists, pulling latest changes..."
    cd 5651-logging-v2
    git pull origin main
else
    git clone https://github.com/ozkanguner/5651-logging-v2.git
    cd 5651-logging-v2
fi

# Copy environment configuration
log_info "Setting up environment configuration..."
if [ ! -f ".env" ]; then
    cp deployment/config/environment.example .env
    log_warning "Please edit .env file with your configuration"
fi

# Generate SSL certificates for RSA signing
log_info "Generating RSA certificates for digital signing..."
if [ ! -f "$CERTS_DIR/private.pem" ]; then
    openssl genrsa -out $CERTS_DIR/private.pem 2048
    openssl rsa -in $CERTS_DIR/private.pem -pubout -out $CERTS_DIR/public.pem
    chmod 600 $CERTS_DIR/private.pem
    chmod 644 $CERTS_DIR/public.pem
    chown $LOGMASTER_USER:$LOGMASTER_USER $CERTS_DIR/*.pem
    log_success "RSA certificates generated"
fi

# Create data directories for Docker volumes
log_info "Creating Docker volume directories..."
mkdir -p ./data/{postgresql,elasticsearch,redis,prometheus,grafana}
chown -R $LOGMASTER_USER:$LOGMASTER_USER ./data

# Configure rsyslog for log collection
log_info "Configuring rsyslog..."
cat > /etc/rsyslog.d/49-logmaster.conf << 'EOF'
# LogMaster v2 - Remote Log Collection
# Enable UDP syslog reception
$ModLoad imudp
$UDPServerRun 514
$UDPServerAddress 0.0.0.0

# Custom template for device-based logging
$template LogMasterFormat,"/var/log/logmaster/remote/%fromhost-ip%/%$year%-%$month%-%$day%.log"

# Route remote logs to device-specific files
if $fromhost-ip != '127.0.0.1' then ?LogMasterFormat
& stop
EOF

systemctl restart rsyslog
log_success "Rsyslog configured for remote log collection"

# Configure firewall
log_info "Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 514/udp   # Syslog
ufw allow 8000/tcp  # FastAPI (temporary)
ufw allow 3000/tcp  # Grafana
ufw allow 9090/tcp  # Prometheus
log_success "Firewall configured"

# Configure fail2ban
log_info "Configuring fail2ban..."
cat > /etc/fail2ban/jail.d/logmaster.conf << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 5
bantime = 3600
EOF

systemctl restart fail2ban
log_success "Fail2ban configured"

# Configure log rotation
log_info "Configuring log rotation..."
cat > /etc/logrotate.d/logmaster << 'EOF'
/var/log/logmaster/*.log {
    daily
    missingok
    rotate 730
    compress
    delaycompress
    notifempty
    create 644 logmaster logmaster
    postrotate
        /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
    endscript
}

/var/log/logmaster/remote/*/*.log {
    daily
    missingok
    rotate 730
    compress
    delaycompress
    notifempty
    create 644 logmaster logmaster
    sharedscripts
    postrotate
        /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
        # Trigger digital signing after rotation
        su - logmaster -c "cd /opt/logmaster/5651-logging-v2 && python3 scripts/sign_rotated_logs.py" || true
    endscript
}
EOF

log_success "Log rotation configured"

# Build and start Docker containers
log_info "Building and starting Docker containers..."
docker-compose down 2>/dev/null || true
docker-compose build
docker-compose up -d

# Wait for services to start
log_info "Waiting for services to start..."
sleep 30

# Check service health
log_info "Checking service health..."
for i in {1..10}; do
    if curl -f http://localhost:8000/health >/dev/null 2>&1; then
        log_success "Backend service is healthy"
        break
    fi
    if [ $i -eq 10 ]; then
        log_error "Backend service failed to start"
        exit 1
    fi
    sleep 5
done

# Initialize database
log_info "Initializing database..."
docker-compose exec -T backend python3 -c "
from app.core.database import db_manager
from app.models.models import Base
from app.core.database import engine

# Create all tables
Base.metadata.create_all(bind=engine)
print('Database tables created successfully')
"

# Create admin user
log_info "Creating admin user..."
docker-compose exec -T backend python3 -c "
import asyncio
from app.services.user_service import UserService
from app.core.database import get_db_session

async def create_admin():
    with get_db_session() as db:
        user_service = UserService(db)
        try:
            admin_user = await user_service.create_admin_user(
                username='admin',
                email='admin@logmaster.com',
                password='LogMaster2024!',
                first_name='System',
                last_name='Administrator'
            )
            print(f'Admin user created: {admin_user.username}')
        except Exception as e:
            print(f'Admin user creation failed or already exists: {e}')

asyncio.run(create_admin())
"

# Configure Nginx
log_info "Configuring Nginx..."
cat > /etc/nginx/sites-available/logmaster << 'EOF'
server {
    listen 80;
    server_name _;
    client_max_body_size 100M;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # API requests to backend
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Frontend application
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
    }

    # Logs directory (protected)
    location /logs/ {
        internal;
        alias /var/log/logmaster/;
    }
}
EOF

ln -sf /etc/nginx/sites-available/logmaster /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
log_success "Nginx configured and restarted"

# Setup cron jobs for automation
log_info "Setting up cron jobs..."
cat > /etc/cron.d/logmaster << 'EOF'
# LogMaster v2 - Automated Tasks
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Hourly digital signing
0 * * * * logmaster cd /opt/logmaster/5651-logging-v2 && python3 scripts/digital_signer.py >> /var/log/logmaster/signer-cron.log 2>&1

# Daily compliance check
0 2 * * * logmaster cd /opt/logmaster/5651-logging-v2 && python3 scripts/compliance_checker.py >> /var/log/logmaster/compliance-cron.log 2>&1

# Weekly backup
0 3 * * 0 logmaster cd /opt/logmaster/5651-logging-v2 && bash scripts/backup.sh >> /var/log/logmaster/backup-cron.log 2>&1

# Monthly compliance report
0 1 1 * * logmaster cd /opt/logmaster/5651-logging-v2 && python3 scripts/compliance_reporter.py >> /var/log/logmaster/report-cron.log 2>&1

# System health check every 15 minutes
*/15 * * * * logmaster cd /opt/logmaster/5651-logging-v2 && python3 scripts/health_monitor.py >> /var/log/logmaster/health-cron.log 2>&1
EOF

systemctl restart cron
log_success "Cron jobs configured"

# Create systemd service for Docker Compose
log_info "Creating systemd service..."
cat > /etc/systemd/system/logmaster.service << 'EOF'
[Unit]
Description=LogMaster v2 Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=forking
RemainAfterExit=yes
WorkingDirectory=/opt/logmaster/5651-logging-v2
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0
User=logmaster
Group=logmaster

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable logmaster
log_success "Systemd service created and enabled"

# Final system check
log_info "Running final system check..."
docker-compose ps

# Display deployment summary
log_success "🎉 LogMaster v2 deployment completed successfully!"
echo
echo -e "${GREEN}📋 DEPLOYMENT SUMMARY${NC}"
echo "=================================="
echo -e "📂 Installation Directory: ${BLUE}$LOGMASTER_HOME/5651-logging-v2${NC}"
echo -e "📊 Web Interface: ${BLUE}http://$(hostname -I | awk '{print $1}')${NC}"
echo -e "📈 Grafana Dashboard: ${BLUE}http://$(hostname -I | awk '{print $1}'):3000${NC}"
echo -e "🔐 Admin Username: ${BLUE}admin${NC}"
echo -e "🔑 Admin Password: ${BLUE}LogMaster2024!${NC}"
echo -e "📁 Log Directory: ${BLUE}$LOG_DIR${NC}"
echo -e "🔒 Certificates: ${BLUE}$CERTS_DIR${NC}"
echo
echo -e "${YELLOW}📝 NEXT STEPS${NC}"
echo "=================================="
echo "1. Edit configuration: nano $LOGMASTER_HOME/5651-logging-v2/.env"
echo "2. Configure devices to send logs to: $(hostname -I | awk '{print $1}'):514"
echo "3. Access web interface and create users"
echo "4. Set up SSL certificates: certbot --nginx -d yourdomain.com"
echo "5. Review and customize firewall rules"
echo
echo -e "${GREEN}✅ LogMaster v2 is ready for enterprise log management!${NC}" 
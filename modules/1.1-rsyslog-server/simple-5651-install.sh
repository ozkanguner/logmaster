#!/bin/bash
set -e

echo "🏨 LogMaster: Basit Multi-Tenant + 5651 İmzalama Kurulumu"
echo "========================================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[ADIM]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[BAŞARILI]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Bu script root olarak çalıştırılmalı!" 
   echo "Kullanım: sudo ./simple-5651-install.sh"
   exit 1
fi

print_step "1. Sistem güncellemesi ve gerekli paketler..."

# Update and install required packages
apt update
apt install -y rsyslog rsyslog-gnutls postgresql postgresql-contrib python3-pip python3-venv nginx openssl tree net-tools curl wget netcat-openbsd

print_step "2. Multi-tenant RSyslog konfigürasyonu..."

# Create log directories
mkdir -p /var/log/rsyslog/{unknown/unknown,archive}
chown -R syslog:adm /var/log/rsyslog/
chmod -R 755 /var/log/rsyslog/

# Multi-tenant RSyslog configuration
cat > /etc/rsyslog.d/10-multitenant-5651.conf << 'EOF'
# LogMaster Multi-Tenant + 5651 Configuration

# Load modules
module(load="imudp")
input(type="imudp" port="514")
module(load="imtcp") 
input(type="imtcp" port="514")

# Templates for Zone/Hotel structure
template(name="MultiTenantPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/%msg:R,ERE,1,FIELD:in:([A-Z0-9_]+)\s+out --end%/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="ZoneDHCPPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/dhcp/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="ZoneGeneralPath" type="string" string="/var/log/rsyslog/%msg:R,ERE,1,FIELD:^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+([A-Z_][A-Z0-9_]*)\s --end%/general/%$YEAR%-%$MONTH%-%$DAY%.log")

template(name="UnknownPath" type="string" string="/var/log/rsyslog/unknown/unknown/%$YEAR%-%$MONTH%-%$DAY%.log")

# Routing rules
# SRCNAT messages go to Zone/Hotel
if $msg contains "srcnat: in:" and $msg contains "out:" then {
    action(type="omfile" dynaFile="MultiTenantPath")
    stop
}

# DHCP messages go to Zone/dhcp
if $msg contains "dhcp" then {
    action(type="omfile" dynaFile="ZoneDHCPPath")
    stop
}

# Other zone messages go to Zone/general
if $msg regex "^[A-Za-z]+\s+[0-9]+\s+[0-9:]+\s+[A-Z_][A-Z0-9_]*\s" then {
    action(type="omfile" dynaFile="ZoneGeneralPath")
    stop
}

# Everything else goes to unknown
action(type="omfile" dynaFile="UnknownPath")
EOF

print_step "3. PostgreSQL kurulumu ve konfigürasyonu..."

# Start PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Create database and user
sudo -u postgres psql << 'EOF'
CREATE DATABASE logmaster_5651;
CREATE USER logmaster WITH PASSWORD 'LogMaster5651!';
GRANT ALL PRIVILEGES ON DATABASE logmaster_5651 TO logmaster;
\q
EOF

# Create database schema
sudo -u postgres psql -d logmaster_5651 << 'EOF'
-- Digital signatures table
CREATE TABLE log_signatures (
    id SERIAL PRIMARY KEY,
    zone_name VARCHAR(100) NOT NULL,
    hotel_name VARCHAR(100),
    log_date DATE NOT NULL,
    file_path TEXT NOT NULL,
    file_hash VARCHAR(64) NOT NULL,
    signature TEXT NOT NULL,
    signed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    signer_info TEXT,
    compliance_status VARCHAR(20) DEFAULT 'SIGNED'
);

-- Log metadata table
CREATE TABLE log_metadata (
    id SERIAL PRIMARY KEY,
    zone_name VARCHAR(100) NOT NULL,
    hotel_name VARCHAR(100),
    log_date DATE NOT NULL,
    message_count INTEGER DEFAULT 0,
    file_size BIGINT DEFAULT 0,
    first_message_time TIMESTAMP,
    last_message_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_signatures_date ON log_signatures(log_date);
CREATE INDEX idx_signatures_zone ON log_signatures(zone_name);
CREATE INDEX idx_metadata_date ON log_metadata(log_date);

-- Grant permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO logmaster;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO logmaster;
\q
EOF

print_step "4. 5651 İmzalama servisi kurulumu..."

# Create Python virtual environment
python3 -m venv /opt/logmaster-5651
source /opt/logmaster-5651/bin/activate
pip install psycopg2-binary cryptography fastapi uvicorn

# Create 5651 digital signing service
mkdir -p /opt/logmaster-5651/app

cat > /opt/logmaster-5651/app/digital_signer.py << 'EOF'
#!/usr/bin/env python3
"""
LogMaster 5651 Digital Signing Service
"""
import os
import hashlib
import psycopg2
from datetime import datetime, date
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.x509.oid import NameOID
from cryptography import x509
import glob
import time
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class DigitalSigner:
    def __init__(self):
        self.db_config = {
            'host': 'localhost',
            'database': 'logmaster_5651',
            'user': 'logmaster', 
            'password': 'LogMaster5651!'
        }
        self.cert_path = '/opt/logmaster-5651/certs'
        os.makedirs(self.cert_path, exist_ok=True)
        self.ensure_certificates()
    
    def ensure_certificates(self):
        """Create self-signed certificate for 5651 compliance"""
        cert_file = f"{self.cert_path}/5651_cert.pem"
        key_file = f"{self.cert_path}/5651_key.pem"
        
        if not os.path.exists(cert_file) or not os.path.exists(key_file):
            logger.info("Creating 5651 compliance certificates...")
            
            # Generate private key
            private_key = rsa.generate_private_key(
                public_exponent=65537,
                key_size=2048,
            )
            
            # Create certificate
            subject = issuer = x509.Name([
                x509.NameAttribute(NameOID.COUNTRY_NAME, "TR"),
                x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "Istanbul"),
                x509.NameAttribute(NameOID.LOCALITY_NAME, "Istanbul"),
                x509.NameAttribute(NameOID.ORGANIZATION_NAME, "LogMaster 5651"),
                x509.NameAttribute(NameOID.COMMON_NAME, "5651 Log Signing Authority"),
            ])
            
            cert = x509.CertificateBuilder().subject_name(
                subject
            ).issuer_name(
                issuer
            ).public_key(
                private_key.public_key()
            ).serial_number(
                x509.random_serial_number()
            ).not_valid_before(
                datetime.utcnow()
            ).not_valid_after(
                datetime.utcnow().replace(year=datetime.utcnow().year + 10)
            ).sign(private_key, hashes.SHA256())
            
            # Save certificate and key
            with open(cert_file, "wb") as f:
                f.write(cert.public_bytes(serialization.Encoding.PEM))
            
            with open(key_file, "wb") as f:
                f.write(private_key.private_bytes(
                    encoding=serialization.Encoding.PEM,
                    format=serialization.PrivateFormat.PKCS8,
                    encryption_algorithm=serialization.NoEncryption()
                ))
            
            logger.info("5651 certificates created successfully")
        
        # Load private key
        with open(key_file, "rb") as f:
            self.private_key = serialization.load_pem_private_key(f.read(), password=None)
    
    def calculate_file_hash(self, file_path):
        """Calculate SHA-256 hash of file"""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
    
    def sign_file(self, file_path):
        """Digitally sign a log file"""
        try:
            file_hash = self.calculate_file_hash(file_path)
            
            # Create signature
            signature = self.private_key.sign(
                file_hash.encode('utf-8'),
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            
            return file_hash, signature.hex()
        except Exception as e:
            logger.error(f"Error signing file {file_path}: {e}")
            return None, None
    
    def save_signature_to_db(self, zone_name, hotel_name, log_date, file_path, file_hash, signature):
        """Save digital signature to database"""
        try:
            conn = psycopg2.connect(**self.db_config)
            cur = conn.cursor()
            
            cur.execute("""
                INSERT INTO log_signatures 
                (zone_name, hotel_name, log_date, file_path, file_hash, signature, signer_info)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (zone_name, hotel_name, log_date, file_path, file_hash, signature, 
                  "LogMaster 5651 Digital Signer v1.0"))
            
            conn.commit()
            cur.close()
            conn.close()
            return True
        except Exception as e:
            logger.error(f"Database error: {e}")
            return False
    
    def process_daily_logs(self):
        """Process and sign daily log files"""
        yesterday = date.today().replace(day=date.today().day-1)
        date_pattern = yesterday.strftime("%Y-%m-%d")
        
        log_pattern = f"/var/log/rsyslog/**/{date_pattern}.log"
        log_files = glob.glob(log_pattern, recursive=True)
        
        logger.info(f"Found {len(log_files)} log files for {date_pattern}")
        
        for log_file in log_files:
            # Skip if file is empty or doesn't exist
            if not os.path.exists(log_file) or os.path.getsize(log_file) == 0:
                continue
            
            # Extract zone and hotel from path
            path_parts = log_file.split('/')
            if len(path_parts) >= 6:
                zone_name = path_parts[4]  # /var/log/rsyslog/ZONE/...
                hotel_name = path_parts[5] if path_parts[5] != date_pattern + '.log' else None
                
                # Sign the file
                file_hash, signature = self.sign_file(log_file)
                
                if file_hash and signature:
                    # Save to database
                    success = self.save_signature_to_db(
                        zone_name, hotel_name, yesterday, log_file, file_hash, signature
                    )
                    
                    if success:
                        logger.info(f"Successfully signed: {log_file}")
                    else:
                        logger.error(f"Failed to save signature for: {log_file}")
                else:
                    logger.error(f"Failed to sign file: {log_file}")

    def run_continuous(self):
        """Run continuous signing service"""
        logger.info("Starting 5651 Digital Signing Service...")
        
        while True:
            try:
                # Sign daily logs every hour
                self.process_daily_logs()
                time.sleep(3600)  # Wait 1 hour
            except KeyboardInterrupt:
                logger.info("Signing service stopped")
                break
            except Exception as e:
                logger.error(f"Unexpected error: {e}")
                time.sleep(60)  # Wait 1 minute before retry

if __name__ == "__main__":
    signer = DigitalSigner()
    signer.run_continuous()
EOF

# Create systemd service for digital signer
cat > /etc/systemd/system/logmaster-5651-signer.service << 'EOF'
[Unit]
Description=LogMaster 5651 Digital Signing Service
After=network.target postgresql.service rsyslog.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/logmaster-5651/app
Environment=PATH=/opt/logmaster-5651/bin
ExecStart=/opt/logmaster-5651/bin/python /opt/logmaster-5651/app/digital_signer.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

print_step "5. Otomatik dizin oluşturma servisi..."

# Create directory auto-creation script
cat > /usr/local/bin/create-multitenant-dirs.sh << 'EOF'
#!/bin/bash

LOG_BASE="/var/log/rsyslog"
MONITOR_LOG="/var/log/multitenant-monitor.log"

log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$MONITOR_LOG"
}

extract_zone_hotel() {
    local message="$1"
    local zone=""
    local hotel=""
    
    # Extract zone
    if [[ "$message" =~ ^[A-Za-z]+[[:space:]]+[0-9]+[[:space:]]+[0-9:]+[[:space:]]+([A-Z_][A-Z0-9_]*)[[:space:]] ]]; then
        zone="${BASH_REMATCH[1]}"
    fi
    
    # Extract hotel
    if [[ "$message" =~ in:([A-Z0-9_]+)[[:space:]]+out ]]; then
        hotel="${BASH_REMATCH[1]}"
        echo "$zone/$hotel"
    elif [[ "$message" =~ dhcp ]]; then
        echo "$zone/dhcp"
    elif [[ -n "$zone" ]]; then
        echo "$zone/general"
    fi
}

create_dir() {
    local path="$1"
    local full_path="$LOG_BASE/$path"
    
    if [[ -n "$path" && ! -d "$full_path" ]]; then
        mkdir -p "$full_path"
        chown -R syslog:adm "$full_path"
        chmod -R 755 "$full_path"
        log_event "Auto-created directory: $path"
    fi
}

monitor_and_create() {
    local unknown_file="$LOG_BASE/unknown/unknown/$(date '+%Y-%m-%d').log"
    
    if [[ -f "$unknown_file" ]]; then
        tail -50 "$unknown_file" 2>/dev/null | while read -r line; do
            category=$(extract_zone_hotel "$line")
            if [[ -n "$category" ]]; then
                create_dir "$category"
            fi
        done
    fi
}

log_event "Multi-tenant directory monitor started"

while true; do
    monitor_and_create
    sleep 30
done
EOF

chmod +x /usr/local/bin/create-multitenant-dirs.sh

# Create systemd service for directory monitor
cat > /etc/systemd/system/logmaster-dir-monitor.service << 'EOF'
[Unit]
Description=LogMaster Multi-Tenant Directory Monitor
After=rsyslog.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/create-multitenant-dirs.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

print_step "6. Basit web interface..."

# Install web interface dependencies
deactivate 2>/dev/null || true
source /opt/logmaster-5651/bin/activate
pip install jinja2 aiofiles

# Create simple web app
cat > /opt/logmaster-5651/app/web_app.py << 'EOF'
#!/usr/bin/env python3
"""
LogMaster 5651 Simple Web Interface
"""
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
import psycopg2
from datetime import date, timedelta
import os

app = FastAPI(title="LogMaster 5651 Compliance Interface")

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'database': 'logmaster_5651',
    'user': 'logmaster',
    'password': 'LogMaster5651!'
}

@app.get("/", response_class=HTMLResponse)
async def dashboard():
    """Main dashboard"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        
        # Get signature statistics
        cur.execute("SELECT COUNT(*) FROM log_signatures WHERE log_date >= %s", 
                   (date.today() - timedelta(days=7),))
        weekly_signatures = cur.fetchone()[0]
        
        cur.execute("SELECT COUNT(DISTINCT zone_name) FROM log_signatures")
        total_zones = cur.fetchone()[0]
        
        # Get recent signatures
        cur.execute("""
            SELECT zone_name, hotel_name, log_date, compliance_status, signed_at
            FROM log_signatures 
            ORDER BY signed_at DESC 
            LIMIT 10
        """)
        recent_signatures = cur.fetchall()
        
        cur.close()
        conn.close()
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>LogMaster 5651 Compliance Dashboard</title>
            <meta charset="utf-8">
            <style>
                body {{ font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }}
                .container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
                h1 {{ color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }}
                .stats {{ display: flex; gap: 20px; margin: 20px 0; }}
                .stat {{ background: #ecf0f1; padding: 20px; border-radius: 5px; flex: 1; text-align: center; }}
                .stat h3 {{ margin: 0; color: #34495e; }}
                .stat p {{ font-size: 24px; font-weight: bold; margin: 10px 0 0 0; color: #27ae60; }}
                table {{ width: 100%; border-collapse: collapse; margin-top: 20px; }}
                th, td {{ border: 1px solid #bdc3c7; padding: 12px; text-align: left; }}
                th {{ background: #34495e; color: white; }}
                tr:nth-child(even) {{ background: #f8f9fa; }}
                .status-signed {{ color: #27ae60; font-weight: bold; }}
                .footer {{ margin-top: 30px; text-align: center; color: #7f8c8d; border-top: 1px solid #ecf0f1; padding-top: 20px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🏨 LogMaster 5651 Compliance Dashboard</h1>
                
                <div class="stats">
                    <div class="stat">
                        <h3>Son 7 Gün İmzalanan</h3>
                        <p>{weekly_signatures}</p>
                    </div>
                    <div class="stat">
                        <h3>Toplam Zone</h3>
                        <p>{total_zones}</p>
                    </div>
                    <div class="stat">
                        <h3>Compliance Durumu</h3>
                        <p>✅ AKTİF</p>
                    </div>
                </div>
                
                <h2>📋 Son İmzalanan Log Dosyaları</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Zone</th>
                            <th>Hotel</th>
                            <th>Tarih</th>
                            <th>Durum</th>
                            <th>İmzalama Zamanı</th>
                        </tr>
                    </thead>
                    <tbody>
        """
        
        for sig in recent_signatures:
            zone, hotel, log_date, status, signed_at = sig
            hotel_display = hotel if hotel else 'Genel'
            html_content += f"""
                        <tr>
                            <td>{zone}</td>
                            <td>{hotel_display}</td>
                            <td>{log_date}</td>
                            <td class="status-signed">{status}</td>
                            <td>{signed_at.strftime('%Y-%m-%d %H:%M:%S')}</td>
                        </tr>
            """
        
        html_content += """
                    </tbody>
                </table>
                
                <div class="footer">
                    <p>LogMaster 5651 Compliance System - Türkiye Cumhuriyeti 5651 Sayılı Kanun'a Uygun Log Yönetimi</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        return html_content
        
    except Exception as e:
        return f"<h1>Hata</h1><p>Veritabanı bağlantı hatası: {e}</p>"

@app.get("/health")
async def health_check():
    return {"status": "OK", "service": "LogMaster 5651"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

# Create systemd service for web app
cat > /etc/systemd/system/logmaster-5651-web.service << 'EOF'
[Unit]
Description=LogMaster 5651 Web Interface
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/logmaster-5651/app
Environment=PATH=/opt/logmaster-5651/bin
ExecStart=/opt/logmaster-5651/bin/uvicorn web_app:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx reverse proxy
cat > /etc/nginx/sites-available/logmaster-5651 << 'EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable Nginx site
ln -sf /etc/nginx/sites-available/logmaster-5651 /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

print_step "7. Servisleri başlatıyor..."

# Test configurations
rsyslogd -N1

# Restart RSyslog
systemctl restart rsyslog

# Start and enable all services
systemctl daemon-reload
systemctl enable postgresql rsyslog nginx
systemctl enable logmaster-5651-signer logmaster-dir-monitor logmaster-5651-web
systemctl start postgresql rsyslog nginx
systemctl start logmaster-5651-signer logmaster-dir-monitor logmaster-5651-web

print_step "8. Test logları gönderiliyor..."

# Create some example directories
mkdir -p /var/log/rsyslog/SISLI_HOTSPOT/{FOURSIDES_HOTEL,ADELMAR_HOTEL,dhcp,general}
chown -R syslog:adm /var/log/rsyslog/SISLI_HOTSPOT
chmod -R 755 /var/log/rsyslog/SISLI_HOTSPOT

# Send test messages
sleep 2
echo "$(date '+%b %d %H:%M:%S') SISLI_HOTSPOT srcnat: in:FOURSIDES_HOTEL out:DT_MODEM, connection-state:new" | nc -u localhost 514
echo "$(date '+%b %d %H:%M:%S') SISLI_HOTSPOT srcnat: in:ADELMAR_HOTEL out:DT_MODEM, connection-state:new" | nc -u localhost 514
echo "$(date '+%b %d %H:%M:%S') SISLI_HOTSPOT dhcp15 assigned 172.11.0.100" | nc -u localhost 514

sleep 3

print_step "9. Kurulum sonuçları..."

echo ""
print_success "🎉 LogMaster Multi-Tenant + 5651 İmzalama Sistemi Kuruldu!"

echo ""
echo "📊 Sistem Durumu:"
echo "================="
echo "RSyslog: $(systemctl is-active rsyslog)"
echo "PostgreSQL: $(systemctl is-active postgresql)"
echo "5651 Signer: $(systemctl is-active logmaster-5651-signer)"
echo "Dir Monitor: $(systemctl is-active logmaster-dir-monitor)"
echo "Web Interface: $(systemctl is-active logmaster-5651-web)"
echo "Nginx: $(systemctl is-active nginx)"

echo ""
echo "🌐 Web Erişim:"
echo "=============="
echo "5651 Compliance Dashboard: http://$(hostname -I | awk '{print $1}')"
echo "API Health Check: http://$(hostname -I | awk '{print $1}')/health"

echo ""
echo "📁 Log Yapısı:"
echo "=============="
tree /var/log/rsyslog/ -L 3 2>/dev/null || find /var/log/rsyslog/ -type d | sort

echo ""
echo "🔐 5651 Compliance:"
echo "=================="
echo "Digital Signatures: /opt/logmaster-5651/certs/"
echo "Signature Database: PostgreSQL logmaster_5651"
echo "Signing Service: Otomatik (her saat)"

echo ""
echo "🔧 Yönetim Komutları:"
echo "===================="
echo "# Servis durumları:"
echo "sudo systemctl status logmaster-5651-signer"
echo "sudo systemctl status logmaster-dir-monitor"
echo "sudo systemctl status logmaster-5651-web"
echo ""
echo "# Logları izle:"
echo "tail -f /var/log/rsyslog/SISLI_HOTSPOT/FOURSIDES_HOTEL/$(date '+%Y-%m-%d').log"
echo "tail -f /var/log/multitenant-monitor.log"
echo ""
echo "# 5651 imzaları kontrol et:"
echo "sudo -u postgres psql -d logmaster_5651 -c 'SELECT * FROM log_signatures ORDER BY signed_at DESC LIMIT 10;'"

print_success "Kurulum tamamlandı! Multi-tenant loglama + 5651 digital imzalama aktif!" 
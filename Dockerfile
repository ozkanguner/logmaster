# LogMaster - 5651 Kanunu Uyumlu Log Yönetim Sistemi
# Docker Container

FROM ubuntu:22.04

# Metadata
LABEL maintainer="LogMaster Team"
LABEL description="5651 Kanunu Uyumlu Log Yönetim Sistemi"
LABEL version="1.0.0"

# Çevre değişkenleri
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV LOGMASTER_ENV=production

# Sistem güncellemeleri ve bağımlılıklar
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    postgresql-client \
    rsyslog \
    nginx \
    supervisor \
    git \
    curl \
    wget \
    unzip \
    gnupg2 \
    openssl \
    libssl-dev \
    libffi-dev \
    libpq-dev \
    htop \
    tree \
    vim \
    cron \
    && rm -rf /var/lib/apt/lists/*

# LogMaster kullanıcısı oluştur
RUN useradd -r -s /bin/bash -d /opt/logmaster -m logmaster

# Çalışma dizini
WORKDIR /opt/logmaster

# Python sanal ortamı oluştur
RUN python3 -m venv venv
ENV PATH="/opt/logmaster/venv/bin:$PATH"

# Python bağımlılıklarını kopyala ve yükle
COPY requirements.txt .
RUN pip install --upgrade pip setuptools wheel
RUN pip install -r requirements.txt

# Uygulama dosyalarını kopyala
COPY . .

# Dizin izinlerini ayarla
RUN mkdir -p /opt/logmaster/{logs,signed,archived,temp,backup,certs,reports} \
    && mkdir -p /var/log/logmaster \
    && chown -R logmaster:logmaster /opt/logmaster \
    && chown -R logmaster:logmaster /var/log/logmaster \
    && chmod -R 750 /opt/logmaster \
    && chmod +x scripts/*.py

# 400 cihaz klasörü oluştur
RUN for i in $(seq -w 1 400); do \
        mkdir -p /opt/logmaster/logs/device-$i; \
        chown logmaster:logmaster /opt/logmaster/logs/device-$i; \
        chmod 750 /opt/logmaster/logs/device-$i; \
    done

# Nginx konfigürasyonu
COPY docker/nginx.conf /etc/nginx/sites-available/logmaster
RUN ln -sf /etc/nginx/sites-available/logmaster /etc/nginx/sites-enabled/ \
    && rm -f /etc/nginx/sites-enabled/default

# Supervisor konfigürasyonu
COPY docker/supervisor.conf /etc/supervisor/conf.d/logmaster.conf

# Rsyslog konfigürasyonu
COPY docker/rsyslog.conf /etc/rsyslog.d/50-logmaster.conf

# Entrypoint script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# SSL sertifikaları oluştur (development)
RUN openssl req -x509 -newkey rsa:4096 \
    -keyout /opt/logmaster/certs/logmaster.key \
    -out /opt/logmaster/certs/logmaster.crt \
    -days 3650 -nodes \
    -subj "/C=TR/ST=Istanbul/L=Istanbul/O=LogMaster/CN=logmaster.local" \
    && chown logmaster:logmaster /opt/logmaster/certs/*

# Portları aç
EXPOSE 80 443 514/udp 8000

# Volumes
VOLUME ["/opt/logmaster/logs", "/opt/logmaster/signed", "/opt/logmaster/archived", "/var/log/logmaster"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/api/system/status || exit 1

# Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["supervisord", "-n"] 
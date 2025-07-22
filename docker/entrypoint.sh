#!/bin/bash
# LogMaster Docker Entrypoint

set -e

echo "LogMaster Container Starting..."

# Çevre değişkenlerini kontrol et
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-logmaster}
DB_USER=${DB_USER:-logmaster}
DB_PASSWORD=${DB_PASSWORD:-CHANGE_THIS_PASSWORD}

# Konfigürasyon dosyasını güncelle
if [ -f /opt/logmaster/config/main.conf ]; then
    sed -i "s/db_host = .*/db_host = $DB_HOST/" /opt/logmaster/config/main.conf
    sed -i "s/db_port = .*/db_port = $DB_PORT/" /opt/logmaster/config/main.conf
    sed -i "s/db_name = .*/db_name = $DB_NAME/" /opt/logmaster/config/main.conf
    sed -i "s/db_user = .*/db_user = $DB_USER/" /opt/logmaster/config/main.conf
    sed -i "s/db_password = .*/db_password = $DB_PASSWORD/" /opt/logmaster/config/main.conf
fi

# Veritabanı bağlantısını bekle
echo "Veritabanı bağlantısı bekleniyor..."
until pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER; do
    echo "PostgreSQL henüz hazır değil - bekleniyor..."
    sleep 2
done

echo "PostgreSQL hazır!"

# Veritabanı şemasını kontrol et ve oluştur
echo "Veritabanı şeması kontrol ediliyor..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "\dt" > /dev/null 2>&1 || {
    echo "Veritabanı şeması oluşturuluyor..."
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < /opt/logmaster/scripts/database_setup.sql
}

# Log dizinlerinin izinlerini kontrol et
echo "Dizin izinleri kontrol ediliyor..."
chown -R logmaster:logmaster /opt/logmaster/logs
chown -R logmaster:logmaster /opt/logmaster/signed
chown -R logmaster:logmaster /opt/logmaster/archived
chown -R logmaster:logmaster /var/log/logmaster

# Nginx konfigürasyonunu test et
echo "Nginx konfigürasyonu test ediliyor..."
nginx -t

# Rsyslog'u başlat
echo "Rsyslog başlatılıyor..."
service rsyslog start

# SSL sertifikalarını kontrol et
if [ ! -f /opt/logmaster/certs/logmaster.crt ]; then
    echo "SSL sertifikaları oluşturuluyor..."
    openssl req -x509 -newkey rsa:4096 \
        -keyout /opt/logmaster/certs/logmaster.key \
        -out /opt/logmaster/certs/logmaster.crt \
        -days 3650 -nodes \
        -subj "/C=TR/ST=Istanbul/L=Istanbul/O=LogMaster/CN=logmaster.local"
    chown logmaster:logmaster /opt/logmaster/certs/*
fi

# Cron servisini başlat
echo "Cron servisi başlatılıyor..."
service cron start

# LogMaster crontab'ını yükle
echo "Crontab yükleniyor..."
if [ -f /opt/logmaster/docker/crontab ]; then
    crontab -u logmaster /opt/logmaster/docker/crontab
fi

echo "LogMaster başlatılıyor..."

# İlk argümanın türüne göre çalıştır
if [ "$1" = 'supervisord' ]; then
    echo "Supervisor ile servisler başlatılıyor..."
    exec "$@"
elif [ "$1" = 'web-only' ]; then
    echo "Sadece web arayüzü başlatılıyor..."
    exec su-exec logmaster python /opt/logmaster/web/app.py
elif [ "$1" = 'collector-only' ]; then
    echo "Sadece log collector başlatılıyor..."
    exec su-exec logmaster python /opt/logmaster/scripts/log_collector.py
elif [ "$1" = 'bash' ]; then
    echo "Bash shell başlatılıyor..."
    exec bash
else
    echo "Komut çalıştırılıyor: $@"
    exec "$@"
fi 
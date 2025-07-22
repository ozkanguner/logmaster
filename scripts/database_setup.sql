-- LogMaster - 5651 Kanunu Uyumlu Log Yönetim Sistemi
-- PostgreSQL Veritabanı Şeması

-- Veritabanı ve kullanıcı oluşturma
CREATE DATABASE logmaster;
CREATE USER logmaster WITH ENCRYPTED PASSWORD 'CHANGE_THIS_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE logmaster TO logmaster;

-- Veritabanına bağlan
\c logmaster;

-- UUID uzantısını etkinleştir
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Cihazlar tablosu
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    ip_address INET,
    mac_address MACADDR,
    location VARCHAR(255),
    department VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(100),
    contact_email VARCHAR(255),
    timezone VARCHAR(50) DEFAULT 'Europe/Istanbul',
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB
);

-- Log girişleri tablosu
CREATE TABLE log_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id VARCHAR(50) REFERENCES devices(device_id),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    source_ip INET NOT NULL,
    raw_message TEXT NOT NULL,
    message_hash VARCHAR(64) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    size INTEGER NOT NULL,
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB
);

-- Dijital imzalar tablosu
CREATE TABLE digital_signatures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_path VARCHAR(500) NOT NULL,
    file_hash VARCHAR(64) NOT NULL,
    signature_data TEXT NOT NULL,
    signature_algorithm VARCHAR(50) NOT NULL,
    certificate_fingerprint VARCHAR(64) NOT NULL,
    signed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    tsa_timestamp TEXT,
    file_size BIGINT NOT NULL,
    compliance_standard VARCHAR(50) DEFAULT '5651_kanunu',
    retention_years INTEGER DEFAULT 2,
    verification_status VARCHAR(20) DEFAULT 'valid',
    last_verified_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB
);

-- Arşiv kayıtları tablosu
CREATE TABLE archive_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    original_file_path VARCHAR(500) NOT NULL,
    archive_file_path VARCHAR(500) NOT NULL,
    compression_type VARCHAR(20) DEFAULT 'gzip',
    original_size BIGINT NOT NULL,
    compressed_size BIGINT NOT NULL,
    archived_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    archive_hash VARCHAR(64) NOT NULL,
    retention_until DATE NOT NULL,
    access_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB
);

-- Erişim logları tablosu (5651 kanunu gereği)
CREATE TABLE access_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(100) NOT NULL,
    user_name VARCHAR(255),
    action VARCHAR(50) NOT NULL, -- read, write, delete, archive, verify
    target_type VARCHAR(50) NOT NULL, -- log_file, signature, archive
    target_path VARCHAR(500) NOT NULL,
    client_ip INET,
    user_agent TEXT,
    session_id VARCHAR(100),
    success BOOLEAN NOT NULL,
    error_message TEXT,
    accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB
);

-- Sistem durumu tablosu
CREATE TABLE system_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    component VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL, -- healthy, warning, error
    message TEXT,
    metrics JSONB,
    checked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Uyumluluk raporları tablosu
CREATE TABLE compliance_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_type VARCHAR(50) NOT NULL, -- daily, monthly, annual, audit
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_logs BIGINT NOT NULL,
    signed_logs BIGINT NOT NULL,
    verified_logs BIGINT NOT NULL,
    archived_logs BIGINT NOT NULL,
    compliance_score DECIMAL(5,2),
    report_data JSONB NOT NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    generated_by VARCHAR(100) NOT NULL
);

-- Konfigürasyon tablosu
CREATE TABLE configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    category VARCHAR(50),
    is_encrypted BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by VARCHAR(100)
);

-- İndeksler oluştur
CREATE INDEX idx_log_entries_timestamp ON log_entries(timestamp);
CREATE INDEX idx_log_entries_device_id ON log_entries(device_id);
CREATE INDEX idx_log_entries_source_ip ON log_entries(source_ip);
CREATE INDEX idx_log_entries_message_hash ON log_entries(message_hash);
CREATE INDEX idx_log_entries_file_path ON log_entries(file_path);

CREATE INDEX idx_digital_signatures_file_path ON digital_signatures(file_path);
CREATE INDEX idx_digital_signatures_signed_at ON digital_signatures(signed_at);
CREATE INDEX idx_digital_signatures_file_hash ON digital_signatures(file_hash);

CREATE INDEX idx_archive_records_archived_at ON archive_records(archived_at);
CREATE INDEX idx_archive_records_retention_until ON archive_records(retention_until);

CREATE INDEX idx_access_logs_accessed_at ON access_logs(accessed_at);
CREATE INDEX idx_access_logs_user_id ON access_logs(user_id);
CREATE INDEX idx_access_logs_action ON access_logs(action);

-- Tetikleyiciler oluştur

-- Cihaz güncellendiğinde updated_at alanını güncelle
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_devices_updated_at 
    BEFORE UPDATE ON devices 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Log girişi eklendiğinde cihazı otomatik oluştur
CREATE OR REPLACE FUNCTION auto_create_device()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO devices (device_id, name, ip_address, status)
    VALUES (NEW.device_id, NEW.device_id, NEW.source_ip, 'auto_created')
    ON CONFLICT (device_id) DO NOTHING;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER auto_create_device_trigger
    BEFORE INSERT ON log_entries
    FOR EACH ROW EXECUTE FUNCTION auto_create_device();

-- Görünümler oluştur

-- Günlük log istatistikleri
CREATE VIEW daily_log_stats AS
SELECT 
    DATE(timestamp) as log_date,
    device_id,
    COUNT(*) as log_count,
    SUM(size) as total_size,
    MIN(timestamp) as first_log,
    MAX(timestamp) as last_log
FROM log_entries
GROUP BY DATE(timestamp), device_id
ORDER BY log_date DESC, device_id;

-- İmza durumu özeti
CREATE VIEW signature_status_summary AS
SELECT 
    ds.compliance_standard,
    COUNT(*) as total_signatures,
    COUNT(CASE WHEN ds.verification_status = 'valid' THEN 1 END) as valid_signatures,
    COUNT(CASE WHEN ds.verification_status = 'invalid' THEN 1 END) as invalid_signatures,
    COUNT(CASE WHEN ds.verification_status = 'expired' THEN 1 END) as expired_signatures,
    AVG(ds.file_size) as avg_file_size
FROM digital_signatures ds
GROUP BY ds.compliance_standard;

-- Arşiv kullanım istatistikleri
CREATE VIEW archive_usage_stats AS
SELECT 
    DATE_TRUNC('month', archived_at) as archive_month,
    COUNT(*) as files_archived,
    SUM(original_size) as total_original_size,
    SUM(compressed_size) as total_compressed_size,
    ROUND(
        (1 - (SUM(compressed_size)::DECIMAL / SUM(original_size))) * 100, 2
    ) as compression_ratio_percent
FROM archive_records
GROUP BY DATE_TRUNC('month', archived_at)
ORDER BY archive_month DESC;

-- Varsayılan konfigürasyonları ekle
INSERT INTO configurations (key, value, description, category) VALUES
('log_retention_days', '730', '5651 kanunu gereği log saklama süresi (gün)', 'compliance'),
('auto_signature_enabled', 'true', 'Otomatik dijital imzalama aktif', 'signature'),
('signature_interval_hours', '24', 'İmzalama aralığı (saat)', 'signature'),
('compression_enabled', 'true', 'Arşiv sıkıştırma aktif', 'archive'),
('compliance_check_enabled', 'true', 'Uyumluluk kontrolü aktif', 'compliance'),
('max_log_file_size_mb', '100', 'Maksimum log dosya boyutu (MB)', 'storage'),
('backup_enabled', 'true', 'Yedekleme aktif', 'backup'),
('encryption_enabled', 'true', 'Arşiv şifreleme aktif', 'security'),
('tsa_url', 'http://timestamp.digicert.com', 'Zaman damgası sunucu URL', 'signature'),
('alert_email', 'admin@company.com', 'Sistem uyarıları için e-posta', 'monitoring');

-- İlk kullanıcı hesabını oluştur (admin)
INSERT INTO access_logs (user_id, user_name, action, target_type, target_path, client_ip, success, accessed_at)
VALUES ('admin', 'System Administrator', 'database_setup', 'system', 'database_init', '127.0.0.1', true, NOW());

-- Yetkiler ver
GRANT ALL ON ALL TABLES IN SCHEMA public TO logmaster;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO logmaster;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO logmaster;

-- İstatistik toplama için fonksiyon
CREATE OR REPLACE FUNCTION get_compliance_stats(start_date DATE, end_date DATE)
RETURNS TABLE(
    total_logs BIGINT,
    signed_logs BIGINT,
    verified_logs BIGINT,
    compliance_percentage DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(le.id) as total_logs,
        COUNT(ds.id) as signed_logs,
        COUNT(CASE WHEN ds.verification_status = 'valid' THEN 1 END) as verified_logs,
        ROUND(
            (COUNT(CASE WHEN ds.verification_status = 'valid' THEN 1 END)::DECIMAL / 
             NULLIF(COUNT(le.id), 0)) * 100, 2
        ) as compliance_percentage
    FROM log_entries le
    LEFT JOIN digital_signatures ds ON le.file_path = ds.file_path
    WHERE DATE(le.timestamp) BETWEEN start_date AND end_date;
END;
$$ LANGUAGE plpgsql;

COMMIT; 
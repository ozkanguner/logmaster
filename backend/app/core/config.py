#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LogMaster v2 - Core Configuration Settings
Centralized configuration management with environment variables
"""

import os
import secrets
from typing import List, Optional, Any, Dict
from pydantic import BaseSettings, validator, PostgresDsn, AnyHttpUrl
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings with environment variable support"""
    
    # Application
    APP_NAME: str = "LogMaster v2"
    APP_VERSION: str = "2.0.0"
    DEBUG: bool = False
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Security
    SECRET_KEY: str = secrets.token_urlsafe(32)
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 8  # 8 hours
    REFRESH_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    SESSION_TIMEOUT: int = 60 * 60 * 8  # 8 hours
    ALLOWED_HOSTS: List[str] = ["*"]
    
    # Database - PostgreSQL
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_USER: str = "logmaster"
    POSTGRES_PASSWORD: str = "logmaster_secure_2024"
    POSTGRES_DB: str = "logmaster_v2"
    DATABASE_URL: Optional[PostgresDsn] = None
    
    @validator("DATABASE_URL", pre=True)
    def assemble_db_connection(cls, v: Optional[str], values: Dict[str, Any]) -> Any:
        if isinstance(v, str):
            return v
        return PostgresDsn.build(
            scheme="postgresql",
            user=values.get("POSTGRES_USER"),
            password=values.get("POSTGRES_PASSWORD"),
            host=values.get("POSTGRES_HOST"),
            port=str(values.get("POSTGRES_PORT")),
            path=f"/{values.get('POSTGRES_DB') or ''}",
        )
    
    # Elasticsearch
    ELASTICSEARCH_URL: str = "http://localhost:9200"
    ELASTICSEARCH_INDEX_PREFIX: str = "logmaster-v2"
    ELASTICSEARCH_TIMEOUT: int = 30
    ELASTICSEARCH_MAX_RETRIES: int = 3
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379"
    REDIS_DB: int = 0
    REDIS_PASSWORD: Optional[str] = None
    REDIS_TIMEOUT: int = 5
    
    # Log Storage
    LOG_BASE_PATH: str = "/var/log/logmaster"
    LOG_ARCHIVE_PATH: str = "/var/log/logmaster/archive"
    LOG_RETENTION_DAYS: int = 730  # 2 years for 5651 compliance
    LOG_COMPRESSION_DAYS: int = 7  # Compress logs older than 7 days
    
    # Digital Signatures (5651 Compliance)
    SIGNATURE_ALGORITHM: str = "RSA-256"
    RSA_KEY_SIZE: int = 2048
    PRIVATE_KEY_PATH: str = "/opt/logmaster/certs/private.pem"
    PUBLIC_KEY_PATH: str = "/opt/logmaster/certs/public.pem"
    TSA_URL: Optional[str] = None  # Time Stamp Authority URL
    
    # Device Authentication
    DEVICE_REGISTRATION_APPROVAL: bool = True  # Require admin approval
    DEVICE_HEARTBEAT_INTERVAL: int = 300  # 5 minutes
    DEVICE_OFFLINE_THRESHOLD: int = 900  # 15 minutes
    MAX_DEVICES_PER_USER: int = 50
    
    # User Management
    DEFAULT_USER_ROLE: str = "viewer"
    PASSWORD_MIN_LENGTH: int = 12
    PASSWORD_REQUIRE_SPECIAL_CHARS: bool = True
    PASSWORD_REQUIRE_NUMBERS: bool = True
    PASSWORD_REQUIRE_UPPERCASE: bool = True
    MAX_LOGIN_ATTEMPTS: int = 5
    ACCOUNT_LOCKOUT_MINUTES: int = 30
    
    # LDAP/AD Integration (Optional)
    LDAP_ENABLED: bool = False
    LDAP_SERVER: Optional[str] = None
    LDAP_PORT: int = 389
    LDAP_USE_SSL: bool = False
    LDAP_BASE_DN: Optional[str] = None
    LDAP_USER_DN_TEMPLATE: Optional[str] = None
    LDAP_BIND_USER: Optional[str] = None
    LDAP_BIND_PASSWORD: Optional[str] = None
    
    # Email Configuration
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: int = 587
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    SMTP_TLS: bool = True
    EMAIL_FROM: str = "noreply@logmaster.com"
    EMAIL_FROM_NAME: str = "LogMaster v2"
    
    # Monitoring & Alerts
    PROMETHEUS_ENABLED: bool = True
    PROMETHEUS_PORT: int = 9090
    GRAFANA_ENABLED: bool = True
    GRAFANA_PORT: int = 3000
    ALERT_EMAIL_ENABLED: bool = False
    ALERT_RECIPIENTS: List[str] = []
    
    # Rate Limiting
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_REQUESTS: int = 100
    RATE_LIMIT_WINDOW: int = 60  # seconds
    API_RATE_LIMIT: str = "1000/hour"
    
    # File Upload
    MAX_UPLOAD_SIZE: int = 100 * 1024 * 1024  # 100MB
    ALLOWED_UPLOAD_EXTENSIONS: List[str] = [".log", ".txt", ".csv"]
    
    # Backup Configuration
    BACKUP_ENABLED: bool = True
    BACKUP_SCHEDULE: str = "0 2 * * *"  # Daily at 2 AM
    BACKUP_RETENTION_DAYS: int = 30
    BACKUP_STORAGE_PATH: str = "/backup/logmaster"
    BACKUP_COMPRESS: bool = True
    
    # Performance Settings
    DB_POOL_SIZE: int = 20
    DB_MAX_OVERFLOW: int = 30
    DB_POOL_TIMEOUT: int = 30
    ELASTICSEARCH_BULK_SIZE: int = 1000
    REDIS_POOL_SIZE: int = 10
    
    # Security Headers
    SECURITY_HEADERS: Dict[str, str] = {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "X-XSS-Protection": "1; mode=block",
        "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
        "Content-Security-Policy": "default-src 'self'"
    }
    
    # Logging Configuration
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    LOG_FILE_PATH: str = "/var/log/logmaster/application.log"
    LOG_FILE_MAX_SIZE: int = 50 * 1024 * 1024  # 50MB
    LOG_FILE_BACKUP_COUNT: int = 10
    
    # 5651 Compliance Settings
    COMPLIANCE_ENABLED: bool = True
    COMPLIANCE_AUDIT_LOG: str = "/var/log/logmaster/audit.log"
    COMPLIANCE_REPORT_SCHEDULE: str = "0 0 1 * *"  # Monthly
    COMPLIANCE_VIOLATION_ALERT: bool = True
    AUTO_COMPLIANCE_CHECK: bool = True
    COMPLIANCE_CHECK_INTERVAL: int = 3600  # 1 hour
    
    # Feature Flags
    FEATURE_DEVICE_AUTO_DISCOVERY: bool = True
    FEATURE_REAL_TIME_MONITORING: bool = True
    FEATURE_ADVANCED_ANALYTICS: bool = True
    FEATURE_MACHINE_LEARNING: bool = False
    FEATURE_API_VERSIONING: bool = True
    
    # Development Settings
    CORS_ENABLED: bool = True
    API_DOCS_ENABLED: bool = True
    PROFILE_ENABLED: bool = False
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        env_prefix = "LOGMASTER_"


class DevelopmentSettings(Settings):
    """Development environment settings"""
    DEBUG: bool = True
    LOG_LEVEL: str = "DEBUG"
    CORS_ENABLED: bool = True
    API_DOCS_ENABLED: bool = True
    
    # Relaxed security for development
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours
    PASSWORD_MIN_LENGTH: int = 8
    PASSWORD_REQUIRE_SPECIAL_CHARS: bool = False
    MAX_LOGIN_ATTEMPTS: int = 10
    
    # Development database
    POSTGRES_HOST: str = "localhost"
    POSTGRES_DB: str = "logmaster_v2_dev"


class ProductionSettings(Settings):
    """Production environment settings"""
    DEBUG: bool = False
    LOG_LEVEL: str = "WARNING"
    
    # Enhanced security for production
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 4  # 4 hours
    PASSWORD_MIN_LENGTH: int = 16
    PASSWORD_REQUIRE_SPECIAL_CHARS: bool = True
    MAX_LOGIN_ATTEMPTS: int = 3
    ACCOUNT_LOCKOUT_MINUTES: int = 60
    
    # Production security
    ALLOWED_HOSTS: List[str] = ["logmaster.company.com", "*.company.com"]
    CORS_ENABLED: bool = False
    API_DOCS_ENABLED: bool = False


class TestingSettings(Settings):
    """Testing environment settings"""
    DEBUG: bool = True
    LOG_LEVEL: str = "DEBUG"
    
    # Test database
    POSTGRES_DB: str = "logmaster_v2_test"
    REDIS_DB: int = 1
    
    # Faster tests
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 5
    PASSWORD_MIN_LENGTH: int = 6
    
    # Disable external services in tests
    LDAP_ENABLED: bool = False
    BACKUP_ENABLED: bool = False
    PROMETHEUS_ENABLED: bool = False


@lru_cache()
def get_settings() -> Settings:
    """Get application settings based on environment"""
    environment = os.getenv("ENVIRONMENT", "development").lower()
    
    if environment == "production":
        return ProductionSettings()
    elif environment == "testing":
        return TestingSettings()
    else:
        return DevelopmentSettings()


# Global settings instance
settings = get_settings() 
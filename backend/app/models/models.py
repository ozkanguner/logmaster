#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LogMaster v2 - Database Models
Enterprise-level database models with device-based authentication and granular permissions
"""

from sqlalchemy import (
    Column, Integer, String, Text, Boolean, DateTime, JSON, 
    ForeignKey, UniqueConstraint, Index, BigInteger, Float,
    TIMESTAMP, Enum as SQLEnum, LargeBinary
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, backref
from sqlalchemy.dialects.postgresql import UUID, INET, JSONB, ARRAY
from sqlalchemy.sql import func
import uuid
from datetime import datetime
from enum import Enum
from typing import Optional, List, Dict, Any

from app.core.database import Base


class UserRole(str, Enum):
    """User role enumeration"""
    ADMIN = "admin"
    NETWORK_MANAGER = "network_manager"
    SECURITY_ANALYST = "security_analyst"
    LOCATION_MANAGER = "location_manager"
    DEVICE_OWNER = "device_owner"
    VIEWER = "viewer"


class DeviceStatus(str, Enum):
    """Device status enumeration"""
    PENDING = "pending"
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"
    MAINTENANCE = "maintenance"


class DeviceType(str, Enum):
    """Device type enumeration"""
    FIREWALL = "firewall"
    ROUTER = "router"
    SWITCH = "switch"
    ACCESS_POINT = "access_point"
    IDS = "ids"
    IPS = "ips"
    PROXY = "proxy"
    LOAD_BALANCER = "load_balancer"
    OTHER = "other"


class PermissionLevel(str, Enum):
    """Permission level enumeration"""
    READ = "read"
    WRITE = "write"
    ADMIN = "admin"
    OWNER = "owner"


class LogLevel(str, Enum):
    """Log level enumeration"""
    DEBUG = "debug"
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


# User Management Tables
class User(Base):
    """User model with enhanced security features"""
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    
    # Profile information
    first_name = Column(String(50))
    last_name = Column(String(50))
    department = Column(String(100))
    job_title = Column(String(100))
    phone = Column(String(20))
    
    # Role and permissions
    role = Column(SQLEnum(UserRole), default=UserRole.VIEWER, nullable=False)
    
    # Security settings
    two_factor_enabled = Column(Boolean, default=False)
    two_factor_secret = Column(String(32))
    ip_restriction_enabled = Column(Boolean, default=False)
    allowed_ip_ranges = Column(JSONB)
    session_timeout_minutes = Column(Integer, default=480)  # 8 hours
    
    # Account status
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    last_login = Column(DateTime(timezone=True))
    failed_login_attempts = Column(Integer, default=0)
    account_locked_until = Column(DateTime(timezone=True))
    
    # LDAP integration
    ldap_dn = Column(String(255))
    external_id = Column(String(100))
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    
    # Relationships
    device_permissions = relationship("UserDevicePermission", back_populates="user")
    audit_logs = relationship("AuditLog", back_populates="user")
    compliance_reports = relationship("ComplianceReport", back_populates="created_by_user")


class UserSession(Base):
    """User session tracking for security"""
    __tablename__ = "user_sessions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    session_token = Column(String(255), unique=True, nullable=False)
    refresh_token = Column(String(255), unique=True, nullable=False)
    
    # Session details
    ip_address = Column(INET)
    user_agent = Column(Text)
    device_fingerprint = Column(String(255))
    
    # Session status
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=False)
    last_activity = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", backref="sessions")


# Device Management Tables
class DeviceGroup(Base):
    """Device grouping for hierarchical permissions"""
    __tablename__ = "device_groups"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    group_name = Column(String(100), nullable=False, index=True)
    description = Column(Text)
    location = Column(String(200))
    group_type = Column(String(50))  # 'location', 'function', 'security_level'
    
    # Hierarchical structure
    parent_group_id = Column(UUID(as_uuid=True), ForeignKey("device_groups.id"))
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    
    # Relationships
    parent_group = relationship("DeviceGroup", remote_side=[id])
    child_groups = relationship("DeviceGroup", back_populates="parent_group")
    devices = relationship("Device", back_populates="group")


class Device(Base):
    """Enhanced device model with MAC-based authentication"""
    __tablename__ = "devices"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    mac_address = Column(String(17), unique=True, nullable=False, index=True)
    device_name = Column(String(100), nullable=False)
    
    # Network information
    ip_address = Column(INET)
    hostname = Column(String(255))
    port = Column(Integer)
    
    # Device details
    device_type = Column(SQLEnum(DeviceType), nullable=False)
    manufacturer = Column(String(100))
    model = Column(String(100))
    firmware_version = Column(String(50))
    serial_number = Column(String(100))
    
    # Location and organization
    location = Column(String(200))
    building = Column(String(100))
    floor = Column(String(50))
    room = Column(String(50))
    group_id = Column(UUID(as_uuid=True), ForeignKey("device_groups.id"))
    
    # Status and monitoring
    status = Column(SQLEnum(DeviceStatus), default=DeviceStatus.PENDING)
    is_online = Column(Boolean, default=False)
    last_seen = Column(DateTime(timezone=True))
    heartbeat_interval = Column(Integer, default=300)  # seconds
    
    # Security settings
    security_level = Column(String(20), default="medium")  # low, medium, high, critical
    encryption_enabled = Column(Boolean, default=False)
    certificate_required = Column(Boolean, default=False)
    
    # Compliance and monitoring
    monitoring_enabled = Column(Boolean, default=True)
    log_level = Column(SQLEnum(LogLevel), default=LogLevel.INFO)
    retention_days = Column(Integer, default=730)  # 5651 compliance
    
    # Registration and ownership
    registration_date = Column(DateTime(timezone=True), server_default=func.now())
    approved_date = Column(DateTime(timezone=True))
    owner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    approved_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    
    # Configuration
    syslog_port = Column(Integer, default=514)
    log_format = Column(String(50), default="syslog")
    timezone = Column(String(50), default="UTC")
    config_data = Column(JSONB)
    tags = Column(JSONB)  # Flexible tagging system
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    group = relationship("DeviceGroup", back_populates="devices")
    owner = relationship("User", foreign_keys=[owner_id])
    approver = relationship("User", foreign_keys=[approved_by])
    permissions = relationship("UserDevicePermission", back_populates="device")
    log_entries = relationship("LogEntry", back_populates="device")
    signatures = relationship("DigitalSignature", back_populates="device")
    
    # Indexes
    __table_args__ = (
        Index("idx_device_status", "status"),
        Index("idx_device_location", "location"),
        Index("idx_device_type", "device_type"),
        Index("idx_device_last_seen", "last_seen"),
    )


# Permission Management Tables
class UserDevicePermission(Base):
    """Granular device-specific permissions"""
    __tablename__ = "user_device_permissions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id"))
    device_group_id = Column(UUID(as_uuid=True), ForeignKey("device_groups.id"))
    
    # Permission level
    permission_level = Column(SQLEnum(PermissionLevel), nullable=False)
    
    # Action-based permissions
    can_view_logs = Column(Boolean, default=False)
    can_export_logs = Column(Boolean, default=False)
    can_delete_logs = Column(Boolean, default=False)
    can_configure_device = Column(Boolean, default=False)
    can_view_real_time = Column(Boolean, default=False)
    can_access_archives = Column(Boolean, default=False)
    can_manage_signatures = Column(Boolean, default=False)
    
    # Time-based restrictions
    access_start_time = Column(String(5))  # HH:MM format
    access_end_time = Column(String(5))    # HH:MM format
    access_days = Column(JSONB)  # ['monday', 'tuesday', ...]
    valid_from = Column(DateTime(timezone=True))
    valid_until = Column(DateTime(timezone=True))
    
    # Location-based restrictions
    allowed_ip_ranges = Column(JSONB)  # ['192.168.1.0/24', ...]
    allowed_locations = Column(JSONB)  # ['office', 'home', ...]
    
    # Usage tracking
    last_accessed = Column(DateTime(timezone=True))
    access_count = Column(Integer, default=0)
    
    # Status
    is_active = Column(Boolean, default=True)
    granted_at = Column(DateTime(timezone=True), server_default=func.now())
    granted_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    
    # Relationships
    user = relationship("User", back_populates="device_permissions")
    device = relationship("Device", back_populates="permissions")
    device_group = relationship("DeviceGroup")
    granter = relationship("User", foreign_keys=[granted_by])
    
    # Constraints
    __table_args__ = (
        UniqueConstraint("user_id", "device_id", name="unique_user_device"),
        Index("idx_permission_user", "user_id"),
        Index("idx_permission_device", "device_id"),
        Index("idx_permission_active", "is_active"),
    )


# Log Management Tables
class LogEntry(Base):
    """Enhanced log entry model with full-text search support"""
    __tablename__ = "log_entries"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id"), nullable=False, index=True)
    
    # Log content
    message = Column(Text, nullable=False)
    raw_message = Column(Text)  # Original unprocessed message
    log_level = Column(SQLEnum(LogLevel), default=LogLevel.INFO, index=True)
    facility = Column(String(50))
    
    # Timestamp information
    timestamp = Column(DateTime(timezone=True), nullable=False, index=True)
    received_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Network information
    source_ip = Column(INET, index=True)
    destination_ip = Column(INET)
    source_port = Column(Integer)
    destination_port = Column(Integer)
    protocol = Column(String(10))
    
    # Parsed fields
    parsed_data = Column(JSONB)
    user_id_field = Column(String(100))  # Extracted user ID from log
    session_id = Column(String(100))     # Extracted session ID
    action = Column(String(100))         # Extracted action
    result = Column(String(50))          # success, failure, error
    
    # Classification and analysis
    category = Column(String(50), index=True)  # authentication, network, security, etc.
    severity_score = Column(Integer)    # 1-10 severity rating
    risk_level = Column(String(20))     # low, medium, high, critical
    is_anomaly = Column(Boolean, default=False)
    
    # Compliance and retention
    is_sensitive = Column(Boolean, default=False)
    retention_category = Column(String(50))
    compliance_flags = Column(JSONB)
    
    # Processing status
    is_processed = Column(Boolean, default=False)
    is_indexed = Column(Boolean, default=False)
    processing_errors = Column(JSONB)
    
    # File information
    log_file_path = Column(String(500))
    log_file_line = Column(BigInteger)
    checksum = Column(String(64))  # SHA-256 hash
    
    # Relationships
    device = relationship("Device", back_populates="log_entries")
    alerts = relationship("SecurityAlert", back_populates="log_entry")
    
    # Indexes for performance
    __table_args__ = (
        Index("idx_log_timestamp", "timestamp"),
        Index("idx_log_device_timestamp", "device_id", "timestamp"),
        Index("idx_log_source_ip", "source_ip"),
        Index("idx_log_category", "category"),
        Index("idx_log_risk_level", "risk_level"),
        Index("idx_log_processed", "is_processed"),
    )


# Digital Signature and Compliance Tables
class DigitalSignature(Base):
    """Digital signature records for 5651 compliance"""
    __tablename__ = "digital_signatures"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id"), nullable=False)
    
    # File information
    file_path = Column(String(500), nullable=False)
    file_name = Column(String(255), nullable=False)
    file_size = Column(BigInteger)
    file_hash = Column(String(64), nullable=False)  # SHA-256
    
    # Signature details
    signature_data = Column(LargeBinary, nullable=False)
    signature_algorithm = Column(String(50), default="RSA-SHA256")
    signing_certificate = Column(Text)
    
    # Timestamp information
    signed_at = Column(DateTime(timezone=True), server_default=func.now())
    timestamp_authority = Column(String(255))
    timestamp_token = Column(LargeBinary)
    
    # Verification status
    is_valid = Column(Boolean, default=True)
    last_verified = Column(DateTime(timezone=True))
    verification_errors = Column(JSONB)
    
    # Compliance information
    compliance_period = Column(String(20))  # "daily", "weekly", "monthly"
    log_count = Column(Integer)
    date_range_start = Column(DateTime(timezone=True))
    date_range_end = Column(DateTime(timezone=True))
    
    # Metadata
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    
    # Relationships
    device = relationship("Device", back_populates="signatures")
    creator = relationship("User")
    
    # Indexes
    __table_args__ = (
        Index("idx_signature_device", "device_id"),
        Index("idx_signature_date", "signed_at"),
        Index("idx_signature_file", "file_path"),
    )


class ComplianceReport(Base):
    """5651 compliance reports"""
    __tablename__ = "compliance_reports"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_type = Column(String(50), nullable=False)  # daily, weekly, monthly, yearly
    report_period_start = Column(DateTime(timezone=True), nullable=False)
    report_period_end = Column(DateTime(timezone=True), nullable=False)
    
    # Report content
    report_data = Column(JSONB, nullable=False)
    summary = Column(JSONB)
    violations = Column(JSONB)
    recommendations = Column(JSONB)
    
    # File information
    report_file_path = Column(String(500))
    report_file_size = Column(BigInteger)
    report_format = Column(String(20), default="PDF")
    
    # Status
    status = Column(String(20), default="generated")  # generated, reviewed, approved
    generated_at = Column(DateTime(timezone=True), server_default=func.now())
    reviewed_at = Column(DateTime(timezone=True))
    approved_at = Column(DateTime(timezone=True))
    
    # Users
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    reviewed_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    approved_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    
    # Relationships
    created_by_user = relationship("User", foreign_keys=[created_by])
    reviewed_by_user = relationship("User", foreign_keys=[reviewed_by])
    approved_by_user = relationship("User", foreign_keys=[approved_by])


# Security and Monitoring Tables
class SecurityAlert(Base):
    """Security alerts and anomaly detection"""
    __tablename__ = "security_alerts"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    log_entry_id = Column(UUID(as_uuid=True), ForeignKey("log_entries.id"))
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id"))
    
    # Alert details
    alert_type = Column(String(50), nullable=False)  # intrusion, anomaly, compliance
    severity = Column(String(20), nullable=False)    # low, medium, high, critical
    title = Column(String(200), nullable=False)
    description = Column(Text)
    
    # Detection information
    detection_method = Column(String(50))  # rule, ml, threshold
    confidence_score = Column(Float)
    false_positive_probability = Column(Float)
    
    # Status and handling
    status = Column(String(20), default="open")  # open, investigating, resolved, false_positive
    assigned_to = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    resolved_at = Column(DateTime(timezone=True))
    resolution_notes = Column(Text)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    log_entry = relationship("LogEntry", back_populates="alerts")
    device = relationship("Device")
    assignee = relationship("User")


class AuditLog(Base):
    """Comprehensive audit logging for compliance"""
    __tablename__ = "audit_logs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    
    # Action details
    action = Column(String(100), nullable=False)
    resource_type = Column(String(50))  # device, user, log, permission
    resource_id = Column(String(100))
    
    # Request information
    ip_address = Column(INET)
    user_agent = Column(Text)
    session_id = Column(String(100))
    
    # Details
    details = Column(JSONB)
    old_values = Column(JSONB)
    new_values = Column(JSONB)
    
    # Results
    success = Column(Boolean, nullable=False)
    error_message = Column(Text)
    
    # Timestamp
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="audit_logs")
    
    # Indexes
    __table_args__ = (
        Index("idx_audit_user", "user_id"),
        Index("idx_audit_timestamp", "timestamp"),
        Index("idx_audit_action", "action"),
        Index("idx_audit_resource", "resource_type", "resource_id"),
    ) 
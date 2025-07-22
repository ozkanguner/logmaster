# LogMaster v2 - Database Schema

## 🗄️ Database Design Overview

LogMaster v2 uses a multi-database architecture optimized for enterprise log management with granular device permissions and 5651 compliance.

## 📊 Entity Relationship Diagram

```mermaid
erDiagram
    USERS {
        uuid id PK
        string username UK
        string email UK
        string password_hash
        enum role
        string first_name
        string last_name
        string department
        boolean is_active
        json allowed_ip_ranges
        timestamp created_at
        timestamp last_login
    }
    
    USER_SESSIONS {
        uuid id PK
        uuid user_id FK
        string session_token UK
        string refresh_token UK
        inet ip_address
        text user_agent
        boolean is_active
        timestamp expires_at
    }
    
    DEVICE_GROUPS {
        uuid id PK
        string group_name
        string description
        string location
        string group_type
        uuid parent_group_id FK
        timestamp created_at
    }
    
    DEVICES {
        uuid id PK
        string mac_address UK
        string device_name
        inet ip_address
        enum device_type
        string location
        enum status
        uuid group_id FK
        uuid owner_id FK
        integer retention_days
        json config_data
        timestamp registration_date
        timestamp last_seen
    }
    
    USER_DEVICE_PERMISSIONS {
        uuid id PK
        uuid user_id FK
        uuid device_id FK
        uuid device_group_id FK
        enum permission_level
        boolean can_view_logs
        boolean can_export_logs
        boolean can_delete_logs
        boolean can_configure_device
        boolean can_view_real_time
        boolean can_access_archives
        string access_start_time
        string access_end_time
        json access_days
        json allowed_ip_ranges
        timestamp valid_from
        timestamp valid_until
        integer access_count
        boolean is_active
        timestamp granted_at
    }
    
    LOG_ENTRIES {
        uuid id PK
        uuid device_id FK
        text message
        text raw_message
        enum log_level
        timestamp timestamp
        inet source_ip
        inet destination_ip
        integer source_port
        integer destination_port
        string protocol
        json parsed_data
        string category
        string risk_level
        boolean is_processed
        boolean is_indexed
        string log_file_path
        string checksum
    }
    
    DIGITAL_SIGNATURES {
        uuid id PK
        uuid device_id FK
        string file_path
        string file_name
        bigint file_size
        string file_hash
        bytea signature_data
        string signature_algorithm
        timestamp signed_at
        boolean is_valid
        integer log_count
        timestamp date_range_start
        timestamp date_range_end
    }
    
    COMPLIANCE_REPORTS {
        uuid id PK
        string report_type
        timestamp report_period_start
        timestamp report_period_end
        json report_data
        json summary
        json violations
        string status
        timestamp generated_at
        uuid created_by FK
    }
    
    SECURITY_ALERTS {
        uuid id PK
        uuid log_entry_id FK
        uuid device_id FK
        string alert_type
        string severity
        string title
        text description
        string detection_method
        float confidence_score
        string status
        uuid assigned_to FK
        timestamp resolved_at
    }
    
    AUDIT_LOGS {
        uuid id PK
        uuid user_id FK
        string action
        string resource_type
        string resource_id
        inet ip_address
        text user_agent
        json details
        json old_values
        json new_values
        boolean success
        text error_message
        timestamp timestamp
    }
    
    USERS ||--o{ USER_SESSIONS : "has"
    USERS ||--o{ USER_DEVICE_PERMISSIONS : "grants"
    USERS ||--o{ DEVICES : "owns"
    USERS ||--o{ COMPLIANCE_REPORTS : "creates"
    USERS ||--o{ SECURITY_ALERTS : "assigned_to"
    USERS ||--o{ AUDIT_LOGS : "performs"
    
    DEVICE_GROUPS ||--o{ DEVICE_GROUPS : "parent_child"
    DEVICE_GROUPS ||--o{ DEVICES : "contains"
    DEVICE_GROUPS ||--o{ USER_DEVICE_PERMISSIONS : "applies_to"
    
    DEVICES ||--o{ USER_DEVICE_PERMISSIONS : "secured_by"
    DEVICES ||--o{ LOG_ENTRIES : "generates"
    DEVICES ||--o{ DIGITAL_SIGNATURES : "signed_for"
    DEVICES ||--o{ SECURITY_ALERTS : "triggers"
    
    LOG_ENTRIES ||--o{ SECURITY_ALERTS : "analyzed_for"
```

## 📋 Table Descriptions

### 👥 Users & Authentication

#### `users`
Central user management with enhanced security features:
- **UUID primary keys** for better security
- **Role-based classification** (admin, network_manager, security_analyst, etc.)
- **LDAP integration** support with external_id
- **IP restriction** capabilities with JSONB arrays
- **Account lockout** mechanism for failed login attempts
- **Two-factor authentication** support

#### `user_sessions`
Comprehensive session tracking for security auditing:
- **Session tokens** with expiration
- **Device fingerprinting** for security
- **IP tracking** for location monitoring
- **Active session management**

### 📱 Device Management

#### `device_groups`
Hierarchical device organization:
- **Self-referencing** for parent-child relationships
- **Location-based** grouping (building, floor, room)
- **Function-based** grouping (firewall, router, switch)
- **Security-level** grouping (critical, high, medium, low)

#### `devices`
Enhanced device registration with MAC-based authentication:
- **MAC address** as unique identifier
- **Network information** (IP, hostname, port)
- **Hardware details** (manufacturer, model, firmware)
- **Status tracking** (pending, active, inactive, maintenance)
- **Configuration storage** in JSONB format
- **Flexible tagging** system

### 🔐 Permission Management

#### `user_device_permissions`
Granular device-specific permissions:
- **Multiple permission levels** (read, write, admin, owner)
- **Action-based permissions** for specific operations
- **Time-based restrictions** (hours, days, date ranges)
- **IP-based restrictions** with CIDR notation support
- **Usage tracking** (access count, last accessed)
- **Audit trail** (granted by, granted at)

### 📊 Log Management

#### `log_entries`
Comprehensive log storage with enhanced metadata:
- **Device relationship** for log source tracking
- **Parsed data** in JSONB for flexible querying
- **Network information** (source/destination IP and ports)
- **Security classification** (risk level, category)
- **Processing status** tracking
- **File system integration** with path and checksum

### ⚖️ Compliance & Security

#### `digital_signatures`
5651 compliance digital signatures:
- **File integrity** with SHA-256 hashing
- **RSA signature** data storage
- **TSA timestamping** support
- **Verification status** tracking
- **Date range coverage** for compliance periods

#### `compliance_reports`
Automated compliance reporting:
- **Multiple report types** (daily, weekly, monthly, yearly)
- **Structured data** in JSONB format
- **Violation tracking** and recommendations
- **Approval workflow** with multiple reviewers

#### `security_alerts`
Advanced threat detection and alerting:
- **ML-based detection** with confidence scoring
- **Alert management** workflow
- **False positive** tracking
- **Assignment and resolution** tracking

#### `audit_logs`
Comprehensive activity auditing:
- **Complete action tracking** for all user activities
- **Before/after values** for change tracking
- **Session correlation** with IP and user agent
- **Success/failure** tracking with error details

## 🔍 Database Indexes

### Performance Indexes
```sql
-- Users
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(is_active);

-- Devices
CREATE INDEX idx_devices_mac ON devices(mac_address);
CREATE INDEX idx_devices_status ON devices(status);
CREATE INDEX idx_devices_type ON devices(device_type);
CREATE INDEX idx_devices_location ON devices(location);
CREATE INDEX idx_devices_last_seen ON devices(last_seen);

-- Permissions
CREATE INDEX idx_permissions_user ON user_device_permissions(user_id);
CREATE INDEX idx_permissions_device ON user_device_permissions(device_id);
CREATE INDEX idx_permissions_active ON user_device_permissions(is_active);
CREATE INDEX idx_permissions_expires ON user_device_permissions(valid_until);

-- Log Entries
CREATE INDEX idx_logs_device ON log_entries(device_id);
CREATE INDEX idx_logs_timestamp ON log_entries(timestamp);
CREATE INDEX idx_logs_source_ip ON log_entries(source_ip);
CREATE INDEX idx_logs_level ON log_entries(log_level);
CREATE INDEX idx_logs_category ON log_entries(category);

-- Audit Logs
CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_timestamp ON audit_logs(timestamp);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_resource ON audit_logs(resource_type, resource_id);
```

### Unique Constraints
```sql
-- Unique constraints for data integrity
ALTER TABLE users ADD CONSTRAINT uk_users_username UNIQUE (username);
ALTER TABLE users ADD CONSTRAINT uk_users_email UNIQUE (email);
ALTER TABLE devices ADD CONSTRAINT uk_devices_mac UNIQUE (mac_address);
ALTER TABLE user_sessions ADD CONSTRAINT uk_sessions_token UNIQUE (session_token);
ALTER TABLE user_device_permissions ADD CONSTRAINT uk_user_device UNIQUE (user_id, device_id);
```

## 🚀 Database Performance Considerations

### Connection Pooling
- **Pool size**: 20 connections
- **Max overflow**: 30 connections
- **Pool timeout**: 30 seconds
- **Connection recycling**: 1 hour

### Query Optimization
- **Prepared statements** for frequent queries
- **Connection pooling** for concurrent access
- **Query result caching** with Redis
- **Batch operations** for bulk inserts

### Scaling Strategy
- **Read replicas** for read-heavy workloads
- **Partitioning** for large tables (log_entries, audit_logs)
- **Archival strategy** for old data
- **Backup and recovery** procedures

## 🔒 Security Considerations

### Data Encryption
- **At-rest encryption** for sensitive columns
- **SSL/TLS connections** for all database access
- **Password hashing** with bcrypt
- **Token encryption** for session management

### Access Control
- **Database user roles** with minimal privileges
- **Application-level security** with ORM
- **Audit logging** for all database changes
- **Regular security updates** and patches

### Backup Strategy
- **Daily automated backups**
- **Point-in-time recovery** capability
- **Offsite backup storage**
- **Regular restore testing** 
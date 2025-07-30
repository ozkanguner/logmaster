package models

import (
	"time"
)

// BusinessType represents the type of business/location
type BusinessType string

const (
	BusinessTypeHotel      BusinessType = "HOTEL"
	BusinessTypeCafe       BusinessType = "CAFE"
	BusinessTypeRestaurant BusinessType = "RESTAURANT"
	BusinessTypeAVM        BusinessType = "AVM"
	BusinessTypeOkul       BusinessType = "OKUL"
	BusinessTypeYurt       BusinessType = "YURT"
	BusinessTypeKonukevi   BusinessType = "KONUKEVI"
	BusinessTypeGeneral    BusinessType = "general"
)

// Business represents a business entity with multiple devices
type Business struct {
	ID          int64        `json:"id" db:"id"`
	Name        string       `json:"name" db:"name"`
	Type        BusinessType `json:"type" db:"type"`
	IPAddresses []string     `json:"ip_addresses" db:"ip_addresses"`
	CreatedAt   time.Time    `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time    `json:"updated_at" db:"updated_at"`
	IsActive    bool         `json:"is_active" db:"is_active"`
}

// User represents a system user with role-based access
type User struct {
	ID         int64     `json:"id" db:"id"`
	Username   string    `json:"username" db:"username"`
	Email      string    `json:"email" db:"email"`
	Role       UserRole  `json:"role" db:"role"`
	BusinessID *int64    `json:"business_id,omitempty" db:"business_id"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time `json:"updated_at" db:"updated_at"`
	IsActive   bool      `json:"is_active" db:"is_active"`
}

// UserRole represents user access levels
type UserRole string

const (
	UserRoleSuperAdmin    UserRole = "super_admin"
	UserRoleBusinessOwner UserRole = "business_owner"
	UserRoleBusinessViewer UserRole = "business_viewer"
)

// LogEntry represents a structured log entry from RSyslog
type LogEntry struct {
	ID         string               `json:"id"`
	Timestamp  time.Time            `json:"timestamp"`
	IP         string               `json:"ip"`
	Interface  string               `json:"interface"`
	Facility   string               `json:"facility"`
	Severity   string               `json:"severity"`
	Hostname   string               `json:"hostname"`
	Tag        string               `json:"tag"`
	Message    string               `json:"message"`
	BusinessID *int64               `json:"business_id,omitempty"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
	CreatedAt  time.Time            `json:"created_at"`
}

// LogRequest represents a request for log ingestion
type LogRequest struct {
	IP        string    `json:"ip" binding:"required"`
	Interface string    `json:"interface"`
	Facility  string    `json:"facility"`
	Severity  string    `json:"severity"`
	Hostname  string    `json:"hostname"`
	Tag       string    `json:"tag"`
	Message   string    `json:"message" binding:"required"`
	Timestamp time.Time `json:"timestamp"`
}

// LogResponse represents the response after log ingestion
type LogResponse struct {
	Status    string    `json:"status"`
	Message   string    `json:"message"`
	LogID     string    `json:"log_id,omitempty"`
	Timestamp time.Time `json:"timestamp"`
}

// LogFilter represents filter criteria for log queries
type LogFilter struct {
	StartTime    time.Time `json:"start_time"`
	EndTime      time.Time `json:"end_time"`
	IP           string    `json:"ip"`
	Interface    string    `json:"interface"`
	Facility     string    `json:"facility"`
	Severity     string    `json:"severity"`
	SearchQuery  string    `json:"search_query"`
	BusinessID   *int64    `json:"business_id"`
	Limit        int       `json:"limit"`
	Offset       int       `json:"offset"`
	SortBy       string    `json:"sort_by"`
	SortOrder    string    `json:"sort_order"`
}

// LogStatistics represents aggregated log statistics
type LogStatistics struct {
	TotalLogs        int64                  `json:"total_logs"`
	LogsToday        int64                  `json:"logs_today"`
	LogsThisHour     int64                  `json:"logs_this_hour"`
	ActiveIPs        int                    `json:"active_ips"`
	ActiveInterfaces int                    `json:"active_interfaces"`
	InterfaceStats   map[string]int64       `json:"interface_stats"`
	IPStats          map[string]int64       `json:"ip_stats"`
	SeverityStats    map[string]int64       `json:"severity_stats"`
	HourlyStats      []HourlyLogStat        `json:"hourly_stats"`
	LastUpdate       time.Time              `json:"last_update"`
}

// HourlyLogStat represents log statistics for a specific hour
type HourlyLogStat struct {
	Hour      time.Time `json:"hour"`
	Count     int64     `json:"count"`
	Interface string    `json:"interface,omitempty"`
}

// SystemMetrics represents system performance metrics
type SystemMetrics struct {
	CPUUsage         float64   `json:"cpu_usage"`
	MemoryUsage      float64   `json:"memory_usage"`
	MemoryTotal      int64     `json:"memory_total"`
	MemoryUsed       int64     `json:"memory_used"`
	DiskUsage        float64   `json:"disk_usage"`
	DiskTotal        int64     `json:"disk_total"`
	DiskUsed         int64     `json:"disk_used"`
	NetworkBytesIn   int64     `json:"network_bytes_in"`
	NetworkBytesOut  int64     `json:"network_bytes_out"`
	LogsPerSecond    float64   `json:"logs_per_second"`
	ActiveConnections int      `json:"active_connections"`
	Uptime           float64   `json:"uptime"`
	LoadAverage      float64   `json:"load_average"`
	Timestamp        time.Time `json:"timestamp"`
}

// ServiceStatus represents the status of a system service
type ServiceStatus struct {
	Name      string    `json:"name"`
	Status    string    `json:"status"`
	Uptime    float64   `json:"uptime"`
	PID       int       `json:"pid"`
	Memory    int64     `json:"memory"`
	CPU       float64   `json:"cpu"`
	LastCheck time.Time `json:"last_check"`
}

// SystemStatus represents overall system health
type SystemStatus struct {
	Status      string                    `json:"status"`
	Services    map[string]ServiceStatus  `json:"services"`
	Metrics     SystemMetrics             `json:"metrics"`
	LogDir      string                    `json:"log_directory"`
	ConfigPath  string                    `json:"config_path"`
	Version     string                    `json:"version"`
	LastCheck   time.Time                 `json:"last_check"`
}

// InterfaceDetectionResult represents the result of interface detection
type InterfaceDetectionResult struct {
	Interface  string                 `json:"interface"`
	Confidence float64                `json:"confidence"`
	Method     string                 `json:"method"`
	Keywords   []string               `json:"keywords,omitempty"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
}

// AutoDiscoveryEvent represents an auto-discovery event
type AutoDiscoveryEvent struct {
	ID           string    `json:"id"`
	EventType    string    `json:"event_type"` // "new_ip", "new_interface", "new_directory"
	IP           string    `json:"ip"`
	Interface    string    `json:"interface"`
	DirectoryPath string   `json:"directory_path"`
	FirstSeen    time.Time `json:"first_seen"`
	LogCount     int64     `json:"log_count"`
	Status       string    `json:"status"`
}

// FileStructure represents the log file directory structure
type FileStructure struct {
	BasePath     string      `json:"base_path"`
	TotalSize    int64       `json:"total_size"`
	FileCount    int         `json:"file_count"`
	Directories  []IPDirectory `json:"directories"`
	LastScanned  time.Time   `json:"last_scanned"`
}

// IPDirectory represents a directory for a specific IP
type IPDirectory struct {
	IP          string              `json:"ip"`
	Path        string              `json:"path"`
	Size        int64               `json:"size"`
	Interfaces  []InterfaceDirectory `json:"interfaces"`
	CreatedAt   time.Time           `json:"created_at"`
	LastModified time.Time          `json:"last_modified"`
}

// InterfaceDirectory represents a directory for a specific interface
type InterfaceDirectory struct {
	Name         string     `json:"name"`
	Path         string     `json:"path"`
	Size         int64      `json:"size"`
	FileCount    int        `json:"file_count"`
	Files        []LogFile  `json:"files"`
	CreatedAt    time.Time  `json:"created_at"`
	LastModified time.Time  `json:"last_modified"`
}

// LogFile represents a log file
type LogFile struct {
	Name         string    `json:"name"`
	Path         string    `json:"path"`
	Size         int64     `json:"size"`
	LineCount    int64     `json:"line_count"`
	Date         string    `json:"date"`
	CreatedAt    time.Time `json:"created_at"`
	LastModified time.Time `json:"last_modified"`
}

// ArchiveInfo represents archive file information
type ArchiveInfo struct {
	OriginalPath string    `json:"original_path"`
	ArchivePath  string    `json:"archive_path"`
	OriginalSize int64     `json:"original_size"`
	CompressedSize int64   `json:"compressed_size"`
	CompressionRatio float64 `json:"compression_ratio"`
	ArchiveDate  time.Time `json:"archive_date"`
	RetentionDays int      `json:"retention_days"`
}

// Alert represents a system alert
type Alert struct {
	ID          string                 `json:"id"`
	Type        string                 `json:"type"`
	Severity    string                 `json:"severity"`
	Title       string                 `json:"title"`
	Description string                 `json:"description"`
	Source      string                 `json:"source"`
	Metadata    map[string]interface{} `json:"metadata"`
	CreatedAt   time.Time              `json:"created_at"`
	ResolvedAt  *time.Time             `json:"resolved_at,omitempty"`
	Status      string                 `json:"status"`
}
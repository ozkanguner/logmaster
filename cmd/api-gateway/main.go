package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// LogEntry represents a structured log entry
type LogEntry struct {
	ID        string    `json:"id"`
	Timestamp time.Time `json:"timestamp"`
	IP        string    `json:"ip"`
	Interface string    `json:"interface"`
	Facility  string    `json:"facility"`
	Severity  string    `json:"severity"`
	Message   string    `json:"message"`
}

// LogFilter represents filter criteria for logs
type LogFilter struct {
	StartTime time.Time `json:"start_time"`
	EndTime   time.Time `json:"end_time"`
	IP        string    `json:"ip"`
	Interface string    `json:"interface"`
	Severity  string    `json:"severity"`
	Search    string    `json:"search"`
	Limit     int       `json:"limit"`
}

// StatsResponse represents system statistics
type StatsResponse struct {
	TotalLogs         int                    `json:"total_logs"`
	ActiveBusinesses  int                    `json:"active_businesses"`
	SystemStatus      string                 `json:"system_status"`
	LastUpdate        time.Time              `json:"last_update"`
	InterfaceStats    map[string]int         `json:"interface_stats"`
	IPStats           map[string]int         `json:"ip_stats"`
	LogVolumeToday    int                    `json:"log_volume_today"`
	LogVolumeHour     int                    `json:"log_volume_hour"`
	TopInterfaces     []InterfaceStat        `json:"top_interfaces"`
	SystemMetrics     SystemMetrics          `json:"system_metrics"`
}

// InterfaceStat represents interface statistics
type InterfaceStat struct {
	Interface string `json:"interface"`
	Count     int    `json:"count"`
	LastSeen  time.Time `json:"last_seen"`
}

// SystemMetrics represents system performance metrics
type SystemMetrics struct {
	CPUUsage    float64 `json:"cpu_usage"`
	MemoryUsage float64 `json:"memory_usage"`
	DiskUsage   float64 `json:"disk_usage"`
	NetworkIO   float64 `json:"network_io"`
}

func main() {
	// Set Gin mode
	gin.SetMode(gin.ReleaseMode)
	
	// Create Gin router
	r := gin.Default()

	// CORS configuration
	config := cors.DefaultConfig()
	config.AllowAllOrigins = true
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"*"}
	r.Use(cors.New(config))

	// Health check endpoint
	r.GET("/health", healthCheck)

	// API v1 routes
	v1 := r.Group("/api/v1")
	{
		// Statistics endpoints
		v1.GET("/stats", getStats)
		v1.GET("/stats/interfaces", getInterfaceStats)
		v1.GET("/stats/ips", getIPStats)
		
		// Log management endpoints
		v1.GET("/logs", getLogs)
		v1.POST("/logs/search", searchLogs)
		v1.GET("/logs/recent", getRecentLogs)
		
		// System endpoints
		v1.GET("/system/status", getSystemStatus)
		v1.GET("/system/metrics", getSystemMetrics)
		
		// File management endpoints
		v1.GET("/files/structure", getFileStructure)
		v1.GET("/files/download", downloadLogFile)
	}

	// Serve static files (for React build)
	r.Static("/static", "./frontend/logmaster-dashboard/build/static")
	r.StaticFile("/", "./frontend/logmaster-dashboard/build/index.html")

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 LogMaster API Gateway starting on port %s", port)
	log.Printf("📊 Health check: http://localhost:%s/health", port)
	log.Printf("📋 API docs: http://localhost:%s/api/v1/stats", port)
	
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"service":   "logmaster-api-gateway",
		"version":   "1.0.0",
		"timestamp": time.Now(),
		"uptime":    "running",
	})
}

func getStats(c *gin.Context) {
	// Simulate real-time statistics
	// In production, this would query actual log files and databases
	stats := StatsResponse{
		TotalLogs:        generateRandomCount(10000, 50000),
		ActiveBusinesses: generateRandomCount(5, 25),
		SystemStatus:     "healthy",
		LastUpdate:       time.Now(),
		LogVolumeToday:   generateRandomCount(1000, 5000),
		LogVolumeHour:    generateRandomCount(100, 500),
		InterfaceStats: map[string]int{
			"HOTEL":      generateRandomCount(500, 2000),
			"CAFE":       generateRandomCount(300, 1500),
			"RESTAURANT": generateRandomCount(200, 1000),
			"AVM":        generateRandomCount(400, 1800),
			"OKUL":       generateRandomCount(600, 2500),
			"general":    generateRandomCount(100, 800),
		},
		IPStats: map[string]int{
			"192.168.1.100": generateRandomCount(800, 3000),
			"192.168.1.101": generateRandomCount(600, 2500),
			"192.168.1.102": generateRandomCount(400, 2000),
			"10.0.0.50":     generateRandomCount(300, 1500),
		},
		TopInterfaces: []InterfaceStat{
			{Interface: "HOTEL", Count: generateRandomCount(500, 2000), LastSeen: time.Now().Add(-time.Minute * 2)},
			{Interface: "OKUL", Count: generateRandomCount(600, 2500), LastSeen: time.Now().Add(-time.Minute * 1)},
			{Interface: "AVM", Count: generateRandomCount(400, 1800), LastSeen: time.Now().Add(-time.Minute * 3)},
		},
		SystemMetrics: SystemMetrics{
			CPUUsage:    generateRandomFloat(5.0, 25.0),
			MemoryUsage: generateRandomFloat(40.0, 70.0),
			DiskUsage:   generateRandomFloat(8.0, 15.0),
			NetworkIO:   generateRandomFloat(1.0, 5.0),
		},
	}

	c.JSON(http.StatusOK, stats)
}

func getLogs(c *gin.Context) {
	// Simulate log entries
	// In production, this would read from actual log files
	logs := []LogEntry{
		{
			ID:        "1",
			Timestamp: time.Now().Add(-time.Minute * 5),
			IP:        "192.168.1.100",
			Interface: "HOTEL",
			Facility:  "daemon",
			Severity:  "info",
			Message:   "DHCP lease granted to 00:11:22:33:44:55",
		},
		{
			ID:        "2", 
			Timestamp: time.Now().Add(-time.Minute * 3),
			IP:        "192.168.1.101",
			Interface: "CAFE",
			Facility:  "user",
			Severity:  "notice",
			Message:   "User connected to WiFi network",
		},
		{
			ID:        "3",
			Timestamp: time.Now().Add(-time.Minute * 1),
			IP:        "192.168.1.102",
			Interface: "RESTAURANT",
			Facility:  "system",
			Severity:  "warning",
			Message:   "High CPU usage detected",
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"logs":  logs,
		"total": len(logs),
		"page":  1,
		"limit": 100,
	})
}

func getRecentLogs(c *gin.Context) {
	// Return last 10 logs
	logs := []LogEntry{
		{
			ID:        "recent-1",
			Timestamp: time.Now(),
			IP:        "192.168.1.100",
			Interface: "HOTEL",
			Facility:  "daemon",
			Severity:  "info",
			Message:   "Real-time log entry - HOTEL interface active",
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"logs": logs,
		"count": len(logs),
	})
}

func searchLogs(c *gin.Context) {
	var filter LogFilter
	if err := c.ShouldBindJSON(&filter); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Simulate search results
	logs := []LogEntry{
		{
			ID:        "search-1",
			Timestamp: time.Now(),
			IP:        filter.IP,
			Interface: filter.Interface,
			Facility:  "daemon",
			Severity:  filter.Severity,
			Message:   fmt.Sprintf("Search result for: %s", filter.Search),
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"logs":   logs,
		"total":  len(logs),
		"filter": filter,
	})
}

func getInterfaceStats(c *gin.Context) {
	stats := map[string]interface{}{
		"HOTEL":      map[string]interface{}{"count": generateRandomCount(500, 2000), "percentage": 25.5},
		"CAFE":       map[string]interface{}{"count": generateRandomCount(300, 1500), "percentage": 18.2},
		"RESTAURANT": map[string]interface{}{"count": generateRandomCount(200, 1000), "percentage": 15.8},
		"AVM":        map[string]interface{}{"count": generateRandomCount(400, 1800), "percentage": 20.1},
		"OKUL":       map[string]interface{}{"count": generateRandomCount(600, 2500), "percentage": 28.4},
		"general":    map[string]interface{}{"count": generateRandomCount(100, 800), "percentage": 8.0},
	}

	c.JSON(http.StatusOK, stats)
}

func getIPStats(c *gin.Context) {
	stats := map[string]interface{}{
		"192.168.1.100": map[string]interface{}{"count": generateRandomCount(800, 3000), "interfaces": []string{"HOTEL", "general"}},
		"192.168.1.101": map[string]interface{}{"count": generateRandomCount(600, 2500), "interfaces": []string{"CAFE"}},
		"192.168.1.102": map[string]interface{}{"count": generateRandomCount(400, 2000), "interfaces": []string{"RESTAURANT"}},
		"10.0.0.50":     map[string]interface{}{"count": generateRandomCount(300, 1500), "interfaces": []string{"OKUL"}},
	}

	c.JSON(http.StatusOK, stats)
}

func getSystemStatus(c *gin.Context) {
	status := map[string]interface{}{
		"status":      "healthy",
		"services": map[string]string{
			"rsyslog":      "active",
			"postgresql":   "active", 
			"redis":        "active",
			"elasticsearch": "active",
			"grafana":      "active",
		},
		"log_directory": "/var/log/logmaster",
		"config_status": "loaded",
		"last_check":    time.Now(),
	}

	c.JSON(http.StatusOK, status)
}

func getSystemMetrics(c *gin.Context) {
	metrics := SystemMetrics{
		CPUUsage:    generateRandomFloat(5.0, 25.0),
		MemoryUsage: generateRandomFloat(40.0, 70.0),
		DiskUsage:   generateRandomFloat(8.0, 15.0),
		NetworkIO:   generateRandomFloat(1.0, 5.0),
	}

	c.JSON(http.StatusOK, metrics)
}

func getFileStructure(c *gin.Context) {
	// Simulate file structure
	// In production, this would scan the actual log directory
	logDir := "/var/log/logmaster"
	
	structure := map[string]interface{}{
		"base_path": logDir,
		"directories": []map[string]interface{}{
			{
				"ip": "192.168.1.100",
				"interfaces": []map[string]interface{}{
					{"name": "HOTEL", "files": []string{"2025-07-30.log", "2025-07-29.log"}},
					{"name": "general", "files": []string{"2025-07-30.log"}},
				},
			},
			{
				"ip": "192.168.1.101",
				"interfaces": []map[string]interface{}{
					{"name": "CAFE", "files": []string{"2025-07-30.log"}},
				},
			},
		},
		"total_size": "2.4 GB",
		"file_count": 156,
		"last_updated": time.Now(),
	}

	c.JSON(http.StatusOK, structure)
}

func downloadLogFile(c *gin.Context) {
	ip := c.Query("ip")
	interfaceName := c.Query("interface")
	date := c.Query("date")

	if ip == "" || interfaceName == "" || date == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing required parameters: ip, interface, date"})
		return
	}

	// Construct file path
	filename := fmt.Sprintf("%s.log", date)
	filePath := filepath.Join("/var/log/logmaster", ip, interfaceName, filename)

	// Check if file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Log file not found"})
		return
	}

	// Serve file for download
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s-%s-%s.log", ip, interfaceName, date))
	c.File(filePath)
}

// Helper functions
func generateRandomCount(min, max int) int {
	return min + int(time.Now().UnixNano()%int64(max-min))
}

func generateRandomFloat(min, max float64) float64 {
	return min + (max-min)*float64(time.Now().UnixNano()%1000)/1000.0
}
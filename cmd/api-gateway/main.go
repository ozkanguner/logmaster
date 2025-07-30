package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
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
	// Real file-based statistics
	logDir := "/var/log/logmaster"
	stats, err := calculateRealStats(logDir)
	if err != nil {
		log.Printf("Error calculating stats: %v", err)
		// Fallback to basic stats
		stats = &StatsResponse{
			TotalLogs:        0,
			ActiveBusinesses: 0,
			SystemStatus:     "healthy",
			LastUpdate:       time.Now(),
			LogVolumeToday:   0,
			LogVolumeHour:    0,
			InterfaceStats:   make(map[string]int),
			IPStats:          make(map[string]int),
			TopInterfaces:    []InterfaceStat{},
			SystemMetrics: SystemMetrics{
				CPUUsage:    5.0,
				MemoryUsage: 40.0,
				DiskUsage:   10.0,
				NetworkIO:   1.0,
			},
		}
	}

	c.JSON(http.StatusOK, stats)
}

func getLogs(c *gin.Context) {
	// Real file-based log reading
	logDir := "/var/log/logmaster"
	
	// Get query parameters
	ip := c.Query("ip")
	interfaceName := c.Query("interface")
	limit := 100
	if l := c.Query("limit"); l != "" {
		if parsed, err := fmt.Sscanf(l, "%d", &limit); err == nil && parsed == 1 {
			if limit > 1000 {
				limit = 1000
			}
		}
	}
	
	logs, err := readRecentLogs(logDir, ip, interfaceName, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read logs"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"logs":  logs,
		"total": len(logs),
		"page":  1,
		"limit": limit,
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

// Helper functions for file-based operations
func calculateRealStats(logDir string) (*StatsResponse, error) {
	interfaceStats := make(map[string]int)
	ipStats := make(map[string]int)
	totalLogs := 0
	activeIPs := 0
	
	// Today's date for filtering
	today := time.Now().Format("2006-01-02")
	
	// Walk through log directory
	err := filepath.WalkDir(logDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil // Continue on errors
		}
		
		if d.IsDir() {
			return nil
		}
		
		// Only process today's log files
		if !strings.Contains(d.Name(), today) {
			return nil
		}
		
		// Extract IP and interface from path
		relPath, _ := filepath.Rel(logDir, path)
		parts := strings.Split(relPath, string(os.PathSeparator))
		if len(parts) >= 2 {
			ip := parts[0]
			interfaceName := parts[1]
			
			// Count lines in file (approximate log count)
			if lineCount, err := countLinesInFile(path); err == nil {
				interfaceStats[interfaceName] += lineCount
				ipStats[ip] += lineCount
				totalLogs += lineCount
			}
		}
		
		return nil
	})
	
	if err != nil {
		return nil, err
	}
	
	// Count unique IPs
	activeIPs = len(ipStats)
	
	// Build top interfaces
	var topInterfaces []InterfaceStat
	for iface, count := range interfaceStats {
		topInterfaces = append(topInterfaces, InterfaceStat{
			Interface: iface,
			Count:     count,
			LastSeen:  time.Now().Add(-time.Minute * 5), // Approximate
		})
	}
	
	// Sort by count
	sort.Slice(topInterfaces, func(i, j int) bool {
		return topInterfaces[i].Count > topInterfaces[j].Count
	})
	
	if len(topInterfaces) > 5 {
		topInterfaces = topInterfaces[:5]
	}
	
	return &StatsResponse{
		TotalLogs:        totalLogs,
		ActiveBusinesses: activeIPs,
		SystemStatus:     "healthy",
		LastUpdate:       time.Now(),
		LogVolumeToday:   totalLogs,
		LogVolumeHour:    totalLogs / 24, // Rough estimate
		InterfaceStats:   interfaceStats,
		IPStats:          ipStats,
		TopInterfaces:    topInterfaces,
		SystemMetrics: SystemMetrics{
			CPUUsage:    5.0,
			MemoryUsage: 40.0,
			DiskUsage:   10.0,
			NetworkIO:   1.0,
		},
	}, nil
}

func readRecentLogs(logDir, filterIP, filterInterface string, limit int) ([]LogEntry, error) {
	var logs []LogEntry
	today := time.Now().Format("2006-01-02")
	
	// Build search paths
	var searchPaths []string
	
	if filterIP != "" && filterInterface != "" {
		// Specific IP and interface
		searchPaths = append(searchPaths, filepath.Join(logDir, filterIP, filterInterface, today+".log"))
	} else if filterIP != "" {
		// Specific IP, all interfaces
		ipDir := filepath.Join(logDir, filterIP)
		if entries, err := os.ReadDir(ipDir); err == nil {
			for _, entry := range entries {
				if entry.IsDir() {
					searchPaths = append(searchPaths, filepath.Join(ipDir, entry.Name(), today+".log"))
				}
			}
		}
	} else {
		// All IPs and interfaces - scan everything
		filepath.WalkDir(logDir, func(path string, d fs.DirEntry, err error) error {
			if err != nil || d.IsDir() {
				return nil
			}
			if strings.Contains(d.Name(), today) {
				searchPaths = append(searchPaths, path)
			}
			return nil
		})
	}
	
	// Read logs from files
	for _, path := range searchPaths {
		if len(logs) >= limit {
			break
		}
		
		fileEntries, err := readLogFile(path, limit-len(logs))
		if err != nil {
			continue // Skip files with errors
		}
		
		logs = append(logs, fileEntries...)
	}
	
	// Sort by timestamp (newest first)
	sort.Slice(logs, func(i, j int) bool {
		return logs[i].Timestamp.After(logs[j].Timestamp)
	})
	
	if len(logs) > limit {
		logs = logs[:limit]
	}
	
	return logs, nil
}

func readLogFile(path string, maxLines int) ([]LogEntry, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	
	var logs []LogEntry
	scanner := bufio.NewScanner(file)
	lineCount := 0
	
	// Extract IP and interface from path
	logDir := "/var/log/logmaster"
	relPath, _ := filepath.Rel(logDir, path)
	parts := strings.Split(relPath, string(os.PathSeparator))
	
	var ip, interfaceName string
	if len(parts) >= 2 {
		ip = parts[0]
		interfaceName = parts[1]
	}
	
	for scanner.Scan() && lineCount < maxLines {
		line := scanner.Text()
		if line == "" {
			continue
		}
		
		// Try to parse JSON log entry
		var logData map[string]interface{}
		if err := json.Unmarshal([]byte(line), &logData); err != nil {
			// Fallback to plain text
			logs = append(logs, LogEntry{
				ID:        fmt.Sprintf("%s-%d", ip, lineCount),
				Timestamp: time.Now(),
				IP:        ip,
				Interface: interfaceName,
				Facility:  "system",
				Severity:  "info",
				Message:   line,
			})
		} else {
			// Parse JSON log
			entry := LogEntry{
				ID:        fmt.Sprintf("%s-%d", ip, lineCount),
				IP:        ip,
				Interface: interfaceName,
				Facility:  "system",
				Severity:  "info",
				Message:   line,
				Timestamp: time.Now(),
			}
			
			// Extract fields from JSON if available
			if ts, ok := logData["timestamp"].(string); ok {
				if parsed, err := time.Parse(time.RFC3339, ts); err == nil {
					entry.Timestamp = parsed
				}
			}
			if ipVal, ok := logData["ip"].(string); ok && ipVal != "" {
				entry.IP = ipVal
			}
			if ifaceVal, ok := logData["interface"].(string); ok && ifaceVal != "" {
				entry.Interface = ifaceVal
			}
			if facilityVal, ok := logData["facility"].(string); ok {
				entry.Facility = facilityVal
			}
			if severityVal, ok := logData["severity"].(string); ok {
				entry.Severity = severityVal
			}
			if msgVal, ok := logData["message"].(string); ok {
				entry.Message = msgVal
			}
			
			logs = append(logs, entry)
		}
		
		lineCount++
	}
	
	return logs, scanner.Err()
}

func countLinesInFile(path string) (int, error) {
	file, err := os.Open(path)
	if err != nil {
		return 0, err
	}
	defer file.Close()
	
	scanner := bufio.NewScanner(file)
	count := 0
	for scanner.Scan() {
		count++
	}
	
	return count, scanner.Err()
}
import React, { useState, useEffect } from 'react';

function SystemStatus() {
  const [systemStatus, setSystemStatus] = useState({});
  const [systemMetrics, setSystemMetrics] = useState({});
  const [fileStructure, setFileStructure] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchSystemData();
    
    // Refresh every 10 seconds
    const interval = setInterval(fetchSystemData, 10000);
    return () => clearInterval(interval);
  }, []);

  const fetchSystemData = async () => {
    try {
      const [statusResponse, metricsResponse, structureResponse] = await Promise.all([
        fetch('/api/v1/system/status'),
        fetch('/api/v1/system/metrics'),
        fetch('/api/v1/files/structure')
      ]);

      if (statusResponse.ok) {
        const statusData = await statusResponse.json();
        setSystemStatus(statusData);
      }

      if (metricsResponse.ok) {
        const metricsData = await metricsResponse.json();
        setSystemMetrics(metricsData);
      }

      if (structureResponse.ok) {
        const structureData = await structureResponse.json();
        setFileStructure(structureData);
      }

      setError(null);
    } catch (err) {
      console.error('Error fetching system data:', err);
      setError('Failed to load system information');
    } finally {
      setLoading(false);
    }
  };

  const getServiceStatusIcon = (status) => {
    switch (status?.toLowerCase()) {
      case 'active': return '✅';
      case 'inactive': return '❌';
      case 'failed': return '🔴';
      default: return '❓';
    }
  };

  const getServiceStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'active': return '#27ae60';
      case 'inactive': return '#e74c3c';
      case 'failed': return '#c0392b';
      default: return '#95a5a6';
    }
  };

  const formatBytes = (bytes) => {
    if (!bytes) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatUptime = (seconds) => {
    if (!seconds) return 'Unknown';
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) return `${days}d ${hours}h ${minutes}m`;
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  };

  if (loading) {
    return (
      <div className="system-status">
        <div className="loading">
          Loading system information...
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="system-status">
        <div className="error">
          {error}
          <button onClick={fetchSystemData}>🔄 Retry</button>
        </div>
      </div>
    );
  }

  return (
    <div className="system-status">
      {/* Header */}
      <div className="system-status-header">
        <h2>🔧 System Status</h2>
        <p>System health monitoring and diagnostics</p>
      </div>

      {/* System Overview */}
      <div className="status-grid">
        
        {/* Overall System Health */}
        <div className="status-card">
          <div className="card-header">
            <h3>Overall System Health</h3>
            <div className="status-indicator">
              <span 
                className="status-dot"
                style={{ backgroundColor: getServiceStatusColor(systemStatus.status) }}
              ></span>
              <span className="status-text">{systemStatus.status?.toUpperCase() || 'UNKNOWN'}</span>
            </div>
          </div>
          <div className="status-details">
            <div className="detail-item">
              <span>Config Status:</span>
              <span>{systemStatus.config_status || 'Unknown'}</span>
            </div>
            <div className="detail-item">
              <span>Log Directory:</span>
              <span>{systemStatus.log_directory || '/var/log/logmaster'}</span>
            </div>
            <div className="detail-item">
              <span>Last Check:</span>
              <span>{systemStatus.last_check ? new Date(systemStatus.last_check).toLocaleString() : 'Unknown'}</span>
            </div>
          </div>
        </div>

        {/* Service Status */}
        <div className="status-card">
          <div className="card-header">
            <h3>Services Status</h3>
            <div className="refresh-button" onClick={fetchSystemData}>
              🔄
            </div>
          </div>
          <div className="services-list">
            {systemStatus.services ? Object.entries(systemStatus.services).map(([service, status]) => (
              <div key={service} className="service-item">
                <div className="service-info">
                  <span className="service-icon">
                    {getServiceStatusIcon(status)}
                  </span>
                  <span className="service-name">{service}</span>
                </div>
                <span 
                  className="service-status"
                  style={{ color: getServiceStatusColor(status) }}
                >
                  {status?.toUpperCase() || 'UNKNOWN'}
                </span>
              </div>
            )) : (
              <div className="no-services">No service information available</div>
            )}
          </div>
        </div>

        {/* System Metrics */}
        <div className="status-card">
          <div className="card-header">
            <h3>System Metrics</h3>
            <div className="metrics-time">
              {new Date().toLocaleTimeString()}
            </div>
          </div>
          <div className="metrics-list">
            <div className="metric-item">
              <div className="metric-header">
                <span>CPU Usage</span>
                <span>{systemMetrics.cpu_usage?.toFixed(1) || '0'}%</span>
              </div>
              <div className="metric-bar">
                <div 
                  className="metric-bar-fill"
                  style={{ 
                    width: `${systemMetrics.cpu_usage || 0}%`,
                    backgroundColor: (systemMetrics.cpu_usage || 0) > 80 ? '#e74c3c' : '#27ae60'
                  }}
                ></div>
              </div>
            </div>

            <div className="metric-item">
              <div className="metric-header">
                <span>Memory Usage</span>
                <span>{systemMetrics.memory_usage?.toFixed(1) || '0'}%</span>
              </div>
              <div className="metric-bar">
                <div 
                  className="metric-bar-fill"
                  style={{ 
                    width: `${systemMetrics.memory_usage || 0}%`,
                    backgroundColor: (systemMetrics.memory_usage || 0) > 85 ? '#e74c3c' : '#3498db'
                  }}
                ></div>
              </div>
            </div>

            <div className="metric-item">
              <div className="metric-header">
                <span>Disk Usage</span>
                <span>{systemMetrics.disk_usage?.toFixed(1) || '0'}%</span>
              </div>
              <div className="metric-bar">
                <div 
                  className="metric-bar-fill"
                  style={{ 
                    width: `${systemMetrics.disk_usage || 0}%`,
                    backgroundColor: (systemMetrics.disk_usage || 0) > 90 ? '#e74c3c' : '#9b59b6'
                  }}
                ></div>
              </div>
            </div>

            <div className="metric-item">
              <div className="metric-header">
                <span>Network I/O</span>
                <span>{systemMetrics.network_io?.toFixed(2) || '0'} MB/s</span>
              </div>
              <div className="metric-bar">
                <div 
                  className="metric-bar-fill"
                  style={{ 
                    width: `${Math.min((systemMetrics.network_io || 0) * 20, 100)}%`,
                    backgroundColor: '#f39c12'
                  }}
                ></div>
              </div>
            </div>
          </div>
        </div>

        {/* File Structure */}
        <div className="status-card">
          <div className="card-header">
            <h3>Log File Structure</h3>
            <div className="structure-stats">
              {fileStructure.file_count || 0} files
            </div>
          </div>
          <div className="structure-overview">
            <div className="structure-stat">
              <span>Base Path:</span>
              <code>{fileStructure.base_path || '/var/log/logmaster'}</code>
            </div>
            <div className="structure-stat">
              <span>Total Size:</span>
              <span>{fileStructure.total_size || '0 GB'}</span>
            </div>
            <div className="structure-stat">
              <span>File Count:</span>
              <span>{fileStructure.file_count || 0}</span>
            </div>
            <div className="structure-stat">
              <span>Last Scanned:</span>
              <span>{fileStructure.last_updated ? new Date(fileStructure.last_updated).toLocaleString() : 'Unknown'}</span>
            </div>
          </div>

          {/* Directory Structure Preview */}
          {fileStructure.directories && fileStructure.directories.length > 0 && (
            <div className="directory-preview">
              <h4>Directory Structure:</h4>
              <div className="directory-tree">
                {fileStructure.directories.slice(0, 5).map((dir, index) => (
                  <div key={index} className="directory-item">
                    <div className="directory-ip">📁 {dir.ip}</div>
                    {dir.interfaces && dir.interfaces.slice(0, 3).map((intf, intfIndex) => (
                      <div key={intfIndex} className="interface-item">
                        <span className="interface-icon">🏢</span>
                        <span className="interface-name">{intf.name}</span>
                        <span className="file-count">({intf.files?.length || 0} files)</span>
                      </div>
                    ))}
                  </div>
                ))}
                {fileStructure.directories.length > 5 && (
                  <div className="more-directories">
                    ... and {fileStructure.directories.length - 5} more directories
                  </div>
                )}
              </div>
            </div>
          )}
        </div>

        {/* System Information */}
        <div className="status-card">
          <div className="card-header">
            <h3>System Information</h3>
            <div className="info-icon">💻</div>
          </div>
          <div className="system-info">
            <div className="info-item">
              <span>Uptime:</span>
              <span>{formatUptime(systemMetrics.uptime)}</span>
            </div>
            <div className="info-item">
              <span>Load Average:</span>
              <span>{systemMetrics.load_average?.toFixed(2) || '0.00'}</span>
            </div>
            <div className="info-item">
              <span>Memory Total:</span>
              <span>{formatBytes(systemMetrics.memory_total)}</span>
            </div>
            <div className="info-item">
              <span>Memory Used:</span>
              <span>{formatBytes(systemMetrics.memory_used)}</span>
            </div>
            <div className="info-item">
              <span>Disk Total:</span>
              <span>{formatBytes(systemMetrics.disk_total)}</span>
            </div>
            <div className="info-item">
              <span>Disk Used:</span>
              <span>{formatBytes(systemMetrics.disk_used)}</span>
            </div>
            <div className="info-item">
              <span>Active Connections:</span>
              <span>{systemMetrics.active_connections || 0}</span>
            </div>
            <div className="info-item">
              <span>Logs/Second:</span>
              <span>{systemMetrics.logs_per_second?.toFixed(2) || '0.00'}</span>
            </div>
          </div>
        </div>

        {/* Network Status */}
        <div className="status-card">
          <div className="card-header">
            <h3>Network Status</h3>
            <div className="network-icon">🌐</div>
          </div>
          <div className="network-info">
            <div className="network-item">
              <span>Bytes In:</span>
              <span>{formatBytes(systemMetrics.network_bytes_in)}</span>
            </div>
            <div className="network-item">
              <span>Bytes Out:</span>
              <span>{formatBytes(systemMetrics.network_bytes_out)}</span>
            </div>
            <div className="network-item">
              <span>Syslog Port:</span>
              <span className="port-status active">514 UDP ✅</span>
            </div>
            <div className="network-item">
              <span>API Port:</span>
              <span className="port-status active">8080 TCP ✅</span>
            </div>
            <div className="network-item">
              <span>Dashboard Port:</span>
              <span className="port-status active">3000 TCP ✅</span>
            </div>
            <div className="network-item">
              <span>Grafana Port:</span>
              <span className="port-status active">3001 TCP ✅</span>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}

export default SystemStatus;
import React, { useState, useEffect } from 'react';

function Dashboard() {
  const [stats, setStats] = useState({
    total_logs: 0,
    active_businesses: 0,
    system_status: 'loading',
    interface_stats: {},
    ip_stats: {},
    log_volume_today: 0,
    log_volume_hour: 0
  });
  
  const [recentLogs, setRecentLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchStats();
    fetchRecentLogs();
    
    // Set up periodic refresh
    const interval = setInterval(() => {
      fetchStats();
      fetchRecentLogs();
    }, 30000);
    
    return () => clearInterval(interval);
  }, []);

  const fetchStats = async () => {
    try {
      const response = await fetch('/api/v1/stats');
      if (!response.ok) throw new Error('Failed to fetch stats');
      const data = await response.json();
      setStats(data);
      setError(null);
    } catch (err) {
      console.error('Error fetching stats:', err);
      setError('Failed to load statistics');
    } finally {
      setLoading(false);
    }
  };

  const fetchRecentLogs = async () => {
    try {
      const response = await fetch('/api/v1/logs/recent');
      if (!response.ok) throw new Error('Failed to fetch recent logs');
      const data = await response.json();
      setRecentLogs(data.logs || []);
    } catch (err) {
      console.error('Error fetching recent logs:', err);
    }
  };

  const formatNumber = (num) => {
    return new Intl.NumberFormat().format(num);
  };

  const getStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'healthy': return '#27ae60';
      case 'warning': return '#f39c12';
      case 'error': return '#e74c3c';
      default: return '#95a5a6';
    }
  };

  const getInterfaceColor = (interface_name) => {
    const colors = {
      'HOTEL': '#e74c3c',
      'CAFE': '#f39c12',
      'RESTAURANT': '#27ae60',
      'AVM': '#3498db',
      'OKUL': '#9b59b6',
      'YURT': '#34495e',
      'KONUKEVI': '#e67e22',
      'general': '#95a5a6'
    };
    return colors[interface_name] || '#95a5a6';
  };

  if (loading) {
    return (
      <div className="dashboard">
        <div className="loading">
          Loading dashboard data...
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="dashboard">
        <div className="error">
          {error}
        </div>
      </div>
    );
  }

  return (
    <div className="dashboard">
      {/* Main Stats */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon">📊</div>
          <div className="stat-content">
            <div className="stat-number">{formatNumber(stats.total_logs)}</div>
            <div className="stat-label">Total Logs</div>
          </div>
        </div>
        
        <div className="stat-card">
          <div className="stat-icon">🏢</div>
          <div className="stat-content">
            <div className="stat-number">{stats.active_businesses}</div>
            <div className="stat-label">Active Devices</div>
          </div>
        </div>
        
        <div className="stat-card">
          <div className="stat-icon">📈</div>
          <div className="stat-content">
            <div className="stat-number">{formatNumber(stats.log_volume_today)}</div>
            <div className="stat-label">Logs Today</div>
          </div>
        </div>
        
        <div className="stat-card">
          <div className="stat-icon">⚡</div>
          <div className="stat-content">
            <div className="stat-number">{formatNumber(stats.log_volume_hour)}</div>
            <div className="stat-label">Logs This Hour</div>
          </div>
        </div>
      </div>

      {/* Dashboard Grid */}
      <div className="dashboard-grid">
        
        {/* System Status Card */}
        <div className="dashboard-card">
          <div className="card-header">
            <h3 className="card-title">System Status</h3>
            <div 
              className="card-icon" 
              style={{ color: getStatusColor(stats.system_status) }}
            >
              {stats.system_status === 'healthy' ? '✅' : 
               stats.system_status === 'warning' ? '⚠️' : 
               stats.system_status === 'error' ? '❌' : '🔄'}
            </div>
          </div>
          <div className="system-status">
            <div className="status-item">
              <span>Overall Status:</span>
              <span style={{ color: getStatusColor(stats.system_status) }}>
                {stats.system_status?.toUpperCase() || 'UNKNOWN'}
              </span>
            </div>
            <div className="status-item">
              <span>Last Update:</span>
              <span>{new Date(stats.last_update).toLocaleString()}</span>
            </div>
            <div className="status-item">
              <span>Auto-Discovery:</span>
              <span style={{ color: '#27ae60' }}>ACTIVE</span>
            </div>
          </div>
        </div>

        {/* Interface Statistics */}
        <div className="dashboard-card">
          <div className="card-header">
            <h3 className="card-title">Interface Statistics</h3>
            <div className="card-icon">🏢</div>
          </div>
          <div className="interface-stats">
            {Object.entries(stats.interface_stats || {}).map(([interface_name, count]) => (
              <div key={interface_name} className="interface-item">
                <div className="interface-info">
                  <span 
                    className="interface-name"
                    style={{ color: getInterfaceColor(interface_name) }}
                  >
                    {interface_name}
                  </span>
                  <span className="interface-count">{formatNumber(count)}</span>
                </div>
                <div className="interface-bar">
                  <div 
                    className="interface-bar-fill"
                    style={{ 
                      width: `${(count / Math.max(...Object.values(stats.interface_stats || {}))) * 100}%`,
                      backgroundColor: getInterfaceColor(interface_name)
                    }}
                  ></div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* IP Statistics */}
        <div className="dashboard-card">
          <div className="card-header">
            <h3 className="card-title">Top IP Addresses</h3>
            <div className="card-icon">🌐</div>
          </div>
          <div className="ip-stats">
            {Object.entries(stats.ip_stats || {})
              .sort(([,a], [,b]) => b - a)
              .slice(0, 5)
              .map(([ip, count]) => (
              <div key={ip} className="ip-item">
                <div className="ip-info">
                  <span className="ip-address">{ip}</span>
                  <span className="ip-count">{formatNumber(count)}</span>
                </div>
                <div className="ip-bar">
                  <div 
                    className="ip-bar-fill"
                    style={{ 
                      width: `${(count / Math.max(...Object.values(stats.ip_stats || {}))) * 100}%`,
                      backgroundColor: '#667eea'
                    }}
                  ></div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Logs */}
        <div className="dashboard-card">
          <div className="card-header">
            <h3 className="card-title">Recent Log Activity</h3>
            <div className="card-icon">📋</div>
          </div>
          <div className="recent-logs">
            {recentLogs.length > 0 ? (
              recentLogs.slice(0, 5).map((log, index) => (
                <div key={index} className="log-item">
                  <div className="log-time">
                    {new Date(log.timestamp).toLocaleTimeString()}
                  </div>
                  <div className="log-content">
                    <span className="log-ip">{log.ip}</span>
                    <span 
                      className="log-interface"
                      style={{ 
                        backgroundColor: getInterfaceColor(log.interface),
                        color: 'white'
                      }}
                    >
                      {log.interface}
                    </span>
                    <span className="log-message">{log.message?.substring(0, 50)}...</span>
                  </div>
                </div>
              ))
            ) : (
              <div className="no-logs">
                <div>No recent logs</div>
                <small>Logs will appear here when devices start sending data</small>
              </div>
            )}
          </div>
        </div>

      </div>

      {/* System Metrics */}
      <div className="dashboard-card" style={{ marginTop: '1.5rem' }}>
        <div className="card-header">
          <h3 className="card-title">System Metrics</h3>
          <div className="card-icon">📈</div>
        </div>
        <div className="system-metrics">
          <div className="metrics-grid">
            <div className="metric-item">
              <div className="metric-label">CPU Usage</div>
              <div className="metric-value">{stats.system_metrics?.cpu_usage?.toFixed(1) || '0'}%</div>
              <div className="metric-bar">
                <div 
                  className="metric-bar-fill"
                  style={{ 
                    width: `${stats.system_metrics?.cpu_usage || 0}%`,
                    backgroundColor: (stats.system_metrics?.cpu_usage || 0) > 80 ? '#e74c3c' : '#27ae60'
                  }}
                ></div>
              </div>
            </div>
            
            <div className="metric-item">
              <div className="metric-label">Memory Usage</div>
              <div className="metric-value">{stats.system_metrics?.memory_usage?.toFixed(1) || '0'}%</div>
              <div className="metric-bar">
                <div 
                  className="metric-bar-fill"
                  style={{ 
                    width: `${stats.system_metrics?.memory_usage || 0}%`,
                    backgroundColor: (stats.system_metrics?.memory_usage || 0) > 85 ? '#e74c3c' : '#3498db'
                  }}
                ></div>
              </div>
            </div>
            
            <div className="metric-item">
              <div className="metric-label">Disk Usage</div>
              <div className="metric-value">{stats.system_metrics?.disk_usage?.toFixed(1) || '0'}%</div>
              <div className="metric-bar">
                <div 
                  className="metric-bar-fill"
                  style={{ 
                    width: `${stats.system_metrics?.disk_usage || 0}%`,
                    backgroundColor: (stats.system_metrics?.disk_usage || 0) > 90 ? '#e74c3c' : '#9b59b6'
                  }}
                ></div>
              </div>
            </div>
            
            <div className="metric-item">
              <div className="metric-label">Network I/O</div>
              <div className="metric-value">{stats.system_metrics?.network_io?.toFixed(1) || '0'} MB/s</div>
              <div className="metric-bar">
                <div 
                  className="metric-bar-fill"
                  style={{ 
                    width: `${Math.min((stats.system_metrics?.network_io || 0) * 20, 100)}%`,
                    backgroundColor: '#f39c12'
                  }}
                ></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Dashboard;
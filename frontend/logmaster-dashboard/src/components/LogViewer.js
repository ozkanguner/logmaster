import React, { useState, useEffect } from 'react';

function LogViewer() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({
    ip: '',
    interface: '',
    severity: '',
    search: '',
    limit: 100
  });
  const [autoRefresh, setAutoRefresh] = useState(true);

  useEffect(() => {
    fetchLogs();
    
    if (autoRefresh) {
      const interval = setInterval(fetchLogs, 5000);
      return () => clearInterval(interval);
    }
  }, [filters, autoRefresh]);

  const fetchLogs = async () => {
    try {
      const queryParams = new URLSearchParams();
      Object.entries(filters).forEach(([key, value]) => {
        if (value) queryParams.append(key, value);
      });

      const response = await fetch(`/api/v1/logs?${queryParams}`);
      if (!response.ok) throw new Error('Failed to fetch logs');
      
      const data = await response.json();
      setLogs(data.logs || []);
      setError(null);
    } catch (err) {
      console.error('Error fetching logs:', err);
      setError('Failed to load logs');
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (key, value) => {
    setFilters(prev => ({
      ...prev,
      [key]: value
    }));
  };

  const clearFilters = () => {
    setFilters({
      ip: '',
      interface: '',
      severity: '',
      search: '',
      limit: 100
    });
  };

  const exportLogs = () => {
    const csvContent = [
      ['Timestamp', 'IP', 'Interface', 'Facility', 'Severity', 'Message'].join(','),
      ...logs.map(log => [
        log.timestamp,
        log.ip,
        log.interface,
        log.facility,
        log.severity,
        `"${log.message?.replace(/"/g, '""') || ''}"`
      ].join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `logmaster-logs-${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const getSeverityClass = (severity) => {
    const severityMap = {
      'error': 'severity-error',
      'warning': 'severity-warning',
      'info': 'severity-info',
      'notice': 'severity-notice',
      'debug': 'severity-debug'
    };
    return severityMap[severity?.toLowerCase()] || 'severity-info';
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

  return (
    <div className="log-viewer">
      {/* Header */}
      <div className="log-viewer-header">
        <div className="header-left">
          <h2>📋 Live Log Viewer</h2>
          <p>Real-time log monitoring and filtering</p>
        </div>
        <div className="header-right">
          <button 
            className={`refresh-toggle ${autoRefresh ? 'active' : ''}`}
            onClick={() => setAutoRefresh(!autoRefresh)}
          >
            {autoRefresh ? '🟢 Auto' : '⏸️ Manual'}
          </button>
          <button className="export-button" onClick={exportLogs}>
            📥 Export CSV
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="log-filters">
        <div className="filter-row">
          <div className="filter-group">
            <label>IP Address:</label>
            <input
              type="text"
              placeholder="192.168.1.100"
              value={filters.ip}
              onChange={(e) => handleFilterChange('ip', e.target.value)}
            />
          </div>
          
          <div className="filter-group">
            <label>Interface:</label>
            <select
              value={filters.interface}
              onChange={(e) => handleFilterChange('interface', e.target.value)}
            >
              <option value="">All Interfaces</option>
              <option value="HOTEL">HOTEL</option>
              <option value="CAFE">CAFE</option>
              <option value="RESTAURANT">RESTAURANT</option>
              <option value="AVM">AVM</option>
              <option value="OKUL">OKUL</option>
              <option value="YURT">YURT</option>
              <option value="KONUKEVI">KONUKEVI</option>
              <option value="general">General</option>
            </select>
          </div>
          
          <div className="filter-group">
            <label>Severity:</label>
            <select
              value={filters.severity}
              onChange={(e) => handleFilterChange('severity', e.target.value)}
            >
              <option value="">All Severities</option>
              <option value="error">Error</option>
              <option value="warning">Warning</option>
              <option value="info">Info</option>
              <option value="notice">Notice</option>
              <option value="debug">Debug</option>
            </select>
          </div>
          
          <div className="filter-group">
            <label>Search:</label>
            <input
              type="text"
              placeholder="Search in messages..."
              value={filters.search}
              onChange={(e) => handleFilterChange('search', e.target.value)}
            />
          </div>
          
          <div className="filter-group">
            <label>Limit:</label>
            <select
              value={filters.limit}
              onChange={(e) => handleFilterChange('limit', parseInt(e.target.value))}
            >
              <option value={50}>50</option>
              <option value={100}>100</option>
              <option value={500}>500</option>
              <option value={1000}>1000</option>
            </select>
          </div>
          
          <button className="clear-filters" onClick={clearFilters}>
            🗑️ Clear
          </button>
        </div>
      </div>

      {/* Status Bar */}
      <div className="log-status">
        <div className="status-left">
          <span className="log-count">
            Showing {logs.length} logs
            {autoRefresh && <span className="auto-refresh-indicator">🔄 Auto-refresh: 5s</span>}
          </span>
        </div>
        <div className="status-right">
          <span className="last-update">
            Last update: {new Date().toLocaleTimeString()}
          </span>
        </div>
      </div>

      {/* Error State */}
      {error && (
        <div className="error">
          {error}
          <button onClick={fetchLogs}>🔄 Retry</button>
        </div>
      )}

      {/* Loading State */}
      {loading && (
        <div className="loading">
          Loading logs...
        </div>
      )}

      {/* Logs Table */}
      {!loading && !error && (
        <div className="logs-container">
          {logs.length > 0 ? (
            <table className="log-table">
              <thead>
                <tr>
                  <th>Time</th>
                  <th>IP Address</th>
                  <th>Interface</th>
                  <th>Facility</th>
                  <th>Severity</th>
                  <th>Message</th>
                </tr>
              </thead>
              <tbody>
                {logs.map((log, index) => (
                  <tr key={log.id || index} className="log-row">
                    <td className="log-time">
                      {new Date(log.timestamp).toLocaleString()}
                    </td>
                    <td className="log-ip">
                      <code>{log.ip}</code>
                    </td>
                    <td className="log-interface">
                      <span 
                        className="interface-tag"
                        style={{ backgroundColor: getInterfaceColor(log.interface) }}
                      >
                        {log.interface}
                      </span>
                    </td>
                    <td className="log-facility">
                      {log.facility}
                    </td>
                    <td className="log-severity">
                      <span className={`severity-tag ${getSeverityClass(log.severity)}`}>
                        {log.severity}
                      </span>
                    </td>
                    <td className="log-message">
                      <div className="message-content">
                        {log.message}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="no-logs">
              <div className="no-logs-icon">📋</div>
              <div className="no-logs-text">
                <h3>No logs found</h3>
                <p>
                  {Object.values(filters).some(v => v) ? 
                    'Try adjusting your filters to see more results.' :
                    'Logs will appear here when devices start sending data.'
                  }
                </p>
                {Object.values(filters).some(v => v) && (
                  <button onClick={clearFilters}>Clear all filters</button>
                )}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default LogViewer;
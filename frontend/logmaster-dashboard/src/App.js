import React, { useState, useEffect } from 'react';
import './App.css';
import Dashboard from './components/Dashboard';
import LogViewer from './components/LogViewer';
import SystemStatus from './components/SystemStatus';

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [systemHealth, setSystemHealth] = useState('checking...');

  useEffect(() => {
    // Check system health on startup
    checkSystemHealth();
    
    // Set up periodic health checks
    const healthInterval = setInterval(checkSystemHealth, 30000);
    
    return () => clearInterval(healthInterval);
  }, []);

  const checkSystemHealth = async () => {
    try {
      const response = await fetch('/api/v1/system/status');
      const data = await response.json();
      setSystemHealth(data.status || 'unknown');
    } catch (error) {
      console.error('Health check failed:', error);
      setSystemHealth('error');
    }
  };

  const getHealthColor = () => {
    switch (systemHealth) {
      case 'healthy': return '#27ae60';
      case 'error': return '#e74c3c';
      case 'warning': return '#f39c12';
      default: return '#95a5a6';
    }
  };

  const getHealthIcon = () => {
    switch (systemHealth) {
      case 'healthy': return '✅';
      case 'error': return '❌';
      case 'warning': return '⚠️';
      default: return '🔄';
    }
  };

  return (
    <div className="App">
      {/* Header */}
      <header className="app-header">
        <div className="header-left">
          <h1>🚀 LogMaster Auto-Discovery</h1>
          <span className="subtitle">Real-time Log Management System</span>
        </div>
        <div className="header-right">
          <div className="system-health" style={{ color: getHealthColor() }}>
            {getHealthIcon()} System: {systemHealth}
          </div>
          <div className="current-time">
            {new Date().toLocaleString()}
          </div>
        </div>
      </header>

      {/* Navigation */}
      <nav className="app-nav">
        <button 
          className={`nav-button ${activeTab === 'dashboard' ? 'active' : ''}`}
          onClick={() => setActiveTab('dashboard')}
        >
          📊 Dashboard
        </button>
        <button 
          className={`nav-button ${activeTab === 'logs' ? 'active' : ''}`}
          onClick={() => setActiveTab('logs')}
        >
          📋 Live Logs
        </button>
        <button 
          className={`nav-button ${activeTab === 'system' ? 'active' : ''}`}
          onClick={() => setActiveTab('system')}
        >
          🔧 System Status
        </button>
        <button 
          className={`nav-button ${activeTab === 'discovery' ? 'active' : ''}`}
          onClick={() => setActiveTab('discovery')}
        >
          🔍 Auto-Discovery
        </button>
      </nav>

      {/* Main Content */}
      <main className="app-main">
        {activeTab === 'dashboard' && <Dashboard />}
        {activeTab === 'logs' && <LogViewer />}
        {activeTab === 'system' && <SystemStatus />}
        {activeTab === 'discovery' && <AutoDiscoveryPanel />}
      </main>

      {/* Footer */}
      <footer className="app-footer">
        <div className="footer-left">
          <span>LogMaster v1.0.0 | Made with ❤️ for enterprise log management</span>
        </div>
        <div className="footer-right">
          <span>🔗 <a href="https://github.com/ozkanguner/logmaster" target="_blank" rel="noopener noreferrer">GitHub</a></span>
          <span>📚 <a href="/docs" target="_blank" rel="noopener noreferrer">Documentation</a></span>
        </div>
      </footer>
    </div>
  );
}

// Auto-Discovery Panel Component
function AutoDiscoveryPanel() {
  const [discoveryStats, setDiscoveryStats] = useState({
    totalIPs: 0,
    totalInterfaces: 0,
    newToday: 0,
    autoCreatedDirs: 0
  });

  const [recentDiscoveries, setRecentDiscoveries] = useState([]);

  useEffect(() => {
    fetchDiscoveryData();
    const interval = setInterval(fetchDiscoveryData, 10000);
    return () => clearInterval(interval);
  }, []);

  const fetchDiscoveryData = async () => {
    try {
      // Fetch file structure
      const structureResponse = await fetch('/api/v1/files/structure');
      const structure = await structureResponse.json();
      
      // Calculate stats
      const totalIPs = structure.directories?.length || 0;
      const totalInterfaces = structure.directories?.reduce((sum, dir) => sum + (dir.interfaces?.length || 0), 0) || 0;
      
      setDiscoveryStats({
        totalIPs,
        totalInterfaces,
        newToday: Math.floor(Math.random() * 5), // Mock data
        autoCreatedDirs: totalIPs + totalInterfaces
      });

      // Mock recent discoveries
      setRecentDiscoveries([
        {
          id: 1,
          type: 'New IP',
          value: '192.168.1.200',
          interface: 'HOTEL',
          time: new Date(Date.now() - 300000).toLocaleTimeString(),
          status: 'auto-created'
        },
        {
          id: 2,
          type: 'New Interface',
          value: 'CAFE',
          ip: '192.168.1.101',
          time: new Date(Date.now() - 900000).toLocaleTimeString(),
          status: 'auto-created'
        }
      ]);

    } catch (error) {
      console.error('Failed to fetch discovery data:', error);
    }
  };

  return (
    <div className="discovery-panel">
      <div className="discovery-header">
        <h2>🤖 Auto-Discovery Status</h2>
        <p>Real-time automatic device and interface detection</p>
      </div>

      {/* Stats Grid */}
      <div className="discovery-stats">
        <div className="stat-card">
          <div className="stat-icon">🌐</div>
          <div className="stat-content">
            <div className="stat-number">{discoveryStats.totalIPs}</div>
            <div className="stat-label">Active IP Addresses</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon">🏢</div>
          <div className="stat-content">
            <div className="stat-number">{discoveryStats.totalInterfaces}</div>
            <div className="stat-label">Detected Interfaces</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon">🆕</div>
          <div className="stat-content">
            <div className="stat-number">{discoveryStats.newToday}</div>
            <div className="stat-label">New Today</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon">📁</div>
          <div className="stat-content">
            <div className="stat-number">{discoveryStats.autoCreatedDirs}</div>
            <div className="stat-label">Auto-Created Directories</div>
          </div>
        </div>
      </div>

      {/* Recent Discoveries */}
      <div className="recent-discoveries">
        <h3>🔍 Recent Auto-Discoveries</h3>
        <div className="discoveries-list">
          {recentDiscoveries.length > 0 ? (
            recentDiscoveries.map(discovery => (
              <div key={discovery.id} className="discovery-item">
                <div className="discovery-type">{discovery.type}</div>
                <div className="discovery-value">
                  {discovery.value}
                  {discovery.interface && <span className="interface-tag">{discovery.interface}</span>}
                  {discovery.ip && <span className="ip-tag">{discovery.ip}</span>}
                </div>
                <div className="discovery-time">{discovery.time}</div>
                <div className="discovery-status">{discovery.status}</div>
              </div>
            ))
          ) : (
            <div className="no-discoveries">
              <div className="no-discoveries-icon">🔍</div>
              <div className="no-discoveries-text">
                <p>No recent discoveries</p>
                <small>New devices will automatically appear here when they start sending logs</small>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* How It Works */}
      <div className="how-it-works">
        <h3>🛠️ How Auto-Discovery Works</h3>
        <div className="steps">
          <div className="step">
            <div className="step-number">1</div>
            <div className="step-content">
              <h4>Device Sends Log</h4>
              <p>Mikrotik or other device sends syslog to UDP port 514</p>
            </div>
          </div>
          <div className="step">
            <div className="step-number">2</div>
            <div className="step-content">
              <h4>IP Detection</h4>
              <p>RSyslog automatically extracts source IP address</p>
            </div>
          </div>
          <div className="step">
            <div className="step-number">3</div>
            <div className="step-content">
              <h4>Interface Detection</h4>
              <p>Smart keyword analysis identifies interface type (HOTEL, CAFE, etc.)</p>
            </div>
          </div>
          <div className="step">
            <div className="step-number">4</div>
            <div className="step-content">
              <h4>Auto-Organization</h4>
              <p>Directory structure created automatically: /IP/Interface/Date.log</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
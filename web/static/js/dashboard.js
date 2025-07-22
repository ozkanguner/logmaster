// LogMaster Dashboard JavaScript

// Global variables
let currentSection = 'dashboard';
let charts = {};
let refreshInterval;

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    initializeDashboard();
    setupNavigation();
    setupEventListeners();
    
    // Start auto-refresh
    startAutoRefresh();
});

// Initialize dashboard
function initializeDashboard() {
    console.log('LogMaster Dashboard initializing...');
    
    // Load initial data
    refreshDashboard();
    loadDevices();
    loadRecentLogs();
    loadComplianceScore();
    
    // Set current date for report form
    setDefaultReportDates();
}

// Setup navigation
function setupNavigation() {
    const navLinks = document.querySelectorAll('.navbar-nav .nav-link');
    
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            if (this.getAttribute('href').startsWith('#')) {
                e.preventDefault();
                const targetSection = this.getAttribute('href').substring(1);
                showSection(targetSection);
                
                // Update active nav link
                navLinks.forEach(l => l.classList.remove('active'));
                this.classList.add('active');
            }
        });
    });
}

// Setup event listeners
function setupEventListeners() {
    // Report form submission
    const reportForm = document.getElementById('reportForm');
    if (reportForm) {
        reportForm.addEventListener('submit', function(e) {
            e.preventDefault();
            generateReport();
        });
    }
    
    // Filter buttons
    const filterButtons = document.querySelectorAll('[onclick*="load"]');
    filterButtons.forEach(button => {
        button.addEventListener('click', function() {
            const functionName = this.getAttribute('onclick');
            eval(functionName);
        });
    });
}

// Show specific section
function showSection(sectionId) {
    // Hide all sections
    const sections = document.querySelectorAll('.section');
    sections.forEach(section => {
        section.style.display = 'none';
    });
    
    // Show target section
    const targetSection = document.getElementById(sectionId);
    if (targetSection) {
        targetSection.style.display = 'block';
        currentSection = sectionId;
        
        // Load section-specific data
        loadSectionData(sectionId);
    }
}

// Load section-specific data
function loadSectionData(sectionId) {
    switch(sectionId) {
        case 'logs':
            loadRecentLogs();
            break;
        case 'devices':
            loadDevices();
            break;
        case 'signatures':
            loadSignatureStatus();
            break;
        case 'archives':
            loadArchiveInfo();
            break;
        case 'reports':
            loadComplianceScore();
            break;
        case 'compliance':
            loadSystemStatus();
            break;
    }
}

// Refresh dashboard
async function refreshDashboard() {
    console.log('Refreshing dashboard...');
    
    try {
        showLoading('dashboard');
        
        // Load overview stats
        const response = await fetch('/api/stats/overview');
        if (response.ok) {
            const stats = await response.json();
            updateOverviewStats(stats);
        }
        
        // Load system status
        loadSystemStatus();
        
        // Update charts
        updateCharts();
        
        // Update last refresh time
        document.getElementById('lastUpdate').textContent = new Date().toLocaleString('tr-TR');
        
    } catch (error) {
        console.error('Dashboard refresh error:', error);
        showAlert('Veri yüklenirken hata oluştu', 'danger');
    } finally {
        hideLoading('dashboard');
    }
}

// Update overview statistics
function updateOverviewStats(stats) {
    document.getElementById('totalLogs').textContent = formatNumber(stats.total_logs);
    document.getElementById('activeDevices').textContent = formatNumber(stats.active_devices);
    document.getElementById('signedFiles').textContent = formatNumber(stats.signed_files);
    document.getElementById('diskUsage').textContent = `${stats.disk_usage.usage_percent}%`;
}

// Load recent logs
async function loadRecentLogs() {
    try {
        const deviceFilter = document.getElementById('deviceFilter')?.value || '';
        const limit = document.getElementById('logLimit')?.value || 100;
        
        let url = `/api/logs/recent?limit=${limit}`;
        if (deviceFilter) {
            url += `&device_id=${deviceFilter}`;
        }
        
        const response = await fetch(url);
        if (response.ok) {
            const logs = await response.json();
            updateLogsTable(logs);
        }
    } catch (error) {
        console.error('Logs loading error:', error);
        showAlert('Loglar yüklenirken hata oluştu', 'danger');
    }
}

// Update logs table
function updateLogsTable(logs) {
    const tbody = document.getElementById('logsTableBody');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    logs.forEach(log => {
        const row = tbody.insertRow();
        row.innerHTML = `
            <td>${formatDateTime(log.timestamp)}</td>
            <td>
                <span class="badge bg-secondary">${log.device_id}</span>
                ${log.device_name ? `<br><small>${log.device_name}</small>` : ''}
            </td>
            <td>${log.source_ip}</td>
            <td>
                <code style="font-size: 0.875rem;">${escapeHtml(log.message_preview)}</code>
            </td>
        `;
    });
}

// Load devices
async function loadDevices() {
    try {
        const response = await fetch('/api/devices');
        if (response.ok) {
            const devices = await response.json();
            updateDevicesTable(devices);
            updateDeviceFilter(devices);
        }
    } catch (error) {
        console.error('Devices loading error:', error);
    }
}

// Update devices table
function updateDevicesTable(devices) {
    const tbody = document.getElementById('devicesTableBody');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    devices.forEach(device => {
        const row = tbody.insertRow();
        const statusClass = getStatusClass(device.status);
        
        row.innerHTML = `
            <td><span class="badge bg-secondary">${device.device_id}</span></td>
            <td>${device.name || '-'}</td>
            <td>${device.ip_address || '-'}</td>
            <td>${device.location || '-'}</td>
            <td><span class="badge ${statusClass}">${device.status}</span></td>
            <td>${formatNumber(device.log_count)}</td>
            <td>${device.last_log ? formatDateTime(device.last_log) : '-'}</td>
        `;
    });
}

// Update device filter dropdown
function updateDeviceFilter(devices) {
    const select = document.getElementById('deviceFilter');
    if (!select) return;
    
    // Clear existing options except first
    while (select.children.length > 1) {
        select.removeChild(select.lastChild);
    }
    
    devices.forEach(device => {
        const option = document.createElement('option');
        option.value = device.device_id;
        option.textContent = `${device.device_id} - ${device.name || device.ip_address}`;
        select.appendChild(option);
    });
}

// Load signature status
async function loadSignatureStatus() {
    try {
        const response = await fetch('/api/signatures/status');
        if (response.ok) {
            const data = await response.json();
            updateSignatureChart(data);
        }
    } catch (error) {
        console.error('Signature status loading error:', error);
    }
}

// Load archive information
async function loadArchiveInfo() {
    try {
        const response = await fetch('/api/archives');
        if (response.ok) {
            const data = await response.json();
            updateArchiveInfo(data);
        }
    } catch (error) {
        console.error('Archive info loading error:', error);
    }
}

// Load compliance score
async function loadComplianceScore() {
    try {
        const response = await fetch('/api/compliance/score');
        if (response.ok) {
            const data = await response.json();
            document.getElementById('complianceScore').textContent = 
                data.compliance_score.toFixed(1);
        }
    } catch (error) {
        console.error('Compliance score loading error:', error);
    }
}

// Load system status
async function loadSystemStatus() {
    try {
        const response = await fetch('/api/system/status');
        if (response.ok) {
            const status = await response.json();
            updateSystemStatus(status);
        }
    } catch (error) {
        console.error('System status loading error:', error);
    }
}

// Update system status
function updateSystemStatus(status) {
    const container = document.getElementById('systemStatus');
    if (!container) return;
    
    container.innerHTML = '';
    
    Object.entries(status).forEach(([key, value]) => {
        const col = document.createElement('div');
        col.className = 'col-md-4 mb-3';
        
        const statusClass = getStatusClass(value);
        const statusIcon = getStatusIcon(value);
        
        col.innerHTML = `
            <div class="d-flex align-items-center">
                <i class="bi ${statusIcon} me-2"></i>
                <div>
                    <strong>${formatStatusKey(key)}</strong><br>
                    <span class="badge ${statusClass}">${value}</span>
                </div>
            </div>
        `;
        
        container.appendChild(col);
    });
}

// Generate report
async function generateReport() {
    try {
        const formData = new FormData(document.getElementById('reportForm'));
        
        showLoading('reports');
        
        const response = await fetch('/api/reports/generate', {
            method: 'POST',
            body: formData
        });
        
        if (response.ok) {
            const result = await response.json();
            showAlert(`Rapor başarıyla oluşturuldu. Uyumluluk skoru: ${result.compliance_score.toFixed(2)}`, 'success');
            loadComplianceScore();
        } else {
            throw new Error('Rapor oluşturulamadı');
        }
        
    } catch (error) {
        console.error('Report generation error:', error);
        showAlert('Rapor oluşturulurken hata oluştu', 'danger');
    } finally {
        hideLoading('reports');
    }
}

// Update charts
function updateCharts() {
    updateLogFlowChart();
    updateSignatureChart();
}

// Update log flow chart
function updateLogFlowChart() {
    const ctx = document.getElementById('logFlowChart');
    if (!ctx) return;
    
    // Destroy existing chart
    if (charts.logFlow) {
        charts.logFlow.destroy();
    }
    
    // Sample data - replace with real API call
    const data = {
        labels: ['6 gün önce', '5 gün önce', '4 gün önce', '3 gün önce', '2 gün önce', 'Dün', 'Bugün'],
        datasets: [{
            label: 'Log Sayısı',
            data: [1200, 1900, 3000, 5000, 2000, 3000, 4500],
            borderColor: '#0d6efd',
            backgroundColor: 'rgba(13, 110, 253, 0.1)',
            fill: true,
            tension: 0.4
        }]
    };
    
    charts.logFlow = new Chart(ctx, {
        type: 'line',
        data: data,
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });
}

// Update signature chart
function updateSignatureChart(data = null) {
    const ctx = document.getElementById('signatureStatusChart');
    if (!ctx) return;
    
    // Destroy existing chart
    if (charts.signature) {
        charts.signature.destroy();
    }
    
    // Sample data if not provided
    const chartData = data ? {
        labels: data.status_breakdown.map(item => item.verification_status),
        datasets: [{
            data: data.status_breakdown.map(item => item.count),
            backgroundColor: ['#198754', '#ffc107', '#dc3545'],
            borderWidth: 0
        }]
    } : {
        labels: ['Geçerli', 'Beklemede', 'Hatalı'],
        datasets: [{
            data: [85, 10, 5],
            backgroundColor: ['#198754', '#ffc107', '#dc3545'],
            borderWidth: 0
        }]
    };
    
    charts.signature = new Chart(ctx, {
        type: 'doughnut',
        data: chartData,
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom'
                }
            }
        }
    });
}

// Utility functions
function formatNumber(num) {
    if (num >= 1000000) {
        return (num / 1000000).toFixed(1) + 'M';
    } else if (num >= 1000) {
        return (num / 1000).toFixed(1) + 'K';
    }
    return num.toString();
}

function formatDateTime(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString('tr-TR');
}

function formatStatusKey(key) {
    return key.replace(/_/g, ' ')
             .replace(/\b\w/g, l => l.toUpperCase())
             .replace('Service ', '');
}

function getStatusClass(status) {
    switch(status?.toLowerCase()) {
        case 'active':
        case 'healthy':
        case 'valid':
        case 'online':
            return 'bg-success';
        case 'warning':
        case 'pending':
            return 'bg-warning';
        case 'error':
        case 'invalid':
        case 'offline':
        case 'failed':
            return 'bg-danger';
        default:
            return 'bg-secondary';
    }
}

function getStatusIcon(status) {
    switch(status?.toLowerCase()) {
        case 'active':
        case 'healthy':
        case 'valid':
            return 'bi-check-circle-fill text-success';
        case 'warning':
        case 'pending':
            return 'bi-exclamation-triangle-fill text-warning';
        case 'error':
        case 'invalid':
        case 'failed':
            return 'bi-x-circle-fill text-danger';
        default:
            return 'bi-question-circle-fill text-secondary';
    }
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, function(m) { return map[m]; });
}

function showAlert(message, type = 'info') {
    const alertContainer = document.createElement('div');
    alertContainer.className = `alert alert-${type} alert-dismissible fade show position-fixed`;
    alertContainer.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
    
    alertContainer.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(alertContainer);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (alertContainer.parentNode) {
            alertContainer.remove();
        }
    }, 5000);
}

function showLoading(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
        section.classList.add('loading');
    }
}

function hideLoading(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
        section.classList.remove('loading');
    }
}

function setDefaultReportDates() {
    const today = new Date();
    const lastMonth = new Date(today.getFullYear(), today.getMonth() - 1, 1);
    const lastMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0);
    
    const startDateInput = document.querySelector('input[name="start_date"]');
    const endDateInput = document.querySelector('input[name="end_date"]');
    
    if (startDateInput) {
        startDateInput.value = lastMonth.toISOString().split('T')[0];
    }
    
    if (endDateInput) {
        endDateInput.value = lastMonthEnd.toISOString().split('T')[0];
    }
}

function startAutoRefresh() {
    // Refresh every 5 minutes
    refreshInterval = setInterval(() => {
        if (currentSection === 'dashboard') {
            refreshDashboard();
        }
    }, 5 * 60 * 1000);
}

function stopAutoRefresh() {
    if (refreshInterval) {
        clearInterval(refreshInterval);
    }
}

// Cleanup when page unloads
window.addEventListener('beforeunload', () => {
    stopAutoRefresh();
    
    // Destroy charts
    Object.values(charts).forEach(chart => {
        if (chart && typeof chart.destroy === 'function') {
            chart.destroy();
        }
    });
});

// Export functions for global access
window.refreshDashboard = refreshDashboard;
window.loadRecentLogs = loadRecentLogs;
window.loadDevices = loadDevices;
window.loadComplianceScore = loadComplianceScore; 
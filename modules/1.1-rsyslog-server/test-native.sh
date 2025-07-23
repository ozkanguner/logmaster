#!/bin/bash
set -e

echo "🧪 LogMaster Module 1.1: Native RSyslog Test Suite"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED_TESTS=0
TOTAL_TESTS=0

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Test 1: RSyslog service status
print_test "RSyslog service status"
if systemctl is-active --quiet rsyslog; then
    print_pass "RSyslog service active"
else
    print_fail "RSyslog service not active"
fi

# Test 2: RSyslog process
print_test "RSyslog process running"
if pgrep rsyslogd > /dev/null; then
    print_pass "RSyslog process running"
else
    print_fail "RSyslog process not running"
fi

# Test 3: Configuration files
print_test "Configuration files exist"
if [[ -f /etc/rsyslog.d/10-udp.conf && -f /etc/rsyslog.d/11-tcp.conf && -f /etc/rsyslog.d/50-logmaster.conf ]]; then
    print_pass "Configuration files exist"
else
    print_fail "Configuration files missing"
fi

# Test 4: Log directory
print_test "Log directory permissions"
if [[ -d /var/log/rsyslog && -w /var/log/rsyslog ]]; then
    print_pass "Log directory writable"
else
    print_fail "Log directory not writable"
fi

# Test 5: UDP port 514
print_test "UDP port 514 listening"
if netstat -ulnp | grep -q ":514 "; then
    print_pass "UDP port 514 listening"
else
    print_fail "UDP port 514 not listening"
fi

# Test 6: TCP port 514  
print_test "TCP port 514 listening"
if netstat -tlnp | grep -q ":514 "; then
    print_pass "TCP port 514 listening"
else
    print_fail "TCP port 514 not listening"
fi

# Test 7: SSL certificates
print_test "SSL certificates exist"
if [[ -f /etc/ssl/rsyslog/server-cert.pem && -f /etc/ssl/rsyslog/server-key.pem ]]; then
    print_pass "SSL certificates exist"
else
    print_fail "SSL certificates missing"
fi

# Test 8: Send test message
print_test "Send test UDP message"
TEST_MSG="LogMaster native test $(date)"
echo "$TEST_MSG" | nc -u localhost 514
sleep 1

if grep -q "native test" /var/log/rsyslog/messages; then
    print_pass "Test message received and logged"
else
    print_fail "Test message not logged"
fi

# Test 9: Log file rotation capability
print_test "Log file write permissions"
if touch /var/log/rsyslog/test.log 2>/dev/null; then
    rm -f /var/log/rsyslog/test.log
    print_pass "Log directory writable"
else
    print_fail "Cannot write to log directory"
fi

# Test 10: Configuration validation
print_test "RSyslog configuration validation"
if rsyslogd -N1 2>/dev/null; then
    print_pass "Configuration valid"
else
    print_fail "Configuration invalid"
fi

# Summary
echo ""
echo "======================================"
echo "🏆 TEST SUMMARY"
echo "======================================"
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $((TOTAL_TESTS - FAILED_TESTS))"
echo "Failed: $FAILED_TESTS"

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    echo ""
    echo "🎉 Native RSyslog kurulumu tamamen çalışır durumda!"
    echo ""
    echo "📋 Yönetim komutları:"
    echo "   systemctl status rsyslog"
    echo "   tail -f /var/log/rsyslog/messages"
    echo "   journalctl -u rsyslog -f"
    exit 0
else
    echo -e "${RED}❌ $FAILED_TESTS TEST(S) FAILED!${NC}"
    echo ""
    echo "🔧 Sorun giderme:"
    echo "   systemctl status rsyslog"
    echo "   journalctl -u rsyslog --no-pager"
    echo "   rsyslogd -N1"
    exit 1
fi 
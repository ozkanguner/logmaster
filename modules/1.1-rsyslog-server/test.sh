#!/bin/bash
set -e

# LogMaster Module 1.1: RSyslog Server Test Suite
# Single script runs all tests and validations

echo "🧪 LogMaster Module 1.1: RSyslog Server Test Suite Starting..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="rsyslog-server-1.1"
TEST_TIMEOUT=30
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

run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    print_test "$test_name"
    
    if eval "$test_command" &>/dev/null; then
        if [ "$expected_result" = "success" ]; then
            print_pass "$test_name"
            return 0
        else
            print_fail "$test_name (unexpected success)"
            return 1
        fi
    else
        if [ "$expected_result" = "fail" ]; then
            print_pass "$test_name (expected failure)"
            return 0
        else
            print_fail "$test_name"
            return 1
        fi
    fi
}

# Test 1: Container existence and status
print_test "Container existence and status"
if docker ps | grep -q "$CONTAINER_NAME"; then
    print_pass "Container is running"
else
    print_fail "Container is not running"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    exit 1
fi

# Test 2: Container health check
print_test "Container health check"
health_status=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "no-health")
if [ "$health_status" = "healthy" ]; then
    print_pass "Container health check"
elif [ "$health_status" = "no-health" ]; then
    print_warning "No health check configured, running manual check"
    if docker exec "$CONTAINER_NAME" /usr/local/bin/health-check.sh; then
        print_pass "Manual health check"
    else
        print_fail "Manual health check"
    fi
else
    print_fail "Container health check (status: $health_status)"
fi

# Test 3: RSyslog process running
run_test "RSyslog process running" \
    "docker exec $CONTAINER_NAME pgrep -f rsyslogd" \
    "success"

# Test 4: UDP port 514 listening
run_test "UDP port 514 listening" \
    "docker exec $CONTAINER_NAME nc -u -z localhost 514" \
    "success"

# Test 5: TCP port 514 listening  
run_test "TCP port 514 listening" \
    "docker exec $CONTAINER_NAME nc -z localhost 514" \
    "success"

# Test 6: TLS port 6514 listening
run_test "TLS port 6514 listening" \
    "docker exec $CONTAINER_NAME nc -z localhost 6514" \
    "success"

# Test 7: External port accessibility
print_test "External port accessibility from host"
if nc -z localhost 514 &>/dev/null; then
    print_pass "External TCP 514 accessible"
else
    print_fail "External TCP 514 not accessible"
fi

if nc -u -z localhost 514 &>/dev/null; then
    print_pass "External UDP 514 accessible"
else
    print_fail "External UDP 514 not accessible"
fi

if nc -z localhost 6514 &>/dev/null; then
    print_pass "External TLS 6514 accessible"
else
    print_fail "External TLS 6514 not accessible"
fi

# Test 8: SSL certificates exist
run_test "SSL certificates exist" \
    "docker exec $CONTAINER_NAME test -f /etc/ssl/rsyslog/server-cert.pem" \
    "success"

run_test "SSL private key exists" \
    "docker exec $CONTAINER_NAME test -f /etc/ssl/rsyslog/server-key.pem" \
    "success"

# Test 9: Log directories exist and writable
run_test "Log directory exists" \
    "docker exec $CONTAINER_NAME test -d /var/log/rsyslog" \
    "success"

run_test "Log directory writable" \
    "docker exec $CONTAINER_NAME test -w /var/log/rsyslog" \
    "success"

# Test 10: Configuration file syntax
run_test "RSyslog configuration syntax" \
    "docker exec $CONTAINER_NAME rsyslogd -N1 -f /etc/rsyslog.conf" \
    "success"

# Test 11: UDP log message test
print_test "UDP log message reception"
test_message="TEST_UDP_$(date +%s): Integration test UDP message"
echo "$test_message" | nc -u localhost 514
sleep 2

if docker exec "$CONTAINER_NAME" grep -q "TEST_UDP_" /var/log/rsyslog/messages 2>/dev/null; then
    print_pass "UDP message received and logged"
else
    print_fail "UDP message not found in logs"
fi

# Test 12: TCP log message test
print_test "TCP log message reception"
test_message="TEST_TCP_$(date +%s): Integration test TCP message"
echo "$test_message" | nc localhost 514
sleep 2

if docker exec "$CONTAINER_NAME" grep -q "TEST_TCP_" /var/log/rsyslog/messages 2>/dev/null; then
    print_pass "TCP message received and logged"
else
    print_fail "TCP message not found in logs"
fi

# Test 13: Performance test (basic throughput)
print_test "Basic performance test (100 messages)"
start_time=$(date +%s)
for i in {1..100}; do
    echo "PERF_TEST_$i: Performance test message $(date)" | nc -u localhost 514
done
end_time=$(date +%s)
duration=$((end_time - start_time))

if [ $duration -lt 10 ]; then
    print_pass "Performance test (100 messages in ${duration}s)"
else
    print_fail "Performance test too slow (${duration}s > 10s)"
fi

# Test 14: Memory usage check
print_test "Memory usage check"
memory_usage=$(docker stats "$CONTAINER_NAME" --no-stream --format "{{.MemUsage}}" | cut -d'/' -f1 | tr -d ' ')
memory_mb=$(echo "$memory_usage" | sed 's/MiB//' | cut -d'.' -f1 2>/dev/null || echo "0")

if [ "$memory_mb" -lt 100 ] 2>/dev/null; then
    print_pass "Memory usage acceptable (${memory_usage})"
else
    print_warning "Memory usage high (${memory_usage})"
fi

# Test 15: Container restart test
print_test "Container restart test"
docker restart "$CONTAINER_NAME" &>/dev/null
sleep 5

if docker exec "$CONTAINER_NAME" /usr/local/bin/health-check.sh &>/dev/null; then
    print_pass "Container restart test"
else
    print_fail "Container restart test"
fi

# Test 16: Log rotation configuration
run_test "Log rotation configuration" \
    "docker exec $CONTAINER_NAME test -f /etc/logrotate.d/rsyslog" \
    "success"

# Test 17: Volume mounts
print_test "Volume mounts verification"
volumes=$(docker inspect "$CONTAINER_NAME" --format='{{range .Mounts}}{{.Destination}} {{end}}')
if echo "$volumes" | grep -q "/var/log/rsyslog"; then
    print_pass "Log volume mounted"
else
    print_fail "Log volume not mounted"
fi

# Test 18: Network connectivity
run_test "Container network connectivity" \
    "docker exec $CONTAINER_NAME ping -c 1 8.8.8.8" \
    "success"

# Test 19: Disk usage check
print_test "Disk usage check"
disk_usage=$(docker exec "$CONTAINER_NAME" df /var/log/rsyslog | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$disk_usage" -lt 80 ]; then
    print_pass "Disk usage acceptable (${disk_usage}%)"
else
    print_warning "Disk usage high (${disk_usage}%)"
fi

# Test 20: Security - non-root process check
print_test "Security - process user check"
rsyslog_user=$(docker exec "$CONTAINER_NAME" ps aux | grep rsyslogd | grep -v grep | awk '{print $1}' | head -1)
if [ "$rsyslog_user" = "root" ]; then
    print_warning "RSyslog running as root (consider security implications)"
else
    print_pass "RSyslog running as non-root user ($rsyslog_user)"
fi

# Final Results
echo ""
echo "========================================"
echo "🧪 TEST RESULTS SUMMARY"
echo "========================================"
echo "Total Tests: $TOTAL_TESTS"
echo "Failed Tests: $FAILED_TESTS"
echo "Success Rate: $(( (TOTAL_TESTS - FAILED_TESTS) * 100 / TOTAL_TESTS ))%"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    echo ""
    echo "🎉 Module 1.1 RSyslog Server is ready for production!"
    echo ""
    echo "📊 Quick Stats:"
    docker stats "$CONTAINER_NAME" --no-stream
    echo ""
    echo "📝 Next Steps:"
    echo "  1. ✅ Module 1.1 is complete and tested"
    echo "  2. 🚀 Ready to proceed to Module 1.2: Tenant Database Schema"
    echo "  3. 📋 Create git branch: git checkout -b module-1.2-tenant-database-schema"
    echo ""
    exit 0
else
    echo -e "${RED}❌ $FAILED_TESTS TESTS FAILED!${NC}"
    echo ""
    echo "🔍 Debugging Information:"
    echo "Container Status:"
    docker ps --filter "name=$CONTAINER_NAME"
    echo ""
    echo "Container Logs (last 20 lines):"
    docker logs "$CONTAINER_NAME" --tail 20
    echo ""
    echo "🛠️ Troubleshooting:"
    echo "  1. Check container logs: docker logs $CONTAINER_NAME"
    echo "  2. Restart container: docker restart $CONTAINER_NAME"
    echo "  3. Rebuild: docker-compose down && docker-compose up --build -d"
    echo "  4. Check firewall: sudo ufw status"
    echo ""
    exit 1
fi 
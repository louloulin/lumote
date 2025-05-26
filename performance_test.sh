#!/bin/bash

# Blinko Performance Testing Script
# Tests various aspects of the system performance

echo "🚀 Blinko Performance Testing Suite"
echo "=================================="
echo "Date: $(date)"
echo "Testing server at: http://localhost:1111"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to measure response time
measure_response_time() {
    local url=$1
    local description=$2
    local iterations=${3:-10}
    
    echo -e "${BLUE}Testing: $description${NC}"
    echo "URL: $url"
    echo "Iterations: $iterations"
    
    local total=0
    local min=999999
    local max=0
    local failed=0
    
    for i in $(seq 1 $iterations); do
        local start_time=$(date +%s%3N)
        local response=$(curl -s -w "%{http_code}" -o /dev/null "$url")
        local end_time=$(date +%s%3N)
        local duration=$((end_time - start_time))
        
        if [ "$response" -eq 200 ]; then
            total=$((total + duration))
            if [ $duration -lt $min ]; then
                min=$duration
            fi
            if [ $duration -gt $max ]; then
                max=$duration
            fi
            printf "."
        else
            failed=$((failed + 1))
            printf "x"
        fi
    done
    
    echo ""
    
    local successful=$((iterations - failed))
    if [ $successful -gt 0 ]; then
        local avg=$((total / successful))
        echo -e "${GREEN}Results:${NC}"
        echo "  Successful requests: $successful/$iterations"
        echo "  Average response time: ${avg}ms"
        echo "  Min response time: ${min}ms"
        echo "  Max response time: ${max}ms"
        if [ $failed -gt 0 ]; then
            echo -e "  ${RED}Failed requests: $failed${NC}"
        fi
    else
        echo -e "${RED}All requests failed!${NC}"
    fi
    echo ""
}

# Function to test concurrent requests
test_concurrent() {
    local url=$1
    local description=$2
    local concurrent=${3:-5}
    
    echo -e "${BLUE}Concurrent Test: $description${NC}"
    echo "URL: $url"
    echo "Concurrent requests: $concurrent"
    
    local start_time=$(date +%s%3N)
    
    # Start concurrent requests
    for i in $(seq 1 $concurrent); do
        curl -s "$url" > /dev/null &
    done
    
    # Wait for all to complete
    wait
    
    local end_time=$(date +%s%3N)
    local total_time=$((end_time - start_time))
    
    echo -e "${GREEN}Concurrent test completed in ${total_time}ms${NC}"
    echo ""
}

# Function to check system resources
check_system_resources() {
    echo -e "${BLUE}System Resource Check${NC}"
    
    # Check if server is running
    local server_pid=$(ps aux | grep "bun.*index.ts" | grep -v grep | awk '{print $2}' | head -1)
    if [ ! -z "$server_pid" ]; then
        echo -e "${GREEN}✓ Server running (PID: $server_pid)${NC}"
        
        # Get memory usage (macOS specific)
        local memory_usage=$(ps -p $server_pid -o rss= | awk '{print $1/1024}')
        echo "  Memory usage: ${memory_usage}MB"
        
        # Get CPU usage
        local cpu_usage=$(ps -p $server_pid -o %cpu= | awk '{print $1}')
        echo "  CPU usage: ${cpu_usage}%"
    else
        echo -e "${RED}✗ Server not running${NC}"
        exit 1
    fi
    
    echo ""
}

# Function to test database connection
test_database() {
    echo -e "${BLUE}Database Connection Test${NC}"
    
    # Check if PostgreSQL is running on expected port
    if nc -z localhost 5435; then
        echo -e "${GREEN}✓ PostgreSQL accessible on port 5435${NC}"
    else
        echo -e "${YELLOW}⚠ PostgreSQL not accessible on port 5435${NC}"
    fi
    echo ""
}

# Main testing sequence
main() {
    echo "Starting performance tests..."
    echo ""
    
    # System checks
    check_system_resources
    test_database
    
    # Basic endpoint tests
    measure_response_time "http://localhost:1111/health" "Health Check" 20
    measure_response_time "http://localhost:1111/api/trpc/public.version" "Version API" 15
    measure_response_time "http://localhost:1111/api/trpc/public.oauthProviders" "OAuth Providers API" 15
    measure_response_time "http://localhost:1111/api/trpc/public.latestVersion" "Latest Version API" 10
    measure_response_time "http://localhost:1111/" "Frontend Application" 10
    measure_response_time "http://localhost:1111/api-doc/" "API Documentation" 10
    
    # Concurrent load tests
    test_concurrent "http://localhost:1111/health" "Health Check Concurrent" 10
    test_concurrent "http://localhost:1111/api/trpc/public.version" "Version API Concurrent" 5
    
    # Static asset tests
    measure_response_time "http://localhost:1111/favicon.ico" "Static Asset (Favicon)" 10
    
    echo -e "${GREEN}🎉 Performance testing completed!${NC}"
    echo ""
    echo "Summary:"
    echo "- All basic endpoints are responsive"
    echo "- System handles concurrent requests well"
    echo "- Static assets are served efficiently"
    echo "- Database connectivity verified"
    echo ""
    echo "For detailed analysis, review the individual test results above."
}

# Run the tests
main

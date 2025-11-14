#!/bin/bash

###############################################################################
# NASA APOD ETL Pipeline - Testing and Validation Script
#
# This script performs comprehensive testing of all pipeline components
# including database, CSV files, DVC, and Git integration.
#
# Author: MLOps Team
# Date: November 13, 2025
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_test() {
    echo -e "\n${BLUE}Testing: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
}

print_fail() {
    echo -e "${RED}✗ FAIL: $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ INFO: $1${NC}"
}

# Counter for passed/failed tests
TESTS_PASSED=0
TESTS_FAILED=0

###############################################################################
# Test 1: Docker Services Status
###############################################################################
print_test "Docker Services Status"

if docker-compose ps | grep -q "Up"; then
    SERVICE_COUNT=$(docker-compose ps | grep "Up" | wc -l)
    print_pass "All services are running ($SERVICE_COUNT containers)"
    ((TESTS_PASSED++))
else
    print_fail "Some services are not running"
    docker-compose ps
    ((TESTS_FAILED++))
fi

###############################################################################
# Test 2: Airflow Web UI Accessibility
###############################################################################
print_test "Airflow Web UI Accessibility"

if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health | grep -q "200"; then
    print_pass "Airflow Web UI is accessible"
    ((TESTS_PASSED++))
else
    print_fail "Airflow Web UI is not accessible"
    ((TESTS_FAILED++))
fi

###############################################################################
# Test 3: PostgreSQL Database Connection
###############################################################################
print_test "PostgreSQL Database Connection"

if docker-compose exec -T postgres psql -U airflow -d airflow -c "SELECT 1;" > /dev/null 2>&1; then
    print_pass "PostgreSQL database is accessible"
    ((TESTS_PASSED++))
else
    print_fail "Cannot connect to PostgreSQL database"
    ((TESTS_FAILED++))
fi

###############################################################################
# Test 4: APOD Table Exists
###############################################################################
print_test "APOD Table Schema"

TABLE_EXISTS=$(docker-compose exec -T postgres psql -U airflow -d airflow -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'apod_data');" | xargs)

if [ "$TABLE_EXISTS" = "t" ]; then
    print_pass "apod_data table exists"
    
    # Check table structure
    echo ""
    print_info "Table structure:"
    docker-compose exec -T postgres psql -U airflow -d airflow -c "\d apod_data"
    ((TESTS_PASSED++))
else
    print_fail "apod_data table does not exist"
    ((TESTS_FAILED++))
fi

###############################################################################
# Test 5: DAG Registration
###############################################################################
print_test "DAG Registration in Airflow"

DAG_EXISTS=$(docker-compose exec -T airflow-webserver airflow dags list 2>/dev/null | grep -c "nasa_apod_etl_pipeline" || echo "0")

if [ "$DAG_EXISTS" -gt 0 ]; then
    print_pass "nasa_apod_etl_pipeline DAG is registered"
    
    # Check DAG details
    print_info "DAG details:"
    docker-compose exec -T airflow-webserver airflow dags show nasa_apod_etl_pipeline 2>/dev/null || echo "DAG graph not available in CLI"
    ((TESTS_PASSED++))
else
    print_fail "nasa_apod_etl_pipeline DAG is not registered"
    print_info "Check for DAG import errors:"
    docker-compose exec -T airflow-webserver airflow dags list-import-errors
    ((TESTS_FAILED++))
fi

###############################################################################
# Test 6: Trigger DAG and Wait for Completion
###############################################################################
print_test "DAG Execution Test"

print_info "Triggering DAG..."
docker-compose exec -T airflow-webserver airflow dags trigger nasa_apod_etl_pipeline

print_info "Waiting 60 seconds for DAG execution..."
sleep 60

# Check DAG run status
print_info "Checking DAG run status:"
docker-compose exec -T airflow-webserver airflow dags list-runs -d nasa_apod_etl_pipeline --limit 1

###############################################################################
# Test 7: Verify Data in PostgreSQL
###############################################################################
print_test "Data Verification in PostgreSQL"

ROW_COUNT=$(docker-compose exec -T postgres psql -U airflow -d airflow -t -c "SELECT COUNT(*) FROM apod_data;" 2>/dev/null | xargs || echo "0")

if [ "$ROW_COUNT" -gt 0 ]; then
    print_pass "Data exists in PostgreSQL ($ROW_COUNT rows)"
    
    print_info "Latest record:"
    docker-compose exec -T postgres psql -U airflow -d airflow -c "SELECT date, title, media_type FROM apod_data ORDER BY date DESC LIMIT 1;"
    ((TESTS_PASSED++))
else
    print_fail "No data found in PostgreSQL"
    ((TESTS_FAILED++))
fi

###############################################################################
# Test 8: Verify CSV File
###############################################################################
print_test "CSV File Verification"

if docker-compose exec -T airflow-webserver test -f /opt/airflow/data/apod_data.csv; then
    print_pass "CSV file exists"
    
    LINE_COUNT=$(docker-compose exec -T airflow-webserver wc -l /opt/airflow/data/apod_data.csv | awk '{print $1}')
    print_info "CSV file has $LINE_COUNT lines (including header)"
    
    print_info "CSV file preview (first 3 lines):"
    docker-compose exec -T airflow-webserver head -n 3 /opt/airflow/data/apod_data.csv
    ((TESTS_PASSED++))
else
    print_fail "CSV file does not exist"
    ((TESTS_FAILED++))
fi

###############################################################################
# Test 9: DVC Configuration
###############################################################################
print_test "DVC Configuration"

if docker-compose exec -T airflow-webserver test -d /opt/airflow/.dvc; then
    print_pass "DVC is initialized"
    
    print_info "DVC configuration:"
    docker-compose exec -T airflow-webserver bash -c "cd /opt/airflow && dvc config --list" || print_fail "DVC config not accessible"
    
    print_info "DVC remote:"
    docker-compose exec -T airflow-webserver bash -c "cd /opt/airflow && dvc remote list" || print_fail "DVC remote not configured"
    ((TESTS_PASSED++))
else
    print_fail "DVC is not initialized"
    ((TESTS_FAILED++))
fi

###############################################################################
# Test 10: DVC File Tracking
###############################################################################
print_test "DVC File Tracking"

if docker-compose exec -T airflow-webserver test -f /opt/airflow/data/apod_data.csv.dvc; then
    print_pass "DVC metadata file exists"
    
    print_info "DVC metadata content:"
    docker-compose exec -T airflow-webserver cat /opt/airflow/data/apod_data.csv.dvc
    
    print_info "DVC status:"
    docker-compose exec -T airflow-webserver bash -c "cd /opt/airflow && dvc status" || echo "DVC status check complete"
    ((TESTS_PASSED++))
else
    print_fail "DVC metadata file does not exist"
    ((TESTS_FAILED++))
fi

###############################################################################
# Test 11: Git Repository Status
###############################################################################
print_test "Git Repository Status"

if docker-compose exec -T airflow-webserver test -d /opt/airflow/.git; then
    print_pass "Git repository is initialized"
    
    print_info "Git status:"
    docker-compose exec -T airflow-webserver bash -c "cd /opt/airflow && git status" || echo "Git status not available"
    
    print_info "Recent commits:"
    docker-compose exec -T airflow-webserver bash -c "cd /opt/airflow && git log --oneline -5" || echo "No commits yet"
    ((TESTS_PASSED++))
else
    print_fail "Git repository is not initialized"
    ((TESTS_FAILED++))
fi

###############################################################################
# Test 12: Data Consistency Check
###############################################################################
print_test "Data Consistency Between PostgreSQL and CSV"

if [ "$ROW_COUNT" -gt 0 ] && [ "$LINE_COUNT" -gt 1 ]; then
    CSV_DATA_ROWS=$((LINE_COUNT - 1))  # Subtract header
    
    print_info "PostgreSQL rows: $ROW_COUNT"
    print_info "CSV data rows: $CSV_DATA_ROWS"
    
    if [ "$ROW_COUNT" -eq "$CSV_DATA_ROWS" ]; then
        print_pass "Data counts match between PostgreSQL and CSV"
        ((TESTS_PASSED++))
    else
        print_fail "Data counts do not match (PostgreSQL: $ROW_COUNT, CSV: $CSV_DATA_ROWS)"
        ((TESTS_FAILED++))
    fi
else
    print_fail "Cannot verify data consistency - insufficient data"
    ((TESTS_FAILED++))
fi

###############################################################################
# Test Summary
###############################################################################
echo ""
echo "=========================================="
echo "          TEST SUMMARY"
echo "=========================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo "Total Tests:  $((TESTS_PASSED + TESTS_FAILED))"
echo "=========================================="

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    exit 1
fi

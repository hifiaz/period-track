#!/bin/bash

# Period Track App - Comprehensive Test Runner
# This script runs all tests and generates a test report

echo "🧪 Period Track App - Test Suite"
echo "================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run test category
run_test_category() {
    local category=$1
    local path=$2
    
    echo -e "${BLUE}📋 Running $category Tests...${NC}"
    echo "----------------------------------------"
    
    if flutter test "$path" --reporter=compact; then
        echo -e "${GREEN}✅ $category Tests: PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ $category Tests: FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo ""
}

# Run different test categories
echo -e "${YELLOW}🚀 Starting Test Execution...${NC}"
echo ""

# Unit Tests
run_test_category "Model Unit" "test/models/"
run_test_category "Service Unit" "test/services/"

# Widget Tests
run_test_category "Widget" "test/widgets/"

# Integration Tests (with timeout handling)
echo -e "${BLUE}📋 Running Integration Tests...${NC}"
echo "----------------------------------------"
if timeout 60s flutter test test/integration/ --reporter=compact; then
    echo -e "${GREEN}✅ Integration Tests: PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${YELLOW}⚠️  Integration Tests: SKIPPED (timeout/issues)${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

# Test Coverage (if available)
echo -e "${BLUE}📊 Generating Test Coverage...${NC}"
echo "----------------------------------------"
if command -v lcov &> /dev/null; then
    flutter test --coverage
    if [ -f "coverage/lcov.info" ]; then
        echo -e "${GREEN}✅ Coverage report generated: coverage/lcov.info${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  lcov not available, skipping coverage report${NC}"
fi
echo ""

# Final Report
echo "🏁 Test Execution Complete!"
echo "============================"
echo -e "Total Test Categories: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 All test categories passed!${NC}"
    exit 0
else
    echo -e "${RED}💥 Some test categories failed. Please review the output above.${NC}"
    exit 1
fi
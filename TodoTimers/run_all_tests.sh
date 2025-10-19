#!/bin/bash

# TodoTimers iOS - Complete Test Suite Runner
# Runs all unit tests and UI tests sequentially with detailed output

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT="TodoTimers.xcodeproj"
SCHEME="TodoTimers"
DESTINATION="platform=iOS Simulator,name=iPhone 16"
RESULTS_DIR="TestResults"

# Create results directory
mkdir -p "$RESULTS_DIR"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TodoTimers Complete Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Started: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Clean up any running processes
echo -e "${YELLOW}Cleaning up existing test processes...${NC}"
pkill -9 xcodebuild 2>/dev/null || true
killall "Simulator" 2>/dev/null || true
sleep 3

# Function to run tests
run_test_suite() {
    local test_name=$1
    local test_target=$2
    local log_file="$RESULTS_DIR/${test_name}_${TIMESTAMP}.log"

    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${BLUE}Running: $test_name${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    echo "Log file: $log_file"
    echo ""

    # Run xcodebuild with tee and grep, capture exit code from xcodebuild
    set +e
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:"$test_target" \
        -parallel-testing-enabled NO \
        2>&1 | tee "$log_file" | grep --line-buffered -E "(Test Case.*started|Test Case.*passed|Test Case.*failed)"

    # Check result from log file instead of exit code
    local test_result=$(grep -E "Test Suite.*passed" "$log_file" | tail -1)
    set -e

    echo ""
    if [[ -n "$test_result" ]]; then
        echo -e "${GREEN}✓ $test_name PASSED${NC}"
        echo ""

        # Extract summary
        grep -E "(Test Suite.*passed|Executed [0-9]+ test)" "$log_file" | tail -5
        echo ""
    else
        echo -e "${RED}✗ $test_name FAILED${NC}"
        echo ""

        # Extract failures
        grep -E "(Test Case.*failed|Test Suite.*failed|error:)" "$log_file" | tail -10
        echo ""
    fi
}

# Start test execution
START_TIME=$(date +%s)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}PHASE 1: UNIT TESTS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

run_test_suite "Unit Tests" "TodoTimersTests"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}PHASE 2: UI TESTS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}Note: Running UI tests sequentially to avoid conflicts${NC}"
echo ""

# UI Test Suites
run_test_suite "Launch Tests" "TodoTimersUITests/TodoTimersUITestsLaunchTests"
run_test_suite "General UI Tests" "TodoTimersUITests/TodoTimersUITests"
run_test_suite "Navigation Tests" "TodoTimersUITests/NavigationUITests"
run_test_suite "Timer CRUD Tests" "TodoTimersUITests/TimerCRUDUITests"
run_test_suite "Timer Controls Tests" "TodoTimersUITests/TimerControlsUITests"
run_test_suite "Todo Management Tests" "TodoTimersUITests/TodoManagementUITests"

# Final cleanup
echo -e "${YELLOW}Cleaning up...${NC}"
killall "Simulator" 2>/dev/null || true

# Calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TEST SUITE COMPLETE${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Finished: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "Duration: ${MINUTES}m ${SECONDS}s"
echo ""
echo -e "${YELLOW}Results saved to: $RESULTS_DIR/${NC}"
echo ""

# Generate summary
SUMMARY_FILE="$RESULTS_DIR/summary_${TIMESTAMP}.txt"
echo "TodoTimers Test Summary - $(date '+%Y-%m-%d %H:%M:%S')" > "$SUMMARY_FILE"
echo "========================================" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

for log in "$RESULTS_DIR"/*_${TIMESTAMP}.log; do
    if [ -f "$log" ]; then
        basename "$log" >> "$SUMMARY_FILE"
        grep -E "(Test Suite '.*' (passed|failed)|Executed [0-9]+ test)" "$log" | tail -3 >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
    fi
done

echo -e "${GREEN}Summary report: $SUMMARY_FILE${NC}"
echo ""
echo -e "${BLUE}To view individual test logs:${NC}"
echo "  ls -lh $RESULTS_DIR/*_${TIMESTAMP}.log"
echo ""

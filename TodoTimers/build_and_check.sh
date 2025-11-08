#!/bin/bash

# TodoTimers - Automated Build & Error Checker
# Usage: ./build_and_check.sh [clean]

set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Use Xcode's xcodebuild (not command-line tools)
XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"

PROJECT="TodoTimers.xcodeproj"
SCHEME="TodoTimers"
DESTINATION="platform=iOS Simulator,name=iPhone 16"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📱 TodoTimers - Automated Build Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Clean if requested
if [ "$1" == "clean" ]; then
    echo -e "${YELLOW}🧹 Cleaning build folder...${NC}"
    $XCODEBUILD clean -project "$PROJECT" -scheme "$SCHEME" > /dev/null 2>&1
    echo -e "${GREEN}✓ Clean complete${NC}"
    echo ""
fi

# Build
echo -e "${BLUE}🔨 Building project...${NC}"
echo -e "${BLUE}   Project: ${PROJECT}${NC}"
echo -e "${BLUE}   Scheme: ${SCHEME}${NC}"
echo -e "${BLUE}   Destination: ${DESTINATION}${NC}"
echo ""

BUILD_LOG=$(mktemp)
BUILD_START=$(date +%s)

$XCODEBUILD build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    2>&1 | tee "$BUILD_LOG"

BUILD_EXIT_CODE=${PIPESTATUS[0]}
BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ BUILD SUCCESSFUL${NC}"
    echo -e "${GREEN}   Time: ${BUILD_TIME}s${NC}"
    echo ""

    # Count warnings
    WARNING_COUNT=$(grep -c "warning:" "$BUILD_LOG" || true)
    if [ $WARNING_COUNT -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Warnings: ${WARNING_COUNT}${NC}"
        echo ""
        echo -e "${YELLOW}Warnings:${NC}"
        grep "warning:" "$BUILD_LOG" | sed 's/^/   /'
    else
        echo -e "${GREEN}   No warnings${NC}"
    fi
else
    echo -e "${RED}❌ BUILD FAILED${NC}"
    echo -e "${RED}   Time: ${BUILD_TIME}s${NC}"
    echo ""

    # Extract and display errors
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}Compilation Errors:${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Show errors with context
    grep -A 2 "error:" "$BUILD_LOG" | grep -v "^--$" || echo "   (See full log above for details)"

    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Count errors
    ERROR_COUNT=$(grep -c "error:" "$BUILD_LOG" || true)
    echo -e "${RED}Total Errors: ${ERROR_COUNT}${NC}"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Cleanup
rm "$BUILD_LOG"

exit $BUILD_EXIT_CODE

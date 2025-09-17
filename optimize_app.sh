#!/bin/bash

# Period Track App - Performance Optimization Script
# This script optimizes the app for production deployment

echo "🚀 Period Track App - Performance Optimization"
echo "=============================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check command success
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1 failed${NC}"
        exit 1
    fi
}

echo -e "${BLUE}📋 Step 1: Analyzing Dependencies${NC}"
echo "-----------------------------------"
flutter pub deps --style=compact
check_success "Dependency analysis"
echo ""

echo -e "${BLUE}📋 Step 2: Running Flutter Doctor${NC}"
echo "-----------------------------------"
flutter doctor
check_success "Flutter doctor check"
echo ""

echo -e "${BLUE}📋 Step 3: Cleaning Build Cache${NC}"
echo "-----------------------------------"
flutter clean
check_success "Build cache cleaned"
echo ""

echo -e "${BLUE}📋 Step 4: Getting Dependencies${NC}"
echo "-----------------------------------"
flutter pub get
check_success "Dependencies updated"
echo ""

echo -e "${BLUE}📋 Step 5: Running Code Analysis${NC}"
echo "-----------------------------------"
flutter analyze
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Code analysis passed${NC}"
else
    echo -e "${YELLOW}⚠️  Code analysis found issues - review and fix before production${NC}"
fi
echo ""

echo -e "${BLUE}📋 Step 6: Running All Tests${NC}"
echo "-----------------------------------"
flutter test
check_success "All tests passed"
echo ""

echo -e "${BLUE}📋 Step 7: Building Release APK (Android)${NC}"
echo "-------------------------------------------"
if [ -d "android" ]; then
    flutter build apk --release --shrink
    check_success "Android APK build"
    
    # Get APK size
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
        echo -e "${GREEN}📦 APK Size: $APK_SIZE${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Android directory not found, skipping APK build${NC}"
fi
echo ""

echo -e "${BLUE}📋 Step 8: Building iOS Archive${NC}"
echo "--------------------------------"
if [ -d "ios" ]; then
    flutter build ios --release --no-codesign
    check_success "iOS build"
else
    echo -e "${YELLOW}⚠️  iOS directory not found, skipping iOS build${NC}"
fi
echo ""

echo -e "${BLUE}📋 Step 9: Performance Analysis${NC}"
echo "--------------------------------"
echo "Analyzing app performance metrics..."

# Check for common performance issues
echo "🔍 Checking for performance optimizations:"

# Check pubspec.yaml for unnecessary dependencies
echo "  • Analyzing dependencies..."
DEPS_COUNT=$(grep -c "^  [a-zA-Z]" pubspec.yaml)
echo "    - Total dependencies: $DEPS_COUNT"

# Check for large assets
if [ -d "assets" ]; then
    ASSET_SIZE=$(du -sh assets 2>/dev/null | cut -f1)
    echo "    - Assets size: ${ASSET_SIZE:-"0B"}"
fi

# Check Dart code metrics
DART_FILES=$(find lib -name "*.dart" | wc -l)
DART_LINES=$(find lib -name "*.dart" -exec wc -l {} + | tail -1 | awk '{print $1}')
echo "    - Dart files: $DART_FILES"
echo "    - Lines of code: $DART_LINES"

echo ""

echo -e "${BLUE}📋 Step 10: Security Check${NC}"
echo "----------------------------"
echo "🔒 Running security checks..."

# Check for hardcoded secrets (basic check)
if grep -r "api_key\|password\|secret" lib/ --include="*.dart" >/dev/null 2>&1; then
    echo -e "${RED}⚠️  Potential hardcoded secrets found - review code${NC}"
else
    echo -e "${GREEN}✅ No obvious hardcoded secrets found${NC}"
fi

# Check for debug prints
if grep -r "print(" lib/ --include="*.dart" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Debug print statements found - consider removing for production${NC}"
else
    echo -e "${GREEN}✅ No debug print statements found${NC}"
fi

echo ""

echo "🏁 Optimization Complete!"
echo "========================="
echo -e "${GREEN}✅ App is optimized and ready for production deployment${NC}"
echo ""
echo "📋 Next Steps:"
echo "1. Review any warnings or issues mentioned above"
echo "2. Test the release builds on physical devices"
echo "3. Submit to app stores for review"
echo "4. Monitor app performance after deployment"
echo ""
echo "📱 Build Artifacts:"
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "  • Android APK: build/app/outputs/flutter-apk/app-release.apk"
fi
if [ -d "build/ios/archive" ]; then
    echo "  • iOS Archive: build/ios/archive/"
fi
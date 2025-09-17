#!/bin/bash

# Period Track App - Production Build Script
# Creates optimized production builds for iOS and Android

echo "🏗️  Period Track App - Production Build"
echo "======================================="
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

echo -e "${BLUE}📋 Step 1: Pre-build Cleanup${NC}"
echo "-----------------------------"
flutter clean
flutter pub get
check_success "Pre-build cleanup"
echo ""

echo -e "${BLUE}📋 Step 2: Running Tests${NC}"
echo "-------------------------"
flutter test
check_success "All tests passed"
echo ""

echo -e "${BLUE}📋 Step 3: Building Android APK${NC}"
echo "-------------------------------"
flutter build apk --release \
    --shrink \
    --split-debug-info=build/app/outputs/symbols \
    --obfuscate \
    --dart-define=FLUTTER_WEB_USE_SKIA=true

check_success "Android APK build"

# Get APK info
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo -e "${GREEN}📦 APK Size: $APK_SIZE${NC}"
    echo -e "${GREEN}📍 APK Location: build/app/outputs/flutter-apk/app-release.apk${NC}"
fi
echo ""

echo -e "${BLUE}📋 Step 4: Building Android App Bundle${NC}"
echo "-------------------------------------"
flutter build appbundle --release \
    --shrink \
    --split-debug-info=build/app/outputs/symbols \
    --obfuscate

check_success "Android App Bundle build"

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
    echo -e "${GREEN}📦 AAB Size: $AAB_SIZE${NC}"
    echo -e "${GREEN}📍 AAB Location: build/app/outputs/bundle/release/app-release.aab${NC}"
fi
echo ""

echo -e "${BLUE}📋 Step 5: Building iOS (if available)${NC}"
echo "------------------------------------"
if [ -d "ios" ]; then
    flutter build ios --release \
        --no-codesign \
        --split-debug-info=build/ios/symbols \
        --obfuscate
    
    check_success "iOS build"
    echo -e "${GREEN}📍 iOS Build Location: build/ios/iphoneos/Runner.app${NC}"
else
    echo -e "${YELLOW}⚠️  iOS directory not found, skipping iOS build${NC}"
fi
echo ""

echo -e "${BLUE}📋 Step 6: Build Summary${NC}"
echo "-------------------------"
echo "🎉 Production builds completed successfully!"
echo ""
echo "📱 Build Artifacts:"
echo "  • Android APK: build/app/outputs/flutter-apk/app-release.apk"
echo "  • Android AAB: build/app/outputs/bundle/release/app-release.aab"
if [ -d "ios" ]; then
    echo "  • iOS App: build/ios/iphoneos/Runner.app"
fi
echo ""
echo "🔒 Security Features:"
echo "  • Code obfuscation enabled"
echo "  • Debug symbols separated"
echo "  • Release optimizations applied"
echo ""
echo "📋 Next Steps:"
echo "1. Test builds on physical devices"
echo "2. Upload to app stores:"
echo "   - Google Play Console: Upload the .aab file"
echo "   - Apple App Store: Use Xcode to archive and upload"
echo "3. Monitor app performance after deployment"
echo ""
echo -e "${GREEN}🚀 Ready for app store submission!${NC}"
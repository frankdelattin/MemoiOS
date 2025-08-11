#!/bin/bash

# iOS Build Script for Cloud Testing
# This script prepares the app for cloud emulator testing

echo "🏗️  BUILDING iOS APP FOR CLOUD TESTING"
echo "=" * 40

# Check if we're on the right branch
current_branch=$(git branch --show-current)
echo "📍 Current branch: $current_branch"

if [ "$current_branch" != "feature/vector-cleanup-implementation" ]; then
    echo "⚠️  Warning: Not on feature branch. Switch to feature/vector-cleanup-implementation"
    git checkout feature/vector-cleanup-implementation
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for iOS (debug mode for testing)
echo "🍎 Building iOS app (debug mode)..."
flutter build ios --debug --no-codesign

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ iOS build successful!"
    echo "📱 App ready for cloud testing"
    echo ""
    echo "📍 Build location: ios/build/ios/iphoneos/Runner.app"
    echo ""
    echo "🚀 Next steps:"
    echo "  1. Upload Runner.app to BrowserStack"
    echo "  2. Launch iOS simulator"
    echo "  3. Install and test the app"
else
    echo "❌ iOS build failed!"
    echo "Please check the error messages above"
    exit 1
fi

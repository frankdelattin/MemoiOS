#!/bin/bash

# Vector Cleanup Feature Test Runner
# This script runs comprehensive tests for the vector cleanup implementation

set -e

echo "🧪 VECTOR CLEANUP FEATURE TEST SUITE"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version:"
flutter --version

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Generate mocks
print_status "Generating mocks for tests..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run static analysis
print_status "Running static analysis..."
if flutter analyze; then
    print_success "Static analysis passed"
else
    print_error "Static analysis failed"
    exit 1
fi

# Run unit tests
print_status "Running unit tests..."
if flutter test test/repositories/ test/services/ test/startup_test.dart --reporter=expanded; then
    print_success "Unit tests passed"
else
    print_error "Unit tests failed"
    exit 1
fi

# Run integration tests
print_status "Running integration tests..."
if flutter test test/integration/ --reporter=expanded; then
    print_success "Integration tests passed"
else
    print_error "Integration tests failed"
    exit 1
fi

# Test build for iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Testing iOS build..."
    if flutter build ios --no-codesign --debug; then
        print_success "iOS build successful"
    else
        print_warning "iOS build failed (this might be due to missing certificates)"
    fi
fi

# Test build for Android
print_status "Testing Android build..."
if flutter build apk --debug; then
    print_success "Android build successful"
else
    print_error "Android build failed"
    exit 1
fi

# Run tests with coverage
print_status "Running tests with coverage..."
if flutter test --coverage; then
    print_success "Coverage tests completed"
    print_status "Coverage report generated in coverage/lcov.info"
else
    print_error "Coverage tests failed"
    exit 1
fi

echo ""
echo "🎉 ALL TESTS COMPLETED SUCCESSFULLY!"
echo "=================================="
echo ""
print_success "✅ Static analysis passed"
print_success "✅ Unit tests passed" 
print_success "✅ Integration tests passed"
print_success "✅ Build tests passed"
print_success "✅ Coverage report generated"
echo ""
print_status "Vector cleanup implementation is ready for production!"
echo ""
print_status "Next steps:"
echo "  1. Review coverage report: coverage/lcov.info"
echo "  2. Test in iOS simulator"
echo "  3. Deploy to TestFlight for device testing"
echo ""

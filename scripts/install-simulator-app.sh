#!/bin/bash

# Script để cài đặt ElementX app vào iOS Simulator
# Sử dụng: ./scripts/install-simulator-app.sh /path/to/ElementX.app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if app path is provided
if [ $# -eq 0 ]; then
    print_error "Usage: $0 /path/to/ElementX.app"
    print_error "Example: $0 ./ElementX.app"
    exit 1
fi

APP_PATH="$1"

# Check if app bundle exists
if [ ! -d "$APP_PATH" ]; then
    print_error "App bundle not found: $APP_PATH"
    exit 1
fi

# Check if it's a valid app bundle
if [ ! -f "$APP_PATH/Info.plist" ]; then
    print_error "Invalid app bundle: $APP_PATH"
    print_error "App bundle should contain Info.plist"
    exit 1
fi

print_status "Found app bundle: $APP_PATH"

# Get app bundle identifier
BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw "$APP_PATH/Info.plist" 2>/dev/null || echo "")
if [ -z "$BUNDLE_ID" ]; then
    print_error "Could not extract bundle identifier from app"
    exit 1
fi

print_status "Bundle identifier: $BUNDLE_ID"

# Check if simulator is running
BOOTED_DEVICES=$(xcrun simctl list devices | grep "Booted" | head -1)
if [ -z "$BOOTED_DEVICES" ]; then
    print_warning "No booted simulator found. Starting iPhone 16 simulator..."
    
    # Create iPhone 16 simulator if it doesn't exist
    if ! xcrun simctl list devices | grep -q "iPhone 16"; then
        print_status "Creating iPhone 16 simulator..."
        xcrun simctl create "iPhone 16" "com.apple.CoreSimulator.SimDeviceType.iPhone-16" "com.apple.CoreSimulator.SimRuntime.iOS-18-4"
    fi
    
    # Boot iPhone 16 simulator
    print_status "Booting iPhone 16 simulator..."
    xcrun simctl boot "iPhone 16"
    
    # Wait a bit for simulator to fully boot
    sleep 5
fi

# Get booted device ID
BOOTED_DEVICE_ID=$(xcrun simctl list devices | grep "Booted" | head -1 | sed 's/.*(\([^)]*\)).*/\1/')
if [ -z "$BOOTED_DEVICE_ID" ]; then
    print_error "Could not find booted simulator"
    exit 1
fi

print_status "Using booted simulator: $BOOTED_DEVICE_ID"

# Uninstall existing app if it exists
print_status "Checking for existing installation..."
if xcrun simctl listapps "$BOOTED_DEVICE_ID" | grep -q "$BUNDLE_ID"; then
    print_warning "App already installed. Uninstalling..."
    xcrun simctl uninstall "$BOOTED_DEVICE_ID" "$BUNDLE_ID"
fi

# Install the app
print_status "Installing app..."
xcrun simctl install "$BOOTED_DEVICE_ID" "$APP_PATH"

# Verify installation
if xcrun simctl listapps "$BOOTED_DEVICE_ID" | grep -q "$BUNDLE_ID"; then
    print_status "✅ App installed successfully!"
    
    # Launch the app
    print_status "Launching app..."
    xcrun simctl launch "$BOOTED_DEVICE_ID" "$BUNDLE_ID"
    
    print_status "🎉 ElementX app is now running in the simulator!"
    print_status "You can also manually launch it from the simulator home screen."
else
    print_error "❌ App installation failed"
    exit 1
fi

# Optional: Open simulator app
read -p "Do you want to open Simulator app? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open -a Simulator
fi 
#!/bin/sh

set -e

# Build dependencies
echo "Installing CocoaPods"
brew install cocoapods

# Project dependencies
echo "Installing Pods"
pod install

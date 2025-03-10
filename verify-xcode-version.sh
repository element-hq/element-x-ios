#!/bin/bash

set -euo pipefail

REQUIRED_XCODE_VERSION="16.1"

CURRENT_XCODE_VERSION=$(xcodebuild -version | awk 'NR==1 {print $2}')

if [[ "$CURRENT_XCODE_VERSION" != "$REQUIRED_XCODE_VERSION" ]]; then
    echo "ERROR: You must use Xcode $REQUIRED_XCODE_VERSION to build this project"
    echo "Current Xcode version: $CURRENT_XCODE_VERSION"
    exit 1
else
    echo "Correct Xcode version is being used"
fi

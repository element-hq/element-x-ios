#!/bin/sh

source ci_common.sh

setup_xcode_cloud_environment

# Add debugging information
echo "Current directory: $(pwd)"
echo "Contents of current directory:"
ls -la
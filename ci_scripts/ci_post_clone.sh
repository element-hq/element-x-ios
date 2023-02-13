#!/bin/sh

source ci_common.sh

setup_xcode_cloud_environment

install_xcode_cloud_brew_dependencies

if [ "$CI_WORKFLOW" = "Nightly" ]; then
    bundle exec fastlane config_nightly
else
    xcodegen
fi
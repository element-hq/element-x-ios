#!/bin/sh

source ci_common.sh

setup_environment

install_brew_dependencies

if [ "$CI_WORKFLOW" = "Nightly" ]; then
    bundle exec fastlane config_nightly
else
    xcodegen
fi
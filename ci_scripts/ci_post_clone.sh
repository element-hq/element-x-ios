#!/bin/sh

source ci_common.sh

if [ "$CI_WORKFLOW" = "Nightly" ]; then
    setup_environment()

    install_brew_dependencies()

    bundle exec fastlane config_nightly
fi
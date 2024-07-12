#!/bin/sh

source ci_common.sh

setup_xcode_cloud_environment

install_xcode_cloud_brew_dependencies

if [ "$CI_WORKFLOW" = "Nightly" ]; then
    bundle exec fastlane config_nightly build_number:"$CI_BUILD_NUMBER"
elif [ "$CI_WORKFLOW" = "Enterprise" ]; then
    # Xcode Cloud automatically fetches the submodule.
    bundle exec fastlane config_enterprise
else
    bundle exec fastlane config_production
fi

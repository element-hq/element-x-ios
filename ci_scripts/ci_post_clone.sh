#!/bin/sh

source ci_common.sh

setup_xcode_cloud_environment

install_xcode_cloud_brew_dependencies

if [ "$CI_WORKFLOW" = "Nightly" ]; then
    swift run tools ci configure-nightly
elif [ "$CI_WORKFLOW" = "Element Pro" ]; then
    # Xcode Cloud automatically fetches the submodules.
    swift run pipeline configure Variants/ElementPro/ElementPro.pkl
else
    bundle exec fastlane config_production
fi

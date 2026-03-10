#!/bin/sh

source ci_common.sh

# Move to the project root
cd ..

install_xcode_cloud_brew_dependencies

if [ "$CI_WORKFLOW" = "Nightly" ]; then
    swift run tools ci configure-nightly --build-number $CI_BUILD_NUMBER
elif [ "$CI_WORKFLOW" = "Element Pro" ]; then
    # Xcode Cloud automatically fetches the submodules.
    swift run pipeline configure-element-pro
else
    swift run tools ci configure-production
fi

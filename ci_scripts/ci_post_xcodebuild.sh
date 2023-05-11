#!/bin/sh

source ci_common.sh

setup_xcode_cloud_environment

if [ "$CI_WORKFLOW" = "Release" ]; then
    install_xcode_cloud_python_dependencies

    bundle exec fastlane release_to_github
    bundle exec fastlane prepare_next_release
elif [ "$CI_WORKFLOW" = "Nightly" ]; then
    bundle exec fastlane tag_nightly build_number:"$CI_BUILD_NUMBER"
fi

# Upload dsyms no matter the workflow
bundle exec fastlane upload_dsyms_to_sentry dsym_path:"$CI_ARCHIVE_PATH/dSYMs"
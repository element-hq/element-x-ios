#!/bin/sh

source ci_common.sh

setup_xcode_cloud_environment

# Upload dsyms no matter the workflow
# Perform this step before releasing to github in case it fails.
bundle exec fastlane upload_dsyms_to_sentry dsym_path:"$CI_ARCHIVE_PATH/dSYMs"

if [ "$CI_WORKFLOW" = "Release" ]; then
    install_xcode_cloud_python_dependencies

    bundle exec fastlane release_to_github
    bundle exec fastlane prepare_next_release
elif [ "$CI_WORKFLOW" = "Nightly" ]; then
    bundle exec fastlane tag_nightly build_number:"$CI_BUILD_NUMBER"
fi

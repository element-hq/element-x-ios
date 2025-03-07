#!/bin/sh

source ci_common.sh

setup_xcode_cloud_environment

# Xcode Cloud shallow clones the repo. We need to deepen it to fetch tags, commit history and be able to rebase main on develop at the end of releases.
fetch_unshallow_repository

# Upload dsyms no matter the workflow
# Perform this step before releasing to github in case it fails.
bundle exec fastlane upload_dsyms_to_sentry dsym_path:"$CI_ARCHIVE_PATH/dSYMs"

generate_what_to_test_notes

if [ "$CI_WORKFLOW" = "Release" ]; then
    bundle exec fastlane release_to_github
    bundle exec fastlane prepare_next_release
elif [ "$CI_WORKFLOW" = "Nightly" ]; then
    bundle exec fastlane tag_nightly build_number:"$CI_BUILD_NUMBER"
fi

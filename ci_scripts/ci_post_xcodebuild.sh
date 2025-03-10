#!/bin/sh

source ci_common.sh

setup_xcode_cloud_environment

# Xcode Cloud shallow clones the repo. We need to deepen it to fetch tags, commit history and be able to rebase main on develop at the end of releases.
fetch_unshallow_repository

# Upload dsyms no matter the workflow
# Perform this step before releasing to github in case it fails.
bundle exec fastlane upload_dsyms_to_sentry dsym_path:"$CI_ARCHIVE_PATH/dSYMs"

echo "Script executed from: ${PWD}"

git=$(which git)

if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
  TESTFLIGHT_DIR_PATH=../TestFlight
  mkdir $TESTFLIGHT_DIR_PATH
  # Get the message of the last commit, set this as the What To Test text for this build on TestFlight
  git fetch --deepen 1 && git log -1 --pretty=format:"%s%+b" > $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
fi

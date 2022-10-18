#!/bin/sh

# Set the -e flag to stop running the script in case a command returns
# a nonzero exit code.
set -e

# Move to the project root
cd ..

if [[ -n $CI_ARCHIVE_PATH ]];
then
    bundle exec fastlane upload_dsyms_to_sentry dsym_path:"$CI_ARCHIVE_PATH/dSYMs"
fi
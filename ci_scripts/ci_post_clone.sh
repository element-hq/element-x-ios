#!/bin/sh

# Set the -e flag to stop running the script in case a command returns
# a nonzero exit code.
set -e

# move to the project root
cd ..

brew bundle

bundle config path vendor/bundle
bundle install --jobs 4 --retry 3

if [ "$CI_WORKFLOW" = "Nightly" ]; then
    bundle exec fastlane config_nightly
elif [ "$CI_WORKFLOW" = "Release" ]; then
    echo "Build release"
fi
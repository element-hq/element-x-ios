#!/bin/sh

# Set the -e flag to stop running the script in case a command returns
# a nonzero exit code.
set -e

# Prevent installing dependencies in system directories
echo 'export GEM_HOME=$HOME/gems' >>~/.bash_profile
echo 'export PATH=$HOME/gems/bin:$PATH' >>~/.bash_profile
export GEM_HOME=$HOME/gems
export PATH="$GEM_HOME/bin:$PATH"

# Move to the project root
cd ..

brew bundle --file=XcodeCloudBrewfile

gem install bundler --install-dir $GEM_HOME

bundle config path vendor/bundle
bundle install --jobs 4 --retry 3

if [ "$CI_WORKFLOW" = "Nightly" ]; then
    bundle exec fastlane config_nightly
elif [ "$CI_WORKFLOW" = "Release" ]; then
    echo "Build release"
fi
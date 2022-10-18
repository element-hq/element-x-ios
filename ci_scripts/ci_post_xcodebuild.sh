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

gem install bundler --install-dir $GEM_HOME

bundle config path vendor/bundle
bundle install --jobs 4 --retry 3

if [ "$CI_WORKFLOW" = "Release" ]; then
    bundle exec fastlane release_to_github
    bundle exec fastlane prepare_next_release
fi

if [[ -n $CI_ARCHIVE_PATH ]];
then
    bundle exec fastlane upload_dsyms_to_sentry dsym_path:"$CI_ARCHIVE_PATH/dSYMs"
fi
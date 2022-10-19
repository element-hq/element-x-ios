#!/bin/sh

# Set the -e flag to stop running the script in case a command returns
# a nonzero exit code.
set -e

# Prevent installing dependencies in system directories
echo 'export GEM_HOME=$HOME/.gem' >>~/.zshrc
echo 'export PATH=$GEM_HOME/bin:$PATH' >>~/.zshrc
echo 'export PATH="/usr/local/opt/ruby@2.7/bin:$PATH"' >> ~/.zshrc

export GEM_HOME=$HOME/.gem
export PATH=$GEM_HOME/bin:$PATH
export PATH="/usr/local/opt/ruby@2.7/bin:$PATH"

# Move to the project root
cd ..

# Things don't work well on the default ruby version. 
# We don't need all the other homebrew dependencies
brew install "ruby@2.7"

gem install bundler

bundle config path vendor/bundle
bundle install --jobs 4 --retry 3

if [ "$CI_WORKFLOW" = "Release" ]; then
    pip3 install -r requirements.txt # Install towncrier for generating changelogs

    bundle exec fastlane release_to_github
    bundle exec fastlane prepare_next_release
fi

if [[ -n $CI_ARCHIVE_PATH ]];
then
    bundle exec fastlane upload_dsyms_to_sentry dsym_path:"$CI_ARCHIVE_PATH/dSYMs"
fi
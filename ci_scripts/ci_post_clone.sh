#!/bin/sh

# Set the -e flag to stop running the script in case a command returns
# a nonzero exit code.
set -e

if [ "$CI_WORKFLOW" != "Nightly" ]; then
    # We only need to run post clone steps for nightlies
    exit 0
fi

# Prevent installing dependencies in system directories
echo 'export GEM_HOME=$HOME/.gem' >>~/.zshrc
echo 'export PATH=$GEM_HOME/bin:$PATH' >>~/.zshrc
echo 'export PATH="/usr/local/opt/ruby@2.7/bin:$PATH"' >> ~/.zshrc

export GEM_HOME=$HOME/.gem
export PATH=$GEM_HOME/bin:$PATH
export PATH="/usr/local/opt/ruby@2.7/bin:$PATH"

# Move to the project root
cd ..

brew bundle --file=XcodeCloudBrewfile

# Things don't work well on the default ruby version
brew install "ruby@2.7"

gem install bundler

bundle config path vendor/bundle
bundle install --jobs 4 --retry 3

if [ "$CI_WORKFLOW" = "Nightly" ]; then
    bundle exec fastlane config_nightly
fi
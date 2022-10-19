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

brew bundle --file=XcodeCloudBrewfile

gem install bundler

bundle config path vendor/bundle
bundle install --jobs 4 --retry 3

pip install -r requirements.txt

if [ "$CI_WORKFLOW" = "Nightly" ]; then
    bundle exec fastlane config_nightly
elif [ "$CI_WORKFLOW" = "Release" ]; then
    echo "Build release"
fi
#!/bin/sh

setup_xcode_cloud_environment () {
    # Return on failures
    # Fail when expanding unset variables
    # Trace each command before executing it
    set -eEu

    # Move to the project root
    cd ..

    # Prevent installing dependencies in system directories
    echo 'export GEM_HOME=$HOME/.gem' >>~/.zshrc
    echo 'export PATH=$GEM_HOME/bin:$PATH' >>~/.zshrc
    echo 'export PATH="/usr/local/opt/ruby@2.7/bin:$PATH"' >> ~/.zshrc
    echo 'export PATH="/Users/local/Library/Python/3.9/bin:$PATH"' >> ~/.zshrc

    export GEM_HOME=$HOME/.gem
    export PATH=$GEM_HOME/bin:$PATH
    export PATH="/usr/local/opt/ruby@2.7/bin:$PATH"
    export PATH="/Users/local/Library/Python/3.9/bin:$PATH"

    # Things don't work well on the default ruby version
    brew install ruby@2.7

    gem install bundler

    bundle config path vendor/bundle
    bundle install --jobs 4 --retry 3
}

install_xcode_cloud_brew_dependencies () {
    brew update && install xcodegen imagemagick
}

install_xcode_cloud_python_dependencies () {
    pip3 install towncrier # Install towncrier for generating changelogs
}

setup_github_actions_environment() {
    brew update && brew install xcodegen swiftformat git-lfs
    
    # brew "swiftlint" # Fails on the CI: `Target /usr/local/bin/swiftlint Target /usr/local/bin/swiftlint already exists`. Installed through https://github.com/actions/virtual-environments/blob/main/images/macos/macos-12-Readme.md#linters
    # brew "imagemagick" # Upgrading imagemagick has failed!

    bundle config path vendor/bundle
    bundle install --jobs 4 --retry 3

    xcodegen
}
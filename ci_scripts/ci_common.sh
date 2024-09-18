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
    echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
    echo 'export PATH="/Users/local/Library/Python/3.9/bin:$PATH"' >> ~/.zshrc

    export GEM_HOME=$HOME/.gem
    export PATH=$GEM_HOME/bin:$PATH
    export PATH="/usr/local/opt/ruby/bin:$PATH"
    export PATH="/Users/local/Library/Python/3.9/bin:$PATH"

    # Things don't work well on the default ruby version
    brew install ruby

    gem install bundler

    bundle config path vendor/bundle
    bundle install --jobs 4 --retry 3
}

install_xcode_cloud_brew_dependencies () {
    brew update && brew install xcodegen
    
    if [ "$CI_WORKFLOW" = "Nightly" ]; then
        brew install imagemagick@6
        brew link imagemagick@6 # imagemagick@6 is keg-only, which means it was not symlinked into /usr/local,
    fi
}

setup_github_actions_translations_environment() {
    unset HOMEBREW_NO_INSTALL_FROM_API
    export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1

    brew update && brew install swiftgen mint localazy/tools/localazy

    mint install Asana/locheck
}

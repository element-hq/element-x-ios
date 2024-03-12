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
    brew update && brew install xcodegen
    
    if [ "$CI_WORKFLOW" = "Nightly" ]; then
        brew install imagemagick@6
    fi
}

install_xcode_cloud_python_dependencies () {
    pip3 install towncrier # Install towncrier for generating changelogs
}

setup_github_actions_environment() {
    unset HOMEBREW_NO_INSTALL_FROM_API
    export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
    
    brew update && brew install xcodegen swiftformat git-lfs a7ex/homebrew-formulae/xcresultparser
    
    if [ "$CI_WORKFLOW" = "PR_BUILD" ]; then
        brew install imagemagick@6
    fi
    
    # brew "swiftlint" # Fails on the CI: `Target /usr/local/bin/swiftlint Target /usr/local/bin/swiftlint already exists`. Installed through https://github.com/actions/virtual-environments/blob/main/images/macos/macos-12-Readme.md#linters

    bundle config path vendor/bundle
    bundle install --jobs 4 --retry 3
}

setup_github_actions_translations_environment() {
    unset HOMEBREW_NO_INSTALL_FROM_API
    export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1

    brew update && brew install swiftgen mint localazy/tools/localazy

    mint install Asana/locheck
}

generate_what_to_test_notes() {
    if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
        TESTFLIGHT_DIR_PATH=TestFlight
        TESTFLIGHT_NOTES_FILE_NAME=WhatToTest.en-US.txt

        # Xcode Cloud shallow clones the repo, we need to manually fetch the tags
        git fetch --tags --quiet
        
        LATEST_TAG=""
        if [ "$CI_WORKFLOW" = "Release" ]; then
            # Use -v to invert grep, searching for non-nightlies
            LATEST_TAG=$(git tag --sort=-creatordate | grep -v 'nightly' | head -n1)
        elif [ "$CI_WORKFLOW" = "Nightly" ]; then
            LATEST_TAG=$(git tag --sort=-creatordate | grep 'nightly' | head -n1)
        fi

        if [[ -z "$LATEST_TAG" ]]; then
            echo "generate_what_to_test_notes: Failed fetching previous tag"
            return 0 # Continue even though this failed
        fi

        echo "generate_what_to_test_notes: latest tag is $LATEST_TAG"

        mkdir $TESTFLIGHT_DIR_PATH

        NOTES="$(git log --pretty='- %an: %s' "$LATEST_TAG"..HEAD)"

        echo "generate_what_to_test_notes: Generated notes:\n"$NOTES""

        echo "$NOTES" > $TESTFLIGHT_DIR_PATH/$TESTFLIGHT_NOTES_FILE_NAME
    fi
}
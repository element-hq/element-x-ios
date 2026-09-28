#!/bin/sh

# Return on failures
# Fail when expanding unset variables
# Trace each command before executing it
set -eEu

install_xcode_cloud_brew_dependencies () {
    brew update && brew install xcodegen pkl getsentry/tools/sentry-cli
}

setup_github_actions_environment() {
    xcode_select_for_github_actions
    
    unset HOMEBREW_NO_INSTALL_FROM_API
    export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
<<<<<<< HEAD

    # Tchap 
    # SwiftFormat est volontairement figé à une version précise pour éviter
    # que les nouvelles règles cassent la CI silencieusement.
    # Pour mettre à jour : changer SWIFTFORMAT_VERSION, lancer swiftformat . en local,
    # corriger les erreurs de formatage, puis committer le tout.
    SWIFTFORMAT_VERSION="0.59.1"

    brew update && brew install xcodegen swiftlint git-lfs pkl a7ex/homebrew-formulae/xcresultparser
    # :tchap: Installe swiftformat à la version exacte depuis les releases GitHub
    # install_swiftformat_head

    curl -sL "https://github.com/nicklockwood/SwiftFormat/releases/download/${SWIFTFORMAT_VERSION}/swiftformat.zip" -o /tmp/swiftformat.zip
    unzip -o /tmp/swiftformat.zip -d /tmp/swiftformat_bin
    # Overwrite le binaire pré-installé du runner au lieu de /usr/local/bin
    sudo cp /tmp/swiftformat_bin/swiftformat "$(which swiftformat)"
    rm -rf /tmp/swiftformat.zip /tmp/swiftformat_bin

    swiftformat --version
    # :tchap:end

=======
    
    brew update && brew install xcodegen swiftlint swiftformat git-lfs pkl
>>>>>>> release/26.09.2
}

setup_github_actions_translations_environment() {
    xcode_select_for_github_actions
    
    unset HOMEBREW_NO_INSTALL_FROM_API
    export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1

    brew update && brew install swiftgen mint localazy/tools/localazy

    mint install Asana/locheck
}

xcode_select_for_github_actions() {
    # We need to select it globally for our custom tools to use the same Xcode version.
    sudo xcode-select -s /Applications/Xcode_26.5.0.app
}

generate_what_to_test_notes() {
    if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
        TESTFLIGHT_DIR_PATH=TestFlight
        TESTFLIGHT_NOTES_FILE_NAME=WhatToTest.en-US.txt
        
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

fetch_unshallow_repository() {
    # Xcode Cloud shallow clones the repo. We need to deepen it to fetch tags, commit history and be able to rebase main on develop at the end of releases.
    git fetch --unshallow --quiet
}

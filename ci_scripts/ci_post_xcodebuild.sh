#!/bin/sh

setup_environment()

if [ "$CI_WORKFLOW" = "Release" ]; then
    install_python_dependencies()

    bundle exec fastlane release_to_github
    bundle exec fastlane prepare_next_release
fi

# Upload dsyms no matter the workflow
bundle exec fastlane upload_dsyms_to_sentry dsym_path:"$CI_ARCHIVE_PATH/dSYMs"
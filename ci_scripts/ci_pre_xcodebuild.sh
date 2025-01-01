#!/bin/sh

echo "Stage: PRE-Xcode Build is activated .... "

# Move to the place where the scripts are located.
# This is important because the position of the subsequently mentioned files depends of this origin.
cd $CI_PRIMARY_REPOSITORY_PATH/ci_scripts || exit 1

# Write a JSON File containing all the environment variables and secrets.
printf "{\"WALLET_CONNECT_PROJECT_ID\":\"%s\"}" "$WALLET_CONNECT_PROJECT_ID" >> ../Zero/SupportingFiles/zero_secrets.json

echo "Wrote zero_secrets.json file."

echo "Stage: PRE-Xcode Build is DONE .... "

exit 0

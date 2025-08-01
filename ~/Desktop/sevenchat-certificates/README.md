# SevenChat Certificates Repository

This repository contains encrypted certificates and provisioning profiles for the SevenChat iOS app.

## Structure
- `certs/` - Contains encrypted certificates
- `profiles/` - Contains encrypted provisioning profiles

## Usage
This repository is used by Fastlane to automatically manage certificates and provisioning profiles for iOS builds.

## Security
All certificates and profiles are encrypted using Fastlane Match. Only authorized team members can decrypt and use these files. 
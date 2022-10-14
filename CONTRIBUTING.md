# Contributing code to Matrix

Please read https://github.com/matrix-org/synapse/blob/master/CONTRIBUTING.md.

Element iOS support can be found in this room: [![Element iOS Matrix room #element-ios:matrix.org](https://img.shields.io/matrix/element-ios:matrix.org.svg?label=%23element-ios:matrix.org&logo=matrix&server_fqdn=matrix.org)](https://matrix.to/#/#element-ios:matrix.org)

## Setting up a development environment

### Xcode

We suggest using an Xcode version later than 13.2.1.

The Xcode project can be directly compiled after checkout through the shared ElementX scheme which includes the main application as well as the unit and UI tests.

The Xcode project itself is generated through [xcodegen](https://github.com/yonaskolb/XcodeGen) so any changes shouldn't be made directly to it but to the configuration files.

### Dependencies

Dependencies will be automatically fetched through the Swift Package Manager, including a release version of the MatrixRustSDK. If you encounter issues while resolving the package graph please attempt a cache reset through `File -> Packages -> Reset Package Caches`.

For instructions on how to setup the RustSDK in development mode please refer to the [matrix-rust-components-swift](https://github.com/matrix-org/matrix-rust-components-swift) repository.

### Tools

The project depends on some tools for the build process. These are all included in the `Brewfile` and can be easily installed by running

```
brew bundle
```

Git LFS is used to store UI test snapshots. After cloning the repo this can be configured by running

```
git lfs install
```

### Continuous Integration

ElementX uses Fastlane for running actions on the CI and tries to keep the configuration confined to either [fastlane](fastlane/Fastfile) or [xcodegen](project.yml). 

Please run `bundle exec fastlane` to see available options.

### Network debugging proxy

It's possible to debug the app's network traffic with a proxy server by setting the `HTTPS_PROXY` environment variable in the ElementX scheme to the proxy's address (e.g. localhost:8080 for mitmproxy).

## Pull requests

Please see our [pull request guide](https://github.com/vector-im/element-android/blob/develop/docs/pull_request.md).

## Implementing a new screen

New screen flows are currently using MVVM-Coordinator pattern. Please refer to the screen template under [Tools/Scripts/createScreen.sh](Tools/Scripts/createScreen.sh) to create a new screen or a new screen flow.

## Coding style

For Swift coding style we use [SwiftLint](https://github.com/realm/SwiftLint) to check some conventions at compile time (rules are located in the `.swiftlint.yml` file). 
Otherwise please have a look to [Apple Swift conventions](https://swift.org/documentation/api-design-guidelines.html#conventions). We are also using some of the conventions of [raywenderlich.com Swift style guide](https://github.com/raywenderlich/swift-style-guide).

We enforce the coding style by running checks on the CI for every PR through [Danger](Dangerfile.swift), [SwiftLint](.swiftlint.yml) and [SonarCloud](https://sonarcloud.io/project/overview?id=vector-im_element-x-ios)

We also gather coverage reports on every PR through [Codecov](https://app.codecov.io/gh/vector-im/element-x-ios) and will eventually start enforcing minimums.

## Thanks

Thank your for contributing to Matrix projects!
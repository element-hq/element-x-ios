# Contributing to Element X iOS

Before opening a PR please make sure that there is a well defined issue. When adding a new feature or updating the user interface, the issue **must** have input from our Product team outlining the desired solution.

Please note: [element-meta](https://github.com/element-hq/element-meta) is where we centralise all product level and cross platform requests. If the change you would like to make will create a disparity between platforms then there must also be a meta-issue before contributing.

Support can be found in [![Element X iOS Matrix room #element-x-ios:matrix.org](https://img.shields.io/matrix/element-x-ios:matrix.org.svg?label=%23element-x-ios:matrix.org&logo=matrix&server_fqdn=matrix.org)](https://matrix.to/#/#element-x-ios:matrix.org).

## Contributing code to Matrix

Please read https://github.com/element-hq/synapse/blob/master/CONTRIBUTING.md.

## Setting up a development environment

### Setup Project

It's mandatory to have [homebrew](https://brew.sh/) installed on your mac, and run after the checkout:

```
swift run tools setup-project
```

This will:
- Install various brew dependencies required for the project (like xcodegen).
- Set up git to use the shared githooks from the repo, instead of the default ones.
- Automatically run xcodegen for the first time.

### Xcode

We suggest using an Xcode version later than 15.0.1.

The Xcode project can be directly compiled through the shared Element X scheme which includes the main application as well as the unit and UI tests.

The Xcode project itself is generated through [xcodegen](https://github.com/yonaskolb/XcodeGen) so any changes shouldn't be made directly to it but to the configuration files.

### Dependencies

Dependencies will be automatically fetched through the Swift Package Manager, including a release version of the MatrixRustSDK. If you encounter issues while resolving the package graph please attempt a cache reset through `File -> Packages -> Reset Package Caches`.

To setup the RustSDK in local development mode run the following command

```
swift run tools build-sdk
```

This will clone a copy of the SDK if needed, build it for all supported architectures and configure Element X to use the built framework. To learn about additional options run

```
swift run tools build-sdk --help
```

### Tools

The project depends on some tools for the build process which are normally installed through `swift run tools setup-project`. Installing them manually though is as easy as copying what the [script does](https://github.com/element-hq/element-x-ios/blob/develop/Tools/Sources/SetupProject.swift)

```
brew install [...]
```

Git LFS is used to store UI and Preview test snapshots. `swift run tools setup-project` will already install it, however it can also be installed after a checkout by running:

```
git lfs install
```

### Snapshot Tests

If you make changes to the UI you may cause existing UI and Preview test snapshots to fail. The UITests run user flows and record snapshots while doing so using the settings defined under [checkEnvironments](https://github.com/element-hq/element-x-ios/blob/c29175d1f924e58b9646a200dbab0301fce3c258/UITests/Sources/Application.swift#L35-L37) while the PreviewTests use the settings defined in [PreviewTests.swift](https://github.com/element-hq/element-x-ios/blob/c29175d1f924e58b9646a200dbab0301fce3c258/PreviewTests/Sources/PreviewTests.swift#L18-L20). The snapshots are stored under `Sources/__Snapshots__` in their respective target's folder. 

### Githooks

The project uses its own shared githooks stored in the .githooks folder, you will need to configure git to use such folder, this is already done if you have run the setup tool with `swift run tools setup-project` otherwise you would need to run:

```
git config core.hooksPath .githooks
```

### Strings and Translations

The project uses Localazy and is sharing its translations with the Element X Android project: https://localazy.com/p/element

Please read the [Android docs](https://github.com/element-hq/element-x-android/blob/develop/tools/localazy/README.md) for more information about how this works. Note: On iOS we don't have the additional step of filtering strings per module.

Please do **not** manually edit the `Localizable.strings`, `Localizable.stringsdict` or `InfoPlist.strings` files! If your PR requires new strings to be added, add the `en` values to `Untranslated.strings`/`Untranslated.stringsdict` and one of the team will transfer them over to Localazy for you.

### Continuous Integration

Element X uses Fastlane for running actions on the CI and tries to keep the configuration confined to either [fastlane](fastlane/Fastfile) or [xcodegen](project.yml). 

Please run `bundle exec fastlane` to see available options.

### Network debugging proxy

It's possible to debug the app's network traffic with a proxy server by setting the `HTTPS_PROXY` environment variable in the Element X scheme to the proxy's address (e.g. localhost:8080 for mitmproxy).

## Pull requests

Please see our [pull request guide](https://github.com/element-hq/element-android/blob/develop/docs/pull_request.md).

## Implementing a new screen

New screen flows are currently using the MVVM-Coordinator pattern. Please refer to the [create screen template](Tools/Scripts/README.md#create-screen-templates) section.

## Changelog

Our [changelog](CHANGES.md) is automatically generated by GitHub, based on the PR title that you use when opening the issue. The changelog can be categorised by applying one of the [`pr-` labels](https://github.com/element-hq/element-x-ios/labels?q=pr-) to your PR. The mapping of Label → Section can be found in the [release.yml](.github/release.yml) file. The contribution will be automatically credited to your GitHub username.

## Coding style

For Swift coding style we use [SwiftLint](https://github.com/realm/SwiftLint) to check some conventions at compile time (rules are located in the `.swiftlint.yml` file). 
Otherwise please have a look to [Apple Swift conventions](https://swift.org/documentation/api-design-guidelines.html#conventions). We are also using some of the conventions of [raywenderlich.com Swift style guide](https://github.com/raywenderlich/swift-style-guide).

We enforce the coding style by running checks on the CI for every PR through [Danger](Dangerfile.swift), [SwiftLint](.swiftlint.yml), [SwiftFormat](.swiftformat) and [SonarCloud](https://sonarcloud.io/project/overview?id=element-x-ios)

We also gather coverage reports on every PR through [Codecov](https://app.codecov.io/gh/element-hq/element-x-ios) and will eventually start enforcing minimums.

## Thanks

Thank your for contributing to Matrix projects!

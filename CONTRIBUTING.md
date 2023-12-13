# Contributing code to Matrix

Please read https://github.com/matrix-org/synapse/blob/master/CONTRIBUTING.md.

Element iOS support can be found in this room: [![Element X iOS Matrix room #element-x-ios:matrix.org](https://img.shields.io/matrix/element-ios:matrix.org.svg?label=%23element-ios:matrix.org&logo=matrix&server_fqdn=matrix.org)](https://matrix.to/#/#element-x-ios:matrix.org)

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

The Xcode project can be directly compiled through the shared ElementX scheme which includes the main application as well as the unit and UI tests.

The Xcode project itself is generated through [xcodegen](https://github.com/yonaskolb/XcodeGen) so any changes shouldn't be made directly to it but to the configuration files.

### Dependencies

Dependencies will be automatically fetched through the Swift Package Manager, including a release version of the MatrixRustSDK. If you encounter issues while resolving the package graph please attempt a cache reset through `File -> Packages -> Reset Package Caches`.

To setup the RustSDK in local development mode run the following command

```
swift run tools build-sdk
```

This will clone a copy of the SDK if needed, build it for all supported architectures and configure ElementX to use the built framework. To learn about additional options run

```
swift run tools build-sdk --help
```

### Tools

The project depends on some tools for the build process. These are all included in the `Brewfile` and can be easily installed by running

```
brew bundle
```

Git LFS is used to store UI test snapshots. `swift run tools setup-project` will already install it, however it can also be installed after a checkout by running:

```
git lfs install
ln -s "$(which git-lfs)" "$(git --exec-path)/git-lfs"
```

### Snapshot Tests

If you make changes to the UI you may cause existing UI Snapshot tests to fail. You can run the snapshot tests using `UITests` target. To update the reference snapshots, delete them from `element-x-ios/UITests/Sources/__Snapshots__/Application` and run the tests again. 
These are the devices we store snapshots for that you will need to run against which need to use the iOS 16.4 simulator in en-US for consistency:
- iPhone 14
- iPad (9th generation)


### Githooks

The project uses its own shared githooks stored in the .githooks folder, you will need to configure git to use such folder, this is already done if you have run the setup tool with `swift run tools setup-project` otherwise you would need to run:

```
git config core.hooksPath .githooks
```

### Strings and Translations

The project uses Localazy and is sharing its translations with the ElementX Android project: https://localazy.com/p/element 

Please read the [Android docs](https://github.com/element-hq/element-x-android/blob/develop/tools/localazy/README.md) for more information about how this works. Note: On iOS we don't have the additional step of filtering strings per module.

### Continuous Integration

ElementX uses Fastlane for running actions on the CI and tries to keep the configuration confined to either [fastlane](fastlane/Fastfile) or [xcodegen](project.yml). 

Please run `bundle exec fastlane` to see available options.

### Network debugging proxy

It's possible to debug the app's network traffic with a proxy server by setting the `HTTPS_PROXY` environment variable in the ElementX scheme to the proxy's address (e.g. localhost:8080 for mitmproxy).

## Pull requests

Please see our [pull request guide](https://github.com/element-hq/element-android/blob/develop/docs/pull_request.md).

## Implementing a new screen

New screen flows are currently using the MVVM-Coordinator pattern. Please refer to the [create screen template](Tools/Scripts/README.md#create-screen-templates) section.

## Changelog

All changes, even minor ones, need a corresponding changelog / newsfragment
entry. These are managed by [Towncrier](https://github.com/twisted/towncrier).

To create a changelog entry, make a new file in the `changelog.d` directory
named in the format of `ElementXiOSIssueNumber.type`. The type can be one of the
following:

- `feature` for a new feature
- `change` for updates to an existing feature
- `bugfix` for bug fix
- `api` for an api break
- `i18n` for translations
- `build` for changes related to build, tools, CI/CD
- `doc` for updates to the documentation
- `wip` for anything that isn't ready to ship and will be enabled at a later date
- `misc` for other changes

This file will become part of our [changelog](CHANGES.md) at the next
release, so the content of the file should be a short description of your
change in the same style as the rest of the changelog. The file must only
contain one line. It can contain Markdown formatting. It should start with the
area of the change (screen, module, ...) and end with a full stop (.) or an
exclamation mark (!) for consistency.

Adding credits to the changelog is encouraged, we value your
contributions and would like to have you shouted out in the release notes!

For example, a fix for an issue #1234 would have its changelog entry in
`changelog.d/1234.bugfix`, and contain content like:

> Voice Messages: Fix a crash when sending a voice message. Contributed by
> Jane Matrix.

If there are multiple pull requests involved in a single bugfix/feature/etc,
then the content for each `changelog.d` file should be the same. Towncrier will
merge the matching files together into a single changelog entry when we come to
release.

There are exceptions on the `ElementXiOSIssueNumber.type` entry format. Even if
it is not encouraged, you can use:

- `pr-[PRNumber].type` for a PR with no related issue
- `x-nolink-[AnyNumber].type` for a PR with a change entry that will not have a link automatically appended. It must be used for internal project update only. `AnyNumber` should be a value that does not clash with existing files.

To preview the changelog for pending changelog entries, use:

```bash
$ towncrier build --draft --version 1.2.3
```

## Coding style

For Swift coding style we use [SwiftLint](https://github.com/realm/SwiftLint) to check some conventions at compile time (rules are located in the `.swiftlint.yml` file). 
Otherwise please have a look to [Apple Swift conventions](https://swift.org/documentation/api-design-guidelines.html#conventions). We are also using some of the conventions of [raywenderlich.com Swift style guide](https://github.com/raywenderlich/swift-style-guide).

We enforce the coding style by running checks on the CI for every PR through [Danger](Dangerfile.swift), [SwiftLint](.swiftlint.yml), [SwiftFormat](.swiftformat) and [SonarCloud](https://sonarcloud.io/project/overview?id=vector-im_element-x-ios)

We also gather coverage reports on every PR through [Codecov](https://app.codecov.io/gh/element-hq/element-x-ios) and will eventually start enforcing minimums.

## Thanks

Thank your for contributing to Matrix projects!
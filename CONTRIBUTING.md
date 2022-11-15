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

We enforce the coding style by running checks on the CI for every PR through [Danger](Dangerfile.swift), [SwiftLint](.swiftlint.yml) and [SonarCloud](https://sonarcloud.io/project/overview?id=vector-im_element-x-ios)

We also gather coverage reports on every PR through [Codecov](https://app.codecov.io/gh/vector-im/element-x-ios) and will eventually start enforcing minimums.

## Thanks

Thank your for contributing to Matrix projects!
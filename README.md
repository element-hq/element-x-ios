[![Element iOS Matrix room #element-x-ios:matrix.org](https://img.shields.io/matrix/element-x-ios:matrix.org.svg?label=%23element-x-ios:matrix.org&logo=matrix&server_fqdn=matrix.org)](https://matrix.to/#/#element-x-ios:matrix.org)
![GitHub](https://img.shields.io/github/license/element-hq/element-x-ios)

![Build Status](https://img.shields.io/github/actions/workflow/status/element-hq/element-x-ios/unit_tests.yml?style=flat-square)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/element-hq/element-x-ios)

[![codecov](https://codecov.io/gh/element-hq/element-x-ios/branch/develop/graph/badge.svg?token=AVIJB2MJU2)](https://codecov.io/gh/element-hq/element-x-ios)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=element-x-ios&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=element-x-ios)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=element-x-ios&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=element-x-ios)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=element-x-ios&metric=bugs)](https://sonarcloud.io/summary/new_code?id=element-x-ios)

# Element X iOS

ElementX iOS is a [Matrix](https://matrix.org/) iOS Client provided by [Element](https://element.io/).

The application is a total rewrite of [Element-iOS](https://github.com/element-hq/element-ios) using the [Matrix Rust SDK](https://github.com/matrix-org/matrix-rust-sdk) underneath and targetting devices running iOS 16+.

## Rust SDK

ElementX leverages the [Matrix Rust SDK](https://github.com/matrix-org/matrix-rust-sdk) through an FFI layer exposed as a [swift package](https://github.com/matrix-org/matrix-rust-components-swift) that the final client can directly import and use.

We're doing this as a way to share code between platforms and while we've seen promising results it's still in the experimental stage and bound to change.

## Status

This project is in work in progress. The app does not cover yet all functionalities we expect.

## Contributing

Please see our [contribution guide](CONTRIBUTING.md).

Come chat with the community in the dedicated Matrix [room](https://matrix.to/#/#element-x-ios:matrix.org).

## Build instructions

Please refer to the [setting up a development environment](CONTRIBUTING.md#setting-up-a-development-environment) section from the [contribution guide](CONTRIBUTING.md).

## Support

When you are experiencing an issue on ElementX iOS, please first search in [GitHub issues](https://github.com/element-hq/element-x-ios/issues)
and then in [#element-x-ios:matrix.org](https://matrix.to/#/#element-x-ios:matrix.org).
If after your research you still have a question, ask at [#element-x-ios:matrix.org](https://matrix.to/#/#element-x-ios:matrix.org). Otherwise feel free to create a GitHub issue if you encounter a bug or a crash, by explaining clearly in detail what happened. You can also perform bug reporting (Rageshake) from the Element application by shaking your phone or going to the application settings. This is especially recommended when you encounter a crash.

## Forking

Please read our [forking guide](docs/FORKING.md).

## Copyright & License

Copyright (c) 2022 - 2024 New Vector Ltd

Licensed under the AGPL-3.0-only (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

https://www.gnu.org/licenses/agpl-3.0.txt

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

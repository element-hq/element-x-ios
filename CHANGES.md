## Changes in 1.0.2 (2022-07-28)

✨ Features

- Implement rageshake service. ([#23](https://github.com/vector-im/element-x-ios/issues/23))
- Add filtering for rooms by name. ([#26](https://github.com/vector-im/element-x-ios/issues/26))
- Settings screen minimal implementation. ([#37](https://github.com/vector-im/element-x-ios/issues/37))
- Perform password login using the Rust authentication service. ([#40](https://github.com/vector-im/element-x-ios/issues/40))
- DesignKit: Add initial implementation of DesignKit to the repo as a Swift package. ([#43](https://github.com/vector-im/element-x-ios/issues/43))
- Room timeline: Add plain styler and add timeline option in settings screen. ([#92](https://github.com/vector-im/element-x-ios/issues/92))
- Implement and use background tasks. ([#99](https://github.com/vector-im/element-x-ios/issues/99))

🙌 Improvements

- Implement new ClientBuilder pattern for login ([#120](https://github.com/vector-im/element-x-ios/pull/120))
- Flatten the room list by removing the encrypted groups. ([#121](https://github.com/vector-im/element-x-ios/pull/121))
- Add AuthenticationService and missing UI tests on the flow. ([#126](https://github.com/vector-im/element-x-ios/pull/126))
- Room: Use bubbles in the timeline. ([#34](https://github.com/vector-im/element-x-ios/issues/34))
- Room: Add header view containing room avatar and encryption badge. ([#35](https://github.com/vector-im/element-x-ios/issues/35))
- Add the splash, login and server selection screens from Element iOS along with a UserSessionStore. ([#40](https://github.com/vector-im/element-x-ios/issues/40))
- DesignKit: Add DesignKit to the ElementX project, style the login screen with it and tint the whole app. ([#43](https://github.com/vector-im/element-x-ios/issues/43))
- Settings: Auto dismiss bug report screen and show a success indicator when bug report completed. ([#76](https://github.com/vector-im/element-x-ios/issues/76))
- Bug report: Add GH labels. ([#77](https://github.com/vector-im/element-x-ios/issues/77))
- Danger: Add a check for png files and warn to use SVG and PDF files. ([#87](https://github.com/vector-im/element-x-ios/issues/87))
- Add localizations to UI tests target and add some checks. ([#101](https://github.com/vector-im/element-x-ios/issues/101))

🐛 Bugfixes

- ElementInfoPlist: Use custom template for Info.plist. ([#71](https://github.com/vector-im/element-x-ios/issues/71))
- Add a sync limit of 20 timeline items and prefill rooms with this number of events when calculating the last message. ([#93](https://github.com/vector-im/element-x-ios/issues/93))

🧱 Build

- Add swiftformat to the project and run it for the first time. ([#129](https://github.com/vector-im/element-x-ios/pull/129))
- Use v0.0.1 of the DesignTokens package. ([#78](https://github.com/vector-im/element-x-ios/pull/78))
- Update to v0.0.2 of the DesignTokens package. ([#90](https://github.com/vector-im/element-x-ios/pull/90))
- Fix Danger's changelog detection. ([#74](https://github.com/vector-im/element-x-ios/issues/74))

🚧 In development 🚧

- Add a proof of concept implementation for login with OIDC. ([#42](https://github.com/vector-im/element-x-ios/issues/42))

Others

- Add Screen as a suffix to all screens and tidy up the template. ([#125](https://github.com/vector-im/element-x-ios/pull/125))
- Fix project urls in Towncrier configuration. ([#96](https://github.com/vector-im/element-x-ios/issues/96))

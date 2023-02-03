## Changes in 1.0.17 (2023-02-03)

🙌 Improvements

- Hardcode the sliding sync proxy to matrix.org for FOSDEM demo. ([#502](https://github.com/vector-im/element-x-ios/pull/502))
- Add different states for a room's last message to distinguish loading from loaded from unknown. ([#514](https://github.com/vector-im/element-x-ios/pull/514))
- Finish the design review ready for a public TestFlight. ([#430](https://github.com/vector-im/element-x-ios/issues/430))

🐛 Bugfixes

- Fixed a bug that recognised any amount in dollars as an untappable link. ([#500](https://github.com/vector-im/element-x-ios/issues/500))


## Changes in 1.0.15 (2023-01-26)

🙌 Improvements

- Add support for aliases to RoomProxy and bump the SDK version. ([#486](https://github.com/vector-im/element-x-ios/pull/486))

🐛 Bugfixes

- Show the date instead of the time in the room list when the last message is from yesterday or before. ([#484](https://github.com/vector-im/element-x-ios/pull/484))
- Prevent room timelines from becoming stale if the room drops out of the sliding sync window ([#448](https://github.com/vector-im/element-x-ios/issues/448))

🚧 In development 🚧

- Design update for first public TestFlight ([#430](https://github.com/vector-im/element-x-ios/issues/430))


## Changes in 1.0.14 (2023-01-20)

✨ Features

- Show state events in the timeline and (at least temporarily) on the home screen. ([#473](https://github.com/vector-im/element-x-ios/pull/473))

🙌 Improvements

- Logging: Redact Room/Message content and use MXLog.info in more places. ([#457](https://github.com/vector-im/element-x-ios/pull/457))
- Rooms: Mark rooms as read when opening/closing. ([#414](https://github.com/vector-im/element-x-ios/issues/414))

🐛 Bugfixes

- Prevent long room names from breaking the room navigation bar layout ([#388](https://github.com/vector-im/element-x-ios/issues/388))
- Fix room member details screen performance ([#421](https://github.com/vector-im/element-x-ios/issues/421))

🧱 Build

- DesignKit: Move into a sub-package as long term this package will live outside of this repo. ([#459](https://github.com/vector-im/element-x-ios/pull/459))


## Changes in 1.0.13 (2023-01-13)

✨ Features

- Add support for manually starting SaS verification flows and accepting remotely started ones ([#408](https://github.com/vector-im/element-x-ios/pull/408))
- Add support for new timeline items: loading indicators, stickers, invalid events and begining of history ([#424](https://github.com/vector-im/element-x-ios/pull/424))

🙌 Improvements

- Add MediaProvider tests. ([#386](https://github.com/vector-im/element-x-ios/pull/386))
- UserSession: Add unit tests. ([#390](https://github.com/vector-im/element-x-ios/pull/390))
- Use the links colour from Compound for links and avoid recomputing the RoomScreen view hierarchy while scrolling. ([#406](https://github.com/vector-im/element-x-ios/pull/406))
- Notification Manager: Replace completion handlers with async/await. ([#407](https://github.com/vector-im/element-x-ios/pull/407))
- Use QuickLook previews for video and present previews full screen (doesn't address gestures yet). ([#418](https://github.com/vector-im/element-x-ios/issues/418))

🐛 Bugfixes

- Use pagination indicators and start of room timeline items to update the view's pagination state. ([#432](https://github.com/vector-im/element-x-ios/pull/432))
- Prevent crash popups when force quitting the application ([#437](https://github.com/vector-im/element-x-ios/pull/437))
- Wait for logout confirmation before changing the app state ([#340](https://github.com/vector-im/element-x-ios/issues/340))
- Migrate and store session data in Application Support instead of Caches ([#389](https://github.com/vector-im/element-x-ios/issues/389))
- Video playback: Fix playback of encrypted video files. ([#419](https://github.com/vector-im/element-x-ios/issues/419))

🧱 Build

- UI Tests: Remove the French locale from the tests. ([#420](https://github.com/vector-im/element-x-ios/pull/420))
- Send all issues to the [EX board](https://github.com/orgs/vector-im/projects/43). ([#439](https://github.com/vector-im/element-x-ios/pull/439))


## Changes in 1.0.12 (2023-01-04)

No significant changes.


## Changes in 1.0.11 (2023-01-04)

🐛 Bugfixes

- Avoid the "Failed to load messages" popup when all messages have been loaded. ([#399](https://github.com/vector-im/element-x-ios/pull/399))
- Fix stuck timeline pagination because of too many membership events ([#394](https://github.com/vector-im/element-x-ios/issues/394))


## Changes in 1.0.10 (2022-12-22)

✨ Features

- Added timeline day separators and read markers ([#383](https://github.com/vector-im/element-x-ios/pull/383))
- Add retry decryption encrypted timeline item debug menu option ([#384](https://github.com/vector-im/element-x-ios/pull/384))
- Display an indicator if the network is currently unreachable ([#258](https://github.com/vector-im/element-x-ios/issues/258))

🐛 Bugfixes

- * moved the message delivery status outside of the main content and added it to the plain timeline as well
  * fixed glithcy scroll to bottom timeline button
  * simplified the emoji picker, double tapping a timeline item directly opens it now and added a context menu option. Linked it to rust side reaction sending
  * fixed cold cache seemingly not working (invalid rooms treated as empty)
  * made splash screen full screen
  * fixed connectivity indicator starting off as offline
  * added presentation detents on the NavigationStackCoordinator as they're not inherited from the child
  * fixed timeline item link tint colors
  * removed some unnecessary classes ([#381](https://github.com/vector-im/element-x-ios/pull/381))


## Changes in 1.0.9 (2022-12-16)

✨ Features

- Timeline: Sending and sent state for timeline messages. ([#27](https://github.com/vector-im/element-x-ios/issues/27))
- NSE: Configure target with commented code blocks. ([#243](https://github.com/vector-im/element-x-ios/issues/243))
- Timeline: Display images fullscreen when tapped. ([#244](https://github.com/vector-im/element-x-ios/issues/244))
- Implemented new SwiftUI based app navigation components ([#286](https://github.com/vector-im/element-x-ios/issues/286))
- Send messages on return. ([#314](https://github.com/vector-im/element-x-ios/issues/314))
- Implemented new user notification components on top of SwiftUI and the new navigation flows ([#315](https://github.com/vector-im/element-x-ios/issues/315))
- Implement a split screen layout for when running on iPad and MacOS ([#317](https://github.com/vector-im/element-x-ios/issues/317))
- Expose sliding sync proxy configuration URL on the server selection screen ([#320](https://github.com/vector-im/element-x-ios/issues/320))

🙌 Improvements

- Swift from a LazyVStack to a VStack for the timeline. ([#332](https://github.com/vector-im/element-x-ios/pull/332))
- Stop generating previews for light and dark colour schemes now that preview variants are a thing. ([#345](https://github.com/vector-im/element-x-ios/pull/345))
- Re-write the timeline view to be backed by a UITableView to fix scroll glitches. ([#349](https://github.com/vector-im/element-x-ios/pull/349))
- Re-write MXLogger in Swift. ([#166](https://github.com/vector-im/element-x-ios/issues/166))
- Timeline: Add a couple of basic tests to make sure the timeline is bottom aligned. ([#352](https://github.com/vector-im/element-x-ios/issues/352))

🐛 Bugfixes

- Fix a bug where the access token wasn't stored on macOS (Designed for iPad). ([#354](https://github.com/vector-im/element-x-ios/pull/354))
- Message Composer: Fix vertical padding with multiple lines of text. ([#305](https://github.com/vector-im/element-x-ios/issues/305))
- Reactions: Match alignment with the message to fix random floating reactions. ([#307](https://github.com/vector-im/element-x-ios/issues/307))
- Timeline: Fixed scrolling performance issues. ([#330](https://github.com/vector-im/element-x-ios/issues/330))
- Application: Fix background tasks & state machine crashes. ([#341](https://github.com/vector-im/element-x-ios/issues/341))

🧱 Build

- The Unit Tests workflow now fails when there are SwiftFormat errors. ([#353](https://github.com/vector-im/element-x-ios/pull/353))
- Tools: Add a command line tool to build a local copy of the SDK for debugging. ([#362](https://github.com/vector-im/element-x-ios/issues/362))

Others

- Setup tracing with a typed configuration and add some presets. ([#336](https://github.com/vector-im/element-x-ios/pull/336))


## Changes in 1.0.8 (2022-11-16)

✨ Features

- Timeline: Add playback support for video items. ([#238](https://github.com/vector-im/element-x-ios/issues/238))
- Timeline: Display file messages and preview them when tapped. ([#310](https://github.com/vector-im/element-x-ios/issues/310))

📄 Documentation

- Updated some documentation files. ([#312](https://github.com/vector-im/element-x-ios/issues/312))


## Changes in 1.0.7 (2022-11-10)

✨ Features

- Timeline: Display video messages. ([#237](https://github.com/vector-im/element-x-ios/issues/237))
- Timeline: Implement message editing via context menu. ([#252](https://github.com/vector-im/element-x-ios/issues/252))
- Added support for non-decryptable timeline items ([#291](https://github.com/vector-im/element-x-ios/issues/291))
- Added a timeline item context menu option for printing and showing their debug description ([#292](https://github.com/vector-im/element-x-ios/issues/292))

🐛 Bugfixes

- Fix identifier regexes: Fixes permalink action on timeline. ([#303](https://github.com/vector-im/element-x-ios/pull/303))
- Allow session restoration even while offline ([#239](https://github.com/vector-im/element-x-ios/issues/239))
- Timeline: Reset keyboard after a message is sent. ([#269](https://github.com/vector-im/element-x-ios/issues/269))
- Remove home screen list change animations ([#273](https://github.com/vector-im/element-x-ios/issues/273))


## Changes in 1.0.6 (2022-11-02)

🙌 Improvements

- Move Rust client operations into a dedicated concurrent queue, make sure not used on main thread. ([#283](https://github.com/vector-im/element-x-ios/pull/283))
- Rebuilt the timeline scrolling behavior on top of a more SwiftUI centric approach ([#276](https://github.com/vector-im/element-x-ios/issues/276))

🐛 Bugfixes

- Fix state machine crashes when backgrounding the app before the user session is setup ([#277](https://github.com/vector-im/element-x-ios/issues/277))
- Fixed blockquote and item layout when using the plain timeline ([#279](https://github.com/vector-im/element-x-ios/issues/279))


## Changes in 1.0.5 (2022-10-28)

✨ Features

- Enable e2e encryption support ([#274](https://github.com/vector-im/element-x-ios/pull/274))

🙌 Improvements

- Reduce code block font size and switch to SanFrancisco Monospaced ([#267](https://github.com/vector-im/element-x-ios/pull/267))
- Set a proper user agent ([#225](https://github.com/vector-im/element-x-ios/issues/225))


## Changes in 1.0.4 (2022-10-25)

🙌 Improvements

- Build with Xcode 14.0 and fix introspection on the timeline List. ([#163](https://github.com/vector-im/element-x-ios/issues/163))
- Include app name in default session display name ([#227](https://github.com/vector-im/element-x-ios/issues/227))

🐛 Bugfixes

- Fix strong reference cycle between RoomProxy and RoomTimelineProvider ([#216](https://github.com/vector-im/element-x-ios/issues/216))

📄 Documentation

- Add notes for how to debug the network traffic ([#223](https://github.com/vector-im/element-x-ios/issues/223))

Others

- Include changelog.d in Xcode project ([#218](https://github.com/vector-im/element-x-ios/issues/218))


## Changes in 1.0.3 (2022-09-23)

✨ Features

- UITests: Add screenshot tests. ([#9](https://github.com/vector-im/element-x-ios/issues/9))
- Logout from the server & implement soft logout flow. ([#104](https://github.com/vector-im/element-x-ios/issues/104))
- Implemented timeline item repyling ([#114](https://github.com/vector-im/element-x-ios/issues/114))
- Room: New bubbles design implementation. ([#177](https://github.com/vector-im/element-x-ios/issues/177))
- HomeScreen: Add user options menu to avatar and display name. ([#179](https://github.com/vector-im/element-x-ios/issues/179))
- Settings screen: Implement new design. ([#180](https://github.com/vector-im/element-x-ios/issues/180))

🙌 Improvements

- Use unstable MSC2967 values for OIDC scopes + client registration metadata updates. ([#154](https://github.com/vector-im/element-x-ios/pull/154))
- DesignKit: Update design tokens and add system colours to a local copy of ElementColors. ([#186](https://github.com/vector-im/element-x-ios/pull/186))
- DesignKit: Update fonts to match Figma. ([#187](https://github.com/vector-im/element-x-ios/pull/187))
- Include redacted events in the timeline. ([#199](https://github.com/vector-im/element-x-ios/pull/199))
- Rename RoomTimelineProviderItem to TimelineItemProxy for clarity. ([#162](https://github.com/vector-im/element-x-ios/issues/162))
- Style the session verification banner to match Figma. ([#181](https://github.com/vector-im/element-x-ios/issues/181))

🐛 Bugfixes

- Replace blocking detached tasks with Task.dispatch(on:). ([#201](https://github.com/vector-im/element-x-ios/pull/201))

🧱 Build

- Disable danger for external forks due to missing secret and run SwiftFormat as a pre-build step to fail early on CI. ([#157](https://github.com/vector-im/element-x-ios/pull/157))
- Run SwiftFormat as a post-build script locally, with an additional pre-build step on CI. ([#167](https://github.com/vector-im/element-x-ios/pull/167))
- Add validate-lfs.sh check from Element Android. ([#203](https://github.com/vector-im/element-x-ios/pull/203))
- Python 3 support for localizer script. ([#191](https://github.com/vector-im/element-x-ios/issues/191))

📄 Documentation

- CONTRIBUTING.md: Fix broken link to the `createScreen.sh` script. ([#153](https://github.com/vector-im/element-x-ios/pull/153))

🚧 In development 🚧

- Begin adding the same Analytics used in Element iOS. ([#106](https://github.com/vector-im/element-x-ios/issues/106))
- Add isEdited and reactions properties to timeline items. ([#111](https://github.com/vector-im/element-x-ios/issues/111))
- Add a redactions context menu item (disabled for now whilst waiting for SDK releases). ([#178](https://github.com/vector-im/element-x-ios/issues/178))

Others

- Add a pull request template. ([#156](https://github.com/vector-im/element-x-ios/pull/156))
- Use standard file headers. ([#150](https://github.com/vector-im/element-x-ios/issues/150))


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

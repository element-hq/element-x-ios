## Changes in 26.01.0 (2026-01-13)

### What's Changed

✨ Features
* Add a banner to encrypted rooms with visible history. by @kaylendog in https://github.com/element-hq/element-x-ios/pull/4738
* Run client store optimizations when upgrating versions by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4888

🙌 Improvements
* Change permissions screen is now responsive to the current user's power level by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4889
* Update the font style for placeholder messages (redacted/encrypted/unsupported). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4927
* Create room redesign and refactor by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4942

🐛 Bugfixes
* Improve canSee Sec & Privacy check. by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4835
* Revert "Add a banner to encrypted rooms with visible history. (#4738)" by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4850
* Fix voice message crashes on the Files tab of the Media and Files room section by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4839
* Unban correctly depends on kick PL + removed Change Settings permission by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4878
* Use the right check to show sec n privacy section in space settings by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4880
* Fix for leaving spaces with 0 joined rooms by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4883
* Fix for unbanning requiring both kick and ban permissions by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4925
* Fix icon alignment on placeholder message items. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4930
* Check permissions before indirectly updating desired settings in sec & privacy by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4926
* Fix how email addresses and links with trailing closing brackets are detected by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4949
* Hide the Translate action on macOS in favour of selecting the text. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4954

⚠️ API Changes
* Move BigIcon into Compound and add a new TitleAndIcon component. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4866

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4857
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4894
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4948
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4956

🧱 Build
* Have fastlane's xcbeautify use a special github actions formatter and reporter. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4864
* Various codecov and workflow action tweaks by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4863
* Use the quiet argument on Fastlane's xcbeautify output formatter by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4867
* Remove now unnecessary screen creation UI tests copying step by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4868
* Bump the calendar version ready for the next release by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4905

📄 Documentation
* Clarify product input requirements and how to add translations for contributions. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4849

🚧 In development 🚧
* Add a Link New Device screen (behind a feature flag). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4811
* Handle the edge case of one or more non parent joined spaces present in the existing allowed list by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4842
* Add a service and flow coordinator for the LinkNewDevice feature. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4859
* Tapping on the space screen title can open settings by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4890
* Add a banner to encrypted rooms with visible history. by @kaylendog in https://github.com/element-hq/element-x-ios/pull/4851
* Do not show history visible banner when the user cannot send messages. by @kaylendog in https://github.com/element-hq/element-x-ios/pull/4892
* Add a Log Files entry to the Usage sizes. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4921
* Add support for linking new devices in the QRCodeLoginScreen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4891
* Add tests for linking a new device. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4934
* Handle OIDC cancellation and workaround missing progress when linking a new device. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4935
* Empty spaces list screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4936

Others
* Remove `eraseToStream` now that `any AsyncSequence` is available to us. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4836
* Fix the integration test and improve the EncryptionSettings UI ones. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4838
* Move the room list sending state icons to the front of the latest event. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4840
* Update actions/cache action to v5 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4848
* Update actions/upload-artifact action to v6 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4855
* Remove unused imports by @mgcm in https://github.com/element-hq/element-x-ios/pull/4793
* Update codecov/test-results-action action to v1.2.1 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4862
* General tidy-up related to QR codes. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4865
* Bump the RustSDK to v25.12.17 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4870
* Update the foreground colour of BigIcon's default style. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4871
* Update history visible settings by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4861
* RTE update 2.41.0 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4872
* Final tweaks to the existing QR code screens to match the designs. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4874
* Update dependency apple/swift-argument-parser to from: "1.7.0" by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4879
* Tweaks to the Translate action. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4912
* Update the SDK by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4914
* Update dependency element-hq/compound-design-tokens to v6.5.0 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4920
* Update dependency element-hq/compound-design-tokens to v6.6.0 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4928
* Bump the Rust SDK to v26.01.06 by @kaylendog in https://github.com/element-hq/element-x-ios/pull/4933
* Update SDK to 26.01.09 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4941
* Update dependencies. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4940
* Update SDK to 26.01.13 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4953
* Rename SpaceRoomProxy to SpaceServiceRoom and stop proxying the struct. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4952

### New Contributors
* @mgcm made their first contribution in https://github.com/element-hq/element-x-ios/pull/4793

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.12.1...release/26.01.0

## Changes in 25.12.1 (2025-12-10)

### What's Changed

🙌 Improvements
* Updated edit details screen copies to reflect the usage of spaces. by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4809
* Use generic "update details..." copy when saving details change by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4818

🐛 Bugfixes
* Fix issues with the last message in the room list being cleared, going missing or being slow to update. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4834

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4830

🚧 In development 🚧
* Ask to join restricted/space members access option by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4812

Others
* Update GitHub Actions by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4824
* Bump the RustSDK to v25.12.07 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4825
* Set trust requirement even if `setEncryption` is `false`. by @kaylendog in https://github.com/element-hq/element-x-ios/pull/4823
* Bump the RustSDK to v25.12.09 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4832
* Update peter-evans/create-pull-request action to v8 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4833

### New Contributors
* @kaylendog made their first contribution in https://github.com/element-hq/element-x-ios/pull/4823

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.12.0...release/25.12.1

## Changes in 25.12.0 (2025-12-02)

### What's Changed

🙌 Improvements
* Room members list redesign by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4769
* Redesigned empty state for room members list by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4771
* Update the date separators to use "Today", "Yesterday" etc for messages in the past 7 days. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4785
* Show the send state in the room list. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4791
* Make multi selection accessory leading by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4795
* Update Compound's List header style to match our iOS 26 components. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4797
* Add the same unsaved changes alerts that Android has. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4803
* Add a specific notification body for space invites. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4808

🐛 Bugfixes
* Favour network over homeserver reachability when computing the offline indicator. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4805
* Fix missing read receipts in the timeline and edits in the room list. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4807

⚠️ API Changes
* Drop support for iOS 17 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4796

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4777
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4802

🦻 Accessibility
* Add accessibility hints for the send state in the room list. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4804

🧱 Build
* Bump the calendar version ready for the next release by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4782

🚧 In development 🚧
* Single space members access option by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4787
* Manage multiple spaces members access by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4798

Others
* Update the enterprise submodule. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4768
* Update actions/checkout action to v6 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4767
* Update peter-evans/create-pull-request action to v7.0.9 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4774
* Esperanto deleted and regenerated some preview tests by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4776
* Adopt the new latest event API. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4779
* Update dependency element-hq/compound-design-tokens to v6.4.1 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4780
* Update the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4792
* Update dependency element-hq/compound-design-tokens to v6.4.2 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4806


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.11.3...release/25.12.0

## Changes in 25.11.3 (2025-11-20)

### What's Changed

✨ Features
* Make the room "Security & privacy" screen available by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4725

🙌 Improvements
* Pop to coordinator by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4703
* Only offer to verify if a cross-signed device is available and improve the UX whilst waiting. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4710
* Use the call expiration timestamp to define the ringing window by @BillCarsonFr in https://github.com/element-hq/element-x-ios/pull/4652
* Permissions screen redesign by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4735
* Security and privacy redesign for spaces. by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4742
* Removed old notification sound by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4761

🐛 Bugfixes
* Fix: update members on power level changes in members list by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4707
* Correctly handle span tags and data attributes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4714
* Fix another bug where the app could crash on launch if the access token had expired. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4733
* Add proper support for nested lists in the AttributedStringBuilder by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4736
* Fix missing EmojiPicker emojis: stop having identifier conflicts between different categories by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4739
* Disable the cross-fade animation on the split view detail. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4737
* Disallow tapping on reply details in a pinned events timeline by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4757
* Separate `displayName` from `avatarDisplayName` when generating notification icons by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4758
* Corrected copies and layout for the security and privacy screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4765

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4721
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4753

🧱 Build
* Move danger/swift to an ubuntu runner and use the available action by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4715
* Fix the integration tests. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4723
* Update UI test snapshots. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4722
* Make sure the integration tests stop when running out of WAS retries 🙈 by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4730
* Don't assert specific devices for accessibility tests and use iOS 18 again. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4741
* Download en and en-US when running download-strings by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4743
* Attempt to fix a flakey call service test. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4746
* Run CI with Xcode 26.1 RC by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4672

🚧 In development 🚧
* Space Settings - Navigations by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4691
* Space Settings: Leave Room by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4700
* Handle threaded pinned events by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4704
* Manage rooms in space permission by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4740

Others
* Update the enterprise submodule. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4712
* Update actions/checkout action to v5 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4716
* Clarify how the different mapLibre URLs are used by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4724
* Silence some warnings. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4747
* Rename snapshots by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4756
* Update the design tokens package. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4759
* Switch the ClientProxy's `roomForIdentifier` state publisher await to the `staticRoomSummaryProvider` by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4755
* Add a DeveloperOptionsScreenHook. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4754
* Update SDK to 25.11.18 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4763
* Test NSE by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4762


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.11.0...release/25.11.3

## Changes in 25.11.2 (2025-11-19)

### What's Changed

✨ Features
* Make the room "Security & privacy" screen available by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4725

🙌 Improvements
* Pop to coordinator by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4703
* Only offer to verify if a cross-signed device is available and improve the UX whilst waiting. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4710
* Use the call expiration timestamp to define the ringing window by @BillCarsonFr in https://github.com/element-hq/element-x-ios/pull/4652
* Permissions screen redesign by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4735
* Security and privacy redesign for spaces. by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4742
* Removed old notification sound by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4761

🐛 Bugfixes
* Fix: update members on power level changes in members list by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4707
* Correctly handle span tags and data attributes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4714
* Fix another bug where the app could crash on launch if the access token had expired. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4733
* Add proper support for nested lists in the AttributedStringBuilder by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4736
* Fix missing EmojiPicker emojis: stop having identifier conflicts between different categories by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4739
* Disable the cross-fade animation on the split view detail. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4737
* Disallow tapping on reply details in a pinned events timeline by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4757
* Separate `displayName` from `avatarDisplayName` when generating notification icons by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4758

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4721
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4753

🧱 Build
* Move danger/swift to an ubuntu runner and use the available action by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4715
* Fix the integration tests. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4723
* Update UI test snapshots. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4722
* Make sure the integration tests stop when running out of WAS retries 🙈 by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4730
* Don't assert specific devices for accessibility tests and use iOS 18 again. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4741
* Download en and en-US when running download-strings by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4743
* Attempt to fix a flakey call service test. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4746
* Run CI with Xcode 26.1 RC by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4672

🚧 In development 🚧
* Space Settings - Navigations by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4691
* Space Settings: Leave Room by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4700
* Handle threaded pinned events by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4704
* Manage rooms in space permission by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4740

Others
* Update the enterprise submodule. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4712
* Update actions/checkout action to v5 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4716
* Clarify how the different mapLibre URLs are used by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4724
* Silence some warnings. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4747
* Rename snapshots by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4756
* Update the design tokens package. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4759
* Switch the ClientProxy's `roomForIdentifier` state publisher await to the `staticRoomSummaryProvider` by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4755
* Add a DeveloperOptionsScreenHook. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4754
* Update SDK to 25.11.18 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4763


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.11.0...release/25.11.2

## Changes in 25.11.1 (2025-11-12)

### What's Changed

✨ Features
* Make the room "Security & privacy" screen available by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4725

🙌 Improvements
* Pop to coordinator by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4703
* Only offer to verify if a cross-signed device is available and improve the UX whilst waiting. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4710

🐛 Bugfixes
* Fix: update members on power level changes in members list by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4707
* Correctly handle span tags and data attributes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4714
* Fix another bug where the app could crash on launch if the access token had expired. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4733

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4721

🧱 Build
* Move danger/swift to an ubuntu runner and use the available action by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4715
* Make sure the integration tests stop when running out of WAS retries 🙈 by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4730

🚧 In development 🚧
* Space Settings - Navigations by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4691
* Space Settings: Leave Room by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4700
* Handle threaded pinned events by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4704

Others
* Update the enterprise submodule. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4712
* Update actions/checkout action to v5 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4716
* Fix the integration tests. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4723
* Clarify how the different mapLibre URLs are used by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4724
* Update UI test snapshots. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4722


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.11.0...release/25.11.1

## Changes in 25.11.0 (2025-11-05)

### What's Changed

✨ Features
* Display members of a space by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4629

🙌 Improvements
* FF to enable/disable focussing the event on notification tap by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4698

🐛 Bugfixes
* Respect the order of joined spaces as defined by Element Web. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4663
* Fix a potential bug where the token couldn't be refreshed when the cached server `/versions` had expired. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4687
* Actually fix the bug where the token couldn't be refreshed when the cached `/versions` has expired. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4697
* Fix a bug where the timeline disappeared when VoiceOver was enabled. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4701

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4660
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4690

🧱 Build
* Add timeouts to our GitHub actions. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4669
* Stop repeating the simulator version throughout the Fastfile. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4677
* Bump the calendar version ready for the next release by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4666

🚧 In development 🚧
* Threaded notifications by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4644
* Test out a more prominent version of the new notification sound. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4667
* Space Settings Screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4670
* Space Settings UI tweaks by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4678
* Reuse `RoomDetailsScreenViewModel` for the `SpaceSettingsScreen` by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4684

Others
* Update enterprise copyright holders by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4654
* Update actions/upload-artifact action to v5 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4657
* Remove the integration tests `tapOnMenu` as it's the same as `tapOnButton` by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4656
* Update UI test snapshots by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4655
* Update dependency SFSafeSymbols/SFSafeSymbols to v7 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4659
* Remove the previous version of the AttributedStringBuilder by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4596
* Refactored room flow coordinator to use the members flow coordinator by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4665
* Introduce a StartChatFlowCoordinator instead of handing a navigation stack to the Screen Coordinator. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4674
* Update IDETemplateMacros.plist by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4692
* Update dependency element-hq/compound-design-tokens to v6.3.0 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4693


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.10.2...release/25.11.0

## Changes in 25.10.2 (2025-10-22)

### What's Changed

🐛 Bugfixes
* Fix the bloom on the space tab for real. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4604
* Thread tweaks by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4601
* Fix last owner not prompted to promote on leave by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4608
* Make the `SpaceRoomListProxy` publish its `SpaceRoomProxy` updates. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4607
* Prevent the system from automatically hiding the sidebar when backgrounding the app by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4610
* Convert the timeline's long press gesture recogniser to UIKit and prevent scroll view conflicts by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4615
* Handle the long press gesture states better and avoid multiple action invocations by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4626
* Use the editor toolbar role on iOS 26 instead of left aligning the header by frame. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4647

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4618
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4641

🧱 Build
* Only run Compound tests when files are changed in Compound. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4611
* Use the new Icon Composer .icon format. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4612
* Configure concurrency for Danger CI workflow by @t3chguy in https://github.com/element-hq/element-x-ios/pull/4646

Others
* Add unit test for the in-timeline space permalink handling by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4592
* Update dependency jpsim/Yams to from: "6.2.0" by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4599
* Add UI tests for accepting space invites. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4602
* The space tweaks continue! by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4606
* Update the enterprise submodule. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4609
* Update dependency apple/swift-argument-parser to from: "1.6.2" by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4613
* Some random tweaks made on a train 🚆 by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4636
* Update copyright holding and dates by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4640
* Update the enterprise submodule by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4643
* Update SDK to 25.10.21 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4642


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.10.0...release/25.10.2

## Changes in 25.10.1 (2025-10-14)

### What's Changed

🐛 Bugfixes
* Fix the bloom on the space tab for real. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4604
* Thread tweaks by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4601
* Fix last owner not prompted to promote on leave by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4608
* Make the `SpaceRoomListProxy` publish its `SpaceRoomProxy` updates. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4607
* Prevent the system from automatically hiding the sidebar when backgrounding the app by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4610
* Convert the timeline's long press gesture recogniser to UIKit and prevent scroll view conflicts by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4615

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4618

🧱 Build
* Only run Compound tests when files are changed in Compound. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4611
* Use the new Icon Composer .icon format. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4612

Others
* Add unit test for the in-timeline space permalink handling by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4592
* Update dependency jpsim/Yams to from: "6.2.0" by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4599
* Add UI tests for accepting space invites. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4602
* The space tweaks continue! by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4606
* Update the enterprise submodule. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4609


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.10.0...release/25.10.1

## Changes in 25.10.0 (2025-10-08)

### What's Changed

✨ Features
* Enable the next gen html parser and attributed string builder by default by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4537
* Enable the Space Exploration tab to discover and join new rooms. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4563
* Use the new notification sound. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4572
* Labs screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4573
* Implemented message forwarding for media previews and media timelines by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4579

🙌 Improvements
* Update the strings for the device verification flow by @andybalaam in https://github.com/element-hq/element-x-ios/pull/4553
* Clear cache on changing the threads FF by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4581
* New divider color for iOS 26 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4583

🐛 Bugfixes
* Improve ElementCall timeout detection by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4536
* Prevent the gradient background from being incorrectly rendered everywhere the placeholder screen is used by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4543
* Order out of order ordered list ordering order by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4531
* Fix #4528 - Prevent the OnboardingFlowCoordinator from interfering with recovery setup by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4559
* More iOS 26 tweaks by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4556
* Fix for permalinks not working by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4562
* Fix for the settings badge being clipped in the home screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4560
* A couple of small tweaks. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4569
* Make the space list bloom height match the room list. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4585

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4550
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4575
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4594

🧱 Build
* Update ruby depdendencies by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4539
* iOS 26 support and tweaks by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4498
* Adjust project and CI workflows to work on Xcode 26 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4523
* Have the nightly label actually fit the icon by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4547
* Switch all workflow runners back to macos-15 in hope that it will require less ram and won't time out by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4552
* Bump the calendar version ready for the next release by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4557

🚧 In development 🚧
* Add some new space properties. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4544
* Show space invites in the room list. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4545
* Accept space invites from a home screen cell. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4554
* Permalink from/to threads by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4565
* Implement the flow for leaving a space. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4568
* Add the spaces feature announcement sheet. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4571
* Minor space tweaks by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4577
* Add support for space rooms on the JoinRoomScreen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4582
* More space tweaks by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4584
* Even more space tweaks by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4588
* Handle in-timeline permalinks to spaces by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4587

Others
* Properly use the new `hideBrandChrome` in the `AuthenticationStartLogo` by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4538
* Move Compound iOS into the project. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4548
* Update acknowledgments with resolved names. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4555
* Update sdk to 25.10.07-2 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4586
* Use the space room name computed by the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4589


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.09.12...release/25.10.0

## Changes in 25.09.12 (2025-09-23)

### What's Changed

✨ Features
* Element Call: Send rtc.decline event when incoming call is declined by @BillCarsonFr in https://github.com/element-hq/element-x-ios/pull/4499
* Automatically clear temporary folders whenever migrating versions  by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4518
* Listen to call decline to stop ringing when declined from other device by @BillCarsonFr in https://github.com/element-hq/element-x-ios/pull/4505
* Add an app setting to disable rendering the chrome around the app logo/brand by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4526

🙌 Improvements
* Show a modal dialog while inviting people to rooms by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4508

🐛 Bugfixes
* Revert "Add intent system to widget URL creation. (#4427)" by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4504
* Fix traling new lines appearing in attributed string when sending text separated by 2 new lines by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4506

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4509
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4530

🚧 In development 🚧
* Add support for joining rooms from a space. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4501
* RoomAvatar in thread timeline by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4516
* Add the JoinRoomScreen into the SpaceFlowCoordinator. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4513
* Implement link previews for text messages using Apple's LinkPreview framework by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4520

Others
* Add the intent system back to call widget URL creation. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4511
* Various UI tweaks by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4514
* Update the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4517
* Update the SDK and Element Call. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4522
* Update the SDK and Element Call. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4527


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.09.3...release/25.09.12

## Changes in 25.09.4 (2025-09-12)

### What's Changed

🐛 Bugfixes
* Revert "Add intent system to widget URL creation. (#4427)" by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4504

🚧 In development 🚧
* Add support for joining rooms from a space. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4501


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.09.3...release/25.09.4

## Changes in 25.09.3 (2025-09-11)

### What's Changed

🐛 Bugfixes
* Fix stripping location data away from raw images when processing them for upload by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4497
* Await user session migrations rather than launching a task. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4502

🚧 In development 🚧
* Tweak attributed string formatting by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4496

Others
* Update the Enterprise submodule. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4495
* Add intent system to widget url creation. by @Copilot in https://github.com/element-hq/element-x-ios/pull/4427


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.09.2...release/25.09.3

## Changes in 25.09.2 (2025-09-09)

### What's Changed

✨ Features
* MediaTimelinePreviewDetails can now be opened by long pressing in the media timeline by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4474

🙌 Improvements
* Increase line limit for name in FileRoomTimelineView by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4470

🐛 Bugfixes
* Fix some retain cycles that could keep the Client(Proxy) alive when clearing the cache. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4462
* Address the real lifetime issue of the SDK's `Client` by making `Context.mediaProvider` weak. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4466
* Use the SDK's offline detection everywhere (except for restarting the sync loop). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4472

⚠️ API Changes
* Introduce flow parameters to simplify dependencies for child flows. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4448
* Dependency Refactor by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4450
* Use the Emoji/Map/Poll view models. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4458

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4454
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4479

🦻 Accessibility
* A11y audit improvements and fixes by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4457
* A11y timeout announcement for verification request, hardcoded to 1 minute by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4467

🚧 In development 🚧
* Hide the tab bar when pushing screens on iPhone as requested by the designs. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4444
* Use the SDK's SpaceService, SpaceRoom and SpaceRoomList. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4455
* Fix a bug where invites would be hidden when the Low Priority feature is enabled. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4461
* Allow joined rooms to be pushed within a space. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4460
* Add a migration to expire sync sessions so that m.space.* state is up to date. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4482

Others
* Tweaks discovered when using Compound overrides. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4456
* Move call presentation from the chats flow into the user session flow. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4459
* Update actions/github-script action to v8 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4471
* Fix proxies by reverting the change that introduced schemes. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4481
* Revert weak media provider by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4483
* Add a new way of parsing HTML data and generating AttributedStrings by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4449

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.09.0...release/25.09.2

## Changes in 25.09.0 (2025-08-27)

### What's Changed

✨ Features
* Fix document picker tint colors, remove multi-selection feature flag by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4424

🙌 Improvements
* Make the room list filters smaller. by @amshakal in https://github.com/element-hq/element-x-ios/pull/4432
* Improve global proxy detection, building and logging. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4440

🐛 Bugfixes
* Only use the Element Call timeoutTask for room calls. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4417
* Configure the video camera picker to record in high quality by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4423
* Improve supported share types by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4428
* Preserve the user chosen order when uploading multiple media files by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4436

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4422
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4438

🧱 Build
* Bump the calendar version ready for the next release by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4441

🚧 In development 🚧
* Add a Low Priority room filter behind a feature flag. by @Copilot in https://github.com/element-hq/element-x-ios/pull/4394
* Add a feature flag for spaces. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4429
* Space flow improvements. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4430

Others
* Update the SDK, handle API breaks. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4418
* Add a couple of logs to debug badge counts. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4425
* Remove unnecessary awaits on RoomFlowCoordinator.init. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4434
* Tidy up some logs that have a prefix. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4443
* Update the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4445
* Update Element Call to 0.15.0. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4446

### New Contributors
* @amshakal made their first contribution in https://github.com/element-hq/element-x-ios/pull/4432

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.08.5...release/25.09.0

## Changes in 25.08.5 (2025-08-15)

### What's Changed

🐛 Bugfixes
* Fix a bug when a compact split view doesn't react to a change of root coordinator in the sidebar. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4393
* Add a workaround to include some via parameters for room v12 tombstone links. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4413
* Fix a bug where the image upload screen was unintentionally dismissed for some failures. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4414
* Fix some app route navigation bugs. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4415

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4398

🚧 In development 🚧
* Add a SpaceExplorerFlowCoordinator. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4383
* Move the Settings flow from the Chats flow up one level to the UserSession flow. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4390
* Add `SpaceRoomCell` & `Space…ProxyProtocols` and use them on the `SpaceListScreen`. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4404
* Add a SpaceScreen for listing rooms and subspaces within a space. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4412

Others
* Label rageshakes from macOS and report the right operating system. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4392
* Remove unreachable guard condition in String.asciified() by @Copilot in https://github.com/element-hq/element-x-ios/pull/4395
* Update dependency jpsim/Yams to from: "6.1.0" by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4397
* Update Roles & Permissions UI test snapshots. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4399
* Update actions/checkout action to v5 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4401
* Update the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4405
* Remove the share_pos developer option. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4406

### New Contributors
* @Copilot made their first contribution in https://github.com/element-hq/element-x-ios/pull/4395

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.08.3...release/25.08.5

## Changes in 25.08.4 (2025-08-12)

### What's Changed

🐛 Bugfixes
* Fix a bug when a compact split view doesn't react to a change of root coordinator in the sidebar. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4393

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4398

🚧 In development 🚧
* Add a SpaceExplorerFlowCoordinator. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4383
* Move the Settings flow from the Chats flow up one level to the UserSession flow. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4390

Others
* Label rageshakes from macOS and report the right operating system. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4392
* Remove unreachable guard condition in String.asciified() by @Copilot in https://github.com/element-hq/element-x-ios/pull/4395
* Update dependency jpsim/Yams to from: "6.1.0" by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4397
* Update Roles & Permissions UI test snapshots. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4399
* Update actions/checkout action to v5 by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4401

### New Contributors
* @Copilot made their first contribution in https://github.com/element-hq/element-x-ios/pull/4395

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.08.3...release/25.08.4

## Changes in 25.08.3 (2025-08-07)

### What's Changed

✨ Features
* Last Owner should edit admins, and not leave when is last by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4372


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.08.2...release/25.08.3

## Changes in 25.08.2 (2025-08-05)

### What's Changed

🐛 Bugfixes
* Fix filtering of non spaces by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4384


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.08.1...release/25.08.2

## Changes in 25.08.1 (2025-08-05)

### What's Changed

🙌 Improvements
* Re-enable share_pos persistance. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4355
* Update message composer design for unencrypted rooms by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4361
* Use the maxUploadSize in the media upload screen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4359
* SDK Update + PowerLevels API update by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4366
* Restore permissions to creator and display them as owners in the list by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4369

🐛 Bugfixes
* Fix the user defaults key used for the developer options. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4328
* Delegate the sending of call notifications to Element Call by @robintown in https://github.com/element-hq/element-x-ios/pull/4370
* Update EC and the SDK to fix call notification issues by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4382

⚠️ API Changes
* Refactor Rageshake URL overrides and Target configuration. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4337
* Update the default logs directory and allow collection from elsewhere. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4352
* Stop showing the sliding sync proxy alert to any remaining proxy users. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4367
* Handle `TimelineDiff` as an enum with associated values. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4379

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4334
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4357
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4381

🦻 Accessibility
* A11y test detected improvements by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4340

🧱 Build
* Fix the flakey preview tests. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4329
* Accessibiliy Tests part 2 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4325
* Bump the calendar version ready for the next release by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4363

🚧 In development 🚧
* Adopt new thread sending APIs by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4344
* Add support for Space avatars. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4362
* Multi file uploads by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4358
* Add a TabView to the root of the UserSession flow and refactor out a new Chats flow. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4368
* Implement tab bar badges, visibility and selection. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4373
* Initial setup for the SpaceListScreen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4380

Others
* Use a Task instead of a DispatchQueue to help fix the flakey observation tests. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4321
* Merge the AuthenticationService with the QRCodeLoginService. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4323
* Show an alert when entering an account provider that requires Element Pro. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4326
* Make the remote settings hook usable within the app extensions. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4342
* Add a TracingHook. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4345
* Refactor LoggingTests utilising Rust's new ability to redirect log files at runtime. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4353
* Add some logs to help debug waiting for rooms. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4360


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.07.2...release/25.08.1

## Changes in 25.08.0 (2025-07-31)

### What's Changed

🙌 Improvements
* Re-enable share_pos persistance. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4355
* Update message composer design for unencrypted rooms by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4361
* Use the maxUploadSize in the media upload screen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4359
* SDK Update + PowerLevels API update by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4366

🐛 Bugfixes
* Fix the user defaults key used for the developer options. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4328

⚠️ API Changes
* Refactor Rageshake URL overrides and Target configuration. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4337
* Update the default logs directory and allow collection from elsewhere. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4352
* Stop showing the sliding sync proxy alert to any remaining proxy users. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4367

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4334
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4357

🦻 Accessibility
* A11y test detected improvements by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4340

🧱 Build
* Fix the flakey preview tests. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4329
* Accessibiliy Tests part 2 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4325
* Bump the calendar version ready for the next release by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4363

🚧 In development 🚧
* Adopt new thread sending APIs by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4344
* Add support for Space avatars. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4362
* Multi file uploads by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4358

Others
* Use a Task instead of a DispatchQueue to help fix the flakey observation tests. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4321
* Merge the AuthenticationService with the QRCodeLoginService. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4323
* Show an alert when entering an account provider that requires Element Pro. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4326
* Make the remote settings hook usable within the app extensions. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4342
* Add a TracingHook. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4345
* Refactor LoggingTests utilising Rust's new ability to redirect log files at runtime. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4353
* Add some logs to help debug waiting for rooms. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4360


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.07.2...release/25.08.0

## Changes in 25.07.2 (2025-07-15)

### What's Changed

🙌 Improvements
* Update and enable the new bloom style on the home screen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4291
* Change the order of timeline media visibility UI by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4294

🐛 Bugfixes
* Fix some panics caused by SDK order assertions. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4281
* Fix a bug with switching to bluetooth earphones during a call. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4285
* Fix the contrast on mention pills. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4313
* Fix a sync performance regression. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4324

⚠️ API Changes
* Adopt StateStoreViewModelV2 in more screens. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4275

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4290
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4293
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4318

🦻 Accessibility
* Group emojis accessibility in session verification screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4296
* Added a11y labels to the home screen cell notification symbols by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4298
* A11y pinned items improvement by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4300
* Hide accessibility of empty section by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4302
* Accessibility label for editing the avatar by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4304
* Add the sender name to VoiceOver for poll titles by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4306
* A11y: added a hint to inform the user that max selections have been reached by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4308
* Announce session verification request as time limited by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4310

🧱 Build
* Update the project for Xcode 16.4 by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4277
* Automatic Accessibility Audits on previews part 1 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4322

📄 Documentation
* Update to the status and clarifications with respect to the legacy app. by @mxandreas in https://github.com/element-hq/element-x-ios/pull/4316

🚧 In development 🚧
* Add support for threaded read receipts by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4288

Others
* Update dependency apple/swift-argument-parser to from: "1.6.1" by @renovate[bot] in https://github.com/element-hq/element-x-ios/pull/4278
* Update Element Call to the actual release of 0.13.0. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4279
* Add a few more labels when sending a rageshake. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4284
* Update the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4286
* Update Compound and add some new snapshot tests. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4311
* FF for enabling share pos and defaults to `false` by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4312
* Use the timeline when marking a room as read by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4319
* Update the SDK and build a client before logging in with a QR code. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4320

### New Contributors
* @mxandreas made their first contribution in https://github.com/element-hq/element-x-ios/pull/4316

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.07.0...release/25.07.2

## Changes in 25.07.1 (2025-07-04)

### What's Changed

🐛 Bugfixes
* Fix some panics caused by SDK order assertions. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4281
* Fix a bug with switching to bluetooth earphones during a call. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4285

⚠️ API Changes
* Adopt StateStoreViewModelV2 in more screens. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4275

🧱 Build
* Update the project for Xcode 16.4 by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4277

Others
* Update dependency apple/swift-argument-parser to from: "1.6.1" by @renovate in https://github.com/element-hq/element-x-ios/pull/4278
* Update Element Call to the actual release of 0.13.0. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4279
* Add a few more labels when sending a rageshake. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4284
* Update the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4286


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.07.0...release/25.07.1

## Changes in 25.07.0 (2025-07-01)

### What's Changed

✨ Features
* Advertise support for `matrix` as a URL scheme. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4236

🙌 Improvements
* Adopt room info power levels by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4245
* Adopt new `canOwnUser*` power level methods instead of the throwing ones by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4247
* EC: handle back navigation from the webview by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4250

🐛 Bugfixes
* Proper error handling when trying to accept invalid invites by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4232
* Fix a crash when attempting to send a bug report with excessively large logs. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4243
* Fix media previews in private room notifications and pagination on upgraded rooms. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4246
* Be more lenient with the power levels by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4261
* Fix earpiece button visibility in Element Call. by @toger5 in https://github.com/element-hq/element-x-ios/pull/4263
* Attempt to fix message composer layout crashes when running as an iPad app on MacOS by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4264

⚠️ API Changes
* Support runtime customisation of the rageshake URL. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4267

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4240
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4268

🦻 Accessibility
* Add View Avatar a11y label by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4253
* Use the close formatting option a11y label by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4254
* a11y poll improvements by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4255
* a11y improvement for removing a selected user by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4256
* voice over focuses title when it changes in session verification view by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4258
* a11y added a label to the remove all filters button by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4259
* Stop VoiceOver from reading the screen behind the current call. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4265
* Added a11y isHeader to the security section list row by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4266

🧱 Build
* Use mock log files for the BugReportScreenViewModelTests. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4257
* Make the BuildSDK tool an AsyncParsableCommand and avoid help showing up after the command is run by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4260
* Fix the calver workflow. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4274
* Bump the calendar version ready for the next release by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4273

🚧 In development 🚧
* EC Timeout if it doesn't respond after 30 seconds by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4237

Others
* Refactor how we deal with user permissions. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4235
* Expose isLiveKitRTCSupported on the ClientProxy. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4238
* Update dependency jpsim/Yams to from: "6.0.2" by @renovate in https://github.com/element-hq/element-x-ios/pull/4244
* Replace the Report a Problem button with the app's version on the start screen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4262
* Fix flakey AuthenticationService test. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4270
* Update dependency apple/swift-argument-parser to from: "1.6.0" by @renovate in https://github.com/element-hq/element-x-ios/pull/4271
* Updated SDK to 25.07.01 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4276

### New Contributors
* @toger5 made their first contribution in https://github.com/element-hq/element-x-ios/pull/4263

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.06.5...release/25.07.0

## Changes in 25.06.5 (2025-06-19)

### What's Changed

🐛 Bugfixes
* Stop failing bug reports when the reportURL is omitted. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4221
* Hide timeline item actions that the user's power level does not allow by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4227
* Fix thread summaries being shown when the thread feature flag was disabled. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4228
* Fix MediaTimeline screen header iOS 26 crash, update remaining version predicates. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4229

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4225

🧱 Build
* Add a section for pr-a11y in the release notes. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4223
* Run Xcode select on the Translations and CalVer workflows. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4224

Others
* Update ui tests for the poll form screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4226
* Bump various dependencies by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4216
* Move all Introspect VersionPredicates into Compound to have them all in the same place. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4230


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.06.4...release/25.06.5

## Changes in 25.06.4 (2025-06-18)

### What's Changed

✨ Features
* Thread aware drafting by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4197

🐛 Bugfixes
* Fixes #4180 - Prevent room header autolayout crashes on iOS 26. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4191
* Bump Compound and prevent Introspect from breaking on newer OS versions. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4203
* Fix OS 26 crashes when not running a development build by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4217

🚧 In development 🚧
* Allow sending locations within threads and render the number of replies in their summaries. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4192

Others
* Update dependency jpsim/Yams to from: "6.0.1" by @renovate in https://github.com/element-hq/element-x-ios/pull/4189
* Add state to the accessibility label of RTE formatting buttons by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4194
* Exclude protocol files from code coverage checks. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4196
* Improved the accessibility in PollFormScreen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4200
* Focus voice over automatically when focussing a timeline event by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4206
* Improved a11y in `CollapsibleRoomTimelineView` by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4208
* Improved reactions a11y by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4215
* Flip the timeline for voice over users by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4212
* Update the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4220


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.06.3...release/25.06.4

## Changes in 25.06.3 (2025-06-11)

### What's Changed

✨ Features
* Add a developer option for history sharing on invite by @richvdh in https://github.com/element-hq/element-x-ios/pull/4172

🐛 Bugfixes
* Send .`fullyRead` marker when navigating out of the room by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4177
* Correct the bug report service submission URL after updating how secrets are configured by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4186

🚧 In development 🚧
* Threaded timeline composer by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4168
* Support for sending media in threads by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4183

Others
* Update dependency fastlane to v2.228.0 by @renovate in https://github.com/element-hq/element-x-ios/pull/4181
* Add a RoomScreenHook. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4175
* Hide accesibility for decorative onboarding image by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4178
* Various thread tweaks by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4182
* update SDK to 25.06.11 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4187

### New Contributors
* @richvdh made their first contribution in https://github.com/element-hq/element-x-ios/pull/4172

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.06.2...release/25.06.3

## Changes in 25.06.2 (2025-06-06)

### What's Changed

🐛 Bugfixes
* Fix subsequent media upload dialogue presentations  by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4176


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.06.1...release/25.06.2

## Changes in 25.06.1 (2025-06-06)

### What's Changed

✨ Features
* EC: Native switch for audio outputs/inputs and earpiece by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4136
* Tombstoned and upgraded rooms implementation by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4169

🙌 Improvements
* Allow multiple room info updates when receiving a call before deciding the room doesn't have an active call anymore by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4171

🧱 Build
* Automatically open a PR to bump the calver by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4167

Others
* updated EC to 0.12.2 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4174


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.06.0...release/25.06.1

## Changes in 25.06.0 (2025-06-03)

### What's Changed

✨ Features
* Setup the new RustSDK sentry integration by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4145
* Handle media previews and invite avatars through the account data by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4142
* Adopt the new deduplicate room versions room list filter. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4160
* Support for experimental MSC4286 to not render external payment details by @hughns in https://github.com/element-hq/element-x-ios/pull/4099

🙌 Improvements
* Fetching room tweaks by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4146

🐛 Bugfixes
* Fix a couple of crashes on macOS from a missing environment object. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4153

⚠️ API Changes
* Adopt StateStoreViewModelV2 in the remaining settings screens. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4158

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4150
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4162

🧱 Build
* Make sure UI tests are run to completion on the remaining device, even if the other one fails. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4164
* Bump the version to 25.06 for the next release. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4165

🚧 In development 🚧
* Setup threaded timeline actions by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4157

Others
* Adopt latest timeline API changes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4140
* Update codecov/test-results-action action to v1.1.1 by @renovate in https://github.com/element-hq/element-x-ios/pull/4143
* Various timeline code improvements by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4144
* Add a developer option that hides notification alerts when a sound wouldn't be played. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4147
* Bump the SDK to v25.05.26-2 and update the breaking changes following the RoomListItem removal by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4148
* Update SDK to 25.05.27 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4151
* Update the enterprise submodule by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4152
* Updated EC and Sentry by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4154
* Update dependency apple/swift-argument-parser to from: "1.5.1" by @renovate in https://github.com/element-hq/element-x-ios/pull/4156
* Run the 'Prevent blocked' check whenever a PR branch is updated by @robintown in https://github.com/element-hq/element-x-ios/pull/4155
* Update the enterprise submodule. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4161
* Add a placeholder association for localhost in developer mode. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4163


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.05.2...release/25.06.0

## Changes in 25.05.2 (2025-05-21)

### What's Changed

✨ Features
* Add support for Account Provisioning links. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4108

🙌 Improvements
* Remove support for building Alpha/PR (adhoc) builds by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4107
* Fix room list heroes label format by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4114
* Always open manage member sheet  by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4110
* Send full user agent header to server during OIDC authentication and when viewing Account and Device management screens by @hughns in https://github.com/element-hq/element-x-ios/pull/4106

🐛 Bugfixes
* Correctly interpret application state transitions for the screen lock when running on the Mac by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4101
* Fix a bug where accepting a DM invite would be accepted as a regular room. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4123
* Observe room info updates and automatically dismiss the room if meanwhile left or banned by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4122

⚠️ API Changes
* Allow the app to be configured to bypass the server selection screen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4131

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4113
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4134

🧱 Build
* Using 1.18.3 snapshot testing and allow UI tests to use the module properly by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4132
* updated the SDK to 25.05.19 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4133
* Integration tests: support for the bottom sheet by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4135

📄 Documentation
* Project tweaks (layout & docs) by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4121

🚧 In development 🚧
* Add mechanism for opening up a threaded timeline. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4125

Others
* Add a state machine to the AuthenticationFlowCoordinator. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4103
* Voice over focuses the search bar automatically on the invite users screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4105
* Fix various small errors when running in the Swift 6 language mode by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4109
* Update dependency jpsim/Yams to from: "5.4.0" by @renovate in https://github.com/element-hq/element-x-ios/pull/4118
* Update dependency jpsim/Yams to v6 by @renovate in https://github.com/element-hq/element-x-ios/pull/4124
* Show an account provider picker on the server confirmation screen when required. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4137
* Don't group timeline items if more than 5 minutes has passed. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4138


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.05.1...release/25.05.2

## Changes in 25.05.1 (2025-05-07)

### What's Changed

🙌 Improvements
* Updated the learn more link for the identity confirmation screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4096

🐛 Bugfixes
* Fix a bug where fetching room history could fail. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4100


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.05.0...release/25.05.1

## Changes in 25.05.0 (2025-05-06)

### What's Changed

✨ Features
* Remove delivered notifications for rooms that have meantime become fully read by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4041

🙌 Improvements
* Show the kick/ban reason in the timeline. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4071
* Rely on the room's info to decide whether a call ringing notification is outdated by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4078
* Move where the developer options are shown and store them in the app settings by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4082

🐛 Bugfixes
* Dismiss room invite notifications when rejecting them from the home screen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4074
* Disable the composer when you don't have the power to post. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4076

⚠️ API Changes
* Remove the support email address from the OIDC configuration. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4059
* Update the template screen to use the new(ish) Observation framework. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4077
* Adopt StateStoreViewModelV2 in the authentication screens and some settings screens. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4083

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4068
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4091

🧱 Build
* Run UI Tests on GH CI by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4072
* Run integration tests on GH CI by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4073
* Update SDK to 25.04.30 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4081
* Fix the integration tests. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4084
* Fix the UI tests. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4085
* Run the UI & Integration tests once a day instead of twice with a 6 hour offset. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4086

Others
* Update the Enterprise submodule. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4064
* Workflow filename name change by @bmarty in https://github.com/element-hq/element-x-ios/pull/4065
* Remove the Learn More URL for the sliding sync proxy. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4070
* Possible fix for flaky UI tests by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4075
* Updated SDK and improved report flow by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4079
* Add a tool (based on Periphery) that reports any unused strings. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4087
* Update dependency fastlane to v2.227.2 by @renovate in https://github.com/element-hq/element-x-ios/pull/4092
* Bump the version to 25.05. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4093

### New Contributors
* @bmarty made their first contribution in https://github.com/element-hq/element-x-ios/pull/4065

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.04.4...release/25.05.0

## Changes in 25.04.4 (2025-04-22)

### What's Changed

🙌 Improvements
* change: stricter private timeline media visibility by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4006
* Adopt the new start chat button design. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4013
* Stop showing the canonical alias for invites in the room list. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4020
* Prefix the user's own messages with 'You' in the room list. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4022
* Specific report copy for DMs by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4024
* Add the new emoji from iOS 18.4 to the reaction picker. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4023
* Show internet connection warning when uploading keys on log out. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4027
* Refactor the NSE so that the original notification content is preserved between all the different processing steps by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4036
* Report room and decline & block screens tweaks by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4044

🐛 Bugfixes
* Fix missing activity indicators in the authentication flow that are visible with a slow authentication server. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4010
* Fix a bug where your own emotes showed as '* You emoted' in the room list. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4038

⚠️ API Changes
* Refactor SecureBackupControllerListener into SDKListener and use it everywhere. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4030

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4018
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/4047

🧱 Build
* Xcode16.3 support by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4029

📄 Documentation
* Fix Matrix room in CONTRIBUTING.md by @manuroe in https://github.com/element-hq/element-x-ios/pull/4043

🚧 In development 🚧
* Decline and block design tweaks by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4009
* Introduce a `TimelineItemThreadSummary` object by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4032
* Add the new bloom style under a feature flag. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4033
* Tweak the size of the new bloom to match Figma better. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4039

Others
* Bump the SDK and adopt the new MsgLike timeline item types by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4000
* External keyboard support for PIN input by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4007
* Update to 25.04.14 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4021
* Update the 3rd-party acknowledgements. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4037
* UI tests on xcode16.3 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4031


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.04.3...release/25.04.4

## Changes in 25.04.3 (2025-04-10)

### What's Changed

✨ Features
* Setup the client media retention policy by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4001

🙌 Improvements
* Also show the room member management sheet when tapping on a profile in the timeline. by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3995
* Add an option to hiding timeline media only in public rooms by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4004

🐛 Bugfixes
* Manually enable the event cache  by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4005

🧱 Build
* Fix the post-release workflow. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3996

Others
* Update dependency fastlane to v2.227.1 by @renovate in https://github.com/element-hq/element-x-ios/pull/3999
* Re-write integration test login for OIDC. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3997
* Only use the appGroupTemporaryDirectory to access a file from the share extension. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4002


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.04.0...release/25.04.3

## Changes in 25.04.2 (2025-04-10)

### What's Changed

✨ Features
* Setup the client media retention policy by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4001

🙌 Improvements
* Also show the room member management sheet when tapping on a profile in the timeline. by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3995
* Add an option to hiding timeline media only in public rooms by @Velin92 in https://github.com/element-hq/element-x-ios/pull/4004

🐛 Bugfixes
* Manually enable the event cache  by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/4005

🧱 Build
* Fix the post-release workflow. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3996

Others
* Update dependency fastlane to v2.227.1 by @renovate in https://github.com/element-hq/element-x-ios/pull/3999
* Re-write integration test login for OIDC. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3997
* Only use the appGroupTemporaryDirectory to access a file from the share extension. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/4002


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.04.0...release/25.04.2

## Changes in 25.04.0 (2025-04-08)

### What's Changed

✨ Features
* Add alerts with reason for kick and ban by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3967

🙌 Improvements
* Update the app icon. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3977

🐛 Bugfixes
* fix: update compound to fix accessibility in pickers and toggles by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3947
* Bring back the background refresh stop sync crash fix by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3960
* Load single rooms in the notification service extension by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3973

⚠️ API Changes
* Add the push gateway to settings overrides and remove the endpoint path from it. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3970

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3959
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3984

🧱 Build
* Make the secrets optional. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3966
* Add a post-release workflow. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3986
* Prepare for version 25.04.x. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3994
* Vendor our StaticCode pkl package inside the project. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3993

🚧 In development 🚧
* feat: report a room by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3971
* feat:  decline and block screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3989

Others
* a11y: accessibility labels for calls by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3949
* a11y: add profile picture accessibility label by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3948
* a11y: better voice over for voice messages by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3950
* Allow the services that are configured by secrets to be disabled. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3961
* Bump the RustSDK to v25.03.31 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3964
* Updated EC to 0.9.0 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3962
* Allow overriding the bug report app ID and analytics cookies URL. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3969
* Add the build number to rageshakes. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3978
* Add a Compound hook. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3979
* Fix UI test toggle tapping after compound accessibility change. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3985
* Add support URLs to the app setting overrides. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3987
* Update actions/github-script action to v7 by @renovate in https://github.com/element-hq/element-x-ios/pull/3988
* Bump the Rust SDK, futher decrease NSE memory consumption by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3992


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.03.8...release/25.04.0

## Changes in 25.03.8 (2025-03-27)

### What's Changed

🐛 Bugfixes
* Revert "Attempt to prevent crashes after expiring background refreshes." by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3946

⚠️ API Changes
* Refactor the MapTiler configuration into a single place. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3944


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.03.7...release/25.03.8

## Changes in 25.03.7 (2025-03-26)

### What's Changed

✨ Features
* Hide invite avatars when such flag is on by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3919

🐛 Bugfixes
* FIX: DM invites now render avatars correctly by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3931
* FIX: Reply view will now render pills as plain text by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3938
* EC Embedding improvements by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3943
* Attempt to prevent crashes after expiring background refreshes. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3942

⚠️ API Changes
* Updated the SDK to 25.03.24 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3916

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3932

Others
* Add developer options for Rust's Log Packs. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3929
* Update GitHub Actions to v5 (major) by @renovate in https://github.com/element-hq/element-x-ios/pull/3928
* Update apple-actions/import-codesign-certs digest to cfd6eb3 by @renovate in https://github.com/element-hq/element-x-ios/pull/3937
* Use 'Dismiss' to close pinned identity changes, instead of 'Ok' by @andybalaam in https://github.com/element-hq/element-x-ios/pull/3936
* Add NSPrivacyTracking and NSPrivacyCollectedDataTypes to PrivacyInfo.xcprivacy by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3935
* Embed element call by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3939


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.03.5...release/25.03.7

## Changes in 25.03.6 (2025-03-25)

### What's Changed

✨ Features
* Hide invite avatars when such flag is on by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3919

🐛 Bugfixes
* FIX: DM invites now render avatars correctly by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3931
* FIX: Reply view will now render pills as plain text by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3938

⚠️ API Changes
* Updated the SDK to 25.03.24 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3916

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3932

Others
* Add developer options for Rust's Log Packs. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3929
* Update GitHub Actions to v5 (major) by @renovate in https://github.com/element-hq/element-x-ios/pull/3928
* Update apple-actions/import-codesign-certs digest to cfd6eb3 by @renovate in https://github.com/element-hq/element-x-ios/pull/3937
* Use 'Dismiss' to close pinned identity changes, instead of 'Ok' by @andybalaam in https://github.com/element-hq/element-x-ios/pull/3936
* Add NSPrivacyTracking and NSPrivacyCollectedDataTypes to PrivacyInfo.xcprivacy by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3935
* Embed element call by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3939


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.03.5...release/25.03.6

## Changes in 25.03.5 (2025-03-21)

### What's Changed

🧱 Build
* Discard any changes before rebasing main. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3927


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.03.3...release/25.03.5

## Changes in 25.03.4 (2025-03-20)

### What's Changed

🧱 Build
* Discard any changes before rebasing main. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3927


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/release/25.03.3...release/25.03.4

## Changes in 25.03.3 (2025-03-20)

### What's Changed

✨ Features
* Alert for phishing attempts by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3895

🙌 Improvements
* Added @room to suggestion view for room mentions by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3896
* Removed images in pills in favour of text decorations by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3905

🐛 Bugfixes
* Fix sharing from in-app QuickLook to itself by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3902
* Fix: completion service matches now any character by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3911
* Fix an issue rendering pills in some forks. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3913
* Attempt to fix the wrong timeline start display by defaulting the backwards publisher to .idle by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3924

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3885
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3903

🧱 Build
* Improve next release flow to rebase main by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3876
* Check if the git is shallow before fetching by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3879
* CI: git fetch unshallow only in post-clone by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3880
* Use updated Fastlane lane. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3877
* Prefix our release tags with `release/` by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3894
* Remove the unused TestMeasurementParser and lint integration tests again by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3918
* Stop CI from uploading Codecov results when a PR comes from a fork. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3917

Others
* ClientProxy refactor by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3875
* Change badge label colors to blue when not highlighted by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3882
* Update sentry to 8.35 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3888
* Update sentry to 8.35.1 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3890
* SDK update by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3891
* Update dependency fastlane to v2.227.0 by @renovate in https://github.com/element-hq/element-x-ios/pull/3900
* Update the Enterprise submodule. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3899
* Added a test to check if URLs with RTL are not marked as phishing by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3907
* Pin all 3rd party github actions to their full length commit SHA by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3908
* Update codecov/codecov-action action to v3.1.6 by @renovate in https://github.com/element-hq/element-x-ios/pull/3915
* Add overrides for OIDC configuration. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3910
* Run the 'prevent blocked' workflow even if PR has conflicts by @robintown in https://github.com/element-hq/element-x-ios/pull/3914
* Update the SDK to 25.03.20. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3925


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/25.03.2...release/25.03.3

## Changes in 25.03.2 (2025-03-06)

### What's Changed

✨ Features
* Show DM recipient verification badges on the room details screen profile button by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3824
* Show room encryption state in the composer by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3841
* Join room by address by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3840
* Only show a badge in the composer if the room is unencrypted. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3866
* Room mentioning in the composer by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3868
* Re-enable the error screens in group calls by @hughns in https://github.com/element-hq/element-x-ios/pull/3856

🐛 Bugfixes
* show "Room" for unresolved event permalinks by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3854
* Private rooms are now created with the `.invited` room history visibility by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3853
* Use a static room summary provider to resolve room summaries through id and aliases by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3863
* Prevent various room subscription task from blocking opening rooms by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3873

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3861

🧱 Build
* Project updates. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3837
* Set APP_GROUP_IDENTIFIER directly. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3847

Others
* Increase the time before we show loading indicators when processing user session and flow coordinators routes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3844
* Bump the RustSDK to v25.02.28 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3855
* Prevent PRs with the X-Blocked label from being merged by @robintown in https://github.com/element-hq/element-x-ios/pull/3864
* Revamp test snapshot naming conventions by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3869
* Bump the RustSDK to v25.03.05 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3870
* FF event cache true by default and updated the SDK by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3874


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/25.03.1...25.03.2

## Changes in 25.03.1 (2025-02-26)

### What's Changed

🐛 Bugfixes
* Cache account management URL by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3826
* Fix editing messages not placing the cursor at the end of the text by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3833
* Fix a bug where you couldn't log in to matrix.org by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3829


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/25.03.0...25.03.1

## Changes in 25.03.0 (2025-02-25)

### What's Changed

✨ Features
* Add support for initiating and responding to user verification requests by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3759
* User verification state indicators by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3793
* Show error screens in group calls by @robintown in https://github.com/element-hq/element-x-ios/pull/3813
* Render Room and Message Pills by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3809

🙌 Improvements
* Updated the notification string for incoming calls by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3723
* Revert back to UIKit for the presentation of the timeline media preview. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3719
* Added an alert before creating a new DM by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3730
* Bottom Sheet to confirm DM creation by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3739
* Use the new preview screen when tapping media on the room and pinned events screens. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3736
* Added a delayed loading when opening a room by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3748
* Updated Bottom Sheet message string by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3743
* Updated File and Media timeline view by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3751
* Fix message completion trigger to work anywhere in the message by @vickcoo in https://github.com/element-hq/element-x-ios/pull/3696
* Hide the unread dot after previewing an invite. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3800

🐛 Bugfixes
* Ensure multiple mandatory verification flows can be ran consecutively (e.g. following encryption resets) by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3722
* Fix missing user IDs. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3725
* Knocking polishing part 1 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3732
* Fix a crash in the media browser by storing the active timeline context. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3746
* Fix a bug where the preview controller breaks when swiping quickly. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3750
* Stop the message composer from randomly changing the cursor position by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3796
* Use alternative summary provider when listening to knocked membership change by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3817
* Don't set the room topic when creating a room if it is blank. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3821

⚠️ API Changes
* Remove support for the sliding sync proxy. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3801

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3727
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3775
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3799
* Update translations (manually). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3815

🧱 Build
* Add a test dependabot.yml file and see to see what it picks up. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3756
* Delete dependabot.yml - it doesn't work for Xcode projects (or XcodeGen). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3757
* Update our development assets. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3783
* Update the Enterprise submodule. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3789
* Configure diagnostics (and MapLibre) using Pkl. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3820

🚧 In development 🚧
* Knocking feature polishing part 2 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3738
* Added the banned room proxy by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3744
* Knock Polishing part 4 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3779
* Updated dev options screen for ask to join by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3787

Others
* Fix flakey room member details screen snapshot test by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3726
* RoomTimeline… refactor (drop the `Room`). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3728
* Switch the ElementCall UI test to `call.element.io` for stability by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3733
* Refactor Rust timeline identifiers into our own. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3731
* Add back verbose logging for the timeline provider to help debug the event cache and lazy loading by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3734
* updated the SDK to 25.02.04 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3737
* Revert unsuccessful UI test stability tweaks by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3740
* Fix some concurrency warnings, update missed licence headers. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3741
* Bump the RustSDK to v25.02.06 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3749
* Removed now unused secrets by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3754
* Refactor how notifications are preprocessed and be explicit about which ones are supposed to be displayed or discarded by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3776
* Log whether a notification is expected to make a noise. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3782
* Fix UI test snapshots following session verification screen changes. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3781
* Update dependency jpsim/Yams to from: "5.2.0" by @renovate in https://github.com/element-hq/element-x-ios/pull/3788
* Update strings after resolving some duplicities. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3791
* Update dependency jpsim/Yams to from: "5.3.0" by @renovate in https://github.com/element-hq/element-x-ios/pull/3798
* Use the app name placeholder added to the logout alert title. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3802
* Update Compound by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3803
* Rename a couple of missed isEncryptedOneToOneRoom properties. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3804
* Update dependency jpsim/Yams to from: "5.3.1" by @renovate in https://github.com/element-hq/element-x-ios/pull/3814
* Add a couple of extra logs around the state of call ringing notifications. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3808
* Fix various UI test snapshots following changes to the development assets by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3816
* Revert "Show error screens in group calls" by @hughns in https://github.com/element-hq/element-x-ios/pull/3819
* Bump the RustSDK to v25.2.25 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3823

### New Contributors
* @vickcoo made their first contribution in https://github.com/element-hq/element-x-ios/pull/3696
* @robintown made their first contribution in https://github.com/element-hq/element-x-ios/pull/3813

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/25.02.0...25.03.0

## Changes in 25.02.0 (2025-01-31)

### What's Changed

✨ Features
* Warn and block sending on verification violation by @BillCarsonFr in https://github.com/element-hq/element-x-ios/pull/3679

🙌 Improvements
* Media upload tweaks by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3643
* Autofocus emoji search and send the first result with the return key on macOS. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3644
* Design tweaks. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3645
* Improve how alias settings are handled, add unit tests. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3686
* Refactor the JoinRoom screen to take advantage of newer APIs and support more joinRule/membership combinations (i.e. invite required, restricted, banned) by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3685
* Media browser tweaks by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3692
* DM Design Tweaks by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3693
* Media Browser: Listen to the timeline in the preview screen by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3707
* Detect the timeline start/end when swiping through media files. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3714

🐛 Bugfixes
* Fix the overlapping scrollbars on the room list filters on macOS. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3646
* Possible fix for the join room screen not updating by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3690
* Make sure the Recovery Key option is shown on the IdentityConfirmationScreen when available. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3699
* Show a blank topic as removed in the state event. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3706

⚠️ API Changes
* Do not handle offline mode yet by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3715

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3649
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3676
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3687
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3704
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3709

🧱 Build
* Include missing gems until Fastlane is updated for Ruby 3.4 by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3663
* Image magick replacement + app variants by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3691
* Switch to CalVer (manually). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3705
* Fastlane calendar versioning check and increase  by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3721

📄 Documentation
* Update the bug report template by @manuroe in https://github.com/element-hq/element-x-ios/pull/3651

🚧 In development 🚧
* Security and privacy part 2 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3637
* Better handling for editing alias in case of different HS by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3695

Others
* Retrofit `deferFulfillment` onto snapshot tests. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3641
* Bump the RustSDK to version 24.12.20 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3647
* Dual licensing: AGPL + Element Commercial by @manuroe in https://github.com/element-hq/element-x-ios/pull/3657
* Ignore Compound and RTE from license acknowledgements. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3661
* Add the event cache to the Rust tracing configuration. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3662
* Delay snapshotting various flakey UI tests by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3667
* Simplify how to we handle background task expirations. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3670
* Move tracing configuration to the rust side. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3668
* Bump the RustSDK to v25.01.15 and fix (most) concurrency sendability warnings in the generated mocks by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3680
* Fix flakey `RoomMemberDetailsScreen` preview test. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3688
* Add MXLog.dev for faster print debugging. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3694
* Bump the RustSDK to v25.01.22 and use the new timeline building API by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3697
* Remove unused/redundant assets. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3702
* Bump the RustSDK to 25.01.27, adopt the new emoji boosting API. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3708
* Various flakey test fixes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3710
* Attempt to fix the every flakey app lock setup test by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3716
* Disable `continueAfterFailure` for the AppLock UI tests by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3720


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.9.10...25.02.0

## Changes in 1.9.10 (2024-12-19)

### What's Changed

✨ Features
* Enable the media browser feature 🖼️ by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3642

🙌 Improvements
* Design Tweaks by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3606
* Updated room details design by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3626
* Reorder timeline item menu options by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3640

🐛 Bugfixes
* Fix tap knockable room and custom keyboard did show scrolling by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3603
* Fix a bug where you're shown the remove caption action when it isn't available. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3608
* Fix recently used emojis by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3624
* Fix state change commented by mistake and simplify snapshot test setup by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3627

⚠️ API Changes
* Support for new UtdCause for historical messages by @BillCarsonFr in https://github.com/element-hq/element-x-ios/pull/3625

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3592
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3623

🚧 In development 🚧
* Media gallery by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3588
* Update the timeline media QuickLook modifier. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3593
* Use TimelineMediaQuickLook in the MediaEventsTimelineScreen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3598
* Monthly media gallery separators by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3601
* Configure the media preview screen based on the event and presentation. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3604
* Media gallery - support for files and voice messages by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3605
* Hook up the actions in the media details sheet. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3607
* Custom media gallery views for files and voice messages by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3610
* Security and privacy part 1 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3617
* Various media gallery related tweaks by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3616
* Implement Knock Logic by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3573
* Rework the presentation of the media browser quick look view to use SwiftUI. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3619
* Implement the save action when previewing media. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3630
* Add a fullscreen button to TimelineMediaPreviewScreen and hook up swiping through the timeline. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3638

Others
* Use a `Date` for the timestamp in all timeline items. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3590
* UI test snapshot fixes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3597
* Bump the RustSDK to v1.0.79; add a feature flag for the new rust side `ClientBuilder::useEventCachePersistentStorage` by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3599
* Update dependency fastlane to v2.226.0 by @renovate in https://github.com/element-hq/element-x-ios/pull/3600
* Update dependency fastlane to v2.226.0 by @renovate in https://github.com/element-hq/element-x-ios/pull/3602
* Update dependency fastlane to v2.226.0 by @renovate in https://github.com/element-hq/element-x-ios/pull/3609
* Update dependency fastlane to v2.226.0 by @renovate in https://github.com/element-hq/element-x-ios/pull/3613
* Report extra UTD error properties to PostHog by @BillCarsonFr in https://github.com/element-hq/element-x-ios/pull/3612
* Various danger swift rule tweaks by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3615
* chore(deps): update dependency fastlane to v2.226.0 by @renovate in https://github.com/element-hq/element-x-ios/pull/3621
* Disable semantic commits from Renovate by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3629
* Updated sdk to 1.0.82 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3631
* Automatically retry decryptions in the active room when the app becomes active again just in case the NSE received keys we're not aware of by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3628


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.9.9...1.9.10

## Changes in 1.9.9 (2024-12-05)

### What's Changed

🙌 Improvements
* Added historical message error label string by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3580
* increase ringing timeout from 15 seconds to 90 seconds by @fkwp in https://github.com/element-hq/element-x-ios/pull/3584
* Compound SendButton v2 by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3589

🧱 Build
* Add new development assets and use in mocks/previews. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3581
* Fix UI snapshots. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3585

Others
* Update sdk to 1.0.78 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3586

### New Contributors
* @fkwp made their first contribution in https://github.com/element-hq/element-x-ios/pull/3584

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.9.8...1.9.9

## Changes in 1.9.8 (2024-12-03)

### What's Changed

✨ Features
* Enable local echoes for media uploads for all builds. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3579

🙌 Improvements
* Add support for copying a caption. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3563
* Move pinned messages button in details by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3575
* Add a warning to the media caption composer. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3574
* Knock a room - added a char counter for the message by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3570

🐛 Bugfixes
* Small Knock adjustments by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3568
* Wait until the sync has stopped before marking a background task as complete. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3564
* Handle media source validation more gracefully. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3571

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3576

Others
* Make the Unit Test media files into development assets. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3569
* Update SDK 1.0.77 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3578


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.9.7...1.9.8

## Changes in 1.9.7 (2024-11-28)

### What's Changed

✨ Features
* Support adding a caption to media uploads. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3531
* Show both defaults and frequent emojis in the timeline item menu, make the list scrollable by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3534
* Enable inline replies for push notifications. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3542

🙌 Improvements
* using `roomPreview` API for invited rooms by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3530
* Add support for sharing URLs and text. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3546
* Add support for adding/editing/removing media captions. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3547
* Update how file captions are rendered by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3554

🐛 Bugfixes
* Handle NSItemProvider public.image data types. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3541
* Fix the media upload preview screen on macOS. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3543
* Delay handling inline notification replies until the user session is established by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3544
* Put the share extension Info.plist updates in the xcodegen yaml 🤦‍♂️ by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3549
* Fix the presentation of QuickLook when viewing logs on macOS. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3556
* Stop delaying ElementCall until the next sync loop and only notify other participants when presumed to already be up to date. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3559
* Add back missing send button when media captions are disabled. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3561
* Fix a bug on iOS 17 where you couldn't long press on a message. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3567

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3552

🧱 Build
* Link the MatrixRustSDK dynamically and only embed it in the main target by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3539

🚧 In development 🚧
* Knock Requests List Screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3533
* Knock Requests banner display logic by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3550
* Knock Requests navigation flows by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3555

Others
* Fix UI tests, update compound to roll back snapshot testing and avoid the requirement for Swift Testing. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3540
* Update the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3545
* Move timeline item tap gestures to the items themselves instead of the bubbled styler by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3553
* Bump the RustSDK to v1.0.75 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3557
* Move the media caption composer (and Add Caption action) behind a feature flag for now. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3560
* Update the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3565


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.9.6...1.9.7

## Changes in 1.9.6 (2024-11-19)

### What's Changed

✨ Features
* Share extension by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3506
* Enable local echoes for media uploads on development builds. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3514

🙌 Improvements
* Stacked Avatars View by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3504

🐛 Bugfixes
* Regenerate thumbnails to see if it helps with phantom avatar switching. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3503
* Fix #1947 - Check expected files are still present before restoring a session. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3507
* Fix Rooms that user has knocked not displaying the request sent screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3513
* Fix share extension app group so it works for nightlies too by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3520
* Fix toolbar icons disappearing on the iPad after backgrounding the app by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3521
* Fix a bug where the security banner has the wrong state when out of sync. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3511
* Fix image animations / remove fading when switching between local and remote echoes. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3525

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3523

🧱 Build
* Update the project to use Xcode 16.1 by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3505

🚧 In development 🚧
* Knock requests banner by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3510
* Knocking Request Cell by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3516

Others
* Update the strings for unsupported calls. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3502
* Bump the RustSDK to v1.0.67 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3512
* UI test fixes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3515
* Group image and video metadata in specialised structs by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3518
* Update compound by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3519
* Update the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3524
* Update compound iOS by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3532
* Expose the public search feature flag in the developer settings and disable it by default. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3528
* Update the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3535


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.9.5...1.9.6

## Changes in 1.9.5 (2024-11-11)

### What's Changed

🐛 Bugfixes
* Stop setting up CallKit sessions when joining calls by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3496
* Fix for creating a knocking room by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3499
* Make stopSync more aware of background usage. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3501

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3500

🚧 In development 🚧
* Add alias to public room creation by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3450

Others
* Fix incorrect analytics mapping for UTDs. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3497
* Update compound. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3498
* Tweak the session verification icons and copy. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3495


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.9.4...1.9.5

## Changes in 1.9.4 (2024-11-07)

### What's Changed

✨ Features
* Hook reaction pickers into the system's recently used keyboard emojis by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3453
* Incoming session verification support by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3428
* Enable the Optimised Media Uploads feature. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3467

🙌 Improvements
* Enable identity pinning violation notifications unconditionally by @andybalaam in https://github.com/element-hq/element-x-ios/pull/3457
* Tweak the flow for changing a recovery key. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3452
* Replace individual RoomProxy properties with a stored RoomInfo. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3445
* Use an https callback for OIDC once again. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3461
* Tweak the flow for setting up a recovery key. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3463
* Tweak the flow for disabling key storage. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3464
* Directly show Recovery Key and Encryption Reset screens from the home screen banner. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3482

🐛 Bugfixes
* Fix the order of the frequently used emojis when showing them in the full reaction picker by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3455
* Stop the sync loop after each background app refresh. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3481
* Fix the Setup Recovery flow from the home screen banner. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3483
* Fix race condition when setting up session verification controller subscriptions by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3486
* Fix a couple of race conditions when observing room info updates for calls. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3487
* Syncing fixes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3488
* Start syncing when receiving a background VoIP call for the cases in which the app was suspended but not terminated by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3491
* Update SDK 1.0.65 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3494

🗣 Translations
* Update translations and some snapshots. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3459
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3477

🧱 Build
* remove iOS 16 support by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3443
* min macos support by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3451
* Revert "min macos support" by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3458

📄 Documentation
* Update the README. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3480

🚧 In development 🚧
* Knocked Preview implementation by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3426
* Switch optimised video uploads to use 720p by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3462

Others
* Update verify identity button title. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3466
* Update the strings for out of sync Key Storage. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3468
* Update SDK 1.0.63 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3479
* Encryption Flow Coordinators. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3471
* Update SDK 1.0.64 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3490
* Fastlane fails resetting the right simulator, use `device` instead of `destination`. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3493

### New Contributors
* @andybalaam made their first contribution in https://github.com/element-hq/element-x-ios/pull/3457

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.9.3...1.9.4

## Changes in 1.9.3 (2024-10-24)

### What's Changed

🙌 Improvements
* Update HeroImage to match the BigIcon component from Compound. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3439
* Update compound to change checkmark color by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3440

🐛 Bugfixes
* Fix a bug where the pinned items banner could overlay the composer. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3441
* Fix composer mention pills showing up as file icons on first use on iOS 18 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3444
* Fix a bug where the room state wouldn't indicate when a call was in progress. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3442


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.9.2...1.9.3

## Changes in 1.9.2 (2024-10-23)

### What's Changed

🙌 Improvements
* Add support for rendering media captions in the timeline. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3429
* Show a verification badge on the Room Member/User Profile screens. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3427

🐛 Bugfixes
* Only subscribe to identity updates if the room is encrypted. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3414
* Fix the pinned identity banner to always show the user ID regardless of ambiguity. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3415
* Fix a bug where uploaded images could have the wrong aspect ratio in the timeline. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3435

⚠️ API Changes
* Adopt various rust side Timeline API additions by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3423

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3433

🚧 In development 🚧
* Allow image uploads to be optimised to reduce bandwidth. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3412
* Knock and knocked state for the join room screen by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3424

Others
* Fix some warnings. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3416
* Refactor the`TimelineItemIdentifier` handling by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3418
* Remove superfluous media request upload handle cancellation call. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3425
* Update dependency fastlane to v2.225.0 by @renovate in https://github.com/element-hq/element-x-ios/pull/3434
* Adopt various Rust side API changes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3437


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.9.1...1.9.2

## Changes in 1.9.1 (2024-10-15)

### What's Changed

🐛 Bugfixes
* Fix a bug opening images with a valid filename but a mimetype of `image/*` (sent by EXA). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3407

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3406

🚧 In development 🚧
* Create Room with knock rule by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3397
* Allow video uploads to be optimised to reduce bandwidth. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3408


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.9.0...1.9.1

## Changes in 1.9.0 (2024-10-10)

### What's Changed

🐛 Bugfixes
* Fix identity pinning link. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3395

🧱 Build
* Update the version to 1.9.0. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3396


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.8.6...1.9.0

## Changes in 1.8.6 (2024-10-10)

### What's Changed

✨ Features
* crypto: Configure decryption trustRequirement based on config flag by @BillCarsonFr in https://github.com/element-hq/element-x-ios/pull/3358
* Introduce a feature flag for the new identity pinning violation notifications feature by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3394
* Show the Login with QR Code button. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3392

🙌 Improvements
* Add a subtitle to the QR Code login instructions. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3386
* Tweak the UI in the EncryptionReset, IdentityConfirmation and SecureBackupRecovery screens. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3391
* Update the secondary button stroke colour. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3393

Others
* Fix an authentication UI test snapshot. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3387
* Ask the iPad to reveal the keyboard in UI Tests when it's hidden. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3389


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.8.5...1.8.6

## Changes in 1.8.5 (2024-10-08)

### What's Changed

✨ Features
* Display a warning when a user's pinned identity changes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3368

🙌 Improvements
* Add detection for latest devices. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3327
* Configure the AuthenticationService later now that we have 2 flows on the start screen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3316
* Selecting a server that doesn't support login now fails instead of letting you continue to a failure later. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3342
* Add new emoji from iOS 17.4 to the reaction picker. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3376

🐛 Bugfixes
* Use a plain view for reactions instead of a TabView. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3328
* Upgrade Kingfisher to fix a bug that prevented GIFs from being tapped. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3326
* Make sure the room header takes up as much space as possible (to hide the back button). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3335
* Have ElementCall always default to the speaker; prevent the lock button from ending the call by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3338
* Allow focusing the different avatars making up a DM details cluster separately. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3341
* Disable auto correction when running on the Mac by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3364

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3347
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3371

🧱 Build
* Start fixing flakey tests ❄️ by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3329
* Integration test runner switch by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3343
* Switch UI tests back to the perf-only runner. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3349

🚧 In development 🚧
* Add developer option to hide media in the timeline. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3366

Others
* Integration test improvements by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3330
* crypto: rename invisible crypto flag to deviceIsolationMode by @BillCarsonFr in https://github.com/element-hq/element-x-ios/pull/3331
* chore(deps): update dependency fastlane to v2.223.0 by @renovate in https://github.com/element-hq/element-x-ios/pull/3337
* Log any failures when creating a call widget. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3339
* chore(deps): update dependency fastlane to v2.223.1 by @renovate in https://github.com/element-hq/element-x-ios/pull/3340
* Tracing and integration test tweaks by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3336
* Remove message pinning FF by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3318
* Move the core logic in LoginScreenCoordinator into the ViewModel. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3348
* Bump the RustSDK to v1.0.53: adopt latest record based timeline item APIs by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3356
* use element-hq RTE version by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3360
* Hide timeline media preparation by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3361
* chore(deps): update dependency fastlane to v2.224.0 by @renovate in https://github.com/element-hq/element-x-ios/pull/3370
* Record a missing snapshot. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3374
* Update the SDK and use media `filename` and `caption` internally. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3375
* update sdk by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3377


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.8.4...1.8.5

## Changes in 1.8.4 (2024-09-24)

### What's Changed

✨ Features
* Enable message pinning by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3308

🐛 Bugfixes
* Fix: confusion of lab flags for invisible crypto by @BillCarsonFr in https://github.com/element-hq/element-x-ios/pull/3319
* Fix a regression where you can't scroll the timeline on iOS 17 by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3320
* Fix a bug where the Join Room screen was sometimes shown instead of the Room. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3323
* Fix a bug on iOS 18 where the timeline background would use the wrong colour scheme when using the app switcher. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3324
* Don't use the new iPad modal presentation mode for the timeline item menu by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3325

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3315

🧱 Build
* Update the project to use Xcode 16. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3303

Others
* A bunch of random tweaks. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3317


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.8.3...1.8.4

## Changes in 1.8.3 (2024-09-19)

### What's Changed

✨ Features
* crypto: Add configuration flag to enable invisible crypto by @BillCarsonFr in https://github.com/element-hq/element-x-ios/pull/3247
* quick and dirty /join command by @ara4n in https://github.com/element-hq/element-x-ios/pull/3288

🐛 Bugfixes
* Await for room sync only for push notification invites by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3307

🧱 Build
* Try to stop random codecov test result action failures from failing the whole test run. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3301

Others
* Various Danger fixes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3304


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.8.2...1.8.3

## Changes in 1.8.2 (2024-09-18)

### What's Changed

✨ Features
* Allow registration on matrix.org using a custom helper URL. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3282

🙌 Improvements
* Allow account deactivation when not using OIDC. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3295

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3283

🧱 Build
* Bump SDK to 1.0.51 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3298

🚧 In development 🚧
* Add a WebRegistrationScreen (not included in the flow yet). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3281
* Added analytics for message pinning by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3284

Others
* Bump the RustSDK to v1.0.50 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3292
* Push the deactivate account screen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3297
* Use the new strings for send failures when the unsigned devices are your own. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3299
* Stop delaying subscriptions until after startup by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3294


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.8.1...1.8.2

## Changes in 1.8.1 (2024-09-13)

### What's Changed

🐛 Bugfixes
* Make sure we don't reuse an old NSEUserSession after logging out and back in. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3273
* Make sure we reset the feature flag when upgrading to SSS. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3272
* Fix interactive dismissal of our QLPreviewController iOS 18 (when built with Xcode 16). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3274
* Replace client side room awaiting with the SDKs new `awaitRoomRemoteEcho` method by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3279
* Handle notifications properly when a call is happening. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3276

🧱 Build
* Upload test results to Codecov. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3266


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.8.0...1.8.1

## Changes in 1.8.0 (2024-09-11)

### What's Changed

✨ Features
* Add a banner that offers the user to transition to native sliding sync by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3252

🙌 Improvements
* Delay setting up subscriptions until the RoomListService is running in order to avoid cancelling in flight initial sync requests by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3233
* Require acknowledgement to send to verified users who have unsigned devices or have changed their identity. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3215
* Make the SessionDirectories type responsible for cleaning up data. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3261

🐛 Bugfixes
* Rewrite how out of band verification changes are handled within the onboarding flows by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3234
* Allow voice message playback in the background by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3236
* Fix wrong durations for uploaded media by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3245
* Make sure introspections are used on iOS 18. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3248
* Bring back default controls for QuickLook based media viewers by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3254
* Reduce the maximum height used by the plain text composer by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3255
* Force frame sizes for timeline items that are missing sizing info by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3259

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3239

🧱 Build
* Replace Prefire with a very similar but simpler and more direct approach by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3232
* Switch codecov-action back to v3 as 4 significantly decreases coverage by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3246
* Free up CI runner disk space before running UI tests. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3253
* version bump to 1.8.0 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3260
* Sdk v1.0.47 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3265

🚧 In development 🚧
* Pin Tweaks by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3242
* Allow redacted messages to be viewed and unpinned by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3251
* Added a pin icon by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3257

Others
* Switch license to AGPL by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3237
* Remove SS proxy migration and waitlist screens by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3154
* Update bug.yml by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3250


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.7.5...1.8.0

## Changes in 1.7.5 (2024-09-04)

### What's Changed

✨ Features
* Add a logout button on the identity confirmation screen by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3212

🐛 Bugfixes
* Make sure reactions always go through the timeline controller. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3209
* Prevent issues when loading user profiles by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3213
* Accept current autocorrection/suggestion before sending a message by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3219
* Update subscriptions if visible range rooms change without the range itself changing by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3220
* Prevent verification state changes other than `verified` from blocking the user on the session verification screen by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3224
* Make pinned events required state in SlidingSync by @jmartinesp in https://github.com/element-hq/element-x-ios/pull/3225
* Force room title headers to layout on one single line by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3229

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3218

🚧 In development 🚧
* Native Sliding Sync Discovery by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3211

Others
* Update GitHub Actions (major) by @renovate in https://github.com/element-hq/element-x-ios/pull/3222
* Update GitHub Actions (major) by @renovate in https://github.com/element-hq/element-x-ios/pull/3227
* Bump the RustSDK to v1.0.44 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3230

### New Contributors
* @jmartinesp made their first contribution in https://github.com/element-hq/element-x-ios/pull/3225

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.7.4...1.7.5

## Changes in 1.7.4 (2024-08-27)

### What's Changed

✨ Features
* Show encryption authenticity warnings on messages in the timeline. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3180
* Picture in Picture support for Calls (requires a supported widget deployment). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3204

🙌 Improvements
* Clarify the copy for Mentions in notifications. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3142
* Remove a notification if its event has been redacted. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3191

🐛 Bugfixes
* RoomScreenViewModel refactor part 2 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3169
* Automatically try reloading failed images on network changes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3170
* Fixes problems processing invites, build rooms differently based on their membership by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3189

⚠️ API Changes
* Introduce a new `RoomProxyType` and treat rooms differently based on their membership state by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3187

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3172
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3179
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3201

🚧 In development 🚧
* RoomScreenViewModel is now TimelineViewModel by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3157
* PinnedBanner is now managed by the RoomScreenViewModel  by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3163
* Navigation support for upcoming Element Call Picture in Picture mode. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3174
* Use native video call picture in picture! by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3190
* Pinned Events Timeline actions and differentiation by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3182
* `TimelineKind` refactor by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3193

Others
* Add a danger check for PR titles that contain a "Fixes #1234" prefix. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3161
* Update package acknowledgements (after resetting the packages). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3167
* Bump the SDK to v1.0.39 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3171
* Remove GenericCallLinkCoordinator, merging it into CallScreen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3181
* Fix the call URL input field in Developer Options by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3192
* Update the SDK by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3196
* Update the client's request timeout to match the SDK's default. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3205


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.7.3...1.7.4

## Changes in 1.7.3 (2024-08-13)

### What's Changed

✨ Features
* Crypto identity reset by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3107
* Fixes #3050 - Sync mute state between ElementCall and CallKit by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3120

🐛 Bugfixes
* Fix a bug where a new line in the composer could move the caret. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3114
* Make sure the whole room header is tappable. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3125
* Force the room list search text field to always be displayed by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3127
* Fix search in the Change Roles screen. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3138
* Various ElementCall fixes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3140
* Fixes #3126 - Prevent identity confirmation from blocking the user's progress after registering through OIDC by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3141
* Fix a bug where the server versions for matrix.org were used when signing in to a different server. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3155
* Stop showing filters when the room list is not in the `rooms` display mode by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3156

🧱 Build
* Update sonarcloud project key by @guillaumevillemont in https://github.com/element-hq/element-x-ios/pull/3112
* Use SwiftPackageList to generate acknowledgements. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3117

🚧 In development 🚧
* Show Encryption Authenticity warnings on messages in the timeline. by @BillCarsonFr in https://github.com/element-hq/element-x-ios/pull/3051
* Pinned items timeline implementation for the banner by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3099
* Add Encryption Authenticity explanations. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3116
* Pinned events banner loading state by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3118
* Finalise strings/icons for EncryptionAuthenticity. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3121
* state events for pinning and unpinning by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3123
* Pinned events banner goes backwards by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3128
* Navigate to the Pinned events timeline by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3139
* Fix for a memory leak by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3143
* Remove links from pinned events banner by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3153

Others
* Put a space between the version and build numbers on the Nightly icon by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3124
* Force update the home screen every time the room list changes by manually moving the inner scrollview by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3122
* Delete more unnecessary logs by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3129
* Adopt APIs available in SDK version 1.0.36 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3145
* Bump the SDK to v1.0.37 by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3158

### New Contributors
* @guillaumevillemont made their first contribution in https://github.com/element-hq/element-x-ios/pull/3112

**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.7.2...1.7.3

## Changes in 1.7.2 (2024-07-30)

### What's Changed

🙌 Improvements
* Add the inviter to `JoinRoomScreen` when it's an invite. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3093

🐛 Bugfixes
* Fix a potential crash when logging out. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3090

🚧 In development 🚧
* Pin/Unpin Logic by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3084

Others
* Update dependency fastlane to v2.222.0 by @renovate in https://github.com/element-hq/element-x-ios/pull/3097
* Refactor TimelineItemSendInfo out of the styler. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3100


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.7.1...1.7.2

## Changes in 1.7.1 (2024-07-26)

### What's Changed

🐛 Bugfixes
* Trim number of resolved alias vias and always default to a join button in the room preview screen by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3082
* Fix a crash experienced when trying to report a crash. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3086

🚧 In development 🚧
* Automatically sign out when toggling the Simplified Sliding Sync feature flag. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3071
* Fix the restoration of a Simplified Sliding Sync session. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3081
* Hide/Show pin banner based on scroll direction by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3080

Others
* Update Compound and handle API breaks in Introspect. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3083


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.7.0...1.7.1

## Changes in 1.7.0 (2024-07-22)

### What's Changed

✨ Features
* Various CallKit and ElementCall fixes by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/2975

🙌 Improvements
* Use local room list sorting from Rust. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/2978
* Replace old visible rooms range with subscriptions in the room list. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3014
* Update RTE to 2.37.5 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3015

🐛 Bugfixes
* Fix for the left room event using member instead of the sender by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3000
* Fix a crash when 2 present room events are sent in quick succession. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3001
* Make sure the BugReportScreen allows the user to retry if sending fails. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3012
* FIX: saving draft did not save the pill markdown content by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3003
* Update the SDK (fixes unnecessary encryption state requests in the room list). by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3016
* Restore Mentions in plain text mode by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3018
* Make sure Element Call uses the correct theme and language. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3017
* Fix stuck unread indicators. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3023
* Fix the string used for encrypted events in the room list. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3030
* Update the SDK fixing a few room list bugs. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3054
* Fix a potential race condition when redacting a message. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3061
* Use the same UI as Android when tapping a link to a private room. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3044
* Use both the room list room and the room preview details to populate the join room screen by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3062
* Fix editing items not in the timeline failing by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3075
* ElementCall unable to access media on ongoing CallKit session. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3077

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3011
* Handle renamed PIN alert string. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3024
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3038
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/3074

🧱 Build
* Upgrade the project to use Xcode 15.4 by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3027
* Fix an App Store upload error due to an RTE version mismatch. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3029
* Fix RTE framework signature error when building DEBUG builds for a device. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3040
* Upgrade Compound. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3039
* Run the integration tests on GitHub again. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3052
* Removed RTE script by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3067

🚧 In development 🚧
* Add a feature flag for Simplified Sliding Sync. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3057
* Add a feature flag for Message Pinning. by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3063
* Pinned Items Banner UI by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3072

Others
* Update dependency jpsim/Yams to from: "5.1.3" by @renovate in https://github.com/element-hq/element-x-ios/pull/3022
* Update RTE with inline prediction working by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3043
* Simplify how we setup Sentry to make sure it's configured before any … by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3053
* Add a ClientBuilder hook. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3056
* Update RTE to 2.37.7 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3064
* Track sub-spans as transactions as well so that we can plot them on a sentry dashboard by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/3066
* Update dependency apple/swift-argument-parser to from: "1.5.0" by @renovate in https://github.com/element-hq/element-x-ios/pull/3065
* Add a certificate validator hook. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/3069
* Set version to 1.7.0 by @Velin92 in https://github.com/element-hq/element-x-ios/pull/3076


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.6.13...1.7.0

## Changes in 1.6.13 (2024-07-04)

### What's Changed

✨ Features
* Add support for editing local echoes and remove redundant failed sent message menu by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/2983
* Allow Element Call's widget URL to be configured by the homeserver. by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/2971
* Volatile draft to restore the composer after an edit. by @Velin92 in https://github.com/element-hq/element-x-ios/pull/2996

🙌 Improvements
* Hide timeline style selection by @Velin92 in https://github.com/element-hq/element-x-ios/pull/2968
* Cleanup how we setup the CallKit provider and have it be used for outgoing calls as well by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/2967

🐛 Bugfixes
* Stop the timeline from requesting back pagination whilst loading existing items. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/2969
* Edit by timeline item only if the event id is missing by @Velin92 in https://github.com/element-hq/element-x-ios/pull/2989
* Add a missing scheme when getting the Element .well-known file. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/2995

🗣 Translations
* Translations update by @RiotRobot in https://github.com/element-hq/element-x-ios/pull/2986

🧱 Build
* Replace Towncrier with GitHub releases + labels. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/2966
* Trigger a Danger CI run when labelling a PR too. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/2972
* Add changelog labels to PRs from Localazy and Renovate. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/2981
* Use XcodeGen files for app variants and setup Enterprise submodule. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/2976
* Setup unit tests for Enterprise. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/2984

Others
* Remove plain style layout by @Velin92 in https://github.com/element-hq/element-x-ios/pull/2980
* Remove layout styling abstraction by @Velin92 in https://github.com/element-hq/element-x-ios/pull/2982
* Setup Sentry instrumentation on top of the existing Signposter by @stefanceriu in https://github.com/element-hq/element-x-ios/pull/2985
* Update the SDK. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/2987
* Add a bug report hook. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/2988
* Use the same format for project.yml as Ruby's YAML output. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/2992
* Update the SDK ready for the release. by @pixlwave in https://github.com/element-hq/element-x-ios/pull/2999


**Full Changelog**: https://github.com/element-hq/element-x-ios/compare/1.6.12...1.6.13

## Changes in 1.6.12 (2024-06-25)

✨ Features

- Draft restoring is enabled by default. ([#2943](https://github.com/element-hq/element-x-ios/pull/2943))

🙌 Improvements

- Adopt the new authentication methods exposed on Rust's Client. ([#2954](https://github.com/element-hq/element-x-ios/pull/2954))

🐛 Bugfixes

- Timestamps in room list inconsistently use absolute and relative formatting ([#2679](https://github.com/element-hq/element-x-ios/issues/2679))

## Changes in 1.6.11 (2024-06-18)

No significant changes.


## Changes in 1.6.10 (2024-06-18)

✨ Features

- Composer drafts will now be saved upon leaving the screen, and get restored later when displayed again. ([#2849](https://github.com/element-hq/element-x-ios/issues/2849))

🙌 Improvements

- Allow timeline messages text selection on both the Mac and on iOS (not on long press but a double tap) ([#2924](https://github.com/element-hq/element-x-ios/issues/2924))

## Changes in 1.6.9 (2024-06-11)

✨ Features

- Adopt new automatically retrying message sending queue ([#2842](https://github.com/element-hq/element-x-ios/issues/2842))

🐛 Bugfixes

- Room membership state changes will use the display name whenever possible. ([#2846](https://github.com/element-hq/element-x-ios/issues/2846))

Others

- Add a flag for Forks to disable hidden profiles for ignored users ([#2892](https://github.com/element-hq/element-x-ios/pull/2892))
- Rageshake | Add device public curve25519 and ed25519 keys info to rageshake. ([#2550](https://github.com/element-hq/element-x-ios/issues/2550))

## Changes in 1.6.8 (2024-05-17)

🙌 Improvements

- DM Details UI has been updated. ([#2813](https://github.com/element-hq/element-x-ios/issues/2813))

🐛 Bugfixes

- Add missing Forgot PIN option when asked to unlock the Screen Lock settings. ([#2688](https://github.com/element-hq/element-x-ios/issues/2688))
- Fix voice message recoder not showing send message button ([#2845](https://github.com/element-hq/element-x-ios/issues/2845))

## Changes in 1.6.7 (2024-05-13)

🙌 Improvements

- Display message bodies (file names) next to attachment previews ([#2800](https://github.com/element-hq/element-x-ios/issues/2800))
- Room details have been updated. ([#2812](https://github.com/element-hq/element-x-ios/issues/2812))
- The UX of the profile of other users has been updated. ([#2816](https://github.com/element-hq/element-x-ios/issues/2816))

🐛 Bugfixes

- Render matrix URIs as links so they can be tapped. ([#2802](https://github.com/element-hq/element-x-ios/issues/2802))
- Show a failure toast when alias look-up fails. ([#2825](https://github.com/element-hq/element-x-ios/issues/2825))

## Changes in 1.6.5 (2024-05-09)

🙌 Improvements

- Reorder available composer menu actions ([#2790](https://github.com/element-hq/element-x-ios/issues/2790))

🐛 Bugfixes

- Only register for notifications when the setting is enabled. ([#2721](https://github.com/element-hq/element-x-ios/issues/2721))
- Prevent the message sending failure options from showing up as a popup on the room list on iPads ([#2808](https://github.com/element-hq/element-x-ios/issues/2808))

## Changes in 1.6.4 (2024-05-07)

✨ Features

- Support navigating to permalinks and replies. ([#2748](https://github.com/element-hq/element-x-ios/pull/2748))
- Impement suggestion and pill support on the plain text composer ([#2751](https://github.com/element-hq/element-x-ios/pull/2751))
- Add specific UX for Expected UTDs due to membership ([#2740](https://github.com/element-hq/element-x-ios/issues/2740))
- Use the keyboard up arrow to edit the last message, use escape to cancel editing or replying. ([#2765](https://github.com/element-hq/element-x-ios/issues/2765))

🙌 Improvements

- Prevent the app from locking while recording a voice message ([#2707](https://github.com/element-hq/element-x-ios/issues/2707))
- Use an animation when scrolling to a nearby timeline item. ([#2757](https://github.com/element-hq/element-x-ios/issues/2757))
- The settings screen design has slightly changed order and grouping of the options. ([#2789](https://github.com/element-hq/element-x-ios/issues/2789))

🐛 Bugfixes

- If button shapes are enabled, emojis are now displayed properly in the menu. ([#2406](https://github.com/element-hq/element-x-ios/issues/2406))
- Fixed a bug that added an extra newline between the name and a formatted text in an emote. ([#2503](https://github.com/element-hq/element-x-ios/issues/2503))
- Fix room list looping and fighting scrolling after filtering ([#2652](https://github.com/element-hq/element-x-ios/issues/2652))
- Fix deeplinking/navigating into the same room multiple times ([#2653](https://github.com/element-hq/element-x-ios/issues/2653))
- Fix a bug where avatars were missing from the RoomChangeRolesScreen. ([#2713](https://github.com/element-hq/element-x-ios/issues/2713))
- Fix a bug where tapping the same permalink a second time didn't do anything. ([#2758](https://github.com/element-hq/element-x-ios/issues/2758))
- Scrolling to the bottom after sending a message should also go live if necessary. ([#2760](https://github.com/element-hq/element-x-ios/issues/2760))
- Handle plain room aliases as permalinks. ([#2762](https://github.com/element-hq/element-x-ios/issues/2762))
- Add missing padding on the permalink highlight. ([#2764](https://github.com/element-hq/element-x-ios/issues/2764))

Others

- Bump posthog sdk version to 3.2.0 ([#2788](https://github.com/element-hq/element-x-ios/issues/2788))

## Changes in 1.6.3 (2024-04-15)

🙌 Improvements

- Add a UserProfileScreen to handle permalinks for users that aren't in the current room. ([#2634](https://github.com/element-hq/element-x-ios/issues/2634))

🚧 In development 🚧

- QR Code login screen displays now the camera view. ([#2674](https://github.com/element-hq/element-x-ios/pull/2674))

## Changes in 1.6.2 (2024-04-09)

✨ Features

- Implement public room search list pagination and room joining ([#2518](https://github.com/element-hq/element-x-ios/issues/2518))
- Added a view that explains how to reset your recovery key in case the user forgot it. ([#2647](https://github.com/element-hq/element-x-ios/issues/2647))

🙌 Improvements

- Allow a room to push another room onto the navigation stack instead of replacing itself. ([#2587](https://github.com/element-hq/element-x-ios/issues/2587))
- Add trophy icon next to the winning poll option ([#2609](https://github.com/element-hq/element-x-ios/issues/2609))

🐛 Bugfixes

- Fix ReplyView when its content has been redacted. ([#2396](https://github.com/element-hq/element-x-ios/issues/2396))
- The message composer now correctly recognises when it is empty after deleting a space or a new line. ([#2538](https://github.com/element-hq/element-x-ios/issues/2538))
- Fix pushers not being registered on re-login after recent Onboarding changes ([#2602](https://github.com/element-hq/element-x-ios/issues/2602))
- Fix room permalink building, allow dashes in room identifiers ([#2618](https://github.com/element-hq/element-x-ios/issues/2618))
- Prevent crashes when mentioning users when running on the Mac ([#2627](https://github.com/element-hq/element-x-ios/issues/2627))

🚧 In development 🚧

- Bug fixes on the moderation feature. ([#2608](https://github.com/element-hq/element-x-ios/pull/2608))
- QR Code login view first step implemented. ([#2667](https://github.com/element-hq/element-x-ios/pull/2667))
- Added an FF for QR code login, and a CTA in the auth screen, to start the flow. ([#2621](https://github.com/element-hq/element-x-ios/issues/2621))

## Changes in 1.6.1 (2024-03-25)

🐛 Bugfixes

- Fix a bug where the new messages in a room weren't always shown until your re-opened the room. ([#2605](https://github.com/element-hq/element-x-ios/pull/2605))

## Changes in 1.6.0 (2024-03-22)

✨ Features

- Introduce a new notification permissions screen as part of the onboarding flows ([#2593](https://github.com/element-hq/element-x-ios/issues/2593))

🙌 Improvements

- Move session verification to the onboarding flows, make it mandatory ([#2592](https://github.com/element-hq/element-x-ios/issues/2592))
- Remove the outdated welcome screen ([#2594](https://github.com/element-hq/element-x-ios/issues/2594))
- Update onboarding flows to consolidate identity confirmation, analytics consent and notification permissions ([#2595](https://github.com/element-hq/element-x-ios/issues/2595))

🚧 In development 🚧

- Room directory search to search public rooms can now be accessed and used for searching, with no pagination yet. Only available in nightly. ([#2585](https://github.com/element-hq/element-x-ios/pull/2585))

## Changes in 1.5.12 (2024-03-14)

Others

- Stop showing that a user's role has changed in the room timeline. ([#2359](https://github.com/element-hq/element-x-ios/issues/2359))

## Changes in 1.5.11 (2024-03-12)

✨ Features

- The features: Filters, Mark as Read/Unread/Favourites are now available. ([#2541](https://github.com/element-hq/element-x-ios/pull/2541))
- Added support for `m.call.invite` events in the timeline, room list and notifications ([#1837](https://github.com/element-hq/element-x-ios/issues/1837))
- Add a blocked users section in the app settings ([#2486](https://github.com/element-hq/element-x-ios/issues/2486))

🙌 Improvements

- Inline predictions have been disabled on iOS 17 temporarily to avoid issues with the text editor. ([#2558](https://github.com/element-hq/element-x-ios/pull/2558))

🐛 Bugfixes

- Don't pass a URL as a log destination to rust on macOS ([#2506](https://github.com/element-hq/element-x-ios/pull/2506))
- Fix a bug where some avatar backgrounds were hard to see in notifications. ([#2514](https://github.com/element-hq/element-x-ios/pull/2514))
- Fix crashes when blocking/unblocking users ([#2553](https://github.com/element-hq/element-x-ios/pull/2553))

🚧 In development 🚧

- Create the Roles and Permissions screen. ([#2505](https://github.com/element-hq/element-x-ios/pull/2505))
- Searching hides and ignores filtering now. ([#2530](https://github.com/element-hq/element-x-ios/pull/2530))
- Add RoomChangeRolesScreen. ([#2356](https://github.com/element-hq/element-x-ios/issues/2356))
- Add RoomChangePermissionsScreen. ([#2358](https://github.com/element-hq/element-x-ios/issues/2358))
- Added an empty state view when the filter returns no rooms. ([#2522](https://github.com/element-hq/element-x-ios/issues/2522))

Others

- Remove the special log level for the Rust SDK read receipts. ([#2544](https://github.com/element-hq/element-x-ios/issues/2544))

## Changes in 1.5.10 (2024-02-27)

No significant changes.


## Changes in 1.5.9 (2024-02-27)

🙌 Improvements

- Handover log file management to Rust. ([#2495](https://github.com/element-hq/element-x-ios/pull/2495))
- Add support for latest iPhones in the User Agent. Also correctly identify when running on a Mac. ([#2496](https://github.com/element-hq/element-x-ios/pull/2496))
- Add error messages about refresh tokens and an invalid well-known file. ([#2497](https://github.com/element-hq/element-x-ios/pull/2497))
- Tapping on the user's own avatar in the Home Screen will now bring them directly to the settings screen. ([#2393](https://github.com/element-hq/element-x-ios/issues/2393))

🚧 In development 🚧

- Favourite filter implemented. ([#2484](https://github.com/element-hq/element-x-ios/pull/2484))
- Implement support for (un)marking rooms as favourite from the room list and room detail screens ([#2320](https://github.com/element-hq/element-x-ios/issues/2320))
- Add support for kicking and banning room members. ([#2357](https://github.com/element-hq/element-x-ios/issues/2357))

Others

- Refactor AvatarHeaderView. ([#2490](https://github.com/element-hq/element-x-ios/pull/2490))

## Changes in 1.5.8 (2024-02-19)

✨ Features

- Add the list of banned users, shown to room members who have the power ban/unban. ([#2355](https://github.com/element-hq/element-x-ios/issues/2355))

🙌 Improvements

- Replaced the share my location button icon with the iOS share icon. ([#1486](https://github.com/element-hq/element-x-ios/issues/1486))

## Changes in 1.5.7 (2024-02-16)

🐛 Bugfixes

- Fixed link colours inside code blocks. ([#2379](https://github.com/element-hq/element-x-ios/issues/2379))

## Changes in 1.5.6 (2024-02-14)

✨ Features

- Show admins and moderators in the room member list. ([#2355](https://github.com/element-hq/element-x-ios/issues/2355))
- Add support for manually marking a room as read/unread ([#2360](https://github.com/element-hq/element-x-ios/issues/2360))

🙌 Improvements

- The timeline will filter some unnecessary state events. ([#2404](https://github.com/element-hq/element-x-ios/issues/2404))
- Move member loading to the room member detail screen, avoid blocking the whole application ([#2414](https://github.com/element-hq/element-x-ios/issues/2414))
- Allow text selection on the timeline item menu header ([#2416](https://github.com/element-hq/element-x-ios/issues/2416))

🐛 Bugfixes

- Prevent crashes when computing aspect ratios on zero media width or height ([#2437](https://github.com/element-hq/element-x-ios/pull/2437))
- Fixed RTE not retaining content when transitioning from a split navigation to a stack navigation. ([#2364](https://github.com/element-hq/element-x-ios/issues/2364))
- SAS Emojis are now localised. ([#2402](https://github.com/element-hq/element-x-ios/issues/2402))
- Long pressing a link will give the preview and the context menu to copy it (or open it in Safari). ([#2440](https://github.com/element-hq/element-x-ios/issues/2440))

⚠️ API Changes

- Remove unnecessary analytics abstraction levels, directly create analytics events in the analytics service ([#2408](https://github.com/element-hq/element-x-ios/pull/2408))

🚧 In development 🚧

- All Filters have been implemented, except for the Favourites one. ([#2423](https://github.com/element-hq/element-x-ios/pull/2423))

## Changes in 1.5.5 (2024-01-30)

✨ Features

- Added an advanced setting to turn off sending read receipts. ([#2319](https://github.com/element-hq/element-x-ios/issues/2319))
- Allow partial text selection in the timeline item view source menu ([#2378](https://github.com/element-hq/element-x-ios/issues/2378))

🐛 Bugfixes

- If a refresh token is found in a non OIDC session, the app will be logged out. ([#2365](https://github.com/element-hq/element-x-ios/issues/2365))

🚧 In development 🚧

- Room list filters UI (does not have any impact on the room list yet) ([#2382](https://github.com/element-hq/element-x-ios/pull/2382))

## Changes in 1.5.4 (2024-01-25)

✨ Features

- Enable log previewing before reporting a problem ([#734](https://github.com/element-hq/element-x-ios/issues/734))

🙌 Improvements

- Unread messages that do not trigger notifications, will show a grey dot in the room list. ([#2371](https://github.com/element-hq/element-x-ios/pull/2371))
- Removed unnecessary state events for DMs. ([#2329](https://github.com/element-hq/element-x-ios/issues/2329))
- Change Leave Room to Leave Conversation for DMs ([#2330](https://github.com/element-hq/element-x-ios/issues/2330))

🐛 Bugfixes

- Bugfix for the mention badge not being unset properly when opening the room. Also the mention badge is enabled by default. ([#2367](https://github.com/element-hq/element-x-ios/pull/2367))
- You can't redact a message of your own if the room does not allow it. ([#2368](https://github.com/element-hq/element-x-ios/pull/2368))
- Is now possible to take photos in landscape mode. ([#1815](https://github.com/element-hq/element-x-ios/issues/1815))

## Changes in 1.5.3 (2024-01-17)

✨ Features

- Automatically focus the composer when a hardware keyboards is connected ([#1911](https://github.com/element-hq/element-x-ios/issues/1911))

🐛 Bugfixes

- Prevent the same WebView from being reused for multiple Element Call links ([#2325](https://github.com/element-hq/element-x-ios/issues/2325))
- Fixed a bug that made the app crash when dictation ended. ([#2344](https://github.com/element-hq/element-x-ios/issues/2344))

## Changes in 1.5.2 (2024-01-16)

✨ Features

- Added back the mention badge option but only behind a feature flag. ([#2281](https://github.com/element-hq/element-x-ios/issues/2281))
- Allow copying user display names on the room member details screen ([#2333](https://github.com/element-hq/element-x-ios/issues/2333))

🙌 Improvements

- Added the user id in the room members list cells, to avoid ambiguity. ([#2332](https://github.com/element-hq/element-x-ios/pull/2332))

🐛 Bugfixes

- Improved plain text mode stability. ([#2327](https://github.com/element-hq/element-x-ios/pull/2327))
- Fix for dictation not working properly in RTE mode. ([#2030](https://github.com/element-hq/element-x-ios/issues/2030))
- Composer won't reset its content the app is backgrounded on iPad. ([#2275](https://github.com/element-hq/element-x-ios/issues/2275))
- Fix timeline entries flickering when a lot of mention pills present ([#2286](https://github.com/element-hq/element-x-ios/issues/2286))
- Fix wrong notification placeholder avatar orientation on 17.2.1 ([#2291](https://github.com/element-hq/element-x-ios/issues/2291))
- Trying to edit messages containing links with angle brackets doesn't pre-populate the message composer ([#2296](https://github.com/element-hq/element-x-ios/issues/2296))
- Fix room messages coming in as push notifications when inside a room when entering it from the invites list ([#2302](https://github.com/element-hq/element-x-ios/issues/2302))
- Fix for read receipts loading slowly when opening a room. ([#2304](https://github.com/element-hq/element-x-ios/issues/2304))
- Fix reporting content screen not being displayed ([#2306](https://github.com/element-hq/element-x-ios/issues/2306))

🚧 In development 🚧

- Enable database encryption for new logins on Nightly/PR builds. ([#441](https://github.com/element-hq/element-x-ios/issues/441))

## Changes in 1.5.1 (2023-12-22)

No significant changes.


## Changes in 1.5.0 (2023-12-21)

✨ Features

- When mentioned in a room, the room list will display a green at symbol for that room. ([#1823](https://github.com/element-hq/element-x-ios/issues/1823))
- The poll history can be viewed in the room details. ([#2230](https://github.com/element-hq/element-x-ios/issues/2230))

🙌 Improvements

- Add notification toggle for invitations. ([#2205](https://github.com/element-hq/element-x-ios/issues/2205))
- Removed redundant options from the home menu. ([#2250](https://github.com/element-hq/element-x-ios/issues/2250))

🐛 Bugfixes

- Don't keep throwing an error each time the user dismisses the error's alert when sharing a location. ([#2233](https://github.com/element-hq/element-x-ios/pull/2233))
- Fix for plain text mode, using the RTE markdown to html conversion properly. ([#2246](https://github.com/element-hq/element-x-ios/pull/2246))
- Detect links in room detail topics and make it more obvious when the text is truncated ([#2210](https://github.com/element-hq/element-x-ios/issues/2210))
- Poll title is displayed in multiline when creating a poll. ([#2215](https://github.com/element-hq/element-x-ios/issues/2215))
- Fix timeline thumbnail frames for media missing sizing info ([#2253](https://github.com/element-hq/element-x-ios/issues/2253))
- Fix flipped notification placeholder avatars on iOS 17.2+ ([#2259](https://github.com/element-hq/element-x-ios/issues/2259))
- Options in poll form creation can be multiline. ([#2273](https://github.com/element-hq/element-x-ios/issues/2273))

🧱 Build

- Update most references of the old vector-im organisation to the new element-hq one. ([#2231](https://github.com/element-hq/element-x-ios/pull/2231))
- Add support for InfoPlist.strings conversion from Localazy. ([#2100](https://github.com/element-hq/element-x-ios/issues/2100))

## Changes in 1.4.3 (2023-12-05)

✨ Features

- Open direct chat directly from the room member details screen ([#2179](https://github.com/vector-im/element-x-ios/issues/2179))

🙌 Improvements

- Automatically pop the invites list when acting on the last one. Coming back from the room will go directly back to the room list ([#2165](https://github.com/vector-im/element-x-ios/pull/2165))
- Use the Compound List component on PollFormScreen. ([#2183](https://github.com/vector-im/element-x-ios/pull/2183))
- Show a loading indicator while searching for people to invite ([#1950](https://github.com/vector-im/element-x-ios/issues/1950))
- Mentioned notifications have a new less verbose copy. ([#2139](https://github.com/vector-im/element-x-ios/issues/2139))
- Hide pin code in lock screen setup mode ([#2145](https://github.com/vector-im/element-x-ios/issues/2145))
- Automatically scroll the timeline to the bottom when sending a message ([#2147](https://github.com/vector-im/element-x-ios/issues/2147))

🐛 Bugfixes

- Fixed a crash that happened when leaving a room through the details screen. ([#2160](https://github.com/vector-im/element-x-ios/pull/2160))
- Fix room avatars not showing up on the message forwarding screen ([#2168](https://github.com/vector-im/element-x-ios/pull/2168))
- Fixed an issue where the text cursor was not positioned correctly. ([#1674](https://github.com/vector-im/element-x-ios/issues/1674))
- Improved the wrapping of the text for File and Audio timeline items. ([#1810](https://github.com/vector-im/element-x-ios/issues/1810))
- Lists at the beginning of messages were displayed incorrectly. ([#1915](https://github.com/vector-im/element-x-ios/issues/1915))
- Remove rooms from the room list after leaving them ([#2005](https://github.com/vector-im/element-x-ios/issues/2005))
- Fixed some issues with voice messages when sent from a bridge. ([#2006](https://github.com/vector-im/element-x-ios/issues/2006))
- Fix the touch area size for the voice message button. ([#2038](https://github.com/vector-im/element-x-ios/issues/2038))
- Fix a bug where cancelling Face ID unlock would loop back round and present Face ID again. ([#2134](https://github.com/vector-im/element-x-ios/issues/2134))
- Fixed a bug that made iOS 17 render avatars sideways in notifications. ([#2136](https://github.com/vector-im/element-x-ios/issues/2136))
- Fix a crash when blocking/unblocking a user from the DM details screen. ([#2140](https://github.com/vector-im/element-x-ios/issues/2140))
- If an invite notification has already been accepted tapping on it will bring you to the invite screen. ([#2150](https://github.com/vector-im/element-x-ios/issues/2150))
- Fix the room attachment popover label colour when using the in-app appearance override. ([#2157](https://github.com/vector-im/element-x-ios/issues/2157))
- Fixed a crash when sending voice messages on some Apple devices. ([#2184](https://github.com/vector-im/element-x-ios/issues/2184))

🧱 Build

- Adopt Xcode 15 (sticking with iOS 16 simulator on CI). ([#2007](https://github.com/vector-im/element-x-ios/pull/2007))

## Changes in 1.4.2 (2023-11-21)

✨ Features

- Expose message actions to voice over rotor ([#660](https://github.com/vector-im/element-x-ios/issues/660))
- Tapping on read receipts will open a detailed sheet of all the receipts. ([#1053](https://github.com/vector-im/element-x-ios/issues/1053))
- Added a disclaimer on the Mentions Only option for notifications, so that the user will know if it will work properly or not on their home server. ([#2078](https://github.com/vector-im/element-x-ios/issues/2078))
- Expose options for overriding the system appearance in the advanced settings menu ([#2083](https://github.com/vector-im/element-x-ios/issues/2083))
- The voice message playback position indicator is displayed during playback or pause. ([#2190](https://github.com/vector-im/element-x-ios/issues/2190))

🙌 Improvements

- Add SwiftLint rule to enforce stack spacing. ([#2080](https://github.com/vector-im/element-x-ios/pull/2080))
- Use Compound List in Start Chat and Room Member Details screens. ([#2099](https://github.com/vector-im/element-x-ios/pull/2099))
- Read Receipts are enabled by default. ([#2123](https://github.com/vector-im/element-x-ios/pull/2123))
- Use more Compound icons throughout the app. ([#2002](https://github.com/vector-im/element-x-ios/issues/2002))
- Show the lock screen placeholder whenever the app resigns as active. ([#2026](https://github.com/vector-im/element-x-ios/issues/2026))
- Update the Welcome Screen to the latest designs. ([#2053](https://github.com/vector-im/element-x-ios/issues/2053))

🐛 Bugfixes

- Fix a regression where the forced logout indicator was presented on the hidden overlay window. ([#2063](https://github.com/vector-im/element-x-ios/pull/2063))
- Don't show the call button on macOS. ([#2064](https://github.com/vector-im/element-x-ios/pull/2064))
- Fix for the status bar being visible during UI tests. ([#2065](https://github.com/vector-im/element-x-ios/pull/2065))
- Fix room list search bar focus glitches ([#2112](https://github.com/vector-im/element-x-ios/pull/2112))
- Added proper accessibility to read receipts. ([#1139](https://github.com/vector-im/element-x-ios/issues/1139))
- Added a small artificial delay when resending a failed message if it fails instantly, for better UX. ([#1352](https://github.com/vector-im/element-x-ios/issues/1352))
- Remove push notification registration on logout ([#1619](https://github.com/vector-im/element-x-ios/issues/1619))
- Fix an animation glitch when signing in on iOS 16. ([#1807](https://github.com/vector-im/element-x-ios/issues/1807))
- Long replies no longer overlay the replied message. ([#1832](https://github.com/vector-im/element-x-ios/issues/1832))
- Fix a bug where tapping a call link could open the call with a keyboard obscuring the sheet. ([#2025](https://github.com/vector-im/element-x-ios/issues/2025))
- Fix speech to text not working properly in RTE. ([#2030](https://github.com/vector-im/element-x-ios/issues/2030))
- Prevent the room list from staying empty after cancelling a search ([#2040](https://github.com/vector-im/element-x-ios/issues/2040))
- Prevent QuickLook from breaking media uploading on Mac, replace the preview with a plain filename label ([#2058](https://github.com/vector-im/element-x-ios/issues/2058))
- Prevent crashes when inserting mention pills in the composers on Mac ([#2070](https://github.com/vector-im/element-x-ios/issues/2070))
- Disable underlining for links defined in the html body ([#2117](https://github.com/vector-im/element-x-ios/issues/2117))

## Changes in 1.4.1 (2023-11-07)

🙌 Improvements

- Set the App Lock grace period to 0. ([#2011](https://github.com/vector-im/element-x-ios/issues/2011))

🐛 Bugfixes

- Use the custom log level inside the NSE too. ([#2020](https://github.com/vector-im/element-x-ios/pull/2020))
- Fixed a memory leak that made the NSE crash. ([#1923](https://github.com/vector-im/element-x-ios/issues/1923))
- Fixed a bug that made the RTE color change when using mentions in dark mode. ([#2009](https://github.com/vector-im/element-x-ios/issues/2009))
- Make sure the last digit is visible when entering a PIN. ([#2010](https://github.com/vector-im/element-x-ios/issues/2010))
- Fix an inconsistency in the App Lock screen's background colour. ([#2029](https://github.com/vector-im/element-x-ios/issues/2029))
- Don't allow the Placeholder Screen layout to be influenced by the keyboard. ([#2032](https://github.com/vector-im/element-x-ios/issues/2032))

## Changes in 1.4.0 (2023-10-31)

✨ Features

- Add support for running Element Calls through Rust side widgets ([#1906](https://github.com/vector-im/element-x-ios/pull/1906))
- Pills for user mentions and the completion suggestion view are now enabled. ([#1971](https://github.com/vector-im/element-x-ios/pull/1971))
- Allow the app to be locked with a PIN code or Touch/Face ID. ([#1990](https://github.com/vector-im/element-x-ios/pull/1990))
- All users mention @room now appears in the completion suggestion view. ([#1875](https://github.com/vector-im/element-x-ios/issues/1875))
- Enable Element Call for all users. ([#1983](https://github.com/vector-im/element-x-ios/issues/1983))

🙌 Improvements

- Remove DesignKit package. ([#1886](https://github.com/vector-im/element-x-ios/pull/1886))
- Update Compound and use new pill colours. ([#1989](https://github.com/vector-im/element-x-ios/pull/1989))

🐛 Bugfixes

- Revert the OIDC redirect URL back to using a custom scheme. ([#1936](https://github.com/vector-im/element-x-ios/issues/1936))

🚧 In development 🚧

- Initial service implementation for using a PIN code ([#1912](https://github.com/vector-im/element-x-ios/pull/1912))
- Add the App Lock settings screen. ([#1917](https://github.com/vector-im/element-x-ios/pull/1917))
- Implement the AppLockScreen as per the designs. ([#1925](https://github.com/vector-im/element-x-ios/pull/1925))
- Add PIN entry screen for creating/accessing PIN settings. ([#1930](https://github.com/vector-im/element-x-ios/pull/1930))
- Add Biometrics screen for enabling Touch/Face ID after creating a PIN. ([#1942](https://github.com/vector-im/element-x-ios/pull/1942))
- Add an AppLockSetupFlowCoordinator for creating a PIN with both mandatory and optional flows. ([#1949](https://github.com/vector-im/element-x-ios/pull/1949))
- Add support for Face ID/Touch ID to app lock. ([#1966](https://github.com/vector-im/element-x-ios/pull/1966))
- Handle invalid PIN input in the settings flow. ([#1972](https://github.com/vector-im/element-x-ios/pull/1972))
- Fix a bug when setting up App Lock if biometrics aren't available. ([#1981](https://github.com/vector-im/element-x-ios/pull/1981))
- Enforce mandatory app lock outside of the authentication flow. ([#1982](https://github.com/vector-im/element-x-ios/pull/1982))

## Changes in 1.3.3 (2023-10-12)

🚧 In development 🚧

- Initial setup for PIN/Biometric app lock. ([#1876](https://github.com/vector-im/element-x-ios/pull/1876))


## Changes in 1.3.2 (2023-10-10)

✨ Features

- Tapping on matrix room id link brings you to that room. ([#1853](https://github.com/vector-im/element-x-ios/pull/1853))
- User mentions pills (behind a Feature Flag). ([#1804](https://github.com/vector-im/element-x-ios/issues/1804))
- Added the user suggestions view when trying to mention a user (but it doesn't react to tap yet). ([#1826](https://github.com/vector-im/element-x-ios/issues/1826))
- @room mention pill, and own mentions are red. ([#1829](https://github.com/vector-im/element-x-ios/issues/1829))
- Implement /me ([#1841](https://github.com/vector-im/element-x-ios/issues/1841))
- Report rust tracing configuration filter in rageshakes ([#1861](https://github.com/vector-im/element-x-ios/issues/1861))

🙌 Improvements

- Use a universal link for OIDC callbacks. ([#1734](https://github.com/vector-im/element-x-ios/issues/1734))

🐛 Bugfixes

- Add remaining iOS 17 introspections. ([#1798](https://github.com/vector-im/element-x-ios/issues/1798))
- Redirect universal links directly to the browser if they're not supported ([#1824](https://github.com/vector-im/element-x-ios/issues/1824))
- Fix message forwarding room list filtering and pagination problems ([#1864](https://github.com/vector-im/element-x-ios/issues/1864))


## Changes in 1.3.1 (2023-09-27)

🙌 Improvements

- Removed the `Reply in Thread` string in the swipe to reply action. ([#1795](https://github.com/vector-im/element-x-ios/pull/1795))
- Update icons to use Compound in more places (bundling some that aren't yet prepared as tokens). ([#1706](https://github.com/vector-im/element-x-ios/issues/1706))


## Changes in 1.3.0 (2023-09-20)

No significant changes.


## Changes in 1.2.9 (2023-09-18)

✨ Features

- Messages that are part of a thread will be marked with a thread decorator. ([#1686](https://github.com/vector-im/element-x-ios/issues/1686))
- Introduce a new advanced settings screen ([#1699](https://github.com/vector-im/element-x-ios/issues/1699))

🙌 Improvements

- Revert to using a Web Authentication Session for OIDC account management. ([#1634](https://github.com/vector-im/element-x-ios/pull/1634))
- Hook up universal links to the App Coordinator (this doesn't actually handle them yet). ([#1638](https://github.com/vector-im/element-x-ios/pull/1638))
- Separate Manage account from Manage devices ([#1698](https://github.com/vector-im/element-x-ios/pull/1698))
- Update app icon. ([#1720](https://github.com/vector-im/element-x-ios/pull/1720))
- Enable token refresh in the NSE (and notifications for OIDC accounts). ([#1712](https://github.com/vector-im/element-x-ios/issues/1712))

🐛 Bugfixes

- Add default schemes for detected links that don't have any ([#1651](https://github.com/vector-im/element-x-ios/pull/1651))
- The bloom does not pop in but fades in. ([#1705](https://github.com/vector-im/element-x-ios/pull/1705))
- Various accessibility fixes: add labels on timeline media, hide swipe to reply button, add sender on all messages, improve replies and reactions ([#1104](https://github.com/vector-im/element-x-ios/issues/1104))
-  ([#1198](https://github.com/vector-im/element-x-ios/issues/1198))
- Add copy permalink option for messages that failed decryption ([#1338](https://github.com/vector-im/element-x-ios/issues/1338))
- Viewing reaction details UI fails to switch between multiple reactions ([#1552](https://github.com/vector-im/element-x-ios/issues/1552))
- Add missing contacts field to OIDC configuration. ([#1653](https://github.com/vector-im/element-x-ios/issues/1653))
- Fix avatar button size and make mxid copyable in Room/Member details screens. ([#1669](https://github.com/vector-im/element-x-ios/issues/1669))
- Correctly parse markdown and html received in push notifications ([#1679](https://github.com/vector-im/element-x-ios/issues/1679))


## Changes in 1.2.8 (2023-09-01)

🙌 Improvements

- New avatar colouring + username colouring. ([#1603](https://github.com/vector-im/element-x-ios/issues/1603))

🐛 Bugfixes

- Fix the size of the generated thumbnail when uploading media ([#980](https://github.com/vector-im/element-x-ios/issues/980))
- Avatar colouring is aligned to web. ([#1345](https://github.com/vector-im/element-x-ios/issues/1345))


## Changes in 1.2.7 (2023-08-31)

🙌 Improvements

- Use Safari for OIDC account management. ([#1591](https://github.com/vector-im/element-x-ios/pull/1591))
- New room button has been moved to the top. ([#1602](https://github.com/vector-im/element-x-ios/issues/1602))

🐛 Bugfixes

- Improve timestamp rendering when mixed LTR and RTL languages are present in the message. ([#1539](https://github.com/vector-im/element-x-ios/pull/1539))
- Fixed a bug that made the spring board crash when trying to mute notifications. ([#1519](https://github.com/vector-im/element-x-ios/issues/1519))
- Add app logo and fix terms link for OIDC login (only affects fresh app installs). ([#1547](https://github.com/vector-im/element-x-ios/issues/1547))
- Fixed a bug that made a magnifying glass appear when long pressing a message. ([#1581](https://github.com/vector-im/element-x-ios/issues/1581))


## Changes in 1.2.6 (2023-08-22)

✨ Features

- Enable OIDC support, with notification content disabled for now. ([#261](https://github.com/vector-im/element-x-ios/issues/261))

🐛 Bugfixes

- Fix for voice over reading braille dot at the end of a message. ([#1538](https://github.com/vector-im/element-x-ios/pull/1538))


## Changes in 1.2.5 (2023-08-18)

No significant changes.


## Changes in 1.2.4 (2023-08-18)

✨ Features

- Allow fuzzy searching for room list rooms ([#1483](https://github.com/vector-im/element-x-ios/pull/1483))

🙌 Improvements

- Use Compound ListRow instead of .xyzStyle(.compoundRow) ([#1484](https://github.com/vector-im/element-x-ios/pull/1484))


## Changes in 1.2.3 (2023-08-10)

✨ Features

- Re-enabled background app refreshes ([#1462](https://github.com/vector-im/element-x-ios/pull/1462))
- Re-enabled the room list cache and offline mode support ([#1461](https://github.com/vector-im/element-x-ios/issues/1461))

🐛 Bugfixes

- Fixed crash when trying to reply to media files ([#1472](https://github.com/vector-im/element-x-ios/pull/1472))
- Prevent inconsistent view hierarchies when opening rooms from push notifications ([#1140](https://github.com/vector-im/element-x-ios/issues/1140))
- Preserve new lines within the same paragraph when parsing html strings ([#1463](https://github.com/vector-im/element-x-ios/issues/1463))


## Changes in 1.2.2 (2023-08-08)

✨ Features

- Display avatars full screen when tapping on them from the room or member detail screens ([#1448](https://github.com/vector-im/element-x-ios/pull/1448))

🐛 Bugfixes

- Fix a bug where media previews would sometimes dismiss to show the timeline with a big empty space at the bottom. ([#1428](https://github.com/vector-im/element-x-ios/pull/1428))
- Send read receipts as messages are displayed instead of on opening/closing rooms. ([#639](https://github.com/vector-im/element-x-ios/issues/639))

🧱 Build

- Make CI upload dSyms to Sentry before releasing to GitHub to avoid tagging failed runs. ([#1457](https://github.com/vector-im/element-x-ios/pull/1457))


## Changes in 1.2.1 (2023-08-01)

✨ Features

- Location sharing: view and send static locations. ([#1358](https://github.com/vector-im/element-x-ios/pull/1358))
- Timeline animations. ([#1371](https://github.com/vector-im/element-x-ios/pull/1371))
- Send current user location ([#1272](https://github.com/vector-im/element-x-ios/issues/1272))
- Contact Me switch added to the Bug Report screen. ([#1299](https://github.com/vector-im/element-x-ios/issues/1299))

🙌 Improvements

- Update Room Details to use compound styles everywhere. ([#1369](https://github.com/vector-im/element-x-ios/pull/1369))
- Tweaks for macOS only: Fix Create Room button animation bug / Restore the timeline context menu / Fix media upload preview obscuring send button. ([#1383](https://github.com/vector-im/element-x-ios/pull/1383))
- Make the app version and the device ID copyable in the Settings screen. ([#623](https://github.com/vector-im/element-x-ios/issues/623))

🐛 Bugfixes

- Fix for UI not retaining blocked/unlocked user state after dismissing and re-entering the details from the room member list. ([#910](https://github.com/vector-im/element-x-ios/issues/910))
- Added an FF to enable push rules filtering. Also invitation notifications will now be always displayed reliably. ([#1172](https://github.com/vector-im/element-x-ios/issues/1172))
- Compute correct sizes for portrait videos ([#1262](https://github.com/vector-im/element-x-ios/issues/1262))
- Push notifications for a room are cleared from the notification centre when opening its timeline. Same for invitations when opening the invite screen. ([#1277](https://github.com/vector-im/element-x-ios/issues/1277))
- Fixed wrong icon for files in replies. ([#1319](https://github.com/vector-im/element-x-ios/issues/1319))
- Moderators can now remove other people messages if they have permission in non direct rooms. ([#1321](https://github.com/vector-im/element-x-ios/issues/1321))

🧱 Build

- Don't upgrade more homebrew deps than needed on GitHub runners. ([#1374](https://github.com/vector-im/element-x-ios/pull/1374))
- Specify the target for code coverage in the Integration Tests plan. ([#1398](https://github.com/vector-im/element-x-ios/pull/1398))


## Changes in 1.1.8 (2023-07-05)

✨ Features

- Added a welcome screen that will appear only once. ([#1259](https://github.com/vector-im/element-x-ios/pull/1259))

🙌 Improvements

- Reduce horizonal message bubble padding when the avatar isn't shown ([#1233](https://github.com/vector-im/element-x-ios/pull/1233))
- Push notifications will be displayed as DM only in direct rooms where joined members are at most 2. ([#1205](https://github.com/vector-im/element-x-ios/issues/1205))
- Add encryption history banner. ([#1251](https://github.com/vector-im/element-x-ios/issues/1251))

🐛 Bugfixes

- Caching for the notification placeholder image, to avoid generating it too many times and taking too much memory. ([#1243](https://github.com/vector-im/element-x-ios/issues/1243))


## Changes in 1.1.7 (2023-06-30)

✨ Features

- Push Notifications of rooms/dm without avatars will now display the default placeholder used in app. ([#1168](https://github.com/vector-im/element-x-ios/issues/1168))
- Send pin-drop location ([#1179](https://github.com/vector-im/element-x-ios/issues/1179))

🙌 Improvements

- Improve media preview presentation and interaction in the timeline. ([#1187](https://github.com/vector-im/element-x-ios/pull/1187))
- Update long press gesture animation ([#1195](https://github.com/vector-im/element-x-ios/pull/1195))
- Failed local echoes can be edited, they will just get cancelled and resent with the new content. ([#1207](https://github.com/vector-im/element-x-ios/pull/1207))
- Show a migration screen on the first use of the app whilst the proxy does an initial sync. ([#983](https://github.com/vector-im/element-x-ios/issues/983))
- Delivery status is now displayed only for the last outgoing message. ([#1101](https://github.com/vector-im/element-x-ios/issues/1101))
- Filter out some message actions and reactions for failed local echoes and redacted messages. ([#1151](https://github.com/vector-im/element-x-ios/issues/1151))

🐛 Bugfixes

- Messages that have failed to be decrypted are show only view source and retry decryptions as possible actions. ([#1185](https://github.com/vector-im/element-x-ios/issues/1185))
- Fix for the flipped notification image placeholder on iOS. ([#1194](https://github.com/vector-im/element-x-ios/issues/1194))


## Changes in 1.1.5 (2023-06-26)

✨ Features

- Add analytics tracking for room creation ([#1100](https://github.com/vector-im/element-x-ios/pull/1100))
- Added support for message forwarding ([#978](https://github.com/vector-im/element-x-ios/issues/978))
- Failed to send messages can now be either retried or removed by tapping on the error icon/timestamp. ([#979](https://github.com/vector-im/element-x-ios/issues/979))
- Add MapLibre SDK and the Map View component ([#1062](https://github.com/vector-im/element-x-ios/issues/1062))
- Two sync loop implementation to allow to fetch and update decryption keys also from the NSE. ([#1083](https://github.com/vector-im/element-x-ios/issues/1083))
- Add reverse geocoding request, that for a given coordinate will return the place name. ([#1085](https://github.com/vector-im/element-x-ios/issues/1085))
- Add analytics events. ([#1097](https://github.com/vector-im/element-x-ios/issues/1097))
- Filtering out push notifications for encrypted rooms based on the room push context. ([#1114](https://github.com/vector-im/element-x-ios/issues/1114))
- Add static map url builder and static map UI component with placeholder and reload logic ([#1115](https://github.com/vector-im/element-x-ios/issues/1115))
- Render emote notifications like in the timeline ([#1117](https://github.com/vector-im/element-x-ios/issues/1117))

🙌 Improvements

- Migrate all colour tokens to use Compound and deprecate DesignKit tokens. ([#732](https://github.com/vector-im/element-x-ios/issues/732))
- General app polish. ([#1036](https://github.com/vector-im/element-x-ios/issues/1036))
- Refactored AlertInfo to not use the soon to be deprecated API for alerts anymore. ([#1067](https://github.com/vector-im/element-x-ios/issues/1067))
- Add a screen to be shown when new users are on the waiting list. ([#1154](https://github.com/vector-im/element-x-ios/issues/1154))

🐛 Bugfixes

- Fixed crashes when opening the invites screen ([#1102](https://github.com/vector-im/element-x-ios/issues/1102))
- Disabled push rules filtering temporarily to fix a bug that prevented push notifications from being received. ([#1155](https://github.com/vector-im/element-x-ios/issues/1155))
- Handled the cancelled state of a message properly as a failure state. ([#1160](https://github.com/vector-im/element-x-ios/issues/1160))


## Changes in 1.1.4 (2023-06-13)

🐛 Bugfixes

- Fixed crashes when trying to save media to the photo library ([#1072](https://github.com/vector-im/element-x-ios/issues/1072))


## Changes in 1.1.3 (2023-06-12)

✨ Features

- Timestamp added to non bubbled messages like images and videos for bubble style. ([#1057](https://github.com/vector-im/element-x-ios/pull/1057))
- Read Receipts with avatars will be displayed at the bottom of the messages (only for Nightly, can be enabled in developer settings). ([#1052](https://github.com/vector-im/element-x-ios/issues/1052))

🐛 Bugfixes

- Improved timestamp rendering for RTL and bidirectional mixed text. ([#1055](https://github.com/vector-im/element-x-ios/pull/1055))


## Changes in 1.1.2 (2023-06-08)

✨ Features

- Timestamp for messages incorporated in a bubble. ([#948](https://github.com/vector-im/element-x-ios/issues/948))
- Add the image picker flow for the creation of a room ([#961](https://github.com/vector-im/element-x-ios/issues/961))
- Update reply composer mode UI to include message being replied to ([#976](https://github.com/vector-im/element-x-ios/issues/976))
- Added an `About` section and links to legal information in the application settings ([#1011](https://github.com/vector-im/element-x-ios/issues/1011))
- Tapping on a user avatar/name in the timeline opens the User Details view for that user. ([#1017](https://github.com/vector-im/element-x-ios/issues/1017))

🙌 Improvements

- Improve bug report uploads with file size checks and better error handling. ([#1018](https://github.com/vector-im/element-x-ios/pull/1018))
- Showing the iOS default contact/group silhouette in notifications when the avatar is missing. ([#965](https://github.com/vector-im/element-x-ios/pull/965))

🐛 Bugfixes

- Update PostHog to 2.0.3 to fix the app's accent colour. ([#1006](https://github.com/vector-im/element-x-ios/pull/1006))
- Fix an incorrect colour when replying to a message in dark mode. ([#1007](https://github.com/vector-im/element-x-ios/pull/1007))
- Prevent room navigation back button from jumping while animating ([#945](https://github.com/vector-im/element-x-ios/pull/945))

⚠️ API Changes

- Bump the minimum supported iOS version to 16.4. ([#994](https://github.com/vector-im/element-x-ios/pull/994))


## Changes in 1.1.1 (2023-05-23)

✨ Features

- Redesigned the delivery status icon. ([#921](https://github.com/vector-im/element-x-ios/issues/921))
- Add creation of a room, fetching the summary, so the room will be ready to be presented. ([#925](https://github.com/vector-im/element-x-ios/issues/925))

🐛 Bugfixes

- Stopping bg task when the app is suspended and the slidingSyncObserver is finished. ([#438](https://github.com/vector-im/element-x-ios/issues/438))
- Added the context menu to the plain style. ([#686](https://github.com/vector-im/element-x-ios/issues/686))


## Changes in 1.1.0 (2023-05-18)

✨ Features

- Add the entry point for the Start a new Chat flow, with button on home Screen and first page ([#680](https://github.com/vector-im/element-x-ios/pull/680))
- Show or create direct message room ([#716](https://github.com/vector-im/element-x-ios/pull/716))
- Add background app refresh support ([#892](https://github.com/vector-im/element-x-ios/pull/892))
- Adopt compound-ios on the Settings and Bug Report screens. ([#43](https://github.com/vector-im/element-x-ios/issues/43))
- Set up Analytics to track data. ([#106](https://github.com/vector-im/element-x-ios/issues/106))
- Add Localazy to the project for strings. ([#124](https://github.com/vector-im/element-x-ios/issues/124))
- Add user search when creating a new dm room. ([#593](https://github.com/vector-im/element-x-ios/issues/593))
- Add invites list (UI only) ([#605](https://github.com/vector-im/element-x-ios/issues/605))
- Users can accept and decline invites. ([#621](https://github.com/vector-im/element-x-ios/issues/621))
- Added unread badges in the invites list. ([#714](https://github.com/vector-im/element-x-ios/issues/714))
- Added the Room Member Details Screen. ([#723](https://github.com/vector-im/element-x-ios/issues/723))
- Ignore User functionality added in the Room Member Details View. ([#733](https://github.com/vector-im/element-x-ios/issues/733))
- Added DM Details View. ([#738](https://github.com/vector-im/element-x-ios/issues/738))
- Enabled Push Notifications with static text. ([#759](https://github.com/vector-im/element-x-ios/issues/759))
- Select members before creating a room (UI for selection) ([#766](https://github.com/vector-im/element-x-ios/issues/766))
- Local notifications support, these can also be decrypted and shown as rich push notifications. ([#813](https://github.com/vector-im/element-x-ios/issues/813))
- Remote Push Notifications can now be displayed as rich push notifications. ([#855](https://github.com/vector-im/element-x-ios/issues/855))
- Create a room screen (UI only) ([#877](https://github.com/vector-im/element-x-ios/issues/877))

🙌 Improvements

- Bump the SDK version and fix breaking changes. ([#703](https://github.com/vector-im/element-x-ios/pull/703))
- Updated dependencies, and added a tool to check for outdated ones. ([#721](https://github.com/vector-im/element-x-ios/pull/721))
- Add test plans for other test targets. ([#740](https://github.com/vector-im/element-x-ios/pull/740))
- change name to nil in direct room parameters ([#758](https://github.com/vector-im/element-x-ios/pull/758))
- Guard user suggestions behind feature flag so that they don't impact releasability of other room creation features ([#770](https://github.com/vector-im/element-x-ios/pull/770))
- Remove styling for developer toggles ([#771](https://github.com/vector-im/element-x-ios/pull/771))
- Use iOS localization handling for strings. ([#803](https://github.com/vector-im/element-x-ios/pull/803))
- Analytics: reset user's consents on logout. ([#816](https://github.com/vector-im/element-x-ios/pull/816))
- Use the existing quote bubble layout with TimelineReplyView. ([#883](https://github.com/vector-im/element-x-ios/pull/883))
- Use Compound fonts everywhere. Allow the search bar to be styled. ([#43](https://github.com/vector-im/element-x-ios/issues/43))
- Add Block user toggle to Report Content screen. ([#115](https://github.com/vector-im/element-x-ios/issues/115))
- Migrate strings to Localazy, remove Android strings and use UntranslatedL10n to be clear when strings won't be translated. ([#124](https://github.com/vector-im/element-x-ios/issues/124))
- Move media file loading logic to the SDK. ([#316](https://github.com/vector-im/element-x-ios/issues/316))
- Bump SDK version and fix breaking changes. ([#709](https://github.com/vector-im/element-x-ios/issues/709))
- Animations are disabled when tapping on an animations when the app is in background. ([#776](https://github.com/vector-im/element-x-ios/issues/776))
- Removed the about title copy from the people section. ([#777](https://github.com/vector-im/element-x-ios/issues/777))
- Move search users into UserProvider service ([#789](https://github.com/vector-im/element-x-ios/issues/789))

🐛 Bugfixes

- Hides the scroll down button for VoiceOver users if it is hidden for visual users by Sem Pruijs ([#670](https://github.com/vector-im/element-x-ios/pull/670))
- Hide the avatars when the users has larger font on by Sem Pruijs ([#690](https://github.com/vector-im/element-x-ios/pull/690))
- Hide the message composer textfield placeholder for VoiceOver users by Sem Pruijs ([#695](https://github.com/vector-im/element-x-ios/pull/695))
- Fix incorrect state string. ([#704](https://github.com/vector-im/element-x-ios/pull/704))
- Use a local copy of the accent colour in the asset catalog so it is applied to Alerts, Xcode previews etc. ([#43](https://github.com/vector-im/element-x-ios/issues/43))
- Fix all broken snapshot tests follow strings update. Use double-length pseudolanguage instead of German to avoid translators breaking tests. ([#124](https://github.com/vector-im/element-x-ios/issues/124))
- Fixed room previews failing to load because of incorrect sliding sync view ranges ([#641](https://github.com/vector-im/element-x-ios/issues/641))
- Fixed room list not loading in offline mode ([#676](https://github.com/vector-im/element-x-ios/issues/676))
- Fixed incorrect link detection and handling in the timeline ([#687](https://github.com/vector-im/element-x-ios/issues/687))
- Fixed a bug that prevented the right localisation to be used when the preferred language locale contained a region identifier. ([#764](https://github.com/vector-im/element-x-ios/issues/764))
- Fixed a bug that crashed the app when tapping on push notifications while the app was in some specific unhandled screens. ([#779](https://github.com/vector-im/element-x-ios/issues/779))
- Display the room list even if the room count is not exact. ([#796](https://github.com/vector-im/element-x-ios/issues/796))
- Notifications are now handled when the app is in a killed state. ([#802](https://github.com/vector-im/element-x-ios/issues/802))
- Fixed a bug that did not render the sender icon of a dm sometimes. ([#863](https://github.com/vector-im/element-x-ios/issues/863))

📄 Documentation

- Update the link of the element ios room to be the element x ios support room in CONTRIBUTING.md and README.md by Sem Pruijs ([#668](https://github.com/vector-im/element-x-ios/pull/668))

🚧 In development 🚧

- Remove AppAuth library and prepare for Rust OIDC. ([#261](https://github.com/vector-im/element-x-ios/issues/261))


## Changes in 1.0.24 (2023-03-10)

✨ Features

- Auto Mocks generator added to the project. ([#600](https://github.com/vector-im/element-x-ios/issues/600))

🙌 Improvements

- Improved report content UI. ([#115](https://github.com/vector-im/element-x-ios/issues/115))
- Avatar url is now cached on the rust side. ([#550](https://github.com/vector-im/element-x-ios/issues/550))

🐛 Bugfixes

- Fixed crash on the settings screen when showing the "complete verification" button before the session verification controller proxy was ready ([#650](https://github.com/vector-im/element-x-ios/pull/650))
- Ignore background images in OnboardingBackgroundView for VoiceOver users by Sem Pruijs ([#658](https://github.com/vector-im/element-x-ios/pull/658))
- Hide the message composer textfield placeholder for VoiceOver users by Sem Pruijs ([#688](https://github.com/vector-im/element-x-ios/pull/688))
- Hides the scroll down button for VoiceOver users if it is hidden for visual users by Sem Pruijs (pr670)
- Prevent creating collapsible groups for one single event. Increase their padding and touch area. ([#631](https://github.com/vector-im/element-x-ios/issues/631))
- Update top padding and a string in Login and Server Selection screens. ([#632](https://github.com/vector-im/element-x-ios/issues/632))

⚠️ API Changes

- Remove all APIs that load media from URLs. These were unused and we should continue to load media through MediaSource in the future. ([#444](https://github.com/vector-im/element-x-ios/issues/444))


## Changes in 1.0.23 (2023-02-24)

No significant changes.


## Changes in 1.0.22 (2023-02-24)

No significant changes.


## Changes in 1.0.21 (2023-02-23)

✨ Features

- Added a feature that allows a user to report content posted by another user by opening the context menu and provide a reason. ([#115](https://github.com/vector-im/element-x-ios/issues/115))
- Added support for audio messages in the timeline as previewable files. ([#594](https://github.com/vector-im/element-x-ios/issues/594))

🐛 Bugfixes

- Fix broken split layout room navigation ([#613](https://github.com/vector-im/element-x-ios/pull/613))


## Changes in 1.0.20 (2023-02-22)

✨ Features

- Enable auto-discovery of sliding sync proxy, directing users to more information when their server doesn't support it. ([#410](https://github.com/vector-im/element-x-ios/issues/410))

🙌 Improvements

- Added the functionality to attach a screenshot in the Bug Report View. ([#127](https://github.com/vector-im/element-x-ios/issues/127))
- Added associated domains applinks. ([#301](https://github.com/vector-im/element-x-ios/issues/301))
- Add missing shimmer effect on home screen and tweak the message composer. ([#430](https://github.com/vector-im/element-x-ios/issues/430))
- Added a progress bar to to the bug report screen, when sending the report. ([#495](https://github.com/vector-im/element-x-ios/issues/495))
- Launch UI tests directly in the screen that will be tested and type character by character instead of retrying. ([#534](https://github.com/vector-im/element-x-ios/issues/534))
- Removed reply/edit dimming for all non highlighted messages to increase readability. ([#542](https://github.com/vector-im/element-x-ios/issues/542))
- Refactored UserNotification into UserIndicator. ([#547](https://github.com/vector-im/element-x-ios/issues/547))
- Update appearance of forms in the app. Add formBackground and formRowBackground colours. ([#565](https://github.com/vector-im/element-x-ios/issues/565))
- Rename SettingsRow… to Form…Style and use these everywhere (sparingly on the Bug Report Screen which isn't a real form). ([#602](https://github.com/vector-im/element-x-ios/issues/602))

🐛 Bugfixes

- Allow blockquote bubbles to fill the message bubble ([#527](https://github.com/vector-im/element-x-ios/pull/527))
- Fixed and updated some UI Tests. ([#554](https://github.com/vector-im/element-x-ios/pull/554))
- Fix incorrect visible room ranges: correctly remove duplicates and ignore appearance changes while filtering ([#603](https://github.com/vector-im/element-x-ios/pull/603))
- Fixed incorrect link detection on messages containing emojis ([#464](https://github.com/vector-im/element-x-ios/issues/464))
- Context Menu Crash: Attempted fix by explicitly passing in the context to each cell. ([#532](https://github.com/vector-im/element-x-ios/issues/532))
- Fix UI Tests for OnboardingScreen, BugReportScreen, ServerSelectionScreen, and UserSessionFlows. Fix UITestsSignalling by switching to file-based communication with a publisher. ([#534](https://github.com/vector-im/element-x-ios/issues/534))
- Fix the background colour of the room members screen in dark mode. ([#583](https://github.com/vector-im/element-x-ios/issues/583))
- Make sure forms have pressed states, remove incorrect disclosure indicators, stop login screen placeholders from flickering and don't block the loging screen when parsing a username. ([#602](https://github.com/vector-im/element-x-ios/issues/602))

🧱 Build

- Update PR Build workflow triggers. ([#564](https://github.com/vector-im/element-x-ios/pull/564))
- Update SwiftLint and SwiftFormat rules. ([#579](https://github.com/vector-im/element-x-ios/pull/579))


## Changes in 1.0.18 (2023-02-03)

No significant changes.


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

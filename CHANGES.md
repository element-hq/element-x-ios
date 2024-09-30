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

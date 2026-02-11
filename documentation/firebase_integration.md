# Firebase Cloud Messaging (FCM) Integration

## Overview

This document describes the Firebase Cloud Messaging integration added to the Element X iOS fork. FCM replaces direct APNs as the push notification transport, wrapping APNs tokens through Firebase's infrastructure and routing them via a Sygnal push gateway configured for FCM.

The integration was implemented in two phases:
1. **Production code** (commit `27a4159c2`) — Firebase SDK, notification service, conditional push routing
2. **Unit tests & testability** (this commit) — Protocol extraction, dependency injection, comprehensive test coverage

---

## Architecture

### Push Provider Selection

The app supports two push providers, controlled by `AppSettings.pushProvider`:

| Provider | Value | Pushkey Format | Token Source |
|----------|-------|---------------|--------------|
| APNs (direct) | `.apns` | Base64-encoded `Data` | `UIApplication.registerForRemoteNotifications()` |
| Firebase (FCM) | `.firebase` | Raw FCM token `String` | `MessagingDelegate.messaging(_:didReceiveRegistrationToken:)` |

The default is `.firebase`, set in `AppSettings`:

```swift
@UserPreference(key: .pushProvider, defaultValue: PushProvider.firebase, storageType: .userDefaults(store))
var pushProvider: PushProvider
```

### Key Components

```
┌──────────────────────────────────────────────────────┐
│ AppCoordinator                                       │
│  ├── firebaseService: FirebaseNotificationServiceProtocol │
│  └── configureNotificationManager()                  │
│       ├── if .firebase → firebaseService.configure() │
│       │   └── onTokenUpdate → notificationManager    │
│       │       .registerWithFCMToken(fcmToken)        │
│       └── appDelegate.callbacks                      │
│           ├── if .apns → notificationManager         │
│           │   .register(with: deviceToken)            │
│           └── if .firebase → Messaging.messaging()   │
│               .apnsToken = deviceToken                │
└──────────────────────────────────────────────────────┘
```

### Files

| File | Role |
|------|------|
| `ElementX/Sources/Application/Settings/PushProvider.swift` | `enum PushProvider: Codable` with `.apns` and `.firebase` cases |
| `ElementX/Sources/Services/Notification/FirebaseNotificationService.swift` | Concrete implementation: initializes Firebase SDK, receives FCM tokens via `MessagingDelegate` |
| `ElementX/Sources/Services/Notification/FirebaseNotificationServiceProtocol.swift` | Protocol for testability (`configure(onTokenUpdate:)` + `currentToken()`) |
| `ElementX/Sources/Services/Notification/Manager/NotificationManager.swift` | `registerWithFCMToken(_:)` — sets Matrix pusher with raw FCM token as pushkey |
| `ElementX/Sources/Application/AppCoordinator.swift` | Wiring: injects `FirebaseNotificationServiceProtocol`, routes tokens based on `pushProvider` setting |
| `ElementX/Sources/Mocks/Generated/GeneratedMocks.swift` | `FirebaseNotificationServiceMock` — thread-safe mock following project Sourcery patterns |

### Firebase SDK Configuration

- **Package:** Firebase iOS SDK v11.8.x (via SPM, `FirebaseMessaging` product)
- **Config file:** `GoogleService-Info.plist` (placeholder — customer must provide real values)
- **Initialization:** `FirebaseApp.configure()` is called inside `FirebaseNotificationService.configure()`
- **Token flow:** Firebase SDK receives the APNs device token (`Messaging.messaging().apnsToken = deviceToken`), then delivers an FCM registration token via `MessagingDelegate`

### Pusher Registration Differences

**APNs path** (`register(with: Data)`):
```swift
pushkey = deviceToken.base64EncodedString()  // Base64-encoded binary APNs token
```

**FCM path** (`registerWithFCMToken(_ String)`):
```swift
pushkey = fcmToken  // Raw FCM registration token string (NOT base64)
```

Both paths use identical payload structure (`APNSPayload` with `mutableContent: 1`). The Sygnal push gateway handles the FCM-to-APNs wrapping.

---

## Testability Changes

### Protocol Extraction

`FirebaseNotificationServiceProtocol` was extracted to enable mocking:

```swift
// sourcery: AutoMockable
protocol FirebaseNotificationServiceProtocol {
    func configure(onTokenUpdate: @escaping (String) -> Void)
    func currentToken() async -> String?
}
```

### Dependency Injection

`AppCoordinator` now accepts the firebase service via constructor injection with a default value, so production code is unchanged:

```swift
init(appDelegate: AppDelegate,
     firebaseService: FirebaseNotificationServiceProtocol = FirebaseNotificationService()) {
    self.firebaseService = firebaseService
    // ...
}
```

### Mock

`FirebaseNotificationServiceMock` follows the project's Sourcery `AutoMockable` pattern:
- Thread-safe call counting (`configureOnTokenUpdateCallsCount`)
- Closure capture (`configureOnTokenUpdateReceivedOnTokenUpdate`) — allows tests to trigger token callbacks
- Injectable closures (`configureOnTokenUpdateClosure`, `currentTokenClosure`)
- Async return value support (`currentTokenReturnValue`)

---

## Test Coverage

### NotificationManagerTests — FCM Tests (5 tests)

Located in `UnitTests/Sources/NotificationManager/NotificationManagerTests.swift`:

| Test | What it verifies |
|------|-----------------|
| `test_whenRegisteredWithFCMToken_pusherIsCalled` | `clientProxy.setPusherWithCalled == true` after registering with FCM token |
| `test_whenRegisteredWithFCMTokenSuccess_returnsTrue` | Returns `true` on successful pusher registration |
| `test_whenRegisteredWithFCMTokenAndPusherThrows_returnsFalse` | Returns `false` when `setPusher` throws an error |
| `test_whenRegisteredWithFCMToken_pusherHasCorrectValues` | Pushkey is the raw FCM token string (not base64), appId/URL/format/payload are correct |
| `test_whenRegisteredWithFCMTokenWithoutSession_returnsFalse` | Returns `false` when no user session is set |

### FirebaseIntegrationTests (5 tests)

Located in `UnitTests/Sources/NotificationManager/FirebaseIntegrationTests.swift`:

These tests verify the full wiring that `AppCoordinator.configureNotificationManager()` performs, using `FirebaseNotificationServiceMock` + `ClientProxyMock`:

| Test | What it verifies |
|------|-----------------|
| `test_firebaseProvider_configureIsCalled` | When `pushProvider == .firebase`, `firebaseMock.configure()` is called |
| `test_firebaseProvider_tokenCallbackRegistersWithFCMToken` | Simulates Firebase delivering a token via the captured callback, asserts `setPusherWithCalled == true` and pushkey matches the FCM token |
| `test_apnsProvider_configureIsNotCalled` | When `pushProvider == .apns`, Firebase `configure()` is never called |
| `test_firebaseProvider_tokenRefreshReRegisters` | Fires the token callback twice with different tokens, asserts `setPusherWithCallsCount == 2` and second invocation has the updated token |
| `test_firebaseProvider_apnsTokenNotUsedForPusher` | Verifies that `register(with: deviceToken)` produces a base64-encoded pushkey (APNs style), confirming the two paths are distinct |

### PushProviderTests (4 tests)

Located in `UnitTests/Sources/PushProviderTests.swift`:

| Test | What it verifies |
|------|-----------------|
| `test_pushProvider_encodeDecode_apns` | Round-trip `JSONEncoder` → `JSONDecoder` for `.apns` |
| `test_pushProvider_encodeDecode_firebase` | Round-trip for `.firebase` |
| `test_pushProvider_defaultIsFirebase` | After `AppSettings.resetAllSettings()`, `pushProvider == .firebase` |
| `test_pushProvider_persistsAfterChange` | Setting to `.apns` persists and reads back correctly |

---

## Configuration Requirements (Customer)

Before FCM works end-to-end, the customer must provide:

1. **`GoogleService-Info.plist`** — Real Firebase project configuration (currently placeholder values)
2. **Sygnal push gateway** — Must be configured for FCM (not APNs) with the Firebase server key
3. **Push gateway URL** — Must match `appSettings.pushGatewayNotifyEndpoint`
4. **Pusher app ID** — Must match `appSettings.pusherAppID` and the Sygnal configuration

See `decisions_tracker.md` (D-004, D-005) for tracking these customer decisions.

---

## Running the Tests

```bash
# Regenerate project (required after adding new files)
xcodegen generate

# Run all FCM-related tests
xcodebuild test -project ElementX.xcodeproj -scheme UnitTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:UnitTests/NotificationManagerTests \
  -only-testing:UnitTests/FirebaseIntegrationTests \
  -only-testing:UnitTests/PushProviderTests

# Run full unit test suite
xcodebuild test -project ElementX.xcodeproj -scheme UnitTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

---

*Last updated: 2026-02-11*

# ShareExtension Target — Pre-Rebranding Audit

## Overview

The ShareExtension enables the iOS "Share" action — users can share files, links, and text from other apps (Photos, Safari, Mail, etc.) directly into Matrix rooms. Unlike the NSE (which has 1 hardcoded string), the ShareExtension has **zero hardcoded brand references** in its source code. All configuration derives from `app.yml` build variables and is read at runtime via `InfoPlistReader`.

---

## 1. Target Configuration

**File:** `ShareExtension/SupportingFiles/target.yml`

### Key Settings

| Setting | Value | Source |
|---------|-------|--------|
| Target type | `app-extension` (iOS) | Static |
| Bundle ID | `${BASE_BUNDLE_IDENTIFIER}.shareextension` | Build variable |
| Display name | `$(APP_DISPLAY_NAME)` | Build variable |
| Product name | `ShareExtension` | Static |
| Team ID | `$(DEVELOPMENT_TEAM)` | Build variable |

### Dependencies (4 packages)

MatrixRustSDK, Compound, Collections, KeychainAccess

Fewer than NSE (which has 8 packages) — the ShareExtension doesn't process notification content or do media rendering.

### Shared Source Files

The ShareExtension includes main app code via `sources` section:
- AppHooks, TargetConfiguration
- AppSettings, SettingsStore
- KeychainController
- RestorationToken, SessionDirectories
- InfoPlistReader, Extensions (Bundle, Dictionary, FileManager, URL, etc.)
- ShareExtensionModels (shared enums/constants)

---

## 2. Entitlements

**File:** `ShareExtension/SupportingFiles/ShareExtension.entitlements`

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>$(APP_GROUP_IDENTIFIER)</string>
</array>
<key>keychain-access-groups</key>
<array>
    <string>$(KEYCHAIN_ACCESS_GROUP_IDENTIFIER)</string>
</array>
```

**All values use build variable substitution — no hardcoded values.**

Simpler than NSE (no `usernotifications.filtering`) and main app (no associated domains).

### Comparison

| Entitlement | Main App | NSE | ShareExtension |
|-------------|----------|-----|----------------|
| App Groups | YES | YES | YES |
| Keychain Groups | YES | YES | YES |
| Associated Domains | YES | NO | NO |
| Notifications Filtering | NO | YES | NO |
| Notifications Communication | YES | NO | NO |

---

## 3. Info.plist

**File:** `ShareExtension/SupportingFiles/Info.plist`

All values use build variable substitution:

| Key | Value | Source |
|-----|-------|--------|
| `CFBundleDisplayName` | `$(PRODUCT_DISPLAY_NAME)` | Build variable |
| `CFBundleIdentifier` | `$(PRODUCT_BUNDLE_IDENTIFIER)` | Build variable |
| `NSExtensionPointIdentifier` | `com.apple.share-services` | Static (correct) |
| `NSExtensionPrincipalClass` | `$(PRODUCT_MODULE_NAME).ShareExtensionViewController` | Build variable |
| `IntentsSupported` | `[INSendMessageIntent]` | Static (Siri Shortcuts) |
| `appGroupIdentifier` | `$(APP_GROUP_IDENTIFIER)` | Build variable |
| `baseBundleIdentifier` | `$(BASE_BUNDLE_IDENTIFIER)` | Build variable |
| `keychainAccessGroupIdentifier` | `$(KEYCHAIN_ACCESS_GROUP_IDENTIFIER)` | Build variable |
| `productionAppName` | `$(PRODUCTION_APP_NAME)` | Build variable |

**No hardcoded values to update.**

### Activation Rules

Supports: files (10 max), images (10), movies (10), text, web URLs (10).

---

## 4. Source Code — Zero Hardcoded Brand References

### Local Files (2 Swift files, 167 LOC total)

**`ShareExtensionViewController.swift`** (142 lines):
- Line 19: `InfoPlistReader.main.keychainAccessGroupIdentifier` — runtime variable
- Line 101: Constructs URL to open main app:
  ```swift
  guard let url = URL(string: "\(InfoPlistReader.main.baseBundleIdentifier):/\(ShareExtensionConstants.urlPath)?\(payload)") else {
  ```
  This reads the bundle ID at runtime, so it **auto-updates** with rebranding.

**`ShareExtensionView.swift`** (25 lines):
- SwiftUI UI only (ProgressView with Compound design system)
- No brand references

### Shared Code

**`ElementX/Sources/ShareExtension/ShareExtensionModels.swift`** (55 lines):
- Defines `ShareExtensionConstants.urlPath = "share"` — generic, no brand reference
- No hardcoded bundle IDs, URLs, or brand strings

**Result: ZERO hardcoded brand references in ShareExtension code.**

---

## 5. Communication with Main App

### Channel 1: Custom URL Scheme (Primary)

```swift
// ShareExtensionViewController.swift, line 101
"\(InfoPlistReader.main.baseBundleIdentifier):/share?{payload}"
// Current: io.element.elementx://share?{payload}
```

Registered in main app's `target.yml` line 65 as `$(BASE_BUNDLE_IDENTIFIER)`. Auto-updates when bundle ID changes.

### Channel 2: Shared App Group Container

Stores temporary media files for transfer to main app. Accessed via `InfoPlistReader.main.appGroupIdentifier`.

### Channel 3: Keychain (Shared Access Group)

Reads user session restoration tokens. Accessed via `InfoPlistReader.main.keychainAccessGroupIdentifier`.

### Channel 4: Shared AppSettings

Reads app settings (log level, traces, feature flags) from shared `UserDefaults` suite.

---

## 6. Data Flow During Share

1. User selects "Share" action from Photos/Safari/Mail
2. iOS launches ShareExtension
3. `viewDidLoad()`: Initializes AppHooks, AppSettings, KeychainController
4. `viewDidAppear()`:
   - Reads session credentials from shared keychain
   - Prepares share payload (text or media)
   - Constructs custom URL with main app's bundle ID (runtime)
   - Opens main app via `UIApplication.open(url)`
5. Main app receives URL, routes to share handler
6. User selects target room and completes share

---

## 7. Rebranding Change Checklist

### Manual Changes Required: NONE

The ShareExtension requires **zero lines of code changes** for rebranding.

### Auto-Updates (via app.yml)

| Change in `app.yml` | ShareExtension Impact |
|---------------------|----------------------|
| `BASE_BUNDLE_IDENTIFIER` | Bundle ID → `{NEW_BASE}.shareextension` |
| `BASE_BUNDLE_IDENTIFIER` | Custom URL scheme → `{NEW_BASE}://share?...` (runtime) |
| `APP_GROUP_IDENTIFIER` | App group entitlement auto-updates |
| `KEYCHAIN_ACCESS_GROUP_IDENTIFIER` | Keychain entitlement auto-updates |
| `DEVELOPMENT_TEAM` | Code signing auto-updates |
| `APP_DISPLAY_NAME` | Extension display name auto-updates |

### After Changes

```bash
xcodegen generate  # Regenerates .xcodeproj with new variables
```

---

## 8. Comparison: ShareExtension vs NSE

| Aspect | ShareExtension | NSE |
|--------|----------------|-----|
| Hardcoded brand references | **0** | 1 (`receivedWhileOfflineNotification` ID) |
| Code complexity | Simple (2 files, 167 LOC) | Complex (6 files, notification processing) |
| Entitlements | 2 | 3 (+ notifications filtering) |
| Dependencies | 4 packages | 8 packages |
| Rebranding effort | **0 lines of code** | 1 line of code |
| Configuration changes | All via app.yml (auto) | All via app.yml (auto) except 1 line |

---

## 9. File Structure

```
ShareExtension/
├── SupportingFiles/
│   ├── target.yml                  ← All build variables, no hardcoded values
│   ├── ShareExtension.entitlements ← All build variables
│   └── Info.plist                  ← All build variables
└── Sources/
    ├── ShareExtensionViewController.swift  ← Runtime InfoPlistReader, no hardcoding
    └── View/
        └── ShareExtensionView.swift        ← UI only, no brand references

ElementX/Sources/ShareExtension/
└── ShareExtensionModels.swift              ← Generic constants, no brand references
```

---

## 10. Verification After Rebranding

1. Confirm bundle ID: `{NEW_BASE}.shareextension`
2. Confirm app group in entitlements matches main app
3. Test Share action in iOS Simulator:
   - Open Photos → Select image → Tap Share
   - Confirm new app name appears in share sheet
   - Confirm app launches with correct custom URL scheme
   - Verify content is shared successfully

---

*Last updated: 2026-02-11*

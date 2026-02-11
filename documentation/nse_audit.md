# Notification Service Extension (NSE) — Pre-Rebranding Audit

## Overview

This audit documents the NSE target configuration, entitlements, source code, and all brand-specific references that need to change during rebranding. The NSE has excellent build variable usage — only **one line of hardcoded code** needs manual updating, with everything else automatically deriving from `app.yml`.

---

## 1. NSE Target Configuration

**File:** `NSE/SupportingFiles/target.yml`

### Key Settings

| Setting | Value | Source |
|---------|-------|--------|
| Target type | `app-extension` (iOS) | Static |
| Bundle ID | `${BASE_BUNDLE_IDENTIFIER}.nse` | Build variable |
| Display name | `$(APP_DISPLAY_NAME)` | Build variable |
| Product name | `NSE` | Static |
| Team ID | `$(DEVELOPMENT_TEAM)` | Build variable |
| Compilation flag | `-DIS_NSE` | Static (identifies NSE at compile time) |

### Dependencies (8 packages)

MatrixRustSDK, KeychainAccess, Kingfisher, Collections, Compound, DeviceKit, LRUCache, Version, SwiftSoup

### Shared Source Files

The NSE includes source files from the main app via the `sources` section in `target.yml`:
- AppHooks, TargetConfiguration
- Assets, Strings, Logging
- Settings, Extensions, Services
- KeychainController, NotificationConstants
- MediaProvider, SessionDirectories

---

## 2. NSE Entitlements

**File:** `NSE/SupportingFiles/NSE.entitlements`

```xml
<key>com.apple.developer.usernotifications.filtering</key>
<true/>
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

### Resolved Values (from app.yml)

| Variable | Current Value |
|----------|---------------|
| `APP_GROUP_IDENTIFIER` | `group.io.element` |
| `KEYCHAIN_ACCESS_GROUP_IDENTIFIER` | `$(DEVELOPMENT_TEAM).$(BASE_BUNDLE_IDENTIFIER)` → `7J4U792NQT.io.element.elementx` |

### Comparison with Main App

NSE has fewer entitlements than the main app — it does NOT need:
- `aps-environment` (push handled separately)
- `com.apple.developer.associated-domains` (not needed for extensions)
- `com.apple.developer.usernotifications.communication` (NSE processes, doesn't send)

**Critical:** NSE MUST have the same `APP_GROUP_IDENTIFIER` and `KEYCHAIN_ACCESS_GROUP_IDENTIFIER` as the main app to share data.

---

## 3. NSE Info.plist

**File:** `NSE/SupportingFiles/Info.plist`

All values use build variable substitution:

| Key | Value | Source |
|-----|-------|--------|
| `CFBundleDisplayName` | `$(PRODUCT_DISPLAY_NAME)` | → "Element X" |
| `CFBundleIdentifier` | `$(PRODUCT_BUNDLE_IDENTIFIER)` | → `io.element.elementx.nse` |
| `CFBundleName` | `$(PRODUCT_NAME)` | → "NSE" |
| `CFBundlePackageType` | `XPC!` | Static (correct for NSE) |
| `NSExtensionPointIdentifier` | `com.apple.usernotifications.service` | Static (correct) |
| `NSExtensionPrincipalClass` | `$(PRODUCT_MODULE_NAME).NotificationServiceExtension` | Build variable |
| `appGroupIdentifier` | `$(APP_GROUP_IDENTIFIER)` | Build variable |
| `baseBundleIdentifier` | `$(BASE_BUNDLE_IDENTIFIER)` | Build variable |
| `keychainAccessGroupIdentifier` | `$(KEYCHAIN_ACCESS_GROUP_IDENTIFIER)` | Build variable |
| `productionAppName` | `$(PRODUCTION_APP_NAME)` | Build variable |

**No hardcoded values to update.**

---

## 4. Hardcoded Identifiers in Source Code

### ONE Critical Hardcoded Value Found

**File:** `NSE/Sources/NotificationServiceExtension.swift` (line 33)

```swift
static let receivedWhileOfflineNotificationID = "io.element.elementx.receivedWhileOfflineNotification"
```

**Usage:** Line 236 — notification request identifier for "received while offline" notification (delivered when device was powered off during message receipt).

**Change required:** Update to `"{NEW_BASE_BUNDLE_ID}.receivedWhileOfflineNotification"`

Example: `"com.customer.messenger.receivedWhileOfflineNotification"`

### No Other Hardcoded Brand References

Unlike the main app, the NSE does NOT have:
- Hardcoded `element.io` domain URLs
- Associated domains
- OIDC redirect URLs
- Analytics endpoints

All inherited from the main app via:
- Shared app group data
- Shared `AppSettings`
- Restored session credentials from keychain

---

## 5. NSE Communication with Main App

### Channel 1: Shared App Group Container

```swift
// NSE accesses via InfoPlistReader:
static var appGroupContainerDirectory: URL {
    FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: InfoPlistReader.main.appGroupIdentifier
    )
}
```

**Shared directories:**
- `Library/Logs/{baseBundleID}/` — NSE writes logs, main app reads
- `Library/Application Support/{baseBundleID}/` — Session data, cache
- `Library/Caches/{baseBundleID}/Sessions/` — Session cache
- `tmp/` — Temporary file transfer

### Channel 2: Keychain (Shared Access Group)

```swift
private let keychainController = KeychainController(
    service: .sessions,
    accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier
)
```

NSE reads from keychain:
- User session restoration tokens
- Pusher notification client identifiers
- Homeserver URLs
- Encryption keys

### Channel 3: Shared App Settings

```swift
private let settings: CommonSettingsProtocol = AppSettings()
```

NSE reads: log level, trace packs, rageshake URL, media preview visibility, invite avatars, thread settings, quiet notification preferences, boot time tracking.

---

## 6. Bundle ID References

### Derivation

- **Formula:** `${BASE_BUNDLE_IDENTIFIER}.nse`
- **Current:** `io.element.elementx.nse`
- **On rebranding:** Auto-updates when `BASE_BUNDLE_IDENTIFIER` changes in `app.yml`

### Where Referenced

| File | Line | Context | Auto-Updates? |
|------|------|---------|---------------|
| `NSE/SupportingFiles/target.yml` | 72 | `PRODUCT_BUNDLE_IDENTIFIER` | YES |
| `NSE/SupportingFiles/Info.plist` | 12 | `CFBundleIdentifier` | YES |
| `project.yml` | 61 | Target definition include | YES |
| `TargetConfiguration.swift` | 15 | `case nse` (enum, not string) | N/A |

---

## 7. Extension Comparison

### Bundle ID Pattern

| Target | Pattern | Current Value |
|--------|---------|---------------|
| Main App | `$(BASE_BUNDLE_IDENTIFIER)` | `io.element.elementx` |
| NSE | `${BASE_BUNDLE_IDENTIFIER}.nse` | `io.element.elementx.nse` |
| ShareExtension | `${BASE_BUNDLE_IDENTIFIER}.shareextension` | `io.element.elementx.shareextension` |

### Entitlements Comparison

| Entitlement | Main App | NSE | ShareExt |
|-------------|----------|-----|----------|
| App Groups | YES | YES | YES |
| Keychain Groups | YES | YES | YES |
| Associated Domains | YES | NO | NO |
| Notifications Communication | YES | NO | NO |
| Notifications Filtering | NO | YES | NO |

All three targets share identical `APP_GROUP_IDENTIFIER` and `KEYCHAIN_ACCESS_GROUP_IDENTIFIER` values.

---

## 8. Rebranding Change Checklist

### MUST CHANGE (Manual — 1 line)

- [ ] **`NSE/Sources/NotificationServiceExtension.swift` line 33**
  - From: `"io.element.elementx.receivedWhileOfflineNotification"`
  - To: `"{CUSTOMER_BASE_BUNDLE_ID}.receivedWhileOfflineNotification"`

### AUTO-UPDATES (Via app.yml — no manual NSE changes)

| Change in `app.yml` | NSE Impact |
|---------------------|------------|
| `BASE_BUNDLE_IDENTIFIER` | NSE bundle ID → `{NEW_BASE}.nse` |
| `APP_GROUP_IDENTIFIER` | NSE entitlements auto-update |
| `DEVELOPMENT_TEAM` | NSE signing auto-updates |
| `APP_DISPLAY_NAME` | NSE display name auto-updates |

### VERIFY (All Dynamic — No Changes Needed)

- [x] `NSE/SupportingFiles/Info.plist` — All variables
- [x] `NSE/SupportingFiles/NSE.entitlements` — All variables
- [x] App group container access — Runtime `InfoPlistReader`
- [x] Keychain access — Runtime `InfoPlistReader`
- [x] Session credential retrieval — Dynamic via keychain

### After Changes: Rebuild

```bash
xcodegen generate  # Regenerates .xcodeproj with new variables
```

---

## 9. Impact Analysis

### If the hardcoded notification ID is NOT changed:
- Offline notifications use old bundle ID identifier
- Could cause duplicate notifications during upgrade
- **Recommendation:** Update before App Store submission

### If `app.yml` variables are changed correctly:
- NSE automatically gets new bundle ID, app group, team ID
- All entitlements regenerated correctly
- No additional configuration needed

### If keychain access group is wrong:
- NSE fails to read session credentials
- No notifications processed
- Error: "Credentials not found, bailing out." (line 131)

### If app group is wrong:
- NSE cannot write logs to shared container
- Cannot read session directories
- Device lock detection fails
- Boot time tracking fails

---

## 10. Build Variables Summary

| Variable | Source | Used In NSE | Requires Manual Update? |
|----------|--------|-------------|------------------------|
| `APP_DISPLAY_NAME` | `app.yml` | Plist, target settings | No (auto) |
| `PRODUCTION_APP_NAME` | `app.yml` | Plist | No (auto) |
| `APP_GROUP_IDENTIFIER` | `app.yml` | Entitlements, target.yml, Plist | No (auto) |
| `BASE_BUNDLE_IDENTIFIER` | `app.yml` | Bundle ID, keychain group | No (auto) |
| `DEVELOPMENT_TEAM` | `app.yml` | Code signing, keychain group | No (auto) |
| `MARKETING_VERSION` | `project.yml` | Plist | No (auto) |
| `CURRENT_PROJECT_VERSION` | `project.yml` | Plist | No (auto) |

**Bottom line:** Update `app.yml` (3 lines) + fix 1 hardcoded string in `NotificationServiceExtension.swift`. Everything else auto-derives.

---

*Last updated: 2026-02-11*

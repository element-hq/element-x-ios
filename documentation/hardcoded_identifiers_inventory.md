# Hardcoded Brand Identifiers — Complete Inventory

## Overview

Comprehensive inventory of ALL hardcoded brand-specific identifiers in the codebase. Each occurrence is classified as:
- **(a) Auto-derived** — changes automatically when `app.yml` build variables change
- **(b) Must change manually** — hardcoded in source code, requires manual update
- **(c) Code/test data** — type names, test fixtures, or preview data (low priority or no change needed)

**Total:** 97 occurrences across 35+ files
- Auto-derived: 28 occurrences
- Must change manually: 52 occurrences
- Test/preview data only: 17 occurrences

---

## 1. Bundle Identifier: `io.element.elementx`

### Build Variables (a)

| File | Line | Value | Notes |
|------|------|-------|-------|
| `app.yml` | 5 | `BASE_BUNDLE_IDENTIFIER: io.element.elementx` | Master setting |
| `Variants/Nightly/nightly.yml` | 3 | `BASE_BUNDLE_IDENTIFIER: io.element.elementx.nightly` | Nightly variant |

### Must Change Manually (b)

| File | Line | String | Purpose |
|------|------|--------|---------|
| `ElementX/SupportingFiles/target.yml` | 97 | `io.element.elementx.background.refresh` | BGTaskScheduler permitted ID |
| `ElementX/SupportingFiles/Info.plist` | 7 | `io.element.elementx.background.refresh` | BGTaskScheduler (generated from YAML) |
| `AppSettings.swift` | 100 | `case "io.element.elementx.nightly":` | Nightly build detection |
| `AppSettings.swift` | 204 | `"io.element.elementx.background.refresh"` | Background refresh task ID |
| `BugReportService.swift` | 94 | `if InfoPlistReader.main.baseBundleIdentifier == "io.element.elementx.nightly"` | Nightly build check |
| `CallScreen.swift` | 353 | `clientID: "io.element.elementx"` | Element Call client ID |
| `UserSessionFlowCoordinator.swift` | 242 | `"io.element.elementx.reachability.notification"` | Network status notification ID |
| `NSE/NotificationServiceExtension.swift` | 33 | `"io.element.elementx.receivedWhileOfflineNotification"` | Offline notification ID |

### Dispatch Queue Labels (b) — 8 occurrences

| File | Line | Label |
|------|------|-------|
| `RoomSummaryProvider.swift` | 67 | `io.element.elementx.room_summary_provider` |
| `RoomDirectorySearchProxy.swift` | 16 | `io.element.elementx.room_directory_search_proxy` |
| `TimelineItemProvider.swift` | 50 | `io.element.elementx.timeline_item_provider` |
| `AttributedStringBuilder.swift` | 45 | `io.element.elementx.attributed_string_builder_v2_cache` |
| `Bundle.swift` | 30 | `io.element.elementx.localization_bundle_cache` |
| `NetworkMonitor.swift` | 23 | `io.element.elementx.network_monitor` |
| `AudioRecorder.swift` | 47 | `io.element.elementx.audio_recorder` |
| `EmojiProviderProtocol.swift` | 23 | `io.element.elementx.frequently_used` (category ID) |

### Test Data (c)

| File | Line | String | Context |
|------|------|--------|---------|
| `UnitTestsAppCoordinator.swift` | 22 | `io.element.elementx.unittests` | Test suite name |
| `UITestsAppCoordinator.swift` | 38 | `io.element.elementx.uitests` | Test suite name |
| `AccessibilityTestsAppCoordinator.swift` | 41 | `io.element.elementx.accessibilitytests` | Test suite name |
| `UserPreferenceTests.swift` | 178 | `io.element.elementx.unitests` | Test suite name |
| `UserSessionFlowCoordinatorTests.swift` | 253 | `io.element.elementx.reachability.notification` | Test assertion |

---

## 2. Domain: `element.io`

### Associated Domains — Entitlements (b)

**Source of truth:** `ElementX/SupportingFiles/target.yml` (lines 115–124)

| Domain | Type |
|--------|------|
| `applinks:element.io` | Universal link |
| `applinks:app.element.io` | Universal link |
| `applinks:staging.element.io` | Universal link |
| `applinks:develop.element.io` | Universal link |
| `applinks:mobile.element.io` | Universal link |
| `applinks:call.element.io` | Universal link |
| `applinks:call.element.dev` | Universal link |
| `applinks:matrix.to` | Universal link (Matrix protocol — typically keep) |
| `webcredentials:*.element.io` | Password autofill |

### AppSettings.swift URLs (b)

| Line | Property | Value |
|------|----------|-------|
| 207 | `websiteURL` | `https://element.io` |
| 209 | `logoURL` | `https://element.io/mobile-icon.png` |
| 211 | `copyrightURL` | `https://element.io/copyright` |
| 213 | `acceptableUseURL` | `https://element.io/acceptable-use-policy-terms` |
| 215 | `privacyURL` | `https://element.io/privacy` |
| 217 | `encryptionURL` | `https://element.io/help#encryption` |
| 219 | `deviceVerificationURL` | `https://element.io/help#encryption-device-verification` |
| 221 | `chatBackupDetailsURL` | `https://element.io/help#encryption5` |
| 223 | `identityPinningViolationDetailsURL` | `https://element.io/help#encryption18` |
| 225 | `historySharingDetailsURL` | `https://element.io/en/help#e2ee-history-sharing` |
| 228 | `elementWebHosts` | `["app.element.io", "staging.element.io", "develop.element.io"]` |
| 230 | `accountProvisioningHost` | `"mobile.element.io"` |
| 253 | `oidcStaticRegistrations` | `["https://id.thirdroom.io/realms/thirdroom": "elementx"]` |
| 255 | `oidcRedirectURL` | `https://element.io/oidc/login` |
| 330 | `analyticsTermsURL` | `https://element.io/cookie-policy` |

### Analytics & Third-Party Services (b)

| File | Line | URL | Service |
|------|------|-----|---------|
| `AppSettings.swift` | 379 | `https://posthog-element-call.element.io` | PostHog (Element Call analytics) |
| `AppSettings.swift` | 381 | `https://...@sentry.tools.element.io/41` | Sentry DSN (Element Call crash reporting) |
| `AppCoordinator.swift` | 1171, 1236 | `https://sentry.tools.element.io/organizations/element/issues/...` | Sentry issue links (comments) |
| `BugReportService.swift` | 88 | `https://sentry.tools.element.io/organizations/element/issues/?project=44...` | Sentry crash link generation |

### Navigation/Parser Code (b)

| File | Line | String | Purpose |
|------|------|--------|---------|
| `AppRoutes.swift` | 106 | `call.element.io` | Known Element Call hosts |
| `ServerConfirmationScreenModels.swift` | 99 | `homeserverAddress == "element.io"` | Special-case server detection |

### Test Data (c)

| File | Context |
|------|---------|
| `AppRouteURLParserTests.swift` | Test URLs with `call.element.io`, `app.element.io`, `develop.element.io` |
| `URLComponentsTests.swift` | Test URLs with `call.element.io` |
| `JoinedRoomProxyMock.swift` | Mock Element Call URL |
| `RoomDetailsScreen.swift` | Preview data with `github.com/vector-im/element-x-ios` |

---

## 3. App Group: `group.io.element`

| File | Type | Classification |
|------|------|----------------|
| `app.yml` line 4 | `APP_GROUP_IDENTIFIER: group.io.element` | (a) Build variable — change here |
| `Variants/Nightly/nightly.yml` line 2 | `APP_GROUP_IDENTIFIER: group.io.element.nightly` | (a) Build variable |
| All entitlements files | `$(APP_GROUP_IDENTIFIER)` | (a) Auto-derived |
| All target.yml files | `$(APP_GROUP_IDENTIFIER)` | (a) Auto-derived |

---

## 4. URL Scheme: `io.element.call`

| File | Line | Classification |
|------|------|----------------|
| `ElementX/SupportingFiles/target.yml` | 58 | (b) Must change — Element Call scheme |
| `ElementX/SupportingFiles/Info.plist` | 47 | (b) Must change (generated from YAML) |
| `InfoPlistReader.swift` | 97–98 | (c) Code logic — reads dynamically from plist |
| `AppRoutes.swift` | 150 | (c) Code logic — uses `InfoPlistReader.app.elementCallScheme` |

---

## 5. Element Pro References

| File | Line | String | Classification |
|------|------|--------|----------------|
| `AppSettings.swift` | 233 | `https://apps.apple.com/app/element-pro-for-work/id6502951615` | (b) Must change or remove |
| `Strings.swift` | 1466–1472 | `screenChangeServerErrorElementProRequired*` | (c) Generated string keys |
| `ServerConfirmationScreenModels.swift` | 99 | `case elementProRequired(...)` | (c) Code type name |
| `ServerSelectionScreenModels.swift` | 71 | `case elementProAlert` | (c) Code type name |
| `LoginScreenModels.swift` | 77 | `case elementProAlert` | (c) Code type name |

---

## 6. Firebase Configuration

| File | Line | Value | Classification |
|------|------|-------|----------------|
| `GoogleService-Info.plist` | 6 | `TODO-customer-api-key` | (b) Must replace with real values |
| `GoogleService-Info.plist` | 14 | `TODO-customer-project-id` | (b) Must replace |
| `GoogleService-Info.plist` | 16 | `1:000000000000:ios:0000000000000000` | (b) Must replace |
| `GoogleService-Info.plist` | 12 | `$(PRODUCT_BUNDLE_IDENTIFIER)` | (a) Auto-derived |

---

## Execution Checklist

### Phase 1: Configuration Files (app.yml)
- [ ] `app.yml`: `APP_DISPLAY_NAME`, `PRODUCTION_APP_NAME`, `BASE_BUNDLE_IDENTIFIER`, `APP_GROUP_IDENTIFIER`, `DEVELOPMENT_TEAM`
- [ ] `Variants/Nightly/nightly.yml`: Update or delete if not keeping nightly variant
- [ ] `GoogleService-Info.plist`: Replace with customer's Firebase config
- [ ] Run `xcodegen generate`

### Phase 2: AppSettings URLs (~15 lines)
- [ ] All `element.io` URLs (lines 207–255, 330)
- [ ] PostHog/Sentry endpoints (lines 379–381) — or disable analytics
- [ ] Element Pro App Store URL (line 233) — remove or redirect

### Phase 3: Associated Domains (target.yml lines 115–124)
- [ ] Replace all 9 `applinks`/`webcredentials` entries with customer domains

### Phase 4: Hardcoded Identifiers in Swift (~18 locations)
- [ ] Background task ID: `AppSettings.swift:204`, `target.yml:97`
- [ ] Nightly build checks: `AppSettings.swift:100`, `BugReportService.swift:94`
- [ ] Element Call client ID: `CallScreen.swift:353`
- [ ] Notification IDs: `UserSessionFlowCoordinator.swift:242`, `NotificationServiceExtension.swift:33`
- [ ] URL scheme: `target.yml:58`
- [ ] Dispatch queue labels: 8 files (debugging only, lower priority)

### Phase 5: Test Files (optional, lower priority)
- [ ] Test suite names in 4 files
- [ ] Test assertion strings in 1 file
- [ ] Test URLs with `element.io` references

### Phase 6: Analytics/Support Links (optional)
- [ ] Sentry links in `AppCoordinator.swift` and `BugReportService.swift`
- [ ] GitHub URLs in preview/mock data

---

## Critical Notes

1. **OIDC Redirect URI** — Changing line 255 requires coordinating with the customer's OIDC server
2. **matrix.to** — Standard Matrix protocol, typically NOT changed in forks
3. **Dispatch queue labels** — Don't affect functionality, but useful for debugging clarity
4. **Element Pro** — Forks shouldn't encounter Element Pro prompts (per code comments), but the hardcoded App Store link should be updated or removed
5. **Nightly variant** — Can delete `Variants/Nightly/nightly.yml` if not publishing nightly builds

---

*Last updated: 2026-02-11*

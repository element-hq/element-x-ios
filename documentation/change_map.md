# Change Map — Element X iOS Rebranding

> **Generated**: 2026-02-09 | **Branch**: `develop` | **Source**: Automated codebase audit (5 parallel agents)
>
> This document maps every file requiring modification for rebranding, organized by priority and category.
> **Rule**: Only files listed here should be modified. Everything else stays untouched.

---

## Quick Stats

| Metric | Count |
|--------|-------|
| `io.element.elementx` (bundle ID) occurrences | 30 |
| `group.io.element` (app group) occurrences | 6 |
| `7J4U792NQT` (team ID) occurrences | 12 |
| `element.io` (domain) occurrences | 74 |
| AppSettings.swift configurable values | 87 total |
| AppSettings values that MUST change | 27 |
| AppSettings values that MAYBE change | 5 |
| InfoPlist.strings files with "Element X" | 34 |
| Localizable.strings files with Element refs | 37 |
| Entitlements files | 4 |
| Associated domain entries (element.io) | 9 |
| Copyright headers ("New Vector") | ~1,150 (DO NOT CHANGE) |

---

## Category 1: IDENTITY (Bundle ID, Team, App Group)

**Single source of truth**: `app.yml` and `project.yml` — change here, regenerate with `xcodegen`.

| File | Line(s) | Current Value | Change To |
|------|---------|---------------|-----------|
| `app.yml` | 2 | `APP_DISPLAY_NAME: Element X` | `{CUSTOMER_APP_NAME}` |
| `app.yml` | 3 | `PRODUCTION_APP_NAME: Element` | `{CUSTOMER_BRAND}` |
| `app.yml` | 4 | `APP_GROUP_IDENTIFIER: group.io.element` | `group.{CUSTOMER_REVERSE_DOMAIN}` |
| `app.yml` | 5 | `BASE_BUNDLE_IDENTIFIER: io.element.elementx` | `{CUSTOMER_BUNDLE_ID}` |
| `app.yml` | 7 | `DEVELOPMENT_TEAM: 7J4U792NQT` | `{DEV_TEAM_ID}` |
| `project.yml` | 54 | `KEYCHAIN_ACCESS_GROUP_IDENTIFIER: "$(DEVELOPMENT_TEAM).$(BASE_BUNDLE_IDENTIFIER)"` | Auto-derived (no manual change) |

**Auto-propagated via XcodeGen** (do NOT edit directly):
- `ElementX.xcodeproj/project.pbxproj` — all `BASE_BUNDLE_IDENTIFIER`, `APP_GROUP_IDENTIFIER`, `DEVELOPMENT_TEAM` entries
- `compound-ios/Inspector/Inspector.xcodeproj/project.pbxproj` — `DEVELOPMENT_TEAM` entries

**Swift source references to `io.element.elementx`** (change bundle ID prefix):

| File | Line | Current Value | Notes |
|------|------|---------------|-------|
| `AppSettings.swift` | 99 | `"io.element.elementx.nightly"` | Nightly build check |
| `AppSettings.swift` | 203 | `"io.element.elementx.background.refresh"` | Background task ID |
| `BugReportService.swift` | 94 | `"io.element.elementx.nightly"` | Nightly detection |
| `UserSessionFlowCoordinator.swift` | 242 | `"io.element.elementx.reachability.notification"` | Notification ID |
| `NetworkMonitor.swift` | 23 | `"io.element.elementx.network_monitor"` | Dispatch queue label |
| `RoomSummaryProvider.swift` | 67 | `"io.element.elementx.room_summary_provider"` | Dispatch queue label |
| `RoomDirectorySearchProxy.swift` | 16 | `"io.element.elementx.room_directory_search_proxy"` | Dispatch queue label |
| `TimelineItemProvider.swift` | 50 | `"io.element.elementx.timeline_item_provider"` | Dispatch queue label |
| `EmojiProviderProtocol.swift` | 23 | `"io.element.elementx.frequently_used"` | Category ID |
| `Bundle.swift` | 30 | `"io.element.elementx.localization_bundle_cache"` | Dispatch queue label |
| `AudioRecorder.swift` | 47 | `"io.element.elementx.audio_recorder"` | Dispatch queue label |
| `AttributedStringBuilder.swift` | 45 | `"io.element.elementx.attributed_string_builder_v2_cache"` | Dispatch queue label |
| `CallScreen.swift` | 353 | `"io.element.elementx"` | Element Call client ID |
| `NSE/NotificationServiceExtension.swift` | 33 | `"io.element.elementx.receivedWhileOfflineNotification"` | Offline notification ID |
| `Info.plist` | 7 | `io.element.elementx.background.refresh` | Background task ID |
| `target.yml` | 97 | `io.element.elementx.background.refresh` | Background task ID |

**Test files** (update for consistency but lower priority):
- `UITestsAppCoordinator.swift:38` — suite name
- `UnitTestsAppCoordinator.swift:22` — suite name
- `AccessibilityTestsAppCoordinator.swift:41` — suite name
- `UserSessionFlowCoordinatorTests.swift:253` — notification ID
- `UserPreferenceTests.swift:178` — suite name

---

## Category 2: ENTITLEMENTS & ASSOCIATED DOMAINS

### Main App Entitlements
**File**: `ElementX/SupportingFiles/ElementX.entitlements`

| Entry | Current Value | Change To |
|-------|---------------|-----------|
| `applinks:element.io` | element.io | `{CUSTOMER_DOMAIN}` |
| `applinks:app.element.io` | app.element.io | Remove or replace |
| `applinks:staging.element.io` | staging.element.io | Remove |
| `applinks:develop.element.io` | develop.element.io | Remove |
| `applinks:mobile.element.io` | mobile.element.io | Remove or replace |
| `applinks:call.element.io` | call.element.io | `{CUSTOMER_CALL_DOMAIN}` or remove |
| `applinks:call.element.dev` | call.element.dev | Remove |
| `applinks:matrix.to` | matrix.to | Keep (Matrix protocol standard) |
| `webcredentials:*.element.io` | *.element.io | `{CUSTOMER_DOMAIN}` (for OIDC) |

**Source of truth**: `ElementX/SupportingFiles/target.yml` lines 115-124 (XcodeGen regenerates the .entitlements)

### Extension Entitlements (use variable substitution — no hardcoded values)
- `NSE/SupportingFiles/NSE.entitlements` — auto-derived from `$(APP_GROUP_IDENTIFIER)`, `$(KEYCHAIN_ACCESS_GROUP_IDENTIFIER)`
- `ShareExtension/SupportingFiles/ShareExtension.entitlements` — same pattern
- `compound-ios/Inspector/Resources/Entitlements.entitlements` — sandbox only, no changes needed

---

## Category 3: AppSettings.swift CONFIGURATION

**File**: `ElementX/Sources/Application/Settings/AppSettings.swift`

### MUST CHANGE (27 values)

| Property | Line | Current Default | Category |
|----------|------|-----------------|----------|
| `accountProviders` | 196 | `["matrix.org"]` | Server |
| `websiteURL` | 206 | `"https://element.io"` | Legal URL |
| `logoURL` | 208 | `"https://element.io/mobile-icon.png"` | Legal URL |
| `copyrightURL` | 210 | `"https://element.io/copyright"` | Legal URL |
| `acceptableUseURL` | 212 | `"https://element.io/acceptable-use-policy-terms"` | Legal URL |
| `privacyURL` | 214 | `"https://element.io/privacy"` | Legal URL |
| `encryptionURL` | 216 | `"https://element.io/help#encryption"` | Legal URL |
| `deviceVerificationURL` | 218 | `"https://element.io/help#encryption-device-verification"` | Legal URL |
| `chatBackupDetailsURL` | 220 | `"https://element.io/help#encryption5"` | Legal URL |
| `identityPinningViolationDetailsURL` | 222 | `"https://element.io/help#encryption18"` | Legal URL |
| `historySharingDetailsURL` | 224 | `"https://element.io/en/help#e2ee-history-sharing"` | Legal URL |
| `elementWebHosts` | 227 | `["app.element.io", "staging.element.io", "develop.element.io"]` | Server |
| `accountProvisioningHost` | 229 | `"mobile.element.io"` | Server |
| `oidcRedirectURL` | 254 | `"https://element.io/oidc/login"` | OIDC |
| `pushGatewayBaseURL` | 279 | `"https://matrix.org"` | Push |
| `bugReportApplicationID` | 315 | `"element-x-ios"` | Bug Report |
| `analyticsTermsURL` | 324 | `"https://element.io/cookie-policy"` | Analytics |
| `elementCallPosthogAPIHost` | 373 | `"https://posthog-element-call.element.io"` | Analytics |
| `elementCallPosthogAPIKey` | 374 | `"phc_rXGHx9vDmyEvyRxPziYtdVIv0ahEv8A9uLWFcCi1WcU"` | Analytics |
| `elementCallPosthogSentryDSN` | 375 | `"https://3bd2f95ba5554d4497da7153b552ffb5@sentry.tools.element.io/41"` | Analytics |
| `mapTilerConfiguration.apiKey` | 389 | `Secrets.mapLibreAPIKey` | Maps |

**Note**: `bugReportRageshakeURL`, `bugReportSentryURL`, `bugReportSentryRustURL` are sourced from `Secrets/Secrets.swift` — change there instead.

### MAYBE CHANGE (5 values)

| Property | Line | Reason |
|----------|------|--------|
| `oidcStaticRegistrations` | 252 | Only if customer has third-party OIDC providers |
| `hideBrandChrome` | 200 | Set `true` to hide Element branding chrome |
| `pusherAppID` | 271-276 | Derived from bundle ID, auto-changes |
| `backgroundAppRefreshTaskIdentifier` | 203 | Should match updated bundle ID |
| `showCreateAccountButton` | 267 | Set `false` if customer controls account creation |

### NO CHANGE NEEDED (55 values)
Feature flags, security settings, user preferences, debug options — all retain defaults.

---

## Category 4: BRANDING ASSETS

### App Icon
| File | Action |
|------|--------|
| `ElementX/Resources/AppIcon.icon/Assets/AppIcon.png` | Replace with customer's 1024x1024 PNG (no alpha) |
| `ElementX/Resources/AppIcon.icon/icon.json` | Keep (auto-fill configuration) |

### App Logo
| File | Action |
|------|--------|
| `ElementX/Resources/Assets.xcassets/images/app-logo.imageset/app-logo.pdf` | Replace with customer's vector logo PDF |

### Launch Screen
| File | Action |
|------|--------|
| `ElementX/Resources/Assets.xcassets/images/launch-background.imageset/iphone-light.png` | Replace |
| `ElementX/Resources/Assets.xcassets/images/launch-background.imageset/iphone-dark.png` | Replace |
| `ElementX/Resources/Assets.xcassets/images/launch-background.imageset/ipad-light.png` | Replace |
| `ElementX/Resources/Assets.xcassets/images/launch-background.imageset/ipad-dark.png` | Replace |

### Accent Color
**File**: `ElementX/Resources/Assets.xcassets/colors/accent-color.colorset/Contents.json`

| Mode | Current RGB | Approx Hex |
|------|-------------|------------|
| Light | (0.106, 0.114, 0.133) | `#1b1d22` (dark gray) |
| Dark | (0.922, 0.933, 0.949) | `#eceeef` (light gray) |
| High Contrast Light | (0.102, 0.110, 0.129) | `#1a1c21` |
| High Contrast Dark | (0.949, 0.961, 0.969) | `#f2f6f7` |

**Action**: Replace all 4 variants with customer's brand color.

**Build setting**: `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = "colors/accent-color"` (in `app.yml`) — no change needed, just replace the color values.

### Nightly Variant (optional)
| File | Action |
|------|--------|
| `Variants/Nightly/Resources/NightlyAppIcon.icon/` | Update if maintaining nightly builds |
| `Variants/Nightly/nightly.yml` | Update `BASE_BUNDLE_IDENTIFIER`, `APP_GROUP_IDENTIFIER` |

---

## Category 5: LOCALIZATION

### InfoPlist.strings (34 files) — Permission Descriptions
**Pattern**: `ElementX/Resources/Localizations/{locale}.lproj/InfoPlist.strings`

Locales: be, bg, cs, cy, da, de, el, en, es, et, eu, fi, fr, hr, hu, id, it, ka, ko, nb, nl, pl, pt-BR, pt, ro, ru, sk, sv, tr, uk, ur, uz, zh-Hans, zh-Hant-TW

**Strings containing "Element X"** (replace app name in each):
- `NSCameraUsageDescription` — "...Element X needs access to the camera."
- `NSLocationWhenInUseUsageDescription` — "...Element X can share your location."
- `NSMicrophoneUsageDescription` — "...Element X needs to access the microphone."

**Note**: `CFBundleDisplayName` is NOT in InfoPlist.strings — it's set via `APP_DISPLAY_NAME` in `app.yml` -> `target.yml`.

### Localizable.strings (37 files) — User-Facing Strings
**Pattern**: `ElementX/Resources/Localizations/{locale}.lproj/Localizable.strings`

**Keys containing Element branding** (present in all 37 locales):

| Key | English Value | Action |
|-----|---------------|--------|
| `screen_advanced_settings_element_call_base_url` | "Custom Element Call base URL" | Replace "Element Call" with customer brand |
| `screen_advanced_settings_element_call_base_url_description` | "Set a custom base URL for Element Call." | Same |
| `screen_change_server_error_element_pro_required_message` | "The Element Pro app is required..." | Remove or replace |
| `screen_change_server_error_element_pro_required_title` | "Element Pro required" | Remove or replace |
| `screen_room_timeline_legacy_call` | "...new Element X app." | Replace app name |
| `screen_server_confirmation_message_login_element_dot_io` | "A private server for Element employees." | Replace or remove |
| `call_invalid_audio_device_bluetooth_devices_disabled` | "Element Call does not support..." | Replace "Element Call" |

### Settings.bundle (15 locales)
**Path**: `ElementX/SupportingFiles/Settings.bundle/{locale}.lproj/`

Locales: ar, de, en, es, fr, hi, it, ja, ko, pl, pt, ru, tr, uk, zh-hans, zh-hant

**Action**: Check for Element branding in `Root.strings` files.

---

## Category 6: URL SCHEME & CALL INTEGRATION

| File | Line | Current Value | Change To |
|------|------|---------------|-----------|
| `ElementX/SupportingFiles/target.yml` | 56 | `CFBundleURLName: "Element Call"` | `"{CUSTOMER_BRAND} Call"` |
| `ElementX/SupportingFiles/target.yml` | 58 | `CFBundleURLSchemes: [io.element.call]` | `[{CUSTOMER_URL_SCHEME}]` |
| `ElementX/SupportingFiles/Info.plist` | 44 | `<string>Element Call</string>` | Auto-regenerated by XcodeGen |
| `ElementX/SupportingFiles/Info.plist` | 47 | `<string>io.element.call</string>` | Auto-regenerated by XcodeGen |

---

## Category 7: SECRETS

**File**: `Secrets/Secrets.swift`

| Secret | Purpose | Action |
|--------|---------|--------|
| `postHogAPIKey` | PostHog analytics | Remove or replace with customer's key |
| `postHogHost` | PostHog host | Remove or replace |
| `sentryDSN` | Sentry crash reporting | Remove or replace |
| `sentryRustDSN` | Sentry Rust SDK crashes | Remove or replace |
| `rageshakeURL` | Bug report server | Remove or replace |
| `mapLibreAPIKey` | MapTiler maps | Replace with customer's API key |

---

## Category 8: HARDCODED ELEMENT.IO IN SWIFT SOURCE

These are references in Swift source code beyond AppSettings that need updating:

| File | Line | Reference | Action |
|------|------|-----------|--------|
| `ServerConfirmationScreenModels.swift` | 60 | `homeserverAddress == "element.io"` | Remove or replace with customer domain |
| `CallScreen.swift` | 354 | `elementCallBaseURL: "https://call.element.io"` | Uses AppSettings in prod; this is preview only |
| `RoomScreenFooterView.swift` | 162-167 | `learnMoreURL: "https://element.io/"` | Replace (3 occurrences) |
| `AppRoutes.swift` | 138 | `knownHosts = ["call.element.io"]` | Replace with customer's call domain |
| `BugReportService.swift` | 88 | `sentry.tools.element.io` | Replace with customer's Sentry or remove |

---

## Category 9: DO NOT CHANGE

### Copyright Headers (~1,150 files)
```swift
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
```
**Reason**: Legal attribution required by license terms.

### Compound Design System (`compound-ios/`)
- Color tokens are generated from `CompoundDesignTokens` package (v6.9.0)
- `.compound.textActionPrimary` and other semantic tokens used in 40+ files
- **Action**: Accent color override via asset catalog is sufficient. Do NOT modify Compound source.

### Test Fixtures
- `@alice:element.io`, `@bob:element.io` in unit tests — mock data
- `https://call.element.io/test` in URL parser tests — test fixtures
- `#old-room-name:element.io` in room address tests
- **Action**: Update only if tests fail due to config changes.

### GitHub/Upstream References
- `element-hq/element-x-ios`, `element-hq/matrix-rust-components-swift` etc. in `project.yml`
- Sentry issue links in comments (`AppCoordinator.swift:1153`, `:1218`)
- **Action**: Do NOT change. These are upstream references.

### Documentation
- `docs/FORKING.md` — Element's forking guide (reference only)
- `SECURITY.md` — security@element.io (upstream contact)
- `documentation/*.md` — our project docs (update separately if needed)

---

## Implementation Order

1. **`app.yml`** — Identity (bundle ID, team, display name, app group)
2. **`Secrets/Secrets.swift`** — Remove/replace all Element analytics keys
3. **`AppSettings.swift`** — All 27 MUST-change values
4. **`target.yml`** — Associated domains, URL schemes, background task ID
5. **Asset catalog** — App icon, logo, launch screen, accent color
6. **InfoPlist.strings** (34 files) — Replace "Element X" in permission descriptions
7. **Localizable.strings** (37 files) — Replace Element branding in 7 string keys
8. **Swift source hardcoded refs** — 5 files with hardcoded element.io
9. **Run `xcodegen generate`** — Regenerate project
10. **Build & verify** — Confirm no Element branding leaks

---

## Verification Checklist

After all changes:
```bash
# Must return ZERO results for user-facing code (excluding tests, docs, copyright, compound-ios):
grep -ri "element.io" ElementX/Sources/ --include="*.swift" | grep -v "Copyright" | grep -v "//" | grep -v "elementCall" | grep -v "elementPro"

# Must return ZERO results:
grep -ri "Element X" ElementX/Resources/Localizations/ --include="*.strings"

# Must return ZERO results:
grep -ri "Element X" ElementX/Resources/Localizations/ --include="InfoPlist.strings"

# Bundle ID check:
grep -r "io.element.elementx" app.yml project.yml ElementX/SupportingFiles/
```

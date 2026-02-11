# Pre-Rebranding Preparations — Summary

## Overview

This document summarizes all preparatory research and tooling completed before rebranding begins. The goal was to map every file, line, and identifier that needs to change — and build automation to make the rebranding process fast and reliable once customer decisions (D-001 through D-012) are resolved.

---

## Research Audits Completed

Eight audit documents were produced through systematic codebase exploration:

### 1. OIDC Authentication Flow (`oidc_audit.md`)

Mapped the complete OIDC authentication flow from `ASWebAuthenticationSession` through token exchange:
- **Redirect URI:** `https://element.io/oidc/login` (AppSettings.swift:255)
- **14 element.io URLs** in AppSettings that must change
- **9 associated domains** in entitlements (universal links + webcredentials)
- **Static OIDC registrations** for thirdroom.io (line 253)
- All authentication is routed through `AuthenticationFlowCoordinator` → `OIDCAuthenticationPresenter` → `AuthenticationService`
- The `AppSettings.override()` method supports runtime OIDC configuration

### 2. Compound Design System & Branding (`branding_audit.md`)

Documented the complete visual identity system:
- **Compound design tokens:** Local `compound-ios/` SPM package + external `CompoundDesignTokens` v6.9.0
- **Color assets:** `accent-color` (4 variants) and `background-color` (4 variants) in asset catalog
- **Visual assets:** `app-logo.pdf` (vector), 4 launch screen PNGs (iPhone/iPad × light/dark)
- **Theme override hook:** `CompoundHookProtocol` in AppHooks for programmatic color overrides
- **37 locales** with brand strings in `InfoPlist.strings` and `Localizable.strings`
- **~86 files** total to modify (including all locale variants)

### 3. NSE Target (`nse_audit.md`)

Audited the Notification Service Extension:
- **1 hardcoded string** at `NotificationServiceExtension.swift:33` — `"io.element.elementx.receivedWhileOfflineNotification"`
- Everything else auto-derives from `app.yml` build variables
- Shares app group, keychain, and AppSettings with main app via `InfoPlistReader`
- 3 communication channels: app group container, keychain, shared settings

### 4. ShareExtension Target (`share_extension_audit.md`)

Audited the Share Extension:
- **Zero hardcoded brand references** — cleanest target for rebranding
- Custom URL scheme construction uses runtime `InfoPlistReader.main.baseBundleIdentifier`
- Simpler entitlements than NSE (no notification filtering)
- 4 dependencies vs NSE's 8

### 5. Hardcoded Identifiers Inventory (`hardcoded_identifiers_inventory.md`)

Comprehensive grep of all brand-specific identifiers across the entire codebase:

| Classification | Count | Description |
|---------------|-------|-------------|
| Auto-derived (a) | 28 | Change automatically via `app.yml` build variables |
| Must change manually (b) | 52 | Hardcoded in Swift source, YAML, or plists |
| Test/preview data (c) | 17 | Type names, test fixtures, mock data |
| **Total** | **97** | Across 35+ files |

Key categories of manual changes:
- 8 dispatch queue labels (`io.element.elementx.*`)
- 2 notification identifiers
- 1 background task ID (in 3 locations)
- 15 AppSettings URLs
- 9 associated domains
- 1 Element Call client ID
- 1 Element Pro App Store URL
- Analytics endpoints (PostHog, Sentry)

### 6. Element Call Infrastructure (`element_call_audit.md`)

Audited the complete Element Call (MatrixRTC + LiveKit) integration:
- **Not Jitsi** — customer's TOR mentions Jitsi, but project uses Element Call
- **8 hardcoded references** across target.yml, AppSettings.swift, AppRoutes.swift, CallScreen.swift
- **Embedded Element Call web app** bundled via SPM — works out-of-box with configured homeserver
- **Can be disabled** via server configuration (no code changes) or via code changes (~2–3 hours)
- Customer needs LiveKit server if proceeding with calls
- **Decision D-011 needed** — Jitsi vs Element Call

### 7. Privacy Manifest Compliance (`privacy_manifest_audit.md`)

Audited App Store privacy requirements:
- **Overall grade: B+ (88%)**
- **2 privacy manifests exist** (Main App + NSE), **1 missing** (ShareExtension — GAP)
- **4 Required Reason APIs** correctly declared (UserDefaults, FileTimestamp, DiskSpace, SystemBootTime)
- **1 API missing** — Network Information (`NWPathMonitor` usage not declared)
- **11 data types** declared with correct linked/tracking flags
- **Analytics/Sentry/Rageshake** all have placeholder values — customer must configure
- **NSPrivacyTracking = false** — no third-party tracking

### 8. Upstream Sync Report (`upstream_sync_report.md`)

Checked upstream Element X iOS for new commits since fork:
- **18 new commits** on upstream `main` (Feb 9–10, 2026)
- **SDK update:** MatrixRustSDK v26.02.03 → v26.02.10
- **3 bug fixes:** server confirmation crashes, iOS 26 PassthroughWindow, QR/Link sign-in
- **~10 Spaces feature commits** (new feature, not infrastructure)
- **3–4 file conflicts** with our fork (AppCoordinator, AppSettings, GeneratedMocks, project.yml)
- **Sync recommended** but not urgent — estimated 15–30 min conflict resolution

---

## Automation Scripts Created

### `scripts/rebrand.sh` (28KB)

Automated rebranding script that handles all text-based substitutions across the project.

**9 sections covering:**
1. `app.yml` — build variables (APP_DISPLAY_NAME, BUNDLE_ID, TEAM_ID, APP_GROUP)
2. `project.yml` — organization name
3. `AppSettings.swift` — 22 URLs and configuration values
4. `target.yml` — URL schemes, background task IDs, associated domains
5. NSE — hardcoded notification ID
6. 15 Swift files — dispatch queue labels, notification IDs, call client ID
7. Navigation/parser code — Element Call hosts, server special cases
8. Test files — test suite names
9. Info.plist — background task identifier

**Features:**
- `--dry-run` mode: preview all changes without modifying files
- Input via environment variables or interactive prompts
- Creates backup branch before changes (`backup/pre-rebrand-YYYYMMDD-HHMMSS`)
- Validates all required parameters and URL/bundle ID format
- Colored console output
- Idempotent — safe to run multiple times
- macOS-compatible (`sed -i ''`)

**Usage:**
```bash
APP_NAME="MyMessenger" \
BUNDLE_ID="com.customer.messenger" \
TEAM_ID="ABC123XYZ" \
APP_GROUP="group.com.customer" \
WEBSITE_URL="https://example.com" \
OIDC_REDIRECT_URL="https://example.com/oidc/login" \
PRIVACY_URL="https://example.com/privacy" \
TERMS_URL="https://example.com/terms" \
COPYRIGHT_URL="https://example.com/copyright" \
./scripts/rebrand.sh --dry-run    # Preview first
./scripts/rebrand.sh              # Then apply
xcodegen generate                 # Regenerate Xcode project
```

### `scripts/rebrand_strings.sh` (20KB)

Localization string replacement across all 37 locales.

**Two phases:**
1. **InfoPlist.strings** (automatic): Replaces "Element X" in permission description strings across 34 locales (3 locales have no InfoPlist.strings). Handles locale-specific variants: Welsh "Elfen X" and Urdu transliteration.
2. **Localizable.strings** (report only): Scans for brand references ("Element X", "Element Pro", "Element Call", "element.io") and generates a categorized report for manual review. Does NOT auto-modify — these strings need human judgment.

**Features:**
- `--dry-run` mode with before/after preview
- Generates timestamped report at `reports/rebrand_report_*.txt`
- UTF-8 safe (uses `perl -CSD`)
- Fixed-string matching (not regex) to avoid breaking localized text

**Usage:**
```bash
./scripts/rebrand_strings.sh --app-name "MyMessenger" --dry-run
./scripts/rebrand_strings.sh --app-name "MyMessenger"
```

---

## Rebranding Workflow (When Customer Provides Values)

Once decisions D-001 (App Identity) and related decisions are resolved:

```
Step 1: Run rebrand.sh with customer values        → Substitutes 52+ identifiers
Step 2: Run rebrand_strings.sh with app name       → Updates 34 locale files + generates report
Step 3: Review Localizable.strings report           → Manual review of ~260 brand references
Step 4: Replace visual assets                       → Customer provides icon, logo, launch images
Step 5: Replace GoogleService-Info.plist             → Customer provides Firebase config
Step 6: Update accent-color/background-color assets → Customer provides brand colors
Step 7: xcodegen generate                           → Regenerate Xcode project
Step 8: Build and verify                            → Test on simulator
```

Estimated rebranding time with scripts: **1-2 hours** (vs 4-8 hours manual).

---

## Files in This Branch

| File | Type | Size |
|------|------|------|
| `documentation/oidc_audit.md` | Research doc | 257 lines |
| `documentation/branding_audit.md` | Research doc | 306 lines |
| `documentation/nse_audit.md` | Research doc | 291 lines |
| `documentation/share_extension_audit.md` | Research doc | 234 lines |
| `documentation/hardcoded_identifiers_inventory.md` | Research doc | 219 lines |
| `documentation/element_call_audit.md` | Research doc | ~200 lines |
| `documentation/privacy_manifest_audit.md` | Research doc | ~200 lines |
| `documentation/upstream_sync_report.md` | Research doc | ~150 lines |
| `documentation/pre_rebranding_preparations.md` | Summary doc | This file |
| `scripts/rebrand.sh` | Automation | 712 lines |
| `scripts/rebrand_strings.sh` | Automation | 560 lines |

**Total: 3,100+ lines of documentation and tooling.**

---

## What's Still Blocked

All of the following require customer decisions before proceeding:

| Blocker | Decision | Status |
|---------|----------|--------|
| App identity (name, bundle ID, team ID) | D-001 | NOT YET DECIDED |
| AGPL v3 commercial license | D-002 | NOT YET INITIATED |
| APNs vs FCM (Firebase config values) | D-003 | Infrastructure ready, needs customer values |
| Homeserver URL | D-004 | NOT YET DECIDED |
| Push gateway URL & Sygnal config | D-005 | NOT YET DECIDED |
| OIDC provider configuration | D-010 | NOT YET DECIDED |
| Brand assets (icon, colors, logo) | D-008 | NOT YET PROVIDED |
| Apple Developer account | D-007 | NOT YET CONFIRMED |

**Next action:** Send `customer_pre_dev_briefing_ru.md` to customer and conduct initial meeting using `customer_questionnaire_init_stage.md`.

---

*Last updated: 2026-02-11*

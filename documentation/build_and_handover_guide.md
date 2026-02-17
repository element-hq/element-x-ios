# Build & Handover Guide — UCMeet iOS

> For the customer's technical team or future maintainer.
> Last updated: 2026-02-17

---

## 1. Prerequisites

### Hardware & Software

| Requirement | Version | Notes |
|-------------|---------|-------|
| macOS | 15.x+ (Sequoia) | Required for Xcode 26 |
| Xcode | 26.0+ | Install from Mac App Store |
| XcodeGen | 2.44+ | `brew install xcodegen` |
| git-lfs | any | `brew install git-lfs && git lfs install` |
| CocoaPods | Not used | Project uses SPM only |
| Apple Developer account | Required | For signing, TestFlight, App Store |

### Accounts & Credentials

| Item | Purpose | Where to get |
|------|---------|-------------|
| Apple Developer Program membership | Code signing, App Store | [developer.apple.com](https://developer.apple.com) |
| GitHub access to this repo | Source code | Repository admin |
| Firebase project (GoogleService-Info.plist) | Push notifications | Firebase Console |
| Matrix homeserver admin | Server config, MAS client registration | Customer's server admin |

---

## 2. Clone & First Build

```bash
# Clone the repository
git clone https://github.com/smurzaliev/custom-element-messenger-ios.git
cd custom-element-messenger-ios

# Ensure git-lfs is configured
git lfs install
git lfs pull

# Generate the Xcode project from YAML
xcodegen generate

# Open in Xcode (SPM packages will resolve automatically)
open ElementX.xcodeproj
```

### Build from command line

```bash
xcodebuild build \
  -project ElementX.xcodeproj \
  -scheme ElementX \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skipPackagePluginValidation \
  -skipMacroValidation
```

First build takes ~5-10 minutes (SPM package resolution + compilation). Subsequent builds are incremental (~30-60 seconds).

---

## 3. Project Structure

### Build System

The project uses **XcodeGen** — YAML files generate the `.xcodeproj`. **Never edit `.xcodeproj` directly.**

```
project.yml          → Root project config (targets, packages, settings)
app.yml              → App identity (display name, bundle ID, app group)
ElementX/SupportingFiles/target.yml  → Main app target config
NSE/SupportingFiles/target.yml       → Notification Service Extension
ShareExtension/SupportingFiles/target.yml → Share Extension
```

After editing any YAML file, regenerate:

```bash
xcodegen generate
```

### Key Configuration File

**`app.yml`** — Central identity configuration:

```yaml
settings:
  APP_DISPLAY_NAME: UCMeet           # User-visible app name
  PRODUCTION_APP_NAME: UCMeet        # Production app name
  APP_GROUP_IDENTIFIER: group.io.element  # Shared storage (change with Bundle ID)
  BASE_BUNDLE_IDENTIFIER: io.element.elementx  # Bundle ID (change for production)
```

### Targets

| Target | Purpose |
|--------|---------|
| ElementX | Main app |
| NSE | Notification Service Extension (processes push notifications) |
| ShareExtension | Share sheet integration |
| UnitTests | Unit test suite |
| UITests | UI test suite |
| PreviewTests | SwiftUI preview snapshot tests |
| IntegrationTests | Integration tests |
| AccessibilityTests | Accessibility tests |

### Architecture

- **Pattern:** Coordinator-based MVVM
- **UI:** SwiftUI (100%)
- **Core SDK:** Matrix Rust SDK v26.02.10 (binary via SPM — cannot modify)
- **Design system:** Compound (Element's semantic design tokens, bundled as local package)
- **Auth:** OIDC via Matrix Authentication Service (MAS)
- **Calls:** Element Call (MatrixRTC + LiveKit, embedded web app via SPM)
- **Push:** APNs + Firebase Cloud Messaging (FCM)

---

## 4. Configuration Reference

### Server Configuration

**File:** `ElementX/Sources/Application/Settings/AppSettings.swift`

| Setting | Current Value | Purpose |
|---------|---------------|---------|
| `accountProviders` | `["matrix.ucmeet.org"]` | Default homeserver |
| `websiteURL` | `https://ucmeet.info` | Legal / About links |
| `acceptableUseURL` | `https://ucmeet.info/policy-152` | Acceptable use policy |
| `privacyURL` | `https://ucmeet.info/policy-152` | Privacy policy |
| `pushGatewayBaseURL` | `https://matrix.org` | Push gateway (Sygnal) |

### OIDC Configuration

**File:** `ElementX/Sources/Application/Settings/AppSettings.swift`

The app uses OIDC via MAS (Matrix Authentication Service) at `matrix.ucmeet.org`. Current OIDC redirect URLs use `element.io` domain because:
1. MAS requires all registration metadata URIs on the same host
2. `element.io` has an AASA (Apple App-Site Association) file required for `ASWebAuthenticationSession`
3. `ucmeet.info` does not have an AASA file yet

**To migrate OIDC to ucmeet.info:**
1. Host an AASA file at `https://ucmeet.info/.well-known/apple-app-site-association`
2. Update `oidcRedirectURL` and related URLs in AppSettings.swift
3. Update associated domains in `target.yml` (replace `webcredentials:*.element.io`)
4. Re-register the OIDC client in MAS with new redirect URIs

### Calls Configuration

Calls use the **embedded Element Call** web app (SPM package `element-call-swift` v0.16.3). No hosted instance needed. Calls route through MatrixRTC + LiveKit SFU.

**File:** `ElementX/SupportingFiles/target.yml`
- URL scheme: `org.ucmeet.call`
- No universal link hosts needed (embedded bundle)

LiveKit must be configured in the homeserver's `.well-known/matrix/client`.

### Push Notifications

**Status:** FCM code implemented, awaiting real Firebase configuration.

**To enable push:**
1. Create a Firebase project in the Firebase Console
2. Register the iOS app with the production Bundle ID
3. Download `GoogleService-Info.plist` and replace the placeholder at:
   `ElementX/SupportingFiles/GoogleService-Info.plist`
4. Configure Sygnal (push gateway) with the Firebase server key
5. Update `pushGatewayBaseURL` in AppSettings.swift to point to Sygnal

### Localization

The app supports 3 locales:
- `en` — English (primary, 6 string files)
- `en-US` — English US (1 override file)
- `ru` — Russian (4 string files)

String files are at: `ElementX/Resources/Localizations/{locale}.lproj/`

---

## 5. Bundle ID Migration (When Ready)

When the customer decides on a Bundle ID (e.g., `org.ucmeet.chat`):

### Step 1: Update `app.yml`

```yaml
settings:
  APP_GROUP_IDENTIFIER: group.org.ucmeet.chat
  BASE_BUNDLE_IDENTIFIER: org.ucmeet.chat
```

### Step 2: Update dispatch queue labels

16 files contain `io.element.elementx` in dispatch queue labels. Search and replace:

```bash
grep -r "io.element.elementx" --include="*.swift" -l
```

Replace `io.element.elementx` with the new Bundle ID in all results.

### Step 3: Update background task identifier

**File:** `ElementX/SupportingFiles/target.yml`

```yaml
BGTaskSchedulerPermittedIdentifiers: [ org.ucmeet.chat.background.refresh ]
```

### Step 4: Update NSE notification ID

**File:** `NSE/Sources/NotificationServiceExtension.swift` (line 33)

```swift
static let receivedWhileOfflineNotificationID = "org.ucmeet.chat.receivedWhileOfflineNotification"
```

### Step 5: Regenerate and verify

```bash
xcodegen generate
xcodebuild build -project ElementX.xcodeproj -scheme ElementX \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skipPackagePluginValidation -skipMacroValidation
```

### Step 6: Configure signing

In Xcode:
1. Select the ElementX target → Signing & Capabilities
2. Set Team to your Apple Developer account
3. Set Bundle Identifier to the new ID
4. Repeat for NSE and ShareExtension targets

---

## 6. Updating the App

### Upstream Sync (Element X updates)

The fork tracks upstream Element X. To pull upstream changes:

```bash
# Add upstream remote (one-time)
git remote add upstream https://github.com/element-hq/element-x-ios.git

# Fetch upstream
git fetch upstream

# Merge upstream main into develop
git merge upstream/main

# Resolve conflicts, rebuild, test
xcodegen generate
xcodebuild build ...
```

**Conflict-prone files:** `project.yml` (package versions), `app.yml`, `AppSettings.swift`.

### SDK Updates

Matrix Rust SDK is pinned in `project.yml`:

```yaml
MatrixRustSDK:
  url: https://github.com/element-hq/matrix-rust-components-swift
  exactVersion: 26.02.10
```

To update: change the version, run `xcodegen generate`, resolve any API changes.

---

## 7. Testing

### Unit Tests

```bash
xcodebuild test \
  -project ElementX.xcodeproj \
  -scheme ElementX \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skipPackagePluginValidation \
  -skipMacroValidation
```

~962 tests. 33 rebrand-affected tests are all passing. ~39 pre-existing upstream failures.

### Manual Testing Checklist

| Feature | How to test |
|---------|------------|
| Login | Launch app → enter homeserver → OIDC login via MAS |
| Room list | Verify rooms load after login (Sliding Sync) |
| Messaging | Open room → send text, image, reaction |
| Calls | In a room → tap call button (requires 2nd account) |
| Push | Send message from another client → verify notification |
| Settings | Settings → verify legal links to ucmeet.info |
| Localization | Set device to Russian → verify all strings |
| E2EE | Send message → verify encryption shield icon |

---

## 8. App Store Submission

### Pre-submission checklist

- [ ] Bundle ID set to production value
- [ ] Code signing with distribution certificate
- [ ] GoogleService-Info.plist has real Firebase credentials
- [ ] Privacy manifests present (all 3 targets)
- [ ] App icon is final (1024x1024, no alpha, no rounded corners)
- [ ] `ITSAppUsesNonExemptEncryption` set to `YES` in Info.plist
- [ ] ECCN documentation prepared (Matrix SDK uses AES-256, Curve25519)

### Build for distribution

```bash
xcodebuild archive \
  -project ElementX.xcodeproj \
  -scheme ElementX \
  -archivePath build/UCMeet.xcarchive \
  -skipPackagePluginValidation \
  -skipMacroValidation

xcodebuild -exportArchive \
  -archivePath build/UCMeet.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/export
```

Or use Xcode: Product → Archive → Distribute App.

See `documentation/app_store_prep_templates.md` for detailed App Store listing templates, privacy nutrition labels, and Guideline 4.3 differentiation strategy.

---

## 9. File Inventory

### Documentation

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Project context and AI assistant instructions |
| `documentation/project_overview.md` | Quick-reference architecture overview |
| `documentation/change_map.md` | Complete rebranding change map |
| `documentation/firebase_integration.md` | FCM integration details |
| `documentation/oidc_audit.md` | OIDC redirect URI architecture |
| `documentation/app_store_prep_templates.md` | App Store submission templates |
| `documentation/decisions_tracker.md` | Decision tracking (12 items) |
| `documentation/overall_implementation_progress.md` | Living progress tracker |

### Automation Scripts

| Script | Purpose |
|--------|---------|
| `scripts/rebrand.sh` | Text substitution automation (Bundle ID, identifiers) |
| `scripts/rebrand_strings.sh` | Locale string replacement |

### Git Tags

| Tag | Commit | Purpose |
|-----|--------|---------|
| `checkpoint/unmodified-build` | `7c96ebfca` | Last upstream commit before fork changes |
| `backup/pre-upstream-sync-20260211` | — | State before upstream merge |
| `checkpoint/branding-complete` | `caf1d6872` | All user-visible branding complete |

---

## 10. Support & Contacts

| Role | Contact |
|------|---------|
| Developer | Saidakhror Murzaliev |
| Upstream project | [github.com/element-hq/element-x-ios](https://github.com/element-hq/element-x-ios) |
| Matrix Rust SDK | [github.com/matrix-org/matrix-rust-sdk](https://github.com/matrix-org/matrix-rust-sdk) |
| Element Call | [github.com/element-hq/element-call](https://github.com/element-hq/element-call) |

---

## Quick Reference Card

```
Clone:     git clone ... && git lfs pull
Generate:  xcodegen generate
Build:     xcodebuild build -project ElementX.xcodeproj -scheme ElementX ...
Test:      xcodebuild test -project ElementX.xcodeproj -scheme ElementX ...
Config:    app.yml (identity), AppSettings.swift (server/features)
Locales:   ElementX/Resources/Localizations/{en,en-US,ru}.lproj/
```

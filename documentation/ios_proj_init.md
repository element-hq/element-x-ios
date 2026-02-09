# iOS Project Initialization — Technical Plan
## Element X iOS Fork: From Clone to First Branded Build

**Purpose:** Step-by-step technical guide for Claude (AI assistant) and developer to execute the initial project setup. Follow sequentially — each step depends on the previous one.

**Scope:** Covers everything from forking the repository to achieving a fully branded, building, configured application — ready for server integration testing.

**Estimated effort:** 28–36 hours (Phases 1 + 3 of the implementation plan, plus identity and localization work)

---

## Table of Contents

1. [Architecture Overview & Technical Justification](#1-architecture-overview--technical-justification)
2. [Prerequisites Checklist](#2-prerequisites-checklist)
3. [Step 1: Fork & Clone Repository](#3-step-1-fork--clone-repository)
4. [Step 2: Build Environment Setup](#4-step-2-build-environment-setup)
5. [Step 3: First Successful Build](#5-step-3-first-successful-build)
6. [Step 4: Codebase Mapping & Audit](#6-step-4-codebase-mapping--audit)
7. [Step 5: Apple Developer Provisioning](#7-step-5-apple-developer-provisioning)
8. [Step 6: Identity Changes (Bundle ID, Team, App Group)](#8-step-6-identity-changes)
9. [Step 7: Branding — App Icon & Colors](#9-step-7-branding--app-icon--colors)
10. [Step 8: Branding — Strings, Launch Screen & Element Removal](#10-step-8-branding--strings-launch-screen--element-removal)
11. [Step 9: Localization](#11-step-9-localization)
12. [Step 10: Configuration (AppSettings, Analytics, Feature Flags)](#12-step-10-configuration)
13. [Step 11: OIDC & Associated Domains](#13-step-11-oidc--associated-domains)
14. [Step 12: Push Notification Plumbing](#14-step-12-push-notification-plumbing)
15. [Step 13: Calls Configuration](#15-step-13-calls-configuration)
16. [Step 14: Full Build Verification & Audit](#16-step-14-full-build-verification--audit)
17. [Step 15: Git Checkpoints & Branching Strategy](#17-step-15-git-checkpoints--branching-strategy)
18. [Claude-Specific Workflow Notes](#18-claude-specific-workflow-notes)

---

## 1. Architecture Overview & Technical Justification

### 1.1 Why This Architecture Exists (We Inherit, Not Choose)

Element X iOS is a mature, production application. We are forking it — not building from scratch. The architecture is **inherited** and must be understood, not redesigned. Any deviation from the established patterns will increase merge difficulty with upstream and introduce bugs.

### 1.2 MVVM + Coordinator Pattern

Element X iOS uses **Coordinator-based MVVM**. Here's why it works and why we keep it:

**Coordinators** own navigation logic and screen lifecycle:
```
AppCoordinator
├── AuthenticationCoordinator       ← Login/registration flow
├── HomeScreenCoordinator           ← Main tab, room list
│   ├── RoomScreenCoordinator       ← Individual chat
│   ├── SettingsScreenCoordinator   ← Settings flow
│   └── ...
└── CallScreenCoordinator           ← Voice/video calls
```

- Each Coordinator creates its ViewModel, injects dependencies, and presents its View
- Coordinators handle navigation transitions (push, present, dismiss)
- This decouples navigation from view logic — critical for testability
- SwiftUI's `NavigationStack` / `NavigationSplitView` are managed at the Coordinator level

**ViewModels** (`@Observable` or `ObservableObject`):
- Hold screen state and business logic
- Expose published properties consumed by Views
- Communicate with Services for data operations
- Never import SwiftUI (except for `@Published` / `@Observable`)

**Views** (pure SwiftUI):
- Stateless renderers — they read ViewModel state and call ViewModel actions
- No business logic, no direct service access
- Use Compound design tokens for all visual styling

**Services** (dependency-injected singletons/protocols):
- `ClientProxy` — wraps Matrix Rust SDK client
- `NotificationManager` — push registration, token handling
- `AppSettings` — all configurable values (server URLs, feature flags, etc.)
- `AnalyticsService` — telemetry (to be disabled/replaced)
- `UserSessionStore` — session persistence

**Why this matters for our fork:**
- We modify **Services** (configuration) and **Assets** (branding) — minimal risk
- We do NOT modify **Coordinators**, **ViewModels**, or **Views** (no functional changes)
- This keeps our fork close to upstream, enabling future merges

### 1.3 SwiftUI

Element X iOS is 100% SwiftUI. No UIKit views (except where bridged for system APIs like camera/calls). Justification:
- Modern declarative UI — less code, fewer bugs
- Native dark mode, Dynamic Type, accessibility support
- Compound design system integrates via SwiftUI `ViewModifier`s and `Color` extensions
- Element chose SwiftUI to replace the legacy UIKit-based Element iOS

**For our fork:** We don't touch Views. We change the design tokens they consume.

### 1.4 Compound Design System

Compound is Element's cross-platform design system. In the iOS project:
- **Color tokens** are semantic names (e.g., `compound.colorAccent`, `compound.colorTextPrimary`)
- Colors resolve to hex values based on light/dark mode
- The accent color propagates through the entire app via these tokens
- Modifying the accent color at the token level changes it everywhere

**Key insight:** To rebrand, we change the token values — not individual views.

### 1.5 Matrix Rust SDK

The core messaging engine is a **Rust library** compiled to a Swift-compatible binary:
- Distributed as a Swift Package (`MatrixRustSDK`)
- Provides: login, sync, messaging, encryption, key management, push registration
- **Opaque** — we cannot read or modify the Rust source code from Swift
- All interaction goes through generated Swift bindings
- Pin the SDK version at fork time — do NOT upgrade unless necessary

### 1.6 XcodeGen Build System

The `.xcodeproj` file is **generated**, not hand-maintained:
- `project.yml` → top-level project settings
- `app.yml` → main app target (bundle ID, name, team)
- `target.yml` (per directory) → per-target entitlements, capabilities
- Workflow: edit YAML → run `xcodegen generate` → open generated `.xcodeproj`
- **Never edit `.xcodeproj` directly** — changes will be lost on regeneration

### 1.7 SPM (Swift Package Manager)

All dependencies managed via SPM (defined in `Package.swift` or `project.yml`):
- Matrix Rust SDK
- Compound design tokens
- Various utilities (KeychainAccess, etc.)
- **No CocoaPods. No Carthage.**
- Resolution happens during `xcodegen generate` or first Xcode build

---

## 2. Prerequisites Checklist

Before starting any step, verify:

| # | Prerequisite | How to verify |
|---|-------------|---------------|
| 1 | macOS (latest stable) | `sw_vers` |
| 2 | Xcode installed (latest stable, supporting iOS 17 SDK) | `xcodebuild -version` |
| 3 | Xcode Command Line Tools | `xcode-select -p` |
| 4 | Homebrew installed | `brew --version` |
| 5 | Git configured | `git config user.name && git config user.email` |
| 6 | Apple Developer account active | Log into developer.apple.com |
| 7 | Customer decisions made (APNs, iOS 17+, calls) | Check `decisions_tracker.md` |
| 8 | Design assets received (icon, color, name) — or placeholders agreed | Check `decisions_tracker.md` D-008 |

---

## 3. Step 1: Fork & Clone Repository

### 3.1 Choose the Source Tag/Branch

**Decision:** Use the latest stable **release tag** with iOS 17.0 minimum deployment target. Do NOT use `develop` branch (iOS 18.5 minimum, unstable).

```bash
# Visit github.com/element-hq/element-x-ios/tags
# Identify the latest release tag (e.g., 1.x.x)
# Verify its minimum deployment target in project.yml or app.yml
```

### 3.2 Fork

Two approaches:

**Option A — GitHub Fork (recommended if repo will be on GitHub):**
- Fork via GitHub UI to your account or organization
- Clone the fork locally

**Option B — Manual clone + new remote (recommended for private hosting):**
```bash
git clone --branch <chosen-tag> https://github.com/element-hq/element-x-ios.git <project-name>
cd <project-name>
git remote rename origin upstream
git remote add origin <your-private-repo-url>
```

### 3.3 Verify Clone

```bash
# Check the tag
git describe --tags

# Check file count
find . -name "*.swift" | wc -l
# Expected: ~900+ files

# Check for FORKING.md
cat FORKING.md
```

### 3.4 Claude Task

> **Claude:** Read `FORKING.md` completely. Summarize all instructions and requirements. This is Element's official forking guide and takes priority over any assumptions.

**Git checkpoint:** None yet — this is the upstream state.

---

## 4. Step 2: Build Environment Setup

### 4.1 Install XcodeGen

```bash
brew install xcodegen
xcodegen --version
```

### 4.2 Generate Xcode Project

```bash
cd <project-root>
xcodegen generate
```

This reads `project.yml`, `app.yml`, and all `target.yml` files to produce the `.xcodeproj`.

**Common issues:**
- XcodeGen version mismatch — check if project specifies a version in its docs
- Missing environment variables — some projects use `$VARIABLE` in YAML
- Path errors — run from the project root directory

### 4.3 Resolve SPM Dependencies

Open the generated `.xcodeproj` in Xcode. SPM resolution starts automatically.

**This will take 10–30 minutes** — Matrix Rust SDK is a large binary package.

**Common issues:**
- Network timeouts — retry, or use `xcodebuild -resolvePackageDependencies`
- Version conflicts — check `Package.resolved` for pinned versions
- Disk space — Matrix Rust SDK binary is large (~100MB+)

### 4.4 Claude Task

> **Claude:** After SPM resolution, list all resolved packages and their versions. Save this as a reference snapshot. Any future build issue can be compared against this baseline.

---

## 5. Step 3: First Successful Build

### 5.1 Build Unmodified Project

In Xcode:
1. Select the main app scheme (e.g., `ElementX`)
2. Select an iOS Simulator target (e.g., iPhone 15 Pro, iOS 17.x)
3. Build (Cmd+B)

**Expected result:** Build succeeds. If it fails — debug before proceeding. Do NOT modify code to fix build issues; they indicate an environment problem.

**From command line (alternative):**
```bash
xcodebuild -scheme ElementX -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

### 5.2 Verify All Targets

The project has multiple targets. All must build:

| Target | Purpose | Must build? |
|--------|---------|-------------|
| Main app (e.g., `ElementX`) | The application itself | Yes |
| NSE (`NotificationServiceExtension`) | Rich push notification handling + decryption | Yes |
| Unit tests (if present) | Test suite | Nice to have |
| UI tests (if present) | UI test suite | Nice to have |

### 5.3 Run on Simulator

1. Run the app (Cmd+R)
2. Verify it launches and reaches the login/welcome screen
3. Take a screenshot — this is the "before" state for comparison

### 5.4 Document Build Environment

Record:
```
macOS version: [version]
Xcode version: [version]
XcodeGen version: [version]
Source tag: [tag]
iOS Deployment Target: [version]
SPM packages resolved: [date]
First build: SUCCESS / FAIL
```

**Git checkpoint: `checkpoint/unmodified-build`** — Tag this commit. This is the known-good baseline.

---

## 6. Step 4: Codebase Mapping & Audit

This is the most critical Claude-assisted step. Before changing anything, map EVERYTHING that needs to change.

### 6.1 Identity Files (Bundle ID, Team, App Group)

> **Claude:** Search the entire project for these patterns and list every file + line:

```
Grep patterns:
- Current bundle identifier (e.g., "io.element.elementx" or similar)
- Current app group identifier (e.g., "group.io.element")
- Current team ID
- "element.io" (domain references)
- "Element" as app name (in YAML, plist, strings files)
```

**Expected locations:**
- `app.yml`
- `target.yml` (multiple)
- `.entitlements` files
- `Info.plist` (if not generated)
- `AppSettings.swift`
- `InfoPlist.strings` (37+ locales)

### 6.2 Branding Assets

> **Claude:** Find all branding-related assets:

```
Glob patterns:
- **/Assets.xcassets/**/AppIcon*
- **/Assets.xcassets/**/AccentColor*
- **/Assets.xcassets/**/LaunchScreen*
- **/Assets.xcassets/**/Logo*
- **/Assets.xcassets/**/Splash*
```

### 6.3 Element-Specific Strings

> **Claude:** Search for all hardcoded Element branding in user-facing text:

```
Grep patterns (case-insensitive):
- "Element"
- "element.io"
- "Element X"
- "element-hq"
- "New Vector"
- "element.call" (Element Call URL)
```

**Categorize findings:**
- **Must change** — user-visible branding (app name, about screen, legal URLs)
- **Should change** — internal references that leak to users (analytics identifiers, push IDs)
- **Do not change** — code-level references (import names, SDK identifiers, upstream comments)

### 6.4 Configuration Points

> **Claude:** Read `AppSettings.swift` completely and list every configurable value with its current default:

Expected categories:
- Server URLs (homeserver, push gateway, Element Call)
- OIDC configuration (client ID, redirect URI)
- Analytics keys (PostHog, Sentry, etc.)
- Feature flags
- Legal URLs (privacy policy, terms of service)
- Push notification identifiers (pusherAppID, pushGatewayNotifyEndpoint)

### 6.5 Localization Files

> **Claude:** List all `.strings` and `.stringsdict` files. Count locales. Identify which files contain app name or Element branding.

```
Glob patterns:
- **/*.strings
- **/*.stringsdict
- **/Localizable.strings
- **/InfoPlist.strings
```

### 6.6 Entitlements

> **Claude:** Read all `.entitlements` files. List every entitlement and its current value:

Expected entitlements:
- `aps-environment` (push notifications)
- `com.apple.security.application-groups` (shared data between app and NSE)
- `com.apple.developer.associated-domains` (universal links, OIDC)
- `keychain-access-groups` (secure storage)

### 6.7 Create the Change Map

Compile all findings into a structured change map:

```markdown
## Change Map

### Files to modify:
1. app.yml — bundle ID, name, team, app group
2. target.yml (main) — entitlements
3. target.yml (NSE) — bundle ID, entitlements
4. AppSettings.swift — all server/config values
5. Assets.xcassets — icon, accent color
6. InfoPlist.strings (×37 locales) — app name
7. [additional files from audit]

### Files to NOT modify:
- Matrix Rust SDK bindings
- Coordinator/ViewModel/View logic
- Package.swift / Package.resolved
```

**Git checkpoint:** No code changes yet. Save the change map as `docs/change_map.md` or keep in session notes.

---

## 7. Step 5: Apple Developer Provisioning

### 7.1 Register App ID

In Apple Developer Portal → Certificates, Identifiers & Profiles → Identifiers:

1. Create new App ID
2. **Bundle ID:** `com.<customer>.<appname>` (explicit, not wildcard)
3. Enable capabilities:
   - Push Notifications
   - App Groups
   - Associated Domains

### 7.2 Register App Group

1. Create new App Group: `group.com.<customer>.<appname>`
2. This is used for shared data between the main app and NSE (encrypted message cache, session data)

### 7.3 Generate Certificates

| Certificate | Purpose | Create if missing |
|------------|---------|-------------------|
| iOS Development | Code signing for development builds | Yes |
| iOS Distribution | Code signing for App Store builds | Yes |

### 7.4 Create Provisioning Profiles

| Profile | Type | App ID | Includes |
|---------|------|--------|----------|
| Dev — Main App | Development | `com.<customer>.<appname>` | Dev certificate + test devices |
| Dev — NSE | Development | `com.<customer>.<appname>.nse` | Dev certificate + test devices |
| Dist — Main App | App Store Distribution | `com.<customer>.<appname>` | Dist certificate |
| Dist — NSE | App Store Distribution | `com.<customer>.<appname>.nse` | Dist certificate |

### 7.5 Automatic vs Manual Signing

**Recommendation:** Use Xcode Automatic Signing for development, switch to manual for distribution.

In `app.yml` or project settings:
- Set `DEVELOPMENT_TEAM` to your Team ID
- Set `CODE_SIGN_STYLE` to `Automatic` (for development)

---

## 8. Step 6: Identity Changes

This is the first code modification. From this point forward, every change must be deliberate and tracked.

### 8.1 Modify `app.yml`

Replace:
```yaml
# FROM (example — actual values will differ):
PRODUCT_BUNDLE_IDENTIFIER: io.element.elementx
PRODUCT_NAME: Element X
DEVELOPMENT_TEAM: ABCDE12345
APP_GROUP_IDENTIFIER: group.io.element.elementx

# TO:
PRODUCT_BUNDLE_IDENTIFIER: com.<customer>.<appname>
PRODUCT_NAME: <CustomerAppName>
DEVELOPMENT_TEAM: <your-team-id>
APP_GROUP_IDENTIFIER: group.com.<customer>.<appname>
```

### 8.2 Modify NSE `target.yml`

Update the NSE (Notification Service Extension) target:
```yaml
PRODUCT_BUNDLE_IDENTIFIER: com.<customer>.<appname>.nse
```

### 8.3 Modify Other Extension `target.yml` Files

If there are additional extensions (Share Extension, Widget, etc.), update each one.

### 8.4 Update Entitlements

For each `.entitlements` file, update:
- `com.apple.security.application-groups` → new App Group ID
- `keychain-access-groups` → new bundle ID prefix + group
- `com.apple.developer.associated-domains` → will be set in Step 11 (OIDC)

### 8.5 Regenerate and Build

```bash
xcodegen generate
# Open in Xcode, let SPM re-resolve if needed
# Build (Cmd+B)
```

**Expected:** Build succeeds with new bundle ID. Signing may require selecting the correct team in Xcode.

### 8.6 Run on Simulator

Verify the app runs with the new identity. It should appear with the old icon but new bundle ID on the simulator home screen.

> **Claude verification:** Run `grep -r "io.element" . --include="*.yml" --include="*.entitlements" --include="*.plist"` — should return zero results (all replaced).

**Git checkpoint: `checkpoint/identity-changed`**

---

## 9. Step 7: Branding — App Icon & Colors

### 9.1 Replace App Icon

**Input required:** Customer's icon as 1024×1024 PNG, no alpha channel, no rounded corners.

**Generate all required sizes** using a tool or script:
```
Sizes needed (points × scales):
20×20 @1x, @2x, @3x
29×29 @1x, @2x, @3x
40×40 @1x, @2x, @3x
60×60 @2x, @3x
76×76 @1x, @2x (iPad)
83.5×83.5 @2x (iPad Pro)
1024×1024 @1x (App Store)
```

Replace all images in `Assets.xcassets/AppIcon.appiconset/`.

Update `Contents.json` if filenames changed.

> **Claude task:** Read the existing `Contents.json` in the AppIcon asset catalog. Generate a script or listing that maps each required size to the correct filename and scale factor.

### 9.2 Update Accent Color

Locate the accent color definition:
- `Assets.xcassets/AccentColor.colorset/Contents.json`
- And/or Compound design token files

**Compound tokens:** Search for where the primary/accent color is defined. This may be in:
- A Swift file defining color constants
- An asset catalog color set
- A design token configuration file

> **Claude task:** Trace how the accent color flows through the app. Start from the asset catalog or Compound token definition and follow it to where it's used in views. Identify every location where the accent color hex value appears.

Update the hex value to the customer's accent color. Verify both light and dark mode variants.

### 9.3 Build and Visual Verify

After icon and color changes:
1. Build and run on simulator
2. Check home screen — new icon should appear
3. Navigate through the app — accent color should be consistent
4. Toggle dark mode in simulator (Shift+Cmd+A) — verify colors work in both modes

**Git checkpoint: `checkpoint/icon-and-colors`**

---

## 10. Step 8: Branding — Strings, Launch Screen & Element Removal

### 10.1 Update Launch Screen

Locate the launch screen configuration:
- `LaunchScreen.storyboard` or `LaunchScreen.xib` (if UIKit-based)
- Or SwiftUI-based launch screen in `Info.plist` configuration

Replace any Element logos or text with customer branding or a neutral design (icon on solid background of accent color).

### 10.2 Remove Element-Specific Strings

Based on the audit from Step 4, replace or remove all user-facing Element branding:

**Typical locations:**
- About screen / Settings → app name, version description
- Login screen → "Welcome to Element" → "Welcome to <AppName>"
- Legal URLs → privacy policy, terms of service, copyright notices
- Error messages mentioning Element
- Placeholder text mentioning Element

> **Claude task:** Grep the entire codebase for user-visible strings containing "Element". For each match, categorize:
> - REPLACE: User-visible branding → change to customer name
> - REMOVE: Element-specific feature references not applicable
> - KEEP: Internal/technical references (import names, SDK identifiers)

### 10.3 Disable/Remove Analytics

Element X uses **PostHog** for analytics and possibly **Sentry** for crash reporting.

**Actions:**
1. Find analytics initialization code (likely in `AppCoordinator` or `AppDelegate`)
2. Remove or disable PostHog API key
3. Remove or disable Sentry DSN
4. Remove or disable any MapTiler API key
5. Search for: `posthog`, `sentry`, `maptiler`, `analytics` in the codebase
6. Either remove the SDK dependencies entirely OR set empty/disabled configuration

> **Claude task:** Trace the analytics initialization flow. Find every third-party service API key and its location. List them all with recommended action (remove/disable/replace).

### 10.4 Update Legal URLs

In `AppSettings.swift` (or wherever these are defined):

| Setting | Change to |
|---------|-----------|
| Privacy policy URL | Customer's privacy policy URL |
| Terms of service URL | Customer's terms URL |
| Copyright notice | Customer's copyright |
| Support/feedback URL | Customer's support URL |

### 10.5 Branding Audit

> **Claude task:** Final branding audit. Search the ENTIRE codebase for any remaining references to:
> - "Element" (case-insensitive, excluding code identifiers like import statements)
> - "element.io"
> - "element-hq"
> - PostHog/Sentry/MapTiler API keys (should be empty or removed)

Any user-visible results = must fix before proceeding.

**Git checkpoint: `checkpoint/branding-complete`** — Tag this. This is the "branding done" milestone.

---

## 11. Step 9: Localization

### 11.1 Understand the Localization Structure

Element X iOS supports **37+ locales**. Localization files are typically:

```
<locale>.lproj/
├── InfoPlist.strings      ← App display name (CFBundleDisplayName)
├── Localizable.strings    ← General app strings
└── Localizable.stringsdict ← Pluralization rules
```

### 11.2 Update `InfoPlist.strings` Across All Locales

The `CFBundleDisplayName` key defines the app name shown under the icon and in iOS Settings. This must be updated in **every locale**.

> **Claude task:** Find every `InfoPlist.strings` file in the project. For each one, replace the value of `CFBundleDisplayName` with the customer's app name. Generate the complete list of files and the exact replacement for each.

**Example:**
```
// Before (in each .lproj/InfoPlist.strings):
"CFBundleDisplayName" = "Element X";

// After:
"CFBundleDisplayName" = "<CustomerAppName>";
```

**Important:** The app name should be the SAME across all locales unless the customer specifically wants localized names (e.g., different script for Arabic, Chinese, etc.).

### 11.3 Audit Localizable.strings for Element Branding

Some `Localizable.strings` entries may contain "Element" in the translation:

> **Claude task:** Search all `Localizable.strings` files for the word "Element" (case-sensitive, as a word, not substring). List every match with its file, key, and current value. These may need replacement or removal.

**Decision per string:**
- If it's a generic reference to "the app" → replace with customer's app name
- If it's an Element-specific feature or legal text → replace or remove
- If it's a Matrix protocol reference → keep as-is

### 11.4 String Catalog (.xcstrings) — Check for Modern Format

Newer Xcode projects may use **String Catalogs** (`.xcstrings` files) instead of `.strings` files.

> **Claude task:** Check if the project uses `.xcstrings` format. If so, the editing approach differs — String Catalogs are JSON-based files where all translations are in a single file per target.

### 11.5 Verify Localization

1. Build and run on simulator
2. Change simulator language (Settings → General → Language) to a non-English locale
3. Verify the app name under the icon is correct
4. Verify no "Element" branding appears in the UI

**Git checkpoint: `checkpoint/localization-complete`**

---

## 12. Step 10: Configuration

### 12.1 Server Configuration (`AppSettings.swift`)

This is the core configuration file. Update all server-related values:

| Setting | Current (Element) | Change to |
|---------|-------------------|-----------|
| Default homeserver URL | `matrix.org` or `element.io` | Customer's homeserver URL |
| Push gateway endpoint (`pushGatewayNotifyEndpoint`) | Element's Sygnal URL | Customer's Sygnal URL |
| Pusher app ID (`pusherAppID`) | Element's identifier | New identifier (e.g., `com.<customer>.<appname>`) |
| Element Call base URL | Element's deployment | Customer's Element Call URL (or disable) |

### 12.2 Disable/Replace Analytics

If not already done in Step 8:

| Service | Setting | Action |
|---------|---------|--------|
| PostHog | API key, host | Remove or set to empty string |
| Sentry | DSN | Remove or set to empty string |
| MapTiler | API key | Remove or set to empty string |
| BugReport (Rageshake) | Endpoint URL | Update to customer's or disable |

### 12.3 Feature Flags

Review all feature flags in `AppSettings.swift`:

> **Claude task:** List every feature flag with its current default value and description. Flag any that are Element-specific (e.g., Element-branded features, beta features tied to Element's infrastructure).

**Likely candidates to disable:**
- Element-specific integrations
- Beta features not ready for production
- Analytics opt-in prompts (if analytics removed)
- Features requiring Element's backend services

### 12.4 Well-Known Configuration

If the app supports `.well-known/matrix/client` auto-discovery, verify it works with the customer's domain. The app should resolve the homeserver from the domain automatically.

### 12.5 Build and Verify

After all configuration changes:
1. Build and run
2. Verify the login screen shows the correct default server
3. Verify no analytics calls are made (check Console.app or network traffic)

**Git checkpoint: `checkpoint/configuration-complete`**

---

## 13. Step 11: OIDC & Associated Domains

### 13.1 Understand the OIDC Flow

Element X iOS uses OIDC for authentication:
```
App → Opens browser/ASWebAuthenticationSession → Customer's OIDC provider
    → User authenticates
    → Provider redirects to app via redirect URI
    → App receives auth code → exchanges for tokens
```

### 13.2 Update OIDC Configuration

Locate OIDC settings (likely in `AppSettings.swift` or a dedicated OIDC configuration file):

| Setting | Change to |
|---------|-----------|
| OIDC Client ID | Customer's registered client ID |
| OIDC Redirect URI | `<bundle-id>://callback` or as specified by customer's OIDC provider |
| OIDC Issuer URL | Customer's OIDC provider URL |

### 13.3 Configure Associated Domains

Associated Domains are required for universal links (OIDC redirect handling).

In the main app's entitlements:
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:<customer-domain></string>
    <string>webcredentials:<customer-domain></string>
</array>
```

Update in `target.yml` (the XcodeGen config) — NOT directly in `.entitlements` (would be overwritten).

### 13.4 Customer-Side Requirements

The customer must:
1. Register our app as an OIDC client on their provider (Keycloak, etc.)
2. Set our redirect URI in the allowed redirect URIs
3. Host an `apple-app-site-association` file at `https://<customer-domain>/.well-known/apple-app-site-association`

> **Claude task:** Generate the `apple-app-site-association` JSON file content based on the project's bundle ID and the features that need universal links.

### 13.5 OIDC Cannot Be Tested Without Server

OIDC configuration changes can be made now, but **testing requires the customer's server**. Mark this as ready-to-test and move on.

**Git checkpoint: `checkpoint/oidc-configured`**

---

## 14. Step 12: Push Notification Plumbing

### 14.1 Verify Push Architecture

Element X uses APNs directly. Verify:
- Push Notifications capability is enabled for both main app and NSE targets
- App Group is configured for data sharing between main app and NSE
- `pushGatewayNotifyEndpoint` points to customer's Sygnal
- `pusherAppID` is updated

### 14.2 NSE Configuration

The Notification Service Extension:
- Must share the App Group with the main app
- Needs access to the user's session to decrypt messages
- Must have its own bundle ID (`<main-bundle-id>.nse`)
- Must have its own provisioning profile

> **Claude task:** Verify the NSE target configuration:
> - Bundle ID matches pattern `<main-bundle-id>.nse`
> - App Group matches main app
> - Entitlements include `aps-environment`
> - `NotificationServiceExtension.swift` doesn't have hardcoded Element-specific values

### 14.3 APNs Key Generation

This happens in Apple Developer Portal (Step 5):
1. Create APNs Authentication Key (`.p8` file)
2. Record: Key ID, Team ID
3. This key + bundle ID is shared with customer for Sygnal configuration

### 14.4 Push Cannot Be Tested Without Server

Like OIDC, push configuration can be set up now but testing requires:
- Customer's Sygnal is running and configured with our APNs key
- A physical device (push doesn't work on simulator)

**Git checkpoint: `checkpoint/push-configured`**

---

## 15. Step 13: Calls Configuration

### 15.1 Element Call Configuration

If the customer has LiveKit + Element Call infrastructure:

| Setting | Change to |
|---------|-----------|
| Element Call base URL | Customer's Element Call deployment URL |
| LiveKit SFU URL (if separately configurable) | Customer's LiveKit server |

### 15.2 If No Calls Infrastructure

If the customer cannot provide LiveKit/Element Call:

> **Claude task:** Find the UI entry points for calls (voice call button, video call button in chat). Determine if there's a feature flag or configuration option to hide/disable calls UI without modifying view code. If not, identify the minimum change needed to hide call buttons.

### 15.3 Calls Cannot Be Tested Without Server + Physical Devices

Calls require:
- Customer's LiveKit SFU running
- Customer's TURN/STUN servers
- Two physical devices on the same homeserver
- Camera and microphone permissions

**Git checkpoint: `checkpoint/calls-configured`**

---

## 16. Step 14: Full Build Verification & Audit

### 16.1 Clean Build

```bash
# Remove derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/<project>*

# Regenerate project
xcodegen generate

# Build from clean state
xcodebuild -scheme <AppScheme> -destination 'platform=iOS Simulator,name=iPhone 15 Pro' clean build
```

### 16.2 All-Targets Build Verification

| Target | Builds? | Notes |
|--------|---------|-------|
| Main app | ⬜ | |
| NSE | ⬜ | |
| Unit tests (if applicable) | ⬜ | |

### 16.3 Final Branding Audit

> **Claude task:** Run the complete branding audit one final time:
>
> 1. `grep -ri "element" . --include="*.swift" --include="*.strings" --include="*.yml" --include="*.plist" --include="*.json"` — review every match
> 2. `grep -ri "element.io" .` — must return zero user-facing results
> 3. `grep -ri "posthog\|sentry\|maptiler" . --include="*.swift"` — analytics removed
> 4. Verify bundle ID in built `.app`: `defaults read <path-to-built-app>/Info.plist CFBundleIdentifier`
> 5. Verify display name: `defaults read <path-to-built-app>/Info.plist CFBundleDisplayName`

### 16.4 Simulator Walkthrough

Navigate through every major screen on the simulator:
1. Launch screen → correct branding
2. Login/welcome screen → correct app name, no Element references
3. Settings → about → correct app name, version, legal URLs
4. Any Element-branded illustrations or images

### 16.5 Build for Physical Device (if available)

If a physical device and signing are configured:
1. Build and install on device
2. Verify icon on home screen
3. Verify app name under icon
4. Verify push notification permission prompt appears (even if push won't work yet)

**Git checkpoint: `checkpoint/init-complete`** — **This is the project initialization milestone.** Tag with version `0.1.0-setup`.

---

## 17. Step 15: Git Checkpoints & Branching Strategy

### 17.1 Branch Structure

```
main                    ← Production-ready state. Tagged releases only.
├── develop             ← Active development branch. All work goes here.
│   ├── feature/branding      ← (already merged by this point)
│   ├── feature/oidc-config   ← (already merged by this point)
│   └── feature/server-integration  ← Next phase work
└── upstream/main       ← Tracks original Element X repo (for future merges)
```

### 17.2 Git Checkpoint Summary

| Checkpoint | Tag | Description |
|-----------|-----|-------------|
| 1 | `checkpoint/unmodified-build` | Clean upstream, builds successfully |
| 2 | `checkpoint/identity-changed` | New bundle ID, team, app group |
| 3 | `checkpoint/icon-and-colors` | Customer icon and accent color |
| 4 | `checkpoint/branding-complete` | All Element branding removed |
| 5 | `checkpoint/localization-complete` | All 37+ locales updated |
| 6 | `checkpoint/configuration-complete` | Server URLs, analytics disabled, flags set |
| 7 | `checkpoint/oidc-configured` | OIDC client settings in place |
| 8 | `checkpoint/push-configured` | Push notification plumbing done |
| 9 | `checkpoint/calls-configured` | Element Call URLs or calls disabled |
| 10 | `checkpoint/init-complete` | **Full initialization done.** Ready for server integration. |

### 17.3 Commit Message Convention

```
[phase] Brief description

- Detail 1
- Detail 2

Files changed: list key files
```

Example:
```
[branding] Replace app icon and accent color

- Replaced AppIcon assets with customer icon (all sizes)
- Updated AccentColor to #3366FF in asset catalog
- Verified light and dark mode color rendering

Files: Assets.xcassets/AppIcon.appiconset/*, Assets.xcassets/AccentColor.colorset/*
```

---

## 18. Claude-Specific Workflow Notes

### 18.1 Using Claude Code with This Project

Claude Code can directly:
- Read and edit all project files (Swift, YAML, JSON, strings, entitlements)
- Run `xcodegen generate` and `xcodebuild` commands
- Search the entire 68K LOC codebase instantly
- Generate repetitive changes (37 locale files) in one pass
- Audit for missed branding references

Claude Code **cannot** directly:
- Interact with Xcode GUI (use developer for this)
- Interact with Apple Developer Portal (use developer)
- Test on physical devices
- See the running app's UI (developer describes or shares screenshots)

### 18.2 Optimal Task Delegation

| Task | Who does it | Why |
|------|------------|-----|
| Codebase search and audit | Claude | Faster, more thorough than manual grep |
| Bulk string replacement (37 locales) | Claude | One-pass, zero typos |
| YAML/JSON configuration edits | Claude | Exact syntax, consistent formatting |
| Entitlements verification | Claude | Cross-references multiple files |
| Icon size generation commands | Claude | Generates exact `sips` or ImageMagick commands |
| XcodeGen regeneration | Claude (Bash) | Runs command, verifies output |
| Build verification | Claude (Bash) | Runs `xcodebuild`, parses output |
| Signing configuration | Developer (Xcode) | Requires GUI interaction |
| Provisioning in Apple Portal | Developer (browser) | Web portal, no API |
| Visual QA on simulator | Developer | Requires seeing the screen |
| Physical device testing | Developer | Requires physical hardware |

### 18.3 AI-Powered Audit Patterns

Run these at each checkpoint:

**Branding audit:**
```bash
# Find all remaining Element references (exclude .git, build artifacts, SPM caches)
grep -ri "element" --include="*.swift" --include="*.strings" --include="*.yml" --include="*.plist" --include="*.json" --include="*.entitlements" . | grep -v ".build/" | grep -v "SourcePackages/" | grep -v ".git/"
```

**Bundle ID consistency check:**
```bash
# All bundle ID references should use the new ID
grep -r "io\.element" --include="*.yml" --include="*.entitlements" --include="*.plist" .
# Expected: zero results
```

**Analytics removal verification:**
```bash
grep -ri "posthog\|sentry\|maptiler" --include="*.swift" . | grep -v "SourcePackages/"
# Expected: zero results (or only in disabled/commented code)
```

**Localization completeness check:**
```bash
# Count InfoPlist.strings files with the new app name
grep -rl "CFBundleDisplayName.*<CustomerAppName>" --include="InfoPlist.strings" . | wc -l
# Should equal total number of locales
```

### 18.4 When to Ask the Developer for Help

Claude should flag and ask the developer when:
- A file's purpose or modification impact is unclear
- A build error suggests an environment issue (not a code issue)
- Visual verification is needed (screenshots, UI appearance)
- Apple Developer Portal interaction is required
- A decision from `decisions_tracker.md` is still unresolved and blocks progress
- Signing/provisioning issues occur (often require Xcode GUI)

---

*This document covers the complete initial setup from fork to first branded build. After completing all 15 steps, the project is ready for server integration testing (Phase 4 of the implementation plan).*

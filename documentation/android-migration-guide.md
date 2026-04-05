# Android Migration Guide: UCMeet.Chat

Comprehensive guide for creating the Android version of UCMeet.Chat, based on the iOS fork experience.

**Prepared:** 2026-03-31
**Author:** Developer (AI-assisted)
**Audience:** Android developer(s) taking over the Android fork

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Base Repository Decision](#2-base-repository-decision)
3. [Architecture & Build System](#3-architecture--build-system)
4. [iOS → Android Change Map](#4-ios--android-change-map)
5. [Phase Plan](#5-phase-plan)
6. [Detailed Configuration Reference](#6-detailed-configuration-reference)
7. [Push Notifications](#7-push-notifications)
8. [OIDC / Authentication](#8-oidc--authentication)
9. [Calls (Element Call / UCMeet Call)](#9-calls-element-call--ucmeet-call)
10. [Branding & Colors](#10-branding--colors)
11. [Localization](#11-localization)
12. [Analytics & Telemetry](#12-analytics--telemetry)
13. [Google Play Publication](#13-google-play-publication)
14. [Testing Strategy](#14-testing-strategy)
15. [Lessons Learned from iOS](#15-lessons-learned-from-ios)
16. [Risk Assessment](#16-risk-assessment)
17. [Appendix: File Reference](#17-appendix-file-reference)

---

## 1. Project Overview

### Goal

Create a branded Android fork of an Element X-based Matrix messenger, published as **UCMeet.Chat** on Google Play (and optionally F-Droid).

### What Was Done on iOS

The iOS app is a fork of `element-hq/element-x-ios` with:
- Full rebrand (icons, colors, strings, bundle ID)
- Server reconfiguration (homeserver, OIDC, push gateway, calls)
- Push notifications via direct APNs through Sygnal
- 47 Compound design token color overrides (green → navy blue #003B5D)
- Localization trimmed to 3 locales (en, en-US, ru)
- Analytics/telemetry fully disabled
- 60 commits ahead, 0 behind upstream. ~96 hours invested.

### Customer Infrastructure

| Service | URL | Notes |
|---------|-----|-------|
| Homeserver | `matrix.ucmeet.org` | Synapse (currently v1.149.1, upgrading to 1.150.0+) |
| Push Gateway | `https://push.ucmeet.org` | Sygnal |
| Element Call | `call.ucmeet.org` | LiveKit-based |
| OIDC (MAS) | Hosted on `ucmeet.org` | MAS with DCR support |
| Website | `https://www.ucmeet.info` | Privacy policy, ToS, support |
| Permalink redirect | `ucmatrix.org` | Post-launch (replaces matrix.to, which is banned in Russia) |

---

## 2. Base Repository Decision

There are three viable options. The customer suggested SchildiChat, but Element X Android is the direct parallel to our iOS fork and deserves equal consideration.

### Option A: Element X Android (Direct Fork)

**Repository:** https://github.com/element-hq/element-x-android
**SDK:** Official `org.matrix.rustcomponents:sdk-android` on Maven Central (AGPL v3)
**License:** AGPL v3 (app + SDK)

| Advantage | Detail |
|-----------|--------|
| **Direct upstream** | Single merge layer — you fork canonical source, merge directly. Simplest maintenance |
| **Official SDK on Maven Central** | No custom SDK builds, no third-party Maven repos. `implementation("org.matrix.rustcomponents:sdk-android:26.03.24")` just works |
| **Symmetry with iOS** | Same upstream org (`element-hq`) as our iOS fork — consistent architecture, same release cadence, same SDK versions |
| **Larger dev team** | Element employs 10+ Android engineers — faster releases, quicker bug fixes, better maintained |
| **Enterprise build infrastructure** | Built-in `enterprise/` submodule variant — may be useful if customer wants managed deployment |
| **Simpler build flavors** | 2 dimensions (`store` × `build type`) vs SchildiChat's 3 |
| **Easier onboarding** | Any Android developer familiar with Element X can contribute immediately |

| Disadvantage | Detail |
|--------------|--------|
| **AGPL v3 throughout** | Both app AND Rust SDK are AGPL — same legal situation as our iOS fork. Written AGPL confirmation still needed |
| **Firebase is default push** | Requires Google Play Services. Can add UnifiedPush but it's extra work |
| **Analytics enabled** | Must disable PostHog, Sentry, rageshake (same as we did on iOS — ~2h work) |
| **No spaces yet** | Space navigation not implemented in Element X (upstream roadmap item) |
| **No URL previews** | Link previews in timeline not available |

**Estimated fork effort:** ~90–100h (closest to iOS experience, well-understood path)

### Option B: SchildiChat Android Next (Fork-of-a-Fork)

**Repository:** https://github.com/SchildiChat/schildichat-android-next
**SDK:** https://github.com/SchildiChat/matrix-rust-sdk (**Apache 2.0**)
**License:** App is AGPL v3, but SDK is Apache 2.0

| Advantage | Detail |
|-----------|--------|
| **Apache 2.0 SDK** | The Rust SDK layer is Apache 2.0, not AGPL — significant legal simplification for the core binary |
| **No Google Play Services dependency** | Uses FOSS FCM distributor via UnifiedPush — works on Huawei and degoogled devices (important for Russian market) |
| **Analytics pre-disabled** | PostHog, Sentry already stripped — less work |
| **Space navigation** | Full hierarchical space support — feature not yet in Element X |
| **Richer features for free** | URL previews, bubble colors, custom room sorting, bigger stickers, freeform reactions |
| **Proven fork methodology** | Mature merge scripts (`pre_merge.sh`, `fix_merge.sh`) for upstream sync |
| **Russian translations** | Already includes `ru` in SC-specific strings |

| Disadvantage | Detail |
|--------------|--------|
| **Fork-of-a-fork** | You sync with SC → SC syncs with Element X. Double merge dependency. If SC falls behind or abandons, you're stuck |
| **Custom Rust SDK** | Must use SC's Maven repo (`maven.spiritcroc.de`) or build SDK from their Rust fork. Not on Maven Central |
| **Single maintainer (SpiritCroc)** | Bus factor = 1. If maintainer stops, SDK and merge scripts stop too |
| **Deeper SC branding** | `chat.schildi.*` throughout flavors, preferences, tests — more renaming than Element X |
| **More complex build system** | 3 flavor dimensions, custom Gradle plugins, SC-specific module structure |
| **App code still AGPL** | Only the SDK is Apache 2.0. The app layer is still AGPL v3 |
| **Less stable release cadence** | SC releases follow one developer's schedule, not a company's |

**Estimated fork effort:** ~100–120h (more renaming, more complex build system, but less analytics stripping)

### Option C: Hybrid Approach

Fork **Element X Android** but swap in **SchildiChat's Apache 2.0 Rust SDK**:
- Best of both: clean single-fork merge path + permissive SDK license
- Risk: SC's SDK may diverge from Element X's expected API surface — potential incompatibilities
- Extra work: ~5–10h to configure Maven dependency + verify compatibility
- Not tested by anyone — you'd be the first to try this combination

### Comparison Matrix

| Factor | Element X Android | SchildiChat | Winner |
|--------|------------------|-------------|--------|
| **Legal simplicity** | AGPL everywhere | SDK is Apache 2.0 | **SchildiChat** |
| **Maintenance simplicity** | Single fork layer | Fork-of-a-fork | **Element X** |
| **SDK reliability** | Official Maven Central | Third-party Maven | **Element X** |
| **Push without Google** | Needs extra work | Built-in | **SchildiChat** |
| **iOS fork symmetry** | Same upstream org | Different org | **Element X** |
| **Feature richness** | Standard | Spaces, URL previews, etc. | **SchildiChat** |
| **Bus factor** | Element team (10+) | SpiritCroc (1) | **Element X** |
| **Build system complexity** | Moderate | High (3 flavor dims) | **Element X** |
| **Upstream merge effort** | Low (direct) | Medium (double layer) | **Element X** |
| **Analytics stripping** | ~2h work | Already done | **SchildiChat** |
| **Russian market fit** | Good | Better (no Google dep) | **SchildiChat** |
| **Estimated effort** | ~90–100h | ~100–120h | **Element X** |

### Recommendation

**The choice depends on the customer's priorities:**

**Choose Element X Android if:**
- Simplicity and long-term maintainability matter most
- Customer is comfortable with AGPL (or plans to open-source / get Element's commercial license)
- Symmetry with iOS fork is valued (same upstream, same patterns, easier for one developer to maintain both)
- Space navigation is not a hard requirement

**Choose SchildiChat if:**
- Apache 2.0 SDK license is a hard requirement (customer won't sign AGPL confirmation)
- App must work without Google Play Services (significant Huawei/degoogled device user base)
- Space navigation and extra features are valued
- Customer accepts the single-maintainer dependency risk

**Our take:** For a branded fork with minimal customization (which is what we're doing), **Element X Android is the lower-risk, lower-effort choice** — it's a direct parallel to our iOS fork, simpler to maintain, and the AGPL situation is manageable (same as iOS). However, if the customer specifically wants the Apache 2.0 SDK advantage, SchildiChat is a reasonable choice with the caveats noted above.

**The customer should make this decision explicitly.** We recommend presenting both options with the trade-offs.

---

## 3. Architecture & Build System

### Technology Stack

| Component | Technology |
|-----------|-----------|
| Language | Kotlin |
| UI | Jetpack Compose |
| Architecture | Coordinator-based MVVM with Molecule presenters |
| Navigation | Appyx |
| DI | Metro (replaced Dagger) |
| Core SDK | Matrix Rust SDK (FFI, opaque binary) |
| Build system | Gradle (Kotlin DSL) with version catalog |
| Min SDK | 24 (Android 7.0) for FOSS builds |
| Target SDK | 36 (Android 16) |

### Project Structure

```
schildichat-android-next/
├── app/                        # Main application module
│   ├── build.gradle.kts        # App ID, versions, flavors, signing
│   ├── src/main/               # Main source + AndroidManifest.xml
│   ├── src/sc/                  # SC flavor overrides (icons, resources)
│   └── src/debug/              # Debug-only resources
├── appconfig/                  # Configuration constants (★ KEY for rebrand)
│   └── src/main/kotlin/.../
│       ├── ApplicationConfig.kt
│       ├── PushConfig.kt
│       ├── RageshakeConfig.kt
│       ├── NotificationConfig.kt
│       └── MatrixConfiguration.kt
├── appicon/                    # App icon resources
├── appnav/                     # Navigation graph
├── features/                   # ~45 feature modules (api/impl/test each)
│   ├── call/                   # Element Call integration
│   ├── login/                  # OIDC + password auth
│   ├── messages/               # Room timeline
│   └── ...
├── libraries/                  # ~45 library modules
│   ├── matrix/                 # SDK wrapper
│   ├── push/                   # Push abstraction
│   ├── pushproviders/          # Firebase / UnifiedPush implementations
│   ├── designsystem/           # Compound design system
│   └── ...
├── plugins/                    # Build plugins (★ KEY for rebrand)
│   └── src/main/kotlin/
│       ├── config/BuildTimeConfig.kt  # Central branding config
│       ├── Versions.kt                # Version codes
│       └── ModulesConfig.kt           # Push provider selection
├── schildi/                    # SC-specific modules
│   ├── theme/                  # Color schemes (ScLight, ScDark, ScBlack)
│   ├── lib/                    # SC preferences, strings, utilities
│   ├── components/             # SC UI composables
│   ├── matrixsdk/              # SDK extensions (spaces, URL previews)
│   └── matrixcore/             # Bridge events, timeline filters
├── sc_tools/                   # Scripts for SDK builds + upstream merges
├── settings.gradle.kts         # Module declarations, Maven repos
└── gradle/libs.versions.toml   # Version catalog
```

### Build Commands

```bash
# Debug build (F-Droid flavor, SC package, default variant)
./gradlew assembleFdroidScDefaultDebug

# Release build
./gradlew assembleFdroidScDefaultRelease

# Run unit tests
./gradlew test

# Code formatting
./gradlew ktlintFormat

# List all tasks
./gradlew tasks --group=build
```

### Build Flavors (SchildiChat)

| Dimension | Values | Purpose |
|-----------|--------|---------|
| `store` | `fdroid` (only, `gplay` disabled) | Distribution channel |
| `package` | `sc` (always) | Overrides Element defaults |
| `sc-variant` | `default`, `beta`, `internal` | Different app IDs/names |

For UCMeet.Chat, you'll likely simplify to a single variant or rename the existing `default` variant.

---

## 4. iOS → Android Change Map

This maps every category of change made in the iOS fork to its Android equivalent.

### 4.1 Identity / Bundle Configuration

| iOS Setting | iOS File | Android Equivalent | Android File |
|-------------|----------|-------------------|--------------|
| Bundle ID `org.ucmeet.UCMeetChat` | `app.yml` | `applicationId` | `app/build.gradle.kts` |
| Display Name `UCMeet.Chat` | `app.yml` → `APP_DISPLAY_NAME` | `resValue("string", "sc_app_name", ...)` | `app/build.gradle.kts` + `ApplicationConfig.kt` |
| App Group `group.org.ucmeet` | `app.yml` | N/A (Android uses shared process) | — |
| Team ID `6HRG779SDK` | `app.yml` | Signing config | `app/build.gradle.kts` (signingConfigs block) |
| Version `1.0.0` Build `5` | `project.yml` | `versionName` / `versionCode` | `app/build.gradle.kts` or `Versions.kt` |
| Background Task ID | `AppSettings.swift` | N/A (Android uses WorkManager job IDs) | — |

### 4.2 Server Configuration

| iOS Setting | iOS File | Android Equivalent | Android File |
|-------------|----------|-------------------|--------------|
| Homeserver `matrix.ucmeet.org` | `AppSettings.swift` → `accountProviders` | Default server | `appconfig/ApplicationConfig.kt` or `BuildTimeConfig.kt` |
| Push Gateway `push.ucmeet.org` | `AppSettings.swift` → `pushGatewayBaseURL` | Push gateway URL | Server-side (`.well-known`) or `PushConfig.kt` |
| OIDC redirect `org.ucmeet.UCMeetChat:/callback` | `AppSettings.swift` | `login_redirect_scheme` | `app/build.gradle.kts` (resValue) + `BuildTimeConfig.kt` |
| OIDC client metadata URLs | `AppSettings.swift` | OIDC config | `BuildTimeConfig.kt` + `OidcConfig.kt` |
| Legal URLs (privacy, ToS, support) | `AppSettings.swift` | Build-time URLs | `BuildTimeConfig.kt` |
| Element Call hosts (cleared) | `AppRoutes.swift` | Known hosts | `BuildTimeConfig.kt` or call config |
| Permalink base URL | `AppRoutes.swift` | Matrix permalink config | `MatrixConfiguration.kt` |

### 4.3 Push Notifications

| iOS Approach | Android Equivalent |
|--------------|-------------------|
| Direct APNs token → Sygnal (`type: apns`) | FCM token or UnifiedPush token → Sygnal (`type: gcm` or `type: apns` equivalent) |
| `PushProvider` enum (`.apns` / `.firebase`) | `ModulesConfig.kt` → `PushProvidersConfig` (`includeFirebase` / `includeUnifiedPush`) |
| `GoogleService-Info.plist` | `google-services.json` or `firebase.xml` (SC flavor) |
| Pusher app ID `org.ucmeet.UCMeetChat.ios.prod` | `PushConfig.PUSHER_APP_ID` (e.g. `org.ucmeet.UCMeetChat.android`) |
| NSE (Notification Service Extension) | `FirebaseMessagingService` or UnifiedPush receiver |

### 4.4 Branding (Colors)

| iOS Approach | Android Equivalent |
|--------------|-------------------|
| `CompoundHook.swift` — 47 token overrides | `schildi/theme/` — `ScLight.kt`, `ScDark.kt`, `ScBlack.kt` |
| Navy blue `#003B5D` with 5 tonal variants | Same palette applied to Compose `Color` values |
| `accent-color.colorset` in asset catalog | `@color/accent` in XML resources or Compose theme |
| Gradient overrides (send button, home) | Compose gradient definitions in theme module |

### 4.5 Localization

| iOS Approach | Android Equivalent |
|--------------|-------------------|
| Trimmed from 37 → 3 locales (en, en-US, ru) | Trim `locales.kt` to desired set |
| `.strings` files per locale | `res/values-*/strings.xml` per locale |
| Modified 10 brand-referencing string keys | Override via SC-specific strings in `schildi/lib/res/values*/strings.xml` |
| InfoPlist.strings for permission descriptions | Not applicable (Android uses `<uses-permission>` in manifest) |

### 4.6 Analytics (All Disabled)

| iOS Setting | Android Equivalent |
|-------------|-------------------|
| `sentryDSN: nil` | `SERVICES_SENTRY_DSN = ""` in `BuildTimeConfig.kt` |
| `postHogHost: nil`, `postHogAPIKey: nil` | `SERVICES_POSTHOG_API_HOST = ""`, `SERVICES_POSTHOG_API_KEY = ""` |
| `rageshakeURL: nil` | `RageshakeConfig.kt` → `url = ""` or disable entirely |
| `bugReportApplicationID: "ucmeet-ios"` | `RageshakeConfig.kt` → `applicationId` |

### 4.7 Entitlements / Permissions

| iOS Entitlement | Android Equivalent |
|-----------------|-------------------|
| `aps-environment` | `<uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />` (if using FCM) |
| Associated Domains | `<intent-filter>` with `android:autoVerify="true"` + `assetlinks.json` on server |
| App Groups | Not needed (single-process shared preferences) |
| Keychain Access | Android Keystore API |
| `ITSAppUsesNonExemptEncryption` | Google Play export compliance declaration |

### 4.8 Calls

| iOS Setting | Android Equivalent |
|-------------|-------------------|
| URL scheme `org.ucmeet.call` | Intent filter in `AndroidManifest.xml` |
| `knownHosts: []` (cleared) | Call host configuration (similar clearing) |
| Element Call PostHog/Sentry (emptied) | `BuildTimeConfig.kt` call analytics fields |

### 4.9 Dispatch Queue Labels / Internal IDs

| iOS | Android |
|-----|---------|
| 11 files with `io.element.elementx.*` queue labels | Not directly applicable — Android uses thread names, less tied to bundle ID |
| Background task ID in AppSettings | WorkManager uses class-based unique work names |

---

## 5. Phase Plan

Based on iOS experience (~96h), estimated Android effort: **80–110 hours** (AI-assisted). Android benefits from the iOS playbook but has its own complexity (Gradle multi-module, signing, Play Store).

### Phase 1: Environment Setup & Fork (Days 1–5, ~12h)

**Goal:** Working debug build on emulator/device.

| Task | Details | Est. |
|------|---------|------|
| Fork SchildiChat repo | Create private repo, set up remotes | 1h |
| Understand build system | Study `build.gradle.kts`, `settings.gradle.kts`, flavor system | 2h |
| Set up development environment | Android Studio, SDK 36, Kotlin 2.x | 1h |
| Build and run SC unmodified | Verify `assembleFdroidScDefaultDebug` succeeds | 2h |
| Configure signing | Debug keystore, prepare release keystore | 1h |
| Connect to `matrix.ucmeet.org` | Change default homeserver, verify login | 2h |
| Verify basic functionality | Send/receive messages, rooms load | 2h |
| Document build steps | Build instructions for team | 1h |

**Deliverable:** Working debug build, successful login to `matrix.ucmeet.org`.

### Phase 2: Identity & Configuration (Days 6–10, ~15h)

**Goal:** All identifiers changed, app is "UCMeet.Chat" internally.

| Task | Details | Est. |
|------|---------|------|
| Application ID | Change to `org.ucmeet.UCMeetChat` in `build.gradle.kts` | 1h |
| Display name | Update `sc_app_name` → `UCMeet.Chat` across flavors | 1h |
| `BuildTimeConfig.kt` | Update all 20+ config values (URLs, names, IDs) | 3h |
| `appconfig/` module | Update `ApplicationConfig`, `PushConfig`, `MatrixConfiguration`, etc. | 2h |
| OIDC configuration | Set redirect scheme, client metadata URLs | 2h |
| `settings.gradle.kts` | Update root project name | 0.5h |
| `AndroidManifest.xml` | Update deep link hosts, intent filters | 2h |
| Version numbering | Set to `1.0.0` (1), establish versioning scheme | 0.5h |
| Audit for remaining SC/Element branding in code | Grep for `schildi`, `element`, `io.element` | 2h |
| Build and verify | Full build, login, basic functionality | 1h |

**Deliverable:** App identifies as `UCMeet.Chat` everywhere, connects to customer servers.

### Phase 3: Branding & Visual Identity (Days 11–16, ~15h)

**Goal:** Full visual rebrand — icons, colors, strings.

| Task | Details | Est. |
|------|---------|------|
| App icons | Replace all densities in `app/src/sc/res/mipmap-*/` | 2h |
| Notification icon | Replace `ic_notification_sc.xml` | 1h |
| SC logo assets | Replace `sc_logo_atom.png` and similar | 1h |
| Color theme — navy blue | Override `ScLight.kt`, `ScDark.kt`, `ScBlack.kt` with #003B5D palette | 4h |
| Notification accent color | Update `NotificationConfig.kt` | 0.5h |
| Compound token overrides | Map iOS 47 token overrides to Android Compose equivalents | 3h |
| String replacements | "SchildiChat" → "UCMeet.Chat" in SC-specific strings | 2h |
| Splash/launch screen | Update if present | 0.5h |
| Visual review | Side-by-side with iOS for consistency | 1h |

**Deliverable:** Visually consistent with iOS version, navy blue theme, UCMeet.Chat branding.

### Phase 4: Localization (Days 17–19, ~8h)

**Goal:** en + ru fully working, unused locales removed.

| Task | Details | Est. |
|------|---------|------|
| Trim locales | Edit `locales.kt` — keep `en`, `ru` (possibly `en-US`) | 1h |
| Review upstream Russian translations | Verify quality of existing `ru` strings | 2h |
| Add/fix Russian translations | Brand-specific strings, permission descriptions | 3h |
| SC-specific Russian strings | Verify `schildi/lib/res/values-ru/strings.xml` | 1h |
| Test locale switching | Verify both languages render correctly | 1h |

**Deliverable:** Full en + ru support, matching iOS translation quality.

### Phase 5: Push Notifications (Days 20–25, ~15h)

**Goal:** Working push notifications via Sygnal.

| Task | Details | Est. |
|------|---------|------|
| Decide push strategy | UnifiedPush (SC default) vs Firebase vs both | 1h |
| Configure push provider | Update `ModulesConfig.kt`, Firebase config if needed | 2h |
| Set pusher app ID | `PushConfig.kt` → match Sygnal config | 1h |
| Create Firebase project (if using FCM) | `google-services.json`, upload server key to Sygnal | 2h |
| Configure Sygnal for Android | Coordinate with customer — `type: gcm` for FCM, or UnifiedPush | 3h |
| Test push E2E | Messages while app backgrounded, terminated | 4h |
| Debug push issues | Based on iOS experience, expect Sygnal config iterations | 2h |

**Deliverable:** Push notifications working on physical device.

**Critical lesson from iOS:** Push debugging consumed ~20h on iOS due to:
- ntfy → Sygnal migration
- FCM v1 payload incompatibility with Sygnal's GCM pushkin
- APNs sandbox vs production environment mismatch

On Android, if using FCM via Sygnal (`type: gcm`), the same payload issue may arise. Test early.

### Phase 6: Calls (Days 26–28, ~6h)

**Goal:** Working voice/video calls via UCMeet Call.

| Task | Details | Est. |
|------|---------|------|
| Configure call URL scheme | Update intent filter for `org.ucmeet.call` | 1h |
| Clear Element Call known hosts | Remove hardcoded `call.element.io` references | 1h |
| Disable call analytics | Empty PostHog/Sentry for Element Call | 0.5h |
| Test 1:1 call | Verify microphone, camera, audio | 1.5h |
| Test group call | Via `call.ucmeet.org` | 1h |
| Test incoming call notification | Verify call notification renders correctly | 1h |

**Note on CallKit (iOS) vs Android:** Android uses a foreground notification for incoming calls (or `ConnectionService` for native dialer integration). Element X Android uses the notification approach. The MSC4075 issue discovered on iOS (Synapse not generating `m.rtc.notification` events) will affect Android equally — this is a server-side fix.

**Deliverable:** Working 1:1 and group calls.

### Phase 7: Analytics Removal & Security Audit (Days 29–31, ~6h)

**Goal:** All telemetry disabled, no data leaks.

| Task | Details | Est. |
|------|---------|------|
| Disable PostHog | Empty all PostHog config values | 0.5h |
| Disable Sentry | Empty all Sentry config values | 0.5h |
| Disable rageshake | Empty URL or disable feature | 0.5h |
| Audit for remaining telemetry | Grep for analytics endpoints, tracking calls | 2h |
| MapTiler configuration | Set customer's API key `iKPA4bK9zgtadTEw8neu` | 0.5h |
| Security audit | Check for hardcoded credentials, exposed endpoints | 2h |

**Deliverable:** Zero telemetry, clean security posture.

### Phase 8: Release Build & Testing (Days 32–38, ~12h)

**Goal:** Release-quality APK/AAB ready for Play Store.

| Task | Details | Est. |
|------|---------|------|
| Release build | `assembleFdroidScDefaultRelease` or equivalent | 1h |
| Signing with release keystore | Configure signing config in Gradle | 1h |
| ProGuard/R8 configuration | Verify minification doesn't break SDK | 2h |
| Full functional test | All features end-to-end on physical device | 3h |
| Performance test | Memory, battery, startup time | 1h |
| Version and metadata | Set final version 1.0.0 | 0.5h |
| Export compliance | Encryption declaration for Play Store | 1h |
| Build handover documentation | Build instructions, signing key management | 2.5h |

**Deliverable:** Signed release AAB/APK.

### Phase 9: Google Play Publication (Days 39–45, ~10h)

**Goal:** App published on Google Play.

| Task | Details | Est. |
|------|---------|------|
| Create Play Console listing | Title, description, screenshots (RU + EN) | 3h |
| Upload AAB | Internal testing track first | 0.5h |
| Content rating questionnaire | IARC rating | 0.5h |
| Privacy policy | Link to `ucmeet.info` privacy policy | 0.5h |
| Data safety section | Declare data collection practices | 1h |
| Internal testing | Verify on multiple devices/API levels | 2h |
| Promote to production | Or open testing first | 0.5h |
| Respond to review | If any issues flagged | 2h |

**Deliverable:** App live on Google Play.

### Total Estimated Effort

| Phase | Hours |
|-------|-------|
| 1. Environment Setup | 12h |
| 2. Identity & Config | 15h |
| 3. Branding & Visual | 15h |
| 4. Localization | 8h |
| 5. Push Notifications | 15h |
| 6. Calls | 6h |
| 7. Analytics & Security | 6h |
| 8. Release Build & Testing | 12h |
| 9. Google Play Publication | 10h |
| **Total** | **~99h** |
| **Buffer (15%)** | **~15h** |
| **Grand Total** | **~114h** |

---

## 6. Detailed Configuration Reference

### `plugins/src/main/kotlin/config/BuildTimeConfig.kt`

This is the **single most important file** for rebranding. All values must be reviewed:

```kotlin
// Current SchildiChat values → UCMeet.Chat values needed

APPLICATION_NAME = "SchildiChat"              → "UCMeet.Chat"
APPLICATION_ID = "chat.schildi.android"       → "org.ucmeet.UCMeetChat"
METADATA_HOST_REVERSED = "de.spiritcroc.riotx"→ "org.ucmeet.UCMeetChat"

// Firebase (if using FCM)
GOOGLE_APP_ID_RELEASE = "..."                 → from customer's google-services.json
GOOGLE_APP_ID_DEBUG = "..."                   → from customer's google-services.json

// URLs
URL_WEBSITE = "..."                           → "https://www.ucmeet.info"
URL_PRIVACY = "..."                           → "https://www.ucmeet.info/privacy"
URL_TERMS = "..."                             → "https://www.ucmeet.info/terms"
URL_SUPPORT = "..."                           → "https://www.ucmeet.info/support"

// Services
SERVICES_MAPTILER_API_KEY = "..."             → "iKPA4bK9zgtadTEw8neu"
SERVICES_POSTHOG_API_HOST = "..."             → "" (disabled)
SERVICES_POSTHOG_API_KEY = "..."              → "" (disabled)
SERVICES_SENTRY_DSN = "..."                   → "" (disabled)
```

### `appconfig/` Module Files

| File | Key Values to Change |
|------|---------------------|
| `ApplicationConfig.kt` | App name strings, default homeserver |
| `PushConfig.kt` | `PUSHER_APP_ID` → `"org.ucmeet.UCMeetChat.android"` |
| `RageshakeConfig.kt` | `url` → `""` (disabled), `applicationId` → `"ucmeet-android"` |
| `NotificationConfig.kt` | Accent color → navy blue `#003B5D` |
| `MatrixConfiguration.kt` | Permalink base URL (post-launch: `ucmatrix.org`) |

### `app/build.gradle.kts`

```kotlin
applicationId = "org.ucmeet.UCMeetChat"    // Package name

// SC variant → rename or simplify
productFlavors {
    create("default") {
        applicationIdSuffix = ""
        resValue("string", "sc_app_name", "UCMeet.Chat")
        resValue("string", "sc_app_name_launcher", "UCMeet.Chat")
    }
}

// Signing (release)
signingConfigs {
    create("release") {
        storeFile = file("path/to/release.keystore")
        storePassword = "..."
        keyAlias = "..."
        keyPassword = "..."
    }
}
```

---

## 7. Push Notifications

### Strategy Decision

The push approach depends on the base repository chosen:

**If using SchildiChat:** UnifiedPush is the default (FOSS FCM distributor). No Google Play Services needed. Can optionally re-enable Firebase.

**If using Element X Android:** Firebase (FCM) is the default. UnifiedPush is available as an alternative. Both can be enabled simultaneously — the app lets the user choose.

**For either base:**
- Create a Firebase project and get `google-services.json` (needed for FCM path)
- Or configure UnifiedPush distributor app on device (e.g., ntfy, UP-FCM)
- Sygnal on the server side handles delivery via `type: gcm` for FCM tokens

### Sygnal Configuration (Customer Side)

For Android, Sygnal needs a separate app config:

```yaml
# sygnal.yaml
apps:
  # iOS (already configured)
  org.ucmeet.UCMeetChat.ios.prod:
    type: apns
    keyfile: /path/to/key.p8
    key_id: XZANH7CD3Z
    team_id: 6HRG779SDK
    topic: org.ucmeet.UCMeetChat

  # Android (NEW — configure for FCM)
  org.ucmeet.UCMeetChat.android:
    type: gcm
    api_version: v1
    project_id: <firebase-project-id>
    service_account_file: /path/to/service-account.json
```

### Pusher App ID

Must match exactly between app and Sygnal config:
- **App:** `PushConfig.PUSHER_APP_ID = "org.ucmeet.UCMeetChat.android"`
- **Sygnal:** App entry key `org.ucmeet.UCMeetChat.android`

### Key Lesson from iOS

The iOS push debugging consumed ~20 extra hours due to:
1. ntfy (customer's initial choice) couldn't handle FCM tokens
2. Sygnal's GCM pushkin put APNs-format payload into FCM `data` field → 400 error
3. Final solution: switched iOS to direct APNs tokens

For Android with FCM via Sygnal, the `type: gcm` pushkin should work correctly because FCM is the native Android push channel. But test early — the customer's Sygnal version and configuration matter.

---

## 8. OIDC / Authentication

### Configuration

The OIDC flow on Android works similarly to iOS:

1. **Redirect scheme:** Set via `login_redirect_scheme` string resource
   - Pattern: `org.ucmeet.UCMeetChat:/` (matches iOS)
   - Set in `app/build.gradle.kts` via `resValue`

2. **Client metadata:** Set in `BuildTimeConfig.kt` or `OidcConfig.kt`
   - `clientName`: `"UCMeet.Chat"`
   - `clientUri`: `"https://www.ucmeet.info"`
   - `logoUri`: `"https://www.ucmeet.info/logo.png"`
   - `tosUri`: `"https://www.ucmeet.info/terms"`
   - `policyUri`: `"https://www.ucmeet.info/privacy"`

3. **Static registration (optional):** Pre-register client ID with MAS
   - Add to `STATIC_REGISTRATIONS` map in `OidcConfig.kt`
   - iOS uses Dynamic Client Registration (DCR) — works but static is more robust

4. **AndroidManifest.xml:** Must have intent filter for OIDC callback:
   ```xml
   <intent-filter>
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data android:scheme="org.ucmeet.UCMeetChat" />
   </intent-filter>
   ```

### iOS Experience

OIDC login worked correctly once the custom URL scheme was configured. MAS on `ucmeet.org` supports DCR. No issues expected on Android if redirect scheme is correctly set.

---

## 9. Calls (Element Call / UCMeet Call)

### Configuration

Calls use MatrixRTC + LiveKit, hosted at `call.ucmeet.org`. Configuration:

1. **URL scheme:** Change intent filter from SC/Element scheme to `org.ucmeet.call`
2. **Known hosts:** Clear any hardcoded `call.element.io` or SC call hosts
3. **LiveKit:** Configured via homeserver's `.well-known` — no app-side changes needed
4. **Call analytics:** Disable PostHog/Sentry for Element Call (empty the config values)

### CallKit Equivalent (Android)

Android doesn't have CallKit. Element X Android uses:
- Foreground notification with full-screen intent for incoming calls
- `ConnectionService` API is available but not used by Element X (or SC)

### MSC4075 Server Issue

The same issue discovered on iOS applies to Android: Synapse must generate `m.rtc.notification` events with `ring` type for incoming call notifications. The customer's Synapse needs to be upgraded to 1.150.0+ with `msc4075_enabled: true` working. This is a **server-side** fix, not app-side.

---

## 10. Branding & Colors

### Navy Blue Palette

From the iOS implementation:

| Token | Hex | Usage |
|-------|-----|-------|
| navy900 | `#003B5D` | Primary accent, icons, text |
| navy800 | `#004A75` | Hovered state |
| navy700 | `#005A8E` | Pressed state |
| navy1000 | `#002D47` | Dark backgrounds |
| navy1100 | `#001F31` | Darkest variant |

### Android Theme Files

In `schildi/theme/`:

```kotlin
// ScLight.kt — modify these values
val scAccentPrimary = Color(0xFF003B5D)      // was SC green
val scAccentHovered = Color(0xFF004A75)
val scAccentPressed = Color(0xFF005A8E)
// ... etc for all token overrides

// ScDark.kt — dark mode equivalents
// ScBlack.kt — AMOLED black theme
```

### Token Override Count

iOS overrides 47 Compound tokens (24 SwiftUI + 23 UIKit). Android should match:
- Accent backgrounds (rest/hovered/pressed/selected)
- Icon colors (accent primary/tertiary)
- Text colors (action accent, badge accent)
- Border colors (accent subtle)
- Badge backgrounds
- Success tokens (all green → navy)
- Send button gradient (4 stops)
- Home screen gradient (5 stops)

### App Icon

Provide icons in all Android densities:
- `mipmap-mdpi/` (48×48)
- `mipmap-hdpi/` (72×72)
- `mipmap-xhdpi/` (96×96)
- `mipmap-xxhdpi/` (144×144)
- `mipmap-xxxhdpi/` (192×192)
- Adaptive icon (foreground + background layers)
- Play Store icon (512×512)

---

## 11. Localization

### Approach

1. **Trim locales:** Edit `plugins/src/main/kotlin/extension/locales.kt` to keep only `en` and `ru`
2. **Upstream strings:** Don't modify Element X base strings directly — override via SC modules
3. **SC-specific strings:** Update `schildi/lib/src/main/res/values/strings.xml` and `values-ru/strings.xml`
4. **Brand strings:** Replace "SchildiChat" → "UCMeet.Chat" in all string resources

### Russian Translation Quality

SchildiChat already includes Russian translations in `schildi/lib`. The upstream Element X strings are also translated to Russian via Localazy. Quality should be reviewed — iOS required 14+ manual Russian translation corrections.

---

## 12. Analytics & Telemetry

Disable everything (matching iOS):

| Service | Config Location | Action |
|---------|----------------|--------|
| PostHog | `BuildTimeConfig.kt` | Set host + key to `""` |
| Sentry | `BuildTimeConfig.kt` | Set DSN to `""` |
| Rageshake | `RageshakeConfig.kt` | Set URL to `""` |
| Element Call PostHog | `BuildTimeConfig.kt` | Set host + key to `""` |
| Element Call Sentry | `BuildTimeConfig.kt` | Set DSN to `""` |

SchildiChat already disables most analytics by default — verify and ensure nothing leaks.

---

## 13. Google Play Publication

### Checklist

| Item | Details | iOS Parallel |
|------|---------|-------------|
| App title | "UCMeet.Chat" | Same |
| Short description | "Мессенджер на протоколе Matrix" | Same as iOS subtitle |
| Full description | RU + EN versions | Same content as iOS |
| Screenshots | Phone + tablet (if supporting) | Customer provides |
| Feature graphic | 1024×500 banner | Not needed on iOS |
| Privacy policy URL | `https://www.ucmeet.info/privacy` | Same |
| Content rating | IARC questionnaire | iOS: 14+ |
| Target audience | 16+ (similar to iOS 14+) | Similar |
| Data safety | Declare encryption, no analytics | iOS: Privacy Nutrition Labels |
| Countries | All (or Russia-focused) | iOS: All countries |
| Signing | Play App Signing (recommended) | iOS: automatic signing |

### Google Play vs App Store Differences

| Aspect | Google Play | App Store |
|--------|------------|-----------|
| Review time | Hours to 1-2 days | 1-7 days |
| AGPL risk | Lower (Google less strict on licenses) | Higher (Apple Guideline 4.3 risk) |
| Encryption compliance | Self-declaration | Document upload + compliance code |
| Screenshots | Min 2, any device | Required 6.7" + 5.5" |
| Privacy | Data Safety section | Privacy Nutrition Labels |
| Beta testing | Internal/Closed/Open tracks | TestFlight |

---

## 14. Testing Strategy

### Minimum Test Matrix

| Test | Method |
|------|--------|
| Build succeeds (debug + release) | CI or local |
| Login via OIDC | Physical device |
| Send/receive messages | Two accounts |
| Push (app background) | Physical device, Sygnal configured |
| Push (app terminated) | Physical device |
| 1:1 call (audio/video) | Two physical devices |
| Group call | Three devices via `call.ucmeet.org` |
| E2EE indicators | Verify encryption badges |
| Russian locale | Switch device language |
| Location sharing | If MapTiler works |
| Media (photo, video, file) | Send + receive |
| Profile management | Name, avatar, device list |
| Logout/re-login | Token cleanup |

### Unit Tests

Both Element X and SchildiChat have extensive test suites. Run `./gradlew test` and ensure no new failures introduced by the fork.

---

## 15. Lessons Learned from iOS

These hard-won insights should save significant time on Android:

### Push Notifications
1. **Test Sygnal configuration EARLY** — it was the #1 time sink on iOS (~20h of debugging)
2. Sygnal's `type: gcm` pushkin may have payload format issues — test with actual message push, not just registration
3. The pusher `app_id` must match EXACTLY between app code and Sygnal config (case-sensitive)
4. Debug builds may use a different push environment — test with release/signed builds
5. After changing push config, users must **re-login** to register new push tokens

### Server-Side Issues
6. **CallKit/incoming calls depend on MSC4075** — Synapse must be 1.150.0+ with `msc4075_enabled: true` actually working (not just configured)
7. The customer's Synapse is currently on 1.149.1 — upgrade is pending
8. **matrix.to is banned in Russia** — permalink redirect to `ucmatrix.org` is a post-launch task

### Branding
9. Color overrides need to cover **both** the design system tokens AND raw color usages
10. Some UI elements have hardcoded colors in upstream code — audit beyond just theme files
11. "Element" appears in many places: strings, URLs, comments, test data — grep thoroughly
12. Copyright headers must NOT be changed (AGPL requirement)

### Build System
13. Never edit generated files directly — always edit the source config
14. iOS: edit YAML → `xcodegen generate`. Android: edit Gradle files → rebuild
15. Keep fork minimal — every extra change increases upstream merge difficulty
16. SchildiChat has merge scripts (`pre_merge.sh`, `fix_merge.sh`) — learn and use them

### Customer Communication
17. Customer is Russian-speaking — all user-facing communication in Russian
18. Customer has limited testing capacity — provide clear step-by-step test instructions
19. Server-side changes (Sygnal, Synapse) require coordination — don't assume they're done

### Legal
20. **AGPL v3 compliance** is required — source code must be available to users
21. If using SchildiChat: SDK is Apache 2.0 — reduces legal risk. If using Element X: same AGPL situation as iOS
22. Still need written license confirmation from customer before publication (regardless of base repo choice)

---

## 16. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Push notification debugging | HIGH | Start testing early (Phase 5), use iOS playbook |
| Sygnal configuration iterations | MEDIUM | Provide customer with exact config from day 1 |
| Synapse MSC4075 for calls | MEDIUM | Server team already aware from iOS; may be fixed by Android phase |
| Double-fork merge complexity (SC only) | MEDIUM | Use SC's merge scripts, keep changes minimal. N/A if using Element X |
| Google Play review rejection | LOW | Google is less strict than Apple on AGPL/forks |
| SC upstream abandoned (SC only) | LOW | Pin to known working release. N/A if using Element X |
| MapTiler static maps (same issue as iOS) | LOW | Customer decision pending, not blocking |
| Customer response delays | MEDIUM | Maintain list of blocked items, work ahead on non-blocked phases |

---

## 17. Appendix: File Reference

Both repositories share the same `appconfig/` module structure. The differences are in branding/theme files.

### A. Common Files (Both Repos)

| # | File | Purpose |
|---|------|---------|
| 1 | `app/build.gradle.kts` | Application ID, version, flavors, signing, OIDC redirect |
| 2 | `appconfig/.../ApplicationConfig.kt` | App name, default homeserver |
| 3 | `appconfig/.../PushConfig.kt` | Pusher app ID |
| 4 | `appconfig/.../RageshakeConfig.kt` | Bug report config (disable) |
| 5 | `appconfig/.../NotificationConfig.kt` | Notification accent color |
| 6 | `appconfig/.../MatrixConfiguration.kt` | Permalink base URL |
| 7 | `settings.gradle.kts` | Root project name, Maven repos |
| 8 | `libraries/matrix/api/.../OidcConfig.kt` | OIDC client config + static registrations |
| 9 | `app/src/main/AndroidManifest.xml` | Intent filters for OIDC callback + deep links |
| 10 | `gradle/libs.versions.toml` | Dependency versions |

### B. SchildiChat-Specific Files

| # | File | Purpose |
|---|------|---------|
| 11 | `plugins/src/main/kotlin/config/BuildTimeConfig.kt` | Central branding: name, URLs, Firebase, analytics |
| 12 | `plugins/src/main/kotlin/ModulesConfig.kt` | Push provider selection |
| 13 | `plugins/src/main/kotlin/Versions.kt` | Version codes |
| 14 | `plugins/src/main/kotlin/extension/locales.kt` | Supported locale list |
| 15 | `app/src/sc/res/mipmap-*/ic_launcher*.png` | App icons (all densities) |
| 16 | `schildi/theme/ScLight.kt` | Light theme colors |
| 17 | `schildi/theme/ScDark.kt` | Dark theme colors |
| 18 | `schildi/theme/ScBlack.kt` | AMOLED black theme |
| 19 | `schildi/theme/ScColors.kt` | Color definitions |
| 20 | `schildi/lib/res/drawable/ic_notification_sc.xml` | Notification icon |
| 21 | `schildi/lib/res/drawable-*/sc_logo_atom.png` | Logo assets |
| 22 | `schildi/lib/src/main/res/values/strings.xml` | SC-specific strings (en) |
| 23 | `schildi/lib/src/main/res/values-ru/strings.xml` | SC-specific strings (ru) |
| 24 | `libraries/pushproviders/firebase/src/sc/res/values/firebase.xml` | Firebase config (SC flavor) |

### C. Element X Android-Specific Files

| # | File | Purpose |
|---|------|---------|
| 11 | `app/src/main/res/mipmap-*/ic_launcher*.png` | App icons (all densities) |
| 12 | `libraries/designsystem/.../theme/` | Compound theme (ElementTheme, colors) |
| 13 | `app/src/main/res/values/strings.xml` | App-specific strings |
| 14 | `app/src/main/res/values-ru/strings.xml` | Russian strings (if present) |
| 15 | `libraries/pushproviders/firebase/google-services.json` | Firebase config |
| 16 | `app/src/main/res/drawable/ic_notification.xml` | Notification icon |
| 17 | `features/login/impl/.../ChangeServerView.kt` | Default server UI |
| 18 | `features/preferences/impl/...` | Settings/about screen strings |

---

## Quick Start Checklist

### If forking Element X Android:

- [ ] Fork `element-hq/element-x-android` to private repo
- [ ] Build unmodified Element X and verify it runs
- [ ] Change `applicationId` to `org.ucmeet.UCMeetChat` in `build.gradle.kts`
- [ ] Update `appconfig/` module constants (homeserver, push, URLs)
- [ ] Update OIDC config in `OidcConfig.kt` + redirect scheme
- [ ] Replace app icons (all densities + adaptive icon)
- [ ] Override Compound theme colors with navy blue `#003B5D`
- [ ] Trim locales to `en` + `ru`
- [ ] Replace "Element" / "Element X" strings with "UCMeet.Chat"
- [ ] Disable analytics (PostHog, Sentry, rageshake — empty all config values)
- [ ] Configure push (FCM via `google-services.json`) with Sygnal `type: gcm`
- [ ] Configure Element Call (URL scheme `org.ucmeet.call`, clear known hosts)
- [ ] Set MapTiler API key `iKPA4bK9zgtadTEw8neu`
- [ ] Test full E2E: login, messages, push, calls
- [ ] Build signed release AAB
- [ ] Publish to Google Play

### If forking SchildiChat:

- [ ] Fork `SchildiChat/schildichat-android-next` to private repo
- [ ] Build unmodified SC and verify it runs
- [ ] Change `applicationId` to `org.ucmeet.UCMeetChat` in `build.gradle.kts`
- [ ] Update `BuildTimeConfig.kt` with all UCMeet values
- [ ] Update `appconfig/` module constants
- [ ] Replace app icons in `app/src/sc/res/mipmap-*/`
- [ ] Apply navy blue `#003B5D` in `schildi/theme/` color files
- [ ] Trim locales in `locales.kt` to `en` + `ru`
- [ ] Replace "SchildiChat" strings with "UCMeet.Chat"
- [ ] Configure OIDC redirect scheme
- [ ] Disable all analytics (verify SC defaults, clear any remaining)
- [ ] Configure push (UnifiedPush default, optionally enable FCM)
- [ ] Configure Element Call (URL scheme, clear known hosts)
- [ ] Set MapTiler API key `iKPA4bK9zgtadTEw8neu`
- [ ] Test full E2E: login, messages, push, calls
- [ ] Build signed release AAB
- [ ] Publish to Google Play

---

*This guide was prepared based on the iOS fork experience (60 commits, ~96h, Builds 1–5). The Android fork should benefit from pre-established customer infrastructure, resolved server-side issues, and this detailed playbook.*

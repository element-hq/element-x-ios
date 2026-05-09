# UCMeet.Chat Android — Implementation Plan

**Last updated:** 2026-04-05
**Branch:** `ucmeet` (8 commits ahead of `upstream/main`)
**Build status:** GREEN ✓

> This document tracks all phases from planning through Play Store publication.
> For a full changelog of what was changed and in which files, see `progress.md`.

---

## Overall Status

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | Environment setup, first build | ✅ Complete |
| 1 | Identity & configuration | ✅ Complete |
| 2 | OIDC, deep links, calls | ✅ Complete |
| 3 | Push notifications (Firebase) | ⏳ Blocked — needs Firebase credentials |
| 4 | Color theme (navy blue) | ✅ Complete |
| 5 | Localization (en + ru) | ✅ Complete |
| 6 | Calls configuration | ✅ Complete (merged into Phase 2) |
| 7 | Analytics audit & endpoint cleanup | ✅ Complete |
| — | App icons | ⏳ Blocked — needs assets from customer |
| 8 | Release build & signing | ⏳ Blocked — needs signing keystore |
| 9 | Google Play publication | ⏳ Blocked — needs Play Console access |

---

## Completed Phases

### Phase 0 — Environment Setup ✅
- `local.properties` created with `sdk.dir=/Users/macbookpro/Library/Android/sdk`
- First clean build verified successful
- Git remotes configured: `upstream` → SchildiChat, `origin` → GitHub fork

### Phase 1 — Identity & Configuration ✅ (`75a2829`)
All branding, URLs, app IDs, and service endpoints replaced:
- Application ID: `org.ucmeet.UCMeetChat` (all variants)
- App name: `UCMeet.Chat`
- Default homeserver: `matrix.ucmeet.org`
- Push gateway: `https://push.ucmeet.org/_matrix/push/v1/notify`
- All legal URLs → `https://www.ucmeet.info`
- Analytics (PostHog, Sentry), crash reporting (rageshake) → disabled
- MapTiler API key set

### Phase 2 — OIDC, Deep Links, Calls ✅ (`b14d5d8`)
- OIDC redirect schemes → `org.ucmeet.UCMeetChat.{variant}.{buildtype}`
- All 6 `variant.xml` files updated
- Deep link scheme: `elementx://` → `ucmeet://`
- Call URLs: `call.element.io` → `call.ucmeet.org`, `io.element.call` → `org.ucmeet.call`
- Static OIDC registrations cleared (using DCR instead)

### Phase 4 — Color Theme: Navy Blue ✅ (`f0525e6`)
- Primary accent: SC green `#8BC34A` → UCMeet navy `#003B5D` (all 4 alpha variants)
- Onboarding gradient light: pale green → pale navy `#E6EEF4`
- Onboarding gradient dark + icon bg: `#0A5C7C` → `#003B5D`
- Only `ScColors.kt` needed editing — ScLight/Dark/Black/Exposures cascade automatically

### Phase 5 — Localization ✅ (`b4da86a`)
- Trimmed from 35 locales to `en` + `ru` only
- Deleted 14 unused locale directories
- Rebranded SC-specific strings: onboarding title, tweaks label
- Russian translations updated to match
- Onboarding tagline left as-is (customer decision)

### Phase 6 — Calls ✅ (merged into Phase 2)

### Phase 7 — Analytics Audit & Endpoint Cleanup ✅ (`be136ea`)
- All SC analytics infrastructure confirmed disabled
- Remaining SC endpoint in preferences `build.gradle.kts` replaced
- `FossFcmDistributor.kt`: SC VAPID + WebPush relay replaced with UCMeet placeholders (TODO pending infrastructure)

---

## Remaining Work

### Phase 3 — Push Notifications ⏳ BLOCKED

**Blocker:** Customer needs to provide Firebase project credentials.

**What to do when unblocked:**

1. Extract values from `google-services.json` into `app/src/gplaySc/res/values/firebase.xml`:
   ```xml
   <string name="default_web_client_id">...</string>
   <string name="gcm_defaultSenderId">...</string>
   <string name="google_api_key">...</string>
   <string name="google_app_id">1:XXXXXX:android:XXXXXX</string>
   <string name="project_id">...</string>
   ```
2. Update `BuildTimeConfig.kt`:
   ```kotlin
   const val GOOGLE_APP_ID_RELEASE = "1:XXXXXX:android:XXXXXX"
   ```
3. Enable Firebase in `ModulesConfig.kt` (currently both FCM and UnifiedPush are enabled — verify this is still the case)
4. Confirm Sygnal is configured on `push.ucmeet.org`:
   ```yaml
   org.ucmeet.UCMeetChat.android:
     type: gcm
     api_version: v1
     project_id: <firebase-project-id>
     service_account_file: /path/to/service-account.json
   ```
5. Resolve `FossFcmDistributor.kt` TODO: either set up UCMeet WebPush relay at `push.ucmeet.org/wpfcm` and generate a VAPID key pair, or leave as placeholder (only affects UnifiedPush users without GPlay Services)
6. Test push end-to-end on physical device

**Estimated effort:** ~4h implementation + Sygnal config (ops team)

---

### App Icons ⏳ BLOCKED

**Blocker:** Customer to provide icon assets (confirmed: same design as iOS fork).

**What to do when assets arrive:**

Replace all SC turtle launcher icons in `app/src/main/res/`:

| Directory | Size | File |
|-----------|------|------|
| `mipmap-mdpi` | 48×48 | `ic_launcher.png`, `ic_launcher_round.png` |
| `mipmap-hdpi` | 72×72 | same |
| `mipmap-xhdpi` | 96×96 | same |
| `mipmap-xxhdpi` | 144×144 | same |
| `mipmap-xxxhdpi` | 192×192 | same |
| `mipmap-anydpi-v26` | — | `ic_launcher.xml` (adaptive), `ic_launcher_round.xml` |

Adaptive icon layers (API 26+):
- `drawable/ic_launcher_foreground.xml` or PNG
- `drawable/ic_launcher_background.xml` or color

Also needed for Play Store:
- Feature graphic: 1024×500 PNG
- Hi-res icon: 512×512 PNG

**Estimated effort:** ~2h

---

### Phase 8 — Release Build & Signing ⏳ BLOCKED

**Blocker:** Signing keystore not yet created/provided.

**What to do when keystore is ready:**

1. Create `keystore.properties` (gitignored):
   ```properties
   storeFile=/path/to/ucmeet.keystore
   storePassword=...
   keyAlias=...
   keyPassword=...
   ```
2. Confirm `app/build.gradle.kts` `signingConfigs.release` reads from `keystore.properties`
3. Build release AAB for Play Store:
   ```bash
   ./gradlew bundleGplayScDefaultRelease --no-daemon
   ```
4. Build release APK for direct distribution:
   ```bash
   ./gradlew assembleGplayScDefaultRelease --no-daemon
   ```
5. Verify APK signature: `apksigner verify --verbose app-release.apk`

**Estimated effort:** ~2h

---

### Phase 9 — Google Play Publication ⏳ BLOCKED

**Blocker:** Play Console access + all prior phases complete.

**What to do:**

1. Update Play Store metadata in `metadata/en-US/`:
   - `title.txt` → `UCMeet.Chat`
   - `short_description.txt` → UCMeet description
   - `full_description.txt` → Full UCMeet description
   - Add `ru-RU/` locale equivalents
2. Upload AAB from Phase 8 to Play Console internal testing track
3. Complete Play Store listing: screenshots, feature graphic, privacy policy URL
4. Promote through tracks: internal → closed testing → production

**Estimated effort:** ~4h (excludes Play Console review time)

---

## Open Decisions

| # | Decision | Status |
|---|----------|--------|
| D1 | Push: both FCM + UnifiedPush | ✅ Confirmed — both enabled |
| D5 | Firebase project | ⏳ Customer creating new project |
| D7 | Icon assets | ⏳ Customer to provide (same design as iOS) |
| D8 | Onboarding tagline | ✅ Leave as-is per customer |
| D9 | UnifiedPush WebPush relay | ⏳ Pending — decide whether to run `push.ucmeet.org/wpfcm` or leave placeholder |
| D12 | Permalink base URL | Post-launch |

---

## Build Reference

```bash
# Debug build (for development/testing)
./gradlew assembleFdroidScDefaultDebug --no-daemon

# Release AAB (for Play Store)
./gradlew bundleGplayScDefaultRelease --no-daemon

# Release APK (for direct distribution)
./gradlew assembleGplayScDefaultRelease --no-daemon
```

```
App ID (debug):    org.ucmeet.UCMeetChat.debug
App ID (release):  org.ucmeet.UCMeetChat
Version:           1.0.0-ex_26_3_3 (code: 1)
Min SDK:           24 (Android 7.0)
Target SDK:        36 (Android 16)
```

---

## Architecture Notes (for future reference)

- **Internal packages** (`chat.schildi.*`, `io.element.*`) intentionally left unchanged to ease upstream merges
- **`maven.spiritcroc.de`** must stay in `settings.gradle.kts` — required for SC's Rust Matrix SDK
- **Theme cascade:** Only `ScColors.kt` needs editing for color changes; ScLight/Dark/Black/Exposures reference it
- **OIDC schemes on macOS:** `create_variant_resources.sh` uses bash 4+ syntax — edit `variant.xml` files directly on macOS (bash 3.2)
- **Upstream merges:** `git fetch upstream && git merge upstream/main` — internal package names kept to minimise conflicts

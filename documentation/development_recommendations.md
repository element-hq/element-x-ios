# Development Recommendations: UCMeet.Chat Android

Lessons learned and actionable recommendations from the iOS fork (Element X iOS → UCMeet.Chat, ~104h, 60 commits). Apply these to the Android fork (SchildiChat Android Next → UCMeet.Chat) to avoid repeating mistakes and save time.

**For use in:** Android project repo as context for AI-assisted development.

---

## 1. Push Notifications — The #1 Time Sink

Push debugging consumed ~20h on iOS across 3 iterations (ntfy → FCM → APNs). Expect similar challenges on Android.

### Critical Rules

- **Pusher app ID must match Sygnal EXACTLY** (case-sensitive). iOS uses `org.ucmeet.UCMeetChat.ios.prod` / `.ios.dev`. Android should use `org.ucmeet.UCMeetChat.android` — verify this matches the Sygnal config entry key character-for-character.
- **After changing ANY push config, users must re-login** to register fresh push tokens. Old tokens from previous configs will cause silent failures.
- **Test with actual message delivery**, not just token registration. A 200 from the pusher registration endpoint does NOT mean push works end-to-end.
- **Debug vs release builds may use different push environments.** On iOS, debug builds use APNs sandbox while TestFlight/release use production APNs. Verify the Android equivalent (FCM doesn't have this distinction, but Sygnal config might).
- **Start push testing EARLY** — don't leave it for the end.

### Firebase Project — Reuse iOS

The iOS project already has Firebase project `matrix-8c24a` (sender ID `951982198962`). To reuse it:

1. Firebase Console → Project `matrix-8c24a` → Add app → Android
2. Package name: `org.ucmeet.UCMeetChat`
3. Download `google-services.json`
4. Extract values into `app/src/gplaySc/res/values/firebase.xml`
5. Update `BuildTimeConfig.kt` with the `GOOGLE_APP_ID_RELEASE` value from `google-services.json`

This avoids creating a separate Firebase project and service account JSON. The existing Sygnal service account can be reused if the project is the same.

### Sygnal Configuration for Android

Provide this exact config to the customer's server team:

```yaml
# Add to sygnal.yaml alongside the existing iOS entry
org.ucmeet.UCMeetChat.android:
  type: gcm
  api_version: v1
  project_id: matrix-8c24a
  service_account_file: /path/to/service-account.json
```

Note: On iOS, Sygnal's `type: gcm` pushkin was INCOMPATIBLE with APNs payload format (it put `alert`/`mutable-content` into FCM `data` field). We had to switch iOS to `type: apns`. This issue does NOT affect Android — `type: gcm` is the correct and native choice for Android/FCM delivery.

### UnifiedPush / FOSS FCM Distributor

SchildiChat uses a FOSS FCM distributor for push without Google Play Services. The `FossFcmDistributor.kt` has placeholder VAPID + WebPush relay values. For initial release:

- **If all target users have Google Play Services:** FCM works directly, UnifiedPush distributor is a fallback. Leave placeholder.
- **If targeting devices without GPlay (Huawei, degoogled):** Set up a WebPush relay at `push.ucmeet.org/wpfcm` and generate VAPID key pair. This is a post-launch optimization.

---

## 2. CallKit / Incoming Call Notifications

### Current Status (as of April 2026)

Incoming calls show as regular push notifications, NOT as the native call screen. This affects both iOS (CallKit) and Android (full-screen intent).

### Root Cause

The **Element Call widget** is not sending `m.rtc.notification` events (MSC4075) when initiating calls. We confirmed this by querying room events via the Matrix API — zero `m.rtc.notification` events exist across all test calls.

Key findings:
- MSC4075 is a **client-side protocol**, NOT a Synapse feature
- `msc4075_enabled: true` in Synapse config does nothing (no such code in Synapse)
- The calling client (Element Call widget) must send `m.rtc.notification` with `notification_type: "ring"` and `m.mentions` targeting the callee
- Synapse distributes it as a normal room event; push triggers via standard mention rules
- The Element Call JS bundle at `call.ucmeet.org` contains `rtc.notification` code but doesn't trigger it

### What This Means for Android

The same issue will prevent native incoming call UI on Android. The fix is:
1. Update Element Call at `call.ucmeet.org` to a version that sends ringing notifications
2. Update the embedded Element Call version in the app (if applicable)

This is a **post-launch task** — deferred to next sprint on both platforms.

### Don't Waste Time On

- Searching for MSC4075 in Synapse source — it's not there
- Adding VoIP push entitlements or special server config
- Modifying app-side call handling code — the receiving code is correct

---

## 3. Branding

### What Worked on iOS

- **Compound design token overrides** via a single hook file (47 tokens, covering SwiftUI + UIKit)
- **Navy blue palette:** `#003B5D` (primary), `#004A75` (hovered), `#005A8E` (pressed), `#002D47` (dark), `#001F31` (darkest)
- **Keep copyright headers unchanged** — AGPL requires preserving original attribution

### Android Equivalent

- **ScColors.kt is the single file** for color changes — ScLight/Dark/Black/Exposures cascade automatically. This is even cleaner than iOS.
- Apply the same navy palette values
- Leave internal package names (`chat.schildi.*`, `io.element.*`) unchanged to minimize upstream merge conflicts
- Do NOT rename internal classes, modules, or Gradle module names unless absolutely necessary

### Icon Assets

Reuse the iOS source assets from the `newIcons/` directory. Generate Android densities:

| Density | Size | Source |
|---------|------|--------|
| mdpi | 48x48 | Scale from 1024x1024 |
| hdpi | 72x72 | Scale from 1024x1024 |
| xhdpi | 96x96 | Scale from 1024x1024 |
| xxhdpi | 144x144 | Scale from 1024x1024 |
| xxxhdpi | 192x192 | Scale from 1024x1024 |
| Play Store | 512x512 | Scale from 1024x1024 |
| Feature graphic | 1024x500 | New asset needed |

For adaptive icons (API 26+): create foreground layer (logo) + background layer (navy blue `#003B5D`).

---

## 4. OIDC / Authentication

### What Worked on iOS

- Custom URL scheme `org.ucmeet.UCMeetChat:/callback`
- Dynamic Client Registration (DCR) — works out of the box with customer's MAS
- Static OIDC registration was planned but DCR made it unnecessary

### Android Notes

- OIDC redirect schemes are per-variant: `org.ucmeet.UCMeetChat.{variant}.{buildtype}`
- DCR should work the same way — MAS on `ucmeet.org` supports it
- Static OIDC registrations correctly cleared (using DCR instead)
- Test OIDC login early — if it works on iOS, it should work on Android with the same MAS

---

## 5. Localization

### What Worked on iOS

- Trimmed from 37 → 3 locales (en, en-US, ru)
- Customer is Russian-speaking — all user-facing communication in Russian
- 14+ manual Russian translation corrections were needed (upstream quality was uneven)

### Android Notes

- Trimmed from 35 → 2 locales (en, ru) — correct approach
- Review upstream Russian translations for quality — same issue may exist
- SchildiChat has its own Russian strings in `schildi/lib/` — verify these are accurate
- Brand strings ("SchildiChat" → "UCMeet.Chat") should be updated in all locale files

---

## 6. Analytics & Telemetry

### Complete Disable Checklist

Both iOS and Android must have ALL analytics disabled:

| Service | iOS Status | Android Action |
|---------|-----------|---------------|
| PostHog | Disabled (nil) | Disable in BuildTimeConfig.kt |
| Sentry | Disabled (nil) | Disable in BuildTimeConfig.kt |
| Rageshake | Disabled (nil) | Disable in RageshakeConfig.kt |
| Element Call PostHog | Disabled (empty) | Disable in BuildTimeConfig.kt |
| Element Call Sentry | Disabled (empty) | Disable in BuildTimeConfig.kt |

SchildiChat already disables most analytics — verify and ensure nothing leaks.

---

## 7. Legal / AGPL Compliance

### Requirements (Same for Both Platforms)

1. **Source code must be available to users** — host the fork on a public GitHub repo or provide source on request
2. **Keep original copyright headers** — do NOT modify AGPL/Apache headers in source files
3. **Credit original projects** in About/Licenses screen (SchildiChat, Element X, Matrix)
4. **Do NOT use SchildiChat's or Element's name/logo/branding** — use your own (UCMeet.Chat)
5. **Written AGPL confirmation from customer** before publication — pending for iOS, same requirement for Android

### App-Side Implementation

Add a "Source Code" link in the app's About/Settings screen pointing to the public fork repository. This satisfies AGPL's source code availability requirement.

---

## 8. App Store / Play Store Preparation

### Google Play Data Safety (Equivalent to iOS Privacy Nutrition Labels)

| Question | Answer |
|----------|--------|
| Does your app collect data? | Yes |
| Data types collected | User identifiers (Matrix user ID), Messages (E2EE), Profile info (display name, avatar) |
| Is data encrypted in transit? | Yes (TLS + E2EE) |
| Data sharing with third parties | No |
| User tracking | No |

### Play Store Listing

Reuse the iOS App Store content:
- **Title:** UCMeet.Chat
- **Short description:** Мессенджер на протоколе Matrix (Russian) / Secure messenger for your organization (English)
- **Full description:** Adapt from iOS App Store description
- **Screenshots:** Capture from Android device/emulator
- **Privacy policy:** `https://www.ucmeet.info/privacy`
- **Feature graphic:** 1024x500 (new asset needed — not required for iOS)

### Review Notes (Private — Not Visible to Users)

Include in Play Store internal notes or testing instructions:

```
UCMeet.Chat is an authorized deployment of the open-source SchildiChat Android client
(AGPL v3, SDK Apache 2.0), customized for the UCMeet corporate communication platform.
It connects exclusively to the organization's private Matrix server (matrix.ucmeet.org)
and cannot be used with public Matrix servers. Source code is available per the AGPL v3 license.

Test account: apple_support / pvINTqBvwBR2
Server: matrix.ucmeet.org (connects automatically)

After login, enter the Security Key when prompted to decrypt chat history:
[PASTE SECURITY KEY HERE]
```

---

## 9. Version Numbering

### Recommendation

Simplify from SchildiChat's inherited `1.0.0-ex_26_3_3` to clean `1.0.0`:
- `versionName = "1.0.0"`
- `versionCode = 1`
- Increment `versionCode` for each build (1, 2, 3...)
- Use semantic versioning: 1.0.0 → 1.0.1 (patch) → 1.1.0 (feature) → 2.0.0 (major)

---

## 10. Signing & Distribution

### Signing Keystore

Generate locally — doesn't need to come from the customer:

```bash
keytool -genkey -v -keystore ucmeet-release.keystore -alias ucmeet \
  -keyalg RSA -keysize 2048 -validity 10000
```

Store securely. Create `keystore.properties` (gitignored):
```properties
storeFile=/path/to/ucmeet-release.keystore
storePassword=...
keyAlias=ucmeet
keyPassword=...
```

### Play App Signing (Recommended)

Use Google's Play App Signing:
- Upload your APK/AAB signed with the upload key
- Google manages the distribution signing key
- If you lose the upload key, Google can reset it (unlike self-managed signing)

---

## 11. Customer Communication

### Key Lessons from iOS

1. **Customer is Russian-speaking** — all user-facing communication in Russian
2. **Customer has limited testing capacity** — provide clear step-by-step instructions
3. **Server-side changes require coordination** — don't assume they're done. Always verify.
4. **Provide exact configs** — don't describe what to do; provide the exact YAML/JSON to paste
5. **Customer response time varies** — maintain a clear list of blocked items, work ahead on non-blocked phases
6. **Document everything** — decisions, configs, credentials in a decisions tracker

### Items to Request from Customer (Android)

1. **Google Play Console access** — either add developer to existing account, or create new ($25 one-time fee)
2. **Firebase credentials** — suggest reusing iOS project `matrix-8c24a` (add Android app, download `google-services.json`)
3. **Sygnal Android entry** — provide exact config (see Section 1 above)
4. **App icons** — reuse iOS source assets, generate Android densities
5. **AGPL confirmation** — same as iOS, one confirmation covers both platforms
6. **Test accounts** — reuse iOS test accounts (`apple_support` / `pvINTqBvwBR2`)

---

## 12. Git & Upstream Merge Strategy

### Rules

- **Keep fork minimal** — every extra change increases upstream merge difficulty
- **Never rename internal packages** (`chat.schildi.*`, `io.element.*`) — this prevents thousands of merge conflicts
- **Edit config files, not generated files** — Gradle builds, not manual edits
- **Commit format:** imperative, concise (match upstream style)
- **Branch structure:** `ucmeet` (active development), `upstream/main` (SchildiChat upstream)
- **Upstream sync:** `git fetch upstream && git merge upstream/main` — SC has merge scripts (`pre_merge.sh`, `fix_merge.sh`) for complex merges

### What to Change vs What to Leave

| Change | Leave |
|--------|-------|
| Application ID, app name | Internal package names |
| BuildTimeConfig values | Gradle module names |
| ScColors.kt (theme) | ScLight/Dark/Black cascading files |
| Locale list (trim) | Upstream translation strings |
| Icon assets | Copyright headers |
| Config files (URLs, keys) | Architecture patterns |

---

## 13. Testing Priorities

### Minimum E2E Test Matrix (Before Release)

| Test | Priority | Method |
|------|----------|--------|
| Build succeeds (debug + release) | P0 | CI or local |
| Login via OIDC | P0 | Physical device |
| Send/receive messages (text) | P0 | Two accounts |
| Push notification (app background) | P0 | Physical device + Sygnal |
| Push notification (app terminated) | P0 | Physical device |
| E2EE indicators | P1 | Two accounts |
| Media (photo, video, file) | P1 | Send + receive |
| 1:1 call (audio/video) | P1 | Two physical devices |
| Group call | P2 | Three devices via call.ucmeet.org |
| Russian locale | P1 | Switch device language |
| Location sharing | P2 | If MapTiler works |
| Profile management | P2 | Name, avatar |
| Logout/re-login | P1 | Token cleanup |
| Security key restore | P1 | Verify E2EE history access |

### Unit Tests

Run `./gradlew test` and ensure no new failures introduced by the fork. Do not fix pre-existing test failures unless they're caused by our changes.

---

## 14. Customer Infrastructure Reference

| Service | URL | Notes |
|---------|-----|-------|
| Homeserver | `matrix.ucmeet.org` | Synapse 1.150.0 |
| Push Gateway | `https://push.ucmeet.org` | Sygnal |
| Element Call | `call.ucmeet.org` | LiveKit-based |
| OIDC (MAS) | Hosted on `ucmeet.org` | DCR supported |
| Website | `https://www.ucmeet.info` | Privacy, ToS, support |
| LiveKit JWT | `https://matrix.ucmeet.org/livekit-jwt-service` | From `.well-known` |
| Firebase Project | `matrix-8c24a` | Sender ID `951982198962` |
| APNs Key ID | `XZANH7CD3Z` | Team ID `6HRG779SDK` (iOS only) |
| Permalink redirect | `ucmatrix.org` | Post-launch (matrix.to banned in Russia) |

### Test Accounts

| Username | Password | Notes |
|----------|----------|-------|
| `apple_support` | `pvINTqBvwBR2` | Has existing chats, security key needed |
| `test_user` | `sPkZt1VCCW48` | Secondary test account |

---

*Prepared from iOS fork experience (104h, 60 commits, Builds 1-5). Last updated: 2026-04-05.*

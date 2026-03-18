# Sprint Plan

Converted from customer-provided sprint breakdown (Спринт 5Element.docx).
Timeline: 6 sprints / 45 days.

---

## Sprint 1: Environment Setup & Fork (Days 1-7) — DONE

**Goal:** Launch fork and build a working dev build.

**Tasks:**
- [x] Clone Element X repository
- [x] Set up new Bundle ID (`org.ucmeet.UCMeetChat`)
- [x] Update Display Name (`UCMeet.Chat`)
- [x] Configure build schemes (Debug/Release)
- [x] Set Deployment Target to iOS 18+
- [x] Connect homeserver (`matrix.ucmeet.org`)
- [x] Verify `.well-known` configuration
- [x] Build runs on device/simulator
- [x] Login with test account works
- [x] Check App Groups / Keychain Sharing configuration

**Result:**
- [x] Working dev build
- [x] Successful authentication
- [x] Room list loads

---

## Sprint 2: Branding & Basic Functionality (Days 8-14) — DONE

**Goal:** Fully functional basic messenger with branding.

**Tasks:**
- [x] Prepare and add app icons (all sizes + 1024x1024)
- [x] Configure accent color (dark navy blue #003B5D)
- [x] Verify RU/EN auto-localization (trimmed to 3 locales: en, en-US, ru)
- [x] Verify Sliding Sync
- [x] Send/receive messages
- [x] Media attachments (images, video, files)
- [x] Reactions
- [x] Read receipts
- [x] Logout/login cycle
- [x] Profile: change display name, avatar, device list
- [x] Verify E2EE: encryption indicators, key exchange between devices
- [x] In-app logo sizing fixed (330x330px @3x, renders at 110pt)
- [x] Configure MapLibre: API key obtained, Secrets.swift updated, styles set to `basic-v2`/`basic-v2-dark`, Secrets.swift excluded from git via `assume-unchanged`

**Result:**
- [x] Fully functional messenger (without push)
- [x] Customer demonstration ready

**Note:** MapLibre interactive map works. Static map previews in timeline show "Invalid key" — the API key lacks Static Maps API permission on MapTiler. Needs key permission update on MapTiler account. Not originally in customer's sprint spec (Спринт 5Element.docx).

**Updates (2026-03-03):**
- Xcode signing resolved: customer's Apple ID added to Xcode Accounts, automatic signing works for all 3 targets
- OIDC redirect URI fixed: custom URL scheme `org.ucmeet.UCMeetChat:/callback` (MAS DCR confirmed working)
- In-app logo sizing fixed: resized to 330x330px @3x (was 1024px causing full-screen render)
- Firebase GoogleService-Info.plist replaced with real Firebase project config

**Updates (2026-03-07):**
- MapLibre API key configured, styles updated to MapTiler built-in defaults
- Interactive map (location sharing screen) works correctly
- Static map preview (timeline) returns 403 — key needs Static Maps permission enabled on MapTiler

---

## Sprint 3: Push + OIDC + Associated Domains (Days 15-21) — BLOCKED ON CUSTOMER

**Goal:** Full push notification and OIDC setup.

### Push Notifications
- [x] Create Firebase project for `org.ucmeet.UCMeetChat` (project ID: `matrix-8c24a`)
- [x] Add real `GoogleService-Info.plist` (replaced placeholder 2026-03-03)
- [x] Upload APNs key to Firebase Console (2026-03-11)
- [x] Integrate Firebase SDK (FirebaseMessaging via SPM)
- [x] Implement FCM token registration
- [x] Configure Sygnal integration (`https://push.ucmeet.org`)
- [x] Generate Firebase service account JSON for customer's Sygnal
- [x] Send customer appeal with Sygnal config instructions (2026-03-11)
- [ ] **BLOCKED — Customer:** Configure Sygnal with Firebase credentials for both app IDs (`org.ucmeet.UCMeetChat.ios.prod` + `.ios.dev`)
- [ ] **BLOCKED — Customer:** Confirm Sygnal URL (currently assuming `https://push.ucmeet.org`)
- [ ] Verify push: app active (needs physical device + Sygnal)
- [ ] Verify push: app in background
- [ ] Verify push: app terminated
- [ ] Badge count
- [ ] Open correct chat on push tap
- [ ] Inline reply from notification

### OIDC / MAS
- [x] OIDC login working (tested on simulator)
- [x] OIDC redirect URI: custom URL scheme `org.ucmeet.UCMeetChat:/callback` (2026-03-03)
- [x] OIDC metadata URIs moved to ucmeet.org (MAS same-host policy)
- [ ] Register `org.ucmeet.UCMeetChat` as OIDC client in MAS (currently using DCR — works, but static registration is more robust)
- [ ] Verify full OIDC flow with registered client

### Associated Domains
- [x] Added Associated Domains capability
- [x] Removed `webcredentials:*.element.io` (no longer needed after custom URL scheme)
- [ ] **POST-LAUNCH:** Remove `applinks:matrix.to` from entitlements — non-functional (matrix.to AASA doesn't list our Bundle ID). Harmless but dead weight.
- [ ] **POST-LAUNCH:** Optionally add `applinks:ucmeet.info` + host AASA file on `ucmeet.info` — would enable universal links (room invites, user profiles open directly in app). Requires customer to set up `ucmeet.info/.well-known/apple-app-site-association` with Bundle ID `org.ucmeet.UCMeetChat`.

**Result:**
- [ ] Fully working push notifications — **blocked on customer Sygnal configuration**
- [x] Working authentication via MAS (custom URL scheme, no element.io dependency)

**Blocking:** Customer must configure Sygnal with Firebase service account JSON (sent 2026-03-11).

**Updates (2026-03-11):**
- APNs key uploaded to Firebase Console
- Firebase service account JSON generated and sent to customer
- Customer appeal sent with detailed Sygnal config instructions (both `.ios.dev` and `.ios.prod` app IDs)
- All developer-side push work complete — waiting on customer

---

## Sprint 4: Calls & UCMeet Call (Days 22-28) — DONE

**Goal:** Working voice/video calls.

**Tasks:**
- [x] Verify 1:1 calls (MatrixRTC)
- [x] Test microphone/camera
- [x] Handle incoming calls
- [x] Configure UCMeet Call (`call.ucmeet.org`): URL scheme `org.ucmeet.call`, knownHosts cleared, LiveKit confirmed
- [x] Test group call scenario
- [x] Verify permissions (Camera/Mic)

**Result:**
- [x] Working 1:1 calls
- [x] Working group calls via UCMeet Call

---

## Sprint 5: Finalization & Release Prep (Days 29-35) — IN PROGRESS

**Goal:** Release-ready build.

**Tasks:**
- [x] Switch build to Release configuration — Archive build succeeded (2026-03-18)
- [x] Set version: 1.0.0 (Build 1) (2026-03-13)
- [x] Verify Info.plist (Camera, Mic, Notifications permissions) — all 5 strings use `$(APP_DISPLAY_NAME)`, en + ru localized (2026-03-13)
- [x] Debug log audit — zero `print()` in production code, all logging via MXLog framework (2026-03-13)
- [x] Optimize: memory, energy, launch time — N/A, upstream-maintained (no new code, rebrand only) (2026-03-18)
- [x] Verify minimum iOS 18 — confirmed `18.0` in project.yml (2026-03-13)
- [x] Verify Distribution signing — Archive build succeeded with customer's Apple ID (2026-03-18)
- [x] NOTICE/attribution — already correct, credits Element X + AGPL-3.0 (2026-03-13)
- [x] **DECIDED:** `ITSAppUsesNonExemptEncryption` set to `true` — Matrix uses E2EE (Olm/Megolm via Vodozemac). Qualifies for mass market exemption EAR §740.17(b)(1). Customer should file BIS self-classification report before release. (2026-03-18)
- [x] CI/CD trimmed for fork — removed 7 Element-specific workflows, all tests manual-only (2026-03-18)
- [ ] Revert temporary debug logging before App Store release (commit `4c2e98746`)
- [ ] **BLOCKED — Customer:** Written confirmation of AGPL license covering Element X fork

**Updates (2026-03-13):**
- Version set to 1.0.0 (Build 1) — changed from upstream calendar version `26.03.4`
- Upstream sync completed (89 commits merged, SDK v26.03.10, Element Call v0.17.0)
- Info.plist permissions verified in en + ru, all reference UCMeet.Chat
- Debug log audit clean — no fork-specific print() statements
- `aps-environment` is `development` in source; Xcode auto-overrides to `production` on Archive
- Build verified on iPhone 17 Pro simulator

**Updates (2026-03-17/18):**
- NSE entitlement `com.apple.developer.usernotifications.filtering` removed (requires Apple approval)
- Second upstream sync: 13 commits merged (translations, compound-design-tokens, Classic accounts, key backup fix)
- Element Classic `group.im.vector` App Group removed (not registered in our Apple Developer account)
- Push E2E test: app-side confirmed working (FCM token, pusher 200 OK, message sent). Server-side break identified (Synapse → ntfy)
- SwiftFormat lint fix: redundant nil init in AppSettings.swift
- `ITSAppUsesNonExemptEncryption` changed from `false` to `true`
- Archive build succeeded — distribution signing confirmed (2026-03-18)
- CI/CD trimmed: removed 7 broken Element workflows, all macOS test workflows manual-only (2026-03-18)

**Result:**
- [x] Release build ready for TestFlight (Archive succeeds, signing works)
- [ ] Legal risks resolved (AGPL confirmation still pending from customer)

---

## Sprint 6: TestFlight & Publication (Days 36-45) — NOT STARTED

**Goal:** App Store publication.

**Tasks:**
- [ ] Upload to TestFlight
- [ ] Customer testing
- [ ] Fix bugs
- [ ] Prepare test account + instructions for App Review
- [ ] App Store listing: RU/EN descriptions, keywords, screenshots (6.7" and 5.5"), privacy URL, support URL, age rating
- [ ] Submit to App Store
- [ ] Respond to review questions
- [ ] Release
- [ ] Handover: source code, build instructions, update documentation

**Result:**
- [ ] App published on App Store
- [ ] Project complete

---

*Last updated: 2026-03-18. Sprint 5 dev-side complete. Blocked on customer for push server fix + AGPL confirmation.*

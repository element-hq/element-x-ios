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

## Sprint 3: Push + OIDC + Associated Domains (Days 15-21) — PARTIAL

**Goal:** Full push notification and OIDC setup.

### Push Notifications
- [x] Create Firebase project for `org.ucmeet.UCMeetChat`
- [x] Add real `GoogleService-Info.plist` (replaced placeholder 2026-03-03)
- [x] Configure APNs key in Firebase (code ready)
- [x] Integrate Firebase SDK (FirebaseMessaging via SPM)
- [x] Implement FCM token registration
- [x] Configure Sygnal integration (`https://push.ucmeet.org`)
- [ ] Upload APNs key to Firebase Console
- [ ] Verify push: app active
- [ ] Verify push: app in background
- [ ] Verify push: app terminated
- [ ] Badge count
- [ ] Open correct chat on push tap

### OIDC / MAS
- [x] OIDC login working (tested on simulator)
- [x] OIDC redirect URI: custom URL scheme `org.ucmeet.UCMeetChat:/callback` (2026-03-03)
- [x] OIDC metadata URIs moved to ucmeet.org (MAS same-host policy)
- [ ] Register `org.ucmeet.UCMeetChat` as OIDC client in MAS (currently using DCR)
- [ ] Verify full OIDC flow with registered client

### Associated Domains
- [x] Added Associated Domains capability
- [x] Removed `webcredentials:*.element.io` (no longer needed after custom URL scheme)
- [ ] Host AASA file on `ucmeet.info` (for universal links, not required for auth)

**Result:**
- [ ] Fully working push notifications (blocked on Sygnal URL + APNs key upload to Firebase Console)
- [x] Working authentication via MAS (custom URL scheme, no element.io dependency)

**Blocking:** Sygnal URL from customer, APNs key upload to Firebase Console.

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

## Sprint 5: Finalization & Release Prep (Days 29-35) — NOT STARTED

**Goal:** Release-ready build.

**Tasks:**
- [ ] Switch build to Release configuration
- [ ] Set version: 1.0.0 (Build 1)
- [ ] Verify Info.plist (Camera, Mic, Notifications permissions)
- [ ] Remove debug logs
- [ ] Optimize: memory, energy, launch time
- [ ] Verify minimum iOS 18
- [ ] Verify Distribution signing
- [ ] License block: written confirmation from Element or publish fork (AGPL compliance), remove Element trademarks, add NOTICE/attribution

**Result:**
- [ ] Release build ready for TestFlight
- [ ] Legal risks resolved

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

*Last updated: 2026-03-07. Converted from Спринт 5Element.docx with progress tracking.*

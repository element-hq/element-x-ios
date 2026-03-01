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

## Sprint 2: Branding & Basic Functionality (Days 8-14) — MOSTLY DONE

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
- [ ] Configure MapLibre: obtain API key, update Secrets.swift, configure map styles, exclude Secrets.swift from git

**Result:**
- [x] Fully functional messenger (without push)
- [ ] Customer demonstration (pending MapLibre + final assets)

**Blocking:** MapLibre API key needed from customer.

---

## Sprint 3: Push + OIDC + Associated Domains (Days 15-21) — PARTIAL

**Goal:** Full push notification and OIDC setup.

### Push Notifications
- [ ] Create Firebase project for `org.ucmeet.UCMeetChat`
- [ ] Add real `GoogleService-Info.plist`
- [x] Configure APNs key in Firebase (code ready)
- [x] Integrate Firebase SDK (FirebaseMessaging via SPM)
- [x] Implement FCM token registration
- [x] Configure Sygnal integration (`https://push.ucmeet.org`)
- [ ] Verify push: app active
- [ ] Verify push: app in background
- [ ] Verify push: app terminated
- [ ] Badge count
- [ ] Open correct chat on push tap

### OIDC / MAS
- [x] OIDC login working (tested on simulator)
- [ ] Register `org.ucmeet.UCMeetChat` as OIDC client in MAS
- [ ] Verify full OIDC flow with registered client

### Associated Domains
- [x] Added Associated Domains capability
- [x] `webcredentials:*.element.io` configured (temporary)
- [ ] Host AASA file on `ucmeet.info`
- [ ] Migrate webcredentials to `ucmeet.info`

**Result:**
- [ ] Fully working push notifications
- [x] Working authentication via MAS (using element.io URIs temporarily)

**Blocking:** Firebase project creation (D-002), Sygnal URL verification, AASA file hosting.

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

*Last updated: 2026-03-01. Converted from Спринт 5Element.docx with progress tracking.*

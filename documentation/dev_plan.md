# Development Plan — iOS Client (UCMeet.Chat)

Converted from customer-provided plan (План разработки iOS 5Element.docx).
Timeline: 6 weeks / 45 days.

---

## Sprint Overview

| Sprint | Days | Name | Key Tasks | Deliverable | Status |
|--------|------|------|-----------|-------------|--------|
| 1 | 1-7 | Environment Setup & Fork | Fork, base build, iOS 18+, server connection | Working dev build | DONE |
| 2 | 8-14 | Branding & Basic Functionality | UI, localization, chats, E2EE, MapLibre | Customer demo | MOSTLY DONE |
| 3 | 15-21 | Push + OIDC + Associated Domains | FCM, Sygnal, MAS, webcredentials | Working push + login | PARTIAL |
| 4 | 22-28 | Calls & UCMeet Call | 1:1 calls, group calls via UCMeet Call | Working calls | DONE |
| 5 | 29-35 | Finalization & Release Prep | Optimization, licensing, compliance | Release build ready | NOT STARTED |
| 6 | 36-45 | TestFlight & Publication | Moderation, publication | App in App Store | NOT STARTED |

---

## Sprint 1 (Days 1-7): Environment Setup & Fork — DONE

**Tasks:**
1. Create private Git repository for Element X fork
2. Clone official repository
3. Install dependencies (Swift Package Manager, Rust SDK)
4. Update: Bundle ID → `org.ucmeet.UCMeetChat`, Display Name → `UCMeet.Chat`
5. Set Deployment Target → iOS 18+
6. Configure Debug/Release schemes
7. Connect customer homeserver: `matrix.ucmeet.org`
8. Verify `.well-known/matrix/client` handling
9. Build app: simulator + real device
10. Verify login with test account
11. Verify room list loading
12. Check App Groups / Keychain Sharing configuration

**Deliverables:**
- Working dev build
- Successful authentication
- Room list loads
- Repository with fork
- Server configuration document

---

## Sprint 2 (Days 8-14): Branding & Basic Functionality — MOSTLY DONE

**Tasks:**
1. Prepare and add icons (all sizes + 1024x1024 for App Store)
2. Configure Accent Color
3. Verify RU/EN auto-localization
4. Verify: Sliding Sync, send/receive messages, attachments (images, video, files), reactions, read receipts, logout/login
5. Verify profile: change display name, avatar, device list
6. Verify E2EE: encryption indicators, key exchange between devices
7. Configure MapLibre: obtain API key, update Secrets.swift, configure map styles, exclude Secrets.swift from git

**Deliverables:**
- Fully functional messenger (without push)
- Customer demonstration
- Branded assets
- Configured localization
- MapLibre configuration

**Status note:** MapLibre configuration pending (API key needed). All other tasks complete.

---

## Sprint 3 (Days 15-21): Push + OIDC + Associated Domains — PARTIAL

### Push Notifications
1. Create Firebase project for `org.ucmeet.UCMeetChat`
2. Add `GoogleService-Info.plist`
3. Configure APNs key in Firebase
4. Integrate Firebase SDK
5. Implement FCM token registration
6. Configure Sygnal integration: `https://push.ucmeet.org`
7. Verify: push while active, background, terminated
8. Implement badge count
9. Open correct chat on push tap

### OIDC / MAS
1. Obtain redirect URI
2. Register OIDC client in MAS
3. Verify authentication via MAS

### Associated Domains
1. Add Associated Domains capability
2. Add `webcredentials:yourdomain`
3. Host `apple-app-site-association` file
4. Verify webcredentials validation

**Deliverables:**
- Fully working push notifications
- Working MAS authentication
- **Critical milestone**

**Status note:** FCM code complete with 14 unit tests. OIDC login working (element.io URIs). Real Firebase config, Sygnal E2E testing, OIDC client registration, and AASA file pending.

---

## Sprint 4 (Days 22-28): Calls — DONE

**Tasks:**
1. Verify 1:1 calls (MatrixRTC)
2. Test microphone/camera
3. Verify incoming call handling
4. Integrate UCMeet Call (`https://call.ucmeet.org`): launch method (WebView/deep link), room parameter passing, return to app
5. Test group scenario
6. Verify permissions (Camera/Mic)

**Deliverables:**
- Working 1:1 calls
- Working group calls via UCMeet Call

---

## Sprint 5 (Days 29-35): Finalization & Release Prep — NOT STARTED

**Tasks:**
1. Switch to Release build
2. Set version: 1.0.0 (Build 1)
3. Verify Info.plist (Camera, Mic, Notifications)
4. Remove debug logs
5. Optimize: memory, energy consumption, launch time
6. Verify minimum iOS 18
7. Verify Distribution signing
8. License block: written confirmation from Element OR publish fork (AGPL compliance), remove Element trademarks, add NOTICE/attribution

**Deliverables:**
- Release build ready for TestFlight upload
- Legal risks resolved

---

## Sprint 6 (Days 36-45): TestFlight & Publication — NOT STARTED

**Tasks:**
1. Upload to TestFlight
2. Customer testing
3. Bug fixes
4. Prepare test account + instructions for App Review (required for login-gated apps)
5. Prepare App Store listing: RU/EN descriptions, keywords, screenshots (6.7" and 5.5"), privacy URL, support URL, age rating
6. Submit to App Store
7. Respond to moderation questions
8. Release
9. Handover: source code, build instructions, update documentation

**Deliverables:**
- App published on App Store
- Project complete

---

## Plan Coverage

This plan addresses:
- Full TOR requirements
- iOS 18+ deployment target
- UCMeet Call integration (MatrixRTC + LiveKit)
- OIDC and Associated Domains
- AGPL licensing compliance
- RU/EN localization
- MapLibre integration
- App Store submission risks (Guideline 4.3 differentiation)

---

*Last updated: 2026-03-01. Converted from План разработки iOS 5Element.docx with progress tracking.*

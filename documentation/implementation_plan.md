# Day-by-Day Implementation Schedule
## Element X iOS — Branded Fork

**Document Version:** 1.0
**Date:** February 8, 2026
**Prepared by:** Saidakhror Murzaliev
**Related Document:** `preliminary_assessment.md` (v1.0)

---

## Schedule Parameters

| Parameter | Value |
|-----------|-------|
| **Working hours per day** | 4h |
| **Working days per week** | 5 (Mon–Fri) |
| **Hours per week** | 20h |
| **Core schedule** | 6 weeks (30 working days) = 120h |
| **Buffer** | 2 weeks (10 working days) = up to 40h |
| **Total maximum** | 8 weeks / 160h |
| **Expected actual effort** | ~120h (matches assessment midpoint) |

### Dependency Flag Legend

| Flag | Meaning |
|------|---------|
| 🔴 | **Backend required** — Customer's server infrastructure must be accessible |
| 🟡 | **Design assets required** — Customer must provide branding materials |
| 📋 | **Licensing checkpoint** — Licensing status must be verified |
| ⚙️ | **Apple Developer account required** — Active enrollment needed |

---

## Week 1 — Project Setup & Licensing Start (Days 1–5)
**Phases:** 1 (Project Setup & Environment) + 2 (Licensing & Legal Resolution — start)
**Hours:** 20h

---

### Day 1 — 4h | Fork & Environment Setup
**Phase:** 1 (Project Setup)

| # | Task | Description |
|---|------|-------------|
| 1 | Fork Element X iOS repository | Create private fork from chosen release tag (iOS 17+ recommended). Set up local Git repo with branching strategy (main + develop). |
| 2 | Send licensing inquiry to Element | Draft and send email to Element (New Vector Ltd) regarding commercial licensing for App Store distribution. Include project scope description. |
| 3 | Install XcodeGen | Install via Homebrew (`brew install xcodegen`), verify version compatibility with project's `project.yml`. |
| 4 | Begin SPM dependency resolution | Run `xcodegen generate`, open generated `.xcodeproj`, let Xcode resolve all Swift Package Manager dependencies. This may take 30–60 minutes. |

**Expected outcome:** Repository forked, licensing inquiry sent, XcodeGen installed, SPM resolution started.

---

### Day 2 — 4h | First Successful Build
**Phase:** 1 (Project Setup)

| # | Task | Description |
|---|------|-------------|
| 1 | Complete SPM resolution | Ensure all packages resolve without errors. Fix any version conflicts if present. |
| 2 | Build unmodified Element X | Achieve first successful build of the unmodified project. Document exact Xcode version and macOS version. |
| 3 | Run on iOS Simulator | Launch the app on simulator, verify it reaches the login screen. |
| 4 | Verify all 3 targets build | Confirm: main app target, Notification Service Extension (NSE), and any other extension targets compile successfully. |

**Expected outcome:** Unmodified Element X builds and runs on simulator. Build environment documented.

---

### Day 3 — 4h | Codebase Study & Fork Planning
**Phase:** 1 (Project Setup)

| # | Task | Description |
|---|------|-------------|
| 1 | Study FORKING.md and documentation | Read Element's official forking guide. Understand recommended customization points vs. files that should not be modified. |
| 2 | Map all files requiring changes | Create a checklist of every file that needs modification for rebranding: `app.yml`, `AppSettings.swift`, `target.yml`, assets, strings, entitlements. |
| 3 | Study Compound design system | Understand how Element's Compound design tokens work. Identify where accent color, theme colors, and typography are defined. |
| 4 | Document architecture notes | Record key coordinator flows, service layers, and configuration injection points relevant to the fork. |

**Expected outcome:** Complete understanding of what needs to change and where. Fork modification checklist ready.

---

### Day 4 — 4h | Apple Developer Provisioning ⚙️
**Phase:** 1 (Project Setup)

| # | Task | Description |
|---|------|-------------|
| 1 | Create App ID in Apple Developer Portal | Register new bundle identifier (e.g., `com.customer.messenger`). Enable required capabilities: Push Notifications, App Groups, Associated Domains. |
| 2 | Create App Group | Register App Group identifier for shared data between main app and NSE (e.g., `group.com.customer.messenger`). |
| 3 | Generate certificates and profiles | Create development and distribution signing certificates. Create provisioning profiles for all targets. |
| 4 | Send design asset specifications to customer | Provide customer with exact requirements: app icon (1024×1024 PNG, no alpha, no rounded corners), accent color hex value, any splash screen assets. |

**Expected outcome:** Apple Developer provisioning complete. Design asset specs sent to customer. 🟡

---

### Day 5 — 4h | New Bundle ID Build 📋
**Phase:** 1 (Project Setup) + 2 (Licensing)

| # | Task | Description |
|---|------|-------------|
| 1 | Modify `app.yml` | Update bundle identifier, display name, app group ID, and development team ID in `app.yml`. |
| 2 | Update `target.yml` files | Update bundle identifiers in NSE and other extension `target.yml` files. Update entitlements references. |
| 3 | Regenerate and build | Run `xcodegen generate`, build the project with new identifiers. Fix any signing or entitlement issues. |
| 4 | **Licensing checkpoint #1** | Check for Element's licensing response. If no response, send follow-up. Document current licensing status. |

**Expected outcome:** Project builds with new bundle identifier and team. Licensing status documented.

**Licensing Checkpoint #1:** If no licensing response received, development continues with understanding that App Store publication is blocked until resolved. Escalation: send follow-up email, explore alternative contact channels.

---

## Week 2 — Branding & Server Configuration Start (Days 6–10)
**Phases:** 3 (Branding & Visual Identity) + 4 (Server Configuration & OIDC — start)
**Hours:** 20h

---

### Day 6 — 4h | App Icon & Colors 🟡
**Phase:** 3 (Branding)

| # | Task | Description |
|---|------|-------------|
| 1 | Replace app icon | Replace all icon assets in `Assets.xcassets` with customer's icon. Generate all required sizes (20pt through 1024pt) from the 1024×1024 source. |
| 2 | Update accent color | Modify Compound design tokens to use customer's accent color. Update `AccentColor` in asset catalog. Verify color propagation across light/dark mode. |
| 3 | Update `InfoPlist.strings` | Update `CFBundleDisplayName` (user-facing app name) across all 37+ supported locales. |
| 4 | Build and visual check | Build and run on simulator. Verify icon, accent color, and app name appear correctly on home screen and throughout the app. |

**Expected outcome:** App displays with customer's icon, accent color, and name.

---

### Day 7 — 4h | Launch Screen & String Cleanup
**Phase:** 3 (Branding)

| # | Task | Description |
|---|------|-------------|
| 1 | Update launch screen | Replace Element branding on launch/splash screen with customer's branding or neutral design. |
| 2 | Remove Element-specific branding strings | Search for and replace/remove Element-specific strings in user-facing text (about screen, settings, etc.). |
| 3 | Update legal URLs | Replace Element's privacy policy, terms of service, and other legal URLs with customer's URLs in `AppSettings.swift`. |
| 4 | Visual QA — branding screens | Navigate through settings, about, login, and other screens to ensure no Element branding remains. |

**Expected outcome:** All user-visible Element branding replaced with customer branding.

---

### Day 8 — 4h | Analytics, Configuration & Branding Checkpoint
**Phase:** 3 (Branding) + 4 (Server Config — start)

| # | Task | Description |
|---|------|-------------|
| 1 | Disable/reconfigure analytics | Remove or disable Element's analytics (PostHog). Remove MapTiler API key or replace with customer's. Review all third-party service configurations. |
| 2 | Begin `AppSettings.swift` server config | Set customer's homeserver URL as default. Update `pushGatewayNotifyEndpoint` to customer's Sygnal URL. Update `pusherAppID`. |
| 3 | Review feature flags | Audit feature flags in `AppSettings.swift`. Disable any features not applicable to the customer's deployment (e.g., Element-specific integrations). |
| 4 | Branding checkpoint commit | Create a Git checkpoint: "Branding complete". All visual identity changes are committed and tagged. |

**Expected outcome:** Analytics disabled, server configuration started, branding milestone committed.

---

### Day 9 — 4h | OIDC Configuration 🔴
**Phase:** 4 (Server Configuration & OIDC)

| # | Task | Description |
|---|------|-------------|
| 1 | Configure OIDC client settings | Update OIDC client ID and redirect URI in the app. Modify `OIDCConfiguration` or equivalent configuration to use customer's OIDC provider. |
| 2 | Update Associated Domains | Configure Associated Domains entitlement in `target.yml` for the customer's domain. This enables universal links for OIDC redirect. |
| 3 | Update entitlements files | Verify all entitlements (push, app group, associated domains) are correctly configured for all targets. |
| 4 | Configure `well-known` requirements | Document what the customer needs to host at `/.well-known/` on their domain for OIDC discovery and Matrix client auto-configuration. |

**Expected outcome:** OIDC configuration complete in code. Customer informed of server-side requirements.

---

### Day 10 — 4h | OIDC End-to-End Test 🔴
**Phase:** 4 (Server Configuration & OIDC)

| # | Task | Description |
|---|------|-------------|
| 1 | Test OIDC login on physical device | Attempt full OIDC authentication flow against customer's auth provider. Use a physical device (associated domains don't work reliably on simulator). |
| 2 | Debug authentication issues | If login fails: check redirect URI matching, associated domains configuration, OIDC client registration, SSL certificates. |
| 3 | Test session persistence | Verify the session persists after app restart. Test token refresh flow. |
| 4 | Test logout flow | Verify logout works correctly and clears session data. |

**Expected outcome:** User can log in, maintain session, and log out via customer's OIDC provider.

---

## Week 3 — Server Integration Complete & Push Notifications (Days 11–15)
**Phases:** 4 (Server Config — finish) + 5 (Push Notifications)
**Hours:** 20h

---

### Day 11 — 4h | Server Integration Testing 🔴 📋
**Phase:** 4 (Server Configuration — finish)

| # | Task | Description |
|---|------|-------------|
| 1 | Test E2EE messaging | Send encrypted messages between two accounts. Verify encryption indicators display correctly. |
| 2 | Test cross-device verification | Perform device verification flow (emoji verification or QR code). Ensure key backup/restore works. |
| 3 | Test media sending | Send and receive images, files, and voice messages. Verify media uploads to customer's media repository. |
| 4 | **Licensing checkpoint #2** | Review licensing status. If still no response from Element, escalate: consider phone call, alternative contacts, or discuss fallback plan with customer. |

**Expected outcome:** Core messaging features working against customer's server. Licensing status escalated if needed.

**Licensing Checkpoint #2:** If no licensing response after 2 weeks, discuss with customer: (a) continue development with accepted risk, (b) pause and wait, (c) evaluate alternative base project.

---

### Day 12 — 4h | APNs Setup ⚙️
**Phase:** 5 (Push Notifications)

| # | Task | Description |
|---|------|-------------|
| 1 | Generate APNs key | Create APNs authentication key (`.p8` file) in Apple Developer Portal. Record Key ID and Team ID. |
| 2 | Provide credentials to customer | Send APNs key, Key ID, Team ID, and bundle identifier to customer for Sygnal push gateway configuration. |
| 3 | Update push configuration in app | Verify `pushGatewayNotifyEndpoint` and `pusherAppID` are correctly set. Ensure push entitlement is enabled in provisioning profiles. |
| 4 | Test push token registration | Build on physical device, verify the app successfully registers for push notifications and obtains a device token. |

**Expected outcome:** APNs credentials generated, provided to customer. App registers for push successfully.

---

### Day 13 — 4h | Push Notification Testing 🔴
**Phase:** 5 (Push Notifications)

| # | Task | Description |
|---|------|-------------|
| 1 | Test push — app in foreground | Send a message from another account. Verify in-app notification appears while app is active. |
| 2 | Test push — app in background | Send a message while app is backgrounded. Verify system push notification appears in notification center. |
| 3 | Test push — app killed | Force-quit the app. Send a message. Verify push notification arrives and tapping it opens the correct conversation. |
| 4 | Verify push content | Check that notification displays sender name and message preview (or "New message" if encrypted). Verify notification actions work. |

**Expected outcome:** Push notifications delivered reliably in all 3 app states.

---

### Day 14 — 4h | NSE & Push Edge Cases 🔴
**Phase:** 5 (Push Notifications)

| # | Task | Description |
|---|------|-------------|
| 1 | Test NSE decryption | Verify the Notification Service Extension decrypts encrypted message content for notification display. |
| 2 | Test push edge cases | Test: rapid multiple messages, messages in different rooms, group chat notifications, thread replies. |
| 3 | Test notification settings | Verify per-room notification settings (mute, mentions-only) are respected. Test Do Not Disturb behavior. |
| 4 | Push notification checkpoint | Document any push-related issues. Create bug tickets for unresolved problems. Commit push configuration. |

**Expected outcome:** Push notifications fully functional including encrypted content display. Known issues documented.

---

### Day 15 — 4h | Buffer & Calls Preparation
**Phase:** 4/5 overflow + 6 (Calls — prep)

| # | Task | Description |
|---|------|-------------|
| 1 | Address Phase 4/5 overflow | Fix any remaining issues from server config or push notification testing. |
| 2 | Prepare Element Call requirements | Document what the customer needs for Element Call: LiveKit SFU server URL, Element Call web app deployment URL, TURN/STUN server configuration. |
| 3 | Verify calls infrastructure availability | Confirm with customer that Element Call / LiveKit infrastructure is ready for testing. |
| 4 | Code review and cleanup | Review all changes made in Weeks 1–3. Clean up temporary debugging code. Ensure all commits are well-organized. |

**Expected outcome:** Phases 4–5 issues resolved. Calls infrastructure requirements communicated. Codebase clean.

---

## Week 4 — Calls Configuration & Systematic Testing (Days 16–20)
**Phases:** 6 (Calls Configuration) + 7 (Testing & QA — start)
**Hours:** 20h

---

### Day 16 — 4h | Element Call Configuration 🔴
**Phase:** 6 (Calls Configuration)

| # | Task | Description |
|---|------|-------------|
| 1 | Configure Element Call URL | Set the Element Call web application URL in app configuration. Verify the embedded web view loads correctly. |
| 2 | Configure LiveKit endpoints | Set LiveKit SFU server URL if separately configurable. Configure TURN/STUN server credentials. |
| 3 | Test 1:1 voice call | Initiate a voice call between two accounts. Verify call connects, audio flows both directions. |
| 4 | Test 1:1 video call | Initiate a video call. Verify camera preview, remote video display, call controls (mute, camera toggle, hang up). |

**Expected outcome:** 1:1 voice and video calls functional.

---

### Day 17 — 4h | Group Calls & Call Polish 🔴
**Phase:** 6 (Calls Configuration)

| # | Task | Description |
|---|------|-------------|
| 1 | Test group calls | Initiate a group call with 3+ participants. Verify multi-party audio and video. |
| 2 | Test call UI | Verify call UI elements: participant tiles, speaking indicators, screen layout for multiple participants. |
| 3 | Test call notifications | Verify incoming call notifications appear when app is in background. Test call answering from notification. |
| 4 | Test call edge cases | Test: caller hangs up, recipient declines, network interruption during call, switching between audio/video. |

**Expected outcome:** Group calls working. Call UI and notifications functional. Edge cases documented.

---

### Day 18 — 4h | Test Plan & Auth/Messaging Suites
**Phase:** 7 (Testing & QA)

| # | Task | Description |
|---|------|-------------|
| 1 | Create comprehensive test plan | Write a structured test plan covering all features: auth, messaging, media, rooms, notifications, calls, settings. Define pass/fail criteria. |
| 2 | Execute auth test suite | Test: OIDC login, session persistence, token refresh, logout, re-login, multiple account scenarios if supported. |
| 3 | Execute messaging test suite | Test: 1:1 messages, group messages, E2EE verification, message editing, message deletion, reactions, threads. |
| 4 | Document test results | Record pass/fail for each test case. Create bug tickets for failures. |

**Expected outcome:** Auth and messaging systematically tested. Bugs logged.

---

### Day 19 — 4h | Media, Rooms, Notifications & Calls Suites
**Phase:** 7 (Testing & QA)

| # | Task | Description |
|---|------|-------------|
| 1 | Execute media test suite | Test: send/receive images (various sizes), files, voice messages, video messages. Test media download and preview. |
| 2 | Execute room management suite | Test: create room, invite users, join room, leave room, room settings, room notifications, room search. |
| 3 | Execute notification test suite | Full regression of push notifications across all states. Verify notification grouping and badges. |
| 4 | Execute calls test suite | Full regression of 1:1 and group calls. Verify call history display. |

**Expected outcome:** All feature areas systematically tested. Bug list updated.

---

### Day 20 — 4h | Device Compatibility & Bug Fixing 📋
**Phase:** 7 (Testing & QA)

| # | Task | Description |
|---|------|-------------|
| 1 | Device compatibility testing | Test on at least 2 device sizes (e.g., iPhone SE size and iPhone Pro Max size). Test on minimum supported iOS version. |
| 2 | iOS version testing | If possible, test on iOS 17 and latest iOS. Verify no version-specific crashes or layout issues. |
| 3 | Start bug fixes | Begin fixing highest-priority bugs found during Days 18–20 testing. |
| 4 | **Licensing checkpoint #3** | Verify licensing is resolved. If not, this is a hard block for App Store submission. Escalation: formal discussion with customer about project continuation. |

**Expected outcome:** Device compatibility verified. Critical bugs being fixed. Licensing status confirmed.

**Licensing Checkpoint #3:** Licensing MUST be resolved before App Store submission (Week 5–6). If unresolved, discuss with customer: delay submission or accept legal risk.

---

## Week 5 — Bug Fixes Complete & App Store Preparation (Days 21–25)
**Phases:** 7 (Testing — finish) + 8 (App Store Preparation)
**Hours:** 20h

---

### Day 21 — 4h | Bug Fixes & Regression
**Phase:** 7 (Testing & QA — finish)

| # | Task | Description |
|---|------|-------------|
| 1 | Fix remaining bugs | Address all critical and major bugs from testing. |
| 2 | Regression testing | Re-test areas affected by bug fixes to ensure no regressions. |
| 3 | Final visual QA pass | Complete walkthrough of all screens checking for: branding consistency, layout issues, dark mode support, dynamic type. |
| 4 | Testing sign-off | Mark test plan as complete. Document known issues (if any) with severity assessment. |

**Expected outcome:** All critical bugs fixed. Testing phase complete.

---

### Day 22 — 4h | App Store Connect Listing
**Phase:** 8 (App Store Preparation)

| # | Task | Description |
|---|------|-------------|
| 1 | Create App Store Connect record | Create new app in App Store Connect. Set bundle ID, SKU, primary language. |
| 2 | Write app description | Write compelling App Store description highlighting the app's features. Ensure it clearly differentiates from Element X (important for Guideline 4.3). |
| 3 | Set keywords and categories | Research and set relevant App Store keywords. Select primary and secondary categories (Social Networking / Productivity). |
| 4 | Set support URL and marketing URL | Configure customer's support URL. Add marketing URL if available. |

**Expected outcome:** App Store Connect listing created with description and metadata.

---

### Day 23 — 4h | Screenshots & Demo Content
**Phase:** 8 (App Store Preparation)

| # | Task | Description |
|---|------|-------------|
| 1 | Prepare demo content | Set up demo conversations with realistic (but non-sensitive) content for screenshots. Ensure branded elements are visible. |
| 2 | Capture 6.7" screenshots | Take required screenshots on iPhone Pro Max size (6.7"): login, conversation list, chat, call, settings — minimum 5 screens. |
| 3 | Capture 6.1" screenshots | Take required screenshots on standard iPhone size (6.1") — same screens. |
| 4 | Capture 5.5" screenshots (if needed) | If supporting older devices, capture 5.5" screenshots. Upload all screenshots to App Store Connect. |

**Expected outcome:** Screenshots for all required device sizes uploaded to App Store Connect.

---

### Day 24 — 4h | Privacy, Compliance & Content Moderation
**Phase:** 8 (App Store Preparation)

| # | Task | Description |
|---|------|-------------|
| 1 | Configure App Privacy labels | Complete App Store Connect privacy questionnaire. Declare data collection practices accurately (account info, messages, device identifiers). |
| 2 | Encryption declarations | Set `ITSAppUsesNonExemptEncryption` appropriately. If the app uses standard encryption (it does — E2EE via Matrix), may need to provide encryption documentation or select CCATS exemption. |
| 3 | Age rating questionnaire | Complete content rating questionnaire. Messaging apps typically require 12+ or 17+ depending on content moderation answers. |
| 4 | Verify Report/Block features | Ensure Report and Block functionality works correctly — this is critical for App Store approval of messaging apps. Test reporting a message and blocking a user. |

**Expected outcome:** All App Store compliance items configured. Content moderation verified.

---

### Day 25 — 4h | Archive & Upload ⚙️
**Phase:** 8 (App Store Preparation) + 9 (Release — start)

| # | Task | Description |
|---|------|-------------|
| 1 | Update version and build numbers | Set appropriate version (1.0.0) and build number. Verify version appears correctly in app settings. |
| 2 | Create archive build | Create release archive in Xcode with production signing. Verify no warnings or errors. |
| 3 | Upload to App Store Connect | Upload binary via Xcode Organizer or `altool`. Wait for App Store Connect processing (10–30 minutes). |
| 4 | Verify build in App Store Connect | Confirm the build appears in App Store Connect without processing issues. Check for any compliance warnings. |

**Expected outcome:** Release binary uploaded and processed in App Store Connect.

---

## Week 6 — TestFlight, Submission & Documentation (Days 26–30)
**Phases:** 9 (Release & App Store Submission) + 10 (Documentation & Handover)
**Hours:** 20h

---

### Day 26 — 4h | TestFlight Testing
**Phase:** 9 (Release & Submission)

| # | Task | Description |
|---|------|-------------|
| 1 | Enable TestFlight internal testing | Add the build to internal TestFlight testing group. Install via TestFlight on physical device. |
| 2 | Smoke test release build | Perform quick validation of core flows in the release build: login, send message, receive push, make call. |
| 3 | Check release-specific issues | Verify no debug artifacts remain. Check that analytics are properly disabled. Ensure no developer-only features are accessible. |
| 4 | External TestFlight (optional) | If customer wants to test before submission, add them to external TestFlight group. This requires a quick Beta App Review. |

**Expected outcome:** Release build validated via TestFlight. Ready for App Store submission.

---

### Day 27 — 4h | App Store Submission 📋
**Phase:** 9 (Release & Submission)

| # | Task | Description |
|---|------|-------------|
| 1 | Write App Review notes | Write clear review notes for Apple's App Review team. Proactively address Guideline 4.3 (explain how this app differs from Element X, who it serves, why it exists). |
| 2 | Provide demo credentials | Create demo account credentials for App Review. Ensure the demo account works reliably. |
| 3 | Submit for App Review | Submit the app for review in App Store Connect. Select manual release (so you can control when it goes live). |
| 4 | **Licensing checkpoint #4** | Final licensing verification before app goes live. Confirm license agreement is signed. If not signed, put release on hold. |

**Expected outcome:** App submitted to App Store Review. Licensing confirmed.

**Licensing Checkpoint #4:** Do NOT release the app publicly until licensing is confirmed in writing. TestFlight distribution may be acceptable while licensing is being finalized, but App Store publication requires confirmed license.

---

### Day 28 — 4h | Configuration Documentation
**Phase:** 10 (Documentation & Handover)

| # | Task | Description |
|---|------|-------------|
| 1 | Write configuration guide | Document how to change: branding (icon, colors, name), server URLs, OIDC settings, push configuration. Include exact file paths and code locations. |
| 2 | Write server requirements | Document all backend requirements: Matrix homeserver config, Sygnal setup with APNs credentials, OIDC client registration, Element Call/LiveKit setup, TURN/STUN. |
| 3 | Source code cleanup | Remove any temporary files, debug comments, or unused code. Ensure `.gitignore` is comprehensive. |
| 4 | Update README | Update the fork's README with project-specific build instructions, requirements, and configuration overview. |

**Expected outcome:** Configuration guide and server requirements documented. Source code cleaned.

---

### Day 29 — 4h | Maintenance Guide & Source Delivery
**Phase:** 10 (Documentation & Handover)

| # | Task | Description |
|---|------|-------------|
| 1 | Write maintenance guide | Document: how to update from upstream Element X, how to update signing certificates, how to push new builds, how to respond to App Store review issues. |
| 2 | Write troubleshooting guide | Document common issues and solutions: push not working, OIDC errors, build failures, certificate expiration. |
| 3 | Prepare source code delivery | Create clean archive of source code. Verify it builds from a clean checkout. Include all required configuration files. |
| 4 | Prepare handover checklist | List all credentials, accounts, and access to transfer: Apple Developer access, App Store Connect, Git repository, APNs keys. |

**Expected outcome:** All documentation complete. Source code ready for delivery.

---

### Day 30 — 4h | Review Response & Handover
**Phase:** 9 (Review cycles) + 10 (Handover)

| # | Task | Description |
|---|------|-------------|
| 1 | Check App Review status | If approved: proceed to handover. If rejected: analyze rejection reasons (see Weeks 7–8). |
| 2 | Handover meeting | Walk customer through: app functionality, documentation, source code, App Store Connect, certificate management. |
| 3 | Transfer access | Ensure customer has access to: Git repository, Apple Developer portal (if applicable), App Store Connect, all documentation. |
| 4 | Project sign-off | Obtain customer acknowledgment of deliverables. Document any remaining items for post-project resolution. |

**Expected outcome:** If approved — app live, handover complete. If in review — handover of all non-App-Store deliverables.

---

## Weeks 7–8 — Buffer: App Store Review Cycles (Days 31–40)
**Phase:** 9 (Review cycles — continued)
**Hours:** Up to 40h (used only as needed)

### Purpose

Apple's App Store review process is unpredictable, especially for:
- **First-time messaging apps** (content moderation scrutiny)
- **White-label/fork apps** (Guideline 4.3 — Design Spam)
- **Apps with encryption** (export compliance)

Expect **1–3 rejection/resubmission cycles**, each taking 2–5 business days for Apple's review.

### Common Rejection Patterns & Response Plan

| Rejection Reason | Likelihood | Response Time | Action Plan |
|-----------------|------------|---------------|-------------|
| **Guideline 4.3 — Design Spam** | High | 4–8h | Strengthen differentiation: unique description, distinct visual identity, clear business justification in review notes. Appeal if unjustified. |
| **Content moderation insufficient** | Medium | 2–4h | Verify Report/Block is prominent and functional. Add screenshots of moderation features to review notes. |
| **Privacy issues** | Medium | 2–4h | Review privacy labels for accuracy. Ensure privacy policy URL is valid and comprehensive. |
| **Encryption compliance** | Low | 1–2h | Provide encryption documentation. File for CCATS exemption if needed. |
| **Demo account issues** | Low | 1h | Ensure demo credentials work. Provide step-by-step testing instructions in review notes. |
| **Crashes during review** | Low | 4–8h | Analyze crash logs from App Store Connect. Fix, test, resubmit. |

### Buffer Day Allocation

| Day | Activity |
|-----|----------|
| 31–32 | Respond to first rejection (if any). Fix issues, resubmit. |
| 33–34 | Wait for second review cycle. |
| 35–36 | Respond to second rejection (if any). Fix issues, resubmit. |
| 37–38 | Wait for third review cycle. |
| 39 | Final fixes and resubmission (if needed). |
| 40 | Final handover after approval. Project closure. |

---

## Dependency Summary Table

| Dependency | Owner | Needed By | Request By | Impact If Late |
|-----------|-------|-----------|------------|----------------|
| **Element commercial license** | Customer + Developer | Day 27 (submission), ideally Day 1 | Day 1 (immediate) | **Critical.** Blocks App Store publication. Development can proceed but app cannot be legally published. |
| **Design assets** (icon, colors) | Customer | Day 6 | Day 1 (specs sent Day 4) | **Medium.** Blocks Phase 3. Can proceed with placeholders but delays branding sign-off. |
| **OIDC client registration** | Customer | Day 9 | Day 4 | **High.** Blocks Phase 4 authentication testing. Core feature cannot be verified. |
| **Matrix homeserver access** | Customer | Day 10 | Day 4 | **High.** Blocks all server-dependent testing (Days 10–20). |
| **Sygnal push gateway** | Customer | Day 12 | Day 8 | **High.** Blocks push notification testing (Days 13–14). |
| **APNs credentials to customer** | Developer | Day 12 | Day 12 (generated same day) | **Medium.** Customer needs to configure Sygnal. Allow 1–2 days for customer setup. |
| **Element Call / LiveKit server** | Customer | Day 16 | Day 8 | **Medium.** Blocks calls testing (Days 16–17). Calls can be deferred if infrastructure delayed. |
| **TURN/STUN server** | Customer | Day 16 | Day 8 | **Medium.** Calls may fail without TURN server, especially on mobile networks. |
| **App Store Connect access** | Developer | Day 22 | Day 1 (Apple Developer enrollment) | **Medium.** Blocks App Store preparation. Must be set up before Week 5. |
| **Demo account for App Review** | Customer | Day 27 | Day 25 | **Low.** Can be created quickly but must be verified working before submission. |

---

## Licensing Checkpoints

| Checkpoint | Day | Status Required | Escalation Action |
|-----------|-----|-----------------|-------------------|
| **#1** | Day 5 | Inquiry sent, awaiting response | Send follow-up email. Explore alternative contact channels (LinkedIn, Element community). |
| **#2** | Day 11 | Response received or escalated | If no response: phone/video call attempt. Discuss fallback plan with customer (alternative base project, accepted risk). |
| **#3** | Day 20 | License terms being negotiated or agreed | If no progress: formal decision point with customer. Pause App Store prep or accept risk. |
| **#4** | Day 27 | License agreement signed | Do NOT submit to App Store without confirmed license. TestFlight-only distribution may be acceptable interim. |

---

## Hours Allocation Summary

| Week | Days | Phase(s) | Planned Hours |
|------|------|----------|---------------|
| **Week 1** | 1–5 | Phase 1 (Setup) + Phase 2 (Licensing start) | 20h |
| **Week 2** | 6–10 | Phase 3 (Branding) + Phase 4 (Server Config start) | 20h |
| **Week 3** | 11–15 | Phase 4 (finish) + Phase 5 (Push Notifications) | 20h |
| **Week 4** | 16–20 | Phase 6 (Calls) + Phase 7 (Testing start) | 20h |
| **Week 5** | 21–25 | Phase 7 (finish) + Phase 8 (App Store Prep) | 20h |
| **Week 6** | 26–30 | Phase 9 (Submission) + Phase 10 (Docs & Handover) | 20h |
| **Weeks 7–8** | 31–40 | Phase 9 (Review cycles) + final handover | Up to 40h |
| | | **Core total** | **120h** |
| | | **With buffer** | **Up to 160h** |

### Cross-Reference with Preliminary Assessment

| Phase | Assessment Range | Allocated in Schedule | Notes |
|-------|-----------------|----------------------|-------|
| 1. Project Setup | 12–16h | 20h (Days 1–5) | Includes Phase 2 start (licensing). Extra time for thorough study. |
| 2. Licensing | 4–8h | Distributed across checkpoints | Active hours low; calendar impact high. |
| 3. Branding | 8–14h | 12h (Days 6–8) | |
| 4. Server Config + OIDC | 10–16h | 12h (Days 8–11) | Plus overflow on Day 15. |
| 5. Push Notifications | 9–12h | 12h (Days 12–15) | Day 15 is buffer/overflow. |
| 6. Calls | 6–10h | 8h (Days 16–17) | |
| 7. Testing & QA | 12–18h | 16h (Days 18–21) | |
| 8. App Store Prep | 10–14h | 16h (Days 22–25) | Includes initial archive/upload. |
| 9. Release & Submission | 8–14h | 8h (Days 26–27) + buffer | Review cycles in Weeks 7–8. |
| 10. Documentation | 6–10h | 12h (Days 28–30) | Includes handover meeting. |
| **Total** | **85–132h** | **120h + up to 40h buffer** | |

---

## Key Files Reference (by Week)

### Week 1 — Setup
- `project.yml` — Top-level project configuration
- `app.yml` — Bundle ID, display name, team ID, app group
- `target.yml` (all targets) — Entitlements references
- `FORKING.md` — Element's forking guide

### Week 2 — Branding & Server Config
- `Assets.xcassets` — App icon, accent color, launch screen assets
- `InfoPlist.strings` (37+ locales) — App display name
- `ElementX/Sources/Application/AppSettings.swift` — Homeserver URL, push gateway, pusher ID, legal URLs, feature flags, analytics
- OIDC configuration files — Client ID, redirect URI
- `target.yml` / entitlements — Associated domains

### Week 3 — Push Notifications
- `AppSettings.swift` — Push gateway endpoint, pusher app ID
- `NSE/Sources/NotificationServiceExtension.swift` — Notification Service Extension
- `NSE/SupportingFiles/target.yml` — NSE target configuration
- Entitlements — Push notification entitlement

### Week 4 — Calls & Testing
- Element Call configuration (URL, LiveKit endpoints)
- Test plan document (created during this week)

### Week 5 — App Store Preparation
- App Store Connect (web portal, not code files)
- Screenshots and marketing assets
- `Info.plist` — `ITSAppUsesNonExemptEncryption`

### Week 6 — Submission & Documentation
- `README.md` — Updated for the fork
- Configuration guide (new document)
- Maintenance guide (new document)
- Troubleshooting guide (new document)

---

*This schedule is based on the preliminary technical assessment (v1.0) and assumes all pre-conditions from Section 5 of that document are met. Actual progress depends on external dependency readiness and App Store review timelines.*

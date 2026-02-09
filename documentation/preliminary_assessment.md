# Preliminary Technical Assessment
## Element X iOS — Branded Fork for Customer's Matrix Infrastructure

**Document Version:** 1.0
**Date:** February 8, 2026
**Prepared by:** Saidakhror Murzaliev
**Status:** Draft — For Internal Review Before Client Presentation

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Project Overview](#2-project-overview)
3. [Source Project Technical Analysis](#3-source-project-technical-analysis)
4. [Critical TOR Discrepancies](#4-critical-tor-discrepancies)
5. [Pre-Conditions and Blockers](#5-pre-conditions-and-blockers)
6. [Work Breakdown Structure](#6-work-breakdown-structure)
7. [Timeline](#7-timeline)
8. [Cost Estimate](#8-cost-estimate)
9. [Risk Register](#9-risk-register)
10. [Recommendations and Next Steps](#10-recommendations-and-next-steps)
11. [Assumptions](#11-assumptions)

---

## 1. Executive Summary

This assessment evaluates the technical scope, effort, risks, and cost of creating a branded fork of **Element X iOS** — an open-source Matrix protocol messenger built with SwiftUI — and publishing it to the Apple App Store.

### Key Numbers

| Metric | Value |
|--------|-------|
| **Estimated effort** | 85–132 hours (expected ~108–120h) |
| **Timeline at 20h/week** | 6–8 weeks (realistic) |
| **Hourly rate** | $17/hr |
| **Expected cost (development only)** | $1,836–$2,040 |
| **Recommended fixed project price** | $2,000–$2,200 |

### Top 3 Blockers Requiring Immediate Resolution

1. **Licensing:** Element X iOS is licensed under AGPL v3, which is legally incompatible with Apple's App Store Terms of Service. A commercial license must be negotiated with Element (New Vector Ltd) before development begins — or an alternative base project must be identified.
2. **Push notification architecture mismatch:** The TOR specifies FCM (Firebase Cloud Messaging), but Element X iOS uses Apple Push Notification service (APNs) directly with no Firebase SDK present in the project. The customer must decide: keep APNs (recommended, lower effort) or require FCM integration (significant rework).
3. **iOS minimum version gap:** The TOR specifies iOS 16+. Element X iOS requires iOS 17+ (on older release tags) or iOS 18.5 (on the current `develop` branch). This constraint must be accepted or a different source tag selected.

---

## 2. Project Overview

### 2.1 Objectives

Deliver a rebranded, customer-configured version of the Element X iOS application published to the Apple App Store, including:

- Custom branding (app name, icon, bundle identifier, accent colors)
- Configuration for the customer's Matrix homeserver and identity server
- Push notification integration through the customer's Sygnal push gateway
- 1:1 and group voice/video calling support
- Full testing and quality assurance cycle
- App Store publication under the developer's Apple Developer account
- Source code delivery with build/deployment documentation

### 2.2 Out of Scope

- Backend infrastructure setup or maintenance (Matrix homeserver, Sygnal, TURN/STUN servers)
- New feature development beyond the existing Element X iOS functionality
- UI/UX design work (customer provides design assets)
- Android application
- Ongoing maintenance or post-launch support (unless separately agreed)
- Element commercial license negotiation fees

---

## 3. Source Project Technical Analysis

### 3.1 Project Identity

| Property | Value |
|----------|-------|
| **Project** | Element X iOS |
| **Repository** | github.com/element-hq/element-x-ios |
| **Language** | Swift (100%) |
| **UI Framework** | SwiftUI |
| **License** | AGPL v3 (see Section 4) |
| **Minimum iOS** | 17.0 (release tags) / 18.5 (develop branch) |

### 3.2 Codebase Metrics

| Metric | Value |
|--------|-------|
| **Swift source files** | ~907 |
| **Lines of code** | ~68,000 |
| **Architecture** | Coordinator-based MVVM |
| **Build system** | XcodeGen + Swift Package Manager (SPM) |
| **Design system** | Compound (Element's cross-platform design tokens) |
| **Core SDK** | Matrix Rust SDK (via Swift bindings, SPM package) |

### 3.3 Architecture Overview

Element X iOS follows a **Coordinator-based MVVM** pattern:

- **Coordinators** manage navigation flow and screen lifecycle. Each major feature has a coordinator that creates and wires together view models and views.
- **ViewModels** contain business logic and expose state to SwiftUI views via `@Observable` / `ObservableObject` patterns.
- **Views** are pure SwiftUI, consuming view model state.
- **Services** provide data access, network communication, and system integration (notifications, calls, analytics).

The application's core messaging functionality is provided by the **Matrix Rust SDK**, a cross-platform Rust library with generated Swift bindings distributed as a Swift Package. This means the messaging protocol logic is opaque — it cannot be modified at the Swift level without forking the Rust SDK.

### 3.4 Build System

The project uses **XcodeGen** to generate the Xcode project from YAML configuration files:

- **`project.yml`** — Top-level project configuration
- **`app.yml`** — Application target: display name, bundle identifier, app group ID, team ID
- **`target.yml`** (per-target) — Entitlements, associated domains, capabilities
- **`NSE/SupportingFiles/target.yml`** — Notification Service Extension configuration

After modifying YAML files, the Xcode project must be regenerated via `xcodegen generate`. Dependencies are managed through SPM and resolved at project generation time.

### 3.5 Key Configuration Files for Rebranding

| File | Configuration Points |
|------|---------------------|
| `app.yml` | Display name, bundle ID, app group, development team ID |
| `ElementX/Sources/Application/AppSettings.swift` | Default homeserver URL, OIDC redirect URI, push gateway endpoint (`pushGatewayNotifyEndpoint`), pusher app ID (`pusherAppID`), analytics keys, legal/policy URLs, feature flags |
| `target.yml` / entitlements | Associated domains (for universal links and OIDC), push notification entitlement, app group entitlement |
| Compound design tokens | Accent color, theme overrides. Element's Compound design system provides semantic color tokens across the app |
| `Assets.xcassets` | App icon, launch screen assets |
| `InfoPlist.strings` / Localizable strings | User-facing app name in all supported locales |

### 3.6 Push Notification Architecture

Element X iOS uses **APNs (Apple Push Notification service) directly**. Key implementation details:

- **No Firebase SDK** is present in the project. There is no `GoogleService-Info.plist`, no Firebase dependency in SPM packages.
- Device tokens are obtained via standard `UIApplication.registerForRemoteNotifications()` and converted to Base64 for registration with the Matrix push gateway.
- The pusher is registered with the homeserver using `appSettings.pushGatewayNotifyEndpoint` (the Sygnal gateway URL) and `appSettings.pusherAppID`.
- Push payload format: `eventIdOnly` — the Notification Service Extension (NSE) fetches full event content from the homeserver upon receipt.
- The NSE (`NSE/Sources/NotificationServiceExtension.swift`) handles rich notification content, decryption, and display.

### 3.7 Calls Architecture

Element X iOS uses **Element Call** (not Jitsi):

- **MatrixRTC** protocol for call signaling over the Matrix protocol
- **LiveKit** as the WebRTC media layer (SFU-based)
- Element Call is loaded as an embedded web view pointing to the Element Call web application
- Configuration requires a LiveKit-compatible SFU server and Element Call deployment, not a Jitsi Meet instance

### 3.8 Authentication

- Element X iOS supports **OIDC (OpenID Connect)** as the primary authentication method
- The OIDC redirect URI includes the app's bundle identifier and an Element-specific domain (`element.io`)
- Forking requires registering a new OIDC client with the customer's authentication provider and updating the redirect URI scheme
- **Associated Domains** entitlement must be configured for the customer's domain

---

## 4. Critical TOR Discrepancies

The following table identifies significant discrepancies between the Technical Requirements Document (TOR) and the actual Element X iOS implementation. These must be resolved before or during development.

| # | Area | TOR States | Actual Implementation | Severity | Impact |
|---|------|-----------|----------------------|----------|--------|
| 1 | **iOS Minimum Version** | iOS 16+ | iOS 17+ (release tags) or iOS 18.5 (develop branch) | **High** | Cannot support iOS 16. Must align on acceptable minimum version. Choosing an older release tag (iOS 17+) provides wider device coverage but means forking from older code. |
| 2 | **Push Notifications** | FCM (Firebase Cloud Messaging) | APNs directly, no Firebase SDK | **High** | If FCM is truly required: +8–12h of work to add Firebase SDK, rework token registration, and modify Sygnal configuration. Recommendation: use APNs (native, simpler, already implemented). |
| 3 | **Voice/Video Calls** | Jitsi integration | Element Call (MatrixRTC + LiveKit) | **Medium** | Customer's backend must provide a LiveKit-compatible SFU server and Element Call deployment instead of (or in addition to) Jitsi. No code change required on the iOS side if Element Call infrastructure is available. |
| 4 | **OIDC Redirect URLs** | Not mentioned | Hardcoded to `element.io` domain | **Medium** | Must register OIDC client with customer's auth provider. Redirect URI scheme in the app, entitlements, and associated domains must all be updated to match. |
| 5 | **License** | AGPL v3 (open source) | AGPL v3 — **incompatible with Apple App Store ToS** | **Critical** | Apple's App Store terms restrict redistribution rights that AGPL mandates. Publishing an AGPL-licensed app on the App Store creates a legal conflict. A **commercial license from Element (New Vector Ltd)** is required, or an alternative approach must be found. |
| 6 | **Scalar Integration Manager** | Referenced in TOR | Not present in Element X iOS | **Low** | Element X does not use the legacy Scalar integration manager. If integration manager functionality is needed, this would be a feature addition (out of scope). |

---

## 5. Pre-Conditions and Blockers

### 5.1 Hard Blockers (Must Be Resolved Before Development Starts)

| # | Blocker | Owner | Notes |
|---|---------|-------|-------|
| 1 | **AGPL v3 / App Store license resolution** | Customer + Developer | Contact Element (New Vector Ltd) about commercial licensing. Without this, App Store publication is legally problematic. |
| 2 | **iOS minimum version decision** | Customer | Accept iOS 17+ (wider reach) or iOS 18.5 (latest features, smaller audience)? This determines which source branch/tag to fork from. |
| 3 | **Push notification clarification** | Customer | Confirm: APNs (recommended) or FCM (requires significant additional work)? |
| 4 | **Calls infrastructure clarification** | Customer | Confirm customer will provide LiveKit SFU + Element Call deployment (not Jitsi). |

### 5.2 Soft Blockers (Can Be Resolved in Parallel with Early Development)

| # | Blocker | Owner | Notes |
|---|---------|-------|-------|
| 5 | **Design assets** | Customer | App icon (1024×1024), accent color hex values, splash screen assets. Must be provided in required Apple formats. |
| 6 | **Apple Developer Program account** | Developer | Active membership ($99/year) required. Enrollment can take 24–48h. |
| 7 | **Backend readiness** | Customer | Matrix homeserver, Sygnal push gateway, TURN/STUN servers, OIDC provider must all be operational and accessible. |
| 8 | **OIDC client registration** | Customer | Customer must register the new app as an OIDC client on their authentication provider and provide client ID, redirect URIs. |
| 9 | **Signing certificates and provisioning profiles** | Developer | Must be created in Apple Developer portal once account is active. |

---

## 6. Work Breakdown Structure

All estimates assume: solo developer, 20h/week, heavy Claude AI assistance, no Firebase SDK (APNs path), and no unforeseen blockers from external dependencies.

### Phase 1: Project Setup & Environment (12–16h)

| Task | Hours |
|------|-------|
| Fork Element X iOS repository, set up local development environment | 2–3 |
| Install and configure XcodeGen, resolve SPM dependencies | 2–3 |
| Achieve first successful build of unmodified Element X | 3–4 |
| Set up version control, branching strategy, CI basics | 2–3 |
| Familiarize with codebase architecture and key files | 3–3 |
| **Phase total** | **12–16** |

### Phase 2: Licensing & Legal Resolution (4–8h) ⛔ BLOCKER

| Task | Hours |
|------|-------|
| Research Element commercial licensing options | 2–3 |
| Draft and send licensing inquiry to Element (New Vector Ltd) | 1–2 |
| Review response, negotiate terms, document resolution | 1–3 |
| **Phase total** | **4–8** |

> **Note:** This phase involves significant wait time for Element's response (1–3 weeks). Active development hours are low, but the calendar impact is high. This phase should start immediately and run in parallel with Phase 1.

### Phase 3: Branding & Visual Identity (8–14h)

| Task | Hours |
|------|-------|
| Update `app.yml`: bundle ID, display name, app group, team ID | 1–2 |
| Replace app icon assets (all required sizes) | 1–2 |
| Update Compound design tokens: accent color, theme customization | 2–3 |
| Update splash/launch screen | 1–2 |
| Update `InfoPlist.strings` and user-facing strings (app name) | 1–1 |
| Regenerate Xcode project via XcodeGen, verify build | 1–2 |
| Visual QA across key screens | 1–2 |
| **Phase total** | **8–14** |

### Phase 4: Server Configuration & OIDC (10–16h)

| Task | Hours |
|------|-------|
| Update `AppSettings.swift`: default homeserver URL | 1–1 |
| Configure OIDC: client ID, redirect URI, associated domains | 3–5 |
| Update entitlements and `target.yml` for associated domains | 2–3 |
| Configure Sygnal push gateway endpoint in app settings | 1–2 |
| Test authentication flow end-to-end against customer's server | 3–5 |
| **Phase total** | **10–16** |

### Phase 5: Push Notifications (9–12h)

*Estimate assumes APNs path (recommended). See alternative below.*

| Task | Hours |
|------|-------|
| Generate APNs certificates/keys in Apple Developer portal | 1–2 |
| Configure Sygnal push gateway with APNs credentials | 2–3 |
| Update `pusherAppID` and `pushGatewayNotifyEndpoint` in app | 1–1 |
| Test push notification delivery (foreground, background, killed) | 3–4 |
| Test Notification Service Extension (rich notifications, decryption) | 2–2 |
| **Phase total (APNs path)** | **9–12** |

> **Alternative — FCM path (if customer insists on Firebase):**
>
> | Additional Task | Hours |
> |----------------|-------|
> | Add Firebase SDK via SPM, configure `GoogleService-Info.plist` | 2–3 |
> | Rework `NotificationManager` for FCM token handling | 4–6 |
> | Update Sygnal configuration for FCM | 2–3 |
> | Additional testing and debugging | 2–4 |
> | **Additional effort for FCM** | **+10–16** |
> | **Phase total (FCM path)** | **16–24** |

### Phase 6: Calls Configuration (6–10h)

| Task | Hours |
|------|-------|
| Verify Element Call integration points in codebase | 1–2 |
| Configure Element Call URL and LiveKit server endpoints | 2–3 |
| Test 1:1 voice/video calls | 1–2 |
| Test group calls | 1–2 |
| Debug and resolve call connectivity issues (TURN/STUN) | 1–1 |
| **Phase total** | **6–10** |

### Phase 7: Testing & Quality Assurance (12–18h)

| Task | Hours |
|------|-------|
| Functional testing: messaging (1:1, groups, E2EE) | 3–4 |
| Functional testing: media (images, files, voice messages) | 2–3 |
| Functional testing: push notifications (all states) | 2–2 |
| Functional testing: calls (1:1, group) | 2–2 |
| Device testing: multiple iOS versions and device sizes | 1–3 |
| Performance and memory testing | 1–2 |
| Bug fixes discovered during testing | 1–2 |
| **Phase total** | **12–18** |

### Phase 8: App Store Preparation (10–14h)

| Task | Hours |
|------|-------|
| Create App Store Connect listing | 2–3 |
| Prepare screenshots (minimum 2 device sizes × 5 screens) | 3–4 |
| Write app description, keywords, privacy policy URL | 2–3 |
| Configure age rating, content rights, encryption declarations | 1–1 |
| Prepare App Privacy details (data collection disclosures) | 1–2 |
| Ensure content moderation features (Report/Block) are functional | 1–1 |
| **Phase total** | **10–14** |

### Phase 9: Release & App Store Submission (8–14h)

| Task | Hours |
|------|-------|
| Create release build with production signing | 1–2 |
| TestFlight internal testing | 2–3 |
| Submit to App Store review | 1–1 |
| Respond to App Review rejections (expect 1–3 cycles) | 3–6 |
| Final release and verification | 1–2 |
| **Phase total** | **8–14** |

### Phase 10: Documentation & Handover (6–10h)

| Task | Hours |
|------|-------|
| Build and deployment documentation | 2–3 |
| Configuration guide (how to change branding, servers) | 2–3 |
| Source code cleanup, README update | 1–2 |
| Handover meeting/walkthrough | 1–2 |
| **Phase total** | **6–10** |

### Summary

| Phase | Optimistic | Pessimistic |
|-------|-----------|-------------|
| 1. Project Setup | 12h | 16h |
| 2. Licensing/Legal | 4h | 8h |
| 3. Branding | 8h | 14h |
| 4. Server Config + OIDC | 10h | 16h |
| 5. Push Notifications (APNs) | 9h | 12h |
| 6. Calls Configuration | 6h | 10h |
| 7. Testing & QA | 12h | 18h |
| 8. App Store Preparation | 10h | 14h |
| 9. Release & Submission | 8h | 14h |
| 10. Documentation & Handover | 6h | 10h |
| **Total** | **85h** | **132h** |

**Expected effort with reasonable buffer: ~108–120 hours**

---

## 7. Timeline

### 7.1 Week-by-Week Schedule (20h/week)

| Week | Phase(s) | Key Milestones | Hours |
|------|----------|----------------|-------|
| **Week 1** | Phase 1 (Setup) + Phase 2 (Licensing — start) | First successful build, licensing inquiry sent | 16–20h |
| **Week 2** | Phase 3 (Branding) + Phase 4 (Server Config — start) | Branded build running, OIDC configuration started | 18–20h |
| **Week 3** | Phase 4 (Server Config — complete) + Phase 5 (Push) | Authentication working, push notifications functional | 18–20h |
| **Week 4** | Phase 6 (Calls) + Phase 7 (Testing — start) | Calls working, systematic testing begins | 18–20h |
| **Week 5** | Phase 7 (Testing — complete) + Phase 8 (App Store Prep) | All features verified, App Store listing prepared | 18–20h |
| **Week 6** | Phase 9 (Submission) + Phase 10 (Docs — start) | TestFlight build, first App Store submission | 14–20h |
| **Week 7** | Phase 9 (Review cycles) + Phase 10 (Docs — complete) | Respond to review feedback, documentation delivered | 6–14h |
| **Week 8** | Buffer / additional review cycles | App Store approval (if not in week 7) | 0–10h |

### 7.2 Timeline vs. Customer Expectation

| | Customer Expectation | Realistic Estimate |
|---|---------------------|-------------------|
| **Development timeline** | 4–6 weeks | 6–8 weeks |
| **Including App Store review** | Included in 4–6 weeks | May add 1–3 additional weeks |

**Why the gap exists:**

1. **App Store review is unpredictable.** First-time submissions for messaging apps typically require 2–4 weeks including 1–3 rejection/resubmission cycles. Apple scrutinizes messaging apps for content moderation compliance and reviews white-label forks under Guideline 4.3 (Design Spam).
2. **External dependencies add wait time.** Licensing inquiry response (1–3 weeks), OIDC client registration, backend readiness — these create calendar delays independent of development speed.
3. **20h/week constraint.** At part-time pace, parallelization is limited. Full-time (40h/week) could compress the development-only portion to 3–4 weeks.

**The 4-week scenario is achievable only if:** all blockers are pre-resolved, APNs path is chosen, the customer's backend is fully ready, design assets are provided upfront, and App Store review passes on the first submission.

---

## 8. Cost Estimate

### 8.1 Rate

**Hourly rate: $17/hr** (Bishkek, Kyrgyzstan market rate for iOS developer with AI tooling assistance)

### 8.2 Development Cost Scenarios

| Scenario | Hours | Cost |
|----------|-------|------|
| **Optimistic** (no blockers, all goes smoothly) | 85h | $1,445 |
| **Expected** (normal issues, 1–2 review cycles) | 108–120h | $1,836–$2,040 |
| **Pessimistic** (FCM required, multiple review rejections) | 132h | $2,244 |

### 8.3 Recommended Fixed Project Price

**$2,000–$2,200**

This covers the expected scope with a reasonable buffer for normal project friction. It assumes the APNs path for push notifications and up to 2 App Store review cycles.

### 8.4 Items NOT Included in Development Cost

| Item | Estimated Cost | Paid By |
|------|---------------|---------|
| Apple Developer Program membership | $99/year | Developer (or Customer) |
| Element commercial license fee | TBD (negotiate with Element) | Customer |
| Backend infrastructure costs | Varies | Customer |
| Professional UI/UX design work | Varies | Customer |
| Ongoing maintenance post-launch | Separate agreement | TBD |
| App Store screenshots (if professional design needed) | Varies | Customer |

---

## 9. Risk Register

| # | Risk | Probability | Impact | Mitigation |
|---|------|-------------|--------|------------|
| 1 | **AGPL v3 / App Store legal conflict blocks publication** | High | Critical | Initiate licensing discussion with Element immediately. If commercial license is unavailable or too expensive, evaluate alternative Matrix iOS clients (e.g., older Element iOS under Apache 2.0). |
| 2 | **App Store rejection under Guideline 4.3 (Design Spam)** | Medium | High | Ensure the fork has sufficient visual differentiation from Element X. Add custom branding, unique App Store description, and clear differentiation in the review notes. Be prepared for appeal process. |
| 3 | **Customer insists on FCM instead of APNs** | Medium | Medium | Present APNs as technically superior for iOS (native, lower latency, no Firebase dependency). If FCM is required, adjust timeline by +1 week and budget by +$170–$270. |
| 4 | **Customer's backend not ready when development reaches integration phase** | Medium | High | Request backend readiness confirmation before starting Phase 4. Have the customer provide a staging environment early. If not ready, development will be blocked at week 2–3. |
| 5 | **OIDC configuration complexity exceeds estimate** | Medium | Medium | OIDC setup depends on the customer's auth provider. Non-standard providers may require debugging. Budget 50% contingency on Phase 4 estimates. |
| 6 | **Matrix Rust SDK version incompatibilities after fork** | Low | High | Pin the SDK version at fork time. Do not upgrade the Rust SDK unless necessary. Keep the fork as close to upstream as possible. |
| 7 | **Element Call / LiveKit infrastructure not available** | Medium | Medium | Clarify infrastructure requirements early. If customer can only provide Jitsi, calls feature would require significant rework (out of scope) or need to be disabled. |
| 8 | **Multiple App Store review rejection cycles** | High | Medium | Budget for 1–3 review cycles. Proactively address known review issues: encryption declaration (ITSAppUsesNonExemptEncryption), content moderation (Report/Block), privacy nutrition labels. |
| 9 | **Design assets delivered late or in wrong format** | Medium | Low | Provide asset specifications to customer in week 1 (sizes, formats, color space). Offer to proceed with placeholder branding while waiting. |
| 10 | **XcodeGen or SPM dependency resolution failures** | Low | Medium | Document the exact Xcode version and macOS version used. Pin all dependency versions. Keep a working build checkpoint after each phase. |

---

## 10. Recommendations and Next Steps

### Immediate Actions (Before Development Starts)

**Priority 1 — Licensing (Week 0)**
1. Contact Element (New Vector Ltd) regarding commercial licensing for an App Store fork of Element X iOS. This is the single most critical dependency.
2. If a commercial license is not feasible, evaluate:
   - Older Element iOS (UIKit-based, Apache 2.0 license) — more permissive but technically inferior
   - Other Matrix iOS clients with permissive licenses

**Priority 2 — Technical Clarifications (Week 0)**
3. Confirm with the customer: **APNs or FCM?** Recommend APNs. Explain that Element X uses APNs natively and FCM would add 10–16 hours of additional work.
4. Confirm with the customer: **Element Call (LiveKit) or Jitsi?** Element X supports Element Call only. If Jitsi is required, this is a feature development effort outside the fork scope.
5. Agree on **iOS minimum version**: iOS 17+ (recommended for device reach) or iOS 18.5 (latest code, narrower audience).

**Priority 3 — Preparation (Week 0–1)**
6. Request design assets from the customer: app icon (1024×1024 PNG, no alpha), accent color hex value, any color palette preferences.
7. Confirm the customer's backend infrastructure is operational: homeserver URL, Sygnal gateway URL, OIDC provider details, Element Call/LiveKit server URL.
8. Ensure Apple Developer Program membership is active.

### Development Start Criteria

Development should begin only after:
- [ ] Licensing path is confirmed (or risk explicitly accepted by customer)
- [ ] Push notification approach is agreed (APNs recommended)
- [ ] Calls infrastructure is clarified
- [ ] iOS minimum version is agreed
- [ ] At least placeholder design assets are available

---

## 11. Assumptions

This assessment is based on the following assumptions. If any assumption proves incorrect, estimates may need revision.

1. **APNs path is chosen** for push notifications (not FCM). If FCM is required, add 10–16 hours and ~$170–$270 to the estimate.
2. **No new features** are developed. The fork is strictly rebranding + reconfiguration of existing Element X iOS functionality.
3. **Customer's backend infrastructure** (Matrix homeserver, Sygnal, OIDC provider, TURN/STUN, Element Call/LiveKit) is fully operational and accessible during integration testing (Phases 4–6).
4. **Design assets** (icon, colors) are provided by the customer. No professional UI/UX design work is included.
5. **One language/locale** for the App Store listing. Multi-language localization of App Store metadata is not included.
6. **App Store review** will require 1–3 submission cycles. The estimate includes time for responding to review feedback.
7. **The Element X iOS source code** at the chosen tag/branch builds successfully on the developer's current Xcode/macOS setup without requiring upstream bug fixes.
8. **Solo developer** working 20 hours per week with AI-assisted development tooling (Claude Code).
9. **The commercial licensing question** with Element can be resolved within 1–3 weeks and does not block the overall project beyond week 2.
10. **The customer does not require** Scalar integration manager functionality, as it is not present in Element X iOS.

---

*This document is a preliminary assessment based on source code analysis and TOR review. Final estimates should be confirmed after all blockers in Section 5 are resolved and the customer has responded to the clarifications in Section 10.*

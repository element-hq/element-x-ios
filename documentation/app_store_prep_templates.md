# App Store Preparation Templates

> Pre-filled templates for App Store Connect submission, based on actual codebase analysis of Element X iOS fork.
> Items marked `[PLACEHOLDER]` require customer/developer input before submission.
>
> **Date:** 2026-02-12
> **Based on:** Element X iOS (Matrix Rust SDK v26.02.10, deployment target iOS 18.0)

---

## Table of Contents

1. [Export Compliance / Encryption Declaration](#1-export-compliance--encryption-declaration)
2. [Privacy Nutrition Labels](#2-privacy-nutrition-labels)
3. [App Review Notes](#3-app-review-notes)
4. [Age Rating Questionnaire](#4-age-rating-questionnaire)
5. [Guideline 4.3 Differentiation Strategy](#5-guideline-43-differentiation-strategy)

---

## 1. Export Compliance / Encryption Declaration

### Current State in Codebase

`Info.plist` line 64 declares:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

**This is likely incorrect for a shipping build.** The app uses end-to-end encryption (E2EE) via the Matrix Rust SDK (Olm/Megolm protocols). The `false` declaration was inherited from Element's development builds and must be reviewed before App Store submission.

### Encryption Usage Analysis

| Encryption Type | Source | Details |
|-----------------|--------|---------|
| **E2EE (Olm/Megolm)** | Matrix Rust SDK (opaque binary) | Full end-to-end encryption for Matrix rooms. Double Ratchet (Olm) for 1:1 key exchange, Megolm for group sessions. |
| **TLS/HTTPS** | Apple URLSession / ATS | All network communication uses TLS 1.2+ via Apple's standard networking stack. |
| **Keychain** | Apple Security framework | Stores session tokens, encryption keys. Uses Apple's built-in Keychain Services. |
| **SQLite encryption** | Matrix Rust SDK | Local message store may use encrypted SQLite (via Rust SDK internals). |

### ECCN Classification Guidance

The Matrix Rust SDK implements custom E2EE (not relying solely on Apple-provided or OS-level encryption). This means:

1. **The app uses non-exempt encryption** — `ITSAppUsesNonExemptEncryption` should be set to `YES` (`<true/>`)
2. **ECCN 5D002** likely applies — the app contains encryption functionality that goes beyond basic authentication and TLS
3. **Mass Market Exemption (EAR §740.17(b)(1))** — messaging apps with E2EE generally qualify for the "mass market" encryption exemption, meaning no individual export license is needed, but a self-classification report (SNAP-R / annual BIS submission) is required

### What to Declare in App Store Connect

**Export Compliance screen answers:**

| Question | Answer | Rationale |
|----------|--------|-----------|
| Does your app use encryption? | **Yes** | Matrix Rust SDK implements Olm/Megolm E2EE |
| Does your app qualify for any encryption exemptions? | **Yes** | Mass market exemption under EAR §740.17(b)(1) |
| Does your app implement or call any proprietary encryption algorithms? | **No** | Olm/Megolm are open-source, well-documented standard protocols |
| Does your app contain or call encryption only available from the operating system? | **No** | Custom E2EE is provided by the Matrix Rust SDK in addition to OS encryption |

### Required Actions Before Submission

- [ ] Change `ITSAppUsesNonExemptEncryption` from `false` to `true` in `Info.plist`
- [ ] File annual self-classification report with BIS (Bureau of Industry and Security) — submit via SNAP-R or email to `crypt@bis.doc.gov` and `enc@nsa.gov`
- [ ] Include CCATS number if obtained, or note mass market exemption on self-classification
- [ ] `[PLACEHOLDER]` Confirm with customer's legal team whether their jurisdiction requires additional encryption import/export declarations
- [ ] `[PLACEHOLDER]` If the customer is based in Russia, check current US export control regulations regarding EAR applicability — sanctions may affect ECCN classification

### Template: Self-Classification Report Entry

```
Product Name: [PLACEHOLDER — App Display Name]
Model/Version: 1.0.0
ECCN: 5D002
Item Type: Software
Submitter: [PLACEHOLDER — Legal Entity Name]
Manufacturer: [PLACEHOLDER — Legal Entity Name]
Technical Description: Mobile messaging application using Matrix protocol
  with end-to-end encryption (Olm/Megolm) via Matrix Rust SDK.
  Encryption is used for secure messaging between users.
Encryption Authorization Type: Mass Market (EAR §740.17(b)(1))
```

---

## 2. Privacy Nutrition Labels

### Source Data

Based on `ElementX/SupportingFiles/PrivacyInfo.xcprivacy` which declares 11 collected data types and 5 accessed API categories. All analytics (PostHog, Sentry) are opt-in. No tracking (`NSPrivacyTracking: false`).

### App Store Connect Privacy Label Answers

#### "Does this app collect data?"

**Yes** — but none for tracking, and analytics are opt-in only.

#### Data Types Collected

| # | App Store Category | App Store Data Type | Collected? | Linked to Identity? | Used for Tracking? | Purpose | Source / Evidence |
|---|-------------------|---------------------|------------|---------------------|-------------------|---------|-------------------|
| 1 | **Contact Info** | Email Address | Yes | Yes | No | App Functionality | User provides email during OIDC registration/login. Stored as part of Matrix user profile. |
| 2 | **Location** | Precise Location | Yes | Yes | No | App Functionality | Opt-in location sharing in chat. Requires explicit `NSLocationWhenInUseUsageDescription` permission. Only collected when user chooses to share location. |
| 3 | **Contacts** | Contacts | Yes | No | No | App Functionality | Optional contact access for user discovery. Not linked to identity in analytics. |
| 4 | **User Content** | Photos or Videos | Yes | No | No | App Functionality | User-initiated media sharing in conversations. Media is E2EE. |
| 5 | **User Content** | Audio Data | Yes | No | No | App Functionality | Voice messages in conversations. Audio is E2EE. |
| 6 | **Identifiers** | User ID | Yes | Yes | No | App Functionality, Analytics | Matrix user ID (`@user:server`). Linked to identity for app functionality. Pseudonymized for analytics (PostHog, opt-in only). |
| 7 | **Identifiers** | Device ID | Yes | Yes | No | App Functionality | Matrix device ID for E2EE key management and push notification delivery. |
| 8 | **Usage Data** | Product Interaction | Yes | No | No | Analytics | Opt-in only (PostHog). Screen views, feature usage. User must explicitly consent via analytics prompt. |
| 9 | **Diagnostics** | Crash Data | Yes | No | No | App Functionality | Crash logs via Sentry (opt-in). Not linked to identity. |
| 10 | **Diagnostics** | Performance Data | Yes | No | No | Analytics | Opt-in performance metrics via PostHog/Sentry. |
| 11 | **Diagnostics** | Other Diagnostic Data | Yes | Yes | No | App Functionality | Rageshake bug reports (user-initiated). May contain logs linked to user session. |

#### Data NOT Collected

The following App Store categories are **not collected** by the app:

- Health & Fitness (no health data)
- Financial Info (no payment processing)
- Sensitive Info (no biometric data beyond FaceID/TouchID for app lock, which is processed on-device only)
- Browsing History (no web browsing)
- Search History (room search is local only)
- Purchases (no in-app purchases)
- Advertising Data (no ad SDKs)

#### Key Disclaimers for App Store Connect

| Aspect | Declaration | Notes |
|--------|------------|-------|
| **Tracking** | No | `NSPrivacyTracking` is `false`. No ATT prompt needed. |
| **Third-party analytics** | PostHog (opt-in) | Only active if user consents. Controlled by `analyticsConsentState` in AppSettings. Customer may disable by not providing PostHog API keys. |
| **Third-party crash reporting** | Sentry (opt-in) | Grouped with analytics consent. Customer may disable by not providing Sentry DSN. |
| **E2EE message content** | Not collected by app/developer | Messages are E2EE — the app developer cannot access message content. Server operator (customer) manages the homeserver. |

### Customer-Specific Adjustments

- [ ] `[PLACEHOLDER]` If customer disables PostHog (no API key in Secrets): remove "Analytics" purpose from User ID, remove Product Interaction and Performance Data rows entirely
- [ ] `[PLACEHOLDER]` If customer disables Sentry (no DSN in Secrets): remove Crash Data row or change to "not collected"
- [ ] `[PLACEHOLDER]` If customer disables Rageshake (no URL in Secrets): remove Other Diagnostic Data row
- [ ] `[PLACEHOLDER]` If customer disables location sharing feature: remove Precise Location row
- [ ] `[PLACEHOLDER]` Confirm whether customer's homeserver collects any additional data server-side that should be disclosed

---

## 3. App Review Notes

### Template for App Store Connect "Notes for Review"

```
REVIEW NOTES — [PLACEHOLDER — App Name]

1. ABOUT THIS APP
[PLACEHOLDER — App Name] is a secure messaging application for
[PLACEHOLDER — Organization Name]'s internal communications.
It connects to a dedicated Matrix homeserver operated by
[PLACEHOLDER — Organization Name].

This app is a branded deployment of the Element X iOS open-source
messenger, customized for organizational use with a private
Matrix server infrastructure.

2. TEST ACCOUNT
Please use the following credentials to test the app:

  Server: [PLACEHOLDER — Homeserver URL, e.g., matrix.example.com]
  Username: [PLACEHOLDER — Test username]
  Password: [PLACEHOLDER — Test password]

Authentication uses OIDC (OpenID Connect). After entering the
server, you will be redirected to the organization's identity
provider login page. Enter the credentials above.

Note: The test account has been pre-configured with sample
conversations and contacts for review purposes.

3. KEY FEATURES TO TEST
- Login via OIDC authentication
- Send and receive text messages (end-to-end encrypted)
- Send photos, videos, voice messages
- Create and manage rooms/conversations
- Push notifications (may not work in review environment)
- User profile management
- Room/user search

4. ENCRYPTION
This app implements end-to-end encryption using the Matrix
protocol (Olm/Megolm). Messages are encrypted on-device and
can only be read by intended recipients. The developer and
server operator cannot access encrypted message content.

5. WHY THIS APP EXISTS SEPARATELY
[PLACEHOLDER — App Name] is purpose-built for
[PLACEHOLDER — Organization Name]'s communication needs.
It differs from Element X in:
- Connects exclusively to [PLACEHOLDER — Organization Name]'s
  private Matrix server
- Custom branding, icon, and color scheme
- Pre-configured for the organization's OIDC identity provider
- [PLACEHOLDER — Any additional differentiators]

See also: Guideline 4.3 differentiation details in the
App Description section.

6. SPECIAL CONFIGURATION
- The app requires network access to
  [PLACEHOLDER — Homeserver domain] for Matrix protocol
  communication
- OIDC authentication redirects to
  [PLACEHOLDER — OIDC provider domain]
- Push notifications route through
  [PLACEHOLDER — Push gateway domain (Sygnal)]
```

### Guideline Risk Assessment

| Guideline | Risk Level | Mitigation |
|-----------|-----------|------------|
| **4.3 Design Spam** | **HIGH** | Must demonstrate clear differentiation from Element X. See Section 5 below. Private server, custom branding, organizational use case are key arguments. |
| **2.1 App Completeness** | Low | Provide working test account. Ensure all features work during review. |
| **2.3.1 Hidden Features** | Low | No hidden features. Developer Options are debug-only (`appBuildType == .debug`). |
| **5.1.1 Data Collection** | Low | Privacy labels accurately reflect actual data collection. All analytics opt-in. |
| **5.1.2 Data Use and Sharing** | Low | E2EE means developer cannot access message content. |
| **4.2 Minimum Functionality** | Low | Full-featured messenger with E2EE, media sharing, calls, spaces. |
| **2.5.1 Software Requirements** | Low | Only uses public APIs. No private frameworks. |
| **3.1 Payments** | None | No in-app purchases, subscriptions, or payment processing. |

### Pre-Review Checklist

- [ ] Test account created on customer's homeserver and verified working
- [ ] Test account has pre-populated conversations (at least 2-3 rooms with messages)
- [ ] OIDC login flow works end-to-end from fresh install
- [ ] Push notifications verified (or noted as "requires specific network" in review notes)
- [ ] App launches to login screen (no crash on first launch)
- [ ] All permission prompts have clear, user-friendly descriptions
- [ ] No debug/development UI visible in release build
- [ ] `developerOptionsEnabled` defaults to `false` for release builds (confirmed in AppSettings.swift line 449)
- [ ] `[PLACEHOLDER]` Screenshot set prepared for all required device sizes
- [ ] `[PLACEHOLDER]` App Store description written (see Section 5 for differentiation language)

---

## 4. Age Rating Questionnaire

### App Store Connect Age Rating Answers

Based on analysis of app features, content capabilities, and user interaction patterns.

| Question | Answer | Rationale |
|----------|--------|-----------|
| **Cartoon or Fantasy Violence** | None | No violent content in the app itself. User-generated content is E2EE and not moderated by the app. |
| **Realistic Violence** | None | No violent content. |
| **Prolonged Graphic or Sadistic Realistic Violence** | None | Not applicable. |
| **Profanity or Crude Humor** | None | No profanity in the app UI. User messages are E2EE. |
| **Mature/Suggestive Themes** | None | No suggestive content in the app. |
| **Horror/Fear Themes** | None | Not applicable. |
| **Medical/Treatment Information** | None | Not applicable. |
| **Alcohol, Tobacco, or Drug Use or References** | None | Not applicable. |
| **Simulated Gambling** | None | No gambling features. |
| **Sexual Content or Nudity** | None | No sexual content in app UI. |
| **Unrestricted Web Access** | No | App does not contain a general-purpose web browser. Link previews (when enabled) open in external browser. |
| **Gambling with Real Currency** | No | No gambling. |

### Interactive Elements

| Element | Present? | Details |
|---------|----------|---------|
| **Unrestricted Internet** | No | App communicates only with configured Matrix homeserver and related services. |
| **User-Generated Content (Sharing)** | Yes | Users can share text, images, videos, audio, files, and location with other users. All content is E2EE. |
| **User-Generated Content (Social)** | Yes | Chat rooms, direct messages, spaces. Users create and name rooms. |
| **Contest** | No | No contests. |
| **In-App Purchases** | No | No IAP. |

### Recommended Age Rating

| Rating | Justification |
|--------|--------------|
| **12+** (Recommended) | Infrequent/Mild User-Generated Content. The app enables messaging between users; content moderation is server-side (customer's responsibility). 12+ is standard for messaging apps with user-generated content. |
| 4+ (Alternative) | Only appropriate if the customer's server has strict content moderation AND the app is limited to a controlled organizational environment. Apple may challenge this. |
| 17+ | Not needed unless the customer explicitly wants unrestricted content. |

### Customer Decision Required

- [ ] `[PLACEHOLDER]` Customer confirms target age rating (recommended: 12+)
- [ ] `[PLACEHOLDER]` If 4+ is desired: document server-side content moderation measures for Apple
- [ ] `[PLACEHOLDER]` Customer confirms whether user blocking/reporting features (present in codebase: `ignoreUser`, `reportContent`) are sufficient for their content moderation policy

### Content Moderation Features Present in Codebase

| Feature | Status | Location |
|---------|--------|----------|
| Block/Ignore User | Implemented | `JoinedRoomProxy.swift`, `RoomMemberDetailsViewModel` |
| Report Content | Implemented | `ReportContentScreenViewModel` |
| Hide Ignored User Profiles | Enabled by default | `AppSettings.swift:389` (`hideIgnoredUserProfiles = true`) |
| Server-side moderation | Customer responsibility | Homeserver admin tools, Mjolnir/Draupnir bots |
| Content filtering | Not implemented in app | Must be handled server-side if needed |

---

## 5. Guideline 4.3 Differentiation Strategy

### The Risk

Apple App Store Review Guideline 4.3 ("Design: Spam") states:

> Don't create multiple Bundle IDs of the same app. If your app has different versions for specific locations, sports teams, universities, etc., consider submitting a single app and provide the variations using in-app purchase.

Element X is already on the App Store. A branded fork must demonstrate **clear, meaningful differentiation** to avoid 4.3 rejection.

### Differentiation Arguments

#### 1. Dedicated Infrastructure (Technical Differentiation)

| Aspect | Element X (Original) | `[PLACEHOLDER — App Name]` (This Fork) |
|--------|---------------------|----------------------------------------|
| Default server | matrix.org (public) | `[PLACEHOLDER — Customer's homeserver]` (private) |
| Authentication | Public OIDC (element.io) | Private OIDC (`[PLACEHOLDER — Customer's OIDC provider]`) |
| User base | Open to anyone | `[PLACEHOLDER — Organization Name]` employees/members only |
| Push gateway | Element's Sygnal | `[PLACEHOLDER — Customer's Sygnal instance]` |
| Data residency | Element's infrastructure | `[PLACEHOLDER — Customer's hosting location/jurisdiction]` |

**Key argument:** This app cannot connect to matrix.org. It is configured exclusively for a private Matrix deployment. Users of Element X cannot access this organization's server, and users of this app have no reason to use Element X.

#### 2. Visual Differentiation (Brand Identity)

| Element | Element X | `[PLACEHOLDER — App Name]` |
|---------|-----------|---------------------------|
| App icon | Element green "E" logo | `[PLACEHOLDER — Customer's icon]` |
| Accent color | Element green (#0DBD8B) | `[PLACEHOLDER — Customer's brand color]` |
| App name | Element X | `[PLACEHOLDER — App Display Name]` |
| Launch screen | Element logo | `[PLACEHOLDER — Customer's logo]` |
| About/Legal URLs | element.io | `[PLACEHOLDER — Customer's website]` |

**Key argument:** The app is visually distinct. No Element branding remains. A user would not confuse this app with Element X.

#### 3. Functional Differentiation (Use Case)

```
Element X is a general-purpose Matrix messenger for the public Matrix
network. [PLACEHOLDER — App Name] is a purpose-built secure
communication tool for [PLACEHOLDER — Organization Name].

The differences include:
- [PLACEHOLDER — App Name] connects only to the organization's
  private server — it cannot be used with any other Matrix server
- Account creation is managed by the organization's IT department
  through their OIDC identity provider
- The app is distributed to [PLACEHOLDER — approximate user count]
  users within the organization
- [PLACEHOLDER — Any custom feature flags, disabled features, or
  organization-specific configuration]
```

#### 4. Precedent

Element's own `docs/FORKING.md` explicitly supports and documents the forking process. The Element X codebase is designed for white-label deployments — `app.yml` provides clean configuration injection, `AppSettings.swift` externalizes all brand-specific values, and the Compound design system supports theme customization.

Other Matrix clients exist as separate App Store listings (FluffyChat, Schildichat, Beeper). The Matrix ecosystem intentionally supports multiple client implementations connecting to different server infrastructures.

### App Store Description Template

```
[PLACEHOLDER — App Name] — Secure Messaging for [PLACEHOLDER — Organization Name]

[PLACEHOLDER — App Name] is the official secure messaging app for
[PLACEHOLDER — Organization Name]. Communicate with your colleagues
using end-to-end encrypted messages, voice calls, and file sharing.

FEATURES:
• End-to-end encrypted messaging
• Voice and video calls
• File, photo, and location sharing
• Group conversations and Spaces
• Cross-device message sync
• Biometric app lock (Face ID / Touch ID)

SECURITY:
All messages are end-to-end encrypted using the Matrix protocol.
Only you and your intended recipients can read your messages.

REQUIREMENTS:
This app requires a [PLACEHOLDER — Organization Name] account.
Contact your IT department for access.

Built on the Matrix open communication protocol.
```

### Rejection Response Template

If Apple rejects under Guideline 4.3, use this response template:

```
Dear App Review Team,

Thank you for your review of [PLACEHOLDER — App Name].

We respectfully note that [PLACEHOLDER — App Name] is a distinct
application from Element X, not a duplicate. The differences are
substantial:

1. DIFFERENT SERVER INFRASTRUCTURE
   [PLACEHOLDER — App Name] connects exclusively to
   [PLACEHOLDER — Organization Name]'s private Matrix server at
   [PLACEHOLDER — Homeserver URL]. It cannot connect to matrix.org
   or any public server. Element X users cannot access our
   organization's server.

2. DIFFERENT AUTHENTICATION
   Our app authenticates against [PLACEHOLDER — Organization Name]'s
   private OIDC provider at [PLACEHOLDER — OIDC URL]. User accounts
   are managed by our organization's IT department.

3. DIFFERENT USER BASE
   This app serves [PLACEHOLDER — approximate user count] members of
   [PLACEHOLDER — Organization Name]. These users have no use for
   Element X, as it cannot reach our private infrastructure.

4. DIFFERENT VISUAL IDENTITY
   The app has a completely different icon, color scheme, name, and
   branding. No Element branding appears anywhere in the app.

5. OPEN-SOURCE ECOSYSTEM PRECEDENT
   Element X (AGPL v3) is designed for white-label deployments.
   The project includes official forking documentation
   (docs/FORKING.md). Multiple Matrix clients already exist as
   separate App Store listings (FluffyChat, Schildichat, etc.),
   demonstrating that the Matrix ecosystem supports distinct
   client applications.

We would be happy to provide any additional information or
schedule a call to discuss the differentiation.

Best regards,
[PLACEHOLDER — Developer Name]
```

---

## Appendix: Pre-Submission Checklist

### Technical Requirements

- [ ] Bundle ID set to `[PLACEHOLDER — Bundle ID]`
- [ ] Team ID set to `[PLACEHOLDER — Team ID]`
- [ ] `ITSAppUsesNonExemptEncryption` changed to `true`
- [ ] All `element.io` URLs replaced with customer's URLs
- [ ] OIDC redirect URI configured and working
- [ ] Push notifications tested end-to-end
- [ ] Privacy manifests up-to-date in all 3 targets (Main App, NSE, ShareExtension)
- [ ] Release build tested on physical device
- [ ] No debug UI accessible in release configuration

### App Store Connect

- [ ] App name registered: `[PLACEHOLDER — App Name]`
- [ ] Bundle ID registered: `[PLACEHOLDER — Bundle ID]`
- [ ] Privacy policy URL: `[PLACEHOLDER — Privacy Policy URL]`
- [ ] Support URL: `[PLACEHOLDER — Support URL]`
- [ ] Marketing URL (optional): `[PLACEHOLDER — Website URL]`
- [ ] App category: Social Networking
- [ ] Secondary category (optional): Business
- [ ] Age rating questionnaire completed (see Section 4)
- [ ] Privacy nutrition labels completed (see Section 2)
- [ ] Export compliance completed (see Section 1)
- [ ] Screenshots uploaded for required device sizes
- [ ] App description in primary language
- [ ] `[PLACEHOLDER]` App description in Russian (if targeting Russian App Store)
- [ ] Keywords set
- [ ] Review notes provided (see Section 3)
- [ ] Test account credentials provided to Apple

### Legal

- [ ] `[PLACEHOLDER]` AGPL v3 commercial license obtained from Element (New Vector Ltd)
- [ ] `[PLACEHOLDER]` BIS self-classification report filed for encryption
- [ ] `[PLACEHOLDER]` Customer's privacy policy covers all data types in Section 2
- [ ] `[PLACEHOLDER]` Customer's terms of service URL configured in app

---

*This document should be reviewed and updated after customer decisions are finalized. All `[PLACEHOLDER]` items must be filled in before App Store submission.*

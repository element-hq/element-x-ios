# Project Overview — Element X iOS Branded Fork

> **Purpose of this file:** Quick-reference context document for AI assistants and developers joining this project. Read this first, then drill into specific documents as needed.

---

## What Is This Project?

A **branded fork** of [Element X iOS](https://github.com/element-hq/element-x-ios) — an open-source Matrix protocol messenger built with SwiftUI — to be published on the Apple App Store under the customer's brand.

**In one sentence:** Take Element X iOS, replace branding, point it at the customer's Matrix server, and publish it.

---

## Project Documents

| File | Language | Purpose |
|------|----------|---------|
| `TOR.docx` / `tor.md` | Russian | Technical Requirements Document (TOR) from the customer — defines what they want |
| `preliminary_assessment.md` | English | Developer's technical assessment — analyzes the actual codebase, identifies discrepancies with TOR, estimates effort |
| `implementation_plan.md` | English | Day-by-day working schedule (30 days + 10 buffer days) |
| `implementation_plan_ru.md` | Russian | Same implementation plan, direct translation |
| `customer_pre_dev_briefing_ru.md` | Russian | Customer-facing briefing: blockers, prerequisites, timeline reality, action items |
| `customer_questionnaire_init_stage.md` | Russian | Developer's conversation guide for initial customer meeting (with licensing deep-dive) |
| `decisions_tracker.md` | Russian | Living tracker of all open decisions and blockers (12 items) |
| `ios_proj_init.md` | English | Technical 15-step init plan: fork → build env → branding → localization → config → first branded build |
| `project_overview.md` | English | **This file** — quick orientation |

---

## Key Facts

| Aspect | Detail |
|--------|--------|
| **Source project** | Element X iOS (`github.com/element-hq/element-x-ios`) |
| **Language** | Swift (100%), SwiftUI |
| **Architecture** | Coordinator-based MVVM |
| **Build system** | XcodeGen + Swift Package Manager |
| **Core SDK** | Matrix Rust SDK (Swift bindings via SPM) |
| **Design system** | Compound (Element's cross-platform design tokens) |
| **License** | AGPL v3 (**critical issue** — see below) |
| **iOS minimum** | iOS 17+ (release tags) or iOS 18.5 (develop branch) |
| **Estimated effort** | 85–132h, expected ~120h |
| **Schedule** | 20h/week, 4h/day, 6 weeks + 2 buffer = 8 weeks max |
| **Rate** | $17/hr |
| **Expected cost** | $2,000–$2,200 fixed |

---

## Critical Issues (TOR vs. Reality)

The TOR was written with assumptions that don't match the actual Element X iOS codebase. These discrepancies are fully analyzed in `preliminary_assessment.md` Section 4.

| # | TOR Says | Reality | Severity | Resolution |
|---|----------|---------|----------|------------|
| 1 | **iOS 16+** | iOS 17+ (release tags) / iOS 18.5 (develop) | High | Accept iOS 17+ — customer must agree |
| 2 | **FCM (Firebase)** for push | **APNs directly** — no Firebase SDK in project | High | Use APNs (recommended, native, simpler). FCM would add +10–16h |
| 3 | **Jitsi** for calls | **Element Call** (MatrixRTC + LiveKit) | Medium | Customer's backend must provide LiveKit SFU, not Jitsi |
| 4 | OIDC not mentioned | OIDC redirect hardcoded to `element.io` | Medium | Must register OIDC client with customer's auth provider |
| 5 | AGPL v3 = open source | **AGPL v3 incompatible with App Store ToS** | **Critical** | Commercial license from Element (New Vector Ltd) required |
| 6 | Scalar integration manager | Not present in Element X | Low | Element X doesn't use Scalar. Out of scope if needed |

---

## What the Customer Provides

| Item | Status | Notes |
|------|--------|-------|
| Matrix homeserver | Must be operational | URL needed for `AppSettings.swift` |
| OIDC provider | Must be operational | Client registration needed |
| Sygnal push gateway | Must be operational | APNs credentials provided by developer |
| Element Call / LiveKit SFU | Must be operational | For voice/video calls |
| TURN/STUN servers | Must be operational | For call connectivity on mobile networks |
| Design assets (icon, colors) | Must provide | 1024x1024 PNG (no alpha), accent color hex |
| `.well-known` hosting | Must configure | On customer's domain for OIDC + Matrix discovery |
| Demo account for App Review | Must create | Working credentials for Apple's reviewers |

## What the Developer Provides

| Item | Notes |
|------|-------|
| Apple Developer account ($99/yr) | Active enrollment required |
| Fork, rebranding, configuration | Core development work |
| APNs key generation | Generated in Apple Developer Portal, shared with customer for Sygnal |
| App Store listing + submission | Under developer's account |
| TestFlight testing | Internal + optional external with customer |
| Documentation + source handover | Configuration guide, maintenance guide, troubleshooting |

---

## Key Files to Modify (in Element X iOS)

| File | What Changes |
|------|-------------|
| `app.yml` | Bundle ID, display name, app group, team ID |
| `AppSettings.swift` | Homeserver URL, OIDC redirect URI, push gateway endpoint, pusher app ID, analytics keys, legal URLs, feature flags |
| `target.yml` / entitlements | Associated domains, push entitlement, app group entitlement |
| `Assets.xcassets` | App icon, accent color, launch screen assets |
| `InfoPlist.strings` (37+ locales) | User-facing app name (`CFBundleDisplayName`) |
| Compound design tokens | Accent color, theme overrides |
| OIDC configuration | Client ID, redirect URI |
| `NSE/SupportingFiles/target.yml` | Notification Service Extension bundle ID, entitlements |

---

## Architecture Quick Reference

```
Element X iOS
├── Coordinators          — Navigation flow, screen lifecycle
│   └── Each feature has a coordinator
├── ViewModels            — Business logic, @Observable state
├── Views                 — Pure SwiftUI
├── Services              — Data access, networking, system integration
│   ├── NotificationManager    — Push registration, token handling
│   ├── AppSettings            — All configurable values
│   └── ...
├── Matrix Rust SDK       — Core messaging (opaque, can't modify at Swift level)
├── NSE (Extension)       — Notification Service Extension for rich push
├── Compound              — Design system tokens
└── Build System
    ├── project.yml       — XcodeGen top-level
    ├── app.yml           — App target config
    └── target.yml        — Per-target entitlements
```

---

## Push Notification Flow

```
Message sent → Matrix Homeserver → Sygnal Push Gateway → APNs → iOS Device
                                   (customer runs)        (Apple)

App registers device token → Homeserver pushers API
                             (pushGatewayNotifyEndpoint + pusherAppID)

NSE receives push → Fetches full event → Decrypts (E2EE) → Displays notification
```

**Key point:** No Firebase involved. APNs directly. The TOR specifies FCM but the assessment recommends APNs (already implemented, simpler, native).

---

## Calls Flow

```
Call initiated → MatrixRTC signaling → Element Call (embedded WebView)
                                       → LiveKit SFU → WebRTC media

NOT Jitsi. Element X uses Element Call exclusively.
Customer must provide: LiveKit SFU server + Element Call web deployment.
```

---

## Schedule Summary

| Week | Days | Focus |
|------|------|-------|
| 1 | 1–5 | Project setup, first build, licensing inquiry, Apple Developer provisioning |
| 2 | 6–10 | Branding (icon, colors, name), server config, OIDC setup |
| 3 | 11–15 | Auth testing, APNs setup, push notification testing |
| 4 | 16–20 | Calls config, systematic testing begins |
| 5 | 21–25 | Bug fixes, App Store listing, screenshots, binary upload |
| 6 | 26–30 | TestFlight, App Store submission, documentation, handover |
| 7–8 | 31–40 | Buffer: App Store review cycles, rejection responses |

**Licensing checkpoints:** Days 5, 11, 20, 27

---

## Risk Summary

| Risk | Probability | Impact |
|------|-------------|--------|
| AGPL / App Store legal conflict | High | Critical |
| App Store rejection (Guideline 4.3 — Design Spam) | Medium | High |
| Customer's backend not ready | Medium | High |
| OIDC complexity exceeds estimate | Medium | Medium |
| Element Call infrastructure unavailable | Medium | Medium |
| Multiple App Store review rejections | High | Medium |

---

## Assumptions

1. APNs path (not FCM)
2. No new features — fork is strictly rebrand + reconfigure
3. Customer's backend is operational during integration (Weeks 2–4)
4. Customer provides design assets
5. Single language for App Store listing
6. 1–3 App Store review cycles
7. Source code builds successfully on developer's current Xcode/macOS
8. Solo developer, 20h/week, AI-assisted (Claude Code)
9. Licensing resolved within 1–3 weeks
10. No Scalar integration manager needed

---

## Glossary

| Term | Meaning |
|------|---------|
| **Element X** | Modern Matrix client by Element, written in Swift/SwiftUI |
| **Matrix** | Open standard for decentralized, encrypted communication |
| **Homeserver** | The Matrix server that stores accounts and messages |
| **Sygnal** | Matrix push notification gateway |
| **Compound** | Element's cross-platform design system (colors, typography) |
| **XcodeGen** | Tool that generates `.xcodeproj` from YAML config files |
| **OIDC** | OpenID Connect — authentication protocol |
| **NSE** | Notification Service Extension — iOS extension for rich push notifications |
| **MatrixRTC** | Matrix protocol for real-time communication (calls) |
| **LiveKit** | WebRTC SFU server used by Element Call |
| **Sliding Sync** | Modern Matrix sync protocol for faster initial loads |
| **AGPL v3** | GNU Affero General Public License — copyleft license requiring source disclosure |
| **Guideline 4.3** | Apple's App Store rule against "Design Spam" (near-duplicate apps) |
| **TOR** | Technical Requirements Document (Техническое задание) |

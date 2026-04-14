# Project Context — Element X iOS Branded Fork

## Project Type

**iOS/Swift/SwiftUI project.** Ignore all Flutter/Dart skills, agents, and commands.

### Slash Commands (`.claude/commands/`)

- `/git-commit`, `/git-push`, `/commit-push-pr` — Git workflows
- `/xcodegen-build` — Regenerate xcodeproj + build for iPhone 17 Pro simulator
- `/upstream-sync`, `/audit-branding`, `/create-checkpoint [name]`, `/rebrand-execute`, `/decision-status`

### Axiom Skills (use `axiom:ask` to auto-route)

`axiom-ios-build` (build failures), `axiom-xcode-debugging` (BUILD FAILED), `axiom-build-debugging` (SPM), `axiom-localization`, `axiom-privacy-ux`, `axiom-apple-docs`, `axiom-ios-testing`, `axiom-app-composition`, `axiom-ios-networking`, `axiom-codable`, `axiom-swift-concurrency`

---

## What This Is

Branded fork of **Element X iOS** (Matrix messenger, SwiftUI) → publish on App Store as **UCMeet.Chat**. Rebrand + reconfigure only. No new features.

**Developer:** Saidakhror Murzaliev (solo, 20h/week, AI-assisted)
**Customer:** Russian-speaking, existing Matrix infrastructure

## Current State (as of 2026-04-05)

**App Store submission imminent.** ASC listing complete except screenshots (expected from customer). Push E2E verified on TestFlight. CallKit deferred to next sprint (Element Call widget issue). AGPL confirmation expected after upcoming call. Sprint 6 (TestFlight & Publication) in progress.

### Configuration Applied

| Setting | Value |
|---------|-------|
| Bundle ID | `org.ucmeet.UCMeetChat` (cascaded through 22 files, registered in Apple Developer Portal) |
| App Group | `group.org.ucmeet` |
| Team ID | `6HRG779SDK` |
| Display Name | `UCMeet.Chat` |
| Homeserver | `matrix.ucmeet.org` |
| Push Gateway | `https://push.ucmeet.org` (Sygnal, `type: apns`). App uses direct APNs tokens (not Firebase) |
| Push Provider | `.apns` (switched from `.firebase` — Sygnal's GCM pushkin incompatible with APNs payload format) |
| OIDC | Custom URL scheme `org.ucmeet.UCMeetChat:/callback` — login verified working |
| Calls | URL scheme `org.ucmeet.call`, LiveKit via `.well-known` |
| Locales | en, en-US, ru (trimmed from 37) |
| Accent Color | Dark navy blue #003B5D (Compound design tokens overridden — all green→navy blue) |
| Xcode Signing | Resolved — customer's Apple ID in Xcode, automatic signing works |
| Firebase | Real GoogleService-Info.plist installed (project `matrix-8c24a`), APNs key uploaded |
| MapLibre | API key `iKPA4bK9zgtadTEw8neu` configured. Interactive maps work. Static map previews show "Invalid key" — free MapTiler plan doesn't include Static Maps API |
| Pusher App IDs | `org.ucmeet.UCMeetChat.ios.prod` (release) / `.ios.dev` (debug) |
| NSE Entitlement | `com.apple.developer.usernotifications.filtering` removed (requires Apple approval, not available for our bundle ID) |
| Encryption | `ITSAppUsesNonExemptEncryption = YES` in plist, encryption compliance document uploaded to ASC |
| Analytics | Disabled (PostHog, Sentry, rageshake all set to `nil`) |
| APP_NAME | `UCMeet.Chat` (was `ElementX` — fixed OIDC system dialog) |
| Permalinks | `ucmatrix.org` (replaced `matrix.to` — blocked in Russia). Outgoing links, mentions, share URLs all use `ucmatrix.org`. Incoming `ucmatrix.org` links parsed via `UCMatrixPermalinkParser` |
| Upstream | Synced with `element-hq/element-x-ios:develop` (60 ahead, 0 behind) |

### Version 1.0.1 Build 1 Changes (2026-04-13)

1. **Permalinks: matrix.to → ucmatrix.org** — All outgoing permalinks (room shares, user profiles, mentions, event/message links, room aliases, "Copy link") now use `ucmatrix.org` instead of `matrix.to` (blocked in Russia). Added `URL.replacingMatrixToHost()` helper. Added `UCMatrixPermalinkParser` for incoming `ucmatrix.org` link handling. Files changed: URL.swift, AppRoutes.swift, JoinedRoomProxy.swift, MatrixUserShareLink.swift, RoomMemberProxyProtocol.swift, UserProfileScreenViewModel.swift, ComposerToolbarViewModel.swift, AttributedStringBuilder.swift

### Build 4 → Build 5 Changes (2026-03-27)

1. **Push: Firebase → APNs** — `pushProvider` default changed from `.firebase` to `.apns` in AppSettings.swift. App registers APNs device token directly instead of FCM token. Sygnal uses `type: apns` with .p8 key. Firebase SDK stays in project.
2. **Send button gradient** — `gradientActionStop1-4` overridden to navy blue in CompoundHook.swift (was green)
3. **4 more Russian translations** — "Sharing options", "No space selected", "Do not add to a space", "Add to space"

### Previous Build Changes (Build 2 → Build 4)

- OIDC dialog: `APP_NAME: ElementX` → `UCMeet.Chat`
- Analytics/bug reports disabled (PostHog, Sentry, rageshake all `nil`)
- MapTiler key configured, location sharing enabled
- 14 Russian translations added/fixed
- Navy blue color overrides (24 SwiftUI + 23 UIKit tokens)
- Test infrastructure: `PRODUCT_MODULE_NAME`, `TEST_HOST` fixes

### Remaining Blockers

1. **Screenshots** — customer needs to provide screenshots (6.5" iPhone + 13" iPad) — expected in coming days
2. **AGPL v3 licensing** — need written confirmation (expected after upcoming call). Then add source code link in app.
3. **CallKit** — DEFERRED to next sprint. Element Call widget not sending `m.rtc.notification` events. App-side code is ready. Requires Element Call update.

### Resolved Since Last Update

- ~~Push E2E testing~~ — **VERIFIED** on TestFlight build (2026-03-28)
- ~~Privacy Nutrition Labels~~ — **COMPLETED** in ASC (2026-04-03)
- ~~Review contact details~~ — **ENTERED** in ASC (2026-04-03)
- ~~Pricing~~ — **Set to Free** in ASC (2026-04-03)
- ~~Privacy policy + support URLs~~ — **ENTERED** in ASC (2026-04-03)

### Post-Launch Tasks

1. ~~**ucmatrix.org**~~ — **DONE** (2026-04-13). Replaced `matrix.to` → `ucmatrix.org` in 7 files: URL helper, AppRoutes (incoming parser), JoinedRoomProxy, MatrixUserShareLink, RoomMemberProxyProtocol, UserProfileScreenViewModel, ComposerToolbarViewModel, AttributedStringBuilder
2. **CallKit** — update Element Call widget to send `m.rtc.notification` events
3. **MapTiler** — customer decision on paid plan for static map previews

> See `decisions_tracker.md` for all 12 tracked decisions: 9 resolved, 1 in progress, 2 deferred.

---

## Source Project Facts

| Fact | Value |
|------|-------|
| Upstream | `element-hq/element-x-ios` (synced Feb 11, SDK v26.02.10) |
| Architecture | Coordinator-based MVVM, SwiftUI, ~68k LOC, ~907 Swift files |
| Build system | XcodeGen (`project.yml`, `app.yml`, `target.yml`) + SPM |
| Core SDK | Matrix Rust SDK v26.02.10 (opaque binary, **cannot modify**) |
| License | AGPL v3 |
| iOS minimum | 18.0 |
| Push | APNs + Firebase SDK (FCM, 14 unit tests) |
| Calls | Element Call (MatrixRTC + LiveKit) |
| Auth | OIDC via MAS |

## Key Files

```
app.yml                    → Bundle ID, display name, team ID, app group
AppSettings.swift          → Homeserver, OIDC, push gateway, analytics, legal URLs, feature flags
target.yml / entitlements  → Associated domains, push, app group
Assets.xcassets            → App icon, accent color
GoogleService-Info.plist   → Firebase config
```

---

## Working Rules

- **No new features.** Rebrand + reconfigure only.
- **Do not modify Matrix Rust SDK** — opaque binary.
- **Never edit `.xcodeproj` directly** — edit YAML, then `xcodegen generate`.
- **Keep fork minimal** — every change increases upstream merge difficulty.
- Customer docs → **Russian**. Code/technical docs → **English**.
- Track decisions in `decisions_tracker.md`. Update after customer interactions.
- **Before modifying any file:** Read it first.
- **When a decision is unresolved:** Do not guess. Flag it and ask.

### Git

- Branching: `main` (releases) + `develop` (active, default) + `upstream` remote
- Tag `checkpoint/unmodified-build` at `7c96ebfca`, `checkpoint/branding-complete` at `caf1d6872`
- Commit format: imperative, concise (match upstream style)

---

## Build Environment

| Tool | Version |
|------|---------|
| Xcode | 26.2 |
| XcodeGen | 2.44.1 |
| Firebase SDK | 11.8.x |
| Simulator | iPhone 17 Pro |
| git-lfs, gh CLI | installed |

---

## Documentation Index

All docs in `documentation/` folder:

**Core:** `project_overview.md`, `tor.md`, `preliminary_assessment.md`, `decisions_tracker.md`, `change_map.md`

**Development:** `ios_proj_init.md` (15-step plan), `implementation_plan.md`, `firebase_integration.md`, `pre_rebranding_preparations.md`, `build_and_handover_guide.md`, `sprints.md`, `dev_plan.md`, `overall_implementation_progress.md`

**Audits:** `oidc_audit.md`, `branding_audit.md`, `nse_audit.md`, `share_extension_audit.md`, `hardcoded_identifiers_inventory.md`, `element_call_audit.md`, `privacy_manifest_audit.md`, `upstream_sync_report.md`

**App Store:** `app_store_prep_templates.md`, `appstore_connect_guide.md`

**Customer:** `customer_pre_dev_briefing_ru.md`, `customer_questionnaire_init_stage.md`

**Progress:** `progress_log.md` (detailed daily log)

---

## Phase Progression

- [x] Phase 0: Planning
- [x] Phase 1: Project Setup (fork, build, audit, branding, config, OIDC, calls, localization)
- [ ] Phase 2: Licensing (AGPL confirmation pending)
- [x] Phase 3: Branding (complete — UCMeet.Chat, logos, accent color)
- [x] Phase 4: Server Config + OIDC (complete — login working)
- [~] Phase 5: Push Notifications (code done, Firebase configured, APNs key uploaded. E2E blocked on customer Sygnal config)
- [x] Phase 6: Calls (complete — LiveKit confirmed)
- [ ] Phase 7: Testing & QA
- [ ] Phase 8: App Store Prep
- [ ] Phase 9: Release
- [ ] Phase 10: Documentation & Handover

### Sprint Status

| Sprint | Status | Notes |
|--------|--------|-------|
| 1: Environment Setup & Fork | **DONE** | |
| 2: Branding & Basic Functionality | **DONE** | MapLibre interactive maps work, static previews need MapTiler permission |
| 3: Push + OIDC + Associated Domains | **DONE** | APNs via Sygnal working. Push E2E verified on TestFlight. CallKit deferred (Element Call widget issue) |
| 4: Calls & UCMeet Call | **DONE** | |
| 5: Finalization & Release Prep | **DONE** | NSE entitlement fix, upstream sync, version set to 1.0.0 (Build 2) |
| 6: TestFlight & Publication | **IN PROGRESS** | ASC listing complete except screenshots. Privacy Labels done. Review notes updated. Pricing set. Waiting: screenshots + AGPL confirmation |

### Summary Metrics

| Metric | Value |
|--------|-------|
| Plan completion | ~99% code, waiting for screenshots + AGPL confirmation |
| Hours invested | ~104h of ~120h budget |
| Hours remaining | ~6–10h (Build 5 upload, AGPL link, submission, review response) |
| Decisions resolved | 9/12 |
| Unit tests | 962 run, 899 passed, 63 pre-existing failures, 0 new |
| User-visible Element branding | **0** |
| Upstream divergence | 60 ahead, 0 behind element-hq/element-x-ios |

---

*Last updated: 2026-04-13. See `documentation/progress_log.md` for detailed daily log.*

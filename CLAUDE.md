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

## Current State (as of 2026-03-24)

**Build 3 in preparation.** Customer tested Build 2 and reported 6 issues — all fixed. Sprint 6 (TestFlight & Publication) in progress. Customer switching from ntfy to Sygnal for push gateway.

### Configuration Applied

| Setting | Value |
|---------|-------|
| Bundle ID | `org.ucmeet.UCMeetChat` (cascaded through 22 files, registered in Apple Developer Portal) |
| App Group | `group.org.ucmeet` |
| Team ID | `6HRG779SDK` |
| Display Name | `UCMeet.Chat` |
| Homeserver | `matrix.ucmeet.org` |
| Push Gateway | Customer switching from ntfy to Sygnal. Sygnal credentials provided (APNs key, pusher app IDs, Firebase JSON). Awaiting Sygnal URL |
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
| Upstream | Synced with `element-hq/element-x-ios:develop` (60 ahead, 0 behind) |

### Build 2 → Build 3 Changes (2026-03-24)

1. **OIDC dialog fix** — `APP_NAME: ElementX` → `UCMeet.Chat` in `project.yml`
2. **Analytics disabled** — PostHog, Sentry set to `nil` in Secrets.swift
3. **Bug reports disabled** — rageshake URL set to `nil`
4. **MapTiler key configured** — `iKPA4bK9zgtadTEw8neu` (static previews need paid plan)
5. **Russian translations** — 13 keys added, 1 fixed (`screen_roomlist_your_spaces`)
6. **Navy blue color overrides** — 20 SwiftUI + 19 UIKit Compound tokens overridden in CompoundHook.swift

### Remaining Blockers

1. **Push E2E testing** — customer switching from ntfy to Sygnal. Credentials provided (APNs key, pusher app IDs, Firebase JSON). Awaiting Sygnal URL
2. **MapTiler static maps** — free plan shows "Invalid key" on static previews. Customer deciding: upgrade to paid plan ($25/mo) or leave as-is
3. **AGPL v3 licensing** — need written confirmation it covers Element X (blocks App Store only)
4. **Screenshots** — customer needs to provide device-framed screenshots from TestFlight (6.7" + 5.5")
5. **Privacy Nutrition Labels** — questionnaire not yet completed in ASC
6. **Review contact details** — need first name, last name, email from customer

### Next Actions (waiting on customer)

1. Customer: configure Sygnal with provided credentials + confirm Sygnal URL
2. Customer: decide on MapTiler paid plan for static map previews
3. Customer: written AGPL license confirmation
4. Customer: provide screenshots from TestFlight with device frames
5. Customer: provide review contact name + email

> See `decisions_tracker.md` for all 12 tracked decisions: 7 resolved, 3 in progress, 2 open.

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
| 3: Push + OIDC + Associated Domains | **BLOCKED** | Push gateway URL confirmed (`https://push.ucmeet.org`), E2E test attempted, FCM token rejected by ntfy. Customer must check ntfy logs |
| 4: Calls & UCMeet Call | **DONE** | |
| 5: Finalization & Release Prep | **DONE** | NSE entitlement fix, upstream sync, version set to 1.0.0 (Build 2) |
| 6: TestFlight & Publication | **IN PROGRESS** | Build 3 prep: 6 customer issues fixed (OIDC name, analytics, bug reports, maps, translations, colors). Remaining: screenshots, Privacy Nutrition Labels, review contact, push E2E |

### Summary Metrics

| Metric | Value |
|--------|-------|
| Plan completion | ~98% code + listing, blocked on customer for screenshots + push E2E + MapTiler decision |
| Hours invested | ~92h of ~120h budget |
| Hours remaining | ~10–15h (Build 3 upload, push testing, privacy labels, release) |
| Decisions resolved | 7/12 |
| Unit tests | 962 run, 899 passed, 63 pre-existing failures, 0 new |
| User-visible Element branding | **0** |
| Upstream divergence | 60 ahead, 0 behind element-hq/element-x-ios |

---

*Last updated: 2026-03-24. See `documentation/progress_log.md` for detailed daily log.*

# Project Context — Element X iOS Branded Fork

## Project Type

**This is an iOS/Swift/SwiftUI project.** Ignore all Flutter/Dart skills, agents, and commands.

### Slash Commands (in `.claude/commands/`)

**Git workflows:**
- `/git-commit` — Stage changes and commit with a good message
- `/git-push` — Push current branch to origin
- `/commit-push-pr` — Commit, push, and open a PR in one step

**Project workflows:**
- `/xcodegen-build` — Regenerate xcodeproj from YAML + build for iPhone 17 Pro simulator
- `/upstream-sync` — Fetch upstream Element X changes, analyze conflicts, guide merge
- `/audit-branding` — Search for remaining Element brand references, categorize by priority
- `/create-checkpoint [name]` — Create annotated `checkpoint/*` tag (planned names from ios_proj_init.md)
- `/rebrand-execute` — Run rebrand scripts with safety gates (requires D-001 resolved)
- `/decision-status` — English summary of all 12 decisions from the tracker

### Axiom Plugin Skills (relevant to this project)

Use `axiom:ask` to auto-route any iOS/Swift question. Key skills for this rebrand project:

| Skill | When to use |
|-------|------------|
| `axiom:axiom-ios-build` | Build failures, Xcode issues |
| `axiom:axiom-xcode-debugging` | BUILD FAILED, simulator hangs |
| `axiom:axiom-build-debugging` | SPM resolution failures, dependency conflicts |
| `axiom:axiom-localization` | String Catalogs, internationalization (37 locales) |
| `axiom:axiom-privacy-ux` | Privacy manifests, App Store compliance |
| `axiom:axiom-apple-docs` | Apple framework API references |
| `axiom:axiom-ios-testing` | Unit test issues |
| `axiom:axiom-app-composition` | App entry point / auth flow changes |
| `axiom:axiom-ios-networking` | Push notification debugging |
| `axiom:axiom-codable` | JSON config / encoding issues |
| `axiom:axiom-swift-concurrency` | async/await, actors, Sendable issues |

---

## What This Is

A branded fork of **Element X iOS** (open-source Matrix messenger, SwiftUI) to be published on Apple App Store under a customer's brand. The project is: rebrand + reconfigure + publish. No new features.

**Developer:** Saidakhror Murzaliev (solo, 20h/week, AI-assisted with Claude Code)
**Customer:** Russian-speaking, has existing Matrix infrastructure

## Current Phase

**Phase 1: Project Setup — partially complete.** Fork created, build environment configured, first build succeeded, codebase audit complete, git branching structure established.

**What's done:**
- Fork created and pushed to `smurzaliev/custom-element-messenger-ios`
- Build environment: Xcode 26.2, XcodeGen 2.44.1, git-lfs, `gh` CLI v2.86.0
- First build succeeded on iPhone 17 Pro simulator (Xcode 26.2)
- Full codebase audit (5 parallel agents): identity, branding, config, localization, strings
- Change map compiled → `documentation/change_map.md`
- Git structure: `main` (releases) + `develop` (active, default) + `upstream` (element-hq)
- Tag `checkpoint/unmodified-build` at commit `7c96ebfca` (last upstream commit before fork changes)
- Claude Code slash commands for git workflows in `.claude/commands/`
- Build re-verified on 2026-02-10 — still succeeds on iPhone 17 Pro (Xcode 26.2, iOS 26.2 simulator), only pre-existing upstream warnings
- Customer outreach documents reviewed and finalized (2026-02-10):
  - `customer_questionnaire_init_stage.md` — all 12 decisions D-001–D-012 mapped to questions, Apple Developer account (D-007) added to final checklist
  - `customer_pre_dev_briefing_ru.md` — Apple Developer account added to Priority 1 actions and Week 0 deliverables
- Cross-check complete: every decision has a clear path to resolution via the questionnaire
- Firebase FCM unit tests added (2026-02-11): 14 tests across 3 test files, all passing. Protocol extraction (`FirebaseNotificationServiceProtocol`) enables mock injection into `AppCoordinator`. Full details in `documentation/firebase_integration.md`
- Pre-rebranding audits complete (2026-02-11): 5 audit documents covering OIDC flow, Compound design system, NSE, ShareExtension, and 97 hardcoded identifiers across 35+ files. See `documentation/pre_rebranding_preparations.md` for summary.
- Rebranding automation scripts created (2026-02-11): `scripts/rebrand.sh` (712 lines, handles all text substitutions) and `scripts/rebrand_strings.sh` (560 lines, handles 37-locale string replacement). Both dry-run tested. Estimated rebranding time reduced from 4-8 hours to 1-2 hours.
- Additional audits completed (2026-02-11): Element Call infrastructure (MatrixRTC + LiveKit, 8 hardcoded refs, disabling options), privacy manifest compliance (B+ grade, 2 gaps identified), upstream sync report (18 new commits, SDK v26.02.10, 3-4 file conflicts)
- Fixed bash 3.2 compatibility bug in `rebrand_strings.sh` — replaced `declare -A` associative arrays with bash 3.2-compatible variables (macOS default shell)
- Privacy manifest gaps fixed (2026-02-11): Added `NSPrivacyAccessedAPICategoryNetworkInformation` to Main App and NSE manifests, created ShareExtension `PrivacyInfo.xcprivacy` (was missing entirely). All 3 targets now have privacy manifests.
- Upstream sync completed (2026-02-11): Merged 18 upstream commits into `develop`. MatrixRustSDK v26.02.03 → v26.02.10, crash fixes (server confirmation, iOS 26 PassthroughWindow, QR/Link sign-in), Spaces feature. Only 1 auto-generated file conflict (pbxproj). Backup tag: `backup/pre-upstream-sync-20260211`.
- Build verified (2026-02-11): `xcodegen generate` + full build on iPhone 17 Pro simulator after upstream merge. BUILD SUCCEEDED.
- App Store preparation templates created (2026-02-12): `documentation/app_store_prep_templates.md` — 5 sections covering export compliance (encryption/ECCN), privacy nutrition labels (mapped from all 11 PrivacyInfo.xcprivacy data types), App Review notes with Guideline 4.3 risk mitigation, age rating questionnaire, and differentiation strategy with rejection response template. 74 `[PLACEHOLDER]` markers for customer-specific values.

- Customer responded (2026-02-16): 5 decisions resolved, server access + test accounts provided
- Server connectivity verified (2026-02-17): login test passed, `.well-known` confirmed (Sliding Sync, MAS, LiveKit)
- AppSettings.swift updated: account provider → `matrix.ucmeet.org`, legal URLs → ucmeet.info, Element Call analytics disabled
- App icon replaced: UCMeet Icon_1 processed (1024x1024, no alpha), temporary pending final re-export from customer
- Build verified (2026-02-17): `xcodegen generate` + full build on iPhone 17 Pro simulator after all changes. BUILD SUCCEEDED.
- Calls configuration (2026-02-17): URL scheme `io.element.call` → `org.ucmeet.call`, knownHosts cleared (embedded Element Call bundle), InfoPlistReader updated. LiveKit confirmed in `.well-known` at `matrix.ucmeet.org/livekit-jwt-service`.
- Localization trimmed (2026-02-17): 37 → 3 locales (en, en-US, ru). 34 locale folders deleted (~117 files). XcodeGen auto-updated `knownRegions`.
- Associated domains cleaned (2026-02-17): Removed 7 Element-specific applinks. Kept `applinks:matrix.to` + `webcredentials:*.element.io` (OIDC).
- Element-specific cleanup (2026-02-17): BugReportService sentry URL removed, Secrets.swift verified safe (`.localhost` placeholders).
- Login verified (2026-02-17): Full OIDC login flow tested on simulator after all changes — working.
- String rebranding (2026-02-17): 30 string replacements across en, en-US, ru (Localizable.strings + InfoPlist.strings). "Element" → "UCMeet", "Element Call" → "UCMeet Call", "Element X" → "UCMeet".
- Swift source cleanup (2026-02-17): 10 Element-specific references cleaned in 8 production Swift files (preview mocks, comments, dead code). 16 `io.element.elementx` dispatch queue labels remain — blocked on Bundle ID (D-001), will be batch-updated via `rebrand.sh`.

**What's blocked (require customer input):**
- Step 5: Bundle identity changes (needs Bundle ID — customer must choose, e.g. `org.ucmeet.chat`)
- Step 6: Identity changes (needs Bundle ID + Apple Developer account decision — D-007)
- Steps 7-9: Final branding (design assets promised via email — D-008)
- Push E2E testing (needs Sygnal URL from customer + Firebase project creation)
- OIDC client registration (needs Bundle ID first, then customer registers in MAS)

**Next actions:**
1. Ask customer for: Bundle ID preference, Sygnal URL, Apple Developer account decision
2. Wait for design assets email (app name, icon re-export, accent color)
3. Create Firebase project once Bundle ID is decided
4. Confirm AGPL license covers Element X specifically

### Blockers (remaining)

1. **Bundle ID** — Customer must choose (e.g., `org.ucmeet.chat`). Blocks Steps 5-6, OIDC, push, background tasks.
2. **AGPL v3 licensing** — Customer says handled; need written confirmation it covers Element X (not just old Element iOS). Blocks App Store publication only.
3. **Sygnal URL** — Customer has Sygnal but hasn't provided the URL yet. Blocks push E2E testing.
4. **Apple Developer account** — Whose account? Customer's or developer's? Blocks provisioning + App Store.
5. **Design assets** — Promised via email (app name, accent color, final icon). Blocks final branding.
6. **Firebase project** — Developer creates it; needs Bundle ID first. Blocks push E2E testing.

> See `decisions_tracker.md` for all 12 tracked decisions: 5 resolved, 4 in progress, 3 open.

---

## Project Documents

### Reading Order (for full context)

| Priority | File | What it is |
|----------|------|-----------|
| 1 | **`project_overview.md`** | Quick-reference: architecture, key facts, diagrams, glossary (English) |
| 2 | `tor.md` | Customer's Technical Requirements Document — what they asked for (Russian) |
| 3 | `preliminary_assessment.md` | Our technical analysis — what's actually true, effort estimates, risks (English) |
| 4 | `decisions_tracker.md` | All 12 open decisions with statuses — **UPDATE THIS after changes** (Russian) |
| 5 | `change_map.md` | Complete rebranding change map — every file/setting to modify, organized by category (English) |

### Development Guides

| File | When to use |
|------|------------|
| **`ios_proj_init.md`** | **START HERE when development begins.** 15-step technical plan from fork to first branded build. Covers architecture justification, build env, branding, localization, config, OIDC, push, calls. Includes Claude-specific task delegation and audit commands. |
| `implementation_plan.md` | Day-by-day schedule: 30 working days + 10 buffer (English) |
| `implementation_plan_ru.md` | Same schedule in Russian |
| `firebase_integration.md` | Firebase FCM integration: architecture, push provider selection, testability changes, all 14 unit tests documented, configuration requirements for customer |
| `pre_rebranding_preparations.md` | **Summary of all pre-rebranding research and tooling.** Links to 8 audit docs, describes 2 automation scripts, documents rebranding workflow |
| `oidc_audit.md` | OIDC redirect URI flow, all 14 element.io URLs, associated domains, authentication architecture |
| `branding_audit.md` | Compound design tokens, color assets, app icons, launch screen, 37 locales, ~86 files to modify |
| `nse_audit.md` | NSE target: 1 hardcoded string, everything else auto-derives from app.yml |
| `share_extension_audit.md` | ShareExtension: zero hardcoded brand references, all runtime via InfoPlistReader |
| `hardcoded_identifiers_inventory.md` | Complete inventory: 97 identifiers across 35+ files (28 auto, 52 manual, 17 test) |
| `element_call_audit.md` | Element Call (MatrixRTC + LiveKit): 8 hardcoded refs, URL scheme, associated domains, disabling options |
| `privacy_manifest_audit.md` | Privacy compliance B+: 2 manifests exist, 2 gaps (ShareExt manifest + NetworkInfo API), all analytics opt-in |
| `upstream_sync_report.md` | 18 upstream commits since fork, SDK v26.02.10, 3 bug fixes, 3-4 file conflicts, sync recommendation |
| `app_store_prep_templates.md` | App Store submission templates: export compliance/encryption, privacy nutrition labels, App Review notes, age rating, Guideline 4.3 differentiation strategy. All customer-specific values marked `[PLACEHOLDER]`. |
| **`overall_implementation_progress.md`** | **Living progress tracker.** TOR fulfillment map, hours invested vs remaining, critical path, decision impact analysis, timeline projections (3 scenarios), risk register (12 items), codebase metrics. **UPDATE THIS after each milestone.** |

### Customer-Facing Documents

| File | Purpose |
|------|---------|
| `customer_pre_dev_briefing_ru.md` | **Send to customer.** Blockers, prerequisites, action items, timeline reality (Russian) |
| `customer_questionnaire_init_stage.md` | **Developer's conversation script** for initial customer meeting, with licensing deep-dive (Russian) |

### Original Source

| File | Notes |
|------|-------|
| `TOR.docx` | Original TOR (binary — use `tor.md` instead) |

---

## Source Project Facts

| Fact | Value |
|------|-------|
| Repository | `github.com/element-hq/element-x-ios` |
| Language | Swift 100%, SwiftUI |
| Architecture | Coordinator-based MVVM |
| Build system | XcodeGen (`project.yml`, `app.yml`, `target.yml`) + SPM |
| Core SDK | Matrix Rust SDK v26.02.10 (Swift bindings via SPM, **opaque — cannot modify**) |
| Design system | Compound (Element's cross-platform semantic design tokens) |
| LOC | ~68,000 across ~907 Swift files |
| License | AGPL v3 (**legally problematic for App Store**) |
| iOS minimum | 18.0 (deployment target, raised from 17.6 due to iOS 18 API dependencies) |
| Push | APNs directly + Firebase SDK (FCM infrastructure added + unit-tested, pending customer config). See `documentation/firebase_integration.md` |
| Calls | Element Call (MatrixRTC + LiveKit, not Jitsi). See `documentation/element_call_audit.md` |
| Auth | OIDC (redirect URI hardcoded to element.io — must change). See `documentation/oidc_audit.md` |
| Privacy | All 3 targets have privacy manifests; NetworkInformation API declared. See `documentation/privacy_manifest_audit.md` |
| Rebranding | 97 hardcoded identifiers mapped, 2 automation scripts ready. See `documentation/pre_rebranding_preparations.md` |
| Upstream | Synced to upstream `main` (Feb 11). SDK v26.02.10, crash fixes merged. See `documentation/upstream_sync_report.md` |

## Key Files to Modify (When Development Starts)

```
app.yml                          → Bundle ID, display name, team ID, app group
AppSettings.swift                → Homeserver URL, OIDC, push gateway, pusher ID, analytics, legal URLs, feature flags
target.yml / entitlements        → Associated domains, push, app group
Assets.xcassets                  → App icon, accent color, launch screen
InfoPlist.strings (37+ locales)  → CFBundleDisplayName
Compound design tokens           → Accent color, theme
OIDC configuration               → Client ID, redirect URI
NSE/SupportingFiles/target.yml   → NSE bundle ID, entitlements
GoogleService-Info.plist         → Firebase project config (placeholder — needs customer values)
```

> Full details and step-by-step instructions in `ios_proj_init.md`.

## Key Technical Discrepancies (TOR vs Reality)

| TOR Says | Reality | Impact |
|----------|---------|--------|
| FCM (Firebase) | FCM infrastructure added (Firebase SDK + conditional APNs/FCM) | Customer provides GoogleService-Info.plist; Sygnal must be FCM-configured |
| Jitsi | Element Call (MatrixRTC + LiveKit) | Customer needs LiveKit, not Jitsi |
| iOS 16+ | iOS 18.0 minimum | Customer must accept |
| Scalar integration manager | Not in Element X | Not applicable |
| OIDC not mentioned | OIDC hardcoded to element.io | Must reconfigure |

## Estimates

| Metric | Value |
|--------|-------|
| Effort (without AI) | 85–132h, expected ~120h |
| Effort (with Claude Code) | ~60–95h, expected ~80h |
| Calendar time | 6–8 weeks at 20h/week (best case 4–5 weeks if all blockers pre-resolved) |
| Rate | $17/hr |
| Fixed price | $2,000–$2,200 |

---

## Working Rules

### General

- **No new features.** This is strictly rebrand + reconfigure. Do not add functionality beyond what Element X already has.
- **Do not modify Matrix Rust SDK** — it's an opaque binary dependency.
- **Never edit `.xcodeproj` directly** — it's generated by XcodeGen. Edit YAML files, then run `xcodegen generate`.
- **Pin SDK versions** at fork time. Do not upgrade unless necessary.
- **Keep the fork minimal** — every change increases future merge difficulty with upstream.

### Languages

- Documents for the customer → **Russian**
- Technical docs, code, commit messages → **English**

### Decisions & Tracking

- Track all decisions in `decisions_tracker.md`. Update status after every customer interaction.
- Use licensing checkpoints at Days 5, 11, 20, 27 (see `implementation_plan.md`).

### File Naming

- Project documents → `snake_case.md`
- Code files → Follow Element X existing conventions (don't rename upstream files)

### Git

- Branching: `main` (releases, at `checkpoint/unmodified-build`) + `develop` (active work, default on GitHub) + `upstream` remote (tracks element-hq/element-x-ios)
- Tag `checkpoint/unmodified-build` at `7c96ebfca` — last upstream commit before any fork changes
- 10 named checkpoints during init phase (see `ios_proj_init.md` Step 15)
- Commit format: Match existing upstream style (imperative, concise)
- Available slash commands: `/git-commit`, `/git-push`, `/commit-push-pr`

### Claude-Specific

- **Before modifying any file:** Read it first.
- **After bulk changes:** Run audit commands from `ios_proj_init.md` Section 18.3.
- **When stuck on signing/provisioning:** Ask the developer — these require Xcode GUI or Apple Portal.
- **When a decision from `decisions_tracker.md` is unresolved:** Do not guess. Flag it and ask.

---

## Customer Context

- Customer is Russian-speaking
- Customer has existing Matrix infrastructure (homeserver, Sygnal, possibly OIDC)
- Customer's TOR was written assuming older Element iOS patterns (FCM, Jitsi, iOS 16)
- Customer expects 4–6 week delivery (realistic: 6 weeks if all goes well, 8 with buffer)
- Customer needs to be educated on: AGPL licensing, APNs vs FCM difference, Element Call vs Jitsi (see `customer_pre_dev_briefing_ru.md`)

## Phase Progression

When updating this file, change "Current Phase" and check off completed phases:

- [x] **Phase 0: Planning** — Documentation created, codebase analyzed, decisions tracked
- [~] **Phase 1: Project Setup** — Fork created, build env configured, first build succeeded, audit complete. Steps 5–14 blocked by customer decisions.
- [ ] **Phase 2: Licensing** — Running in parallel, checkpoints at Days 5/11/20/27
- [ ] **Phase 3: Branding** — Icon, colors, strings, localization (Days 6–8)
- [ ] **Phase 4: Server Config + OIDC** — Homeserver, auth, `.well-known` (Days 8–11)
- [ ] **Phase 5: Push Notifications** — APNs key, Sygnal config, testing (Days 12–15)
- [ ] **Phase 6: Calls** — Element Call config, testing (Days 16–17)
- [ ] **Phase 7: Testing & QA** — Systematic testing, bug fixes (Days 18–21)
- [ ] **Phase 8: App Store Prep** — Listing, screenshots, privacy, compliance (Days 22–25)
- [ ] **Phase 9: Release** — TestFlight, submission, review cycles (Days 26–27 + buffer)
- [ ] **Phase 10: Documentation & Handover** — Guides, source delivery, handover (Days 28–30)

---

## Progress Analysis (as of 2026-02-11)

### ios_proj_init.md — 15-Step Technical Plan

| Step | Description | Status | Notes |
|------|-------------|--------|-------|
| 1 | Fork & Clone Repository | **DONE** | Fork at `smurzaliev/custom-element-messenger-ios`, upstream remote configured |
| 2 | Build Environment Setup | **DONE** | Xcode 26.2, XcodeGen 2.44.1, SPM resolved, git-lfs |
| 3 | First Successful Build | **DONE** | Build verified on iPhone 17 Pro simulator (re-verified Feb 11 after upstream merge) |
| 4 | Codebase Mapping & Audit | **DONE** | 8 audit docs, 97 hardcoded identifiers mapped across 35+ files, change map created |
| 5 | Apple Developer Provisioning | **BLOCKED** | Requires D-007 (Apple Developer account), D-001 (app identity) |
| 6 | Identity Changes (Bundle ID, Team, App Group) | **BLOCKED** | Requires D-001 (app name, bundle ID from customer) |
| 7 | Branding — App Icon & Colors | **BLOCKED** | Requires D-008 (design assets from customer) |
| 8 | Branding — Strings, Launch Screen & Element Removal | **MOSTLY DONE** | 30 string values rebranded (en, en-US, ru), 10 Swift refs cleaned. 16 dispatch queue labels blocked on D-001. Final app name needs D-008. |
| 9 | Localization | **DONE** | Trimmed 37 → 3 locales (en, en-US, ru). All "Element" strings replaced with "UCMeet". |
| 10 | Configuration (AppSettings, Analytics, Feature Flags) | **MOSTLY DONE** | Server URLs configured, analytics disabled, legal URLs set. Push gateway needs Sygnal URL. |
| 11 | OIDC & Associated Domains | **MOSTLY DONE** | OIDC login working, associated domains cleaned. Full migration to ucmeet.info needs AASA file. |
| 12 | Push Notification Plumbing | **PARTIAL** | FCM code + 14 unit tests complete. Blocked on real GoogleService-Info.plist (D-002) |
| 13 | Calls Configuration | **DONE** | URL scheme → `org.ucmeet.call`, knownHosts cleared, LiveKit confirmed in `.well-known` |
| 14 | Full Build Verification & Audit | **NOT STARTED** | Final step after all changes |
| 15 | Git Checkpoints & Branching Strategy | **DONE** | `main` + `develop` + `upstream` structure, checkpoint/unmodified-build tagged |

**Result:** 7 of 15 steps complete, 3 mostly done, 1 partial, 4 blocked on customer decisions.

### implementation_plan.md — 30-Day Schedule

| Days | Planned | Status |
|------|---------|--------|
| 1–3 | Fork, build, codebase study | **DONE** |
| 4–5 | Provisioning + bundle ID build | **BLOCKED** (D-001, D-007) |
| 6–8 | Branding (icon, colors, strings, analytics) | **BLOCKED** (D-008) |
| 9–10 | OIDC configuration & testing | **DONE** (OIDC login working, associated domains cleaned) |
| 11–15 | Server integration + push testing | **PARTIALLY READY** (FCM code done, server configured, push blocked on Sygnal URL) |
| 16–17 | Element Call configuration | **DONE** (URL scheme, knownHosts, LiveKit confirmed) |
| 18–30 | Testing, App Store prep, submission, docs | **NOT STARTED** |

### Work Done Beyond Original Schedule

| Category | Deliverable | Est. Hours |
|----------|-------------|------------|
| Firebase FCM | Full implementation + 14 unit tests + protocol extraction + documentation | ~8h |
| Pre-Rebranding Audits (5) | OIDC flow, Compound tokens, NSE, ShareExtension, 97 hardcoded identifiers | ~6h |
| Automation Scripts (2) | `rebrand.sh` (712 lines) + `rebrand_strings.sh` (560 lines), dry-run tested | ~6h |
| Additional Audits (3) | Element Call, privacy manifests, upstream sync report | ~4h |
| Privacy Manifest Fixes | NetworkInfo API added, ShareExtension manifest created | ~1h |
| Upstream Sync | Merged 18 upstream commits, SDK v26.02.10 | ~2h |
| Customer Documents (2) | Pre-dev briefing + questionnaire, both updated for FCM/iOS 18 | ~3h |
| Documentation | 8 audit docs, firebase integration guide, pre-rebranding summary | ~4h |
| App Store Prep Templates | Export compliance, privacy labels, review notes, age rating, 4.3 differentiation | ~3h |

### Summary Metrics

| Metric | Value |
|--------|-------|
| Plan completion | ~67% (7 done + 4 mostly done + 1 partial of 15 steps) |
| Schedule position | Day 11 of 30 (actual tasks complete) |
| Hours invested | ~56–61h of ~120h core budget |
| Decisions resolved | 5 of 12 (4 in progress: D-001, D-002, D-007, D-008) |
| Critical blockers | 3 (D-001 Bundle ID, D-007 Apple account, D-008 design assets) |
| Element brand refs remaining | 16 dispatch queue labels (blocked on D-001) + OIDC URLs (intentional) |

### Assessment

The project is **nearly feature-complete for what's possible without Bundle ID**. Server configured, OIDC login working, calls configured, all user-facing strings rebranded, 34 unused locales removed, associated domains cleaned. The remaining work is: Bundle ID-dependent changes (16 queue labels, provisioning), final design assets, push E2E testing, and App Store submission.

---

## Build Environment

| Tool | Version | Notes |
|------|---------|-------|
| Xcode | 26.2 | `/Applications/Xcode.app` |
| XcodeGen | 2.44.1 | Generates `.xcodeproj` from YAML |
| git-lfs | installed | Required by project |
| gh CLI | 2.86.0 | GitHub CLI for auth and repo management |
| Firebase SDK | 11.8.x | FirebaseMessaging via SPM |
| Simulator | iPhone 17 Pro | First build verified here |

---

## Progress Log

| Date | What was done |
|------|---------------|
| 2026-02-08 | Phase 0 complete: all documentation created, codebase audited, 12 decisions tracked |
| 2026-02-09 | Phase 1 partial: fork, build env, first build, change map, git structure, slash commands, Phases 7-10 continuation plan |
| 2026-02-10 | Build re-verified (still passes). Customer outreach docs reviewed and finalized — D-007 (Apple Developer account) gap fixed in both briefing and questionnaire. All 12 decisions cross-checked against questionnaire coverage. Ready for customer engagement. |
| 2026-02-10 | Firebase FCM integration implemented on `feature/firebase-fcm-integration` branch. Firebase SDK (v11.8.x) added via SPM, FirebaseNotificationService created, conditional APNs/FCM push provider in AppCoordinator, PushProvider setting (defaults to .firebase), placeholder GoogleService-Info.plist. Deployment target corrected from 17.6 to 18.0 (codebase requires iOS 18 APIs). Build verified on iPhone 17 Pro simulator. |
| 2026-02-11 | Firebase FCM unit tests: extracted `FirebaseNotificationServiceProtocol` for testability, injected into `AppCoordinator` via constructor, added `FirebaseNotificationServiceMock`. 14 new tests (5 NotificationManager FCM, 5 Firebase integration flow, 4 PushProvider), all passing. Documented in `documentation/firebase_integration.md`. |
| 2026-02-11 | Pre-rebranding research and tooling. 5 audit docs (OIDC, branding/Compound, NSE, ShareExtension, hardcoded identifiers — 97 total across 35+ files). 2 automation scripts: `scripts/rebrand.sh` (712 lines, all text substitutions with dry-run/validation/backup) and `scripts/rebrand_strings.sh` (560 lines, 37-locale string replacement + review report). Merged via PR #2. |
| 2026-02-11 | Additional audits: Element Call infrastructure (MatrixRTC+LiveKit, 8 refs, disabling options), privacy manifest compliance (B+, 2 gaps), upstream sync (18 commits, SDK v26.02.10). Fixed bash 3.2 bug in rebrand_strings.sh. Both scripts dry-run tested successfully. Total: 8 audit docs, 3,100+ lines of documentation and tooling. |
| 2026-02-11 | Privacy manifest gaps fixed: added NetworkInformation API to Main App + NSE, created ShareExtension PrivacyInfo.xcprivacy. Upstream sync completed: merged 18 commits (SDK v26.02.10, crash fixes, Spaces). Build verified after merge — BUILD SUCCEEDED on iPhone 17 Pro simulator. |
| 2026-02-11 | Regenerated xcodeproj after all Firebase FCM, privacy manifest, and upstream sync changes. All 14 FCM unit tests re-verified passing (32 total across 3 test suites). Pushed to origin/develop. |
| 2026-02-11 | Updated customer-facing documents: briefing and questionnaire reflect FCM-implemented status and iOS 18.0 requirement. Updated decisions tracker: D-002 status to "in progress" (FCM done, awaiting config), D-003 status to "in progress" (iOS 18.0 only option). All pushed to origin/develop. |
| 2026-02-11 | Progress analysis completed: 4 of 15 init steps done, 1 partial (push), 10 blocked on customer. ~40–45h invested. Project maximally prepared — no further dev work possible until customer meeting. |
| 2026-02-12 | App Store preparation templates: `documentation/app_store_prep_templates.md` — export compliance (identified ITSAppUsesNonExemptEncryption must change to true), privacy nutrition labels (all 11 data types mapped), App Review notes (Guideline 4.3 risk strategy), age rating (recommends 12+), differentiation strategy with rejection response template. |
| 2026-02-16 | Created 6 project-specific Claude Code commands: `/xcodegen-build`, `/upstream-sync`, `/audit-branding`, `/create-checkpoint`, `/rebrand-execute`, `/decision-status`. Updated `.claude/settings.local.json` with 6 missing permission patterns (git status/diff/log/merge, rebrand scripts). Build re-verified — BUILD SUCCEEDED on iPhone 17 Pro simulator. |
| 2026-02-17 | **Major unblock: customer responded.** 5 decisions resolved (D-003 iOS 18+, D-004 UCMeet Call, D-005 server infra, D-006 MAS/OIDC, D-011 contact). Server connectivity verified: login test passed against `matrix.ucmeet.org` (Synapse 1.144.0, Sliding Sync, MAS, LiveKit all confirmed). AppSettings.swift updated: account provider → `matrix.ucmeet.org`, all legal URLs → `ucmeet.info/policy-152`, Element Call PostHog/Sentry analytics disabled. App icon replaced with processed UCMeet Icon_1 (1024x1024, no alpha). Decisions tracker fully updated. New TOR (`TZ Matrix.docx`) analyzed — identical to original, no new info. Build verified — BUILD SUCCEEDED on iPhone 17 Pro simulator. |
| 2026-02-17 | **OIDC login working on simulator.** Fixed 3 issues blocking login: (1) OIDC redirect URL domain mismatch — MAS requires all URIs (client, redirect, logo, tos, policy) on same host; solved by using element.io for all OIDC registration metadata while keeping ucmeet.info for app UI links. (2) ASWebAuthenticationSession associated domains — HTTPS callback requires webcredentials + AASA file; ucmeet.info has no AASA, so element.io used (already in entitlements as `webcredentials:*.element.io`). (3) Firebase crash on placeholder GoogleService-Info.plist — added API key validation guard to skip Firebase init when credentials are placeholders. Successfully logged in as `test_user` on iPhone 17 Pro simulator. |
| 2026-02-17 | **Parallel UCMeet configuration batch.** (1) Calls: URL scheme `io.element.call` → `org.ucmeet.call`, `knownHosts` cleared (embedded bundle), InfoPlistReader updated, LiveKit confirmed in `.well-known`. (2) Localization: 37 → 3 locales (en, en-US, ru), 34 folders deleted (~117 files). (3) Associated domains: removed 7 Element-specific applinks, kept `matrix.to` + `webcredentials:*.element.io`. (4) Element cleanup: BugReportService sentry URL removed, Secrets.swift verified safe. Build + login verified on simulator. |
| 2026-02-17 | **String rebranding + Swift source cleanup.** 30 string replacements across 5 locale files (en, en-US, ru): "Element" → "UCMeet", "Element Call" → "UCMeet Call", "Element X" → "UCMeet". 10 Element-specific references cleaned in 8 Swift files (preview mocks, comments, dead code paths). 16 `io.element.elementx` dispatch queue labels identified as blocked on D-001. OIDC element.io URLs left as-is (technical requirement). Build verified. |
| 2026-02-17 | **Unit test fixes for rebrand.** 962 tests run, 16 failures caused by rebrand changes fixed across 5 test files: AppRouteURLParserTests (5 — knownHosts, URL scheme, web hosts), ServerConfirmationScreenViewModelTests (7 — accountProviders default, mock serverAddress), ServerConfirmationScreenViewStateTests (1 — element.io message removed), LocalizationTests (2 — Italian→Russian locale+plurals), AuthenticationServiceTests (1 — default homeserver address). All 33 affected tests passing. 39 pre-existing failures unrelated to rebrand. |

---

*Last updated: 2026-02-17 (unit test fixes for rebrand). Update this file whenever the project phase changes or a blocker is resolved.*

# Project Context — Element X iOS Branded Fork

## Skill Override — IMPORTANT

**This is an iOS/Swift/SwiftUI project. IGNORE all Flutter/Dart global skills.**

The following global skills are NOT applicable to this project and must be completely disregarded:
- Flutter skills (tdd-workflow, unit-testing, widget-testing, bloc-testing, bloc-architecture, clean-architecture, repository-pattern, error-handling, mocking-patterns, feature-structure, dependency-injection, and all other Flutter-specific skills)
- Flutter agents (flutter-senior-engineer)
- Flutter commands (flutter-test, flutter-lint, generate-bloc, generate-feature, generate-model, build-runner)
- All Flutter architecture patterns (BLoC, Riverpod, GetIt, Freezed, Dart-specific patterns)

**Project-specific local skills (in `.claude/skills/`):**
- `xcodegen-workflow` — XcodeGen YAML configuration and project generation
- `ios-branding` — App icon, colors, strings, display name changes
- `ios-signing-provisioning` — Code signing, entitlements, certificates
- `plist-configuration` — Info.plist and entitlements configuration

**Axiom plugin skills (use for all general iOS/Swift development):**
- `axiom:axiom-swiftui-architecture` — Architecture patterns, separating logic from views (replaces `swift-project-structure`)
- `axiom:axiom-app-composition` — App entry points, authentication flows, scene management
- `axiom:axiom-ios-build` — Build failures, test crashes, Xcode issues (replaces `ios-build-errors`)
- `axiom:axiom-xcode-debugging` — BUILD FAILED, test crashes, simulator hangs
- `axiom:axiom-build-debugging` — Dependency conflicts, SPM resolution failures (replaces `spm-management`)
- `axiom:axiom-localization` — String Catalogs, type-safe strings, internationalization (replaces `ios-localization`)
- `axiom:axiom-swift-concurrency` — async/await, actors, Sendable, data races (replaces `swift-concurrency`)
- `axiom:axiom-ios-concurrency` — Async code, actors, threads, concurrency diagnostics
- `axiom:axiom-swiftui-layout` — Adaptive layouts, screen sizes, iPad multitasking (replaces `swiftui-patterns`)
- `axiom:axiom-swiftui-performance` — UI performance, scrolling, animations
- `axiom:axiom-swiftui-nav` — Navigation patterns, NavigationStack, deep links
- `axiom:axiom-ios-testing` — Unit tests, flaky tests, test performance
- `axiom:axiom-swift-testing` — Swift Testing framework adoption
- `axiom:axiom-memory-debugging` — Memory warnings, retain cycles, leaks
- `axiom:axiom-privacy-ux` — Privacy manifests, permissions, App Tracking Transparency
- `axiom:axiom-apple-docs` — Apple framework APIs, Swift compiler questions
- `axiom:axiom-codable` — Codable protocol, JSON encoding/decoding
- `axiom:axiom-ios-networking` — Network connections, API calls, debugging
- `axiom:axiom-accessibility-diag` — VoiceOver, Dynamic Type, color contrast
- Use `axiom:ask` to route any iOS/Swift question to the right Axiom skill automatically

**Project-local agents (in `.claude/agents/`):**
- `ios-senior-engineer` — Expert iOS/Swift/SwiftUI development
- `git-manager` — Git operations, upstream sync, checkpoint management
- `planning-agent` — Project planning, task breakdown, progress tracking

**Project-local commands (in `.claude/commands/`):**
- `/xcodegen-generate` — Regenerate .xcodeproj from YAML
- `/ios-build` — Build for simulator
- `/ios-test` — Run unit tests
- `/git-commit` — Stage and commit with proper message
- `/git-push` — Push to origin
- `/commit-push-pr` — Full commit + push + PR workflow
- `/upstream-sync` — Fetch and review upstream changes
- `/create-checkpoint` — Create milestone checkpoint tag
- `/audit-branding` — Scan for remaining brand references

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
- Rebranding automation scripts created (2026-02-11): `scripts/rebrand.sh` (712 lines, handles all text substitutions) and `scripts/rebrand_strings.sh` (556 lines, handles 37-locale string replacement). Estimated rebranding time reduced from 4-8 hours to 1-2 hours.

**What's blocked (all require customer decisions):**
- Step 5: Bundle identity changes (needs App Name, Bundle ID, Team ID — D-001)
- Steps 6–14: Branding, config, OIDC, push, calls, testing, App Store
- See `decisions_tracker.md` for all 12 tracked decisions (D-001 through D-012)

**Next action:** Send `customer_pre_dev_briefing_ru.md` to customer, then conduct initial meeting using `customer_questionnaire_init_stage.md`. Resolve blockers before proceeding to Step 5.

### Blockers (must be resolved before rebranding work starts)

1. **AGPL v3 licensing** — Element X is AGPL v3, which conflicts with App Store ToS. Commercial license from Element (New Vector Ltd) required. NOT YET INITIATED.
2. **APNs vs FCM** — FCM infrastructure added (Firebase SDK, conditional push provider, placeholder config) and unit-tested (14 tests, all passing). Customer must provide real GoogleService-Info.plist values and configure Sygnal for FCM. Push provider defaults to FCM per TOR. NOT YET TESTED END-TO-END.
3. **iOS version** — TOR says iOS 16+, project requires iOS 18.0+ (deployment target). Customer must accept. NOT YET DECIDED.
4. **Calls infrastructure** — TOR says Jitsi, project uses Element Call (LiveKit). Customer must clarify. NOT YET DECIDED.
5. **App identity** — App name, bundle ID, team ID, app group needed before any code changes. NOT YET DECIDED (D-001).

> See `decisions_tracker.md` for all 12 tracked decisions with statuses (D-001 through D-012).

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
| `pre_rebranding_preparations.md` | **Summary of all pre-rebranding research and tooling.** Links to 5 audit docs, describes 2 automation scripts, documents rebranding workflow |
| `oidc_audit.md` | OIDC redirect URI flow, all 14 element.io URLs, associated domains, authentication architecture |
| `branding_audit.md` | Compound design tokens, color assets, app icons, launch screen, 37 locales, ~86 files to modify |
| `nse_audit.md` | NSE target: 1 hardcoded string, everything else auto-derives from app.yml |
| `share_extension_audit.md` | ShareExtension: zero hardcoded brand references, all runtime via InfoPlistReader |
| `hardcoded_identifiers_inventory.md` | Complete inventory: 97 identifiers across 35+ files (28 auto, 52 manual, 17 test) |

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
| Core SDK | Matrix Rust SDK (Swift bindings via SPM, **opaque — cannot modify**) |
| Design system | Compound (Element's cross-platform semantic design tokens) |
| LOC | ~68,000 across ~907 Swift files |
| License | AGPL v3 (**legally problematic for App Store**) |
| iOS minimum | 18.0 (deployment target, raised from 17.6 due to iOS 18 API dependencies) |
| Push | APNs directly + Firebase SDK (FCM infrastructure added + unit-tested, pending customer config). See `documentation/firebase_integration.md` |
| Calls | Element Call (MatrixRTC + LiveKit, not Jitsi) |
| Auth | OIDC (redirect URI hardcoded to element.io — must change). See `documentation/oidc_audit.md` |
| Rebranding | 97 hardcoded identifiers mapped, 2 automation scripts ready. See `documentation/pre_rebranding_preparations.md` |

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
- Slash commands available: `/git-commit`, `/git-push`, `/commit-push-pr`

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
| 2026-02-11 | Pre-rebranding research and tooling. 5 audit docs (OIDC, branding/Compound, NSE, ShareExtension, hardcoded identifiers — 97 total across 35+ files). 2 automation scripts: `scripts/rebrand.sh` (712 lines, all text substitutions with dry-run/validation/backup) and `scripts/rebrand_strings.sh` (556 lines, 37-locale string replacement + review report). Merged via PR #2. |

---

*Last updated: 2026-02-11 (pre-rebranding audits and automation). Update this file whenever the project phase changes or a blocker is resolved.*

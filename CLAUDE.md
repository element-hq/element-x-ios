# Project Context — Element X iOS Branded Fork

## What This Is

A branded fork of **Element X iOS** (open-source Matrix messenger, SwiftUI) to be published on Apple App Store under a customer's brand. The project is: rebrand + reconfigure + publish. No new features.

**Developer:** Saidakhror Murzaliev (solo, 20h/week, AI-assisted with Claude Code)
**Customer:** Russian-speaking, has existing Matrix infrastructure

## Current Phase

**Pre-development / Planning.** No code has been written yet. We are in the customer negotiation and decision-gathering stage.

**Next action:** Conduct initial meeting with customer using `customer_questionnaire_init_stage.md`, then send `customer_pre_dev_briefing_ru.md`.

### Blockers (must be resolved before development starts)

1. **AGPL v3 licensing** — Element X is AGPL v3, which conflicts with App Store ToS. Commercial license from Element (New Vector Ltd) required. NOT YET INITIATED.
2. **APNs vs FCM** — TOR says FCM, project uses APNs natively. Customer must confirm APNs. NOT YET DECIDED.
3. **iOS version** — TOR says iOS 16+, project requires iOS 17+. Customer must accept. NOT YET DECIDED.
4. **Calls infrastructure** — TOR says Jitsi, project uses Element Call (LiveKit). Customer must clarify. NOT YET DECIDED.

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

### Development Guides

| File | When to use |
|------|------------|
| **`ios_proj_init.md`** | **START HERE when development begins.** 15-step technical plan from fork to first branded build. Covers architecture justification, build env, branding, localization, config, OIDC, push, calls. Includes Claude-specific task delegation and audit commands. |
| `implementation_plan.md` | Day-by-day schedule: 30 working days + 10 buffer (English) |
| `implementation_plan_ru.md` | Same schedule in Russian |

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
| iOS minimum | 17.0 (release tags) / 18.5 (develop branch) |
| Push | APNs directly (no Firebase SDK) |
| Calls | Element Call (MatrixRTC + LiveKit, not Jitsi) |
| Auth | OIDC (redirect URI hardcoded to element.io — must change) |

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
```

> Full details and step-by-step instructions in `ios_proj_init.md`.

## Key Technical Discrepancies (TOR vs Reality)

| TOR Says | Reality | Impact |
|----------|---------|--------|
| FCM (Firebase) | APNs directly, no Firebase SDK | Use APNs — saves 10–16h |
| Jitsi | Element Call (MatrixRTC + LiveKit) | Customer needs LiveKit, not Jitsi |
| iOS 16+ | iOS 17+ minimum | Customer must accept |
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

- Branching: `main` (releases) + `develop` (active work) + `upstream/main` (tracks Element X)
- 10 named checkpoints during init phase (see `ios_proj_init.md` Step 15)
- Commit format: `[phase] Brief description`

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

- [ ] **Phase 0: Planning** — Customer decisions, licensing initiated
- [ ] **Phase 1: Project Setup** — Fork, build env, first build (Days 1–5)
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

*Last updated: 2026-02-08. Update this file whenever the project phase changes or a blocker is resolved.*

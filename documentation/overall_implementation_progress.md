# Overall Implementation Progress

> Living document tracking project progress, estimates, and risk status.
> Updated after each significant milestone or analysis session.
>
> **Project:** Element X iOS Branded Fork
> **Developer:** Saidakhror Murzaliev (solo, 20h/week, AI-assisted)

---

## Latest Analysis: 2026-02-12

**Calendar day:** ~14 since project start (Feb 8)

---

## 1. TOR Requirements Fulfillment Map

### Work Scope (TOR Section 3)

| TOR Section | Requirement | Status | Notes |
|-------------|-------------|--------|-------|
| **3.1** Source code adaptation | Bundle ID, identifiers, build scheme, libraries | **READY** | Automation scripts handle all substitutions. Firebase SDK added. Build verified. |
| **3.2** Branding | Icon, name, colors | **BLOCKED** (D-008) | Audit complete, scripts ready, awaiting assets |
| **3.3** FCM push integration | Firebase SDK, Sygnal, APNs key, testing | **70% DONE** | Code + 14 tests complete. Awaiting real GoogleService-Info.plist (D-002) |
| **3.4** Server configuration | Homeserver URL, identity server, .well-known, Scalar, Jitsi | **BLOCKED** (D-005) | .well-known handling works. Scalar doesn't exist in Element X. Jitsi replaced by Element Call. |
| **3.5** Calls support | 1:1 + group calls | **BLOCKED** (D-004) | 1:1 works (MatrixRTC). Group = Element Call (LiveKit), NOT Jitsi. Customer must decide. |
| **3.6** Testing | Full test cycle across devices/iOS versions | **0% DONE** | Requires server access. Entirely blocked on D-005. |
| **3.7** Release build | Version, signing, validation | **BLOCKED** (D-001, D-007) | Requires Apple Developer account + licensing resolution |
| **3.8** App Store publication | Listing, TestFlight, review, release | **TEMPLATES READY** | App Store prep templates created. Execution blocked on all above. |

### Functionality (TOR Section 4)

All items 4.1-4.11 are **inherited from Element X and already functional**. No code changes needed — only verification testing against customer's server.

| Feature | TOR Section | Element X Status | Fork Verification |
|---------|-------------|-----------------|-------------------|
| Registration | 4.1 | Works | Needs server test |
| Login/OIDC | 4.2 | Works | Needs OIDC config (D-006) |
| Sliding Sync | 4.3 | Works | Needs server test |
| Messaging (text, media, reactions, read receipts) | 4.4 | Works | Needs server test |
| Room management | 4.5 | Works | Needs server test |
| User profile | 4.6 | Works | Needs server test |
| 1:1 calls | 4.7 | Works (MatrixRTC) | Needs server test |
| Group calls | 4.7 | Works (Element Call) | **NOT Jitsi** — needs D-004 |
| Push notifications | 4.8 | FCM code ready | Needs real config (D-002) |
| Background updates | 4.9 | Works | Needs server test |
| Settings | 4.10 | Works | Needs server test |
| E2EE, Keychain, PIN/biometric | 4.11 | Works | Needs server test |

### Results (TOR Section 7)

| Requirement | Status | Gap |
|-------------|--------|-----|
| 7.1 App in App Store | **NOT DONE** | Blocked on D-001 (licensing), D-007 (Apple account) |
| 7.2 All functionality works | **NOT VERIFIED** | Needs server access for testing |
| 7.3 Stability/quality | **NOT VERIFIED** | Needs testing cycle |
| 7.4 Apple compliance | **TEMPLATES READY** | Privacy labels mapped, export compliance analyzed |
| 7.5 Branding matches customer | **NOT DONE** | Blocked on D-008 (assets) |
| 7.6 Source code + build docs | **PARTIALLY DONE** | 21 docs exist; build guide still needed |
| 7.7 Maintenance guidance | **NOT DONE** | Upstream sync process documented |

---

## 2. Hours: Invested vs. Remaining

### Hours Invested (as of 2026-02-12)

| Category | Hours | Deliverables |
|----------|-------|-------------|
| Project setup (fork, build env, first build) | ~8h | Working build on simulator |
| Codebase audit & mapping | ~10h | 8 audit docs, 97 identifiers, change map |
| Firebase FCM implementation | ~8h | Full code + 14 unit tests + protocol extraction |
| Automation scripts | ~6h | `rebrand.sh` (712 lines) + `rebrand_strings.sh` (560 lines) |
| Privacy manifest fixes | ~1h | 3 targets with complete manifests |
| Upstream sync | ~2h | 18 commits merged, SDK v26.02.10 |
| Customer documents | ~3h | Briefing + questionnaire (Russian) |
| App Store prep templates | ~3h | 5-section submission guide, 481 lines |
| Documentation overhead | ~4h | Plans, overview, misc |
| **Total invested** | **~45-48h** | |

### Remaining Work Estimate (by phase)

| Phase | Original Est. | Work Done | Remaining | Savings From |
|-------|--------------|-----------|-----------|-------------|
| Licensing (parallel) | 4-8h | ~1h | 3-7h | Mostly waiting, not labor |
| Branding | 8-14h | ~6h | **2-4h** | Automation scripts save 60-70% |
| Server Config + OIDC | 10-16h | ~3h | 7-10h | Audit de-risks but config is manual |
| Push Notifications | 9-12h | ~8h | **4-5h** | FCM code complete |
| Calls | 6-10h | ~2h | 2-4h | If Element Call accepted |
| Testing | 12-18h | 0h | 12-18h | Cannot parallelize, needs server |
| App Store Prep | 10-14h | ~6h | **5-8h** | Templates pre-filled |
| Release + Submission | 8-14h | 0h | 8-14h | Review cycles unpredictable |
| Docs + Handover | 6-10h | ~5h | **2-4h** | 21 docs already exist |
| **Total** | **73-116h** | **~31h** | **45-74h** | |

**Expected remaining: ~55h** (midpoint with AI assistance)

### Project Totals

| Metric | Value |
|--------|-------|
| Original estimate (with AI) | 60-95h, expected ~80h |
| Original estimate (without AI) | 85-132h, expected ~120h |
| Hours invested so far | ~45-48h |
| Hours remaining (estimated) | 45-74h, expected ~55h |
| **Projected total** | **~100-105h** |
| Budget position | Within original 85-132h range; slightly above ~80h AI-assisted estimate |
| Budget consumed | ~37% of hours, ~47% of $2,200 fixed price |

> The slight overrun vs. the AI-assisted estimate is explained by work done beyond the original plan scope: 8 audits, 2 automation scripts, App Store templates, upstream sync — all of which pay back in later phases.

---

## 3. Critical Path

### Dependency Chain

```
Customer meeting (Week 0)
    |
    |---> D-001 licensing initiated --> Element response (1-3 weeks) --> License signed
    |
    |---> D-005 server URLs received --> Server config + OIDC (1 week)
    |       |
    |       |---> D-006 OIDC registration
    |       |---> D-002 GoogleService-Info.plist --> Push testing
    |       +---> D-004 calls decision --> Call testing
    |
    |---> D-008 design assets --> Branding (2-3 days with scripts)
    |
    +---> D-007 Apple Developer account confirmed
            |
            +---> Provisioning --> Signing --> TestFlight --> App Review
```

**The critical path is:**
Customer meeting -> Server access (D-005) -> Config + OIDC + Push + Calls testing -> TestFlight -> App Review -> Release

**Licensing (D-001) runs in parallel** but must be resolved before App Store submission.

### Time-to-Resume After Customer Meeting

If all decisions are made in a single meeting:

| Action | Time to complete |
|--------|-----------------|
| Branding (run scripts + verify) | 1 day |
| Server config + OIDC | 2-3 days |
| Push end-to-end testing | 1-2 days |
| Calls verification | 1 day |
| Full test cycle | 3-4 days |
| App Store prep (fill templates) | 1-2 days |
| TestFlight + customer approval | 2-3 days |
| **Active dev total** | **~12-16 working days** |

At 20h/week (4h/day), this is **3-4 weeks of active development** after decisions are made.

---

## 4. Decision Impact Analysis

| Decision | Best Case | Worst Case | Impact |
|----------|-----------|------------|--------|
| **D-001 Licensing** | Element grants commercial license quickly ($0-5K) | Element refuses, customer won't open-source | **PROJECT KILLER** — would need to switch to old Element iOS (Apache 2.0) or accept legal risk |
| **D-002 Push/FCM** | Customer provides GoogleService-Info.plist + configures Sygnal | Customer has no Firebase project, Sygnal not configured | +1-2 days (help customer set up) |
| **D-003 iOS 18.0+** | Customer accepts (no choice) | Customer insists on iOS 16 | **Impossible** — codebase uses iOS 18 APIs. Would require abandoning Element X entirely. |
| **D-004 Calls** | Customer accepts Element Call + deploys LiveKit | Customer insists on Jitsi | **+20-40h out of scope.** Recommend disabling calls in v1 if no LiveKit. |
| **D-005 Servers** | All infrastructure ready | Server not set up | **PROJECT BLOCKED** indefinitely. Active dev cannot proceed. |
| **D-006 OIDC** | Customer registers client, provides credentials | Customer uses password-only auth (no OIDC) | Simpler (fewer changes needed). Element X supports both paths. |
| **D-007 Apple Account** | Developer's account ready | No account, need to register | +2-3 days (Apple registration time) |
| **D-008 Design** | Assets delivered with first meeting | Design not ready | Can proceed with placeholders, finalize later |

### Kill Scenarios (project cannot complete)

1. **Element refuses commercial license AND customer won't open-source AND customer won't accept legal risk** — No path to App Store.
2. **Customer insists on iOS 16** — Technically impossible with Element X. Would require entirely different codebase.
3. **Customer's server doesn't support Sliding Sync** — Element X requires it. No fallback.

---

## 5. TOR Discrepancy Resolution Status

| # | TOR Requirement | Reality | Resolution Path | Effort if Worst Case |
|---|----------------|---------|----------------|---------------------|
| 1 | iOS 16+ | iOS 18.0+ | Customer must accept | 0h (or project pivot) |
| 2 | FCM push | FCM code done, needs config | Customer provides config | ~5h remaining |
| 3 | Jitsi for calls | Element Call (LiveKit) | Customer deploys LiveKit OR disables calls | 0-2h (or +20-40h for Jitsi) |
| 4 | Scalar integration | Not in Element X | Drop requirement — Scalar is legacy | 0h |
| 5 | OIDC not mentioned | OIDC is primary auth | Audit complete, 14 URLs mapped | ~4h to reconfigure |
| 6 | AGPL v3 awareness | AGPL conflicts with App Store | Commercial license needed | 3-7h + $$ + wait time |

---

## 6. Timeline Projections

### Scenario A: Best Case (5 weeks remaining)

- Customer meeting happens this week
- All decisions made immediately
- Server infrastructure already operational
- Design assets provided same week
- Element responds to licensing within 1 week
- App Store approved on first submission

```
Week 1: Customer meeting, decisions resolved, assets received
Week 2: Branding + server config + OIDC + push testing
Week 3: Full testing cycle + bug fixes
Week 4: App Store prep + TestFlight + customer approval
Week 5: App Review + approval + release
Total project: ~7 weeks (Feb 8 - Mar 28)
```

### Scenario B: Expected Case (7-8 weeks remaining)

- Customer meeting happens within 1 week
- Some decisions deferred (calls, design)
- Server needs minor setup assistance
- Element responds in 2-3 weeks
- App Store requires 1 revision

```
Week 1-2: Customer meeting, partial decisions
Week 3: Server access received, begin config
Week 4: Branding + OIDC + push testing
Week 5: Testing cycle + calls resolution
Week 6: App Store prep + TestFlight
Week 7: First App Review submission, rejection for 4.3
Week 8: Appeal/resubmit, approval
Total project: ~10 weeks (Feb 8 - Apr 18)
```

### Scenario C: Worst Case (12+ weeks remaining)

- Customer meeting delayed 2+ weeks
- Server infrastructure not ready
- Licensing negotiation takes 4+ weeks
- Multiple App Store rejections
- Calls infrastructure requires pivot

```
Week 1-3: Waiting for customer engagement
Week 4: Meeting, partial decisions
Week 5-6: Wait for server setup + licensing
Week 7-8: Active development resumes
Week 9-10: Testing + App Store prep
Week 11-12: App Review cycles
Week 13+: Final resolution
Total project: 14+ weeks (Feb 8 - May+)
```

### Summary

| Scenario | Total Project Duration | Active Dev Hours | Calendar End |
|----------|----------------------|-----------------|-------------|
| Best | 7 weeks | ~95h | Late March |
| Expected | 10 weeks | ~105h | Mid-April |
| Worst | 14+ weeks | ~120h+ | May+ |
| Customer's expectation (from TOR) | 4-6 weeks | — | Mid-March |

**The customer's 4-6 week expectation is unrealistic** given that no decisions have been made and zero customer engagement has occurred in 14 calendar days.

---

## 7. Risk Register

| # | Risk | Probability | Impact | Status vs. Original | Mitigation Done |
|---|------|-------------|--------|---------------------|-----------------|
| 1 | **AGPL/App Store conflict** | High | Critical | **UNCHANGED** — not initiated | Documented in briefing, questionnaire covers it |
| 2 | **Guideline 4.3 rejection** | Medium | High | **REDUCED** | Differentiation strategy + rejection response template prepared |
| 3 | **FCM complications** | Low | Medium | **REDUCED** from Medium | Code complete, 14 tests passing |
| 4 | **Backend not ready** | Medium | High | **UNCHANGED** — no visibility | Customer briefing asks about it |
| 5 | **OIDC complexity** | Low | Medium | **REDUCED** from Medium | Full audit: 14 URLs mapped, architecture understood |
| 6 | **SDK incompatibilities** | Low | High | **REDUCED** | Upstream synced to v26.02.10 |
| 7 | **LiveKit unavailable** | Medium | Medium | **UNCHANGED** | Element Call audit + disable option documented |
| 8 | **Multiple review cycles** | High | Medium | **REDUCED** | App Store templates pre-answer compliance |
| 9 | **Late design assets** | Medium | Low | **UNCHANGED** | Automation scripts minimize execution time |
| 10 | **XcodeGen/SPM failures** | Low | Medium | **REDUCED** | Build verified 3 times after changes |
| **11** | **Customer engagement delay** | **High** | **Critical** | **NEW** | **14 days with zero customer contact. Single biggest risk.** |
| **12** | **Export control/sanctions** | **Low** | **High** | **NEW** | Identified in encryption analysis. Russian customer + US encryption export rules. |

---

## 8. Codebase Metrics

| Metric | Value |
|--------|-------|
| Total Swift files | 1,260 |
| Test files | 162 |
| Documentation files | 21 |
| Automation scripts | 2 (1,272 lines total) |
| Localization files | 71 (34 InfoPlist + 37 Localizable) |
| Remaining `element.io` refs in Swift | 58 occurrences across 18 files |
| Remaining `io.element` refs in Swift | 24 occurrences across 20 files |
| Git tags (fork-specific) | 2 (`checkpoint/unmodified-build`, `backup/pre-upstream-sync-20260211`) |

---

## 9. Conclusions (2026-02-12)

**The project is in a paradoxical state: technically over-prepared but operationally stalled.**

1. **All pre-customer work is exhausted.** Every audit, script, template, and technical preparation that can be done without customer input has been done. The codebase is deeply understood, risks are mapped, and automation tools are ready.

2. **The single bottleneck is customer engagement.** 0 of 12 decisions resolved. No meeting scheduled. Every day of delay adds a day to the timeline with zero productive work possible.

3. **Hours tracking is healthy but calendar is slipping.** ~48h invested at ~37% of budget is fine for hours, but 14 calendar days with the project at an unbreakable standstill means the customer's 4-6 week expectation is already mathematically difficult.

4. **Licensing (D-001) is a time bomb.** It's the only risk that can kill the project entirely, and it hasn't been initiated. Element's response time is typically 1-3 weeks. Every day of delay on this front directly threatens the final delivery date.

5. **When development resumes, it will be fast.** The automation scripts, audits, and templates mean that Phases 3-5 (branding, config, push) will take approximately 50-60% less time than originally estimated. The testing phase (Phase 7) is the only phase that cannot be accelerated.

**Recommended immediate actions:**
1. Send the customer briefing document and schedule the initial meeting.
2. In parallel, send the licensing inquiry to Element (New Vector Ltd) at `sales@element.io`.
3. These two actions are the only things that can unblock the project.

---

## Progress History

| Date | Analysis Summary |
|------|-----------------|
| 2026-02-12 | Initial progress analysis. 4/15 init steps done, 1 partial. ~45-48h invested (~37% budget). 0/12 decisions resolved. Project maximally prepared for customer engagement. Estimated ~55h remaining active work. Timeline: 7-10 weeks total (best/expected). |

---

*This document is updated after each significant milestone, customer interaction, or periodic review. Next update: after customer meeting or next work session.*

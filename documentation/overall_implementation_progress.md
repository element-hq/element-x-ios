# Overall Implementation Progress

> Living document tracking project progress, estimates, and risk status.
> Updated after each significant milestone or analysis session.
>
> **Project:** Element X iOS Branded Fork
> **Developer:** Saidakhror Murzaliev (solo, 20h/week, AI-assisted)

---

## Latest Analysis: 2026-02-17

**Calendar day:** ~19 since project start (Feb 8)

---

## 1. TOR Requirements Fulfillment Map

### Work Scope (TOR Section 3)

| TOR Section | Requirement | Status | Notes |
|-------------|-------------|--------|-------|
| **3.1** Source code adaptation | Bundle ID, identifiers, build scheme, libraries | **MOSTLY DONE** | Server config applied, Element refs cleaned, associated domains updated. Bundle ID still needs D-001. |
| **3.2** Branding | Icon, name, colors | **MOSTLY DONE** (D-008) | Temp icon applied, all user-facing strings rebranded. Final assets (name, accent color, icon re-export) promised via email. |
| **3.3** FCM push integration | Firebase SDK, Sygnal, APNs key, testing | **70% DONE** | Code + 14 tests complete. Awaiting real GoogleService-Info.plist (D-002). |
| **3.4** Server configuration | Homeserver URL, identity server, .well-known, Scalar, Jitsi | **DONE** | `matrix.ucmeet.org` configured, `.well-known` verified, legal URLs → ucmeet.info. Scalar N/A. |
| **3.5** Calls support | 1:1 + group calls | **DONE** | URL scheme → `org.ucmeet.call`, LiveKit confirmed in `.well-known`, embedded Element Call bundle. |
| **3.6** Testing | Full test cycle across devices/iOS versions | **IN PROGRESS** | OIDC login verified on simulator. 16 rebrand-affected unit tests fixed and passing. Full test cycle needs more device coverage. |
| **3.7** Release build | Version, signing, validation | **BLOCKED** (D-001, D-007) | Requires Apple Developer account + licensing resolution |
| **3.8** App Store publication | Listing, TestFlight, review, release | **TEMPLATES READY** | App Store prep templates created. Execution blocked on D-001, D-007. |

### Functionality (TOR Section 4)

All items 4.1-4.11 are **inherited from Element X and already functional**. No code changes needed — only verification testing against customer's server.

| Feature | TOR Section | Element X Status | Fork Verification |
|---------|-------------|-----------------|-------------------|
| Registration | 4.1 | Works | Needs server test |
| Login/OIDC | 4.2 | Works | **VERIFIED** — OIDC login working on simulator |
| Sliding Sync | 4.3 | Works | **VERIFIED** — room list loads via Sliding Sync |
| Messaging (text, media, reactions, read receipts) | 4.4 | Works | Needs deeper testing |
| Room management | 4.5 | Works | Needs server test |
| User profile | 4.6 | Works | Needs server test |
| 1:1 calls | 4.7 | Works (MatrixRTC) | Needs server test |
| Group calls | 4.7 | Works (Element Call) | LiveKit confirmed in `.well-known`, needs call test |
| Push notifications | 4.8 | FCM code ready | Needs real config (D-002) |
| Background updates | 4.9 | Works | Needs server test |
| Settings | 4.10 | Works | Needs server test |
| E2EE, Keychain, PIN/biometric | 4.11 | Works | Needs server test |

### Results (TOR Section 7)

| Requirement | Status | Gap |
|-------------|--------|-----|
| 7.1 App in App Store | **NOT DONE** | Blocked on D-001 (licensing), D-007 (Apple account) |
| 7.2 All functionality works | **PARTIALLY VERIFIED** | OIDC login + Sliding Sync verified. Calls, push, E2EE need testing. |
| 7.3 Stability/quality | **NOT VERIFIED** | Needs full testing cycle |
| 7.4 Apple compliance | **TEMPLATES READY** | Privacy labels mapped, export compliance analyzed |
| 7.5 Branding matches customer | **PARTIAL** | Temporary icon applied. Final assets awaited (D-008). |
| 7.6 Source code + build docs | **PARTIALLY DONE** | 21+ docs exist; build guide still needed |
| 7.7 Maintenance guidance | **NOT DONE** | Upstream sync process documented |

---

## 2. Hours: Invested vs. Remaining

### Hours Invested (as of 2026-02-17)

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
| Claude Code commands | ~1h | 6 project-specific slash commands |
| Server config + OIDC login | ~4h | AppSettings configured, OIDC login working, Firebase crash fix |
| Calls + localization + cleanup | ~3h | URL scheme, knownHosts, 34 locales removed, domains cleaned |
| String rebranding + Swift cleanup | ~3h | 30 string replacements (en, en-US, ru), 10 Swift source refs cleaned |
| Unit test fixes | ~1h | 16 test assertions updated across 5 test files to match rebrand |
| **Total invested** | **~57-60h** | |

### Remaining Work Estimate (by phase)

| Phase | Original Est. | Work Done | Remaining | Savings From |
|-------|--------------|-----------|-----------|-------------|
| Licensing (parallel) | 4-8h | ~1h | 3-7h | Mostly waiting, not labor |
| Branding | 8-14h | ~10h | **0.5-1h** | Strings rebranded, temp icon applied. Only final icon/color swap when assets arrive. |
| Server Config + OIDC | 10-16h | ~7h | **1-2h** | Server configured, OIDC working. Only AASA migration left. |
| Push Notifications | 9-12h | ~8h | **4-5h** | FCM code complete, needs real config |
| Calls | 6-10h | ~5h | **0-1h** | ✅ Configuration complete, LiveKit confirmed |
| Testing | 12-18h | ~2h | 10-16h | Login verified; full test cycle still needed |
| App Store Prep | 10-14h | ~6h | **5-8h** | Templates pre-filled |
| Release + Submission | 8-14h | 0h | 8-14h | Review cycles unpredictable |
| Docs + Handover | 6-10h | ~5h | **2-4h** | 21+ docs already exist |
| **Total** | **73-116h** | **~41h** | **34-60h** | |

**Expected remaining: ~42h** (midpoint with AI assistance)

### Project Totals

| Metric | Value |
|--------|-------|
| Original estimate (with AI) | 60-95h, expected ~80h |
| Original estimate (without AI) | 85-132h, expected ~120h |
| Hours invested so far | ~57-60h |
| Hours remaining (estimated) | 31-57h, expected ~39h |
| **Projected total** | **~94-99h** |
| Budget position | Within AI-assisted range (60-95h), on track |
| Budget consumed | ~59% of hours, ~64% of $2,200 fixed price |

> Project is tracking well within budget. String rebranding and source cleanup further reduced remaining work. Main cost centers left: testing (~10-16h) and App Store submission (~8-14h).

---

## 3. Critical Path

### Dependency Chain (Updated 2026-02-17)

```
✅ Customer responded (Feb 16) — 5 decisions resolved
    |
    |---> D-001 licensing → 🟡 Customer claims resolved, need written confirmation
    |
    |---> ✅ D-005 server URLs → DONE (matrix.ucmeet.org configured)
    |       |
    |       |---> ✅ D-006 OIDC → DONE (MAS login working on simulator)
    |       |---> D-002 Firebase project → Needs Bundle ID first (D-001)
    |       +---> ✅ D-004 calls → DONE (LiveKit confirmed, URL scheme updated)
    |
    |---> D-008 design assets → 🟡 Promised via email (awaiting)
    |
    +---> D-007 Apple Developer account → 🔴 Not discussed yet
            |
            +---> D-001 Bundle ID → Provisioning → Signing → TestFlight → App Review
```

**The critical path is now:**
Bundle ID (D-001) -> Firebase project (D-002) -> Push testing -> TestFlight -> App Review -> Release

**Licensing (D-001) runs in parallel** but must be resolved before App Store submission.

### Remaining Actions

| Action | Blocker | Time to complete |
|--------|---------|-----------------|
| Final branding (run scripts + verify) | D-008 (design assets email) | 0.5-1 day |
| Bundle ID + provisioning | D-001 (customer choice) + D-007 (Apple account) | 1 day |
| Create Firebase project + push testing | D-001 (Bundle ID) + Sygnal URL | 1-2 days |
| Full test cycle | All above | 3-4 days |
| App Store prep (fill templates) | — | 1-2 days |
| TestFlight + customer approval | D-007 (Apple account) | 2-3 days |
| **Active dev total** | | **~9-13 working days** |

At 20h/week (4h/day), this is **2-3 weeks of active development** once remaining blockers are resolved.

---

## 4. Decision Impact Analysis

| Decision | Best Case | Worst Case | Impact | Status |
|----------|-----------|------------|--------|--------|
| **D-001 Licensing** | Customer has commercial license | License doesn't cover Element X | **PROJECT KILLER** for App Store | 🟡 Customer claims resolved |
| **D-002 Push/FCM** | Dev creates Firebase project, customer configures Sygnal | Sygnal not FCM-compatible | +1-2 days | 🟡 Needs Bundle ID first |
| **D-003 iOS 18.0+** | ~~Customer accepts~~ | ~~Customer insists on iOS 16~~ | ~~N/A~~ | ✅ Resolved |
| **D-004 Calls** | ~~LiveKit deployed~~ | ~~No LiveKit~~ | ~~N/A~~ | ✅ Resolved + configured |
| **D-005 Servers** | ~~All ready~~ | ~~Not set up~~ | ~~N/A~~ | ✅ Resolved + configured |
| **D-006 OIDC** | ~~MAS works~~ | ~~No OIDC~~ | ~~N/A~~ | ✅ Resolved + login verified |
| **D-007 Apple Account** | Developer's account ready | No account, need to register | +2-3 days | 🔴 Not discussed |
| **D-008 Design** | Assets arrive this week | Design delayed | Can proceed with temp icon | 🟡 Promised via email |

### Kill Scenarios (project cannot complete)

1. **Element refuses commercial license AND customer won't open-source AND customer won't accept legal risk** — No path to App Store.
2. **Customer insists on iOS 16** — Technically impossible with Element X. Would require entirely different codebase.
3. **Customer's server doesn't support Sliding Sync** — Element X requires it. No fallback.

---

## 5. TOR Discrepancy Resolution Status

| # | TOR Requirement | Reality | Resolution Path | Status |
|---|----------------|---------|----------------|--------|
| 1 | iOS 16+ | iOS 18.0+ | ✅ Customer accepted | Resolved |
| 2 | FCM push | FCM code done, needs config | Dev creates Firebase project (needs Bundle ID) | ~4h remaining |
| 3 | Jitsi for calls | Element Call (LiveKit) | ✅ LiveKit confirmed + configured | Resolved |
| 4 | Scalar integration | Not in Element X | ✅ Dropped — Scalar is legacy | Resolved |
| 5 | OIDC not mentioned | OIDC is primary auth | ✅ MAS login working on simulator | Resolved |
| 6 | AGPL v3 awareness | AGPL conflicts with App Store | Customer claims resolved — need written confirmation | In progress |

---

## 6. Timeline Projections

### Scenario A: Best Case (3 weeks remaining)

- Bundle ID + Apple account resolved this week
- Design assets arrive via email this week
- Firebase project created, push tested
- App Store approved on first submission

```
Week 4 (current): Bundle ID received, final branding, Firebase project
Week 5: Push testing, full test cycle, App Store prep
Week 6: TestFlight, App Review, release
Total project: ~6 weeks (Feb 8 - Mar 21)
```

### Scenario B: Expected Case (4-5 weeks remaining)

- Bundle ID + Apple account resolved within 1 week
- Design assets arrive within 1 week
- Push testing takes 1-2 days
- App Store requires 1 revision (Guideline 4.3)

```
Week 4 (current): Waiting for Bundle ID + assets
Week 5: Bundle ID received, final branding, Firebase project, push testing
Week 6: Full test cycle, App Store prep, TestFlight
Week 7: First submission, Guideline 4.3 rejection
Week 8: Resubmit with differentiation, approval
Total project: ~8 weeks (Feb 8 - Apr 4)
```

### Scenario C: Worst Case (8+ weeks remaining)

- Bundle ID / Apple account delayed 2+ weeks
- Licensing confirmation delayed
- Multiple App Store rejections
- Push testing reveals Sygnal issues

```
Week 4-5: Waiting for customer decisions
Week 6: Bundle ID + assets received, rapid configuration
Week 7: Testing + App Store prep
Week 8-9: App Review cycles
Week 10+: Final resolution
Total project: 10+ weeks (Feb 8 - Apr 18+)
```

### Summary

| Scenario | Total Project Duration | Active Dev Hours | Calendar End |
|----------|----------------------|-----------------|-------------|
| Best | 6 weeks | ~90h | Late March |
| Expected | 8 weeks | ~98h | Early April |
| Worst | 10+ weeks | ~110h+ | Mid-April+ |
| Customer's expectation (from TOR) | 4-6 weeks | — | Mid-March |

**The customer's 4-6 week expectation is tight but achievable** for best-case scenario. Key dependency: Bundle ID and Apple Developer account must be resolved this week.

---

## 7. Risk Register

| # | Risk | Probability | Impact | Status vs. Feb 12 | Mitigation Done |
|---|------|-------------|--------|---------------------|-----------------|
| 1 | **AGPL/App Store conflict** | Medium | Critical | **REDUCED** — customer claims resolved | Need written confirmation covering Element X specifically |
| 2 | **Guideline 4.3 rejection** | Medium | High | **UNCHANGED** | Differentiation strategy + rejection response template prepared |
| 3 | **FCM complications** | Low | Medium | **UNCHANGED** | Code complete, 14 tests passing. Needs real config. |
| 4 | **Backend not ready** | Low | High | **RESOLVED** | ✅ Server verified, login working, `.well-known` confirmed |
| 5 | **OIDC complexity** | Low | Low | **RESOLVED** | ✅ OIDC login working on simulator via MAS |
| 6 | **SDK incompatibilities** | Low | High | **UNCHANGED** | Upstream synced to v26.02.10 |
| 7 | **LiveKit unavailable** | Low | Medium | **RESOLVED** | ✅ LiveKit confirmed in `.well-known`, URL scheme configured |
| 8 | **Multiple review cycles** | High | Medium | **UNCHANGED** | App Store templates pre-answer compliance |
| 9 | **Late design assets** | Medium | Low | **UNCHANGED** | Temp icon applied, scripts ready for final assets |
| 10 | **XcodeGen/SPM failures** | Low | Medium | **UNCHANGED** | Build verified 5+ times after changes |
| ~~11~~ | ~~**Customer engagement delay**~~ | ~~Low~~ | ~~Critical~~ | **RESOLVED** | ✅ Customer responded Feb 16, 5 decisions resolved |
| 12 | **Export control/sanctions** | Low | High | **UNCHANGED** | Identified in encryption analysis. Russian customer + US encryption export rules. |
| **13** | **Bundle ID delay** | **Medium** | **High** | **NEW** | **Bundle ID blocks Firebase project, provisioning, OIDC migration, and App Store. Must resolve ASAP.** |

---

## 8. Codebase Metrics

| Metric | Value |
|--------|-------|
| Total Swift files | ~1,260 |
| Test files | 162 |
| Documentation files | 21+ |
| Automation scripts | 2 (1,272 lines total) |
| Localization locales | 3 (en, en-US, ru) — trimmed from 37 |
| Localization files | ~13 (was ~130 before trim) |
| Associated domains | 2 (matrix.to + webcredentials:*.element.io) — trimmed from 9 |
| Remaining `element.io` in production Swift | ~10 (OIDC URLs intentional, Compound library previews) |
| Remaining `io.element.elementx` identifiers | 16 dispatch queue labels (blocked on D-001 Bundle ID) |
| Git tags (fork-specific) | 2 (`checkpoint/unmodified-build`, `backup/pre-upstream-sync-20260211`) |

---

## 9. Conclusions (2026-02-17)

**The project has shifted from "stalled" to "rapidly progressing with 3 remaining blockers."**

1. **Customer engagement unlocked major progress.** 5 of 12 decisions resolved in a single exchange. Server configured, OIDC login working, calls configured, localization trimmed, Element-specific references cleaned up. The app is functional on the simulator.

2. **The critical path is now Bundle ID + Apple Developer account.** These two items (D-001, D-007) gate everything remaining: Firebase project creation, provisioning, OIDC migration to ucmeet.info, and App Store submission.

3. **Hours tracking is healthy.** ~55h invested at ~55% of budget, with ~60% of work complete by task weight. The remaining work (~42h expected) fits within the original AI-assisted estimate of 60-95h.

4. **Licensing still needs written confirmation.** Customer claims it's resolved, but we need explicit confirmation that the license covers Element X iOS (AGPL v3), not just old Element iOS (Apache 2.0).

5. **Design assets are the easiest remaining blocker.** Customer promised to send via email. When received, branding can be finalized in <1 day using the automation scripts.

**Recommended immediate actions:**
1. Ask customer for Bundle ID preference (e.g., `org.ucmeet.chat`).
2. Clarify Apple Developer account ownership (D-007).
3. Request Sygnal URL for push notification testing.
4. Get written AGPL licensing confirmation.

---

## Progress History

| Date | Analysis Summary |
|------|-----------------|
| 2026-02-12 | Initial progress analysis. 4/15 init steps done, 1 partial. ~45-48h invested (~37% budget). 0/12 decisions resolved. Project maximally prepared for customer engagement. Estimated ~55h remaining active work. Timeline: 7-10 weeks total (best/expected). |
| 2026-02-17 | Major progress after customer response. 7/15 init steps done, 4 mostly done, 1 partial. ~56-59h invested (~58% budget). 5/12 decisions resolved. Server configured, OIDC login verified, calls configured, 34 locales removed, associated domains cleaned, 30 strings rebranded, 10 Swift refs cleaned. Estimated ~39h remaining. Timeline: 6-8 weeks total (best/expected). Critical path: Bundle ID + Apple Developer account. |
| 2026-02-17 | Unit test fixes for rebrand. 962 tests run, 16 failures caused by our changes fixed across 5 test files (AppRouteURLParserTests, ServerConfirmationScreenViewModelTests, ServerConfirmationScreenViewStateTests, LocalizationTests, AuthenticationServiceTests). All 33 affected tests now passing. ~57-60h invested (~59% budget). |

---

*This document is updated after each significant milestone, customer interaction, or periodic review. Next update: after Bundle ID decision or design assets received.*

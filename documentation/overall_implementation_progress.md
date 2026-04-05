# Overall Implementation Progress

> Living document tracking project progress, estimates, and risk status.
> Updated after each significant milestone or analysis session.
>
> **Project:** Element X iOS Branded Fork
> **Developer:** Saidakhror Murzaliev (solo, 20h/week, AI-assisted)

---

## Latest Analysis: 2026-04-05

**Calendar day:** ~56 since project start (Feb 8)

---

## 1. TOR Requirements Fulfillment Map

### Work Scope (TOR Section 3)

| TOR Section | Requirement | Status | Notes |
|-------------|-------------|--------|-------|
| **3.1** Source code adaptation | Bundle ID, identifiers, build scheme, libraries | **DONE** | Server config applied, Element refs cleaned, associated domains updated, Bundle ID fully cascaded, Xcode signing works. |
| **3.2** Branding | Icon, name, colors | **DONE** | Display name "UCMeet.Chat" applied, new 3D logos installed (square + circular), accent color #003B5D (dark navy blue). 24 SwiftUI + 23 UIKit Compound token overrides. Zero Element branding visible. |
| **3.3** Push integration | APNs through Sygnal | **DONE — E2E VERIFIED** | Switched from FCM to direct APNs (Mar 26). Push E2E verified on TestFlight build (Mar 28). Firebase SDK retained but unused for push. |
| **3.4** Server configuration | Homeserver URL, identity server, .well-known, Scalar, Jitsi | **DONE** | `matrix.ucmeet.org` configured, `.well-known` verified, legal URLs → ucmeet.org. Scalar N/A. |
| **3.5** Calls support | 1:1 + group calls | **DONE** | URL scheme → `org.ucmeet.call`, LiveKit confirmed in `.well-known`, embedded Element Call bundle. |
| **3.6** Testing | Full test cycle across devices/iOS versions | **IN PROGRESS** | 962 tests run, 899 passed, 63 pre-existing failures, 0 new. Builds 1-4 on TestFlight. Push E2E verified. CallKit deferred (Element Call widget issue). |
| **3.7** Release build | Version, signing, validation | **DONE** | Archive build succeeded. Distribution signing works. Version 1.0.0 (Build 5 ready). |
| **3.8** App Store publication | Listing, TestFlight, review, release | **IN PROGRESS** | ASC listing nearly complete. Pricing, privacy policy, support URL, review notes, encryption compliance all done. Only screenshots remaining (customer). AGPL confirmation expected. |

### Functionality (TOR Section 4)

All items 4.1-4.11 are **inherited from Element X and already functional**. No code changes needed — only verification testing against customer's server.

| Feature | TOR Section | Element X Status | Fork Verification |
|---------|-------------|-----------------|-------------------|
| Registration | 4.1 | Works | Needs server test |
| Login/OIDC | 4.2 | Works | **VERIFIED** — OIDC login working on simulator + device |
| Sliding Sync | 4.3 | Works | **VERIFIED** — room list loads via Sliding Sync |
| Messaging (text, media, reactions, read receipts) | 4.4 | Works | **VERIFIED** — customer testing Build 2-4 |
| Room management | 4.5 | Works | **VERIFIED** — customer testing |
| User profile | 4.6 | Works | **VERIFIED** — customer testing |
| 1:1 calls | 4.7 | Works (MatrixRTC) | LiveKit confirmed in `.well-known` |
| Group calls | 4.7 | Works (Element Call) | LiveKit confirmed, needs call test |
| Push notifications | 4.8 | APNs code done | E2E blocked on customer Sygnal `type: apns` config (D-002) |
| Background updates | 4.9 | Works | Needs server test |
| Settings | 4.10 | Works | Analytics/bug reports disabled per customer request |
| E2EE, Keychain, PIN/biometric | 4.11 | Works | Needs server test |

### Results (TOR Section 7)

| Requirement | Status | Gap |
|-------------|--------|-----|
| 7.1 App in App Store | **IN PROGRESS** | ASC nearly complete. Only screenshots remaining. AGPL confirmation expected. |
| 7.2 All functionality works | **MOSTLY VERIFIED** | OIDC, Sliding Sync, messaging, rooms, profiles, push all verified. CallKit deferred to next sprint (Element Call widget issue). |
| 7.3 Stability/quality | **IN PROGRESS** | 962 tests, 0 new failures. Customer testing Builds 2-4. 6 customer-reported issues fixed. |
| 7.4 Apple compliance | **DONE** | Encryption compliance uploaded. ASC listing complete. Age rating set. Privacy Nutrition Labels completed. Pricing set. |
| 7.5 Branding matches customer | **DONE** | Display name "UCMeet.Chat", new 3D logos, accent color #003B5D, 47 Compound token overrides, zero Element branding visible. |
| 7.6 Source code + build docs | **DONE** | 30+ docs + build & handover guide (`build_and_handover_guide.md`) |
| 7.7 Maintenance guidance | **DONE** | Upstream sync documented in handover guide, `/upstream-sync` command available |

---

## 2. Hours: Invested vs. Remaining

### Hours Invested (as of 2026-03-27)

| Category | Hours | Deliverables |
|----------|-------|-------------|
| Project setup (fork, build env, first build) | ~8h | Working build on simulator |
| Codebase audit & mapping | ~10h | 8 audit docs, 97 identifiers, change map |
| Firebase FCM implementation | ~8h | Full code + 14 unit tests + protocol extraction |
| Automation scripts | ~6h | `rebrand.sh` (712 lines) + `rebrand_strings.sh` (560 lines) |
| Privacy manifest fixes | ~1h | 3 targets with complete manifests |
| Upstream syncs (3 total) | ~6h | 120+ commits merged, SDK v26.03.10 |
| Customer documents | ~3h | Briefing + questionnaire + App Store guide (Russian) |
| App Store prep + ASC listing | ~7h | Templates, listing filled, encryption compliance, review info |
| Documentation overhead | ~6h | Plans, overview, progress tracking, sprints |
| Claude Code commands | ~1h | 6 project-specific slash commands |
| Server config + OIDC login | ~4h | AppSettings configured, OIDC login working, Firebase crash fix |
| Calls + localization + cleanup | ~3h | URL scheme, knownHosts, 34 locales removed, domains cleaned |
| String rebranding + Swift cleanup | ~3h | 30 string replacements (en, en-US, ru), 10 Swift source refs cleaned |
| Unit test fixes | ~2h | 16 test assertions updated, PRODUCT_MODULE_NAME + TEST_HOST fix |
| App display name + branding audit | ~1h | APP_DISPLAY_NAME → UCMeet, full branding audit |
| Launch screen + checkpoint + handover guide | ~2h | Launch screen verified, checkpoint tag, 10-section build guide |
| Platform restrictions + push hardening | ~1h | Mac/Vision Pro disabled, push gateway URL, dynamic NSE notification ID |
| Bundle ID application + casing fix | ~6h | 22 files updated, display name, dispatch queue labels, casing corrections |
| New logos + accent color + Compound overrides | ~5h | 2 logos, 24 SwiftUI + 23 UIKit token overrides, send button gradient |
| Apple Developer Portal + Xcode signing | ~7h | 3 Bundle IDs, App Group, signing resolved, OIDC redirect fix |
| Sprint 5 release prep | ~3h | Version 1.0.0, CI/CD trim, Archive build, NSE entitlement fix |
| TestFlight uploads (Builds 1-4) | ~3h | 4 builds uploaded, compliance wizard, customer testing |
| Customer issue fixes (Builds 3-4) | ~3h | OIDC name, analytics, bug reports, MapTiler, 17 translations, color overrides |
| Push E2E debugging + APNs switch | ~3h | ntfy diagnosis, FCM v1 diagnosis, APNs switch, Sygnal instructions |
| CallKit investigation + MSC4075 research | ~4h | Full push/CallKit code audit, API event query, MSC4075 is client-side discovery |
| ASC finalization + Android migration guide | ~4h | Review notes, pricing, privacy labels, Android fork guide (1000+ lines) |
| **Total invested** | **~104h** | |

### Remaining Work Estimate

| Task | Est. Hours | Blocker |
|------|-----------|---------|
| Build 5 upload to TestFlight | ~1h | None |
| AGPL source code link in app (after confirmation) | ~1h | Customer AGPL call |
| Fix bugs from customer testing (if any) | ~2-4h | Customer feedback |
| App Store submission + review response | ~2-4h | Screenshots from customer |
| Final handover documentation | ~1h | None |
| **Total remaining** | **~6-10h** | |

### Project Totals

| Metric | Value |
|--------|-------|
| Original estimate (with AI) | 60-95h, expected ~80h |
| Original estimate (without AI) | 85-132h, expected ~120h |
| Hours invested so far | ~104h |
| Hours remaining (estimated) | ~6-10h |
| **Projected total** | **~110-114h** |
| Budget position | Above AI-assisted range (60-95h), within non-AI range (85-132h) |
| Budget consumed | ~87% of hours |

> Over-run vs AI-assisted estimate driven by: extensive push debugging (ntfy → FCM → APNs, 3 E2E test cycles), 3 upstream syncs (120+ conflicts), 6 customer-reported issue rounds, 30+ documentation files. Core dev work was on-estimate; iteration with customer and server-side issues added ~20h.

---

## 3. Critical Path

### Dependency Chain (Updated 2026-03-27)

```
✅ All developer-side code work DONE
    |
    |---> D-001 licensing → 🟡 Customer claims resolved, need written confirmation
    |
    |---> D-002 Push E2E → 🟡 Customer must configure Sygnal `type: apns` + .p8 key
    |       |
    |       +---> Push E2E test on two real devices
    |
    |---> Customer items for ASC:
    |       |---> Screenshots (6.7" + 5.5" with device frames)
    |       |---> Privacy Nutrition Labels questionnaire
    |       +---> Review contact (first name, last name, email)
    |
    +---> All above resolved → Submit to App Store → Review → Release
```

**The critical path is now entirely on the customer side:**
Customer Sygnal config + screenshots + Privacy Labels + AGPL confirmation → App Store submission → Review → Release

**Licensing (D-001) runs in parallel** but must be resolved before submission.

### Remaining Actions

| Action | Owner | Blocker | Time to complete |
|--------|-------|---------|-----------------|
| Upload Build 5 to TestFlight | Developer | None | ~1h |
| Add AGPL source code link in app | Developer | AGPL confirmation call | ~1h |
| Provide screenshots (6.5" iPhone + 13" iPad) | Customer | None — expected in coming days | Customer action |
| Written AGPL confirmation | Customer | Upcoming call | Customer action |
| Submit to App Store | Developer | Screenshots + AGPL | ~1h |
| **Active developer time remaining** | | | **~6-10h** |

---

## 4. Decision Impact Analysis

| Decision | Best Case | Worst Case | Impact | Status |
|----------|-----------|------------|--------|--------|
| **D-001 Licensing** | Customer has commercial license | License doesn't cover Element X | **PROJECT KILLER** for App Store | 🟡 Customer claims resolved |
| **D-002 Push/APNs** | Customer configures Sygnal, push works | Sygnal incompatible with APNs | +1-2 days debugging | 🟡 Awaiting customer Sygnal `type: apns` config |
| **D-003 iOS 18.0+** | ~~Customer accepts~~ | ~~Customer insists on iOS 16~~ | ~~N/A~~ | ✅ Resolved |
| **D-004 Calls** | ~~LiveKit deployed~~ | ~~No LiveKit~~ | ~~N/A~~ | ✅ Resolved + configured |
| **D-005 Servers** | ~~All ready~~ | ~~Not set up~~ | ~~N/A~~ | ✅ Resolved + configured |
| **D-006 OIDC** | ~~MAS works~~ | ~~No OIDC~~ | ~~N/A~~ | ✅ Resolved + login verified |
| **D-007 Apple Account** | ~~Developer's account ready~~ | ~~No account~~ | ~~N/A~~ | ✅ Resolved (Administrator access) |
| **D-008 Design** | ~~Assets arrive~~ | ~~Design delayed~~ | ~~N/A~~ | ✅ Resolved — logos + accent color applied |

### Kill Scenarios (project cannot complete)

1. **Element refuses commercial license AND customer won't open-source AND customer won't accept legal risk** — No path to App Store.
2. ~~**Customer insists on iOS 16**~~ — Resolved (iOS 18.0+ accepted).
3. ~~**Customer's server doesn't support Sliding Sync**~~ — Resolved (Sliding Sync confirmed).

---

## 5. TOR Discrepancy Resolution Status

| # | TOR Requirement | Reality | Resolution Path | Status |
|---|----------------|---------|----------------|--------|
| 1 | iOS 16+ | iOS 18.0+ | ✅ Customer accepted | Resolved |
| 2 | FCM push | APNs direct (FCM abandoned due to Sygnal GCM pushkin incompatibility) | App registers APNs token, Sygnal uses `type: apns` | Code done, E2E blocked on customer |
| 3 | Jitsi for calls | Element Call (LiveKit) | ✅ LiveKit confirmed + configured | Resolved |
| 4 | Scalar integration | Not in Element X | ✅ Dropped — Scalar is legacy | Resolved |
| 5 | OIDC not mentioned | OIDC is primary auth | ✅ MAS login working on simulator + device | Resolved |
| 6 | AGPL v3 awareness | AGPL conflicts with App Store | Customer claims resolved — need written confirmation | In progress |

---

## 6. Timeline Projections (from 2026-04-05)

### Scenario A: Best Case (1 week)

- Customer provides screenshots this week
- AGPL confirmed after call
- App Store approved on first submission

```
Week 9 (current): Screenshots arrive, AGPL confirmed, Build 5 uploaded, submit
Week 10: Approval, release
Total project: ~9-10 weeks (Feb 8 - Apr 14)
```

### Scenario B: Expected Case (2 weeks)

- Screenshots arrive within days
- App Store requires 1 revision (Guideline 4.3 differentiation)

```
Week 9 (current): Screenshots arrive, AGPL confirmed, submit
Week 10: Guideline 4.3 revision, resubmit, approval
Total project: ~10-11 weeks (Feb 8 - Apr 21)
```

### Scenario C: Worst Case (3+ weeks)

- Customer delays on screenshots
- Multiple App Store rejections
- AGPL confirmation stalls

```
Week 9-10: Waiting for customer items
Week 11: Submit, review cycles
Week 12: Approval
Total project: 12+ weeks (Feb 8 - May+)
```

### Summary

| Scenario | Total Project Duration | Active Dev Hours | Calendar End |
|----------|----------------------|-----------------|-------------|
| Best | 9-10 weeks | ~110h | Mid-April |
| Expected | 10-11 weeks | ~112h | Late April |
| Worst | 12+ weeks | ~114h+ | May+ |

**Developer-side work is essentially complete.** Only 2 blockers remain: screenshots (customer) and AGPL confirmation (upcoming call). CallKit deferred to next sprint. ASC listing is ready to submit once screenshots are uploaded.

---

## 7. Risk Register

| # | Risk | Probability | Impact | Status vs. Mar 3 | Mitigation Done |
|---|------|-------------|--------|-------------------|-----------------|
| 1 | **AGPL/App Store conflict** | Medium | Critical | **UNCHANGED** | Need written confirmation covering Element X specifically |
| 2 | **Guideline 4.3 rejection** | Medium | High | **UNCHANGED** | Differentiation strategy + rejection response template prepared |
| ~~3~~ | ~~**FCM complications**~~ | ~~N/A~~ | ~~N/A~~ | **RESOLVED** | ✅ FCM abandoned, switched to direct APNs (Mar 26) |
| ~~4~~ | ~~**Backend not ready**~~ | ~~N/A~~ | ~~N/A~~ | **RESOLVED** | ✅ Server verified, login working, `.well-known` confirmed |
| ~~5~~ | ~~**OIDC complexity**~~ | ~~N/A~~ | ~~N/A~~ | **RESOLVED** | ✅ OIDC login working via MAS, custom URL scheme |
| 6 | **SDK incompatibilities** | Low | High | **UNCHANGED** | Upstream synced to v26.03.10 (20 commits behind, sync planned) |
| ~~7~~ | ~~**LiveKit unavailable**~~ | ~~N/A~~ | ~~N/A~~ | **RESOLVED** | ✅ LiveKit confirmed in `.well-known`, URL scheme configured |
| 8 | **Multiple review cycles** | High | Medium | **UNCHANGED** | App Store listing pre-filled, review notes and credentials entered |
| ~~9~~ | ~~**Late design assets**~~ | ~~N/A~~ | ~~N/A~~ | **RESOLVED** | ✅ New 3D logos + accent color applied |
| 10 | **XcodeGen/SPM failures** | Low | Medium | **UNCHANGED** | Build verified 10+ times after changes |
| ~~11~~ | ~~**Customer engagement delay**~~ | ~~N/A~~ | ~~N/A~~ | **RESOLVED** | ✅ Customer responded Feb 16 |
| 12 | **Export control/sanctions** | Low | High | **REDUCED** | Encryption compliance document uploaded to ASC, `ITSAppUsesNonExemptEncryption=YES` |
| ~~13~~ | ~~**Bundle ID delay**~~ | ~~N/A~~ | ~~N/A~~ | **RESOLVED** | ✅ Bundle ID registered, cascaded, signing works |

---

## 8. Codebase Metrics

| Metric | Value |
|--------|-------|
| Total Swift files | ~1,260 |
| Test files | 162 |
| Tests run | 962 (899 passed, 63 pre-existing failures, 0 new) |
| Documentation files | 30+ |
| Automation scripts | 2 (1,272 lines total) |
| Localization locales | 3 (en, en-US, ru) — trimmed from 37 |
| Associated domains | 0 — all removed (matrix.to non-functional, webcredentials not needed) |
| Remaining `element.io` in production Swift | ~10 (OIDC URLs intentional, Compound library previews) |
| Remaining `io.element.elementx` identifiers | 0 — all migrated to `org.ucmeet.UCMeetChat` |
| User-visible Element branding | 0 |
| Upstream divergence | 60 ahead, 0 behind (as of Mar 17 sync; 20 new upstream commits since) |
| TestFlight builds | 4 uploaded (1.0.0 Builds 1-4) |
| Git tags (fork-specific) | 3 (`checkpoint/unmodified-build`, `backup/pre-upstream-sync-20260211`, `checkpoint/branding-complete`) |

---

## 9. Conclusions (2026-03-27)

**The project is ~99% code-complete. All developer-side work is done. Remaining items are on the customer side.**

1. **All branding work is done.** New 3D logos, accent color #003B5D, display name "UCMeet.Chat", 47 Compound token overrides (24 SwiftUI + 23 UIKit), send button gradient navy blue. Zero user-visible Element branding.

2. **Push switched from Firebase to APNs (Mar 26).** After 3 E2E test cycles (ntfy rejection, FCM v1 payload incompatibility), app now registers APNs device token directly. Sygnal must use `type: apns` with .p8 key. Firebase SDK retained but unused for push delivery.

3. **App Store Connect fully prepared.** App created (Apple ID: 6759875787), listing filled (RU+EN descriptions, keywords, copyright, URLs), encryption compliance uploaded, review credentials entered, age rating 14+, all countries enabled.

4. **7 of 12 decisions resolved** (D-003, D-004, D-005, D-006, D-007, D-008, D-011). 3 in progress (D-001 licensing, D-002 push E2E, D-009 listing details). 2 open (D-010, D-012).

5. **Hours tracking:** ~96h invested vs 60-95h AI-assisted estimate. Projected total ~106-111h. Over-run driven by push debugging iterations, 3 upstream syncs, and 6 rounds of customer issue fixes — not core development.

6. **All remaining blockers are on customer side:**
   - Sygnal `type: apns` configuration + push E2E test
   - Screenshots (6.7" + 5.5" with device frames)
   - Privacy Nutrition Labels questionnaire in ASC
   - Review contact (first name, last name, email)
   - Written AGPL confirmation
   - ucmatrix.org confirmation (for permalink redirect)
   - MapTiler paid plan decision (for static map previews)

**Recommended immediate actions (all customer):**
1. Configure Sygnal iOS with `type: apns`, install .p8 key, restart, re-login, test push on two devices.
2. Provide 6.7" + 5.5" device-framed screenshots from TestFlight.
3. Complete Privacy Nutrition Labels in App Store Connect.
4. Provide review contact name + email.
5. Send written AGPL v3 licensing confirmation.

---

## Progress History

| Date | Analysis Summary |
|------|-----------------|
| 2026-02-12 | Initial progress analysis. 4/15 init steps done, 1 partial. ~45-48h invested (~37% budget). 0/12 decisions resolved. Project maximally prepared for customer engagement. Estimated ~55h remaining active work. Timeline: 7-10 weeks total (best/expected). |
| 2026-02-17 | Major progress after customer response. 7/15 init steps done, 4 mostly done, 1 partial. ~56-59h invested (~58% budget). 5/12 decisions resolved. Server configured, OIDC login verified, calls configured, 34 locales removed, associated domains cleaned, 30 strings rebranded, 10 Swift refs cleaned. Estimated ~39h remaining. Timeline: 6-8 weeks total (best/expected). Critical path: Bundle ID + Apple Developer account. |
| 2026-02-17 | Unit test fixes for rebrand. 962 tests run, 16 failures caused by our changes fixed across 5 test files (AppRouteURLParserTests, ServerConfirmationScreenViewModelTests, ServerConfirmationScreenViewStateTests, LocalizationTests, AuthenticationServiceTests). All 33 affected tests now passing. ~57-60h invested (~59% budget). |
| 2026-02-17 | App display name + branding audit. Changed APP_DISPLAY_NAME/PRODUCTION_APP_NAME → "UCMeet" in app.yml (propagates to main app, NSE, ShareExtension). Verified on simulator: iOS Settings shows "< UCMeet". Full branding audit: **zero user-visible Element branding remains**. NSE/ShareExtension audit: clean. ~58-61h invested (~60% budget). |
| 2026-02-17 | Launch screen verified clean (plain background). Checkpoint tag `checkpoint/branding-complete` created. Build & handover guide written (10 sections). TOR 7.6 (source + docs) and 7.7 (maintenance) now DONE. ~60-63h invested (~62% budget). |
| 2026-02-18 | Platform restriction + push notification hardening. Disabled Mac/Vision Pro "Designed for iPad" compatibility. Push gateway URL → `matrix.ucmeet.org`. NSE notification ID → dynamic bundle identifier. ~61-64h invested (~63% budget). |
| 2026-02-20 | Customer provided "Forking Data.doc" — Bundle ID `org.ucmeet.ucmeetchat`, App Group `group.org.ucmeet`, Team `26UC01GH`, Display Name `UCMeet.Chat`. All cascaded through 22 files. 962 tests: 899 passed, 0 new failures. ~66-69h invested (~68% budget). |
| 2026-03-01 | Sprint planning docs + new logos + Bundle ID casing fix + accent color. Bundle ID corrected to `org.ucmeet.UCMeetChat` (20 files). New 3D logos installed (square AppIcon + circular in-app). Accent color → #003B5D (dark navy blue from logo). 3 new docs: sprints.md, dev_plan.md, appstore_connect_guide.md. D-008 resolved. 7/12 decisions now resolved. BUILD SUCCEEDED. ~69-72h invested (~72% budget). |
| 2026-03-02 | Apple Developer Portal: 3 Bundle IDs registered, App Group created, capabilities enabled. Access issue found — developer in ASC only, not Developer Program. APNs key + ASC API key received. ~72-75h invested (~75% budget). |
| 2026-03-03 | **Major unblocks:** (1) Xcode signing resolved — customer's Apple ID added to Xcode, automatic signing works for all 3 targets. (2) OIDC redirect URI fixed — custom URL scheme `org.ucmeet.UCMeetChat:/callback`, all OIDC metadata on ucmeet.org, removed webcredentials entitlement. (3) In-app logo sizing fixed — 330x330px @3x (was 1024px full-screen). (4) Firebase GoogleService-Info.plist replaced with real config. Login verified on simulator. ~76-79h invested (~78% budget). |
| 2026-03-13 | Upstream sync (89 commits, SDK v26.03.10). Sprint 5 release prep: version 1.0.0, Info.plist verified, debug log audit clean. ~82-85h invested. |
| 2026-03-17/18 | NSE entitlement removed. Push E2E tests (FCM pusher works, ntfy rejects). Second upstream sync (13 commits). Archive build succeeded. TestFlight Build 1 uploaded. App in ASC. Encryption compliance set. ~88-91h invested. |
| 2026-03-22 | Build 2 uploaded. ASC listing fully filled (RU+EN). Privacy manifests fixed. Encryption compliance uploaded. Customer added to TestFlight. ~91-93h invested. |
| 2026-03-24 | Build 3: 6 customer issues fixed (OIDC name, analytics, bug reports, maps, 13 translations, color overrides). Test infra fixed (PRODUCT_MODULE_NAME + TEST_HOST). ~94h invested. |
| 2026-03-25/26 | Push E2E #3: Sygnal GCM pushkin incompatible with FCM v1 payload format. **Switched from Firebase to direct APNs.** Build 4 uploaded. 4 more translations, send button gradient navy blue. ~96h invested (~80% budget). |
| 2026-03-27 | Documentation update: sprints.md, decisions_tracker.md, overall_implementation_progress.md refreshed to reflect APNs switch and Build 5 prep state. All developer-side work complete. ~96h invested. |

---

*This document is updated after each significant milestone, customer interaction, or periodic review. Next update: after Build 5 upload or App Store submission.*

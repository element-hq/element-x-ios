# Morning Plan — 10 February 2026

## Current Status

**ios_proj_init.md Steps 1–4: DONE.** Fork, build env, first build, codebase audit all complete.
**Steps 5–14: BLOCKED** by customer decisions (D-001 through D-012).
**Step 15: PARTIAL** — branching strategy and first checkpoint tag in place.

---

## Gap Analysis: ios_proj_init.md vs TOR

The 15-step init plan (`ios_proj_init.md`) covers **TOR sections 3.1–3.5** — code adaptation, branding, push plumbing, server config, and calls config. It ends at a branded, building app ready for server integration testing.

The following TOR deliverables are **NOT covered** by the 15 steps and require a continuation plan:

| TOR Section | Deliverable | Implementation Plan Phase |
|-------------|-------------|--------------------------|
| 3.6 | Full testing cycle (multi-device, multi-iOS, all features) | Phase 7 (Days 18–21) |
| 3.7 | Release build preparation (version, disable debug, validate IPA) | Phase 8 (Days 22–25) |
| 6.2–6.3 | Build config, profiling, optimization | Phase 8 (Days 22–25) |
| 6.4 | App Store metadata (descriptions RU+EN, screenshots, keywords) | Phase 8 (Days 22–25) |
| 6.5 | TestFlight beta testing with customer | Phase 9 (Days 26–27) |
| 6.6 | App Store review + rejection response | Phase 9 (Days 26–27 + buffer) |
| 6.7 | Publication (Ready for Sale, regional availability) | Phase 9 |
| 7.6 | Documentation + source code delivery | Phase 10 (Days 28–30) |
| 7.7 | Maintenance guidance (merge from upstream, cert renewal) | Phase 10 (Days 28–30) |
| 5.7 | AGPL licensing resolution | Phase 2 (parallel, checkpoints at Days 5/11/20/27) |

---

## Continuation Plan: Phases 7–10

### Phase 7 — Testing & QA (Days 18–21, ~16h)

**Prerequisite:** All branding, config, OIDC, push, and calls work from Steps 5–14 is complete and committed.

#### 7.1 Create Test Plan (Day 18, 2h)
Write structured test plan covering every TOR section 4.x requirement:

| Test Suite | TOR Ref | Test Cases |
|-----------|---------|------------|
| Auth | 4.1, 4.2 | Registration, OIDC login, session persist, token refresh, logout, re-login |
| Sync | 4.3 | Sliding Sync, room list load, history scroll, offline→online recovery |
| Messaging | 4.4 | 1:1 text, group text, E2EE, edit, delete, reactions, threads, quotes, forwarding |
| Media | 4.4 | Images (gallery + camera), video, files, voice messages, download, preview |
| Rooms | 4.5 | Create room, invite, join, leave, search, room settings, moderation |
| Profile | 4.6 | View profile, edit display name, change avatar, view sessions, device verification |
| Calls | 4.7 | 1:1 voice, 1:1 video, group call, incoming call notification, CallKit |
| Push | 4.8 | Foreground, background, killed state, tap-to-open, badge count, per-room mute |
| Settings | 4.10 | Notifications config, theme toggle, key backup/restore, rageshake |
| Security | 4.11 | E2EE indicators, key verification, keychain storage, permission prompts |

#### 7.2 Execute Test Suites (Days 18–19, 8h)
- Run each suite against customer's server infrastructure
- Record pass/fail per case
- Log bugs with severity (P0 blocker / P1 major / P2 minor / P3 cosmetic)

#### 7.3 Device Compatibility (Day 20, 4h)
Per TOR 3.6 and 6.3:
- Test on minimum supported device (likely iPhone SE 3rd gen or similar at iOS 18.5)
- Test on latest device (iPhone 17 Pro)
- Test on at least one non-Pro device (screen size difference)
- Verify Dynamic Type, dark mode, landscape behavior

#### 7.4 Bug Fixes & Regression (Day 21, 4h)
- Fix all P0 and P1 bugs
- Regression test affected areas
- Final visual QA pass (all screens, both themes)
- Sign off test plan — document known issues with severity

**Exit criteria:** Zero P0, zero P1, all test suites pass, known P2/P3 documented.

---

### Phase 8 — App Store Preparation (Days 22–25, ~16h)

#### 8.1 App Store Connect Setup (Day 22, 4h)
- Create app record in App Store Connect
- Set bundle ID, SKU, primary language (Russian + English)
- Write app description (RU + EN) — must differentiate from Element X per Guideline 4.3
- Set keywords, categories (Social Networking), age rating (12+ or 17+)
- Set support URL and privacy policy URL (customer-provided)

#### 8.2 Screenshots (Day 23, 4h)
Per TOR 6.4:
- Prepare demo content (realistic conversations, no sensitive data)
- Capture screenshots for required device sizes:
  - 6.7" (iPhone Pro Max)
  - 6.1" (standard iPhone)
  - iPad (if supporting iPad — TOR says "universal but no iPad-specific adaptation")
- Key screens: chat list, conversation, call screen, profile, settings
- Upload to App Store Connect for all supported localizations

#### 8.3 Privacy & Compliance (Day 24, 4h)
- Complete App Privacy questionnaire (data types: account info, messages, device ID)
- Set `ITSAppUsesNonExemptEncryption` in Info.plist (E2EE = yes, but may qualify for exemption)
- Verify Report/Block features work (critical for messaging app approval)
- Verify privacy policy URL is accessible and comprehensive
- Check all `NS*UsageDescription` strings in Info.plist (camera, microphone, photos, contacts)

#### 8.4 Release Build & Upload (Day 25, 4h)
Per TOR 3.7:
- Set version 1.0.0, build 1
- Disable debug logging, test modes
- Remove unused resources
- Archive with distribution signing
- Validate via Xcode Organizer (zero errors, zero warnings)
- Upload to App Store Connect via Xcode or Transporter
- Verify build processes without issues

**Exit criteria:** Build uploaded, metadata complete, privacy configured, screenshots uploaded.

---

### Phase 9 — Release & App Store Submission (Days 26–27 + buffer, ~8h + up to 40h)

#### 9.1 TestFlight Testing (Day 26, 4h)
Per TOR 6.5:
- Enable internal TestFlight testing
- Smoke test release build on physical device (login, message, push, call)
- Verify no debug artifacts, analytics disabled, no developer-only features
- Invite customer to external TestFlight (requires Beta App Review ~1 day)
- Customer tests and gives final approval

#### 9.2 App Store Submission (Day 27, 4h)
Per TOR 6.6:
- Write App Review notes:
  - Explain differentiation from Element X (Guideline 4.3)
  - Describe the customer's business use case
  - Provide server infrastructure context
- Create and verify demo account credentials
- Submit for review (select **manual release** for control)
- **Licensing checkpoint #4:** Confirm AGPL license resolved before release

#### 9.3 Review Response Cycles (Buffer Days 31–40, up to 40h)
Common rejection patterns for messenger forks:

| Rejection | Likelihood | Response |
|-----------|-----------|----------|
| **4.3 Design Spam** | HIGH | Strengthen differentiation in description, visual identity, review notes. Appeal if needed. |
| **Content moderation** | MEDIUM | Demonstrate Report/Block features, add screenshots to review notes |
| **Privacy labels** | MEDIUM | Audit and correct privacy declarations |
| **Encryption compliance** | LOW | File CCATS exemption or provide documentation |
| **Demo account broken** | LOW | Fix credentials, provide step-by-step instructions |

Allow 2–5 business days per review cycle. Budget for 1–3 rejection/resubmission rounds.

**Exit criteria:** App approved, status "Pending Developer Release" or "Ready for Sale".

---

### Phase 10 — Documentation & Handover (Days 28–30, ~12h)

#### 10.1 Configuration Guide (Day 28, 4h)
Per TOR 7.6 — customer must be able to rebuild independently:
- Build instructions (Xcode version, XcodeGen, SPM resolution)
- How to change: app name, icon, accent color, homeserver URL
- How to change: OIDC settings, push config, calls config
- File paths for every configurable value
- How to regenerate `.xcodeproj` after YAML changes

#### 10.2 Server Requirements Document (Day 28, included above)
- Matrix homeserver configuration requirements
- Sygnal push gateway setup with APNs credentials
- OIDC client registration requirements
- Element Call / LiveKit setup
- TURN/STUN server requirements
- `.well-known` file contents and hosting instructions

#### 10.3 Maintenance Guide (Day 29, 4h)
Per TOR 7.7:
- How to merge updates from upstream Element X (complexity, conflict areas)
- How to renew signing certificates and provisioning profiles
- How to push new builds to App Store (version bump, archive, upload)
- How to respond to App Store review issues
- Troubleshooting guide: push not working, OIDC errors, build failures, cert expiration

#### 10.4 Source Delivery & Handover (Day 30, 4h)
- Clean source code archive (verify builds from clean checkout)
- Transfer/share Git repository access
- Handover meeting with customer:
  - Walk through app functionality
  - Walk through documentation
  - Walk through App Store Connect
  - Transfer all credentials (APNs key, certificates, etc.)
- Obtain customer sign-off on deliverables

**Exit criteria:** All documentation delivered, source code transferred, customer acknowledges receipt.

---

## Summary: Effort by Phase

| Phase | Days | Hours | Blocked By |
|-------|------|-------|------------|
| 7. Testing & QA | 18–21 | 16h | Steps 5–14 complete |
| 8. App Store Prep | 22–25 | 16h | Phase 7 sign-off |
| 9. Release | 26–27 + buffer | 8h + up to 40h | Phase 8 complete + AGPL license |
| 10. Documentation | 28–30 | 12h | Can start in parallel with Phase 9 |
| **Total** | | **52h + up to 40h buffer** | |

## Combined Project Completion Checklist

When ALL of the following are true, the TOR is 100% fulfilled:

- [ ] Steps 1–14 of `ios_proj_init.md` complete (branded, configured app)
- [ ] Step 15 checkpoint tags all created
- [ ] Phase 7: All test suites pass, zero P0/P1 bugs
- [ ] Phase 8: App Store listing complete with metadata + screenshots
- [ ] Phase 9: App approved and published in App Store
- [ ] Phase 9: AGPL licensing resolved
- [ ] Phase 10: Configuration guide delivered
- [ ] Phase 10: Maintenance guide delivered
- [ ] Phase 10: Source code delivered to customer
- [ ] Phase 10: Customer sign-off obtained

---

*Created: 2026-02-10. This plan supplements ios_proj_init.md (Steps 1–15) and aligns with implementation_plan.md (Days 18–30 + buffer).*

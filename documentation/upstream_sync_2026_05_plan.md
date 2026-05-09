# Upstream Sync Plan — May 2026 (target: `release/26.05.0`)

> **Status:** Plan only. No work executed yet. Awaiting decisions on §"Open questions for the user" before kick-off.
>
> **Author:** iOS team (Saidakhror) with planning support.
> **Date prepared:** 2026-05-10.
> **Last upstream sync:** 2026-03-17 (13 commits, SDK to 26.03.10).
> **This sync target:** upstream `release/26.05.0` (May 2026).

---

## 1. Context — why now

We're 270 commits behind `upstream/develop` (and 267 commits behind the May release tag). That's the largest gap since the project started — roughly 8 weeks of upstream activity. Material changes incoming include:

- **Matrix Rust SDK bumps** to 26.04.16 → 26.04.23 → 26.04.28 → 26.05.06 (we're on 26.03.10).
- **OIDC → OAuth rename** (#5525, #5497, #5391, #5545) — large auth refactor with API breaks.
- **Compound design tokens v8 → v10.1.1** — multiple major versions affecting our 24+23 colour overrides in `CompoundHook.swift`.
- **Xcode 26.2 → 26.4 requirement** — upstream forced this in `release/26.04.1` (#5375). **Hard prerequisite.**
- **Live Location Sharing graduation** — feature flag removed; LLS now permanently on (#5370).
- **Multi-window support fixes** for iPad/Mac.
- **iOS 26 cold-start crash fix** (keyWindow nil).
- **Route-handling logs** added in upstream (#5504) — same area we just added our own logs on `feature/universal-links-ucmatrix`. Guaranteed merge conflict in `AppCoordinator.swift`.
- 6 batches of upstream translation updates → 6 large rounds of locale-file noise that we re-trim each sync.
- Various smaller dep bumps: PostHog v3.56-3.57.2, MapLibre v6.26.0, EmbeddedElementCall, XcodeGen.

Why sync now and not later: every week we delay, the gap grows ~30-40 commits, conflict density compounds, and security/SDK fixes pile up. Customer is in App Store and we want their next update to roll forward cleanly.

**Outcome we want:** `develop` rebased on top of upstream's May 2026 release point, all our customizations preserved (rebrand, OIDC config, push provider, ucmatrix.org permalinks, navy blue colours, trimmed locales, Russian translations, Universal Links code), full test suite green relative to baseline, manual smoke tests pass on simulator.

---

## 2. Strategy — recommended approach

### 2.1 Merge target: `upstream/release/26.05.0`

Recommended over `upstream/develop` tip because:
- Bounded, stable, tagged.
- Only 3 commits behind dev tip — marginal cost.
- Easier to communicate ("we're on 26.05.0").
- Cleaner basis for the next sync.

The 3 omitted commits (caption fade scroll, MapLibre 6.26.0, Enterprise submodule update) can be picked up in the next sync; nothing user-facing critical is lost.

### 2.2 Merge, not rebase

Hard recommendation: `git merge --no-ff`. Rebasing 91 of our commits onto upstream multiplies conflicts ~10x and buries our customization history. Merge produces one explicit "merge upstream" commit that ops can later inspect.

### 2.3 Dedicated sync branch

Recommended branching:

```
develop
  └─ chore/upstream-sync-2026-05    ← all sync work happens here
       (PR → develop after green build + tests)
```

Then **after** that PR merges to `develop`, propagate to the unmerged feature branch:

```
feature/universal-links-ucmatrix
  └─ git merge develop              ← second-stage merge for the 5 overlap files
       (PR → develop after re-verification)
```

Why two stages, in this order:
- The Universal Links branch is blocked on customer's AASA deployment for E2E. We don't want to delay the sync waiting on ops.
- Doing them sequentially keeps each PR's diff scoped and reviewable.
- The second-stage merge will be much smaller (5 files we know upfront) and predictable.

### 2.4 Rollback plan

Tag `checkpoint/pre-sync-2026-05` at current `develop` HEAD before starting. If the sync goes sideways:
- Abandon `chore/upstream-sync-2026-05` (no one but us has seen it).
- `develop` is unchanged.
- Universal Links branch is unchanged.

Existing checkpoint tags (`checkpoint/branding-complete`, `checkpoint/unmodified-build`) remain untouched.

---

## 3. Pre-flight checklist (must complete before kicking off)

| # | Item | Owner | Notes |
|---|---|---|---|
| 1 | **Confirm Xcode 26.4 available locally** | Saidakhror | `xcodebuild -version`. If on 26.2, install 26.4 first. May require macOS 26.x. **Hard blocker.** |
| 2 | Confirm xcodegen 2.44.1+ still works (upstream bumped XcodeGen #5520 — check version requirement) | Saidakhror | `xcodegen --version` |
| 3 | Verify clean working tree on `develop` | Saidakhror | Stash or commit anything pending. Currently dirty: `.claude/settings.local.json` (local config — leave). |
| 4 | Push `feature/universal-links-ucmatrix` to origin (latest 10 commits) | Saidakhror | ✅ Already done as of 2026-05-10. |
| 5 | Tag pre-sync checkpoint | Saidakhror | `git tag checkpoint/pre-sync-2026-05 develop && git push origin checkpoint/pre-sync-2026-05` |
| 6 | Confirm answers to §11 "Open questions" with user | Saidakhror + customer | Sync target, LLS feature acceptance, time budget |
| 7 | Confirm customer is OK with potential temporary build interruption | Saidakhror + customer | If sync takes 2 days and a hotfix is needed in between, we may need to branch from pre-sync tag |
| 8 | Block calendar: 1.5–2 days for focused execution | Saidakhror | See §10 |

---

## 4. Execution plan — 8 phases

### Phase 0 — Prep (15 min)

```bash
git checkout develop
git pull --ff-only origin develop
git fetch upstream --tags
git tag checkpoint/pre-sync-2026-05
git push origin checkpoint/pre-sync-2026-05
git checkout -b chore/upstream-sync-2026-05
```

Verify environment:
```bash
xcodebuild -version              # must be 26.4+
xcodegen --version               # 2.44.1+
git status                       # clean
```

### Phase 1 — Discovery & risk-mapping (30 min, no code changes)

Read upstream's `CHANGES.md` between our last sync point and `release/26.05.0` to surface any breaking changes the commit list didn't make obvious.

Read the four OAuth-related upstream PRs (#5497, #5525, #5391, #5545) to understand the rename scope:
- Are types/methods renamed or just re-aliased?
- Is `OIDCConfiguration` deprecated, removed, or kept as an alias?
- Does the new `OAuthPresenterHook` give us a cleaner override point than what we use today?

Read commits touching `CompoundHook.swift` adjacency (token version bumps) to see if v10.1.1 changed the colour-token names we override.

Output: a short "merge brief" — if any decision points emerge that differ from this plan, surface them before doing the merge.

### Phase 2 — The merge attempt (15 min — produces conflicts to resolve)

```bash
git merge upstream/release/26.05.0 --no-ff --no-commit
```

This will produce conflicts. Don't commit yet. Get the full picture:

```bash
git status --short | grep "^UU\|^AA\|^DD\|^DU\|^UD" | sort
```

Categorize conflicts (predicted from §6 conflict map). Triage in this order:

1. **Trivial**: Locale files we deleted, upstream re-added — `git rm` them all in one batch (132 files).
2. **Mechanical**: Workflows, .gitignore, README, project.pbxproj — accept upstream where it doesn't undo our customizations; otherwise prefer ours.
3. **Surgical**: AppSettings.swift, target.yml, AppCoordinator.swift, AppRoutes.swift — preserve our customizations while integrating upstream's new code.
4. **Hard**: CompoundHook.swift (if token names changed), OIDC→OAuth migration, NSE entitlements.

### Phase 3 — Conflict resolution (4–6 hours)

File-by-file (see §6 conflict map for full list and treatment). Key areas:

#### 3.1 Locale files — bulk re-trim
```bash
# Re-trim everything outside en, en-US, ru
ls ElementX/Resources/Localizations/ | grep -v -E "^(en|en-US|ru)\.lproj$" | while read d; do
    git rm -rf "ElementX/Resources/Localizations/$d"
done
# Then carefully merge en/en-US/ru changes from upstream while preserving our additions
```

For en/en-US/ru: `git checkout --conflict=diff3 <files>` to see both sides, then manually merge. Preserve our 14+4 added Russian strings (room: "Ваши пространства", "Sharing options" → Russian, etc. — see CLAUDE.md changelog).

#### 3.2 `app.yml` / `target.yml` / `entitlements`
Preserve:
- `BASE_BUNDLE_IDENTIFIER: org.ucmeet.UCMeetChat`
- `APP_GROUP_IDENTIFIER: group.org.ucmeet`
- `DEVELOPMENT_TEAM: 6HRG779SDK`
- `APP_NAME: UCMeet.Chat`
- All entitlement removals we made (`com.apple.developer.usernotifications.filtering` in NSE).
- `ITSAppUsesNonExemptEncryption: YES` in Info.plist + plist properties.

Accept upstream:
- New build settings if any.
- New BGTaskScheduler identifiers if any.

#### 3.3 `AppSettings.swift`
Preserve:
- Homeserver: `https://matrix.ucmeet.org`
- OIDC redirect URI: `org.ucmeet.UCMeetChat:/callback`
- Push provider: `.apns` (NOT `.firebase`)
- Push gateway: `https://push.ucmeet.org`
- Analytics: PostHog/Sentry/rageshake all `nil`
- All legal URLs (privacy, support, marketing)

Migrate carefully:
- If OIDC config was renamed to OAuthConfiguration, update our redirect URI in the new place.
- If new feature flags were added (LLS removed, room directory search permanent), accept upstream defaults.

#### 3.4 `AppCoordinator.swift`
This is the highest-risk single file. Upstream made 14 changes; we made 1 (the new log line in `handleDeepLink`).

- Take upstream's structure (multi-window, OAuth rename, route logging).
- Re-apply our `MXLog.info` for the unhandled-URL fall-through case (preserve the diagnostic value).
- Verify `handleDeepLink` signature didn't change (it's called from Application.swift's modifier).

#### 3.5 `AppRoutes.swift`
Preserve `UCMatrixPermalinkParser` (lines 177-189). Verify the parser chain order in `route(from:)` still includes it. If upstream added new parsers (e.g., #5391's restored `.oidcCallback` route), insert them appropriately.

#### 3.6 `CompoundHook.swift` (potential heavy lift)
Run a diff between Compound v8/v9/v10 token names BEFORE merging. If token names changed:
- For each renamed token, find the new name and re-apply our navy blue (#003B5D) override.
- For removed tokens, drop the override.
- For added tokens that visibly affect colour, decide whether to override (default: leave upstream colour unless it's brand-green).

If unchanged: our overrides apply as-is.

#### 3.7 OIDC → OAuth migration
This may affect 8-12 files. Likely cases:
- `OIDCConfiguration.swift` → `OAuthConfiguration.swift` rename. If it's a pure rename, preserve our customizations in the new file.
- Symbol renames in OIDC-related screens, view models, services.
- `OIDCAuthenticationPresenter` → may become `OAuthAuthenticationPresenter`.

**Critical:** OIDC custom-scheme callback `org.ucmeet.UCMeetChat:/callback` MUST continue to work end-to-end. Smoke-test login on simulator before merging.

#### 3.8 Permalink files
8 files we modified for `matrix.to → ucmatrix.org` rewrite (URL.swift, AppRoutes.swift, JoinedRoomProxy.swift, MatrixUserShareLink.swift, RoomMemberProxyProtocol.swift, UserProfileScreenViewModel.swift, ComposerToolbarViewModel.swift, AttributedStringBuilder.swift). For each:
- Preserve every `.replacingMatrixToHost()` call.
- If upstream added new SDK calls that emit `matrix.to` URLs, find them via grep and add `.replacingMatrixToHost()`.

#### 3.9 NSE entitlements + target.yml
Preserve removal of `com.apple.developer.usernotifications.filtering` (we removed it because it requires Apple approval not granted to our App ID).

#### 3.10 SPM Package.resolved
Conflict expected. Resolution: take theirs (`git checkout --theirs Package.resolved`), then run `xcodegen generate && xcodebuild -resolvePackageDependencies` to regenerate cleanly.

#### 3.11 ElementX.xcodeproj/project.pbxproj
This file is regenerated by xcodegen. Take theirs initially (`git checkout --theirs ...`), then `xcodegen generate` to regenerate from our YAML configs. Verify the project opens in Xcode.

### Phase 4 — Build & sanity (1–2 hours)

```bash
xcodegen generate
xcodebuild -project ElementX.xcodeproj -scheme ElementX -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Compile errors expected after such a large merge — fix one by one. Common after OIDC→OAuth: missing imports, renamed types, removed deprecated APIs.

If SDK API breaks:
- Check `Update the SDK, handling OIDC/OAuth API breaks. (#5497)` PR for guidance.
- May need to update our SDK callsites in JoinedRoomProxy, AppCoordinator, etc.

### Phase 5 — Test gauntlet (1 hour)

```bash
xcodebuild test \
  -project ElementX.xcodeproj \
  -scheme UnitTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 | tee build/sync-test-output.log
```

Baseline (from CLAUDE.md): **962 tests, 899 passed, 63 known pre-existing failures, 0 new.**

Goal post-sync: 0 NEW failures. If failure count grows:
1. Run `grep "Test Case.*failed" build/sync-test-output.log | sort > new-failures.txt`
2. Compare to baseline list (we should snapshot the 63 pre-sync failures into `documentation/test-baseline-pre-sync-2026-05.txt` during Phase 0).
3. For each new failure, decide: is it (a) our merge mistake, (b) upstream test that doesn't apply to UCMeet (e.g., assumes Element web hosts we don't configure), or (c) genuine regression?
4. Fix (a). Document (b). Investigate (c).

Run AppRouteURLParserTests specifically — our 18 parser tests must still pass.

### Phase 6 — Manual smoke test on simulator (30 min)

| Flow | Expectation |
|---|---|
| App launches without crash | iOS 18+ simulator |
| Branding correct | Navy blue accent, UCMeet.Chat name, custom logos |
| OIDC/OAuth login | Custom-scheme callback `org.ucmeet.UCMeetChat:/callback` returns to app |
| Open a room | Room screen renders, messages display |
| Send a message | Goes through |
| Share permalink for a room | Generated link starts with `ucmatrix.org`, NOT `matrix.to` |
| Share permalink for a user | Same |
| Open a `ucmatrix.org` link via LLDB injection | App routes correctly (use commands from `universal_links_status.md` smoke checklist) |
| Russian locale | Russian strings render correctly, including 14+4 customer-added strings |
| Static map preview | Shows MapTiler interactive map (static previews known broken — pre-existing) |

### Phase 7 — Documentation (1 hour)

Update:
- `CLAUDE.md` — bump SDK version row to 26.05.06, add note about LLS being permanent if we accepted it, update "upstream divergence" line.
- `documentation/progress_log.md` — daily entry for sync date.
- `documentation/decisions_tracker.md` — journal entry summarizing the sync, called-out new features.
- `documentation/upstream_sync_report.md` — detailed report (see existing format from 2026-03-13 sync).
- `documentation/upstream_sync_2026_05_plan.md` (this file) — append "Execution log" section with what actually happened.
- This plan file: mark relevant sections "DONE" or "DEVIATED — see notes" as we execute.

### Phase 8 — PR, review, merge (30 min)

```bash
git push -u origin chore/upstream-sync-2026-05
gh pr create --base develop --title "Sync upstream → release/26.05.0" --body "$(cat <<'EOF'
## Summary
- Merge upstream/release/26.05.0 (267 commits): SDK 26.03.10 → 26.05.06, OIDC → OAuth rename, Compound design tokens v8 → v10.1.1, Xcode 26.4, Live Location Sharing graduated, multi-window support fixes.
- Preserved all UCMeet customizations: bundle ID, branding, OIDC config, push provider (APNs), ucmatrix.org permalinks, trimmed locales, Russian translations, navy blue color overrides, Universal Links work TBD via second-stage merge.

## Test plan
- [x] Unit tests pass (X new pre-existing failures from upstream test suite + 0 new from this sync)
- [x] AppRouteURLParserTests all green
- [x] App builds for iPhone 17 Pro simulator
- [x] OIDC login works end-to-end on simulator
- [x] ucmatrix.org permalinks still generated outgoing + parsed inbound
- [x] Russian locale renders correctly

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

After merge:
```bash
git checkout feature/universal-links-ucmatrix
git merge develop          # Second-stage merge for the 5 overlap files
# Resolve smaller conflict set (AppCoordinator.swift route logs, target.yml entitlements, AppRoutes.swift parser chain, AppRouteURLParserTests.swift, ElementX.entitlements)
xcodebuild test -only-testing:UnitTests/AppRouteURLParserTests
git push origin feature/universal-links-ucmatrix
```

---

## 5. File-by-file conflict map (the 37 non-locale overlaps)

Resolution legend:
- **OURS**: Keep our version, ignore upstream change in this file.
- **THEIRS**: Take upstream's version wholesale.
- **MERGE**: Manually combine — both sides have meaningful changes.
- **REGEN**: Regenerate from source (xcodegen, SPM resolve).

| File | Treatment | Notes |
|---|---|---|
| `.github/workflows/automatic-calendar-version.yml` | THEIRS | We don't customize CI. |
| `.github/workflows/integration-tests.yml` | THEIRS | Same. |
| `.github/workflows/post-release.yml` | THEIRS | Same. |
| `.github/workflows/translations-pr.yml` | THEIRS | Same. |
| `.github/workflows/triage_incoming.yml` | THEIRS | Same. |
| `.gitignore` | MERGE | Likely additive on both sides. |
| `app.yml` | MERGE | Preserve bundle ID, team ID, app name, app group; take upstream additions. |
| `ElementX.xcodeproj/project.pbxproj` | REGEN | Take theirs, then xcodegen generate. |
| `ElementX.xcodeproj/.../Package.resolved` | REGEN | Take theirs, then xcodebuild -resolvePackageDependencies. |
| `ElementX/Sources/AccessibilityTests/AccessibilityTestsAppCoordinator.swift` | MERGE | Test coordinator — verify our handleDeepLink stub still aligns. |
| `ElementX/Sources/Application/AppCoordinator.swift` | MERGE | **HARD**. Re-apply our diagnostic log; integrate upstream OAuth + multi-window + route-log changes. |
| `ElementX/Sources/Application/Navigation/AppRoutes.swift` | MERGE | Preserve UCMatrixPermalinkParser. Add upstream's new parsers in chain. |
| `ElementX/Sources/Application/Settings/AppSettings.swift` | MERGE | **HARD**. Preserve all customer config (homeserver, OIDC, push, analytics-disabled, legal URLs). Integrate upstream's new feature flags. |
| `ElementX/Sources/FlowCoordinators/UserSessionFlowCoordinator.swift` | MERGE | Verify any OAuth references match upstream new naming. |
| `ElementX/Sources/Mocks/Generated/GeneratedMocks.swift` | THEIRS | Sourcery-generated; will be re-generated. |
| `ElementX/Sources/Mocks/JoinedRoomProxyMock.swift` | MERGE | If upstream added methods, accept them. |
| `ElementX/Sources/Other/HTMLParsing/AttributedStringBuilder.swift` | MERGE | Preserve `.replacingMatrixToHost()` calls. |
| `ElementX/Sources/Other/InfoPlistReader.swift` | MERGE | Likely small additive change. |
| `ElementX/Sources/Screens/Authentication/ServerConfirmationScreen/ServerConfirmationScreenModels.swift` | MERGE | Auth-screen — verify no UCMeet-specific config got dropped. |
| `ElementX/Sources/Screens/CallScreen/View/CallScreen.swift` | MERGE | Preserve any UCMeet call-screen tweaks (none material AFAIK). |
| `ElementX/Sources/Screens/RoomScreen/ComposerToolbar/ComposerToolbarViewModel.swift` | MERGE | Preserve `.replacingMatrixToHost()` calls in mention-link generation. |
| `ElementX/Sources/Screens/UserProfileScreen/UserProfileScreenViewModel.swift` | MERGE | Same — preserve replacingMatrixToHost. |
| `ElementX/Sources/Services/Room/JoinedRoomProxy.swift` | MERGE | Preserve `.replacingMatrixToHost()` calls; accept SDK API changes. |
| `ElementX/Sources/Services/Room/RoomSummary/RoomSummaryProvider.swift` | THEIRS | We don't customize this. |
| `ElementX/Sources/Services/RoomDirectorySearch/RoomDirectorySearchProxy.swift` | THEIRS | Same. |
| `ElementX/Sources/Services/Timeline/TimelineItemProvider.swift` | THEIRS | Same. |
| `ElementX/Sources/UITests/UITestsAppCoordinator.swift` | MERGE | Test coordinator — same as accessibility variant. |
| `ElementX/Sources/UnitTests/UnitTestsAppCoordinator.swift` | MERGE | Same. |
| `ElementX/SupportingFiles/ElementX.entitlements` | MERGE | Preserve removed entitlements (was already done) and our new `applinks:ucmatrix.org` if Universal Links was already merged (NOT in this sync — see two-stage strategy). |
| `ElementX/SupportingFiles/Info.plist` | MERGE | Preserve `ITSAppUsesNonExemptEncryption: YES`. |
| `ElementX/SupportingFiles/target.yml` | MERGE | Preserve all entitlement customizations + APP_NAME + bundle ID. |
| `project.yml` | MERGE | Preserve top-level bundle ID, team ID. |
| `README.md` | MERGE | Preserve Secrets/Secrets.swift row, copyright deletion. |
| `UnitTests/Sources/AppRouteURLParserTests.swift` | MERGE | Preserve our 6+ ucmatrix.org and round-trip tests; integrate upstream's new test cases. **NOTE:** This file is also touched by the `feature/universal-links-ucmatrix` branch — second-stage merge will see this again. |
| `UnitTests/Sources/AuthenticationServiceTests.swift` | MERGE | OAuth-related rename impact. |
| `UnitTests/Sources/ServerConfigurationScreenViewStateTests.swift` | MERGE | Probably auto-resolves. |
| `UnitTests/Sources/ServerConfirmationScreenViewModelTests.swift` | MERGE | Same. |

Plus 132 locale files: bulk `git rm` for non-en/en-US/ru, then surgical merge for the three we keep.

---

## 6. Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| OIDC→OAuth rename breaks login flow | High | High (login is critical) | Smoke-test login first thing in Phase 6. Have rollback ready. |
| Compound v10 token names changed → branding broken | Medium | High (visual brand integrity) | Phase 1 reads token diff; if names changed, fix CompoundHook before merging UI |
| Xcode 26.4 not installed locally | Medium | Hard blocker | Pre-flight item #1. Install before starting. |
| SDK 26.05.06 has API breaks beyond what upstream PR docs cover | Medium | Medium | Read PR #5497 description first. Compile errors expected. Allocate Phase 4 time. |
| Multi-window support breaks our share extension | Low | Medium | Smoke-test sharing a URL into the app on simulator. |
| Our 14+4 Russian translations get clobbered by upstream's translation update | Medium | Low (visible regression but easy fix) | Snapshot `ru.lproj/Localizable.strings` BEFORE merge; diff after; re-apply our additions. |
| Universal Links code path conflicts with upstream's #5504 route logs | High | Low | Already known. Resolve in second-stage merge. |
| New upstream files we miss adopting break a future merge | Low | Medium | Phase 1 reads commit list end-to-end. |
| Test failure baseline drift makes triage hard | Medium | Low | Phase 0 snapshots current 63 failures into `documentation/test-baseline-pre-sync-2026-05.txt`. |
| Customer reports a hotfix-needed bug mid-sync | Low | Medium | Pre-sync checkpoint tag means we can branch from it for hotfixes without aborting the sync. |
| LLS feature now permanent, customer doesn't want it | Low | Medium | Open question for user. If they don't want it, may need to keep a feature flag or hide UI. |
| Apple Developer Portal capability mismatch after OAuth changes | Low | Medium | Verify in dev portal that our App ID still has all required capabilities. |
| Build artifact cache (DerivedData) corruption | Low | Low | Clear DerivedData before final test pass: `rm -rf ~/Library/Developer/Xcode/DerivedData/ElementX-*` |

---

## 7. Decision points the sync may surface (and our defaults)

| Decision | Default if user not consulted |
|---|---|
| Sync target: tag vs dev tip | Tag `release/26.05.0` |
| Live Location Sharing graduated to permanent | Accept (the customer hasn't said anything against location features; they wanted maps). Document in CLAUDE.md. |
| OAuthPresenterHook adoption | Investigate in Phase 1; if it's a cleaner override point than our current setup, use it. Otherwise keep what we have. |
| Multi-window support | Accept upstream defaults. Our app group/keychain config supports it. |
| Compound color tokens — broken overrides | If 1-3 tokens broken, fix and ship. If many broken, schedule a follow-up branding-refresh sprint. |
| New feature flags upstream added | Default to upstream's defaults; document in progress_log. |
| Xcode version: pin in CI to 26.4 | Yes, mirror upstream. |
| Translations PR workflow upstream re-added | Accept; we re-trim post-PR. |

---

## 8. Testing strategy

### 8.1 Pre-sync baseline

In Phase 0, capture:
```bash
xcodebuild test -project ElementX.xcodeproj -scheme UnitTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 | \
  grep "Test Case.*failed" | sort > documentation/test-baseline-pre-sync-2026-05.txt
```

This gives us the 63 known-failing tests by name.

### 8.2 Post-sync comparison

After Phase 5:
```bash
xcodebuild test ... 2>&1 | grep "Test Case.*failed" | sort > documentation/test-results-post-sync-2026-05.txt
diff documentation/test-baseline-pre-sync-2026-05.txt documentation/test-results-post-sync-2026-05.txt
```

Lines starting with `>` in the diff are NEW failures introduced or revealed by the sync. Triage each.

### 8.3 Critical-path tests (must pass)

- `UnitTests/AppRouteURLParserTests` — all 10 (or all 18 if Universal Links got into develop somehow during sync window).
- `UnitTests/AuthenticationServiceTests` — proves OAuth rename didn't break us.
- `UnitTests/ServerConfirmationScreenViewModelTests` — proves homeserver/UCMeet config still works.
- Any test in the `Push*` family — proves APNs config unchanged.

### 8.4 Critical-path manual flows (must work)

See Phase 6 table.

---

## 9. Rollback plan

Three layers of safety:

1. **Branch isolation:** all sync work in `chore/upstream-sync-2026-05`. `develop` remains pristine until PR is merged.
2. **Pre-sync tag:** `checkpoint/pre-sync-2026-05` lets us reset develop to its current state if the post-merge `develop` ever proves problematic.
3. **Force-push protection:** never force-push to `develop` or `main`. If the sync PR introduces a bug post-merge, we revert via `git revert -m 1 <merge-commit>`.

If we get stuck mid-resolution and want to start over:
```bash
git merge --abort
# or, if we already committed:
git reset --hard develop
git merge upstream/release/26.05.0 --no-ff --no-commit
```

---

## 10. Time budget

**Estimate: 8–14 hours of focused work**, spread over 1.5–2 calendar days.

| Phase | Estimate |
|---|---|
| 0 — Prep | 15 min |
| 1 — Discovery | 30 min |
| 2 — Merge attempt | 15 min |
| 3 — Conflict resolution | 4–6 hours |
| 4 — Build & sanity | 1–2 hours |
| 5 — Test gauntlet | 1 hour |
| 6 — Manual smoke | 30 min |
| 7 — Documentation | 1 hour |
| 8 — PR & merge | 30 min |
| **Subtotal sync** | **8–11 hours** |
| 9 — Second-stage merge into `feature/universal-links-ucmatrix` | 1–3 hours |
| **TOTAL** | **9–14 hours** |

Risk multiplier for the worst-case scenario (Compound tokens fully restructured, SDK API breaks ripple through many files, OAuth migration touches more than expected): up to **20 hours**. Plan for the worst, hope for the best.

---

## 11. Open questions for the user

These are decisions I'd rather not make alone before committing to the plan. Tagging each with my recommendation and the rationale:

### Q1. Sync target — `release/26.05.0` (tag) or `upstream/develop` (tip)?

**My recommendation:** `release/26.05.0`. Bounded, stable, only 3 commits behind tip; cleaner basis for the next sync. The 3 omitted commits are non-critical.

### Q2. Live Location Sharing — accept upstream's graduation to permanent feature?

Upstream removed the LLS feature flag (commits #5370 area). Once we sync, LLS is permanently enabled in our app — users can share their live location during a session. **My recommendation:** accept (it's already a feature in the upstream app the customer chose to fork). Mention it in the changelog so they know.

But: if the customer has any privacy concerns or wants it disabled, we'd need to either hide the UI or keep the feature flag downstream. That's a small extra cost (~1 hour) to maintain.

### Q3. Block customer ops on Universal Links AASA deployment vs proceed independently?

**My recommendation:** proceed independently. Sync work shouldn't be gated on customer ops timelines. The two-stage merge (sync first → develop → then propagate to Universal Links branch) handles this cleanly.

### Q4. Time/scheduling — single 2-day session or split across multiple shorter sessions?

A 2-day focused window minimizes context-switching cost (after a merge starts, holding the conflict map in your head matters). But if your week doesn't allow that, the merge can be paused on a feature branch indefinitely.

**My recommendation:** ideally 1.5-2 contiguous days. If that's not possible, split between Phase 0-3 (merge mechanics, ~1 day) and Phase 4-8 (testing + ship, ~half day) at most.

### Q5. Compound color tokens — what if v10 broke our overrides?

**My recommendation:** if it's 1-5 tokens broken, fix during the sync (still in Phase 3). If it's 10+ tokens broken (token system was substantially refactored), accept upstream defaults temporarily and schedule a "branding refresh" sprint (Sprint 7?) to re-apply navy blue brand. Notify the customer either way.

### Q6. OAuthPresenterHook — investigate adoption?

Upstream added (#5545) a new "Hook" extension point for OAuth presentation. We have a similar pattern (`CompoundHook`) for color overrides. **My recommendation:** Phase 1 spend 15 min reading the PR; if it gives us a cleaner customization surface (e.g., we can use it instead of forking AuthenticationStartScreen), adopt it. Otherwise leave alone.

---

## 12. Summary — what I need from you to start

1. **Confirm or change my recommendations on Q1–Q6 above** (default to my recommendations if no objection).
2. **Confirm Xcode 26.4 is installed locally** (or schedule the upgrade).
3. **Block 1.5–2 days on the calendar** for the focused execution window.
4. **Approve the plan** (or call out concerns with specific phases).

After that, the work follows the 8 phases above. I'll capture an "Execution log" section at the bottom of this file as I go, and update CLAUDE.md / decisions_tracker / progress_log per Phase 7.

---

*Plan prepared 2026-05-10. Approved-by: TBD. Executed-by: TBD. Execution start: TBD.*

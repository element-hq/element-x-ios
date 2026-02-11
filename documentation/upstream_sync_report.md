# Upstream Sync Report — Element X iOS

## Summary

**Fork point:** Commit `7c96ebfca` ("Fix a retain cycle in SecureBackupController") — Feb 6, 2026
**Report date:** Feb 11, 2026
**New upstream commits:** 18 (pushed Feb 9–10, 2026)

---

## 1. Upstream Commits Since Fork

| Hash | Description | Area |
|------|-------------|------|
| `4116ee8` | Prepare next release (version 26.02.1 → 26.02.2) | Release |
| `071a1ee` | Remove global UserIndicatorController.alertInfo, replace with local usage (#5087) | Architecture |
| `b725d8b` | Make space feature flags volatile, initialized to true by default | Settings |
| `2cd58b9` | Enable spaces second iteration feature flags | Settings |
| `17cc41e` | More Space UI tweaks (#5086) | Spaces |
| `617fa27` | **Update SDK to MatrixRustSDK v26.02.10** (#5081) | SDK |
| `9ced1cf` | Always present space selection even for pre-selected spaces | Spaces |
| `591ce39` | Add rounded rect border around space avatars | Spaces |
| `20a84dd` | **Fix multiple server confirmation crashes** | Bug Fix |
| `32ec97a` | **Make PassthroughWindow work correctly on iOS 26** | Bug Fix |
| `35800ed` | Translations update | Localization |
| `db3a623` | Renamed function to resetRoomList | Refactor |
| `d6c5799` | Update preview tests | Tests |
| `c9cd4cb` | Updated space selection UI, pagination, access defaults | Spaces |
| `14845d5` | Auto-dismiss UserDetailsEditScreen after saving (#5073) | UX |
| `e23685b` | Show empty state when space has no children | Spaces |
| `2dfda98` | Treat NotFound error as expired in QR/Link sign-in | Bug Fix |
| `4b4b060` | Space tweaks (#5068) | Spaces |

---

## 2. Changes by Area

### Spaces Feature (~10 commits)
- Space selection UI, pagination, filtering, avatars
- Feature flags enabled and made volatile
- SpaceRoomCell, SpaceHeaderView, LoadableAvatarImage refactored

### SDK Update (1 commit, significant)
- MatrixRustSDK bumped from v26.02.03 to **v26.02.10**
- `project.yml` modified, `Package.resolved` updated
- `JoinedRoomProxy.swift` simplified (pinned events defaults)

### Architecture Refactoring (1 commit, wide impact)
- `UserIndicatorController.alertInfo` removed globally
- Replaced with local `alertInfo` on `NavigationRootCoordinator`
- **Files touched:** AppCoordinator.swift, GeneratedMocks.swift, NavigationRootCoordinator.swift, UserSessionFlowCoordinator.swift, UserIndicatorController.swift, OIDCAuthenticationPresenter.swift

### Bug Fixes (3 commits)
- Server confirmation crashes fixed (ServerConfirmationScreenViewModel.swift)
- PassthroughWindow iOS 26 compatibility (WindowManager.swift)
- QR/Link sign-in NotFound error handling (AuthenticationService.swift, LinkNewDeviceService.swift)

### Release Preparation (1 commit)
- Version bumped to 26.02.2 in `project.yml` and `project.pbxproj`
- CHANGES.md updated

---

## 3. Security & Stability Fixes

| Commit | Severity | Description |
|--------|----------|-------------|
| `20a84dd` | Medium | Fixes multiple server confirmation crashes (Sentry-reported) |
| `2dfda98` | Low | QR/Link sign-in: treats NotFound as expired session |
| `32ec97a` | Medium | iOS 26 PassthroughWindow compatibility fix |
| `617fa27` | Medium | SDK update v26.02.10 (may contain security fixes) |

---

## 4. Conflict Analysis with Our Fork

### Files Modified by BOTH Fork and Upstream

| File | Our Change | Upstream Change | Risk |
|------|-----------|----------------|------|
| `AppCoordinator.swift` | Firebase notification service injection, FCM push provider logic | Replaced `userIndicatorController.alertInfo` with `navigationRootCoordinator.alertInfo` | **MEDIUM** — different parts of file |
| `AppSettings.swift` | Added `PushProvider` enum and push provider setting | Changed 3 space feature flags to volatile storage | **LOW** — different sections |
| `GeneratedMocks.swift` | Added `FirebaseNotificationServiceMock` | Removed `alertInfo` from `UserIndicatorControllerMock` | **LOW** — different mock sections |
| `project.yml` | Changed deployment target, removed macOS/visionOS | SDK version bump, marketing version to 26.02.2 | **MEDIUM** — same YAML structure |

### No Conflict (Upstream-Only Changes)
NavigationRootCoordinator.swift, UserSessionFlowCoordinator.swift, UserIndicatorController.swift, OIDCAuthenticationPresenter.swift, WindowManager.swift, ServerConfirmationScreenViewModel.swift, JoinedRoomProxy.swift, AuthenticationService.swift, LinkNewDeviceService.swift, all Space UI files, CHANGES.md

---

## 5. Recommendation

**Sync is recommended but not urgent.**

### Arguments FOR Syncing Now
- SDK update (v26.02.03 → v26.02.10) likely contains bug fixes
- Crash fixes improve stability
- Only 18 commits — manageable merge
- The `UserIndicatorController` refactoring touches `AppCoordinator.swift` which we modified — merging now while changes are small minimizes conflict complexity

### Arguments for WAITING
- Rebranding blocked by customer decisions anyway
- Our fork changes are isolated (Firebase + documentation)
- Upstream changes are primarily Spaces feature (not infrastructure)

### Recommended Approach

```bash
git remote add upstream https://github.com/element-hq/element-x-ios.git
git fetch upstream
git checkout develop && git merge upstream/main
# Resolve 3-4 file conflicts (AppCoordinator, AppSettings, GeneratedMocks, project.yml)
# Then rebase feature branches onto updated develop
# Verify build succeeds after merge
```

Estimated conflict resolution time: **15–30 minutes**.

---

*Last updated: 2026-02-11*

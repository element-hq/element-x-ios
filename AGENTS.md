# AGENTS.md — Element X iOS

> **Repo:** `element-hq/element-x-ios` — iOS Matrix client (SwiftUI + `matrix-rust-sdk`).
> **Keep current:** Change break fact here — path, command, convention, structure? Fix that fact, same PR. Change not described here? Leave file alone. Edit file? Use caveman skill — match terse voice. No caveman, no edit.

---

## Strong Conventions

PRs must follow rules. Prefer Xcode MCP tools over terminal commands.

### Code Style

- **SwiftLint** (.swiftlint.yml) + **SwiftFormat** (.swiftformat) enforce style on build. Warnings show in Xcode. Build before **XcodeRefreshCodeIssuesInFile**.
- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) everywhere, Rust SDK wrappers too (`ID` not `Id`, `URL` not `Url`, `configuration` not `config` or `cfg`).
- File headers live in `IDETemplateMacros.plist`.

### Comments

- **Code speak for itself** — doc comments fine, but no comments restating what clear code already says.
- **Do** comment when code hides trap, hard to follow, or choice needs justifying.
- Comments short — one line where possible. Exceed only when truly needed.

### PII & Logging

- Default: `MXLog.info`. Unexpected failures: `.error`. Noisy dev logs: `.verbose`. `.failure`/`.debug` rare.
- **Never log secrets, passwords, keys, user content** (e.g. message bodies).
- Action enums with secret associated values **must** conform `CustomStringConvertible` (log only case name).
- Matrix IDs safe to log.

### Strings & Localisation

- Default localisation: `en` (en-GB strings), shared with Element X Android via [Localazy](https://localazy.com/p/element).
- **Never edit `Localizable.strings`** — auto-overwritten.
- New English strings → **`Untranslated.strings`** (plurals: `Untranslated.stringsdict`). Team imports to Localazy before merge.
- Access strings via generated `L10n` types (e.g. `L10n.actionDone`).
- **Key naming** (see [element-x-android README](https://github.com/element-hq/element-x-android/blob/develop/tools/localazy/README.md#key-naming-rules)):
  - Cross-screen verbs: `action_`. Nouns/other: `common_`. Accessibility: `a11y_`.
  - Key match string, e.g. `action_copy_link` → `Copy link`.
  - Screen-specific: `screen_<name>_<free>` (e.g. `screen_onboarding_welcome_title`).
  - Errors: `error_` prefix or `_error_` infix.
  - iOS-only: `_ios` suffix. Android-only: `_android` suffix.
  - Placeholders: always numbered form `%1$@`, `%1$d`. Use `%x$@` in iOS source; add translator comment `Localazy: change %x$@ -> %x$s`.

### Previews

- Previews for **all main states**.
- Use `PreviewProvider` (not `#Preview`) — snapshot/accessibility tests generated from it.
- Add `TestablePreview` conformance → snapshot + accessibility tests generated.

---

## Pull Request Guidelines

- Sentence-style titles (no conventional commits).
- Exactly one `pr-` label (see `.github/release.yml`).
- Title = changelog entry — descriptive, no "Fixes #…".
- Leave description template for developer. Point them to [contributing etiquette](CONTRIBUTING.md#etiquette).
- Screenshots/videos for visual changes.
- 500 additions max — split big changes.
- Commits need title + description. No tiny commits, no massive commits.
- No history rewrites.

---

## Project Structure

### Build System

Initial setup: `swift run tools setup-project`

**Git hooks** installed by `swift run tools setup-project`, run SwiftLint/SwiftFormat on commit. Hook fail? **Do not abandon changes** — fix reported issues, recommit.

| Tool | Command | Notes |
|------|---------|-------|
| **XcodeGen** | `xcodegen` | Generates Xcode project from `project.yml` (includes `app.yml` + `target.yml` files) |
| **Sourcery** | `sourcery --config Tools/Sourcery/<config>` | Configs: `AutoMockableConfig.yml`, `PreviewTestsConfig.yml`, `TestablePreviewsDictionary.yml`, `AccessibilityTests.yml`. Auto-runs on ElementX build. |
| **SwiftGen** | `swiftgen config run --config Tools/SwiftGen/swiftgen-config.yml` | Auto-runs on ElementX build. |
| **SwiftLint** | `swiftlint` | Auto-runs on ElementX build |
| **SwiftFormat** | `swiftformat .` | Run from project root only. Auto-runs in lint mode on ElementX build. |

CI test commands:
- Unit tests: `swift run tools ci unit-tests`
- CI help: `swift run tools ci --help`

### Targets & Layout

Key targets (each has `target.yml`):
- **ElementX** — main app
- **NSE** — Notification Service Extension
- **ShareExtension** — Share Extension

Each target: `Sources/`, `Resources/`, `SupportingFiles/`.

```
ElementX/Sources/
├── Application/         # App lifecycle, settings, windowing, root coordinators
├── FlowCoordinators/    # Flow coordinators + state machines
├── Services/<Feature>/  # SDK proxies, app services, non-view logic
├── Screens/<Screen>/    # View, ViewModel, Coordinator, Models per screen
├── Other/               # Shared extensions, utilities, SwiftUI helpers
└── {Unit|UI|A11y}Tests/ # Testing infrastructure 
```

Mocks, test helpers, generated files live next to sources in `Generated/` directories. Test suites in dedicated targets.

### Swift Packages

1. **`compound-ios/`** — Compound design system (local package, all UI styling).
2. **`Tools/Sources/`** — Developer CLI helpers.

### Dependencies

- **matrix-rust-sdk** source: [`matrix-org/matrix-rust-sdk`](https://github.com/matrix-org/matrix-rust-sdk).
- Binary builds (xcframework + Swift bindings): [`element-hq/matrix-rust-components-swift`](https://github.com/element-hq/matrix-rust-components-swift), imported via `project.yml`.
- SDK hash for build: cross-reference components version in `project.yml` with its tag in components repo. Hash in commit message.

---

## Architecture: MVVM-C

Every screen = **MVVM-Coordinator**. Template: `Tools/Scripts/Templates/SimpleScreenExample/` + `createScreen.sh`.

### Files Per Screen (`Foo`)

| File | Purpose |
|------|---------|
| `FooScreenModels.swift` | `ViewState`, `ViewStateBindings`, `ViewAction` enum, `ViewModelAction` enum |
| `FooScreenViewModelProtocol.swift` | Protocol: `actionsPublisher`, `context` |
| `FooScreenViewModel.swift` | Concrete VM subclassing `StateStoreViewModelV2` |
| `FooScreen.swift` (in `View/`) | SwiftUI view taking `@Bindable var context` |
| `FooScreenCoordinator.swift` | Owns VM, subscribes to actions, exposes own `actionsPublisher` |
| `FooScreenViewModelTests.swift` | Unit tests (UnitTests target) |

### Data Flow

```
View ──send(viewAction:)──► ViewModel ──actionsPublisher──► Coordinator ──actionsPublisher──► FlowCoordinator
     ◄──viewState──────────                                                                         │
     ◄──$context.bindings──►                                                              StateMachine<State,Event>
```

### StateStoreViewModelV2

Lives at `ElementX/Sources/Other/SwiftUI/ViewModel/StateStoreViewModelV2.swift` (uses Swift `Observation`):

- `state` — mutable state struct conforming `BindableState`
- `context` — `@Observable` class passed to view:
  - `context.viewState` — read-only state
  - `context.send(viewAction:)` — sends action to view model
  - `$context.<binding>` — two-way SwiftUI bindings
  - `context.mediaProvider` — optional media service
- Override `process(viewAction:)` for incoming actions.
- Use `PassthroughSubject<ViewModelAction, Never>` to notify coordinator.

> Some screens still use older `StateStoreViewModel.swift` (Combine/`ObservableObject`).

### Screen Coordinator

```swift
final class FooScreenCoordinator: CoordinatorProtocol {
    private let parameters: FooScreenCoordinatorParameters
    private let viewModel: FooScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<FooScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<FooScreenCoordinatorAction, Never> { actionsSubject.eraseToAnyPublisher() }
    
    init(parameters: FooScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = FooScreenViewModel(/* dependencies */)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in /* map to coordinator actions */ }
            .store(in: &cancellables)
    }

    func toPresentable() -> AnyView { AnyView(FooScreen(context: viewModel.context)) }
}
```

### Error Presentation

1. **SwiftUI Alerts** — add `AlertInfo` to `bindings`. Present with one-liner in view.
2. **User Indicators** (via `UserIndicatorController`):
   - `.toast` — pill at top of screen (errors)
   - `.modal` — not for errors (or actual modal). Blocking overlay for waiting.

---

## Flow Coordinators & Navigation

### FlowCoordinatorProtocol

```swift
@MainActor protocol FlowCoordinatorProtocol {
    func start(animated: Bool)
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool)
    func clearRoute(animated: Bool)
}
```

### State Machines

Uses `StateMachine<State, Event>` from [`ReactKit/SwiftState`](https://github.com/ReactKit/SwiftState):
- `State`/`Event` enums defined inside flow coordinator, conforming `StateType`/`EventType`.
- Simple transitions: `addRoutes(event:transitions:)`. Associated values: `addRouteMapping`.
- `addErrorHandler` should `fatalError` on unexpected transitions.

### Navigation Coordinators

| Type | SwiftUI Equivalent | Usage |
|------|--------------------|-------|
| `NavigationStackCoordinator` | `NavigationStack` | Push/pop within flow |
| `NavigationSplitCoordinator` | `NavigationSplitView` | iPad split view |
| `NavigationTabCoordinator` | `TabView` | Tab navigation |
| `NavigationRootCoordinator` | Root view | Switch app root (e.g. auth → session) |

### CommonFlowParameters

Shared dependency bag for **flow coordinators only**. Never pass to screen coordinators or view models — they get specific dependencies via their `Parameters` struct.

### AppRoute (Deep Linking)

`AppRoute` enum = deep-link destinations. Handled in `handleAppRoute` by rebuilding coordinators, clearing stack, or no-op.

---

## The Rust SDK Layer

### Proxy Pattern (uniffi::Object)

| Layer | Example | Location |
|-------|---------|---------|
| Protocol | `ClientProxyProtocol` | defines interface |
| Proxy | `ClientProxy` | wraps SDK type, in `Services/<Feature>/` |
| Mock | `ClientProxyMock` | Sourcery-generated |

Naming: SDK type name + `Proxy` suffix (e.g. `Client` → `ClientProxy`). Exceptions where specialisation needed (e.g. `JoinedRoomProxy`, `InvitedRoomProxy`).

### Type Mapping (uniffi::Record/Enum)

Map SDK types to app-owned Swift types (no `MatrixRustSDK` import in views):
- `init(rustValue:)` — from SDK
- `var rustValue` — back to SDK

### Wrapping Guidelines

- `Result<T, E>` with typed errors (no bare `throws`).
- `async` only when Rust method async.
- Prefer computed `var` over methods for simple properties.
- Map FFI types: `String` → `URL`, timestamp `UInt64` → `Date`, etc.
- Follow Swift API naming (`userID` not `userId`).

---

## Services

Live in `ElementX/Sources/Services/<Feature>/`.

1. **Pure app services** (e.g. `AppLockService`) — no SDK involvement.
2. **SDK-wrapping services** — compose proxies with app logic. Keep view models simple/testable.

Services = where product-level opinions live (Rust SDK stays spec-faithful).

### Dependency Injection

- Inject via `init` parameters.
- Screen coordinators get `Parameters` struct with specific dependencies.
- `CommonFlowParameters` flow-coordinator-only.
- `ServiceLocator` **deprecated** — never use services directly. Always inject from above.

---

## Concurrency & Actors

- All targets **Swift 6.2**, approachable concurrency.
- **ElementX** app, **UnitTests** + **PreviewTests**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — no redundant `@MainActor`. Other targets (incl. app extensions) nonisolated.
- Services + data-layer types: `nonisolated` + `Sendable` when background work need.
- Never `@unchecked Sendable` / `nonisolated(unsafe)`. Dev add these.
- `actor` types rare in codebase.

---

## Compound Design System

`compound-ios/` provides **all** UI styling. Use Compound. Deviate only when no equivalent exists.

### Tokens (`.compound` namespace)

- **Colours:** `Color.compound.textPrimary`, `.bgCanvasDefault`, …
- **Fonts:** `Font.compound.bodyLG`, `.headingMDBold`, `.bodySMSemibold`, …
- **Icons:** key paths on `CompoundIcons` (e.g. `\.userProfile`). Always use `CompoundIcon(\.iconName)` (handles Dynamic Type scaling).

### Key Components

| Component | Notes |
|-----------|-------|
| `ListRow` | Primary list/form building block. Label styles: `.default`, `.plain`, `.action`, `.centeredAction`. Kinds: `.label`, `.button`, `.textField`, `.toggle`, etc. |
| `.compoundList()` | Styles `Form`/`List` with Compound tokens |
| `.compoundListSectionHeader/Footer()` | Section header/footer styling |
| `CompoundButtonStyle` | Styles: `.primary`, `.secondary`, `.tertiary`, `.super`, `.textLink`. Sizes: `.large`, `.medium`, `.small`, `.toolbarIcon` |
| `CompoundToggleStyle` | `.toggleStyle(.compound)` |
| `CompoundIcon` | Sizes: `.xSmall` (16pt), `.small` (20pt), `.medium` (24pt), `.custom(CGFloat)` |
| `SendButton` | Specialised send button for message composition |
| `Label` with icon keypaths | `Label("Title", icon: \.userProfile)` uses `CompoundIcon` internally |

### Example

```swift
Form {
    Section {
        ListRow(label: .default(title: "Setting", icon: \.settings),
                kind: .navigationLink { /* action */ })
        ListRow(label: .default(title: "Toggle", icon: \.notifications),
                details: .isWaiting(context.viewState.isLoading),
                kind: .toggle($context.isEnabled))
    }
}
.compoundList()
.navigationTitle("Settings")
```

See `compound-ios/Sources/Compound/` for full component set.

---

## Testing

Coverage target: **80%** (includes SDK, Compound, Rich Text Editor).
Project migrating from XCTest to **Swift Testing** (see PR #5119).

### Test Types

| Type | Location | Purpose |
|------|----------|---------|
| Unit Tests | `UnitTests/Sources/` | VM logic, state machines, services |
| UI Tests | `UITests/Sources/` | Flow coordinator integration (snapshots) |
| Preview Tests | `PreviewTests/Sources/` | Auto-generated snapshots from previews |
| Accessibility Tests | `AccessibilityTests/Sources/` | Auto-generated Xcode Accessibility Audits |

No `.serialized` suite traits needed — tests not run in parallel.

### Mocks

Generated by Sourcery (configs in `Tools/Sourcery/`). Files in `Generated/` directories.
- Un-configured methods crash on purpose.
- Common mocks have `Configuration`-based convenience `init`:
  ```swift
  let mock = ClientProxyMock(.init(userID: "@alice:example.com"))
  ```

### Async Testing

```swift
let deferred = deferFulfillment(context.observe(\.viewState.counter)) { $0 == 1 }
context.send(viewAction: .incrementCounter)
try await deferred.fulfill()
#expect(context.viewState.counter == 1)
```

Same pattern for publishers.

### Snapshots

- Stored in `<Target>/Sources/__Snapshots__/`, tracked via **Git LFS** (`git lfs install`).
- Re-record on correct device/OS if UI changes.
- Powered by [`pointfreeco/swift-snapshot-testing`](https://github.com/pointfreeco/swift-snapshot-testing). Failures produce 3 images: reference, failure, diff.

---

## Key Files

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen project (targets, packages, settings) |
| `app.yml` | App-level XcodeGen config |
| `.swiftlint.yml` | SwiftLint rules |
| `.swiftformat` | SwiftFormat rules |
| `Dangerfile.swift` | Danger PR checks |
| `Package.swift` | SPM manifest (Tools CLI) |
| `localazy.json` | Localazy translation config |
| `codecov.yml` | Codecov config |
| `.periphery.yml` | Periphery dead-code detection |

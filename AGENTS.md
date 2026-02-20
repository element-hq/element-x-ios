# AGENTS.md — Element X iOS

> **Audience:** AI coding agents. **Repo:** `element-hq/element-x-ios` — iOS Matrix client (SwiftUI + `matrix-rust-sdk`).

---

## Strong Conventions

PRs must meet these rules. Prefer Xcode MCP tools over terminal commands.

### Code Style

- Style enforced by **SwiftLint** (`.swiftlint.yml`) and **SwiftFormat** (`.swiftformat`).
- **Whitespace-only lines:** never strip indentation (Xcode's "Trim whitespace-only lines" is disabled). Adjusting indentation to match scope is fine; removing it causes PR rejection.
- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) everywhere, including Rust SDK wrappers (e.g. `ID` not `Id`, `URL` not `Url`, `configuration` not `config` or `cfg`).
- File headers defined in `IDETemplateMacros.plist`.

### PII & Logging

- Default: `MXLog.info`; unexpected failures: `.error`; noisy dev logs: `.verbose`. `.failure`/`.debug` rarely used.
- **Never log secrets, passwords, keys, or user content** (e.g. message bodies).
- Action enums with secret-containing associated values **must** conform to `CustomStringConvertible` (logs only case name).
- Matrix IDs are safe to log.

### Strings & Localisation

- Default localisation: `en` (en-GB strings), shared with Element X Android via [Localazy](https://localazy.com/p/element).
- **Never edit `Localizable.strings`** — it is auto-overwritten.
- New English strings go in **`Untranslated.strings`** (plurals: `Untranslated.stringsdict`). Team imports to Localazy before merge.
- Access strings via generated `L10n` types (e.g. `L10n.actionDone`).
- **Key naming** (see [element-x-android README](https://github.com/element-hq/element-x-android/blob/develop/tools/localazy/README.md#key-naming-rules)):
  - Cross-screen verbs: `action_`; nouns/other: `common_`; accessibility: `a11y_`.
  - Key matches the string, e.g. `action_copy_link` → `Copy link`.
  - Screen-specific: `screen_<name>_<free>` (e.g. `screen_onboarding_welcome_title`).
  - Errors: `error_` prefix or `_error_` infix.
  - iOS-only: `_ios` suffix; Android-only: `_android` suffix.
  - Placeholders: always use numbered form `%1$@`, `%1$d`. Use `%x$@` in iOS source; add translator comment `Localazy: change %x$@ -> %x$s`.

### Previews

- Create previews for **all main states**.
- Use `PreviewProvider` (not `#Preview`) — snapshot/accessibility tests are generated from it.
- Add `TestablePreview` conformance to generate snapshot and accessibility tests.

---

## Pull Request Guidelines

- Use sentence-style commit/PR messages (no conventional commits).
- Apply exactly **one** `pr-` label (see `.github/release.yml`).
- PR title = changelog entry — make it descriptive; no "Fixes #…" prefixes.
- Include screenshots/videos for visual changes.
- Keep PRs under 1000 additions; split large changes.

---

## Project Structure

### Build System

Initial setup: `swift run tools setup-project`

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
- Fastlane: `bundle exec fastlane lanes`

### Targets & Layout

Key targets (each has a `target.yml`):
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

Mocks, test helpers, and generated files live alongside sources in `Generated/` directories. Test suites are in dedicated targets.

### Swift Packages

1. **`compound-ios/`** — Compound design system (local package, all UI styling).
2. **`Tools/Sources/`** — Developer CLI helpers.

### Dependencies

- **matrix-rust-sdk** source: [`matrix-org/matrix-rust-sdk`](https://github.com/matrix-org/matrix-rust-sdk).
- Binary builds (xcframework + Swift bindings): [`element-hq/matrix-rust-components-swift`](https://github.com/element-hq/matrix-rust-components-swift), imported via `project.yml`.
- SDK hash for a given build: cross-reference the components version in `project.yml` with its tag in the components repo. Find hash in commit message.

---

## Architecture: MVVM-C

Every screen follows **MVVM-Coordinator**. Template: `Tools/Scripts/Templates/SimpleScreenExample/` + `createScreen.sh`.

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

Located at `ElementX/Sources/Other/SwiftUI/ViewModel/StateStoreViewModelV2.swift` (uses Swift `Observation`):

- `state` — mutable state struct conforming to `BindableState`
- `context` — `@Observable` class passed to the view:
  - `context.viewState` — read-only state
  - `context.send(viewAction:)` — sends action to view model
  - `$context.<binding>` — two-way SwiftUI bindings
  - `context.mediaProvider` — optional media service
- Override `process(viewAction:)` for incoming actions.
- Use `PassthroughSubject<ViewModelAction, Never>` to notify the coordinator.

> Some screens still use the older `StateStoreViewModel.swift` (Combine/`ObservableObject`).

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

1. **SwiftUI Alerts** — Add `AlertInfo` to `bindings`; present with a one-liner in the view.
2. **User Indicators** (via `UserIndicatorController`):
   - `.toast` — pill at top of screen (errors)
   - `.modal` — not for errors (or an actual model). Blocking overlay for waiting.

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
- `State`/`Event` enums defined inside the flow coordinator, conforming to `StateType`/`EventType`.
- Simple transitions: `addRoutes(event:transitions:)`. Associated values: `addRouteMapping`.
- `addErrorHandler` should `fatalError` on unexpected transitions.

### Navigation Coordinators

| Type | SwiftUI Equivalent | Usage |
|------|--------------------|-------|
| `NavigationStackCoordinator` | `NavigationStack` | Push/pop within a flow |
| `NavigationSplitCoordinator` | `NavigationSplitView` | iPad split view |
| `NavigationTabCoordinator` | `TabView` | Tab navigation |
| `NavigationRootCoordinator` | Root view | Switch app root (e.g. auth → session) |

### CommonFlowParameters

Shared dependency bag for **flow coordinators only**. Never pass to screen coordinators or view models — they receive specific dependencies via their `Parameters` struct.

### AppRoute (Deep Linking)

`AppRoute` enum represents deep-link destinations. Handled in `handleAppRoute` by rebuilding coordinators, clearing stack, or no-op.

---

## The Rust SDK Layer

### Proxy Pattern (uniffi::Object)

| Layer | Example | Location |
|-------|---------|---------|
| Protocol | `ClientProxyProtocol` | defines interface |
| Proxy | `ClientProxy` | wraps SDK type, in `Services/<Feature>/` |
| Mock | `ClientProxyMock` | Sourcery-generated |

Naming: SDK type name + `Proxy` suffix (e.g. `Client` → `ClientProxy`). Exceptions where specialisation is needed (e.g. `JoinedRoomProxy`, `InvitedRoomProxy`).

### Type Mapping (uniffi::Record/Enum)

Map SDK types to app-owned Swift types (avoids importing `MatrixRustSDK` in views):
- `init(rustValue:)` — from SDK
- `var rustValue` — back to SDK

### Wrapping Guidelines

- `Result<T, E>` with typed errors (no bare `throws`).
- `async` only when the Rust method is async.
- Prefer computed `var` over methods for simple properties.
- Map FFI types: `String` → `URL`, timestamp `UInt64` → `Date`, etc.
- Follow Swift API naming (`userID` not `userId`).

---

## Services

Located in `ElementX/Sources/Services/<Feature>/`.

1. **Pure app services** (e.g. `AppLockService`) — no SDK involvement.
2. **SDK-wrapping services** — compose proxies with app logic; keep view models simple/testable.

Services are where product-level opinions live (the Rust SDK stays spec-faithful).

### Dependency Injection

- Inject via `init` parameters.
- Screen coordinators get a `Parameters` struct with specific dependencies.
- `CommonFlowParameters` is flow-coordinator-only.
- `ServiceLocator` is **deprecated** — never use services directly; always inject from above.

---

## Concurrency & Actors

- Most protocols are `@MainActor`; conforming types inherit this.
- Views, screens, coordinators: always `@MainActor`.
- Some services are `nonisolated` for background work.
- `actor` types are rare in the codebase.

---

## Compound Design System

`compound-ios/` provides **all** UI styling. Use Compound; only deviate when no equivalent exists.

### Tokens (`.compound` namespace)

- **Colours:** `Color.compound.textPrimary`, `.bgCanvasDefault`, …
- **Fonts:** `Font.compound.bodyLG`, `.headingMDBold`, `.bodySMSemibold`, …
- **Icons:** key paths on `CompoundIcons` (e.g. `\.userProfile`). Always use `CompoundIcon(\.iconName)` (handles Dynamic Type scaling).

### Key Components

| Component | Notes |
|-----------|-------|
| `ListRow` | Primary list/form building block. Label styles: `.default`, `.plain`, `.action`, `.centeredAction`. Kinds: `.label`, `.button`, `.textField`, `.toggle`, etc. |
| `.compoundList()` | Styles a `Form`/`List` with Compound tokens |
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

See `compound-ios/Sources/Compound/` for the full component set.

---

## Testing

Coverage target: **80%** (includes SDK, Compound, Rich Text Editor).
Project is migrating from XCTest to **Swift Testing** (see PR #5119).

### Test Types

| Type | Location | Purpose |
|------|----------|---------|
| Unit Tests | `UnitTests/Sources/` | VM logic, state machines, services |
| UI Tests | `UITests/Sources/` | Flow coordinator integration (snapshots) |
| Preview Tests | `PreviewTests/Sources/` | Auto-generated snapshots from previews |
| Accessibility Tests | `AccessibilityTests/Sources/` | Auto-generated Xcode Accessibility Audits |

No need for `.serialized` suite traits, tests aren't run in parallel.

### Mocks

Generated by Sourcery (configs in `Tools/Sourcery/`); files in `Generated/` directories.
- Un-configured methods intentionally crash.
- Common mocks have a `Configuration`-based convenience `init`:
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
- Re-record on the correct device/OS if UI changes.
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
| `Gemfile` | Ruby deps (Fastlane, Danger) |
| `localazy.json` | Localazy translation config |
| `codecov.yml` | Codecov config |
| `.periphery.yml` | Periphery dead-code detection |
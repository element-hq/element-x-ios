# AGENTS.md — Element X iOS

> **Audience:** AI coding agents working on the project.
> **Repository:** `element-hq/element-x-ios` — A Matrix client for iOS built with SwiftUI on top of `matrix-rust-sdk`.

---

## Strong Conventions:

These rules must be met for a PR to be accepted. Always prefer the use of Xcode's MCP tools over executing commands in the terminal.

### Code Style

- Code style is enforced by **SwiftLint** (`.swiftlint.yml`) and **SwiftFormat** (`.swiftformat`). Follow their configuration.
- Whitespace-only lines: Do not remove indentation from blank/whitespace-only lines (we keep Xcode's "Trim whitespace-only lines" setting disabled).
  - It’s OK to add or adjust indentation on whitespace-only lines to match the surrounding scope, but never strip it.
  - PRs that remove indentation on whitespace-only lines will be rejected.
- Follow [Swift's API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) everywhere, including when wrapping Rust SDK types (e.g. use `ID` not `Id`, `URL` not `Url`).
- File headers are defined in `IDETemplateMacros.plist`.

### PII & Logging

- Use `MXLog.info` by default, `.error` for unexpected failures and `.verbose` for noisy development-only logs. `.failure` and `.debug` are rarely used.
- **NEVER log secrets, passwords, keys, or user content** (e.g. message bodies).
- Action enums with associated values containing secrets (passwords, keys, tokens) **MUST** conform to `CustomStringConvertible` so only the case name is logged, not the associated values. The template includes a comment reminding you of this.
- Matrix IDs are acceptable to log.

### Strings & Localisation

- The project's default localisation is `en` which contains en-GB strings.
- Strings are shared with Element X Android via [Localazy](https://localazy.com/p/element).
- **Never edit `Localizable.strings`** — it is overwritten when downloading from Localazy.
- Add new English strings to **`Untranslated.strings`** (or `Untranslated.stringsdict` for plurals). The team will import them into Localazy before merging.
- Strings are accessed via generated `L10n` types (e.g. `L10n.actionDone`).
- **Key naming rules** (from [element-x-android/tools/localazy/README.md](https://github.com/element-hq/element-x-android/blob/develop/tools/localazy/README.md#key-naming-rules)):
  - Common strings reusable across screens: start with `action_` (verbs) or `common_` (nouns/other).
  - Common accessibility strings: start with `a11y_` (e.g. `a11y_hide_password`).
  - Keys for common strings should be named to match the string. Example: `action_copy_link` for the string `Copy link`.
  - Screen-specific strings: start with `screen_` + screen name + free name (e.g. `screen_onboarding_welcome_title`).
  - Error strings: start with `error_` or contain `_error_` for screen-specific errors.
  - iOS-only strings: suffix with `_ios`. Android-only: suffix with `_android`.
  - Placeholders:
    - Use numbered form `%1$@`, `%1$d` etc.
    - Use %1$@ for strings in iOS source; Localazy expects %1$s. Add a translator comment: Localazy: change %@ -> %s.

### Previews

- Create previews for **all main states** a screen/view will be in.
- Use `PreviewProvider` (not `#Preview`) because snapshot/accessibility tests are generated from it.
- Adding a second conformance `TestablePreview` marks the to have snapshot and accessibility tests generated.

---

## Pull Request Guidelines

- Do not use conventional commit messages, prefer the use of sentences.
- Apply exactly **one** `pr-` label to categorise the changelog entry (mapping defined in `.github/release.yml`).
- The PR title becomes the changelog entry — make it descriptive and complete (no "Fixes #…" or conventional-commit prefixes).
- Include screenshots/videos for any visual changes.
- Keep PRs under 1000 additions when possible; split large changes.

---

## Project Structure

### Build System

- Run this first to set up all required tooling/dependencies:
  - `swift run tools setup-project`

The following tools are used to update the project. Commands must be run in the project's root directory.
- **XcodeGen** (generate Xcode project from `project.yml`):
  - Generate: `xcodegen`
  - Notes: `project.yml` contains project configuration and includes `app.yml` along with various `target.yml` files.
- **Sourcery** (generate mocks / preview tests / accessibility tests):
  - Generate: `sourcery --config Tools/Sourcery/{configuration}`
  - Configurations: AutoMockableConfig.yml, PreviewTestsConfig.yml, TestablePreviewsDictionary.yml, AccessibilityTests.yml
  - Notes: Automatically run by Xcode when building the ElementX target.
- **SwiftGen** (generate type-safe strings/assets):
  - Generate: `swiftgen config run --config Tools/SwiftGen/swiftgen-config.yml`
  - Notes: Automatically run by Xcode when building the ElementX target.
- **SwiftLint** (lint rules):
  - Lint: `swiftlint`
  - Auto-fix (if used): `swiftlint lint --fix`
- **SwiftFormat** (formatting):
  - Format: `swiftformat .`
  - Notes: Do *not* run this outside of the project directory.

Xcode Intelligence supplies tools to execute the tests. However on CI tests can be executed from the command line:
  - UnitTests: `swift run tools ci unit-tests`
  - Swift CI tools: `swift run tools ci --help`
  - Fastlane lanes: `bundle exec fastlane lanes`

### Targets & Layout

Key targets (each with their own `target.yml` for XcodeGen):

- **ElementX** — the main app target
- **NSE** — Notification Service Extension
- **ShareExtension** — Share Extension

Within each target: `Sources/`, `Resources/`, `SupportingFiles/`.

The main target's `Sources/` is organised as:

```
ElementX/Sources/
├── Application/           # App lifecycle, settings, windowing, root coordinators
├── FlowCoordinators/      # Flow coordinators with state machines
├── Services/<Feature>/    # SDK proxies, app services, non-view logic
├── Screens/<Screen>/      # Single screens (View, ViewModel, Coordinator, Models)
├── Screens/<Feature>/     # Groups of related screens
│   └── <Screen>/
├── Other/                 # Shared extensions, utilities, SwiftUI helpers
└── {Unit|UI|A11y}Tests/   # Any pieces of testing infrastructure that must be part of the app.
```

Mocks, test helpers, and generated files are found alongside their sources, often in `Generated/` directories. There are also dedicated targets for the test suites themselves.

Not every top-level directory is a target — there are supporting files alongside the targets.

### Swift Packages

1. **`compound-ios/`** — The Compound design system (local package). All UI styling comes from here.
2. **`Tools/Sources/`** — Helper CLI tools for developer experience.

### Dependencies

- **matrix-rust-sdk**: The Rust SDK source is at [`matrix-org/matrix-rust-sdk`](https://github.com/matrix-org/matrix-rust-sdk). Binary builds (xcframework + Swift bindings) are published at [`element-hq/matrix-rust-components-swift`](https://github.com/element-hq/matrix-rust-components-swift) and imported as a Swift package via `project.yml`. Each commit of the components repo references the SDK commit it was built from, so it is possible to find the SDK hash for a particular build of the app by cross-referencing the components version in the `project.yml` file, and finding the commit with that tag in the components repo.

---

## Architecture: MVVM-C

Every screen follows the **MVVM-Coordinator** pattern. A complete screen template is at `Tools/Scripts/Templates/SimpleScreenExample/` along with a script `createScreen.sh` that adds a new screen to the project based on the template.

### Files Per Screen

For a screen called `Foo`:

| File | Purpose |
|------|---------|
| `FooScreenModels.swift` | `FooScreenViewState`, `FooScreenViewStateBindings`, `FooScreenViewAction` enum, `FooScreenViewModelAction` enum |
| `FooScreenViewModelProtocol.swift` | Protocol exposing `actionsPublisher` and `context` |
| `FooScreenViewModel.swift` | Concrete view model subclassing `StateStoreViewModelV2` |
| `FooScreen.swift` (in `View/`) | SwiftUI view taking `@Bindable var context` |
| `FooScreenCoordinator.swift` | Owns the view model, subscribes to actions, exposes its own `actionsPublisher` |
| `FooScreenViewModelTests.swift` | Unit tests (this one lives in the UnitTests target, not ElementX) |

### Data Flow

```
View ──send(viewAction:)──► ViewModel ──actionsPublisher──► Coordinator ──actionsPublisher──► FlowCoordinator
         ◄──viewState────                                                                          │
         ◄──$context.bindings──►                                                                    │
                                                                                    StateMachine<State, Event>
```

### StateStoreViewModelV2

The base view model class (in `ElementX/Sources/Other/SwiftUI/ViewModel/StateStoreViewModelV2.swift`) uses Swift's `Observation` framework:

- `state` — the view model's mutable state (a struct conforming to `BindableState`)
- `context` — a constrained `@Observable` class passed to the view. Provides:
  - `context.viewState` — read-only access to state
  - `context.send(viewAction:)` — sends actions to the view model
  - `$context.<binding>` — two-way bindings for SwiftUI controls (via the state's `bindings` property)
  - `context.mediaProvider` — optional media loading service
- Override `process(viewAction:)` to handle incoming view actions
- Use a `PassthroughSubject<ViewModelAction, Never>` to communicate back to the coordinator

Note: Some screens are still using the older `StateStoreViewModel.swift` class, which is based on the original Combine/`ObservableObject` SwiftUI pattern.

### Screen Coordinator

```swift
final class FooScreenCoordinator: CoordinatorProtocol {
    private let parameters: FooScreenCoordinatorParameters  // Dependencies struct
    private let viewModel: FooScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Actions back to the flow coordinator
    private let actionsSubject: PassthroughSubject<FooScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<FooScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: FooScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = FooScreenViewModel(/* dependencies from parameters */)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            // Map view model actions to coordinator actions
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(FooScreen(context: viewModel.context))
    }
}
```

### Error Presentation

Two patterns:

1. **SwiftUI Alerts** — Add an `AlertInfo` to the view model's `bindings`. Present with a one-liner in the view.
2. **User Indicators** — Via `UserIndicatorController`:
   - `.toast` — a pill at the top of the screen (used for errors)
   - `.modal` — a platter overlay for blocking operations (not an actual modal)

---

## Flow Coordinators & Navigation

### FlowCoordinatorProtocol

```swift
@MainActor
protocol FlowCoordinatorProtocol {
    func start(animated: Bool)
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool)
    func clearRoute(animated: Bool)
}
```

### State Machines

Flow coordinators use `StateMachine<State, Event>` from [`ReactKit/SwiftState`](https://github.com/ReactKit/SwiftState):

- `State` and `Event` enums are defined inside the flow coordinator, conforming to `StateType` and `EventType`.
- Routes are configured via `addRoutes(event:transitions:)` for simple transitions or `addRouteMapping` when associated values are involved.
- An error handler (`addErrorHandler`) should `fatalError` on unexpected transitions to catch bugs early.
- Transitions call handler closures to present/dismiss coordinators.

### Navigation Coordinators

| Type | SwiftUI Equivalent | Usage |
|------|--------------------|-------|
| `NavigationStackCoordinator` | `NavigationStack` | Push/pop screens within a flow |
| `NavigationSplitCoordinator` | `NavigationSplitView` | iPad split view |
| `NavigationTabCoordinator` | `TabView` | Tab-based navigation |
| `NavigationRootCoordinator` | Root view | Switches the app's root (e.g. auth → session) |

### CommonFlowParameters

A shared dependency bag passed between **flow coordinators only**. Never pass this directly to screen coordinators or view models. Screen coordinators receive specific dependencies via their `Parameters` struct.

### AppRoute (Deep Linking)

`AppRoute` is an enum representing deep link destinations. Flow coordinators handle routes in `handleAppRoute` by either rebuilding their presented coordinators, clearing their stack, or doing nothing.

---

## The Rust SDK Layer

### Proxy Pattern (for uniffi objects)

SDK objects that are `uniffi::Object` are wrapped with:

1. **Protocol** (e.g. `JoinedRoomProxyProtocol`) — defines the interface
2. **Proxy** (e.g. `JoinedRoomProxy`) — wraps the Rust SDK type, lives in `Services/<Feature>/`
3. **Mock** (e.g. `JoinedRoomProxyMock`) — generated by Sourcery for testing

Naming: match the SDK type name + `Proxy` suffix (e.g. `Client` → `ClientProxy`). Exceptions exist where specialisation is needed (e.g. `JoinedRoomProxy`, `InvitedRoomProxy`).

### Type Mapping (for uniffi records/enums)

SDK types that are `uniffi::Record` or `uniffi::Enum` are mapped to app-owned Swift types to avoid importing `MatrixRustSDK` in views:

- `init(sdkType:)` — to convert from SDK type
- `var rustValue` — computed property to convert back

### Wrapping Guidelines

- Use `Result<T, E>` with typed errors — don't just throw untyped `Error`.
- Make methods `async` only when the Rust method is async; otherwise use synchronous computed properties/methods.
- Use computed `var` for simple properties, not methods.
- Map FFI types to Swift types: `String` → `URL`, `String` → `TimeInterval`, etc.
- Follow Swift API Design Guidelines for naming (e.g. `userID` not `userId`, `URL` not `Url`).

---

## Services

Services live in `ElementX/Sources/Services/<Feature>/`. They serve two purposes:

1. **Pure app services** (e.g. `AppLockService`) — app-level logic with no SDK involvement
2. **SDK-wrapping services** — compose SDK proxies with app logic to keep view models simple and testable

The Rust SDK follows the Matrix spec closely and can't be opinionated. Services are where product-level opinions live (e.g. how to combine SDK calls, when to show certain states, etc.).

### Dependency Injection

- Dependencies are injected via `init` parameters.
- Screen coordinators receive a `Parameters` struct with their specific dependencies.
- `CommonFlowParameters` is for flow coordinators only.
- There is a `ServiceLocator` but it is **deprecated**. Never access it directly from a type that needs a service — always inject from a level above. This will be removed to support multiple accounts.

---

## Concurrency & Actors

- Most protocols are annotated `@MainActor`, so conforming types inherit this automatically.
- Views, screens and coordinators are always `@MainActor` (automatically).
- Some services are `nonisolated` if they do background work.
- There are very few `actor` types in the codebase.

---

## Compound Design System

The `compound-ios` package (at `compound-ios/` in-repo) provides **all** UI styling. Always use Compound over custom styling unless there's no Compound equivalent.

### Tokens

Access via the `.compound` namespace:

- **Colours:** `Color.compound.textPrimary`, `.compound.bgCanvasDefault`, etc.
- **Fonts:** `Font.compound.bodyLG`, `.compound.headingMDBold`, `.compound.bodySMSemibold`, etc.
- **Icons:** Key paths on `CompoundIcons` (e.g. `\.userProfile`, `\.plus`, `\.leave`). Never use icon images directly — use `CompoundIcon(\.iconName)` which handles Dynamic Type scaling.

### Key Components

- **`ListRow`** — The primary building block for list/form screens. Supports labels (`.default`, `.plain`, `.action`, `.centeredAction`), detail views, and kinds (`.label`, `.button`, `.textField`, `.toggle`, etc.).
- **`.compoundList()`** — Modifier to style a `Form`/`List` with Compound tokens.
- **`.compoundListSectionHeader()`** / **`.compoundListSectionFooter()`** — Section header/footer styling.
- **`CompoundButtonStyle`** — Button styles: `.compound(.primary)`, `.compound(.secondary)`, `.compound(.tertiary)`, `.compound(.super)`, `.compound(.textLink)`. Sizes: `.large`, `.medium`, `.small`, `.toolbarIcon`.
- **`CompoundToggleStyle`** — Toggle styling: `.toggleStyle(.compound)`.
- **`CompoundIcon`** — Icon view with sizes `.xSmall` (16pt), `.small` (20pt), `.medium` (24pt), `.custom(CGFloat)`.
- **`SendButton`** — Specialised send button for message composition.
- **`Label` with icon keypaths** — `Label("Title", icon: \.userProfile)` uses `CompoundIcon` internally.

### Pattern

A typical Compound-styled list screen:

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

Explore `compound-ios/Sources/Compound/` for the full component set.

---

## Testing

Coverage is tracked in codecov with a target of 80% coverage as a minimum (including the coverage from the SDK, Compound and Rich Text Editor).

### Test Types

| Type | Location | Purpose |
|------|----------|---------|
| **Unit Tests** | `UnitTests/Sources/` | View model logic, state machines, services |
| **UI Tests** | `UITests/Sources/` | Flow coordinator integration (tapping through screens) |
| **Preview Tests** | `PreviewTests/Sources/` | Auto-generated snapshot tests from SwiftUI previews |
| **Accessibility Tests** | `AccessibilityTests/Sources` | Auto-generated Xcode Accessibility Audits from previews |

When the test suite uses Swift Testing, add the `.serialized` trait to the suite when it contains anything that is stored globally (such as AppSettings) to ensure consistent test states across runs (as some test plans randomise the run order).

### Mocks

Generated by **Sourcery** (config in `Tools/Sourcery/`). Generated files live in `Generated/` directories.

- Sourcery mocks intentionally crash when calling un-configured methods.
- Commonly-used mocks have a convenience `init` with a `Configuration` struct providing defaults and easy customisation:
  ```swift
  let mock = ClientProxyMock(.init(userID: "@alice:example.com"))
  ```

### Async Testing

Use `deferFulfillment` to await specific values from Combine publishers or `AsyncSequence` with a timeout:

```swift
let deferred = deferFulfillment(context.observe(\.viewState.counter)) { $0 == 1 }
context.send(viewAction: .incrementCounter)
try await deferred.fulfill()
#expect(context.viewState.counter == 1)
```

The project is migrating from XCTest to **Swift Testing** (see PR #5119).

### Snapshots

UI and Preview tests use snapshots to catch unwanted changes in the UI.

- Snapshots are stored under `<Target>/Sources/__Snapshots__/`.
- Snapshots are tracked via **Git LFS** — ensure `git lfs install` has been run.
- If you change UI, snapshots may need to be re-recorded on the correct device/OS combination.

Snapshots are handled by [`pointfreeco/swift-snapshot-testing`](https://github.com/pointfreeco/swift-snapshot-testing) and any failures are included in the test results as a set of 3 images: the reference, the failure and a diff.

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen project definition (targets, packages, settings) |
| `app.yml` | App-level XcodeGen configuration |
| `.swiftlint.yml` | SwiftLint rules |
| `.swiftformat` | SwiftFormat rules |
| `Dangerfile.swift` | Danger PR checks |
| `Package.swift` | SPM package manifest (for the Tools CLI) |
| `Gemfile` | Ruby dependencies (Fastlane, Danger) |
| `localazy.json` | Localazy translation config |
| `codecov.yml` | Codecov configuration |
| `.periphery.yml` | Periphery dead-code detection config |
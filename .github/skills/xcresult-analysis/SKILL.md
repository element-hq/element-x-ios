---
name: xcresult-analysis
description: 'Analyse Xcode xcresult bundles to diagnose failing tests. Accepts a local .xcresult path or a GitHub Actions run URL. Use when: investigating test failures from CI or local runs (unit, snapshot/preview, accessibility, integration, UI); needing the XCUITest activity log before a failure; debugging flakiness; or triaging CI artifacts.'
argument-hint: '<path-to.xcresult>'
---

# xcresult Analysis

Extracts failing test names, failure messages, file/line locations, and the XCUITest activity log from an `.xcresult` bundle via `xcresulttool`. Works for all test targets: `UnitTests`, `PreviewTests`, `AccessibilityTests`, `IntegrationTests`, `UITests`.

## Procedure

### 1. Compile the script (first time only)

```
swiftc .github/skills/xcresult-analysis/scripts/analyze-xcresult.swift \
       -o .github/skills/xcresult-analysis/scripts/analyze-xcresult
```

The compiled binary is gitignored. It only needs to be recompiled when the `.swift` source changes.

### 2. Run the analysis

**Option A: Local xcresult path**

```
.github/skills/xcresult-analysis/scripts/analyze-xcresult <path-to.xcresult>
```

Common local locations:
- `test_output/UnitTests.xcresult`
- `test_output/PreviewTests.xcresult`
- `test_output/AccessibilityTests.xcresult`
- `test_output/IntegrationTests.xcresult`
- `test_output/UITests.xcresult`

**Option B: GitHub Actions run URL**

Use a run URL (e.g. `https://github.com/element-hq/element-x-ios/actions/runs/24243377085`) and download artifacts with the GitHub CLI.

```
RUN_URL="https://github.com/element-hq/element-x-ios/actions/runs/24243377085"
RUN_ID=$(echo "$RUN_URL" | grep -oE '[0-9]+$')
WORK_ROOT=".github/skills/xcresult-analysis/work"
RUN_DIR="$WORK_ROOT/$RUN_ID"
mkdir -p "$RUN_DIR"

# Most failing workflows upload an artifact named "Results".
gh run download "$RUN_ID" --repo element-hq/element-x-ios --name Results --dir "$RUN_DIR"

# If "Results" does not exist (for example, some UI test jobs), list artifact names and retry.
gh run view "$RUN_ID" --repo element-hq/element-x-ios --json artifacts
# gh run download "$RUN_ID" --repo element-hq/element-x-ios --name <ARTIFACT_NAME> --dir "$RUN_DIR"

find "$RUN_DIR" -name "*.zip" -exec unzip -q {} -d "$RUN_DIR" \;
XCRESULT_PATH=$(find "$RUN_DIR" -name "*.xcresult" -type d | head -1)

.github/skills/xcresult-analysis/scripts/analyze-xcresult "$XCRESULT_PATH"
```

Authentication note: run `gh auth login` first (or set `GH_TOKEN`).
The `work/` folder is gitignored and can keep per-run folders (`work/<RUN_ID>`) for later inspection.

Optional flag: `--last N` — number of activity log steps to show per failure (default: 40).

### 3. Read the output

The script prints two sections:

**Overview** — one line per test with ✅/❌ and duration.

**Failure detail** — for each failure:
- **Test name** and identifier
- **Location: file:line** of the failing assertion — only printed when available. XCTest failures always include it; **Swift Testing failures (`#expect`, `deferFulfillment`) do not** — the `sourceCodeContext` is absent from `failureSummaries` in the xcresult for those.
- **Failure message**
- **Activity log** — the last N steps the test took (integration/UI tests only; empty for unit/snapshot tests)

### 4. Diagnose by test type

#### Unit tests (`UnitTests.xcresult`)

The activity log is empty — the failure message is all you need. `Location:` is printed for XCTest-style failures but **absent for Swift Testing** (`#expect`, `deferFulfillment`) — search the source by test name to locate the assertion. Common messages:

- `XCTAssertEqual failed: ("x") is not equal to ("y")` — logic bug, check the relevant method.
- `XCTAssertTrue failed` at a specific line — check the condition on that line in context.
- Async assertion failures — check `deferFulfillment` / publisher observation patterns.

#### Snapshot & Preview tests (`PreviewTests.xcresult`)

- `Snapshot does not match reference` — a UI change caused a visual diff. Re-record snapshots on the correct device/OS: `swift run tools ci unit-tests` or open the test in Xcode and enable record mode.
- The script shows file:line pointing to the generated snapshot test. The actual diff images are stored as xcresult attachments — open the `.xcresult` in Xcode to view the reference, failure, and diff images side by side.

#### Accessibility tests (`AccessibilityTests.xcresult`)

- Failure messages describe the specific audit issue (e.g. contrast ratio, missing label). The file:line points to the generated test — find the originating preview via the test name, then fix the accessibility issue in the view.

#### Integration & UI tests (`IntegrationTests.xcresult`)

The activity log is the primary diagnostic. The last entry before `• Tear Down` reveals what the test was doing when it failed:

- **`Waiting Xs for … to exist`** — the element never appeared. The app likely didn't navigate to the expected screen, or the identifier is wrong.
- **`Timed out while evaluating UI query`** on a tap — the element existed when `waitForExistence` checked but was gone by the time `tap` ran (common with dismissing sheets/pickers whose elements linger briefly during animation). Gate the tap on `isHittable == true` instead of `exists`.
- **`Asynchronous wait failed: Exceeded timeout`** on `exists == 0` — an element that should have disappeared matched something in the next screen. Use a more specific query scoped to the outgoing screen.
- **`Checking existence` repeated many times then abrupt stop** — `waitForExistence(timeout:)` ran out. The timeout is too short for CI, or the app is stuck.

### 5. Fix the test

Apply the fix to the relevant source file based on the diagnosis:

- Unit test logic: `UnitTests/Sources/`
- Snapshot re-record: run tests with record mode, then commit the new `__Snapshots__` images
- Accessibility issue: fix in the SwiftUI view
- Integration test: `IntegrationTests/Sources/UserFlowTests.swift` or `Common.swift`

## Notes

- Uses `--legacy` flag required by `xcresulttool` on Xcode 16+.
- Activity log entries are nested subactivities flattened to depth 2 — deeper polling noise is suppressed.
- The `summaryRef` on each failing test node is fetched in a separate `xcresulttool` call. Stderr is drained concurrently to prevent pipe-buffer deadlocks on large (100MB+) bundles.

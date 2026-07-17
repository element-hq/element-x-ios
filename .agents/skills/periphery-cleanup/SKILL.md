---
name: periphery-cleanup
description: Dead-code sweep with Periphery — scan the Pro-configured project, delete unused code, guard false positives (keep-alive handles, future-use code), run unit tests, purge scan cache. Use when user want "clean up dead code", "run periphery", "remove unused code".
---

# Periphery cleanup

Periphery = static analysis, find unused code. Scan build ALL schemes — slow (cold ~30-60 min). Maintenance thing, run rare.

## Scan — always on the Pro variant

Scan run on the Pro-configured project so every source get analysed (plain config leave hook implementations + their call sites out, flood report with false "unused"):

```bash
git submodule update --init --recursive   # once, if submodules missing
swift run pipeline configure-element-pro
periphery scan --relative-results --quiet > periphery-report.txt
```

Config live in `.periphery.yml` — schemes already cover every target, don't narrow. Two deliberate settings there:
- `retain_unused_protocol_func_params: true` — protocol signatures are contracts (hooks, delegates); params unused in every conformance stay. NEVER annotate protocol function parameters, config already handle them.
- `index_exclude: compound-ios/**` — Compound excluded: its Inspector app + package tests live outside this project's schemes, so their usage invisible → findings there unreliable (e.g. making things internal break the Inspector). Never act on Compound code from this scan.

Report line format: `path:line:col: warning: <kind> '<name>'`. Build fail → fix build first, scan need compiling project.

## Comment hygiene — strip, scan, restore

Every run: existing `periphery:ignore` comments hide drift — code change, comment stay, nobody notice it useless. So:

1. **Strip + remember.** Before the scan, remove every `periphery:ignore` comment (both spellings: `periphery:ignore` and `periphery: ignore`) and stash them: `git diff > /tmp/periphery-comments.patch` right after stripping, or just rely on `git diff` against HEAD to recall what was where.
2. **Scan.** The report now show ground truth: every declaration that genuinely need protection re-flag.
3. **Restore only what re-flag.** For each finding that match the false-positive table, put the comment back (same reason strings). Findings that DON'T re-flag = comments that were stale → stay deleted. Anything newly flagged that isn't a false positive = real dead code → delete it.

Result: comment set always minimal, always true. The clutter never accumulate.

## Triage — kind → action

| Warning | Action |
|---|---|
| Unused function / property / enum / struct / init | Check false-positive table FIRST. True dead → delete whole declaration + helpers/extensions only it used |
| Assign-only property | DANGER ZONE. Prime keep-alive suspect — read table below before touch |
| Unused parameter | Protocol params never appear (config retain them). ObjC selector / system callback → `ignore:parameters <name> - <reason>`. Free signature → remove param + fix call sites |
| Redundant protocol conformance | `TestablePreview` → SKIP, always (see below). Others: verify nothing need conformance (generics, tests, mocks), then remove conformance only, keep type |
| Redundant public accessibility | Drop `public`, make internal — EXCEPT member that satisfy a public protocol in a public type (e.g. `previews`), Swift refuse internal there; skip or internalise whole type |
| Superfluous ignore comment | Declaration referenced now — comment dead, code alive. Remove comment ONLY, never declaration |

Never touch `Generated/` directories, never edit `Localizable.strings`. Delete bottom-up per file — line numbers stay valid.

## False positives — mark, no delete

Stored-never-read variable often alive ON PURPOSE: keep task / SDK object / coordinator alive past declaration scope. Delete = app break silent (observation stop, flow deallocate, rust handle drop). Mark instead: `// periphery:ignore - <reason>` line above declaration. Reuse existing reasons from codebase:

| Pattern | How recognise | Reason string |
|---|---|---|
| Rust SDK handle | `TaskHandle`, observation token from SDK, stored after `observe`/`subscribe` call | `required for instance retention in the rust codebase` |
| Keep-alive reference | child flow coordinator, service stored so updates keep flowing | `retaining purpose` or `used to avoid deallocation` or `keep alive to keep receiving updates.` |
| Cancellable task handle | `@CancellableTask` property, `Task` stored so reassign/nil cancel previous | `auto cancels when reassigned` |
| SDK enum exhaustiveness | unused `init` switching over SDK enum | `Unused, but added to detect new cases when updating the SDK.` |
| MVVM-C architecture | empty `ViewModelAction` enum from screen template, unused VM protocol — NEVER delete VM protocols, convention keep them | `required for the architecture` (keep the mark even if a superfluous-comment warning appear — it document intent) |
| Property wrapper internals | `@propertyWrapper`, `@dynamicMemberLookup` subscript | `property wrappers generate false positives` / `subscript are seen as false positives` |
| ObjC selector parameter | parameter only touched by runtime (`displayLink`, `sender` etc.) | `ignore:parameters <name> - required for objc selector` |
| Underscored SwiftUI protocol | `_body` from `TextFieldStyle` etc. — called by SwiftUI, members inside resolve transitively | `called by SwiftUI via the TextFieldStyle protocol` |
| SDK delegate requirement | method required by rust SDK delegate protocol (e.g. `didRefreshTokens`) | `required by the SDK's delegate protocol` |
| Synthesized conformance | field only read via synthesized Hashable/Equatable/Codable (cache keys, diffing models) | `used via the synthesized Hashable conformance` |
| Encoded/decoded schema field | Codable field parsed or serialized but not consumed yet | `documents the schema, parsed but not consumed yet` / `part of the encoded payload` |
| Release-only code | compiled out in Debug scan (`#if !DEBUG` paths, nightly checks) | `only used in release builds` |
| Hand-written mock file | whole file mock infra | `// periphery:ignore:all` at file top |
| `TestablePreview` conformance | flagged "Redundant protocol conformance" on every preview | NO marker, NO removal — Sourcery read conformance, generate snapshot + a11y tests from it. Remove = tests silently vanish. Skip finding, bulk noise |

**Unsure if keep-alive?** Property type Task / AnyCancellable / TaskHandle / coordinator / SDK proxy, assigned inside async or stream setup → smell like keep-alive. ASK USER before delete. Show declaration, where assigned, your read on it.

## Future-use code

Unused but look intentional — API pair completeness, feature half-landed, "team will need soon". No silent delete, no silent keep. Present to user: what, where, opinion keep-or-delete. User say keep → mark `// periphery:ignore - might be useful to have`.

## Mock cascade after protocol deletions

Delete protocol member → Sourcery regenerate mock WITHOUT its `fooReturnValue` / `fooClosure` helpers → hand-written mock `Configuration` inits and test set-up lines still assigning those helpers break the build. Those lines are inert setup for API nothing call — more dead code, not evidence of use. After protocol deletions: grep non-Generated `Mocks/` + `UnitTests/` for `<name>ReturnValue`, `<name>Closure`, direct assignments to deleted members — delete them too. Compiler walk you to the stragglers; that expected, not a false positive.

Careful with same-name members: one mock file often configure SEVERAL protocols (proxy-level `inviter` vs info-level `inviter`). Strip only lines whose target member actually deleted — the wrong one compile fine (member still exist) but silently un-configure previews; snapshot tests catch it, so run them before calling done.

## Verify — on the PLAIN project

Restore the plain configuration BEFORE running tests — snapshots are recorded against plain Element X; Pro branding fail ~8 preview tests falsely:

```bash
git restore project.yml ElementX.xcodeproj/project.pbxproj "ElementX/Resources/AppIcon.icon/Assets/AppIcon.png"
xcodegen
swift run tools ci unit-tests
```

Sourcery regenerate mocks on build — deleted protocol members clean themselves. All tests pass before call done. Note: the CI helper pipe through `xcbeautify` — if not installed the exit code lie even when tests pass; check the `.xcresult` summary.

## Purge cache — always

Periphery DerivedData cache eat tens of GBs. Scan run rare → cache worthless between runs. Last step, no skip:

```bash
rm -rf ~/Library/Caches/com.github.peripheryapp
```

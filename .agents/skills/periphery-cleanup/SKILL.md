---
name: periphery-cleanup
description: Dead-code sweep with Periphery — scan app, delete unused code, guard false positives (keep-alive handles, future-use code), run unit tests, purge scan cache. Use when user want "clean up dead code", "run periphery", "remove unused code".
---

# Periphery cleanup

Periphery = static analysis, find unused code. Scan build ALL schemes — slow (cold ~30-60 min). Maintenance thing, run rare.

## Scan

```bash
periphery scan --relative-results --quiet > periphery-report.txt
```

Config live in `.periphery.yml` — schemes already cover every target, don't narrow. Report line format: `path:line:col: warning: <kind> '<name>'`. Build fail → fix build first, scan need compiling project.

## Triage — kind → action

| Warning | Action |
|---|---|
| Unused function / property / enum / struct / init | Check false-positive table FIRST. True dead → delete whole declaration + helpers/extensions only it used |
| Assign-only property | DANGER ZONE. Prime keep-alive suspect — read table below before touch |
| Unused parameter | Signature forced by protocol / objc / system API → `// periphery:ignore:parameters <name> - <reason>`. Free signature → remove param + fix call sites |
| Redundant protocol conformance | `TestablePreview` → SKIP, always (see below). Others: verify nothing need conformance (generics, tests, mocks), then remove conformance only, keep type |
| Redundant public accessibility | Drop `public`, make internal |
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
| MVVM-C architecture | empty `ViewModelAction` enum from screen template | `required for the architecture` |
| Property wrapper internals | `@propertyWrapper`, `@dynamicMemberLookup` subscript | `property wrappers generate false positives` / `subscript are seen as false positives` |
| ObjC selector parameter | parameter only touched by runtime (`displayLink` etc.) | `ignore:parameters <name> - required for objc selector` |
| Build-config-only code | compiled out in Debug | `only used in release builds` |
| Hand-written mock file | whole file mock infra | `// periphery:ignore:all` at file top |
| `TestablePreview` conformance | flagged "Redundant protocol conformance" on every preview | NO marker, NO removal — Sourcery read conformance, generate snapshot + a11y tests from it. Remove = tests silently vanish. Skip finding, bulk noise |

**Unsure if keep-alive?** Property type Task / AnyCancellable / TaskHandle / coordinator / SDK proxy, assigned inside async or stream setup → smell like keep-alive. ASK USER before delete. Show declaration, where assigned, your read on it.

## Future-use code

Unused but look intentional — API pair completeness, feature half-landed, "team will need soon". No silent delete, no silent keep. Present to user: what, where, opinion keep-or-delete. User say keep → mark `// periphery:ignore - might be useful to have`.

## Verify

```bash
swift run tools ci unit-tests
```

Sourcery regenerate mocks on build — deleted protocol members clean themselves. All tests pass before call done.

## Purge cache — always

Periphery DerivedData cache eat GBs. Scan run rare → cache worthless between runs. Last step, no skip:

```bash
rm -rf ~/Library/Caches/com.github.peripheryapp
```

---
name: constrained-tests
description: Slow-CI simulation — run unit tests on saturated CPU to reproduce CI-style flakiness locally. Suggest when new/reworked suite lean heavy on awaits (deferFulfillment, waitForConfirmation, TestClock, timeouts) or test fail only on CI. Not for every change.
---

# Constrained test runs

CI runners shared + slow. Background tasks starve, awaits stretch, scheduler races flake there, pass locally. `--constrained` saturate CPU with hog tasks — same conditions, local.

## When

- PR add/rework suite heavy on timing-sensitive async: `deferFulfillment`, `waitForConfirmation`, `TestClock`, `transitionValues`, timeouts.
- Test fail on CI, pass locally.
- Not routine changes, not sync suites — slow, no gain.

## How

Full unit test workflow (what CI run):

```bash
swift run tools ci unit-tests --constrained
```

One suite, iterate on new tests (prefer while developing):

```bash
swift run tools ci run-tests --scheme UnitTests --test-name MyNewTests --constrained
```

Hog count automatic (2× cores). Suite survive ~10 constrained iterations → good shape.

## Failures mean

Failure under constraint = real bug in test (sometimes code under test): assertion race async work, transient state observation missed, timeout too tight. Fix synchronisation, no blind timeout bump. Helpers in `UnitTests/Sources/TestUtilities/` (`deferFulfillment`, `deferFailure`, `waitForConfirmation`). Wait on durable state, not transient.

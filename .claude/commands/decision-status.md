| allowed-tools | description |
|---|---|
| Bash(git log:*) | Summarize all 12 decisions from the tracker |

## Context

- Current branch: !`git branch --show-current`
- Last tracker update: !`git log -1 --format="%ai %s" -- documentation/decisions_tracker.md`

## Your task

Produce an English-language summary of the project's 12 tracked decisions (D-001 through D-012).

1. Read `documentation/decisions_tracker.md` (it's in Russian)
2. Parse each decision: ID, title, status, criticality, owner, deadline
3. Produce a summary table in English with columns: ID | Title | Status | Criticality | Blocker?
4. Show counts: resolved / in-progress / open
5. List all decisions that are currently blocking development
6. Read the "Current Phase" and "Blockers" sections of `CLAUDE.md` — flag any inconsistencies with the tracker
7. Identify the critical path: which decisions must be resolved next for development to continue
8. Suggest concrete next actions for each open blocker
9. Do all of the above in a single message.

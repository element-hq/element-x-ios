| allowed-tools | description |
|---|---|
| Bash(git status:*) | Find remaining Element brand references in the codebase |

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`

## Your task

Search for remaining Element/element.io brand references that need to change during rebranding.

1. Use the built-in Grep tool to search for these patterns across `.swift`, `.strings`, `.yml`, `.plist`, `.json`, `.entitlements` files:
   - `"Element X"` (exact product name)
   - `"element\.io"` (domain references)
   - `"io\.element"` (bundle ID pattern)
   - `"element-hq"` (GitHub org references)
   - `"Element Call"` (call branding)
   - `"Element"` (broad match — in `.swift` and `.strings` only)

2. **Exclude** these paths from results (they are not rebrandable or are reference-only):
   - `.build/`, `SourcePackages/`, `.git/`
   - `documentation/`, `scripts/`
   - Lines that are only copyright/license headers (e.g., `// Copyright ... Element`)

3. **Categorize** each match into one of:
   - **MUST CHANGE** — user-visible strings, display names, UI text
   - **SHOULD CHANGE** — internal identifiers, bundle IDs, config keys
   - **KEEP** — SDK references, test fixtures, import statements, Compound design system

4. Produce a summary:
   - Counts per category
   - Top files needing changes, sorted by priority
   - Any new references not in `documentation/change_map.md`

5. Read `documentation/change_map.md` and cross-reference — flag anything found in step 1 that isn't covered by the change map

6. Do all of the above in a single message.

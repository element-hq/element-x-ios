| allowed-tools | description |
|---|---|
| Bash(git fetch:*), Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(git merge:*) | Fetch upstream changes and guide merge |

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`
- Current HEAD: !`git log --oneline -1`
- Upstream remote: !`git remote get-url upstream 2>/dev/null || echo "No upstream remote configured"`

## Your task

Fetch upstream Element X changes and guide the user through merging them.

1. **Pre-flight checks:**
   - If working tree is dirty (uncommitted changes), STOP and tell the user to commit or stash first
   - If not on `develop` branch, warn the user (merges should happen on `develop`)
   - If no `upstream` remote exists, tell the user to add it: `git remote add upstream https://github.com/element-hq/element-x-ios.git`

2. **Fetch upstream:** `git fetch upstream`

3. **Show new commits:** `git log --oneline develop..upstream/main`
   - If no new commits, report "Already up to date with upstream" and stop

4. **Show diff summary:** `git diff --stat develop...upstream/main`

5. **Identify potential conflicts:**
   - Show files changed on both sides (files in `git diff --name-only develop...upstream/main` that also appear in `git diff --name-only checkpoint/unmodified-build..develop`)
   - Flag high-risk files: `project.yml`, `app.yml`, `target.yml`, `AppSettings.swift`, `Package.resolved`

6. **Recommend merge strategy** based on conflict risk:
   - Low risk (no overlapping files): recommend direct merge
   - Medium risk (config files overlap): recommend merge with manual review
   - High risk (many conflicts): recommend creating a backup tag first

7. **Do NOT auto-merge.** Ask the user for explicit confirmation before proceeding.

8. **Only after user confirms:** Run `git merge upstream/main --no-edit` and report the result. If conflicts occur, list them and advise resolution.

9. Do steps 1-7 in a single message. Only merge after user confirms.

| allowed-tools | description |
|---|---|
| Bash(git status:*), Bash(git tag:*), Bash(git log:*), Bash(git push:*) | Create a named checkpoint tag |

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`
- Current HEAD: !`git log --oneline -1`
- Existing checkpoints: !`git tag -l "checkpoint/*"`
- Requested name: $ARGUMENTS

## Your task

Create an annotated checkpoint tag following the project's checkpoint naming convention.

1. Check working tree status — if dirty, warn the user (but don't refuse)
2. If `$ARGUMENTS` is provided, use it as the checkpoint name
3. If no name provided, list the planned checkpoints from `ios_proj_init.md` Step 15 and ask the user to pick one:
   - `unmodified-build` (should already exist)
   - `identity-changed`
   - `icon-and-colors`
   - `branding-complete`
   - `localization-complete`
   - `configuration-complete`
   - `oidc-configured`
   - `push-configured`
   - `calls-configured`
   - `init-complete`
4. Check if `checkpoint/{name}` already exists — if so, warn and ask before overwriting
5. Create the annotated tag: `git tag -a "checkpoint/{name}" -m "Checkpoint: {name}"`
6. Show the tag details with `git tag -v "checkpoint/{name}"` or `git log --oneline -1 "checkpoint/{name}"`
7. Ask whether to push the tag to origin (`git push origin "checkpoint/{name}"`)
8. Do steps 1-6 in a single message. Only push after user confirms.

| allowed-tools | description |
|---|---|
| Bash(./scripts/rebrand.sh:*), Bash(./scripts/rebrand_strings.sh:*), Bash(xcodegen:*), Bash(xcodebuild:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*) | Run rebrand scripts with safety gates |

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`
- Existing checkpoints: !`git tag -l "checkpoint/*"`
- Scripts exist: !`ls -la scripts/rebrand.sh scripts/rebrand_strings.sh 2>/dev/null || echo "MISSING: rebrand scripts not found"`
- D-001 status: !`grep -A5 "D-001" documentation/decisions_tracker.md 2>/dev/null | head -6`

## Your task

Execute the rebranding scripts with full safety checks. This is a destructive operation — be cautious.

1. **Prerequisite check:** Read `documentation/decisions_tracker.md`. If D-001 (App Identity) is NOT resolved, STOP immediately and tell the user: "D-001 (App Identity) must be resolved before rebranding. Run /decision-status for details."

2. **Collect required values** from the user (do NOT proceed without all of these):
   - `APP_NAME` — internal/code name (e.g., "MyMessenger")
   - `PRODUCTION_NAME` — display name shown to users
   - `BUNDLE_ID` — reverse-domain bundle identifier (e.g., "com.company.messenger")
   - `APP_GROUP` — app group identifier (e.g., "group.com.company.messenger")
   - `TEAM_ID` — Apple Developer Team ID
   - `WEBSITE_URL` — product website
   - `OIDC_REDIRECT_URL` — OIDC redirect URI
   - `PRIVACY_URL` — privacy policy URL
   - `TERMS_URL` — terms of service URL
   - `COPYRIGHT_URL` — copyright URL

3. **Dry-run rebrand.sh first:**
   ```
   APP_NAME=... PRODUCTION_NAME=... BUNDLE_ID=... APP_GROUP=... TEAM_ID=... WEBSITE_URL=... OIDC_REDIRECT_URL=... PRIVACY_URL=... TERMS_URL=... COPYRIGHT_URL=... ./scripts/rebrand.sh --dry-run
   ```
   Show the dry-run output to the user.

4. **Ask for confirmation** before executing the real run.

5. **Execute rebrand.sh** with the same environment variables (without `--dry-run`).

6. **Dry-run rebrand_strings.sh:**
   ```
   APP_NAME=... PRODUCTION_NAME=... ./scripts/rebrand_strings.sh --dry-run
   ```
   Show output and ask for confirmation.

7. **Execute rebrand_strings.sh** with the same environment variables.

8. **Regenerate and build:**
   - `xcodegen generate`
   - `xcodebuild build -scheme ElementX -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipPackagePluginValidation -skipMacroValidation 2>&1 | tail -30` (10-minute timeout)

9. **Show summary:**
   - `git diff --stat` (what changed)
   - `git status --short` (full picture)

10. **Remind about manual steps:**
    - Replace visual assets (app icon, launch screen) — scripts don't handle images
    - Review Localizable.strings changes across all 37 locales
    - Run `/audit-branding` to verify no Element references remain
    - Create a checkpoint: `/create-checkpoint branding-complete`

11. Each phase (dry-run → confirm → execute) must be separate. Do NOT combine dry-run and execution.

| allowed-tools | description |
|---|---|
| Bash(xcodegen:*), Bash(xcodebuild:*), Bash(git status:*) | Regenerate xcodeproj and build for simulator |

## Context

- Current branch: !`git branch --show-current`
- Working tree status: !`git status --short`

## Your task

Regenerate the Xcode project from YAML and build for the simulator.

1. Run `xcodegen generate` in the project root
2. If xcodegen fails, report the error and stop — do not attempt to build
3. Run the build command (pipe through `tail -30` to keep output manageable):
   ```
   xcodebuild build -project ElementX.xcodeproj -scheme ElementX -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipPackagePluginValidation -skipMacroValidation 2>&1 | tail -30
   ```
   Use a 10-minute timeout for the build.
4. Report the result:
   - On **success**: confirm BUILD SUCCEEDED
   - On **failure**: extract and show the first 3 error lines (lines containing `error:`)
5. Show `git status --short` to reveal any generated file changes (e.g., `.xcodeproj` modifications)
6. Do all of the above in a single message.

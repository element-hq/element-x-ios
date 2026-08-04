# One-tap TestFlight release

The [`TestFlight` workflow](../.github/workflows/testflight.yml) archives, signs, and
uploads the Gua iOS app to TestFlight from a single button press in the GitHub
Actions UI. No local Xcode, no Match repo, no manual certificate juggling.

## How to release

1. Push the commit you want to ship to its branch (the workflow runs from the
   branch/ref you pick).
2. GitHub -> **Actions** tab -> **TestFlight** (left sidebar) -> **Run workflow**.
3. Pick the branch, optionally type a "What to Test" note, and **Run workflow**.
4. Wait for the run to go green (~30-60 min on a cold cache). The build then shows
   up in App Store Connect -> TestFlight after Apple finishes processing
   (usually another 5-15 min).

Each run uses `github.run_number` as the build number, so every upload is unique
and monotonically increasing — TestFlight never rejects a duplicate.

## Signing approach: cloud-managed automatic signing

The app and both app extensions (`global.gua`, `global.gua.nse`,
`global.gua.shareextension`) all use `CODE_SIGN_STYLE = Automatic` with team
`BSLR4D6L28` (set in `app.yml` as `DEVELOPMENT_TEAM`, inherited by every signed target).

The workflow hands an **App Store Connect API key** to `xcodebuild` via
`-allowProvisioningUpdates -authenticationKeyPath/-authenticationKeyID/-authenticationKeyIssuerID`.
Xcode then fetches or creates, on the fly:

- the iOS Distribution certificate, and
- the App Store provisioning profiles for all three bundle ids (including the app
  group and keychain-access-group entitlements).

That is why there is **no** `.p12`, `.mobileprovision`, keychain import, or
Fastlane Match in this pipeline — the single API key replaces all of it. The same
key is reused by `xcrun altool` for the TestFlight upload.

## Required GitHub secrets

Add these under **Settings -> Secrets and variables -> Actions -> New repository secret**.
These are the same App Store Connect API key credentials already used by the
feedback bot.

| Secret | What it is | Where to get it |
| --- | --- | --- |
| `ASC_ISSUER_ID` | App Store Connect API **issuer id** (a UUID) | App Store Connect -> Users and Access -> Integrations -> App Store Connect API -> the "Issuer ID" shown at the top |
| `ASC_KEY_ID` | The API **key id** (~10 chars) | Same page, the "Key ID" column for your key |
| `ASC_PRIVATE_KEY` | The full contents of the `AuthKey_<KEY_ID>.p8` file | Downloaded once when the key was created. Paste the whole PEM block, `-----BEGIN PRIVATE KEY-----` through `-----END PRIVATE KEY-----`, including newlines. |
| `ASC_APP_ID_DEV` | The **dev** app record's numeric Apple ID (only needed for `environment=dev`) | Same place, on the `Gua Dev` app record. |
| `ASC_APP_ID` | The app's **numeric Apple ID** | App Store Connect -> Apps -> (the Gua app) -> App Information -> "Apple ID". The upload pins this so the build can't be routed to the wrong app record on a multi-app account. |
| `GUA_DEV_RESOLVER_BASE_URL` | **HTTPS** base URL of the dev **resolver** (phone → homeserver routing) | The dev cluster's resolver ingress, e.g. `https://resolver.dev.gua.<dev-zone>` |
| `GUA_DEV_IDENTITY_SERVICE_BASE_URL` | **HTTPS** base URL of the dev **identity-service** (phone/OTP IdP) | The dev cluster's identity ingress, e.g. `https://identity.dev.gua.<dev-zone>` |
| `GUA_DEV_ACCOUNT_PROVIDER` | The dev **homeserver server-name** offered at login (host, no scheme) | The `serverName` the resolver returns, e.g. `dev.gua.<dev-zone>` |

## Two apps: prod and dev

The workflow takes an `environment` input and builds one of two apps:

| | `prod` (default) | `dev` |
|---|---|---|
| Bundle id | `global.gua` | `global.gua.dev` |
| App name | Gua | Gua Dev |
| Backend | `gua.global` (committed in `GuaDeployment.swift`) | dev cluster (injected from `GUA_DEV_*` secrets) |
| OIDC redirect | `global.gua:/oidc` | `global.gua.dev:/oidc` |
| App record | `ASC_APP_ID` | `ASC_APP_ID_DEV` |

They install side by side (different bundle ids, and deliberately different URL
schemes since iOS routes a scheme to a single app). The dev app comes from the
XcodeGen overlay `Variants/Dev/dev.yml`, applied by `fastlane config_dev`;
`Release` on its own means production.

The dev redirect scheme still pairs with client_uri `https://gua.global`: MAS
reverses the scheme and requires it to match the client_uri host as a *prefix*,
so `global.gua.dev` satisfies `gua.global` and no new domain or server change is
needed.

Before the first `environment=dev` run, the Apple Developer account needs the
`global.gua.dev`, `global.gua.dev.nse` and `global.gua.dev.shareextension`
identifiers plus the `group.global.gua.dev` App Group, and an App Store Connect
record for the dev app (see the identifier caveats below, which apply equally).

The `GUA_DEV_*` secrets point the **TestFlight build** at the network-reachable
**dev backend** instead of the committed `localhost` placeholders in
`Secrets/Secrets.swift`. `localhost` only resolves on the simulator — on a real
device it's the phone itself, so a build without these is dead at phone entry. The
resolver and identity-service URLs **must be `https://`** (App Transport Security
blocks cleartext on device). The "Inject dev backend endpoints" step writes them
into `Secrets.swift` before the archive and **fails fast** if any is missing, so a
build can never silently ship localhost again.

The API key needs the **App Manager** role (or at least access to certificates,
identifiers & profiles + TestFlight) so it can manage signing assets and upload
builds.

> **First-run precondition (App IDs must already exist).** Cloud-managed signing
> reliably *updates* existing App IDs, but is flaky at *creating* App-Group-bearing
> ones on a cold portal. Before the first run, make sure the three App IDs
> `global.gua`, `global.gua.nse`, and `global.gua.shareextension` are already
> registered in the Developer portal **with the Push, Associated Domains, App Groups
> (`group.global.gua`), and Keychain Sharing capabilities enabled**, and that the
> App Group `group.global.gua` itself exists. The simplest way to seed all of this
> is a one-time manual archive from Xcode (which creates the identifiers, the App
> Group, and the App Store profiles); after that, CI's `-allowProvisioningUpdates`
> keeps them current. If you skip this, the very first CI run can fail at the
> archive's signing phase.

No secrets beyond the table above are required. There is **no** manual-signing fallback configured,
because all targets already use automatic signing (see "Fallback" below if that
ever changes).

## What the workflow does

```
checkout (with LFS)
  -> select Xcode 16.x
  -> cache SwiftPM + Homebrew
  -> brew install xcodegen (+ xcbeautify if missing)
  -> xcodegen generate            # regenerate Gua.xcodeproj from project.yml
  -> write AuthKey_<id>.p8 from ASC_PRIVATE_KEY into $RUNNER_TEMP/private_keys
  -> xcodebuild archive  -allowProvisioningUpdates  CURRENT_PROJECT_VERSION=<run #>
  -> xcodebuild -exportArchive  (fastlane/exportOptions.plist, method app-store-connect)
  -> xcrun altool --validate-app  (fail fast on signing/entitlement/plist rejects)
  -> xcrun altool --upload-package <ipa> --apple-id ASC_APP_ID --bundle-id <prod|dev bundle id>
       (output grepped for "No errors uploading"; altool can exit 0 on failure)
  -> upload the .xcarchive as a run artifact (5-day retention)
  -> always: shred the AuthKey_<id>.p8 from disk
```

Key build facts the workflow relies on:

- **Build system:** Element X fork using **XcodeGen**. `Gua.xcodeproj` is generated
  from `project.yml` + `app.yml` + the per-target `target.yml` files, so the
  workflow regenerates it rather than trusting the committed copy.
- **Scheme:** `Gua`. **Configuration:** `Release` (which compiles with the
  `GUA_DEVELOPMENT` flag — TestFlight currently points at the dev backend; see the
  note in `ElementX/SupportingFiles/target.yml`).
- **Secrets file:** the committed placeholder `Secrets/Secrets.swift` compiles
  fine for an archive. The workflow deliberately does **not** run the
  `fastlane config_production` lane, because its `update_foss_secrets()` helper
  lives in the Enterprise pipeline that is not part of this fork.

## Caveats

- **macOS minutes:** iOS archiving requires a macOS runner (`macos-15`). GitHub
  bills macOS minutes at 10x the Linux rate, and private repos have a monthly free
  allowance — a full archive run can use a meaningful chunk of it. Budget
  accordingly or use a self-hosted Mac runner. **If you use a self-hosted runner,**
  note that `$HOME`/`$RUNNER_TEMP` can persist across jobs, so the App Store Connect
  `.p8` key must not be left on disk. The workflow writes the key under
  `$RUNNER_TEMP/private_keys` and an always-run "Clean up API key" step shreds it at
  the end of every run (including on failure) — keep that step intact.
- **Xcode version:** the project requires Xcode 16+. The workflow selects
  `Xcode_16.4` if present, else the newest `Xcode_16*`. If no `Xcode_16*` is found
  it **fails fast** (rather than silently picking an incompatible toolchain), and it
  also asserts the active `xcodebuild` reports major version >= 16. If the runner
  image drops 16.x or the project later requires a newer Xcode, adjust the
  "Select Xcode" step.
- **`altool` vs `notarytool`:** TestFlight/App Store uploads use `xcrun altool`
  (`--upload-package`, with `--validate-app` first). `notarytool` notarizes Mac apps
  for Gatekeeper and is **not** used for iOS App Store uploads. Note that `altool`
  can exit `0` even when an upload fails, and `--upload-app` cannot pin the target
  app, so the workflow uses `--upload-package` with an explicit `--apple-id`
  (`ASC_APP_ID`) / `--bundle-id` and greps the output for `No errors uploading`
  before treating the run as green.
- **First run is slow:** SwiftPM has to resolve the Matrix Rust SDK and many other
  packages on a cold cache, and Apple has to provision new signing assets the first
  time. Expect the first green run to take longer than subsequent ones.
- **Marketing version:** `MARKETING_VERSION` comes from `project.yml`
  (currently `25.09.12`). Only the build number auto-increments. Bump the marketing
  version in `project.yml` when you want a new TestFlight version string.

## Fallback: manual signing (only if automatic ever fails)

Automatic signing should work for this project as-is. If Apple ever blocks
cloud-managed signing for these bundle ids, switch to importing assets from
secrets:

1. Add secrets `BUILD_CERTIFICATE_BASE64` (base64 of the distribution `.p12`),
   `P12_PASSWORD`, and one `*_PROVISION_PROFILE_BASE64` per bundle id.
2. In the workflow, before archiving: create a temp keychain, import the `.p12`,
   and install each `.mobileprovision` into
   `~/Library/MobileDevice/Provisioning Profiles/`.
3. Set `signingStyle` to `manual` in `fastlane/exportOptions.plist` and add a
   `provisioningProfiles` dictionary mapping each bundle id to its profile name.
4. Flip `CODE_SIGN_STYLE` to `Manual` (and set `CODE_SIGN_IDENTITY` /
   `PROVISIONING_PROFILE_SPECIFIER`) for the three targets.

This is intentionally not wired up — keep the single-API-key path unless you have
to.

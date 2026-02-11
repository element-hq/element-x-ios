# OIDC Authentication Flow — Pre-Rebranding Audit

## Overview

This audit documents all OIDC-related configuration, redirect URIs, and element.io references that must change during rebranding. The OIDC flow uses `ASWebAuthenticationSession` with a redirect URI currently hardcoded to `element.io`.

---

## 1. OIDC Configuration (AppSettings.swift)

### Redirect URI

**File:** `ElementX/Sources/Application/Settings/AppSettings.swift` (line 255)

```swift
private(set) var oidcRedirectURL: URL = "https://element.io/oidc/login"
```

This is the callback URL that the OIDC identity provider redirects to after authentication. It does NOT use universal links — the comment explicitly states this to avoid conflicts between Element X, Nightly, and PR builds.

### OIDC Configuration Structure

**File:** `ElementX/Sources/Application/Settings/AppSettings.swift` (lines 257–263)

```swift
private(set) lazy var oidcConfiguration = OIDCConfiguration(
    clientName: InfoPlistReader.main.bundleDisplayName,
    redirectURI: oidcRedirectURL,
    clientURI: websiteURL,
    logoURI: logoURL,
    tosURI: acceptableUseURL,
    policyURI: privacyURL,
    staticRegistrations: oidcStaticRegistrations.mapKeys { $0.absoluteString }
)
```

All fields derive from other AppSettings properties. Changing the individual URLs cascades into this configuration automatically.

### Static OIDC Registrations

**File:** `ElementX/Sources/Application/Settings/AppSettings.swift` (line 253)

```swift
let oidcStaticRegistrations: [URL: String] = ["https://id.thirdroom.io/realms/thirdroom": "elementx"]
```

Pre-registered client IDs for known OIDC providers. Customer may need to replace or extend this.

### OIDCConfiguration Data Structure

**File:** `ElementX/Sources/Application/Settings/OIDCConfiguration.swift`

```swift
struct OIDCConfiguration {
    let clientName: String
    let redirectURI: URL
    let clientURI: URL
    let logoURI: URL
    let tosURI: URL
    let policyURI: URL
    let staticRegistrations: [String: String]
}
```

No changes needed to this file — it reads from AppSettings.

---

## 2. All element.io URL References

### AppSettings.swift — Brand URLs (lines 207–330)

| Line | Property | Current Value | Must Change |
|------|----------|---------------|-------------|
| 207 | `websiteURL` | `https://element.io` | YES |
| 209 | `logoURL` | `https://element.io/mobile-icon.png` | YES |
| 211 | `copyrightURL` | `https://element.io/copyright` | YES |
| 213 | `acceptableUseURL` | `https://element.io/acceptable-use-policy-terms` | YES |
| 215 | `privacyURL` | `https://element.io/privacy` | YES |
| 217 | `encryptionURL` | `https://element.io/help#encryption` | YES |
| 219 | `deviceVerificationURL` | `https://element.io/help#encryption-device-verification` | YES |
| 221 | `chatBackupDetailsURL` | `https://element.io/help#encryption5` | YES |
| 223 | `identityPinningViolationDetailsURL` | `https://element.io/help#encryption18` | YES |
| 225 | `historySharingDetailsURL` | `https://element.io/en/help#e2ee-history-sharing` | YES |
| 255 | `oidcRedirectURL` | `https://element.io/oidc/login` | YES |
| 330 | `analyticsTermsURL` | `https://element.io/cookie-policy` | YES |

### AppSettings.swift — Host Arrays

| Line | Property | Current Value | Must Change |
|------|----------|---------------|-------------|
| 228 | `elementWebHosts` | `["app.element.io", "staging.element.io", "develop.element.io"]` | YES |
| 230 | `accountProvisioningHost` | `"mobile.element.io"` | YES |

### Other Source Files

| File | Reference | Context |
|------|-----------|---------|
| `AppRoutes.swift` | `knownHosts = ["call.element.io"]` | Element Call host detection |
| `ServerConfirmationScreenModels.swift` | `homeserverAddress == "element.io"` | Special-case for element.io server |
| `SpaceScreen.swift` | `"#engineering-team:element.io"` | Preview/test data only |

---

## 3. Authentication Flow Architecture

### Flow Coordinator Chain

```
AuthenticationFlowCoordinator
  → startScreen
    → serverConfirmationScreen
      → oidcAuthentication (if OIDC supported)
        → ASWebAuthenticationSession
          → callback to oidcRedirectURL
            → loginWithOIDCCallback()
              → complete
```

### Key Files in the Flow

| File | Role |
|------|------|
| `AuthenticationFlowCoordinator.swift` | Orchestrates the flow, creates `OIDCAuthenticationPresenter` |
| `OIDCAuthenticationPresenter.swift` | Creates `ASWebAuthenticationSession`, handles redirect callback |
| `AuthenticationService.swift` | `urlForOIDCLogin()` gets auth URL, `loginWithOIDCCallback()` exchanges code for tokens |
| `AuthenticationClientFactory.swift` | Builds the Matrix SDK client with `.well-known` discovery |
| `OIDCAccountSettingsPresenter.swift` | Post-login OIDC account management |

### OIDCAuthenticationPresenter — Redirect Handling

**File:** `ElementX/Sources/Screens/Authentication/OIDCAuthenticationPresenter.swift`

```swift
// Lines 35-36 — Creates the web auth session
let session = ASWebAuthenticationSession(url: oidcData.url,
    callback: .oidcRedirectURL(oidcRedirectURL)) { url, error in
    continuation.resume(returning: (url, error))
}

// Lines 112-121 — Callback URL handler
extension ASWebAuthenticationSession.Callback {
    static func oidcRedirectURL(_ url: URL) -> Self {
        if url.scheme == "https", let host = url.host() {
            .https(host: host, path: url.path())
        } else if let scheme = url.scheme {
            .customScheme(scheme)
        } else {
            fatalError("Invalid OIDC redirect URL: \(url)")
        }
    }
}
```

### Homeserver Discovery Flow

1. User enters homeserver address (e.g., `example.com`)
2. `LoginHomeserver.sanitized()` normalizes to HTTPS
3. `AuthenticationService.configure()` fetches `.well-known/matrix/client`
4. SDK parses OIDC issuer from response
5. If OIDC is supported, `urlForOIDCLogin()` gets the authorization URL
6. `ASWebAuthenticationSession` presents browser
7. Browser redirects to `oidcRedirectURL` after authentication
8. `loginWithOIDCCallback()` exchanges the authorization code for tokens

### Runtime Override

**AppSettings.swift** (lines 131–171) has an `override()` method that accepts `oidcRedirectURL` as a parameter, enabling runtime configuration without code changes.

---

## 4. Associated Domains & Entitlements

### Main App Entitlements

**File:** `ElementX/SupportingFiles/ElementX.entitlements` (lines 8–18)

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:element.io</string>
    <string>applinks:app.element.io</string>
    <string>applinks:staging.element.io</string>
    <string>applinks:develop.element.io</string>
    <string>applinks:mobile.element.io</string>
    <string>applinks:call.element.io</string>
    <string>applinks:call.element.dev</string>
    <string>applinks:matrix.to</string>
    <string>webcredentials:*.element.io</string>
</array>
```

**Source of truth:** `ElementX/SupportingFiles/target.yml` (lines 114–125) — XcodeGen regenerates entitlements from this YAML.

### URL Schemes

**File:** `ElementX/SupportingFiles/target.yml` (lines 53–69)

```yaml
CFBundleURLTypes:
  - CFBundleTypeRole: Editor
    CFBundleURLName: "Element Call"
    CFBundleURLSchemes: [io.element.call]
  - CFBundleTypeRole: Editor
    CFBundleURLName: "Application"
    CFBundleURLSchemes:
      - $(BASE_BUNDLE_IDENTIFIER)  # Custom routes
      - "matrix"                    # Matrix URI scheme
```

---

## 5. Files That Must Change

### Primary Changes (Customer-Specific Values Required)

| File | What to Change | Depends On |
|------|---------------|------------|
| `AppSettings.swift` line 255 | `oidcRedirectURL` | Customer's OIDC provider redirect endpoint |
| `AppSettings.swift` lines 207–225, 330 | All `element.io` URLs | Customer's website, legal, help pages |
| `AppSettings.swift` line 228 | `elementWebHosts` | Customer's web client domains |
| `AppSettings.swift` line 230 | `accountProvisioningHost` | Customer's provisioning service |
| `AppSettings.swift` line 253 | `oidcStaticRegistrations` | Customer's OIDC static registrations (if any) |
| `target.yml` lines 115–124 | Associated domains | Customer's domains for universal links |
| `target.yml` line 58 | Element Call URL scheme | Customer's call service scheme |

### No Changes Needed

| File | Why |
|------|-----|
| `OIDCConfiguration.swift` | Reads from AppSettings |
| `OIDCAuthenticationPresenter.swift` | Receives redirect URL from AppSettings |
| `AuthenticationService.swift` | Uses `appSettings.oidcConfiguration` |
| `AuthenticationClientFactory.swift` | Generic Matrix client builder |

### Verification After Changes

1. OIDC redirect URL must match what's registered with the customer's OIDC provider
2. Associated domains must match the `apple-app-site-association` file on the customer's server
3. If using HTTPS redirect (not custom scheme), the customer's domain must serve the AASA file
4. The `clientName` in OIDC configuration automatically uses `InfoPlistReader.main.bundleDisplayName` — will update when app name changes

---

## 6. Customer Prerequisites (Decision D-010)

Before OIDC can be reconfigured, the customer must provide:

1. **OIDC provider URL** — The issuer URL of their OIDC identity provider
2. **Redirect URI** — The callback URL to register with the OIDC provider (replaces `https://element.io/oidc/login`)
3. **Static registrations** (optional) — Pre-registered client IDs for known OIDC providers
4. **Website/legal URLs** — Customer's website, privacy policy, terms of use, copyright notice
5. **Associated domains** — Customer's domain(s) for universal links and webcredentials

---

*Last updated: 2026-02-11*

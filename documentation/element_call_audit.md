# Element Call (MatrixRTC + LiveKit) — Pre-Rebranding Audit

## Overview

This audit documents the Element Call integration, configuration, hardcoded references, and all call-related infrastructure that must change during rebranding. The project uses **Element Call** (MatrixRTC + LiveKit), **not Jitsi** as mentioned in the customer's TOR.

---

## 1. Element Call Configuration

### Primary Settings

**File:** `ElementX/Sources/Application/Settings/AppSettings.swift` (lines 371–384)

| Parameter | Current Value | Must Change |
|-----------|---------------|-------------|
| `elementCallBaseURL` | `EmbeddedElementCall.appURL` (embedded web app) | Potentially — customer may host own instance |
| `elementCallBaseURLOverride` | `nil` (UserDefaults) | No — runtime override via Developer Options |
| `elementCallPosthogAPIHost` | `https://posthog-element-call.element.io` | YES — replace or disable |
| `elementCallPosthogAPIKey` | `phc_rXGHx9vDmyEvyRxPziYtdVIv0ahEv8A9uLWFcCi1WcU` | YES — replace or disable |
| `elementCallPosthogSentryDSN` | `https://...@sentry.tools.element.io/41` | YES — replace or disable |

### Element Call Base URL Sources

1. **Embedded (Default):** `EmbeddedElementCall.appURL` — static hosted Element Call web app bundled with the app
2. **Override (Developer):** `elementCallBaseURLOverride` — accessible via Developer Options, stored in UserDefaults
3. **No compile-time configuration needed** — customer can change at runtime

---

## 2. URL Scheme & Universal Links

### URL Scheme Registration

**File:** `ElementX/SupportingFiles/target.yml` (lines 53–59)

```yaml
CFBundleURLTypes:
  - CFBundleTypeRole: Editor
    CFBundleURLName: "Element Call"
    CFBundleURLSchemes: [io.element.call]
```

Registers `io.element.call://` custom scheme. Must change to `{CUSTOMER_BUNDLE_PREFIX}.call`.

### Associated Domains

**File:** `ElementX/SupportingFiles/target.yml` (lines 120–121)

```yaml
com.apple.developer.associated-domains:
  - applinks:call.element.io
  - applinks:call.element.dev
```

Replace with customer's Element Call domain or remove if using embedded version only.

---

## 3. Navigation & Routing

### URL Parser

**File:** `AppRoutes.swift` (lines 136–173)

The `ElementCallURLParser` handles two types of Element Call links:

1. **Custom scheme URLs:** `io.element.call?url=https://call.example.com/...`
2. **Universal links:** `https://call.element.io/room/{roomID}`

Hardcoded known hosts at line 138: `["call.element.io"]` — must change to customer's call domain.

### Call Routes

```swift
case call(roomID: String)          // Room-based calls (MatrixRTC)
case genericCallLink(url: URL)     // External call links
```

### macOS/Catalyst Handling

Element Call routes return `nil` on macOS (Catalyst) — WebRTC not available.

---

## 4. Call Screen Implementation

### Main Call UI

**File:** `CallScreen.swift` — 267 lines

- `CallScreen` (SwiftUI) — Main view with toolbar
- `CallView` (UIViewRepresentable) — Wraps WKWebView
- Implements Picture-in-Picture via `AVPictureInPictureController`
- Route picker for audio output selection
- JavaScript message bridge for widget communication

### Client ID (Hardcoded)

**File:** `CallScreen.swift` (line 353)

```swift
clientID: "io.element.elementx"
```

This identifies the client in MatrixRTC protocol messages. Must change to `"{CUSTOMER_BUNDLE_ID}"`.

### Call Configuration

**File:** `ElementCallConfiguration.swift` — 80 lines

Two configuration kinds:
- `genericCallLink(URL)` — External call link
- `roomCall(...)` — Full room call with SDK integration, encryption, analytics

---

## 5. LiveKit & MatrixRTC Integration

### Widget Driver Architecture

| File | Lines | Purpose |
|------|-------|---------|
| `ElementCallWidgetDriver.swift` | 250 | Room calls with Matrix Rust SDK integration |
| `GenericCallLinkWidgetDriver.swift` | 40 | External call links only |

### How It Works

1. Creates virtual Element Call widget via Matrix Rust SDK
2. Sets encryption mode: `perParticipantKeys` (E2EE) or `unencrypted`
3. Generates WebView URL with widget state
4. Runs widget driver in background task
5. Bidirectional message passing via Widget API

### Widget Props Passed to Element Call

```swift
WidgetSettings.Props(
    elementCallUrl: baseURL.absoluteString,
    widgetId: UUID().uuidString,
    encryption: useEncryption ? .perParticipantKeys : .unencrypted,
    posthogApiHost: analyticsConfiguration?.posthogAPIHost,
    posthogApiKey: analyticsConfiguration?.posthogAPIKey,
    sentryDsn: analyticsConfiguration?.sentryDSN
)
```

### Customer Infrastructure Requirements

| Component | Required | Details |
|-----------|----------|---------|
| Element Call instance | Yes (if using calls) | Hosted web app or use embedded version |
| LiveKit server | Yes | SFU for WebRTC calls |
| Homeserver config | Yes | `.well-known/matrix/client` must advertise Element Call |
| TURN/STUN servers | Recommended | For NAT traversal (included with LiveKit) |

---

## 6. Entitlements & Capabilities

### VoIP Background Mode

**File:** `ElementX/SupportingFiles/target.yml` (lines 90–95)

```yaml
UIBackgroundModes: [audio, fetch, processing, voip]
```

Enables CallKit and VoIP push notifications.

### Permissions (No Changes Needed)

Camera and microphone permission strings are generic — suitable for any brand.

---

## 7. Hardcoded References — Complete Inventory

| File | Line | Reference | Change To |
|------|------|-----------|-----------|
| `target.yml` | 56 | `"Element Call"` (URL name) | `"{CUSTOMER_BRAND} Call"` |
| `target.yml` | 58 | `io.element.call` (URL scheme) | `{CUSTOMER_CALL_SCHEME}` |
| `target.yml` | 120 | `applinks:call.element.io` | `applinks:{CUSTOMER_CALL_DOMAIN}` |
| `target.yml` | 121 | `applinks:call.element.dev` | Remove (dev domain) |
| `AppSettings.swift` | 379 | `posthog-element-call.element.io` | Replace or disable |
| `AppSettings.swift` | 381 | `sentry.tools.element.io` | Replace or disable |
| `AppRoutes.swift` | 138 | `["call.element.io"]` | `["{CUSTOMER_CALL_DOMAIN}"]` |
| `CallScreen.swift` | 353 | `"io.element.elementx"` (clientID) | `"{CUSTOMER_BUNDLE_ID}"` |

---

## 8. Can Calls Be Disabled?

**Current state:** NO built-in feature flag to disable calls on iOS.

### Option A: Disable via Server Configuration
- Customer's homeserver does NOT advertise Element Call in `.well-known/matrix/client`
- Calls won't initiate if Element Call isn't configured server-side
- **Simplest approach — no code changes needed**

### Option B: Disable via Code Changes (~2–3 hours)
1. Remove "Join Call" button from RoomScreen
2. Hide call icon from room details shortcuts
3. Conditionally skip CallScreenCoordinator initialization
4. Remove Element Call associated domains
5. Remove EmbeddedElementCall package dependency

### Option C: Proceed with Element Call
- Requires LiveKit infrastructure
- Customer provides Element Call hosting or uses embedded version
- Rebranding changes are straightforward (~15 min)

---

## 9. Key Technical Notes

1. **Embedded Element Call:** Project includes `EmbeddedElementCall` SPM package — calls work out-of-box if homeserver is configured
2. **No Jitsi Support:** Customer's TOR mentions Jitsi but is incorrect. **Decision D-011 needed**
3. **Encryption:** Calls support E2EE via per-participant encryption (if room is encrypted)
4. **Picture-in-Picture:** Supported natively
5. **CallKit Integration:** Uses CallKit for native call UI and VoIP push notifications
6. **No Call History:** Calls don't appear in native iOS Call History — only in Matrix room timeline
7. **Developer Override:** Developer Options screen allows overriding `elementCallBaseURL` at runtime

---

## 10. Rebranding Checklist

| Task | File(s) | Priority | Effort |
|------|---------|----------|--------|
| Update call URL scheme | `target.yml` line 58 | HIGH | 1 min |
| Update associated domains | `target.yml` lines 120–121 | HIGH | 1 min |
| Update call known hosts | `AppRoutes.swift` line 138 | HIGH | 1 min |
| Update Element Call clientID | `CallScreen.swift` line 353 | HIGH | 1 min |
| Update call analytics endpoints | `AppSettings.swift` lines 379–381 | MEDIUM | 5 min |
| Update CFBundleURLName | `target.yml` line 56 | LOW | 1 min |
| Run `xcodegen generate` | — | REQUIRED | 1 min |

---

*Last updated: 2026-02-11*

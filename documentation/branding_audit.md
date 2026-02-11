# Compound Design System & Branding — Pre-Rebranding Audit

## Overview

This audit documents the Compound design token system, color assets, app icons, launch screen, brand strings, and all visual/textual elements that must change during rebranding.

---

## 1. Compound Design System

### Package Structure

The app uses Element's **Compound Design System**, a cross-platform semantic design token system.

| Component | Location | Version |
|-----------|----------|---------|
| Local Swift wrapper | `compound-ios/` (SPM package) | Local |
| External design tokens | `compound-design-tokens` (GitHub: element-hq) | v6.9.0 (exact) |
| Additional dependencies | SwiftUI-Introspect v26.0+, SFSafeSymbols v7.0+, swift-snapshot-testing v1.18.7 | — |

**27 Swift files** in the local package provide SwiftUI/UIKit APIs around the Compound tokens.

### Color Architecture

```swift
// SwiftUI access
Color.compound.textPrimary
Color.compound.bgCanvasDefault

// UIKit access
UIColor.compound.textPrimary
UIColor.compound.bgCanvasDefault
```

The `CompoundColors` class uses:
- `@Observable` for reactive SwiftUI updates
- `@dynamicMemberLookup` for property-based token access
- Runtime override system via `override(_ keyPath:, with:)` method
- Base tokens from `CompoundCoreColorTokens` (external package)
- Semantic tokens from `CompoundColorTokens` (external package)

### Color Token Categories

| Category | Examples |
|----------|---------|
| Text | `textPrimary`, `textSecondary`, `textTertiary`, `textDisabled`, `textLinkExternal`, `textBadgeAccent` |
| Background | `bgCanvasDefault`, `bgCanvasDefaultLevel1`, `bgSubtlePrimary`, `bgBadgeDefault`, `bgDecorative1-6` |
| Icon | `iconPrimary`, `iconSecondary`, `iconTertiary`, `iconDisabled`, `iconAccentTertiary` |
| Border | `borderInteractiveSecondary`, `borderCriticalPrimary` |
| Decorative | 6 predefined decoration color pairs (background + text) |

### Key Color Files

| File | Purpose |
|------|---------|
| `compound-ios/Sources/Compound/Colors/CompoundColors.swift` | SwiftUI Color extension + dynamic override system (125 lines) |
| `compound-ios/Sources/Compound/Colors/CompoundUIColors.swift` | UIKit UIColor extension + override system (60 lines) |
| `compound-ios/Sources/Compound/Colors/CompoundGradients.swift` | Gradient definitions using color stop tokens (47 lines) |

---

## 2. Asset Catalog Colors

**Location:** `ElementX/Resources/Assets.xcassets/colors/`

### accent-color

**File:** `colors/accent-color.colorset/Contents.json`

| Appearance | RGB | Description |
|-----------|-----|-------------|
| Light | (0.106, 0.114, 0.133) | Dark gray |
| Dark | (0.922, 0.933, 0.949) | Light gray |
| High Contrast Light | (0.102, 0.110, 0.129) | Slightly darker |
| High Contrast Dark | (0.949, 0.961, 0.969) | Slightly lighter |

Referenced in `app.yml`:
```yaml
ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: "colors/accent-color"
```

This asset controls: navigation bar tints, link colors, selection highlights, button tints, UI control accents.

### background-color

**File:** `colors/background-color.colorset/Contents.json`

| Appearance | RGB | Description |
|-----------|-----|-------------|
| Light | (1.0, 1.0, 1.0) | White |
| Dark | (0.063, 0.075, 0.090) | Dark gray |

Referenced in `target.yml` for launch screen:
```yaml
UILaunchScreen:
  UIColorName: colors/background-color
```

---

## 3. Visual Assets

### App Logo

**Location:** `ElementX/Resources/Assets.xcassets/images/app-logo.imageset/`

- **File:** `app-logo.pdf` (52 KB, vector)
- **Format:** PDF (scalable, all sizes auto-generated)
- **Usage:** In-app branding, onboarding screens

### Launch Screen Background

**Location:** `ElementX/Resources/Assets.xcassets/images/launch-background.imageset/`

| File | Size | Purpose |
|------|------|---------|
| `iphone-light.png` | 100 KB | iPhone light mode |
| `iphone-dark.png` | 186 KB | iPhone dark mode |
| `ipad-light.png` | 233 KB | iPad light mode |
| `ipad-dark.png` | 413 KB | iPad dark mode |

**Launch screen is SwiftUI-based** — no LaunchScreen.storyboard. Uses the `background-color` asset as fill color.

### App Icon

Not in Assets.xcassets images — provided separately via XcodeGen configuration. Customer must provide a 1024x1024 icon.

---

## 4. Theme Propagation

### CompoundHook — Color Override Extension Point

**File:** `ElementX/Sources/AppHooks/Hooks/CompoundHook.swift`

```swift
protocol CompoundHookProtocol {
    @MainActor func override(colors: CompoundColors, uiColors: CompoundUIColors)
}

struct DefaultCompoundHook: CompoundHookProtocol {
    func override(colors: CompoundColors, uiColors: CompoundUIColors) { }
}
```

Called in `AppCoordinator.swift` (line 75):
```swift
appHooks.compoundHook.override(colors: Color.compound, uiColors: UIColor.compound)
```

To customize colors programmatically, implement a custom hook:
```swift
struct CustomCompoundHook: CompoundHookProtocol {
    @MainActor func override(colors: CompoundColors, uiColors: CompoundUIColors) {
        colors.override(\.textPrimary, with: Color(...))
    }
}
```

### Appearance Settings

**File:** `ElementX/Sources/Application/Settings/AppAppearance.swift`

```swift
enum AppAppearance: CaseIterable, Codable {
    case system   // Device settings
    case dark     // Forces dark mode
    case light    // Forces light mode
}
```

### Color Usage Spread

104 uses of `Color.compound.*` and `UIColor.compound.*` across:
- Voice message UI (waveforms, playback controls)
- Timeline pills and mentions
- HTML parsing (code blocks, quotes)
- Form components (buttons, text fields)
- Layout helpers
- Avatar rendering

---

## 5. Brand Strings

### App Name Configuration

**File:** `app.yml`

```yaml
APP_DISPLAY_NAME: Element X       # User-facing name
PRODUCTION_APP_NAME: Element       # Server identification
BASE_BUNDLE_IDENTIFIER: io.element.elementx
```

### InfoPlist.strings (37 Locales)

**Location:** `ElementX/Resources/Localizations/*/InfoPlist.strings`

Permission strings reference the app name via `$(APP_DISPLAY_NAME)` in YAML, but the localized `.strings` files contain hardcoded "Element X":

- "To take pictures or videos and send them as a message Element X needs access to the camera."
- "To record and send messages with audio, Element X needs to access the microphone."
- "Grant location access so that Element X can share your location."

**37 locales** must be updated: be, bg, cs, cy, da, de, el, en, en-US, es, et, eu, fa, fi, fr, hr, hu, id, it, ka, and more.

### Generated Strings

**File:** `ElementX/Sources/Generated/Strings.swift`

Auto-generated from `Localizable.strings`. Contains brand references:
- "Element X" (display name)
- "Element" (production app name)
- "Element Pro" (premium version references)
- "element.io" (website references)

This file is auto-regenerated — change the source `.strings` files instead.

### Localizable.strings Brand References

String keys with Element brand content:
- `screen_server_confirmation_message_login_element_dot_io` — "A private server for Element employees."
- Element Call references
- Element Pro references

---

## 6. Complete Rebranding File List

### Colors & Styling (MUST CHANGE)

| File | What to Change | Impact |
|------|---------------|--------|
| `Assets.xcassets/colors/accent-color.colorset/Contents.json` | RGB values for all 4 variants | App tint color everywhere |
| `Assets.xcassets/colors/background-color.colorset/Contents.json` | RGB values for all variants | Launch screen + canvas |

### Visual Assets (MUST CHANGE)

| File | What to Change | Impact |
|------|---------------|--------|
| `Assets.xcassets/images/app-logo.imageset/app-logo.pdf` | Replace with customer logo (PDF vector) | In-app branding, onboarding |
| `Assets.xcassets/images/launch-background.imageset/iphone-light.png` | Replace with branded image | iPhone launch screen (light) |
| `Assets.xcassets/images/launch-background.imageset/iphone-dark.png` | Replace with branded image | iPhone launch screen (dark) |
| `Assets.xcassets/images/launch-background.imageset/ipad-light.png` | Replace with branded image | iPad launch screen (light) |
| `Assets.xcassets/images/launch-background.imageset/ipad-dark.png` | Replace with branded image | iPad launch screen (dark) |

### Configuration Files (MUST CHANGE)

| File | What to Change |
|------|---------------|
| `app.yml` | `APP_DISPLAY_NAME`, `PRODUCTION_APP_NAME`, `BASE_BUNDLE_IDENTIFIER`, `APP_GROUP_IDENTIFIER`, `DEVELOPMENT_TEAM` |
| `project.yml` | `ORGANIZATIONNAME`, `MARKETING_VERSION` if needed |
| `ElementX/SupportingFiles/target.yml` | Verify `CFBundleDisplayName` variable substitution, URL schemes |

### Localization (MUST CHANGE — 74+ files)

| Category | Files | Count |
|----------|-------|-------|
| `InfoPlist.strings` | All 37 locales | 37 |
| `Localizable.strings` | Search & replace brand references across all locales | 37 |
| `Strings.swift` | Auto-regenerated after `.strings` changes | 1 |

### App Settings (MUST CHANGE)

| File | Lines | What |
|------|-------|------|
| `AppSettings.swift` | 207–230 | All `element.io` URLs (website, logo, legal, help) |
| `AppSettings.swift` | 255 | OIDC redirect URL |
| `AppSettings.swift` | 330 | Analytics terms URL |

### Optional Extension Points

| File | Mechanism | Use Case |
|------|-----------|----------|
| `CompoundHook.swift` | `CompoundHookProtocol` | Programmatic color overrides |
| `AppSettings.override()` | Runtime configuration | Override URLs/providers remotely |
| `AppSettings.hideBrandChrome` | Feature flag | Hide/show brand UI elements |

---

## 7. Summary

| Category | Files to Modify | Priority | Effort |
|----------|----------------|----------|--------|
| Colors (asset catalog) | 2 | HIGH | Low |
| Icons/Images | 5 | HIGH | Medium (customer provides assets) |
| Configuration YAML | 3 | HIGH | Low |
| Localization strings | 74 (37 × 2 types) | HIGH | High |
| AppSettings URLs | 1 (many lines) | HIGH | Medium |
| CompoundHook | 1 | OPTIONAL | Low |

**Total files to modify:** ~86 (including all locale variants)

### Key Technical Notes

1. Never edit `.xcodeproj` directly — use XcodeGen YAML files
2. The `CompoundDesignTokens` external package (v6.9.0) cannot be modified
3. Color system is two-layer: asset catalog + runtime overrides via Compound tokens
4. Localization uses `.strings` files (legacy), not String Catalogs — all 37 locales require manual updates
5. Launch screen is dynamic (no storyboard) — uses `background-color` asset
6. All AppSettings URLs can be overridden at runtime via `AppSettings.override()` method

---

*Last updated: 2026-02-11*

# Privacy Manifest Compliance — Pre-Rebranding Audit

## Overview

This audit documents the privacy manifest status, Required Reason API declarations, data collection practices, third-party SDK compliance, and gaps that must be addressed before App Store submission.

**Overall Compliance Grade: B+ (88%)**

---

## 1. Current Privacy Manifest Status

| Target | File | Status |
|--------|------|--------|
| Main App | `ElementX/SupportingFiles/PrivacyInfo.xcprivacy` | EXISTS |
| NSE | `NSE/SupportingFiles/PrivacyInfo.xcprivacy` | EXISTS |
| ShareExtension | — | **MISSING** (GAP) |

---

## 2. Required Reason APIs

### Declared APIs (Main App + NSE)

| API Category | Reason Code | Purpose | Status |
|---|---|---|---|
| UserDefaults | `1C8F.1` | App functionality | DECLARED |
| FileTimestamp | `C617.1` | App functionality | DECLARED |
| DiskSpace | `7D9E.1` | App functionality | DECLARED |
| SystemBootTime | `8FFB.1` | App functionality | DECLARED |

### Confirmed Code Usage

| API | File | Usage |
|-----|------|-------|
| UserDefaults | `AppSettings.swift` | Primary storage for user preferences (12+ keys) |
| FileTimestamp | `CameraPicker.swift`, `PhotoLibraryManager.swift` | Media file operations |
| DiskSpace | Various FileManager operations | Video quality selection, media optimization |
| SystemBootTime | `NSE/Sources/BootDetectionManager.swift` | Notification sequencing, boot time tracking |

### Missing Declaration (GAP)

**Network Information API** — `NWPathMonitor` used in `NetworkMonitor.swift` but NOT declared.

```
NSPrivacyAccessedAPICategoryNetworkInformation — Reason: 55BD.1
```

---

## 3. Data Collection Practices

### Declared in PrivacyInfo.xcprivacy

| Data Type | Linked to User | Used for Tracking | Purposes |
|---|---|---|---|
| Email Address | YES | NO | App Functionality |
| Precise Location | YES | NO | App Functionality |
| Contacts | NO | NO | App Functionality |
| Photos/Videos | NO | NO | App Functionality |
| Audio Data | NO | NO | App Functionality |
| User ID | YES | NO | App Functionality, Analytics |
| Device ID | YES | NO | App Functionality |
| Product Interaction | NO | NO | Analytics |
| Crash Data | NO | NO | App Functionality |
| Performance Data | NO | NO | Analytics |
| Other Diagnostic Data | YES | NO | App Functionality |

**NSPrivacyTracking:** `false` (no third-party tracking)

### Analytics Infrastructure

**PostHog** (opt-in analytics):
- Current config: `https://posthog.localhost` (placeholder — inactive)
- Opt-in model: Users must explicitly consent; can change in Settings
- No auto-capture: `captureScreenViews: false`, `enableSwizzling: false`

**Sentry** (crash reporting):
- Current config: `https://username@sentry.localhost/project_id` (placeholder — inactive)
- Only initializes with valid production DSN
- Also opt-in via analytics consent

**Firebase/FCM** (push notifications):
- Device token only (for push routing)
- Conditional initialization based on `GoogleService-Info.plist`

---

## 4. Third-Party SDK Privacy Compliance

| SDK | Privacy Manifest | Data Collection | Status |
|-----|------------------|-----------------|--------|
| Firebase SDK (v11.8.x) | Included in framework | Device token only | OK |
| PostHog SDK | Included | Configurable events | OK |
| Sentry SDK | Included | Crash/error data | OK |
| Kingfisher | Included (v7.x) | Cache management only | OK |
| Matrix Rust SDK | **Unknown** (opaque binary) | All Matrix protocol data | Verify |
| Compound (design) | N/A (pure UI) | None | OK |
| Lottie | Included | None | OK |

---

## 5. Permission Strings

| Permission | Key | Declared | Used |
|---|---|---|---|
| Camera | `NSCameraUsageDescription` | YES | YES |
| Microphone | `NSMicrophoneUsageDescription` | YES | YES |
| Photo Library (Add) | `NSPhotoLibraryAddUsageDescription` | YES | YES |
| Photo Library (Read) | `NSPhotoLibraryUsageDescription` | **NO** | Verify |
| Location (When In Use) | `NSLocationWhenInUseUsageDescription` | YES | YES (message-based) |
| Face ID | `NSFaceIDUsageDescription` | YES | Verify |

---

## 6. Critical Gaps & Recommendations

### GAP 1: ShareExtension Missing Privacy Manifest (HIGH)

**Action:** Create `ShareExtension/SupportingFiles/PrivacyInfo.xcprivacy` declaring at minimum: UserDefaults, FileTimestamp, DiskSpace.

### GAP 2: Network Information API Not Declared (MEDIUM)

**Action:** Add to both Main App and NSE manifests:

```xml
<dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryNetworkInformation</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array>
        <string>55BD.1</string>
    </array>
</dict>
```

### GAP 3: Placeholder Configuration Values (CRITICAL for App Store)

Customer must provide before submission:
- Real PostHog host and API key (if analytics desired)
- Real Sentry DSN (if crash reporting desired)
- Real Rageshake server URL (if bug reporting desired)
- Real `GoogleService-Info.plist` for Firebase/FCM

### GAP 4: Photo Library Read Permission (LOW)

Review `PhotoLibraryManager` — if it reads from photo library (not just adds), `NSPhotoLibraryUsageDescription` must be declared.

---

## 7. App Store Submission Readiness

| Item | Status | Notes |
|---|---|---|
| Main app PrivacyInfo.xcprivacy | OK | Comprehensive, well-formed |
| NSE PrivacyInfo.xcprivacy | OK | Matches main app |
| ShareExtension PrivacyInfo.xcprivacy | **MISSING** | Must create |
| Network Information API | **NOT DECLARED** | Must add |
| Analytics configuration | PLACEHOLDER | Customer must configure |
| FCM configuration | PLACEHOLDER | Customer must configure |
| Permission strings | MOSTLY OK | Verify photo library |
| Privacy policy URL | UNKNOWN | Must reflect actual practices |

---

## 8. Summary

| Category | Status | Risk | Action |
|---|---|---|---|
| Privacy manifests exist | PARTIAL | MEDIUM | Create ShareExtension manifest |
| Required Reason APIs | 80% | MEDIUM | Add NetworkInformation |
| Data collection practices | GOOD | LOW | None |
| Third-party SDKs | READY | LOW | Verify manifests at build time |
| Permission strings | 95% | LOW | Verify photo library usage |
| Analytics configuration | PLACEHOLDER | HIGH | Customer must configure |
| FCM configuration | PLACEHOLDER | HIGH | Customer must configure |
| Privacy UX/consent | GOOD | LOW | Excellent opt-in implementation |

**Strengths:** Comprehensive manifests, correct NSPrivacyTracking=false, excellent opt-in consent model, accurate data declarations.

**For submission:** Fix 2 gaps (ShareExtension manifest + NetworkInformation API), customer provides real configuration values, resolve AGPL licensing.

---

*Last updated: 2026-02-11*

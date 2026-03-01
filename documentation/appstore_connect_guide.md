# App Store Connect & Developer Portal Setup Guide

Step-by-step guide for registering Bundle IDs, creating the app, and configuring provisioning for UCMeet.Chat.

**Prerequisites:**
- Apple Developer account with Administrator role (Team ID: `26UC01GH`)
- Access to [Apple Developer Portal](https://developer.apple.com/account)
- Access to [App Store Connect](https://appstoreconnect.apple.com)

---

## Step 1: Register Bundle IDs

Go to **Certificates, Identifiers & Profiles → Identifiers → App IDs**.

Register three Bundle IDs:

### 1.1 Main App

- **Description:** UCMeet.Chat
- **Bundle ID:** `org.ucmeet.UCMeetChat` (Explicit)
- **Capabilities to enable:**
  - Push Notifications
  - Associated Domains
  - App Groups

### 1.2 Notification Service Extension (NSE)

- **Description:** UCMeet.Chat NSE
- **Bundle ID:** `org.ucmeet.UCMeetChat.nse` (Explicit)
- **Capabilities to enable:**
  - App Groups

### 1.3 Share Extension

- **Description:** UCMeet.Chat Share Extension
- **Bundle ID:** `org.ucmeet.UCMeetChat.shareextension` (Explicit)
- **Capabilities to enable:**
  - App Groups

---

## Step 2: Create App Group

Go to **Certificates, Identifiers & Profiles → Identifiers → App Groups**.

- **Group ID:** `group.org.ucmeet`
- **Description:** UCMeet Shared Data

After creation, go back to each of the 3 Bundle IDs above and assign this App Group.

---

## Step 3: Enable Capabilities per Target

For each registered Bundle ID, verify these capabilities are enabled:

| Capability | Main App | NSE | Share Extension |
|-----------|----------|-----|-----------------|
| Push Notifications | Yes | No | No |
| Associated Domains | Yes | No | No |
| App Groups | Yes | Yes | Yes |
| Keychain Sharing | Yes | No | No |

The Keychain Access Group identifier used in the project is `$(AppIdentifierPrefix)$(BASE_BUNDLE_IDENTIFIER)` — this is auto-configured by Xcode when Keychain Sharing is enabled.

---

## Step 4: Create App in App Store Connect

Go to **App Store Connect → My Apps → "+" → New App**.

| Field | Value |
|-------|-------|
| Platform | iOS |
| Name | UCMeet.Chat |
| Primary Language | Russian |
| Bundle ID | org.ucmeet.UCMeetChat (select from dropdown) |
| SKU | `ucmeetchat` (or any unique identifier) |
| User Access | Full Access |

### App Information

| Field | Value |
|-------|-------|
| Subtitle (optional) | Secure Matrix Messenger |
| Category | Social Networking |
| Secondary Category | Productivity (optional) |
| Content Rights | Does not contain third-party content requiring rights |
| Age Rating | 12+ (user-generated content via chat) |

### Privacy Policy URL

`https://ucmeet.info/policy-152`

### Support URL

`https://ucmeet.info` (or customer's dedicated support page)

---

## Step 5: Provisioning Profiles

Go to **Certificates, Identifiers & Profiles → Profiles**.

Create **6 profiles** (Development + Distribution for each target):

### Development Profiles

| Profile Name | Type | Bundle ID | Certificate |
|-------------|------|-----------|-------------|
| UCMeet.Chat Dev | iOS App Development | `org.ucmeet.UCMeetChat` | Dev cert |
| UCMeet.Chat NSE Dev | iOS App Development | `org.ucmeet.UCMeetChat.nse` | Dev cert |
| UCMeet.Chat Share Dev | iOS App Development | `org.ucmeet.UCMeetChat.shareextension` | Dev cert |

### Distribution Profiles

| Profile Name | Type | Bundle ID | Certificate |
|-------------|------|-----------|-------------|
| UCMeet.Chat Dist | App Store Distribution | `org.ucmeet.UCMeetChat` | Distribution cert |
| UCMeet.Chat NSE Dist | App Store Distribution | `org.ucmeet.UCMeetChat.nse` | Distribution cert |
| UCMeet.Chat Share Dist | App Store Distribution | `org.ucmeet.UCMeetChat.shareextension` | Distribution cert |

> **Tip:** If using Xcode Automatic Signing (recommended for development), Xcode will create development profiles automatically. You only need to manually create Distribution profiles for App Store submission.

---

## Step 6: Configure Xcode Signing

In Xcode (after running `xcodegen generate`):

1. Select the **ElementX** target → Signing & Capabilities
   - Team: `26UC01GH`
   - Bundle Identifier: `org.ucmeet.UCMeetChat`
   - Enable "Automatically manage signing" for Debug
   - For Release: select the Distribution provisioning profile

2. Select the **NSE** target → Signing & Capabilities
   - Team: `26UC01GH`
   - Bundle Identifier: `org.ucmeet.UCMeetChat.nse`

3. Select the **ShareExtension** target → Signing & Capabilities
   - Team: `26UC01GH`
   - Bundle Identifier: `org.ucmeet.UCMeetChat.shareextension`

---

## Step 7: APNs Key (for Push Notifications)

Go to **Certificates, Identifiers & Profiles → Keys**.

1. Create a new key:
   - **Name:** UCMeet Push Key
   - **Enable:** Apple Push Notifications service (APNs)
2. Download the `.p8` file — **save it securely, it can only be downloaded once**
3. Note the **Key ID** (10 characters)
4. This key + Team ID (`26UC01GH`) will be needed for:
   - Firebase Cloud Messaging configuration
   - Sygnal push gateway configuration

---

## Step 8: Verification Checklist

After completing all steps:

- [ ] 3 Bundle IDs registered (main + NSE + share extension)
- [ ] App Group `group.org.ucmeet` created and assigned to all 3 Bundle IDs
- [ ] Push Notifications enabled for main app Bundle ID
- [ ] Associated Domains enabled for main app Bundle ID
- [ ] App created in App Store Connect with correct Bundle ID
- [ ] Development provisioning profiles working (or automatic signing enabled)
- [ ] Distribution provisioning profiles created
- [ ] APNs key downloaded and Key ID noted
- [ ] Xcode signing configured for all 3 targets
- [ ] Test build to device succeeds with correct Bundle ID

---

## Troubleshooting

### "No matching provisioning profiles found"
- Ensure Bundle IDs match exactly (case-sensitive: `UCMeetChat` not `ucmeetchat`)
- Download latest profiles in Xcode: Preferences → Accounts → Download Manual Profiles

### "App Group container not accessible"
- Verify App Group is assigned to all 3 Bundle IDs in the Developer Portal
- Rebuild after adding the App Group capability

### "Push registration failed"
- Ensure Push Notifications capability is enabled in the Developer Portal (not just Xcode)
- Verify the APNs key is uploaded to Firebase project settings

---

*Last updated: 2026-03-01.*

# Firebase Project Setup Guide — UCMeet.Chat

Step-by-step guide for creating the Firebase project, configuring FCM push notifications, and integrating with the iOS app and Sygnal push gateway.

**Prerequisites:**
- Google account (any Gmail)
- APNs Authentication Key: `AuthKey_XZANH7CD3Z.p8` (Key ID: `XZANH7CD3Z`, Team ID: `26UC01GH`)
- Access to [Firebase Console](https://console.firebase.google.com)

---

## Step 1: Create Firebase Project

1. Go to **https://console.firebase.google.com**
2. Click **"Create a project"** (or "Add project")
3. Enter project name: `UCMeet-Chat` (or `ucmeet-chat`)
4. **Disable Google Analytics** — not needed for push notifications only. Click "Create project"
5. Wait for project creation to complete, then click **"Continue"**

---

## Step 2: Add iOS App to Firebase Project

1. On the project overview page, click the **iOS icon** (Apple logo) to add an iOS app
2. Fill in the registration form:

| Field | Value |
|-------|-------|
| **Apple bundle ID** | `org.ucmeet.UCMeetChat` |
| App nickname (optional) | `UCMeet.Chat` |
| App Store ID (optional) | Leave blank (not published yet) |

3. Click **"Register app"**

### Download GoogleService-Info.plist

4. Firebase will generate and offer to download **`GoogleService-Info.plist`**
5. **Download it** — this is the critical file. It contains:
   - `API_KEY` — Firebase API key (starts with `AI...`, 39 characters)
   - `GCM_SENDER_ID` — a 12-digit number (the Firebase project number)
   - `GOOGLE_APP_ID` — format `1:XXXXXXXXXXXX:ios:XXXXXXXXXXXXXX`
   - `PROJECT_ID` — your project ID string (e.g. `ucmeet-chat`)
   - `BUNDLE_ID` — should show `org.ucmeet.UCMeetChat`

6. Click **"Next"** through the remaining SDK setup steps (we've already added the Firebase SDK via SPM). Click **"Continue to console"**

> **Important:** Keep this file safe. You'll need it in Step 4.

---

## Step 3: Configure APNs in Firebase

Firebase needs the APNs key to send push notifications through Apple's infrastructure.

1. In Firebase Console, go to **Project Settings** (gear icon next to "Project Overview")
2. Select the **"Cloud Messaging"** tab
3. Scroll down to **"Apple app configuration"**
4. Under **"APNs authentication key"**, click **"Upload"**
5. Fill in the form:

| Field | Value |
|-------|-------|
| **APNs auth key (.p8 file)** | Upload `AuthKey_XZANH7CD3Z.p8` |
| **Key ID** | `XZANH7CD3Z` |
| **Team ID** | `26UC01GH` |

6. Click **"Upload"**
7. You should see a green checkmark confirming the APNs key is configured

### Verify Configuration

After uploading, the Cloud Messaging tab should show:
- APNs authentication key: **Uploaded** (Key ID: XZANH7CD3Z)
- This single key works for both development and production push notifications

---

## Step 4: Replace Placeholder GoogleService-Info.plist in Xcode Project

The project currently has a placeholder file at:
```
ElementX/SupportingFiles/GoogleService-Info.plist
```

Current placeholder contents (all TODO values):
```xml
<key>API_KEY</key>
<string>TODO-customer-api-key</string>
<key>GCM_SENDER_ID</key>
<string>000000000000</string>
<key>PROJECT_ID</key>
<string>TODO-customer-project-id</string>
<key>GOOGLE_APP_ID</key>
<string>1:000000000000:ios:0000000000000000</string>
```

### Replace the file:

```bash
# Backup the placeholder
cp ElementX/SupportingFiles/GoogleService-Info.plist \
   ElementX/SupportingFiles/GoogleService-Info.plist.placeholder

# Copy the downloaded file (adjust source path as needed)
cp ~/Downloads/GoogleService-Info.plist \
   ElementX/SupportingFiles/GoogleService-Info.plist
```

### Verify the replacement:

```bash
# Should show real values (not TODO)
grep -A1 "API_KEY\|GCM_SENDER_ID\|PROJECT_ID\|GOOGLE_APP_ID" \
  ElementX/SupportingFiles/GoogleService-Info.plist
```

Expected output — real values like:
```
<key>API_KEY</key>
<string>AIza...(39 chars)...</string>
<key>GCM_SENDER_ID</key>
<string>123456789012</string>
<key>PROJECT_ID</key>
<string>ucmeet-chat</string>
<key>GOOGLE_APP_ID</key>
<string>1:123456789012:ios:abcdef1234567890</string>
```

> **Note:** The `BUNDLE_ID` field in the plist uses `$(PRODUCT_BUNDLE_IDENTIFIER)` — this is an Xcode build variable that resolves to `org.ucmeet.UCMeetChat` at build time. Do NOT change this to a hardcoded value.

### Validation guard in code

The app has a safety check in `FirebaseNotificationService.swift:28-31` that skips Firebase initialization if the API key looks like a placeholder:

```swift
guard let options = FirebaseOptions.defaultOptions(),
      options.apiKey?.hasPrefix("A") == true,
      options.apiKey?.count == 39 else {
    MXLog.warning("Firebase not configured: GoogleService-Info.plist contains placeholder values.")
    return
}
```

With a real `GoogleService-Info.plist`, this guard passes and Firebase initializes normally.

---

## Step 5: Build and Verify Firebase Initialization

```bash
# Regenerate project (if needed after file changes)
xcodegen generate

# Build
xcodebuild build -project ElementX.xcodeproj -scheme ElementX \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### What to look for in console logs:

**With placeholder plist (current state):**
```
⚠️ Firebase not configured: GoogleService-Info.plist contains placeholder values. Push notifications disabled.
```

**With real plist (after replacement):**
```
✅ FCM registration token updated
```

> On simulator, Firebase will initialize but FCM tokens may not be delivered (APNs not available on simulator). Real device testing is needed for full push verification — see Step 8.

---

## Step 6: Get FCM Server Key for Sygnal

Sygnal needs the FCM server credentials to forward push notifications from Matrix to Firebase (which then delivers to APNs).

### Option A: FCM v1 API (Recommended — new Sygnal versions)

1. In Firebase Console → **Project Settings** → **Service accounts**
2. Click **"Generate new private key"**
3. Download the JSON file (e.g. `ucmeet-chat-firebase-adminsdk-xxxxx.json`)
4. This JSON file must be provided to whoever configures Sygnal on the server side

### Option B: Legacy Server Key (Older Sygnal versions)

1. In Firebase Console → **Project Settings** → **Cloud Messaging** tab
2. Under **"Cloud Messaging API (Legacy)"** — if it says "Disabled", click the three-dot menu → **"Manage API in Google Cloud Console"** → Enable it
3. Copy the **Server key** (starts with `AAAA...`)
4. Provide this key to whoever configures Sygnal

> **Which one?** Ask the customer which Sygnal version they run. Sygnal v0.12+ supports FCM v1 API (JSON). Older versions need the legacy server key.

---

## Step 7: Sygnal Configuration (Customer's Server)

The customer's Sygnal instance at `push.ucmeet.org` needs to be configured to accept FCM pushers from this app.

### What to provide to the customer:

| Item | Value | Where to get it |
|------|-------|----------------|
| **Pusher App ID (debug)** | `org.ucmeet.UCMeetChat.ios.dev` | Auto-generated from Bundle ID in `AppSettings.swift:284-289` |
| **Pusher App ID (release)** | `org.ucmeet.UCMeetChat.ios.prod` | Same, but `#else` branch |
| **FCM credentials** | JSON service account file OR legacy server key | Step 6 above |
| **Push gateway URL** | `https://push.ucmeet.org/_matrix/push/v1/notify` | Already configured in `AppSettings.swift:292` |

### Sygnal config example (sygnal.yaml):

```yaml
apps:
  org.ucmeet.UCMeetChat.ios.dev:
    type: gcm           # FCM uses the GCM type in Sygnal
    api_key: "AAAA..."  # Legacy server key (Option B)
    # OR for FCM v1 API (Option A):
    # type: gcm
    # fcm_v1_service_account_file: /path/to/ucmeet-chat-firebase-adminsdk.json
    # fcm_v1_project_id: ucmeet-chat

  org.ucmeet.UCMeetChat.ios.prod:
    type: gcm
    api_key: "AAAA..."  # Same key works for both
```

> **Important:** The `type` must be `gcm` (not `apns`), because our app sends FCM tokens as push keys. Sygnal receives the FCM token and uses Firebase to push, which then wraps to APNs.

### Push gateway URL

Currently configured in `AppSettings.swift:292`:
```swift
private(set) var pushGatewayBaseURL: URL = "https://push.ucmeet.org"
```

If Sygnal runs on a different URL (e.g. `https://sygnal.ucmeet.org`), update this value.

---

## Step 8: End-to-End Push Testing

### Prerequisites for testing:

- [x] Real `GoogleService-Info.plist` installed (Step 4)
- [ ] Sygnal configured with FCM credentials (Step 7)
- [ ] **Real iOS device** (push doesn't work on simulator)
- [ ] Xcode signing resolved (customer's team visible, or customer's Apple ID in Xcode)

### Test procedure:

**Device A** — iPhone with UCMeet.Chat installed
**Device B** — any Matrix client logged into a different account (or use the web client at `https://chat.ucmeet.org`)

#### Test 1: App in foreground
1. Open UCMeet.Chat on Device A, log in
2. From Device B, send a message to Device A's user
3. **Expected:** In-app notification banner appears

#### Test 2: App in background
1. Press Home on Device A (app goes to background)
2. From Device B, send a message
3. **Expected:** iOS push notification appears on lock screen / notification center

#### Test 3: App terminated
1. Force-quit UCMeet.Chat on Device A (swipe up from app switcher)
2. From Device B, send a message
3. **Expected:** iOS push notification appears

#### Test 4: Tap notification opens correct room
1. Tap on any push notification from Tests 2 or 3
2. **Expected:** App opens directly to the room where the message was sent

#### Test 5: Badge count
1. Send multiple messages from Device B while app is backgrounded on Device A
2. **Expected:** Badge count appears on app icon

### Debugging push issues:

| Symptom | Likely cause | Check |
|---------|-------------|-------|
| No FCM token in logs | `GoogleService-Info.plist` still placeholder | Check `API_KEY` is real (starts with `AI`, 39 chars) |
| FCM token generated but no push | Sygnal not configured | Verify Sygnal has the app ID + FCM credentials |
| Push arrives but no sound/badge | NSE not running | Check `org.ucmeet.UCMeetChat.nse` signing is correct |
| Push shows "Received While Offline" | NSE can't decrypt | Check App Group `group.org.ucmeet` is assigned to NSE |
| Wrong room opens on tap | Notification payload issue | Check Sygnal is sending room_id in payload |

### Console log indicators:

```
# Good — Firebase initialized
FCM registration token updated

# Good — Pusher registered with Matrix server
Setting pusher with appId: org.ucmeet.UCMeetChat.ios.dev

# Bad — Placeholder plist
Firebase not configured: GoogleService-Info.plist contains placeholder values.

# Bad — No user session
Cannot register pusher: no user session
```

---

## Step 9: Verify Pusher App ID Matches

After the app registers with the Matrix server, you can verify the pusher registration:

```bash
# Using Matrix API (replace ACCESS_TOKEN with a valid token)
curl -s "https://matrix.ucmeet.org/_matrix/client/v3/pushers" \
  -H "Authorization: Bearer ACCESS_TOKEN" | python3 -m json.tool
```

Expected response should include a pusher with:
```json
{
  "app_id": "org.ucmeet.UCMeetChat.ios.dev",
  "kind": "http",
  "data": {
    "url": "https://push.ucmeet.org/_matrix/push/v1/notify",
    "format": "event_id_only"
  },
  "pushkey": "<FCM registration token>"
}
```

The `app_id` must match exactly what's configured in Sygnal.

---

## Summary: Who Does What

| Task | Who | Status |
|------|-----|--------|
| Create Firebase project | Developer | **DO NOW** |
| Add iOS app with Bundle ID `org.ucmeet.UCMeetChat` | Developer | **DO NOW** |
| Upload APNs key to Firebase | Developer | **DO NOW** |
| Download `GoogleService-Info.plist` | Developer | **DO NOW** |
| Replace placeholder plist in Xcode project | Developer | After download |
| Generate FCM credentials for Sygnal | Developer | After project created |
| Build and verify Firebase initializes | Developer | After plist replaced |
| Configure Sygnal with FCM credentials + app ID | **Customer** | Provide FCM key + app IDs |
| Provide Sygnal URL (if not `push.ucmeet.org`) | **Customer** | Confirm or correct |
| End-to-end push test on real device | Developer | After Sygnal configured |

---

## Quick Reference: Key Values

| Parameter | Value |
|-----------|-------|
| Bundle ID | `org.ucmeet.UCMeetChat` |
| APNs Key ID | `XZANH7CD3Z` |
| Team ID | `26UC01GH` |
| APNs Key File | `AuthKey_XZANH7CD3Z.p8` |
| Pusher App ID (debug) | `org.ucmeet.UCMeetChat.ios.dev` |
| Pusher App ID (release) | `org.ucmeet.UCMeetChat.ios.prod` |
| Push Gateway URL | `https://push.ucmeet.org/_matrix/push/v1/notify` |
| GoogleService-Info.plist location | `ElementX/SupportingFiles/GoogleService-Info.plist` |
| Firebase init code | `ElementX/Sources/Services/Notification/FirebaseNotificationService.swift` |
| Push registration code | `ElementX/Sources/Services/Notification/Manager/NotificationManager.swift` |
| Push provider setting | `ElementX/Sources/Application/Settings/AppSettings.swift:281` |

---

*Last updated: 2026-03-02.*

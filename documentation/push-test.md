# Push Notification E2E Test Guide

Step-by-step instructions for testing push notifications in UCMeet.Chat.

**Last updated:** 2026-03-17

---

## Prerequisites

### Developer side (all done)

| Item | Status | Details |
|------|--------|---------|
| Firebase SDK | Done | v11.8.x via SPM |
| GoogleService-Info.plist | Done | Firebase project `matrix-8c24a` |
| APNs key in Firebase Console | Done | Key ID `XZANH7CD3Z`, Team ID `6HRG779SDK` |
| FCM code | Done | `FirebaseNotificationService`, 14 unit tests |
| Push gateway URL | Done | `https://push.ucmeet.org` in `AppSettings.swift` |
| Pusher app IDs | Done | `org.ucmeet.UCMeetChat.ios.dev` (debug), `.ios.prod` (release) |
| NSE entitlement fix | Done | `com.apple.developer.usernotifications.filtering` removed |
| Debug logging | Done | FCM token + pusher details logged (temporary) |

### Customer side (required)

| Item | Status | Action |
|------|--------|--------|
| ntfy server FCM forwarding | **BLOCKED** | Check ntfy logs — FCM tokens are being rejected |
| Firebase service account JSON | Sent | Sent to customer 2026-03-11 |
| Sygnal/ntfy configuration | Unknown | Must support `app_id` values: `org.ucmeet.UCMeetChat.ios.dev` AND `org.ucmeet.UCMeetChat.ios.prod` |

### Hardware

- iPhone with iOS 18+ (push notifications cannot be tested on simulator)
- Customer's Apple ID signed in Xcode for code signing
- USB cable or wireless debugging enabled

---

## Architecture Overview

```
Matrix Homeserver (matrix.ucmeet.org)
        │
        ▼
Push Gateway (push.ucmeet.org / ntfy)
   POST /_matrix/push/v1/notify
        │
        ▼
Firebase Cloud Messaging (FCM)
   uses service account JSON
        │
        ▼
Apple Push Notification service (APNs)
   uses APNs Auth Key (.p8)
        │
        ▼
UCMeet.Chat app on device
   NSE decrypts → shows notification
```

**Push flow:**
1. Homeserver receives a message for the user
2. Homeserver sends push notification to gateway (`push.ucmeet.org/_matrix/push/v1/notify`)
3. ntfy gateway forwards to FCM using the Firebase service account JSON
4. FCM delivers to APNs using the uploaded APNs key
5. APNs delivers to the device
6. NSE (Notification Service Extension) decrypts and displays the notification

---

## Test Steps

### Step 1: Build and install on device

```bash
# Regenerate project (if YAML was changed)
xcodegen generate

# Build for device (connect via USB, select your device in Xcode)
# Or from command line:
xcodebuild build -scheme ElementX \
  -destination 'platform=iOS,name=<YOUR_DEVICE_NAME>' \
  -skipPackagePluginValidation -skipMacroValidation
```

Alternatively, use Xcode GUI: select your device, press Cmd+R.

### Step 2: Launch app and log in

1. Open UCMeet.Chat on the device
2. Log in with a test account:
   - `apple_support` / `pvINTqBvwBR2`
   - `test_user` / `sPkZt1VCCW48`
3. When prompted for notification permissions, tap **Allow**

### Step 3: Verify FCM registration in logs

Open Xcode Console (or Console.app) and filter for `MXLog`. Look for:

```
FCM registration token updated: <token>
```

This confirms Firebase SDK initialized and received an FCM token.

### Step 4: Verify pusher registration

After login, look for:

```
Set FCM pusher succeeded — appId: org.ucmeet.UCMeetChat.ios.dev, url: https://push.ucmeet.org/_matrix/push/v1/notify, pushkey prefix: <first 20 chars>...
```

This confirms the app registered a pusher with the homeserver. If you see `Set FCM pusher failed`, check the error message.

### Step 5: Send a test message

1. Background the app (swipe up to home screen) or lock the device
2. From a **second account** (on another device or Element Web), send a message to the logged-in user
3. Wait 10-30 seconds for the notification to appear

### Step 6: Verify notification delivery

**Success:** A push notification appears on the lock screen or notification center with the message content.

**Failure scenarios:**

| Symptom | Likely cause | Debug action |
|---------|-------------|--------------|
| No FCM token in logs | Firebase SDK not initializing | Check GoogleService-Info.plist is valid |
| `Set FCM pusher failed` | Homeserver rejected pusher | Check homeserver logs, verify push gateway URL |
| Pusher succeeds but no notification | Gateway not forwarding to FCM | See "Gateway debugging" below |
| Notification appears but content is "Notification" | NSE failed to decrypt | Check NSE logs, ensure app group is correct |

---

## Gateway Debugging

### Test gateway reachability

```bash
curl -s https://push.ucmeet.org/_matrix/push/v1/notify
```

Expected: an error response (not a connection failure). Any HTTP response means the gateway is reachable.

### Simulate a push notification

Send a test push directly to the gateway:

```bash
curl -X POST https://push.ucmeet.org/_matrix/push/v1/notify \
  -H "Content-Type: application/json" \
  -d '{
    "notification": {
      "event_id": "$test_event_id",
      "room_id": "!test_room:matrix.ucmeet.org",
      "type": "m.room.message",
      "sender": "@test:matrix.ucmeet.org",
      "sender_display_name": "Test",
      "room_name": "Test Room",
      "room_alias": "#test:matrix.ucmeet.org",
      "prio": "high",
      "content": {
        "msgtype": "m.text",
        "body": "Push test message"
      },
      "counts": {
        "unread": 1
      },
      "devices": [
        {
          "app_id": "org.ucmeet.UCMeetChat.ios.dev",
          "pushkey": "<FCM_TOKEN_FROM_LOGS>",
          "pushkey_ts": 1710000000,
          "data": {
            "url": "https://push.ucmeet.org/_matrix/push/v1/notify",
            "format": "event_id_only"
          }
        }
      ]
    }
  }'
```

Replace `<FCM_TOKEN_FROM_LOGS>` with the actual FCM token from Step 3.

**Expected response (success):**
```json
{"rejected": []}
```

**Current response (failure):**
```json
{"rejected": ["<FCM_TOKEN>"]}
```

A `rejected` response with the token means the gateway cannot forward to FCM. This is the **current blocker** — ntfy needs its FCM forwarding configured with the Firebase service account JSON.

### Check ntfy server logs (customer action)

The customer must check ntfy server logs for errors when processing FCM tokens. Common issues:

1. **Missing Firebase service account JSON** — ntfy needs the JSON file to authenticate with FCM
2. **Wrong project** — service account must be from Firebase project `matrix-8c24a`
3. **FCM v1 API not enabled** — Firebase Cloud Messaging API (V1) must be enabled in Google Cloud Console
4. **Wrong app_id mapping** — ntfy must be configured to accept `org.ucmeet.UCMeetChat.ios.dev` and `org.ucmeet.UCMeetChat.ios.prod`

---

## Configuration Reference

### App settings (`AppSettings.swift`)

| Setting | Value |
|---------|-------|
| `pushGatewayBaseURL` | `https://push.ucmeet.org` |
| `pushGatewayNotifyEndpoint` | `https://push.ucmeet.org/_matrix/push/v1/notify` |
| `pusherAppID` (debug) | `org.ucmeet.UCMeetChat.ios.dev` |
| `pusherAppID` (release) | `org.ucmeet.UCMeetChat.ios.prod` |
| `pushProvider` | `.firebase` (default) |

### Firebase (`GoogleService-Info.plist`)

| Setting | Value |
|---------|-------|
| Firebase project | `matrix-8c24a` |
| Bundle ID | `org.ucmeet.UCMeetChat` |
| APNs Key ID | `XZANH7CD3Z` |
| Team ID | `6HRG779SDK` |

### ntfy server config (customer-side)

The customer's ntfy server at `push.ucmeet.org` needs:

```yaml
# Example ntfy server configuration for FCM forwarding
# Exact format depends on ntfy version and deployment

# Firebase service account JSON path
firebase-key-file: "/path/to/matrix-8c24a-firebase-adminsdk.json"

# Or via upstream-base-url if using ntfy as Matrix push gateway
upstream-base-url: "https://ntfy.sh"
```

The Firebase service account JSON was sent to the customer on 2026-03-11. It must be from project `matrix-8c24a`.

---

## Known Issues

1. **ntfy rejects FCM tokens** (2026-03-17) — Gateway returns `{"rejected": ["<token>"]}`. Blocked on customer configuring ntfy with Firebase service account JSON.
2. **Debug logging is temporary** — `FirebaseNotificationService.swift` and `NotificationManager.swift` log FCM tokens and pusher details. **Revert before App Store release** (commit `4c2e98746`).
3. **NSE filtering entitlement** — Removed in commit `2bd50eb11`. The `com.apple.developer.usernotifications.filtering` entitlement requires explicit Apple approval. Not needed for basic push delivery.

---

## Verification Checklist

- [ ] App builds and runs on real device
- [ ] Notification permission granted
- [ ] FCM token appears in logs
- [ ] Pusher registration succeeds (check logs for "Set FCM pusher succeeded")
- [ ] Gateway reachable (`curl` returns HTTP response)
- [ ] Gateway accepts FCM token (response: `{"rejected": []}`)
- [ ] Notification delivered when app is backgrounded
- [ ] Notification content is decrypted (shows message, not just "Notification")
- [ ] Tapping notification opens the correct room
- [ ] Inline reply works from notification

---

*This document should be updated after each push testing session.*

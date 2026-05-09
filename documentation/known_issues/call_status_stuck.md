# Known Issue: Call Status "Звонок начат" Stuck in Chat

**First reported:** 2026-04-10
**Reporter:** Customer
**Status:** Diagnosed, fix options identified, not yet implemented
**Severity:** Low (cosmetic + minor UX issue, does not affect functionality)

---

## Customer Report (Original)

> Подскажите еше пожалуйста, а вы используете Element X на каких-либо других серверах или matrix.org сервере? Заметили проблему, что внутри чата после звонка его статус остается неизменным - "Звонок начат". Такое наблюдается даже со старыми вызовами на matrix.ucmeet.org. Это такой баг современного клиента Element или не правильно настроен сервер livekit? Как это можно исправить?
>
> Ну и удалить его из чата тоже не представляется возможным.
>
> Коллега подметил, что на его другом сервере, там, где используется NTFY вместо Sygnal такой проблемы нет.

**Translation / Summary:**
1. After a call ends, the chat status still shows "Call started" / "Звонок начат"
2. This affects even old/historical calls on `matrix.ucmeet.org`
3. The call notification event cannot be deleted from the chat
4. A colleague reports that on another server using NTFY (instead of Sygnal), this problem does not occur

---

## Root Cause Analysis

This is a **known upstream Element X behavior**, not a server misconfiguration. There are TWO separate issues that combine to create the symptom:

### Issue 1: Timeline card never updates

**Location:** `ElementX/Sources/Services/Timeline/TimelineItems/RoomTimelineItemFactory.swift:754-760`

The Matrix Rust SDK provides an `expirationTs` field on every `m.rtc.notification` event (MSC4075):

```swift
case rtcNotification(
    notificationType: RtcNotificationType,
    /** The timestamp at which this notification is considered invalid. */
    expirationTs: Timestamp,
    callIntent: RtcCallIntent?
)
```

However, `RoomTimelineItemFactory.buildCallNotificationTimelineItem` **ignores** `expirationTs`, `notificationType`, and `callIntent` when building the timeline item. It creates a `CallNotificationRoomTimelineItem` with only id/timestamp/sender.

As a result:
- `CallNotificationRoomTimelineView.swift:34` always renders `Text(L10n.commonCallStarted)` ("Звонок начат")
- There is no "Call ended" / "Call expired" / "Missed call" state
- Historical call events look identical to active ones — forever

### Issue 2: Room list "ongoing call" indicator depends on MSC3401 cleanup

**Location:** `ElementX/Sources/Services/Room/RoomSummary/RoomSummaryProvider.swift:335`

The `hasOngoingCall` flag comes from `roomInfo.hasRoomCall`, which is computed by the Matrix Rust SDK as: *"Is there a non-expired membership with application 'm.call' and scope 'm.room' in this room."*

This is based on MSC3401 `org.matrix.msc3401.call.member` state events. When a participant joins a call:
1. The client writes a `call.member` state event with `expires: 14400000` (4 hours)
2. When the participant leaves, the client is supposed to clean up this state
3. If cleanup fails (client crash, network drop, no permission, power-level issue), the state lingers
4. The SDK keeps returning `hasRoomCall = true` until the 4-hour expiry elapses

The iOS app has **no local fallback** — no stale-member sweeper, no timeout watchdog, no manual cleanup. It relies 100% on the SDK + server for stale state handling.

### Why NTFY vs Sygnal doesn't matter

The push gateway has **nothing to do with this issue**. The bug is entirely in:
- The SDK's stale state cleanup (SDK + server cooperation)
- The iOS client's timeline rendering (app-side)

The colleague's NTFY server likely differs in:
- More recent Element Call version
- Different LiveKit configuration that cleans up state correctly
- Different Synapse version or power-level rules
- Different matrix-rust-sdk version

---

## Files Involved

| File | Lines | Purpose |
|------|-------|---------|
| `ElementX/Sources/Services/Timeline/TimelineItems/RoomTimelineItemFactory.swift` | 68-75, 746-760 | Builds timeline item, ignores expirationTs |
| `ElementX/Sources/Screens/Timeline/View/TimelineItemViews/CallNotificationRoomTimelineView.swift` | 34 | Renders "Call started" unconditionally |
| `ElementX/Sources/Services/Timeline/TimelineItems/Items/Other/CallNotificationRoomTimelineItem.swift` | — | Model, no expiry field |
| `ElementX/Sources/Services/Room/RoomSummary/RoomEventStringBuilder.swift` | 87-88 | Room list preview, ignores expirationTs |
| `ElementX/Sources/Services/Room/RoomSummary/RoomSummary.swift` | 59 | `hasOngoingCall` field |
| `ElementX/Sources/Services/Room/RoomSummary/RoomSummaryProvider.swift` | 335 | Maps from SDK's `roomInfo.hasRoomCall` |
| `ElementX/Sources/Services/Room/RoomInfoProxy.swift` | 109-115 | SDK passthrough |
| `ElementX/Sources/Screens/RoomScreen/View/RoomScreen.swift` | 177 | Ongoing call banner |
| `ElementX/Resources/Localizations/en.lproj/Localizable.strings` | 199 | `"common_call_started" = "Call started"` |
| `ElementX/Resources/Localizations/ru.lproj/Localizable.strings` | 199 | `"common_call_started" = "Звонок начат"` |

---

## Fix Options

### Option A: Client-side fix (recommended for fork)

**Scope:** Read `expirationTs` from the SDK and display "Call ended" / "Звонок завершён" when the timestamp is in the past.

**Changes needed:**
1. `CallNotificationRoomTimelineItem.swift` — add `expirationTs: Date?` field
2. `RoomTimelineItemFactory.swift:754` — plumb `expirationTs` through when building the item
3. `CallNotificationRoomTimelineView.swift:34` — conditional rendering: if `Date() > expirationTs`, show "Call ended"
4. `RoomEventStringBuilder.swift:87-88` — same logic for room list preview
5. Add new localization strings: `common_call_ended` = "Call ended" / "Звонок завершён"

**Effort:** ~30-45 min
**Risk:** Low, but increases fork divergence from upstream

### Option B: Wait for upstream fix

Monitor `element-hq/element-x-ios` for a fix. This is a known upstream limitation that may be addressed in a future release.

**Effort:** Zero, but no ETA
**Risk:** Issue persists indefinitely

### Option C: Server-side fix (Element Call / LiveKit update)

For the "ongoing call" banner specifically:
- Update Element Call on `call.ucmeet.org` to latest version
- Verify LiveKit sends proper disconnect events
- Verify clients have permission to clean up their own `call.member` state events
- Wait 4 hours after a stuck call for auto-expiry

**Effort:** Server team, low-medium
**Risk:** May not fully resolve the timeline card issue (client-side rendering)

---

## Recommendation

**Primary:** Implement Option A (client-side fix) as a small, well-contained patch. This solves the timeline card issue which is the most visible symptom.

**Secondary:** Request server team to update Element Call and verify LiveKit cleanup, which should resolve the "ongoing call" banner lingering.

**Note:** The customer cannot delete `m.rtc.notification` events via standard UI — Element X does not provide a UI action to redact timeline events. This is a separate limitation not addressed by either fix.

---

## Conversation Log

### 2026-04-10 — Initial customer report
Customer reported issue, asked if we use Element X on other servers, whether it's a client bug or LiveKit config issue.

### 2026-04-10 — Developer response (draft, sent to customer)

Response sent to customer explaining:
1. This is a known upstream Element X behavior, not related to push gateway type
2. We don't use Element X on other servers, only `matrix.ucmeet.org`
3. Two separate causes:
   - Timeline card: iOS client ignores `expirationTs` field
   - "Ongoing call" indicator: depends on MSC3401 `call.member` state event cleanup
4. NTFY vs Sygnal is irrelevant — difference is likely in Element Call version or LiveKit config on colleague's server
5. Fix options:
   - Client patch for timeline card (possible but increases fork divergence)
   - Server-side: update Element Call, verify LiveKit disconnect handling, check room permissions, or wait 4 hours for auto-expiry
6. Cannot delete `m.rtc.notification` events via standard client UI

### Status

Awaiting customer decision on whether to:
- Implement client-side patch (Option A)
- Investigate server-side (Option C)
- Wait for upstream fix (Option B)

---

## Upstream References

- MSC4075 (`m.rtc.notification`): https://github.com/matrix-org/matrix-spec-proposals/pull/4075
- MSC3401 (group calls): https://github.com/matrix-org/matrix-spec-proposals/pull/3401
- element-hq/element-x-ios: https://github.com/element-hq/element-x-ios
- matrix-rust-sdk: https://github.com/matrix-org/matrix-rust-sdk

Search terms for upstream issues:
- `repo:element-hq/element-x-ios "Call started" stuck`
- `repo:matrix-org/matrix-rust-sdk stale call.member`
- `repo:element-hq/element-call cleanup disconnect`

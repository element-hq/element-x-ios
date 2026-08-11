# Dogfood branches: what has actually landed

Three stacked branch pairs, each existing in both
[element-x-ios](https://github.com/element-hq/element-x-ios) (EXI) and
[matrix-rust-sdk](https://github.com/matrix-org/matrix-rust-sdk) (SDK) under the same name,
always built and installed as a same-name pairing:

```
develop/main
  └── matthew/sss-roomlist-ordering    stable room-list ordering
        └── matthew/startup-time       launch speed
              └── matthew/preview-prefill   instant previews, timelines, push-taps
```

Each section below lists the concrete fixes that branch layer added, newest work last.
Refactors, merges and reverted experiments are omitted.

## matthew/sss-roomlist-ordering — stable room-list ordering

Fixes the room-list "treadmill": rooms sinking to ancient timestamps, previewless rooms
being promoted, and lists spasming on filter changes.

SDK:
- Order the room list atomically by timestamp, slotting rooms without one by bump stamp
  [`029ce3280`](https://github.com/matrix-org/matrix-rust-sdk/commit/029ce3280)
- Stop the latest-event candidate scan at the first gap, so rooms stop adopting the
  timestamp of some ancient decryptable event
  [`04032e107`](https://github.com/matrix-org/matrix-rust-sdk/commit/04032e107)
- Stop inconsistent anchors promoting previewless rooms in the room list
  [`b92ec4b4c`](https://github.com/matrix-org/matrix-rust-sdk/commit/b92ec4b4c)
- Don't synthesise `now()` timestamps for invites (they jumped the list on every restart)
  [`e8cf882bb`](https://github.com/matrix-org/matrix-rust-sdk/commit/e8cf882bb)
  - possibly fixes [#4916 invites for new rooms are sorted after existing rooms](https://github.com/element-hq/element-x-ios/issues/4916)
- Replay the current state when an FFI state listener attaches, so observers attached
  after `Running` don't miss it (prerequisite for EXI's eager sync start)
  [`a804ac7fc`](https://github.com/matrix-org/matrix-rust-sdk/commit/a804ac7fc)
- Room resubscription cancels the in-flight request and refreshes the settings of
  already-subscribed rooms
  [`c99b69226`](https://github.com/matrix-org/matrix-rust-sdk/commit/c99b69226),
  [`66654fbad`](https://github.com/matrix-org/matrix-rust-sdk/commit/66654fbad)

EXI:
- Skip re-applying an identical room list filter (each re-apply forced a full list Reset)
  [`2df7d3209`](https://github.com/element-hq/element-x-ios/commit/2df7d3209)
- Drop tracing spans whose `defer exit()` runs on a different thread than `enter()` -
  a rustPanic → abort at launch under room-list rebuild storms
  [`0c42ffd0e`](https://github.com/element-hq/element-x-ios/commit/0c42ffd0e)

## matthew/startup-time — launch speed

Warm relaunch on a 300-room account measured 2.13s → 1.33s (sim Debug), ~1.1s wall on a
device Release build; first sync response now lands before the rooms render.

SDK:
- Skip the store-cipher KDF for high-entropy passphrases (opt-in fast-open cipher cache)
  [`5b7c3240d`](https://github.com/matrix-org/matrix-rust-sdk/commit/5b7c3240d)
- Cut needless work and requests from session restore: recovery/ignored-users state from
  local account data, cached OIDC metadata
  [`b8e28420e`](https://github.com/matrix-org/matrix-rust-sdk/commit/b8e28420e)
  (write-through on server-acked writes
  [`015809e4f`](https://github.com/matrix-org/matrix-rust-sdk/commit/015809e4f),
  server truth kept for the auto-enable-backups decision
  [`4fdf6af78`](https://github.com/matrix-org/matrix-rust-sdk/commit/4fdf6af78))
- Slim single-call `RoomSummaryDetails` FFI for cheap room-list rendering
  [`4966f5403`](https://github.com/matrix-org/matrix-rust-sdk/commit/4966f5403)
- Persist latest-event values in a second phase, batching room-list updates (kills the
  post-launch preview flicker)
  [`bdcc1b1fd`](https://github.com/matrix-org/matrix-rust-sdk/commit/bdcc1b1fd)
- Compute latest events for rooms created by the response being processed (fixes dropped
  "Room is unknown" computes after a clear-cache)
  [`17b6dc3b7`](https://github.com/matrix-org/matrix-rust-sdk/commit/17b6dc3b7)
EXI:
- Start the session restore eagerly from `AppCoordinator.init`, on a detached task, and
  build + start the sync service on it (first sync request out at ~0.9s instead of ~1.4s)
  [`a9d03e576`](https://github.com/element-hq/element-x-ios/commit/a9d03e576),
  [`6318ba1e1`](https://github.com/element-hq/element-x-ios/commit/6318ba1e1),
  [`eabed5558`](https://github.com/element-hq/element-x-ios/commit/eabed5558)
- Open the session stores with a high-entropy passphrase declaration (adopts the KDF skip)
  [`04f9f87da`](https://github.com/element-hq/element-x-ios/commit/04f9f87da)
- Build room summaries from the slim FFI, with bounded concurrency
  [`e320d27b8`](https://github.com/element-hq/element-x-ios/commit/e320d27b8),
  [`3aa4ba8f7`](https://github.com/element-hq/element-x-ios/commit/3aa4ba8f7)
- Defer the alternate/static room summary providers until the primary has published
  (subscribing all three tripled the O(rooms) work in front of first paint)
  [`31693e404`](https://github.com/element-hq/element-x-ios/commit/31693e404)
- Defer Sentry, analytics and notification startup off the launch critical path, gated on
  first render; fix the empty-list flash
  [`8c33808c9`](https://github.com/element-hq/element-x-ios/commit/8c33808c9),
  [`505a9d6da`](https://github.com/element-hq/element-x-ios/commit/505a9d6da)
- Drop `SecureBackupController`'s unconditional init-time remote backup check
  [`270633527`](https://github.com/element-hq/element-x-ios/commit/270633527)
- Consume the room summary provider's current state synchronously at init
  [`3a85fab72`](https://github.com/element-hq/element-x-ios/commit/3a85fab72)

## matthew/preview-prefill — instant previews, timelines and push-taps

Attacks blank previews after scroll/clear-cache, rooms opening without local history, and
(latest round) the NSE/main-app seams: push-taps landing on an unsynced room, lost sync
events, and rooms stuck unread.

**Headline: cold launch to a correct room list is now ~200ms on a 6k-room account**
(measured 198-205ms across launches, zero stale exposure; was ~2.1s when this arc
started). The launch-speed work across this branch and matthew/startup-time is the
answer to [#4102 Launch time is ~20x slower than it should
be](https://github.com/element-hq/element-x-ios/issues/4102). A representative launch
(2026-08-10 19:27:35 / 19:31:53 measurement round, iPhone 12 Pro Max, dev-signed build):

| phase | window | cost |
|---|---|---|
| pre-main + UIKit bringup to first app log | 0 → ~80ms | ~80ms |
| AppCoordinator init, splash root, bg-refresh registration | +80 → +105 | ~25ms |
| four SQLite stores open, in parallel (state 24ms the longest) | +105 → +135 | ~30ms |
| session restore incl. inline 64-room recency load | +135 → +165 | ~30ms |
| providers subscribe, room list `loaded`, sync starts | +165 → +170 | ~5ms |
| first 64-room summary batch (30ms) + render | +170 → +205 | ~35ms |

Pre-main was 264-580ms before MapLibre moved behind dlopen (its 60ms Metal static
initialiser plus dev-signing validation dominated); no single fat target remains -
everything is 25-35ms slices. Note LaunchMetrics lines print at settle time (~1s
after paint), not paint time.

SDK - previews and the back-pagination queue:
- Accept undecrypted events as latest-event candidates: UTDs render as "Waiting for
  decryption key", keep an accurate bump timestamp (no sink treadmill), and are replaced
  in place once the key arrives
  [`e1374ff8f`](https://github.com/matrix-org/matrix-rust-sdk/commit/e1374ff8f),
  [`1457a8eca`](https://github.com/matrix-org/matrix-rust-sdk/commit/1457a8eca)
- `BackPaginationQueue`: priority heap, per-room single-flight, per-priority concurrency
  caps, coalescing - replaces the credit system (built on Stefan's queue series)
  [`3fe3a3dcc`](https://github.com/matrix-org/matrix-rust-sdk/commit/3fe3a3dcc)…[`6bed07f5b`](https://github.com/matrix-org/matrix-rust-sdk/commit/6bed07f5b),
  caps [`6a3546d95`](https://github.com/matrix-org/matrix-rust-sdk/commit/6a3546d95),
  concurrency [`993bb82d7`](https://github.com/matrix-org/matrix-rust-sdk/commit/993bb82d7)
  - part of [sdk#6014 [meta] Automatic backpagination](https://github.com/matrix-org/matrix-rust-sdk/issues/6014)
- Valueless rooms backfill their preview automatically via a detached request; viewport
  rooms preload with top priority, two-tier (preview first, then a screenful)
  [`25c7c3a83`](https://github.com/matrix-org/matrix-rust-sdk/commit/25c7c3a83),
  [`c55c20607`](https://github.com/matrix-org/matrix-rust-sdk/commit/c55c20607),
  [`3685da91e`](https://github.com/matrix-org/matrix-rust-sdk/commit/3685da91e)
  - fixes [#4898 Last messages are populated only for the displayed rooms in the room list](https://github.com/element-hq/element-x-ios/issues/4898)
  - fixes [#5189 No last message logic when logging in with a small account](https://github.com/element-hq/element-x-ios/issues/5189)
- Stop the automatic backfill walking a room's entire history (the `/messages` trickle
  loop; origin-aware re-arm with a strict budget)
  [`53c1bed53`](https://github.com/matrix-org/matrix-rust-sdk/commit/53c1bed53)
  - likely fixes [#3183 Opening a room when offline causes scrollback spinner to tightloop](https://github.com/element-hq/element-x-ios/issues/3183)
- Drain the latest-event backlog in reverse chronological order
  [`32220d70e`](https://github.com/matrix-org/matrix-rust-sdk/commit/32220d70e)
- Stop the room list spasming during catch-up syncs: a burst of freshly computed
  latest events is persisted in one store transaction and broadcast back-to-back
  (one atomic reorder per drain instead of one per room), and one drain fits a
  whole response's rooms
  [`a637111d1`](https://github.com/matrix-org/matrix-rust-sdk/commit/a637111d1),
  [`f08c09150`](https://github.com/matrix-org/matrix-rust-sdk/commit/f08c09150)
  - fixes [#4814 The roomlist order jumps around (spasms) fairly wildly when syncing](https://github.com/element-hq/element-x-ios/issues/4814)
  - fixes [rageshake#4993 yet another 20s sync… then the roomlist spasmed like crazy as it caught up](https://github.com/element-hq/element-x-ios-rageshakes/issues/4993)
- Never fetch `/room_keys/version` while classifying UTDs - cold-launch first paint
  blocked up to 49s offline on this network call
  [`12e2d0d8b`](https://github.com/matrix-org/matrix-rust-sdk/commit/12e2d0d8b)

SDK - sync correctness:
- Never persist the sliding-sync `pos` ahead of the event cache: a kill between the two
  silently lost events forever (rooms stuck unread). Pos persistence is now ack-gated on
  the event cache having durably processed the response
  [`a2ce71d71`](https://github.com/matrix-org/matrix-rust-sdk/commit/a2ce71d71)
  - fixes [#4729 3 inbound messages (and 1 edit) went entirely missing from my timeline](https://github.com/element-hq/element-x-ios/issues/4729)
  - addresses [sdk#6401 Find a better place for the pos persistance](https://github.com/matrix-org/matrix-rust-sdk/issues/6401)
  - likely behind stuck-unread reports like [rageshake#6243 Stuck unread in the room list](https://github.com/element-hq/element-x-ios-rageshakes/issues/6243)
    and [rageshake#6272 Stuck unread, had to manually mark it as read](https://github.com/element-hq/element-x-ios-rageshakes/issues/6272)
- Make the read-receipt hunt a shallow seek, not a deep spider (3MB `/messages` batches
  of server-ACL churn were starving the queue), then merge all same-room walks into
  needs-based shared runs
  [`8b9058252`](https://github.com/matrix-org/matrix-rust-sdk/commit/8b9058252),
  [`00c64393e`](https://github.com/matrix-org/matrix-rust-sdk/commit/00c64393e)
- Take latest-events work out of the `state_store_lock` region; surface stuck response
  handling instead of stalling silently
  [`f8c5742fa`](https://github.com/matrix-org/matrix-rust-sdk/commit/f8c5742fa),
  [`d80633f6f`](https://github.com/matrix-org/matrix-rust-sdk/commit/d80633f6f)
- Room-list catch-up: publish state at round start, show the sync indicator whenever
  content is stale, don't cancel catch-up rounds for room subscriptions, defer bulky
  extensions past the first round
  [`455cf9dc8`](https://github.com/matrix-org/matrix-rust-sdk/commit/455cf9dc8),
  [`d44e4482f`](https://github.com/matrix-org/matrix-rust-sdk/commit/d44e4482f),
  [`f40199ed4`](https://github.com/matrix-org/matrix-rust-sdk/commit/f40199ed4),
  [`f17362d62`](https://github.com/matrix-org/matrix-rust-sdk/commit/f17362d62)

SDK - NSE and push-taps:
- Ingest notification-fetched events into the shared event cache: the NSE's short sync
  replays into the parent's persistent cache through the normal gap-safe path, so the
  main app finds the room's timeline and preview already populated
  [`48e010cbc`](https://github.com/matrix-org/matrix-rust-sdk/commit/48e010cbc)
- Serve focused timelines from the persisted event cache instead of always hitting
  `/context`
  [`8b73bb326`](https://github.com/matrix-org/matrix-rust-sdk/commit/8b73bb326)
- Upgrade the persisted UTD in place once the NSE's encryption sync fetches the key, so
  the main app doesn't come up rendering a UTD it has the key for
  [`6cf6b06e5`](https://github.com/matrix-org/matrix-rust-sdk/commit/6cf6b06e5)
- Don't back-paginate rooms we're not joined to (a declined invite's leave update
  re-armed the backfill, which 403'd against `/messages`)
  [`2860034b0`](https://github.com/matrix-org/matrix-rust-sdk/commit/2860034b0)
- Stop the NSE burning its ~30s budget on fixed network costs, which turned
  poor-connectivity pushes into blank notifications: reuse the cached `/versions`
  instead of refetching per launch, skip the all-tracked-users device-list refresh
  (decrypt-only process; it cost a 0.5-1.3MB `/keys/query` per push), and fall back
  to `/context` after a single failed `/sync` attempt instead of three
  [`c187fef45`](https://github.com/matrix-org/matrix-rust-sdk/commit/c187fef45)

SDK - launch speed and diagnosability:
- Take the WAL checkpoint off the store-open critical path: the open-time TRUNCATE
  (upstream #6004) stalls launch in proportion to the WAL grown while only the NSE was
  writing (~1s after a 30-min pause); replaced by a deferred PASSIVE checkpoint on a pool
  connection, close/pause keeps its TRUNCATE
  [`c4b51714a`](https://github.com/matrix-org/matrix-rust-sdk/commit/c4b51714a)
- Give every first-party SDK crate a root log target: the FFI filter has no global
  directive, so crates missing from its target table (`matrix_sdk_base`,
  `matrix_sdk_common`, `matrix_sdk_sqlite`, `matrix_sdk_store_encryption`,
  `matrix_sdk_ui`) were dropped at every app log level; now the app's chosen level
  propagates through the whole SDK
  [`3524b89a1`](https://github.com/matrix-org/matrix-rust-sdk/commit/3524b89a1)
- Load rooms progressively in pages of 200 instead of deserializing every RoomInfo
  before session restore returns (~500ms of the launch critical path on a 6k-room
  account; measured launch→roomlist 302ms after); sync processing waits on a
  rooms-loaded barrier so a not-yet-loaded room can't be recreated blank
  [`a6bdc2720`](https://github.com/matrix-org/matrix-rust-sdk/commit/a6bdc2720)
- Log which event counts a room as unread, so rooms stuck unread despite an up-to-date
  receipt name their culprit
  [`24333794e`](https://github.com/matrix-org/matrix-rust-sdk/commit/24333794e)
- Wait for the progressive room load before snapshotting the room list: pages load in
  state-store row order (roughly least-recently-updated first), so a mid-load snapshot
  rendered a stale subset of the account as the cold-launch room list until sync healed it
  [`110050e5a`](https://github.com/matrix-org/matrix-rust-sdk/commit/110050e5a)
- Load the most recent rooms first and fill the rest concurrently: the barrier above
  fixed correctness but put the full ~750ms load back on the paint path; a plaintext
  `recency` column on `room_info` makes the inline first page the most recently active
  rooms (correct first render, no waiting), and the remaining pages load on a small
  worker pool since sync processing still waits for completeness
  [`8d22c6b4d`](https://github.com/matrix-org/matrix-rust-sdk/commit/8d22c6b4d)
- Read only the profile row for latest-event preview senders: each room-list entry
  loaded the sender's full RoomMember (seven store queries: power levels, ambiguity,
  presence, ignored users) to render a name and avatar - 3-13ms per room under launch
  contention, 89-426ms for the first page of summaries
  [`b9e04f7d4`](https://github.com/matrix-org/matrix-rust-sdk/commit/b9e04f7d4)
- Shrink the inline room load to 64 rooms (was 200): the recency-ordered read fetches
  rows in index order (random table lookups, ~0.45ms/room on the restore critical path);
  64 matches the home list's first page so the inline read covers exactly what first
  paint can show
  [`79b5182d3`](https://github.com/matrix-org/matrix-rust-sdk/commit/79b5182d3),
  [`4df4dbca2`](https://github.com/matrix-org/matrix-rust-sdk/commit/4df4dbca2),
  [`2cd2f16b4`](https://github.com/matrix-org/matrix-rust-sdk/commit/2cd2f16b4)

EXI:
- Preload visible rooms via the back-pagination queue instead of SSS subscriptions;
  1 visible event requested, SDK tops up the timeline
  [`38ef09140`](https://github.com/element-hq/element-x-ios/commit/38ef09140),
  [`c10a36027`](https://github.com/element-hq/element-x-ios/commit/c10a36027)
- Route visible rooms through a dedicated viewport sliding-sync connection; staged
  room-list growth relies on proactive sync
  [`eadcb4239`](https://github.com/element-hq/element-x-ios/commit/eadcb4239),
  [`5cd7d67b5`](https://github.com/element-hq/element-x-ios/commit/5cd7d67b5)
- Never block launch on the network (fire-and-forget `auth_metadata` caching); add
  per-launch `LaunchMetrics` (greppable log line + Sentry transaction)
  [`e86a457b5`](https://github.com/element-hq/element-x-ios/commit/e86a457b5)
- Never show a join screen for a room the user is already in (push-taps for unsynced
  rooms now wait for the room; the join screen honours server-reported membership)
  [`ac2169469`](https://github.com/element-hq/element-x-ios/commit/ac2169469)
  - fixes [#4287 Opening a push for a room whose invite you accepted elsewhere fails](https://github.com/element-hq/element-x-ios/issues/4287)
  - likely fixes [rageshake#7352 Opening rooms just opens an invite screen and not the room](https://github.com/element-hq/element-x-ios-rageshakes/issues/7352)
    and [rageshake#2479 Tapped notification and got the Join Room screen](https://github.com/element-hq/element-x-ios-rageshakes/issues/2479)
- Hold the splash until the cached room list has published - zero skeleton frames on
  launch
  [`5ae04e03f`](https://github.com/element-hq/element-x-ios/commit/5ae04e03f)
- Focus notification taps on their event (served locally when the NSE prefilled it);
  give background refresh a bounded wait for session restore instead of a silent no-op
  [`580ba004d`](https://github.com/element-hq/element-x-ios/commit/580ba004d)
  - fixes [#4790 Tapping on a push should permalink to that message](https://github.com/element-hq/element-x-ios/issues/4790)
- Make declining an invite non-blocking: the decline also forgets the room server-side
  (measured ~5s on matrix.org) and the modal indicator froze the whole room list for
  that long
  [`556982912`](https://github.com/element-hq/element-x-ios/commit/556982912)
  - fixes the blocking half of [#2535 No local echo on rejecting invites](https://github.com/element-hq/element-x-ios/issues/2535)
  - related: [rageshake#6668 unable to decline… I just get a Loading window pop up and the app is unresponsive](https://github.com/element-hq/element-x-ios-rageshakes/issues/6668)
- Route taps on notifications the NSE couldn't process: the raw pusher payload still
  carries room/event IDs, but the tap handler required an NSE-only field and silently
  dropped the tap ("blank pushes" on a poor connection went nowhere)
  [`eb0555a53`](https://github.com/element-hq/element-x-ios/commit/eb0555a53)
  - likely fixes [rageshake#5207 New notification came in, I tapped it. Message didn't load](https://github.com/element-hq/element-x-ios-rageshakes/issues/5207)
- Open the room live at the bottom when a notification tap targets the newest message,
  instead of a permalink-style detached timeline (green highlight, dead jump-to-latest)
  [`a39307fc0`](https://github.com/element-hq/element-x-ios/commit/a39307fc0), waiting for the
  live timeline's items to be published so the check can actually match
  [`f26581fe4`](https://github.com/element-hq/element-x-ios/commit/f26581fe4), and retracting
  the focus "Loading…" toast when the skip goes straight to live (nothing else could ever
  hide it, so it spun at the top of the room forever)
  [`e550a82df`](https://github.com/element-hq/element-x-ios/commit/e550a82df).
  The item-based check still mis-decided (the provider builds items progressively, so
  the last item can trail the room's newest event right after opening) - it now compares
  against the latest-events value instead, via a new `latestEventId` FFI
  ([SDK `92950c9f3`](https://github.com/matrix-org/matrix-rust-sdk/commit/92950c9f3))
  [`5e43d0872`](https://github.com/element-hq/element-x-ios/commit/5e43d0872)
  - the unhideable focus toast matches stuck-"Loading…" reports like
    [rageshake#3004 upgraded to 851 and promptly got stuck on a loading… spinner](https://github.com/element-hq/element-x-ios-rageshakes/issues/3004)
- Re-run the timeline's viewport fill check after each snapshot applies: it only ran on
  scroll and pagination-state changes, which fire against the previous timeline's
  geometry when switching timelines. A live timeline whose loaded window had been
  unloaded by a limited sync (dogfooding hit this as "room shows only the remote echo
  of my own message after sending from a notification tap") stayed a single bubble
  until the user scrolled
  [`c1cae2c9c`](https://github.com/element-hq/element-x-ios/commit/c1cae2c9c)
  - likely fixes [#5817 Timeline can get stuck showing only the most recent message if there's a reset which races with a local echo](https://github.com/element-hq/element-x-ios/issues/5817)
    (mirrored as [sdk#6709](https://github.com/matrix-org/matrix-rust-sdk/issues/6709))
  - possibly fixes [rageshake#5597 new messages the notification was about simply disappear from the conversation view](https://github.com/element-hq/element-x-ios-rageshakes/issues/5597)
- Focus scrolls (permalinks, pinned-message taps) now put the top of the target message
  halfway up the viewport, accurately: `scrollToRow(.top)` pinned a long message's
  bottom to the viewport edge (top off-screen), and estimated row heights made the
  landing drift anywhere from mid-message to past it. The offset is computed
  explicitly and re-measured as layout settles (within one paint for jumps); nearby
  targets animate normally, distant ones crossfade a settled jump since animating
  across estimated heights can't aim
  [`6b300c22c`](https://github.com/element-hq/element-x-ios/commit/6b300c22c)
  - fixes [#2806 tapping on replies doesn't always take you to the top of the replied to message](https://github.com/element-hq/element-x-ios/issues/2806)
  - possibly fixes [#4377 Scrolling got stuck after jumping to a permalink, and refused to scroll to the actual bottom of the timeline](https://github.com/element-hq/element-x-ios/issues/4377)
- Notification taps jump straight to the room: taps on the newest message open live at
  the bottom with no focus treatment, decided at the route level from the fetched
  event's ID *and timestamp* (the in-memory latest event lags the NSE right after a
  tap wakes the app, so ID comparison alone mis-decides)
  [`363b3b7f5`](https://github.com/element-hq/element-x-ios/commit/363b3b7f5),
  new `latestEventTimestamp` FFI
  ([SDK `9a7707b37`](https://github.com/matrix-org/matrix-rust-sdk/commit/9a7707b37))
  - likely fixes [rageshake#2349 Tapped on a notification… the latest message was wrong… after a few seconds it turned into the correct, new message](https://github.com/element-hq/element-x-ios-rageshakes/issues/2349)
- Dirty-lock recovery scoped to the rooms other processes actually touched: after the
  NSE handled a push, the first store access reloaded the entire in-memory event cache
  state (5451 rooms, ~11s, synchronously inside the tap's room open). Writers journal
  the rooms they modify per lock-generation tenure; recovery reloads only those (the
  NSE touches 1-2). Fail-safe by construction: tenure markers stamped at every lease
  acquisition let recovery verify the journal covers every generation in its window -
  a gap (e.g. a build without the journal) falls back to the full reload, so
  mixed-version cost is the old slow path, never staleness. Store-wide clears and
  pruning leave wildcard/horizon markers with the same fallback
  ([SDK `b10561742`](https://github.com/matrix-org/matrix-rust-sdk/commit/b10561742),
  [`41e4704ed`](https://github.com/matrix-org/matrix-rust-sdk/commit/41e4704ed))
  - advances [sdk#4874 [meta] Dirty cross-process locks](https://github.com/matrix-org/matrix-rust-sdk/issues/4874)
    and [sdk#6681 [meta] Adopt a new cross-process state invalidation strategy](https://github.com/matrix-org/matrix-rust-sdk/issues/6681)
  - likely fixes [rageshake#5029 Opening a room takes several seconds](https://github.com/element-hq/element-x-ios-rageshakes/issues/5029)
- Long-press on a redacted message showed a blank fullscreen sheet (the filtered action
  set came back empty with view source off, and the sheet presents regardless; state
  events hit the same). Redacted items keep copy-permalink (plus view source in dev
  mode), and the menu no longer presents at all when a provider has nothing to offer
  [`d8b529726`](https://github.com/element-hq/element-x-ios/commit/d8b529726)
- Redactions now apply as local echoes: `Timeline::redact` sent remote-target
  redactions as a direct HTTP request, so "Remove" left the message visible until the
  redaction came back down /sync (forever, while offline). Routed through the send
  queue, whose redaction local echo the timeline already applies to the target item
  immediately - plus the usual queue durability (retries, offline, ordering behind
  pending sends)
  ([SDK `4366a2e7b`](https://github.com/matrix-org/matrix-rust-sdk/commit/4366a2e7b))
  - fixes [#1713 Redactions don't local echo](https://github.com/element-hq/element-x-ios/issues/1713)
- THE SYNC WEDGE, root-caused and fixed: the latest-events "re-trigger missing
  computations" step held the rooms-map read lock while awaiting every response room's
  own lock; with the compute task holding a room's write lock and a room registration
  queued on `rooms.write()`, tokio's write-preferring `RwLock` closed a three-party
  cycle. The sync handler sat inside it holding the sliding-sync `position` lock, so
  the sync loop, the ack-gated pos persist and any room open all wedged behind it
  (dogfooding: room list stuck behind a permanent "Loading…" overlay). Both offending
  sites now snapshot cheap clone handles and release the map lock before awaiting
  per-room locks
  ([SDK `830f3dc0e`](https://github.com/matrix-org/matrix-rust-sdk/commit/830f3dc0e))
  - likely the cause of
    [rageshake#6487 app got stuck on Loading… when opening a room and had to be force quit](https://github.com/element-hq/element-x-ios-rageshakes/issues/6487),
    [rageshake#6322 app hung while opening room on "loading…" spinner. had to force quit](https://github.com/element-hq/element-x-ios-rageshakes/issues/6322),
    [rageshake#7173 infinite Loading spinner while trying to open room. had to force quit](https://github.com/element-hq/element-x-ios-rageshakes/issues/7173) and
    [rageshake#5716 app stuck solid on loading spinner trying to open room](https://github.com/element-hq/element-x-ios-rageshakes/issues/5716)
- Open the thread when a room's preview shows a threaded reply: the preview surfaces
  the room's latest event even when it is threaded, which the main timeline hides -
  tapping the room then appears to be missing the previewed message (dogfooded as
  "preview shows 13:41 but the room ends at 13:32")
  [`b2140c102`](https://github.com/element-hq/element-x-ios/commit/b2140c102),
  new `latestEventThreadRootId` FFI
  ([SDK `0ba9d0d9d`](https://github.com/matrix-org/matrix-rust-sdk/commit/0ba9d0d9d))
- Reply previews of undecrypted events showed "Unsupported event" and never refreshed:
  they now say "Waiting for decryption key"
  [`bde3cbd69`](https://github.com/element-hq/element-x-ios/commit/bde3cbd69) and update
  in place when the key arrives - the SDK hooks the redecryptor's resolved-UTDs report
  to refresh replies whose target is outside the loaded timeline
  ([SDK `17af054e3`](https://github.com/matrix-org/matrix-rust-sdk/commit/17af054e3)).
  Events fetched over `/event` are now saved into the event cache too: reply targets
  used to be refetched over the network on every item rebuild (a ~10s skeleton while
  matrix.org served a cold 2023 event) and, being invisible to the redecryptor, never
  resolved in place when their key arrived from backup
  ([SDK `4b23e1d77`](https://github.com/matrix-org/matrix-rust-sdk/commit/4b23e1d77);
  REVERTED in [`ff0d38bd2`](https://github.com/matrix-org/matrix-rust-sdk/commit/ff0d38bd2) while
  bisecting duplicate echoes of freshly sent messages - the save ran in the affected
  room minutes before the duplicates started; mechanism not yet root-caused)
  - fixes [#3113 Late decryptions don't update RepliedToEvent](https://github.com/element-hq/element-x-ios/issues/3113)
  - fixes the "unsupported event in summary" half of
    [#4819 Message in thread shows as UTD in main timeline + unsupported event in summary until you load the thread](https://github.com/element-hq/element-x-ios/issues/4819)
    (reported in the wild as [rageshake#6859 "unsupported event" in thread preview](https://github.com/element-hq/element-x-ios-rageshakes/issues/6859))
  - related: [#6002 Update UI when replied to message cannot be loaded](https://github.com/element-hq/element-x-ios/issues/6002)
- Fix the first list item rendering more indented than the rest (inter-element
  whitespace in markdown-generated HTML normalised into stray spaces)
  [`550a6467d`](https://github.com/element-hq/element-x-ios/commit/550a6467d)
  - fixes [#5179 First bullet point in an unordered list is always incorrectly indented](https://github.com/element-hq/element-x-ios/issues/5179)
- Show the app and SDK git SHAs in the Settings version footer (build phase stamps
  `AppGitSHA` into Info.plist, `-dirty` when the tree is modified) so you can tell
  exactly which dogfood pairing a phone is running
  [`48cba7c70`](https://github.com/element-hq/element-x-ios/commit/48cba7c70)
- Re-snap to the real top after a system scroll-to-top: with 6k rooms the status-bar
  tap lands slightly off the estimated top, leaving the navigation bar (large title,
  search drawer, filter chips) stuck mid-transition
  [`877f5db4c`](https://github.com/element-hq/element-x-ios/commit/877f5db4c)
- Shrink the home list's first page from 100 to 32 rooms: every first-page room costs
  a summary build (FFI fetch + string building) in front of the first paint, while the
  screen renders ~10 rows and scrolling grows the list anyway; also log summary builds
  over 25ms so launches attribute this stage. Later settled on 64 once summary builds
  slimmed down and the bottom-bounce prefetch landed
  [`edb009314`](https://github.com/element-hq/element-x-ios/commit/edb009314),
  [`babf62b7d`](https://github.com/element-hq/element-x-ios/commit/babf62b7d)
- Prefetch the next room list page half a page before the user reaches the bottom:
  the grow trigger fired only once the last row was visible, and the visible-range
  publisher is throttled at 0.5s, so fast scrolls bounced off the end of the list
  while the next page loaded. The home screen also dropped range updates entirely
  while a scroll was in flight (0.5s defer + ignore-while-scrolling guard), so
  scroll events now publish the range live and the provider grows the list
  unthrottled, suppressing re-requests until the previous growth lands
  [`ab7b063c7`](https://github.com/element-hq/element-x-ios/commit/ab7b063c7),
  [`5859d1c52`](https://github.com/element-hq/element-x-ios/commit/5859d1c52),
  [`5e55f53e9`](https://github.com/element-hq/element-x-ios/commit/5e55f53e9)
- Don't blank the room list into the "no chats" empty state when a sliding-sync
  session expiry (HTTP 400 → pos reset) momentarily reports the list count as nil:
  only trust a zero count when no rooms are actually published
  [`c2d9cf778`](https://github.com/element-hq/element-x-ios/commit/c2d9cf778)
- Load MapLibre lazily via dlopen: its static initialisers (mostly a Metal compression
  context) cost ~60ms of dyld work on every cold launch, for a map that only renders
  once a location screen opens. The interactive map moved into a MapLibreShim framework
  (embedded, unlinked, dlopen'd on first map use); the app links only a tiny
  MapInterface framework of shared types. Timeline location messages already used the
  static tile view, which never touched MapLibre
  [`e80dd55a5`](https://github.com/element-hq/element-x-ios/commit/e80dd55a5)

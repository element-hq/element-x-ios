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
started). A representative launch (2026-08-10 19:27:35 / 19:31:53 measurement round,
iPhone 12 Pro Max, dev-signed build):

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
- Valueless rooms backfill their preview automatically via a detached request; viewport
  rooms preload with top priority, two-tier (preview first, then a screenful)
  [`25c7c3a83`](https://github.com/matrix-org/matrix-rust-sdk/commit/25c7c3a83),
  [`c55c20607`](https://github.com/matrix-org/matrix-rust-sdk/commit/c55c20607),
  [`3685da91e`](https://github.com/matrix-org/matrix-rust-sdk/commit/3685da91e)
- Stop the automatic backfill walking a room's entire history (the `/messages` trickle
  loop; origin-aware re-arm with a strict budget)
  [`53c1bed53`](https://github.com/matrix-org/matrix-rust-sdk/commit/53c1bed53)
- Drain the latest-event backlog in reverse chronological order
  [`32220d70e`](https://github.com/matrix-org/matrix-rust-sdk/commit/32220d70e)
- Stop the room list spasming during catch-up syncs: a burst of freshly computed
  latest events is persisted in one store transaction and broadcast back-to-back
  (one atomic reorder per drain instead of one per room), and one drain fits a
  whole response's rooms
  [`a637111d1`](https://github.com/matrix-org/matrix-rust-sdk/commit/a637111d1),
  [`f08c09150`](https://github.com/matrix-org/matrix-rust-sdk/commit/f08c09150)
- Never fetch `/room_keys/version` while classifying UTDs - cold-launch first paint
  blocked up to 49s offline on this network call
  [`12e2d0d8b`](https://github.com/matrix-org/matrix-rust-sdk/commit/12e2d0d8b)

SDK - sync correctness:
- Never persist the sliding-sync `pos` ahead of the event cache: a kill between the two
  silently lost events forever (rooms stuck unread). Pos persistence is now ack-gated on
  the event cache having durably processed the response
  [`a2ce71d71`](https://github.com/matrix-org/matrix-rust-sdk/commit/a2ce71d71)
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
- Hold the splash until the cached room list has published - zero skeleton frames on
  launch
  [`5ae04e03f`](https://github.com/element-hq/element-x-ios/commit/5ae04e03f)
- Focus notification taps on their event (served locally when the NSE prefilled it);
  give background refresh a bounded wait for session restore instead of a silent no-op
  [`580ba004d`](https://github.com/element-hq/element-x-ios/commit/580ba004d)
- Make declining an invite non-blocking: the decline also forgets the room server-side
  (measured ~5s on matrix.org) and the modal indicator froze the whole room list for
  that long
  [`556982912`](https://github.com/element-hq/element-x-ios/commit/556982912)
- Route taps on notifications the NSE couldn't process: the raw pusher payload still
  carries room/event IDs, but the tap handler required an NSE-only field and silently
  dropped the tap ("blank pushes" on a poor connection went nowhere)
  [`eb0555a53`](https://github.com/element-hq/element-x-ios/commit/eb0555a53)
- Open the room live at the bottom when a notification tap targets the newest message,
  instead of a permalink-style detached timeline (green highlight, dead jump-to-latest)
  [`a39307fc0`](https://github.com/element-hq/element-x-ios/commit/a39307fc0), waiting for the
  live timeline's items to be published so the check can actually match
  [`f26581fe4`](https://github.com/element-hq/element-x-ios/commit/f26581fe4), and retracting
  the focus "Loading…" toast when the skip goes straight to live (nothing else could ever
  hide it, so it spun at the top of the room forever)
  [`e550a82df`](https://github.com/element-hq/element-x-ios/commit/e550a82df)
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

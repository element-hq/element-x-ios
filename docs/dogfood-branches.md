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

Each section below lists the concrete fixes that branch layer added, in chronological
order of when the commits landed (oldest first, newest work last) - keep new entries
in that order. Refactors, merges and reverted experiments are omitted.

## matthew/sss-roomlist-ordering — stable room-list ordering

Fixes the room-list "treadmill": rooms sinking to ancient timestamps, previewless rooms
being promoted, and lists spasming on filter changes.

SDK:
- Room resubscription cancels the in-flight request and refreshes the settings of
  already-subscribed rooms
  [`c99b69226`](https://github.com/matrix-org/matrix-rust-sdk/commit/c99b69226),
  [`66654fbad`](https://github.com/matrix-org/matrix-rust-sdk/commit/66654fbad)
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
- Cut needless work and requests from session restore: recovery/ignored-users state from
  local account data, cached OIDC metadata
  [`b8e28420e`](https://github.com/matrix-org/matrix-rust-sdk/commit/b8e28420e)
  (write-through on server-acked writes
  [`015809e4f`](https://github.com/matrix-org/matrix-rust-sdk/commit/015809e4f),
  server truth kept for the auto-enable-backups decision
  [`4fdf6af78`](https://github.com/matrix-org/matrix-rust-sdk/commit/4fdf6af78))
- Skip the store-cipher KDF for high-entropy passphrases (opt-in fast-open cipher cache)
  [`5b7c3240d`](https://github.com/matrix-org/matrix-rust-sdk/commit/5b7c3240d)
- Slim single-call `RoomSummaryDetails` FFI for cheap room-list rendering
  [`4966f5403`](https://github.com/matrix-org/matrix-rust-sdk/commit/4966f5403)
- Persist latest-event values in a second phase, batching room-list updates (kills the
  post-launch preview flicker)
  [`bdcc1b1fd`](https://github.com/matrix-org/matrix-rust-sdk/commit/bdcc1b1fd)
- Compute latest events for rooms created by the response being processed (fixes dropped
  "Room is unknown" computes after a clear-cache)
  [`17b6dc3b7`](https://github.com/matrix-org/matrix-rust-sdk/commit/17b6dc3b7)
EXI:
- Build room summaries from the slim FFI, with bounded concurrency
  [`e320d27b8`](https://github.com/element-hq/element-x-ios/commit/e320d27b8),
  [`3aa4ba8f7`](https://github.com/element-hq/element-x-ios/commit/3aa4ba8f7)
- Defer the alternate/static room summary providers until the primary has published
  (subscribing all three tripled the O(rooms) work in front of first paint)
  [`31693e404`](https://github.com/element-hq/element-x-ios/commit/31693e404)
- Drop `SecureBackupController`'s unconditional init-time remote backup check
  [`270633527`](https://github.com/element-hq/element-x-ios/commit/270633527)
- Open the session stores with a high-entropy passphrase declaration (adopts the KDF skip)
  [`04f9f87da`](https://github.com/element-hq/element-x-ios/commit/04f9f87da)
- Start the session restore eagerly from `AppCoordinator.init`, on a detached task, and
  build + start the sync service on it (first sync request out at ~0.9s instead of ~1.4s)
  [`a9d03e576`](https://github.com/element-hq/element-x-ios/commit/a9d03e576),
  [`6318ba1e1`](https://github.com/element-hq/element-x-ios/commit/6318ba1e1),
  [`eabed5558`](https://github.com/element-hq/element-x-ios/commit/eabed5558)
- Defer Sentry, analytics and notification startup off the launch critical path, gated on
  first render; fix the empty-list flash
  [`8c33808c9`](https://github.com/element-hq/element-x-ios/commit/8c33808c9),
  [`505a9d6da`](https://github.com/element-hq/element-x-ios/commit/505a9d6da)
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
- `BackPaginationQueue`: priority heap, per-room single-flight, per-priority concurrency
  caps, coalescing - replaces the credit system (built on Stefan's queue series)
  [`3fe3a3dcc`](https://github.com/matrix-org/matrix-rust-sdk/commit/3fe3a3dcc)…[`6bed07f5b`](https://github.com/matrix-org/matrix-rust-sdk/commit/6bed07f5b),
  caps [`6a3546d95`](https://github.com/matrix-org/matrix-rust-sdk/commit/6a3546d95),
  concurrency [`993bb82d7`](https://github.com/matrix-org/matrix-rust-sdk/commit/993bb82d7)
  - part of [sdk#6014 [meta] Automatic backpagination](https://github.com/matrix-org/matrix-rust-sdk/issues/6014)
- Accept undecrypted events as latest-event candidates: UTDs render as "Waiting for
  decryption key", keep an accurate bump timestamp (no sink treadmill), and are replaced
  in place once the key arrives
  [`e1374ff8f`](https://github.com/matrix-org/matrix-rust-sdk/commit/e1374ff8f),
  [`1457a8eca`](https://github.com/matrix-org/matrix-rust-sdk/commit/1457a8eca)
- Valueless rooms backfill their preview automatically via a detached request; viewport
  rooms preload with top priority, two-tier (preview first, then a screenful)
  [`25c7c3a83`](https://github.com/matrix-org/matrix-rust-sdk/commit/25c7c3a83),
  [`c55c20607`](https://github.com/matrix-org/matrix-rust-sdk/commit/c55c20607),
  [`3685da91e`](https://github.com/matrix-org/matrix-rust-sdk/commit/3685da91e)
  - fixes [#4898 Last messages are populated only for the displayed rooms in the room list](https://github.com/element-hq/element-x-ios/issues/4898)
  - fixes [#5189 No last message logic when logging in with a small account](https://github.com/element-hq/element-x-ios/issues/5189)
- Drain the latest-event backlog in reverse chronological order
  [`32220d70e`](https://github.com/matrix-org/matrix-rust-sdk/commit/32220d70e)
- Stop the automatic backfill walking a room's entire history (the `/messages` trickle
  loop; origin-aware re-arm with a strict budget)
  [`53c1bed53`](https://github.com/matrix-org/matrix-rust-sdk/commit/53c1bed53)
  - likely fixes [#3183 Opening a room when offline causes scrollback spinner to tightloop](https://github.com/element-hq/element-x-ios/issues/3183)
- Never fetch `/room_keys/version` while classifying UTDs - cold-launch first paint
  blocked up to 49s offline on this network call
  [`12e2d0d8b`](https://github.com/matrix-org/matrix-rust-sdk/commit/12e2d0d8b)
- Stop the room list spasming during catch-up syncs: a burst of freshly computed
  latest events is persisted in one store transaction and broadcast back-to-back
  (one atomic reorder per drain instead of one per room), and one drain fits a
  whole response's rooms
  [`a637111d1`](https://github.com/matrix-org/matrix-rust-sdk/commit/a637111d1),
  [`f08c09150`](https://github.com/matrix-org/matrix-rust-sdk/commit/f08c09150)
  - fixes [#4814 The roomlist order jumps around (spasms) fairly wildly when syncing](https://github.com/element-hq/element-x-ios/issues/4814)
  - fixes [rageshake#4993 yet another 20s sync… then the roomlist spasmed like crazy as it caught up](https://github.com/element-hq/element-x-ios-rageshakes/issues/4993)

SDK - sync correctness:
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
- Log which event counts a room as unread, so rooms stuck unread despite an up-to-date
  receipt name their culprit
  [`24333794e`](https://github.com/matrix-org/matrix-rust-sdk/commit/24333794e)
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

#### Prefill rooms via Stefan's auto-pagination engine rather than via SSS subscriptions

- Preload visible rooms via the back-pagination queue instead of SSS subscriptions;
  1 visible event requested, SDK tops up the timeline
  [`38ef09140`](https://github.com/element-hq/element-x-ios/commit/38ef09140),
  [`c10a36027`](https://github.com/element-hq/element-x-ios/commit/c10a36027)
- Route visible rooms through a dedicated viewport sliding-sync connection; staged
  room-list growth relies on proactive sync
  [`eadcb4239`](https://github.com/element-hq/element-x-ios/commit/eadcb4239),
  [`5cd7d67b5`](https://github.com/element-hq/element-x-ios/commit/5cd7d67b5)
  - **I am pretty sure this is a dead-end commit which got backed out later: rather than proactively expanding all_rooms in blocks of 20 with timeline_limit=10 to prefill room history, we switched back to growing it rapidly in blocks of 200 with timeline_limit=1 and instead hooked up autopagination to prefill history.**

#### Unbreak offline mode

- Never block launch on the network (fire-and-forget `auth_metadata` caching); add
  per-launch `LaunchMetrics` (greppable log line + Sentry transaction)
  [`e86a457b5`](https://github.com/element-hq/element-x-ios/commit/e86a457b5)

#### Fix all the spurious "join" screens when you try to view a room which hasn't been synced yet.

- Never show a join screen for a room the user is already in (push-taps for unsynced
  rooms now wait for the room; the join screen honours server-reported membership)
  [`ac2169469`](https://github.com/element-hq/element-x-ios/commit/ac2169469)
  - fixes [#4287 Opening a push for a room whose invite you accepted elsewhere fails](https://github.com/element-hq/element-x-ios/issues/4287)
  - likely fixes [rageshake#7352 Opening rooms just opens an invite screen and not the room](https://github.com/element-hq/element-x-ios-rageshakes/issues/7352)
    and [rageshake#2479 Tapped notification and got the Join Room screen](https://github.com/element-hq/element-x-ios-rageshakes/issues/2479)

#### Hide skeletons as they make things feel slower by flashing up (plus we're fast enough to never see them now)

- Hold the splash until the cached room list has published - zero skeleton frames on
  launch
  [`5ae04e03f`](https://github.com/element-hq/element-x-ios/commit/5ae04e03f)

#### Make it clear precisely what git versions any given app build is using

- Show the app and SDK git SHAs in the Settings version footer (build phase stamps
  `AppGitSHA` into Info.plist, `-dirty` when the tree is modified) so you can tell
  exactly which dogfood pairing a phone is running
  [`48cba7c70`](https://github.com/element-hq/element-x-ios/commit/48cba7c70)

#### Implement smooth infinite scrolling on the room list

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
- Re-snap to the real top after a system scroll-to-top: with 6k rooms the status-bar
  tap lands slightly off the estimated top, leaving the navigation bar (large title,
  search drawer, filter chips) stuck mid-transition
  [`877f5db4c`](https://github.com/element-hq/element-x-ios/commit/877f5db4c)
- Shrink the home list's first page from 100 to 64 rooms: every first-page room costs
  a summary build (FFI fetch + string building) in front of the first paint, while the
  screen renders ~10 rows and scrolling grows the list anyway; also log summary builds
  over 25ms so launches attribute this stage. (Was originally 32 rooms; later settled on
  64 once summary builds slimmed down and the bottom-bounce prefetch landed)
  [`edb009314`](https://github.com/element-hq/element-x-ios/commit/edb009314),
  [`babf62b7d`](https://github.com/element-hq/element-x-ios/commit/babf62b7d)

#### Speed up launch from 480ms to 80ms on iPhone 12 by lazyloading MapLibre on demand

- Load MapLibre lazily via dlopen: its static initialisers (mostly a Metal compression
  context) cost ~60ms of dyld work on every cold launch, for a map that only renders
  once a location screen opens. The interactive map moved into a MapLibreShim framework
  (embedded, unlinked, dlopen'd on first map use); the app links only a tiny
  MapInterface framework of shared types. Timeline location messages already used the
  static tile view, which never touched MapLibre
  [`e80dd55a5`](https://github.com/element-hq/element-x-ios/commit/e80dd55a5)

#### Implement long-tap-to-peek on the room list

- Long-press a room in the room list to peek at its timeline (iMessage-style preview
  above the context menu) without sending a read receipt: the peek renders the real
  timeline item views read-only, deliberately avoiding the timeline table controller
  and RoomScreenViewModel - the only two places receipts originate. Tapping the
  preview opens the room properly (which needs UIKit: SwiftUI context menu previews
  never receive taps, so the row's menu moved to a UIContextMenuInteraction with a
  preview-commit handler), a themed 20% scrim fades in behind the preview and menu,
  short histories back-paginate to fill the viewport, and the platter is sized so
  platter + gap + menu exactly fill the screen - any slack makes the peek's position
  track whichever row you pressed. Gotcha for posterity: a bottom-anchored lazy stack
  of timeline items layout-loops (appearing items fetch reply details, change height
  and re-cross the lazy horizon) hard enough that the cpu watchdog kills the app;
  the peek renders the newest 40 items in a non-lazy stack instead
  - implements [#3658 Long-tap on room list entry to read-only preview room contents](https://github.com/element-hq/element-x-ios/issues/3658)

#### Fix the class of problems where timelines get stuck with one message visible and don't automatically backfill

- Re-run the timeline's viewport fill check after each snapshot applies: it only ran on
  scroll and pagination-state changes, which fire against the previous timeline's
  geometry when switching timelines. A live timeline whose loaded window had been
  unloaded by a limited sync (dogfooding hit this as "room shows only the remote echo
  of my own message after sending from a notification tap") stayed a single bubble
  until the user scrolled
  [`c1cae2c9c`](https://github.com/element-hq/element-x-ios/commit/c1cae2c9c)
  - likely fixes [#5817 Timeline can get stuck showing only the most recent message if there's a reset which races with a local echo](https://github.com/element-hq/element-x-ios/issues/5817)
    (mirrored as [sdk#6709](https://github.com/matrix-org/matrix-rust-sdk/issues/6709))

#### Make rejecting invites local echo & non-blocking

- Make declining an invite non-blocking: the decline also forgets the room server-side
  (measured ~5s on matrix.org) and the modal indicator froze the whole room list for
  that long
  [`556982912`](https://github.com/element-hq/element-x-ios/commit/556982912)
  - fixes the blocking half of [#2535 No local echo on rejecting invites](https://github.com/element-hq/element-x-ios/issues/2535)
  - related: [rageshake#6668 unable to decline… I just get a Loading window pop up and the app is unresponsive](https://github.com/element-hq/element-x-ios-rageshakes/issues/6668)

#### Make redactions local echo, and fix what happens if you long-press on them

- Redactions now apply as local echoes: `Timeline::redact` sent remote-target
  redactions as a direct HTTP request, so "Remove" left the message visible until the
  redaction came back down /sync (forever, while offline). Routed through the send
  queue, whose redaction local echo the timeline already applies to the target item
  immediately - plus the usual queue durability (retries, offline, ordering behind
  pending sends)
  ([SDK [`4366a2e7b`](https://github.com/matrix-org/matrix-rust-sdk/commit/4366a2e7b)](https://github.com/matrix-org/matrix-rust-sdk/commit/4366a2e7b))
  - fixes [#1713 Redactions don't local echo](https://github.com/element-hq/element-x-ios/issues/1713)
  - broke `test_redact_message`/`test_redact_local_sent_message` (they asserted the
    old direct-HTTP shapes, and the queued redaction raced test teardown); re-mocked
    for the local-echo semantics in
    [SDK [`a0dbb30ba`](https://github.com/matrix-org/matrix-rust-sdk/commit/a0dbb30ba)](https://github.com/matrix-org/matrix-rust-sdk/commit/a0dbb30ba)
- Long-press on a redacted message showed a blank fullscreen sheet (the filtered action
  set came back empty with view source off, and the sheet presents regardless; state
  events hit the same). Redacted items keep copy-permalink (plus view source in dev
  mode), and the menu no longer presents at all when a provider has nothing to offer
  [`d8b529726`](https://github.com/element-hq/element-x-ios/commit/d8b529726)

#### Stop getting blocked on "Loading..." when opening rooms

I'm not entirely sure about this one, or what "THE SYNC WEDGE" is that Fable is thinking about.
In general, the fact the app now has the ability to lock the user out beind a "Loading..." modal they can never cancel feels like a major footgun and antipattern.

- THE SYNC WEDGE, root-caused and fixed: the latest-events "re-trigger missing
  computations" step held the rooms-map read lock while awaiting every response room's
  own lock; with the compute task holding a room's write lock and a room registration
  queued on `rooms.write()`, tokio's write-preferring `RwLock` closed a three-party
  cycle. The sync handler sat inside it holding the sliding-sync `position` lock, so
  the sync loop, the ack-gated pos persist and any room open all wedged behind it
  (dogfooding: room list stuck behind a permanent "Loading…" overlay). Both offending
  sites now snapshot cheap clone handles and release the map lock before awaiting
  per-room locks
  ([SDK [`830f3dc0e`](https://github.com/matrix-org/matrix-rust-sdk/commit/830f3dc0e)](https://github.com/matrix-org/matrix-rust-sdk/commit/830f3dc0e))
  - likely the cause of
    [rageshake#6487 app got stuck on Loading… when opening a room and had to be force quit](https://github.com/element-hq/element-x-ios-rageshakes/issues/6487),
    [rageshake#6322 app hung while opening room on "loading…" spinner. had to force quit](https://github.com/element-hq/element-x-ios-rageshakes/issues/6322),
    [rageshake#7173 infinite Loading spinner while trying to open room. had to force quit](https://github.com/element-hq/element-x-ios-rageshakes/issues/7173) and
    [rageshake#5716 app stuck solid on loading spinner trying to open room](https://github.com/element-hq/element-x-ios-rageshakes/issues/5716)

#### Stop "Loading..." blocking and locking you out of the app when you tap on a push on bad network

- Let a tap on a route's "Loading…" modal abandon the navigation: a push-tap on a
  black-hole network wedged the whole app for ~92s, because the tapped event's fetch
  retries 3x30s behind a non-interactive modal (console logs 2026-08-11 ~18:58 local).
  The modal's scrim is now tappable for the event/child-event routes, ChatsTab alias
  resolution and thread presentation - a tap hides the modal, cancels the in-flight
  task and unwinds whatever the route half-started. Also fixes a failed thread
  timeline build leaving the state machine in `.thread` with no screen pushed
  [`5c11e1b37`](https://github.com/element-hq/element-x-ios/commit/5c11e1b37)

#### Position permalinks correctly in the middle of the viewport

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

#### Make tap-on-push work, and go rapidly straight to the right room and permalink (unless the event is at the bottom of the timeline, then don't bother permalinking)

- Focus notification taps on their event (served locally when the NSE prefilled it);
  give background refresh a bounded wait for session restore instead of a silent no-op
  [`580ba004d`](https://github.com/element-hq/element-x-ios/commit/580ba004d)
  - fixes [#4790 Tapping on a push should permalink to that message](https://github.com/element-hq/element-x-ios/issues/4790)
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
  ([SDK [`92950c9f3`](https://github.com/matrix-org/matrix-rust-sdk/commit/92950c9f3)](https://github.com/matrix-org/matrix-rust-sdk/commit/92950c9f3))
  [`5e43d0872`](https://github.com/element-hq/element-x-ios/commit/5e43d0872)
  - the unhideable focus toast matches stuck-"Loading…" reports like
    [rageshake#3004 upgraded to 851 and promptly got stuck on a loading… spinner](https://github.com/element-hq/element-x-ios-rageshakes/issues/3004)
- Attach the UNUserNotificationCenter delegate at init: deferring notification startup
  off the launch critical path ([`505a9d6da`](https://github.com/element-hq/element-x-ios/commit/505a9d6da), above) also deferred the delegate
  assignment past the end of launch, and iOS discards (not buffers) the notification
  response for a tap that launched the app when no delegate is in place - a push tapped
  while the app was killed silently dropped its route and left the user on the room
  list (console logs 2026-08-12 ~11:30 local). Warm-app taps were unaffected
  [`2c7928bb9`](https://github.com/element-hq/element-x-ios/commit/2c7928bb9)
- Notification taps jump straight to the room: taps on the newest message open live at
  the bottom with no focus treatment, decided at the route level from the fetched
  event's ID *and timestamp* (the in-memory latest event lags the NSE right after a
  tap wakes the app, so ID comparison alone mis-decides)
  [`363b3b7f5`](https://github.com/element-hq/element-x-ios/commit/363b3b7f5),
  new `latestEventTimestamp` FFI
  ([SDK [`9a7707b37`](https://github.com/matrix-org/matrix-rust-sdk/commit/9a7707b37)](https://github.com/matrix-org/matrix-rust-sdk/commit/9a7707b37))
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
  ([SDK [`b10561742`](https://github.com/matrix-org/matrix-rust-sdk/commit/b10561742)](https://github.com/matrix-org/matrix-rust-sdk/commit/b10561742),
  [`41e4704ed`](https://github.com/matrix-org/matrix-rust-sdk/commit/41e4704ed))
  - advances [sdk#4874 [meta] Dirty cross-process locks](https://github.com/matrix-org/matrix-rust-sdk/issues/4874)
    and [sdk#6681 [meta] Adopt a new cross-process state invalidation strategy](https://github.com/matrix-org/matrix-rust-sdk/issues/6681)
  - likely fixes [rageshake#5029 Opening a room takes several seconds](https://github.com/element-hq/element-x-ios-rageshakes/issues/5029)

#### Jump straight to thread from room preview rather than taking you to the main room and feeling lost

- Open the thread when a room's preview shows a threaded reply: the preview surfaces
  the room's latest event even when it is threaded, which the main timeline hides -
  tapping the room then appears to be missing the previewed message (dogfooded as
  "preview shows 13:41 but the room ends at 13:32")
  [`b2140c102`](https://github.com/element-hq/element-x-ios/commit/b2140c102),
  new `latestEventThreadRootId` FFI
  ([SDK [`0ba9d0d9d`](https://github.com/matrix-org/matrix-rust-sdk/commit/0ba9d0d9d)](https://github.com/matrix-org/matrix-rust-sdk/commit/0ba9d0d9d))
- The tap-into-thread routing made thread latest events a routine code path,
  and reproduced the sync wedge the 2026-08-11 fix had left as a residual
  watch. Three distinct causes were found and fixed across one evening of
  repro rounds (all with regression tests that fail without the fix):
  - `room_latest_event`'s thread arm (plus `forget_thread`, both
    `listen_and_subscribe` entry points and the backfill-candidates loop)
    still awaited a per-room lock while holding the rooms-map lock; a second
    tap on the room then parked holding the map, the sync response handler
    queued behind it holding the sliding sync `position` lock, and the whole
    app wedged behind a permanent uncancellable "Loading..." modal. All
    remaining under-map-lock awaits evicted with the snapshot-handle pattern.
    [SDK [`84c47e013`](https://github.com/matrix-org/matrix-rust-sdk/commit/84c47e013)](https://github.com/matrix-org/matrix-rust-sdk/commit/84c47e013)
  - With that fixed, the handler still wedged 70s+ inside "Re-triggering
    missing latest event computations": a catch-up response registering
    hundreds of rooms enqueues as many computations, and the trigger loop
    awaited each room's lock under the `position` lock, convoying behind the
    compute task. It now `try_read`s and enqueues busy rooms unconditionally
    (recomputing an existing value is idempotent; the check only avoids queue
    spam).
    [SDK [`19e852a81`](https://github.com/matrix-org/matrix-rust-sdk/commit/19e852a81)](https://github.com/matrix-org/matrix-rust-sdk/commit/19e852a81)
  - The plain room route's loading modal was uncancellable (only event routes
    wired up tap-to-cancel), so a wedged open locked the whole app. All four
    routes through `handleRoomRoute` (room, thread, event, share) now track
    their in-flight task and a tap on the modal's background abandons it.
    [EXI [`49f379d51`](https://github.com/element-hq/element-x-ios/commit/49f379d51)](https://github.com/element-hq/element-x-ios/commit/49f379d51)
- The room-open path now logs every await boundary (resolve proxy, fetch
  room, fetch room info, build live timeline, room-list/timeline
  subscriptions) so any future silent hang names its stuck await in the
  rageshake.
  [EXI [`5c868e39c`](https://github.com/element-hq/element-x-ios/commit/5c868e39c)](https://github.com/element-hq/element-x-ios/commit/5c868e39c)
- A final repro round was poisoned by a rig bug worth knowing about:
  `devicectl device process launch --terminate-existing` only terminates the
  newest install's process, so every reinstall left the previous build
  running as a zombie - three live ElementX instances were sharing the
  app-group sqlite stores and the sync session. The dogfood install script
  now kills every ElementX pid before installing (e2ee-rig [`11c7545`](https://github.com/element-hq/e2ee-test-rig/commit/11c7545)).

#### Fix reply previews showing "Unsupported event" if they haven't yet decrypted the reply

- Reply previews of undecrypted events showed "Unsupported event" and never refreshed:
  they now say "Waiting for decryption key"
  [`bde3cbd69`](https://github.com/element-hq/element-x-ios/commit/bde3cbd69) and update
  in place when the key arrives - the SDK hooks the redecryptor's resolved-UTDs report
  to refresh replies whose target is outside the loaded timeline
  ([SDK [`17af054e3`](https://github.com/matrix-org/matrix-rust-sdk/commit/17af054e3)](https://github.com/matrix-org/matrix-rust-sdk/commit/17af054e3)).
  Events fetched over `/event` are now saved into the event cache too: reply targets
  used to be refetched over the network on every item rebuild (a ~10s skeleton while
  matrix.org served a cold 2023 event) and, being invisible to the redecryptor, never
  resolved in place when their key arrived from backup
  ([SDK [`4b23e1d77`](https://github.com/matrix-org/matrix-rust-sdk/commit/4b23e1d77)](https://github.com/matrix-org/matrix-rust-sdk/commit/4b23e1d77);
  briefly reverted while bisecting duplicate echoes of freshly sent messages, then
  reapplied in [`bdea86735`](https://github.com/matrix-org/matrix-rust-sdk/commit/bdea86735) -
  the duplicates turned out to be a long-standing intermittent race, reported since
  2025 as [#4242 Slow server can result in duplicate msgs in E2EE room](https://github.com/element-hq/element-x-ios/issues/4242)
  and rageshakes [#6945](https://github.com/element-hq/element-x-ios-rageshakes/issues/6945),
  [#6592](https://github.com/element-hq/element-x-ios-rageshakes/issues/6592),
  [#5789](https://github.com/element-hq/element-x-ios-rageshakes/issues/5789))
  - fixes [#3113 Late decryptions don't update RepliedToEvent](https://github.com/element-hq/element-x-ios/issues/3113)
  - fixes the "unsupported event in summary" half of
    [#4819 Message in thread shows as UTD in main timeline + unsupported event in summary until you load the thread](https://github.com/element-hq/element-x-ios/issues/4819)
    (reported in the wild as [rageshake#6859 "unsupported event" in thread preview](https://github.com/element-hq/element-x-ios-rageshakes/issues/6859))
  - related: [#6002 Update UI when replied to message cannot be loaded](https://github.com/element-hq/element-x-ios/issues/6002)

#### Fix indentation in markdown bullet lists

- Fix the first list item rendering more indented than the rest (inter-element
  whitespace in markdown-generated HTML normalised into stray spaces)
  [`550a6467d`](https://github.com/element-hq/element-x-ios/commit/550a6467d)
  - fixes [#5179 First bullet point in an unordered list is always incorrectly indented](https://github.com/element-hq/element-x-ios/issues/5179)

#### Fix many scenarios where sent messages can duplicate in the timeline or get lost

- Instrument the local-echo reconciliation to catch duplicated sent-message echoes
  in the wild (intermittent for months; server-side the event exists once). Logs the
  birth of a duplicate item, own remote events failing to match a local echo, the
  send queue's eager event-cache insert, and each delivery's dedup classification
  ([SDK [`9a24a6a76`](https://github.com/matrix-org/matrix-rust-sdk/commit/9a24a6a76)](https://github.com/matrix-org/matrix-rust-sdk/commit/9a24a6a76))
  - diagnoses [#4242 Slow server can result in duplicate msgs in E2EE room](https://github.com/element-hq/element-x-ios/issues/4242),
    [rageshake#6945 all my sent msgs are showing in duplicate in most recent room](https://github.com/element-hq/element-x-ios-rageshakes/issues/6945),
    [rageshake#6592 a pile of UTDs, and then my messages are getting duplicated](https://github.com/element-hq/element-x-ios-rageshakes/issues/6592) and
    [rageshake#5789 I sometimes see messages double](https://github.com/element-hq/element-x-ios-rageshakes/issues/5789)
- ROOT-CAUSED the duplicated sent-message echoes, from the rageshake#6945 logs: a room
  update that fails mid-way (there: the store closed during a `JoinedRoomUpdate`,
  aborting the chunk shrink between its store operations) leaves the in-memory linked
  chunk divergent from the store. The store is the deduplication oracle, so every
  re-delivery of an event already in memory - notably each sent message's sync echo,
  which the send queue also eagerly inserts - is misclassified as new and appended
  again: every send duplicates until something reloads the chunk (leaving the room
  triggers the auto-shrink, hence the observed self-healing). Failed updates now
  poison the room, and the next update entry point reloads the linked chunk from the
  store before mutating anything
  ([SDK [`4eed9b8a2`](https://github.com/matrix-org/matrix-rust-sdk/commit/4eed9b8a2)](https://github.com/matrix-org/matrix-rust-sdk/commit/4eed9b8a2))
  - fixes [rageshake#6945 all my sent msgs are showing in duplicate in most recent room](https://github.com/element-hq/element-x-ios-rageshakes/issues/6945)
    and likely [#4242 Slow server can result in duplicate msgs in E2EE room](https://github.com/element-hq/element-x-ios/issues/4242),
    [rageshake#6592](https://github.com/element-hq/element-x-ios-rageshakes/issues/6592) and
    [rageshake#5789](https://github.com/element-hq/element-x-ios-rageshakes/issues/5789)
- Widen the duplicated-echoes tripwire to the remotes region and log what
  `remove_events` actually removes: the 1-10 self-send repro (2026-08-12, sliding-sync
  session restart mid-send collapsed the open timeline and left 6-10 duplicated below
  a re-appended 1-10) produced visible duplicates without tripping the existing
  instrumentation (the decisive classification logs sit at debug, below the rageshake
  filter - a temporary debug default [`038d0121c`](https://github.com/matrix-org/matrix-rust-sdk/commit/038d0121c) was reverted in [`98f06f80f`](https://github.com/matrix-org/matrix-rust-sdk/commit/98f06f80f) as too
  noisy for the phone; the warn-level tripwires carry the signal instead)
  ([SDK [`4a3906914`](https://github.com/matrix-org/matrix-rust-sdk/commit/4a3906914)](https://github.com/matrix-org/matrix-rust-sdk/commit/4a3906914))
- Merge the tachyon (DMLS) review's collapse/redelivery fixes, §§1-5 of
  `workspace-dmls .../docs/dmls/REVIEW-upstream-timeline-bugs.md` - §3+§4 are the
  root causes of the 1-10 self-send duplicates (a limited-sync collapse makes the
  dedup's recorded removal positions stale, so `push_live_events` appends a second
  copy; and a copy offloaded to the store during the collapse means chunk-level dedup
  correctly removes nothing while the timeline still shows its item). §1 un-wedges
  backfill behind non-advancing empty `/messages` gaps after such collapses, §2 stops
  a clear-racing-a-local-echo leaving stale `all_remote_events` meta that offsets
  later positional diffs (fresh messages vanishing), §5 downgrades a stale-position
  `.expect()` panic in `remove_events` to a log. §6 (timeline-only state events under
  MSC4186) deliberately NOT merged - inverts documented upstream behaviour, needs an
  upstream design discussion first. All six were verified still present in upstream
  main @ [`44a907dd8`](https://github.com/matrix-org/matrix-rust-sdk/commit/44a907dd8) (2026-08-04); upstreaming candidates
  ([SDK [`f5d631a4a`](https://github.com/matrix-org/matrix-rust-sdk/commit/f5d631a4a)](https://github.com/matrix-org/matrix-rust-sdk/commit/f5d631a4a),
  [SDK [`59d0d4f3d`](https://github.com/matrix-org/matrix-rust-sdk/commit/59d0d4f3d)](https://github.com/matrix-org/matrix-rust-sdk/commit/59d0d4f3d))
  - likely fixes [#4242 Slow server can result in duplicate msgs in E2EE room](https://github.com/element-hq/element-x-ios/issues/4242)-family
    residue beyond the dup-echo divergence fix, and the 2026-08-12 1-10 self-send
    duplicate run

#### Fix echoes bouncing back and forth as you send a sequence of messages

- ROOT-CAUSED the sent-message ordering bounce (echoes swapping back and forth on slow
  connections, screen recordings 2026-08-12 ~12:36 local): the send queue eagerly
  inserts each sent event at the linked chunk's tail, and every lagging sync delivery
  of an already-inserted event went through the dedup's remove+re-append, yanking a
  visible message below newer sends until a final all-inclusive batch settled it. The
  all-duplicates early return never saves own sends (it requires a foreign sender).
  Tail duplicates that form a prefix of the sync batch - sync merely catching up on a
  tail we already have - are now replaced in place, also swapping the eager copy's
  fabricated `origin_server_ts` for the real payload; superset re-deliveries (e.g. a
  timeline-limit increase) and gappy responses keep the authoritative remove+re-append
  ([SDK [`b004a4b9b`](https://github.com/matrix-org/matrix-rust-sdk/commit/b004a4b9b)](https://github.com/matrix-org/matrix-rust-sdk/commit/b004a4b9b))
  - upstreamable; also softens [#4242](https://github.com/element-hq/element-x-ios/issues/4242)-family churn

#### Fix the glitches in the send animation at last.

Finish off the nightmare of https://github.com/element-hq/element-x-ios/issues/4127 at last.
See the test jig that Fable built to diagnose this at https://github.com/element-hq/bubbleanim

- Animate the sent tick's removal from the previous message in sync with the new
  row's insertion: sending made the previously-last outgoing bubble snap ~27pt
  shorter (the tick row under it vanishing unanimated) while the insertion animated,
  so the old bubble visibly halved in height and squashed against its neighbour
  before re-expanding (screen recording 2026-08-12 ~20:35 local, frame-by-frame).
  First attempt keyed an `elementDefault` animation on the last-item flip
  ([`0125d9091`](https://github.com/element-hq/element-x-ios/commit/0125d9091)), but a
  minimal sim harness (bubble-anim-harness in the workspace: same flipped-table +
  diffable + UIHostingConfiguration construction, frame-by-frame measured) showed
  that to be worse: the self-sizing invalidation desyncs from the batch animation -
  the whole stack pops down by the tick-row height in one frame and the old bubble
  rides up truncated. Real fix: reconfigure the previous newest item inside the same
  animated snapshot apply, making its height change part of the one batch layout
  animation with the insertion - every bubble stays full height and the stack rises
  monotonically. Not yet validated on the phone; upstreamable
  [`1b450577b`](https://github.com/element-hq/element-x-ios/commit/1b450577b)
- Follow-up: residual downward dip of the previous bubble during the insert
  (phone-visible). Harness root cause: on the batch's first frames the cell keeps
  its old tall frame while its content has already re-rendered without the status
  row, and SwiftUI centres content in the excess space - the bubble dips by half
  the status-row height. Fix: pin the hosted cell content to topLeading with
  maxHeight .infinity, so the excess is consumed at the status-row edge; measured
  fully monotonic in the harness incl. image-sized bubbles either side of the
  transition. Upstreamable together with the reconfigure
  [`66bea662f`](https://github.com/element-hq/element-x-ios/commit/66bea662f)
#### Fixing blocks of sends which vanish and then reappear 10s of seconds later

This bug has been around since the event cache landed, i think.

- Diagnostics for own sends vanishing after a limited gappy sync (2026-08-12
  20:35 local, Self DM): four just-sent messages left the visible timeline for
  ~19s until the next sync re-delivered them. Trigger fully established (bad
  network delays the long-poll → the room comes back limited with a new gap
  whose batch is exactly the just-sent tail → dedup remove + re-append +
  `shrink_to_last_reloaded_chunk`), but every rust layer checks out under new
  regression tests (event cache emits `[Clear, Append]`, timeline + lazy skip
  subscriber deliver a faithful view), so the loss is between the FFI hop and
  the app's table. Both sides now log each timeline diff batch at info level so
  a rageshake can pair them up: SDK
  [`6f60ba2e3`](https://github.com/matrix-org/matrix-rust-sdk/commit/6f60ba2e3)
  ("timeline listener: forwarding diffs" + regression tests), EXI
  [`365c091af`](https://github.com/element-hq/element-x-ios/commit/365c091af)
  ("Timeline(kind) applied ..."). The EXI commit also implements the previously
  ignored `.truncate` diff (silent desync if one ever arrives; nothing emits it
  today). To validate: burst-send on a poor connection, watch for the vanish,
  rageshake immediately
- ROOT CAUSE FOUND + FIXED for the vanishing own sends: the instrumented repro
  (2026-08-12 23:01, 10 sends, ~5 vanished 11.5s) showed the FFI forwarding
  `[Clear, PushBack x20]` then `PushBack x10` with no removes - the rebuild
  never contained the sends, so the loss was in the event cache, not the app.
  The long-poll response was stale: generated before the sends completed but
  delivered after them, limited+gappy with a batch of only older events. The
  all-duplicates early return requires a foreign sender, so the all-own stale
  batch fell through to the gap+shrink path and the newer tail fell behind the
  gap. Fix: ignore batches that are entirely known events and don't contain
  the newest in-memory event (such a response describes a server view older
  than local state); batches containing the tail keep today's behaviour.
  Regression test drops exactly the tail sends without the fix. Upstream this
  together with the diagnostics commit
  [SDK [`6532fc2be`](https://github.com/matrix-org/matrix-rust-sdk/commit/6532fc2be)](https://github.com/matrix-org/matrix-rust-sdk/commit/6532fc2be)
- **BUGGY AS SHIPPED (flagged 2026-08-15): this guard over-matched.** It
  conflated known-and-in-the-live-tail with known-but-stranded-behind-a-gap
  (store-only copy), and so ate the late sync echo of a stranded just-sent
  event - making a sent message invisible permanently (survived restarts).
  Properly fixed by SDK
  [`cbf7545bc`](https://github.com/matrix-org/matrix-rust-sdk/commit/cbf7545bc)
  (the known copies must all live in memory); see "Vanished mid-send message
  ROOT-CAUSED + FIXED" at the end of this document. Upstream `6532fc2be` only
  together with `cbf7545bc`.

#### Crash if the user stabs the send button too fast as it switches between send and VM

- Crash + missing crash prompt fixed (2026-08-13, from the 22:19 rageshake,
  Sentry `4671176f84f8`): a send action racing the start of a voice recording
  reached `TimelineViewModel.sendCurrentMessage` with mode `.recordVoiceMessage`
  and hit `fatalError("invalid composer mode.")`. The composer view model now
  ignores sends while recording and the fatalError is an error log. Separately,
  the "app crashed, submit report?" prompt never appeared because
  `HomeScreenCoordinator.start()` sampled `lastCrashEventID` once, ~76ms before
  Sentry's `onCrashedLastRun` callback set it (fast warm relaunches reliably
  win that race); the ID is now a `CurrentValuePublisher` and the alert is
  presented when it first becomes non-nil. Both upstreamable. EXI
  [`e8b28d5ef`](https://github.com/element-hq/element-x-ios/commit/e8b28d5ef).
  The same rageshake showed the post-crash flavour of the stale-sync-batch
  vanish (first sync after relaunch uses the pre-crash pos while the send queue
  is still re-sending), covered by SDK [`6532fc2be`](https://github.com/matrix-org/matrix-rust-sdk/commit/6532fc2be) above (BUGGY AS SHIPPED, see the
  flag on its entry; corrected by `cbf7545bc`); the send queue itself
  behaved (both pending messages restored and re-sent, nothing lost)

#### Stop the first tap after a "Loading..." modal being silently swallowed

- Systematically reproduced as "the first back press (or scroll) after
  opening a thread from the room list does nothing, the second works" - and
  pinned by dogfood observation: waiting an extra ~500ms avoided it. A
  retracted indicator lingers for the rest of `minimumDisplayDuration`
  (0.5s) so it doesn't flash, but it kept its scrim and the overlay window's
  interactivity for that whole window, so any tap during the linger hit a
  scrim whose cancel action had nothing left to cancel. The controller now
  tracks retracting indicators: the pill still fades over the linger, but
  the scrim is removed and the overlay window stops intercepting the moment
  the retract begins. (An earlier attempt disabling window interaction only
  once no indicator was active -
  [EXI [`1f669f332`](https://github.com/element-hq/element-x-ios/commit/1f669f332)](https://github.com/element-hq/element-x-ios/commit/1f669f332)
  - kept as a belt, was too late to help.) Window-level touch logging landed
  alongside for future swallowed-tap hunts
  ([EXI [`7ff0ea3fb`](https://github.com/element-hq/element-x-ios/commit/7ff0ea3fb)](https://github.com/element-hq/element-x-ios/commit/7ff0ea3fb),
  strip before upstreaming). Upstreamable.


#### The send transition: no more composer-collapse pop

Sending a multiline message popped the whole timeline: clearing the composer
shrinks the bottom inset in one unanimated pass (the harness showed SwiftUI
turns the safeAreaInset into a frame resize of the table, whose flipped content
is glued to the frame's bottom edge), so the timeline dropped by the collapse
delta and the echo's insert pushed it back up ~100ms later. Replaced with a
Signal-style send transition, iterated over 16 commits of phone dogfooding +
device-log forensics (2026-08-13). Sends + replies only; edits/voice/media keep
today's behaviour; reduce-motion skips it entirely.

**How the fix works, in one breath**: when you tap send, the composer tells the
timeline exactly how much height its collapse is about to hand back (it
measures itself against its empty baseline). The timeline pins itself in place
\- freezing its frame and compensating its scroll offset - so neither the
composer's animated collapse nor the echo's insertion can shove it around;
the sent message is laid out early behind the composer's opaque background and
is revealed as the composer shrinks, fading in, while a single ease-out scroll
carries the timeline up by exactly the leftover (the message being taller than
the space handed back) to the final resting position, which is computed up
front rather than discovered afterwards. Single-line sends need none of this
choreography and use the stock insert animation. The details:

**Final architecture** (all in `TimelineTableViewController` + small hooks):

- *Measured collapse delta*: `ComposerToolbar` already reads its own frame; it
  records the excess over its empty-default-mode baseline height in
  `composerCollapseExtraHeight` (bindings) and every `.sendMessage` action
  carries it. This is the one number the timeline cannot observe in time, and
  it makes single-vs-multiline detection exact at the send tap (the send→mic
  button swap jiggles the toolbar height on clear, so observing resizes
  misfires).
- *Send hook*: `TimelineViewModel` fires `sendTransitionPublisher(delta)`
  synchronously when a `.default`/`.reply` send begins, before the clear
  renders.
- *Composer animations, decoupled from the timeline*: the post-send clear
  blanks the content instantly and animates only the height collapse
  (`withAnimation(.easeOut(0.2))` in the `.clear` handler). Typing growth
  tweens too (0.1s in `textViewDidChange`, `geometryGroup()` on the field, and
  `ElementTextView` drops caret auto-scrolls while the content fits under the
  height cap so the text stays glued to the animating box).
- *The freeze*: on send the table stops tracking the view's size (the collapse
  resizes the view every frame; following it drags the bottom-glued timeline
  down). For collapsing sends the frame freezes oversized (+300pt) so the
  echo's row materialises early - it renders behind the composer's opaque
  background and is revealed as the collapse shrinks - with a matching
  `contentInset.top` making the pinned overscroll legal (UIScrollView silently
  clamps illegal offsets mid-collapse; found via on-device logging of the pin
  deltas).
- *The pin*: a content-offset compensation keyed on the previous newest cell's
  visual top edge (top, because the same update removes its delivery status
  row), re-applied on every table layout pass
  (`SendTransitionTableView.onDidLayout`) until the settle motion starts. When
  a message taller than the oversize pushes the reference cell outside the
  materialised window, it is scrolled back in *inside the un-committed layout
  pass* (the `restoreLayout` pattern) before measuring - never measure
  unmaterialised rows via `contentSize`/`rectForRow`, their estimated heights
  track recent real cells and the error flips sign with context.
- *The choreography*: the echo applies unanimated whenever it lands, re-pinned;
  the new message fades in (0.2s) in the opening gap while ONE ease-out settle
  runs in parallel with the collapse, targeting absolute bottom computed in the
  frozen coordinates (final view height = height at send + measured delta) so
  there is a single velocity curve and nothing to true up afterwards; the
  frame/inset restore is a compensated no-op deferred to the settle's
  completion. Single-line sends leave the transition at the echo and use the
  stock animated batch insert (reconfigure included) with an alpha fade layered
  on. A settling flag keeps `isScrolledToBottom` true so the jump-to-bottom
  button doesn't flash; drags interrupt at the presentation value; a 1s
  fallback settles sends that never produce an echo (failures, slash commands);
  `scrollToNewestItem` is suppressed while active. Note: a message much taller
  than the composer's height cap necessarily "flies in from the bottom" - the
  timeline must end risen by (message height − delta), and only ~9 lines' worth
  is revealed by the collapse itself; if that ever grates, scale the settle
  duration with distance rather than adding a second phase.

**The journey** - each step was phone-validated or refuted by the user, with
screen recordings frame-scanned (ffmpeg column run-length traces) and, later,
on-device pin-delta logs; the dead ends are as valuable as the fixes:

1. [`0bbbfe5e4`](https://github.com/element-hq/element-x-ios/commit/0bbbfe5e4)
   pin + snapshot-overlay slide (prototyped in bubbleanim [`9a5a67b`](https://github.com/element-hq/bubbleanim/commit/9a5a67b); harness
   dead end: animating the collapse through layout + per-pass pinning renders
   inconsistently). Overlay read as the composer *sliding*, not shrinking.
2. [`e1a9fff97`](https://github.com/element-hq/element-x-ios/commit/e1a9fff97)
   clip-shrink overlay + typing-growth tween → collapse read as a vertical
   wipe (clipping cuts the field's top border off).
3. [`6e4f71c3b`](https://github.com/element-hq/element-x-ios/commit/6e4f71c3b)
   jump-to-bottom flash suppressed; status-row flicker fixed (no reconfigure in
   the frozen apply - rebuilding hosted content blanks it a frame).
4. [`0e268e0bd`](https://github.com/element-hq/element-x-ios/commit/0e268e0bd)
   growth desync root-caused from a recording: text led the box ~4pt on growth
   only - UITextView's caret auto-scroll during the tween. Suppressed.
5. [`4cf06d5aa`](https://github.com/element-hq/element-x-ios/commit/4cf06d5aa)
   cap-inset stretch overlay → worse (text block squished). Dead end: any
   snapshot of a *full* composer has content that can't fake a shrink.
6. [`36c5c6bd5`](https://github.com/element-hq/element-x-ios/commit/36c5c6bd5)
   the pivot (user suggestion): blank instantly, genuinely animate only the
   height, freeze the table's frame instead of fighting offsets. Overlay
   machinery deleted.
7. [`cd9462cbf`](https://github.com/element-hq/element-x-ios/commit/cd9462cbf)
   parallelism: oversized freeze so the echo applies mid-collapse; apply
   gating deleted (also fixed a single-line pop the gating caused - the echo
   parked while the status-row removal animated).
8. [`43f1da9af`](https://github.com/element-hq/element-x-ios/commit/43f1da9af)
   single-line slide-in; per-table-layout re-pin.
9. [`9cb742b52`](https://github.com/element-hq/element-x-ios/commit/9cb742b52)
   the measured collapse delta plumbed through; ease-out settles (user
   suggestion); residual settle starts at the apply; pin-delta logging added.
10. [`d84983b4e`](https://github.com/element-hq/element-x-ios/commit/d84983b4e)
    the dip root-caused from device logs: the oversize makes the pin
    overscroll and UIScrollView silently clamps it (-301 → -1, ~255pt repair
    deltas). Legalised with a matching content inset.
11. [`816054ffb`](https://github.com/element-hq/element-x-ios/commit/816054ffb)
    single-line skips the oversize churn; multiline undershoots by the
    status-row allowance so the end tops up in the same direction.
12. [`7f96896ff`](https://github.com/element-hq/element-x-ios/commit/7f96896ff)
    the bounce root-caused from logs: the dynamic frame-growth check fed on
    contentSize estimate-noise (frames exploded to 2036pt, offsets to -1555,
    top-of-viewport rows blanking) - deleted; and post-settle applies stopped
    pinning to the stale send-time reference. Single-line handed back to the
    stock animated insert.
13. [`4bb249f14`](https://github.com/element-hq/element-x-ios/commit/4bb249f14)
    single-line fades as it slides. Validated by the user: "multiline is
    working perfectly without dip or overscroll".
14. [`b06904f5c`](https://github.com/element-hq/element-x-ios/commit/b06904f5c)
    freeze-framing caught a velocity kink halfway through: the residual
    settle's ease-out tail met the end's fresh top-up curve. Replaced by ONE
    settle targeting absolute bottom in frozen coordinates, geometry restore
    deferred to its completion; the 30pt allowance and the whole second phase
    deleted.
15. [`b4ed1dd7d`](https://github.com/element-hq/element-x-ios/commit/b4ed1dd7d)
    >9-line sends dived: the message outgrew the 300pt oversize, the reference
    cell fell outside the materialised window, the pin silently no-opped
    ("restore found no cell" in the logs) and the settle ran from the wrong
    side of the target. First fix (contentSize arithmetic) was itself
    estimate-poisoned - the new row contributes only its estimated height, and
    estimates track recent real cells, so a short previous message made
    bubbles fly down from the top and a long one made them fly up from below.
16. [`03d924df9`](https://github.com/element-hq/element-x-ios/commit/03d924df9)
    the estimate-free pin: scroll the reference back into the window inside
    the un-committed pass (materialising the new row's real height), then the
    normal exact delta pin. Validated "almost perfect"; the remaining
    fly-in-from-the-bottom for very long messages is the designed motion (see
    the choreography note above).
17. [`0df3d522f`](https://github.com/element-hq/element-x-ios/commit/0df3d522f).
    Sends taller than the visible timeline (~19+ lines) left more
    than a screenful of residual travel after the pin, and animating that
    distance read as the bubbles zooming in from the bottom. Since everything
    pinned is offscreen once the settle lands anyway, the frozen apply now
    detects `travel > post-collapse view height`, jumps the content offset to
    the target unanimated inside the same layout pass, and lets the existing
    0.2s fade-in on the new message carry the transition alone. The settle path
    (and its deferred geometry-restore handshake) is bypassed, so the normal
    `endSendTransition` restore runs afterwards. Sub-screenful sends keep the
    single-curve settle unchanged.
18. [`8acdd35a9`](https://github.com/element-hq/element-x-ios/commit/8acdd35a9).
    validated on the phone. The travel-based snap condition above
    never fired for a real 26-line send: after the materialising pin the
    residual travel is only the couple hundred points the collapse doesn't
    absorb, well under a screenful - yet the message fills the whole viewport,
    so even that small settle read as fly-in. The snap now triggers when the
    laid-out height of the new message's cell fills the post-collapse viewport
    on its own (no older content survives the settle, so motion is pure noise);
    a cell so tall it isn't materialised within the oversized frame qualifies
    by definition, and the travel guard stays as a backstop. A
    `SendTransition: snapping` diagnostic logs the measured heights - strip
    with the other SendTransition logs before upstreaming.

Before (note animation glitches on the previously bottom-most message, and the composer snapping back and thus the timeline jumping around when sending multiline messages):

https://github.com/user-attachments/assets/7d3ab293-141b-4605-855f-14ffab5a61c0

After (note new messages slide in without the previously bottom-most message bouncing around; composer now expands smoothly and snaps back smoothly without causing the timeline to bounce on multiline messages):

https://github.com/user-attachments/assets/d9f1aca5-f445-412d-a06c-f93c7a4a08ec

Before upstreaming: strip the `SendTransition: restore`/`materialising` MXLog
diagnostics in the pin paths. Upstreamable as a whole; the composer-side
pieces (measured delta, growth tween, caret-scroll suppression) stand alone.

## Room list wedged on skeletons after a session expiry (SDK fix)

rust-sdk [`60a514641`](https://github.com/matrix-org/matrix-rust-sdk/commit/60a514641) on `matthew/preview-prefill`. Dogfood incident: a
sliding-sync session expiry two seconds into a cold launch (the reinstall
killed the app mid-poll → `UnknownPos`) emptied the home screen's room list
and left it on skeletons forever, while search and static lookups kept
working. Root cause shape: `entries_with_dynamic_adapters` yielded each
filter/sort/head adapter chain into `switch()`, so the chain's death was
unobservable - when its underlying entries stream ended (most plausibly the
eyeball broadcast subscriber lagging out during the post-expiry flood),
nothing rebuilt the chain until the next `set_filter` call, which never
comes for the home screen's fixed filter. Fix: the generator is now a flat
loop that `select!`s between filter changes and chain items; when the chain
ends it rebuilds immediately under the current filter and re-emits a fresh
`Reset`. Filter changes keep the old drop-and-rebuild semantics with
priority over pending diffs. The two previously-silent death sites (merged
raw-stream end, FFI listener task exit) now log `error!` so a recurrence
pinpoints which stream died. Upstreamable; the exact death trigger is still
unproven from logs - the new diagnostics exist to catch it.

## Stale sync batch permanently reordered sent messages (SDK fix)

rust-sdk [`4d97fa38a`](https://github.com/matrix-org/matrix-rust-sdk/commit/4d97fa38a) on `matthew/preview-prefill`, from rageshake 7467.
Dogfood incident on bad connectivity: message 1 was sent from another
device, and while its remote echo crawled towards the phone (23 seconds),
messages 2 and 3 were sent from the phone (their events land in the
timeline instantly: send-response confirmation plus the send queue's eager
event-cache insert). The late long-poll response then delivered the batch
[msg1, msg2] - generated by the server before msg3 existed. The event
cache's dedup removed the known msg2 from its place and re-appended it at
the tail together with the never-seen msg1, moving both past msg3, and
persisted the result: the room showed (and kept showing) 3,1,2,4 while the
server and every other client order 1,2,3,4.

Fix, generalising the earlier tail-duplicates-replaced-in-place rule
(which only handled duplicates forming a batch prefix): known tail events
in a non-gappy sync batch act as *anchors*. They never move (their sync
copy replaces them in place), and unknown events before or between anchors
are inserted where the batch says they belong, right before their
following anchor - so msg1 lands before msg2, which stays before msg3.
Events after the last anchor still append at the back (best guess: they
postdate our eagerly-inserted tail, whose stream position is unknown).
When a batch orders anchors differently from the linked chunk, sync's
ordering is authoritative and the legacy remove+re-append restores it,
which also self-corrects any earlier wrong guess. Regression test
`test_stale_sync_batch_does_not_reorder_the_tail` fails on the old code.
Upstreamable.

## Event cache wedged: every room open stuck on a Loading modal (SDK diagnostics)

rust-sdk [`25ff0e827`](https://github.com/matrix-org/matrix-rust-sdk/commit/25ff0e827) on `matthew/preview-prefill`, from rageshake 7468.
Dogfood incident on bad connectivity: from 13:42:12Z the entire event
cache wedged permanently - the room updates task stopped mid-batch (last
act: a thread-aggregation `find_event` for a room), the backfill queue
worker stopped right after receiving a /messages response, the redecryptor
went silent, `pos` persistence warned forever ("the event cache may be
stalled", target_seq advancing ~1/second while acks never came), and every
room open hung at "building the live timeline" behind the same lock - the
Loading modal on basically any room (now at least cancellable via the
earlier tap-scrim fix). Everything funnels through the event cache's
global `StateLock` (state RwLock + read-upgrade mutex + cross-process
store lock), and that layer logs at trace level only, so the dogfood logs
cannot name the deadlock parties. Ruled out from logs and code: NSE
holding the store lock (idle since 13:24), the read-receipts hunt (fire
and forget), linked-chunk update channel backpressure (broadcast,
non-blocking), and a threads-map/state-lock ABBA (ordering is consistent).

Change: every state-lock guard now registers its holder (the tracing span
current at acquisition, plus age) in a registry, and any acquisition -
upgrade mutex, state RwLock, or store lock - that stalls longer than 10
seconds logs an `error!` with the live-holder snapshot, repeating every
10s and logging resolution if it ever completes. No locking behaviour
changes (pending acquisitions keep their fair-queue position; nothing
times out): a stall stays a bug, now surfaced loudly with names. The next
occurrence identifies the cycle; the real fix follows from that.

## Event cache wedge: candidate lock-contention theories

Companion to the diagnostics entry above ([`25ff0e827`](https://github.com/matrix-org/matrix-rust-sdk/commit/25ff0e827)), so the next
occurrence can be read against the shortlist. Evidence timeline: the
redecryptor went silent at 13:42:06.9Z, the room updates task at
13:42:12.9 (in the threads-aggregation phase, right after a `find_event`),
the backfill worker at 13:42:14.6 (just before applying a /messages
response, i.e. just before its state write), and everything else queued
behind. Ranked candidates:

1. **Redecryptor holding a state guard across crypto work.** Best timing
   fit: it stalled first, exactly while the encryption sync loop had the
   OlmMachine and crypto store busy (keys/claim, to-device batches). If
   any redecryptor path (`on_resolved_utds`, the retry loops,
   `update_encryption_info_for_events`) holds a state guard while calling
   `decrypt_event` / `get_encryption_info` / `push_context`, that one
   held guard plus the backfill worker's queued write is the whole wedge:
   the fair RwLock parks all later readers behind the queued writer. The
   static read suggests the `all_*_events` helpers drop their guards
   before the crypto calls, but not every path was audited.

2. **A nested `read()` while already holding a read guard.** Three-party
   shape: A holds a read guard and calls `read()` again, blocking on the
   upgrade mutex; C holds the mutex inside `read()`, queued behind B's
   pending write; B waits on A's first guard. One nested-read call site
   anywhere suffices, and it also wedges every other `read()` via the
   mutex. None found in the audited paths (aggregator, thread summaries,
   receipts); subscriber/auto-shrink, pinned events, event-focused,
   latest-events and the send queue's eager insert remain unaudited.

3. **Cross-process store lock stalling inside an acquisition.** Every
   state guard also acquires the store lock, and `read()` does so while
   holding the upgrade mutex; a leaked in-process store-lock holder
   presents identically. The NSE variant is ruled out for this incident
   (idle since 13:24, lease would have expired).

4. **Dirty-recovery reload under the write lock.** The unscoped
   (`Ok(None)`) recovery path is log-silent and reloads all ~5.4k rooms
   holding the write lock and upgrade mutex. Weakened because a running
   reload would have emitted store timer lines and none appeared after
   13:42:12.9.

Ruled out from logs or code: threads-map/state ABBA and by_room ordering
(both consistently ordered), the read-receipts hunt (fire-and-forget),
linked-chunk update channel backpressure (broadcast, non-blocking send),
NSE store-lock holding.

The diagnostics distinguish these directly: candidate 1/2 shows as a
long-held `state (read)` naming the owner span; candidate 3 as a stall on
`store (read|write)` with no live holders; candidate 4 as a long-held
`state (read, dirty upgrade)`.

## Event cache wedge SOLVED: nested read in the thread aggregator (SDK fix)

The wedge recurred on 2026-08-14 at 07:05:23Z (permanent Loading modal on
every room open after filtering via search), and this time the phone was
running the holder-attributing stall diagnostics
([`25ff0e827`](https://github.com/matrix-org/matrix-rust-sdk/commit/25ff0e827)).
129 `state lock acquisition is stalled` errors named the parties
immediately, confirming candidate theory 2 (the three-party nested read)
- with the embarrassing footnote that the culprit sat in the one path the
first audit had marked clean.

The snapshot: `state (read) held by handle_room_updates` (for 2569s and
counting), `upgrade mutex (read) held by handle_room_updates` acquired
0.157s later, the main `room_updates_task` itself stalled on `state
(read)`, and backfill `run_request` spans stalled on `state (write)`.

The chain, matched line-by-line against the log:

1. 07:05:23.290 - `Caches::handle_joined_room_update`'s threads section
   acquired the room read guard and passed it **by value** into
   `aggregate_timeline_for_threads`, so the guard lived for the whole
   aggregation. The batch contained a redaction whose target existed in
   the room.
2. 07:05:23.420 - a backfill `/messages` response for
   `!DWnKHhSrAvvbpShXda:fosdem.org` arrived and called `write()`,
   queueing on the write-preferring RwLock behind the held guard.
3. 07:05:23.447 - the aggregator's redaction full-search called
   `ThreadEventCache::find_event`, which re-acquires the same global
   state lock via `read()`. That nested read acquired the upgrade mutex,
   then parked behind the queued writer. Writer waits on the guard; the
   guard's owner is the parked reader. Deadlock, and the held upgrade
   mutex wedges every other `read()` in the process too.

iOS suspending the app mid-catch-up (background refresh expiry at
07:05:23.4) made the window easy to hit, but the race needs no
suspension: any write landing in the ~0.1s between the guard acquisition
and the thread search suffices, which is why it fires on bad-network
catch-up batches (backfill writers are flying) and not in quiet steady
state.

Fix ([`addbff009`](https://github.com/matrix-org/matrix-rust-sdk/commit/addbff009)):
`aggregate_timeline_for_threads` now takes the `CacheStateLock` instead
of a guard, so each room lookup takes a short-lived guard dropped before
the thread search runs. Nothing in the aggregation holds the state lock
across `thread.find_event` any more. All 99 unit + 61 integration event
cache tests green. UPSTREAMABLE, together with the diagnostics that
caught it.

Rule reaffirmed, now with a proven scalp: never acquire the event cache
StateLock (via any per-room/thread/pinned `CacheStateLock` view - they
are all the same lock) while holding any guard on it. The stall
diagnostics stay in the build to name any sibling site instantly.

## StateLock nesting audit: no further deadlock sites, one stall hazard

Following the aggregator fix, a full audit of the event cache for the
same bug class: any code holding a StateLock guard across a call that
(transitively) re-acquires the lock. Method: enumerate every acquisition
site (`read()`/`write()`/`try_insert_once_with`/`clear_and_reload` plus
every helper that wraps one, e.g. `ThreadEventCache::find_event` - the
wrapper that hid the original bug), then inspect every guard-holding
region for calls into that set.

**No other deadlock site exists.** Every guard-across-await region only
touches guard-local state, the store, or non-blocking channel sends:
`handle_sync` and `post_process_new_events` (both run under held write
guards on the sync, send-queue and redecryptor paths) never leave the
guard; the receipts hunt is a fire-and-forget enqueue; redecryptor
decrypts with no guard held and takes short-lived guards per phase;
auto-shrink, subscriber drop (`try_send` capped at 1024 attempts),
pinned-events and both pagination conclude paths are clean. Two places
already defend against exactly this class: thread pagination fetches the
thread root *before* locking (with a comment naming the constraint), and
the pinned listener explicitly drops its guard before
`reload_from_network`. Guards never escape the event_cache module, so
external callers (timeline, send queue, latest-events) cannot construct
the bug. Lock ordering is consistent everywhere: by_room / threads-map /
event_focused-map before the global StateLock, never the reverse.

**One stall (not deadlock) hazard, upstream too:** the event-focused
cache runs its network fetches *under the held global write guard* -
`reload_impl` awaits `/context` inside `start_from`, and
`paginate_backwards`/`paginate_forwards` await `/messages` or
`/relations` the same way (event_focused/mod.rs; `origin/main`
identical). Nothing inside re-acquires the lock, so it cannot wedge, but
on bad network one permalink/focused-timeline open freezes the entire
event cache - every room, sync ingestion, the lot - for up to the HTTP
timeout, presenting as a self-healing flavour of the Loading-modal
symptom. Fix shape is the dance thread pagination already does: fetch
outside the guard, lock to install. Not yet fixed; flagged for a
follow-up round.

## Event-focused network-under-lock stall FIXED (SDK fix)

The stall hazard flagged by the nesting audit is fixed in SDK
[`5f715227a`](https://github.com/matrix-org/matrix-rust-sdk/commit/5f715227a):
the event-focused cache no longer runs any network request under the
global state lock.

What changed, per entry point:

- `start_from` (permalink / focused-timeline open): store hydration and
  input capture happen under a short-lived guard, the `/context` fetch
  runs with no lock held, then a fresh guard installs the response
  (`install_context_response`, the old `reload_impl` tail).
- `paginate_backwards` / `paginate_forwards`: capture the gap token and
  pagination mode under a short read guard, fetch `/messages` or
  `/relations` unlocked, then re-acquire and install. The install
  verifies the gap it paginated from is still in place (a concurrent
  pagination or a reload may have consumed it) and drops the response
  otherwise - the same conclude dance room pagination does.
- Recovery `reload` never touches the network any more. It used to
  refetch `/context` under the reloadable write guard during dirty
  recovery, where a network error also aborted the whole recovery via
  `?`. A dirty store cannot invalidate this in-memory cache, so ForgetAll
  now resets the chunk and plain recovery keeps the snapshot. The
  `initial_num_context_events` and `thread_mode` state fields existed
  only to serve that refetch and are deleted.

All event cache tests green (99 unit + 61 integration) plus the 8
focused-timeline integration tests in matrix-sdk-ui. UPSTREAMABLE (the
hazard is on origin/main verbatim).

Known remaining ceiling, deliberately left: the per-room event-focused
map write guard is still held across `start_from` during cache creation
(Caches::event_focused). That blocks only same-room focused opens and
redecryptor sweeps for the fetch duration, not the global lock; fixing
it needs a started-flag or two-phase insert, not worth it until it shows
up in practice.

## Vanished sent message in !FBSk: collateral of the StateLock wedge, no new bug

Report: sent message `$178662887510241ftaZv` (13:47:55Z 2026-08-13,
room !FBSkLwrSkdSBBXWHUj:matrix.org) disappeared entirely from the EXI
timeline, reappearing only after a later timeline reload.

Log forensics gotcha first: the "EXI" console logs supplied for this bug
(and one of yesterday's downloads) were actually the **Nightly** app's
log - three separate downloads were byte-identical (same md5) and
contained Nightly's `$ilx` send. Confirmed by pulling Nightly's own log
straight off the phone via devicectl
(`--domain-identifier group.io.element.nightly`, path
`Library/Logs/io.element.elementx.nightly/`). The dogfood evidence came
from rageshake 7468's copy of `console.2026-08-13-16.log`, which covers
13:00:04-13:46:52Z; the on-device originals for hours 16-17 have rotated
away.

Not a wrong-client send this time, and no new bug. The chain, from
rageshake 7468's log:

1. 13:42:08-13:42:10 - three sends to !FBSk succeed; each is followed by
   its eager-insert persistence
   (`handle_linked_chunk_updates{Room(!FBSk)}`). Healthy.
2. 13:42:12.899 - the event cache StateLock wedge begins (this IS the
   rageshake 7468 deadlock, root-caused since as the thread-aggregator
   nested read and fixed in
   [`addbff009`](https://github.com/matrix-org/matrix-rust-sdk/commit/addbff009));
   pos-persist stall WARNs from 13:42:37.
3. 13:44:36 - another !FBSk send succeeds ("Sent event in room") but NO
   !FBSk persistence ever follows: the send queue's eager insert calls
   `state.write()` and parks forever on the wedged lock. By design the
   queue continues anyway (the insert is "not crucial"), and crucially
   `mark_as_sent` has already durably removed the queue entry, so
   nothing will retry the insert after restart.
4. 13:44:51 and 13:45:34 - two more messages queued ("Finished sending
   message"); their PUTs crawl out over the dying network and one is
   accepted server-side at 13:47:55 = the vanished event (the log copy
   ends 13:46:52, before the success line).
5. After the app restart cleared the wedge, the event existed nowhere
   locally: never eager-inserted, never synced (the room's next syncs
   were limited+gappy, so it sat behind a gap). Timeline shows it
   gone. It reappeared once a reload/back-pagination filled the gap.

So the vanish is pure collateral of the (now fixed) deadlock, amplified
by the mark-as-sent-before-eager-insert ordering, which converts "event
cache unavailable at send time" into "sent event absent from local
timeline until backfill". With the deadlock fixed the window is gone;
the ordering is upstream's design (the eager insert is best-effort by
intent), so no change made.

## Thread root shows a permanent loading skeleton instead of its thread summary (SDK fix)

Report (2026-08-14 ~17:20Z, Techteam Internal): tapping the room in the
room list (whose latest activity was in a thread) opened the main
timeline, and the thread root rendered EXI's redacted-placeholder
thread-summary pill (the "skeleton") indefinitely instead of "N replies
+ latest reply preview". Note the first half of that report is expected
behaviour today: a room-list tap always opens the room, and the thread
is reached via the summary pill, which makes a skeleton pill doubly
useless.

Diagnosis (hour-20 console log pulled off the phone; the user's .gz
download was truncated to 556 bytes):

1. EXI renders the skeleton whenever `TimelineItemThreadSummary` is not
   `.loaded`; `.notLoaded` maps from the SDK's
   `TimelineDetails::Unavailable`, which the timeline produces when the
   `ThreadSummary` has `latest_reply: None` (a failed load would log
   "Failed to load thread latest event"; the log has none).
2. `compute_thread_summary` finds the latest reply by scanning the
   in-memory thread linked chunk with the latest-events filter (which
   rejects reactions/edits/redactions), but counts `num_replies` from
   the store's relations. The two can disagree.
3. At 17:18:12 the thread cache for the root was created fresh (empty
   store: `try_insert_once_with > load_last_chunk` found nothing) by a
   sync whose only in-thread event was an aggregation (a reaction to
   the user's reply, routed by the aggregator's Annotation branch). The
   log proves the scan found nothing: each episode shows exactly ONE
   `find_event_relations` (the num_replies count) and no edit-check
   lookups, which only happens when `latest_event_id` is `None`.
4. Result: summary `{num_replies: N, latest_reply: None}` persisted
   onto the root event; every timeline build renders it as the eternal
   skeleton. Nothing ever heals it (the thread chunk stays
   aggregation-only until the thread is opened or a real reply
   arrives). Same episode repeated at 17:20:54.

The bug is UPSTREAM: `thread/state.rs` is byte-identical to
origin/main; the same shape also fires without a fresh cache, via the
limited-sync shrink (`handle_sync` shrinks the thread chunk to its last
chunk, which can be a lone reaction).

Fix (SDK
[`5a4990bc3`](https://github.com/matrix-org/matrix-rust-sdk/commit/5a4990bc3),
pushed): when the in-memory scan finds no suitable event, fall back to
the thread replies already fetched from the store for `num_replies` and
pick the newest suitable one by `origin_server_ts`. Regression test
reproduces the limited-sync shrink shape (red before, green after); all
62 + 99 event cache tests green.

Caveat for validation: the bad summary is PERSISTED on this thread's
root, and the fix only recomputes on the next thread activity. So the
Techteam Internal root may still show the skeleton after updating until
someone reacts/replies in that thread (or cache is cleared); any NEW
occurrence of the shape is what would indicate the fix failed.

Upstream queue: add `5a4990bc3` alongside `4d97fa38a`, `25ff0e827`,
`addbff009`, `5f715227a`.

## OPEN: own send vanishes when a catch-up shrink lands mid-send (Self room, 2026-08-14 21:04Z)

Repro (screen recording + hour-00 log in scratchpad/vanish2): three
identical `/me` sends to !ZBAy (Self) at 21:04:34 ($LwBCw), 21:04:41
($OFAzx) and 21:06:00 ($AgqKj), during the tail of the clear-cache
catch-up. End state: $OFAzx accepted server-side but absent from the
timeline; at the video's end it was $LwBCw that was missing and $OFAzx
visible (read receipts targeted $OFAzx until 21:05:48), so the two
swapped at some point - a poison/heal dance, not a clean drop.

Established from the log:

1. ALL THREE sends (plus one in !Kzal) completed into "Timeline item
   not found, can't update send state ... remote_item_exists=false":
   the local echo item was destroyed before each send finished.
2. The killer for send 2: a limited+gappy sync for !ZBAy landed at
   21:04:41.489 (filter_duplicated_events → shrink_to_last_reloaded_chunk),
   BETWEEN the local echo PushBack (41.367) and the send completing
   (42.83). The timeline was mass-rebuilt (14 removes + 21 inserts,
   16 → 24 items) and the local echo did not survive.
3. Each send's eager insert DID persist
   (handle_linked_chunk_updates{Room(!ZBAy)} after each "Sent event"),
   and surfaced in the timeline as a bare Set(last-index) rather than an
   append - after the rebuild those indices don't correspond to what the
   handler believes, which is the leading theory for how one own-message
   item ends up overwriting another's.
4. The 6532fc2be stale-batch guard fired correctly at 21:04:50
   ("Ignoring a stale sync batch", batch_len=1) - this new loss is a
   DIFFERENT window in the same limited-sync-collapse family.
5. Sync redeliveries at 21:05:04 and 21:06:19 each produced a lone
   Set(last-index) on the live timeline.

Next steps: deterministic repro as a matrix-sdk-ui integration test
(local echo + limited gappy sync with shrink mid-send + mark_as_sent),
then bisect the Set-index path (live_update_handler position mapping
after a shrink rebuild). Store state believed to contain all three
events; awaiting post-restart visual check to split store-level vs
timeline-level loss.

## Vanished mid-send message ROOT-CAUSED + FIXED: stale-batch guard ate the stranded event's echo (SDK fix)

Resolution of the OPEN entry above, via the CHUNKDUMP diagnostics (SDK
62f1f2522) - no repro needed, the persisted store state was read
directly off the phone on one room-open:

```
chunk 4: GAP          chunk 3: []          chunk 2: [$LwBCw]  <- send 1, stranded
chunk 5: GAP          chunk 6: [20 events all <=18:32Z, $OFAzx, $AgqKj]
```

So the missing message was SEND 1 ($LwBCw), not send 2 - with identical
bodies the eye can't tell. Mechanism, each step now log-proven:

1. 21:04:35 send 1 eager-appends $LwBCw to the live tail.
2. 21:04:41 a stale limited+gappy sync (its ~20 events all predate
   18:32Z, and not all were known, so no guard applied) takes the legacy
   dedup path: appends [GAP][batch] after $LwBCw, and the shrink
   collapses memory to the batch chunk. $LwBCw is stranded behind the
   gap, offloaded to the store, in the wrong causal order.
3. 21:04:50 the server's late echo of $LwBCw arrives as a lone batch -
   the exact information that would restore it to the live tail - and
   the 6532fc2be stale-batch guard eats it: "all events known" (the
   stranded copy) "and lacking the tail". Permanent invisibility,
   surviving restarts.

Fix (SDK cbf7545bc, pushed): the guard now requires the known copies to
all live IN MEMORY (the live tail). A store-resident copy means a
stranded event, and the batch takes the legacy dedup path, pulling the
event back to the tail. Regression test red-before/green-after; 63+99
event cache tests green. The 21:04:41-window incident (test
test_late_echo_of_a_stranded_event_is_not_treated_as_stale) needs the
sender to be the OWN user: foreign fully-known batches are dropped
earlier by non_empty_all_duplicates.

Residuals (deliberate, journal for upstream):
- The stranding itself still happens transiently; the echo now heals it
  within seconds. The deeper fix - inserting a stale gap+batch BEFORE
  the eager tail suffix rather than after it - is an upstream
  discussion.
- The heal appends the event at the tail, which can leave a cosmetic
  misorder (send 1 after send 2) until server order is re-asserted.
- non_empty_all_duplicates has the same theoretical hole for stranded
  FOREIGN events; unreachable via the send queue, upstream discussion.
- The Self room's $LwBCw remains stranded on the phone (its echo was
  already eaten pre-fix; the server won't re-send it): clear cache to
  fully heal that one room, or ignore it.

The "Timeline item not found, can't update send state" WARNs firing on
EVERY send remain unexplained-but-benign in this incident (likely a
stale second Timeline instance; the FFI diff log now carries room +
instance markers to pin that down next time).

## Eager-tail relocation: the stranding itself is now fixed, not just healed (SDK fix)

Follow-up to the two entries above, closing the vanished-send incident
at both ends. The transient residual - a stale gappy batch stranding
our just-sent events behind its gap until the sync echo heals them - is
an UPSTREAM flaw (their legacy path + shrink; our buggy 6532fc2be only
made it permanent). Fixed at the source (SDK
[`7fad14efb`](https://github.com/matrix-org/matrix-rust-sdk/commit/7fad14efb),
pushed): in the legacy gappy path, identify the eager tail suffix
conservatively (maximal trailing run of OWN events, absent from the
batch, strictly newer by origin_server_ts than every batch event), pull
it out, append the gap+batch, re-append the suffix at the new tail. The
room stays [batch..., our sends]: no invisibility window, no misorder,
and the later echo dedups in place as an anchor. Anything the rule
doesn't confidently claim stays put and falls back to the cbf7545bc
echo-heal.

Regression test red-before/green-after
(test_gappy_stale_batch_does_not_strand_our_eager_tail); the echo-heal
and reorder tests still green; 64+99 event cache tests green.

Upstream arc for this family is now: 4d97fa38a (anchored merge) +
6532fc2be (stale-batch guard, ONLY together with) + cbf7545bc (guard
narrowing) + 7fad14efb (suffix relocation) + the diagnostics-strip.

## Room-list taps route into threads through edits + threaded-preview icon (VALIDATED)

Two related pieces, user-validated 2026-08-15:

1. The room-list tap-to-thread routing (opens the thread when the
   room's latest event is a threaded reply) silently broke when that
   reply was EDITED: the latest-event value becomes the edit event,
   whose relation is m.replace, so latest_event_thread_root_id saw no
   thread. Fixed in the SDK
   ([`b69d40ecd`](https://github.com/matrix-org/matrix-rust-sdk/commit/b69d40ecd)):
   the UI latest-event value now carries a resolved thread_root - read
   off the event itself or, for an edit, off the edited original looked
   up in the event cache (no network) - and the FFI
   latestEventThreadRootID became async to do the same resolution.
   Regression test covers both the direct and the edit case.
2. Room-list rows now show a Compound threads icon before the message
   preview when the previewed event lives in a thread (matching Element
   Web), piped via thread_root_event_id on the room summary's latest
   event. Position user-tuned: vertically centred on the first line's
   capitals, nudged 1pt down (EXI
   [`51e1d46b0`](https://github.com/element-hq/element-x-ios/commit/51e1d46b0)
   + [`a85914f67`](https://github.com/element-hq/element-x-ios/commit/a85914f67)).

Both validated on the phone. The routing feature itself plus this
resolution are candidates for upstreaming with the thread work.

## Reply previews sometimes show raw mxids instead of sender names (FIXED, SDK)

User report 2026-08-15 (no logs needed - fully explainable from code):
the quoted-sender line in a reply preview sometimes shows the raw
@user:server instead of their display name. Audit found the embedded
sender profile is a ONE-SHOT SNAPSHOT that nothing ever heals:

- Built either by copying the replied-to item's profile as it was at
  that instant (`InReplyToDetails::new`), or store-only via
  `get_member_no_sync` for out-of-timeline targets
  (`EmbeddedEvent::try_from_timeline_event`). During the room-open
  window (`/members` still in flight, lazy-loaded member lists, fresh
  cache) that snapshot is Unavailable/Pending.
- The heal sweeps (`update_missing_sender_profiles` after `/members`,
  `force_update_sender_profiles` on member changes) only replaced the
  item's top-level `sender_profile` and never descended into
  `content.in_reply_to`.
- `fetch_in_reply_to_details` early-returns once the details are Ready,
  and EXI only refetches on notLoaded/error - so
  content-loaded-with-mxid was a terminal state until timeline rebuild
  (why it "sometimes" self-fixed on reopen).

UPSTREAM bug (matrix-sdk-ui, untouched by our branches). Fixed in SDK
([`f6e0cba3a`](https://github.com/matrix-org/matrix-rust-sdk/commit/f6e0cba3a)):
both profile sweeps now also refresh the embedded reply sender profile
through a shared helper - the missing sweep fills any non-ready
embedded profile, the force sweep re-resolves embedded profiles for
changed senders. Regression test
(`test_reply_preview_sender_profile_updates_when_members_load`) red
before / green after. Add to the upstream queue.

## Accepted invite lingers in the room list (FIXED, SDK, upstream bug)

User report 2026-08-15 (no logs - root-caused by audit): hitting Accept
on a room-list invite leaves the invite row hanging around for a while,
even after the room has been joined and opened. Chain audited end to
end; every local link was sound:

- `/join` success marks the room Joined locally (`room_joined`,
  base client) and emits a MEMBERSHIP notable update; the room-list
  merge stream re-emits a Set diff; EXI rebuilds the summary from live
  state. The row should flip within milliseconds.
- The culprit is the sliding-sync processor
  (`response_processors/room/msc4186`): any response carrying
  `invite_state` did `mark_as_invited()` with an explicit "override the
  room state if the room already exists". A long-poll IN FLIGHT when
  Accept was tapped - generated pre-join - lands post-join and
  regresses Joined back to Invited. The row resurrects until a later
  response re-delivers the room as joined.
- `awaitRoomRemoteEcho` doesn't help: it returns on "partially
  synced", which the local mark itself sets, so EXI's post-join wait is
  satisfied instantly and the whole stale window is user-visible. Our
  viewport-subscriptions conn (second SSS connection) widens the window
  further. Declining has the mirror hole: a stale response resurrects
  the declined invite as Left flips back to Invited.

Same stale-long-poll family as the event-cache bugs (stale gappy
batches). UPSTREAM flaw. Fixed in SDK
([`f7161bf4b`](https://github.com/matrix-org/matrix-rust-sdk/commit/f7161bf4b)):
in-memory `membership_from_local_action` marker on RoomInfo, set by
`room_joined`/`room_left`; while set, the processor ignores
`invite_state` for the room (state kept, stripped-state dispatch and
its re-notification skipped); cleared by the action's sync echo or any
genuinely honoured invite/knock. Not persisted deliberately (restart
clears; persisting could suppress a genuine re-invite). Known ceiling:
multi-conn stale response arriving after another conn's echo cleared
the marker can still flicker briefly (self-heals); sync v2 has the same
theoretical hole, untouched. Two regression tests (accept + decline),
red before / green after. Add to the upstream queue.

## Formatted room previews (quotes stripped / plaintext previews FIXED, EXI)

User report 2026-08-16: room-list previews showed "a plaintext view of
the rendered markdown" - quotes lost their markers entirely, bold
didn't render. Decision: base previews on the HTML representation
(formatted_body), falling back to plaintext body when absent, and
render the subset a two-line Text can represent - native inline
styling, markdown-style markers for blocks.

Root causes (EXI
[`1a3a97317`](https://github.com/element-hq/element-x-ios/commit/1a3a97317)):
1. `RoomMessageEventStringBuilder.prefix()` rebuilt the summary from
   its plain `.string` to avoid tappable links, stripping ALL
   formatting. Now preserves attributes, drops only `.link`.
2. Nothing re-inserted block semantics on flattening. New
   `flattenedForPreview()` (AttributedString extension): "> " on every
   quoted line, font→presentation-intent conversion (bold/italic/code
   render at the row's own size + Dynamic Type),
   strikethrough/underline remapped from UIKit to SwiftUI attributes,
   consecutive newlines collapsed. Applies to all flattened surfaces
   sharing the builder: room list, notifications (NSE), thread list,
   pinned banner.

Bycatch - two parser regressions from the list-indent fix (`550a6467d`),
caught once the unit tests could run again:
- SwiftSoup classes del/ins/s as BLOCK tags, so the inter-element
  whitespace drop ate real spaces around strikethrough. Explicit
  block-tag list now.
- Adjacent blockquotes coalesced into one run = grouped quotes rendered
  as a single quote box in the timeline (`multipleGroupedBlockquotes`
  red). Unattributed "\n" separator between adjacent quotes; the
  separated-quotes case is unaffected (only inter-element whitespace is
  skipped when checking adjacency).

Also unblocked the branch's unit tests: the xcframework now builds with
a simulator slice (build-xcframework.sh unchanged; both-targets build
done manually - consider making it the default), and
ComposerToolbarViewModelTests' sendMessage patterns were missing the
new fifth associated value, crashing the compiler and taking the whole
UnitTests target down (`fedf3ae3d`).

STRIP/RERECORD pre-upstream: FormattedBodyText preview snapshots
(grouped blockquotes now render correctly as separate boxes).

## Quote-reply bubble mangled + reply fallbacks in previews (FIXED, EXI)

Regression report 2026-08-16 (dogfood validation of the previews arc):
`> test` / blank / `test` rendered with BOTH lines quote-barred and the
timestamp overlapping the second line. Root cause was latent, not the
new parsing: `formattedComponents` used each component's TEXT as its
Identifiable id, so quote("test") + plain("test") shared an identity
and FormattedBodyText's ForEach rendered identity soup. The
inter-element whitespace that used to leak between components (" test"
vs "test") masked the collision; `1a3a97317`'s whitespace fix exposed
it. Nightly still leaks the whitespace, which is also why its quote bar
over-extends below the quoted line (stray blank line inside the quote
box) - our branch renders that part correctly now. Fix (EXI
[`5ccc92263`](https://github.com/element-hq/element-x-ios/commit/5ccc92263)):
component ids carry their position; the timestamp-reservation component
gets a sentinel id instead of "".

Same commit, per user request: previews strip reply fallbacks entirely
- `<mx-reply>` blocks from formatted bodies, and leading
`> <@user:server> ...` lines (to the first blank line) from plain-text
bodies, gated on the `> <` signature so genuine markdown quotes keep
their `> ` preview marker. Regression tests for id uniqueness, both
fallback paths, and the genuine-quote guard.

## Nested blockquotes rendered flat (FIXED, EXI)

Dogfood round 3 on the previews arc, 2026-08-16: `> > test` inside an
outer quote rendered identically to the outer quote - one uniform box,
unlike GFM/EW. The blockquote attribute was a Bool, so nesting was
flattened at parse time. Fixed (EXI
[`fcf00a121`](https://github.com/element-hq/element-x-ios/commit/fcf00a121)):
the attribute now carries nesting depth (each blockquote level
increments what the recursion below produced), `formattedComponents`
split per depth (`.blockquote(depth:)`), BlockquoteView draws one bar
per level with matching indent, previews repeat the `> ` marker per
depth. Known approximation: the flat component stack draws the outer
bar per-component rather than spanning the whole outer quote as EW
does; good enough until the component model grows nesting. Tests:
component depths + preview markers for the nested fixture.

## Tree-shaped block components (FIXED, EXI)

Round 4 on the previews/formatting arc, 2026-08-16: the flat component
model's composition defects (code blocks inside quotes losing their
box, quotes inside list items detaching from their bullet, and the
fragmented quote spine) fixed by restructuring `formattedComponents`
into a TREE (EXI
[`76a39ee07`](https://github.com/element-hq/element-x-ios/commit/76a39ee07)):

- Stack machine over the SAME attribute runs (a quoted code block's run
  already carries both attributes; the flat splitter just discarded the
  composition). Blockquote components hold `children`; BlockquoteView
  recurses, so nested quotes draw their bar inside the parent's
  SPANNING bar (supersedes the depth-count bars from `fcf00a121`) and
  code blocks render as real boxes within quotes.
- New `ListIndent` attribute set ONLY on block ranges inside `<li>`
  (list text keeps literal indentation - attributing it would split
  runs and change unrelated rendering); block components indent
  16pt/level under their bullet.
- Quote components keep aggregate content in `attributedString` (a11y +
  test compat); separator runs reduce to nothing instead of surfacing
  as empty components (grouped-quotes component count 5 → 3).
- Gotcha: inside the parser's `li` case, `indentLevel` is already the
  list nesting level (ul/ol increments before recursing).

Tests: nested-quote tree shape, code-block-in-quote, quote-in-list
(+updated legacy component-count expectations). Preview flatten path
(runs-based) unchanged. Snapshots still need re-recording pre-upstream.

## Change role from the member sheet (NEW FEATURE, EXI)

2026-08-16, implements
[element-meta#3028](https://github.com/element-hq/element-meta/issues/3028)
(deferred upstream as a new feature, implemented here on request): the
manage-member bottom sheet (tap a sender avatar / member-list row) gains
a Role row (EXI
[`e8458da2b`](https://github.com/element-hq/element-x-ios/commit/e8458da2b)):

- The role is ALWAYS shown when non-default (Moderator/Admin/Owner),
  read-only trailing text if you can't act on it (user refinement over
  the issue's AC).
- It becomes a Compound `.picker` row (same idiom as Settings →
  Advanced → Appearance; native menu when expanded) when you can send
  `m.room.power_levels` AND outrank the member. Options are every role
  up to your own power level, so admins can mint admins (with the
  Roles & permissions screen's irreversible "Add Admin?" warning) and
  owners/creators can transfer ownership (same transfer warning).
  Apply path is the same `updatePowerLevelsForUsers` +
  info-echo-then-`updateMembers` dance as RoomChangeRolesScreen, then
  the sheet dismisses; cancelling a warning reverts the picker.
- Permission plumbing: `canOwnUserEditRolesAndPermissions()` threaded
  through both sheet construction sites (member list + timeline).

Follow-up (user request, same day): own user no longer special-cased
straight to "view profile" from the member list - it presents the same
sheet for symmetry (EXI
[`8edfdf132`](https://github.com/element-hq/element-x-ios/commit/8edfdf132)):
since you can only demote yourself, the role row opens the Roles &
permissions screen's "Change my role" vertical-buttons dialog instead
of the picker (demote to moderator/member, filtered to roles below your
own); "Remove user" skips the power-level comparison for self (removing
yourself is just leaving) while self-ban stays disabled (matches the
`target < sender` ban auth rule). Regular-member self shows no role row
(nothing to demote to). Creators show read-only Owner.

Tests: 10 sheet suite tests (visibility/editability gating incl. self,
plain demotion, add-admin warning flow, cancel-reverts-picker,
self-demote dialog, self-regular hides row) + member-list self-tap now
expects the sheet. Three new previews (Editable Role / Read Only Role /
Own User) - FormattedBodyText + these need the same snapshot re-record
before upstreaming. Open question inherited from the issue: promoting
to owner is offered to owners/creators here (the Roles & permissions
screens only reach admin/moderator modes today).

Affordance follow-up ([`3ba795880`](https://github.com/element-hq/element-x-ios/commit/3ba795880)): the own-user role row
gained the picker rows' up/down chevrons glyph so it reads as tappable.

## Gappy timelines: cached content always visible (SDK + EXI, `matthew/gappy-timelines`)

Implements how-hard-can-it-be-2025#115 / element-x-ios#3872, landing the
ideas from Hywan's `feat-ui-timeline-with-gaps` hackathon branch as a
fresh port onto `matthew/preview-prefill` (his merge-base predates the
event-cache `caches/` restructure, so nothing was cherry-pickable).
Branches: rust-sdk `matthew/gappy-timelines` (off preview-prefill, 4
commits) and EXI `matthew/gappy-timelines` (off preview-prefill).

The idea: a live timeline should never block on the network to show
what's already cached. Back-pagination now (opt-in) walks the storage
only, straight past gaps; each gap becomes an inline timeline item
rendered as a small spinner (same look as the top pagination spinner),
and is resolved with a single `/messages` request when it becomes
visible. Offline you see everything that's cached with spinners marking
the holes; online the spinners fill in and disappear.

SDK design (differs from the hackathon branch deliberately):

- `RoomEventCacheUpdate::UpdateTimelineGaps` carries a full snapshot of
  `TimelineGap { prev_token, following_event_id }` (the event after the
  gap anchors it). Snapshot-and-reconcile replaces Hywan's
  prepend/resolve event pair, which couldn't represent mid-timeline
  gaps (`events / gap / events`), i.e. the exact offline scenario. The
  state change-detects (`take_timeline_gaps_update`) so unchanged sets
  are never re-sent; trailing gaps (nothing after them) aren't reported.
- `RoomPagination::run_backwards_once_from_storage`: storage-only
  pagination mode; the historical storage-then-network mode is untouched
  (the BackPaginationQueue keeps using it), and purely legacy flows
  never see gap updates (guarded on "observers already believe in
  gaps"), so the update chatter for old consumers is zero.
- `RoomEventCache::resolve_gap(prev_token, batch_size)`: the network
  path, reusing the hardened `conclude_backwards_pagination_from_network`
  (dedup + dead-end-gap guard + stale-token check) with an in-flight
  token set so UI retriggers dedupe, plus a cheap pre-check that skips
  the request when the token is unknown.
- Timeline: `VirtualTimelineItem::Gap` items are reconciled against the
  latest snapshot at the end of *every* state transaction (so events
  landing around a gap re-anchor it in the same atomic diff batch), with
  a fast path that avoids no-op remove/insert churn. Items keep their
  identity across moves. TimelineStart is suppressed while a gap leads
  the timeline (storage exhausted != room start seen). All opt-in via
  `TimelineBuilder::with_storage_only_pagination`, which EXI enables for
  the live and media timelines only.

Tests (all green): 3 in-crate storage tests (snapshot anchoring,
walk-past-gap without network, stop-at-leading-gap), 2 wiremock
integration tests (limited-sync gap surfaced by storage pagination;
full+partial+stale resolve_gap cycle), 5 timeline unit tests
(anchoring, re-anchor with stable identity, removal, deferred anchor,
TimelineStart guard), plus the full pre-existing event-cache and
timeline suites (only two tests needed updating for the new update
type, both asserting it explicitly now).

EXI side: `GapRoomTimelineItem` renders as `ProgressView` via
`GapRoomTimelineView`, firing `.resolveGap(prevToken:)` on appear (SDK
dedupes repeats; failures leave the spinner, retried on next appear).
The inverted table view keeps content below a resolving gap stationary
for free (insertions above the anchor push older content up), and the
scroll-anchor helper now skips gap cells (and actually skips pagination
indicators, fixing an always-false `is` check). Media & Files keeps gap
items in both modes as spinner cells that resolve on appear, so the
grid shows all cached media fast with spinners for the holes.

Issue-thread notes worth keeping (element-x-ios#3872): bnjbvr wants an
"offline, content may be missing" hint rather than an eternally
spinning gap when there's no network - follow-up, we render the plain
spinner for now; design (mxandreas) leans towards a subtler
Slack-style placeholder, same treatment for top-of-timeline and
mid-timeline; and bnjbvr's technical caveat that mid-timeline gaps
stress related-event ordering (aggregations arriving across gap
boundaries) - the aggregations machinery has ordering support now, but
watch for misattached edits/reactions around freshly resolved gaps
while dogfooding.

### Dogfood round 2 (2026-08-16): adjacent spinners, stalls, pops

First real-world round (matrix.org HQ room) surfaced three issues, all
fixed:

- **Two adjacent spinners** - two gap chunks with no rendered event
  between them (limited sync whose events all deduplicated away, or
  followers filtered out of the timeline) each rendered a spinner. SDK
  `reconcile_gap_items` now collapses each run of gaps sharing an
  anchor down to its newest member; resolving it either closes it or
  lands events between the gaps, at which point survivors re-anchor
  and render in turn (d88bbf2a0 + regression test).
- **Stalled index after backgrounding** - a resolution killed mid-flight
  (bg the app, network error) never retried: the spinner's `onAppear`
  had already fired and nothing re-requested it, with no user
  affordance to kick it. Both gap views (room timeline + Media & Files)
  now re-send `.resolveGap` every 2s while the spinner is visible via a
  `.task` loop (idempotent thanks to SDK in-flight dedupe + cheap
  unknown-token pre-check) (EXI 0c0c33ed2).
- **Timeline pop on resolution** - the gap's spinner row swapped for the
  fetched events in an unanimated snapshot apply. When a *visible* gap
  disappears from the snapshot, the apply now runs animated (100ms
  ease-out, `.fade` row animation) so neighbours close the slot and the
  spinner reads as shrinking away (EXI 1d478a346).

Open caveat spotted while reviewing: a room with cached text history
but *no cached media* shows the Media & Files empty state ("endReached"
from the storage walk + gaps unanchored because no media item exists to
anchor before), even though the server has media in the gaps. Needs a
design think - maybe render unanchored/trailing gaps at the list end,
or fall back to network pagination when the filtered timeline is empty.

Round 2 addendum: off-screen gap resolution jumped the visible timeline
(flipped table = offsets measured from the newest end, so newer-side
insertions shift everything; also skewed paginateIfNeeded's thresholds).
Fixed by pinning the newest visible item across unanimated gap-resolve
applies, reusing snapshotLayout/restoreLayout (EXI, after 1d478a346).

Round 2 addendum 2: scroll-back spasms at the top of the room
(user recording, spasms at 10.5s/12.86s matching "Finished resolving
timeline gap" log lines exactly): a resolution's inserted events make
adjacent "N room changes" groups regroup under new identities, so the
animated .fade apply cross-faded half the screen mid-scroll. Now a
resolution only animates when the spinner is the sole visible casualty;
churny applies go unanimated + pinned, and group items are no longer
used as the layout anchor (identity unstable). EXI 25291a7be.

Round 2 addendum 3: second recording (spasm at 4.56s) showed a tall
single-message resolve at the viewport top spasming WITHOUT identity
churn - animating any content-inserting apply near the viewport is
inherently messy in the flipped table. Final policy (EXI 912c06177):
animate only resolves that close EMPTY (pure spinner removal - the true
shrink-away); all content-inserting resolves apply unanimated with the
visible content pinned. Pin now adjusts bounds.origin directly instead
of scrollToRow, so it no longer cancels an in-flight fling.

### Gappy timelines: merged into preview-prefill (2026-08-16)

Round-2 fixes user-validated on the phone ("feels great"). Both
`matthew/gappy-timelines` branches fast-forward-merged into
`matthew/preview-prefill` (SDK f7161bf4b..d88bbf2a0, EXI
6f3b3249d..2e5e05436) and pushed; gappy-timelines branches retired
(same commits, kept for the upstream PR split). Final behaviour, for
the record: gaps render as inline spinners that resolve while visible
(2s idempotent retry loop, so backgrounding/network failures self-heal);
adjacent same-anchor gaps collapse to their newest member; a resolve
that closes EMPTY animates away (100ms ease-out), any resolve that
inserts content applies unanimated with the viewport pinned via a
momentum-preserving bounds.origin adjustment; group items are never
scroll anchors. Storage-only pagination stays scoped to the live and
Media & Files timelines. Open follow-ups tracked above: media-less
cached rooms show a false Media & Files empty state (needs design);
offline "content missing" hint; Slack-style placeholder design;
aggregations-across-gaps watch.

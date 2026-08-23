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
  (SDK [`4366a2e7b`](https://github.com/matrix-org/matrix-rust-sdk/commit/4366a2e7b))
  - fixes [#1713 Redactions don't local echo](https://github.com/element-hq/element-x-ios/issues/1713)
  - broke `test_redact_message`/`test_redact_local_sent_message` (they asserted the
    old direct-HTTP shapes, and the queued redaction raced test teardown); re-mocked
    for the local-echo semantics in
    SDK [`a0dbb30ba`](https://github.com/matrix-org/matrix-rust-sdk/commit/a0dbb30ba)
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
  (SDK [`830f3dc0e`](https://github.com/matrix-org/matrix-rust-sdk/commit/830f3dc0e))
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
  (SDK [`92950c9f3`](https://github.com/matrix-org/matrix-rust-sdk/commit/92950c9f3))
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
  (SDK [`9a7707b37`](https://github.com/matrix-org/matrix-rust-sdk/commit/9a7707b37))
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
  (SDK [`b10561742`](https://github.com/matrix-org/matrix-rust-sdk/commit/b10561742),
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
  (SDK [`0ba9d0d9d`](https://github.com/matrix-org/matrix-rust-sdk/commit/0ba9d0d9d))
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
    SDK [`84c47e013`](https://github.com/matrix-org/matrix-rust-sdk/commit/84c47e013)
  - With that fixed, the handler still wedged 70s+ inside "Re-triggering
    missing latest event computations": a catch-up response registering
    hundreds of rooms enqueues as many computations, and the trigger loop
    awaited each room's lock under the `position` lock, convoying behind the
    compute task. It now `try_read`s and enqueues busy rooms unconditionally
    (recomputing an existing value is idempotent; the check only avoids queue
    spam).
    SDK [`19e852a81`](https://github.com/matrix-org/matrix-rust-sdk/commit/19e852a81)
  - The plain room route's loading modal was uncancellable (only event routes
    wired up tap-to-cancel), so a wedged open locked the whole app. All four
    routes through `handleRoomRoute` (room, thread, event, share) now track
    their in-flight task and a tap on the modal's background abandons it.
    EXI [`49f379d51`](https://github.com/element-hq/element-x-ios/commit/49f379d51)
- The room-open path now logs every await boundary (resolve proxy, fetch
  room, fetch room info, build live timeline, room-list/timeline
  subscriptions) so any future silent hang names its stuck await in the
  rageshake.
  EXI [`5c868e39c`](https://github.com/element-hq/element-x-ios/commit/5c868e39c)
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
  (SDK [`17af054e3`](https://github.com/matrix-org/matrix-rust-sdk/commit/17af054e3)).
  Events fetched over `/event` are now saved into the event cache too: reply targets
  used to be refetched over the network on every item rebuild (a ~10s skeleton while
  matrix.org served a cold 2023 event) and, being invisible to the redecryptor, never
  resolved in place when their key arrived from backup
  (SDK [`4b23e1d77`](https://github.com/matrix-org/matrix-rust-sdk/commit/4b23e1d77);
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
  (SDK [`9a24a6a76`](https://github.com/matrix-org/matrix-rust-sdk/commit/9a24a6a76))
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
  (SDK [`4eed9b8a2`](https://github.com/matrix-org/matrix-rust-sdk/commit/4eed9b8a2))
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
  (SDK [`4a3906914`](https://github.com/matrix-org/matrix-rust-sdk/commit/4a3906914))
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
  (SDK [`f5d631a4a`](https://github.com/matrix-org/matrix-rust-sdk/commit/f5d631a4a),
  SDK [`59d0d4f3d`](https://github.com/matrix-org/matrix-rust-sdk/commit/59d0d4f3d))
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
  (SDK [`b004a4b9b`](https://github.com/matrix-org/matrix-rust-sdk/commit/b004a4b9b))
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
  SDK [`6532fc2be`](https://github.com/matrix-org/matrix-rust-sdk/commit/6532fc2be)
- **BUGGY AS SHIPPED (flagged 2026-08-15): this guard over-matched.** It
  conflated known-and-in-the-live-tail with known-but-stranded-behind-a-gap
  (store-only copy), and so ate the late sync echo of a stranded just-sent
  event - making a sent message invisible permanently (survived restarts).
  Properly fixed by SDK
  [`cbf7545bc`](https://github.com/matrix-org/matrix-rust-sdk/commit/cbf7545bc)
  (the known copies must all live in memory); see "Vanished mid-send message
  ROOT-CAUSED + FIXED" at the end of this document. Upstream [`6532fc2be`](https://github.com/matrix-org/matrix-rust-sdk/commit/6532fc2be) only
  together with [`cbf7545bc`](https://github.com/matrix-org/matrix-rust-sdk/commit/cbf7545bc).

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
  flag on its entry; corrected by [`cbf7545bc`](https://github.com/matrix-org/matrix-rust-sdk/commit/cbf7545bc)); the send queue itself
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
  EXI [`1f669f332`](https://github.com/element-hq/element-x-ios/commit/1f669f332)
  - kept as a belt, was too late to help.) Window-level touch logging landed
  alongside for future swallowed-tap hunts
  (EXI [`7ff0ea3fb`](https://github.com/element-hq/element-x-ios/commit/7ff0ea3fb),
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

Upstream queue: add [`5a4990bc3`](https://github.com/matrix-org/matrix-rust-sdk/commit/5a4990bc3) alongside [`4d97fa38a`](https://github.com/matrix-org/matrix-rust-sdk/commit/4d97fa38a), [`25ff0e827`](https://github.com/matrix-org/matrix-rust-sdk/commit/25ff0e827),
[`addbff009`](https://github.com/matrix-org/matrix-rust-sdk/commit/addbff009), [`5f715227a`](https://github.com/matrix-org/matrix-rust-sdk/commit/5f715227a).

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
4. The [`6532fc2be`](https://github.com/matrix-org/matrix-rust-sdk/commit/6532fc2be) stale-batch guard fired correctly at 21:04:50
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
[`62f1f2522`](https://github.com/matrix-org/matrix-rust-sdk/commit/62f1f2522)) - no repro needed, the persisted store state was read
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
   the [`6532fc2be`](https://github.com/matrix-org/matrix-rust-sdk/commit/6532fc2be) stale-batch guard eats it: "all events known" (the
   stranded copy) "and lacking the tail". Permanent invisibility,
   surviving restarts.

Fix (SDK [`cbf7545bc`](https://github.com/matrix-org/matrix-rust-sdk/commit/cbf7545bc), pushed): the guard now requires the known copies to
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
an UPSTREAM flaw (their legacy path + shrink; our buggy [`6532fc2be`](https://github.com/matrix-org/matrix-rust-sdk/commit/6532fc2be) only
made it permanent). Fixed at the source (SDK
[`7fad14efb`](https://github.com/matrix-org/matrix-rust-sdk/commit/7fad14efb),
pushed): in the legacy gappy path, identify the eager tail suffix
conservatively (maximal trailing run of OWN events, absent from the
batch, strictly newer by origin_server_ts than every batch event), pull
it out, append the gap+batch, re-append the suffix at the new tail. The
room stays [batch..., our sends]: no invisibility window, no misorder,
and the later echo dedups in place as an anchor. Anything the rule
doesn't confidently claim stays put and falls back to the [`cbf7545bc`](https://github.com/matrix-org/matrix-rust-sdk/commit/cbf7545bc)
echo-heal.

Regression test red-before/green-after
(test_gappy_stale_batch_does_not_strand_our_eager_tail); the echo-heal
and reorder tests still green; 64+99 event cache tests green.

Upstream arc for this family is now: [`4d97fa38a`](https://github.com/matrix-org/matrix-rust-sdk/commit/4d97fa38a) (anchored merge) +
[`6532fc2be`](https://github.com/matrix-org/matrix-rust-sdk/commit/6532fc2be) (stale-batch guard, ONLY together with) + [`cbf7545bc`](https://github.com/matrix-org/matrix-rust-sdk/commit/cbf7545bc) (guard
narrowing) + [`7fad14efb`](https://github.com/matrix-org/matrix-rust-sdk/commit/7fad14efb) (suffix relocation) + the diagnostics-strip.

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

Bycatch - two parser regressions from the list-indent fix ([`550a6467d`](https://github.com/element-hq/element-x-ios/commit/550a6467d)),
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
UnitTests target down ([`fedf3ae3d`](https://github.com/element-hq/element-x-ios/commit/fedf3ae3d)).

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
vs "test") masked the collision; [`1a3a97317`](https://github.com/element-hq/element-x-ios/commit/1a3a97317)'s whitespace fix exposed
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
  SPANNING bar (supersedes the depth-count bars from [`fcf00a121`](https://github.com/element-hq/element-x-ios/commit/fcf00a121)) and
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
  and render in turn ([`d88bbf2a0`](https://github.com/matrix-org/matrix-rust-sdk/commit/d88bbf2a0) + regression test).
- **Stalled index after backgrounding** - a resolution killed mid-flight
  (bg the app, network error) never retried: the spinner's `onAppear`
  had already fired and nothing re-requested it, with no user
  affordance to kick it. Both gap views (room timeline + Media & Files)
  now re-send `.resolveGap` every 2s while the spinner is visible via a
  `.task` loop (idempotent thanks to SDK in-flight dedupe + cheap
  unknown-token pre-check) (EXI [`0c0c33ed2`](https://github.com/element-hq/element-x-ios/commit/0c0c33ed2)).
- **Timeline pop on resolution** - the gap's spinner row swapped for the
  fetched events in an unanimated snapshot apply. When a *visible* gap
  disappears from the snapshot, the apply now runs animated (100ms
  ease-out, `.fade` row animation) so neighbours close the slot and the
  spinner reads as shrinking away (EXI [`1d478a346`](https://github.com/element-hq/element-x-ios/commit/1d478a346)).

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
applies, reusing snapshotLayout/restoreLayout (EXI [`53c10646d`](https://github.com/element-hq/element-x-ios/commit/53c10646d)).

Round 2 addendum 2: scroll-back spasms at the top of the room
(user recording, spasms at 10.5s/12.86s matching "Finished resolving
timeline gap" log lines exactly): a resolution's inserted events make
adjacent "N room changes" groups regroup under new identities, so the
animated .fade apply cross-faded half the screen mid-scroll. Now a
resolution only animates when the spinner is the sole visible casualty;
churny applies go unanimated + pinned, and group items are no longer
used as the layout anchor (identity unstable). EXI [`25291a7be`](https://github.com/element-hq/element-x-ios/commit/25291a7be).

Round 2 addendum 3: second recording (spasm at 4.56s) showed a tall
single-message resolve at the viewport top spasming WITHOUT identity
churn - animating any content-inserting apply near the viewport is
inherently messy in the flipped table. Final policy (EXI [`912c06177`](https://github.com/element-hq/element-x-ios/commit/912c06177)):
animate only resolves that close EMPTY (pure spinner removal - the true
shrink-away); all content-inserting resolves apply unanimated with the
visible content pinned. Pin now adjusts bounds.origin directly instead
of scrollToRow, so it no longer cancels an in-flight fling.

### Gappy timelines: merged into preview-prefill (2026-08-16)

Round-2 fixes user-validated on the phone ("feels great"). Both
`matthew/gappy-timelines` branches fast-forward-merged into
`matthew/preview-prefill` (SDK [`f7161bf4b`](https://github.com/matrix-org/matrix-rust-sdk/commit/f7161bf4b)..[`d88bbf2a0`](https://github.com/matrix-org/matrix-rust-sdk/commit/d88bbf2a0), EXI
[`6f3b3249d`](https://github.com/element-hq/element-x-ios/commit/6f3b3249d)..[`2e5e05436`](https://github.com/element-hq/element-x-ios/commit/2e5e05436)) and pushed; gappy-timelines branches retired
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

### Cache-as-index round (2026-08-16 afternoon)

Principle (user): the event cache is an INDEX, not a cache - only an
explicit clear (or a future user-set size cap, or known-bad data) may
empty it. Four fixes on preview-prefill towards that:

- SDK [`a706d3bfd`](https://github.com/matrix-org/matrix-rust-sdk/commit/a706d3bfd): the event cache now receives sync room updates over a
  dedicated lossless unbounded queue instead of the capacity-32
  broadcast; the lag path that wiped EVERY room's persisted chunks on
  a missed broadcast is gone entirely.
- SDK [`d77c69156`](https://github.com/matrix-org/matrix-rust-sdk/commit/d77c69156): linked chunk updates (feeding the search index, thread
  subscriber and re-decryptor) now go through a lossless per-subscriber
  fanout; previously each consumer silently skipped updates on lag
  (dozens of "Lagged behind linked chunk updates" in one busy session =
  permanent search-index holes, missed redecryptions).
- SDK [`9587599ea`](https://github.com/matrix-org/matrix-rust-sdk/commit/9587599ea): ignoring a user now filters their events out of the
  existing cache (rooms + instantiated threads, memory + store, via the
  dedup removal machinery, emitting removal diffs) instead of wiping
  everything. Unignore still clears (only way to resurrect filtered
  events). Known gap: never-instantiated persisted thread chunks can't
  be enumerated yet (store threads table is write-only) - store-level
  enumeration API is the follow-up.
- SDK [`32ad3ed0c`](https://github.com/matrix-org/matrix-rust-sdk/commit/32ad3ed0c) + EXI [`ecaf44a38`](https://github.com/element-hq/element-x-ios/commit/ecaf44a38): the UnknownPos "server unavailable"
  flash pair - sync service restarts silently on session expiry (10s
  anti-spin guard), and EXI debounces the offline/unreachable banners
  (2s sustained before showing, immediate retract via switchToLatest).
  Follow-up [`3d974500c`](https://github.com/matrix-org/matrix-rust-sdk/commit/3d974500c): drain stale child termination reports on the
  silent restart - they otherwise killed the freshly restarted sync
  (real bug, found via the hanging regression test).

Toolchain gotcha (bit us twice today): stable rustc hangs 20+ minutes
in trait-solver error-recovery on unresolved-name errors after
mechanical refactors; `cargo +nightly check` reports the real errors
in seconds. Also hit a nightly incremental-compilation ICE once
(`cargo clean -p matrix-sdk` fixes it).

Round addendum: first dogfood of the cache-as-index build surfaced a
frozen timeline in #ruma-dev:flipdot.org - overscroll did nothing (no
pagination, no gap spinner) until bg/fg. Logs proved the SDK idle and
the table frozen on a stale snapshot: a cancelled drag gesture fires
willBeginDragging without didEndDragging, wedging isDraggingScrollView
true, parking every update in hasPendingItems (which paginateIfNeeded
also gates on). Fixed EXI [`6586deb77`](https://github.com/element-hq/element-x-ios/commit/6586deb77): gate applies on UIKit's live
isTracking/isDragging and flush pending items from scrollViewDidScroll.
Pre-existing bug, but gappy timelines made it much more visible (the
gap item that would resolve history sat in the pending batch).

Round addendum 2: the frozen-timeline symptom recurred on the drag-fix
build (#ruma-dev again, then GNOME Newcomers): no start-of-room item,
no gap spinner, overscroll dead, bg/fg heals. Logs showed a healthy
chain of gap resolutions ending 2 min before the report, then silence:
storage-only pagination hits the leading gap and reports "start hit"
(EXI flips to endReached and stops paginating - by design, the gap
item drives itself from there); when the gap chain then resolves to
completion, nothing inserted the timeline start (the status stream is
dedup'd and already said hit) and nobody paginates anymore. bg/fg
heals by re-subscribing. Fixed SDK
[`ce16d5247`](https://github.com/matrix-org/matrix-rust-sdk/commit/ce16d5247):
gaps drive the timeline-start decision (inserted when no gap leads and
the status says hit; retracted if a racing status update inserted it
before the gap was known); paginations and gap resolutions refresh
gaps synchronously; the leading-gap check uses the cache's snapshot
rather than rendered items. Regression test covers the wedge and the
race (the race alone made the test fail before the fix, so it was
biting too). Also SDK
[`bd9e6f428`](https://github.com/matrix-org/matrix-rust-sdk/commit/bd9e6f428):
ignore-filtering removals weren't emitted to timelines until the next
sync's diffs (found by the timeline ignore test) - emitted right away
now. The earlier EXI cancelled-drag fix stands: it was a real,
separate wedge.

Round addendum 3: with the wedge gone, scrolling history showed a
one-frame jump on every gap resolution. Logs: each resolution produced
two diff batches, `[Insert x N ..., Remove(1), Insert(21)]` then
`[Remove(21), Insert(1)]` - the gap spinner was briefly re-anchored
just above the previously-first event (mid-viewport), then moved back
to the top. Cause: the event cache announces the events diffs and the
resulting gaps snapshot as two separate updates, and the timeline
applied the diffs against the stale snapshot. Fixed SDK
[`ff480667c`](https://github.com/matrix-org/matrix-rust-sdk/commit/ff480667c):
the live event-subscriber reads the cache's current gaps before
applying an events batch, so one transaction places both. Regression
test drives the resolution through the event cache directly (the
timeline's own `resolve_gap` refreshes gaps right after and hides the
race on a single-threaded runtime).

Still open from the same session: the topmost visible bubble jumping
when back-pagination lands a same-sender predecessor above it. It's the
group-style change (`.first` -> `.middle`, sender header removed) on an
existing cell: UIKit self-sizing invalidation animates the row-height
change (header fades, bubble slides ~35pt), then the row shrink shifts
the whole viewport when scrolled at the top of loaded content. Purely
EXI-side (TimelineTableViewController / hosting-cell resize); not fixed
yet, approach TBD (disable the implicit resize animation for
pagination-driven group-style updates, or pin the layout on the newest
visible item as the non-live path does).

Round addendum 4: the top-bubble regroup jump above turned out to be
EXI's own `RoomTimelineItemView` `.animation(.elementDefault, value:
groupStyle)`: meant for live sends regrouping the tail, it also
animated the sender header away when back-pagination landed a
same-sender predecessor above the top visible item. Fixed EXI
[`b8f5db3bf`](https://github.com/element-hq/element-x-ios/commit/b8f5db3bf):
`TimelineViewModel.updateViewState` applies a "loses sender details"
regroup inside a transaction with animations disabled; every other
group-style change keeps its animation. Validate: paginating up through
a same-sender run no longer slides/fades the top bubble; if a residual
whole-viewport shift remains on those batches, that's the flipped
table's row-shrink at max content offset (next suspect).

Round addendum 5: "history won't load from cache behind a leading gap"
(offline, and on slow network): the top spinner was not the gap item
but EXI's pagination indicator, i.e. `paginationState.backward` stuck
at `.paginating`, so `paginateIfNeeded` never asked for another storage
walk (the SDK had settled to Idle: logs show the walk returning, and a
new SDK test asserts the status stream settles with a leading gap).
Cause: `TimelineController` iterated the provider's `updatePublisher`
(`combineLatest` of items + state) via `.values`, which requests one
value at a time; `combineLatest` forwards that demand to the subjects
and a subject drops values sent while its demand is 0, so a
`paginating -> idle` pair arriving while the previous update was still
being built lost the `idle` for good (reproduced standalone in 20 lines
of Combine). Fixed EXI
[`1c6c7f4bf`](https://github.com/element-hq/element-x-ios/commit/1c6c7f4bf):
unlimited-demand sink coalescing to the latest update, processed
serially. Validate offline: open a room with a leading gap, scroll up:
one spinner (the gap's) below the divider, cached history behind it
loads via storage walks; no spinner above the first date divider.
Same drop class could plausibly have hidden other late state updates
(forward pagination state, item batches during heavy builds).

### Speeding up Media & Files view so it's not blocked by gaps and can be used as an index

Round addendum 6 (Media & Files): three reports - slow load, no
spinner while looking for media in a media-less room, never any gap
spinners in the grid. Logs showed the grid's filtered storage-only
timeline paginating one store chunk per FFI round trip (~70ms each,
mostly yielding nothing). Two SDK fixes
[`e6b518ab7`](https://github.com/matrix-org/matrix-rust-sdk/commit/e6b518ab7):
(1) gaps whose followers are all filtered out of the timeline (newest
media predates the gap, or no media at all) were never rendered, so
nobody resolved them; they now render at the newest end (the grid
already keeps `.gap` items as spinner cells, so a media-less room shows
a spinner group instead of the empty state, and gaps in the room show
as spinners in the grid until filled); (2) storage walks keep going
(up to 32 chunks per call) until a loaded chunk holds an event passing
the timeline's filter, instead of returning after every non-empty
chunk. Still O(cached events) on a cold grid; a real media index is a
follow-up (hashed `msgtype` column next to the existing hashed
`event_type` in the sqlite events table + a media-focused event-cache
view ordered by chunk position/timestamp with gaps placed by
neighbouring events).

Round addendum 7 (Media & Files index + store hog). Media & Files was
still slow with the room fully cached: the console showed the culprit
was not the storage walk (5-25ms per chunk) but the store being hogged
between chunks by the redecryptor's per-session encryption-info refresh
(`get_room_events(room_id, session_id)`, one per received room key,
~1.8s EACH in a big room, 15 back-to-back after launch; 24s once at
17:11Z): the query had no covering index (`event_type_index` is
(room_id, event_type, session_id)) and scanned every event of the room,
serialising every other store access behind it (also the "`pos`
persistence is still waiting for the event cache" 10s warnings). SDK
[`daea5b0e2`](https://github.com/matrix-org/matrix-rust-sdk/commit/daea5b0e2)
migration 018 adds `events(room_id, session_id)`.

Then the actual index. Same migration adds a hashed `msgtype` column
(room messages only; hashed "" for msgtype-less/redacted ones; NULL for
legacy rows, backfilled lazily the first time a room is queried) with
`events(room_id, msgtype)`, and store methods
`find_events_by_message_types` (matches + positions, index-only) and
`load_all_gaps`. SDK
[`3b387ee02`](https://github.com/matrix-org/matrix-rust-sdk/commit/3b387ee02)
`MessageTypesEventCache`: a projection of the room's PERSISTED linked
chunk onto the wanted msgtypes, seeded from the index in one query
(under the room's state read lock, after a lock-free warm-up query so
the legacy backfill never stalls sync), ordered by a standalone
`OrderTracker` over the full chunk metadata, kept up to date from the
lossless linked-chunk-update fanout (sync, pagination, gap resolution,
redecryption, redaction, clear); exposes newest-first in pages of 50;
reports the room's gaps as `TimelineGap`s anchored to the next matching
event, or unanchored (`following_event_id: None`, rendered at the newest
end) when nothing matching follows; `resolve_gap` goes through the room
event cache after loading the room's storage down to the gap (gaps
resolve on the in-memory linked chunk only; store-only resolution is the
upgrade path if that load ever hurts). SDK
[`7544e8345`](https://github.com/matrix-org/matrix-rust-sdk/commit/7544e8345)
`TimelineFocus::MessageTypes { msgtypes }` (+ FFI
`.messageTypes(types:)`): storage-only implied, no local echoes, gaps as
items, timeline start once fully exposed with no leading gap. EXI
[`38de1429e`](https://github.com/element-hq/element-x-ios/commit/38de1429e):
Media & Files build both grids on `TimelineFocus.messageTypes`; the media
viewer's swipe timelines keep their live/event focus. Tests: store
integration tests (all stores) + sqlite backfill test, 6 projection unit
tests, 1 timeline integration test. Behaviour changes to watch: no
sending-media thumbnail in the grid before the send completes (no local
echoes); first open of each room after upgrade decodes that room's
message rows once (backfill), instant afterwards; the chat behind the
grid may briefly show its top spinner while a grid gap resolves (storage
loads down to the gap).

Also this round: room list to skeletons ~3s after a relaunch (17:51Z):
AllRooms emptied on the first sync response of the fresh session and
never recovered, siblings fine, and NEITHER of the 13 Aug death logs
fired, so the chain was alive and the emptying was a legitimate diff.
Diagnostics only for now: SDK
[`f2d87693b`](https://github.com/matrix-org/matrix-rust-sdk/commit/f2d87693b)
logs the size of every (re)built dynamic entries chain; EXI
[`e806f1d55`](https://github.com/element-hq/element-x-ios/commit/e806f1d55)
logs the diff kinds that empty a populated list.

### Round 8: Media viewer swipes using the message filter index rather than walking the timeline

Commits: SDK [`843292aec`](https://github.com/matrix-org/matrix-rust-sdk/commit/843292aec); EXI [`1edf24d3c`](https://github.com/element-hq/element-x-ios/commit/1edf24d3c), [`27abd3d77`](https://github.com/element-hq/element-x-ios/commit/27abd3d77).

Tapping a media in the chat used to build a fresh msgtype-filtered live
(or event-focused) timeline to swipe through: another walk of the room's
history, the same slowness the grids had. The viewer now opens a
`MessageTypes` timeline seeded *around the tapped event*. SDK
[`843292aec`](https://github.com/matrix-org/matrix-rust-sdk/commit/843292aec):
`MessageTypesEventCache` exposes a window (`exposed_from..exposed_to`)
instead of a suffix; `new(around_event)` seeds half a page either side of
the event (falls back to the newest page with a warning if the event
isn't an indexed match); `paginate_forwards`/`hit_end` join
`paginate_backwards`/`hit_start`; a window reaching the newest entry
follows it (live appends show), one stopped mid-history holds appends
back until paged to; `TimelineFocus::MessageTypes { around_event }`,
`Timeline::paginate_forwards` supported for it, FFI `aroundEventId`. EXI
(this commit): `TimelineFocus.messageTypes(aroundEventID:)`; the room
screen's media taps (live and detached) build the swipe timeline with it
when the item has an event ID (a local echo keeps the old live path,
it isn't indexed yet); `.roomScreenLive` previews start with forward
pagination `.idle` so newer media beyond the initial page can be paged
to (one no-op forward call when there is none). Threads and pinned keep
their focused timelines (the index isn't thread-scoped). Tests: 2 unit
(window paging both ways + held-back vs followed appends; unknown-event
fallback) + 1 timeline integration. Watch for: viewer opens on the
tapped item at once (no "Ignoring update" single-item viewer), swipes
both ways land fast on cached rooms, live-sent media appears at the end
only once the viewer has paged to the newest end.

### Round 9: Manage storage screen in Advanced Settings

Commits: SDK [`88a7907a0`](https://github.com/matrix-org/matrix-rust-sdk/commit/88a7907a0), [`ac895b612`](https://github.com/matrix-org/matrix-rust-sdk/commit/ac895b612), [`f0070d5c0`](https://github.com/matrix-org/matrix-rust-sdk/commit/f0070d5c0); EXI [`1bfc65c0e`](https://github.com/element-hq/element-x-ios/commit/1bfc65c0e).

Advanced settings → Manage storage: a colour-coded horizontal bar chart of
the caches (Cached message keys = crypto store megolm sessions, Cached
room state = state store room data, Cached messages = event cache, Cached
media = media store, Log files = the app's rageshake logs), each with its
size in MB and a clear button; a "Clear all caches" row; and the rooms
listed by total storage with multi-select checkboxes. Selecting rooms
scopes the chart (its header reads All rooms / the room name / "N rooms",
the log row hides since logs are session-wide) and the clear buttons,
whose row reads "Clear caches for <room>" / "Clear caches for N rooms".
Every clear goes through a confirmation sheet carrying the warnings
(message keys: unreadable history without a backup; state/messages: the
two are cleared together, and clearing them for all rooms restarts the
app through the existing clear-cache flow) and three options:
everything, older than 30 days, older than 90 days. "Older than" means:
media not opened for that long (exact, by last access), log files older
than that (by modification date), and, for the per-room caches, the
caches of rooms with no activity for that long (the room's recency
stamp; keys/members/events carry no per-row timestamps, and the linked
chunk can't have holes, so room granularity is what's cheap).

SDK [`88a7907a0`](https://github.com/matrix-org/matrix-rust-sdk/commit/88a7907a0):
`StorageUsage { total_bytes, per_room }` (matrix-sdk-common); store trait
methods with sqlite implementations (memory stores implement the
clearing, other stores default to no usage / no-op): CryptoStore
`room_keys_storage_usage` + `remove_inbound_group_sessions` (also drops
the backup fully-downloaded markers so keys are refetched from backup),
StateStore `storage_usage` + `remove_room_members` (member events,
members, profiles, receipts, display names; room info + other state
kept, and the room is marked members-missing persistently),
EventCacheStore `storage_usage` + `room_media_uris` (mxc URIs of the
room's media messages via the msgtype index, so media is attributable
per room), MediaStore `storage_usage` + `remove_media_contents(uris,
last_accessed_before)`, `EventCache::clear_room`; `Client::storage_usage()`
/ `clear_room_keys` / `clear_room_caches` / `clear_media_cache`. Sizes
are payload sums grouped by the hashed room/uri keys and mapped back
through the known rooms (approximate vs on-disk; the developer options'
store sizes stay the on-disk numbers). FFI
[`ac895b612`](https://github.com/matrix-org/matrix-rust-sdk/commit/ac895b612)
+ [`f0070d5c0`](https://github.com/matrix-org/matrix-rust-sdk/commit/f0070d5c0):
`storageUsage()` report (per-cache totals, per-room shares with display
name + last activity, largest first), `clearRoomKeys`, `clearRoomCaches`,
`clearMediaCache(roomIds, notAccessedFor)`. EXI (this commit): screen
+ ClientProxy wiring + unit tests. Tests: 4 sqlite store tests + 1
client integration test (SDK), 4 view model tests (EXI). Caveats: a
room's media share only counts contents referenced by its cached media
messages (avatars, other rooms' unattributed media sit in the total
only); clearing a room's messages also makes its media unattributable
until re-cached; per-room state clearing keeps state events (power
levels etc.) on purpose.

Also this round: chat media swipe on the index (addendum 8), (i) icon
swap now KVO-synchronous, neighbour preload joins in-flight loads and
covers unknown sizes.

## Round 10: Manage storage, second pass

Commits: SDK [`6b95f506d`](https://github.com/matrix-org/matrix-rust-sdk/commit/6b95f506d); EXI [`37e87950f`](https://github.com/element-hq/element-x-ios/commit/37e87950f).

Dogfood on build 18: totals didn't match Developer options (payload sums
vs on-disk files), and the screen blocked for ages because attributing
media to rooms decoded every stored media message of every room. Now:
the all-rooms bars are the stores' on-disk sizes (same numbers as
Developer options, instant); the rooms stream in one by one, biggest
first, with a spinner in the section header, and only rooms over 5 MB
are listed (the older-than logic still considers every room); and the
event cache store indexes each media message's mxc URIs when the event
is written (`event_media` table, small encrypted values, cascading with
the event) so nothing is decoded to measure - rows written before the
table are indexed lazily once per room, the last time a media message
is decoded for this. SDK
[`6b95f506d`](https://github.com/matrix-org/matrix-rust-sdk/commit/6b95f506d)
(`Client::storage_usage_by_room(on_room)`, FFI
`storageUsageByRoom(listener) -> TaskHandle`, migration 019); EXI (this
commit): `storageUsageByRoom() -> AsyncStream<StorageUsageRoom>`, totals
from `storeSizes()`, progressive list, >5 MB filter. Note the crypto
"Cached message keys" total is now the whole crypto store file (devices,
identities, olm sessions included), like Developer options; per-room
shares stay the megolm-session payloads.

## Round  11: Manage storage, third pass + viewer preload

Commits: SDK [`2d44d71f3`](https://github.com/matrix-org/matrix-rust-sdk/commit/2d44d71f3), [`9f25138a8`](https://github.com/matrix-org/matrix-rust-sdk/commit/9f25138a8), [`6c2d1487e`](https://github.com/matrix-org/matrix-rust-sdk/commit/6c2d1487e); EXI [`470dc4d9b`](https://github.com/element-hq/element-x-ios/commit/470dc4d9b), [`e746f4b29`](https://github.com/element-hq/element-x-ios/commit/e746f4b29).

Build 21 dogfood: rooms appeared quickly but the media shares took ~30 s.
Log: the media pass called `room_media_uris` per room (5728 rooms × 3
sqlite round-trips ≈ 11 s) and each room was upserted into the list one
at a time, twice (11k SwiftUI updates for the rest). Now one query for
the whole `event_media` index (`media_uris_by_room(room_ids)`, legacy
backfill done once across rooms) and the SDK reports rooms in two
batches (all rooms, then the rooms with media); the screen merges each
batch in one state update. Also from the same round: the per-room
counters (SDK
[`2d44d71f3`](https://github.com/matrix-org/matrix-rust-sdk/commit/2d44d71f3)
/ [`9f25138a8`](https://github.com/matrix-org/matrix-rust-sdk/commit/9f25138a8),
migrations 020 event cache + 016 state store): trigger-maintained
`room_event_sizes` / `room_data_sizes` tables replace the GROUP BY scans,
filled once from existing rows on first use.

UI, per feedback: the older-than options are gone (clears are
all-or-nothing again; the SDK's `notAccessedFor` stays available), the
confirmation is a plain alert titled "Clear all caches?" / "Clear caches
for X?" / "Clear cached media?", and clearing the log files offers "View
log files" (the bug-report log viewer, pushed) first.

Media viewer: a preloaded neighbour now gets its file handle as soon as
the preload finishes and QuickLook rebuilds its pages (deferred to the
next settled index if mid-swipe), so the neighbouring media swipes into
view instead of a black page that pops in once the transition ends.

Follow-up on the same build: rebuilding all the QuickLook pages flashed
the current one black, so instead two items either side are preloaded
(QuickLook builds the pages next to the current one as it settles, so
the item after next has its file by the time the next one is reached)
and only a page that QuickLook built before its file arrived is
refreshed, once it's current. "Media and files" in Room Info waited
~1.3 s for both filtered timelines (`find_events_by_message_types`
decodes every media message of the room): the two timelines are now
built when Room Info opens (and again when returning to it), so the tap
opens instantly; a tap before they're ready still waits.

## Round 12: media views seeded index-only

Commits: SDK [`0e26df61e`](https://github.com/matrix-org/matrix-rust-sdk/commit/0e26df61e); EXI [`4405607ba`](https://github.com/element-hq/element-x-ios/commit/4405607ba) (docs only, the seeding is SDK-side).

The Media and files open cost was O(all media in the room): the
message-type view decoded every matching event at seed (twice, plus the
files view). SDK
[`0e26df61e`](https://github.com/matrix-org/matrix-rust-sdk/commit/0e26df61e):
the view is seeded from the index alone (`find_event_refs_by_message_types`,
opaque event refs + positions, no content read), events are held as
pending and loaded in one query per page as they come into the exposed
window (seed page, `paginate_backwards`/`paginate_forwards`), and the
around-event focus is located through `filter_duplicated_events`. So
opening the media grid costs one index query + one page decode however
big the room; the Room Info prewarm (addendum 11) stays as a bonus.
Also on this build: the preloaded-neighbour refresh in the media viewer
waits for the pages to rest (it was being dropped by the
don't-refresh-while-scrolling guard, leaving preloaded items black).

## Round 13: media viewer swiping, the whole journey

Commits: EXI [`1edf24d3c`](https://github.com/element-hq/element-x-ios/commit/1edf24d3c), [`e746f4b29`](https://github.com/element-hq/element-x-ios/commit/e746f4b29), [`fc85bea0c`](https://github.com/element-hq/element-x-ios/commit/fc85bea0c), [`eddee8ba0`](https://github.com/element-hq/element-x-ios/commit/eddee8ba0), [`c7a2be821`](https://github.com/element-hq/element-x-ios/commit/c7a2be821), [`13364ae7c`](https://github.com/element-hq/element-x-ios/commit/13364ae7c) (builds 21-30), [`e82c58c13`](https://github.com/element-hq/element-x-ios/commit/e82c58c13) (builds 31-34).

The goal: swiping between media in the QuickLook viewer should reveal
the neighbouring media as it slides in, not a black page that pops in
afterwards after a spinner. It took seven builds and a device log to get
right, because two assumptions about QuickLook were wrong.

1. **Preload the neighbours** (build 21). The viewer fetched the two
   media either side of the current one into the media cache, but left
   the item's file handle unset so that the load on display would set
   it and refresh the page. Result: fast (cache) loads, but a black page
   still slid in and popped.
2. **Set the file handle at preload and rebuild the pages** (build 22)
   with `QLPreviewController.reloadData()`. The media slid in, but
   `reloadData` rebuilds the current page too: black flash on every
   settle.
3. **Refresh only pages built without a file** (build 23): preload ±2,
   set the handle at preload, and remember the items whose preload
   finished while their page already existed (assumed: the pages either
   side of the current one, built as it settles) to refresh them on
   arrival. Result: everything black. The refresh on arrival went
   through the existing "don't refresh while scrolling" guard, and the
   index changes while the pages are still decelerating, so it was
   silently dropped (build 24 fix: poll until resting). Then a swipe
   during the wait abandoned the refresh with nothing remembering it,
   so the item was black for good (build 25: remember it). Then the
   snap-to-page after a flick is QuickLook's own animation, invisible to
   `isDragging`/`isDecelerating`, so the refresh could fire mid-snap
   (build 26: require the page offset to be still for ~200 ms).
4. **Logs, not theories** (build 27, `PreviewDebug`). The log showed
   QuickLook building pages two either side, not one (build 28: mark
   within ±2, preload ±3), and then, decisively, items arriving with
   their file present, page built with the file present, black anyway.
   QuickLook simply parks a page on its `_UIContentUnavailableScrollView`
   placeholder when swiped through quickly, file or not, and nothing but
   `refreshCurrentPreviewItem` clears it (pages far enough away are
   dropped and rebuilt fine, which is why swiping back slowly "worked").
5. **Detect the placeholder** (builds 29-30): on settling on an item
   (offset still, not dragging/decelerating), and when its file arrives,
   look for that placeholder view over the page centre and refresh only
   then. Build 29 still flickered (the old "marked" path refreshed
   good pages, and two checks could run for one item) and looped on
   videos (refresh re-fires the index, the video page always looked
   unavailable). Build 30: one refresh path, always gated on the
   placeholder, one check per item at a time, at most one refresh per
   arrival (a freshly loaded file bypasses that once). Verdict: pages
   that QuickLook drops during a fast flick still land black for a
   moment and then repair; everything else slides in clean.

Also from this round: the Media and files timelines are seeded
index-only in the SDK (addendum 12) and prebuilt when Room Info opens
(addendum 11). The `PreviewDebug` logging is still in and should be
stripped before upstreaming, as should the whole placeholder-detection
approach be raised with the EX team as a QuickLook workaround.

Follow-ups (builds 31-34):

6. **Stop at the ends instead of bouncing.** Swiping past the first or
   last media paged onto the timeline-start/end placeholder, snapped
   back and toasted "No more media to show". The controller now pins
   the page scroll view's offset at rest whenever the current item is
   the last one in the swiped direction and that direction has hit the
   end (`isAtTimelineEdge`), so the page simply doesn't move (setting
   the offset also cancels any deceleration towards the placeholder).
   The toast, its view action and string usage are gone; the
   snap-back stays as a silent fallback should QuickLook flip the
   index anyway.
7. **Same behaviour from the room screen as from the grid.** Both flows
   already open the same `messageTypes(aroundEventID:)` timeline; the
   room-screen one started with `forward = .idle` because it opened
   mid-index and couldn't know whether newer media existed, so the
   first forward swipe still paged onto the "paginating" placeholder
   before learning there was nothing there. `TimelineProxy` now probes
   with a zero-sized `paginateForwards(0)` at subscribe time (exposes
   nothing, returns the message-types cache's `hit_end`) and seeds
   `.endReached` when already at the newest. Backwards stays `.idle`
   on both flows (`hit_start` on the index doesn't mean no older
   history: gaps may remain).
8. **Neighbours preloaded from the room screen too.** Preloading only
   ran on the current-item change; opened from the room screen the
   media timeline was still loading at that point, so the data source
   held the tapped item alone and its neighbours arrived without a
   preload pass. It now re-runs whenever the timeline items update.
9. **"Preload media in viewer" toggle** in Advanced settings
   (`AppSettings.preloadMediaInViewer`, default on) for people who
   want to save data; `TimelineMediaPreviewViewModel` takes
   `appSettings` and skips `preloadNeighbours` when it's off.

## Round 14: Manage storage, fourth pass

Commits: SDK [`f8b8b7cfa`](https://github.com/matrix-org/matrix-rust-sdk/commit/f8b8b7cfa); EXI [`107753bb5`](https://github.com/element-hq/element-x-ios/commit/107753bb5), [`e3325dbda`](https://github.com/element-hq/element-x-ios/commit/e3325dbda), [`eec67d48c`](https://github.com/element-hq/element-x-ios/commit/eec67d48c), [`4de28ca89`](https://github.com/element-hq/element-x-ios/commit/4de28ca89), [`af1ae89fb`](https://github.com/element-hq/element-x-ios/commit/af1ae89fb), [`96c5b31ef`](https://github.com/element-hq/element-x-ios/commit/96c5b31ef).

With the media share measured from the URI index in one query (round 11),
the whole per-room walk finishes in well under a second, so the
progressive two-batch API wasn't buying anything and made the list
re-sort under the user's finger. Changes:

- SDK `Client::storage_usage_by_room()` now just returns the
  `Vec<(OwnedRoomId, RoomStorageUsage)>` (rooms with data, media
  included, biggest first); the FFI is a plain async
  `storageUsageByRoom() -> [RoomStorageUsage]` and the
  `StorageUsageListener` callback interface is gone. EXI
  `ClientProxy.storageUsageByRoom()` returns a `Result`; the view model
  sets the rooms once, sorted by total.
- Each room row draws its total as a stacked capsule (one segment per
  cache, the chart's colours), width relative to the largest listed
  room, so the list previews the breakdown you get by selecting it
  (`StorageUsageRoomRow`).
- Selecting rooms no longer hides the log-files row (which made the
  layout pop): all five rows stay; the session-wide one is greyed out,
  its bar fill hidden and its clear button disabled (`activeCaches`).
- Rooms the user has selected stay listed (and selected) even once a
  clear takes them under the 5 MB bar or out of the report entirely
  (kept as an empty entry until the screen is next opened), so the
  selection doesn't vanish from under the user.
- The Manage storage row moved up above Moderation and safety in
  Advanced settings.
- The chart header carries the scope's total, e.g. "All rooms (580.0 MB,
  6340 rooms)" or "Matrix HQ (95.0 MB)", summing the active caches only
  (so no logs once filtered to rooms); the room count is the rooms with
  any cached data (what the SDK reports), shown in All rooms mode only.
- Listing threshold lowered from 5 MB to 1 MB.
- The room count is elided from the header until the rooms have loaded
  (no "0 rooms" flash).

## Round 15: Gappy timelines, false "beginning of the room"

Commits: SDK [`11abfd1d7`](https://github.com/matrix-org/matrix-rust-sdk/commit/11abfd1d7).

Muninn Hall Main showed "This is the beginning of Muninn Hall Main"
above a message from 25 July, nowhere near the room's start
(console.2026-08-16-21.log). The room had three limited-sync gaps a
handful of events apart (prev-batch tokens `t4297`, `t4301`, `t4306`),
all in memory thanks to storage-only pagination, and all being resolved
concurrently as they scrolled into view (three interleaved `/messages`
walks in the log). Two walks over overlapping history break the event
cache's duplicate handling, which assumes a single walk: when a
resolution returns events we already have, the existing copies are
moved to the resolved gap's position. That's right when the copies sit
right before the gap (the classic limited-sync case), and wrong when
they sit *after* it, fetched through a newer gap whose walk already
went past: they get dragged backwards in front of that walk's frontier
gap, the timeline is misordered, and once the leading gap is dropped as
"all duplicates" nothing leads the frontier gap any more, so the timeline
start gets inserted.

Fix (SDK `conclude_backwards_pagination_from_network`): if any duplicate
of a gap's `/messages` response lives after the gap in the linked chunk,
the gap has been overtaken; drop it, move and insert nothing. Older
history keeps coming through the newer gap's own trailing gap, which
stays leading, so no start item. Regression test
`test_resolve_gap_drops_gap_overtaken_by_a_newer_gap` (fails on the old
code with the frontier gap ending up behind moved events).

Also checked while here (the "stuck with a spinner at the top" question):
storage-only back-pagination never blocks on `/messages`. The storage
walk (`paginate_backwards_impl`) skips over gap chunks and keeps loading
older cached chunks; it stops (`hit_timeline_start`) only once the
store is exhausted. Mid-timeline gaps are inline spinners resolved on
visibility while scrolling continues past them. The only time the top of
the timeline waits on the network is a *leading* gap with nothing cached
behind it (plus the empty-room bootstrap), which is the intended
"nothing left in the cache" case.

## Round 16: Skeletons-forever root cause, re-introduce skeletons on launch

Commits: EXI [`73a0c75fc`](https://github.com/element-hq/element-x-ios/commit/73a0c75fc), [`15e7a42e0`](https://github.com/element-hq/element-x-ios/commit/15e7a42e0), [`217289b85`](https://github.com/element-hq/element-x-ios/commit/217289b85), [`da464bc52`](https://github.com/element-hq/element-x-ios/commit/da464bc52), [`30c6c8ae2`](https://github.com/element-hq/element-x-ios/commit/30c6c8ae2).

The "stuck on skeletons" home list recurred (console.2026-08-17-11.log,
10:02:59Z, ~5s into a launch) and this time the round-14 diagnostics
caught it: `Dynamic room list entries chain (re)built num_rooms=0`
followed by `AllRooms: Room list emptied by diffs: ["reset(0)"]`, with
neither stream-death log firing. So the chain was rebuilt by a filter
change, and the new filter matched nothing: focusing the search field
applies `.excludeAll` (the SDK's match-nothing filter; the list is
hidden behind the search UI by design). The trap is what happens next:

1. A loading-state update lands while the list is empty (here the room
   count coming back after a session-expiry restart, 0.5s later) and
   the branch's "hold skeletons until rooms exist" clause in
   `HomeScreenViewModel.updateRoomListMode` (not upstream) flips the
   mode to `.skeletons`.
2. `HomeScreenContent` mounts `.roomListSearchable` only in the
   `.rooms` case, so the skeleton view removes the search field from
   the hierarchy; `isSearchFieldFocused` never gets its unfocus,
   `updateFilter` never runs again, the filter stays `.excludeAll`, the
   list stays empty, the placeholders stay up, and there is no search
   bar left to cancel. Deadlock; that's why the log shows no second
   chain rebuild.

Fix [`73a0c75fc`](https://github.com/element-hq/element-x-ios/commit/73a0c75fc): an empty list under an active search, filter chip or
space filter is a real answer, not a not-yet-loaded one; it goes to
`.rooms` (empty-filter state / hidden-behind-search), which keeps the
searchable modifier mounted, so cancelling the search re-applies `.all`
and the rooms come back. `RoomSummaryProvider.setFilter` now logs
`"<name>: Applying filter ..."` so a future emptying names its trigger.
Yesterday's occurrence (emptied at the first sync response after a
restart, no death logs) fits the same shape.

Slow launches: [`15e7a42e0`](https://github.com/element-hq/element-x-ios/commit/15e7a42e0) first tried a "Loading..." modal once the
session restore took over 1s (a store migration leaves the static
splash up for seconds, which reads as a hang and invites a force-quit
mid-migration). Reverted in favour of the design's own answer, the
skeletons: the splash gate from [`5ae04e03f`](https://github.com/element-hq/element-x-ios/commit/5ae04e03f) (hold the splash until the
cached room list has published, 700ms cap) is backed out, so the home
screen mounts as soon as the session is restored and shows skeletons
until the first summaries land. Caveat: a store migration runs inside
the client build, before any session UI exists, so during that phase
the splash is still all there is.

Manage storage bar colours ([`579a0078b`](https://github.com/element-hq/element-x-ios/commit/579a0078b)): the decorative pastels are
replaced with Compound core palette tokens, `blue-800` (message keys),
`green-800` (room state), `pink-800` (messages), `purple-800` (media),
`fuchsia-800` (logs). Gotcha: the core scale *inverts* in dark mode
(`yellow-500` is #FBCE00 in light and #5C2400, a dark brown, in dark;
`green-700` goes dull), so the bars resolve each token at its light-mode
value in both themes; a chart palette shouldn't flip with the theme.

Also confirmed: [`b8f5db3bf`](https://github.com/element-hq/element-x-ios/commit/b8f5db3bf) (snap, don't animate, the sender header away
when an older same-sender message is inserted above) covers inline gap
resolves too, since it sits in `TimelineViewModel.updateViewState`, the
one regroup path every applied diff goes through. Residual: the item
*above* a resolved gap can still animate its corner radii
(`.last` -> `.middle`), no header or layout shift involved.

## Round 17: spurious slide at every gap resolution

Symptom (screen recording, GNOME Newcomers, 2026-08-17): scrolling up
into a gap, the rows below the spinner slide up by the spinner's height
(sender header of the top message disappears, the day divider
crossfades), then ~0.3s later the fetched content lands in place. Frame
analysis of the recording (60fps strips) plus the device log show the
sequence exactly: every `Finished resolving timeline gap` is followed by
`Timeline(live) applied ["Remove(1)"]` and, 10-20ms later, a second
apply with the inserts (`["Insert", "Set(1)", ..., "Set(0)"]`).

Root cause (SDK [`e83dfeaf3`](https://github.com/matrix-org/matrix-rust-sdk/commit/e83dfeaf3)): `Timeline::resolve_gap` refreshed the gaps
snapshot synchronously right after the event cache resolved the gap
([`ce16d5247`](https://github.com/matrix-org/matrix-rust-sdk/commit/ce16d5247), added to reach the room start when the last leading gap
resolves). That commits a transaction of its own that removes the gap
item, racing the event subscriber task that applies the fetched events'
diffs a moment later. EXI's policy is to animate pure spinner removals
([`912c06177`](https://github.com/element-hq/element-x-ios/commit/912c06177)), so the removal-only batch is precisely the case that
slides; the content batch is then applied unanimated and pinned. The
events update already reads the current gaps snapshot and applies diffs
and gaps in one transaction, and the trailing `UpdateTimelineGaps` update
settles the timeline start, so the eager refresh was redundant. Dropped
for resolutions (kept after paginations, which only ever add gaps); the
regression test now asserts the gap removal and the event insertion
arrive in the same batch.

Not a bug, for the record: the floating date badge in the same clip
tracks the timestamp of the topmost visible row (the "Monday 10 August"
divider belongs to older content that landed above the viewport), and
the first 0.3s of the clip is the overscroll rubber-band settling, not
an animation.

Side note from the same log: `duplicate read receipts in this timeline`
ERRORs dump the whole item list, 400-700KB per line, dozens of times a
minute in busy rooms (68MB of log in an hour). Trimmed in SDK
[`3af5613ce`](https://github.com/matrix-org/matrix-rust-sdk/commit/3af5613ce): the duplicates field already names the events; the items
dump is gone. Whether the duplicates themselves are a preview-prefill
artefact (gaps, prefilled receipts) is still open.

## Round 18: pushed message takes ~40s to show after opening the app

Report: a push arrived (with the message), the app was opened without
tapping it, and the message only appeared in the room tens of seconds
later. Logs `console.2026-08-16-16.log` + `nse.2026-08-16-16.log`, room
`!KzalCNJxkqtytlbQvX:matrix.org`, event at 15:40:54Z.

What happened, in order:

- 15:40:45 app foregrounded, no network for 5s; 15:40:50 sync starts.
  First request 401s (the NSE had rotated the OAuth token; the app
  refreshes and retries at 15:40:52.8: 2.3s lost).
- Catch-up sliding sync responses from matrix.org: 11s (26 rooms), then
  15.6s (75 rooms), then 7s (28 rooms). Client-side processing 1-1.6s
  each. Pure server latency for a 6155-room account after a background
  spell; nothing new, this is the cost the paginated-sync experiment
  targets.
- 15:40:54 push. NSE's sliding sync attempt (single room subscription,
  4s budget) *timed out* client-side; fell back to `/context`, which
  answered in 1s; notification delivered at 15:41:00.
- 15:41:20 room opened from the list, timeline built from the cache
  (older tail). The room wasn't in the list ranges of the in-flight
  catch-up, so it only rode on the third request as a room subscription:
  response 15:41:29, event in the timeline 15:41:31, i.e. 11s after
  opening the room and 37s after the push. Typing had started at
  15:41:23, so the reply was composed against a stale timeline.

The gap that's ours: the NSE only prefills the shared event cache on the
sliding sync path (`ingest_into_shared_event_cache`); the `/context`
fallback, which is what a slow server makes the common path, persisted
nothing. SDK [`d00a5b4d6`](https://github.com/matrix-org/matrix-rust-sdk/commit/d00a5b4d6): persist the `/context` event as a limited
batch at the room's tail behind the `/context` prev-batch token, unless
the store already knows it or already holds something newer for the room
(delayed pushes for old events must not land at the tail). Test covers
both. Effect: opening the room shows the pushed message from the cache
immediately; the app's own sync deduplicates it when it finally arrives.

Not addressed: the server-side catch-up latency itself, and the fact
that opening a room mid-catch-up can't jump the queue (the subscription
rides on the next request; the SDK's skip-over-iteration only helps
while a request is in flight and the answer here was already landing).

## Round 19: reply preview attributes a redacted message to the redactor

Report: reply to an event, have someone else redact that event, and the
reply's preview shows the redacted message as sent by the redactor. SDK
[`9e85204c8`](https://github.com/matrix-org/matrix-rust-sdk/commit/9e85204c8): `handle_redaction` built the "redacted" placeholder pushed
into the replies from the redaction's own context (sender, profile,
timestamp). It now takes them from the redacted event's timeline item,
or from a reply's already-loaded details, and otherwise leaves the
replies alone (their details are fetched from the redacted event, which
carries the right sender). The upstream unit test redacted as the author
and so couldn't see it; it now redacts as someone else and asserts the
sender and timestamp. Upstream bug, straight port.

## Round 20: media pagination walks into the gaps

Question: does the Media & Files grid resolve the room's gaps to find
media hidden in them, and does overswiping past the oldest item in the
viewer still paginate rather than hard-stopping? Grid: yes, gaps render
as spinner cells (unanchored ones at the newest end, so a room with
cached text but no cached media shows a spinner, not the empty state;
pinned by SDK test [`cd586ceb1`](https://github.com/matrix-org/matrix-rust-sdk/commit/cd586ceb1)) and each visible spinner re-requests its
resolution every 2s. Viewer: the hard stop only applies at `.endReached`.
The catch: for a message-types timeline `.endReached` meant "store
exhausted", so at the oldest *cached* media with a gap still above it,
the viewer stopped dead and only the grid's spinner could make progress.

SDK [`07fc90598`](https://github.com/matrix-org/matrix-rust-sdk/commit/07fc90598): once the store is exhausted, `paginate_backwards` on the
message-types view resolves the next gap back (the newest gap older than
the oldest exposed event, or the newest gap at all when nothing matches
yet), one request per call, and only reports the room's start when no
such gap remains. Both EXI drivers already loop on `.idle` (viewer:
`paginateIfNeeded` on each state change while the placeholder is
current; grid: `backPaginateIfNecessary` at the top), so an overswipe
now walks back through text-only history until the next media appears,
or hard-stops at the real start of the room. A resolution already in
flight (a spinner's) is awaited instead of being reported as no
progress, so nothing spins. Tests updated on both crates.

## Round 21: gap resolutions jumped the timeline; leading-gap spinner

Two recordings in a room with a heavily fragmented store (limited syncs
had stacked gaps: `[events][gap][gap][gap][empty][gap][events]`).

(a) "Spinner at the top I can't scroll past, three times": the storage
walk had genuinely exhausted the store (chunks loaded down to the first
one in ~1.5s, oldest chunk = a gap), so what showed was the room's
*leading* gap spinner, resolving over the network 300-500ms per hop and
re-appearing with its next token: normal network back-pagination, not
cached history hidden behind a spinner. Nothing to fix there; the sync
fragmentation is what makes it look odd (five gaps resolving at once).

(b) "Massive scroll jump while several inline spinners resolved":
resolving a gap on top of loaded history returns mostly events the
cache already holds behind the gap, plus a couple it missed. The SDK's
network-pagination dedup removed every known duplicate and re-inserted
the whole batch in place of the gap (`Remove(38..22)` then 20 inserts in
the log): correct order, but a run of rendered rows vanished and came
back, and the table's scroll anchor went with it. SDK [`e553d7414`](https://github.com/matrix-org/matrix-rust-sdk/commit/e553d7414) +
[`40b80d934`](https://github.com/matrix-org/matrix-rust-sdk/commit/40b80d934): when the batch orders the known events as we do, they stay
put as anchors; runs of new events are inserted before the anchor that
follows them, the run newer than every anchor takes the gap's place,
gaps sitting between the oldest anchor and the resolved gap are dropped
(the batch spans them), and the older-history token is dropped (it
points into history we hold). Older new events with a token to follow,
or a disagreeing order, still take the legacy path. Net diff for the
recorded case becomes two inserts instead of 18 removes + 20 inserts.
Two regression tests.

## Round 22: launch-time re-benchmark (2026-08-17)

Same method as the 2026-08-10 round (four kill+relaunch cycles ~12s
apart, phone console log, LaunchMetrics + first-app-log-relative
phases). Before the fix: `rooms_shown_ms` 384-528 (was 198-205). Every
phase up to "room list `loaded`, sync starts" was unchanged (+87-90ms
after first log, as before); the whole regression was the first
64-room summary page: **243-258ms, was ~30ms**.

Cause: SDK [`b69d40ecd`](https://github.com/matrix-org/matrix-rust-sdk/commit/b69d40ecd) (round 19, latest-event thread root through
edits) resolved an edit's original via `Room::event_cache()`, which
creates the room's event cache when it isn't loaded, loading the room's
last chunk from the store while holding the event cache's global write
lock. On the launch page one busy bridged room's last chunk took 117ms
(+25ms for another), and the other 62 summaries queued behind the lock.
SDK [`a14651a2d`](https://github.com/matrix-org/matrix-rust-sdk/commit/a14651a2d): read the original straight from the event cache store
(read-only, dirty lock fine); no room cache is created.

Post-fix (build 55): `rooms_shown_ms` 347-384; the 64-room page still
reported 202-231ms. New per-batch diagnostics (EXI [`ab4232f14`](https://github.com/element-hq/element-x-ios/commit/ab4232f14),
`SummaryBuild:` line) split it: the summaries themselves finish ~50ms
after the list loads (FFI 300-480ms of work across 8 concurrent tasks);
the other ~150ms is `updateRoomsWithDiffs` waiting for its hop back to
the main actor, which is busy mounting the home screen's skeletons and
tab bar. That is the round-16 back-out of the splash gate
([`5ae04e03f`](https://github.com/element-hq/element-x-ios/commit/5ae04e03f), held the splash ~until the cached list had published, so
the build ran on an idle main thread and the home screen mounted
straight into rooms): the 2026-08-10 numbers were taken with the gate
in place. The gate never covered the store-migration case (that runs
inside the client build, before any session UI), so restoring it costs
nothing there; without it a launch is skeletons for ~150ms and rooms at
~350ms instead of ~200ms. Product call.

Also seen, not regressions: the encryption
sliding-sync connection restarts with `pos=None` on every launch and
marks all tracked users dirty (five ~1MB `/keys/query` per launch,
`bytes_down` 2-4MB, upstream behaviour); the room-list connection's
first response is server-bound (0.9-8.3s on matrix.org this round),
which is what `stale_exposure_ms` now measures on a busy account.

Decision: [`da464bc52`](https://github.com/element-hq/element-x-ios/commit/da464bc52) reverted; the splash gate
([`5ae04e03f`](https://github.com/element-hq/element-x-ios/commit/5ae04e03f)) and the >1s loading modal
([`15e7a42e0`](https://github.com/element-hq/element-x-ios/commit/15e7a42e0)) are back: rooms at first paint,
summary build on an idle main thread. Round-16's skeleton-deadlock fix
([`73a0c75fc`](https://github.com/element-hq/element-x-ios/commit/73a0c75fc)) is unaffected.

Follow-up: the >1s "Loading..." modal is replaced by skeletons on the
splash itself after 500ms of restore (`SplashScreenCoordinator.showSkeletons`,
same placeholder cells as the home screen's `.skeletons` mode, no
session needed, so it also covers a store migration inside the client
build). Build 58 re-benchmark: `rooms_shown_ms` 194-221, first 64-room
page 39-45ms, i.e. back to the 2026-08-10 numbers.

## Round 23: false "beginning of the room", take two (2026-08-17)

Report: The Element Moving Moving Club (`!xIxvCULkoSgHpgZsYg:matrix.org`,
a tombstone successor) showed "This is the beginning of ..." above a
message from last Wednesday, with a week's older history below it out of
order and gaps still open. Log `console.2026-08-17-19.log` 18:00:55Z (and
the same room at 17:30:51Z in the 18h file): the storage walk exhausted
the store (28 chunks, ids all over the place: `70 66 67 64 58 52 53 54 50
22 23 25 31 37 14 27 33 39 41 43 45 71 73 74 9 8 29 35`), the first
chunk being a plain events chunk with no predecessor -> `StartOfTimeline`
-> `PushFront` of the timeline start, while gap resolutions were still
in flight and inserting 20-event pages *below* that head. The store is
misordered from the pre-round-15 builds (the Aug 12 chunk sits in front
of Aug 11 ones; visible already in `console.2026-08-16-13.log`), and its
former leading gap has been dropped by one of the redundant-gap paths
(all-duplicates, overtaken gap, anchored resolution): each of those
drops a gap on the strength of "another gap reaches that history", which
is fine for reachability but leaves an events chunk at the head that
`load_more_events_backwards` then took for the room's start.

Fix SDK [`f5574914c`](https://github.com/matrix-org/matrix-rust-sdk/commit/f5574914c): the storage
walk applies the same rule as the network path
(`push_backwards_pagination_events`' `!has_gaps`): a gap-free head is
only the start once no gap is left anywhere. With gaps remaining, an
exhausted storage now resolves the oldest remaining gap over the network
(new `LoadMoreEventsBackwardsOutcome::ResolveGap`) instead of claiming
the start; a chunk loaded with no predecessor only reports
`reached_start` when no gap is left; and `resolve_gap` resets the sticky
"start hit" pagination status when its resolution didn't reach the start,
so the next pagination re-evaluates. Net effect on the phone: at the top
of such a room the spinner keeps going and the remaining gaps fill in
(one `/messages` per pagination), and the start item only appears once
history is fully accounted for. The misordering itself is persisted
damage from before build 41; a clear-cache heals it, the fix stops it
from lying about the start. Regression tests in the event cache and the
timeline (see commit). Storage-only pagination doc updated: it now has
two network exceptions (empty room bootstrap; remaining gaps at store
exhaustion). EXI unchanged (build 59 = SDK f5574914c).

## Round 24: room key ~21s late after foregrounding (2026-08-18)

Report: a UTD in a room preview after the morning foreground; open the
room, still UTD; back to the list, still UTD; open again, decrypted
(`!ZCWYLfAKXolsPWObuZ:matrix.org`, `$c0OOkKuX…`, console.2026-08-18-07.log).
Timeline: foreground 06:53:48.6; encryption sliding-sync connection
starts with `pos=None` at 06:53:48.9 (every launch), which marks all
tracked users dirty and fires five ~1MB `/keys/query` (1.3s, 2.3s, 5.6s,
10.5s, 22.5s); its first sync response, carrying the room key, came back
at 06:53:48.955 (54ms) but was only handled at 06:54:11.558, i.e. once
the slowest `/keys/query` returned: `SlidingSync::send_sync_request`
awaited the concurrent E2EE requests *before* handling the response. The
room-list sync delivered the message at 06:53:50 (UTD), the user opened
the room at 06:53:56, went back at 06:54:10.85, the key was processed at
06:54:11.56, the redecryptor re-decrypted the event and the latest-event
value was persisted at 06:54:11.58 (`Persisting new latest-event values
rooms=1`, right after the room's `retry_decryption`), the room was
reopened at 06:54:14.3. So the preview *did* update, ~3s before the
reopen; the whole 21s was the deferred response handling, not a missing
room-list update.

Fix SDK [`41edd7f48`](https://github.com/matrix-org/matrix-rust-sdk/commit/41edd7f48): handle the sync response first,
then wait on the outgoing E2EE requests (still before the next iteration,
so batches never overlap; still aborted if the sync request fails).
Regression test with a 3s `/keys/query` and a to-device event in the
response (fails at 3.03s on the old order). One brittle test relaxed
(`/keys/upload` round-trips 3..=4 instead of exactly 4; the
duplicate-one-time-key assertion it exists for is untouched). Upstream
bug, upstream candidate. Remaining, upstream: the `pos=None` restart of
the encryption connection at every launch (round 22) is what makes the
batch that heavy in the first place. Build 60 = SDK 41edd7f48.

### The ~5MB of `/keys/query` per launch, in detail

Not fixed on the branch; recorded here so it can be taken upstream.

Mechanism. `EncryptionSyncService` builds its sliding sync without
`share_pos()` (the call is commented out in
`encryption_sync_service.rs` with "racy, needs cross-process lock"), so
the encryption connection's `pos` only lives in memory: every process
start (cold launch, background app refresh, foreground after a kill)
begins with `pos=None`. MSC4186 returns no `device_lists` changes for a
request without `pos`, so `send_sync_request` marks every tracked user
dirty (`sliding_sync/mod.rs:707`, "Marking all tracked users as dirty");
`OlmMachine::users_for_key_query` then chunks the tracked users 250 per
request (`MAX_KEY_QUERY_USERS`), which on this account is 5 parallel
`/keys/query`, each 0.4-1.2MB (~1000-1250 tracked users; the largest
users are big federated rooms), i.e. ~4.5MB and 2-22s of matrix.org
time per restart. The same happens after every silent session restart:
`SyncService` restarts both connections when either expires, so the
encryption connection loses its in-memory `pos` again.

This hour (console.2026-08-18-07.log), six batches ≈ 27MB in 40 minutes:

| when | trigger | batches |
|---|---|---|
| 06:15:02 | background app refresh | 10 requests sent (5 aborted with the loop, 5 re-sent), 5 answered, 4.1MB |
| 06:22:41 + 06:22:47 | background app refresh, then silent restart | 5 + 5, 4.1MB + 4.1MB |
| 06:47:34 + 06:47:40 | background app refresh, then silent restart | 5 + 5, 4.5MB + 4.5MB |
| 06:53:48 | foreground | 5, 4.1MB (the round-24 batch, slowest 22.5s) |

The doubles have their own cause: the room-list connection restored a
persisted `pos` (`667230561/…`) that the previous process had already
moved past (it used `667535803/…` for its last 3 requests but was killed
before the ack-gated persist, see the pos/event-cache ordering section),
Synapse had pruned the older position, `M_UNKNOWN_POS` → silent restart
→ second batch. So on this branch every background refresh that dies
mid-catch-up costs ~9MB the next time round.

The NSE is already exempt (`c187fef45`: a notification process only
decrypts, stale device lists can't make that unsafe), which is the
argument for the general fix: device lists only need to be fresh before
*encrypting*. Options, cheapest first: (a) mark users dirty but do not
issue the `/keys/query` until a room key is about to be shared with them
(lazy refresh; the SDK already re-queries dirty users before
`share_room_key`), so a launch that only reads costs nothing; (b) persist
the encryption `pos` under the existing cross-process crypto store lock
(the NSE takes that lock anyway, and its position is in-memory so it
never writes one), which removes the `pos=None` restart for the main
process entirely; (c) do not restart the encryption connection when only
the room-list connection expired. Any of these is upstream work; the
branch keeps the behaviour and only fixes the ordering (41edd7f48) so
the batch no longer holds the room key hostage.

### Fix: the encryption `pos` is now shared across processes

SDK [`7b0388401`](https://github.com/matrix-org/matrix-rust-sdk/commit/7b0388401): `EncryptionSyncService` builds its sliding sync with
`share_pos()` (option b above). The 2023 reason for leaving it off
("racy, needs a cross-process lock") no longer holds: the `pos` is
stored in the crypto store, is written only after the response has been
processed (immediately for a room-less response, see below), and a
foreign write (the notification process moved the position) is adopted
on the next request; two processes racing on the same position get
`M_UNKNOWN_POS` and restart, which is exactly what a non-shared `pos`
did on every start. Since Synapse deletes the whole connection on a
`pos`-less request for a known `conn_id`, the old behaviour also meant
the notification process destroyed the app's server-side connection at
every push. Synapse has no time-based expiry for a list-less connection
(only 7 days unused), so the encryption connection now resumes with
`device_lists.changed` after any pause, and the `/keys/query` sweep only
happens after a real restart.

Second half of the same commit: the deferred `pos` write of a response
without room updates keeps the previous target instead of the global
room-updates sequence, so the encryption connection persists at once
rather than after the room list's catch-up; otherwise a kill during
catch-up left a stale encryption `pos` on disk (the same mechanism that
produced the room-list `M_UNKNOWN_POS` doubles in the table above).
Tests: `test_encryption_sync_shares_pos_across_instances`,
`test_pos_of_a_room_less_response_is_persisted_at_once`. Upstream
candidate. Build 61 = SDK 7b0388401; validate: "Marking all tracked
users as dirty" no longer logged on foreground/background refresh, no
`/keys/query` burst, room keys arrive within the first sync round.

## Round 25: sub/superscripts full-size in previews (2026-08-18)

Reported: `<sub>` renders subscript in room previews (baseline shifted)
but at the row's full font size; same for `<sup>`.

Cause: `flattenedForPreview` swaps the parser's fixed `UIFont`s for
presentation intents so previews adopt the row font, and that swap
discards the 0.7x font the parser sets on sub/sup while the
`baselineOffset` attribute survives (Text honours it), hence the
half-applied look.

Fix EXI [`1d4d12138`](https://github.com/element-hq/element-x-ios/commit/1d4d12138):
runs carrying a `baselineOffset` get a `.caption` SwiftUI font in
`flattenedForPreview` (compound fonts are MainActor-isolated, the
extension is `nonisolated`). All flattened surfaces (room list, NSE,
thread list, pinned banner). `formattedPreviewCapabilities` test extended
with `H<sub>2</sub>O`. The ±6/-4pt offsets are left as-is (tuned for the
17pt timeline body; fine at bodyMD). Validate: subscript visibly smaller
in the room list. Build 62 = EXI 1d4d12138 x SDK 7b0388401, compiled and
signed but the phone was unavailable to devicectl; re-run
`build-install-exi.sh` when reachable.

## Round 26: permalinks not highlighting + UTDs that never resolve (2026-08-20)

Two rageshakes from build 61 (SDK 7b0388401).

### 7527: permalink opened the room but nothing was highlighted

Reported: a permalink to a message in another room opened that room at
the bottom with no highlight, so the link looked broken.

Cause: round 9's "open the room live when a notification tap targets the
newest message" (EXI 363b3b7f5) decided at `handleRoomRoute`, i.e. for
every event route, and the linked message happened to be the room's
latest. The skip was only ever meant for notification taps.

Fix EXI [`2707df925`](https://github.com/element-hq/element-x-ios/commit/2707df925):
`AppRoute.event` carries `openLiveIfNewest` (default false), set only by
`handleNotificationTap`; it travels through the ChatsTab entry point
(`RoomFlowCoordinatorEntryPoint.eventID`) and `FocusEvent` to the
decision, which is now `focusEvent.openLiveIfNewest && isNewest`.
Permalinks, search results and in-app event taps always get the focus
treatment. Tests `permalinkToNewestEventStillFocusses` /
`notificationTapOnNewestEventOpensLive` in RoomFlowCoordinatorTests.
Validate: tap a permalink to a room's newest message; it must be
highlighted. Notification taps must still open the room live with no
green flash.

### 7515: UTDs labelled "Historical messages are not available on this device" and not resolving

Reported: a room full of UTDs from 3-4 August that never resolve, all
labelled "Historical messages are not available on this device", on a
device with key backup enabled (v5) and verified.

Two separate SDK bugs, both ours:

**(a) The label.** `Room::crypto_context_info` reads the "backup exists
on server" answer cached-only since round 10 (12e2d0d8b, a hung
`/room_keys/version` had blocked first paint), but nothing on a plain
session restore ever asks the server for the backup version: the log has
no `/room_keys/version` at all in 27 minutes, the cache stayed `None` and
`unwrap_or(false)` turned every pre-device UTD into
`HistoricalMessageAndBackupIsDisabled`. Fix SDK
[`3fef1e98e`](https://github.com/matrix-org/matrix-rust-sdk/commit/3fef1e98e):
an unknown answer defaults to "exists" when backups are enabled on this
device (you cannot be enabled on a backup that isn't there), and
`Backups::setup_and_resume` warms the cache with a detached
`fetch_exists_on_server` when backups are not enabled (so the
unverified/not-configured labels are right too) without ever putting the
fetch on the render path. Items already classified keep their label
until rebuilt; the common case (backup enabled at restore) is now right
from the first paint. Upstream candidate.

**(b) The stall.** The keys for those UTDs WERE downloaded from backup
(`GET /room_keys/keys/!UnK…/<session>` 200, "Successfully imported room
keys" at 18:34:33, 18:34:43, 18:35:12) but nothing redecrypted the event
cache until the room was closed and reopened (timeline re-requests
decryption of the UTDs it shows): key to retry went from ~8ms before
18:30:32 to 25-27s after. At 18:30:32 the NSE had bumped the crypto store
generation and the app regenerated its `OlmMachine`. The event cache
redecryptor takes its room-key streams from the machine's store and only
re-obtains them when the old stream ends, which requires every clone of
the old machine to be dropped, and the FFI `SessionVerificationController`
holds a `UserIdentity` (hence the old machine's store wrapper and its
broadcast sender) for the whole app lifetime. No "Regenerating the
re-decryption streams" in the log, ever. Fix SDK
[`b1d3ac2d3`](https://github.com/matrix-org/matrix-rust-sdk/commit/b1d3ac2d3):
`BaseClient::regenerate_olm` broadcasts a regeneration event
(`subscribe_to_olm_machine_regenerations`) and the redecryptor loop
selects on it, rebuilding its streams and retrying in-memory UTDs, the
path it already had for a closed stream. `test_redecryptor` now pins the
old machine across the regeneration; it fails without the signal. Upstream
bug (the FFI pinning exists on main too), add to the queue.

Not fixed here: the pinned `UserIdentity` in `SessionVerificationController`
also means `isVerified()` answers from a pre-regeneration snapshot; worth
a look upstream but out of scope for the dogfood.

Build 63 = EXI 2707df925 x SDK b1d3ac2d3. Validate: open a room with
"historical" UTDs after a push arrived in the background, they must resolve
in place within a few seconds of the backup download (no close/reopen) and
the label while waiting must be "Unable to decrypt"/"Waiting for decryption
key", never "Historical messages are not available on this device" while
backup is enabled.

Addendum (same day): the setup-time warm of the exists-on-server cache in
3fef1e98e fired on every restore and broke ten backups tests that count
`/room_keys/version` requests. SDK
[`134f727b8`](https://github.com/matrix-org/matrix-rust-sdk/commit/134f727b8)
moves it on demand: `crypto_context_info` calls
`Backups::warm_exists_on_server_cache` only when the answer is unknown and
backups are not enabled on this device, deduplicated by an in-flight flag
(`test_warming_the_exists_on_server_cache_fetches_once`). Build 63 carries
b1d3ac2d3 (setup-time variant); with backups enabled the two behave the
same (no request at all), so 134f727b8 rides along with the next build.

## Round 27: invite screen shows the inviter twice, user ID not copyable (2026-08-20)

Reported (offline, 1:1 invite from a stranger): the invite screen titled
the room "Yea" with member count 0, then "Invited by Yea
@33yea34:matrix.org" underneath, and there was no way to copy the user
ID to check on them before accepting.

Cause: the DM layout required `isDirect && memberCount == 1`; offline (or
for a brand new invite) the preview is built from local invite state, so
the joined count is 0 and the check fails. The SDK names a nameless room
after its only known member, the inviter, hence the duplicate. The same
happens online when the inviter's client didn't set `is_direct` (we can't
tell from the logs which one it was here; the fix covers both). Upstream
has the identical check.

Fix EXI [`6159f5a72`](https://github.com/element-hq/element-x-ios/commit/6159f5a72):
`invitePresentsAsDM` = nobody but the inviter known in the room (count
0 or 1) and (the invite is direct, or the room's display name is just the
inviter's name/ID). Title, subtitle and the "Invited by" user ID get
`.textSelection(.enabled)` (long-press to copy, as on profile headers).
Two JoinRoomScreenViewModelTests; suite 10/10. Build 64 = EXI 6159f5a72 x
SDK 134f727b8. Validate: a 1:1 invite offline shows inviter as title +
user ID subtitle, no "Invited by" duplicate; long-press the user ID copies.

## Round 28: inline gap spinners pop instead of shrinking away (2026-08-20)

Reported (recording 15:13): a visible gap spinner resolved mid-viewport
and the fetched messages appeared above the "NEW" marker in one frame
while the spinner vanished; the newer rows stayed put. That is the round
2 addendum 3 policy (912c06177) working as written: only resolutions
that closed EMPTY took the animated apply, every content-inserting one
went unanimated + pinned, hence "sometimes they shrink correctly".

Evidence: BubbleAnim harness experiment 3 (private repo
element-hq/bubbleanim, `Sources/App.swift`) scripts a gap resolve
inserting three messages (one tall) with the spinner mid-viewport, at
the viewport top edge, just off the top, just off the bottom, at the
very top of the page, and during an in-flight scroll, under four modes:
POP (status quo, reproduces the recording), ANIM (animated `.fade`
batch, 0.1s ease-out), PRESIZE (ANIM with pre-measured row heights) and
SHRINK (pinned unanimated apply + the spinner snapshot shrinking away on
top). ANIM is clean in every visible-spinner position, mid-scroll
included: the fetched rows fade in while the older rows slide up and the
newer rows stay put (the flipped table measures its offsets from the
newest end). PRESIZE adds nothing; SHRINK still pops the older rows.
The round-18 "spasm without churn" recording could not be reproduced;
its two candidate causes are both still guarded (below).

Fix EXI [`9d3bee9d1`](https://github.com/element-hq/element-x-ios/commit/9d3bee9d1):
a resolution animates whenever its spinner is on screen AND the
identifiers newer than the gap are unchanged in the same apply (if they
changed, the newer rows would shift - that apply keeps the unanimated
momentum-preserving pin); visible identity churn still goes unanimated.
Off-screen resolutions unchanged (unanimated + pinned), so the
off-the-bottom / off-the-top / fling pins from rounds 2 and 18 stand.
Build 65 = EXI 9d3bee9d1 x SDK 134f727b8 (also carries round 27).
Validate: visible spinner resolving = spinner shrinks, content slides
in above, no jump below; spinner just past the top/bottom edge = no
movement; top-of-room spinner = fills in above without a jump; scroll
through a spinner mid-fling = no spasm.

### Round 28 addendum: the bubble below the spinner popped (2026-08-20 16:19)

Recording: the spinner closed empty and "I suppose it requires…" joined
richvdh's group above it, so its sender header vanished; the bubble
jumped UP by the header height in one frame, slid back down, and
snapped. Column scan of the recording: +30pt at the first frame of the
apply, back over ~80ms, snap to the original spot at the end.

Cause: the hosted cell content is pinned to the visual TOP
(66bea662f, for the status-row case where the change is at the
BOTTOM). A regroup changes the cell at its top: the content re-renders
short inside the batch while the cell frame still animates, so the
bubble rides the cell's moving top edge instead of staying on its
fixed bottom edge. Harness experiment 4 (bubbleanim) reproduces it
once the apply is driven from `updateUIViewController` like EXI (the
hosted views are already dirty and render inside the batch); with the
EXI-style `.animation(value: groupStyle)` on the header the bubble
moves 72px and eases back over ~0.6s.

Fix EXI [`99d488ebc`](https://github.com/element-hq/element-x-ios/commit/99d488ebc):
`EdgePinnedTimelineItemView` pins the content to the BOTTOM edge for
~0.5s after the item's group style changed (decided in body; onChange
fires a frame late), top otherwise - so a header toggling leaves the
bubble on the fixed bottom edge and a status/receipts row toggling
keeps the validated top pin. Harness: bubble within 2px across
regroup-on-empty-close, regroup-on-insert and pagination; TICK
unchanged. Also: the 0.1s `UIView.animate` wrapper around the visible
gap apply (1d478a346) cut UIKit's own row-height animation short - the
rows above slid linearly then jumped the remainder (visible in the
phone scan too); the apply now uses the plain batch duration, measured
smooth to the end. Build 66. Validate: spinner closing next to a
same-sender message = header fades, bubble below does not move, rows
above slide smoothly to the end; send a message = previous bubble's
status row still collapses without a dip (66bea662f case).

## Round 29: notifications vanish except the newest one (2026-08-20)

Symptom: a stack of missed-message notifications for one room collapsed
to the most recent one while being looked at (`!ZZVN…`, 17:20-17:22Z
deliveries, gone at the 17:24:40Z background refresh). Nightly keeps the
whole stack.

Cause: not an NSE or grouping problem (the NSE log shows "Delivering
notification" for every push). It is upstream's
`NotificationManager.removeDeliveredNotificationsForFullyReadRooms`
(899c33a5a, on `develop` too): on every sync update, rooms whose unread
count is 0 have their delivered notifications withdrawn, so a room read
on another client (EW here; the phone sent no receipt for it) stops
shouting. Two things made it look like a regression:

1. preview-prefill computes the unread count correctly (the NSE prefills
   the room's tail into the shared store and the scoped dirty-lock reload
   picks it up, so the own receipt resolves to 0), which is what lets the
   feature fire at all; develop's count tends to stay >0 for rooms not
   opened on the phone, so it rarely clears anything.
2. Upstream bug: the guard compared the notification's *delivery* date to
   the latest message's `origin_server_ts`; the newest notification is
   delivered a second or two after its event, so it always survived.

Fix: the NSE stamps the event's `origin_server_ts` into the notification
`userInfo` (`event_timestamp`, seconds) and the main app compares that,
falling back to the delivery date for older notifications; and the whole
removal is gated by a new advanced setting "Clear notifications read
elsewhere" (`removeNotificationsWhenReadElsewhere`, default on). Unit test
covers stale/fresh/legacy notifications and the setting. Validate: read a
room on EW while the phone has a notification stack for it = the whole
stack clears at the next refresh; with the setting off nothing clears; a
push arriving after the app's last sync is never removed.

### Round 29 addendum: nothing cleared on build 67 (2026-08-20 18:35Z)

Rooms read on EW (`#offtopic:continuwuity.org`, `!Kzal…`) kept their stacks
even after opening the app. The removal was hooked on
`ClientProxyAction.receivedSyncUpdate`, which despite its name is sent only
when the room list *state* becomes `.running`: once per resume (18:35:32Z),
before that sync's room batches and receipts were processed (18:35:36Z+),
and never again. The 17:24Z case only worked because the state flipped to
running after the receipt had landed. Now driven by the static room
summaries publisher (debounced 1s), and the manager logs "Removing N
notifications for fully read rooms" or "Keeping notifications for <room>:
unread=… lastMessageDate=…" so a stack that should have cleared can be
explained from the console log. Build 68. Validate as round 29.

### Round 28 addendum 2: the send animation regressed (2026-08-20 21:59)

`EdgePinnedTimelineItemView` bottom-pinned on any `groupStyle` change, but on
send the previous own bubble goes `.single -> .first`: no header toggle, its
status row collapses at the bottom (the 66bea662f case), so it must stay
top-pinned; bottom-pinned it was clipped at the top and slid back. Now keyed
on `shouldShowSenderDetails` flipping only. Build 69. Validate: send a
message = previous bubble still, status row collapses without clipping or
dip; spinner closing next to a same-sender message (round 28 addendum) still
fades the header without moving the bubble.

## Round 30: bounce when sending from the emoji keyboard (2026-08-20 22:22)

Symptom: sending a large emoji bounced the whole stack (up 12pt, down 19pt,
settle); text, multiline and thumbnails fine. Frame scan of the recording +
the phone log (`SendTransition: restore delta=0.0 tableH=363 viewH=444`,
then `restore delta=107 tableH=444`) show the trigger: the message was sent
from the emoji keyboard, and clearing the composer resets the keyboard type
(upstream #299, intentional: back to letters after a send), swapping in the
81pt-shorter letters keyboard. The view grows mid send transition, but the
composer had predicted no collapse (single-line), so the transition took
the stock path: compensated geometry restore + 81pt settle down, racing the
animated row insert sliding up.

Fix: `viewWillLayoutSubviews` promotes a single-line send transition to the
collapse path when it sees the view grow (expected delta := observed growth,
oversize + pin via the new `oversizeFrozenTable`), so the echo takes the
frozen apply (fade into the vacated slot, one settle) exactly like a
multiline collapse. Build 70. Validate: send from the emoji keyboard =
previous bubbles still, emoji bubble fades into the vacated space, single
settle; plain single-line and multiline sends unchanged.

## Round 31: thread contents very slow to load (2026-08-21)

Symptom: opening a thread shows its last few replies, then the rest trickles
in slowly; it felt like threads weren't using the event cache at all.

Cause: threads do have their own persisted linked chunks, but they were
only ever read one chunk deep before going to the network. Every *limited*
room sync that carries a thread reply stamps the room's `prev_batch` onto
the thread's chunk as a gap and shrinks it to the last chunk (the thread
gets the room's `limited`/`prev_batch`, not its own), and thread pagination
had no storage-only mode (`thread/pagination.rs`: "gaps are always
resolved over the network"). So opening a thread = last chunk from disk,
then a serial `/relations?recurse=true` round trip per 20 events before any
older stored reply is reachable: the inline-spinner gappy-timeline problem,
minus the inline spinner. Two extra taxes on top: an empty thread chunk
waited up to 3s for a prev-batch token that only ever arrives with new
activity in that very thread; and (upstream bug) a pagination "from the
end" that only returned already-known events dropped its token and claimed
the start of the thread, so a live-created thread longer than the batch
never loaded its root and showed a false "beginning of thread".

Fix (SDK): the room's storage-first machinery ported to threads.
`ThreadPagination::run_backwards_once_from_storage` walks the stored
chunks past gaps (whole chunks at a time, no network), exposes the gaps via
`ThreadEventCache::timeline_gaps()` (the same `TimelineGap` snapshot as the
room; observers pull it alongside every `TimelineVectorDiffs` update, and
an update with no diff means only the gaps changed), and only reaches the
network once the store is exhausted: remaining gaps oldest-first, then
"from the end" until the root leads; `reached_start` is never claimed
without the root leading and no gap left. `ThreadEventCache::resolve_gap`
resolves one gap on demand (in-flight dedup shared with the room via
`GapResolutionsInFlight`). The from-the-end all-duplicates page now parks
its token in front of the oldest known event instead of dropping it; the
3s token wait is skipped for threads. UI: thread timelines honour
`storage_only_pagination` (storage walk, gap items, `resolve_gap`), and the
thread updates task applies diffs + gaps in one transaction like live.
EXI: `threadTimeline` opens with `storageOnlyPagination: true`; the gap
item view and resolve action were already timeline-kind agnostic.
Regression tests: `test_storage_only_pagination_serves_stored_events_past_gaps`
(no `/relations` mock mounted = any network hit fails the test) and
`test_pagination_from_the_end_progresses_past_known_events`.

Build 71. Validate: open a long thread = its cached replies appear at once
(cold and warm), inline spinners where history is missing, scrolling up
walks the cache before touching the network; a thread created while the app
was live still reaches its root and "beginning of thread" only shows with
the root on screen.

## Round 32: network handover stalls + blank DM until a drag (2026-08-21)

Rageshakes 7542 and 7543.

### 7542: messages took ages to send walking out of Wi-Fi coverage

Per-request table from the log: the Wi-Fi went black-hole at ~12:16:18;
every request from then on (typing, the `/keys/claim` of the send, the
`/members` fetch, presence, both sliding-sync long-polls) hung for its full
30s/60s timeout, retried on the same dead interface, hung again, and the
whole lot only recovered at 12:17:19 when the Wi-Fi socket was finally torn
down, all in-flight requests errored at once and the retries went out over
5G and completed in under a second. iOS reported nine "reachable" path
updates during that minute (Wi-Fi Assist / interface set changes) that the
app ignored because the status never changed.

Cause: the SDK's `reqwest` pool keeps connections bound to the old
interface; a black-holed TCP/h2 connection is neither closed nor erroring,
so the only thing that ever notices is the request timeout, and the backoff
retry then reuses the same pool.

Fix (SDK): `Client::notify_network_change()` (FFI
`Client.notifyNetworkChange()`). `HttpClient` now keeps the `HttpSettings`
it was built from and a `watch` generation counter; on a network change it
rebuilds the `reqwest` client (fresh pool) and bumps the generation, and
`send_request_inner` races every in-flight attempt against that generation
so the request re-sends itself immediately on the fresh client without
consuming one of its retry attempts or any backoff delay. Covers sync,
sends, media, OAuth token refresh and the QR rendezvous channel (all route
through the one swappable client). Regression test
`test_network_change_resends_in_flight_request`.
EXI: `NetworkMonitor.pathUpdatePublisher` fires on every `NWPathMonitor`
update (reachable or not, with the interface list logged); `ClientProxy`
forwards each one to `notifyNetworkChange()`.

### 7543: DM opened to a blank timeline, appeared on the first tap-drag

The SDK delivered the 20 items 80ms after the open; a touch landed on the
table 60ms later, still before the items reached the table view through
SwiftUI, and nothing drew until the drag at +9s. The gappy-timelines round's
"cancelled drag" fix (6586deb77) gated snapshot application on
`tableView.isTracking || isDragging`; a finger merely resting on the table
(isTracking, no drag) parked the items, and a tap without a drag produces no
scroll callback to flush them. Gate on `isDragging` alone (the original
"actively dragging" semantics, on UIKit's self-clearing state). The second
open in the log, with no touch, rendered instantly, which is the tell.

Build 72. Validate: walk out of Wi-Fi coverage mid-send = the message goes
out within a second or two of the "Network path changed" log line rather
than after a 30s timeout; sync resumes on the new interface equally fast;
open a room with a thumb already resting on the screen = the timeline draws
immediately.

## Round 33: two spinners at the top of every thread load (2026-08-21)

Symptom: opening or scrolling up a thread showed a spinner, then the date
header, then a second spinner, then the messages.

Cause: round 31 made a thread whose store is exhausted behind a leading gap
resolve that gap over the network from the pagination itself, so the top
pagination indicator spun above the very gap item that was already
spinning for the same hole. The room never did this: once its storage is
exhausted, a leading gap is "the start as far as pagination is concerned"
and the gap item resolves it on demand.

Fix (SDK): threads follow the room's rule. Non-leading remaining gaps are
still resolved from the pagination (redundant-gap drops), as in the room.
`test_storage_only_pagination_serves_stored_events_past_gaps` now pins the
storage walk stopping at the leading gap with no network, then the gap
resolving on demand.

Build 73 (SDK only; EXI unchanged). Validate: thread loads show one inline
spinner per hole and no indicator above it; the hole still resolves on its
own while visible and the thread still reaches its root.

## Round 34: room preview stuck on "Waiting for message" for a decrypted thread reply (2026-08-21)

Rageshake-style report: a room's preview showed a UTD ("Waiting for
message") whose most recent message was a thread reply; tapping the room
went straight to the thread with the message already decrypted, so the
preview simply hadn't updated once the message decrypted.

Traced (SDK/main-app logs, room !rbxKpMQm..., session KTxua2/Y...): the
thread reply arrived as a UTD in a limited/gappy sync while the room was
backgrounded and became the room's latest-event (this branch lets a thread
reply be the room preview). The megolm key was later imported by the NSE (a
separate process) while the app wasn't running: no "Received a new megolm
room key" line ever appears for this session in the app logs, yet the key
was in the store by the time the room was opened. Nothing re-decrypted the
persisted UTD:
- the redecryptor's room-key stream only carries keys THIS process's
  OlmMachine receives, so an NSE import is invisible to it;
- the OlmMachine-regeneration path (the app's cross-process signal) only
  retries IN-MEMORY UTDs, and this one had been shrunk out to the store;
- a fresh process start loads with the key already present but nothing
  requests a retry for background rooms.
Opening the room instantiated its cache, loaded the chunk, and the
timeline's retryDecryption issued an explicit request_decryption that read
the store and decrypted instantly.

Fix (SDK): `Redecryptor::retry_persisted_events`, a store-backed sweep over
every encrypted room's persisted UTDs. Reads each room straight from the
store so it doesn't pull thousands of rooms into memory; only rooms with a
decryptable UTD get instantiated (when the decrypted event is written back,
which recomputes the latest-event and heals the preview). Runs once at
startup and on OlmMachine regeneration/Lagging, in batches of 20 with a
20ms pause. Regression test
`test_persisted_utd_sweep_heals_out_of_band_key`.

Build 74 (SDK only; EXI unchanged). Validate: a room whose preview is stuck
on "Waiting for message" heals on its own shortly after launch (or after
the NSE delivers a push) without needing to open the room; look for
"Swept persisted UTDs for redecryption" in the logs.

## Round 35: spinner before the thread root on reopen (2026-08-21)

Report: opened a thread, waited ages for it to load (/relations over a flaky
network), went back and reopened it. Second time it loaded fast from cache
but showed a spinner for ages before the root, then resolved it. It
shouldn't try to fill a spinner before the root of the thread.

Traced (room !SGNQGP, thread $q4XPKR6H): the thread is stored as
[gap][root, r1, r2] — a thread whose root arrived in a limited room sync
gets the room's prev-batch stamped as a gap that lands before the root. On
reopen, storage loaded the 3 events fast, then the storage-only walk loaded
the leading gap chunk and surfaced it (Insert -> 4 items = the spinner
before the root), and the UI resolved it with two /relations round-trips
(REQ-109/111) before dropping it. Nothing precedes a thread's root event, so
that gap is provably empty.

Fix (SDK): when the storage walk loads a gap chunk while the thread root
already leads the known events, drop the gap (and persist the removal,
healing the stored chunk) and conclude the thread start, instead of
announcing the gap and resolving it over the network. Regression test
test_storage_only_pagination_drops_a_gap_before_the_thread_root (no
/relations mock mounted = any network hit fails the test).

Build 75 (SDK only; EXI unchanged). Validate: reopen a fully-loaded thread =
no spinner before the root, no /relations; "beginning of thread" shows with
the root on screen immediately.

## Round 36: media viewer swipes into black; hard-locked at the ends (2026-08-21)

Two reports about swiping through images in the media viewer (QuickLook).

1. "Swipe 3 times fine, 4th swipe lands on black then the image appears."
   Not the QuickLook padding (100 placeholder slots each side, plenty). The
   underlying media-filtered timeline paginates *reactively*: the media view
   model only sent paginateBackwards/Forwards once the user landed on a
   `.paginating` placeholder page (already black). So each time the loaded
   media window was exhausted, a swipe hit black before the load fired.
   Fix (EXI): prefetch the pagination. When the current media is within
   `paginationPrefetchDistance` (5) of the loaded range's edge, kick off a
   pagination in that direction (if idle) so the next media's event is loaded
   before it's swiped onto. paginationEventLimit (20 events/batch) left as-is.

2. "At the oldest/newest media, don't hard-lock the swipe; let me overscroll
   a bit with an affordance that I've hit the end." The edge was pinned dead
   (contentOffset reset to the resting offset). Now rubber-band it with
   UIScrollView's own bounce curve (`rubberBandedOffset`) so the page gives a
   little and springs back — the standard iOS end-of-content affordance.

Build 76 (EXI only; SDK unchanged). Validate: swiping through a room's media
never lands on a black page (media loads ahead of the swipe); at the first/
last media the page rubber-bands and springs back instead of stopping dead.
The rubber-band constant (0.55) and prefetch distance (5) are tunable on feel.

## Round 36 follow-ups (2026-08-21)

- Crash on overscrolling the end: the edge rubber-band wrote `contentOffset`
  from inside the `contentOffset` KVO observation. The old hard pin wrote a
  constant (converges in one step); an offset-dependent write never settles,
  so the synchronous KVO callback recursed to a stack overflow. Guard our own
  write (`isApplyingRubberBand`) so the re-entrant callback is swallowed.
- "Blank on the 4th swipe" persisted because it was never timeline pagination
  (logs showed the current item is always a media item being refreshed once
  its file arrives, never a `.paginating` placeholder). It's the media file
  download outrunning the preload: only 3 items were fetched ahead
  (`builtPagesRadius + 1`). Raised to 8 (`neighbourPreloadReach`, nearest
  first). The timeline prefetch from round 36 stays (helps when the event
  itself isn't loaded), but the reach bump is the actual fix.

Build 77. Validate: overscrolling the first/last media rubber-bands without
crashing; swiping quickly through a room's images no longer lands on blank
pages. neighbourPreloadReach (8) tunable on feel/bandwidth.

## Round 36 follow-ups #2 (2026-08-21)

- "Remove the blank-on-swipe limit entirely": bumping the full-media preload
  reach only pushed the boundary out (blank moved from the 4th to the ~9th
  swipe). Real fix: serve a thumbnail until the full media loads. Preload every
  loaded item's thumbnail (small, usually already cached from the timeline)
  and return it as the QuickLook preview URL when the full file isn't ready, so
  a swipe lands on the thumbnail, not black. When the full media replaces an
  on-screen thumbnail, force a QuickLook page refresh (it won't otherwise: the
  page is "available"), tracked by `wasUpgradedFromThumbnail`. The arrival
  refresh now proceeds on any preview URL (thumbnail or full), so a page built
  blank shows its thumbnail as soon as that arrives.
- Overscroll: reverted to the hard pin. The rubber-band drove `contentOffset`
  from the `contentOffset` KVO observation, which fights QuickLook's own
  scrolling — that was both the crash (repeated overscroll) and the
  snap-back-mid-scroll jog. A smooth overscroll needs an approach that doesn't
  write `contentOffset` (native bounce via zero end-padding, or a pan-driven
  view transform); both need on-device iteration. Pin is stable meanwhile.

Build 78. Validate: quick-swiping through a room's media shows thumbnails
(sharpening to full) instead of blank pages; overscrolling the ends is a clean
stop with no crash.

## Round 36 follow-ups #3 (native bounce + bounded preload)

Two follow-ups after build 78 validated the blank-on-swipe fix.

- Native bounce at the timeline ends (the smooth overscroll left open in #2).
  The data source padded QuickLook's item count with 100 phantom slots each
  side so it never saw a content edge (hence the hard pin). Now, once a side is
  fully paginated (`endReached`), its phantom padding collapses to zero, so the
  last real item becomes QuickLook's own content edge and its scroll view
  rubber-bands and snaps back natively - no `contentOffset` writes, so no crash
  and no mid-scroll jog. Gated on having seen a real pagination state first,
  because `.initial` is `endReached/endReached` as a "don't paginate yet"
  sentinel and would otherwise collapse the padding at open. The controller
  carries the current item across the one-off index shift and reloads only when
  the count actually changes (normal pagination keeps it constant, so the
  padding trick still holds and zoom/playback aren't lost mid-browse). Hard pin
  removed. Regression test `endReachedCollapsesPhantomPadding` (11/11 green).
- Bounded the preload after a question about memory. The preview items are the
  paginated media-timeline window, not the full event-cache media index, so
  QuickLook is never pointed at thousands of thumbnails; the handles are disk
  file refs and QuickLook only decodes the ~2 pages around the current one, so
  there was no OOM path. Still tightened it: thumbnail preload now covers a
  window (+/-20) around the current item rather than every loaded item (the
  window grows into the hundreds over a long session), and the full-media
  neighbour preload dropped from 8 back to 3.

Build 79 (EXI 0dbd64d2a x SDK 35648826a). Compiled + signed for device; phone
unreachable at build time (tunnel down), install pending. Validate: overscroll
the oldest/newest media - it should rubber-band and settle with no crash and no
snap-back jog; blank-on-swipe stays fixed with the smaller preload window.

## Round 36 follow-ups #4 (thumbnail preload removed)

Device logs (build 80) settled the thumbnail question: zero preloaded
thumbnails ever reached QuickLook (grep of the controller's index/refresh lines
for `thumbnail.jpeg` = 0), and only 4 blank-landings in a whole session.
QuickLook renders file URLs only, and the thumbnail was fetched over the
network via `loadFileFromSource`, landing ~20s after the viewer opened - far
too late for a swipe - so it was pure overhead (a per-item network fetch that
was never shown). The perceived improvement in build 80 was the full-file
preload (3->5) plus the on-disk cache: a visited item never blanks again
(hence "occasional blank but doesn't repeat").

The in-memory image cache (what the timeline drew) only holds media near where
you were scrolled, so it can't cover the deep fast-swipe case where the blank
actually happens - bridging it to a temp `.jpeg` for QuickLook would only paper
over the first couple of swipes. Not worth it. So: dropped the thumbnail
preload entirely, put the full-media neighbour preload back to 8 (the earlier
sweet spot). The data source's thumbnail-URL fallback is left dormant (harmless)
in case a future bridge feeds it.

Build 81 (EXI x SDK 35648826a). Installed + launched. Net of round 36: native
bounce at the media-viewer ends (working well), and blank-on-swipe is rare and
self-healing via preload=8 + cache.

## Round 36 follow-ups #5 (adaptive directional preload)

Replaced the fixed symmetric neighbour preload (8 each side) with a directional
one that grows while a swipe is sustained. On the first open it's symmetric
(base 6 each way); once a direction is established the reach ahead grows (+4 per
same-direction step, cap 24) and the behind reach drops to 3, so the download
budget follows the user instead of straddling a moving target. Reverse
direction and it resets. The cap is deliberate: preloading is throughput-bound,
so queuing more than the network services before they're reached only spends
bandwidth on files the swipe may pass or that a reversal discards. The truly
fast deep swipe (swipe faster than the download pipe) stays unbeatable, but the
sustained-moderate-swipe blank should be gone.

Build 82 (EXI 09100f7a2 x SDK 35648826a). Installed + launched.

## Round 36 follow-ups #6 (snapshot-covered heal reloads, preload back to 3)

Between #5 and here (builds 83-88, commits 5a5d22735..a08f99aac) a blurhash
placeholder was tried and reverted: it forced a reload on nearly every arrival
(flash on every swipe), and a placeholder-from-the-timeline can only ever cover
the first couple of swipes anyway. Net of that detour: QuickLook's page for a
neighbour preloaded late is rebuilt by a resting, debounced `reloadData` (the
heal), and a rested-on blank is cleared by an uncovered `reloadData` on arrival.

The question this round: can QuickLook be made to swipe smoothly through a
gallery at all, given that it builds pages eagerly from `previewItemURL` at
build time, never re-reads a built page, offers no per-page invalidation (only
`refreshCurrentPreviewItem` for the current page and `reloadData` for
everything) and `reloadData` flashes the current page? Three options were on
the table: (A) hand QuickLook a renderable placeholder file per page, (B) keep
the reactive heal reload and live with the flash, (C) block the open until the
current item and its +/-2 neighbours are downloaded. (C) was written and
dropped within the hour: it holds the image you tapped hostage to four
downloads you haven't asked for, and a fast swipe outruns it regardless. The
fix is (B) plus a cover for the flash.

**Snapshot cover.** `TimelineMediaPreviewController.coverReload` takes a
`snapshotView(afterScreenUpdates: false)` of the page scroll view, inserts it
directly above that scroll view (below the navigation/tool bars, so their glass
keeps animating and the (i) swap stays live), calls `reloadData`, then polls
every 16ms and drops the snapshot the instant the rebuilt page has content
again; a drag also drops it, and a 1s cap covers page types it can't recognise.
The "has content" signal came from a device-side hierarchy probe (build 96):
on iOS 26.5 the pages ARE in-process - `_UIQueuingScrollView` -> three plain
`UIView` page containers (previous/current/next) -> `QLPreviewScrollView` ->
`UIImageView` (images) or `AVPlayerView` -> `AVPlayerLayer` (video). `reloadData`
empties the current container synchronously and repopulates it ~20-35ms later
for an image, ~50-130ms for a video, and the "content unavailable" placeholder
never appears during a rebuild (so polling for it, the first attempt, was
blind). Rendered = a NEW (identity-checked) visible `UIImageView.image` or an
`AVPlayerLayer.isReadyForDisplay` under the container beneath the view centre.
The arrival refresh (page already blank) stays uncovered: a snapshot of black
would only delay the media. Note the simulator is useless for this: on 26.5 it
hosts the whole QuickLook UI as one remote ExtensionKit scene
(`QLHostRemoteView` -> `CALayerHost`) with nothing in-process.

**Heal guard fix.** The once-per-rest guard keyed on `contentOffset.x`, which
QuickLook reuses after a reload, so it over-fired across different pages and
suppressed legitimate heals (the residual swipe-13 blank of build 94). Keyed on
the current item id now.

**Preload reach.** The adaptive directional reach (#5: base 6, growing to 24)
is gone; back to a fixed, symmetric, nearest-first reach. QuickLook only builds
media pages at +/-2, the download pipe is shared (a deep queue slows the
neighbours that decide whether the next swipe lands on media, and a concurrent
pool doesn't honour enqueue order), and a 24-deep queue on cellular is up to
~240MB for a gallery you may close after one image. Build 95's session showed
the cost side: 51 preloads for 31 items visited, 22 never looked at. First cut
was +/-3 (build 98), which brought back the reliable 4th-swipe black that
follow-up #1 had already diagnosed: the 4th item is only queued on landing on
the 1st, and at a ~1s cadence QuickLook builds its page (two swipes out) before
the download lands. Settled on 8 (build 99), the sweet spot #4 found.

**Measured (build 95, 27 swipes out and back, user saw no black and no
flicker):** 65/67 arrivals had their file present (the other 2 = the initial
item and a >10MB video, which the on-display load handles); 2 heal reloads in
the whole session, both covered. Build 96 (one forced covered reload per rest,
to sample the probe) produced the only black flash of the round, a reload
colliding with the next drag before the page repopulated - exactly the window
the rendered-page detection now closes - and one swipe-to-blank at a 0.6s
cadence with the file cached, which is QuickLook parking a page built mid-swipe
on its placeholder (pre-existing; the arrival refresh clears it). Build 97
(detection live, no forced reloads): 76 index changes, 2 heal reloads, cover
down after 17ms and 23ms, both `rendered`.

**Tidy-up.** All `PreviewDebug` logging stripped from the viewer (controller,
view model, data source), the dormant thumbnail-URL fallback and
upgrade-from-thumbnail refresh path removed from the data source/controller,
the hierarchy probe and forced-reload switch removed.

Build 98 (EXI b9b01c433 x SDK 35648826a); build 99 = reach 8 (EXI 5b3deb996).

## Media & Files: 4-5s to open, on the message-type index (SDK)

Regression report (round 37, 2026-08-22): tapping Media & Files in Room Info
took 3-4s, reproducibly, with the prewarm from Room Info in place. The log
shows the prewarm firing on the Room Info push (1.5s ahead of the tap) but the
two timeline builds taking ~5.8s between them, all of it in the SQLite store:

- `find_event_refs_by_message_types` ran `backfill_legacy_msgtypes` on every
  call, and that is a full `SCAN events` of the whole store (no index leads
  with `event_type`; the content blobs are read too): ~1.5s per call here, and
  the media view calls it twice (once outside the room lock, once under it),
  the files view once more. The "no-op once done" was the UPDATE, not the
  SELECT. Fixed: recorded once under the `msgtypes_backfilled` kv key, like
  the room event-size counters.
- `load_events_by_refs` looked the page's ~50 events up with `room_id = ? AND
  event_id IN (...)`. Once `ANALYZE` stats exist (the SDK runs `PRAGMA
  optimize`), the planner prefers the `(room_id, ...)` index over the `IN`
  list for a page-sized list and walks the whole room (a big room: ~2s),
  reproduced on a synthetic store. The refs are primary keys: dropped the
  `room_id` term so they're looked up as such.

Timers per open before the fix (UTC 09:59 / 01:25 / 01:54, all alike): find
1.5s + find 0.7-1.5s + load 2.2-2.5s for media, find 0.9s + load 0.2s for
files. Regression test `test_find_event_refs_by_message_types_backfills_legacy_rows_once`.
Expect the prewarmed screen to open instantly and the cold build to be tens of
milliseconds; check with the `event_cache_store.rs` `Timer _method_` lines
under `build > new{msgtypes=...}`.

SDK 891f0122f; build 101 (EXI unchanged a713b865f x SDK 891f0122f).

## Media viewer: directional preload, queued before the current item lands (EXI)

Round 38 (2026-08-22). Fetching ±8 neighbours (17 files) to view one item is
wasteful, and the question was whether ±3 (QuickLook's ±2 pages + a spare)
plus the covered heal reload would do. It doesn't, and that was build 98: what
bounds the reach isn't QuickLook geometry but download time × swipe rate.
Only first views download (the timeline/grid cache thumbnails, the viewer
needs the file; cached files are just a store read + temp file write), but
phone photos are 2-8MB and take 1-3s on cellular, so file n+3, queued on
landing on n and built into a page on n+1, has ~2s before the rest on n+2 is
the last chance to heal it. Reach 8 gives ~7s.

Changed in `TimelineMediaPreviewViewModel`:

- Opening: ±3 both sides (no direction known yet). After the first swipe the
  deep reach (8) only goes the way the user is heading, the other side keeps
  2: ~10 files in flight instead of 17, reversal waste gone. Direction is
  derived from the last preload centre by item id (pagination prepends items,
  indices shift).
- The neighbours are queued as soon as the current item becomes current, not
  once its own load has finished (the old `defer` ordering): the current
  item's load is started first so it keeps the head download slot, then the
  neighbours, then it's awaited. At open this is what QuickLook needs: it
  builds ±1/±2 the moment the first item lands, which is exactly when the
  old code only started queuing them.

Validate: swipe runs out and back at ~1s cadence, cellular and Wi-Fi; no
black pages on the 4th swipe onward; `Media viewer: healing ...` / `landed on
a blank page` lines rare; fewer `media/download` requests per viewer open
(up to 7 on open, then ≤1 new per swipe in the travelled direction).

## Media viewer: why it was always the 4th swipe (QuickLook snapshots every URL at load)

Post-mortem (2026-08-22) of the round 36 "swipe 3 times fine, 4th swipe lands
on black then the image appears". Two diagnoses were offered along the way and
both were wrong for the case reported: it wasn't timeline pagination (#1: the
current item was always a media item, never a `.paginating` placeholder), and
it wasn't download throughput (follow-up #1 / round 38 reasoning): the media
was already in the cache, a cache read lands in ~50-300ms, and the black came
no matter how long you rested before swiping. What the reach bumps (3 -> 8 ->
directional) actually did is explained below; they moved the boundary, they
didn't remove the cause.

**Mechanism.** QuickLook does not ask the data source for items lazily as
pages come within reach. The device logs show it calling `previewItemAt:` for
*every* index in the count at open (placeholder builds logged for 0...99 and
101...200), again on `refreshCurrentPreviewItem`, and again after every
`reloadData`; the hierarchy probe's three page containers (previous/current/
next) are which pages get *views*, not when the items are read. The per-item
answer is fixed at that sweep: an item whose `previewItemURL` was nil when
QuickLook swept it is "content unavailable" until the next refresh (current
page only) or reload (everything), however early its file arrives afterwards.
The item objects are reused across updates and the URL is computed from the
file handle, so a lazy read at page-build time would have found the file; it
didn't, so the URL is captured at the sweep.

Timeline of an open on cached media (device log console.2026-08-22-01,
00:07:14): open at index 100 with the current URL nil -> full sweep at +2ms,
before any preload has started (every neighbour nil) -> current item read from
cache at +170ms -> its arrival refresh at +380ms re-sweeps everything, by which
time the +/-3 neighbour preloads (also cache reads, +300ms) have URLs -> swipe
to N-1 at +2.6s queues N-4 and it lands in ~60ms, but the page on display is
fine so nothing refreshes or reloads, and N-4 keeps the nil QuickLook cached at
open -> its page is built blank -> 4th swipe lands on black -> the landing
refresh shows the file. Hence "4th" = reach + 1 exactly, independent of
waiting: the +/-reach items were rescued by the open-time arrival refresh
re-sweep (which is why +/-2 originally, +/-3 and 8 moved the blank to the 3rd,
4th and ~9th swipe), and nothing ever re-read anything beyond it. Preloading is
necessary (the URL has to be there when QuickLook looks) but never sufficient:
QuickLook has to be made to look again.

**Solution (as shipped, builds 95-100):**

- Heal reload: when a preloaded neighbour's file arrives while the user rests,
  one debounced `reloadData` (`TimelineMediaPreviewController`), ungated from
  the +/-2 radius precisely because the blank can be any item from the last
  sweep; the blank model (`builtBlankItemIDs`) is every item whose URL was nil
  at the last load/reload, and a reload is only issued if one of those now has
  a file. The current page's flash is hidden by a snapshot of the page scroll
  view dropped the instant the rebuilt page renders (~20-35ms images, ~50-130ms
  video).
- Landing reload: arriving on a page that is blank with its file present
  (the sweep caught it nil and no rest happened since) reloads uncovered.
- Preload: directional (8 ahead / 2 behind once a direction is known, +/-3 on
  open), queued before the current item's own load so the neighbours have URLs
  by the open-time refresh re-sweep. This is what makes the heal reloads rare
  (2 in 27 swipes in build 95), not what fixes the blank.
- Not taken: a renderable placeholder URL for every item so no sweep ever sees
  nil (blurhash, builds 83-88): flashed on every arrival and was reverted.

Still an inference rather than a direct observation: that QuickLook reads
`previewItemURL` (not just fetches the item) during the sweep. One line in the
SwipeTest harness (log every `previewItemURL` read by index in `ProxyItem`, run
on device) would show exactly which indices are read at open, on swipe and on
refresh/reload.

## Media view - Matthew's notes

My manual notes on the whole rigamarole above:

- the core problem is that QL materialises n-2 and n+2 images from its file list, and if the file doesn't exist at the point it attempts to preload them, it caches the negative and never tries again.
- refreshCurrentPreviewItem() doesn't fix that.
- therefore, if you hit a race with pulling an image out of the cache or downloading it (or QL wasn't told the URL when it was instantiated), you end up "swiping into black"
- the two fixes are either to then:
    1. reload the whole of QL if you ever swipe into black in order to force it to refresh and load the missing image (which is how my branch was previously working, but meant that you'd be guaranteed to hit this whenever you hit the end of the current range of file URLs you handed QL, meaning one in X swipes would always swipe to black.)
    2. spot when media which is n±2 of your current one has not yet loaded, and refresh QL when it does, so that rather than swiping into black you swipe into the now-loaded content.  However, this causes a nasty flicker to black for a few frames while QL reloads, which is pretty unpleasant.
- I tried fixing this by instead getting QL to display thumbnails or blurhashes even if the main content hasn't yet downloaded/decrypted-from-cache so worst-case you swipe to a thumbnail/blur. However, this was painful, because QL doesn't seem to have a way to reliably show thumbnails/blurhashes at the same size/shape as the full-res contents (so you have to gen transient blurhashes which are as big as the viewport), and more importantly I couldn't see a way to reliably swap between the thumbnails/blurhashes and full-res image reliably. And for that matter thumbnails & blurhashes don't exist on disk, so you'd have to mess around transitively generating them which feels pretty ugly.
- So in the end up I gave up and switched to making option 2 work better, with the fairly evil hack of papering over the flicker when QL reloads by taking a UI snapshot and temporarily freezing it over the top as QL restarts.  In practice, this actually works surprisingly well, and seems to have solved things.
- Finally, there's always a risk that if you swipe too fast you try to view a file which hasn't yet been downloaded/decrypted yet and so you swipe to black - but given it fixes as soon as you stop swiping, this doesn't seem too bad; it's the exception rather than reliably doing it 1 in N times, which just felt crap.
## Composer caret bouncing one line up while typing (EXI, round 39)

Symptom (recording 2026-08-22 15:29, editing a 12-line message): on most
keystrokes the green caret is drawn one line above the insertion point (same x,
one line pitch higher, 1pt taller) for 1-4 frames, then drops back. The text
itself never moves (whole-screen frame diffs: only the caret and the key
highlight change). The text view was just over the 250pt height cap (12 x 21pt
at content size M) so it was scrolling by ~2pt.

Not reproduced in the simulator with the same build (`0dbd64d2a`, composer
code identical to `7bb7688e7`): a minimal UITextViewWrapper harness
(`carettest/`, caretRect + cursor-view probe per frame) in fit / over-cap
regimes with `insertText`, `UIKeyboardImpl addInputString:` and the software
keyboard; nor real EX in the UI-tests mock room driven by XCUITest through the
software keyboard (default compose, edit mode, content size M, over-cap, human
typing pace) - caret y flat in all of them.

Prime suspect on the preview-prefill branch: `textViewDidChange` wraps the
text binding update in `withAnimation(.easeOut(0.1))` on every keystroke
(added for the line-growth tween), putting the whole SwiftUI update and the
representable's re-layout inside an animation transaction mid-edit.

Build 103: animate only when the laid-out text height changes (line added or
removed; `layoutManager.usedRect` compared with the last change), plain
binding update otherwise. Plus a temporary per-frame probe while the composer
is first responder: `CARETPROBE caret x,y h | cursor x,y h | off bounds
content len` (`MXLog.info`, only on change) and the `setContentOffset`
override's decisions, to distinguish a wrong `caretRect` (TextKit) from a
late cursor-view layout (UIKit) if the bounce persists. Strip the probe before
upstreaming.

Validate: edit or compose a message longer than the composer cap (12+ lines)
and type a sentence; caret must stay on the insertion line. If it still
bounces, pull the console log and grep `CARETPROBE` around the keystrokes.

Round 39, second recording (editing the MIDDLE of a long message, deleting):
caret drawn up to ~5 lines above for 3-6 frames per keystroke, sometimes off
the top of the field, later one line; text static. The displacement equals
the field's scroll offset, not a line count. Root cause found with the
`carettest` harness once the field was put in an HStack like EX's: on every
layout pass SwiftUI's stack probes the field with width 0, infinity and the
real width, and each `UITextView.sizeThatFits` resizes the text container,
which momentarily shrinks `contentSize`; UIKit clamps `contentOffset` (e.g.
146.7 -> 111) and the text view restores it a moment later. The cursor gets
laid out during that window and sits a scroll-offset too high until the next
layout pass. Upstream has the same measurement code; what makes it visible is
a scrolled composer (content over the 250pt cap), common when editing long
messages. Neither the keystroke animation nor the `setContentOffset`
override nor an unbounded measuring height changes the count (A/B in the
harness: ~13 transient offset sets per keystroke in all of them).

Build 104 (`1d50e73bc`): answer the 0/infinity width probes from the cached
height, and for the same width read the height off the live
`layoutManager.usedRect` (no container resize); only a width change still
measures. Harness: transient offset sets 378 -> 0 over 37 keystrokes, height
sequences identical to the measuring path for growth, trailing newlines and
empty text. Build 103's line-count-only animation stays (fewer animated
transactions, growth still tweens). CARETPROBE logging still in; strip once
validated. Upstream candidate (the measurement path is upstream code).

Build 104 feedback: caret bounces one line DOWN for a few frames when deleting
inserted linefeeds in a scrolled composer; separately the caret sometimes hops
to the end and the scroll offset jumps while deleting (not reliably
reproducible). Phone probe log (build 104): offset overshoot-and-return with
no text change (212->288, 314->397->329), one keystroke moving the caret six
lines, one-line-tall frames with the full text at edit entry (pre-existing).
Harness: deleting a line in a bottom-scrolled field clamps contentOffset the
moment contentSize shrinks; build 104's forced `ensureLayout`/`usedRect` in
`sizeThatFits` and in `textViewDidChange` (line-count animation gate) moved
that update ahead of UIKit's own caret update, so the cursor sat at its old
content position (one line below on screen) until the next pass.

Build 105 (`4f44e42c7`): no forced text layout while typing at all.
`sizeThatFits` reads UIKit's `contentSize` for the current width (a
programmatic text set calls `layoutIfNeeded` in `updateUIView` so the first
measure is right), the 0/infinity probes use the cached height, a width change
still measures. The binding update animates only while the field is under the
250pt cap (growth/shrink tween kept; at the cap nothing moves). Harness:
identical height sequences, zero offset transients. Probe now logs every tick
while cursor and caret disagree (`MISMATCHn`) and every `attributedText`
re-apply in `updateUIView` (the path that parks the caret at the end and
resets scroll), to catch the hop/scroll-jump reports. Upstream candidate once
validated; strip the probe.

Build 105 probe log (phone, editing a long message): `updateUIView
re-applies attributedText (attributes only)` on EVERY keystroke (len 919,
920, 921 ...), each followed by a transient content size (456/581/602 with
the offset clamped to match) and a cursor/caret mismatch. The binding value
we push in `textViewDidChange` is the view's text at that moment; the text
view's storage then drifts from it by attributes UIKit adds while typing, and
upstream's `textView.attributedText != text` check took the drift for a
binding change: re-setting the text resets the selection (restored after,
but the scroll offset and content size bounce) on every keystroke while
editing. That is the common root of the dips, the hop to the left of the
deleted text and the scroll jumps in edit mode.

Build 106 (`e6a4137e0`): the coordinator remembers what the wrapper last
pushed into or applied from the binding and `updateUIView` only applies a
binding that differs from that (edit/draft load, pill insertion, clear on
send, formatting toggle still apply). Upstream candidate; the probe line
now lists the attribute keys on both sides for the report.

Build 106 USER-VALIDATED ("totally fixed"). Build 107 (`6f0cf8c50`) strips
the CARETPROBE lines; behaviour unchanged. Upstream candidates from this
round: the binding re-apply guard (`e6a4137e0`, the bug) and not re-measuring
the live text view on every layout pass (`1d50e73bc`/`4f44e42c7`).

## Round 40: timeline stops responding to drags (rageshake 7549)

Rageshake 7549 (2026-08-22 14:56Z, build 107, SDK 891f0122f): in a room,
dragging the timeline did nothing at all; the status-bar tap scrolled to
the top (drag still dead), then the scroll-to-bottom button worked and
dragging was fine afterwards.

What the log shows (`console.2026-08-22-15.log`, room `!vuHhaspFFTUFPmqAaS`):
the room was opened at 14:42:38 and scrolled normally; a message was edited
and sent at 14:43:08 (no send transition: none of the `SendTransition:`
lines); the app was backgrounded at 14:43:19, then became active three
times for ~150ms each at 14:47:40-46 (home-indicator swipes, touches
landing on the root hosting view at y≈913-917 followed immediately by
`will resign active`), and came back for real at 14:55:05. From 14:55:11
to 14:55:25 a dozen touches began on `MessageTextView` cells with no
drag ever beginning: no `scrollViewDidEndDragging` read-receipt send
follows any of them, whereas after the bottom tap at 14:55:26 every
touch is followed by one. The status-bar tap (no app touch involved)
paginated and sent receipts normally. Nothing in our code gates the pan
gesture; `isScrollEnabled` is never touched; no in-flight send transition
or frozen geometry. The shape (touches reach the cells, UIKit's pan never
recognises, programmatic scrolls fine, clears when the overlay changes)
fits a gesture recogniser left mid-gesture (`.began`/`.changed`) somewhere
in the room screen's hierarchy after the rapid active/inactive flicks: a
stale recogniser blocks every non-simultaneous recogniser below it for
new touches. Which one, the log cannot say.

Diagnostics only this round (`32f90239f`, build 108): the existing
window-level `TouchDebug` line gains a second line, logged only when
something is off, naming every recogniser in the window currently in
`.began`/`.changed` (class@view:state), the hit scroll view's state
(enabled/tracking/dragging/decelerating/pan state/content vs bounds), and
ancestors of the hit view with layer animations in flight. On recurrence:
reproduce the dead drag once, pull the console log, grep `TouchDebug` for
`active=`.

## Round 41: media viewer shows the thumbnail while the full image downloads

Ask: tapping an image whose thumbnail the timeline has drawn but whose
full-size file has never been downloaded showed a spinner on black until the
file landed; show the thumbnail first, spinner over it, and swap the full
image in when it arrives.

`90edabed1` (build 109). When an item becomes current without a file, the
view model looks the thumbnail up in the in-memory image cache (the same
source/size keys the timeline, gallery and media-grid cells load with) and
draws it into a JPEG in a temp directory (removed with the view model) at
the media's own pixel size from the event's `w`/`h`, capped at 2048 on the
longest side (a file at the thumbnail's own size would sit tiny on the page
and jump when the media replaced it: QuickLook lays images out by pixel
size, native when they fit, fit-to-screen otherwise; the sim harness showed
a same-size placeholder to be pixel-identical in layout). The file is handed
to QuickLook as `previewItemURL` via `Media.placeholderURL`; the existing
`.itemLoaded` path then refreshes the black page (uncovered reload, page
blank anyway) and the download spinner stays up (`fileHandle == nil`).

When the file arrives, pages built from a placeholder (tracked in the
controller as `builtPlaceholderItemIDs`, recorded alongside the blank set
after every build) are not "unavailable" to QuickLook, so the arrival check
and file-loaded path take an explicit `upgrade`: `refreshCurrentPreviewItem()`
once resting, verified by watching the rendered page's image view / image
identity change within 1s, otherwise a snapshot-covered `reloadData`. The
resting heal reload also treats a placeholder page whose media has arrived
as healable. Log lines: `swapping the placeholder for the media`, then
`placeholder swapped after …` or `placeholder swap not detected …,
reloading`.

Device-unverified parts (build 109 is the test): that
`refreshCurrentPreviewItem` honours the URL change on device (sim: yes; the
fallback covers a no), and that the upscaled placeholder lays out exactly
like the media for portrait/landscape/small images. Scope: images and videos
(a video's poster thumbnail, then the player), current item only; no
blurhash fallback when the thumbnail isn't cached.

## Round 41 follow-ups: viewer opened on the wrong item; placeholders only for media that has to download

**Wrong item (builds 109-112, user: "tapping N-1 opens ~N-10").** Caught in
the build-111 log: the viewer opened on the tapped `$AjbFg` at QuickLook index
100, the media timeline's first `Reset(30)` arrived, and `handleUpdatedItems`
shifted the index by -25 onto `$LuhgO`. The round-36 padding-collapse code
moved QuickLook's index by the change in the data source's first index
whenever the item count changed; but a prepend the padding absorbs (that
first reset inserts the items older than the tapped one) moves the first
index without moving any page, so the shift was wrong whenever a count change
(the forward padding collapsing at the live end) coincided with it. Build 112
made it systematic by seeding the baseline. Fix `2eca4747a` (build 113): on a
count change, re-derive the current item's absolute index from the data
source (`previewIndex(of:)`: array index + effective leading padding),
falling back to the edge-following shift only on placeholder pages; the
baseline is seeded at build time. Pre-existing since round 36 (native
bounce); the new early reloads only made it visible. Logs: `item count A -> B,
… current index X -> Y`, `index i -> item`, `reloadData (covered:) at index`.

**Placeholders only when the media isn't cached (user rule).** Whether the
file is in the SDK's media store can't be known without an async store read,
so: the initial item's load starts at view model init, the QuickLook
presentation (`PreviewHostingController.viewDidAppear`) awaits the view
model's `initialPresentationGate` (load landed or 150ms), and only a load
still outstanding after that grace gets the placeholder (rendered
synchronously for the initial item so the first page is built from it;
async for swiped-to items and preload neighbours, which go through the
existing `.itemLoaded` refresh). Cached media opens straight to the file, no
spinner; uncached opens ≤150ms later on the thumbnail. Neighbours that have
to download get the thumbnail too, so a swipe lands on it.

Also in build 113: `TouchDebug` still logs the active-recogniser line from
round 40. Validate: tapping any item opens that item; uncached images open on
the thumbnail and sharpen in place; cached ones open directly.

## Round 42: viewer overscroll ("loading more" maze), and the wedges found fixing it

User: swiping off the oldest loaded media paged into a run of identical
"Loading more..." placeholders (the index-stability padding: 100 phantom
pages a side until that side reaches the end). Asked for one such page with
the elastic band beyond it. USER-VALIDATED on build 123 ("the backpagination
logic all seems to be working well now"). Commits, in order, each a
device-observed failure:

- `656dc2b44` (build 115; 114 was meant to carry it but the patch had
  aborted, only its log split `8e8c9a119` shipped): while on a "loading
  more" page the data source reports one page beyond the loaded items on
  that side (`isClampedToBackward/ForwardPlaceholder`, effective padding 1),
  so QuickLook's native edge bounce stops the swipe; when the page's items
  arrive the controller steps onto the newest of them (anchored on the edge
  item it paged off); back on media the padding returns. Each transition is
  a covered reload.
- `e7cd6c958` (116): watchdog kill on overscroll. Clamp/release ran inside
  QuickLook's index-change callback, and QuickLook drops an index write made
  from there, so the state toggled forever. Transitions deferred a run-loop
  turn, re-checking the page; a rate breaker stops any toggling.
- `2e8b59f5a` (117): stepping onto the arrived items never landed and the
  viewer ended on the room's first media (2018): QuickLook drops an index
  write beyond the count it last read (still the clamped count), so a larger
  index is set after the reload. And a page QuickLook built as "loading
  more" whose index now holds a media (absorbed by the padding since the
  build) is refreshed rather than clamped on.
- `49ff69188` (118): stuck unable to page either way after releasing the
  clamp: reload and the index jump in the same run-loop turn leave
  QuickLook's page queue wedged; the index is set 0.1s after the reload
  (upstream's `returnToIndex` uses the same remedy).
- `fbcecf7d3` (119): the step still dropped every time: the reload's own
  index callback re-clamped the transit page before the delayed set. While a
  move is pending the callback leaves the page alone; the landing re-runs it.
- `34989c881` (120): a blank video page (Feb 2025 mp4) that could be neither
  viewed nor left, swipes stuck midway: the stale-page refresh called
  `refreshCurrentPreviewItem` the instant the swipe landed, i.e. mid
  deceleration (the documented way to wedge QLPreviewController). It now
  waits for rest and uses the covered reload; the transit page is ignored by
  the index callback (its "loading" state had put a spinner over the cover).
- `6b887f8d3` (122): mangled view after swiping back from the placeholder
  (half-scrolled page, "Loading more..." title, spinner): the release
  reloaded one turn after landing, still decelerating. Clamp and release
  wait for rest too (`scheduleWhenResting`, `waitUntilResting(atIndex:)`).
- `5274de125` (123): stuck on a Sep 2025 image with no "loading more" page:
  the data source ignored any update in which its loaded items weren't a
  contiguous run of the new list (upstream), and the media timeline's
  dedup/backfill churn broke that 142 times in a minute, freezing the viewer
  at 9 items while the timeline went on to the room's start and reported end
  reached (padding collapsed). Such updates are now taken, re-anchored on the
  current item (or any shared item) so its index stays put, and the pages
  are rebuilt behind the cover at rest (`needsRebuild`).

Rules learned for QLPreviewController on device: never set
`currentPreviewItemIndex` from inside its index-change callback; never set
an index beyond the count it last read before a reload; never reload or
refresh while its pages are still decelerating; an index jump in the same
turn as a reload wedges the page queue.

Also this round: `d634097e6` (121) the thumbnail placeholder falls back to
the SDK's media store via the provider (400ms cap) when the in-memory image
cache (memory-only, short idle expiry) has let the timeline's thumbnail go.
Today's logs had shown zero placeholders ever rendered: every tapped item was
cached, every swiped-to download had no thumbnail in memory. Build 124 adds a
DEMO 2s delay on every full-size load (`fullSizeDemoDelay`, STRIP) so the
thumbnail and its swap can be seen at all.

## Round 43: thumbnail placeholder UX, and a faster tap-to-viewer

With the demo delay in, the placeholder was finally visible, and it showed
the approach's rough edges: a spinner sat over the thumbnail, QuickLook
re-animated its bar buttons and flashed the page black on the swap, and a
video's poster with no way to play it read as broken. Build 127
(`93cf06e2d`, with `460c6cf22` making the grace wait a 10ms poll: the
task-group race it replaced never timed out on device, so build 124's
presentation waited the whole 2s for the load):

- The placeholder only kicks in after a 300ms grace (was 150ms): cached
  media lands inside it and never shows one.
- No spinner over the placeholder. While it's up the header reads
  "Loading..." where the sender's name goes, and the filename shows under
  the page (it used to be blank until the file was ready).
- The thumbnail-to-media swap runs under the page cover (hides the black
  flash); the bars are left uncovered on purpose, their buttons
  re-animating is the cue that the media has arrived.
- Videos keep their poster placeholder (a black page is worse).

Tap-to-viewer timing, from the log of one open: tap, ~110ms building the
media timeline and view model (the only thing the timeline's spinner
covers), 300ms grace, then ~140ms writing the 2048px placeholder JPEG
synchronously, then QuickLook's presentation animation. Build 128: the
placeholder is prepared alongside the grace wait (a wasted temp file when
the media arrives in time) so it costs the presentation nothing, and the
timeline's tap spinner only appears if building the media timeline takes
more than 300ms, so it no longer flashes for the ~100ms cache-backed case.
Build 129 strips the DEMO 2s delay.

Remaining nit: the "loading more" spinner lingers a fraction of a second
after swiping away from the placeholder page.

## Round 44: the viewer skipped ~20 media on "Loading more", and the redecryptor lag behind it

Swiping back into history from the viewer sometimes landed ~20 items too
far (Jan 2026 straight to Dec 2024), the skipped media appearing behind the
user a while later. Builds 131-138, SDK `b80c5ff7a`..`2ed0284a5`.

How it skipped: the media timeline is the msgtype-filtered event cache
view, and /messages pages fetched ahead of their room keys are all UTDs,
invisible to a msgtype filter. A page of them looked like "no media here",
the viewer asked for the next page, and so on until the next *decrypted*
media, which it stepped onto; the keys then arrived from backup, the ~20
media between decrypted, and inserted themselves behind the current page.
Build 131's gap-aware step (`f9681ba7e`, don't step while a gap remains
between the edge and the target) never applied, the timeline-shape log
(`71ef1e0bd`, `M`/`G`/`U`/`P`/`S`/`D`/`o` per item, oldest first) showed the
gap only ever sits beyond the oldest item. First SDK fix, `b80c5ff7a`:
the room-key broadcast stream had capacity 10 and the ~117 single-session
backup imports of one swipe-back overflowed it, so the redecryptor hit
`Lagging`, swept all 6170 rooms' persisted UTDs (~11s) inline in its loop,
lagged again, swept again: the in-between media decrypted ~14s late.
Capacity 1024, the sweep off-loop and coalesced, faster batches.

The real fix (the user's idea: resolve the UTDs nearest first rather than
race the decryption): make the UTDs visible to the viewer. SDK
`0e0579380`, the filtered view's `matches()` accepts undecryptable events
("maybe media once the key arrives"; the decryption already replaces them
in place if media, removes them otherwise; test added), and `59f270858`,
the FFI `OnlyMessage` filter lets `m.room.encrypted` through (it was the
second filter hiding them, build 134 skipped exactly as before). EXI
`275671ca1`: a UTD of unknown cause between the current item and the next
older media counts like a gap for the step rule; while any such UTD sits
older than the oldest media, back-pagination is held (the nearest page's
keys get requested first, ~20 GETs instead of 117); final causes (withheld,
before-join, insecure device) are ignored at once, `.unknown` is given up
on after 5s (`pendingUTDWait`, timer re-evaluates the shape). `0992805e7`:
the hold was only re-evaluated on a pagination state change or a swipe, so
a text-only UTD page left "Loading more…" spinning until the user moved
(25s, 11s stalls in the build-135 log); resolved UTDs now re-trigger
pagination.

Then "largely works but very slow to backpaginate" (build 136, cleared
room cache, chatty room): ~1s per 20-event page, plus 5-7s stalls with the
give-ups stepping early ("a little out of order around Dec 2024"). The log:
keys arrived 0.19s (median) after each UTD was first seen, EXI applied
diffs in sub-ms, but the redecryptor itself fell behind: for every key
received it refreshes the encryption info of all already-decrypted events
of that session, one crypto-store lookup per event although the info only
depends on (session, sender); sessions of ~100 messages × ~300 backup
downloads = seconds. SDK `2ed0284a5`: one lookup per session. EXI
`0d32214de`: media timelines page 50 events (a text-heavy stretch is mostly
round trips). Build 138: no give-ups, ~1 page/s.

Remaining per-page cost, measured: a 50-UTD page resolves in ~2-3s because
the redecryptor replaces events one at a time (one store txn, one diff, one
EXI timeline rebuild each, 10-30ms per event: the `TODO` at
`redecryptor.rs:515`). Batching the replacements per key batch is the next
win. Upstream candidates: `0e0579380`, `59f270858`, `b80c5ff7a`,
`2ed0284a5`.

Asked: background auto-pagination to pre-index a room for media browsing
and search. Assessment: a low-priority "index to room start" request kind
on the `BackPaginationQueue` is small (paced, capped, resumable via the
stored gap tokens); encrypted rooms want `download_room_keys_for_room`
first (one GET for all the room's keys); local search would be a new FTS
index in the event cache store (same shape as the msgtype index); per-room
opt-in on wifi/idle, not all 6000 rooms. Suggested: an explicit "Load full
history" room action first.

## Round 45: redecryptor bulk replacements, the upstream merge, and a narrower UTD sweep

Three things, in order.

**Bulk replacements (SDK `0fd1acf75`).** The remaining per-page cost from
round 44: a room key resolves hundreds of UTDs and the redecryptor looked
each one up (one store query per event not in memory) and replaced each
one (one store transaction per event). New `EventCacheStore::find_events`
/ `save_events` (default looping impls; SQLite overrides with one `IN`
query and one write transaction, `save_event` now delegates to
`save_events`), `find_events` on the room state (one in-memory pass + one
store query), and the redecryptor uses both. Integration test
`test_save_events_and_find_events` runs against every store. Build 139.

**Upstream merge.** `origin/main` (87 commits, head `c260607d5`) into the
SDK branch -> `821ec9e95`; `origin/develop` (82 commits, head `1ba090b91`)
into the EXI branch -> `9cd67edf3`. Rule applied: where upstream solved the
same problem its way, ours goes; where ours goes further and the branch
still needs it, ours is rebased on top and flagged. Full report in the
session handover; the short version:

- Replaced by upstream's version (ours deleted): FFI state-listener replay
  (#6895), the thread-aggregator StateLock deadlock fix (upstream takes one
  all-states read lock), the redecryptor's resolve-once `on_resolved_utds`
  flow (our `replace_events` dropped; our bulk `find_events` + store
  `save_events` kept underneath it), MapLibre lazy loading (#6012, our
  `MapInterface`/`MapLibreShim` removed wholesale), crash-report prompt
  race (#6017), composer voice-mode crash (#6018), `cacheAccountURL`
  detach (#6019), deferred secondary summary providers (#6038), the #6045
  set (backup init check, empty-list flash, sync list mode, half-page
  prefetch + growth guard), identical-filter skip (#6016), tracing spans
  (#5996, `createSpan` is gone upstream), `truncate` diff (#6029), viewport
  re-check (#6056), inter-block whitespace (#6055).
- Ours layered on top (FLAGGED): HomeScreenViewModel keeps two guards over
  upstream's `combineLatest`/`hasRooms` mode logic (empty filter result ->
  `.rooms`, zero count only trusted while no rooms are published); the
  StateLock holder-registry ticket became `Option` like upstream's mapped
  guards' timer; OAuth refresh keeps upstream's lock ordering but our
  `cached_server_metadata()`; `root_leads` thread-start guard; both new
  `client_builder` options.
- Regenerated: `GeneratedMocks.swift` (sourcery), `project.pbxproj`
  (xcodegen), and `Components/SDKMocks/.../SDKGeneratedMocks.swift` against
  the local bindings (upstream's copy targets the released SDK; same
  recipe as `213cbe3e8`, output path is now under `Components/`).
- Tests on the merged SDK: event cache lib 113, integration 73,
  sliding_sync 62, base store 36, sqlite 96, ui timeline 227, redecryptor
  4, all green. EXI unit tests not run (snapshot re-record still owed).
- Build 140 tripped over a stale MapLibre precompiled module in derived
  data (the framework moved); cleared. Build 140f (after an SDK `username` -> `serverNameFromUserId` rename the pinned-SDK develop had not hit, EXI `c6cfceb47`) compiled and installed; VALIDATE on the phone.

**Narrower UTD sweep (SDK `5140c5839`).** The round-34 startup/Lagging
sweep scanned every encrypted room's persisted events and re-attempted
every UTD, i.e. thousands of long-term undecryptable messages on each
launch, for the one case it was added for (a room preview stuck on a UTD
whose key the NSE imported out of band). It now retries only each room's
latest-event UTD, read from the persisted latest-event value: no store
scan, one decrypt attempt per such room. Older UTDs are retried when the
room is opened (the `Timeline` builder retries every event) or by the
room-key stream. Test updated.

#3290 bookkeeping: `5859d1c52`/`5e55f53e9` (live visible-range publishing,
no growth on the initial empty range) look upstreamed by #6045 after all
(develop's `HomeScreenContent` reports through `didScroll`, the provider
has the `!range.isEmpty` guard); the merge hunks differed only by comments.

## Round 46: build 140f launched onto placeholders for 8 minutes (the version-bump VACUUM)

First launch of the merged build (`26.08.2` -> `26.08.4`) sat on the
app-level placeholder skeletons (no nav bar: the home screen was never
mounted) until the user gave up at +24s; the event cache stall diagnostics
fired from +10s on (`state (write) held by handle_joined_room_update` for
40s+, waiters in `run_request` and `root`) and the process was killed in the
background; the relaunch at +8min came up in 1s.

Root cause (log `console.2026-08-23-09.log`, 08:41:57Z): upstream's
`performUserSessionMigrations` (EXI `8a1d0fe8b`, Dec 2025) awaits
`clientProxy.optimizeStores()` on every version change, BEFORE the
`UserSessionFlowCoordinator` starts. `Client::optimize_stores` is a sqlite
`VACUUM` of the state, event cache and media stores in turn, and the SDK doc
on it says "**DO NOT use in production**". On this phone: 295MB state store
= 11s, then `Optimizing event cache store...` on the 835MB event cache never
finished (the 485MB media store was still queued). The VACUUM holds the
event cache's single write connection, so the first sync batch's
`handle_joined_room_update` parked on `send_updates_to_store` with the
global StateLock write guard held: that is the stall the diagnostics named
(holder `handle_joined_room_update`, not a nested-lock bug this time). The
migration never re-ran because `lastVersionLaunched` is stamped at app
start, so the VACUUM was simply abandoned (rolled back) on the kill.

Fix (EXI `HEAD`): the `optimizeStores()` call is removed from the migration
(comment cites the numbers). Upstream note: either drop it, or gate it on
`PRAGMA freelist_count` (don't rewrite 835MB to reclaim little) AND run it
detached after the home screen is up; but even detached, a multi-minute
VACUUM wedges the event cache behind the write connection, so the gate is
the important half. Build 141 = this EXI x SDK `5140c5839`.

Side observation on the 08:49:54Z relaunch: HomeScreen flashed "Showing
empty state" for 0.5s before "Showing rooms" (`loaded(maximumNumberOfRooms:
nil)` at +0.36s while the summaries were still building, `hasRooms` false).
Our zero-count guard trusts the count only while no rooms are published,
which is exactly this window; open nit, not a wedge.

## Round 47: viewer header lost to QuickLook's filename, galleries browsed inline, launch hitch trace

**Header showing filenames (EXI `383b7c761`, build 142).** The media viewer's
sender/timestamp header is installed as the navigation item's `titleView`,
but only from `viewWillLayoutSubviews`; QuickLook replaces its navigation
item on the same refreshes that re-install its list button (file loaded,
reloads, placeholder swaps), after which its own title (the item's
filename, `previewItemTitle`) showed until the next layout pass. Not a
merge change (the merge did not touch FilePreviewScreen); our reload-heavy
rounds (36+) made the swaps frequent. Fix: reapply the title view from
`updateBarButtons`, which already runs on exactly those swaps (KVO +
100ms timer fallback). "Loading…" over a thumbnail placeholder is kept
(the header text, not the QuickLook title).

**Galleries browsed inline (EXI `01f22400b`, build 143).** Tapping a tile in a
gallery message opened a viewer scoped to that gallery (paging trapped in
the subset). The tap already builds the room's media timeline, so galleries
now go through the timeline-spanning data source: `initialGalleryIndex`
picks the tapped attachment (whole gallery as the not-yet-loaded fallback),
swiping past either end continues to the adjacent media events, and the
header reads e.g. "Alice (2 of 3)" for gallery attachments (reusing the
pinned-banner "%1$@ of %2$@" string). The gallery-only data source / view
model inits and `displayGalleryPreview` are gone (-66 lines). Data source
tests adapted to the fallback path but NOT RUN: the local xcframework has
only the device slice; rebuild both slices before the next sim test pass.

**Launch after the merge (asked: "has launch time regressed? the launch
animation stutters more").** `LaunchMetrics` cold launches: 868/1156ms
(the 1156 = dyld-cold first launch after install) vs 693-935ms pre-merge
cold launches: time-to-rooms NOT regressed. Instruments Animation Hitches
trace of a cold launch of build 141 on the phone (`xcrun xctrace record
--template 'Animation Hitches' --device <UDID> --time-limit 12s --launch --
io.element.elementx`; export tables `hitches`, `potential-hangs`,
`life-cycle-period` via `xctrace export --xpath`): 13 hitches in the 1.2s
after the first frame: one 183ms "Potentially expensive app update" + 194ms
main-thread "Brief Unresponsiveness" at t+1.87s = the HomeScreen's first
render (53 rooms "Showing rooms" at t+1.90s; upstream's tab bar + Spaces
screen are built in the same instant), then 17-67ms hitches at t+2.1-2.9s =
the 64/100-room summary republishes during sync catch-up (SummaryBuild
ffi_total 93-436ms off-main, list diffs applied on main). Whether that is
worse than pre-merge needs the same trace on the pre-merge pair (EXI
`0d32214de`-era x SDK `2ed0284a5` xcframework, ~45 min of builds): offered,
not run. Gotchas: `xctrace record` keeps writing for minutes after "ending
recording" (export before `Output file saved` = "Document Missing Template
Error"); `time-sample` callstacks export as raw PCs (needs dSYM + slide to
symbolicate).

**Round 47 follow-ups (EXI `b33630f3e`, build 144).** (1) Swiping off the end
of a gallery landed on "Loading more…" with the neighbours cached: the
not-yet-loaded fallback held every attachment of the gallery while the media
timeline flattens galleries through `allowedGalleryItemTypes`, so the loaded
list never matched the fallback as a contiguous range and the merge took the
re-anchoring path, leaving the padding pages around the gallery. The fallback
is now filtered the same way (the filter derives from the tapped attachment's
type, so it is always kept). (2) Blank screen after the build-143 launch: the
install script launched the app via `devicectl` on the locked phone at
09:34:38Z; it ran in the background for 13s (splash root only; `start()` is
deferred to foreground), restored the session within 120ms of "will enter
foreground", yet the screen stayed blank until a background/foreground cycle
even though a touch at +7s hit-tested to the room list's `HostingScrollView`
(content 5371pt, tracking): drawn-nothing, not missing content. No cause
found from the log; `WindowDebug` now logs each window's
hidden/alpha/key/root on willEnterForeground + didBecomeActive (strip before
upstreaming). Reproduce with `devicectl device process launch --no-activate`
then activate.

**"Loading more…" off a gallery, the actual cause (EXI `HEAD`, build 145).** The
log (09:37:44Z) showed the merge never happened at all: `Ignoring update:
unable to find existing preview items range` twice after the media timeline's
`Reset(3)`. `GalleryItemID`'s synthesised equality covered the whole
`TimelineItemIdentifier`, including the per-timeline `uniqueID`, so the
tapped attachment (room timeline) never equalled the media timeline's copy
(the standalone `MediaPreviewItemID.timelineItem` already keys on the event
ID for exactly this reason, and the `GalleryItemID` doc comment promised
cross-timeline identity). Equality/hash now use event-or-transaction ID +
`mediaIndex` (whole identifier only for virtual items). The fallback filter
from build 144 stays (clean contiguous-range merge). Build 145 = this x SDK
`5140c5839`.

**Still no overscroll out of a gallery (EXI `5bc16305b`, build 146).** Build
145 merged fine (11:22:56Z: count 103 -> 3, current index 0, shape SDM) but
the media timeline built for a gallery tap was still filtered to
`msgtypes=[gallery]` (the pre-inline scoping in
`TimelineInteractionHandler.processItemTap`, comment and all), so in a room
with one gallery the timeline was that gallery's 3 attachments with both ends
reached: nothing to swipe onto. The tapped attachment index is now threaded
into `processItemTap` and a gallery tap filters like an individual tap of
that attachment's kind would (image/video -> `[image, video, gallery]`,
audio/file -> `[audio, file, gallery]`). Build 146 = this x SDK `5140c5839`.

## Round 48: media download + upload progress bars, retry for stalled uploads

**Download progress in the viewer (SDK `4ea0801f1`, EXI this round, build 148).**
Nothing in the stack reported download progress: the SDK's HTTP client only
streamed the *request* body (`send_progress`, for uploads) and read every
response whole with `bytes()`, so a full-size image/video/file in the viewer
gave no feedback until it landed (spinner or thumbnail placeholder + "Loading"
header). SDK: a receive-side observable (`SendRequest::with_recv_progress_observable`
/ `subscribe_to_recv_progress`); when subscribed, the native client streams the
body chunk by chunk with the `Content-Length` as the total (wasm keeps
`bytes()`); `Media::get_media_content_with_progress` / `get_media_file_with_progress`
thread it to the fetcher (`MediaFetcher::fetch_media_content` gains the
parameter, the content-scanner fetcher ignores it); FFI `Client::get_media_file`
takes an optional `ProgressWatcher` forwarded like the upload one (cached files
arrive without any update). Integration test `test_get_media_content_reports_download_progress`.
EXI: `MediaLoaderProtocol/MediaProviderProtocol.loadFileFromSource(_:filename:progress:)`
(`MediaDownloadProgressHandler`, a fraction on the main actor, throttled to 1%
steps in `MediaLoader`); the viewer's `Media.downloadProgress` feeds a
`ProgressView(value:)` along the bottom of the page (in `CaptionView`, above
the caption/toolbar) and replaces the centred spinner while a fraction is
known. Thumbnails deliberately NOT given a bar: their wait is time-to-first-byte
(auth, server-side thumbnailing), bytes would sit at 0 then jump to 100.
Unit test `downloadProgress` in `TimelineMediaPreviewViewModelTests` (sim
slice not built this round, NOT RUN).

**Upload progress on timeline media (same build).** The SDK already puts per-item
upload progress on the local echo (`EventSendState::NotSentYet { progress }`,
cumulative over a gallery's attachments) behind
`enable_send_queue_upload_progress`, which EXI never enabled and whose payload
`TimelineItemProxy.deliveryStatus` dropped. Now enabled in `ClientProxy`;
`EventTimelineItemProxy.uploadProgress` -> `RoomTimelineItemProperties.uploadProgress`
(all factory sites) -> `TimelineMediaUploadProgressBar` overlaid along the
bottom of image/video thumbnails and gallery grids while sending.

**Stalled uploads.** Send-queue uploads use `reasonable_upload_timeout` (>= 5 min,
size-based), so a black-holed connection sits silently with the bar frozen.
First cut of a kick: the long-press menu on an uploading item gains "Retry"
(`TimelineItemMenuAction.retryUpload` -> `ClientProxy.retryInFlightRequests()`
= `Client::notify_network_change()`, the round-32 re-send hook: drops the pool
and re-sends every in-flight request on a fresh connection without consuming a
retry; blunt, also nudges the sync long-poll, harmless). Candidates if wanted:
auto-detect a bar frozen for ~15 s and show "Stalled, tap to retry" on the
bubble; a per-request re-send (new SDK API on `SendHandle`) instead of the
client-wide kick.

**Round 48 follow-up: viewer unit tests run (both-slices xcframework), one real fix.**
First sim run since the viewer rounds: 4 VM tests + 1 DS test red. Causes, all
pre-existing: (1) a load joining an in-flight preload emitted `.itemLoaded`
TWICE for the item (preload task, then the joined awaiter) = a redundant
covered page rebuild on device; FIXED (skip when the handle is already there).
(2) The thumbnail placeholder path emits `.itemLoaded` ~300 ms in, which the
tests' "no load on failure" watch read as the media landing; tests now run
without cached/loadable thumbnails. (3) Neighbour preload (default on) breaks
the tests' single-load call counts; off in the test setup. (4) DS test written
for the first inline-gallery commit expected non-previewable gallery items
kept; the fallback has filtered them like the timeline since `b33630f3e`.
26/26 green. Build 149 = the dedupe x SDK `4ea0801f1`.

**Round 48 bar restyle (build 150).** Both bars are now `MediaProgressBar`: a
2pt strip flush with the bottom edge of the media (bubble thumbnail / gallery
grid / viewer page above the caption), transparent track, accent-green
(`iconAccentPrimary`) fill growing from the leading edge, no padding.

**Round 49 (2026-08-23): uploads in the viewer, upload caching, mid-upload
network change (build 151).** Three checks asked for, two holes closed:
(1) Queued uploads DO appear when swiping: every timeline focus (incl. the
viewer's MessageTypes one) subscribes to the send queue, so the local echo is
on the media timeline at the newest end; the viewer's `MediaPreviewItemID`
accepts a transaction ID. HOLE: when the send completes the item's ID flips
transaction -> event, which the data source read as a reshuffle (page rebuilt
around a "new" item reloading the file; if the echo was the only item, updates
were ignored for good). The SDK recycles the local item's timeline unique ID on
the flip and media timelines carry a UUID prefix (no cross-timeline clash), so
`updatePreviewItems` now matches old-local -> new-remote by unique ID (+
gallery index) and migrates the `Media` object's `id` in place: same page, same
file handle, no rebuild. Test `sentLocalEchoKeepsItsPage`.
(2) Uploads are NOT re-downloaded: the send queue caches the file (and
thumbnail) under a local `mxc://send-queue.localhost/<txn>` key before sending;
`update_media_cache_keys_after_upload` renames to the real mxc as
`MediaFormat::File` and re-stores the thumbnail as `Thumbnail(w,h)` with the
event's thumbnail dims, which is exactly what the bubble asks for
(`thumbnailInfo.size`) and the viewer's `getMediaFile(useCache: true)` hits
the File key. Only the in-memory Kingfisher key changes across the flip (one
local decode). Encrypted rooms: keyed on the encrypted source, same match.
(3) A network change mid-upload is handled by the same `send_request_inner`
loop as every request, whose `select!` on the network-change watch (round 32)
re-executes the attempt on a fresh reqwest client with no backoff; EXI fires
it from `NetworkMonitor.pathUpdatePublisher` (and the Retry menu item). It
used to drop EVERY in-flight request, a multi-MB upload still flowing over the
old path included (Wi-Fi joining while on cellular): SDK `c17016f4d` gives a
byte-counted transfer (send/recv progress subscriber present, i.e. uploads
with the bar on and viewer downloads) a 2 s stall grace and keeps it if it
moved; only a stalled one is re-sent. Requests without that signal (long-poll,
small requests) still re-send at once. Ceiling: progress counts bytes as
reqwest pulls them, so a black-holed socket the kernel is still buffering into
looks alive for a moment; the menu Retry (another notification) re-checks once
the buffer is full. Also fixed there: the progress observables accumulated
across attempts (`total += content_length`, `current` kept counting) so the
bar ended short of 100 % after a re-send; reset to zero on re-send. Tests
`test_network_change_resends_in_flight_request` (untracked = immediate) +
`..._resends_tracked_transfer_only_once_stalled` (grace honoured). Also:
`MediaProgressBar` is 3pt high on a `bgCanvasDefault` track (dark/light with
the theme) instead of transparent.

**Round 49 follow-up: Manage storage chart with rooms selected (build 152).**
With rooms selected the greyed-out logs line still read its session-wide
total, and since the chart scales every bar to the largest value, the (hidden)
logs bar set the scale: after "Clear for room" the room caches dropped to ~0
while the logs stayed the maximum, so the remaining bars collapsed to slivers
although their numbers updated. Session-wide caches now read zero in the
filtered scope (`bytes(for:)`); test `loadingAndScoping` updated.

**Round 50 (2026-08-23): first viewer download bar on device, three findings
(build 153).** Log of the session (video `WqaQzuhEDPdqdDllTdqUsnOk`):
(1) The bar bounced backwards: the SAME file was downloaded twice concurrently
(REQ-135 + REQ-139), each download's watcher writing the one `downloadProgress`.
The viewer's display load wasn't registered in `preloads` (only neighbour
preloads and the initial item were), so QuickLook asking for the page again
mid-download (it rebuilds pages as neighbours/placeholders land) started a
second `loadFileFromSource`; videos exceed the preload size cap so no preload
covered them. FIXED at both levels: `MediaLoader.loadMediaFileForSource` now
de-duplicates in-flight file loads by source (`ongoingFileRequests`, like the
data loads; a joiner's progress handler isn't wired, the first drives the same
item) and the viewer registers its display load in `preloads` (which the
placeholder grace wait also keys on). Test `displayLoadIsNotDuplicated`.
(2) Bar over a black page though the bubble showed a thumbnail: the media
cache had been cleared per-room at 14:03:53Z, so the thumbnail wasn't in the
store (the in-memory Kingfisher cache expires entries after ~5 min) and went to
the network, which under a flapping connection missed the 400 ms thumbnail
wait ("thumbnail … from the store: false … no placeholder"). The 400 ms stays
for the initial item (it gates presentation) but the on-display placeholder
path now waits up to 5 s (`thumbnailTimeoutOnDisplay`): nothing blocks on it
and the download takes far longer.
(3) `NWPathMonitor` delivered an identical path (wifi,wifi,cellular) every
~0.5 s for stretches: 128 "Network path changed" in 10 min, each re-sending
every untracked in-flight request (a `/messages` was re-sent 10+ times in 5 s
and could never complete). `NetworkMonitor` now fingerprints the path (status,
interface names+types, gateways, expensive/constrained) and only publishes a
real change. The tracked video download survived the spam thanks to the round
49 stall grace ("still progressing, keeping it" every 2 s).
Progressive video playback while downloading: not with QuickLook (needs the
whole file); would be an AVPlayer page streaming via HTTP ranges with the auth
header (unencrypted media only; encrypted files need the full download for the
SHA-256 check). Not started.

**Round 50 follow-up: Manage storage "0.0 MB" bars (build 154).** A cache
under 50 kB (labelled "0.0 MB") was still scaled against the largest value, so
when it was the largest left (after clearing a room) it drew a full bar. Such
caches now draw empty and don't set the scale (`minimumDrawnBytes`).

**Round 51 (2026-08-23): thumbnail + bar seen on device, three follow-ups
(build 155).** Log of the 91 MB video (`IMG_5177.mp4`, 57 s download):
(1) The bar sat at the page bottom (above the toolbar), far below the
letterboxed placeholder. It now lives in its own hosted view
(`ProgressBarView`) that the controller frames along the bottom edge of the
page's content: the displayed image rect (aspect-fit within QuickLook's image
view, `renderedPageContentView`), re-laid on the existing 100 ms tick since the
page content comes and goes asynchronously; on a page without content yet it
falls back to the bottom of the page above the caption.
(2) The thumbnail was starved by the download: requested alongside it, it
took ~5 s (14:26:44.8 -> 49.9Z) to land. For files >= 10 MB
(`placeholderFirstFileSize`) the thumbnail placeholder is now fetched and
shown BEFORE the download starts (`preload(placeholderFirst:)`, on-display
load likewise); the initial item presents as soon as the placeholder is up or
after 1 s. Smaller files keep the 300 ms grace path.
(3) "Stalled at 100 % until tapped": the swap did run on its own, 0.2 s after
the file handle landed, but the handle landed 6.3 s after the last byte
(14:27:41.8 -> 48.1Z): the SDK decrypts, writes the 91 MB blob into the
(encrypted) media store and writes the temp file after the download. The
spinner now shows over the placeholder while the bar sits at 100 % so that
stretch reads as work, not a stall. Trimming it (stream to file, store write
off the critical path) is an SDK follow-up, not done.
Found on the way: the thumbnail lookup's timeout was an unstructured Task
that the task group's `cancelAll()` never cancelled, so the group waited the
WHOLE timeout however fast the load returned or failed (400 ms every
placeholder before; 5 s once the on-display wait grew, which would have held
the placeholder-first download back by 5 s). The sleep now lives in the group
child; a timed-out load is cancelled. Placeholder-first also requires the
event to carry a thumbnail source (no server-side video thumbnail attempts).

**Round 51 follow-up (build 156).** Bar moved to the very bottom edge of the
screen: following the placeholder's content edge broke down once it was
pinched/zoomed. Spinner-before-thumbnail question: on build 155 both
placeholder-first thumbnails took ~5.0 s (14:42:11.3 -> 16.4Z, 28.5 -> 33.6Z)
although the SDK's store read for them took 3 ms (`media_store Timer
2.985ms` at 11.338Z) and nothing else touched the store or the network until
the viewer logged them; the main thread was alive throughout. So the ~5 s sits
in the Swift provider layer (Kingfisher disk lookup / decode + store / the
retry-on-reachability path), not the SDK. DIAG added (strip pre-upstream):
`Slow image load …: disk cache …, loader …, decode+store …` for any image
load over 500 ms, `Image load failed, retrying on reconnection`, and the
viewer's "thumbnail … from the store: … after …" elapsed. Next slow one
names the stage.

**Round 52 (2026-08-23): "copy to preview" pages + autoplay (build 157).**
User saw many QuickLook "cannot preview / copy to" pages on build 156 and
suspected a URL handed over before decryption finished. Checked: the SDK
writes and flushes the whole decrypted file before returning the handle
(`get_media_file`: `write_all` + flush), the placeholder JPEG is written
before its URL is set, the placeholder dir is per view model, and the log of
that session (54 files, 7 blank-landing heals, 2 stale-placeholder rebuilds)
shows no load errors: nothing names the cause. The only lever QuickLook
leaves is its ContentUnavailable view, which the arrival check already heals
once per arrival; a SECOND unavailable after that reload would mean the file
itself. DIAG added at that point (strip pre-upstream): "unavailable page for
…: <file> <bytes|MISSING>, already reloaded on arrival: …" so the next
occurrence says whether the file was there and whole. Autoplay: once the
thumbnail placeholder is swapped for a video (user sat through the download),
the page's AVPlayer is started (`AVPlayerLayer.player.play()` on the rendered
page content).

**Round 53 (2026-08-23): "Loading more…" stuck; per-room media clear clears
nothing (build 158).** (1) Log 15:09:56-15:11:39Z: clamped to the backwards
placeholder, "undecryptable messages pending behind the oldest media, not
paginating yet", the 5 s UTD wait gave up at 15:09:59 with NEWER pending UTDs
still ahead (pending before oldest: true) and then nothing until the user
swiped away and back. Cause: the UTD-expiry timer is only armed when the
timeline's items change (`scheduleUTDExpiry()` in the items sink); the expiry
task itself never re-armed for the later-seen UTDs' expiry. FIXED: re-arm
after each expiry. (2) Every per-room media clear today logged `Media cache
cleared num_rooms=N num_uris=0`: `media_uris_by_room` returns no URIs for the
selected rooms, so `remove_media_contents` gets an empty list and the files
stay (hence no re-download when reproducing). The index itself isn't empty
(the storage screen's per-room sizing at 13:46 got URIs for some rooms and
went on to size them), and insert/lookup hash the room id with the same
table key, so the selected rooms' media rows simply aren't indexed. Best
candidate: media events decrypted after insert whose decrypted form never
reached the store (`event_media` is built from the stored event; a UTD row has
no URIs). Pulling the phone's event cache DB to confirm before changing the
SDK; meanwhile the whole-cache clear ("Clear all" with no room selected, or
the media bar's bin) does remove files (no URI filter).

**Round 53 follow-up: vacuum after a Manage storage clear (build 159).**
Deleting rows never shrank the store files (SQLite keeps the freed pages), so
per-room clears left the "Messages"/"Media" totals unchanged and the event
cache's 835 MB was part genuine volume (5.4k rooms prefilled, deep history in
a few; no retention policy exists for it) and part free pages from past
clears. New SDK `Client::optimize_event_cache_store()` /
`optimize_media_store()` (VACUUM of the one store; the event cache one only
under a clean cross-process lock) + FFI; `ManageStorageScreenViewModel` calls
them for the stores it cleared, under the same "please wait" (a big store
takes a while; the version-bump VACUUM of all three took minutes, which is why
`optimizeStores()` left the launch path in round 46).

**Round 53 findings from the phone's event cache DB (copied via devicectl,
875 MB).** 116,224 events in 5,741 rooms: 23,178 decrypted `m.room.message`
rows, 85,838 rows stored ENCRYPTED (UTD at write time; the biggest rooms are
75-95 % encrypted, e.g. 1616 events / 1511 encrypted / 1 media URI). The
`event_media` index is complete for what the store can see (`media_indexed =
0` count 0) but holds only 915 URIs over 205 rooms: a per-room media clear
can only remove media whose events are decrypted IN THE STORE, and in the
test rooms most aren't (lost keys for the bulk, and what does decrypt on
display isn't what the clear sees), hence `num_uris=0`. Whole-cache media
clear (no room selected) has no URI filter and works. Size: 213,670 × 4 KB
pages; 26,646 (109 MB) free-list from past clears (the 159 VACUUM recovers
them); `events.content` is 336 MB (avg 2.9 KB, a third of it undecrypted
ciphertext plus the store's value encryption); the rest indexes/chunk tables.
No retention policy exists for the event cache. Fix direction for the
per-room media clear (not done): have `clear_media_cache(room_ids)` try
decrypting the room's stored UTDs with the current keys to collect URIs, and
persist what decrypts (heals the store too).

**Round 53 diag (build 160 = EXI 4049cfeae x SDK 02ec3cdc0).** User's point:
no stored UTD needs decrypting to flush media, every cached media came from an
event the app decrypted, so the gap is write-back. Every redecryptor path
does `save_events` (`on_resolved_utds`), so the 85k encrypted rows should be
the genuinely undecryptable ones and the viewed media should be indexed;
`num_uris=0` for the cleared rooms 21 times says otherwise for them. SDK
`02ec3cdc0` logs, per requested room in `media_uris_by_room`: stored rows,
rows still encrypted, indexed media URIs, index room count (DEBUG, strip
pre-upstream). Repro: Manage storage, select the test room, clear Media,
pull the log. Whole-cache media clear + vacuum (159) remains the reliable
flush meanwhile.

**Round 54 (2026-08-23): viewer collapse on a cold cache (build 161).** After
the whole-cache media flush the user swiped through ~10 pages in seconds and
got "copy to preview"/blank pages en masse. Log: the files landed 5-30 s after
the pages were built; every unavailable page the diag caught had its file
present (placeholder or media, right sizes) and the forced reload ran, so the
files are fine. The remaining pages were built blank/unavailable while
swiping and heal only on the next rest, once per rest. Fix: the neighbours
QuickLook builds (±3) now get their thumbnail placeholder prepared alongside
the preload (`placeholderReach`, de-duplicated via `placeholderJobs`), so a
cold cache builds poster pages that swap to the media on arrival instead of
blank ones.

**Round 55 (2026-08-23): three on build 161, cold caches (build 162).**
Log 16:10-16:11Z, three viewer opens right after "Clear for room" (event
cache AND media cache cold). (1) "Gaps that never fixed" = pages QuickLook
built as the "Loading more…" placeholder while the media timeline had not
yet paginated the items (the padding absorbs prepends, so no count change, no
reload); they rebuilt only on landing + rest ("stale placeholder page …
rebuilding when resting", 3x). New: when items land inside the built
neighbourhood (first index moves below it within 3 of the current page) a
covered rebuild is scheduled for the next rest (`placeholderRebuildRadius`,
coalesced by `prependRebuildPending`). (2) "Copy to preview" = 6 unavailable
pages, every one with its file present (102 kB-870 kB), i.e. built before
the file landed; heal on landing + rest as before, the ±3 neighbour
placeholders (161) need the thumbnail in the store to help, and after a
media flush the thumbnails download too. (3) "Couldn't swipe beyond a point"
(session 4, 16:11:26Z): stopped on index 95, a video whose file wasn't there
yet (poster page, grace wait "file: false"), nothing logged after; not
reproduced from the log. Structural note: all three are QuickLook's
build-once pages vs content arriving later; every mitigation here is a
rest-gated reload, the real fix is owning the pager.
Bug 3 FOUND (session 2, 16:11:08Z): landed on index 97, the placeholder swap
ran after the 200 ms rest check, its rebuilt-page detection failed, and the
fallback `reloadData` ran at 08.135 while the next touch had begun at 08.083
(`TouchDebug: began`); QuickLook then accepted every pan but moved no page
until the viewer was closed (the known refresh/reload-mid-swipe wedge). The
rest predicates checked `isDragging`/`isDecelerating` but not `isTracking`
(finger down before the pan is recognised): added everywhere, and the swap
fallback reload now defers to the next rest when a touch is down (build 163).

**Round 56 (2026-08-23): build 162 report (build 164).** (1) "Skipped lots"
after the clear: the first go shows six prepend rebuilds while the media
timeline paginated (each a covered reload at rest); no skip visible in the
log. (3) "Copy to preview" for content that worked the go before: the third
open's rebuild ran 0.5 s after opening, before the (cached, ~100 ms) files had
loaded, so it built the pages either side blank, and the neighbour heal is
once per rest on the same item, which that rebuild had consumed: nothing
healed them until landing (unavailable pages at 98/95/85/83, all with files).
Fix: a rebuild resets the once-per-rest heal guard. Also: video posters get a
play badge (circle + play.fill) like the timeline's thumbnails.

**Round 56 follow-up: never hand QuickLook nothing (build 165).** User:
"wait until the URL is valid before telling QL". QuickLook reads the URL once
when it builds the page and never re-reads; a nil answer is what it renders
as the "unavailable / copy to" page. Every file-less item without a
thumbnail now answers with a shared black loading JPEG
(`Media.loadingPlaceholderURL`, written once per process), so pages are built
as placeholder pages: the header says Loading, the spinner/bar sit over
black, and the arrival path is the placeholder upgrade (refresh under cover,
rest-gated reload fallback) rather than the "landed on a blank page" heal,
which can no longer occur. Thumbnails replace the black via the same upgrade
when they land. "Skipped from Aug to June": the shapes show ~30 undecryptable
messages between them decrypting later in batches; those land as mid-list
inserts (reshuffle path, rebuilt at rest) or prepends (rebuild at rest), so
swiping back should find them without a restart once they've decrypted.

**Round 57 (2026-08-23): build 165 report + asks (build 166).** Build 165
"felt pretty good". (1) "Couldn't swipe back into the items that decrypted
in the initial gap": the log shows the viewer holding the user on the
"Loading more" placeholder for 13 s (16:43:38-51Z) while 12 items decrypted
behind it: the data source waits 5 s per undecryptable message from first
sight, and each backfill brought more, so the wait kept restarting while the
arrived items sat unreachable behind the clamp. The hold is now bounded from
landing on the placeholder (`placeholderHoldLimit` = the same 5 s, with a
re-check timer): past it the viewer steps onto what has arrived; what
decrypts later lands as a reshuffle, rebuilt at rest, reachable by swiping.
(2) "Adjacent large video preloaded": a neighbouring video with no `size`
in its event info was preloaded (the 10 MB limit only applied to sized
files) and shared the bandwidth of the one on display. Videos of unknown
size now count as large: not preloaded, and placeholder-first on display.
Cancelling a download you've swiped past isn't possible from Swift (uniffi:
"Cancellation not supported yet"), so no setting for that; "Preload media in
the viewer" in Advanced settings already turns neighbour preloads off.
(3) QuickLook's selection/caret tint (Live Text) was the window's
primary-text grey: the controller's view now takes the composer's
`iconAccentTertiary`. (4) Video posters use the timeline's `VideoPlayBadge`
(shared view, rendered with `ImageRenderer` at the poster's on-screen density)
instead of a hand-drawn circle. (5) Timeline: double tap on a bubble opens
the reaction picker (declared before the empty single tap so it wins; a
content view's own tap, e.g. media, still goes first). (6) "Copy text" is
now "Select text": a sheet with the message body in a selectable text view,
all selected, with the system edit menu and a Copy button; copying the whole
message puts the body (markdown for formatted messages) on the pasteboard as
plain text plus the formatted body as HTML and RTF, so a plain-text composer
paste gets markdown and a rich-text one keeps the formatting; a partial
selection copies its plain text. (7) Manage storage: a search field filters
the room list by name or ID and lists every match regardless of the 1 MB
threshold (build 166 = bf8d4a5e4…).

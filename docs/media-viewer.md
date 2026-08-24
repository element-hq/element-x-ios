# The media viewer

How the timeline's media viewer (`TimelineMediaPreview*`, a `QLPreviewController`)
works: what QuickLook is fed, how content is fetched ahead of the user's swipes,
how stale pages are detected and repaired invisibly, and how the whole thing
behaves when the timeline changes underneath it. Current as of round 68
(builds 194-202).

## QuickLook's rules of engagement

Everything here is shaped by two facts, proven on device by the page
diagnostic (each `previewItemAt` logs what the page was built from):

1. On every `reloadData` QuickLook synchronously requests **every** item the
   data source reports, and caches the URL each item answers with.
2. Between reloads it **never asks again**. A page shows whatever its item
   answered at the last (re)build, indefinitely. The only re-read levers are
   `reloadData` (every page; always rebuilds the current one, losing zoom and
   playback position) and `refreshCurrentPreviewItem` (current page only).

So the design goal is: (a) every item answers with something presentable at
build time, and (b) when something better arrives after a build, force a
re-read without the user seeing the mechanics.

## The dataset

`TimelineMediaPreviewDataSource` flattens the timeline's item view states into
`previewItems`: every previewable attachment, oldest first. Gallery messages
contribute their attachments inline (filtered to the tapped attachment's
types), so browsing walks through a gallery like any other run of media;
each attachment knows its "(2 of 3)" position.

**Local echoes** are matched across updates by more than event ID: a sent echo
swaps its transaction ID for an event ID, but keeps the timeline's unique ID,
so the merge recognises it (`isLocalEcho(of:)`) and reuses the existing item -
preserving its file handle, download state and QuickLook page instead of
rebuilding the viewer around a "new" item.

### The ~100-slot phantom padding

The initial array is padded with 100 phantom indices on each side. This is
the workaround for `reloadData` always resetting the current page: pagination
*prepends and appends into the padding* (`backwardPadding -= prependCount`),
so the total count and every built page's index stay fixed and no reload is
needed as the timeline grows. The padding indices themselves render as
"Loading more" placeholder pages.

Two consequences worth knowing:

- The padding is also a **browse budget**: with a side's padding fully spent
  there would be no "Loading more" page left to land on, so the oldest
  reachable item would become QuickLook's content edge and bounce **exactly
  as if the timeline had ended** (with further items merging unreachably
  below index 0). The budget is therefore **re-centred before it runs out**:
  when a pagination merge leaves a side's padding at 10 slots or fewer (and
  that side hasn't genuinely reached the timeline's end), the controller
  restores both paddings to their initial 100 at the next rest, under a
  covered `reloadData` with the current item's index re-derived - one covered
  reload per ~90 items browsed in one direction. A restore also brings back
  anything a fully-spent side had briefly left unreachable, since positive
  padding gives those items indices again.
- When a side genuinely reaches the timeline's end, its padding collapses to
  0 so the last real item becomes QuickLook's own content edge and the swipe
  gets a native bounce (the affordance for "nothing more this way"). That
  count change is one of the few places the controller must re-derive the
  current index and reload.

### "Loading more" pages and overswipe clamping

Landing on a padding page triggers a timeline pagination (unless blocked, see
UTDs below). While the user sits on one, the data source reports only **one**
placeholder page beyond the loaded items (`isClampedTo*Placeholder`), so
QuickLook's edge bounce stops the swipe there rather than letting the user
page on through a run of identical placeholders - the padding exists for
index stability, not to be browsed. Clamp and release are driven by the
controller on index changes, deferred a run-loop turn (QuickLook drops index
writes made from inside its own index observation) and suppressed while a
programmatic move is in flight.

When the paginated items land, the controller steps off the placeholder onto
the newest arrival - but only if it is *adjacent* to the previous edge in the
timeline: a backfill can land older items first, leaving a gap (or messages
still waiting for keys) between the edge and them, and stepping would skip
everything that fills in afterwards. The hold is bounded (from when the user
landed on the placeholder, not per message): past the limit it steps onto
what has arrived, and later decryptions insert behind as a reshuffle.

## What a page is built from (the three layers)

Each item answers `previewItemURL` with the best it has:

1. **The file** (`fileHandle`) - the downloaded media.
2. **The thumbnail placeholder** (`placeholderURL`) - the event's thumbnail
   written to a temp JPEG at the media's *own* pixel size (capped 2048 per
   side), so QuickLook lays it out exactly like the real image and the later
   swap doesn't jump. Placeholder files live in a per-viewer temp directory,
   deleted wholesale with the view model.
3. **The black loading image** - a shared 1080x1920 black JPEG, written once
   per process. Answering nil instead makes QuickLook build its grey
   "unavailable / copy to" page, which it also never re-reads and which looks
   worse than black. Black therefore marks "nothing was available at build
   time"; the machinery below exists to make these pages rare and short-lived.

## Fetching ahead of the swipe

A **reach** is how many items to either side of the current one a speculative
fetch pass covers - "reach 8 ahead" means the 8 items in the direction the
user is swiping. Reaches bound *file* downloads. They no longer bound
thumbnails: a thumbnail reach just moves where the first black page sits
(reach 3 put it deterministically on the 4th swipe, reach 8 on the 9th),
because at a sustained swipe cadence nothing can repair pages mid-run.

- **Files**: the on-display item always downloads, at any size. Neighbours:
  reach 3 both sides on open (direction unknown), then 8 ahead / 2 behind
  once the swipe direction is known (tracked by item, not index - pagination
  shifts indices), queued nearest first. Files over 10MB and videos of
  unknown size are never speculatively fetched. Loads are joined, not
  duplicated, if the user lands on an item mid-preload; an optional setting
  cancels a large in-flight download on swipe-away.
- **Thumbnail placeholders**: one job per **loaded item** - the whole exposed
  dataset, no reach. Each job tries the in-memory image cache (usually a hit:
  the timeline just drew these thumbnails), then the disk cache, then a
  thumbnail-sized network fetch (bounded, abandoned if the file lands first).
  Strictly thumbnail bytes, with one exception: an image whose sender skipped
  the thumbnail because the original is already thumbnail-sized (MSC4409:
  none required at <=800x600, judged by the event's pixel size, else a small
  file size) is fetched as full content - which costs what the thumbnail
  would have, and must be full content because the thumbnail endpoint cannot
  serve encrypted media. Large thumbnail-less media and videos get nothing
  speculatively; they get their poster only once on display, where the
  download is happening anyway.

## Knowing when to reload: the built-page model

QuickLook's offscreen pages can't be inspected (it drops their views), so the
controller models what each page was built from. After **every** (re)build,
`recordBuiltBlankPages` snapshots:

- `builtBlankItemIDs` - pages built from the black image (no file, no
  thumbnail at build time);
- `builtPlaceholderItemIDs` - pages built without their file (thumbnail or
  black).

A page is **healable** when it now has something better than it was built
with: a black-built page once its thumbnail *or* file arrives; a
thumbnail-built page once its file arrives. Every arrival - a placeholder
written, a preload finished - fires `.itemLoaded` at the controller.

### The heal path (repair before arrival)

`scheduleHealReloadIfResting`, poked by every `.itemLoaded` and every landing:

1. **150ms coalesce** - a burst of arrivals becomes one check.
2. **Quiet-gap wait** - reloading mid-gesture wedges QuickLook, so the check
   polls (up to 2s) for a moment with no touch, drag or deceleration. A
   one-shot check reliably landed mid-gesture at a steady cadence and the
   heal never ran; the bounded wait catches the short gaps between swipes.
3. **Once per rest** (keyed on the current item) and the **600ms floor**: no
   two heal reloads within 600ms of each other. Without the floor,
   placeholder/file arrival bursts fired covered reloads back-to-back
   (observed 200ms apart) which fought each other and the swipe. Anything
   skipped is re-scheduled by the next trigger.
4. **Whole-range scan** for a healable page - not a radius around the current
   item: QuickLook holds a page for every loaded item, so a black-built page
   can sit (and be swiped into) well outside any radius. Scanning only +/-2
   was the deterministic 4th-swipe black.
5. One covered `reloadData` rebuilds every page with whatever is best now.

In a healthy session the heal log lines read `healing ... -7/-8 from the
current item`: pages several swipes ahead being repaired before arrival.

### The arrival paths (repair on landing)

- Landing on a page built without its file whose file has since arrived: the
  **upgrade swap** - `refreshCurrentPreviewItem` under a cover; when the new
  content renders, a video autoplays (the user already waited through the
  poster).
- Landing on QuickLook's **"content unavailable"** page (it sometimes builds
  one during fast swipes even with a valid file - every observed instance had
  the file present on disk with its full byte count): detected by inspecting
  the view hierarchy under the screen centre, healed with an *uncovered*
  reload (the page is blank; a cover would only delay the media).
- Landing on a "Loading more" page whose index now holds real media
  (pagination absorbed items since the build): rebuilt at rest.

### How far `refreshCurrentPreviewItem` can be trusted

The current-page-only lever has three known caveats (all observed on device):

- Called **while swiping between items it breaks the QLPreviewController
  outright**, so every refresh path waits for the pages to stop moving first.
- It **cannot clear a cached "content unavailable" page** - QuickLook's
  stale negative cache. A page QuickLook built as "unavailable" stays
  unavailable through a refresh even with a valid file on disk; only
  `reloadData` clears it, which is why the landed-on-a-blank path reloads
  (uncovered) instead of refreshing.
- Even in the good case (swapping a rendered placeholder page for the
  media), the refresh is **not always honoured**. The upgrade swap therefore
  verifies: it runs under a cover and watches for the page's content to
  actually change; if it hasn't shortly after, it falls back to a covered
  `reloadData` of every page.

## The cover

`reloadData` empties the current page synchronously and repopulates it
20-130ms later - a visible flash. Every deliberate reload therefore runs
under a **cover**: a snapshot of the page area inserted above the page scroll
view (below the bars, whose glass keeps animating).

Dropping the cover is the delicate part:

- A watcher polls for the rebuilt page's content: a *new* image view or
  player layer under the screen centre. For video, `isReadyForDisplay` is a
  genuine on-glass signal. For images, `image != nil` is not - a large photo
  decodes out of process for another 50-150ms - so the cover **holds 150ms
  past detection** for image pages. It is showing identical content, so the
  hold is invisible.
- **Handover, not fighting**: if a new covered reload starts while a cover is
  up, the standing cover is *reused* - a fresh snapshot taken mid-rebuild
  captures a just-emptied (black) page, so re-snapshotting made the cover
  itself the flash - and the previous watcher is cancelled; only the newest
  watcher may drop the cover. (Before this, a stale watcher tore down the
  cover a newer reload had just installed, within microseconds.)
- Failsafes: a 1s timeout, and a starting drag drops the cover immediately -
  never trap a gesture under a stale picture.

## When the timeline changes under the open viewer

`updatePreviewItems` merges every timeline update through one of three paths:

1. **Contiguous** - the existing items are a contiguous slice of the new
   list (the normal pagination case): the prepend/append counts are absorbed
   into the phantom padding. No reload, no index movement.
2. **Reshuffle** - the lists share items but not contiguously (de-duplication,
   a backfill landing in the middle, a UTD decrypting into media between
   loaded items): the merge re-anchors on the current item (or any shared
   item), adjusts both paddings so its index doesn't move, and marks
   `needsRebuild` - the controller rebuilds all pages, covered, at the next
   rest. Ignoring these updates used to freeze the viewer at a handful of
   items while the timeline moved on.
3. **No shared items** - the update is ignored (protects the state where the
   viewer opened on a tapped item the timeline hasn't loaded yet). Known
   trade-off: a redaction that empties the overlap stops further updates.

### UTDs and gaps (the shape analysis)

Undecryptable messages aren't previewable, but one may *become* media a
second later (its key is usually already on the way), and a timeline gap may
hide media entirely. `analyseShape` walks the timeline oldest-first and
tracks:

- media with something unresolved (a gap, or a maybe-media UTD) between them
  and the next newer media (`itemIDsWithGapOnNewerSide`) - stepping off a
  "Loading more" placeholder is refused while such a gap sits between the
  edge and the arrivals (bounded by the placeholder hold limit), so the step
  doesn't skip items that decrypt moments later;
- whether pending UTDs sit *older than the oldest media*
  (`hasPendingUTDsBeforeOldestMedia`) - backward pagination is held while
  they pend, since paginating on would request keys for older pages ahead of
  the nearest ones and step past them.

A UTD of unknown cause counts as "maybe media" for 5 seconds from first
sight; a timer re-evaluates the shape when the wait expires (keys that come,
come within a second or so - one that hasn't isn't coming). Whatever
decrypts later arrives as a reshuffle (path 2) and is rebuilt at rest,
reachable.

## Scaling notes

Could a room with 10,000 cached media events hand QuickLook 10,000
placeholders? No - the working set is bounded by construction:

- The dataset is the media flattened from the timeline's **loaded** item view
  states - what the timeline view has actually paginated in, not the store's
  full contents. A viewer session opens with typically tens of items and
  grows only as the user actually browses (pagination is demand-driven:
  triggered by proximity to the loaded edge and by "Loading more" landings).
- So 10K exposed items means the user swiped through thousands of media in
  one sitting; the store's 10K cached events alone expose nothing.

The costs that grow linearly with the exposed set: a (re)build's hand-off is
one cached-property read per item (a few hundred microseconds each, ~25ms
for a 28-item build including diagnostics; a thousand items ~1s of
main-thread per reload, which at that depth happens once per ~90 items
browsed for the budget re-centre, plus heals); placeholder jobs are one-shot
per item, mostly memory-cache hits, with their JPEGs (30-200KB each) living
until the viewer closes; the heal scan and shape analysis are single linear
passes per event.

If deep-browsing sessions ever matter, the things to bound are the
whole-range placeholder pass (order it nearest-first, cap the live
placeholder files with an LRU) and the per-reload hand-off cost (QuickLook
offers no incremental alternative, so the lever is windowing the exposed
range - dropping items far behind the user the same way the padding
re-centre already rebases indices).

## Diagnostics

Still in place, to be stripped before upstreaming: the per-page
`handed to QuickLook as file/thumbnail/BLACK` log (the tool that cracked the
deterministic black), `fileDiagnostics` on unavailable pages, and the slow
image load probe in `MediaProvider`. The permanent info logs (heal,
landed-on-blank, cover down) stay.

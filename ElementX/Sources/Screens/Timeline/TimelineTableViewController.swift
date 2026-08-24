//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import MatrixRustSDK
import OrderedCollections
import SwiftUI

/// A table view cell that displays a timeline item in a room. The cell is intended
/// to be configured to display a SwiftUI view and not use any UIKit.
class TimelineItemCell: UITableViewCell {
    static let reuseIdentifier = "TimelineItemCell"
    
    var item: RoomTimelineItemViewState?
    
    override func prepareForReuse() {
        item = nil
    }
}

/// A table view cell that displays member typing notifications. The cell is intended
/// to be configured to display a SwiftUI view and not use any UIKit.
class TimelineTypingIndicatorCell: UITableViewCell {
    static let reuseIdentifier = "TimelineTypingIndicatorCell"
}

/// Hosts a timeline item pinned to one vertical edge of its cell.
///
/// During animated snapshot applies the cell's frame and its (already re-rendered)
/// content height are transiently out of sync; without a vertical alignment SwiftUI
/// centres the content in the excess space, which reads as the bubble dipping by half
/// the removed status row. The bubble must hug the edge OPPOSITE the one whose content
/// changed: the visual top when a row below the bubble toggles (delivery status, read
/// receipts, reactions - the common case, EXI 66bea662f), but the visual bottom when the
/// item joins or leaves a sender group and its header above the bubble appears or
/// disappears (a gap resolving or a back-pagination landing next to it); top-pinned, the
/// bubble would jump by the header height and slide back. The edge is decided in body
/// (`onChange` fires a frame too late) and held for the length of any batch animation.
private struct EdgePinnedTimelineItemView: View {
    @ObservedObject var viewState: RoomTimelineItemViewState
    @State private var memory = EdgeMemory()
    
    final class EdgeMemory {
        var lastGroupStyle: TimelineGroupStyle?
        var alignment: Alignment = .topLeading
        var resetWork: DispatchWorkItem?
    }
    
    var body: some View {
        RoomTimelineItemView(viewState: viewState)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
    
    private var alignment: Alignment {
        // Only a header toggle changes the content's top edge. Other regroups (e.g. the previous
        // bubble going .single -> .first on send) change the bottom: status row, corner radii.
        if let lastGroupStyle = memory.lastGroupStyle,
           lastGroupStyle.shouldShowSenderDetails != viewState.groupStyle.shouldShowSenderDetails {
            memory.alignment = .bottomLeading
            memory.resetWork?.cancel()
            let resetWork = DispatchWorkItem { [memory] in memory.alignment = .topLeading }
            memory.resetWork = resetWork
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: resetWork)
        }
        memory.lastGroupStyle = viewState.groupStyle
        return memory.alignment
    }
}

class TypingMembersObservableObject: ObservableObject {
    @Published var members: [String] = []
    
    init(members: [String]) {
        self.members = members
    }
}

/// A table view that reports its layout passes, so the send transition can
/// re-pin the timeline after ANY content-height change (e.g. the previous
/// message's delivery status row animating away mid-transition), not just
/// view-controller-level layout.
private final class SendTransitionTableView: UITableView {
    var onDidLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onDidLayout?()
    }
}

/// A table view controller that displays the timeline of a room.
///
/// This class subclasses `UIViewController` as `UITableViewController` adds some
/// extra keyboard handling magic that wasn't playing well with SwiftUI (as of iOS 16.1).
/// Also this TableViewController uses a **flipped tableview**
class TimelineTableViewController: UIViewController {
    private let coordinator: TimelineViewRepresentable.Coordinator
    private let tableView = SendTransitionTableView(frame: .zero, style: .plain)
    
    var timelineItemsDictionary = OrderedDictionary<TimelineItemIdentifier.UniqueID, RoomTimelineItemViewState>() {
        didSet {
            guard canApplySnapshot else {
                hasPendingItems = true
                return
            }

            applySnapshot()
            
            sendLastVisibleItemReadReceipt()
        }
    }
    
    /// Whether or not it is safe to update the data source with the latest items.
    private var canApplySnapshot: Bool {
        if isLive {
            // Backward pagination jumps if items are inserted whilst actively dragging.
            // Trust UIKit's own dragging state rather than the delegate-paired
            // isDraggingScrollView flag: a cancelled gesture (context menu,
            // swipe-to-reply, a system gesture stealing the touch) fires
            // willBeginDragging without a matching didEndDragging, which wedged
            // the flag and froze the timeline behind pending items forever.
            // Only dragging counts, not isTracking: a finger merely resting on
            // the table (rageshake 7543, a touch landing as the room opened)
            // parked the first items and a tap without a drag produces no scroll
            // callback to flush them, so the timeline stayed blank until a drag.
            !tableView.isDragging
        } else {
            // Forward pagination breaks inertial scrolling when fixing the offset.
            !scrollViewIsScrolling
        }
    }
    
    /// There are pending items in `timelineItemsDictionary` that haven't been applied to the data source.
    private var hasPendingItems = false

    /// An `applySnapshot` is currently in flight. UIKit hard-crashes
    /// (NSInternalInconsistencyException "Deadlock detected") if
    /// `dataSource.apply` is re-entered, and an animated apply synchronously
    /// fires `scrollViewDidScroll` (whose self-heal flush calls back in) as
    /// well as SwiftUI view updates (which can set `timelineItemsDictionary`)
    /// mid-batch. Rageshake 7562.
    private var isApplyingSnapshot = false

    /// The gap items rendered by the last applied snapshot, used to animate a gap's resolution.
    private var renderedGapIDs = Set<TimelineItemIdentifier.UniqueID>()
    
    /// The scroll view is scrolling either directly with a drag or indirectly with inertia.
    private var scrollViewIsScrolling = false {
        didSet {
            if !scrollViewIsScrolling, hasPendingItems, !isLive {
                hasPendingItems = false
                applySnapshot()
            }
        }
    }
    
    /// The scroll view is being dragged by the user (doesn't include scrolling with inertia)
    private var isDraggingScrollView = false {
        didSet {
            if !isDraggingScrollView, hasPendingItems, isLive {
                hasPendingItems = false
                applySnapshot()
            }
        }
    }
    
    /// Whether or not the current timeline is live or built around an event ID.
    var isLive = true {
        didSet {
            // Update isScrolledToBottom when switching back to a live timeline.
            if isLive {
                scrollViewDidScroll(tableView)
            }
        }
    }
    
    /// The state of pagination (in both directions) of the current timeline.
    var paginationState: TimelinePaginationState = .initial {
        didSet {
            // Paginate again if the threshold hasn't been satisfied.
            paginatePublisher.send(())
        }
    }
    
    /// Whether the table view is about to load items from a new timeline or not.
    var isSwitchingTimelines = false
    
    /// The focussed event if navigating to an event permalink within the room.
    var focussedEvent: TimelineState.FocussedEvent? {
        didSet {
            guard let focussedEvent, focussedEvent.appearance != .hasAppeared else { return }
            scrollToItem(eventID: focussedEvent.eventID, animated: focussedEvent.appearance == .animated)
        }
    }
    
    var hideTimelineMedia = false {
        didSet {
            guard let snapshot = dataSource?.snapshot() else { return }
            dataSource?.applySnapshotUsingReloadData(snapshot)
        }
    }
    
    /// Used to hold an observable object that the typing indicator can use
    let typingMembers = TypingMembersObservableObject(members: [])
    
    /// Updates the typing members but also updates table view items
    func setTypingMembers(_ members: [String]) {
        DispatchQueue.main.async {
            // Avoid `Publishing changes from within view update` warnings
            self.typingMembers.members = members
        }
    }
    
    @Binding private var isScrolledToBottom: Bool
    @Binding private var isReadMarkerVisible: Bool
    @Binding private var hasNewMessagesAtBottom: Bool
    @Binding private var floatingDate: Date?
    
    /// The unique ID of the read marker (NEW banner) currently in the timeline, if any.
    /// Updated by `TimelineViewRepresentable.updateUIViewController` whenever it changes.
    var readMarkerUniqueID: TimelineItemIdentifier.UniqueID?
    
    /// A work item used to auto-hide the floating date badge after scrolling stops.
    private var floatingDateHideWorkItem: DispatchWorkItem?
    
    private var timelineItemsIDs: [TimelineItemIdentifier.UniqueID] {
        timelineItemsDictionary.keys.elements.reversed()
    }
    
    /// The table's diffable data source.
    private var dataSource: UITableViewDiffableDataSource<TimelineSection, TimelineItemIdentifier.UniqueID>?
    private var cancellables = Set<AnyCancellable>()
    
    /// A publisher used to throttle back pagination requests.
    ///
    /// Our view actions get wrapped in a `Task` so it is possible that a second call in
    /// quick succession can execute before ``paginationState`` acknowledges that
    /// pagination is in progress.
    private let paginatePublisher = PassthroughSubject<Void, Never>()
    
    /// A value to determine the scroll velocity threshold to detect a change in direction of the scroll view
    private let scrollVelocityThreshold: CGFloat = 50.0
    /// A publisher used to throttle scroll direction changes
    private let scrollDirectionPublisher = PassthroughSubject<ScrollDirection, Never>()
    /// Whether or not the view has been shown on screen yet.
    private var hasAppearedOnce = false
    
    // MARK: Send transition

    /// While non-nil, a send transition is running: the timeline is pinned to this
    /// reference so the composer's height collapse can't move it, and the sent
    /// message fades into the vacated slot instead of shoving everything around.
    private var sendTransitionReference: Layout?
    /// While true, the table stops tracking the view's size: the composer's
    /// animated collapse resizes the view every frame, and the flipped table's
    /// content is glued to its frame's bottom edge, so following the resize
    /// would drag the timeline down with it. The frame catches up in one
    /// compensated pass when the collapse finishes.
    private var sendTransitionFrameFrozen = false
    /// How far the frozen table's frame extends beyond the view so rows beyond
    /// the old bottom edge are materialised (grown further if a message needs it).
    private static let sendTransitionOversize: CGFloat = 300
    /// The extra legal overscroll granted (as a content-start inset) while
    /// frozen: pinning against the extended frame overscrolls by up to the
    /// oversize, and an illegal offset gets silently clamped mid-collapse.
    private static let sendTransitionOverscrollAllowance: CGFloat = 340
    /// Whether the composer collapse's animated resize has been observed while
    /// frozen (it never fires for single-line sends).
    private var sendTransitionCollapseObserved = false
    /// The height the composer's collapse is expected to hand back, measured by
    /// the composer at send time (0 for single-line sends).
    private var sendTransitionExpectedDelta: CGFloat = 0
    /// Whether the settle motion has started; the per-layout re-pin stops then
    /// so it doesn't fight the deliberate scroll.
    private var sendTransitionDriftStarted = false
    /// The content inset currently added for legal overscroll, removed at the end.
    private var sendTransitionInsetAdded: CGFloat = 0
    /// The view's height at the send tap; with the measured collapse delta this
    /// gives the final view height, so the settle can target absolute bottom in
    /// frozen coordinates and run as ONE curve through the collapse's end.
    private var sendTransitionViewHeightAtBegin: CGFloat = 0
    /// The end arrived while the settle was mid-flight: the (invisible,
    /// compensated) geometry restore waits for the settle's completion so a
    /// second animation never has to true anything up.
    private var sendTransitionRestoreDeferred = false
    private var sendTransitionFallback: DispatchWorkItem?
    /// True from the start of a send transition until its settling scroll finishes.
    /// The pin and drift briefly leave a positive content offset, which would
    /// otherwise read as "scrolled away from the bottom" and flash the
    /// jump-to-bottom button on every send.
    private var sendTransitionIsSettling = false

    init(coordinator: TimelineViewRepresentable.Coordinator,
         isScrolledToBottom: Binding<Bool>,
         isReadMarkerVisible: Binding<Bool>,
         hasNewMessagesAtBottom: Binding<Bool>,
         floatingDate: Binding<Date?>,
         scrollToBottomPublisher: PassthroughSubject<Void, Never>,
         scrollToFirstItemForDatePublisher: PassthroughSubject<Void, Never>,
         scrollToReadMarkerPublisher: PassthroughSubject<TimelineItemIdentifier.UniqueID, Never>,
         sendTransitionPublisher: PassthroughSubject<CGFloat, Never>) {
        self.coordinator = coordinator
        _isScrolledToBottom = isScrolledToBottom
        _isReadMarkerVisible = isReadMarkerVisible
        _hasNewMessagesAtBottom = hasNewMessagesAtBottom
        _floatingDate = floatingDate
        
        super.init(nibName: nil, bundle: nil)
        
        tableView.register(TimelineItemCell.self, forCellReuseIdentifier: TimelineItemCell.reuseIdentifier)
        tableView.register(TimelineTypingIndicatorCell.self, forCellReuseIdentifier: TimelineTypingIndicatorCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = .compound.bgCanvasDefault
        
        // The tableview is flipped to display the newest items at the bottom.
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        view.addSubview(tableView)

        // Every table layout pass during a send transition re-pins the content:
        // cell self-sizing (the previous message's status row animating away)
        // and the collapse's view resizes must not move the timeline. The pin
        // stops as soon as the transition ends so the settle drift can run.
        tableView.onDidLayout = { [weak self] in
            guard let self, let sendTransitionReference, !sendTransitionDriftStarted else { return }
            restoreSendTransitionPosition(sendTransitionReference)
        }
        
        // Prevents XCUITest from invoking the diffable dataSource's cellProvider
        // for each possible cell, causing layout issues
        tableView.accessibilityElementsHidden = ProcessInfo.shouldDisableTimelineAccessibility
        
        scrollToBottomPublisher
            .sink { [weak self] _ in
                self?.scrollToNewestItem(animated: true)
            }
            .store(in: &cancellables)
        
        scrollToFirstItemForDatePublisher
            .sink { [weak self] _ in
                self?.scrollToFirstItemForCurrentDate()
            }
            .store(in: &cancellables)
        
        scrollToReadMarkerPublisher
            .sink { [weak self] uniqueID in
                self?.scrollToItem(uniqueID: uniqueID, animated: true)
            }
            .store(in: &cancellables)

        sendTransitionPublisher
            .sink { [weak self] collapseHeight in
                self?.beginSendTransition(expectedCollapseDelta: collapseHeight)
            }
            .store(in: &cancellables)
        
        paginatePublisher
            .collect(.byTime(DispatchQueue.main, 0.1))
            .sink { [weak self] _ in
                self?.paginateIfNeeded()
            }
            .store(in: &cancellables)
        
        scrollDirectionPublisher
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()
            .sink { direction in
                coordinator.send(viewAction: .hasScrolled(direction: direction))
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.sendLastVisibleItemReadReceipt()
            }
            .store(in: &cancellables)
        
        configureDataSource()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available.")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sendLastVisibleItemReadReceipt()
        
        guard !hasAppearedOnce else { return }
        tableView.contentOffset.y = -1
        hasAppearedOnce = true
        paginatePublisher.send()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        guard tableView.frame.size != view.frame.size else {
            return
        }

        if sendTransitionFrameFrozen {
            // The composer's animated collapse is resizing the view; hold the
            // (oversized) table still and finish in one compensated pass once
            // the animation completes.
            if !sendTransitionCollapseObserved {
                sendTransitionCollapseObserved = true
                // A single-line send predicted no collapse, yet the view is growing:
                // clearing the composer resets the keyboard type (#299), which swaps
                // the taller emoji keyboard for the letters one. Same shape as a
                // collapse, so promote to the frozen path before the echo applies;
                // the stock path's compensated restore plus settle would otherwise
                // run against the animated insert (the bounce on emoji sends).
                let growth = view.frame.height - sendTransitionViewHeightAtBegin
                if sendTransitionExpectedDelta <= 1, growth > 1, let reference = sendTransitionReference {
                    MXLog.info("SendTransition: view grew \(growth) during a single-line send, promoting to the collapse path")
                    sendTransitionExpectedDelta = growth
                    oversizeFrozenTable(pinning: reference)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.endSendTransition()
                }
            }
            return
        }

        tableView.frame = CGRect(origin: .zero, size: view.frame.size)
    }


    // MARK: - Send transition

    /// Starts a send transition: the composer clears with an animated height
    /// collapse (ComposerToolbarViewModel), and following that resize would drag
    /// the bottom-glued timeline down with it, so the table's frame freezes for
    /// the duration instead. When the collapse completes the frame catches up
    /// and the echo applies in one compensated pass: old content pinned, the
    /// sent message fading into the vacated slot, and a final drift to the
    /// bottom for the residual.
    private func beginSendTransition(expectedCollapseDelta: CGFloat) {
        guard isLive, !isSwitchingTimelines, isScrolledToBottom,
              !UIAccessibility.isReduceMotionEnabled,
              sendTransitionReference == nil,
              let reference = snapshotLayout() else {
            return
        }

        sendTransitionReference = reference
        sendTransitionIsSettling = true
        sendTransitionFrameFrozen = true
        sendTransitionCollapseObserved = false
        sendTransitionExpectedDelta = expectedCollapseDelta
        sendTransitionDriftStarted = false
        sendTransitionRestoreDeferred = false
        sendTransitionViewHeightAtBegin = view.frame.height

        // For a collapsing (multiline) composer, freeze the table OVERSIZED so
        // the sent message's row is materialised even though it lands beyond the
        // old bottom edge: it renders behind the composer's opaque background
        // and is revealed as the collapse shrinks it, in parallel. Pinning
        // against a bottom-extended frame necessarily overscrolls (the device
        // logs showed the scroll view silently clamping the pinned offset back
        // to -1 during collapse layout passes - the dip), so a matching content
        // inset on the content-start side makes the overscroll legal for the
        // duration. Single-line sends skip all of this: their message slides in
        // from the bottom via the settle, materialising like any other scroll.
        if expectedCollapseDelta > 1 {
            oversizeFrozenTable(pinning: reference)
        }

        // If the echo never lands (send failure, slash command), settle anyway.
        let fallback = DispatchWorkItem { [weak self] in
            self?.endSendTransition()
        }
        sendTransitionFallback = fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: fallback)
    }

    /// Extends the frozen table beyond the view (plus the matching overscroll
    /// allowance) and re-pins the reference, so rows landing past the old bottom
    /// edge are materialised for the collapse to reveal. Sized from the height
    /// at the send tap, whatever the view measures by now.
    private func oversizeFrozenTable(pinning reference: Layout) {
        guard sendTransitionInsetAdded == 0 else { return }
        UIView.performWithoutAnimation {
            tableView.contentInset.top += Self.sendTransitionOverscrollAllowance
            sendTransitionInsetAdded = Self.sendTransitionOverscrollAllowance
            tableView.frame = CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: sendTransitionViewHeightAtBegin + Self.sendTransitionOversize))
            tableView.layoutIfNeeded()
            restoreSendTransitionPosition(reference)
        }
    }

    /// Shifts the content offset so the reference cell sits back at its captured
    /// position. Pins the visual top edge: the cell loses its delivery status row
    /// when the sent message lands, so pinning the bottom edge would drop the
    /// bubble by the status row's height.
    private func restoreSendTransitionPosition(_ reference: Layout) {
        guard let frame = cellFrame(for: reference.id.uniqueID) else {
            MXLog.info("SendTransition: restore found no cell for \(reference.id.uniqueID)")
            return
        }
        let deltaY = frame.minY - reference.frame.minY
        // Strip before upstreaming: dip diagnostics.
        MXLog.info("SendTransition: restore delta=\(deltaY) offset=\(tableView.contentOffset.y) tableH=\(tableView.frame.height) viewH=\(view.frame.height)")
        if deltaY != 0 {
            tableView.contentOffset.y -= deltaY
        }
    }

    /// Ends the transition. If the settle is still mid-flight it already targets
    /// the visually exact bottom in frozen coordinates, so the geometry restore
    /// defers to its completion - a second motion never runs. Otherwise restore
    /// and settle from here.
    private func endSendTransition() {
        sendTransitionFallback?.cancel()
        sendTransitionFallback = nil
        guard sendTransitionReference != nil else { return }
        sendTransitionReference = nil

        if sendTransitionDriftStarted, sendTransitionIsSettling {
            sendTransitionRestoreDeferred = true
            return
        }

        finishSendTransitionGeometry()

        let target = min(-1, -tableView.adjustedContentInset.top)
        guard abs(tableView.contentOffset.y - target) > 0.5 else {
            sendTransitionIsSettling = false
            return
        }
        settle(to: target)
    }

    /// Swaps the frozen geometry (oversized frame + overscroll inset) back,
    /// pinning whatever is on screen NOW across the change - visually a no-op
    /// whenever it runs.
    private func finishSendTransitionGeometry() {
        sendTransitionRestoreDeferred = false
        guard sendTransitionFrameFrozen else { return }
        sendTransitionFrameFrozen = false
        UIView.performWithoutAnimation {
            let current = snapshotLayout()
            if sendTransitionInsetAdded != 0 {
                tableView.contentInset.top -= sendTransitionInsetAdded
                sendTransitionInsetAdded = 0
            }
            tableView.frame = CGRect(origin: .zero, size: view.frame.size)
            tableView.layoutIfNeeded()
            if let current {
                restoreSendTransitionPosition(current)
            }
        }
    }

    /// Animates the content offset with an ease-out curve so the motion reads as
    /// an immediate response to the send rather than winding up. A beginning
    /// drag cancels it (``scrollViewWillBeginDragging``).
    private func settle(to target: CGFloat) {
        sendTransitionDriftStarted = true
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]) {
            self.tableView.contentOffset.y = target
        } completion: { [weak self] _ in
            guard let self, sendTransitionReference == nil else { return }
            if sendTransitionRestoreDeferred {
                finishSendTransitionGeometry()
                // The restore is exact up to the measured delta; silently absorb
                // the last point or two rather than animating a correction.
                if abs(tableView.contentOffset.y - -1) <= 4 {
                    tableView.contentOffset.y = -1
                } else {
                    settle(to: -1)
                    return
                }
            }
            sendTransitionIsSettling = false
            sendLastVisibleItemReadReceipt()
        }
    }
    
    /// Configures a diffable data source for the timeline's table view.
    private func configureDataSource() {
        dataSource = .init(tableView: tableView) { [weak self] tableView, indexPath, id in
            switch id {
            case TimelineItemIdentifier.UniqueID(TimelineTypingIndicatorCell.reuseIdentifier):
                let cell = tableView.dequeueReusableCell(withIdentifier: TimelineTypingIndicatorCell.reuseIdentifier, for: indexPath)
                guard let self else {
                    return cell
                }
                
                cell.contentConfiguration = UIHostingConfiguration {
                    TypingIndicatorView(typingMembers: self.typingMembers)
                }
                .margins(.vertical, 0)
                .minSize(height: 0)
                .background(Color.clear)
                
                // Flipping the cell can create some issues with cell resizing, so flip the content View
                cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
                cell.accessibilityElements = [cell.contentView] // Ensure VoiceOver reads the content view only
                
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: TimelineItemCell.reuseIdentifier, for: indexPath)
                guard let self, let cell = cell as? TimelineItemCell else { return cell }
                
                let viewState = timelineItemsDictionary[id]
                cell.item = viewState
                guard let viewState else {
                    return cell
                }
                
                cell.contentConfiguration = UIHostingConfiguration { [coordinator, hideTimelineMedia] in
                    EdgePinnedTimelineItemView(viewState: viewState)
                        .id(id)
                        .environmentObject(coordinator.context) // Attempted fix at a crash in TimelineItemContextMenu
                        .environment(\.timelineContext, coordinator.context)
                        .environment(\.shouldAutomaticallyLoadImages, !hideTimelineMedia)
                }
                .margins(.all, 0) // Margins are handled in the stylers
                .minSize(height: 1)
                .background(Color.clear)
                
                // Flipping the cell can create some issues with cell resizing, so flip the content View
                cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
                return cell
            }
        }
        
        // We only animate when there's a new last message, so its safe
        // to animate from the bottom (which is the top as we're flipped).
        dataSource?.defaultRowAnimation = (UIAccessibility.isReduceMotionEnabled ? .none : .top)
        tableView.delegate = self
        
        // "Select text": a tap outside the selected text ends the selection (taps on
        // another bubble already end it in the bubble's own tap handler). Passive: it
        // cancels nothing and recognises alongside everything.
        let endSelectionTap = UITapGestureRecognizer(target: self, action: #selector(handleEndTextSelectionTap))
        endSelectionTap.cancelsTouchesInView = false
        endSelectionTap.delegate = self
        tableView.addGestureRecognizer(endSelectionTap)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(accessibilityReduceMotionDidChange),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                               object: nil)
    }
    
    @objc private func handleEndTextSelectionTap(_ recognizer: UITapGestureRecognizer) {
        guard coordinator.context.textSelection != nil else { return }
        MXLog.info("Timeline: tap outside the selection ends Select text")
        coordinator.context.send(viewAction: .endTextSelection)
    }
    
    @objc private func accessibilityReduceMotionDidChange() {
        dataSource?.defaultRowAnimation = (UIAccessibility.isReduceMotionEnabled ? .none : .top)
    }
    
    /// Updates the table view with the latest items from the ``timelineItems`` array. After
    /// updating the data, the table will be scrolled to the bottom if it was visible otherwise
    /// the scroll position will be updated to maintain the position of the last visible item.
    private func applySnapshot() {
        guard let dataSource else { return }

        // Re-entrancy guard: park the update and flush it when the in-flight
        // apply returns (see isApplyingSnapshot).
        guard !isApplyingSnapshot else {
            hasPendingItems = true
            return
        }
        isApplyingSnapshot = true
        defer {
            isApplyingSnapshot = false
            if hasPendingItems, canApplySnapshot {
                hasPendingItems = false
                applySnapshot()
            }
        }

        var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, TimelineItemIdentifier.UniqueID>()
        
        // We don't want to display the typing notification in this timeline
        if coordinator.context.viewState.timelineKind != .pinned {
            snapshot.appendSections([.typingIndicator])
            snapshot.appendItems([TimelineItemIdentifier.UniqueID(TimelineTypingIndicatorCell.reuseIdentifier)])
        }
        snapshot.appendSections([.main])
        snapshot.appendItems(timelineItemsIDs)
        
        let currentSnapshot = dataSource.snapshot()

        // We only animate when new items come at the end of a live timeline, ignoring transitions through empty.
        let newestItemIdentifier = snapshot.mainItemIdentifiers.first
        let currentNewestItemIdentifier = currentSnapshot.mainItemIdentifiers.first
        let newestItemIDChanged = snapshot.numberOfMainItems > 0 && currentSnapshot.numberOfMainItems > 0 && newestItemIdentifier != currentNewestItemIdentifier
        // Only sends with a collapsing (multiline) composer take the frozen apply
        // path; single-line sends release their freeze and use the stock animated
        // batch insert, which already slides the message in from the bottom edge
        // in sync with the rest of the timeline.
        let frozenApply = sendTransitionReference != nil && sendTransitionExpectedDelta > 1
        let animated = isLive && !isSwitchingTimelines && newestItemIDChanged && !frozenApply

        // A gap resolving swaps its visible spinner row for the fetched events;
        // animate that apply so the swap shrinks/fades instead of popping.
        let newGapIDs = Set(timelineItemsDictionary.compactMap { id, viewState -> TimelineItemIdentifier.UniqueID? in
            guard case .gap = viewState.type else { return nil }
            return id
        })
        let resolvedGapIDs = renderedGapIDs.subtracting(newGapIDs)
        let visibleIDs = Set(tableView.indexPathsForVisibleRows?.compactMap { dataSource.itemIdentifier(for: $0) } ?? [])
        // Animate a resolution whose spinner is on screen so it shrinks away as
        // the fetched events slide in above it (the flipped table measures its
        // offsets from the newest end, so rows older than the gap move and the
        // newer ones stay put). That only holds while nothing newer than the
        // gap changed in the same apply - otherwise the newer rows shift and
        // the apply needs the pin below instead. Identity churn among visible
        // rows (e.g. "N room changes" groups regrouping under new identities)
        // would cross-fade half the screen, so that goes unanimated too.
        let removedIDs = Set(currentSnapshot.mainItemIdentifiers).subtracting(timelineItemsIDs)
        let visibleChurn = !removedIDs.subtracting(resolvedGapIDs).isDisjoint(with: visibleIDs)
        let newerSideUnchanged = {
            guard let gapIndex = currentSnapshot.mainItemIdentifiers.firstIndex(where: { resolvedGapIDs.contains($0) }) else { return false }
            return Array(currentSnapshot.mainItemIdentifiers.prefix(gapIndex)) == Array(timelineItemsIDs.prefix(gapIndex))
        }()
        let visibleGapResolved = !frozenApply && !visibleChurn && newerSideUnchanged
            && !resolvedGapIDs.isDisjoint(with: visibleIDs)
        renderedGapIDs = newGapIDs

        // The previous newest item loses its delivery status marker when a newer one
        // arrives, which shrinks its cell. Reconfiguring it in the same apply makes
        // that height change part of the same batch animation as the insertion, so
        // the bubbles slide up in sync; otherwise the collapse snaps separately and
        // the timeline visibly warps (a SwiftUI .animation on the marker is worse:
        // the self-sizing desyncs and clips the bubble). Not wanted in the frozen
        // send-transition apply: rebuilding the hosted content there blanks the
        // status row for a frame, and the reactive update fades it out anyway.
        if animated, let currentNewestItemIdentifier, snapshot.mainItemIdentifiers.contains(currentNewestItemIdentifier) {
            snapshot.reconfigureItems([currentNewestItemIdentifier])
        }

        let layout: Layout? = if !isLive, newestItemIDChanged {
            snapshotLayout()
        } else {
            nil
        }

        // A gap resolving on the newer side of the viewport (its spinner scrolled
        // off the bottom) inserts rows between the visible content and the newest
        // end, which the flipped table measures its offsets from - shifting every
        // visible row. Pin the visible content across the apply. Only for
        // unanimated applies: a visible gap's animated shrink is its own feedback,
        // and mid-animation frames make the anchor's measured position unreliable.
        let gapPinLayout: Layout? = if !resolvedGapIDs.isEmpty, !visibleGapResolved, !frozenApply {
            snapshotLayout()
        } else {
            nil
        }

        if frozenApply, let reference = sendTransitionReference {
            // Mid send transition the timeline is pinned: apply without any row
            // animation, re-pin, and when the sent message arrives fade it into the
            // slot the composer vacated before drifting to bottom-pinned. Once the
            // settle is moving the send-time reference is stale, so later applies
            // (delivery status, receipts) go unpinned rather than yanking the
            // content back (the bounce).
            UIView.performWithoutAnimation {
                dataSource.apply(snapshot, animatingDifferences: false)
                tableView.layoutIfNeeded()
                if !sendTransitionDriftStarted {
                    if cellFrame(for: reference.id.uniqueID) == nil,
                       let indexPath = dataSource.indexPath(for: reference.id.uniqueID) {
                        // A message taller than the frame oversize pushes the
                        // reference cell beyond the materialised window, so the
                        // pin can't measure it and the settle would run from the
                        // unpinned offset (the >9-line dive). Scroll it back into
                        // the window inside this un-committed pass - which also
                        // materialises the new row's REAL height; contentSize
                        // arithmetic is estimate-poisoned for exactly that row -
                        // and let the delta pin below do its usual exact fix.
                        // Strip before upstreaming: dip diagnostics.
                        MXLog.info("SendTransition: materialising the reference for the pin")
                        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                        tableView.layoutIfNeeded()
                    }
                    restoreSendTransitionPosition(reference)
                }
            }

            if newestItemIDChanged {
                // One settle, all the way: absolute bottom is computable in the
                // frozen coordinates (final view height = height at send + the
                // measured collapse delta), so the whole residual runs as a
                // single ease-out curve in parallel with the collapse - no
                // second phase, no allowances, and the status-row shrink can't
                // offset an absolute target. The geometry restore at the end
                // waits for this to land (sendTransitionRestoreDeferred).
                let finalViewHeight = sendTransitionViewHeightAtBegin + sendTransitionExpectedDelta
                let target = -1 - (tableView.frame.height - finalViewHeight)
                let travel = tableView.contentOffset.y - target
                // A message that fills the final viewport on its own leaves no
                // older content visible once the settle lands, so the whole
                // motion reads as the message zooming in from below. Snap to
                // the target unanimated and let the fade below carry the
                // transition alone. The height is measured from the laid-out
                // cell; a message so tall it isn't even materialised within
                // the oversized frame qualifies by definition. Same deal when
                // the residual travel itself exceeds a screenful.
                let newMessageHeight = newestItemIdentifier.flatMap { cellFrame(for: $0)?.height } ?? .greatestFiniteMagnitude
                let snap = newMessageHeight >= finalViewHeight || travel > finalViewHeight
                if snap {
                    MXLog.info("SendTransition: snapping, newMessageHeight=\(newMessageHeight) travel=\(travel) finalViewHeight=\(finalViewHeight)")
                    sendTransitionDriftStarted = true
                    sendTransitionIsSettling = false
                    UIView.performWithoutAnimation {
                        tableView.contentOffset.y = target
                        tableView.layoutIfNeeded()
                    }
                }

                if let newestItemIdentifier,
                   !currentSnapshot.itemIdentifiers.contains(newestItemIdentifier),
                   let indexPath = dataSource.indexPath(for: newestItemIdentifier),
                   let cell = tableView.cellForRow(at: indexPath) {
                    // The collapse reveals the slot; fade the message in as it does.
                    cell.alpha = 0
                    UIView.animate(withDuration: 0.2) {
                        cell.alpha = 1
                    }
                }

                if !snap, abs(travel) > 1 {
                    settle(to: target)
                }
            }
        } else {
            // A single-line send's transition ends here: the animated apply below
            // is its slide-in, with a fade layered on so it doesn't pop.
            let endingSendTransition = sendTransitionReference != nil
            if endingSendTransition {
                endSendTransition()
            }
            if visibleGapResolved, !animated {
                // Fade (not the default slide) plus the neighbours closing the slot
                // (or the fetched rows opening it) reads as the spinner shrinking
                // away. Plain batch duration: wrapping the apply in a shorter
                // UIView.animate cut the rows' own height animations short and
                // they snapped the remainder at the end.
                let defaultRowAnimation = dataSource.defaultRowAnimation
                dataSource.defaultRowAnimation = .fade
                dataSource.apply(snapshot, animatingDifferences: true)
                dataSource.defaultRowAnimation = defaultRowAnimation
            } else {
                dataSource.apply(snapshot, animatingDifferences: animated)
            }
            if endingSendTransition, animated,
               let newestItemIdentifier,
               !currentSnapshot.itemIdentifiers.contains(newestItemIdentifier),
               let indexPath = dataSource.indexPath(for: newestItemIdentifier),
               let cell = tableView.cellForRow(at: indexPath) {
                cell.alpha = 0
                UIView.animate(withDuration: 0.25) {
                    cell.alpha = 1
                }
            }
        }
        
        if let focussedEvent, focussedEvent.appearance != .hasAppeared {
            scrollToItem(eventID: focussedEvent.eventID, animated: focussedEvent.appearance == .animated)
        } else if let layout {
            restoreLayout(layout)
        } else if let gapPinLayout {
            restoreLayoutPreservingMomentum(gapPinLayout)
        } else if isSwitchingTimelines {
            scrollToNewestItem(animated: false)
        }
        
        if isSwitchingTimelines {
            coordinator.send(viewAction: .hasSwitchedTimeline)
        }
        
        // Re-evaluate after the snapshot has been applied so the new layout is reflected.
        DispatchQueue.main.async { [weak self] in
            self?.updateReadMarkerVisibility()
            
            // Make sure we paginate with the final timeline geometry
            self?.paginatePublisher.send(())
        }
    }
    
    /// Scrolls to the newest item in the timeline.
    private func scrollToNewestItem(animated: Bool) {
        guard !timelineItemsIDs.isEmpty else {
            return
        }
        // A send transition is already carrying the timeline to the bottom.
        guard sendTransitionReference == nil else {
            return
        }
        tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: animated)
        scrollDirectionPublisher.send(.bottom)
    }
    
    /// Scrolls to the oldest item in the timeline.
    private func scrollToOldestItem(animated: Bool) {
        // The data source can lag behind timelineItemsIDs, so scroll against the table's actual
        // contents to avoid targeting a section or row that doesn't exist yet.
        guard tableView.numberOfSections > 1,
              tableView.numberOfRows(inSection: 1) > 0 else {
            return
        }
        tableView.scrollToRow(at: IndexPath(item: tableView.numberOfRows(inSection: 1) - 1, section: 1), at: .bottom, animated: animated)
        scrollDirectionPublisher.send(.top)
    }
    
    /// Scrolls to the item with the corresponding unique ID. Used to jump to virtual items like
    /// the read marker that have no event ID. Positions the item near the middle of the viewport
    /// so the user can see what's above and below the marker.
    private func scrollToItem(uniqueID: TimelineItemIdentifier.UniqueID, animated: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let indexPath = dataSource?.indexPath(for: uniqueID) else { return }
            tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
        }
    }
    
    /// Scrolls to the item with the corresponding event ID if loaded in the timeline,
    /// positioning the top of the message halfway up the viewport.
    private func scrollToItem(eventID: String, animated: Bool) {
        DispatchQueue.main.async { [weak self] in // Fixes #2805
            guard let self else { return }
            if let kvPair = timelineItemsDictionary.first(where: { $0.value.identifier.eventID == eventID }),
               let indexPath = dataSource?.indexPath(for: kvPair.key) {
                if animated, tableView.rectForRow(at: indexPath).intersects(tableView.bounds.insetBy(dx: 0, dy: -tableView.bounds.height)) {
                    // Within a viewport of the visible rows the heights are real, so the
                    // target is exact and the scroll animation lands cleanly. Keep a silent
                    // post-animation settle as insurance (scrollViewDidEndScrollingAnimation).
                    focusRefinementIndexPath = indexPath
                    tableView.setContentOffset(CGPoint(x: 0, y: focussedRowTargetOffset(for: indexPath)), animated: true)
                } else if animated {
                    // A distant target sits behind estimated row heights: an animated scroll
                    // can't aim at it correctly, and correcting afterwards reads as a bounce.
                    // Crossfade a layout-settled jump instead.
                    UIView.transition(with: tableView, duration: 0.25, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                        self.scrollToFocussedRowSettlingLayout(at: indexPath)
                    }
                } else {
                    scrollToFocussedRowSettlingLayout(at: indexPath)
                }
                coordinator.send(viewAction: .scrolledToFocussedItem)
                // Ensure VoiceOver focus happens after the scroll animation (if any)
                DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.5 : 0.0)) {
                    if let cell = self.tableView.cellForRow(at: indexPath) {
                        UIAccessibility.post(notification: .layoutChanged, argument: cell)
                    }
                }
            }
        }
    }

    /// The row awaiting a post-animation position refinement, if any.
    private var focusRefinementIndexPath: IndexPath?

    /// The content offset that puts the top of the given row's message halfway up the
    /// viewport. In the flipped table the message's visual top is the row rect's `maxY`.
    ///
    /// Only accurate once the rows between the current offset and the target have real
    /// (non-estimated) heights - callers must re-evaluate after layout settles.
    private func focussedRowTargetOffset(for indexPath: IndexPath) -> CGFloat {
        let rowRect = tableView.rectForRow(at: indexPath)
        let target = rowRect.maxY - tableView.visibleSize.height / 2

        let minOffset = -tableView.adjustedContentInset.top
        let maxOffset = max(minOffset, tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom)
        return min(max(target, minOffset), maxOffset)
    }

    /// Jumps to the focussed row, re-measuring until its position stops moving as
    /// estimated row heights are replaced by real ones.
    private func scrollToFocussedRowSettlingLayout(at indexPath: IndexPath) {
        for _ in 0..<3 {
            let target = focussedRowTargetOffset(for: indexPath)
            if abs(tableView.contentOffset.y - target) < 1 {
                return
            }
            tableView.setContentOffset(CGPoint(x: 0, y: target), animated: false)
            tableView.layoutIfNeeded()
        }
    }
    
    /// Checks whether or not pagination is needed in either direction and requests one if so.
    ///
    /// **Note:** Prefer not to call this directly, instead using ``paginatePublisher`` to throttle requests.
    private func paginateIfNeeded() {
        guard !hasPendingItems else { return }
        
        if paginationState.backward == .idle,
           tableView.contentOffset.y > tableView.contentSize.height - tableView.visibleSize.height * 2.0 {
            coordinator.send(viewAction: .paginateBackwards)
        }
        if !isLive,
           paginationState.forward == .idle,
           tableView.contentOffset.y < tableView.visibleSize.height {
            coordinator.send(viewAction: .paginateForwards)
        }
    }
    
    /// Updates the `isReadMarkerVisible` binding based on whether the read marker is currently
    /// on screen or below the viewport (already scrolled past).
    ///
    /// In the flipped table view, "above the viewport" means a higher index path. The marker is
    /// considered "visible or below" iff its index path ≤ the maximum visible index path.
    private func updateReadMarkerVisibility() {
        let isVisible: Bool = {
            guard let readMarkerUniqueID,
                  let readMarkerIndexPath = dataSource?.indexPath(for: readMarkerUniqueID),
                  let visibleIndexPaths = tableView.indexPathsForVisibleRows,
                  let maxVisibleIndexPath = visibleIndexPaths.max() else {
                return false
            }
            return readMarkerIndexPath <= maxVisibleIndexPath
        }()
        
        if isReadMarkerVisible != isVisible {
            isReadMarkerVisible = isVisible
        }
    }
    
    private func sendLastVisibleItemReadReceipt() {
        // Find the last visible timeline item and send a read receipt for it
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else {
            return
        }
        
        // These are already in reverse order because the table view is flipped
        for indexPath in visibleIndexPaths {
            if let visibleItemUniqueID = dataSource?.itemIdentifier(for: indexPath),
               let visibleItemID = timelineItemsDictionary[visibleItemUniqueID]?.identifier {
                coordinator.send(viewAction: .sendReadReceiptIfNeeded(visibleItemID))
                return
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension TimelineTableViewController: UIGestureRecognizerDelegate {
    /// The end-selection tap: never over the selected text itself (caret moves, the
    /// edit menu), and always alongside every other recogniser.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard coordinator.context.textSelection != nil else { return false }
        var view: UIView? = touch.view
        while let current = view {
            if current is MessageTextView { return false }
            view = current.superview
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

extension TimelineTableViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Self-heal after a cancelled drag gesture: if items queued up while a
        // phantom drag wedged the apply gate, flush them as soon as UIKit says
        // no finger is down (paginateIfNeeded also waits on hasPendingItems, so
        // a wedge here otherwise blocks pagination too).
        if hasPendingItems, canApplySnapshot {
            hasPendingItems = false
            applySnapshot()
        }

        paginatePublisher.send(())
        
        // Dispatch to fix runtime warning about making changes during a view update.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            let isScrolledToBottom = scrollView.contentOffset.y <= 0 || sendTransitionIsSettling
            
            // Only update the binding on changes to avoid needlessly recomputing the hierarchy when scrolling.
            if self.isScrolledToBottom != isScrolledToBottom {
                self.isScrolledToBottom = isScrolledToBottom
                if isScrolledToBottom, self.hasNewMessagesAtBottom {
                    self.hasNewMessagesAtBottom = false
                }
            }
            
            if !isScrolledToBottom {
                updateFloatingDate()
            }
            
            updateReadMarkerVisibility()
        }
        
        // We never want the table view to be fully at the bottom to allow the status bar tap to work properly
        if scrollView.contentOffset.y == 0 {
            scrollView.contentOffset.y = -1
        }
        
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView.superview).y
        if velocity > scrollVelocityThreshold {
            scrollDirectionPublisher.send(.top)
        } else if velocity < -scrollVelocityThreshold {
            scrollDirectionPublisher.send(.bottom)
        }
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollToOldestItem(animated: true)
        return false
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDraggingScrollView = true
        scrollViewIsScrolling = true

        // The user took over - don't yank the viewport back to the focussed row,
        // and settle any in-flight send transition, handing the scroll position
        // over at its currently rendered value.
        focusRefinementIndexPath = nil
        if sendTransitionIsSettling {
            sendTransitionIsSettling = false
            if let presentation = tableView.layer.presentation() {
                let offset = presentation.bounds.origin
                tableView.layer.removeAllAnimations()
                tableView.contentOffset = offset
            }
        }
        endSendTransition()
        // A deferred geometry restore can outlive endSendTransition (reference
        // already nil); the user taking over must not scroll frozen coordinates.
        finishSendTransitionGeometry()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        sendLastVisibleItemReadReceipt()
        
        isDraggingScrollView = false
        if !decelerate {
            scrollViewIsScrolling = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        sendLastVisibleItemReadReceipt()
        scrollViewIsScrolling = false
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        sendLastVisibleItemReadReceipt()
        sendTransitionIsSettling = false

        // The animated focus scroll lands wherever the pre-animation height estimates
        // said the row was - correct against the now-materialised layout.
        if let indexPath = focusRefinementIndexPath {
            focusRefinementIndexPath = nil
            scrollToFocussedRowSettlingLayout(at: indexPath)
        }
    }
}

// MARK: - Floating Date Badge

extension TimelineTableViewController {
    /// Computes the timestamp for the topmost visible timeline item
    /// and updates the floating date binding.
    func updateFloatingDate() {
        guard let date = newestVisibleDate() else {
            return
        }
        
        // Before updating it already schedule it's removal or the future.
        // The schedule needs to happen regardless of a value change
        // to extend the display duration of the floating date.
        scheduleFloatingDateHide()
        
        // Only update when the calendar day changes to avoid needless SwiftUI recomputation.
        if floatingDate.map({ !Calendar.current.isDate($0, inSameDayAs: date) }) ?? true {
            floatingDate = date
        }
    }
    
    /// Schedules the floating date badge to be hidden after a delay.
    func scheduleFloatingDateHide() {
        floatingDateHideWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.floatingDate = nil
        }
        floatingDateHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
    
    /// Scrolls to the first (oldest) item on the same calendar day as the current floating date.
    private func scrollToFirstItemForCurrentDate() {
        guard let floatingDate else { return }
        // timelineItemsDictionary is ordered oldest-first; the first match is the earliest item for that day.
        for uniqueID in timelineItemsDictionary.keys {
            if let timestamp = timelineItemsDictionary[uniqueID]?.timestamp,
               Calendar.current.isDate(timestamp, inSameDayAs: floatingDate),
               let indexPath = dataSource?.indexPath(for: uniqueID) {
                // The table view is flipped, so .bottom aligns the cell to the visual top.
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                return
            }
        }
    }
    
    /// Returns the timestamp of the newest visible timeline item.
    ///
    /// The table view is flipped, so the "newest" visible cell on screen is
    /// actually the *last* index path in `indexPathsForVisibleRows`.
    private func newestVisibleDate() -> Date? {
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows,
              !visibleIndexPaths.isEmpty else {
            return nil
        }
        
        // In a flipped table view the last index path is the topmost item on screen.
        let orderedPaths = visibleIndexPaths.reversed()
        
        // Walk from topmost downward and return the timestamp of the first item that has one.
        for indexPath in orderedPaths {
            if let uniqueID = dataSource?.itemIdentifier(for: indexPath),
               let timestamp = timelineItemsDictionary[uniqueID]?.timestamp {
                return timestamp
            }
        }
        
        return nil
    }
}

// MARK: - Layout

extension TimelineTableViewController {
    /// The sections of the table view used in the diffable data source.
    nonisolated enum TimelineSection {
        case main
        case typingIndicator
    }
    
    /// A representation of the table's layout based on a particular item.
    private struct Layout {
        let id: TimelineItemIdentifier
        let frame: CGRect
    }
    
    /// The current layout of the table, based on the newest timeline item.
    private func snapshotLayout() -> Layout? {
        guard let newestItemID = newestVisibleItemID(),
              let newestCellFrame = cellFrame(for: newestItemID.uniqueID) else {
            return nil
        }
        return Layout(id: newestItemID, frame: newestCellFrame)
    }
    
    /// Restores an anchor row to its snapshotted on-screen position without
    /// cancelling any in-flight scroll: adjusting `bounds.origin` directly,
    /// unlike `scrollToRow`/`setContentOffset`, preserves deceleration, so a
    /// gap resolving mid-scroll doesn't kill the user's fling.
    private func restoreLayoutPreservingMomentum(_ layout: Layout) {
        guard let indexPath = dataSource?.indexPath(for: layout.id.uniqueID) else { return }
        tableView.layoutIfNeeded()
        // rectForRow doesn't need the cell to be materialised.
        let screenFrame = tableView.convert(tableView.rectForRow(at: indexPath), to: tableView.superview)
        let deltaY = screenFrame.maxY - layout.frame.maxY
        if deltaY != 0 {
            tableView.bounds.origin.y -= deltaY
        }
    }

    /// Restores the timeline's layout from an old snapshot.
    private func restoreLayout(_ layout: Layout) {
        if let indexPath = dataSource?.indexPath(for: layout.id.uniqueID) {
            // Scroll the item into view.
            tableView.scrollToRow(at: indexPath, at: .top, animated: false)
            
            // Remove any unwanted offset that was added by scrollToRow.
            if let frame = cellFrame(for: layout.id.uniqueID) {
                let deltaY = frame.maxY - layout.frame.maxY
                if deltaY != 0 {
                    tableView.contentOffset.y -= deltaY
                }
            }
        }
    }
    
    /// Returns the frame of the cell for a particular timeline item.
    private func cellFrame(for uniqueID: TimelineItemIdentifier.UniqueID) -> CGRect? {
        guard let timelineCell = tableView.visibleCells.first(where: { ($0 as? TimelineItemCell)?.item?.identifier.uniqueID == uniqueID }) else {
            return nil
        }
        
        return tableView.convert(timelineCell.frame, to: tableView.superview)
    }
    
    /// The item ID of the newest visible item in the timeline.
    private func newestVisibleItemID() -> TimelineItemIdentifier? {
        guard let timelineCell = tableView.visibleCells.first(where: {
            guard let cell = $0 as? TimelineItemCell, let itemType = cell.item?.type else { return false }
            switch itemType {
            // Transient cells make for a bad scroll anchor, and state-event
            // groups take a new identity when events land next to them.
            case .paginationIndicator, .gap, .group:
                return false
            default:
                return true
            }
        }) else {
            return nil
        }
        return (timelineCell as? TimelineItemCell)?.item?.identifier
    }
}

private extension NSDiffableDataSourceSnapshot<TimelineTableViewController.TimelineSection, TimelineItemIdentifier.UniqueID> {
    var numberOfMainItems: Int {
        guard sectionIdentifiers.contains(.main) else { return 0 }
        return numberOfItems(inSection: .main)
    }
    
    var mainItemIdentifiers: [TimelineItemIdentifier.UniqueID] {
        guard sectionIdentifiers.contains(.main) else { return [] }
        return itemIdentifiers(inSection: .main)
    }
}

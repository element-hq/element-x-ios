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

class TypingMembersObservableObject: ObservableObject {
    @Published var members: [String] = []
    
    init(members: [String]) {
        self.members = members
    }
}

/// A table view that reports its layout passes.
private final class TimelineTableView: UITableView {
    var didLayoutSubviews: (() -> Void)?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        didLayoutSubviews?()
    }
}

/// A table view controller that displays the timeline of a room.
///
/// This class subclasses `UIViewController` as `UITableViewController` adds some
/// extra keyboard handling magic that wasn't playing well with SwiftUI (as of iOS 16.1).
/// Also this TableViewController uses a **flipped tableview**
class TimelineTableViewController: UIViewController {
    private let coordinator: TimelineViewRepresentable.Coordinator
    private let tableView = TimelineTableView(frame: .zero, style: .plain)
    
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
            !isDraggingScrollView
        } else {
            // Forward pagination breaks inertial scrolling when fixing the offset.
            !scrollViewIsScrolling
        }
    }
    
    /// There are pending items in `timelineItemsDictionary` that haven't been applied to the data source.
    private var hasPendingItems = false
    
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
            } else {
                finishSendHold(scrollingToBottom: false)
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
    
    /// Keeps the timeline still while a message sent from the bottom lands, see ``SendHold``.
    private var sendHold: SendHold?
    /// The pending timeout of the current ``sendHold`` phase.
    private var sendHoldTimer: DispatchWorkItem?
    
    init(coordinator: TimelineViewRepresentable.Coordinator,
         isScrolledToBottom: Binding<Bool>,
         isReadMarkerVisible: Binding<Bool>,
         hasNewMessagesAtBottom: Binding<Bool>,
         floatingDate: Binding<Date?>,
         scrollToBottomPublisher: PassthroughSubject<Void, Never>,
         scrollToFirstItemForDatePublisher: PassthroughSubject<Void, Never>,
         scrollToReadMarkerPublisher: PassthroughSubject<TimelineItemIdentifier.UniqueID, Never>,
         sendProgressPublisher: PassthroughSubject<TimelineSendProgress, Never>) {
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
        
        tableView.didLayoutSubviews = { [weak self] in
            self?.pinSendHoldAnchor()
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
        
        sendProgressPublisher
            .sink { [weak self] progress in
                switch progress {
                case .sending: self?.beginSendHold()
                case .clearingComposer: self?.sendHoldComposerWillClear()
                }
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        finishSendHold(scrollingToBottom: sendHold?.phase != .detached)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        guard tableView.frame.size != view.frame.size else {
            return
        }
        
        if sendHold != nil {
            if tableView.frame.width != view.frame.width {
                finishSendHold(scrollingToBottom: sendHold?.phase != .detached)
            } else {
                sendHoldViewWillResize()
            }
        }
        
        tableView.frame = CGRect(origin: .zero, size: view.frame.size)
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
                    RoomTimelineItemView(viewState: viewState)
                        .id(id)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(accessibilityReduceMotionDidChange),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                               object: nil)
    }
    
    @objc private func accessibilityReduceMotionDidChange() {
        dataSource?.defaultRowAnimation = (UIAccessibility.isReduceMotionEnabled ? .none : .top)
    }
    
    /// Updates the table view with the latest items from the ``timelineItems`` array. After
    /// updating the data, the table will be scrolled to the bottom if it was visible otherwise
    /// the scroll position will be updated to maintain the position of the last visible item.
    private func applySnapshot() {
        guard let dataSource else { return }
        
        var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, TimelineItemIdentifier.UniqueID>()
        
        // We don't want to display the typing notification in this timeline
        if coordinator.context.viewState.timelineKind != .pinned {
            snapshot.appendSections([.typingIndicator])
            snapshot.appendItems([TimelineItemIdentifier.UniqueID(TimelineTypingIndicatorCell.reuseIdentifier)])
        }
        snapshot.appendSections([.main])
        snapshot.appendItems(timelineItemsIDs)
        
        let currentSnapshot = dataSource.snapshot()
        
        let isFocussingEvent = focussedEvent.map { $0.appearance != .hasAppeared } ?? false
        if !isLive || isSwitchingTimelines || isFocussingEvent {
            finishSendHold(scrollingToBottom: false)
        }
        
        if sendHold?.phase == .holding {
            applySnapshotWhileHoldingSend(snapshot, currentSnapshot: currentSnapshot)
        } else {
            // We only animate when new items come at the end of a live timeline, ignoring transitions through empty.
            let newestItemIdentifier = snapshot.mainItemIdentifiers.first
            let currentNewestItemIdentifier = currentSnapshot.mainItemIdentifiers.first
            let newestItemIDChanged = snapshot.numberOfMainItems > 0 && currentSnapshot.numberOfMainItems > 0 && newestItemIdentifier != currentNewestItemIdentifier
            let animated = isLive && !isSwitchingTimelines && newestItemIDChanged
            
            let layout: Layout? = if !isLive, newestItemIDChanged {
                snapshotLayout()
            } else {
                nil
            }
            
            dataSource.apply(snapshot, animatingDifferences: animated)
            
            if let focussedEvent, focussedEvent.appearance != .hasAppeared {
                scrollToItem(eventID: focussedEvent.eventID, animated: focussedEvent.appearance == .animated)
            } else if let layout {
                restoreLayout(layout)
            } else if isSwitchingTimelines {
                scrollToNewestItem(animated: false)
            }
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
        if let sendHold {
            // A hold ends at the bottom by itself, unless the user has dragged during it.
            guard sendHold.phase == .detached else {
                scrollDirectionPublisher.send(.bottom)
                return
            }
            finishSendHold(scrollingToBottom: false)
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
        finishSendHold(scrollingToBottom: false)
        tableView.scrollToRow(at: IndexPath(item: tableView.numberOfRows(inSection: 1) - 1, section: 1), at: .bottom, animated: animated)
        scrollDirectionPublisher.send(.top)
    }
    
    /// Scrolls to the item with the corresponding unique ID. Used to jump to virtual items like
    /// the read marker that have no event ID. Positions the item near the middle of the viewport
    /// so the user can see what's above and below the marker.
    private func scrollToItem(uniqueID: TimelineItemIdentifier.UniqueID, animated: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let indexPath = dataSource?.indexPath(for: uniqueID) else { return }
            finishSendHold(scrollingToBottom: false)
            tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
        }
    }
    
    /// Scrolls to the item with the corresponding event ID if loaded in the timeline.
    private func scrollToItem(eventID: String, animated: Bool) {
        DispatchQueue.main.async { [weak self] in // Fixes #2805
            guard let self else { return }
            if let kvPair = timelineItemsDictionary.first(where: { $0.value.identifier.eventID == eventID }),
               let indexPath = dataSource?.indexPath(for: kvPair.key) {
                finishSendHold(scrollingToBottom: false)
                // Scrolling to the middle created a small bump in the timeline
                // Using top, which is bottom in the reversed timeline helps with rendering
                // in full long messages and images
                tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
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

extension TimelineTableViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        paginatePublisher.send(())
        
        // Dispatch to fix runtime warning about making changes during a view update.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            // A hold briefly offsets the rows while it keeps them still at the bottom.
            let isScrolledToBottom = scrollView.contentOffset.y <= 0 || (sendHold.map { $0.phase != .detached } ?? false)
            
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
        if scrollView.contentOffset.y == 0, sendHold == nil {
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
        detachSendHold()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        sendLastVisibleItemReadReceipt()
        
        isDraggingScrollView = false
        if !decelerate {
            scrollViewIsScrolling = false
            settleDetachedSendHold()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        sendLastVisibleItemReadReceipt()
        scrollViewIsScrolling = false
        settleDetachedSendHold()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        sendLastVisibleItemReadReceipt()
        if sendHold?.phase == .releasing, abs(scrollView.contentOffset.y - SendHold.bottomOffset) < 0.5 {
            finishSendHold(scrollingToBottom: true)
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
                finishSendHold(scrollingToBottom: false)
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

// MARK: - Send Hold

extension TimelineTableViewController {
    /// Sending from the bottom of the timeline clears the composer, which grows this view, a few frames
    /// before the local echo is inserted. The flipped table's rows follow the view's bottom edge, so they
    /// would drop and then jump back up. A hold pins the newest row instead, so the echo lands in the space
    /// the composer gave back, then scrolls to the bottom once.
    private struct SendHold {
        enum Phase {
            /// The rows are pinned until the composer has cleared and the echo has been inserted.
            case holding
            /// Scrolling to the bottom.
            case releasing
            /// The user dragged during the hold, which ends with the drag.
            case detached
        }
        
        /// The resting offset at the bottom, see `scrollViewDidScroll`.
        static let bottomOffset: CGFloat = -1
        static let clearTimeout: TimeInterval = 1.5
        static let echoTimeout: TimeInterval = 1.0
        /// The composer and the keyboard can resize the view over several passes, so wait for them to stop.
        static let settleInterval: TimeInterval = 0.04
        /// Ends a release whose scroll was stopped without a callback, e.g. by a tap.
        static let releaseTimeout: TimeInterval = 0.6
        
        var phase = Phase.holding
        var pendingClears = 1
        var pendingEchoes = 1
        /// The row kept still, and the window y its visual top (its content maxY in the flipped table) is kept at.
        var anchorID: TimelineItemIdentifier.UniqueID
        var anchorWindowY: CGFloat
        var lastViewBottomWindowY: CGFloat
        var lastResizeTime: CFTimeInterval = 0
    }
    
    private var viewBottomWindowY: CGFloat {
        view.convert(CGPoint(x: 0, y: view.bounds.maxY), to: nil).y
    }
    
    private func beginSendHold() {
        if let sendHold {
            guard sendHold.phase != .detached else { return }
            // Another send before the previous one has settled: hold until both have.
            if sendHold.phase == .releasing {
                self.sendHold?.phase = .holding
                tableView.setContentOffset(tableView.contentOffset, animated: false) // Stops the release.
                guard let anchor = newestItemAnchor() else {
                    finishSendHold(scrollingToBottom: true)
                    return
                }
                self.sendHold?.anchorID = anchor.id
                self.sendHold?.anchorWindowY = anchor.windowY
            }
            self.sendHold?.pendingClears += 1
            self.sendHold?.pendingEchoes += 1
            scheduleSendHoldTimeout(after: SendHold.clearTimeout)
            return
        }
        
        guard isLive, !isSwitchingTimelines, view.window != nil,
              !tableView.isTracking, !tableView.isDecelerating,
              tableView.contentOffset.y <= 0,
              let anchor = newestItemAnchor() else {
            return
        }
        
        sendHold = SendHold(anchorID: anchor.id, anchorWindowY: anchor.windowY, lastViewBottomWindowY: viewBottomWindowY)
        scheduleSendHoldTimeout(after: SendHold.clearTimeout)
    }
    
    private func sendHoldComposerWillClear() {
        guard var sendHold, sendHold.phase == .holding else { return }
        sendHold.pendingClears = max(0, sendHold.pendingClears - 1)
        self.sendHold = sendHold
        scheduleSendHoldTimeout(after: SendHold.echoTimeout)
        scheduleSendHoldReleaseCheck()
    }
    
    /// Called before the table takes the view's new size.
    private func sendHoldViewWillResize() {
        guard var sendHold else { return }
        sendHold.lastResizeTime = CACurrentMediaTime()
        let rise = sendHold.lastViewBottomWindowY - viewBottomWindowY
        sendHold.lastViewBottomWindowY = viewBottomWindowY
        if sendHold.phase == .holding, rise > 0 {
            // The composer or the keyboard grew: the empty slot under the newest row shrinks first,
            // then any remainder pushes the rows up as it would without a hold.
            let slot = max(0, SendHold.bottomOffset - tableView.contentOffset.y)
            sendHold.anchorWindowY -= max(0, rise - slot)
        }
        self.sendHold = sendHold
        
        // UIKit clamps an out of range offset when the size changes, which would undo the pin.
        let excess = tableView.contentOffset.y - (tableView.contentSize.height + tableView.adjustedContentInset.bottom - view.frame.height)
        if excess > 0 {
            tableView.contentInset.bottom += excess
        }
    }
    
    /// Called after every layout pass of the table, so any height change keeps the anchor row still.
    private func pinSendHoldAnchor() {
        guard let sendHold, sendHold.phase == .holding,
              let anchorWindowY = visualTopWindowY(of: sendHold.anchorID) else {
            return
        }
        // The rows move down as the offset grows in the flipped table.
        let offset = tableView.contentOffset.y + sendHold.anchorWindowY - anchorWindowY
        guard abs(offset - tableView.contentOffset.y) >= 0.5 else { return }
        
        // Widen the insets first, as UIKit clamps an out of range offset.
        var insets = tableView.contentInset
        insets.top = max(insets.top, -offset - (tableView.adjustedContentInset.top - insets.top))
        insets.bottom = max(insets.bottom, offset + tableView.bounds.height - tableView.contentSize.height - (tableView.adjustedContentInset.bottom - insets.bottom))
        if insets != tableView.contentInset {
            tableView.contentInset = insets
        }
        tableView.contentOffset.y = offset
    }
    
    /// Applies the changes without animation, leaving the pin to keep the rows still.
    private func applySnapshotWhileHoldingSend(_ snapshot: NSDiffableDataSourceSnapshot<TimelineSection, TimelineItemIdentifier.UniqueID>,
                                               currentSnapshot: NSDiffableDataSourceSnapshot<TimelineSection, TimelineItemIdentifier.UniqueID>) {
        guard var sendHold, let dataSource else { return }
        
        let identifiers = Set(snapshot.itemIdentifiers)
        if !identifiers.contains(sendHold.anchorID) {
            guard let survivorID = currentSnapshot.mainItemIdentifiers.first(where: identifiers.contains),
                  let survivorWindowY = visualTopWindowY(of: survivorID) else {
                finishSendHold(scrollingToBottom: true)
                dataSource.apply(snapshot, animatingDifferences: false)
                return
            }
            sendHold.anchorID = survivorID
            sendHold.anchorWindowY = survivorWindowY
        }
        
        // Echoes land at the newest end, unlike any history that back-pagination brings in.
        let currentIdentifiers = Set(currentSnapshot.itemIdentifiers)
        let sentItemCount = snapshot.mainItemIdentifiers
            .prefix { !currentIdentifiers.contains($0) }
            .count { timelineItemsDictionary[$0]?.type.isOutgoing == true }
        sendHold.pendingEchoes = max(0, sendHold.pendingEchoes - sentItemCount)
        self.sendHold = sendHold
        
        UIView.performWithoutAnimation {
            dataSource.apply(snapshot, animatingDifferences: false)
            tableView.layoutIfNeeded()
        }
        
        if sentItemCount > 0 {
            scheduleSendHoldReleaseCheck()
        }
    }
    
    /// Releases once the composer has cleared, the echo is in and the view has stopped resizing.
    private func scheduleSendHoldReleaseCheck() {
        DispatchQueue.main.asyncAfter(deadline: .now() + SendHold.settleInterval) { [weak self] in
            guard let self, let sendHold, sendHold.phase == .holding,
                  sendHold.pendingClears == 0, sendHold.pendingEchoes == 0 else {
                return
            }
            
            if CACurrentMediaTime() - sendHold.lastResizeTime < SendHold.settleInterval {
                scheduleSendHoldReleaseCheck()
            } else {
                releaseSendHold()
            }
        }
    }
    
    private func releaseSendHold() {
        guard let phase = sendHold?.phase, phase != .releasing else { return }
        sendHold?.phase = .releasing
        
        guard !UIAccessibility.isReduceMotionEnabled,
              abs(tableView.contentOffset.y - SendHold.bottomOffset) >= 0.5 else {
            finishSendHold(scrollingToBottom: true)
            return
        }
        
        if tableView.adjustedContentInset.top < -SendHold.bottomOffset {
            tableView.contentInset.top += -SendHold.bottomOffset - tableView.adjustedContentInset.top
        }
        // Animated per frame, unlike UIView.animate which drops the rows scrolling out straight away.
        tableView.setContentOffset(CGPoint(x: 0, y: SendHold.bottomOffset), animated: true)
        scheduleSendHoldTimeout(after: SendHold.releaseTimeout)
    }
    
    private func finishSendHold(scrollingToBottom: Bool) {
        guard sendHold != nil else { return }
        sendHold = nil
        sendHoldTimer?.cancel()
        sendHoldTimer = nil
        
        let offset = scrollingToBottom ? CGPoint(x: 0, y: SendHold.bottomOffset) : tableView.contentOffset
        tableView.setContentOffset(offset, animated: false) // Also stops a running release.
        tableView.contentInset = .zero
        scrollViewDidScroll(tableView)
        if scrollingToBottom {
            scrollDirectionPublisher.send(.bottom)
        }
        sendLastVisibleItemReadReceipt()
    }
    
    private func detachSendHold() {
        guard sendHold != nil else { return }
        sendHold?.phase = .detached
        sendHoldTimer?.cancel()
        sendHoldTimer = nil
    }
    
    /// Ends a hold the user dragged during, closing the empty slot if it is still on screen.
    private func settleDetachedSendHold() {
        guard sendHold?.phase == .detached else { return }
        if tableView.contentOffset.y < SendHold.bottomOffset - 0.5 {
            releaseSendHold()
        } else {
            finishSendHold(scrollingToBottom: false)
        }
    }
    
    /// Every phase but `detached` has a timeout, which always ends in `finishSendHold`.
    private func scheduleSendHoldTimeout(after interval: TimeInterval) {
        sendHoldTimer?.cancel()
        let timer = DispatchWorkItem { [weak self] in
            guard let self else { return }
            switch sendHold?.phase {
            case .holding: releaseSendHold()
            case .releasing: finishSendHold(scrollingToBottom: true)
            case .detached, nil: break
            }
        }
        sendHoldTimer = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: timer)
    }
    
    private func newestItemAnchor() -> (id: TimelineItemIdentifier.UniqueID, windowY: CGFloat)? {
        guard let id = dataSource?.snapshot().mainItemIdentifiers.first,
              let windowY = visualTopWindowY(of: id) else {
            return nil
        }
        return (id, windowY)
    }
    
    /// The window y of a row's visual top, which is its content maxY in the flipped table.
    private func visualTopWindowY(of uniqueID: TimelineItemIdentifier.UniqueID) -> CGFloat? {
        guard let indexPath = dataSource?.indexPath(for: uniqueID) else { return nil }
        return tableView.convert(CGPoint(x: 0, y: tableView.rectForRow(at: indexPath).maxY), to: nil).y
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
            guard let cell = $0 as? TimelineItemCell else { return false }
            return !(cell.item?.type is PaginationIndicatorRoomTimelineItem)
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

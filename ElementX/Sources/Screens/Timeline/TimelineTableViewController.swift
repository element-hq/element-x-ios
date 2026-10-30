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
    
    var item: RoomTimelineItemViewState? {
        didSet {
            guard item !== oldValue else { return }
            unanimatedChanges.reset()
            itemChanges = item.map(recordUnanimatedChanges)
        }
    }
    
    private let unanimatedChanges = UnanimatedChanges()
    private var itemChanges: AnyCancellable?
    
    /// Whether this row, or another row of the same table, has an unanimated change to show.
    private var tableHasUnshownUnanimatedChanges: Bool {
        guard !unanimatedChanges.arePending else { return true }
        
        var tableView = superview
        while let view = tableView, !(view is UITableView) {
            tableView = view.superview
        }
        return tableView?.subviews.contains { view in
            guard let cell = view as? TimelineItemCell, cell.window != nil, !cell.isHidden else { return false }
            return cell.unanimatedChanges.arePending
        } ?? false
    }
    
    override func prepareForReuse() {
        item = nil
    }
    
    override func invalidateIntrinsicContentSize() {
        // UIKit animates a self-sizing resize even when SwiftUI changed the content without animation, and animates all
        // of a layout pass's resizes when it animates one. A bubble, already in its new layout at the row's top, would
        // then jump by a header's full height and glide back. So while any row has an unanimated change, none animates.
        if tableHasUnshownUnanimatedChanges {
            UIView.performWithoutAnimation { super.invalidateIntrinsicContentSize() }
        } else {
            super.invalidateIntrinsicContentSize()
        }
    }
    
    /// Shows the content at the row's visual top, also while the row's height lags behind the content's.
    func setContent(@ViewBuilder _ content: () -> some View) {
        contentConfiguration = UIHostingConfiguration { [unanimatedChanges] in
            content()
                // Without `minHeight: 0`, content taller than its row is centred.
                .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .background { UnanimatedChangesObserver(changes: unanimatedChanges) }
        }
        .margins(.all, 0) // Margins are handled in the stylers
        .minSize(height: 1)
        .background(Color.clear)
        
        // Flipping the cell can create some issues with cell resizing, so flip the content View
        contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    /// Makes SwiftUI show the content's pending change now, so that the table's next update resizes the row for it,
    /// instead of a layout pass of its own once SwiftUI gets to the row.
    func layOutPendingContentChange() {
        // Forced, in case SwiftUI hasn't asked for a layout yet.
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
    }
    
    /// Records each change as the view model makes it: several updates can land before the table shows them, and a
    /// later, animated one mustn't make an earlier unanimated change animate.
    private func recordUnanimatedChanges(of item: RoomTimelineItemViewState) -> AnyCancellable {
        // `objectWillChange` fires after the view model has set `animatesResize` for the update.
        item.objectWillChange.sink { [weak item, unanimatedChanges] in
            if item?.animatesResize == false {
                unanimatedChanges.record()
            }
        }
    }
}

/// The changes a cell's item had without animation, until the cell's content has shown them.
private final class UnanimatedChanges: ObservableObject {
    /// Drives `UnanimatedChangesObserver`, so the content sees each change, also one that a later change reverts.
    @Published private(set) var count = 0
    private(set) var arePending = false
    
    func record() {
        count += 1
        arePending = true
    }
    
    func reset() {
        arePending = false
    }
    
    func didShow(upTo shownCount: Int) {
        // It runs before this row and the others resize for the change, so clearing now would let them animate.
        DispatchQueue.main.async { [weak self] in
            guard let self, count == shownCount else { return }
            arePending = false
        }
    }
}

private struct UnanimatedChangesObserver: View {
    @ObservedObject var changes: UnanimatedChanges
    
    var body: some View {
        Color.clear
            .accessibilityHidden(true)
            .onChange(of: changes.count) { _, count in
                changes.didShow(upTo: count)
            }
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
    
    /// An apply runs layout passes and scroll callbacks, and a diffable apply started from one of them crashes (A1).
    private var isApplyingSnapshot = false
    
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
                handleSendHold(.exit(scrollToBottom: false))
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
    
    private lazy var scroller = FlippedTableScroller(tableView: tableView)
    /// Keeps the timeline still while a message sent from the bottom lands.
    private var sendHold = SendHoldMachine()
    /// The row the hold keeps still.
    private var sendHoldAnchorID: TimelineItemIdentifier.UniqueID?
    /// What the hold added to the table's insets, to take away again when it ends.
    private var sendHoldAddedInsets = UIEdgeInsets.zero
    /// The hold's next timeout or settle check.
    private var sendHoldTick: DispatchWorkItem?
    /// Where the view's bottom edge was at the hold's last resize, in window coordinates.
    private var lastViewBottomWindowY: CGFloat = 0
    /// What keeping the reader's place added to the table's insets, such as the spinner's space at the start of the room.
    /// It stays until the reader scrolls out of that space.
    private var pendingPaginationInsets = UIEdgeInsets.zero
    /// Each row's group style as the table last applied it. The view model changes the view states in place, so they
    /// no longer show what an update regrouped.
    private var lastAppliedGroupStyles: [TimelineItemIdentifier.UniqueID: TimelineGroupStyle] = [:]
    
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
                case .clearingComposer: self?.handleSendHold(.composerWillClear)
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
        handleSendHold(.exit(scrollToBottom: sendHold.phase != .detached))
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        guard tableView.frame.size != view.frame.size else {
            return
        }
        
        if tableView.frame.width != view.frame.width {
            handleSendHold(.widthChanged)
        } else if sendHold.phase != .idle {
            sendHoldViewWillResize()
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
                
                cell.setContent { [coordinator, hideTimelineMedia] in
                    RoomTimelineItemView(viewState: viewState)
                        .id(id)
                        .environmentObject(coordinator.context) // Attempted fix at a crash in TimelineItemContextMenu
                        .environment(\.timelineContext, coordinator.context)
                        .environment(\.shouldAutomaticallyLoadImages, !hideTimelineMedia)
                }
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
    
    /// Updates the table view with the latest items from the ``timelineItems`` array. While pages of messages land, the
    /// topmost message on screen stays put in a live timeline, and the bottom one in a detached timeline.
    private func applySnapshot() {
        guard let dataSource else { return }
        assert(!isApplyingSnapshot, "An apply mustn't start from a layout pass or scroll callback of another one.")
        isApplyingSnapshot = true
        defer { isApplyingSnapshot = false }
        
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
            handleSendHold(.exit(scrollToBottom: false))
        }
        if isSwitchingTimelines {
            removePendingPaginationInsets()
        }
        
        if sendHold.isPinning {
            applySnapshotWhileHoldingSend(snapshot, currentSnapshot: currentSnapshot)
        } else {
            let oldIDs = currentSnapshot.mainItemIdentifiers
            let newIDs = snapshot.mainItemIdentifiers
            let plan = ApplyPlanner.plan(for: .init(oldIDs: oldIDs,
                                                    newIDs: newIDs,
                                                    localEchoIDs: localEchoIDs(in: snapshot),
                                                    isLive: isLive,
                                                    isSwitchingTimelines: isSwitchingTimelines,
                                                    isHoldingSend: false,
                                                    reduceMotion: UIAccessibility.isReduceMotionEnabled))
            
            // A detached timeline keeps the reader's place through any update, as the forward spinner can hide a newer page.
            // A live one follows its newest items, so only its oldest end needs it, and only once scrolled up: at the bottom
            // the flipped table already keeps the newest row still. A new timeline starts at its newest item or its focussed
            // event instead.
            let keepsPlace = !isLive || (oldIDs.last != newIDs.last && tableView.contentOffset.y > 0)
            let anchors: [AnchorPolicy.Anchor] = if !plan.animated, !isSwitchingTimelines, keepsPlace {
                AnchorPolicy.anchors(in: captureGeometry(), nearest: isLive ? .top : .bottom, excluding: regroupedIDs(in: snapshot))
            } else {
                []
            }
            
            layOutPendingContentChanges(of: plan.resizedInSameBatchIDs)
            dataSource.apply(snapshot, animatingDifferences: plan.animated)
            fadeIn(plan.fadeInIDs)
            
            if let focussedEvent, focussedEvent.appearance != .hasAppeared {
                scrollToItem(eventID: focussedEvent.eventID, animated: focussedEvent.appearance == .animated)
            } else if !anchors.isEmpty {
                tableView.layoutIfNeeded()
                restore(anchors)
            } else if isSwitchingTimelines {
                scrollToNewestItem(animated: false)
            }
        }
        lastAppliedGroupStyles = Dictionary(uniqueKeysWithValues: timelineItemsDictionary.map { ($0.key, $0.value.groupStyle) })
        
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
    
    /// Echoes only land at the newest end, so the first few items are all that need checking.
    private func localEchoIDs(in snapshot: NSDiffableDataSourceSnapshot<TimelineSection, TimelineItemIdentifier.UniqueID>) -> Set<TimelineItemIdentifier.UniqueID> {
        Set(snapshot.mainItemIdentifiers.prefix(5).filter { timelineItemsDictionary[$0]?.identifier.transactionID != nil })
    }
    
    /// Lets the next apply resize the visible rows for their pending content changes in its own batch.
    private func layOutPendingContentChanges(of ids: [TimelineItemIdentifier.UniqueID]) {
        for id in ids {
            guard let indexPath = dataSource?.indexPath(for: id), let cell = tableView.cellForRow(at: indexPath) as? TimelineItemCell else { continue }
            cell.layOutPendingContentChange()
        }
    }
    
    /// Fades the rows' content in. Never touches the scroll offset.
    private func fadeIn(_ ids: [TimelineItemIdentifier.UniqueID]) {
        for id in ids {
            guard let indexPath = dataSource?.indexPath(for: id), let cell = tableView.cellForRow(at: indexPath) else { continue }
            cell.contentView.alpha = 0
            UIView.animate(withDuration: 0.2) { cell.contentView.alpha = 1 }
        }
    }
    
    /// Scrolls to the newest item in the timeline.
    private func scrollToNewestItem(animated: Bool) {
        guard !timelineItemsIDs.isEmpty, prepareForProgrammaticScroll(to: .newest) else { return }
        tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: animated)
        scrollDirectionPublisher.send(.bottom)
    }
    
    /// Scrolls to the oldest item in the timeline.
    private func scrollToOldestItem(animated: Bool) {
        // The data source can lag behind timelineItemsIDs, so scroll against the table's actual
        // contents to avoid targeting a section or row that doesn't exist yet.
        guard tableView.numberOfSections > 1,
              tableView.numberOfRows(inSection: 1) > 0,
              prepareForProgrammaticScroll(to: .other) else { return }
        tableView.scrollToRow(at: IndexPath(item: tableView.numberOfRows(inSection: 1) - 1, section: 1), at: .bottom, animated: animated)
        scrollDirectionPublisher.send(.top)
    }
    
    /// Scrolls to the item with the corresponding unique ID. Used to jump to virtual items like
    /// the read marker that have no event ID. Positions the item near the middle of the viewport
    /// so the user can see what's above and below the marker.
    private func scrollToItem(uniqueID: TimelineItemIdentifier.UniqueID, animated: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let indexPath = dataSource?.indexPath(for: uniqueID), prepareForProgrammaticScroll(to: .other) else { return }
            tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
        }
    }
    
    /// Scrolls to the item with the corresponding event ID if loaded in the timeline.
    private func scrollToItem(eventID: String, animated: Bool) {
        DispatchQueue.main.async { [weak self] in // Fixes #2805
            guard let self else { return }
            if let kvPair = timelineItemsDictionary.first(where: { $0.value.identifier.eventID == eventID }),
               let indexPath = dataSource?.indexPath(for: kvPair.key) {
                guard prepareForProgrammaticScroll(to: .other) else { return }
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
            let isScrolledToBottom = scrollView.contentOffset.y <= 0 || sendHold.keepsTimelineAtBottom
            
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
            removePaginationInsetsNoLongerNeeded()
        }
        
        // We never want the table view to be fully at the bottom to allow the status bar tap to work properly
        if scrollView.contentOffset.y == 0, sendHold.phase == .idle {
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
        handleSendHold(.dragBegan)
        removePaginationInsetsNoLongerNeeded()
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
        if sendHold.phase == .releasing, abs(scrollView.contentOffset.y - Self.bottomOffset) < 0.5 {
            handleSendHold(.releaseReachedBottom)
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
                guard prepareForProgrammaticScroll(to: .other) else { return }
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
    private enum ScrollTarget {
        case newest
        case other
    }
    
    /// The resting offset at the bottom, see `scrollViewDidScroll`.
    private static let bottomOffset: CGFloat = -1
    private static let detachedPollInterval: TimeInterval = 0.25
    
    private var viewBottomWindowY: CGFloat {
        view.convert(CGPoint(x: 0, y: view.bounds.maxY), to: nil).y
    }
    
    private func handleSendHold(_ event: SendHoldMachine.Event) {
        perform(sendHold.handle(event, now: CACurrentMediaTime()))
        scheduleSendHoldTick()
    }
    
    private func beginSendHold() {
        let canHold = isLive && !isSwitchingTimelines && view.window != nil
            && !tableView.isTracking && !tableView.isDecelerating && tableView.contentOffset.y <= 0
        lastViewBottomWindowY = viewBottomWindowY
        handleSendHold(.sendBegan(canHold: canHold, anchorTop: newestRowAnchor()?.visualTop))
    }
    
    private func perform(_ command: SendHoldMachine.Command) {
        switch command {
        case .none:
            break
        case .startHolding:
            tableView.setContentOffset(tableView.contentOffset, animated: false) // Stops a running release.
            sendHoldAnchorID = newestRowAnchor()?.id
        case .release:
            releaseSendHold()
        case .stopRelease:
            tableView.setContentOffset(tableView.contentOffset, animated: false)
        case .finish(let scrollToBottom):
            finishSendHold(scrollToBottom: scrollToBottom)
        }
    }
    
    /// Called after every layout pass of the table, when the cells have their real rects.
    private func pinSendHoldAnchor() {
        guard sendHold.isPinning, let anchorID = sendHoldAnchorID, let indexPath = dataSource?.indexPath(for: anchorID) else { return }
        sendHoldAddedInsets += scroller.moveRowsVisually(by: sendHold.anchorTarget - scroller.visualTop(of: indexPath))
    }
    
    /// Called before the table takes the view's new size: a frame change clamps an out-of-range offset.
    private func sendHoldViewWillResize() {
        let rise = lastViewBottomWindowY - viewBottomWindowY
        lastViewBottomWindowY = viewBottomWindowY
        handleSendHold(.viewHeightChanged(rise: rise, slot: max(0, Self.bottomOffset - tableView.contentOffset.y)))
        sendHoldAddedInsets += scroller.widenInsets(toAllow: tableView.contentOffset.y, height: view.frame.height)
    }
    
    /// Applies the update without any animation, leaving the pin to keep the rows still.
    private func applySnapshotWhileHoldingSend(_ snapshot: NSDiffableDataSourceSnapshot<TimelineSection, TimelineItemIdentifier.UniqueID>,
                                               currentSnapshot: NSDiffableDataSourceSnapshot<TimelineSection, TimelineItemIdentifier.UniqueID>) {
        guard let dataSource else { return }
        
        let identifiers = Set(snapshot.itemIdentifiers)
        if let anchorID = sendHoldAnchorID, !identifiers.contains(anchorID) {
            guard let survivorID = currentSnapshot.mainItemIdentifiers.first(where: identifiers.contains),
                  let indexPath = dataSource.indexPath(for: survivorID) else {
                handleSendHold(.exit(scrollToBottom: true))
                UIView.performWithoutAnimation { dataSource.apply(snapshot, animatingDifferences: false) }
                return
            }
            sendHoldAnchorID = survivorID
            handleSendHold(.anchorReplaced(top: scroller.visualTop(of: indexPath)))
        }
        
        // Echoes land at the newest end, unlike any history that back-pagination brings in.
        let currentIdentifiers = Set(currentSnapshot.itemIdentifiers)
        let ownEchoes = snapshot.mainItemIdentifiers
            .prefix { !currentIdentifiers.contains($0) }
            .count { timelineItemsDictionary[$0]?.identifier.transactionID != nil }
        let plan = ApplyPlanner.plan(for: .init(oldIDs: currentSnapshot.mainItemIdentifiers,
                                                newIDs: snapshot.mainItemIdentifiers,
                                                localEchoIDs: localEchoIDs(in: snapshot),
                                                isLive: isLive,
                                                isSwitchingTimelines: isSwitchingTimelines,
                                                isHoldingSend: true,
                                                reduceMotion: UIAccessibility.isReduceMotionEnabled))
        
        UIView.performWithoutAnimation {
            layOutPendingContentChanges(of: plan.resizedInSameBatchIDs)
            dataSource.apply(snapshot, animatingDifferences: false)
            tableView.layoutIfNeeded()
        }
        fadeIn(plan.fadeInIDs)
        handleSendHold(.applied(ownEchoes: ownEchoes))
    }
    
    /// Called when a drag ends without decelerating, when a deceleration ends, and at the detached timeout.
    private func settleDetachedSendHold() {
        guard sendHold.phase == .detached else { return }
        let offset = tableView.contentOffset.y
        // The slot under the newest row, or, when the rows don't fill the table, the space past the oldest one.
        let isInHoldSpace = offset < Self.bottomOffset - 0.5 || offset > scroller.offsetRange(without: sendHoldAddedInsets).upperBound + 0.5
        handleSendHold(.dragEnded(isInHoldSpace: isInHoldSpace))
    }
    
    /// Every programmatic scroll goes through here so a send hold never fights it.
    /// - Returns: whether the caller should go on and scroll.
    private func prepareForProgrammaticScroll(to target: ScrollTarget) -> Bool {
        switch (target, sendHold.phase) {
        case (.newest, .holding), (.newest, .releasing):
            scrollDirectionPublisher.send(.bottom) // The hold is already taking the timeline to the bottom.
            return false
        case (.newest, .detached), (.other, .holding), (.other, .releasing), (.other, .detached):
            handleSendHold(.exit(scrollToBottom: false))
            return true
        case (_, .idle):
            return true
        }
    }
    
    private func releaseSendHold() {
        let motion = OffsetMotionPolicy.motion(for: .init(travel: tableView.contentOffset.y - Self.bottomOffset,
                                                          viewportHeight: tableView.bounds.height,
                                                          reduceMotion: UIAccessibility.isReduceMotionEnabled,
                                                          isVoiceOverRunning: UIAccessibility.isVoiceOverRunning))
        switch motion {
        case .systemAnimated:
            sendHoldAddedInsets += scroller.widenInsets(toAllow: Self.bottomOffset)
            tableView.setContentOffset(CGPoint(x: 0, y: Self.bottomOffset), animated: true)
        case .snap:
            handleSendHold(.releaseReachedBottom)
        }
    }
    
    private func finishSendHold(scrollToBottom: Bool) {
        sendHoldTick?.cancel()
        sendHoldTick = nil
        sendHoldAnchorID = nil
        UIView.performWithoutAnimation {
            let offset = scrollToBottom ? CGPoint(x: 0, y: Self.bottomOffset) : tableView.contentOffset
            tableView.setContentOffset(offset, animated: false) // Also stops a running release.
        }
        // Without scrolling, this clamps rows left in the hold's space. The settle releases those instead, and every other
        // caller scrolls, swaps the content or goes away next.
        scroller.removeInsets(sendHoldAddedInsets)
        sendHoldAddedInsets = .zero
        scrollViewDidScroll(tableView)
        if scrollToBottom {
            scrollDirectionPublisher.send(.bottom)
        }
        sendLastVisibleItemReadReceipt()
    }
    
    private func scheduleSendHoldTick(minimumDelay: TimeInterval = 0) {
        sendHoldTick?.cancel()
        let now = CACurrentMediaTime()
        guard let next = sendHold.nextTick(after: now) else {
            sendHoldTick = nil
            return
        }
        let tick = DispatchWorkItem { [weak self] in self?.sendHoldTickFired() }
        sendHoldTick = tick
        DispatchQueue.main.asyncAfter(deadline: .now() + max(minimumDelay, next - now), execute: tick)
    }
    
    /// Forwards a tick to the machine. A detached hold's timeout settles as a drag end does, once no drag or fling runs:
    /// settling then would stop the fling, as any offset write does.
    private func sendHoldTickFired() {
        guard sendHold.phase == .detached else {
            handleSendHold(.tick)
            return
        }
        if tableView.isTracking || tableView.isDecelerating {
            scheduleSendHoldTick(minimumDelay: Self.detachedPollInterval)
        } else {
            settleDetachedSendHold()
        }
    }
    
    private func newestRowAnchor() -> AnchorPolicy.Anchor? {
        guard let id = dataSource?.snapshot().mainItemIdentifiers.first, let indexPath = dataSource?.indexPath(for: id) else { return nil }
        return AnchorPolicy.Anchor(id: id, visualTop: scroller.visualTop(of: indexPath))
    }
}

// MARK: - Anchoring

extension TimelineTableViewController {
    /// The visible rows, top of the screen first.
    private func captureGeometry() -> TimelineGeometry {
        let mainSection = dataSource?.snapshot().indexOfSection(.main)
        let rows = (tableView.indexPathsForVisibleRows ?? [])
            .filter { $0.section == mainSection }
            .compactMap { indexPath -> TimelineGeometry.Row? in
                guard let id = dataSource?.itemIdentifier(for: indexPath), let item = timelineItemsDictionary[id] else { return nil }
                let rect = tableView.convert(tableView.rectForRow(at: indexPath), to: nil)
                return TimelineGeometry.Row(id: id, kind: .init(item.type), visualTop: rect.minY, visualBottom: rect.maxY)
            }
            .sorted { $0.visualTop < $1.visualTop }
        return TimelineGeometry(rows: rows, viewportBottom: viewBottomWindowY, viewportHeight: tableView.bounds.height)
    }
    
    /// Puts the first anchor that survived the update back where it was, without stopping a fling.
    private func restore(_ anchors: [AnchorPolicy.Anchor]) {
        for anchor in anchors {
            guard let indexPath = dataSource?.indexPath(for: anchor.id) else { continue }
            let correction = AnchorPolicy.correction(for: anchor, newVisualTop: scroller.visualTop(of: indexPath))
            let added = scroller.moveRowsVisually(by: -correction)
            pendingPaginationInsets += added
            return
        }
    }
    
    /// Only for a new timeline: if the space is on screen, UIKit snaps the old rows over it, and the new rows hide that.
    private func removePendingPaginationInsets() {
        scroller.removeInsets(pendingPaginationInsets)
        pendingPaginationInsets = .zero
    }
    
    private func removePaginationInsetsNoLongerNeeded() {
        guard pendingPaginationInsets != .zero else { return }
        pendingPaginationInsets = scroller.removeInsetsNoLongerNeeded(from: pendingPaginationInsets)
    }
    
    private func regroupedIDs(in snapshot: NSDiffableDataSourceSnapshot<TimelineSection, TimelineItemIdentifier.UniqueID>) -> Set<TimelineItemIdentifier.UniqueID> {
        Set(snapshot.mainItemIdentifiers.filter { id in
            guard let old = lastAppliedGroupStyles[id], let new = timelineItemsDictionary[id]?.groupStyle else { return false }
            return old != new
        })
    }
}

// MARK: - Layout

extension TimelineTableViewController {
    /// The sections of the table view used in the diffable data source.
    nonisolated enum TimelineSection {
        case main
        case typingIndicator
    }
}

private extension NSDiffableDataSourceSnapshot<TimelineTableViewController.TimelineSection, TimelineItemIdentifier.UniqueID> {
    var mainItemIdentifiers: [TimelineItemIdentifier.UniqueID] {
        guard sectionIdentifiers.contains(.main) else { return [] }
        return itemIdentifiers(inSection: .main)
    }
}

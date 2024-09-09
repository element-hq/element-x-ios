//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

import OrderedCollections

/// A table view cell that displays a timeline item in a room. The cell is intended
/// to be configured to display a SwiftUI view and not use any UIKit.
class TimelineItemCell: UITableViewCell {
    static let reuseIdentifier = "TimelineItemCell"
    
    // periphery:ignore - retaining purpose
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

/// A table view controller that displays the timeline of a room.
///
/// This class subclasses `UIViewController` as `UITableViewController` adds some
/// extra keyboard handling magic that wasn't playing well with SwiftUI (as of iOS 16.1).
/// Also this TableViewController uses a **flipped tableview**
class TimelineTableViewController: UIViewController {
    private let coordinator: TimelineView.Coordinator
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    var timelineItemsDictionary = OrderedDictionary<String, RoomTimelineItemViewState>() {
        didSet {
            guard canApplySnapshot else {
                hasPendingItems = true
                return
            }
            
            applySnapshot()
            
            if timelineItemsDictionary.isEmpty {
                paginatePublisher.send()
            }
            
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
            if isLive { scrollViewDidScroll(tableView) }
        }
    }
    
    /// The state of pagination (in both directions) of the current timeline.
    var paginationState: PaginationState = .initial {
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

    private var timelineItemsIDs: [String] {
        timelineItemsDictionary.keys.elements.reversed()
    }
    
    /// The table's diffable data source.
    private var dataSource: UITableViewDiffableDataSource<TimelineSection, String>?
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
    
    init(coordinator: TimelineView.Coordinator,
         isScrolledToBottom: Binding<Bool>,
         scrollToBottomPublisher: PassthroughSubject<Void, Never>) {
        self.coordinator = coordinator
        _isScrolledToBottom = isScrolledToBottom
        
        super.init(nibName: nil, bundle: nil)
        
        tableView.register(TimelineItemCell.self, forCellReuseIdentifier: TimelineItemCell.reuseIdentifier)
        tableView.register(TimelineTypingIndicatorCell.self, forCellReuseIdentifier: TimelineTypingIndicatorCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = UIColor(.compound.bgCanvasDefault)
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        view.addSubview(tableView)
        
        // Prevents XCUITest from invoking the diffable dataSource's cellProvider
        // for each possible cell, causing layout issues
        tableView.accessibilityElementsHidden = ProcessInfo.shouldDisableTimelineAccessibility
        
        scrollToBottomPublisher
            .sink { [weak self] _ in
                self?.scrollToNewestItem(animated: true)
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
    required init?(coder: NSCoder) { fatalError("init(coder:) is not available.") }
    
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
        
        tableView.frame = CGRect(origin: .zero, size: view.frame.size)
    }
    
    /// Configures a diffable data source for the timeline's table view.
    private func configureDataSource() {
        dataSource = .init(tableView: tableView) { [weak self] tableView, indexPath, id in
            switch id {
            case TimelineTypingIndicatorCell.reuseIdentifier:
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
                
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: TimelineItemCell.reuseIdentifier, for: indexPath)
                guard let self, let cell = cell as? TimelineItemCell else { return cell }
                
                // A local reference to avoid capturing self in the cell configuration.
                let coordinator = self.coordinator
                
                let viewState = timelineItemsDictionary[id]
                cell.item = viewState
                guard let viewState else {
                    return cell
                }
                
                cell.contentConfiguration = UIHostingConfiguration {
                    RoomTimelineItemView(viewState: viewState)
                        .id(id)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .environmentObject(coordinator.context) // Attempted fix at a crash in TimelineItemContextMenu
                        .environment(\.timelineContext, coordinator.context)
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

        var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, String>()
        
        // We don't want to display the typing notification in this timeline
        if !coordinator.context.viewState.isPinnedEventsTimeline {
            snapshot.appendSections([.typingIndicator])
            snapshot.appendItems([TimelineTypingIndicatorCell.reuseIdentifier])
        }
        snapshot.appendSections([.main])
        snapshot.appendItems(timelineItemsIDs)
        
        let currentSnapshot = dataSource.snapshot()
        
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
        
        if isSwitchingTimelines {
            coordinator.send(viewAction: .hasSwitchedTimeline)
        }
    }
    
    /// Scrolls to the newest item in the timeline.
    private func scrollToNewestItem(animated: Bool) {
        guard !timelineItemsIDs.isEmpty else {
            return
        }
        tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: animated)
        scrollDirectionPublisher.send(.bottom)
    }

    /// Scrolls to the oldest item in the timeline.
    private func scrollToOldestItem(animated: Bool) {
        guard !timelineItemsIDs.isEmpty else {
            return
        }
        tableView.scrollToRow(at: IndexPath(item: timelineItemsIDs.count - 1, section: 1), at: .bottom, animated: animated)
        scrollDirectionPublisher.send(.top)
    }
    
    /// Scrolls to the item with the corresponding event ID if loaded in the timeline.
    private func scrollToItem(eventID: String, animated: Bool) {
        DispatchQueue.main.async { [weak self] in // Fixes #2805
            guard let self else { return }
            if let kvPair = timelineItemsDictionary.first(where: { $0.value.identifier.eventID == eventID }),
               let indexPath = dataSource?.indexPath(for: kvPair.key) {
                tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
                coordinator.send(viewAction: .scrolledToFocussedItem)
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
    
    private func sendLastVisibleItemReadReceipt() {
        // Find the last visible timeline item and send a read receipt for it
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else {
            return
        }
        
        // These are already in reverse order because the table view is flipped
        for indexPath in visibleIndexPaths {
            if let visibleItemTimelineID = dataSource?.itemIdentifier(for: indexPath),
               let visibleItemID = timelineItemsDictionary[visibleItemTimelineID]?.identifier {
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
            
            let isScrolledToBottom = scrollView.contentOffset.y <= 0
            
            // Only update the binding on changes to avoid needlessly recomputing the hierarchy when scrolling.
            if self.isScrolledToBottom != isScrolledToBottom {
                self.isScrolledToBottom = isScrolledToBottom
            }
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
    }
}

// MARK: - Layout

extension TimelineTableViewController {
    /// The sections of the table view used in the diffable data source.
    enum TimelineSection {
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
              let newestCellFrame = cellFrame(for: newestItemID.timelineID) else {
            return nil
        }
        return Layout(id: newestItemID, frame: newestCellFrame)
    }
    
    /// Restores the timeline's layout from an old snapshot.
    private func restoreLayout(_ layout: Layout) {
        if let indexPath = dataSource?.indexPath(for: layout.id.timelineID) {
            // Scroll the item into view.
            tableView.scrollToRow(at: indexPath, at: .top, animated: false)
            
            // Remove any unwanted offset that was added by scrollToRow.
            if let frame = cellFrame(for: layout.id.timelineID) {
                let deltaY = frame.maxY - layout.frame.maxY
                if deltaY != 0 {
                    tableView.contentOffset.y -= deltaY
                }
            }
        }
    }
    
    /// Returns the frame of the cell for a particular timeline item.
    private func cellFrame(for id: String) -> CGRect? {
        guard let timelineCell = tableView.visibleCells.first(where: { ($0 as? TimelineItemCell)?.item?.id == id }) else {
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

private extension NSDiffableDataSourceSnapshot<TimelineTableViewController.TimelineSection, String> {
    var numberOfMainItems: Int {
        guard sectionIdentifiers.contains(.main) else { return 0 }
        return numberOfItems(inSection: .main)
    }
    
    var mainItemIdentifiers: [String] {
        guard sectionIdentifiers.contains(.main) else { return [] }
        return itemIdentifiers(inSection: .main)
    }
}

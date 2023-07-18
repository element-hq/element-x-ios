//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import SwiftUI

import OrderedCollections

/// A table view cell that displays a timeline item in a room. The cell is intended
/// to be configured to display a SwiftUI view and not use any UIKit.
class TimelineItemCell: UITableViewCell {
    static let reuseIdentifier = "TimelineItemCell"
    
    var item: RoomTimelineItemViewModel?
    
    override func prepareForReuse() {
        item = nil
    }
}

/// A table view controller that displays the timeline of a room.
///
/// This class subclasses `UIViewController` as `UITableViewController` adds some
/// extra keyboard handling magic that wasn't playing well with SwiftUI (as of iOS 16.1).
class TimelineTableViewController: UIViewController {
    private let coordinator: TimelineView.Coordinator
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    var timelineStyle: TimelineStyle
    var timelineItemsDictionary = OrderedDictionary<String, RoomTimelineItemViewModel>() {
        didSet {
            guard !scrollAdapter.isScrolling.value else {
                // Delay updating until scrolling has stopped as programatic
                // changes to the scroll position kills any inertia.
                hasPendingUpdates = true
                return
            }

            applySnapshot()

            if timelineItemsDictionary.isEmpty {
                paginateBackwardsPublisher.send()
            }
        }
    }

    /// The mode of the message composer. This is used to render selected
    /// items in the timeline when replying, editing etc.
    var composerMode: RoomScreenComposerMode = .default
    
    /// Whether or not the timeline has more messages to back paginate.
    var canBackPaginate = true
    
    /// Whether or not the timeline is waiting for more messages to be added to the top.
    var isBackPaginating = false {
        didSet {
            // Paginate again if the threshold hasn't been satisfied.
            paginateBackwardsPublisher.send(())
        }
    }
        
    var contextMenuActionProvider: (@MainActor (_ itemID: TimelineItemIdentifier) -> TimelineItemMenuActions?)?
    
    @Binding private var scrollToBottomButtonVisible: Bool

    private var timelineItemsIDs: [String] {
        timelineItemsDictionary.keys.elements
    }
    
    /// The table's diffable data source.
    private var dataSource: UITableViewDiffableDataSource<TimelineSection, String>?
    private var cancellables: Set<AnyCancellable> = []
    
    /// The scroll view adapter used to detect whether scrolling is in progress.
    private let scrollAdapter = ScrollViewAdapter()
    /// A publisher used to throttle back pagination requests.
    ///
    /// Our view actions get wrapped in a `Task` so it is possible that a second call in
    /// quick succession can execute before ``isBackPaginating`` becomes `true`.
    private let paginateBackwardsPublisher = PassthroughSubject<Void, Never>()
    /// Whether or not the ``timelineItems`` value should be applied when scrolling stops.
    private var hasPendingUpdates = false
    /// We need to store the previous layout as computing it on the fly leads to problems.
    private var previousLayout: LayoutDescriptor?
    /// Whether or not the view has been shown on screen yet.
    private var hasAppearedOnce = false
    /// Whether the scroll and the animations should happen
    private var shouldAnimate = false
    
    init(coordinator: TimelineView.Coordinator,
         timelineStyle: TimelineStyle,
         scrollToBottomButtonVisible: Binding<Bool>,
         scrollToBottomPublisher: PassthroughSubject<Void, Never>) {
        self.coordinator = coordinator
        self.timelineStyle = timelineStyle
        _scrollToBottomButtonVisible = scrollToBottomButtonVisible
        
        super.init(nibName: nil, bundle: nil)
        
        tableView.register(TimelineItemCell.self, forCellReuseIdentifier: TimelineItemCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = UIColor(.compound.bgCanvasDefault)
        view.addSubview(tableView)
        
        // Prevents XCUITest from invoking the diffable dataSource's cellProvider
        // for each possible cell, causing layout issues
        tableView.accessibilityElementsHidden = Tests.shouldDisableTimelineAccessibility
        
        tableView.publisher(for: \.contentSize)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateTopPadding()
            }
            .store(in: &cancellables)
        
        scrollToBottomPublisher
            .sink { [weak self] _ in
                self?.scrollToBottom(animated: true)
            }
            .store(in: &cancellables)
        
        scrollAdapter.isScrolling
            .sink { [weak self] isScrolling in
                guard !isScrolling, let self, self.hasPendingUpdates else { return }
                // When scrolling has stopped, apply any pending updates.
                self.applySnapshot()
                self.hasPendingUpdates = false
                self.paginateBackwardsPublisher.send(())
            }
            .store(in: &cancellables)
        
        paginateBackwardsPublisher
            .collect(.byTime(DispatchQueue.main, 0.1))
            .sink { [weak self] _ in
                self?.paginateBackwardsIfNeeded()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
            .sink { [weak self] _ in
                guard let self, let layout = self.previousLayout, layout.isBottomVisible else { return }
                self.scrollToBottom(animated: false) // Force the bottom to be visible as some timelines misbehave.
            }
            .store(in: &cancellables)

        ServiceLocator.shared.settings.$timelineDiffableAnimationsEnabled
            .weakAssign(to: \.shouldAnimate, on: self)
            .store(in: &cancellables)
        
        configureDataSource()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not available.") }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard !hasAppearedOnce else { return }
        scrollToBottom(animated: false)
        hasAppearedOnce = true
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        // Ensure the padding is correct before display.
        updateTopPadding()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        guard tableView.frame.size != view.frame.size else {
            return
        }
        
        tableView.frame = CGRect(origin: .zero, size: view.frame.size)
        
        // Update the table's layout if necessary after the frame changed.
        updateTopPadding()
        
        if let previousLayout, previousLayout.isBottomVisible {
            scrollToBottom(animated: false)
        }
    }
    
    /// Configures a diffable data source for the timeline's table view.
    private func configureDataSource() {
        dataSource = .init(tableView: tableView) { [weak self] tableView, indexPath, id in
            let cell = tableView.dequeueReusableCell(withIdentifier: TimelineItemCell.reuseIdentifier, for: indexPath)
            guard let self, let cell = cell as? TimelineItemCell else { return cell }
            
            // A local reference to avoid capturing self in the cell configuration.
            let coordinator = self.coordinator

            let viewModel = timelineItemsDictionary[id]
            cell.item = viewModel
            guard let viewModel else {
                return cell
            }
            cell.contentConfiguration = UIHostingConfiguration {
                RoomTimelineItemView(viewModel: viewModel)
                    .id(id)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environmentObject(coordinator.context) // Attempted fix at a crash in TimelineItemContextMenu
                    .onAppear {
                        coordinator.send(viewAction: .itemAppeared(itemID: viewModel.id))
                    }
                    .onDisappear {
                        coordinator.send(viewAction: .itemDisappeared(itemID: viewModel.id))
                    }
                    .environment(\.openURL, OpenURLAction { url in
                        coordinator.send(viewAction: .linkClicked(url: url))
                        return .systemAction
                    })
            }
            .margins(.all, self.timelineStyle.rowInsets)
            .minSize(height: 1)
            .background(Color.clear)
            
            return cell
        }

        dataSource?.defaultRowAnimation = .fade
        tableView.delegate = self
    }
    
    /// Updates the table view with the latest items from the ``timelineItems`` array. After
    /// updating the data, the table will be scrolled to the bottom if it was visible otherwise
    /// the scroll position will be updated to maintain the position of the last visible item.
    private func applySnapshot() {
        guard let dataSource else { return }
        
        let previousLayout = layout()
        self.previousLayout = previousLayout
        
        var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, String>()
        snapshot.appendSections([.main])
        snapshot.appendItems(timelineItemsIDs)

        let currentSnapshot = dataSource.snapshot()
        MXLog.verbose("DIFF: \(snapshot.itemIdentifiers.difference(from: currentSnapshot.itemIdentifiers))")

        // We only animate if the last item has changed
        // We don't care to animate backpagination since we want to keep the scrolling position when that happens
        let animated = shouldAnimate && snapshot.itemIdentifiers.last != currentSnapshot.itemIdentifiers.last
        dataSource.apply(snapshot, animatingDifferences: animated)

        if previousLayout.isBottomVisible {
            scrollToBottom(animated: false)
        } else if let pinnedItem = previousLayout.pinnedItem {
            restoreScrollPosition(using: pinnedItem, and: snapshot)
        }
    }
    
    /// Returns a description of the current layout in order to update the
    /// scroll position after adding/updating items to the timeline.
    private func layout() -> LayoutDescriptor {
        guard let dataSource else { return LayoutDescriptor() }
        
        let snapshot = dataSource.snapshot()
        var layout = LayoutDescriptor(numberOfItems: snapshot.numberOfItems)
        
        guard !snapshot.itemIdentifiers.isEmpty else {
            layout.isBottomVisible = true
            return layout
        }
        
        guard let bottomItemIndexPath = tableView.indexPathsForVisibleRows?.last,
              let bottomID = dataSource.itemIdentifier(for: bottomItemIndexPath)
        else { return layout }
        
        let bottomCellFrame = tableView.cellFrame(for: bottomID)
        layout.pinnedItem = PinnedItem(id: bottomID, position: .bottom, frame: bottomCellFrame)
        layout.isBottomVisible = bottomID == snapshot.itemIdentifiers.last
        
        return layout
    }
    
    /// Updates the additional padding added to the top of the table (via a header)
    /// in order to fill the timeline from the bottom of the view upwards.
    private func updateTopPadding() {
        let headerHeight = tableView.tableHeaderView?.frame.height ?? 0
        let contentHeight = tableView.contentSize.height - headerHeight
        let newHeight = max(0, tableView.visibleSize.height - contentHeight)
        
        // Round the check to account floating point accuracy during keyboard appearance.
        guard newHeight.rounded() != headerHeight.rounded() else { return }
        
        if newHeight > 0 {
            let frame = CGRect(origin: .zero, size: CGSize(width: tableView.contentSize.width, height: newHeight))
            tableView.tableHeaderView = UIView(frame: frame) // Updating an existing view's height doesn't move the cells.
        } else {
            tableView.tableHeaderView = nil
        }
    }
    
    /// Whether or not the bottom of the scroll view is visible (with some small tolerance added).
    private func isAtBottom() -> Bool {
        tableView.contentOffset.y < (tableView.contentSize.height - tableView.visibleSize.height - 15)
    }
    
    /// Scrolls to the bottom of the timeline.
    private func scrollToBottom(animated: Bool) {
        guard let lastItemID = timelineItemsIDs.last,
              let lastIndexPath = dataSource?.indexPath(for: lastItemID)
        else { return }
        
        tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: animated)
    }
    
    /// Restores the position of the timeline using the supplied item and snapshot.
    private func restoreScrollPosition(using pinnedItem: PinnedItem, and snapshot: NSDiffableDataSourceSnapshot<TimelineSection, String>) {
        guard let item = snapshot.itemIdentifiers.first(where: { $0 == pinnedItem.id }),
              let indexPath = dataSource?.indexPath(for: item)
        else { return }
        
        // Scroll the item into view.
        tableView.scrollToRow(at: indexPath, at: pinnedItem.position, animated: false)
        
        guard let oldFrame = pinnedItem.frame, let newFrame = tableView.cellFrame(for: item) else { return }
        
        // Remove any unwanted offset that was added by scrollToRow.
        let deltaY = newFrame.maxY - oldFrame.maxY
        if deltaY != 0 {
            tableView.contentOffset.y += deltaY
        }
    }
    
    /// Checks whether or a backwards pagination is needed and requests one if so.
    ///
    /// Prefer not to call this directly, instead using ``paginateBackwardsPublisher`` to throttle requests.
    private func paginateBackwardsIfNeeded() {
        guard canBackPaginate,
              !isBackPaginating,
              !hasPendingUpdates,
              tableView.contentOffset.y < tableView.visibleSize.height * 2.0
        else { return }
        
        coordinator.send(viewAction: .paginateBackwards)
    }
}

// MARK: - UITableViewDelegate

extension TimelineTableViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        paginateBackwardsPublisher.send(())
        
        // Dispatch to fix runtime warning about making changes during a view update.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            let isAtBottom = self.isAtBottom()
            
            // Only update the binding on changes to avoid needlessly recomputing the hierarchy when scrolling.
            if self.scrollToBottomButtonVisible != isAtBottom {
                self.scrollToBottomButtonVisible = isAtBottom
            }
        }
    }

    // MARK: ScrollViewAdapter Methods
    
    // Required delegate methods are forwarded to the adapter so others can be implemented.
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollAdapter.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollAdapter.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollAdapter.scrollViewDidEndScrollingAnimation(scrollView)
    }
        
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollAdapter.scrollViewDidEndDecelerating(scrollView)
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollAdapter.scrollViewDidScrollToTop(scrollView)
    }
}

// MARK: - Layout Types

extension TimelineTableViewController {
    /// The sections of the table view used in the diffable data source.
    enum TimelineSection {
        case main
    }
    
    /// A description of the timeline's layout.
    struct LayoutDescriptor {
        var numberOfItems = 0
        var pinnedItem: PinnedItem?
        var isBottomVisible = false
    }
    
    /// An item that should have its position pinned after updates.
    struct PinnedItem {
        let id: String
        let position: UITableView.ScrollPosition
        let frame: CGRect?
    }
}

// MARK: - Cell Layout

private extension UITableView {
    /// Returns the frame of the cell for a particular timeline item.
    func cellFrame(for id: String) -> CGRect? {
        guard let timelineCell = visibleCells.last(where: { ($0 as? TimelineItemCell)?.item?.id.timelineID == id }) else {
            return nil
        }
        
        return convert(timelineCell.frame, to: superview)
    }
}

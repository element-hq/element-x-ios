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

/// A table view cell that displays a timeline item in a room. The cell is intended
/// to be configured to display a SwiftUI view and not use any UIKit.
class TimelineItemCell: UITableViewCell {
    static let reuseIdentifier = "TimelineItemCell"
    
    var item: RoomTimelineViewProvider?
    
    override func prepareForReuse() {
        item = nil
    }
}

/// A table view wrapper that displays the timeline of a room.
struct TimelineTableView: UIViewRepresentable {
    @EnvironmentObject private var viewModelContext: RoomScreenViewModel.Context
    @Environment(\.timelineStyle) private var timelineStyle
    
    func makeUIView(context: Context) -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(TimelineItemCell.self, forCellReuseIdentifier: TimelineItemCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .onDrag
        context.coordinator.tableView = tableView
        viewModelContext.send(viewAction: .paginateBackwards)
        return tableView
    }
    
    func updateUIView(_ uiView: UITableView, context: Context) {
        context.coordinator.update()
        
        if context.coordinator.timelineStyle != timelineStyle {
            context.coordinator.timelineStyle = timelineStyle
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModelContext: viewModelContext)
    }
    
    // MARK: - Coordinator
    
    @MainActor
    class Coordinator: NSObject {
        let viewModelContext: RoomScreenViewModel.Context
        
        var tableView: UITableView? {
            didSet {
                registerFrameObserver()
                configureDataSource()
            }
        }
        
        var timelineStyle: TimelineStyle = .bubbles
        var timelineItems: [RoomTimelineViewProvider] = [] {
            didSet {
                guard !scrollAdapter.isScrolling.value else {
                    // Delay updating until scrolling has stopped as programatic
                    // changes to the scroll position kills any inertia.
                    hasPendingUpdates = true
                    return
                }
                
                applySnapshot()
            }
        }
        
        /// The mode of the message composer. This is used to render selected
        /// items in the timeline when replying, editing etc.
        var composerMode: RoomScreenComposerMode = .default {
            didSet {
                // Reload the visible items in order to update their opacity.
                // Applying a snapshot won't work in this instance as the items don't change.
                reloadVisibleItems()
            }
        }
        
        /// Whether or not the timeline is waiting for more messages to be added to the top.
        var isBackPaginating = false {
            didSet {
                // Paginate again if the threshold hasn't been satisfied.
                paginateBackwardsIfNeeded()
            }
        }
        
        /// The table's diffable data source.
        private var dataSource: UITableViewDiffableDataSource<TimelineSection, RoomTimelineViewProvider>?
        private var cancellables: Set<AnyCancellable> = []
        
        /// The scroll view adapter used to detect whether scrolling is in progress.
        private let scrollAdapter = ScrollViewAdapter()
        /// Whether or not the ``timelineItems`` value should be applied when scrolling stops.
        private var hasPendingUpdates = false
        /// The observation token used to handle frame changes.
        private var frameObserverToken: NSKeyValueObservation?
        
        init(viewModelContext: RoomScreenViewModel.Context) {
            self.viewModelContext = viewModelContext
            super.init()
            
            viewModelContext.viewState.scrollToBottomPublisher
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
                    self.paginateBackwardsIfNeeded()
                }
                .store(in: &cancellables)
        }
        
        /// Configures a diffable data source for the timeline's table view.
        private func configureDataSource() {
            guard let tableView else { return }
            
            dataSource = .init(tableView: tableView) { [weak self] tableView, indexPath, timelineItem in
                let cell = tableView.dequeueReusableCell(withIdentifier: TimelineItemCell.reuseIdentifier, for: indexPath)
                guard let self, let cell = cell as? TimelineItemCell else { return cell }
                
                // A local reference to avoid capturing self in the cell configuration.
                let viewModelContext = self.viewModelContext
                
                cell.item = timelineItem
                cell.contentConfiguration = UIHostingConfiguration {
                    timelineItem
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(viewModelContext.viewState.opacity(for: timelineItem))
                        .contextMenu {
                            viewModelContext.viewState.contextMenuBuilder?(timelineItem.id)
                        }
                        .onAppear {
                            viewModelContext.send(viewAction: .itemAppeared(id: timelineItem.id))
                        }
                        .onDisappear {
                            viewModelContext.send(viewAction: .itemDisappeared(id: timelineItem.id))
                        }
                        .environment(\.openURL, OpenURLAction { url in
                            viewModelContext.send(viewAction: .linkClicked(url: url))
                            return .systemAction
                        })
                        .onTapGesture {
                            viewModelContext.send(viewAction: .itemTapped(id: timelineItem.id))
                        }
                }
                .margins(.all, self.timelineStyle.rowInsets)
                .minSize(height: 1)
                
                return cell
            }
            
            tableView.delegate = self
        }
        
        /// Adds an observer on the frame of the table view in order to keep the
        /// last item visible when the keyboard is shown or the window resizes.
        private func registerFrameObserver() {
            // Remove the existing observer if necessary
            frameObserverToken?.invalidate()
            
            frameObserverToken = tableView?.observe(\.frame, options: .new) { [weak self] _, _ in
                self?.handleFrameChange()
            }
        }
        
        /// Updates the table's layout if necessary after the frame changed.
        private nonisolated func handleFrameChange() {
            Task { @MainActor in
                guard self.composerMode == .default else { return }
                
                // The table view is yet to update its layout so layout() returns a
                // description of the timeline before the frame change occurs.
                let previousLayout = self.layout()
                if previousLayout.isBottomVisible {
                    self.scrollToBottom(animated: false)
                }
            }
        }
        
        /// Updates the table view's internal state from the view model's context.
        func update() {
            if timelineItems != viewModelContext.viewState.items {
                timelineItems = viewModelContext.viewState.items
            }
            if isBackPaginating != viewModelContext.viewState.isBackPaginating {
                isBackPaginating = viewModelContext.viewState.isBackPaginating
            }
            if composerMode != viewModelContext.viewState.composerMode {
                composerMode = viewModelContext.viewState.composerMode
            }
        }
        
        /// Updates the table view with the latest items from the ``timelineItems`` array. After
        /// updating the data, the table will be scrolled to the bottom if it was visible otherwise
        /// the scroll position will be updated to maintain the position of the last visible item.
        private func applySnapshot() {
            guard let dataSource else { return }
            
            let previousLayout = layout()
            
            var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, RoomTimelineViewProvider>()
            snapshot.appendSections([.main])
            snapshot.appendItems(timelineItems)
            dataSource.apply(snapshot, animatingDifferences: false)
            
            updateTopPadding()
            
            guard snapshot.numberOfItems != previousLayout.numberOfItems else { return }
            
            if previousLayout.isBottomVisible {
                scrollToBottom(animated: false)
            } else if let pinnedItem = previousLayout.pinnedItem {
                restoreScrollPosition(using: pinnedItem, and: snapshot)
            }
        }
        
        /// Reloads all of the visible timeline items.
        ///
        /// This only needs to be called when some state internal to this table view changes that
        /// will affect the appearance of those items. Any updates to the items themselves should
        /// use ``applySnapshot()`` which handles everything in the diffable data source.
        private func reloadVisibleItems() {
            guard let tableView, let visibleIndexPaths = tableView.indexPathsForVisibleRows, let dataSource else { return }
            var snapshot = dataSource.snapshot()
            snapshot.reloadItems(visibleIndexPaths.compactMap { dataSource.itemIdentifier(for: $0) })
            dataSource.apply(snapshot)
        }
        
        /// Returns a description of the current layout in order to update the
        /// scroll position after adding/updating items to the timeline.
        private func layout() -> LayoutDescriptor {
            guard let tableView, let dataSource else { return LayoutDescriptor() }
            
            let snapshot = dataSource.snapshot()
            var layout = LayoutDescriptor(numberOfItems: snapshot.numberOfItems)
            
            guard !snapshot.itemIdentifiers.isEmpty else {
                layout.isBottomVisible = true
                return layout
            }
            
            guard let bottomItemIndexPath = tableView.indexPathsForVisibleRows?.last,
                  let bottomItem = dataSource.itemIdentifier(for: bottomItemIndexPath)
            else { return layout }
            
            let bottomCellFrame = tableView.cellFrame(for: bottomItem)
            layout.pinnedItem = PinnedItem(id: bottomItem.id, position: .bottom, frame: bottomCellFrame)
            layout.isBottomVisible = bottomItem == snapshot.itemIdentifiers.last
            
            return layout
        }
        
        /// Updates the additional padding added to the top of the table (via a header)
        /// in order to fill the timeline from the bottom of the view upwards.
        private func updateTopPadding() {
            guard let tableView else { return }
            
            let contentHeight = tableView.contentSize.height - (tableView.tableHeaderView?.frame.height ?? 0)
            let height = tableView.visibleSize.height - contentHeight
            
            if height > 0 {
                let frame = CGRect(origin: .zero, size: CGSize(width: tableView.contentSize.width, height: height))
                tableView.tableHeaderView = UIView(frame: frame) // Updating an existing view's height doesn't move the cells.
            } else {
                tableView.tableHeaderView = nil
            }
        }
        
        /// Whether or not the bottom of the scroll view is visible (with some small tolerance added).
        private func isAtBottom(of scrollView: UIScrollView) -> Bool {
            scrollView.contentOffset.y < (scrollView.contentSize.height - scrollView.visibleSize.height - 15)
        }
        
        /// Scrolls to the bottom of the timeline.
        private func scrollToBottom(animated: Bool) {
            guard let lastItem = timelineItems.last,
                  let lastIndexPath = dataSource?.indexPath(for: lastItem)
            else { return }
            
            tableView?.scrollToRow(at: lastIndexPath, at: .bottom, animated: animated)
        }
        
        /// Restores the position of the timeline using the supplied item and snapshot.
        private func restoreScrollPosition(using pinnedItem: PinnedItem, and snapshot: NSDiffableDataSourceSnapshot<TimelineSection, RoomTimelineViewProvider>) {
            guard let tableView,
                  let item = snapshot.itemIdentifiers.first(where: { $0.id == pinnedItem.id }),
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
        private func paginateBackwardsIfNeeded() {
            guard let tableView,
                  !isBackPaginating,
                  !hasPendingUpdates,
                  tableView.contentOffset.y < tableView.visibleSize.height * 2.0
            else { return }
            
            viewModelContext.send(viewAction: .paginateBackwards)
        }
    }
}

// MARK: - UITableViewDelegate

extension TimelineTableView.Coordinator: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let isAtBottom = isAtBottom(of: scrollView)
        
        if !viewModelContext.scrollToBottomButtonVisible, isAtBottom {
            DispatchQueue.main.async { self.viewModelContext.scrollToBottomButtonVisible = true }
        } else if viewModelContext.scrollToBottomButtonVisible, !isAtBottom {
            DispatchQueue.main.async { self.viewModelContext.scrollToBottomButtonVisible = false }
        }
        
        paginateBackwardsIfNeeded()
    }

    // MARK: - ScrollViewAdapter
    
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

extension TimelineTableView.Coordinator {
    /// The sections of the table view used in the diffable data source.
    enum TimelineSection { case main }
    
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
    func cellFrame(for item: RoomTimelineViewProvider) -> CGRect? {
        guard let timelineCell = visibleCells.last(where: { ($0 as? TimelineItemCell)?.item == item }) else {
            return nil
        }
        
        return convert(timelineCell.frame, to: superview)
    }
}

// MARK: - Previews

struct TimelineTableView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            mediaProvider: MockMediaProvider(),
                                            roomName: "Preview room")
        
        NavigationView {
            RoomScreen(context: viewModel.context)
        }
    }
}

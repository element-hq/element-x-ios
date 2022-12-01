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

class TimelineItemCell: UITableViewCell {
    static let reuseIdentifier = "TimelineCell"
    
    var item: RoomTimelineViewProvider?
    
    override func prepareForReuse() {
        item = nil
    }
}

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
        context.coordinator.paginateBackwardsPublisher.send(())
        return tableView
    }
    
    func updateUIView(_ uiView: UITableView, context: Context) {
        if context.coordinator.timelineItems != viewModelContext.viewState.items {
            context.coordinator.timelineItems = viewModelContext.viewState.items
        }
        if context.coordinator.isBackPaginating != viewModelContext.viewState.isBackPaginating {
            context.coordinator.isBackPaginating = viewModelContext.viewState.isBackPaginating
        }
        if context.coordinator.timelineStyle != timelineStyle {
            context.coordinator.timelineStyle = timelineStyle
        }
        if case let .reply(selectedItemID, _) = viewModelContext.viewState.composerMode {
            if context.coordinator.selectedItemID != selectedItemID {
                context.coordinator.selectedItemID = selectedItemID
            }
        } else if context.coordinator.selectedItemID != nil {
            context.coordinator.selectedItemID = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModelContext: viewModelContext,
                    scrollToBottomButtonVisible: $viewModelContext.scrollToBottomButtonVisible)
    }
    
    // MARK: - Coordinator
    
    @MainActor
    class Coordinator: NSObject {
        var tableView: UITableView? {
            didSet {
                registerFrameObserver()
                configureDataSource()
            }
        }
        
        var timelineStyle: TimelineStyle = .bubbles
        var timelineItems: [RoomTimelineViewProvider] = [] {
            didSet {
                guard !adapter.isScrolling.value else {
                    hasPendingUpdates = true
                    return
                }
                
                applySnapshot()
            }
        }
        
        var selectedItemID: String? {
            didSet {
                // Reload the visible items in order to update their opacity.
                // Applying a snapshot won't work in this instance as the items don't change.
                guard let tableView, let visibleIndexPaths = tableView.indexPathsForVisibleRows, let dataSource else { return }
                var snapshot = dataSource.snapshot()
                snapshot.reloadItems(visibleIndexPaths.compactMap { dataSource.itemIdentifier(for: $0) })
                dataSource.apply(snapshot)
            }
        }
        
        var isBackPaginating = false {
            didSet {
                paginateBackwardsIfNeeded()
            }
        }
        
        private let contextMenuBuilder: (@MainActor (_ itemId: String) -> TimelineItemContextMenu)?
        private let viewActionPublisher: PassthroughSubject<RoomScreenViewAction, Never>
        let paginateBackwardsPublisher: PassthroughSubject<Void, Never>
        @Binding var scrollToBottomButtonVisible: Bool
        
        private var dataSource: UITableViewDiffableDataSource<TimelineSection, RoomTimelineViewProvider>?
        private var cancellables: Set<AnyCancellable> = []
        private let adapter = ScrollViewAdapter()
        private var hasPendingUpdates = false
        private var frameObserverToken: NSKeyValueObservation?
        
        init(viewModelContext: RoomScreenViewModel.Context,
             scrollToBottomButtonVisible: Binding<Bool>) {
            contextMenuBuilder = viewModelContext.viewState.contextMenuBuilder
            viewActionPublisher = viewModelContext.viewState.viewActionPublisher
            paginateBackwardsPublisher = viewModelContext.viewState.paginateBackwardsPublisher
            _scrollToBottomButtonVisible = scrollToBottomButtonVisible
            
            super.init()
            
            viewModelContext.viewState.scrollToBottomPublisher
                .sink { [weak self] _ in
                    self?.scrollToBottom(animated: true)
                }
                .store(in: &cancellables)
            
            adapter.isScrolling
                .sink { [weak self] isScrolling in
                    guard !isScrolling, let self, self.hasPendingUpdates else { return }
                    self.applySnapshot()
                    self.hasPendingUpdates = false
                    self.paginateBackwardsIfNeeded()
                }
                .store(in: &cancellables)
        }
        
        /// Configures a diffable data source for the timeline's table view.
        private func configureDataSource() {
            guard let tableView else { return }
            
            dataSource = .init(tableView: tableView) { tableView, indexPath, timelineItem in
                let cell = tableView.dequeueReusableCell(withIdentifier: TimelineItemCell.reuseIdentifier, for: indexPath)
                guard let cell = cell as? TimelineItemCell else { return cell }
                
                cell.item = timelineItem
                #warning("Do we need a weak self here???")
                cell.contentConfiguration = UIHostingConfiguration {
                    timelineItem
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contextMenu {
                            self.contextMenuBuilder?(timelineItem.id)
                        }
                        .opacity(self.opacityForItem(timelineItem))
                        .onAppear {
                            self.viewActionPublisher.send(.itemAppeared(id: timelineItem.id))
                        }
                        .onDisappear {
                            self.viewActionPublisher.send(.itemDisappeared(id: timelineItem.id))
                        }
                        .environment(\.openURL, OpenURLAction { url in
                            self.viewActionPublisher.send(.linkClicked(url: url))
                            return .systemAction
                        })
                        .onTapGesture {
                            self.viewActionPublisher.send(.itemTapped(id: timelineItem.id))
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
                guard let self, self.selectedItemID == nil else { return }
                let previousLayout = self.layout()
                
                if previousLayout.isBottomVisible {
                    self.scrollToBottom(animated: false)
                }
            }
        }
        
        /// Updates the table view with the latest items from the `timelineItems` array. After
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
            
            if let pinnedIndexPath = tableView.indexPathsForVisibleRows?.last,
               let pinnedItem = dataSource.itemIdentifier(for: pinnedIndexPath) {
                let pinnedCellFrame = tableView.cellFrame(for: pinnedItem)
                layout.pinnedItem = PinnedItem(id: pinnedItem.id, position: .bottom, frame: pinnedCellFrame)
                layout.isBottomVisible = pinnedItem == snapshot.itemIdentifiers.last
            }
            
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
            
            paginateBackwardsPublisher.send(())
        }
        
        /// 
        private func opacityForItem(_ item: RoomTimelineViewProvider) -> Double {
            guard let selectedItemID else { return 1.0 }
            return item.id == selectedItemID ? 1.0 : 0.5
        }
    }
}

// MARK: - UITableViewDelegate

extension TimelineTableView.Coordinator: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let isAtBottom = isAtBottom(of: scrollView)
        
        if !scrollToBottomButtonVisible, isAtBottom {
            DispatchQueue.main.async { self.scrollToBottomButtonVisible = true }
        } else if scrollToBottomButtonVisible, !isAtBottom {
            DispatchQueue.main.async { self.scrollToBottomButtonVisible = false }
        }
        
        paginateBackwardsIfNeeded()
    }

    // MARK: - ScrollViewAdapter
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        adapter.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        adapter.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        adapter.scrollViewDidEndScrollingAnimation(scrollView)
    }
        
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        adapter.scrollViewDidEndDecelerating(scrollView)
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        adapter.scrollViewDidScrollToTop(scrollView)
    }
}

// MARK: - Layout Types

extension TimelineTableView.Coordinator {
    enum TimelineSection { case main }
    
    struct LayoutDescriptor {
        var numberOfItems = 0
        var pinnedItem: PinnedItem?
        var isBottomVisible = false
    }
    
    struct PinnedItem {
        let id: String
        let position: UITableView.ScrollPosition
        let frame: CGRect?
    }
}

// MARK: - Cell Layout

private extension UITableView {
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
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            mediaProvider: MockMediaProvider(),
                                            roomName: "Preview room")
        
        NavigationView {
            RoomScreen(context: viewModel.context)
        }
    }
}

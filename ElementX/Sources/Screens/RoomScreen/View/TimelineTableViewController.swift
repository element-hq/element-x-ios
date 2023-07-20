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
        timelineItemsDictionary.keys.elements.reversed()
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
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        view.addSubview(tableView)
        
        // Prevents XCUITest from invoking the diffable dataSource's cellProvider
        // for each possible cell, causing layout issues
        tableView.accessibilityElementsHidden = Tests.shouldDisableTimelineAccessibility
        
        scrollToBottomPublisher
            .sink { [weak self] _ in
                self?.scrollToTop(animated: true)
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
        scrollToTop(animated: false)
        hasAppearedOnce = true
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

            cell.transform = CGAffineTransform(scaleX: 1, y: -1)
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

        var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, String>()
        snapshot.appendSections([.main])
        snapshot.appendItems(timelineItemsIDs)

        let currentSnapshot = dataSource.snapshot()
        MXLog.verbose("DIFF: \(snapshot.itemIdentifiers.difference(from: currentSnapshot.itemIdentifiers))")

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }
    
    /// Scrolls to the bottom of the timeline.
    private func scrollToTop(animated: Bool) {
        tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: animated)
    }
    
    /// Checks whether or a backwards pagination is needed and requests one if so.
    ///
    /// Prefer not to call this directly, instead using ``paginateBackwardsPublisher`` to throttle requests.
    private func paginateBackwardsIfNeeded() {
        guard canBackPaginate,
              !isBackPaginating,
              !hasPendingUpdates,
              // TODO: this probably needs to change
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
            
            let scrollToBottomButtonVisible = tableView.contentOffset.y > 15
            
            // Only update the binding on changes to avoid needlessly recomputing the hierarchy when scrolling.
            if self.scrollToBottomButtonVisible != scrollToBottomButtonVisible {
                self.scrollToBottomButtonVisible = scrollToBottomButtonVisible
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
}

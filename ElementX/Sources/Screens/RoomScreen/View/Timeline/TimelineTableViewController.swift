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
    private let coordinator: UITimelineView.Coordinator
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    var timelineStyle: TimelineStyle
    var timelineItemsDictionary = OrderedDictionary<String, RoomTimelineItemViewState>() {
        didSet {
            applySnapshot()

            if timelineItemsDictionary.isEmpty {
                paginateBackwardsPublisher.send()
            }
            
            sendLastVisibleItemReadReceipt()
        }
    }
    
    /// Whether or not the timeline has more messages to back paginate.
    var canBackPaginate = true
    
    /// Whether or not the timeline is waiting for more messages to be added to the top.
    var isBackPaginating = false {
        didSet {
            // Paginate again if the threshold hasn't been satisfied.
            paginateBackwardsPublisher.send(())
        }
    }
    
    /// Used to hold an observable object that the typing indicator can use
    let typingMembers = TypingMembersObservableObject(members: [])
    
    /// Updates the typing members but also updates table view items
    func setTypingMembers(_ members: [String]) {
        DispatchQueue.main.async {
            // Avoid `Publishing changes from within view update warnings`
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
    /// quick succession can execute before ``isBackPaginating`` becomes `true`.
    private let paginateBackwardsPublisher = PassthroughSubject<Void, Never>()
    /// Whether or not the view has been shown on screen yet.
    private var hasAppearedOnce = false
    
    init(coordinator: UITimelineView.Coordinator,
         timelineStyle: TimelineStyle,
         isScrolledToBottom: Binding<Bool>,
         scrollToBottomPublisher: PassthroughSubject<Void, Never>) {
        self.coordinator = coordinator
        self.timelineStyle = timelineStyle
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
                self?.scrollToBottom(animated: true)
            }
            .store(in: &cancellables)
        
        paginateBackwardsPublisher
            .collect(.byTime(DispatchQueue.main, 0.1))
            .sink { [weak self] _ in
                self?.paginateBackwardsIfNeeded()
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
        paginateBackwardsPublisher.send()
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
                        .environment(\.roomContext, coordinator.context)
                }
                .margins(.all, self.timelineStyle.rowInsets)
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
        snapshot.appendSections([.typingIndicator])
        snapshot.appendItems([TimelineTypingIndicatorCell.reuseIdentifier])
        snapshot.appendSections([.main])
        snapshot.appendItems(timelineItemsIDs)
        
        let currentSnapshot = dataSource.snapshot()
        MXLog.verbose("DIFF: \(snapshot.itemIdentifiers.difference(from: currentSnapshot.itemIdentifiers))")
        
        // We only animate when new items come at the end of the timeline, ignoring transitions through empty.
        let animated = currentSnapshot.sectionIdentifiers.contains(.main) &&
            snapshot.sectionIdentifiers.contains(.main) &&
            currentSnapshot.numberOfItems(inSection: .main) > 0 &&
            snapshot.numberOfItems(inSection: .main) > 0 &&
            snapshot.itemIdentifiers(inSection: .main).first != currentSnapshot.itemIdentifiers(inSection: .main).first
        
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    /// Scrolls to the bottom of the timeline.
    private func scrollToBottom(animated: Bool) {
        guard !timelineItemsIDs.isEmpty else {
            return
        }
        tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: animated)
    }

    /// Scrolls to the top of the timeline.
    private func scrollToTop(animated: Bool) {
        guard !timelineItemsIDs.isEmpty else {
            return
        }
        tableView.scrollToRow(at: IndexPath(item: timelineItemsIDs.count - 1, section: 0), at: .bottom, animated: animated)
    }
    
    /// Checks whether or a backwards pagination is needed and requests one if so.
    ///
    /// Prefer not to call this directly, instead using ``paginateBackwardsPublisher`` to throttle requests.
    private func paginateBackwardsIfNeeded() {
        guard canBackPaginate,
              !isBackPaginating,
              tableView.contentOffset.y > tableView.contentSize.height - tableView.visibleSize.height * 2.0
        else { return }
        
        coordinator.send(viewAction: .paginateBackwards)
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
        paginateBackwardsPublisher.send(())
        
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
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollToTop(animated: true)
        return false
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        sendLastVisibleItemReadReceipt()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        sendLastVisibleItemReadReceipt()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        sendLastVisibleItemReadReceipt()
    }
}

// MARK: - Layout Types

extension TimelineTableViewController {
    /// The sections of the table view used in the diffable data source.
    enum TimelineSection {
        case main
        case typingIndicator
    }
}

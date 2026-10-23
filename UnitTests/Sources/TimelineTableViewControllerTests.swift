//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import OrderedCollections
import SwiftUI
import Testing

/// Drives a real timeline table as the view model does, while new messages land at the bottom.
final class TimelineTableViewControllerTests {
    private let window: UIWindow
    /// Owns the context that the cells use.
    private let viewModel: TimelineViewModel
    private let controller: TimelineTableViewController
    private let tableView: UITableView
    private var viewStates = OrderedDictionary<TimelineItemIdentifier.UniqueID, RoomTimelineItemViewState>()
    
    init() throws {
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        viewModel = TimelineViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "")),
                                      timelineController: TimelineControllerMock(.init(timelineItems: [])),
                                      userSession: UserSessionMock(.init()),
                                      mediaPlayerProvider: MediaPlayerProviderMock(),
                                      userIndicatorController: UserIndicatorControllerMock(),
                                      appMediator: AppMediatorMock(.init()),
                                      analyticsService: AnalyticsServiceMock(.init()),
                                      emojiProvider: EmojiProvider(userSettings: .mock()),
                                      linkMetadataProvider: LinkMetadataProvider(),
                                      timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        controller = TimelineTableViewController(coordinator: .init(viewModelContext: viewModel.context),
                                                 isScrolledToBottom: .constant(true),
                                                 isReadMarkerVisible: .constant(false),
                                                 hasNewMessagesAtBottom: .constant(false),
                                                 floatingDate: .constant(nil),
                                                 scrollToBottomPublisher: .init(),
                                                 scrollToFirstItemForDatePublisher: .init(),
                                                 scrollToReadMarkerPublisher: .init())
        window.rootViewController = controller
        window.isHidden = false
        tableView = try #require(controller.view.subviews.lazy.compactMap { $0 as? UITableView }.first)
        
        show((0..<20).map { _ in Self.message(id: .randomEvent) })
        tableView.contentOffset.y = -1 // Where the timeline rests at the bottom.
        window.layoutIfNeeded()
    }
    
    isolated deinit {
        window.rootViewController = nil
        window.isHidden = true
    }
    
    /// The previous newest message loses its "Sent" as the next one lands. Its row has to shrink in the insert's batch,
    /// or the history drops once the insert has started.
    @Test
    func thePreviousNewestMessageLosesItsReceiptInTheInsertsBatch() async throws {
        let sentID = TimelineItemIdentifier.randomEvent
        show([Self.message(id: sentID, isOutgoing: true)])
        try await settle()
        let heightWithReceipt = try rowHeight(of: sentID.uniqueID)
        
        show([Self.message(id: .randomEvent)])
        let heightAfterTheBatch = try rowHeight(of: sentID.uniqueID)
        let sentCell = try #require(tableView.visibleCells.lazy.compactMap { $0 as? TimelineItemCell }.first { $0.item?.id == sentID.uniqueID })
        #expect(sentCell.isShowingPendingContentChange, "The row should be top-aligned while it shrinks.")
        try await settle(for: .milliseconds(500)) // Longer than the insert's animation.
        
        let height = try rowHeight(of: sentID.uniqueID)
        try #require(height < heightWithReceipt - 5, "The previous newest message should have lost its receipt.")
        #expect(abs(heightAfterTheBatch - height) < 0.5, "The row should have shrunk in the insert's batch.")
        #expect(!sentCell.isShowingPendingContentChange, "The row should be centred again once the insert is over.")
    }
    
    // MARK: - Helpers
    
    private static func message(id: TimelineItemIdentifier, isOutgoing: Bool = false) -> TextRoomTimelineItem {
        TextRoomTimelineItem(id: id,
                             timestamp: .mock,
                             isOutgoing: isOutgoing,
                             isEditable: false,
                             canBeRepliedTo: true,
                             sender: .init(id: isOutgoing ? "@me:server.com" : "@alice:server.com"),
                             content: .init(body: "Hello"))
    }
    
    /// Shows the items after the ones already shown, as the view model's next update does: the views that read the
    /// view model's items, such as a message's "Sent", see the change before the table applies it.
    private func show(_ items: [RoomTimelineItemProtocol]) {
        for item in items {
            viewStates[item.id.uniqueID] = RoomTimelineItemViewState(item: item, groupStyle: .single)
        }
        viewModel.state.timelineState.itemsDictionary = viewStates
        controller.timelineItemsDictionary = viewStates
    }
    
    /// The row's height in the table, which is up to date right after an apply, unlike its cell's frame.
    private func rowHeight(of id: TimelineItemIdentifier.UniqueID) throws -> CGFloat {
        let index = try #require(viewStates.index(forKey: id))
        // The newest message is the first row of the main section, which comes after the typing indicator's.
        return tableView.rectForRow(at: IndexPath(row: viewStates.count - 1 - index, section: 1)).height
    }
    
    /// Lets the rows finish any resize that UIKit or SwiftUI leaves for a later pass.
    private func settle(for duration: Duration = .milliseconds(100)) async throws {
        try await Task.sleep(for: duration)
        window.layoutIfNeeded()
    }
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import OrderedCollections
import SwiftUI
import Testing

/// Drives a real timeline table as the composer and the view model do: through a send from the bottom, and through
/// pages of messages landing at either end.
final class TimelineTableViewControllerTests {
    private static let echoID = TimelineItemIdentifier.event(uniqueID: .init("echo"), eventOrTransactionID: .transactionID("transaction"))
    private static let secondEchoID = TimelineItemIdentifier.event(uniqueID: .init("secondEcho"), eventOrTransactionID: .transactionID("secondTransaction"))
    private static let backwardSpinner = PaginationIndicatorRoomTimelineItem(position: .start)
    private static let forwardSpinner = PaginationIndicatorRoomTimelineItem(position: .end)
    
    private let window: UIWindow
    /// Owns the context that the cells and the table's view actions use.
    private let viewModel: TimelineViewModel
    private let controller: TimelineTableViewController
    private let tableView: UITableView
    private let sendProgress: PassthroughSubject<TimelineSendProgress, Never>
    private let scrollToBottom: PassthroughSubject<Void, Never>
    private let scrollToReadMarker: PassthroughSubject<TimelineItemIdentifier.UniqueID, Never>
    private let scrolledToBottom: ValueRecorder<Bool>
    private var viewStates = OrderedDictionary<TimelineItemIdentifier.UniqueID, RoomTimelineItemViewState>()
    
    init() throws {
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        let sendProgress = PassthroughSubject<TimelineSendProgress, Never>()
        let scrollToBottom = PassthroughSubject<Void, Never>()
        let scrollToReadMarker = PassthroughSubject<TimelineItemIdentifier.UniqueID, Never>()
        let scrolledToBottom = ValueRecorder(true)
        self.sendProgress = sendProgress
        self.scrollToBottom = scrollToBottom
        self.scrollToReadMarker = scrollToReadMarker
        self.scrolledToBottom = scrolledToBottom
        
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
                                                 isScrolledToBottom: scrolledToBottom.binding,
                                                 isReadMarkerVisible: .constant(false),
                                                 hasNewMessagesAtBottom: .constant(false),
                                                 floatingDate: .constant(nil),
                                                 scrollToBottomPublisher: scrollToBottom,
                                                 scrollToFirstItemForDatePublisher: .init(),
                                                 scrollToReadMarkerPublisher: scrollToReadMarker,
                                                 sendProgressPublisher: sendProgress)
        
        // The composer sits below the timeline, so the timeline's bottom edge moves as the composer resizes.
        let container = UIViewController()
        window.rootViewController = container
        window.isHidden = false
        container.addChild(controller)
        container.view.addSubview(controller.view)
        controller.view.frame = CGRect(x: 0, y: 100, width: 390, height: 600)
        controller.didMove(toParent: container)
        tableView = try #require(controller.view.subviews.lazy.compactMap { $0 as? UITableView }.first)
        
        show(adding: (0..<20).map { _ in Self.message(id: .randomEvent) })
    }
    
    isolated deinit {
        window.rootViewController = nil
        window.isHidden = true
    }
    
    @Test
    func theNewestMessageStaysStillUntilTheEchoLandsThenTheTimelineSettlesAtTheBottom() async throws {
        let newestID = try #require(viewStates.keys.last)
        let newestTop = try visualTop(of: newestID)
        
        sendProgress.send(.sending)
        sendProgress.send(.clearingComposer)
        growView(by: 40)
        #expect(try abs(visualTop(of: newestID) - newestTop) < 0.5, "The rows shouldn't follow the collapsing composer down.")
        
        show(adding: [Self.message(id: Self.echoID, isOutgoing: true)])
        #expect(try abs(visualTop(of: newestID) - newestTop) < 0.5, "The echo should land in the space the composer gave back.")
        
        #expect(await settlesAtTheBottom(withInsets: .zero))
        #expect(!scrolledToBottom.values.contains(false), "The jump to the bottom button should never show.")
    }
    
    @Test
    func anOwnMessageSentFromAnotherDeviceIsNotTheEcho() async throws {
        let newestID = try #require(viewStates.keys.last)
        let newestTop = try visualTop(of: newestID)
        
        sendProgress.send(.sending)
        sendProgress.send(.clearingComposer)
        show(adding: [Self.message(id: .randomEvent, isOutgoing: true)])
        try await Task.sleep(for: .milliseconds(200))
        #expect(try abs(visualTop(of: newestID) - newestTop) < 0.5, "The timeline should still wait for this device's echo.")
        
        show(adding: [Self.message(id: Self.echoID, isOutgoing: true)])
        #expect(await settlesAtTheBottom(withInsets: .zero))
    }
    
    @Test
    func theEchoFadesInWhileHeld() throws {
        let newestID = try #require(viewStates.keys.last)
        let newestTop = try visualTop(of: newestID)
        
        sendProgress.send(.sending)
        show(adding: [Self.message(id: Self.echoID, isOutgoing: true)])
        #expect(try abs(visualTop(of: newestID) - newestTop) < 0.5, "The echo should land while the timeline is held.")
        
        let echoCell = try cell(for: Self.echoID.uniqueID)
        let fades = echoCell.contentView.layer.animationKeys()?.contains("opacity") ?? false
        #expect(fades == !UIAccessibility.isReduceMotionEnabled)
    }
    
    @Test
    func theHoldRemovesOnlyTheInsetsItAdded() async {
        let otherInsets = UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
        tableView.contentInset = otherInsets
        
        sendProgress.send(.sending)
        sendProgress.send(.clearingComposer)
        growView(by: 40)
        #expect(tableView.contentInset.top > otherInsets.top, "The hold should make room for the space the composer gave back.")
        show(adding: [Self.message(id: Self.echoID, isOutgoing: true)])
        
        #expect(await settlesAtTheBottom(withInsets: otherInsets))
    }
    
    @Test
    func aWidthChangeEndsTheHoldAtTheBottomStraightAway() {
        sendProgress.send(.sending)
        growView(by: 40)
        #expect(tableView.contentOffset.y < -1.5, "The space the composer gave back should be on screen.")
        
        controller.view.frame.size.width = 320
        window.layoutIfNeeded()
        
        #expect(tableView.contentOffset.y > -1.5 && tableView.contentOffset.y <= 0)
        #expect(tableView.contentInset == .zero)
    }
    
    @Test
    func aScrollToTheBottomDuringTheHoldIsLeftToTheHold() async throws {
        let newestID = try #require(viewStates.keys.last)
        let newestTop = try visualTop(of: newestID)
        
        sendProgress.send(.sending)
        growView(by: 40)
        scrollToBottom.send(())
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(try abs(visualTop(of: newestID) - newestTop) < 0.5)
    }
    
    @Test
    func anyOtherScrollDuringTheHoldEndsItAndGoesAhead() async {
        let olderID = viewStates.keys[4]
        #expect(visibleCell(for: olderID) == nil, "The row should start off screen.")
        
        sendProgress.send(.sending)
        growView(by: 40)
        #expect(tableView.contentOffset.y < -1.5, "The space the composer gave back should be on screen.")
        scrollToReadMarker.send(olderID)
        
        #expect(await eventually { visibleCell(for: olderID) != nil }, "The scroll should go ahead.")
        #expect(tableView.contentInset == .zero, "The hold should have ended.")
    }
    
    /// A new room or DM: the rows don't fill the table, so the range of offsets ends where it starts.
    @Test
    func aSendInATimelineThatDoesntFillTheScreenSlidesToTheBottom() async throws {
        showOnlyMessages(3)
        let newestID = try #require(viewStates.keys.last)
        let newestTop = try visualTop(of: newestID)
        
        // A single-line send: the composer keeps its height.
        sendProgress.send(.sending)
        sendProgress.send(.clearingComposer)
        Self.insert([Self.message(id: Self.echoID, isOutgoing: true)], at: viewStates.count, in: &viewStates)
        controller.timelineItemsDictionary = viewStates
        #expect(tableView.contentOffset.y <= oldestEndOffset + 0.5, "Out of range, the next inset write would snap the rows.")
        window.layoutIfNeeded()
        #expect(try abs(visualTop(of: newestID) - newestTop) < 0.5, "The echo should land under the held rows.")
        let travel = tableView.contentOffset.y + 1
        
        let offsets = try #require(await offsetsUntilSettledAtTheBottom())
        #expect(largestStep(in: offsets) < travel / 2, "The timeline should slide to the bottom, not jump there.")
    }
    
    @Test
    func aDragEndingWithTheRowsPastTheOldestEndOfAShortTimelineSlidesThemBack() async throws {
        showOnlyMessages(3)
        sendProgress.send(.sending)
        sendProgress.send(.clearingComposer)
        show(adding: [Self.message(id: Self.echoID, isOutgoing: true)])
        try #require(tableView.contentOffset.y > 0.5, "The held rows should sit past their resting place.")
        let echoTop = try visualTop(of: Self.echoID.uniqueID)
        let travel = tableView.contentOffset.y + 1
        
        controller.scrollViewWillBeginDragging(tableView)
        controller.scrollViewDidEndDragging(tableView, willDecelerate: false)
        window.layoutIfNeeded()
        
        #expect(try abs(visualTop(of: Self.echoID.uniqueID) - echoTop) < 0.5, "Ending the drag shouldn't snap the rows.")
        let offsets = try #require(await offsetsUntilSettledAtTheBottom())
        #expect(largestStep(in: offsets) < travel / 2)
    }
    
    /// A reply header or the keyboard: the composer grows into the space it gave back first, so the rows stay put until
    /// that's used up, and then move up with the composer.
    @Test(arguments: [30.0, 60.0])
    func aGrowingComposerUsesTheSpaceUnderTheNewestMessageFirst(growth: CGFloat) throws {
        let newestID = try #require(viewStates.keys.last)
        let newestTop = try visualTop(of: newestID)
        sendProgress.send(.sending)
        growView(by: 40)
        
        growView(by: -growth)
        
        #expect(try abs(visualTop(of: newestID) - (newestTop - max(0, growth - 40))) < 0.5)
    }
    
    @Test
    func whenTheHeldMessageGoesTheNextNewestOneIsHeld() throws {
        let newestID = try #require(viewStates.keys.last)
        let nextID = viewStates.keys[viewStates.count - 2]
        let nextTop = try visualTop(of: nextID)
        sendProgress.send(.sending)
        growView(by: 40)
        
        update { $0.removeValue(forKey: newestID) }
        
        #expect(try abs(visualTop(of: nextID) - nextTop) < 0.5)
    }
    
    @Test
    func whenNoHeldMessageIsLeftTheHoldEndsAtTheBottom() {
        sendProgress.send(.sending)
        growView(by: 40)
        
        update { viewStates in
            viewStates.removeAll()
            Self.insert((0..<20).map { _ in Self.message(id: .randomEvent) }, at: 0, in: &viewStates)
        }
        
        #expect(tableView.contentOffset.y > -1.5 && tableView.contentOffset.y <= 0)
        #expect(tableView.contentInset == .zero)
    }
    
    @Test
    func aDragEndingOnTheSpaceUnderTheNewestMessageSettlesAtTheBottom() async {
        sendProgress.send(.sending)
        growView(by: 40)
        
        controller.scrollViewWillBeginDragging(tableView)
        controller.scrollViewDidEndDragging(tableView, willDecelerate: false)
        
        #expect(await settlesAtTheBottom(withInsets: .zero))
    }
    
    @Test
    func aDragEndingInTheHistoryLeavesTheMessagesWhereTheyAre() throws {
        sendProgress.send(.sending)
        growView(by: 40)
        controller.scrollViewWillBeginDragging(tableView)
        tableView.contentOffset.y = 200
        window.layoutIfNeeded()
        let rowID = try #require(viewStates.keys.first { visibleCell(for: $0) != nil })
        let rowTop = try visualTop(of: rowID)
        
        controller.scrollViewDidEndDragging(tableView, willDecelerate: false)
        window.layoutIfNeeded()
        
        #expect(try abs(visualTop(of: rowID) - rowTop) < 0.5)
        #expect(tableView.contentInset == .zero, "The hold should hand back the insets it added.")
    }
    
    @Test
    func aSecondSendDuringTheReleaseHoldsTheTimelineAgain() async throws {
        sendProgress.send(.sending)
        sendProgress.send(.clearingComposer)
        show(adding: [Self.message(id: Self.echoID, isOutgoing: true)])
        let heldOffset = tableView.contentOffset.y
        try #require(await eventually { tableView.contentOffset.y < heldOffset - 0.5 }, "The release should have started.")
        
        sendProgress.send(.sending)
        let echoTop = try visualTop(of: Self.echoID.uniqueID)
        try await Task.sleep(for: .milliseconds(100))
        #expect(try abs(visualTop(of: Self.echoID.uniqueID) - echoTop) < 0.5, "The first echo should stay where the second send found it.")
        
        sendProgress.send(.clearingComposer)
        show(adding: [Self.message(id: Self.secondEchoID, isOutgoing: true)])
        #expect(await settlesAtTheBottom(withInsets: .zero))
    }
    
    @Test(arguments: HoldExit.allCases)
    func leavingWhileHoldingHandsBackTheInsets(through exit: HoldExit) throws {
        sendProgress.send(.sending)
        growView(by: 40)
        try #require(tableView.contentInset != .zero)
        
        switch exit {
        case .disappearing:
            controller.viewWillDisappear(false)
            #expect(tableView.contentOffset.y > -1.5 && tableView.contentOffset.y <= 0, "The timeline should be at the bottom when it's shown again.")
        case .leavingTheLiveTimeline:
            controller.isLive = false
        }
        
        #expect(tableView.contentInset == .zero)
    }
    
    /// The previous newest message loses its "Sent" as the next one lands. Its row has to shrink in the insert's batch,
    /// held or not, or the history dips after the insert.
    @Test(arguments: [false, true])
    func thePreviousNewestMessageLosesItsReceiptInTheInsertsBatch(whileHoldingASend: Bool) async throws {
        let sentID = TimelineItemIdentifier.randomEvent
        update(syncingTheViewModel: true) { Self.insert([Self.message(id: sentID, isOutgoing: true)], at: $0.count, in: &$0) }
        restAtTheBottom()
        try await settle()
        let heightWithReceipt = try rowHeight(of: sentID.uniqueID)
        
        if whileHoldingASend {
            sendProgress.send(.sending)
        }
        let newest = whileHoldingASend ? Self.message(id: Self.echoID, isOutgoing: true) : Self.message(id: .randomEvent)
        Self.insert([newest], at: viewStates.count, in: &viewStates)
        viewModel.state.timelineState.itemsDictionary = viewStates
        controller.timelineItemsDictionary = viewStates
        let heightAfterTheBatch = try rowHeight(of: sentID.uniqueID)
        window.layoutIfNeeded()
        try await settle()
        
        let height = try rowHeight(of: sentID.uniqueID)
        try #require(height < heightWithReceipt - 5, "The previous newest message should have lost its receipt.")
        #expect(abs(heightAfterTheBatch - height) < 0.5, "The row should have shrunk in the insert's batch.")
    }
    
    /// Layout passes and scroll callbacks run inside an apply, and a diffable apply started from one of them crashes, so
    /// `applySnapshot` asserts against it. This drives every hook the table adds work to, while updates land.
    @Test
    func noUpdateIsAppliedInsideAnother() async throws {
        sendProgress.send(.sending)
        sendProgress.send(.clearingComposer)
        growView(by: 40)
        show(adding: [Self.message(id: Self.echoID, isOutgoing: true)])
        
        controller.scrollViewWillBeginDragging(tableView)
        show(adding: [Self.message(id: .randomEvent)]) // Waits for the drag to end.
        controller.scrollViewDidScroll(tableView)
        controller.scrollViewDidEndDragging(tableView, willDecelerate: true)
        controller.scrollViewDidEndDecelerating(tableView)
        controller.scrollViewDidEndScrollingAnimation(tableView)
        
        show(addingAtTheOldestEnd: [Self.backwardSpinner])
        try scrollToTheOldestEnd()
        update { viewStates in
            viewStates.removeValue(forKey: Self.backwardSpinner.id.uniqueID)
            Self.insert((0..<4).map { _ in Self.message(id: .randomEvent) }, at: 0, in: &viewStates)
        }
        try await settle()
        
        #expect(tableView.numberOfRows(inSection: 1) == viewStates.count)
    }
    
    // MARK: - Pages
    
    /// A live timeline at the bottom follows its newest messages, even when a page lands at its oldest end in the same update.
    @Test(arguments: [false, true])
    func aNewMessageShowsAtTheBottomOfALiveTimeline(whileAPageLandsAtTheOldestEnd: Bool) throws {
        restAtTheBottom()
        let newestID = try #require(viewStates.keys.last)
        let newestBottom = try visualRect(of: newestID).maxY
        let message = Self.message(id: .randomEvent)
        
        update { viewStates in
            if whileAPageLandsAtTheOldestEnd {
                Self.insert((0..<4).map { _ in Self.message(id: .randomEvent) }, at: 0, in: &viewStates)
            }
            Self.insert([message], at: viewStates.count, in: &viewStates)
        }
        
        #expect(abs(tableView.contentOffset.y + 1) < 0.5)
        #expect(try abs(visualRect(of: message.id.uniqueID).maxY - newestBottom) < 0.5, "The new message should show where the newest one was.")
        #expect(tableView.contentInset == .zero)
    }
    
    /// The pages, spinners and on-screen changes that land in the same update when the timeline opens.
    @Test(arguments: [false, true])
    func aLiveTimelineStaysAtTheBottomWhenARowOnScreenGoes(whileAPageLandsAtTheOldestEnd: Bool) throws {
        let readMarker = ReadMarkerRoomTimelineItem(id: .virtual(uniqueID: .init("readMarker")))
        update { Self.insert([readMarker], at: $0.count - 3, in: &$0) }
        restAtTheBottom()
        try #require(visualRect(of: readMarker.id.uniqueID).height > 0)
        let newestID = try #require(viewStates.keys.last)
        let newestBottom = try visualRect(of: newestID).maxY
        
        update { viewStates in
            viewStates.removeValue(forKey: readMarker.id.uniqueID)
            if whileAPageLandsAtTheOldestEnd {
                Self.insert((0..<4).map { _ in Self.message(id: .randomEvent) }, at: 0, in: &viewStates)
            }
        }
        
        #expect(abs(tableView.contentOffset.y + 1) < 0.5)
        #expect(tableView.contentInset == .zero)
        #expect(try abs(visualRect(of: newestID).maxY - newestBottom) < 0.5)
    }
    
    /// When the page's newest message is from the same sender, the oldest message shown loses its sender header.
    @Test(arguments: [false, true])
    func theMessagesShownStayPutWhenAPageReplacesTheSpinner(regroupingTheOldestMessage: Bool) async throws {
        let oldestID = try #require(viewStates.keys.first)
        let nextID = viewStates.keys[1]
        show(addingAtTheOldestEnd: [Self.backwardSpinner])
        try scrollToTheOldestEnd()
        let oldestRect = try visualRect(of: oldestID)
        let nextTop = try visualRect(of: nextID).minY
        let page = (0..<4).map { _ in Self.message(id: .randomEvent) }
        let pageNewestID = try #require(page.last?.id.uniqueID)
        
        if regroupingTheOldestMessage {
            try regroupWithoutAnimation(oldestID, to: .last)
        }
        update { viewStates in
            viewStates.removeValue(forKey: Self.backwardSpinner.id.uniqueID)
            Self.insert(page, at: 0, in: &viewStates)
        }
        let pageBottom = try visualRect(of: pageNewestID).maxY
        #expect(try abs(visualRect(of: nextID).minY - nextTop) < 0.5)
        
        try await settle()
        
        #expect(try abs(visualRect(of: nextID).minY - nextTop) < 0.5)
        #expect(try abs(visualRect(of: oldestID).maxY - oldestRect.maxY) < 0.5, "The oldest message's bubble should end where it did.")
        #expect(try abs(visualRect(of: pageNewestID).maxY - pageBottom) < 0.5, "The page shouldn't move once it's shown.")
        if regroupingTheOldestMessage {
            #expect(try visualRect(of: oldestID).height < oldestRect.height - 5, "The oldest message should have lost its header.")
        } else {
            #expect(try abs(visualRect(of: oldestID).minY - oldestRect.minY) < 0.5)
        }
    }
    
    @Test
    func theOldestMessageStaysPutWhenTheSpinnerLeavesAtTheStartOfTheRoom() async throws {
        let oldestID = try #require(viewStates.keys.first)
        show(addingAtTheOldestEnd: [Self.backwardSpinner])
        try scrollToTheOldestEnd()
        let oldestTop = try visualRect(of: oldestID).minY
        let spinnerHeight = try visualRect(of: Self.backwardSpinner.id.uniqueID).height
        
        update { $0.removeValue(forKey: Self.backwardSpinner.id.uniqueID) }
        #expect(try abs(visualRect(of: oldestID).minY - oldestTop) < 0.5)
        
        try await settle()
        
        #expect(try abs(visualRect(of: oldestID).minY - oldestTop) < 0.5)
        #expect(abs(tableView.contentInset.bottom - spinnerHeight) < 0.5, "An inset should keep the space the spinner left.")
    }
    
    /// Taking the space away while it's on screen would make UIKit snap the rows back over it.
    @Test(arguments: [true, false])
    func theSpaceASpinnerLeftStaysUntilTheReaderScrollsOutOfIt(atTheStartOfTheRoom: Bool) async throws {
        let spinner = atTheStartOfTheRoom ? Self.backwardSpinner : Self.forwardSpinner
        if atTheStartOfTheRoom {
            show(addingAtTheOldestEnd: [spinner])
            try scrollToTheOldestEnd()
        } else {
            controller.isLive = false
            show(adding: [spinner])
            restAtTheBottom()
        }
        let spinnerHeight = try visualRect(of: spinner.id.uniqueID).height
        update { $0.removeValue(forKey: spinner.id.uniqueID) }
        let insets = tableView.contentInset
        try #require(insets != .zero, "An inset should keep the space the spinner left.")
        let visibleIDs = viewStates.keys.filter { visibleCell(for: $0) != nil }
        let rowID = visibleIDs[visibleIDs.count / 2]
        let rowTop = try visualRect(of: rowID).minY
        
        controller.scrollViewWillBeginDragging(tableView)
        
        #expect(try abs(visualRect(of: rowID).minY - rowTop) < 0.5, "Putting a finger down shouldn't move the messages.")
        #expect(tableView.contentInset == insets)
        
        // Further than the space goes, towards the newest messages at the start of the room and away from them otherwise.
        tableView.contentOffset.y += (atTheStartOfTheRoom ? -1 : 1) * (spinnerHeight + 50)
        let offset = tableView.contentOffset.y
        let scrolledRowTop = try visualRect(of: rowID).minY
        
        #expect(await eventually { tableView.contentInset == .zero }, "The space should go once it's off screen.")
        #expect(tableView.contentOffset.y == offset)
        #expect(try abs(visualRect(of: rowID).minY - scrolledRowTop) < 0.5)
    }
    
    /// The space goes during the jump's scroll animation, which has to keep going.
    @Test
    func aJumpToTheBottomFromTheStartOfTheRoomGetsThereWithoutTheSpaceTheSpinnerLeft() async throws {
        show(addingAtTheOldestEnd: [Self.backwardSpinner])
        try scrollToTheOldestEnd()
        update { $0.removeValue(forKey: Self.backwardSpinner.id.uniqueID) }
        try #require(tableView.contentInset.bottom > 0, "An inset should keep the space the spinner left.")
        
        scrollToBottom.send(())
        
        #expect(await eventually { tableView.contentOffset.y <= 0 && tableView.contentInset == .zero })
    }
    
    /// A message halfway up the screen loses its header in the same update, so the messages above and below it can't both
    /// stay put. A live timeline keeps the topmost one still, where its pages land, and a detached one the bottom one.
    @Test(arguments: [true, false])
    func theMessageAtTheEdgeWherePagesLandStaysPut(isLive: Bool) throws {
        controller.isLive = isLive
        if isLive {
            show(addingAtTheOldestEnd: [Self.backwardSpinner])
            try scrollToTheOldestEnd()
        }
        let visibleIDs = viewStates.keys.filter { visibleCell(for: $0) != nil && $0 != Self.backwardSpinner.id.uniqueID }
        let edgeID = try #require(isLive ? visibleIDs.first : visibleIDs.last)
        let edgeTop = try visualRect(of: edgeID).minY
        let page = (0..<4).map { _ in Self.message(id: .randomEvent) }
        
        try regroupWithoutAnimation(visibleIDs[visibleIDs.count / 2], to: .last)
        update { viewStates in
            if isLive {
                viewStates.removeValue(forKey: Self.backwardSpinner.id.uniqueID)
                Self.insert(page, at: 0, in: &viewStates)
            } else {
                Self.insert(page, at: viewStates.count, in: &viewStates)
            }
        }
        
        #expect(try abs(visualRect(of: edgeID).minY - edgeTop) < 0.5)
    }
    
    /// While it loads, the forward spinner stays below the messages it brings in.
    @Test(arguments: [false, true])
    func theNewestMessageShownStaysPutWhenANewerPageLandsInADetachedTimeline(underTheSpinner: Bool) async throws {
        controller.isLive = false
        let newestID = try #require(viewStates.keys.last)
        if underTheSpinner {
            show(adding: [Self.forwardSpinner])
        }
        let newestTop = try visualRect(of: newestID).minY
        let page = (0..<4).map { _ in Self.message(id: .randomEvent) }
        
        update { viewStates in
            Self.insert(page, at: viewStates.count - (underTheSpinner ? 1 : 0), in: &viewStates)
        }
        #expect(try abs(visualRect(of: newestID).minY - newestTop) < 0.5)
        
        try await settle()
        
        #expect(try abs(visualRect(of: newestID).minY - newestTop) < 0.5)
    }
    
    /// Moving the rows back doesn't call the scroll delegate. The apply's own row updates do, and the delegate works out
    /// whether the timeline is at the bottom a turn later, from where the rows ended up.
    @Test
    func keepingTheReadersPlaceUpdatesWhetherTheTimelineIsAtTheBottom() async throws {
        controller.isLive = false
        show(adding: [Self.forwardSpinner])
        tableView.contentOffset.y = 10 // Shows the top of the spinner below the newest message.
        window.layoutIfNeeded()
        try #require(await eventually { scrolledToBottom.values.last == false })
        
        update { $0.removeValue(forKey: Self.forwardSpinner.id.uniqueID) }
        
        #expect(tableView.contentOffset.y <= 0, "The rows should have moved up into the space the spinner left.")
        #expect(await eventually { scrolledToBottom.values.last == true }, "The jump to the bottom button should hide.")
    }
    
    /// The start of the room has the same ID in every timeline, so it's still there after the switch.
    @Test(arguments: [true, false])
    func switchingToTheLiveTimelineShowsItsNewestMessage(reportingLiveFirst: Bool) throws {
        controller.isLive = false
        show(addingAtTheOldestEnd: [TimelineStartRoomTimelineItem(name: nil)])
        try scrollToTheOldestEnd()
        
        switchToANewLiveTimeline(startingWith: [TimelineStartRoomTimelineItem(name: nil)], reportingLiveFirst: reportingLiveFirst)
        
        #expect(tableView.contentOffset.y <= 0)
    }
    
    @Test
    func switchingTimelinesDropsTheSpaceTheSpinnerLeft() throws {
        controller.isLive = false
        show(adding: [Self.forwardSpinner])
        restAtTheBottom()
        update { $0.removeValue(forKey: Self.forwardSpinner.id.uniqueID) }
        try #require(tableView.contentInset.top > 0, "An inset should keep the space the spinner left.")
        
        switchToANewLiveTimeline()
        
        #expect(tableView.contentInset == .zero)
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
    
    /// Inserts the items, oldest first, at `index` of the oldest-first timeline.
    private static func insert(_ items: [RoomTimelineItemProtocol],
                               at index: Int,
                               in viewStates: inout OrderedDictionary<TimelineItemIdentifier.UniqueID, RoomTimelineItemViewState>) {
        for (offset, item) in items.enumerated() {
            viewStates.updateValue(RoomTimelineItemViewState(item: item, groupStyle: .single), forKey: item.id.uniqueID, insertingAt: index + offset)
        }
    }
    
    /// Shows the items after the ones already shown, as the view model's next update would.
    private func show(adding items: [RoomTimelineItemProtocol]) {
        update { Self.insert(items, at: $0.count, in: &$0) }
    }
    
    /// Shows the items before the ones already shown, as the view model's next update would.
    private func show(addingAtTheOldestEnd items: [RoomTimelineItemProtocol]) {
        update { Self.insert(items, at: 0, in: &$0) }
    }
    
    /// Shows the timeline with `change` made, as the view model's next update would. Views that read the view model's
    /// items, such as a message's "Sent", only see the change when `syncingTheViewModel`.
    private func update(syncingTheViewModel: Bool = false,
                        _ change: (inout OrderedDictionary<TimelineItemIdentifier.UniqueID, RoomTimelineItemViewState>) -> Void) {
        change(&viewStates)
        if syncingTheViewModel {
            viewModel.state.timelineState.itemsDictionary = viewStates
        }
        controller.timelineItemsDictionary = viewStates
        window.layoutIfNeeded()
    }
    
    /// Shows a new timeline of `count` messages at the bottom, as in a new room or DM.
    private func showOnlyMessages(_ count: Int) {
        controller.isSwitchingTimelines = true
        update { viewStates in
            viewStates.removeAll()
            Self.insert((0..<count).map { _ in Self.message(id: .randomEvent) }, at: 0, in: &viewStates)
        }
        controller.isSwitchingTimelines = false
        restAtTheBottom()
    }
    
    /// Changes the row's group style in place and without animation, as the view model does when a page lands next to it.
    private func regroupWithoutAnimation(_ id: TimelineItemIdentifier.UniqueID, to groupStyle: TimelineGroupStyle) throws {
        let viewState = try #require(viewStates[id])
        viewState.animatesResize = false
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            viewState.groupStyle = groupStyle
        }
    }
    
    /// Shows a new live timeline. The timeline controller reports that it's live before it reports the new items, but when
    /// both land in one SwiftUI update, `TimelineViewRepresentable` passes the items on first.
    private func switchToANewLiveTimeline(startingWith oldestItems: [RoomTimelineItemProtocol] = [], reportingLiveFirst: Bool = true) {
        if reportingLiveFirst {
            controller.isLive = true
        }
        controller.isSwitchingTimelines = true
        update { viewStates in
            viewStates.removeAll()
            Self.insert(oldestItems + (0..<20).map { _ -> RoomTimelineItemProtocol in Self.message(id: .randomEvent) }, at: 0, in: &viewStates)
        }
        if !reportingLiveFirst {
            controller.isLive = true
        }
    }
    
    /// The offset that shows the oldest row at the top of the table, past which UIKit snaps the offset back.
    private var oldestEndOffset: CGFloat {
        tableView.contentSize.height + tableView.adjustedContentInset.bottom - tableView.bounds.height
    }
    
    /// Scrolls as far towards the oldest messages as the table goes, as the reader does to load older ones.
    private func scrollToTheOldestEnd() throws {
        // Half a screen at a time, as a reader scrolls, so that every row has replaced its estimated height. When that
        // shrinks the content under the offset, UIKit slides the offset back with an animation: setting it stops that.
        for _ in 0..<50 where abs(tableView.contentOffset.y - oldestEndOffset) >= 0.5 {
            let offset = min(tableView.contentOffset.y + tableView.bounds.height / 2, oldestEndOffset)
            tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
            window.layoutIfNeeded()
        }
        try #require(abs(tableView.contentOffset.y - oldestEndOffset) < 0.5, "The table should have reached its oldest end.")
    }
    
    /// Shows the newest messages, at the offset the timeline rests at so that a status bar tap still scrolls.
    private func restAtTheBottom() {
        tableView.contentOffset.y = -1
        window.layoutIfNeeded()
    }
    
    /// Moves the timeline's bottom edge down by `delta`, as the composer does when it shrinks by that much.
    private func growView(by delta: CGFloat) {
        controller.view.frame.size.height += delta
        window.layoutIfNeeded()
    }
    
    private func visibleCell(for id: TimelineItemIdentifier.UniqueID) -> UITableViewCell? {
        tableView.visibleCells.first { ($0 as? TimelineItemCell)?.item?.id == id }
    }
    
    private func cell(for id: TimelineItemIdentifier.UniqueID) throws -> UITableViewCell {
        try #require(visibleCell(for: id))
    }
    
    /// The row's height in the table, which is up to date right after an apply, unlike its cell's frame.
    private func rowHeight(of id: TimelineItemIdentifier.UniqueID) throws -> CGFloat {
        let index = try #require(viewStates.index(forKey: id))
        // The newest message is the first row of the main section, which comes after the typing indicator's.
        return tableView.rectForRow(at: IndexPath(row: viewStates.count - 1 - index, section: 1)).height
    }
    
    /// The window y of the row's top as seen on screen.
    private func visualTop(of id: TimelineItemIdentifier.UniqueID) throws -> CGFloat {
        try visualRect(of: id).minY
    }
    
    /// The row's rect as seen on screen, in window coordinates.
    private func visualRect(of id: TimelineItemIdentifier.UniqueID) throws -> CGRect {
        let cell = try cell(for: id)
        return cell.convert(cell.bounds, to: nil)
    }
    
    /// Lets the rows finish any resize or offset adjustment that UIKit or SwiftUI leaves for a later pass.
    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(100))
        window.layoutIfNeeded()
    }
    
    /// Waits for the hold to end, which is when it hands back the insets, with the newest row at the bottom.
    private func settlesAtTheBottom(withInsets insets: UIEdgeInsets) async -> Bool {
        await eventually { tableView.contentInset == insets && abs(tableView.contentOffset.y + 1) < 0.5 }
    }
    
    /// Like `settlesAtTheBottom(withInsets: .zero)`, with the offsets on the way there.
    private func offsetsUntilSettledAtTheBottom() async -> [CGFloat]? {
        var offsets = [tableView.contentOffset.y]
        let settles = await eventually {
            offsets.append(tableView.contentOffset.y)
            return tableView.contentInset == .zero && abs(tableView.contentOffset.y + 1) < 0.5
        }
        return settles ? offsets : nil
    }
    
    private func largestStep(in offsets: [CGFloat]) -> CGFloat {
        zip(offsets, offsets.dropFirst()).map { abs($1 - $0) }.max() ?? 0
    }
    
    private func eventually(_ condition: () -> Bool) async -> Bool {
        let deadline = ContinuousClock.now + .seconds(3)
        while !condition() {
            guard ContinuousClock.now < deadline else { return false }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return true
    }
    
    /// How the table stops showing a held send's timeline.
    nonisolated enum HoldExit: CaseIterable {
        case disappearing
        case leavingTheLiveTimeline
    }
}

/// Records every value written through its binding.
private final class ValueRecorder<Value> {
    private(set) var values: [Value]
    
    var binding: Binding<Value> {
        Binding { self.values[self.values.count - 1] } set: { self.values.append($0) }
    }
    
    init(_ initialValue: Value) {
        values = [initialValue]
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX

import Combine
import MatrixRustSDK
import XCTest

@MainActor
class TimelineViewModelTests: XCTestCase {
    var userIndicatorControllerMock: UserIndicatorControllerMock!
    var cancellables = Set<AnyCancellable>()

    override func setUp() async throws {
        AppSettings.resetAllSettings()
        cancellables.removeAll()
        userIndicatorControllerMock = UserIndicatorControllerMock.default
    }

    override func tearDown() async throws {
        userIndicatorControllerMock = nil
    }
    
    // MARK: - Message Grouping

    func testMessageGrouping() {
        // Given 3 messages from Bob.
        let items = [
            TextRoomTimelineItem(text: "Message 1",
                                 sender: "bob"),
            TextRoomTimelineItem(text: "Message 2",
                                 sender: "bob"),
            TextRoomTimelineItem(text: "Message 3",
                                 sender: "bob")
        ]
        
        // When showing them in a timeline.
        let timelineController = MockRoomTimelineController()
        timelineController.timelineItems = items
        let viewModel = makeViewModel(timelineController: timelineController)
        
        // Then the messages should be grouped together.
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[0].groupStyle, .first, "Nothing should prevent the first message from being grouped.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[1].groupStyle, .middle, "Nothing should prevent the middle message from being grouped.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[2].groupStyle, .last, "Nothing should prevent the last message from being grouped.")
    }
    
    func testMessageGroupingMultipleSenders() {
        // Given some interleaved messages from Bob and Alice.
        let items = [
            TextRoomTimelineItem(text: "Message 1",
                                 sender: "alice"),
            TextRoomTimelineItem(text: "Message 2",
                                 sender: "bob"),
            TextRoomTimelineItem(text: "Message 3",
                                 sender: "alice"),
            TextRoomTimelineItem(text: "Message 4",
                                 sender: "alice"),
            TextRoomTimelineItem(text: "Message 5",
                                 sender: "bob"),
            TextRoomTimelineItem(text: "Message 6",
                                 sender: "bob")
        ]
        
        // When showing them in a timeline.
        let timelineController = MockRoomTimelineController()
        timelineController.timelineItems = items
        let viewModel = makeViewModel(timelineController: timelineController)
        
        // Then the messages should be grouped by sender.
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[0].groupStyle, .single, "A message should not be grouped when the sender changes.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[1].groupStyle, .single, "A message should not be grouped when the sender changes.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[2].groupStyle, .first, "A group should start with a new sender if there are more messages from that sender.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[3].groupStyle, .last, "A group should be ended when the sender changes in the next message.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[4].groupStyle, .first, "A group should start with a new sender if there are more messages from that sender.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[5].groupStyle, .last, "A group should be ended when the sender changes in the next message.")
    }
    
    func testMessageGroupingWithLeadingReactions() {
        // Given 3 messages from Bob where the first message has a reaction.
        let items = [
            TextRoomTimelineItem(text: "Message 1",
                                 sender: "bob",
                                 addReactions: true),
            TextRoomTimelineItem(text: "Message 2",
                                 sender: "bob"),
            TextRoomTimelineItem(text: "Message 3",
                                 sender: "bob")
        ]
        
        // When showing them in a timeline.
        let timelineController = MockRoomTimelineController()
        timelineController.timelineItems = items
        let viewModel = makeViewModel(timelineController: timelineController)
        
        // Then the first message should not be grouped but the other two should.
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[0].groupStyle, .single, "When the first message has reactions it should not be grouped.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[1].groupStyle, .first, "A new group should be made when the preceding message has reactions.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[2].groupStyle, .last, "Nothing should prevent the last message from being grouped.")
    }
    
    func testMessageGroupingWithInnerReactions() {
        // Given 3 messages from Bob where the middle message has a reaction.
        let items = [
            TextRoomTimelineItem(text: "Message 1",
                                 sender: "bob"),
            TextRoomTimelineItem(text: "Message 2",
                                 sender: "bob",
                                 addReactions: true),
            TextRoomTimelineItem(text: "Message 3",
                                 sender: "bob")
        ]
        
        // When showing them in a timeline.
        let timelineController = MockRoomTimelineController()
        timelineController.timelineItems = items
        let viewModel = makeViewModel(timelineController: timelineController)
        
        // Then the first and second messages should be grouped and the last one should not.
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[0].groupStyle, .first, "Nothing should prevent the first message from being grouped.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[1].groupStyle, .last, "When the message has reactions, the group should end here.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[2].groupStyle, .single, "The last message should not be grouped when the preceding message has reactions.")
    }
    
    func testMessageGroupingWithTrailingReactions() {
        // Given 3 messages from Bob where the last message has a reaction.
        let items = [
            TextRoomTimelineItem(text: "Message 1",
                                 sender: "bob"),
            TextRoomTimelineItem(text: "Message 2",
                                 sender: "bob"),
            TextRoomTimelineItem(text: "Message 3",
                                 sender: "bob",
                                 addReactions: true)
        ]
        
        // When showing them in a timeline.
        let timelineController = MockRoomTimelineController()
        timelineController.timelineItems = items
        let viewModel = makeViewModel(timelineController: timelineController)
        
        // Then the messages should be grouped together.
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[0].groupStyle, .first, "Nothing should prevent the first message from being grouped.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[1].groupStyle, .middle, "Nothing should prevent the second message from being grouped.")
        XCTAssertEqual(viewModel.state.timelineState.itemViewStates[2].groupStyle, .last, "Reactions on the last message should not prevent it from being grouped.")
    }
    
    // MARK: - Focussing
    
    func testFocusItem() async throws {
        // Given a room with 3 items loaded in a live timeline.
        let items = [TextRoomTimelineItem(eventID: "t1"),
                     TextRoomTimelineItem(eventID: "t2"),
                     TextRoomTimelineItem(eventID: "t3")]
        let timelineController = MockRoomTimelineController()
        timelineController.timelineItems = items
        
        let viewModel = makeViewModel(timelineController: timelineController)
        XCTAssertEqual(timelineController.focusOnEventCallCount, 0)
        XCTAssertTrue(viewModel.context.viewState.timelineState.isLive)
        XCTAssertNil(viewModel.context.viewState.timelineState.focussedEvent)
        
        // When focussing on an item that isn't loaded.
        let deferred = deferFulfillment(viewModel.context.$viewState) { !$0.timelineState.isLive }
        await viewModel.focusOnEvent(eventID: "t4")
        try await deferred.fulfill()
        
        // Then a new timeline should be loaded and the room focussed on that event.
        XCTAssertEqual(timelineController.focusOnEventCallCount, 1)
        XCTAssertFalse(viewModel.context.viewState.timelineState.isLive)
        XCTAssertEqual(viewModel.context.viewState.timelineState.focussedEvent, .init(eventID: "t4", appearance: .immediate))
    }
    
    func testFocusLoadedItem() async throws {
        // Given a room with 3 items loaded in a live timeline.
        let items = [TextRoomTimelineItem(eventID: "t1"),
                     TextRoomTimelineItem(eventID: "t2"),
                     TextRoomTimelineItem(eventID: "t3")]
        let timelineController = MockRoomTimelineController()
        timelineController.timelineItems = items
        
        let viewModel = makeViewModel(timelineController: timelineController)
        XCTAssertEqual(timelineController.focusOnEventCallCount, 0)
        XCTAssertTrue(viewModel.context.viewState.timelineState.isLive)
        XCTAssertNil(viewModel.context.viewState.timelineState.focussedEvent)
        
        // When focussing on a loaded item.
        let deferred = deferFailure(viewModel.context.$viewState, timeout: 1) { !$0.timelineState.isLive }
        await viewModel.focusOnEvent(eventID: "t1")
        try await deferred.fulfill()
        
        // Then the timeline should remain live and the item should be focussed.
        XCTAssertEqual(timelineController.focusOnEventCallCount, 0)
        XCTAssertTrue(viewModel.context.viewState.timelineState.isLive)
        XCTAssertEqual(viewModel.context.viewState.timelineState.focussedEvent, .init(eventID: "t1", appearance: .animated))
    }
    
    func testFocusLive() async throws {
        // Given a room with a non-live timeline focussed on a particular event.
        let items = [TextRoomTimelineItem(eventID: "t1"),
                     TextRoomTimelineItem(eventID: "t2"),
                     TextRoomTimelineItem(eventID: "t3")]
        let timelineController = MockRoomTimelineController()
        timelineController.timelineItems = items
        
        let viewModel = makeViewModel(timelineController: timelineController)
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { !$0.timelineState.isLive }
        await viewModel.focusOnEvent(eventID: "t4")
        try await deferred.fulfill()
        
        XCTAssertEqual(timelineController.focusLiveCallCount, 0)
        XCTAssertFalse(viewModel.context.viewState.timelineState.isLive)
        XCTAssertEqual(viewModel.context.viewState.timelineState.focussedEvent, .init(eventID: "t4", appearance: .immediate))
        
        // When switching back to a live timeline.
        deferred = deferFulfillment(viewModel.context.$viewState) { $0.timelineState.isLive }
        viewModel.context.send(viewAction: .focusLive)
        try await deferred.fulfill()
        
        // Then the timeline should switch back to being live and the event focus should be removed.
        XCTAssertEqual(timelineController.focusLiveCallCount, 1)
        XCTAssertTrue(viewModel.context.viewState.timelineState.isLive)
        XCTAssertNil(viewModel.context.viewState.timelineState.focussedEvent)
    }
    
    func testInitialFocusViewState() async throws {
        let timelineController = MockRoomTimelineController()
        
        let viewModel = makeViewModel(focussedEventID: "t10", timelineController: timelineController)
        XCTAssertEqual(viewModel.context.viewState.timelineState.focussedEvent, .init(eventID: "t10", appearance: .immediate))
    }
    
    // MARK: - Read Receipts
    
    // swiftlint:disable force_unwrapping
    func testSendReadReceipt() async throws {
        // Given a room with only text items in the timeline
        let items = [TextRoomTimelineItem(eventID: "t1"),
                     TextRoomTimelineItem(eventID: "t2"),
                     TextRoomTimelineItem(eventID: "t3")]
        let (viewModel, _, timelineProxy, _) = readReceiptsConfiguration(with: items)
        
        // When sending a read receipt for the last item.
        viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(items.last!.id))
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the receipt should be sent.
        XCTAssertEqual(timelineProxy.sendReadReceiptForTypeCalled, true)
        let arguments = timelineProxy.sendReadReceiptForTypeReceivedArguments
        XCTAssertEqual(arguments?.eventID, "t3")
        XCTAssertEqual(arguments?.type, .read)
    }
    
    func testSendReadReceiptWithoutEvents() async throws {
        // Given a room with only virtual items.
        let items = [SeparatorRoomTimelineItem(uniqueID: .init(id: "v1")),
                     SeparatorRoomTimelineItem(uniqueID: .init(id: "v2")),
                     SeparatorRoomTimelineItem(uniqueID: .init(id: "v3"))]
        let (viewModel, _, timelineProxy, _) = readReceiptsConfiguration(with: items)
        
        // When sending a read receipt for the last item.
        viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(items.last!.id))
        try await Task.sleep(for: .milliseconds(100))
        
        // Then nothing should be sent.
        XCTAssertEqual(timelineProxy.sendReadReceiptForTypeCalled, false)
    }
    
    func testSendReadReceiptVirtualLast() async throws {
        // Given a room where the last event is a virtual item.
        let items: [RoomTimelineItemProtocol] = [TextRoomTimelineItem(eventID: "t1"),
                                                 TextRoomTimelineItem(eventID: "t2"),
                                                 SeparatorRoomTimelineItem(uniqueID: .init(id: "v3"))]
        let (viewModel, _, _, _) = readReceiptsConfiguration(with: items)
        
        // When sending a read receipt for the last item.
        viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(items.last!.id))
        try await Task.sleep(for: .milliseconds(100))
    }
    
    // swiftlint:enable force_unwrapping
    // swiftlint:disable:next large_tuple
    private func readReceiptsConfiguration(with items: [RoomTimelineItemProtocol]) -> (TimelineViewModel,
                                                                                       JoinedRoomProxyMock,
                                                                                       TimelineProxyMock,
                                                                                       MockRoomTimelineController) {
        let roomProxy = JoinedRoomProxyMock(.init(name: ""))
        
        let timelineProxy = TimelineProxyMock()
        
        roomProxy.timeline = timelineProxy
        let timelineController = MockRoomTimelineController()
        
        timelineProxy.sendReadReceiptForTypeReturnValue = .success(())
        
        timelineController.timelineItems = items
        timelineController.roomProxy = roomProxy

        let viewModel = TimelineViewModel(roomProxy: roomProxy,
                                          timelineController: timelineController,
                                          mediaProvider: MediaProviderMock(configuration: .init()),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                          userIndicatorController: userIndicatorControllerMock,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics,
                                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings))
        return (viewModel, roomProxy, timelineProxy, timelineController)
    }
    
    func testShowReadReceipts() async throws {
        let receipts: [ReadReceipt] = [.init(userID: "@alice:matrix.org", formattedTimestamp: "12:00"),
                                       .init(userID: "@charlie:matrix.org", formattedTimestamp: "11:00")]
        // Given 3 messages from Bob where the middle message has a reaction.
        let message = TextRoomTimelineItem(text: "Test",
                                           sender: "bob",
                                           addReadReceipts: receipts)
        let id = message.id
        
        // When showing them in a timeline.
        let timelineController = MockRoomTimelineController()
        timelineController.timelineItems = [message]
        let viewModel = TimelineViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "", members: [RoomMemberProxyMock.mockAlice, RoomMemberProxyMock.mockCharlie])),
                                          timelineController: timelineController,
                                          mediaProvider: MediaProviderMock(configuration: .init()),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                          userIndicatorController: userIndicatorControllerMock,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics,
                                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings))
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.bindings.readReceiptsSummaryInfo?.orderedReceipts == receipts
        }
        
        viewModel.context.send(viewAction: .displayReadReceipts(itemID: id))
        try await deferred.fulfill()
    }
    
    // MARK: - Pins
    
    func testPinnedEvents() async throws {
        var configuration = JoinedRoomProxyMockConfiguration(name: "",
                                                             pinnedEventIDs: .init(["test1"]))
        let roomProxyMock = JoinedRoomProxyMock(configuration)
        let infoSubject = CurrentValueSubject<RoomInfoProxy, Never>(.init(roomInfo: RoomInfo(configuration)))
        roomProxyMock.underlyingInfoPublisher = infoSubject.asCurrentValuePublisher()
        
        let viewModel = TimelineViewModel(roomProxy: roomProxyMock,
                                          timelineController: MockRoomTimelineController(),
                                          mediaProvider: MediaProviderMock(configuration: .init()),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                          userIndicatorController: userIndicatorControllerMock,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics,
                                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings))
        XCTAssertEqual(configuration.pinnedEventIDs, viewModel.context.viewState.pinnedEventIDs)
        
        configuration.pinnedEventIDs = ["test1", "test2"]
        let deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.pinnedEventIDs == ["test1", "test2"]
        }
        infoSubject.send(.init(roomInfo: RoomInfo(configuration)))
        try await deferred.fulfill()
    }
    
    func testCanUserPinEvents() async throws {
        let configuration = JoinedRoomProxyMockConfiguration(name: "", canUserPin: true)
        let roomProxyMock = JoinedRoomProxyMock(configuration)
        let infoSubject = CurrentValueSubject<RoomInfoProxy, Never>(.init(roomInfo: RoomInfo(configuration)))
        roomProxyMock.underlyingInfoPublisher = infoSubject.asCurrentValuePublisher()
        
        let viewModel = TimelineViewModel(roomProxy: roomProxyMock,
                                          timelineController: MockRoomTimelineController(),
                                          mediaProvider: MediaProviderMock(configuration: .init()),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                          userIndicatorController: userIndicatorControllerMock,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics,
                                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings))
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.canCurrentUserPin
        }
        try await deferred.fulfill()
        
        roomProxyMock.canUserPinOrUnpinUserIDReturnValue = .success(false)
        deferred = deferFulfillment(viewModel.context.$viewState) { value in
            !value.canCurrentUserPin
        }
        infoSubject.send(.init(roomInfo: RoomInfo(configuration)))
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    private func makeViewModel(roomProxy: JoinedRoomProxyProtocol? = nil,
                               focussedEventID: String? = nil,
                               timelineController: RoomTimelineControllerProtocol) -> TimelineViewModel {
        TimelineViewModel(roomProxy: roomProxy ?? JoinedRoomProxyMock(.init(name: "")),
                          focussedEventID: focussedEventID,
                          timelineController: timelineController,
                          mediaProvider: MediaProviderMock(configuration: .init()),
                          mediaPlayerProvider: MediaPlayerProviderMock(),
                          voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                          userIndicatorController: userIndicatorControllerMock,
                          appMediator: AppMediatorMock.default,
                          appSettings: ServiceLocator.shared.settings,
                          analyticsService: ServiceLocator.shared.analytics,
                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings))
    }
}

private extension TextRoomTimelineItem {
    init(text: String, sender: String, addReactions: Bool = false, addReadReceipts: [ReadReceipt] = []) {
        let reactions = addReactions ? [AggregatedReaction(accountOwnerID: "bob", key: "🦄", senders: [ReactionSender(id: sender, timestamp: Date())])] : []
        self.init(id: .randomEvent,
                  timestamp: .mock,
                  isOutgoing: sender == "bob",
                  isEditable: sender == "bob",
                  canBeRepliedTo: true,
                  isThreaded: false,
                  sender: .init(id: "@\(sender):server.com", displayName: sender),
                  content: .init(body: text),
                  properties: RoomTimelineItemProperties(reactions: reactions, orderedReadReceipts: addReadReceipts))
    }
}

private extension SeparatorRoomTimelineItem {
    init(uniqueID: TimelineUniqueId) {
        self.init(id: .virtual(uniqueID: uniqueID), timestamp: .mock)
    }
}

private extension TextRoomTimelineItem {
    init(eventID: String) {
        self.init(id: .event(uniqueID: .init(id: UUID().uuidString), eventOrTransactionID: .eventId(eventId: eventID)),
                  timestamp: .mock,
                  isOutgoing: false,
                  isEditable: false,
                  canBeRepliedTo: true,
                  isThreaded: false,
                  sender: .init(id: ""),
                  content: .init(body: "Hello, World!"))
    }
}

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

@testable import ElementX

import Combine
import XCTest

@MainActor
class RoomScreenViewModelTests: XCTestCase {
    var userIndicatorControllerMock: UserIndicatorControllerMock!
    var cancellables = Set<AnyCancellable>()

    override func setUp() async throws {
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
        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: RoomProxyMock(with: .init(displayName: "")),
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)
        
        // Then the messages should be grouped together.
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[0].groupStyle, .first, "Nothing should prevent the first message from being grouped.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[1].groupStyle, .middle, "Nothing should prevent the middle message from being grouped.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[2].groupStyle, .last, "Nothing should prevent the last message from being grouped.")
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
        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: RoomProxyMock(with: .init(displayName: "")),
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)
        
        // Then the messages should be grouped by sender.
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[0].groupStyle, .single, "A message should not be grouped when the sender changes.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[1].groupStyle, .single, "A message should not be grouped when the sender changes.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[2].groupStyle, .first, "A group should start with a new sender if there are more messages from that sender.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[3].groupStyle, .last, "A group should be ended when the sender changes in the next message.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[4].groupStyle, .first, "A group should start with a new sender if there are more messages from that sender.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[5].groupStyle, .last, "A group should be ended when the sender changes in the next message.")
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
        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: RoomProxyMock(with: .init(displayName: "")),
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)
        
        // Then the first message should not be grouped but the other two should.
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[0].groupStyle, .single, "When the first message has reactions it should not be grouped.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[1].groupStyle, .first, "A new group should be made when the preceding message has reactions.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[2].groupStyle, .last, "Nothing should prevent the last message from being grouped.")
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
        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: RoomProxyMock(with: .init(displayName: "")),
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)
        
        // Then the first and second messages should be grouped and the last one should not.
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[0].groupStyle, .first, "Nothing should prevent the first message from being grouped.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[1].groupStyle, .last, "When the message has reactions, the group should end here.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[2].groupStyle, .single, "The last message should not be grouped when the preceding message has reactions.")
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
        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: RoomProxyMock(with: .init(displayName: "")),
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)
        
        // Then the messages should be grouped together.
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[0].groupStyle, .first, "Nothing should prevent the first message from being grouped.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[1].groupStyle, .middle, "Nothing should prevent the second message from being grouped.")
        XCTAssertEqual(viewModel.state.timelineViewState.itemViewStates[2].groupStyle, .last, "Reactions on the last message should not prevent it from being grouped.")
    }
    
    // MARK: - User Details

    func testGoToUserDetailsSuccessNoDelay() async {
        // Setup
        let expectation = expectation(description: #function)
        let timelineController = MockRoomTimelineController()
        let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))
        let roomMemberMock = RoomMemberProxyMock()
        roomMemberMock.userID = "bob"
        roomProxyMock.getMemberUserIDReturnValue = .success(roomMemberMock)

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxyMock,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)
        viewModel.actions
            .sink { action in
                switch action {
                case .displayRoomMemberDetails(let member):
                    XCTAssert(member === roomMemberMock)
                default:
                    XCTFail("Did not received the expected action")
                }
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Test
        viewModel.context.send(viewAction: .tappedOnUser(userID: "bob"))
        await fulfillment(of: [expectation])
        XCTAssert(userIndicatorControllerMock.submitIndicatorDelayCallsCount == 1)
        XCTAssert(roomProxyMock.getMemberUserIDCallsCount == 1)
        XCTAssertEqual(roomProxyMock.getMemberUserIDReceivedUserID, "bob")
    }

    func testGoToUserDetailsSuccessWithDelay() async {
        // Setup
        let timelineController = MockRoomTimelineController()
        let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))
        let roomMemberMock = RoomMemberProxyMock()
        roomMemberMock.userID = "bob"
        let expectation = XCTestExpectation(description: "Go to user details")
        
        roomProxyMock.getMemberUserIDClosure = { _ in
            .success(roomMemberMock)
        }

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxyMock,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)
                                            
        viewModel.actions
            .sink { action in
                switch action {
                case .displayRoomMemberDetails(let member):
                    XCTAssert(member === roomMemberMock)
                    expectation.fulfill()
                default:
                    XCTFail("Did not received the expected action")
                }
            }
            .store(in: &cancellables)

        // Test
        viewModel.context.send(viewAction: .tappedOnUser(userID: "bob"))
        await fulfillment(of: [expectation])
        
        XCTAssert(userIndicatorControllerMock.submitIndicatorDelayCallsCount == 1)
        XCTAssert(userIndicatorControllerMock.retractIndicatorWithIdCallsCount == 1)
        XCTAssert(roomProxyMock.getMemberUserIDCallsCount == 1)
        XCTAssertEqual(roomProxyMock.getMemberUserIDReceivedUserID, "bob")
    }

    func testGoToUserDetailsFailure() async throws {
        // Setup
        let timelineController = MockRoomTimelineController()
        let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))
        let roomMemberMock = RoomMemberProxyMock()
        roomMemberMock.userID = "bob"
        roomProxyMock.getMemberUserIDClosure = { _ in
            .failure(.failedRetrievingMember)
        }

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxyMock,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)
        viewModel.actions
            .sink { _ in
                XCTFail("Should not receive any action")
            }
            .store(in: &cancellables)

        let deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.bindings.alertInfo != nil
        }
        
        viewModel.context.send(viewAction: .tappedOnUser(userID: "bob"))
        
        try await deferred.fulfill()
        
        XCTAssertFalse(viewModel.state.bindings.alertInfo.isNil)
        XCTAssert(roomProxyMock.getMemberUserIDCallsCount == 1)
        XCTAssertEqual(roomProxyMock.getMemberUserIDReceivedUserID, "bob")
    }
    
    // MARK: - Sending

    func testRetrySend() async throws {
        let timelineController = MockRoomTimelineController()
        let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxyMock,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)

        viewModel.context.send(viewAction: .retrySend(itemID: .init(timelineID: UUID().uuidString, transactionID: "test retry send id")))
        
        try? await Task.sleep(for: .milliseconds(100))
        
        XCTAssert(roomProxyMock.retrySendTransactionIDCallsCount == 1)
        XCTAssert(roomProxyMock.retrySendTransactionIDReceivedInvocations == ["test retry send id"])
    }

    func testRetrySendNoTransactionID() async {
        let timelineController = MockRoomTimelineController()
        let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxyMock,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)

        viewModel.context.send(viewAction: .retrySend(itemID: .random))
        
        try? await Task.sleep(for: .milliseconds(100))
        
        XCTAssert(roomProxyMock.retrySendTransactionIDCallsCount == 0)
    }

    func testCancelSend() async {
        let timelineController = MockRoomTimelineController()
        let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxyMock,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)

        viewModel.context.send(viewAction: .cancelSend(itemID: .init(timelineID: UUID().uuidString, transactionID: "test cancel send id")))
        
        try? await Task.sleep(for: .milliseconds(100))
        
        XCTAssert(roomProxyMock.cancelSendTransactionIDCallsCount == 1)
        XCTAssert(roomProxyMock.cancelSendTransactionIDReceivedInvocations == ["test cancel send id"])
    }

    func testCancelSendNoTransactionID() async {
        let timelineController = MockRoomTimelineController()
        let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxyMock,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)

        viewModel.context.send(viewAction: .cancelSend(itemID: .random))

        try? await Task.sleep(for: .milliseconds(100))
        
        XCTAssert(roomProxyMock.cancelSendTransactionIDCallsCount == 0)
    }
    
    // MARK: - Read Receipts
    
    // swiftlint:disable force_unwrapping
    func testSendReadReceipt() async throws {
        // Given a room with only text items in the timeline
        let items = [TextRoomTimelineItem(eventID: "t1"),
                     TextRoomTimelineItem(eventID: "t2"),
                     TextRoomTimelineItem(eventID: "t3")]
        let (viewModel, roomProxy, _, notificationCenter) = readReceiptsConfiguration(with: items)
        
        // When sending a read receipt for the last item.
        viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(items.last!.id))
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the receipt should be sent.
        XCTAssertEqual(roomProxy.sendReadReceiptForCalled, true)
        XCTAssertEqual(roomProxy.sendReadReceiptForReceivedEventID, "t3")
        
        // And the notifications should be cleared.
        XCTAssertEqual(notificationCenter.postNameObjectReceivedArguments?.aName, .roomMarkedAsRead)
        let roomID = notificationCenter.postNameObjectReceivedArguments?.anObject as? String
        XCTAssertEqual(roomID, roomProxy.id)
    }
    
    func testSendMoreReadReceipts() async throws {
        // Given a room with only text items in the timeline that are all read.
        let items = [TextRoomTimelineItem(eventID: "t1"),
                     TextRoomTimelineItem(eventID: "t2"),
                     TextRoomTimelineItem(eventID: "t3")]
        let (viewModel, roomProxy, timelineController, _) = readReceiptsConfiguration(with: items)
        viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(items.last!.id))
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(roomProxy.sendReadReceiptForCallsCount, 1)
        XCTAssertEqual(roomProxy.sendReadReceiptForReceivedEventID, "t3")
        
        // When sending a receipt for the first item in the timeline.
        viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(items.first!.id))
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the request should be ignored.
        XCTAssertEqual(roomProxy.sendReadReceiptForCallsCount, 1)
        XCTAssertEqual(roomProxy.sendReadReceiptForReceivedEventID, "t3")
        
        // When a new message is received and marked as read.
        let newMessage = TextRoomTimelineItem(eventID: "t4")
        timelineController.timelineItems.append(newMessage)
        timelineController.callbacks.send(.updatedTimelineItems)
        try await Task.sleep(for: .milliseconds(100))
        
        viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(newMessage.id))
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the request should be made.
        XCTAssertEqual(roomProxy.sendReadReceiptForCallsCount, 2)
        XCTAssertEqual(roomProxy.sendReadReceiptForReceivedEventID, "t4")
    }
    
    func testSendReadReceiptWithoutEvents() async throws {
        // Given a room with only virtual items.
        let items = [SeparatorRoomTimelineItem(timelineID: "v1"),
                     SeparatorRoomTimelineItem(timelineID: "v2"),
                     SeparatorRoomTimelineItem(timelineID: "v3")]
        let (viewModel, roomProxy, _, _) = readReceiptsConfiguration(with: items)
        
        // When sending a read receipt for the last item.
        viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(items.last!.id))
        try await Task.sleep(for: .milliseconds(100))
        
        // Then nothing should be sent.
        XCTAssertEqual(roomProxy.sendReadReceiptForCalled, false)
    }
    
    func testSendReadReceiptVirtualLast() async throws {
        // Given a room where the last event is a virtual item.
        let items: [RoomTimelineItemProtocol] = [TextRoomTimelineItem(eventID: "t1"),
                                                 TextRoomTimelineItem(eventID: "t2"),
                                                 SeparatorRoomTimelineItem(timelineID: "v3")]
        let (viewModel, roomProxy, _, _) = readReceiptsConfiguration(with: items)
        
        // When sending a read receipt for the last item.
        viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(items.last!.id))
        try await Task.sleep(for: .milliseconds(100))
        
        // Then a read receipt should be sent for the item before it.
        XCTAssertEqual(roomProxy.sendReadReceiptForCalled, true)
        XCTAssertEqual(roomProxy.sendReadReceiptForReceivedEventID, "t2")
    }
    
    func testSendReadReceiptMultipleRequests() async throws {
        // Given a room where the last event is a virtual item which was already read.
        let items: [RoomTimelineItemProtocol] = [TextRoomTimelineItem(eventID: "t1"),
                                                 TextRoomTimelineItem(eventID: "t2"),
                                                 SeparatorRoomTimelineItem(timelineID: "v3")]
        let (viewModel, roomProxy, _, _) = readReceiptsConfiguration(with: items)
        viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(items.last!.id))
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(roomProxy.sendReadReceiptForCallsCount, 1)
        XCTAssertEqual(roomProxy.sendReadReceiptForReceivedEventID, "t2")
        
        // When sending the same receipt again
        viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(items.last!.id))
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the second call should be ignored.
        XCTAssertEqual(roomProxy.sendReadReceiptForCallsCount, 1)
    }
    
    // swiftlint:enable force_unwrapping
    // swiftlint:disable:next large_tuple
    private func readReceiptsConfiguration(with items: [RoomTimelineItemProtocol]) -> (RoomScreenViewModel,
                                                                                       RoomProxyMock,
                                                                                       MockRoomTimelineController,
                                                                                       NotificationCenterMock) {
        let notificationCenter = NotificationCenterMock()
        let roomProxy = RoomProxyMock(with: .init(displayName: ""))
        let timelineController = MockRoomTimelineController()
        
        roomProxy.sendReadReceiptForReturnValue = .success(())
        roomProxy.underlyingHasUnreadNotifications = true
        timelineController.timelineItems = items
        timelineController.roomProxy = roomProxy

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxy,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock,
                                            notificationCenterProtocol: notificationCenter)
        
        return (viewModel, roomProxy, timelineController, notificationCenter)
    }
}

private extension TextRoomTimelineItem {
    init(text: String, sender: String, addReactions: Bool = false) {
        let reactions = addReactions ? [AggregatedReaction(accountOwnerID: "bob", key: "🦄", senders: [ReactionSender(senderID: sender, timestamp: Date())])] : []
        self.init(id: .random,
                  timestamp: "10:47 am",
                  isOutgoing: sender == "bob",
                  isEditable: sender == "bob",
                  isThreaded: false,
                  sender: .init(id: "@\(sender):server.com", displayName: sender),
                  content: .init(body: text),
                  properties: RoomTimelineItemProperties(reactions: reactions))
    }
}

private extension SeparatorRoomTimelineItem {
    init(timelineID: String) {
        self.init(id: .init(timelineID: timelineID), text: "")
    }
}

private extension TextRoomTimelineItem {
    init(eventID: String) {
        self.init(id: .init(timelineID: UUID().uuidString, eventID: eventID),
                  timestamp: "",
                  isOutgoing: false,
                  isEditable: false,
                  isThreaded: false,
                  sender: .init(id: ""),
                  content: .init(body: "Hello, World!"))
    }
}

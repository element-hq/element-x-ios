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
import XCTest

@MainActor
class RoomScreenViewModelTests: XCTestCase {
    var userIndicatorControllerMock: UserIndicatorControllerMock!

    override func setUp() async throws {
        userIndicatorControllerMock = UserIndicatorControllerMock.default
    }

    override func tearDown() async throws {
        userIndicatorControllerMock = nil
    }

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
        viewModel.callback = { action in
            switch action {
            case .displayRoomMemberDetails(let member):
                XCTAssert(member === roomMemberMock)
            default:
                XCTFail("Did not received the expected action")
            }
            expectation.fulfill()
        }

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
                                            
        viewModel.callback = { action in
            switch action {
            case .displayRoomMemberDetails(let member):
                XCTAssert(member === roomMemberMock)
                expectation.fulfill()
            default:
                XCTFail("Did not received the expected action")
            }
        }

        // Test
        viewModel.context.send(viewAction: .tappedOnUser(userID: "bob"))
        await fulfillment(of: [expectation])
        
        XCTAssert(userIndicatorControllerMock.submitIndicatorDelayCallsCount == 1)
        XCTAssert(userIndicatorControllerMock.retractIndicatorWithIdCallsCount == 1)
        XCTAssert(roomProxyMock.getMemberUserIDCallsCount == 1)
        XCTAssertEqual(roomProxyMock.getMemberUserIDReceivedUserID, "bob")
    }

    func testGoToUserDetailsFailure() async {
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
        viewModel.callback = { _ in
            XCTFail("Should not receive any action")
        }

        // Test
        viewModel.context.send(viewAction: .tappedOnUser(userID: "bob"))
        await viewModel.context.nextViewState()
        XCTAssertFalse(viewModel.state.bindings.alertInfo.isNil)
        XCTAssert(roomProxyMock.getMemberUserIDCallsCount == 1)
        XCTAssertEqual(roomProxyMock.getMemberUserIDReceivedUserID, "bob")
    }

    func testRetrySend() async {
        // Setup
        let timelineController = MockRoomTimelineController()
        let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxyMock,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)

        // Test
        viewModel.context.send(viewAction: .retrySend(itemID: .init(timelineID: UUID().uuidString, transactionID: "test retry send id")))
        await Task.yield()
        try? await Task.sleep(for: .microseconds(500))
        XCTAssert(roomProxyMock.retrySendTransactionIDCallsCount == 1)
        XCTAssert(roomProxyMock.retrySendTransactionIDReceivedInvocations == ["test retry send id"])
    }

    func testRetrySendNoTransactionID() async {
        // Setup
        let timelineController = MockRoomTimelineController()
        let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxyMock,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)

        // Test
        viewModel.context.send(viewAction: .retrySend(itemID: .random))
        await Task.yield()
        XCTAssert(roomProxyMock.retrySendTransactionIDCallsCount == 0)
    }

    func testCancelSend() async {
        // Setup
        let timelineController = MockRoomTimelineController()
        let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxyMock,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)

        // Test
        viewModel.context.send(viewAction: .cancelSend(itemID: .init(timelineID: UUID().uuidString, transactionID: "test cancel send id")))
        try? await Task.sleep(for: .microseconds(500))
        XCTAssert(roomProxyMock.cancelSendTransactionIDCallsCount == 1)
        XCTAssert(roomProxyMock.cancelSendTransactionIDReceivedInvocations == ["test cancel send id"])
    }

    func testCancelSendNoTransactionID() async {
        // Setup
        let timelineController = MockRoomTimelineController()
        let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxyMock,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock)

        // Test
        viewModel.context.send(viewAction: .cancelSend(itemID: .random))
        await Task.yield()
        XCTAssert(roomProxyMock.cancelSendTransactionIDCallsCount == 0)
    }

    func testMarkAsRead() async throws {
        // Setup
        let notificationCenterMock = NotificationCenterMock()
        let timelineController = MockRoomTimelineController()
        let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))

        let viewModel = RoomScreenViewModel(timelineController: timelineController,
                                            mediaProvider: MockMediaProvider(),
                                            roomProxy: roomProxyMock,
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: userIndicatorControllerMock,
                                            notificationCenterProtocol: notificationCenterMock)

        viewModel.context.send(viewAction: .markRoomAsRead)
        try await Task.sleep(for: .microseconds(100))
        XCTAssertEqual(notificationCenterMock.postNameObjectReceivedArguments?.aName, .roomMarkedAsRead)
        let roomID = notificationCenterMock.postNameObjectReceivedArguments?.anObject as? String
        XCTAssertEqual(roomID, roomProxyMock.id)
    }
}

private extension TextRoomTimelineItem {
    init(text: String, sender: String, addReactions: Bool = false) {
        let reactions = addReactions ? [AggregatedReaction(accountOwnerID: "bob", key: "🦄", senders: [ReactionSender(senderID: sender, timestamp: Date())])] : []
        self.init(id: .random,
                  timestamp: "10:47 am",
                  isOutgoing: sender == "bob",
                  isEditable: sender == "bob",
                  sender: .init(id: "@\(sender):server.com", displayName: sender),
                  content: .init(body: text),
                  properties: RoomTimelineItemProperties(reactions: reactions))
    }
}

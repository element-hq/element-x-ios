//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
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
        let timelineController = MockTimelineController()
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
        let timelineController = MockTimelineController()
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
        let timelineController = MockTimelineController()
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
        let timelineController = MockTimelineController()
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
        let timelineController = MockTimelineController()
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
        let timelineController = MockTimelineController()
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
        let timelineController = MockTimelineController()
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
        let timelineController = MockTimelineController()
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
    
    func testInitialFocusViewState() {
        let timelineController = MockTimelineController()
        
        let viewModel = makeViewModel(focussedEventID: "t10", timelineController: timelineController)
        XCTAssertEqual(viewModel.context.viewState.timelineState.focussedEvent, .init(eventID: "t10", appearance: .immediate))
    }
    
    // MARK: - Read Receipts
    
    func testSendReadReceipt() async throws {
        // Given a room with only text items in the timeline
        let items = [TextRoomTimelineItem(eventID: "t1"),
                     TextRoomTimelineItem(eventID: "t2"),
                     TextRoomTimelineItem(eventID: "t3")]
        let (viewModel, _, timelineProxy, _) = readReceiptsConfiguration(with: items)
        
        // When sending a read receipt for the last item.
        try viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(XCTUnwrap(items.last?.id)))
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the receipt should be sent.
        XCTAssertEqual(timelineProxy.sendReadReceiptForTypeCalled, true)
        let arguments = timelineProxy.sendReadReceiptForTypeReceivedArguments
        XCTAssertEqual(arguments?.eventID, "t3")
        XCTAssertEqual(arguments?.type, .read)
    }
    
    func testSendReadReceiptWithoutEvents() async throws {
        // Given a room with only virtual items.
        let items = [SeparatorRoomTimelineItem(uniqueID: .init("v1")),
                     SeparatorRoomTimelineItem(uniqueID: .init("v2")),
                     SeparatorRoomTimelineItem(uniqueID: .init("v3"))]
        let (viewModel, _, timelineProxy, _) = readReceiptsConfiguration(with: items)
        
        // When sending a read receipt for the last item.
        try viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(XCTUnwrap(items.last?.id)))
        try await Task.sleep(for: .milliseconds(100))
        
        // Then nothing should be sent.
        XCTAssertEqual(timelineProxy.sendReadReceiptForTypeCalled, false)
    }
    
    func testSendReadReceiptVirtualLast() async throws {
        // Given a room where the last event is a virtual item.
        let items: [RoomTimelineItemProtocol] = [TextRoomTimelineItem(eventID: "t1"),
                                                 TextRoomTimelineItem(eventID: "t2"),
                                                 SeparatorRoomTimelineItem(uniqueID: .init("v3"))]
        let (viewModel, _, _, _) = readReceiptsConfiguration(with: items)
        
        // When sending a read receipt for the last item.
        try viewModel.context.send(viewAction: .sendReadReceiptIfNeeded(XCTUnwrap(items.last?.id)))
        try await Task.sleep(for: .milliseconds(100))
    }
    
    // swiftlint:disable:next large_tuple
    private func readReceiptsConfiguration(with items: [RoomTimelineItemProtocol]) -> (TimelineViewModel,
                                                                                       JoinedRoomProxyMock,
                                                                                       TimelineProxyMock,
                                                                                       MockTimelineController) {
        let roomProxy = JoinedRoomProxyMock(.init(name: ""))
        
        let timelineProxy = TimelineProxyMock()
        
        roomProxy.timeline = timelineProxy
        let timelineController = MockTimelineController()
        
        timelineProxy.sendReadReceiptForTypeReturnValue = .success(())
        
        timelineController.timelineItems = items
        timelineController.roomProxy = roomProxy

        let viewModel = TimelineViewModel(roomProxy: roomProxy,
                                          timelineController: timelineController,
                                          userSession: UserSessionMock(.init()),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          userIndicatorController: userIndicatorControllerMock,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics,
                                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                          linkMetadataProvider: LinkMetadataProvider(),
                                          timelineControllerFactory: TimelineControllerFactoryMock(.init()))
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
        let timelineController = MockTimelineController()
        timelineController.timelineItems = [message]
        let viewModel = TimelineViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "", members: [RoomMemberProxyMock.mockAlice, RoomMemberProxyMock.mockCharlie])),
                                          timelineController: timelineController,
                                          userSession: UserSessionMock(.init()),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          userIndicatorController: userIndicatorControllerMock,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics,
                                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                          linkMetadataProvider: LinkMetadataProvider(),
                                          timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.bindings.readReceiptsSummaryInfo?.orderedReceipts == receipts
        }
        
        viewModel.context.send(viewAction: .displayReadReceipts(itemID: id))
        try await deferred.fulfill()
    }
    
    func testShowManageUserAsAdmin() async throws {
        let viewModel = TimelineViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "",
                                                                               members: [RoomMemberProxyMock.mockAdmin,
                                                                                         RoomMemberProxyMock.mockAlice],
                                                                               ownUserID: RoomMemberProxyMock.mockAdmin.userID)),
                                          timelineController: MockTimelineController(),
                                          userSession: UserSessionMock(.init()),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          userIndicatorController: userIndicatorControllerMock,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics,
                                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                          linkMetadataProvider: LinkMetadataProvider(),
                                          timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.canCurrentUserKick && value.canCurrentUserBan
        }
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.bindings.manageMemberViewModel != nil
        }
        
        viewModel.context.send(viewAction: .tappedOnSenderDetails(sender: .init(with: RoomMemberProxyMock.mockAlice)))
        try await deferred.fulfill()
        
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.id, RoomMemberProxyMock.mockAlice.userID)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.permissions.canBan, true)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.permissions.canKick, true)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.isKickDisabled, false)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.isBanUnbanDisabled, false)
    }
    
    func testShowDetailsForAnAdmin() async throws {
        let viewModel = TimelineViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "",
                                                                               members: [RoomMemberProxyMock.mockAdmin,
                                                                                         RoomMemberProxyMock.mockAlice],
                                                                               ownUserID: RoomMemberProxyMock.mockAlice.userID)),
                                          timelineController: MockTimelineController(),
                                          userSession: UserSessionMock(.init()),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          userIndicatorController: userIndicatorControllerMock,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics,
                                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                          linkMetadataProvider: LinkMetadataProvider(),
                                          timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        
        var deferredState = deferFulfillment(viewModel.context.$viewState) { value in
            !value.canCurrentUserKick && !value.canCurrentUserBan
        }
        
        try await deferredState.fulfill()
        
        deferredState = deferFulfillment(viewModel.context.$viewState) { value in
            value.bindings.manageMemberViewModel != nil
        }
        
        viewModel.context.send(viewAction: .tappedOnSenderDetails(sender: .init(with: RoomMemberProxyMock.mockAdmin)))
        try await deferredState.fulfill()
        
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.permissions.canBan, false)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.permissions.canKick, false)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.isKickDisabled, true)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.isBanUnbanDisabled, true)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.id, RoomMemberProxyMock.mockAdmin.userID)
    }
    
    func testShowDetailsForABannedUser() async throws {
        let viewModel = TimelineViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "",
                                                                               members: [RoomMemberProxyMock.mockAdmin,
                                                                                         RoomMemberProxyMock.mockBanned[0]],
                                                                               ownUserID: RoomMemberProxyMock.mockAdmin.userID)),
                                          timelineController: MockTimelineController(),
                                          userSession: UserSessionMock(.init()),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          userIndicatorController: userIndicatorControllerMock,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics,
                                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                          linkMetadataProvider: LinkMetadataProvider(),
                                          timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        
        var deferredState = deferFulfillment(viewModel.context.$viewState) { value in
            value.canCurrentUserKick && value.canCurrentUserBan
        }
        
        try await deferredState.fulfill()
        
        deferredState = deferFulfillment(viewModel.context.$viewState) { value in
            value.bindings.manageMemberViewModel != nil
        }
        
        viewModel.context.send(viewAction: .tappedOnSenderDetails(sender: .init(with: RoomMemberProxyMock.mockBanned[0])))
        try await deferredState.fulfill()
        
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.permissions.canBan, true)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.permissions.canKick, true)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.isKickDisabled, true)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.isBanUnbanDisabled, false)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.state.isMemberBanned, true)
        XCTAssertEqual(viewModel.context.manageMemberViewModel?.id, RoomMemberProxyMock.mockBanned[0].userID)
    }
    
    // MARK: - Pins
    
    func testPinnedEvents() async throws {
        var configuration = JoinedRoomProxyMockConfiguration(name: "",
                                                             pinnedEventIDs: .init(["test1"]))
        let roomProxyMock = JoinedRoomProxyMock(configuration)
        let infoSubject = CurrentValueSubject<RoomInfoProxyProtocol, Never>(RoomInfoProxyMock(configuration))
        roomProxyMock.underlyingInfoPublisher = infoSubject.asCurrentValuePublisher()
        
        let viewModel = TimelineViewModel(roomProxy: roomProxyMock,
                                          timelineController: MockTimelineController(),
                                          userSession: UserSessionMock(.init()),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          userIndicatorController: userIndicatorControllerMock,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics,
                                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                          linkMetadataProvider: LinkMetadataProvider(),
                                          timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        XCTAssertEqual(configuration.pinnedEventIDs, viewModel.context.viewState.pinnedEventIDs)
        
        configuration.pinnedEventIDs = ["test1", "test2"]
        let deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.pinnedEventIDs == ["test1", "test2"]
        }
        infoSubject.send(RoomInfoProxyMock(configuration))
        try await deferred.fulfill()
    }
    
    func testCanUserPinEvents() async throws {
        let configuration = JoinedRoomProxyMockConfiguration(name: "",
                                                             powerLevelsConfiguration: .init(canUserPin: true))
        let roomProxyMock = JoinedRoomProxyMock(configuration)
        let infoSubject = CurrentValueSubject<RoomInfoProxyProtocol, Never>(RoomInfoProxyMock(configuration))
        roomProxyMock.underlyingInfoPublisher = infoSubject.asCurrentValuePublisher()
        
        let viewModel = TimelineViewModel(roomProxy: roomProxyMock,
                                          timelineController: MockTimelineController(),
                                          userSession: UserSessionMock(.init()),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          userIndicatorController: userIndicatorControllerMock,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics,
                                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                          linkMetadataProvider: LinkMetadataProvider(),
                                          timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { value in
            value.canCurrentUserPin
        }
        try await deferred.fulfill()
        
        let powerLevelsProxyMock = RoomPowerLevelsProxyMock(configuration: .init())
        powerLevelsProxyMock.canUserPinOrUnpinUserIDReturnValue = .success(false)
        powerLevelsProxyMock.canOwnUserPinOrUnpinReturnValue = false
        roomProxyMock.powerLevelsReturnValue = .success(powerLevelsProxyMock)
        
        let roomInfoProxyMock = RoomInfoProxyMock(configuration)
        roomInfoProxyMock.powerLevels = powerLevelsProxyMock
        
        deferred = deferFulfillment(viewModel.context.$viewState) { value in
            !value.canCurrentUserPin
        }
        infoSubject.send(roomInfoProxyMock)
        try await deferred.fulfill()
    }
    
    // MARK: - Tap Actions
    
    func testTapSendInfoEncryptionAuthentictyDisplaysAlert() {
        // Given a room with an event whose authenticity could not be verified
        let items = [TextRoomTimelineItem(eventID: "t1", encryptionAuthenticity: .verificationViolation(color: .red))]
        let timelineController = MockTimelineController()
        timelineController.timelineItems = items
        let viewModel = makeViewModel(timelineController: timelineController)
        
        XCTAssertNil(viewModel.state.bindings.alertInfo)
        
        viewModel.process(viewAction: .itemSendInfoTapped(itemID: items[0].id))
        
        XCTAssertEqual(viewModel.state.bindings.alertInfo?.title, "Encrypted by a previously-verified user.")
    }
    
    func testTapSendInfoEncryptionForwarderDisplaysAlert() {
        // Given a room with an event whose key was forwarded
        let items = [TextRoomTimelineItem(eventID: "t1", keyForwarder: .test)]
        let timelineController = MockTimelineController()
        timelineController.timelineItems = items
        let viewModel = makeViewModel(timelineController: timelineController)
        
        XCTAssertNil(viewModel.state.bindings.alertInfo)
        
        viewModel.process(viewAction: .itemSendInfoTapped(itemID: items[0].id))
        
        XCTAssertEqual(viewModel.state.bindings.alertInfo?.title, "alice (@alice:matrix.org) shared this message since you were not in the room when it was sent.")
    }
    
    // MARK: - Helpers
    
    private func makeViewModel(roomProxy: JoinedRoomProxyProtocol? = nil,
                               focussedEventID: String? = nil,
                               timelineController: TimelineControllerProtocol) -> TimelineViewModel {
        TimelineViewModel(roomProxy: roomProxy ?? JoinedRoomProxyMock(.init(name: "")),
                          focussedEventID: focussedEventID,
                          timelineController: timelineController,
                          userSession: UserSessionMock(.init()),
                          mediaPlayerProvider: MediaPlayerProviderMock(),
                          userIndicatorController: userIndicatorControllerMock,
                          appMediator: AppMediatorMock.default,
                          appSettings: ServiceLocator.shared.settings,
                          analyticsService: ServiceLocator.shared.analytics,
                          emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                          linkMetadataProvider: LinkMetadataProvider(),
                          timelineControllerFactory: TimelineControllerFactoryMock(.init()))
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
                  sender: .init(id: "@\(sender):server.com", displayName: sender),
                  content: .init(body: text),
                  properties: RoomTimelineItemProperties(reactions: reactions, orderedReadReceipts: addReadReceipts))
    }
}

private extension SeparatorRoomTimelineItem {
    init(uniqueID: TimelineItemIdentifier.UniqueID) {
        self.init(id: .virtual(uniqueID: uniqueID), timestamp: .mock)
    }
}

private extension TextRoomTimelineItem {
    init(eventID: String) {
        self.init(id: .event(uniqueID: .init(UUID().uuidString), eventOrTransactionID: .eventID(eventID)),
                  timestamp: .mock,
                  isOutgoing: false,
                  isEditable: false,
                  canBeRepliedTo: true,
                  sender: .init(id: ""),
                  content: .init(body: "Hello, World!"))
    }
}

private extension TextRoomTimelineItem {
    init(eventID: String, keyForwarder: TimelineItemKeyForwarder) {
        self.init(id: .event(uniqueID: .init(UUID().uuidString), eventOrTransactionID: .eventID(eventID)),
                  timestamp: .mock,
                  isOutgoing: false,
                  isEditable: false,
                  canBeRepliedTo: true,
                  sender: .init(id: ""),
                  content: .init(body: "Hello, World!"),
                  properties: RoomTimelineItemProperties(encryptionForwarder: keyForwarder))
    }
}

private extension TextRoomTimelineItem {
    init(eventID: String, encryptionAuthenticity: EncryptionAuthenticity) {
        self.init(id: .event(uniqueID: .init(UUID().uuidString), eventOrTransactionID: .eventID(eventID)),
                  timestamp: .mock,
                  isOutgoing: false,
                  isEditable: false,
                  canBeRepliedTo: true,
                  sender: .init(id: ""),
                  content: .init(body: "Hello, World!"),
                  properties: RoomTimelineItemProperties(encryptionAuthenticity: encryptionAuthenticity))
    }
}

private extension TimelineItemSender {
    init(with proxy: RoomMemberProxyMock) {
        self.init(id: proxy.userID,
                  displayName: proxy.displayName ?? "",
                  isDisplayNameAmbiguous: false,
                  avatarURL: proxy.avatarURL)
    }
}

private extension TimelineItemKeyForwarder {
    static var test: TimelineItemKeyForwarder {
        TimelineItemKeyForwarder(id: "@alice:matrix.org", displayName: "alice")
    }
}

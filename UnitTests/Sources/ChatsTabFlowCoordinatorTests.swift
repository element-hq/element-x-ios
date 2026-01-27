//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import XCTest

@MainActor
class ChatsTabFlowCoordinatorTests: XCTestCase {
    var clientProxy: ClientProxyMock!
    var timelineControllerFactory: TimelineControllerFactoryMock!
    var chatsTabFlowCoordinator: ChatsTabFlowCoordinator!
    var splitCoordinator: NavigationSplitCoordinator!
    var notificationManager: NotificationManagerMock!
    let stateMachineFactory = PublishedStateMachineFactory()
    
    var cancellables = Set<AnyCancellable>()
    
    var detailCoordinator: CoordinatorProtocol? {
        splitCoordinator?.detailCoordinator
    }

    var detailNavigationStack: NavigationStackCoordinator? {
        detailCoordinator as? NavigationStackCoordinator
    }
    
    override func setUp() async throws {
        cancellables.removeAll()
        clientProxy = ClientProxyMock(.init(userID: "hi@bob", roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))))
        timelineControllerFactory = TimelineControllerFactoryMock(.init())
        
        splitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator(hideBrandChrome: false))
        
        notificationManager = NotificationManagerMock()
        
        let flowParameters = CommonFlowParameters(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                  bugReportService: BugReportServiceMock(.init()),
                                                  elementCallService: ElementCallServiceMock(.init()),
                                                  timelineControllerFactory: timelineControllerFactory,
                                                  emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  appMediator: AppMediatorMock.default,
                                                  appSettings: ServiceLocator.shared.settings,
                                                  appHooks: AppHooks(),
                                                  analytics: ServiceLocator.shared.analytics,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  notificationManager: notificationManager,
                                                  stateMachineFactory: stateMachineFactory)
        chatsTabFlowCoordinator = ChatsTabFlowCoordinator(isNewLogin: false,
                                                          navigationSplitCoordinator: splitCoordinator,
                                                          flowParameters: flowParameters)
        
        let deferred = deferFulfillment(stateMachineFactory.chatsTabFlowStatePublisher) { $0 == .roomList(detailState: nil) }
        chatsTabFlowCoordinator.start()
        try await deferred.fulfill()
    }
    
    func testRoomPresentation() async throws {
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(detailState: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "2", via: []), expectedState: .roomList(detailState: .room(roomID: "2")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(detailState: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        XCTAssertEqual(notificationManager.removeDeliveredMessageNotificationsForReceivedInvocations, ["1", "1", "2"])
    }
    
    func testRoomAliasPresentation() async throws {
        clientProxy.resolveRoomAliasReturnValue = .success(.init(roomId: "1", servers: []))
        
        try await process(route: .roomAlias("#alias:matrix.org"), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(detailState: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        clientProxy.resolveRoomAliasReturnValue = .success(.init(roomId: "2", servers: []))
        
        try await process(route: .room(roomID: "2", via: []), expectedState: .roomList(detailState: .room(roomID: "2")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(detailState: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        XCTAssertEqual(notificationManager.removeDeliveredMessageNotificationsForReceivedInvocations, ["1", "1", "2"])
    }
    
    func testRoomDetailsPresentation() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(detailState: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
    }
    
    func testStackUnwinding() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "2", via: []), expectedState: .roomList(detailState: .room(roomID: "2")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testNoOp() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        let unexpectedFulfillment = deferFailure(stateMachineFactory.chatsTabFlowStatePublisher, timeout: 1) { _ in true }
        chatsTabFlowCoordinator.handleAppRoute(.roomDetails(roomID: "1"), animated: true)
        try await unexpectedFulfillment.fulfill()
        
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testSwitchToDifferentDetails() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomDetails(roomID: "2"), expectedState: .roomList(detailState: .room(roomID: "2")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testPushDetails() async throws {
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        let unexpectedFulfillment = deferFailure(stateMachineFactory.chatsTabFlowStatePublisher, timeout: 1) { _ in true }
        chatsTabFlowCoordinator.handleAppRoute(.roomDetails(roomID: "1"), animated: true)
        try await unexpectedFulfillment.fulfill()
        
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 1)
        XCTAssertTrue(detailNavigationStack?.stackCoordinators.first is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testReplaceDetailsWithTimeline() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testUserProfileClearsStack() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertNil(splitCoordinator?.sheetCoordinator)
        
        try await process(route: .userProfile(userID: "alice"), expectedState: .userProfileScreen)
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        guard let sheetStackCoordinator = splitCoordinator?.sheetCoordinator as? NavigationStackCoordinator else {
            XCTFail("There should be a navigation stack presented as a sheet.")
            return
        }
        XCTAssertTrue(sheetStackCoordinator.rootCoordinator is UserProfileScreenCoordinator)
    }
    
    func testRoomClearsStack() async throws {
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        
        chatsTabFlowCoordinator.handleAppRoute(.childRoom(roomID: "2", via: []), animated: true)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 1)
        XCTAssertTrue(detailNavigationStack?.stackCoordinators.first is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "3", via: []), expectedState: .roomList(detailState: .room(roomID: "3")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testEventRoutes() async throws {
        // A regular event route should set its room as the root of the stack and focus on the event.
        try await process(route: .event(eventID: "1", roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount, 1)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments?.initialFocussedEventID, "1")
        
        // A child event route should push a new room screen onto the stack and focus on the event.
        chatsTabFlowCoordinator.handleAppRoute(.childEvent(eventID: "2", roomID: "2", via: []), animated: true)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 1)
        XCTAssertTrue(detailNavigationStack?.stackCoordinators.first is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount, 2)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments?.initialFocussedEventID, "2")
        
        // A subsequent regular event route should clear the stack and set the new room as the root of the stack.
        try await process(route: .event(eventID: "3", roomID: "3", via: []), expectedState: .roomList(detailState: .room(roomID: "3")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount, 3)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments?.initialFocussedEventID, "3")
        
        // A regular event route for the same room should set a new instance of the room as the root of the stack.
        try await process(route: .event(eventID: "4", roomID: "3", via: []), expectedState: .roomList(detailState: .room(roomID: "3")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount, 4)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments?.initialFocussedEventID, "4",
                       "A new timeline should be created for the same room ID, so that the screen isn't stale while loading.")
    }
    
    func testShareMediaRouteWithRoom() async throws {
        try await process(route: .event(eventID: "1", roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        
        let sharePayload: ShareExtensionPayload = .mediaFiles(roomID: "2", mediaFiles: [.init(url: .picturesDirectory, suggestedName: nil)])
        try await process(route: .share(sharePayload),
                          expectedState: .roomList(detailState: .room(roomID: "2")))
        
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertTrue((splitCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is MediaUploadPreviewScreenCoordinator)
    }
    
    func testShareTextRouteWithRoom() async throws {
        try await process(route: .event(eventID: "1", roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        
        let sharePayload: ShareExtensionPayload = .text(roomID: "2", text: "Important text")
        try await process(route: .share(sharePayload),
                          expectedState: .roomList(detailState: .room(roomID: "2")))
        
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNil(splitCoordinator?.sheetCoordinator, "The media upload sheet shouldn't be shown when sharing text.")
    }
    
    // MARK: - Private
    
    private func process(route: AppRoute, expectedState: ChatsTabFlowCoordinatorStateMachine.State) async throws {
        // Sometimes the state machine's state changes before the coordinators have updated the stack.
        let delayedPublisher = stateMachineFactory.chatsTabFlowStatePublisher.delay(for: .milliseconds(100), scheduler: DispatchQueue.main)
        
        let deferred = deferFulfillment(delayedPublisher) { $0 == expectedState }
        chatsTabFlowCoordinator.handleAppRoute(route, animated: true)
        try await deferred.fulfill()
    }
}

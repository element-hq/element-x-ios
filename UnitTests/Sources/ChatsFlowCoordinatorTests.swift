//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

import Combine
@testable import ElementX

@MainActor
class ChatsFlowCoordinatorTests: XCTestCase {
    var clientProxy: ClientProxyMock!
    var timelineControllerFactory: TimelineControllerFactoryMock!
    var chatsFlowCoordinator: ChatsFlowCoordinator!
    var splitCoordinator: NavigationSplitCoordinator!
    var notificationManager: NotificationManagerMock!
    
    var cancellables = Set<AnyCancellable>()
    
    var detailCoordinator: CoordinatorProtocol? { splitCoordinator?.detailCoordinator }
    var detailNavigationStack: NavigationStackCoordinator? { detailCoordinator as? NavigationStackCoordinator }
    
    override func setUp() async throws {
        cancellables.removeAll()
        clientProxy = ClientProxyMock(.init(userID: "hi@bob", roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))))
        timelineControllerFactory = TimelineControllerFactoryMock(.init())
        
        splitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator())
        
        notificationManager = NotificationManagerMock()
        
        chatsFlowCoordinator = ChatsFlowCoordinator(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                    navigationSplitCoordinator: splitCoordinator,
                                                    appLockService: AppLockServiceMock(),
                                                    bugReportService: BugReportServiceMock(.init()),
                                                    elementCallService: ElementCallServiceMock(.init()),
                                                    timelineControllerFactory: timelineControllerFactory,
                                                    appMediator: AppMediatorMock.default,
                                                    appSettings: ServiceLocator.shared.settings,
                                                    appHooks: AppHooks(),
                                                    analytics: ServiceLocator.shared.analytics,
                                                    notificationManager: notificationManager,
                                                    isNewLogin: false)
        
        let deferred = deferFulfillment(chatsFlowCoordinator.statePublisher) { $0 == .roomList(roomListSelectedRoomID: nil) }
        chatsFlowCoordinator.start()
        try await deferred.fulfill()
    }
    
    func testRoomPresentation() async throws {
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(roomListSelectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "2", via: []), expectedState: .roomList(roomListSelectedRoomID: "2"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(roomListSelectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        XCTAssertEqual(notificationManager.removeDeliveredMessageNotificationsForReceivedInvocations, ["1", "1", "2"])
    }
    
    func testRoomAliasPresentation() async throws {
        clientProxy.resolveRoomAliasReturnValue = .success(.init(roomId: "1", servers: []))
        
        try await process(route: .roomAlias("#alias:matrix.org"), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(roomListSelectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        clientProxy.resolveRoomAliasReturnValue = .success(.init(roomId: "2", servers: []))
        
        try await process(route: .room(roomID: "2", via: []), expectedState: .roomList(roomListSelectedRoomID: "2"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(roomListSelectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        XCTAssertEqual(notificationManager.removeDeliveredMessageNotificationsForReceivedInvocations, ["1", "1", "2"])
    }
    
    func testRoomDetailsPresentation() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(roomListSelectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
    }
    
    func testStackUnwinding() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "2", via: []), expectedState: .roomList(roomListSelectedRoomID: "2"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testNoOp() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        let unexpectedFulfillment = deferFailure(chatsFlowCoordinator.statePublisher, timeout: 1) { _ in true }
        chatsFlowCoordinator.handleAppRoute(.roomDetails(roomID: "1"), animated: true)
        try await unexpectedFulfillment.fulfill()
        
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testSwitchToDifferentDetails() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomDetails(roomID: "2"), expectedState: .roomList(roomListSelectedRoomID: "2"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testPushDetails() async throws {
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        let unexpectedFulfillment = deferFailure(chatsFlowCoordinator.statePublisher, timeout: 1) { _ in true }
        chatsFlowCoordinator.handleAppRoute(.roomDetails(roomID: "1"), animated: true)
        try await unexpectedFulfillment.fulfill()
        
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 1)
        XCTAssertTrue(detailNavigationStack?.stackCoordinators.first is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testReplaceDetailsWithTimeline() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testUserProfileClearsStack() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(roomListSelectedRoomID: "1"))
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
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        
        chatsFlowCoordinator.handleAppRoute(.childRoom(roomID: "2", via: []), animated: true)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 1)
        XCTAssertTrue(detailNavigationStack?.stackCoordinators.first is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "3", via: []), expectedState: .roomList(roomListSelectedRoomID: "3"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testEventRoutes() async throws {
        // A regular event route should set its room as the root of the stack and focus on the event.
        try await process(route: .event(eventID: "1", roomID: "1", via: []), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount, 1)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments?.initialFocussedEventID, "1")
        
        // A child event route should push a new room screen onto the stack and focus on the event.
        chatsFlowCoordinator.handleAppRoute(.childEvent(eventID: "2", roomID: "2", via: []), animated: true)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 1)
        XCTAssertTrue(detailNavigationStack?.stackCoordinators.first is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount, 2)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments?.initialFocussedEventID, "2")
        
        // A subsequent regular event route should clear the stack and set the new room as the root of the stack.
        try await process(route: .event(eventID: "3", roomID: "3", via: []), expectedState: .roomList(roomListSelectedRoomID: "3"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount, 3)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments?.initialFocussedEventID, "3")
        
        // A regular event route for the same room should set a new instance of the room as the root of the stack.
        try await process(route: .event(eventID: "4", roomID: "3", via: []), expectedState: .roomList(roomListSelectedRoomID: "3"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount, 4)
        XCTAssertEqual(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments?.initialFocussedEventID, "4",
                       "A new timeline should be created for the same room ID, so that the screen isn't stale while loading.")
    }
    
    func testShareMediaRouteWithoutRoom() async throws {
        try await process(route: .settings, expectedState: .settingsScreen(roomListSelectedRoomID: nil))
        XCTAssertTrue((splitCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is SettingsScreenCoordinator)
        
        let sharePayload: ShareExtensionPayload = .mediaFiles(roomID: nil, mediaFiles: [.init(url: .picturesDirectory, suggestedName: nil)])
        try await process(route: .share(sharePayload),
                          expectedState: .shareExtensionRoomList(sharePayload: sharePayload))
        
        XCTAssertTrue((splitCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is RoomSelectionScreenCoordinator)
    }
    
    func testShareMediaRouteWithRoom() async throws {
        try await process(route: .event(eventID: "1", roomID: "1", via: []), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        
        let sharePayload: ShareExtensionPayload = .mediaFiles(roomID: "2", mediaFiles: [.init(url: .picturesDirectory, suggestedName: nil)])
        try await process(route: .share(sharePayload),
                          expectedState: .roomList(roomListSelectedRoomID: "2"))
        
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertTrue((splitCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is MediaUploadPreviewScreenCoordinator)
    }
    
    func testShareTextRouteWithoutRoom() async throws {
        try await process(route: .settings, expectedState: .settingsScreen(roomListSelectedRoomID: nil))
        XCTAssertTrue((splitCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is SettingsScreenCoordinator)
        
        let sharePayload: ShareExtensionPayload = .text(roomID: nil, text: "Important Text")
        try await process(route: .share(sharePayload),
                          expectedState: .shareExtensionRoomList(sharePayload: sharePayload))
        
        XCTAssertTrue((splitCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is RoomSelectionScreenCoordinator)
    }
    
    func testShareTextRouteWithRoom() async throws {
        try await process(route: .event(eventID: "1", roomID: "1", via: []), expectedState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        
        let sharePayload: ShareExtensionPayload = .text(roomID: "2", text: "Important text")
        try await process(route: .share(sharePayload),
                          expectedState: .roomList(roomListSelectedRoomID: "2"))
        
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNil(splitCoordinator?.sheetCoordinator, "The media upload sheet shouldn't be shown when sharing text.")
    }
    
    // MARK: - Private
    
    private func process(route: AppRoute, expectedState: ChatsFlowCoordinatorStateMachine.State) async throws {
        // Sometimes the state machine's state changes before the coordinators have updated the stack.
        let delayedPublisher = chatsFlowCoordinator.statePublisher.delay(for: .milliseconds(100), scheduler: DispatchQueue.main)
        
        let deferred = deferFulfillment(delayedPublisher) { $0 == expectedState }
        chatsFlowCoordinator.handleAppRoute(route, animated: true)
        try await deferred.fulfill()
    }
}

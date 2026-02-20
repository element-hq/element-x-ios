//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import MatrixRustSDKMocks
import Testing

@MainActor
@Suite final class RoomFlowCoordinatorTests {
    var clientProxy: ClientProxyMock!
    var timelineControllerFactory: TimelineControllerFactoryMock!
    var roomFlowCoordinator: RoomFlowCoordinator!
    var navigationStackCoordinator: NavigationStackCoordinator!
    var cancellables = Set<AnyCancellable>()
    
    deinit {
        AppSettings.resetAllSettings()
    }
    
    @Test
    func roomPresentation() async throws {
        setupRoomFlowCoordinator()
        
        try await process(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        
        try await clearRoute(expectedActions: [.finished])
        #expect(navigationStackCoordinator.rootCoordinator == nil)
    }
    
    @Test
    func roomDetailsPresentation() async throws {
        setupRoomFlowCoordinator()
        
        try await process(route: .roomDetails(roomID: "1"))
        #expect(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        
        try await clearRoute(expectedActions: [.finished])
        #expect(navigationStackCoordinator.rootCoordinator == nil)
    }
    
    @Test
    func noOp() async throws {
        setupRoomFlowCoordinator()
        
        try await process(route: .roomDetails(roomID: "1"))
        #expect(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        let detailsCoordinator = navigationStackCoordinator.rootCoordinator
        
        roomFlowCoordinator.handleAppRoute(.roomDetails(roomID: "1"), animated: true)
        await Task.yield()
        
        #expect(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        #expect(navigationStackCoordinator.rootCoordinator === detailsCoordinator)
    }
    
    @Test
    func pushDetails() async throws {
        setupRoomFlowCoordinator()
        
        try await process(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        
        try await process(route: .roomDetails(roomID: "1"))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomDetailsScreenCoordinator)
    }
    
    @Test
    func childRoomFlow() async throws {
        setupRoomFlowCoordinator()
        
        try await process(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        
        try await process(route: .childRoom(roomID: "2", via: []))
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        
        try await process(route: .childRoom(roomID: "3", via: []))
        #expect(navigationStackCoordinator.stackCoordinators.count == 2)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.last is RoomScreenCoordinator)
        
        try await clearRoute(expectedActions: [.finished])
        #expect(navigationStackCoordinator.rootCoordinator == nil)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
    }
    
    /// Tests the child flow teardown in isolation of it's parent.
    @Test
    func childFlowTearDown() async throws {
        setupRoomFlowCoordinator(asChildFlow: true)
        navigationStackCoordinator.setRootCoordinator(BlankFormCoordinator())
        
        try await process(route: .room(roomID: "1", via: []))
        try await process(route: .roomDetails(roomID: "1"))
        #expect(navigationStackCoordinator.rootCoordinator is BlankFormCoordinator, "A child room flow should push onto the stack, leaving the root alone.")
        #expect(navigationStackCoordinator.stackCoordinators.count == 2)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.last is RoomDetailsScreenCoordinator)
        
        try await clearRoute(expectedActions: [.finished])
        #expect(navigationStackCoordinator.rootCoordinator is BlankFormCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 2, "A child room flow should leave its parent to clean up the stack.")
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator, "A child room flow should leave its parent to clean up the stack.")
        #expect(navigationStackCoordinator.stackCoordinators.last is RoomDetailsScreenCoordinator, "A child room flow should leave its parent to clean up the stack.")
    }
    
    @Test
    func childRoomMemberDetails() async throws {
        setupRoomFlowCoordinator()
        
        try await process(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        
        try await process(route: .childRoom(roomID: "2", via: []))
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        
        try await process(route: .roomMemberDetails(userID: RoomMemberProxyMock.mockMe.userID))
        #expect(navigationStackCoordinator.stackCoordinators.count == 2)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.last is RoomMemberDetailsScreenCoordinator)
    }
    
    @Test
    func childRoomIgnoresDirectDuplicate() async throws {
        setupRoomFlowCoordinator()
        
        try await process(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        
        try await process(route: .childRoom(roomID: "1", via: []))
        #expect(navigationStackCoordinator.stackCoordinators.count == 0,
                "A room flow shouldn't present a direct child for the same room.")
        
        try await process(route: .childRoom(roomID: "2", via: []))
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        
        try await process(route: .childRoom(roomID: "1", via: []))
        #expect(navigationStackCoordinator.stackCoordinators.count == 2,
                "Presenting the same room multiple times should be allowed when it's not a direct child of itself.")
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.last is RoomScreenCoordinator)
    }
    
    @Test
    func roomMembershipInvite() async throws {
        setupRoomFlowCoordinator(roomType: .invited(roomID: "InvitedRoomID"))
        
        try await process(route: .room(roomID: "InvitedRoomID", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is JoinRoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        
        try await clearRoute(expectedActions: [.finished])
        #expect(navigationStackCoordinator.rootCoordinator == nil)
        
        setupRoomFlowCoordinator(roomType: .invited(roomID: "InvitedRoomID"))
        
        try await process(route: .room(roomID: "InvitedRoomID", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is JoinRoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        
        // "Join" the room
        clientProxy.roomForIdentifierClosure = { _ in
            .joined(JoinedRoomProxyMock(.init()))
        }
        
        try await process(route: .room(roomID: "InvitedRoomID", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
    }
    
    @Test
    func childRoomMembershipInvite() async throws {
        setupRoomFlowCoordinator(asChildFlow: true, roomType: .invited(roomID: "InvitedRoomID"))
        navigationStackCoordinator.setRootCoordinator(BlankFormCoordinator())
        
        try await process(route: .room(roomID: "InvitedRoomID", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is BlankFormCoordinator, "A child room flow should push onto the stack, leaving the root alone.")
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators.last is JoinRoomScreenCoordinator)
        
        try await clearRoute(expectedActions: [.finished])
        #expect(navigationStackCoordinator.stackCoordinators.last == nil, "A child room flow should remove the join room scren on dismissal")
        
        setupRoomFlowCoordinator(asChildFlow: true, roomType: .invited(roomID: "InvitedRoomID"))
        navigationStackCoordinator.setRootCoordinator(BlankFormCoordinator())
        
        try await process(route: .room(roomID: "InvitedRoomID", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is BlankFormCoordinator, "A child room flow should push onto the stack, leaving the root alone.")
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators.last is JoinRoomScreenCoordinator)
        
        // "Join" the room
        clientProxy.roomForIdentifierClosure = { _ in
            .joined(JoinedRoomProxyMock(.init()))
        }
        
        try await process(route: .room(roomID: "InvitedRoomID", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is BlankFormCoordinator, "A child room flow should push onto the stack, leaving the root alone.")
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators.last is RoomScreenCoordinator)
    }
    
    @Test
    func eventRoute() async throws {
        setupRoomFlowCoordinator()
        
        try await process(route: .event(eventID: "1", roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        
        try await process(route: .childEvent(eventID: "2", roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        
        try await process(route: .childEvent(eventID: "3", roomID: "2", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
    }
    
    @Test
    func threadedEventRoutes() async throws {
        ServiceLocator.shared.settings.threadsEnabled = true
        setupRoomFlowCoordinator()
        
        // Navigate directly to the threaded event
        var configuration = JoinedRoomProxyMockConfiguration(id: "1")
        var roomProxy = JoinedRoomProxyMock(configuration)
        
        var roomInfoSubject = CurrentValueSubject<RoomInfoProxyProtocol, Never>(RoomInfoProxyMock(configuration))
        roomProxy.infoPublisher = roomInfoSubject.asCurrentValuePublisher()
        
        var mockedEvent = TimelineEventSDKMock()
        mockedEvent.threadRootEventIdReturnValue = "1"
        roomProxy.loadOrFetchEventDetailsForReturnValue = .success(mockedEvent)
        
        clientProxy.roomForIdentifierClosure = { _ in
            .joined(roomProxy)
        }
        
        try await process(route: .event(eventID: "2", roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators[0] is ThreadTimelineScreenCoordinator)
        
        // From the thread screen, navigate to another threaded event in the same room, and in the same thread.
        let threadCoordinator = navigationStackCoordinator.stackCoordinators[0] as? ThreadTimelineScreenCoordinator
        try await process(route: .childEvent(eventID: "3", roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators[0] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[0] === threadCoordinator)
        // Would be nice to test if the focusEvent function has been called but there is no way to mock that.
        
        // From the thread screen, navigate to another threaded event in the same room, but in a different thread.
        mockedEvent = TimelineEventSDKMock()
        mockedEvent.threadRootEventIdReturnValue = "4"
        roomProxy.loadOrFetchEventDetailsForReturnValue = .success(mockedEvent)
        try await process(route: .childEvent(eventID: "5", roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 2)
        #expect(navigationStackCoordinator.stackCoordinators[0] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[1] is ThreadTimelineScreenCoordinator)
        
        // From the thread screen, navigate to another threaded event in a different room.
        configuration = JoinedRoomProxyMockConfiguration(id: "2")
        roomProxy = JoinedRoomProxyMock(configuration)
        
        roomInfoSubject = CurrentValueSubject<RoomInfoProxyProtocol, Never>(RoomInfoProxyMock(configuration))
        roomProxy.infoPublisher = roomInfoSubject.asCurrentValuePublisher()
        
        mockedEvent = TimelineEventSDKMock()
        mockedEvent.threadRootEventIdReturnValue = "1"
        roomProxy.loadOrFetchEventDetailsForReturnValue = .success(mockedEvent)
        
        clientProxy.roomForIdentifierClosure = { _ in
            .joined(roomProxy)
        }
        
        try await process(route: .childEvent(eventID: "2", roomID: "2", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 4)
        #expect(navigationStackCoordinator.stackCoordinators[0] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[1] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[2] is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[3] is ThreadTimelineScreenCoordinator)
        
        // From the thread screen, navigate to an event of the same room that is not threaded
        mockedEvent = TimelineEventSDKMock()
        mockedEvent.threadRootEventIdReturnValue = nil
        roomProxy.loadOrFetchEventDetailsForReturnValue = .success(mockedEvent)
        
        try await process(route: .childEvent(eventID: "3", roomID: "2", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 5)
        #expect(navigationStackCoordinator.stackCoordinators[0] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[1] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[2] is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[3] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[4] is RoomScreenCoordinator)
    }
    
    @Test
    func shareMediaRoute() async throws {
        setupRoomFlowCoordinator()
        
        try await process(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        
        let sharePayload: ShareExtensionPayload = .mediaFiles(roomID: "1", mediaFiles: [.init(url: .picturesDirectory, suggestedName: nil)])
        try await process(route: .share(sharePayload))
        
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        
        #expect((navigationStackCoordinator.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is MediaUploadPreviewScreenCoordinator)
        
        try await process(route: .childRoom(roomID: "2", via: []))
        #expect(navigationStackCoordinator.sheetCoordinator == nil)
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        
        try await process(route: .share(sharePayload))
        
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        #expect((navigationStackCoordinator.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is MediaUploadPreviewScreenCoordinator)
    }
    
    @Test
    func shareTextRoute() async throws {
        setupRoomFlowCoordinator()
        
        try await process(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        
        let sharePayload: ShareExtensionPayload = .text(roomID: "1", text: "Important text")
        try await process(route: .share(sharePayload))
        
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        
        #expect(navigationStackCoordinator.sheetCoordinator == nil, "The media upload sheet shouldn't be shown when sharing text.")
        
        try await process(route: .childRoom(roomID: "2", via: []))
        #expect(navigationStackCoordinator.sheetCoordinator == nil)
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        
        try await process(route: .share(sharePayload))
        
        #expect(navigationStackCoordinator.stackCoordinators.count == 0)
        #expect(navigationStackCoordinator.sheetCoordinator == nil, "The media upload sheet shouldn't be shown when sharing text.")
    }
    
    @Test
    func leavingRoom() async throws {
        setupRoomFlowCoordinator()
        
        var configuration = JoinedRoomProxyMockConfiguration()
        let roomProxy = JoinedRoomProxyMock(configuration)
        
        let roomInfoSubject = CurrentValueSubject<RoomInfoProxyProtocol, Never>(RoomInfoProxyMock(configuration))
        roomProxy.infoPublisher = roomInfoSubject.asCurrentValuePublisher()
        
        clientProxy.roomForIdentifierClosure = { _ in
            .joined(roomProxy)
        }
        
        try await process(route: .room(roomID: "1", via: []))
        
        let fulfillment = deferFulfillment(roomFlowCoordinator.actions) { action in
            action == .finished
        }
        
        configuration.membership = .left
        roomInfoSubject.send(RoomInfoProxyMock(configuration))
        
        try await fulfillment.fulfill()
    }
    
    // MARK: - Spaces
    
    @Test
    func spacePermalink() async throws {
        setupRoomFlowCoordinator()
        
        try await process(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        
        try await process(route: .childRoom(roomID: "space1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.first is SpaceScreenCoordinator)
    }
    
    // MARK: - Private
    
    private func process(route: AppRoute) async throws {
        roomFlowCoordinator.handleAppRoute(route, animated: true)
        // A single yield isn't enough when creating the new flow coordinator.
        try await Task.sleep(for: .milliseconds(100))
    }
    
    private func clearRoute(expectedActions: [RoomFlowCoordinatorAction]) async throws {
        try await processRouteOrClear(route: nil, expectedActions: expectedActions)
    }
    
    private func process(route: AppRoute, expectedActions: [RoomFlowCoordinatorAction]) async throws {
        try await processRouteOrClear(route: route, expectedActions: expectedActions)
    }
    
    private func processRouteOrClear(route: AppRoute?, expectedActions: [RoomFlowCoordinatorAction]) async throws {
        guard !expectedActions.isEmpty else {
            return
        }
        
        var fulfillments = [DeferredFulfillment<RoomFlowCoordinatorAction>]()
        
        for expectedAction in expectedActions {
            fulfillments.append(deferFulfillment(roomFlowCoordinator.actions) { action in
                action == expectedAction
            })
        }
        
        if let route {
            roomFlowCoordinator.handleAppRoute(route, animated: true)
        } else {
            roomFlowCoordinator.clearRoute(animated: true)
        }
        
        for fulfillment in fulfillments {
            try await fulfillment.fulfill()
        }
    }
    
    private func setupRoomFlowCoordinator(asChildFlow: Bool = false, roomType: RoomType? = nil) {
        cancellables.removeAll()
        clientProxy = ClientProxyMock(.init(userID: "hi@bob",
                                            roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                            spaceServiceConfiguration: .populated))
        timelineControllerFactory = TimelineControllerFactoryMock(.init())
        
        clientProxy.roomPreviewForIdentifierViaClosure = { [roomType] roomID, _ in
            switch roomType {
            case .invited:
                return .success(RoomPreviewProxyMock.invited(roomID: roomID))
            default:
                fatalError("Something isn't set up right")
            }
        }
        
        let navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator(hideBrandChrome: false))
        navigationStackCoordinator = NavigationStackCoordinator()
        navigationSplitCoordinator.setDetailCoordinator(navigationStackCoordinator)
        
        let roomID = switch roomType {
        case .invited(let roomID):
            roomID
        default:
            "1"
        }
        
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
                                                  userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                  notificationManager: NotificationManagerMock(),
                                                  stateMachineFactory: StateMachineFactory())
        
        roomFlowCoordinator = RoomFlowCoordinator(roomID: roomID,
                                                  isChildFlow: asChildFlow,
                                                  navigationStackCoordinator: navigationStackCoordinator,
                                                  flowParameters: flowParameters)
    }
}

private enum RoomType {
    case invited(roomID: String)
}

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
final class RoomFlowCoordinatorTests {
    var clientProxy: ClientProxyMock!
    var timelineControllerFactory: TimelineControllerFactoryMock!
    var roomFlowCoordinator: RoomFlowCoordinator!
    var navigationStackCoordinator: NavigationStackCoordinator!
    var cancellables = Set<AnyCancellable>()
    
    private let appSettings: AppSettings
    
    init() {
        appSettings = AppSettings.volatile()
    }
    
    @Test
    func roomPresentation() async throws {
        setupRoomFlowCoordinator()
        
        try await processExpectingNewRootCoordinator(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        
        try await clearRoute(expectedActions: [.finished])
        try await waitForStackToClear()
    }
    
    @Test
    func roomDetailsPresentation() async throws {
        setupRoomFlowCoordinator()
        
        try await processExpectingNewRootCoordinator(route: .roomDetails(roomID: "1"))
        #expect(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        
        try await clearRoute(expectedActions: [.finished])
        try await waitForStackToClear()
    }
    
    @Test
    func noOp() async throws {
        setupRoomFlowCoordinator()
        
        try await processExpectingNewRootCoordinator(route: .roomDetails(roomID: "1"))
        #expect(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        let detailsCoordinator = navigationStackCoordinator.rootCoordinator
        
        try await processNotExpectingNavigation(route: .roomDetails(roomID: "1"))
        
        #expect(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        #expect(navigationStackCoordinator.rootCoordinator === detailsCoordinator)
    }
    
    @Test
    func pushDetails() async throws {
        setupRoomFlowCoordinator()
        
        try await processExpectingNewRootCoordinator(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        
        try await process(route: .roomDetails(roomID: "1"), expectedStackCount: 1)
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomDetailsScreenCoordinator)
    }
    
    @Test
    func childRoomFlow() async throws {
        setupRoomFlowCoordinator()
        
        try await processExpectingNewRootCoordinator(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        
        try await process(route: .childRoom(roomID: "2", via: []), expectedStackCount: 1)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        
        try await process(route: .childRoom(roomID: "3", via: []), expectedStackCount: 2)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.last is RoomScreenCoordinator)
        
        try await clearRoute(expectedActions: [.finished])
        try await waitForStackToClear()
    }
    
    /// Tests the child flow teardown in isolation of it's parent.
    @Test
    func childFlowTearDown() async throws {
        setupRoomFlowCoordinator(asChildFlow: true)
        navigationStackCoordinator.setRootCoordinator(BlankFormCoordinator())
        
        try await process(route: .room(roomID: "1", via: []), expectedStackCount: 1)
        try await process(route: .roomDetails(roomID: "1"), expectedStackCount: 2)
        #expect(navigationStackCoordinator.rootCoordinator is BlankFormCoordinator, "A child room flow should push onto the stack, leaving the root alone.")
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
        
        try await processExpectingNewRootCoordinator(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        
        try await process(route: .childRoom(roomID: "2", via: []), expectedStackCount: 1)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        
        try await process(route: .roomMemberDetails(userID: RoomMemberProxyMock.mockMe.userID), expectedStackCount: 2)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.last is RoomMemberDetailsScreenCoordinator)
    }
    
    @Test
    func childRoomIgnoresDirectDuplicate() async throws {
        setupRoomFlowCoordinator()
        
        try await processExpectingNewRootCoordinator(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        
        try await processNotExpectingNavigation(route: .childRoom(roomID: "1", via: []))
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty,
                "A room flow shouldn't present a direct child for the same room.")
        
        try await process(route: .childRoom(roomID: "2", via: []), expectedStackCount: 1)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        
        try await process(route: .childRoom(roomID: "1", via: []), expectedStackCount: 2)
        #expect(navigationStackCoordinator.stackCoordinators.count == 2,
                "Presenting the same room multiple times should be allowed when it's not a direct child of itself.")
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.last is RoomScreenCoordinator)
    }
    
    @Test
    func roomMembershipInvite() async throws {
        setupRoomFlowCoordinator(roomType: .invited(roomID: "InvitedRoomID"))
        
        try await processExpectingNewRootCoordinator(route: .room(roomID: "InvitedRoomID", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is JoinRoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        
        try await clearRoute(expectedActions: [.finished])
        try await waitForStackToClear()
        
        setupRoomFlowCoordinator(roomType: .invited(roomID: "InvitedRoomID"))
        
        try await processExpectingNewRootCoordinator(route: .room(roomID: "InvitedRoomID", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is JoinRoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        
        // "Join" the room
        clientProxy.roomForIdentifierClosure = { _ in
            .joined(JoinedRoomProxyMock(.init()))
        }
        
        try await processExpectingNewRootCoordinator(route: .room(roomID: "InvitedRoomID", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
    }
    
    @Test
    func childRoomMembershipInvite() async throws {
        setupRoomFlowCoordinator(asChildFlow: true, roomType: .invited(roomID: "InvitedRoomID"))
        navigationStackCoordinator.setRootCoordinator(BlankFormCoordinator())
        
        try await processExpectingNewTopCoordinator(route: .room(roomID: "InvitedRoomID", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is BlankFormCoordinator, "A child room flow should push onto the stack, leaving the root alone.")
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators.last is JoinRoomScreenCoordinator)
        
        try await clearRoute(expectedActions: [.finished])
        let deferredDismissal = deferFulfillment(navigationStackCoordinator.observe(\.stackCoordinators.count),
                                                 message: "A child room flow should remove the join room screen on dismissal") { $0 == 0 }
        try await deferredDismissal.fulfill()
        
        setupRoomFlowCoordinator(asChildFlow: true, roomType: .invited(roomID: "InvitedRoomID"))
        navigationStackCoordinator.setRootCoordinator(BlankFormCoordinator())
        
        try await processExpectingNewTopCoordinator(route: .room(roomID: "InvitedRoomID", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is BlankFormCoordinator, "A child room flow should push onto the stack, leaving the root alone.")
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators.last is JoinRoomScreenCoordinator)
        
        // "Join" the room
        clientProxy.roomForIdentifierClosure = { _ in
            .joined(JoinedRoomProxyMock(.init()))
        }
        
        try await processExpectingNewTopCoordinator(route: .room(roomID: "InvitedRoomID", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is BlankFormCoordinator, "A child room flow should push onto the stack, leaving the root alone.")
        #expect(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators.last is RoomScreenCoordinator)
    }
    
    @Test
    func eventRoute() async throws {
        setupRoomFlowCoordinator()
        
        try await processExpectingNewRootCoordinator(route: .event(eventID: "1", roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        
        try await processNotExpectingNavigation(route: .childEvent(eventID: "2", roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        
        try await process(route: .childEvent(eventID: "3", roomID: "2", via: []), expectedStackCount: 1)
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
    }
    
    @Test
    func threadedEventRoutes() async throws {
        appSettings.threadsEnabled = true
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
        
        try await process(route: .event(eventID: "2", roomID: "1", via: []), expectedStackCount: 1)
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        try #require(navigationStackCoordinator.stackCoordinators.count == 1) // #require these counts so accessing by index is safe.
        #expect(navigationStackCoordinator.stackCoordinators[0] is ThreadTimelineScreenCoordinator)
        
        // From the thread screen, navigate to another threaded event in the same room, and in the same thread.
        let threadCoordinator = navigationStackCoordinator.stackCoordinators[0] as? ThreadTimelineScreenCoordinator
        try await processNotExpectingNavigation(route: .childEvent(eventID: "3", roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        try #require(navigationStackCoordinator.stackCoordinators.count == 1)
        #expect(navigationStackCoordinator.stackCoordinators[0] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[0] === threadCoordinator)
        // Would be nice to test if the focusEvent function has been called but there is no way to mock that.
        
        // From the thread screen, navigate to another threaded event in the same room, but in a different thread.
        mockedEvent = TimelineEventSDKMock()
        mockedEvent.threadRootEventIdReturnValue = "4"
        roomProxy.loadOrFetchEventDetailsForReturnValue = .success(mockedEvent)
        try await process(route: .childEvent(eventID: "5", roomID: "1", via: []), expectedStackCount: 2)
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        try #require(navigationStackCoordinator.stackCoordinators.count == 2)
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
        
        try await process(route: .childEvent(eventID: "2", roomID: "2", via: []), expectedStackCount: 4)
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        try #require(navigationStackCoordinator.stackCoordinators.count == 4)
        #expect(navigationStackCoordinator.stackCoordinators[0] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[1] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[2] is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[3] is ThreadTimelineScreenCoordinator)
        
        // From the thread screen, navigate to an event of the same room that is not threaded
        mockedEvent = TimelineEventSDKMock()
        mockedEvent.threadRootEventIdReturnValue = nil
        roomProxy.loadOrFetchEventDetailsForReturnValue = .success(mockedEvent)
        
        try await process(route: .childEvent(eventID: "3", roomID: "2", via: []), expectedStackCount: 5)
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        try #require(navigationStackCoordinator.stackCoordinators.count == 5)
        #expect(navigationStackCoordinator.stackCoordinators[0] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[1] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[2] is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[3] is ThreadTimelineScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators[4] is RoomScreenCoordinator)
    }
    
    @Test
    func shareMediaRoute() async throws {
        setupRoomFlowCoordinator()
        
        try await processExpectingNewRootCoordinator(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        
        let sharePayload: ShareExtensionPayload = .mediaFiles(roomID: "1", mediaFiles: [.init(url: .picturesDirectory, suggestedName: nil)])
        try await processExpectingSheet(route: .share(sharePayload))
        
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        
        #expect((navigationStackCoordinator.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is MediaUploadPreviewScreenCoordinator)
        
        try await process(route: .childRoom(roomID: "2", via: []), expectedStackCount: 1)
        let deferredSheetDismissal = deferFulfillment(navigationStackCoordinator.observe(\.sheetCoordinatorID)) { $0 == nil }
        try await deferredSheetDismissal.fulfill()
        
        try await processExpectingSheet(route: .share(sharePayload))
        
        let deferredPop = deferFulfillment(navigationStackCoordinator.observe(\.stackCoordinators.count)) { $0 == 0 }
        try await deferredPop.fulfill()
        #expect((navigationStackCoordinator.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is MediaUploadPreviewScreenCoordinator)
    }
    
    @Test
    func shareTextRoute() async throws {
        setupRoomFlowCoordinator()
        
        try await processExpectingNewRootCoordinator(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        
        let sharePayload: ShareExtensionPayload = .text(roomID: "1", text: "Important text")
        try await processNotExpectingNavigation(route: .share(sharePayload))
        
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.isEmpty)
        
        #expect(navigationStackCoordinator.sheetCoordinator == nil, "The media upload sheet shouldn't be shown when sharing text.")
        
        try await process(route: .childRoom(roomID: "2", via: []), expectedStackCount: 1)
        #expect(navigationStackCoordinator.sheetCoordinator == nil)
        
        try await process(route: .share(sharePayload), expectedStackCount: 0)
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
        
        try await processExpectingNewRootCoordinator(route: .room(roomID: "1", via: []))
        
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
        
        try await processExpectingNewRootCoordinator(route: .room(roomID: "1", via: []))
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        
        try await process(route: .childRoom(roomID: "space1", via: []), expectedStackCount: 1)
        #expect(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        #expect(navigationStackCoordinator.stackCoordinators.first is SpaceScreenCoordinator)
    }
    
    // MARK: - Private
    
    /// Handles the route and waits for the navigation stack's root coordinator to be replaced,
    /// which happens asynchronously after the route has been handled.
    private func processExpectingNewRootCoordinator(route: AppRoute) async throws {
        // Keep the previous coordinator alive while waiting, otherwise a newly presented
        // coordinator could be allocated at the same address and be mistaken for it below.
        let previousRootCoordinator = navigationStackCoordinator.rootCoordinator
        let previousRootCoordinatorID = previousRootCoordinator.map { ObjectIdentifier($0) }
        roomFlowCoordinator.handleAppRoute(route, animated: true)
        
        let deferred = deferFulfillment(navigationStackCoordinator.observe(\.rootCoordinatorID)) { $0 != nil && $0 != previousRootCoordinatorID }
        try await deferred.fulfill()
        
        withExtendedLifetime(previousRootCoordinator) { }
    }
    
    /// Handles the route and waits for the topmost coordinator on the stack to be replaced.
    private func processExpectingNewTopCoordinator(route: AppRoute) async throws {
        let previousTopCoordinator = navigationStackCoordinator.stackCoordinators.last
        let previousTopCoordinatorID = previousTopCoordinator.map { ObjectIdentifier($0) }
        roomFlowCoordinator.handleAppRoute(route, animated: true)
        
        let deferred = deferFulfillment(navigationStackCoordinator.observe(\.topCoordinatorID)) { $0 != nil && $0 != previousTopCoordinatorID }
        try await deferred.fulfill()
        
        withExtendedLifetime(previousTopCoordinator) { }
    }
    
    /// Handles the route and waits for a new sheet to be presented.
    private func processExpectingSheet(route: AppRoute) async throws {
        let previousSheetCoordinator = navigationStackCoordinator.sheetCoordinator
        let previousSheetCoordinatorID = previousSheetCoordinator.map { ObjectIdentifier($0) }
        roomFlowCoordinator.handleAppRoute(route, animated: true)
        
        let deferred = deferFulfillment(navigationStackCoordinator.observe(\.sheetCoordinatorID)) { $0 != nil && $0 != previousSheetCoordinatorID }
        try await deferred.fulfill()
        
        withExtendedLifetime(previousSheetCoordinator) { }
    }
    
    /// Handles the route and waits for the navigation stack to reach the expected size.
    private func process(route: AppRoute, expectedStackCount: Int) async throws {
        roomFlowCoordinator.handleAppRoute(route, animated: true)
        
        let deferred = deferFulfillment(navigationStackCoordinator.observe(\.stackCoordinators.count)) { $0 == expectedStackCount }
        try await deferred.fulfill()
    }
    
    /// Handles a route that isn't expected to trigger any navigation.
    private func processNotExpectingNavigation(route: AppRoute) async throws {
        let currentStackCount = navigationStackCoordinator.stackCoordinators.count
        let deferred = deferFailure(navigationStackCoordinator.observe(\.stackCoordinators.count), timeout: .seconds(1)) { $0 != currentStackCount }
        
        roomFlowCoordinator.handleAppRoute(route, animated: true)
        try await deferred.fulfill()
    }
    
    /// Waits for the navigation stack to be emptied after the flow has been cleared.
    private func waitForStackToClear() async throws {
        let deferredRoot = deferFulfillment(navigationStackCoordinator.observe(\.rootCoordinatorID)) { $0 == nil }
        try await deferredRoot.fulfill()
        
        let deferredStack = deferFulfillment(navigationStackCoordinator.observe(\.stackCoordinators.count)) { $0 == 0 }
        try await deferredStack.fulfill()
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
                                                  emojiProvider: EmojiProvider(appSettings: appSettings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  appMediator: AppMediatorMock(.init()),
                                                  appSettings: appSettings,
                                                  appHooks: AppHooks(),
                                                  analytics: AnalyticsServiceMock(.init()),
                                                  userIndicatorController: UserIndicatorControllerMock(),
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

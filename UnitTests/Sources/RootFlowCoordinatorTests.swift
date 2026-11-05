//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import SwiftUI
import Testing

@MainActor
struct RootFlowCoordinatorTests {
    private let navigationRootCoordinator = NavigationRootCoordinator()
    private let userSessionManager = UserSessionManagerMock(.init())
    private let clientProxy: ClientProxyMock
    private let roomID = "1"
    private let inviteRoomID = "someAwesomeRoomId1"
    
    private let rootFlowCoordinator: RootFlowCoordinator
    
    init() {
        clientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org",
                                            roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded([RoomSummary].mockRooms + .mockInvites)))))
        clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.invited())
        
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        userSessionManager.activeSession = userSession
        userSessionManager.sessionsPublisher = .init([userSession])
        
        rootFlowCoordinator = RootFlowCoordinator(navigationRootCoordinator: navigationRootCoordinator,
                                                  userSessionManager: userSessionManager,
                                                  elementCallManager: ElementCallManagerMock(),
                                                  appLockService: AppLockServiceMock(),
                                                  bugReportService: BugReportServiceMock(.init()),
                                                  appMediator: AppMediatorMock(.init()),
                                                  appSettings: .volatile(),
                                                  appHooks: AppHooks(),
                                                  analyticsService: AnalyticsServiceMock(.init()),
                                                  userIndicatorController: UserIndicatorControllerMock())
    }
    
    // MARK: Pending routes
    
    @Test("A route received before the user session flow starts is opened once it does")
    func pendingRoute() async throws {
        rootFlowCoordinator.handleAppRoute(.room(roomID: roomID, via: []), userID: "@alice:matrix.org", awaitsRoom: false, animated: false)
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        
        let splitCoordinator = try #require(chatsSplitCoordinator)
        let deferred = deferFulfillment(splitCoordinator.observe(\.detailRootCoordinatorID)) { $0 != nil }
        try await deferred.fulfill()
        #expect((splitCoordinator.detailCoordinator as? NavigationStackCoordinator)?.rootCoordinator is RoomScreenCoordinator)
    }
    
    @Test("A pending invite only waits for its room to sync once the user session flow starts")
    func pendingInvite() {
        rootFlowCoordinator.handleAppRoute(.room(roomID: inviteRoomID, via: []), userID: "@alice:matrix.org", awaitsRoom: true, animated: false)
        #expect(clientProxy.roomsToAwait.isEmpty)
        
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        #expect(clientProxy.roomsToAwait == [inviteRoomID])
    }
    
    // MARK: Routes while a flow is shown
    
    @Test("A route that needs a session is ignored when not signed in")
    func routeDuringAuthentication() async throws {
        rootFlowCoordinator.handleAppRoute(.authentication, animated: false)
        #expect(navigationRootCoordinator.rootCoordinator is NavigationStackCoordinator)
        
        rootFlowCoordinator.handleAppRoute(.room(roomID: roomID, via: []), animated: false)
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        
        let splitCoordinator = try #require(chatsSplitCoordinator)
        let deferred = deferFailure(splitCoordinator.observe(\.detailRootCoordinatorID), timeout: .seconds(1)) { $0 != nil }
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    private var chatsSplitCoordinator: NavigationSplitCoordinator? {
        let tabCoordinator = navigationRootCoordinator.rootCoordinator as? NavigationTabCoordinator<UserSessionFlowCoordinator.HomeTab>
        return tabCoordinator?.tabCoordinators.first as? NavigationSplitCoordinator
    }
}

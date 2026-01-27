//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import XCTest

@MainActor
class RoomMembersFlowCoordinatorTests: XCTestCase {
    var membersFlowCoordinator: RoomMembersFlowCoordinator!
    var navigationStackCoordinator: NavigationStackCoordinator!
    var stateMachineFactory: PublishedStateMachineFactory!
        
    func testClearRoute() async throws {
        try await setUp(entryPoint: .roomMembersList)
        XCTAssertTrue(navigationStackCoordinator.stackCoordinators.last is RoomMembersListScreenCoordinator)
        
        var membersFlowStateExpectation = deferFulfillment(stateMachineFactory.membersFlowStatePublisher) { $0 == .roomMemberDetails(userID: "test", previousState: .roomMembersList) }
        membersFlowCoordinator.handleAppRoute(.roomMemberDetails(userID: "test"), animated: false)
        try await membersFlowStateExpectation.fulfill()
        XCTAssertTrue(navigationStackCoordinator.stackCoordinators.last is RoomMemberDetailsScreenCoordinator)
        
        membersFlowStateExpectation = deferFulfillment(stateMachineFactory.membersFlowStatePublisher) { $0 == .roomMembersList }
        let membersFlowActionExpectation = deferFulfillment(membersFlowCoordinator.actions) { action in
            switch action {
            case .finished:
                true
            default:
                false
            }
        }
        membersFlowCoordinator.clearRoute(animated: false)
        try await membersFlowStateExpectation.fulfill()
        try await membersFlowActionExpectation.fulfill()
        XCTAssertTrue(navigationStackCoordinator.stackCoordinators.last is BlankFormCoordinator)
    }
    
    private func setUp(entryPoint: RoomMembersFlowCoordinatorEntryPoint) async throws {
        stateMachineFactory = .init()
        navigationStackCoordinator = NavigationStackCoordinator()
        navigationStackCoordinator.setRootCoordinator(PlaceholderScreenCoordinator(hideBrandChrome: false))
        navigationStackCoordinator.push(BlankFormCoordinator())
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.directRoomForUserIDReturnValue = .success(nil)
                
        let flowParameters = CommonFlowParameters(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                  bugReportService: BugReportServiceMock(.init()),
                                                  elementCallService: ElementCallServiceMock(.init()),
                                                  timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                                  emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  appMediator: AppMediatorMock.default,
                                                  appSettings: ServiceLocator.shared.settings,
                                                  appHooks: AppHooks(),
                                                  analytics: ServiceLocator.shared.analytics,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  notificationManager: NotificationManagerMock(),
                                                  stateMachineFactory: stateMachineFactory)
        
        let roomProxy = JoinedRoomProxyMock(.init())
        roomProxy.getMemberUserIDClosure = { _ in
            .success(RoomMemberProxyMock(with: .init(userID: "test", membership: .join)))
        }
        
        membersFlowCoordinator = RoomMembersFlowCoordinator(entryPoint: entryPoint,
                                                            roomProxy: roomProxy,
                                                            navigationStackCoordinator: navigationStackCoordinator,
                                                            flowParameters: flowParameters)
        
        let deferred = deferFulfillment(stateMachineFactory.membersFlowStatePublisher) { state in
            switch entryPoint {
            case .roomMember(let userID):
                state == .roomMemberDetails(userID: userID, previousState: .initial)
            case .roomMembersList:
                state == .roomMembersList
            }
        }
        
        membersFlowCoordinator.start()
        try await deferred.fulfill()
    }
}

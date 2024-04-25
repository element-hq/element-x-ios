//
// Copyright 2023 New Vector Ltd
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

import XCTest

import Combine
@testable import ElementX

@MainActor
class UserSessionFlowCoordinatorTests: XCTestCase {
    var clientProxy: ClientProxyMock!
    var userSessionFlowCoordinator: UserSessionFlowCoordinator!
    var navigationRootCoordinator: NavigationRootCoordinator!
    var notificationManager: NotificationManagerMock!
    
    var cancellables = Set<AnyCancellable>()
    
    var splitCoordinator: NavigationSplitCoordinator? { navigationRootCoordinator.rootCoordinator as? NavigationSplitCoordinator }
    var detailCoordinator: CoordinatorProtocol? { splitCoordinator?.detailCoordinator }
    var detailNavigationStack: NavigationStackCoordinator? { detailCoordinator as? NavigationStackCoordinator }
    
    override func setUp() async throws {
        cancellables.removeAll()
        clientProxy = ClientProxyMock(.init(userID: "hi@bob", roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))))
        let mediaProvider = MockMediaProvider()
        let voiceMessageMediaManager = VoiceMessageMediaManagerMock()
        let userSession = MockUserSession(clientProxy: clientProxy,
                                          mediaProvider: mediaProvider,
                                          voiceMessageMediaManager: voiceMessageMediaManager)
        
        navigationRootCoordinator = NavigationRootCoordinator()
        
        notificationManager = NotificationManagerMock()
        
        userSessionFlowCoordinator = UserSessionFlowCoordinator(userSession: userSession,
                                                                navigationRootCoordinator: navigationRootCoordinator,
                                                                appLockService: AppLockServiceMock(),
                                                                bugReportService: BugReportServiceMock(),
                                                                roomTimelineControllerFactory: MockRoomTimelineControllerFactory(),
                                                                appMediator: AppMediatorMock.default,
                                                                appSettings: ServiceLocator.shared.settings,
                                                                analytics: ServiceLocator.shared.analytics,
                                                                notificationManager: notificationManager,
                                                                isNewLogin: false)
        
        let deferred = deferFulfillment(userSessionFlowCoordinator.statePublisher) { $0 == .roomList(selectedRoomID: nil) }
        userSessionFlowCoordinator.start()
        try await deferred.fulfill()
    }
    
    func testRoomPresentation() async throws {
        try await process(route: .room(roomID: "1"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(selectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        try await process(route: .room(roomID: "1"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "2"), expectedState: .roomList(selectedRoomID: "2"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(selectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        XCTAssertEqual(notificationManager.removeDeliveredMessageNotificationsForReceivedInvocations, ["1", "1", "2"])
    }
    
    func testRoomAliasPresentation() async throws {
        clientProxy.resolveRoomAliasReturnValue = "1"
        
        try await process(route: .roomAlias("#alias:matrix.org"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(selectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        try await process(route: .room(roomID: "1"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        clientProxy.resolveRoomAliasReturnValue = "2"
        
        try await process(route: .room(roomID: "2"), expectedState: .roomList(selectedRoomID: "2"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(selectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        XCTAssertEqual(notificationManager.removeDeliveredMessageNotificationsForReceivedInvocations, ["1", "1", "2"])
    }
    
    func testRoomDetailsPresentation() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(selectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
    }
    
    func testStackUnwinding() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "2"), expectedState: .roomList(selectedRoomID: "2"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testNoOp() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        let unexpectedFulfillment = deferFailure(userSessionFlowCoordinator.statePublisher, timeout: 1) { _ in true }
        userSessionFlowCoordinator.handleAppRoute(.roomDetails(roomID: "1"), animated: true)
        try await unexpectedFulfillment.fulfill()
        
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testSwitchToDifferentDetails() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomDetails(roomID: "2"), expectedState: .roomList(selectedRoomID: "2"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testPushDetails() async throws {
        try await process(route: .room(roomID: "1"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        let unexpectedFulfillment = deferFailure(userSessionFlowCoordinator.statePublisher, timeout: 1) { _ in true }
        userSessionFlowCoordinator.handleAppRoute(.roomDetails(roomID: "1"), animated: true)
        try await unexpectedFulfillment.fulfill()
        
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 1)
        XCTAssertTrue(detailNavigationStack?.stackCoordinators.first is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testReplaceDetailsWithTimeline() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "1"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testUserProfileClearsStack() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(selectedRoomID: "1"))
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
        try await process(route: .room(roomID: "1"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        
        userSessionFlowCoordinator.handleAppRoute(.childRoom(roomID: "2"), animated: true)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 1)
        XCTAssertTrue(detailNavigationStack?.stackCoordinators.first is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "3"), expectedState: .roomList(selectedRoomID: "3"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testEventRoutes() async throws {
        try await process(route: .event(roomID: "1", eventID: "1"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        
        userSessionFlowCoordinator.handleAppRoute(.childEvent(roomID: "2", eventID: "2"), animated: true)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 1)
        XCTAssertTrue(detailNavigationStack?.stackCoordinators.first is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .event(roomID: "3", eventID: "3"), expectedState: .roomList(selectedRoomID: "3"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
    }
    
    // MARK: - Private
    
    private func process(route: AppRoute, expectedState: UserSessionFlowCoordinatorStateMachine.State) async throws {
        // Sometimes the state machine's state changes before the coordinators have updated the stack.
        let delayedPublisher = userSessionFlowCoordinator.statePublisher.delay(for: .milliseconds(10), scheduler: DispatchQueue.main)
        
        let deferred = deferFulfillment(delayedPublisher) { $0 == expectedState }
        userSessionFlowCoordinator.handleAppRoute(route, animated: true)
        try await deferred.fulfill()
    }
}

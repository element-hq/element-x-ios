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
    var timelineControllerFactory: RoomTimelineControllerFactoryMock!
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
        timelineControllerFactory = RoomTimelineControllerFactoryMock(configuration: .init())
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
                                                                elementCallService: ElementCallServiceMock(),
                                                                roomTimelineControllerFactory: timelineControllerFactory,
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
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(selectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "2", via: []), expectedState: .roomList(selectedRoomID: "2"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(selectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        XCTAssertEqual(notificationManager.removeDeliveredMessageNotificationsForReceivedInvocations, ["1", "1", "2"])
    }
    
    func testRoomAliasPresentation() async throws {
        clientProxy.resolveRoomAliasReturnValue = .success(.init(roomId: "1", servers: []))
        
        try await process(route: .roomAlias("#alias:matrix.org"), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .roomList, expectedState: .roomList(selectedRoomID: nil))
        XCTAssertNil(detailNavigationStack?.rootCoordinator)
        XCTAssertNil(detailCoordinator)
        
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        clientProxy.resolveRoomAliasReturnValue = .success(.init(roomId: "2", servers: []))
        
        try await process(route: .room(roomID: "2", via: []), expectedState: .roomList(selectedRoomID: "2"))
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
        
        try await process(route: .room(roomID: "2", via: []), expectedState: .roomList(selectedRoomID: "2"))
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
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(selectedRoomID: "1"))
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
        
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(selectedRoomID: "1"))
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
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        
        userSessionFlowCoordinator.handleAppRoute(.childRoom(roomID: "2", via: []), animated: true)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 1)
        XCTAssertTrue(detailNavigationStack?.stackCoordinators.first is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        try await process(route: .room(roomID: "3", via: []), expectedState: .roomList(selectedRoomID: "3"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testEventRoutes() async throws {
        // A regular event route should set its room as the root of the stack and focus on the event.
        try await process(route: .event(eventID: "1", roomID: "1", via: []), expectedState: .roomList(selectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(timelineControllerFactory.buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryCallsCount, 1)
        XCTAssertEqual(timelineControllerFactory.buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryReceivedArguments?.initialFocussedEventID, "1")
        
        // A child event route should push a new room screen onto the stack and focus on the event.
        userSessionFlowCoordinator.handleAppRoute(.childEvent(eventID: "2", roomID: "2", via: []), animated: true)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 1)
        XCTAssertTrue(detailNavigationStack?.stackCoordinators.first is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(timelineControllerFactory.buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryCallsCount, 2)
        XCTAssertEqual(timelineControllerFactory.buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryReceivedArguments?.initialFocussedEventID, "2")
        
        // A subsequent regular event route should clear the stack and set the new room as the root of the stack.
        try await process(route: .event(eventID: "3", roomID: "3", via: []), expectedState: .roomList(selectedRoomID: "3"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(timelineControllerFactory.buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryCallsCount, 3)
        XCTAssertEqual(timelineControllerFactory.buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryReceivedArguments?.initialFocussedEventID, "3")
        
        // A regular event route for the same room should set a new instance of the room as the root of the stack.
        try await process(route: .event(eventID: "4", roomID: "3", via: []), expectedState: .roomList(selectedRoomID: "3"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(detailNavigationStack?.stackCoordinators.count, 0)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(timelineControllerFactory.buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryCallsCount, 4)
        XCTAssertEqual(timelineControllerFactory.buildRoomTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryReceivedArguments?.initialFocussedEventID, "4",
                       "A new timeline should be created for the same room ID, so that the screen isn't stale while loading.")
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

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
class RoomFlowCoordinatorTests: XCTestCase {
    var roomFlowCoordinator: RoomFlowCoordinator!
    var navigationStackCoordinator: NavigationStackCoordinator!
    var cancellables = Set<AnyCancellable>()
    
    func testRoomPresentation() async throws {
        await setupViewModel()
        
        try await process(route: .room(roomID: "1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        
        try await process(route: .roomList, expectedAction: .finished)
        XCTAssertNil(navigationStackCoordinator.rootCoordinator)
    }
    
    func testRoomDetailsPresentation() async throws {
        await setupViewModel()
        
        try await process(route: .roomDetails(roomID: "1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        
        try await process(route: .roomList, expectedAction: .finished)
        XCTAssertNil(navigationStackCoordinator.rootCoordinator)
    }
    
    func testNoOp() async throws {
        await setupViewModel()
        
        try await process(route: .roomDetails(roomID: "1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        let detailsCoordinator = navigationStackCoordinator.rootCoordinator
        
        roomFlowCoordinator.handleAppRoute(.roomDetails(roomID: "1"), animated: true)
        await Task.yield()
        
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        XCTAssert(navigationStackCoordinator.rootCoordinator === detailsCoordinator)
    }
    
    func testPushDetails() async throws {
        await setupViewModel()
        
        try await process(route: .room(roomID: "1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, 0)
        
        try await process(route: .roomDetails(roomID: "1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, 1)
        XCTAssert(navigationStackCoordinator.stackCoordinators.first is RoomDetailsScreenCoordinator)
    }
    
    func testChildRoomFlow() async throws {
        await setupViewModel()
        
        try await process(route: .room(roomID: "1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, 0)
        
        try await process(route: .childRoom(roomID: "2"))
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, 1)
        XCTAssert(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        
        try await process(route: .childRoom(roomID: "3"))
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, 2)
        XCTAssert(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        XCTAssert(navigationStackCoordinator.stackCoordinators.last is RoomScreenCoordinator)
        
        try await process(route: .roomList, expectedAction: .finished)
        XCTAssertNil(navigationStackCoordinator.rootCoordinator)
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, 0)
    }
    
    /// Tests the child flow teardown in isolation of it's parent.
    func testChildFlowTearDown() async throws {
        await setupViewModel(asChildFlow: true)
        navigationStackCoordinator.setRootCoordinator(BlankFormCoordinator())
        
        try await process(route: .room(roomID: "1"))
        try await process(route: .roomDetails(roomID: "1"))
        XCTAssertTrue(navigationStackCoordinator.rootCoordinator is BlankFormCoordinator, "A child room flow should push onto the stack, leaving the root alone.")
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, 2)
        XCTAssertTrue(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        XCTAssertTrue(navigationStackCoordinator.stackCoordinators.last is RoomDetailsScreenCoordinator)
        
        try await process(route: .roomList, expectedAction: .finished)
        XCTAssertTrue(navigationStackCoordinator.rootCoordinator is BlankFormCoordinator)
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, 2, "A child room flow should leave its parent to clean up the stack.")
        XCTAssertTrue(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator, "A child room flow should leave its parent to clean up the stack.")
        XCTAssertTrue(navigationStackCoordinator.stackCoordinators.last is RoomDetailsScreenCoordinator, "A child room flow should leave its parent to clean up the stack.")
    }
    
    func testChildRoomMemberDetails() async throws {
        await setupViewModel()
        
        try await process(route: .room(roomID: "1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, 0)
        
        try await process(route: .childRoom(roomID: "2"))
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, 1)
        XCTAssert(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        
        try await process(route: .roomMemberDetails(userID: RoomMemberProxyMock.mockMe.userID))
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, 2)
        XCTAssert(navigationStackCoordinator.stackCoordinators.first is RoomScreenCoordinator)
        XCTAssert(navigationStackCoordinator.stackCoordinators.last is RoomMemberDetailsScreenCoordinator)
    }
    
    // MARK: - Private
    
    private func process(route: AppRoute) async throws {
        roomFlowCoordinator.handleAppRoute(route, animated: true)
        await Task.yield()
    }
    
    private func process(route: AppRoute, expectedAction: RoomFlowCoordinatorAction) async throws {
        try await process(route: route, expectedActions: [expectedAction])
    }
    
    private func process(route: AppRoute, expectedActions: [RoomFlowCoordinatorAction]) async throws {
        guard !expectedActions.isEmpty else {
            return
        }
        
        var fulfillments = [DeferredFulfillment<RoomFlowCoordinatorAction>]()
        
        for expectedAction in expectedActions {
            fulfillments.append(deferFulfillment(roomFlowCoordinator.actions) { action in
                action == expectedAction
            })
        }
        
        roomFlowCoordinator.handleAppRoute(route, animated: true)
        
        for fulfillment in fulfillments {
            try await fulfillment.fulfill()
        }
    }
    
    private func setupViewModel(asChildFlow: Bool = false) async {
        cancellables.removeAll()
        let clientProxy = ClientProxyMock(.init(userID: "hi@bob", roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))))
        let mediaProvider = MockMediaProvider()
        let voiceMessageMediaManager = VoiceMessageMediaManagerMock()
        let userSession = MockUserSession(clientProxy: clientProxy,
                                          mediaProvider: mediaProvider,
                                          voiceMessageMediaManager: voiceMessageMediaManager)
        
        let navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator())
        navigationStackCoordinator = NavigationStackCoordinator()
        navigationSplitCoordinator.setDetailCoordinator(navigationStackCoordinator)
        
        roomFlowCoordinator = await RoomFlowCoordinator(roomProxy: RoomProxyMock(with: .init(id: "1")),
                                                        userSession: userSession,
                                                        isChildFlow: asChildFlow,
                                                        roomTimelineControllerFactory: MockRoomTimelineControllerFactory(),
                                                        navigationStackCoordinator: navigationStackCoordinator,
                                                        emojiProvider: EmojiProvider(),
                                                        appSettings: ServiceLocator.shared.settings,
                                                        analytics: ServiceLocator.shared.analytics,
                                                        userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                        orientationManager: OrientationManagerMock())
    }
}

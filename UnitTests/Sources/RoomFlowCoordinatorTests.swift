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
    private var cancellables: Set<AnyCancellable> = .init()
    
    override func setUp() async throws {
        let clientProxy = MockClientProxy(userID: "hi@bob", roomSummaryProvider: MockRoomSummaryProvider(state: .loaded(.mockRooms)))
        let mediaProvider = MockMediaProvider()
        let userSession = MockUserSession(clientProxy: clientProxy, mediaProvider: mediaProvider)
        
        let navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: SplashScreenCoordinator())
        navigationStackCoordinator = NavigationStackCoordinator()
        navigationSplitCoordinator.setDetailCoordinator(navigationStackCoordinator)
        
        roomFlowCoordinator = RoomFlowCoordinator(userSession: userSession,
                                                  roomTimelineControllerFactory: MockRoomTimelineControllerFactory(),
                                                  navigationStackCoordinator: navigationStackCoordinator,
                                                  navigationSplitCoordinator: navigationSplitCoordinator,
                                                  emojiProvider: EmojiProvider())
    }
    
    func testRoomPresentation() async {
        await process(route: .room(roomID: "1"), expectedAction: .presentedRoom("1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        
        await process(route: .roomList, expectedAction: .dismissedRoom)
        XCTAssertNil(navigationStackCoordinator.rootCoordinator)
        
        await process(route: .room(roomID: "1"), expectedAction: .presentedRoom("1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        
        await process(route: .room(roomID: "2"), expectedAction: .presentedRoom("2"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        
        await process(route: .roomList, expectedAction: .dismissedRoom)
        XCTAssertNil(navigationStackCoordinator.rootCoordinator)
    }
    
    func testRoomDetailsPresentation() async {
        await process(route: .roomDetails(roomID: "1"), expectedAction: .presentedRoom("1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        
        await process(route: .roomList, expectedAction: .dismissedRoom)
        XCTAssertNil(navigationStackCoordinator.rootCoordinator)
    }
    
    func testStackUnwinding() async {
        await process(route: .roomDetails(roomID: "1"), expectedAction: .presentedRoom("1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        
        await process(route: .room(roomID: "2"), expectedAction: .presentedRoom("2"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
    }
    
    func testNoOp() async {
        await process(route: .roomDetails(roomID: "1"), expectedAction: .presentedRoom("1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        roomFlowCoordinator.handleAppRoute(.roomDetails(roomID: "1"), animated: true)
        await Task.yield()
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
    }
    
    func testSwitchToDifferentDetails() async {
        await process(route: .roomDetails(roomID: "1"), expectedAction: .presentedRoom("1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        
        await process(route: .roomDetails(roomID: "2"), expectedAction: .presentedRoom("2"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
    }
    
    func testPushDetails() async {
        await process(route: .room(roomID: "1"), expectedAction: .presentedRoom("1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        
        await process(route: .roomDetails(roomID: "1"), expectedAction: nil)
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
        XCTAssertEqual(navigationStackCoordinator.stackCoordinators.count, 1)
        XCTAssert(navigationStackCoordinator.stackCoordinators.first is RoomDetailsScreenCoordinator)
    }
    
    func testReplaceDetailsWithTimeline() async {
        await process(route: .roomDetails(roomID: "1"), expectedAction: .presentedRoom("1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomDetailsScreenCoordinator)
        
        await process(route: .room(roomID: "1"), expectedAction: .presentedRoom("1"))
        XCTAssert(navigationStackCoordinator.rootCoordinator is RoomScreenCoordinator)
    }
    
    // MARK: - Private
    
    func process(route: AppRoute, expectedAction: RoomFlowCoordinatorAction?) async {
        let routeTask = Task.detached(priority: .low) {
            try? await Task.sleep(for: .milliseconds(500))
            await self.roomFlowCoordinator.handleAppRoute(route, animated: true)
        }
        
        if let expectedAction {
            await roomFlowCoordinator.actions.values.first(where: { $0 == expectedAction })
        } else {
            await roomFlowCoordinator.actions.values.first()
        }
    }
}

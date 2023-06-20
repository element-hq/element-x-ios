//
// Copyright 2022 New Vector Ltd
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

import Combine
import XCTest

@testable import ElementX

@MainActor
class HomeScreenViewModelTests: XCTestCase {
    var viewModel: HomeScreenViewModelProtocol!
    var clientProxy: MockClientProxy!
    
    var context: HomeScreenViewModelType.Context! {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        clientProxy = MockClientProxy(userID: "@mock:client.com")
        viewModel = HomeScreenViewModel(userSession: MockUserSession(clientProxy: clientProxy,
                                                                     mediaProvider: MockMediaProvider()),
                                        attributedStringBuilder: AttributedStringBuilder(),
                                        selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher())
    }
    
    func testSelectRoom() async throws {
        let mockRoomId = "mock_room_id"
        var correctResult = false
        var selectedRoomId = ""
        viewModel.callback = { result in
            switch result {
            case .presentRoom(let roomId):
                correctResult = true
                selectedRoomId = roomId
            default:
                break
            }
        }

        context.send(viewAction: .selectRoom(roomIdentifier: mockRoomId))
        await Task.yield()
        XCTAssert(correctResult)
        XCTAssertEqual(mockRoomId, selectedRoomId)
    }

    func testTapUserAvatar() async throws {
        var correctResult = false
        viewModel.callback = { result in
            switch result {
            case .presentSettingsScreen:
                correctResult = true
            default:
                break
            }
        }

        context.send(viewAction: .userMenu(action: .settings))
        await Task.yield()
        XCTAssert(correctResult)
    }
    
    func testLeaveRoomAlert() async throws {
        let mockRoomId = "1"
        clientProxy.roomForIdentifierMocks[mockRoomId] = .init(with: .init(id: mockRoomId, displayName: "Some room"))
        context.send(viewAction: .leaveRoom(roomIdentifier: mockRoomId))
        await context.nextViewState()
        XCTAssertEqual(context.leaveRoomAlertItem?.roomId, mockRoomId)
    }
    
    func testLeaveRoomError() async throws {
        let mockRoomId = "1"
        let room: RoomProxyMock = .init(with: .init(id: mockRoomId, displayName: "Some room"))
        room.leaveRoomClosure = { .failure(.failedLeavingRoom) }
        clientProxy.roomForIdentifierMocks[mockRoomId] = room
        context.send(viewAction: .confirmLeaveRoom(roomIdentifier: mockRoomId))
        await context.nextViewState()
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testLeaveRoomSuccess() async throws {
        let mockRoomId = "1"
        var correctResult = false
        viewModel.callback = { result in
            switch result {
            case .roomLeft(let roomIdentifier):
                correctResult = roomIdentifier == mockRoomId
            default:
                break
            }
        }
        let room: RoomProxyMock = .init(with: .init(id: mockRoomId, displayName: "Some room"))
        room.leaveRoomClosure = { .success(()) }
        clientProxy.roomForIdentifierMocks[mockRoomId] = room
        context.send(viewAction: .confirmLeaveRoom(roomIdentifier: mockRoomId))
        await Task.yield()
        XCTAssertNil(context.alertInfo)
        XCTAssertTrue(correctResult)
    }
    
    func testShowRoomDetails() async throws {
        let mockRoomId = "1"
        var correctResult = false
        viewModel.callback = { result in
            switch result {
            case .presentRoomDetails(let roomIdentifier):
                correctResult = roomIdentifier == mockRoomId
            default:
                break
            }
        }
        context.send(viewAction: .showRoomDetails(roomIdentifier: mockRoomId))
        await Task.yield()
        XCTAssertNil(context.alertInfo)
        XCTAssertTrue(correctResult)
    }
}

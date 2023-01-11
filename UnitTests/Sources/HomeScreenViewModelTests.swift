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

import XCTest

@testable import ElementX

class HomeScreenViewModelTests: XCTestCase {
    var viewModel: HomeScreenViewModelProtocol!
    var context: HomeScreenViewModelType.Context!
    
    @MainActor override func setUpWithError() throws {
        viewModel = HomeScreenViewModel(userSession: MockUserSession(clientProxy: MockClientProxy(userIdentifier: "@mock:client.com"),
                                                                     mediaProvider: MockMediaProvider()),
                                        attributedStringBuilder: AttributedStringBuilder())
        context = viewModel.context
    }
    
    @MainActor func testSelectRoom() async throws {
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

    @MainActor func testTapUserAvatar() async throws {
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
}

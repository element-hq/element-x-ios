// 
// Copyright 2021 New Vector Ltd
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

    override func setUpWithError() throws {
        viewModel = HomeScreenViewModel(attributedStringBuilder: AttributedStringBuilder())
        context = viewModel.context
    }

    func testLogout() throws {
        var correctResult = false
        self.viewModel.completion = { result in
            switch result {
            case .logout:
                correctResult = true
            default:
                break
            }
        }

        context.send(viewAction: .logout)
        async { expectation in
            XCTAssert(correctResult)
            expectation.fulfill()
        }
    }

    func testSelectRoom() throws {
        let mockRoomId = "mock_room_id"
        var correctResult = false
        var selectedRoomId = ""
        self.viewModel.completion = { result in
            switch result {
            case .selectRoom(let roomId):
                correctResult = true
                selectedRoomId = roomId
            default:
                break
            }
        }

        context.send(viewAction: .selectRoom(roomIdentifier: mockRoomId))
        async { expectation in
            XCTAssert(correctResult)
            XCTAssertEqual(mockRoomId, selectedRoomId)
            expectation.fulfill()
        }
    }

    func testTapUserAvatar() throws {
        var correctResult = false
        self.viewModel.completion = { result in
            switch result {
            case .tapUserAvatar:
                correctResult = true
            default:
                break
            }
        }

        context.send(viewAction: .tapUserAvatar)
        async { expectation in
            XCTAssert(correctResult)
            expectation.fulfill()
        }
    }

    private func async(_ timeout: TimeInterval = 0.5, _ block: @escaping (XCTestExpectation) -> Void) {
        let waiter = XCTWaiter()
        let expectation = XCTestExpectation(description: "Async operation expectation")
        block(expectation)
        waiter.wait(for: [expectation], timeout: timeout)
    }
}

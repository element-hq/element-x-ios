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

@MainActor
class RoomDetailsScreenViewModelTests: XCTestCase {
    var viewModel: RoomDetailsViewModelProtocol!
    var context: RoomDetailsViewModelType.Context!
    var roomProxyMock: RoomProxyMock!

    override func setUp() {
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test"))
        viewModel = RoomDetailsViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        context = viewModel.context
    }

    func testLeaveRoomTapped() {
        context.send(viewAction: .processTapLeave)
        XCTAssertNotNil(context.leaveRoomAlertItem)
    }

    func testLeaveRoomSuccess() async {
        roomProxyMock.leaveRoomClosure = {
            .success(())
        }
        viewModel.callback = { action in
            switch action {
            case .leftRoom:
                break
            default:
                XCTFail("leaveRoom expected")
            }
        }
        context.send(viewAction: .confirmLeave)
        await Task.yield()
        XCTAssertEqual(roomProxyMock.leaveRoomCallsCount, 1)
    }

    func testLeaveRoomError() async {
        roomProxyMock.leaveRoomClosure = {
            .failure(.failedLeavingRoom)
        }
        context.send(viewAction: .confirmLeave)
        await Task.yield()
        XCTAssertEqual(roomProxyMock.leaveRoomCallsCount, 1)
        XCTAssertNotNil(context.alertInfo)
    }
}

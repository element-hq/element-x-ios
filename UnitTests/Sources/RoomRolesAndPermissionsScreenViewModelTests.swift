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
class RoomRolesAndPermissionsScreenViewModelTests: XCTestCase {
    var viewModel: RoomRolesAndPermissionsScreenViewModelProtocol!
    
    var context: RoomRolesAndPermissionsScreenViewModelType.Context {
        viewModel.context
    }

    func testEmptyCounters() {
        viewModel = RoomRolesAndPermissionsScreenViewModel(roomProxy: RoomProxyMock(with: .init()))
        XCTAssertEqual(context.viewState.administratorCount, 0)
        XCTAssertEqual(context.viewState.moderatorCount, 0)
    }

    func testFilledCounters() async throws {
        viewModel = RoomRolesAndPermissionsScreenViewModel(roomProxy: RoomProxyMock(with: .init(members: .allMembersAsAdmin)))
        XCTAssertEqual(context.viewState.administratorCount, 2)
        XCTAssertEqual(context.viewState.moderatorCount, 1)
    }
}

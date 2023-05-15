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

import ElementX
import XCTest

@MainActor
class RoomMemberDetailsScreenUITests: XCTestCase {
    func testInitialStateComponentsForAccountOwner() async throws {
        let app = Application.launch(.roomMemberDetailsAccountOwner)

        XCTAssertFalse(app.buttons[A11yIdentifiers.roomMemberDetailsScreen.ignore].exists)
        XCTAssertFalse(app.buttons[A11yIdentifiers.roomMemberDetailsScreen.unignore].exists)
        try await app.assertScreenshot(.roomMemberDetailsAccountOwner)
    }

    func testInitialStateComponents() async throws {
        let app = Application.launch(.roomMemberDetails)

        XCTAssert(app.buttons[A11yIdentifiers.roomMemberDetailsScreen.ignore].waitForExistence(timeout: 1))
        XCTAssertFalse(app.buttons[A11yIdentifiers.roomMemberDetailsScreen.unignore].exists)
        try await app.assertScreenshot(.roomMemberDetails)
    }

    func testInitialStateComponentsForIgnoredUser() async throws {
        let app = Application.launch(.roomMemberDetailsIgnoredUser)

        XCTAssertFalse(app.buttons[A11yIdentifiers.roomMemberDetailsScreen.ignore].exists)
        XCTAssert(app.buttons[A11yIdentifiers.roomMemberDetailsScreen.unignore].waitForExistence(timeout: 1))
        try await app.assertScreenshot(.roomMemberDetailsIgnoredUser)
    }
}

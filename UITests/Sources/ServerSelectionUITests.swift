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
class ServerSelectionUITests: XCTestCase {
    func testNormalState() async throws {
        // Given the initial server selection screen as a modal.
        let app = Application.launch(.serverSelection)
        
        // Then it should be configured for matrix.org
        try await app.assertScreenshot(.serverSelection, step: 0)
    }

    func testEmptyAddress() async throws {
        // Given the initial server selection screen as a modal.
        let app = Application.launch(.serverSelection)
        
        // When clearing the server address text field.
        app.textFields[A11yIdentifiers.changeServerScreen.server].tap()
        app.textFields[A11yIdentifiers.changeServerScreen.server].buttons.element.tap()
        
        // Then the screen should not allow the user to continue.
        try await app.assertScreenshot(.serverSelection, step: 1)
    }

    func testInvalidAddress() async throws {
        // Given the initial server selection screen as a modal.
        let app = Application.launch(.serverSelection)
        
        // When typing in an invalid homeserver
        app.textFields[A11yIdentifiers.changeServerScreen.server].clearAndTypeText("thisisbad\n") // The tests only accept an address from LoginHomeserver.mockXYZ
        
        // Then an error should be shown and the confirmation button disabled.
        try await app.assertScreenshot(.serverSelection, step: 2)
        XCTAssertFalse(app.buttons[A11yIdentifiers.changeServerScreen.continue].isEnabled, "The continue button should be disabled when there is an error.")
    }

    func testNonModalPresentation() async throws {
        // Given the initial server selection screen pushed onto the stack.
        let app = Application.launch(.serverSelectionNonModal)
        
        // Then the screen should be tweaked slightly to reflect the change of navigation.
        try await app.assertScreenshot(.serverSelectionNonModal)
        XCTAssertFalse(app.buttons[A11yIdentifiers.changeServerScreen.dismiss].exists, "The dismiss button should be hidden when not in modal presentation.")
    }
}

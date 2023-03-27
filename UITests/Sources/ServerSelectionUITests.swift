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
    func testNormalState() async {
        // Given the initial server selection screen as a modal.
        let app = Application.launch(.serverSelection)
        
        // Then it should be configured for matrix.org
        app.assertScreenshot(.serverSelection, step: 0)
        XCTAssertEqual(app.textFields[A11yIdentifiers.changeServerScreen.server].value as? String, "matrix.org", "The server shown should be matrix.org with the https scheme hidden.")
        XCTAssertEqual(app.buttons[A11yIdentifiers.changeServerScreen.continue].label, L10n.actionContinue, "The confirm button should say Confirm when in modal presentation.")
    }

    func testEmptyAddress() async {
        // Given the initial server selection screen as a modal.
        let app = Application.launch(.serverSelection)
        
        // When clearing the server address text field.
        app.textFields[A11yIdentifiers.changeServerScreen.server].tap()
        app.textFields[A11yIdentifiers.changeServerScreen.server].buttons.element.tap()
        
        // Then the screen should not allow the user to continue.
        app.assertScreenshot(.serverSelection, step: 1)
        XCTAssertEqual(app.textFields[A11yIdentifiers.changeServerScreen.server].value as? String, L10n.commonServerUrl, "The text field should show placeholder text in this state.")
        XCTAssertFalse(app.buttons[A11yIdentifiers.changeServerScreen.continue].isEnabled, "The confirm button should be disabled when the address is empty.")
    }

    func testInvalidAddress() {
        // Given the initial server selection screen as a modal.
        let app = Application.launch(.serverSelection)
        
        // When typing in an invalid homeserver
        app.textFields[A11yIdentifiers.changeServerScreen.server].clearAndTypeText("thisisbad\n") // The tests only accept an address from LoginHomeserver.mockXYZ
        
        // Then an error should be shown and the confirmation button disabled.
        app.assertScreenshot(.serverSelection, step: 2)
        XCTAssertTrue(app.staticTexts[L10n.screenChangeServerErrorInvalidHomeserver].exists)
        XCTAssertFalse(app.buttons[A11yIdentifiers.changeServerScreen.continue].isEnabled, "The confirm button should be disabled when there is an error.")
    }

    func testNonModalPresentation() {
        // Given the initial server selection screen pushed onto the stack.
        let app = Application.launch(.serverSelectionNonModal)
        
        // Then the screen should be tweaked slightly to reflect the change of navigation.
        app.assertScreenshot(.serverSelectionNonModal)
        XCTAssertFalse(app.buttons[A11yIdentifiers.changeServerScreen.dismiss].exists, "The dismiss button should be hidden when not in modal presentation.")
        XCTAssertEqual(app.buttons[A11yIdentifiers.changeServerScreen.continue].label, L10n.actionNext, "The confirm button should say Next when not in modal presentation.")
    }
}

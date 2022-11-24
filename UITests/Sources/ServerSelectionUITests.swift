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
    let textFieldIdentifier = "addressTextField"
    
    func testNormalState() async {
        // Given the initial server selection screen as a modal.
        let app = Application.launch()
        app.goToScreenWithIdentifier(.serverSelection)
        
        // Then it should be configured for matrix.org and with a cancel button
        let serverTextField = app.textFields[textFieldIdentifier]
        XCTAssertEqual(serverTextField.value as? String, "matrix.org", "The server shown should be matrix.org with the https scheme hidden.")

        let confirmButton = app.buttons["confirmButton"]
        XCTAssertEqual(confirmButton.label, ElementL10n.actionConfirm, "The confirm button should say Confirm when in modal presentation.")
        XCTAssertTrue(confirmButton.exists, "The confirm button should always be shown.")
        XCTAssertTrue(confirmButton.isEnabled, "The confirm button should be enabled when there is an address.")

        XCTAssertTrue(app.staticTexts[ElementL10n.serverSelectionServerFooter].exists)

        let dismissButton = app.buttons["dismissButton"]
        XCTAssertTrue(dismissButton.exists, "The dismiss button should be shown during modal presentation.")

        app.assertScreenshot(.serverSelection)
    }

    func testEmptyAddress() async {
        // Given the initial server selection screen as a modal.
        let app = Application.launch()
        app.goToScreenWithIdentifier(.serverSelection)
        
        // When clearing the server address text field.
        app.textFields[textFieldIdentifier].tap()
        app.textFields[textFieldIdentifier].buttons.element.tap()
        
        // Then the screen should not allow the user to continue.
        XCTAssertEqual(app.textFields[textFieldIdentifier].value as? String, ElementL10n.ftueAuthChooseServerEntryHint, "The text field should show placeholder text in this state.")

        let confirmButton = app.buttons["confirmButton"]
        XCTAssertTrue(confirmButton.exists, "The confirm button should always be shown.")
        XCTAssertFalse(confirmButton.isEnabled, "The confirm button should be disabled when the address is empty.")
    }

    func testInvalidAddress() {
        // Given the initial server selection screen as a modal.
        let app = Application.launch()
        app.goToScreenWithIdentifier(.serverSelection)
        
        // When typing in an invalid homeserver
        app.textFields[textFieldIdentifier].tap()
        app.textFields.element.buttons.element.tap()
        app.typeText("thisisbad\n") // The tests only accept an address from LoginHomeserver.mockXYZ
        
        // Then an error should be shown and the confirmation button disabled.
        XCTAssertEqual(app.textFields[textFieldIdentifier].value as? String, "thisisbad", "The text field should show the entered server.")

        let confirmButton = app.buttons["confirmButton"]
        XCTAssertTrue(confirmButton.exists, "The confirm button should always be shown.")
        XCTAssertFalse(confirmButton.isEnabled, "The confirm button should be disabled when there is an error.")

        XCTAssertTrue(app.staticTexts[ElementL10n.loginErrorHomeserverNotFound].exists)
    }

    func testNonModalPresentation() {
        // Given the initial server selection screen pushed onto the stack.
        let app = Application.launch()
        app.goToScreenWithIdentifier(.serverSelectionNonModal)
        
        // Then the screen should be tweaked slightly to reflect the change of navigation.
        let dismissButton = app.buttons["dismissButton"]
        XCTAssertFalse(dismissButton.exists, "The dismiss button should be hidden when not in modal presentation.")

        let confirmButton = app.buttons["confirmButton"]
        XCTAssertEqual(confirmButton.label, ElementL10n.actionNext, "The confirm button should say Next when not in modal presentation.")

        app.assertScreenshot(.serverSelectionNonModal)
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class ServerSelectionViewModelTests: XCTestCase {
    var viewModel: ServerSelectionScreenViewModelProtocol!
    var context: ServerSelectionScreenViewModelType.Context!
    
    @MainActor override func setUp() {
        viewModel = ServerSelectionScreenViewModel(homeserverAddress: "",
                                                   slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL,
                                                   isModallyPresented: true)
        context = viewModel.context
    }

    func testErrorMessage() async throws {
        // Given a new instance of the view model.
        XCTAssertNil(context.viewState.footerErrorMessage, "There should not be an error message for a new view model.")
        XCTAssertEqual(String(context.viewState.footerMessage.characters), L10n.screenChangeServerFormNotice(L10n.actionLearnMore),
                       "The standard footer message should be shown.")
        
        // When an error occurs.
        let message = "Unable to contact server."
        viewModel.displayError(.footerMessage(message))
        
        // Then the footer should now be showing an error.
        XCTAssertEqual(context.viewState.footerErrorMessage, message, "The error message should be stored.")
        XCTAssertEqual(String(context.viewState.footerMessage.characters), message, "The error message should be shown.")
        
        // And when clearing the error.
        context.send(viewAction: .clearFooterError)
        
        // Wait for the action to spawn a Task.
        await Task.yield()
        
        // Then the error message should now be removed.
        XCTAssertNil(context.viewState.footerErrorMessage, "The error message should have been cleared.")
        XCTAssertEqual(String(context.viewState.footerMessage.characters), L10n.screenChangeServerFormNotice(L10n.actionLearnMore),
                       "The standard footer message should be shown again.")
    }
}

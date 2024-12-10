//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class SecurityAndPrivacyScreenViewModelTests: XCTestCase {
    var viewModel: SecurityAndPrivacyScreenViewModelProtocol!
    
    var context: SecurityAndPrivacyScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        viewModel = SecurityAndPrivacyScreenViewModel()
    }

    func testInitialState() {
        XCTAssertFalse(context.viewState.placeholder.isEmpty)
        XCTAssertFalse(context.composerText.isEmpty)
    }

    func testCounter() async throws {
        context.composerText = "123"
        context.send(viewAction: .textChanged)
        XCTAssertEqual(context.composerText, "123")
    }
}

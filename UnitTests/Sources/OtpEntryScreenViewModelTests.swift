//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class OtpEntryScreenViewModelTests: XCTestCase {
    var viewModel: OtpEntryScreenViewModel!

    var context: OtpEntryScreenViewModelType.Context {
        viewModel.context
    }

    override func setUpWithError() throws {
        viewModel = OtpEntryScreenViewModel(phoneNumber: "+15551234567", initialResendCountdown: 0)
    }

    func testInitialState() {
        XCTAssertEqual(context.viewState.phoneNumber, "+15551234567")
        XCTAssertTrue(context.viewState.bindings.code.isEmpty)
        XCTAssertFalse(context.viewState.canVerify)
        XCTAssertTrue(context.viewState.canResend)
    }

    func testCodeSanitisation() async throws {
        context.code = "12-3a4 5b6"
        context.send(viewAction: .codeChanged)
        XCTAssertEqual(context.code, "123456")
    }

    func testFullCodeAutoSubmits() async throws {
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            if case .verify(let code) = action, code == "123456" { return true }
            return false
        }
        context.code = "123456"
        context.send(viewAction: .codeChanged)
        try await deferred.fulfill()
    }

    func testResendBlockedByCountdown() async throws {
        viewModel = OtpEntryScreenViewModel(phoneNumber: "+15551234567", initialResendCountdown: 30)
        XCTAssertFalse(context.viewState.canResend)
    }
}

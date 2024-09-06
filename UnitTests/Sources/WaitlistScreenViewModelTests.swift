//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class WaitlistScreenViewModelTests: XCTestCase {
    var viewModel: WaitlistScreenViewModelProtocol!
    var context: WaitlistScreenViewModelType.Context { viewModel.context }
    
    override func setUpWithError() throws {
        viewModel = WaitlistScreenViewModel(homeserver: .mockMatrixDotOrg)
    }

    func testSuccess() async throws {
        XCTAssertNil(context.viewState.userSession, "No user session should be set on a new view model.")
        XCTAssertTrue(context.viewState.isWaiting, "The view should start off in the waiting state.")
        
        viewModel.update(userSession: UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@alice:matrix.org")))))
        
        XCTAssertNotNil(context.viewState.userSession, "The user session should have been updated.")
        XCTAssertFalse(context.viewState.isWaiting, "The view should not be in the waiting state after setting a user session.")
    }
}

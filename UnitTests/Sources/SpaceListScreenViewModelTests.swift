//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class SpaceListScreenViewModelTests: XCTestCase {
    var viewModel: SpaceListScreenViewModelProtocol!
    
    var context: SpaceListScreenViewModelType.Context {
        viewModel.context
    }

    func testInitialState() {
        setupViewModel()
        XCTAssertTrue(context.viewState.rooms.isEmpty)
        XCTAssertEqual(context.viewState.joinedRoomsCount, 0)
    }
    
    // MARK: - Helpers
    
    private func setupViewModel() {
        let clientProxy = ClientProxyMock(.init())
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        viewModel = SpaceListScreenViewModel(userSession: userSession)
    }
}

//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class SpaceScreenViewModelTests: XCTestCase {
    var viewModel: SpaceScreenViewModelProtocol!
    
    var context: SpaceScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        viewModel = SpaceScreenViewModel(spaceRoomList: SpaceRoomListProxyMock(.init(spaceRoomProxy: SpaceRoomProxyMock(.init(isSpace: true)))),
                                         mediaProvider: MediaProviderMock(configuration: .init()))
    }

    func testInitialState() {
        XCTAssertFalse(context.viewState.isPaginating)
    }
}

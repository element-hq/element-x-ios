//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class KnockRequestsListScreenViewModelTests: XCTestCase {
    var viewModel: KnockRequestsListScreenViewModelProtocol!
    
    var context: KnockRequestsListScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        viewModel = KnockRequestsListScreenViewModel(roomProxy: JoinedRoomProxyMock(.init()),
                                                     mediaProvider: MediaProviderMock(),
                                                     userIndicatorController: UserIndicatorControllerMock())
    }
}

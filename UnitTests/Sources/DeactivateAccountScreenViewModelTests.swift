//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class DeactivateAccountScreenViewModelTests: XCTestCase {
    var viewModel: DeactivateAccountScreenViewModelProtocol!
    
    var context: DeactivateAccountScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        viewModel = DeactivateAccountScreenViewModel(clientProxy: ClientProxyMock(.init()), userIndicatorController: UserIndicatorControllerMock())
    }
}

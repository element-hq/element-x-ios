//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ManageWalletsCoordinatorParameters {
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

final class ManageWalletsCoordinator: CoordinatorProtocol {
    private var viewModel: ManageWalletsViewModelProtocol
    
    init(parameters: ManageWalletsCoordinatorParameters) {
        viewModel = ManageWalletsViewModel(userSession: parameters.userSession, userIndicatorController: parameters.userIndicatorController)
    }
            
    func toPresentable() -> AnyView {
        AnyView(ManageWalletsScreen(context: viewModel.context))
    }
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ModerationAndSafetySettingsScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

final class ModerationAndSafetySettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: ModerationAndSafetySettingsScreenViewModelProtocol
    
    init(parameters: ModerationAndSafetySettingsScreenCoordinatorParameters) {
        viewModel = ModerationAndSafetySettingsScreenViewModel(userSession: parameters.userSession,
                                                               userIndicatorController: parameters.userIndicatorController)
    }
    
    func toPresentable() -> AnyView {
        AnyView(ModerationAndSafetySettingsScreen(context: viewModel.context))
    }
}

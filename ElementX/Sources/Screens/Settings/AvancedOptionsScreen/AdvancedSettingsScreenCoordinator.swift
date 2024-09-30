//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

final class AdvancedSettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AdvancedSettingsScreenViewModelProtocol
    
    init() {
        viewModel = AdvancedSettingsScreenViewModel(advancedSettings: ServiceLocator.shared.settings)
    }
            
    func toPresentable() -> AnyView {
        AnyView(AdvancedSettingsScreen(context: viewModel.context))
    }
}

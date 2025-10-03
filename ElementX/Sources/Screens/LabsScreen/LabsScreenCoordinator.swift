//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all - this is just a labs remove this comment once generating the final file

import Combine
import SwiftUI

struct LabsScreenCoordinatorParameters {
    let appSettings: AppSettings
}

final class LabsScreenCoordinator: CoordinatorProtocol {
    private let viewModel: LabsScreenViewModelProtocol
    
    init(parameters: LabsScreenCoordinatorParameters) {
        viewModel = LabsScreenViewModel(labsOptions: parameters.appSettings)
    }
    
    func start() { }
        
    func toPresentable() -> AnyView {
        AnyView(LabsScreen(context: viewModel.context))
    }
}

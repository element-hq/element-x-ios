//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct BlockedUsersScreenCoordinatorParameters {
    let hideProfiles: Bool
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

final class BlockedUsersScreenCoordinator: CoordinatorProtocol {
    private let viewModel: BlockedUsersScreenViewModelProtocol
    
    init(parameters: BlockedUsersScreenCoordinatorParameters) {
        viewModel = BlockedUsersScreenViewModel(hideProfiles: parameters.hideProfiles,
                                                userSession: parameters.userSession,
                                                userIndicatorController: parameters.userIndicatorController)
    }
    
    func stop() {
        viewModel.stop()
    }
        
    func toPresentable() -> AnyView {
        AnyView(BlockedUsersScreen(context: viewModel.context))
    }
}

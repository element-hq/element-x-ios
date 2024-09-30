//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct BlockedUsersScreenCoordinatorParameters {
    let hideProfiles: Bool
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

final class BlockedUsersScreenCoordinator: CoordinatorProtocol {
    private let viewModel: BlockedUsersScreenViewModelProtocol
    
    init(parameters: BlockedUsersScreenCoordinatorParameters) {
        viewModel = BlockedUsersScreenViewModel(hideProfiles: parameters.hideProfiles,
                                                clientProxy: parameters.clientProxy,
                                                mediaProvider: parameters.mediaProvider,
                                                userIndicatorController: parameters.userIndicatorController)
    }
    
    func stop() {
        viewModel.stop()
    }
        
    func toPresentable() -> AnyView {
        AnyView(BlockedUsersScreen(context: viewModel.context))
    }
}

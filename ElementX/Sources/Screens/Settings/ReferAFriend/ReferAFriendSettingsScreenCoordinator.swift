//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ReferAFriendSettingsScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
}

final class ReferAFriendSettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: ReferAFriendSettingsScreenViewModelProtocol
    
    init(parameters: ReferAFriendSettingsScreenCoordinatorParameters) {
        viewModel = ReferAFriendSettingsScreenViewModel(userSession: parameters.userSession)
    }
            
    func toPresentable() -> AnyView {
//        AnyView(ReferAFriendSettingsScreen(context: viewModel.context))
        AnyView(EmptyView())
    }
}

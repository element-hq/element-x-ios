//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ZeroProSubcriptionScreenCoordinatorParams {
    let userSession: UserSessionProtocol
}

final class ZeroProSubcriptionScreenCoordinator: CoordinatorProtocol {
    private var viewModel: ZeroProSubcriptionScreenViewModel
    
    init(parameters: ZeroProSubcriptionScreenCoordinatorParams) {
        viewModel = ZeroProSubcriptionScreenViewModel(userSession: parameters.userSession)
    }
            
    func toPresentable() -> AnyView {
        AnyView(ZeroProSubcriptionScreenView(context: viewModel.context))
    }
}

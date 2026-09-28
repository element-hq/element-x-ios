//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ElementCall
import SwiftUI

struct NativeCallScreenCoordinatorParameters {
    let controller: ElementCallController
}

final class NativeCallScreenCoordinator: CoordinatorProtocol {
    private let viewModel: ElementCallScreenViewModel
    
    init(parameters: NativeCallScreenCoordinatorParameters) {
        viewModel = ElementCallScreenViewModel(controller: parameters.controller)
    }
    
    func toPresentable() -> AnyView {
        AnyView(ElementCallScreen(viewModel: viewModel))
    }
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ElementCallAll
import SwiftUI

struct NativeCallScreenCoordinatorParameters {
    /// Session-scoped, and owned by the flow coordinator: the call outlives this screen.
    let controller: ElementCallController
}

/// Hosts the call package's screen.
///
/// Deliberately thin. There is no view model of its own and no actions to forward, because the call
/// is a fact about the session rather than about this screen, and the flow coordinator listens to
/// the controller directly. All this owns is the package view model's lifetime, which is why the
/// package takes one rather than building its own.
final class NativeCallScreenCoordinator: CoordinatorProtocol {
    private let viewModel: ElementCallScreenViewModel
    
    init(parameters: NativeCallScreenCoordinatorParameters) {
        viewModel = ElementCallScreenViewModel(controller: parameters.controller)
    }
    
    func toPresentable() -> AnyView {
        AnyView(ElementCallScreen(viewModel: viewModel))
    }
}

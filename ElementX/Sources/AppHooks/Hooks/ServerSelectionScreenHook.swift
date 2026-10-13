//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum ServerSelectionSupplementaryFlowAction {
    case finished
}

@MainActor protocol ServerSelectionSupplementaryFlowCoordinatorProtocol: FlowCoordinatorProtocol where Action == ServerSelectionSupplementaryFlowAction { }

nonisolated protocol ServerSelectionScreenHookProtocol: Sendable {
    @MainActor func additionalButtons(authenticationFlow: AuthenticationFlow, action: @escaping () -> Void) -> AnyView?
    @MainActor func makeSupplementaryFlowCoordinator(navigationStackCoordinator: NavigationStackCoordinator) -> (any ServerSelectionSupplementaryFlowCoordinatorProtocol)?
}

struct DefaultServerSelectionScreenHook: ServerSelectionScreenHookProtocol {
    func additionalButtons(authenticationFlow: AuthenticationFlow, action: @escaping () -> Void) -> AnyView? {
        nil
    }
    
    func makeSupplementaryFlowCoordinator(navigationStackCoordinator: NavigationStackCoordinator) -> (any ServerSelectionSupplementaryFlowCoordinatorProtocol)? {
        nil
    }
}

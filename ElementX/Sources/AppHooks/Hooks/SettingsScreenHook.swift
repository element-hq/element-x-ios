//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum SettingsSupplementaryFlowAction {
    case finished
}

@MainActor protocol SettingsSupplementaryFlowCoordinatorProtocol: FlowCoordinatorProtocol where Action == SettingsSupplementaryFlowAction { }

nonisolated protocol SettingsScreenHookProtocol: Sendable {
    @MainActor func supplementaryRows(action: @escaping (String) -> Void) -> AnyView?
    @MainActor func makeSupplementaryFlowCoordinator(flowID: String, navigationStackCoordinator: NavigationStackCoordinator) -> (any SettingsSupplementaryFlowCoordinatorProtocol)?
}

struct DefaultSettingsScreenHook: SettingsScreenHookProtocol {
    func supplementaryRows(action: @escaping (String) -> Void) -> AnyView? {
        nil
    }
    
    func makeSupplementaryFlowCoordinator(flowID: String, navigationStackCoordinator: NavigationStackCoordinator) -> (any SettingsSupplementaryFlowCoordinatorProtocol)? {
        nil
    }
}

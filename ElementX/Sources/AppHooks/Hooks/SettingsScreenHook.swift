//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

nonisolated protocol SettingsScreenHookProtocol: Sendable {
    @MainActor func additionalRows(action: @escaping () -> Void) -> AnyView?
    @MainActor func makeCoordinator(navigationStackCoordinator: NavigationStackCoordinator) -> (any CoordinatorProtocol)?
}

struct DefaultSettingsScreenHook: SettingsScreenHookProtocol {
    func additionalRows(action: @escaping () -> Void) -> AnyView? {
        nil
    }
    
    func makeCoordinator(navigationStackCoordinator: NavigationStackCoordinator) -> (any CoordinatorProtocol)? {
        nil
    }
}

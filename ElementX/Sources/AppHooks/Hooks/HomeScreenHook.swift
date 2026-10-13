//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum HomeScreenSupplementaryPlacement { case banner, floating, overlay }
enum HomeScreenSupplementaryAction {
    case room(String)
    case settings(String)
}

nonisolated protocol HomeScreenHookProtocol: Sendable {
    @MainActor func supplementaryView(placement: HomeScreenSupplementaryPlacement, action: @escaping (HomeScreenSupplementaryAction) -> Void) -> AnyView?
    @MainActor func roomBadge(roomID: String) -> AnyView?
    @MainActor func isContentCovered() -> Bool
}

struct DefaultHomeScreenHook: HomeScreenHookProtocol {
    func supplementaryView(placement: HomeScreenSupplementaryPlacement, action: @escaping (HomeScreenSupplementaryAction) -> Void) -> AnyView? {
        nil
    }
    
    func roomBadge(roomID: String) -> AnyView? {
        nil
    }
    
    func isContentCovered() -> Bool {
        false
    }
}

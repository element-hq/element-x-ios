//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

enum RootFlowHookState {
    case authentication
    case userSession(UserSessionProtocol)
}

nonisolated protocol RootFlowHookProtocol: Sendable {
    @MainActor func configure(for state: RootFlowHookState)
}

struct DefaultRootFlowHook: RootFlowHookProtocol {
    func configure(for state: RootFlowHookState) { }
}

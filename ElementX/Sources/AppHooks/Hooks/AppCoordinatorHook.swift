//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

nonisolated protocol AppCoordinatorHookProtocol: Sendable {
    @MainActor func configure()
}

struct DefaultAppCoordinatorHook: AppCoordinatorHookProtocol {
    func configure() { }
}

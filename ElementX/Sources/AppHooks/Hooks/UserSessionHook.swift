//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

nonisolated protocol UserSessionHookProtocol: Sendable {
    func configure(with userSession: UserSessionProtocol?) async
}

nonisolated struct DefaultUserSessionHook: UserSessionHookProtocol {
    func configure(with userSession: UserSessionProtocol?) async { }
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

nonisolated protocol AuthenticationServiceHookProtocol: Sendable {
    @MainActor func updateClient(_ client: ClientProtocol) -> ClientProtocol
}

struct DefaultAuthenticationServiceHook: AuthenticationServiceHookProtocol {
    func updateClient(_ client: ClientProtocol) -> ClientProtocol {
        client
    }
}

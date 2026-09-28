//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

nonisolated protocol ClientFactoryHookProtocol: Sendable {
    func configure(_ builder: ClientBuilder, toRestore session: Session?) -> ClientBuilder
    
    func updateAuthenticationClient(_ client: ClientProtocol) -> ClientProtocol
}

nonisolated struct DefaultClientFactoryHook: ClientFactoryHookProtocol {
    func configure(_ builder: ClientBuilder, toRestore session: Session?) -> ClientBuilder {
        builder
    }
    
    func updateAuthenticationClient(_ client: ClientProtocol) -> ClientProtocol {
        client
    }
}

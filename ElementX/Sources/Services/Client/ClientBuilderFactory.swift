//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

// sourcery: AutoMockable
nonisolated protocol ClientBuilderFactoryProtocol {
    func makeBuilder() -> ClientBuilder
}

/// A wrapper around `ClientBuilder` to allow for mocked builders to be injected into tests.
nonisolated struct ClientBuilderFactory: ClientBuilderFactoryProtocol {
    func makeBuilder() -> ClientBuilder {
        ClientBuilder()
    }
}

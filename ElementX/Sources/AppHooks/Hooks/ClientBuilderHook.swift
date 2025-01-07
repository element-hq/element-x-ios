//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

protocol ClientBuilderHookProtocol {
    func configure(_ builder: ClientBuilder) -> ClientBuilder
}

struct DefaultClientBuilderHook: ClientBuilderHookProtocol {
    func configure(_ builder: ClientBuilder) -> ClientBuilder { builder }
}

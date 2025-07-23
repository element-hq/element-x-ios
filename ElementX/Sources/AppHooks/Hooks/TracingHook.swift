//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

protocol TracingHookProtocol {
    func update(_ configuration: TracingConfiguration, with rageshakeURL: RemotePreference<RageshakeConfiguration>)
}

struct DefaultTracingHook: TracingHookProtocol {
    func update(_ configuration: TracingConfiguration, with rageshakeURL: RemotePreference<RageshakeConfiguration>) { }
}

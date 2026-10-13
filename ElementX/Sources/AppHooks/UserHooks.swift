//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated struct UserHooks: Sendable {
    let createRoomScreenHook: CreateRoomScreenHookProtocol
    
    init(createRoomScreenHook: CreateRoomScreenHookProtocol = DefaultCreateRoomScreenHook()) {
        self.createRoomScreenHook = createRoomScreenHook
    }
}

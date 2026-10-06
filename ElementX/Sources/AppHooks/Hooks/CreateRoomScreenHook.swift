//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated protocol CreateRoomScreenHookProtocol: Sendable {
    @MainActor func update(_ viewState: CreateRoomScreenViewState, homeserver: String) -> CreateRoomScreenViewState
}

struct DefaultCreateRoomScreenHook: CreateRoomScreenHookProtocol {
    func update(_ viewState: CreateRoomScreenViewState, homeserver: String) -> CreateRoomScreenViewState {
        viewState
    }
}

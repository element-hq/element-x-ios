//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

nonisolated protocol RoomDetailsScreenHookProtocol: Sendable {
    @MainActor func update(_ viewState: RoomDetailsScreenViewState) -> RoomDetailsScreenViewState
    @MainActor func additionalSections() -> AnyView?
}

struct DefaultRoomDetailsScreenHook: RoomDetailsScreenHookProtocol {
    func update(_ viewState: RoomDetailsScreenViewState) -> RoomDetailsScreenViewState {
        viewState
    }
    
    func additionalSections() -> AnyView? {
        nil
    }
}

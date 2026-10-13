//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum RoomScreenSupplementaryPlacement {
    case toolbar, banner, composer, overlay
}

nonisolated protocol RoomScreenHookProtocol: Sendable {
    @MainActor func supplementaryView(roomID: String, roomName: String, placement: RoomScreenSupplementaryPlacement) -> AnyView?
    @MainActor func isContentCovered(roomID: String) -> Bool
    @MainActor func update(_ viewState: RoomScreenViewState) -> RoomScreenViewState
}

struct DefaultRoomScreenHook: RoomScreenHookProtocol {
    func supplementaryView(roomID: String, roomName: String, placement: RoomScreenSupplementaryPlacement) -> AnyView? {
        nil
    }
    
    func isContentCovered(roomID: String) -> Bool {
        false
    }
    
    func update(_ viewState: RoomScreenViewState) -> RoomScreenViewState {
        viewState
    }
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

nonisolated protocol RoomDetailsScreenHookProtocol: Sendable {
    @MainActor func update(_ viewState: RoomDetailsScreenViewState) -> RoomDetailsScreenViewState
    /// Extra rows shown at the top of the Security section.
    /// Asked again on every room info change: return `nil` to show nothing, never an empty view.
    @MainActor func additionalSecurityRows(roomProxy: JoinedRoomProxyProtocol) -> AnyView?
}

@MainActor
extension RoomDetailsScreenHookProtocol {
    func additionalSecurityRows(roomProxy: JoinedRoomProxyProtocol) -> AnyView? {
        nil
    }
}

struct DefaultRoomDetailsScreenHook: RoomDetailsScreenHookProtocol {
    func update(_ viewState: RoomDetailsScreenViewState) -> RoomDetailsScreenViewState {
        viewState
    }
}

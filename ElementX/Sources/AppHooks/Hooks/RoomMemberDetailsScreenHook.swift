//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated protocol RoomMemberDetailsScreenHookProtocol: Sendable {
    @MainActor func configure(with userSession: UserSessionProtocol?) async
    @MainActor func update(_ viewState: RoomMemberDetailsScreenViewState) -> RoomMemberDetailsScreenViewState
}

struct DefaultRoomMemberDetailsScreenHook: RoomMemberDetailsScreenHookProtocol {
    func configure(with userSession: UserSessionProtocol?) async { }
    func update(_ viewState: RoomMemberDetailsScreenViewState) -> RoomMemberDetailsScreenViewState {
        viewState
    }
}

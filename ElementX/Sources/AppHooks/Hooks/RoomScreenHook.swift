//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol RoomScreenHookProtocol {
    func configure(with userSession: UserSessionProtocol?) async
    func update(_ viewState: RoomScreenViewState) -> RoomScreenViewState
}

struct DefaultRoomScreenHook: RoomScreenHookProtocol {
    func configure(with userSession: UserSessionProtocol?) async { }
    func update(_ viewState: RoomScreenViewState) -> RoomScreenViewState { viewState }
}

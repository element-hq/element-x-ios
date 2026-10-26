//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated protocol UserProfileScreenHookProtocol: Sendable {
    @MainActor func update(_ viewState: UserProfileScreenViewState) -> UserProfileScreenViewState
    @MainActor func update(_ parameters: CreateRoomParameters) -> CreateRoomParameters
}

struct DefaultUserProfileScreenHook: UserProfileScreenHookProtocol {
    func update(_ viewState: UserProfileScreenViewState) -> UserProfileScreenViewState {
        viewState
    }
    
    func update(_ parameters: CreateRoomParameters) -> CreateRoomParameters {
        parameters
    }
}

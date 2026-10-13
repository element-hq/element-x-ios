//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

nonisolated protocol UserSessionHookProtocol: Sendable {
    #if IS_MAIN_APP
    func configure(with userSession: UserSessionProtocol?) async
    
    func makeUserHooks(forHomeserver homeserver: String) -> UserHooks
    #endif
    
    func configure(_ userSettings: UserSettings, forHomeserver homeserver: String) -> UserSettings
}

nonisolated struct DefaultUserSessionHook: UserSessionHookProtocol {
    #if IS_MAIN_APP
    func configure(with userSession: UserSessionProtocol?) async { }
    
    func makeUserHooks(forHomeserver homeserver: String) -> UserHooks {
        UserHooks()
    }
    #endif
    
    func configure(_ userSettings: UserSettings, forHomeserver homeserver: String) -> UserSettings {
        userSettings
    }
}

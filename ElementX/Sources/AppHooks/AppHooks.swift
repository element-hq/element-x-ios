//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Macros
import Synchronization

final nonisolated class AppHooks: AppHooksProtocol {
    #if IS_MAIN_APP
    func configure(with userSession: UserSessionProtocol?) async {
        await userSessionHook.configure(with: userSession)
    }
    
    @AppHook(default: DefaultAppSettingsHook())
    var appSettingsHook: AppSettingsHookProtocol
    
    @AppHook(default: DefaultCompoundHook())
    var compoundHook: CompoundHookProtocol
    
    @AppHook(default: DefaultBugReportHook())
    var bugReportHook: BugReportHookProtocol
    
    @AppHook(default: DefaultOAuthPresenterHook())
    var oAuthPresenterHook: OAuthPresenterHookProtocol
    
    @AppHook(default: DefaultUserSessionHook())
    var userSessionHook: UserSessionHookProtocol
    
    @AppHook(default: DefaultRoomScreenHook())
    var roomScreenHook: RoomScreenHookProtocol
    
    @AppHook(default: DefaultRoomDetailsScreenHook())
    var roomDetailsScreenHook: RoomDetailsScreenHookProtocol
    
    @AppHook(default: DefaultRoomMemberDetailsScreenHook())
    var roomMemberDetailsScreenHook: RoomMemberDetailsScreenHookProtocol
    
    @AppHook(default: DefaultUserProfileScreenHook())
    var userProfileScreenHook: UserProfileScreenHookProtocol
    
    @AppHook(default: DefaultDeveloperOptionsScreenHook())
    var developerOptionsScreenHook: DeveloperOptionsScreenHookProtocol
    
    @AppHook(default: DefaultRecoveryKeyScreenHook())
    var recoveryKeyScreenHook: RecoveryKeyScreenHookProtocol
    #endif
    
    @AppHook(default: DefaultTracingHook())
    var tracingHook: TracingHookProtocol
    
    @AppHook(default: DefaultClientBuilderHook())
    var clientBuilderHook: ClientBuilderHookProtocol
    
    @AppHook(default: DefaultRemoteSettingsHook())
    var remoteSettingsHook: RemoteSettingsHookProtocol
}

nonisolated protocol AppHooksProtocol: Sendable {
    // periphery:ignore - required for the architecture
    func setUp()
}

nonisolated extension AppHooksProtocol {
    // periphery:ignore - required for the architecture
    func setUp() { }
}

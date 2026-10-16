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
    @AppHook(default: DefaultAppSettingsHook())
    var appSettingsHook: AppSettingsHookProtocol
    
    @AppHook(default: DefaultCompoundHook())
    var compoundHook: CompoundHookProtocol
    
    @AppHook(default: DefaultBugReportHook())
    var bugReportHook: BugReportHookProtocol
    
    @AppHook(default: DefaultOAuthAuthenticationPresenterHook())
    var oAuthAuthenticationPresenterHook: OAuthAuthenticationPresenterHookProtocol
    
    @AppHook(default: DefaultDeveloperOptionsScreenHook())
    var developerOptionsScreenHook: DeveloperOptionsScreenHookProtocol
    #endif
    
    @AppHook(default: DefaultTracingHook())
    var tracingHook: TracingHookProtocol
    
    @AppHook(default: DefaultClientFactoryHook())
    var clientFactoryHook: ClientFactoryHookProtocol
    
    @AppHook(default: DefaultRemoteSettingsHook())
    var remoteSettingsHook: RemoteSettingsHookProtocol
    
    @AppHook(default: DefaultUserSessionHook())
    var userSessionHook: UserSessionHookProtocol
}

nonisolated protocol AppHooksProtocol: Sendable {
    // periphery:ignore - required for the architecture
    func setUp()
}

nonisolated extension AppHooksProtocol {
    // periphery:ignore - required for the architecture
    func setUp() { }
}

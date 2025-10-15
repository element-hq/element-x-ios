//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class AppHooks: AppHooksProtocol {
    #if IS_MAIN_APP
    func configure(with userSession: UserSessionProtocol?) async {
        await roomScreenHook.configure(with: userSession)
    }
    
    private(set) var appSettingsHook: AppSettingsHookProtocol = DefaultAppSettingsHook()
    func registerAppSettingsHook(_ hook: AppSettingsHookProtocol) {
        appSettingsHook = hook
    }
    
    private(set) var compoundHook: CompoundHookProtocol = DefaultCompoundHook()
    func registerCompoundHook(_ hook: CompoundHookProtocol) {
        compoundHook = hook
    }
    
    private(set) var bugReportHook: BugReportHookProtocol = DefaultBugReportHook()
    func registerBugReportHook(_ hook: BugReportHookProtocol) {
        bugReportHook = hook
    }
    
    private(set) var certificateValidatorHook: CertificateValidatorHookProtocol = DefaultCertificateValidator()
    func registerCertificateValidatorHook(_ hook: CertificateValidatorHookProtocol) {
        certificateValidatorHook = hook
    }
    
    private(set) var roomScreenHook: RoomScreenHookProtocol = DefaultRoomScreenHook()
    func registerRoomScreenHook(_ hook: RoomScreenHookProtocol) {
        roomScreenHook = hook
    }
    
    private(set) var developerOptionsScreenHook: DeveloperOptionsScreenHookProtocol = DefaultDeveloperOptionsScreenHook()
    func registerDeveloperOptionsScreenHook(_ hook: DeveloperOptionsScreenHookProtocol) {
        developerOptionsScreenHook = hook
    }
    #endif
    
    private(set) var tracingHook: TracingHookProtocol = DefaultTracingHook()
    func registerTracingHook(_ hook: TracingHookProtocol) {
        tracingHook = hook
    }
    
    private(set) var clientBuilderHook: ClientBuilderHookProtocol = DefaultClientBuilderHook()
    func registerClientBuilderHook(_ hook: ClientBuilderHookProtocol) {
        clientBuilderHook = hook
    }
    
    private(set) var remoteSettingsHook: RemoteSettingsHookProtocol = DefaultRemoteSettingsHook()
    func registerRemoteSettingsHook(_ hook: RemoteSettingsHookProtocol) {
        remoteSettingsHook = hook
    }
}

protocol AppHooksProtocol {
    func setUp()
}

extension AppHooksProtocol {
    func setUp() { }
}

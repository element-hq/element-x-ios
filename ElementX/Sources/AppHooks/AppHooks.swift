//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct AppHooks: AppHooksProtocol {
    #if IS_MAIN_APP
    func configure(with userSession: UserSessionProtocol?) async {
        await roomScreenHook.configure(with: userSession)
    }
    
    private(set) var appSettingsHook: AppSettingsHookProtocol = DefaultAppSettingsHook()
    mutating func registerAppSettingsHook(_ hook: AppSettingsHookProtocol) {
        appSettingsHook = hook
    }

    private(set) var compoundHook: CompoundHookProtocol = DefaultCompoundHook()
    mutating func registerCompoundHook(_ hook: CompoundHookProtocol) {
        compoundHook = hook
    }

    private(set) var bugReportHook: BugReportHookProtocol = DefaultBugReportHook()
    mutating func registerBugReportHook(_ hook: BugReportHookProtocol) {
        bugReportHook = hook
    }

    private(set) var certificateValidatorHook: CertificateValidatorHookProtocol = DefaultCertificateValidator()
    mutating func registerCertificateValidatorHook(_ hook: CertificateValidatorHookProtocol) {
        certificateValidatorHook = hook
    }

    private(set) var oAuthPresenterHook: OAuthPresenterHookProtocol = DefaultOAuthPresenterHook()
    mutating func registerOAuthPresenterHook(_ hook: OAuthPresenterHookProtocol) {
        oAuthPresenterHook = hook
    }

    private(set) var roomScreenHook: RoomScreenHookProtocol = DefaultRoomScreenHook()
    mutating func registerRoomScreenHook(_ hook: RoomScreenHookProtocol) {
        roomScreenHook = hook
    }

    private(set) var developerOptionsScreenHook: DeveloperOptionsScreenHookProtocol = DefaultDeveloperOptionsScreenHook()
    mutating func registerDeveloperOptionsScreenHook(_ hook: DeveloperOptionsScreenHookProtocol) {
        developerOptionsScreenHook = hook
    }
    #endif
    
    private(set) var tracingHook: TracingHookProtocol = DefaultTracingHook()
    mutating func registerTracingHook(_ hook: TracingHookProtocol) {
        tracingHook = hook
    }
    
    private(set) var clientBuilderHook: ClientBuilderHookProtocol = DefaultClientBuilderHook()
    mutating func registerClientBuilderHook(_ hook: ClientBuilderHookProtocol) {
        clientBuilderHook = hook
    }
    
    private(set) var remoteSettingsHook: RemoteSettingsHookProtocol = DefaultRemoteSettingsHook()
    mutating func registerRemoteSettingsHook(_ hook: RemoteSettingsHookProtocol) {
        remoteSettingsHook = hook
    }
}

protocol AppHooksProtocol: Sendable {
    func setUp()
}

extension AppHooksProtocol {
    func setUp() { }
}

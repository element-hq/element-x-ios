//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Synchronization

final nonisolated class AppHooks: AppHooksProtocol {
    #if IS_MAIN_APP
    func configure(with userSession: UserSessionProtocol?) async {
        await roomScreenHook.configure(with: userSession)
    }
    
    private let _appSettingsHook: Mutex<AppSettingsHookProtocol> = Mutex(DefaultAppSettingsHook())
    var appSettingsHook: AppSettingsHookProtocol {
        _appSettingsHook.withLock { $0 }
    }
    
    func registerAppSettingsHook(_ hook: AppSettingsHookProtocol) {
        _appSettingsHook.withLock { $0 = hook }
    }
    
    private let _compoundHook: Mutex<CompoundHookProtocol> = Mutex(DefaultCompoundHook())
    var compoundHook: CompoundHookProtocol {
        _compoundHook.withLock { $0 }
    }
    
    func registerCompoundHook(_ hook: CompoundHookProtocol) {
        _compoundHook.withLock { $0 = hook }
    }
    
    private let _bugReportHook: Mutex<BugReportHookProtocol> = Mutex(DefaultBugReportHook())
    var bugReportHook: BugReportHookProtocol {
        _bugReportHook.withLock { $0 }
    }
    
    func registerBugReportHook(_ hook: BugReportHookProtocol) {
        _bugReportHook.withLock { $0 = hook }
    }
    
    private let _oAuthPresenterHook: Mutex<OAuthPresenterHookProtocol> = Mutex(DefaultOAuthPresenterHook())
    var oAuthPresenterHook: OAuthPresenterHookProtocol {
        _oAuthPresenterHook.withLock { $0 }
    }
    
    func registerOAuthPresenterHook(_ hook: OAuthPresenterHookProtocol) {
        _oAuthPresenterHook.withLock { $0 = hook }
    }
    
    private let _roomScreenHook: Mutex<RoomScreenHookProtocol> = Mutex(DefaultRoomScreenHook())
    var roomScreenHook: RoomScreenHookProtocol {
        _roomScreenHook.withLock { $0 }
    }
    
    func registerRoomScreenHook(_ hook: RoomScreenHookProtocol) {
        _roomScreenHook.withLock { $0 = hook }
    }
    
    private let _developerOptionsScreenHook: Mutex<DeveloperOptionsScreenHookProtocol> = Mutex(DefaultDeveloperOptionsScreenHook())
    var developerOptionsScreenHook: DeveloperOptionsScreenHookProtocol {
        _developerOptionsScreenHook.withLock { $0 }
    }
    
    func registerDeveloperOptionsScreenHook(_ hook: DeveloperOptionsScreenHookProtocol) {
        _developerOptionsScreenHook.withLock { $0 = hook }
    }
    
    private let _recoveryKeyScreenHook: Mutex<RecoveryKeyScreenHookProtocol> = Mutex(DefaultRecoveryKeyScreenHook())
    var recoveryKeyScreenHook: RecoveryKeyScreenHookProtocol {
        _recoveryKeyScreenHook.withLock { $0 }
    }
    
    func registerRecoveryKeyScreenHook(_ hook: RecoveryKeyScreenHookProtocol) {
        _recoveryKeyScreenHook.withLock { $0 = hook }
    }
    #endif
    
    private let _tracingHook: Mutex<TracingHookProtocol> = Mutex(DefaultTracingHook())
    var tracingHook: TracingHookProtocol {
        _tracingHook.withLock { $0 }
    }
    
    func registerTracingHook(_ hook: TracingHookProtocol) {
        _tracingHook.withLock { $0 = hook }
    }
    
    private let _clientBuilderHook: Mutex<ClientBuilderHookProtocol> = Mutex(DefaultClientBuilderHook())
    var clientBuilderHook: ClientBuilderHookProtocol {
        _clientBuilderHook.withLock { $0 }
    }
    
    func registerClientBuilderHook(_ hook: ClientBuilderHookProtocol) {
        _clientBuilderHook.withLock { $0 = hook }
    }
    
    private let _remoteSettingsHook: Mutex<RemoteSettingsHookProtocol> = Mutex(DefaultRemoteSettingsHook())
    var remoteSettingsHook: RemoteSettingsHookProtocol {
        _remoteSettingsHook.withLock { $0 }
    }
    
    func registerRemoteSettingsHook(_ hook: RemoteSettingsHookProtocol) {
        _remoteSettingsHook.withLock { $0 = hook }
    }
}

nonisolated protocol AppHooksProtocol: Sendable {
    func setUp()
}

nonisolated extension AppHooksProtocol {
    func setUp() { }
}

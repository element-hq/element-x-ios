//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

class AppHooks: AppHooksProtocol {
    #if IS_MAIN_APP
    private(set) var appSettingsHook: AppSettingsHookProtocol = DefaultAppSettingsHook()
    func registerAppSettingsHook(_ hook: AppSettingsHookProtocol) {
        appSettingsHook = hook
    }
    
    private(set) var bugReportHook: BugReportHookProtocol = DefaultBugReportHook()
    func registerBugReportHook(_ hook: BugReportHookProtocol) {
        bugReportHook = hook
    }
    
    private(set) var certificateValidatorHook: CertificateValidatorHookProtocol = DefaultCertificateValidator()
    func registerCertificateValidatorHook(_ hook: CertificateValidatorHookProtocol) {
        certificateValidatorHook = hook
    }
    #endif
    
    private(set) var clientBuilderHook: ClientBuilderHookProtocol = DefaultClientBuilderHook()
    func registerClientBuilderHook(_ hook: ClientBuilderHookProtocol) {
        clientBuilderHook = hook
    }
}

protocol AppHooksProtocol {
    func configure()
}

extension AppHooksProtocol {
    func configure() { }
}

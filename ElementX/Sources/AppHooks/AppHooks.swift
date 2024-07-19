//
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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

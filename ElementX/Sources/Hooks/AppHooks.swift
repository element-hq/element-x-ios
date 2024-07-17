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
import MatrixRustSDK

// MARK: Registration

class AppHooks: AppHooksProtocol {
    #if IS_MAIN_APP
    private var appSettingsHook: AppSettingsHookProtocol?
    func registerAppSettingsHook(_ hook: AppSettingsHookProtocol) {
        appSettingsHook = hook
    }
    
    func runAppSettingsHook(_ appSettings: AppSettings) -> AppSettings {
        guard let appSettingsHook else { return appSettings }
        return appSettingsHook.run(appSettings: appSettings)
    }
    
    private var bugReportHook: BugReportHookProtocol?
    func registerBugReportHook(_ hook: BugReportHookProtocol) {
        bugReportHook = hook
    }
    
    func runBugReportHook(_ bugReport: BugReport) -> BugReport {
        guard let bugReportHook else { return bugReport }
        return bugReportHook.run(bugReport: bugReport)
    }
    #endif
    
    private var clientBuilderHook: ClientBuilderHookProtocol?
    func registerClientBuilderHook(_ hook: ClientBuilderHookProtocol) {
        clientBuilderHook = hook
    }
    
    func runClientBuilderHook(_ clientBuilder: ClientBuilder) -> ClientBuilder {
        guard let clientBuilderHook else { return clientBuilder }
        return clientBuilderHook.run(builder: clientBuilder)
    }
}

protocol AppHooksProtocol {
    func configure()
}

extension AppHooksProtocol {
    func configure() { }
}

// MARK: Protocols

#if IS_MAIN_APP
protocol AppSettingsHookProtocol {
    func run(appSettings: AppSettings) -> AppSettings
}

protocol BugReportHookProtocol {
    func run(bugReport: BugReport) -> BugReport
}
#endif

protocol ClientBuilderHookProtocol {
    func run(builder: ClientBuilder) -> ClientBuilder
}

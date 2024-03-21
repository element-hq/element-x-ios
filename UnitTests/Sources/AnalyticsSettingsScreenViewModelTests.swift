//
// Copyright 2022 New Vector Ltd
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

import XCTest

@testable import ElementX

@MainActor
class AnalyticsSettingsScreenViewModelTests: XCTestCase {
    private var appSettings: AppSettings!
    private var viewModel: AnalyticsSettingsScreenViewModelProtocol!
    private var context: AnalyticsSettingsScreenViewModelType.Context!
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }
    
    @MainActor override func setUpWithError() throws {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        let analyticsClient = AnalyticsClientMock()
        analyticsClient.isRunning = false
        ServiceLocator.shared.register(analytics: AnalyticsService(client: analyticsClient,
                                                                   appSettings: appSettings,
                                                                   bugReportService: ServiceLocator.shared.bugReportService))
        
        viewModel = AnalyticsSettingsScreenViewModel(appSettings: appSettings,
                                                     analytics: ServiceLocator.shared.analytics)
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssertFalse(context.enableAnalytics)
    }

    func testOptIn() {
        appSettings.analyticsConsentState = .optedOut
        context.send(viewAction: .toggleAnalytics)
        XCTAssertTrue(context.enableAnalytics)
    }
    
    func testOptOut() {
        appSettings.analyticsConsentState = .optedIn
        context.send(viewAction: .toggleAnalytics)
        XCTAssertFalse(context.enableAnalytics)
    }
}

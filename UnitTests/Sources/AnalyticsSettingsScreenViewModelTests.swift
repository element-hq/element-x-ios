//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
                                                                   appSettings: appSettings))
        
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

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class AnalyticsSettingsScreenViewModelTests: XCTestCase {
    private var appSettings: AppSettings!
    private var viewModel: AnalyticsSettingsScreenViewModelProtocol!
    private var context: AnalyticsSettingsScreenViewModelType.Context!
    
    override func setUp() {
        AppSettings.resetAllSettings()
    }
    
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

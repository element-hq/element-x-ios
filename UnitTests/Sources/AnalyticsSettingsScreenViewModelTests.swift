//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite
final class AnalyticsSettingsScreenViewModelTests {
    private var appSettings: AppSettings!
    private var viewModel: AnalyticsSettingsScreenViewModelProtocol!
    private var context: AnalyticsSettingsScreenViewModelType.Context!
    
    init() {
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
    
    deinit {
        AppSettings.resetAllSettings()
    }

    @Test
    func initialState() {
        #expect(!context.enableAnalytics)
    }

    @Test
    func optIn() {
        appSettings.analyticsConsentState = .optedOut
        context.send(viewAction: .toggleAnalytics)
        #expect(context.enableAnalytics)
    }
    
    @Test
    func optOut() {
        appSettings.analyticsConsentState = .optedIn
        context.send(viewAction: .toggleAnalytics)
        #expect(!context.enableAnalytics)
    }
}

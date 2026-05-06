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
final class AnalyticsSettingsScreenViewModelTests {
    private let analytics: AnalyticsService
    private let appSettings: AppSettings

    private var viewModel: AnalyticsSettingsScreenViewModelProtocol!
    private var context: AnalyticsSettingsScreenViewModelType.Context!
    
    init() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        analytics = .mock(settings: appSettings)

        viewModel = AnalyticsSettingsScreenViewModel(appSettings: appSettings,
                                                     analytics: analytics)
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

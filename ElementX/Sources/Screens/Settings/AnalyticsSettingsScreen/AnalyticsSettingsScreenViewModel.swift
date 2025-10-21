//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias AnalyticsSettingsScreenViewModelType = StateStoreViewModelV2<AnalyticsSettingsScreenViewState, AnalyticsSettingsScreenViewAction>

class AnalyticsSettingsScreenViewModel: AnalyticsSettingsScreenViewModelType, AnalyticsSettingsScreenViewModelProtocol {
    private let analytics: AnalyticsService
    
    init(appSettings: AppSettings, analytics: AnalyticsService) {
        self.analytics = analytics
        
        let strings = AnalyticsSettingsScreenStrings(termsURL: appSettings.analyticsTermsURL)
        let bindings = AnalyticsSettingsScreenViewStateBindings(enableAnalytics: analytics.isEnabled)
        let state = AnalyticsSettingsScreenViewState(strings: strings, bindings: bindings)
        
        super.init(initialViewState: state)
        
        appSettings.$analyticsConsentState
            .map { $0 == .optedIn }
            .weakAssign(to: \.state.bindings.enableAnalytics, on: self)
            .store(in: &cancellables)
    }
    
    override func process(viewAction: AnalyticsSettingsScreenViewAction) {
        switch viewAction {
        case .toggleAnalytics:
            if analytics.isEnabled {
                analytics.optOut()
            } else {
                analytics.optIn()
            }
        }
    }
}

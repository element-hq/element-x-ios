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

import Combine
import SwiftUI

typealias AnalyticsSettingsScreenViewModelType = StateStoreViewModel<AnalyticsSettingsScreenViewState, AnalyticsSettingsScreenViewAction>

class AnalyticsSettingsScreenViewModel: AnalyticsSettingsScreenViewModelType, AnalyticsSettingsScreenViewModelProtocol {
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    
    init(appSettings: AppSettings, analytics: AnalyticsService) {
        self.appSettings = appSettings
        self.analytics = analytics
        
        let strings = AnalyticsSettingsScreenStrings(termsURL: appSettings.analyticsConfiguration.termsURL)
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

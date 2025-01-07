//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias AdvancedSettingsScreenViewModelType = StateStoreViewModel<AdvancedSettingsScreenViewState, AdvancedSettingsScreenViewAction>

class AdvancedSettingsScreenViewModel: AdvancedSettingsScreenViewModelType, AdvancedSettingsScreenViewModelProtocol {
    private let analytics: AnalyticsService
    
    init(advancedSettings: AdvancedSettingsProtocol, analytics: AnalyticsService) {
        self.analytics = analytics
        
        let state = AdvancedSettingsScreenViewState(bindings: .init(advancedSettings: advancedSettings))
        super.init(initialViewState: state)
    }
    
    override func process(viewAction: AdvancedSettingsScreenViewAction) {
        switch viewAction {
        case .optimizeMediaUploadsChanged:
            // Note: Using a view action here as sinking the AppSettings publisher tracks the initial value.
            analytics.trackInteraction(name: state.bindings.optimizeMediaUploads ? .MobileSettingsOptimizeMediaUploadsEnabled : .MobileSettingsOptimizeMediaUploadsDisabled)
        }
    }
}

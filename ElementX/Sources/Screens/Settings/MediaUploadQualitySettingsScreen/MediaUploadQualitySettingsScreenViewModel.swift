//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias MediaUploadQualitySettingsScreenViewModelType = StateStoreViewModelV2<MediaUploadQualitySettingsScreenViewState, MediaUploadQualitySettingsScreenViewAction>

class MediaUploadQualitySettingsScreenViewModel: MediaUploadQualitySettingsScreenViewModelType, MediaUploadQualitySettingsScreenViewModelProtocol {
    private let analytics: AnalyticsServiceProtocol
    
    init(userSettings: UserSettings, analytics: AnalyticsServiceProtocol) {
        self.analytics = analytics
        
        let state = MediaUploadQualitySettingsScreenViewState(bindings: .init(userSettings: userSettings))
        super.init(initialViewState: state)
    }
    
    override func process(viewAction: MediaUploadQualitySettingsScreenViewAction) {
        switch viewAction {
        case .optimizeMediaUploadsChanged:
            // Note: Using a view action here as sinking the UserSettings publisher tracks the initial value.
            analytics.trackInteraction(name: state.bindings.optimizeMediaUploads ? .MobileSettingsOptimizeMediaUploadsEnabled : .MobileSettingsOptimizeMediaUploadsDisabled)
        }
    }
}

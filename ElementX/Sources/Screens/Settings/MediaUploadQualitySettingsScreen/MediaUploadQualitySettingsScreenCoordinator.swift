//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct MediaUploadQualitySettingsScreenCoordinatorParameters {
    let userSettings: UserSettings
    let analytics: AnalyticsServiceProtocol
}

final class MediaUploadQualitySettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: MediaUploadQualitySettingsScreenViewModelProtocol
    
    init(parameters: MediaUploadQualitySettingsScreenCoordinatorParameters) {
        viewModel = MediaUploadQualitySettingsScreenViewModel(userSettings: parameters.userSettings, analytics: parameters.analytics)
    }
    
    func toPresentable() -> AnyView {
        AnyView(MediaUploadQualitySettingsScreen(context: viewModel.context))
    }
}

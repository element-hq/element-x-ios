//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct AnalyticsSettingsScreenCoordinatorParameters {
    let appSettings: AppSettings
    let analytics: AnalyticsService
}

final class AnalyticsSettingsScreenCoordinator: CoordinatorProtocol {
    private let viewModel: AnalyticsSettingsScreenViewModel
    
    init(parameters: AnalyticsSettingsScreenCoordinatorParameters) {
        viewModel = AnalyticsSettingsScreenViewModel(appSettings: parameters.appSettings,
                                                     analytics: parameters.analytics)
    }
    
    func toPresentable() -> AnyView {
        AnyView(AnalyticsSettingsScreen(context: viewModel.context))
    }
}

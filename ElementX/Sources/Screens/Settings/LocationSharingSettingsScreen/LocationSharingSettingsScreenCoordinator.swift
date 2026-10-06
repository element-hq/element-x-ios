//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct LocationSharingSettingsScreenCoordinatorParameters {
    let userSettings: UserSettings
}

final class LocationSharingSettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: LocationSharingSettingsScreenViewModelProtocol
    
    init(parameters: LocationSharingSettingsScreenCoordinatorParameters) {
        viewModel = LocationSharingSettingsScreenViewModel(userSettings: parameters.userSettings)
    }
    
    func toPresentable() -> AnyView {
        AnyView(LocationSharingSettingsScreen(context: viewModel.context))
    }
}

//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias LocationSharingSettingsScreenViewModelType = StateStoreViewModelV2<LocationSharingSettingsScreenViewState, LocationSharingSettingsScreenViewAction>

class LocationSharingSettingsScreenViewModel: LocationSharingSettingsScreenViewModelType, LocationSharingSettingsScreenViewModelProtocol {
    init(userSettings: UserSettings) {
        let state = LocationSharingSettingsScreenViewState(bindings: .init(userSettings: userSettings))
        super.init(initialViewState: state)
    }
    
    override func process(viewAction: LocationSharingSettingsScreenViewAction) { }
}

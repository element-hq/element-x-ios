//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias AdvancedSettingsScreenViewModelType = StateStoreViewModel<AdvancedSettingsScreenViewState, AdvancedSettingsScreenViewAction>

class AdvancedSettingsScreenViewModel: AdvancedSettingsScreenViewModelType, AdvancedSettingsScreenViewModelProtocol {
    init(advancedSettings: AdvancedSettingsProtocol) {
        let bindings = AdvancedSettingsScreenViewStateBindings(advancedSettings: advancedSettings)
        let state = AdvancedSettingsScreenViewState(bindings: bindings)
        
        super.init(initialViewState: state)
    }
    
    override func process(viewAction: AdvancedSettingsScreenViewAction) { }
}

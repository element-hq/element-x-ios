//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ReferAFriendSettingsScreenViewModelType = StateStoreViewModel<ReferAFriendSettingsScreenViewState, ReferAFriendSettingsScreenViewAction>

class ReferAFriendSettingsScreenViewModel:
    ReferAFriendSettingsScreenViewModelType,
    ReferAFriendSettingsScreenViewModelProtocol {
    init(userSession: UserSessionProtocol) {
        super.init(
            initialViewState: .init(bindings: .init())
        )
    }
    
    override func process(viewAction: ReferAFriendSettingsScreenViewAction) {
        
    }
}

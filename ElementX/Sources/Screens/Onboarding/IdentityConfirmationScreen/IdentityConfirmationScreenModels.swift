//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum IdentityConfirmationScreenViewModelAction {
    case otherDevice
    case recoveryKey
    /// Only possible in debug builds.
    case skip
    case reset
    case logoutConfirmed
}

struct IdentityConfirmationScreenViewState: BindableState {
    enum AvailableActions {
        case recovery
        case interactiveVerification
    }
    
    var availableActions: [AvailableActions]?
    let learnMoreURL: URL
    
    var bindings = IdentityConfirmationScreenBindings()
}

struct IdentityConfirmationScreenBindings {
    var alertInfo: AlertInfo<IdentityConfirmationScreenAlertType>?
}

enum IdentityConfirmationScreenAlertType {
    case logout
}

enum IdentityConfirmationScreenViewAction {
    case otherDevice
    case recoveryKey
    /// Only possible in debug builds.
    case skip
    case reset
    case logout
}

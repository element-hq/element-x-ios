//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum IdentityConfirmationScreenViewModelAction {
    case otherDevice
    case recoveryKey
    /// Only possible in debug builds.
    case skip
    case reset
    case logout
}

struct IdentityConfirmationScreenViewState: BindableState {
    enum AvailableActions {
        case recovery
        case interactiveVerification
    }
    
    var availableActions: [AvailableActions] = []
    let learnMoreURL: URL
}

enum IdentityConfirmationScreenViewAction {
    case otherDevice
    case recoveryKey
    /// Only possible in debug builds.
    case skip
    case reset
    case logout
}

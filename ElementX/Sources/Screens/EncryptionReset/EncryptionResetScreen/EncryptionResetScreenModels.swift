//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum EncryptionResetScreenViewModelAction {
    case requestPassword(passwordPublisher: PassthroughSubject<String, Never>)
    case requestOAuthAuthorisation(url: URL)
    case resetFinished
    case cancel
    case logoutWithoutConfirmation
}

/// How the reset is presented, depending on what else the user could do to confirm their identity.
enum EncryptionResetScreenMode {
    /// The user has another verified device or a recovery key, so resetting is a last resort.
    case hasConfirmationOptions
    /// The user can only reset, and has encrypted rooms whose history will be lost.
    case noOptionsWithEncryptedRooms
    /// The user can only reset, and has no encrypted rooms to lose.
    case noOptionsWithoutEncryptedRooms
    
    init(hasConfirmationOptions: Bool, hasEncryptedRooms: @autoclosure () -> Bool) {
        self = if hasConfirmationOptions {
            .hasConfirmationOptions
        } else if hasEncryptedRooms() {
            .noOptionsWithEncryptedRooms
        } else {
            .noOptionsWithoutEncryptedRooms
        }
    }
    
    var isResetTheOnlyOption: Bool {
        self != .hasConfirmationOptions
    }
}

struct EncryptionResetScreenViewState: BindableState {
    let mode: EncryptionResetScreenMode
    var bindings: EncryptionResetScreenViewStateBindings
}

struct EncryptionResetScreenViewStateBindings {
    var alertInfo: AlertInfo<UUID>?
}

enum EncryptionResetScreenViewAction {
    case reset
    case cancel
    case signOut
}

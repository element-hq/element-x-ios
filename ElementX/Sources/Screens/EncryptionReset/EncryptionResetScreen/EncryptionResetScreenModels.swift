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
    case logoutConfirmed
}

/// How the reset is presented, depending on what else the user could do to confirm their identity.
enum EncryptionResetScreenVariant {
    /// The user has another verified device or a recovery key, so resetting is a last resort.
    case hasConfirmationOptions
    /// The user can only reset, and has encrypted chats whose history will be lost.
    case noOptionsWithEncryptedChats
    /// The user can only reset, and has no encrypted chats to lose.
    case noOptionsWithoutEncryptedChats
    
    init(hasConfirmationOptions: Bool, hasEncryptedChats: @autoclosure () -> Bool) {
        self = if hasConfirmationOptions {
            .hasConfirmationOptions
        } else if hasEncryptedChats() {
            .noOptionsWithEncryptedChats
        } else {
            .noOptionsWithoutEncryptedChats
        }
    }
    
    var isResetTheOnlyOption: Bool {
        self != .hasConfirmationOptions
    }
}

struct EncryptionResetScreenViewState: BindableState {
    let variant: EncryptionResetScreenVariant
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

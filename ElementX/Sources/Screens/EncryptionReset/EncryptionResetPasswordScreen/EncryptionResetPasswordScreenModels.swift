//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum EncryptionResetPasswordScreenViewModelAction: CustomStringConvertible {
    case resetIdentity(String)
    
    var description: String {
        switch self {
        case .resetIdentity:
            "resetIdentity"
        }
    }
}

struct EncryptionResetPasswordScreenViewState: BindableState {
    var bindings: EncryptionResetPasswordScreenViewStateBindings
}

struct EncryptionResetPasswordScreenViewStateBindings {
    var password: String
    var alertInfo: AlertInfo<UUID>?
}

enum EncryptionResetPasswordScreenViewAction {
    case resetIdentity
}

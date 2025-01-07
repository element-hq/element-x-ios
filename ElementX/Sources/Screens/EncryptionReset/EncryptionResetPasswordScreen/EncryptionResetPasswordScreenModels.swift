//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum EncryptionResetPasswordScreenViewModelAction {
    case passwordEntered
}

struct EncryptionResetPasswordScreenViewState: BindableState {
    var bindings: EncryptionResetPasswordScreenViewStateBindings
}

struct EncryptionResetPasswordScreenViewStateBindings {
    var password: String
    var alertInfo: AlertInfo<UUID>?
}

enum EncryptionResetPasswordScreenViewAction {
    case submit
}

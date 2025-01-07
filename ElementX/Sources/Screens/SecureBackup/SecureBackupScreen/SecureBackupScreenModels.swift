//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SecureBackupScreenViewModelAction {
    case manageRecoveryKey
    case disableKeyBackup
}

struct SecureBackupScreenViewState: BindableState {
    let chatBackupDetailsURL: URL
    var recoveryState = SecureBackupRecoveryState.unknown
    var keyBackupState = SecureBackupKeyBackupState.unknown
    var bindings: SecureBackupScreenViewStateBindings
    
    var keyStorageToggleDescription: String? {
        keyBackupState.keyStorageToggleState ? nil : L10n.screenChatBackupKeyStorageDisabledError
    }
}

struct SecureBackupScreenViewStateBindings {
    var keyStorageEnabled: Bool
    var alertInfo: AlertInfo<UUID>?
}

enum SecureBackupScreenViewAction {
    case recoveryKey
    case keyStorageToggled(Bool)
}

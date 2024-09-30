//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum SecureBackupKeyBackupScreenViewModelAction {
    case done
}

enum SecureBackupKeyBackupScreenViewMode {
    case disableBackup
}

struct SecureBackupKeyBackupScreenViewState: BindableState {
    let mode: SecureBackupKeyBackupScreenViewMode
    var bindings = SecureBackupKeyBackupScreenViewStateBindings()
}

struct SecureBackupKeyBackupScreenViewStateBindings {
    var alertInfo: AlertInfo<UUID>?
}

enum SecureBackupKeyBackupScreenViewAction {
    case cancel
    case toggleBackup
}

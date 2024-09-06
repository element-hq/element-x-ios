//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum SecureBackupLogoutConfirmationScreenViewModelAction {
    case cancel
    case settings
    case logout
}

enum SecureBackupLogoutConfirmationScreenViewMode {
    case saveRecoveryKey
    case backupOngoing
    case offline
}

struct SecureBackupLogoutConfirmationScreenViewState: BindableState {
    var mode: SecureBackupLogoutConfirmationScreenViewMode
    var bindings = SecureBackupLogoutConfirmationScreenBindings()
}

struct SecureBackupLogoutConfirmationScreenBindings {
    var alertInfo: AlertInfo<SecureBackupLogoutConfirmationScreenAlertType>?
}

enum SecureBackupLogoutConfirmationScreenAlertType {
    case backupUploadFailed
}

enum SecureBackupLogoutConfirmationScreenViewAction {
    case cancel
    case settings
    case logout
}

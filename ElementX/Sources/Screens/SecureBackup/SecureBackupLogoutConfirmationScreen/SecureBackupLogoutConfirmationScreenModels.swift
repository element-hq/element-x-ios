//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SecureBackupLogoutConfirmationScreenViewModelAction {
    case cancel
    case settings
    case logout
}

enum SecureBackupLogoutConfirmationScreenViewMode: Equatable {
    case saveRecoveryKey
    case waitingToStart(hasStalled: Bool)
    case backupOngoing(progress: Double)
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

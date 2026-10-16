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
    case generateRecoveryKey
    case logout
}

nonisolated enum SecureBackupLogoutConfirmationScreenViewMode: Equatable {
    /// The user has a recovery key but this is their only verified device.
    case saveRecoveryKey
    /// The user has no recovery key and this is their only verified device.
    case noRecovery
    case waitingToStart(hasStalled: Bool)
    case backupOngoing(progress: Double)
    case offline
    
    /// Whether the user is still being asked about removing the device, as opposed to the removal being underway.
    var isInitial: Bool {
        self == .saveRecoveryKey || self == .noRecovery
    }
}

struct SecureBackupLogoutConfirmationScreenViewState: BindableState {
    let learnMoreURL: URL
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
    case generateRecoveryKey
    case logout
}

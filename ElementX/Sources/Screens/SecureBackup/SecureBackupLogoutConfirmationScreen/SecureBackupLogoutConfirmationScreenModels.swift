//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// Receives a value once the user has generated and saved a new recovery key.
typealias SecureBackupLogoutConfirmationScreenRecoveryKeyContinuation = AsyncStream<Void>.Continuation

enum SecureBackupLogoutConfirmationScreenViewModelAction {
    case cancel
    case checkRecoveryKey(SecureBackupLogoutConfirmationScreenRecoveryKeyContinuation)
    case generateRecoveryKey(SecureBackupLogoutConfirmationScreenRecoveryKeyContinuation)
    case logout
}

nonisolated enum SecureBackupLogoutConfirmationScreenViewMode: Equatable {
    /// The user has other devices, show a friendly confirmation prompt.
    case confirmationOnly
    /// The user has a recovery key but this is their only verified device.
    case saveRecoveryKey
    /// The user has no recovery key and this is their only verified device.
    case noRecovery
    case waitingToStart(hasStalled: Bool)
    case backupOngoing(progress: Double)
    case offline
    
    /// Whether the user is still being asked about removing the device, as opposed to the removal being underway.
    var isInitial: Bool {
        switch self {
        case .confirmationOnly, .saveRecoveryKey, .noRecovery: true
        default: false
        }
    }
    
    /// Whether the toolbar shows a button to close the screen.
    var showsCloseButton: Bool {
        switch self {
        case .confirmationOnly: false
        default: true
        }
    }
    
    /// Returns the initial mode the screen should use, based on the user's recovery options after the device has been removed.
    init(hasOtherVerifiedDevice: Bool, recoveryState: SecureBackupRecoveryState) {
        self = if hasOtherVerifiedDevice {
            .confirmationOnly
        } else if recoveryState == .enabled {
            .saveRecoveryKey // Note: We no longer check the key backup state, it shouldn't be possible to disable on its own.
        } else {
            .noRecovery
        }
    }
}

struct SecureBackupLogoutConfirmationScreenViewState: BindableState {
    let learnMoreURL: URL
    var mode: SecureBackupLogoutConfirmationScreenViewMode
    var userProfile: UserProfile
    
    var bindings = SecureBackupLogoutConfirmationScreenBindings()
    
    var icon: (keyPath: KeyPath<CompoundIcons, Image>, style: BigIcon.Style) {
        switch mode {
        case .confirmationOnly, .saveRecoveryKey:
            (\.info, .defaultSolid)
        case .noRecovery:
            (\.errorSolid, .alertSolid)
        case .waitingToStart, .backupOngoing, .offline:
            (\.keyOffSolid, .defaultSolid)
        }
    }
    
    var title: String {
        switch mode {
        case .confirmationOnly:
            L10n.screenSignoutOtherVerifiedDeviceDialogTitle
        case .saveRecoveryKey:
            L10n.screenSignoutSaveRecoveryKeyTitle
        case .noRecovery:
            L10n.screenSignoutRecoveryDisabledTitle
        case .waitingToStart, .backupOngoing:
            L10n.screenSignoutKeyBackupOngoingTitle
        case .offline:
            L10n.screenSignoutKeyBackupOfflineTitle
        }
    }
    
    var subtitle: String {
        switch mode {
        case .confirmationOnly:
            L10n.screenSignoutOtherVerifiedDeviceDialogContent
        case .saveRecoveryKey:
            L10n.screenSignoutSaveRecoveryKeySubtitle
        case .noRecovery:
            L10n.screenSignoutRecoveryDisabledSubtitle
        case .waitingToStart, .backupOngoing:
            L10n.screenSignoutKeyBackupOngoingSubtitle
        case .offline:
            L10n.screenSignoutKeyBackupOfflineSubtitle
        }
    }
}

struct SecureBackupLogoutConfirmationScreenBindings {
    var alertInfo: AlertInfo<SecureBackupLogoutConfirmationScreenAlertType>?
}

enum SecureBackupLogoutConfirmationScreenAlertType {
    case backupUploadFailed
}

enum SecureBackupLogoutConfirmationScreenViewAction {
    case cancel
    case checkRecoveryKey
    case generateRecoveryKey
    case logout
}

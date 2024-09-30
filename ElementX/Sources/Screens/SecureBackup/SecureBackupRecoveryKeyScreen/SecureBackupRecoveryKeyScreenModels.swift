//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum SecureBackupRecoveryKeyScreenViewModelAction {
    case done(mode: SecureBackupRecoveryKeyScreenViewMode)
    case cancel
    case resetEncryption
}

enum SecureBackupRecoveryKeyScreenViewMode {
    case setupRecovery
    case changeRecovery
    case fixRecovery
    case unknown
}

struct SecureBackupRecoveryKeyScreenViewState: BindableState {
    /// Whether the screen is presented modally or within a navigation stack.
    var isModallyPresented: Bool
    
    let mode: SecureBackupRecoveryKeyScreenViewMode
    
    var recoveryKey: String?
    var doneButtonEnabled = false
    
    var bindings: SecureBackupRecoveryKeyScreenViewBindings
    
    var title: String {
        switch mode {
        case .setupRecovery:
            return recoveryKey == nil ? L10n.screenRecoveryKeySetupTitle : L10n.screenRecoveryKeySaveTitle
        case .changeRecovery:
            return recoveryKey == nil ? L10n.screenRecoveryKeyChangeTitle : L10n.screenRecoveryKeySaveTitle
        case .fixRecovery:
            return L10n.screenRecoveryKeyConfirmTitle
        default:
            return L10n.errorUnknown
        }
    }
    
    var subtitle: String? {
        switch mode {
        case .setupRecovery:
            return recoveryKey == nil ? L10n.screenRecoveryKeySetupDescription : L10n.screenRecoveryKeySaveDescription
        case .changeRecovery:
            return recoveryKey == nil ? L10n.screenRecoveryKeyChangeDescription : L10n.screenRecoveryKeySaveDescription
        case .fixRecovery:
            return L10n.screenRecoveryKeyConfirmDescription
        default:
            return nil
        }
    }
    
    var recoveryKeySubtitle: String? {
        switch mode {
        case .setupRecovery:
            return recoveryKey == nil ? L10n.screenRecoveryKeySetupGenerateKeyDescription : L10n.screenRecoveryKeySaveKeyDescription
        case .changeRecovery:
            return recoveryKey == nil ? L10n.screenRecoveryKeyChangeGenerateKeyDescription : L10n.screenRecoveryKeySaveKeyDescription
        case .fixRecovery:
            return L10n.screenRecoveryKeyConfirmKeyDescription
        default:
            return nil
        }
    }
}

struct SecureBackupRecoveryKeyScreenViewBindings {
    var confirmationRecoveryKey = ""
    var alertInfo: AlertInfo<UUID>?
}

enum SecureBackupRecoveryKeyScreenViewAction {
    case generateKey
    case copyKey
    case keySaved
    case confirmKey
    case resetEncryption
    case done
    case cancel
}

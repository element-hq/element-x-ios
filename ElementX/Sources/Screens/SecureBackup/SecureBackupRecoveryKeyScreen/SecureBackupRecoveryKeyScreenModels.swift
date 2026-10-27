//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

enum SecureBackupRecoveryKeyScreenViewModelAction {
    case complete
}

/// Where the screen is being shown, which decides what its final button says.
enum SecureBackupRecoveryKeyScreenPresentationContext {
    case standard
    /// The screen is part of removing the device, after which the removal carries on.
    case deviceRemoval
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
    let presentationContext: SecureBackupRecoveryKeyScreenPresentationContext
    /// Whether the new recovery key is saved and the screen is showing that it is now active.
    var isCompleted = false
    
    var recoveryKey: String?
    var isGeneratingKey = false
    var doneButtonEnabled = false
    
    var bindings: SecureBackupRecoveryKeyScreenViewBindings
    
    /// Setting up or changing the key goes straight to generating it, so the introduction is only seen if that failed.
    private var hasKeyOrIsGenerating: Bool {
        recoveryKey != nil || isGeneratingKey
    }
    
    /// The title of the button that closes the screen once the new recovery key is active.
    var completionButtonTitle: String {
        switch presentationContext {
        case .standard:
            L10n.actionDone
        case .deviceRemoval:
            L10n.screenSignoutSaveRecoveryKeyActionContinue
        }
    }
    
    var icon: KeyPath<CompoundIcons, Image> {
        isCompleted ? \.checkCircleSolid : \.keySolid
    }
    
    var iconStyle: BigIcon.Style {
        isCompleted ? .successSolid : .defaultSolid
    }
    
    var title: String {
        guard !isCompleted else { return UntranslatedL10n.screenRecoveryKeySuccessTitle }
        
        switch mode {
        case .setupRecovery:
            return hasKeyOrIsGenerating ? L10n.screenRecoveryKeySaveTitle : L10n.screenRecoveryKeySetupTitle
        case .changeRecovery:
            return hasKeyOrIsGenerating ? L10n.screenRecoveryKeySaveTitle : L10n.screenRecoveryKeyChangeTitle
        case .fixRecovery:
            return L10n.screenRecoveryKeyConfirmTitle
        default:
            return L10n.errorUnknown
        }
    }
    
    var subtitle: String? {
        guard !isCompleted else { return L10n.screenCustomRecoveryKeySuccessSubtitle }
        
        switch mode {
        case .setupRecovery:
            return hasKeyOrIsGenerating ? L10n.screenRecoveryKeySaveDescription : L10n.screenRecoveryKeySetupDescription
        case .changeRecovery:
            return hasKeyOrIsGenerating ? L10n.screenRecoveryKeySaveDescription : L10n.screenRecoveryKeyChangeDescription
        case .fixRecovery:
            return L10n.screenRecoveryKeyConfirmDescription
        default:
            return nil
        }
    }
    
    var recoveryKeySubtitle: String? {
        switch mode {
        case .setupRecovery:
            return hasKeyOrIsGenerating ? L10n.screenRecoveryKeySaveKeyDescription : L10n.screenRecoveryKeySetupGenerateKeyDescription
        case .changeRecovery:
            return hasKeyOrIsGenerating ? L10n.screenRecoveryKeySaveKeyDescription : L10n.screenRecoveryKeyChangeGenerateKeyDescription
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
    /// The user has saved the key and wants to continue, which asks them to confirm that.
    case confirmKeySaved
    /// The user has seen that the new key is active.
    case complete
    case cancel
}

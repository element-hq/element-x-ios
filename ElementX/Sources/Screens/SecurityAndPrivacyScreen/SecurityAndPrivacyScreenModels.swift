//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SecurityAndPrivacyScreenViewModelAction {
    case done
}

struct SecurityAndPrivacyScreenViewState: BindableState {
    var bindings: SecurityAndPrivacyScreenViewStateBindings
    
    var currentSettings: SecurityAndPrivacySettings
    
    var hasChanges: Bool {
        currentSettings != bindings.desiredSettings
    }
    
    var availableVisibilityOptions: [SecurityAndPrivacyHistoryVisibility] {
        var options = [SecurityAndPrivacyHistoryVisibility.sinceSelection]
        if !bindings.desiredSettings.isEncryptionEnabled, bindings.desiredSettings.accessType == .anyone {
            options.append(.anyone)
        } else {
            options.append(.sinceInvite)
        }
        return options
    }
    
    init(accessType: SecurityAndPrivacyRoomAccessType,
         isEncryptionEnabled: Bool,
         historyVisibility: SecurityAndPrivacyHistoryVisibility) {
        let settings = SecurityAndPrivacySettings(accessType: accessType,
                                                  isEncryptionEnabled: isEncryptionEnabled,
                                                  historyVisibility: historyVisibility)
        currentSettings = settings
        bindings = SecurityAndPrivacyScreenViewStateBindings(desiredSettings: settings)
    }
}

struct SecurityAndPrivacyScreenViewStateBindings {
    var desiredSettings: SecurityAndPrivacySettings
    var alertInfo: AlertInfo<SecurityAndPrivacyAlertType>?
}

struct SecurityAndPrivacySettings: Equatable {
    var accessType: SecurityAndPrivacyRoomAccessType
    var isEncryptionEnabled: Bool
    var historyVisibility: SecurityAndPrivacyHistoryVisibility
}

enum SecurityAndPrivacyRoomAccessType {
    case inviteOnly
    case askToJoin
    case anyone
}

enum SecurityAndPrivacyAlertType {
    case enableEncryption
}

enum SecurityAndPrivacyScreenViewAction {
    case save
    case tryUpdatingEncryption(Bool)
}

enum SecurityAndPrivacyHistoryVisibility {
    case sinceSelection
    case sinceInvite
    case anyone
    
    var isAllowedInPublicRoom: Bool {
        switch self {
        case .anyone, .sinceSelection:
            true
        default:
            false
        }
    }
}

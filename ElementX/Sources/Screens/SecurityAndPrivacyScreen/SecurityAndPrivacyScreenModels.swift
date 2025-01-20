//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SecurityAndPrivacyScreenViewModelAction {
    case displayEditAddressScreen
}

struct SecurityAndPrivacyScreenViewState: BindableState {
    let serverName: String
    var currentSettings: SecurityAndPrivacySettings
    var bindings: SecurityAndPrivacyScreenViewStateBindings
    var canonicalAlias: String?
    
    private var hasChanges: Bool {
        currentSettings != bindings.desiredSettings
    }
    
    var isSaveDisabled: Bool {
        !hasChanges ||
            (currentSettings.isVisibileInRoomDirectory == nil &&
                bindings.desiredSettings.accessType != .inviteOnly &&
                canonicalAlias != nil)
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
        
    init(serverName: String,
         accessType: SecurityAndPrivacyRoomAccessType,
         isEncryptionEnabled: Bool,
         historyVisibility: SecurityAndPrivacyHistoryVisibility) {
        self.serverName = serverName
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
    var isVisibileInRoomDirectory: Bool?
}

enum SecurityAndPrivacyRoomAccessType {
    case inviteOnly
    case askToJoin
    case anyone
    case spaceUsers
}

enum SecurityAndPrivacyAlertType {
    case enableEncryption
}

enum SecurityAndPrivacyScreenViewAction {
    case save
    case tryUpdatingEncryption(Bool)
    case editAddress
}

enum SecurityAndPrivacyHistoryVisibility {
    case sinceSelection
    case sinceInvite
    case anyone
    
    var fallbackOption: Self {
        switch self {
        case .sinceInvite, .sinceSelection:
            return .sinceSelection
        case .anyone:
            return .sinceInvite
        }
    }
}

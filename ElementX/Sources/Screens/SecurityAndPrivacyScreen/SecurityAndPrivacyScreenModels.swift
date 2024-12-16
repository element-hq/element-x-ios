//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    
    init(accessType: SecurityAndPrivacyRoomAccessType,
         isEncryptionEnabled: Bool) {
        let settings = SecurityAndPrivacySettings(accessType: accessType, isEncryptionEnabled: isEncryptionEnabled)
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

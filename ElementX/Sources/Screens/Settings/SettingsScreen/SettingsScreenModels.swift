//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

enum SettingsScreenViewModelAction: Equatable {
    case close
    case userDetails
    case manageAccount(url: URL)
    case analytics
    case appLock
    case reportBug
    case about
    case blockedUsers
    case secureBackup
    case notifications
    case advancedSettings
    case developerOptions
    case logout
    case deactivateAccount
}

enum SettingsScreenSecuritySectionMode {
    case none
    case secureBackup
}

struct SettingsScreenViewState: BindableState {
    var deviceID: String?
    var userID: String
    var accountProfileURL: URL?
    var accountSessionsListURL: URL?
    var showAccountDeactivation: Bool
    var userAvatarURL: URL?
    var userDisplayName: String?
    var showDeveloperOptions: Bool
    
    var securitySectionMode = SettingsScreenSecuritySectionMode.none
    var showSecuritySectionBadge = false
    
    var showBlockedUsers = false
    
    var bindings = SettingsScreenViewStateBindings()
}

struct SettingsScreenViewStateBindings {
    var isPresentingAccountDeactivationConfirmation = false
}

enum SettingsScreenViewAction {
    case close
    case userDetails
    case analytics
    case appLock
    case reportBug
    case about
    case blockedUsers
    case secureBackup
    case manageAccount(url: URL)
    case notifications
    case enableDeveloperOptions
    case developerOptions
    case advancedSettings
    case logout
    case deactivateAccount
}

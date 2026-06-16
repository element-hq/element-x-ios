//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    // GUA FORK: Two-step verification (PIN) nav target
    case twoStepVerification
    // GUA FORK: Find which of the user's phone contacts are on Gua
    case findFriends
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

    /// GUA FORK: When `true`, the advanced Encryption entry point is hidden from
    /// Settings. E2EE remains fully enabled with safe defaults.
    var hidesAdvancedEncryption = true

    /// GUA FORK: The bare localpart (e.g. "alice") of `userID`, hiding the
    /// "@" prefix and ":homeserver" suffix for Gua's frictionless design.
    /// Display-only — `userID` is still used for avatars and any logic.
    var userLocalpart: String {
        userID.hasPrefix("@") ? String(userID.dropFirst().prefix { $0 != ":" }) : userID
    }
    
    var securitySectionMode = SettingsScreenSecuritySectionMode.none
    var showSecuritySectionBadge = false
    
    var showBlockedUsers = false
    let showAnalyticsSettings: Bool
    
    let isBugReportServiceEnabled: Bool
    
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
    // GUA FORK: Two-step verification (PIN) action
    case twoStepVerification
    // GUA FORK: Find friends from phone contacts
    case findFriends
}

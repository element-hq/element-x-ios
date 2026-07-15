//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum SettingsScreenViewModelAction: Equatable {
    case close
    case userDetails
    case linkNewDevice
    case manageAccount(url: URL)
    case analytics
    case appLock
    case reportBug
    case about
    case blockedUsers
    case secureBackup
    case notifications
    case advancedSettings
    case labs
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
    var userProfile: UserProfile
    var showUserStatus: Bool
    var showLinkNewDeviceButton: Bool
    var accountProfileURL: URL?
    var showAccountDeactivation: Bool
    var showDeveloperOptions: Bool
    
    var securitySectionMode = SettingsScreenSecuritySectionMode.none
    var showSecuritySectionBadge = false
    
    var showBlockedUsers = false
    let showAnalyticsSettings: Bool
    
    let isBugReportServiceEnabled: Bool
    
    let navigationBarVisibility: Visibility
    
    var bindings = SettingsScreenViewStateBindings()
    
    var userStatusRowMode: SettingsScreenUserStatusRow.Mode {
        if bindings.isShowingCustomStatusField {
            .custom
        } else if let rawStatus = userProfile.status.raw {
            .show(rawStatus)
        } else {
            .pick
        }
    }
}

struct SettingsScreenViewStateBindings {
    var isPresentingStatusPicker = false
    var isShowingCustomStatusField = false
    var isPresentingAccountDeactivationConfirmation = false
}

enum SettingsScreenViewAction {
    case close
    case userDetails
    case userStatus(UserStatusAction)
    case analytics
    case appLock
    case reportBug
    case about
    case blockedUsers
    case secureBackup
    case linkNewDevice
    case manageAccount(url: URL)
    case notifications
    case enableDeveloperOptions
    case developerOptions
    case advancedSettings
    case labs
    case logout
    case deactivateAccount
    
    enum UserStatusAction {
        case pickStatus
        case customStatus
        case set(UserStatus.Raw?)
        case cancel
    }
}

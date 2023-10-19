//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit

enum SettingsScreenViewModelAction {
    case close
    case userDetails
    case accountProfile
    case analytics
    case appLock
    case reportBug
    case about
    case sessionVerification
    case accountSessionsList
    case notifications
    case advancedSettings
    case developerOptions
    case logout
}

struct SettingsScreenViewState: BindableState {
    var deviceID: String?
    var userID: String
    var accountProfileURL: URL?
    var accountSessionsListURL: URL?
    var userAvatarURL: URL?
    var userDisplayName: String?
    var showSessionVerificationSection: Bool
    var showAppLockSettings: Bool
    var showDeveloperOptions: Bool
    
    /// The presentation anchor used to display the OIDC account URL.
    var window: UIWindow?
}

enum SettingsScreenViewAction {
    case close
    case userDetails
    case accountProfile
    case analytics
    case appLock
    case reportBug
    case about
    case sessionVerification
    case accountSessionsList
    case notifications
    case developerOptions
    case advancedSettings
    case logout
    
    /// Updates the window used for the OIDC account URL anchor.
    case updateWindow(UIWindow)
}

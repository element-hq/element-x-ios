//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import LocalAuthentication

enum AppLockSetupSettingsScreenViewModelAction {
    /// The user would like to enter new PIN code.
    case changePINCode
    /// The user has disabled the App Lock feature.
    case appLockDisabled
}

struct AppLockSetupSettingsScreenViewState: BindableState {
    /// Whether App Lock is mandatory and can be disabled by the user.
    let isMandatory: Bool
    let biometryType: LABiometryType
    var bindings: AppLockSetupSettingsScreenViewStateBindings
    
    var supportsBiometrics: Bool { biometryType != .none }
    var enableBiometricsTitle: String { L10n.screenAppLockSetupBiometricUnlockAllowTitle(biometryType.localizedString) }
}

struct AppLockSetupSettingsScreenViewStateBindings {
    var enableBiometrics: Bool
    var alertInfo: AlertInfo<AppLockSetupSettingsScreenAlertType>?
}

enum AppLockSetupSettingsScreenAlertType {
    /// The alert shown to confirm the user would like to remove their PIN.
    case confirmRemovePINCode
}

enum AppLockSetupSettingsScreenViewAction {
    /// The user would like to enter a new PIN code.
    case changePINCode
    /// The user would like to disable the App Lock feature.
    case disable
    /// The user has toggled the biometrics setting.
    case enableBiometricsChanged
}

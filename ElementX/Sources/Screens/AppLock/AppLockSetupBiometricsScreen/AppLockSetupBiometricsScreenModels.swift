//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import LocalAuthentication
import SFSafeSymbols

enum AppLockSetupBiometricsScreenViewModelAction {
    case `continue`
}

struct AppLockSetupBiometricsScreenViewState: BindableState {
    /// The supported biometry type on this device.
    let biometryType: LABiometryType
    
    var icon: SFSymbol { biometryType.systemSymbol }
    var title: String { L10n.screenAppLockSetupBiometricUnlockAllowTitle(biometryType.localizedString) }
    var subtitle: String { L10n.screenAppLockSetupBiometricUnlockSubtitle(biometryType.localizedString) }
}

enum AppLockSetupBiometricsScreenViewAction {
    /// The user would like to use Touch/Face ID.
    case allow
    /// The user doesn't want to use biometrics.
    case skip
}

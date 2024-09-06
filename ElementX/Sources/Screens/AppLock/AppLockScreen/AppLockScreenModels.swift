//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum AppLockScreenViewModelAction {
    /// The user has successfully unlocked the app.
    case appUnlocked
    /// The user failed to unlock the app (or forgot their PIN).
    case forceLogout
}

struct AppLockScreenViewState: BindableState {
    /// The number of attempts allowed to unlock the app.
    let maximumAttempts = 3
    
    /// The number of times the user attempted to enter their PIN.
    var numberOfPINAttempts = 0
    /// An overlay indicator shown when the user is being logged out.
    var forcedLogoutIndicator: UserIndicator?
    
    var bindings: AppLockScreenViewStateBindings
    
    /// The number of digits the user has entered so far.
    var numberOfDigitsEntered: Int { bindings.pinCode.count }
    /// Whether the subtitle is in a warning state or not.
    var isSubtitleWarning: Bool { numberOfPINAttempts > 0 }
    /// The string shown in the screen's subtitle.
    var subtitle: String {
        if !isSubtitleWarning {
            return L10n.screenAppLockSubtitle(maximumAttempts)
        } else {
            return L10n.screenAppLockSubtitleWrongPin(maximumAttempts - numberOfPINAttempts)
        }
    }
}

struct AppLockScreenViewStateBindings {
    /// The PIN code entered by the user.
    var pinCode = ""
    var alertInfo: AlertInfo<AppLockScreenAlertType>?
}

enum AppLockScreenAlertType {
    /// The user has failed too many times, they're being logged out.
    case forcedLogout
    /// The user has forgotten their PIN, confirm they're happy to sign out.
    case confirmResetPIN
}

enum AppLockScreenViewAction {
    /// Clears the PIN code after a failure animation.
    case clearPINCode
    /// The user didn't heed the warnings and can't remember their PIN.
    case forgotPIN
}

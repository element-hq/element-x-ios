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

enum AppLockScreenViewModelAction {
    /// The user has successfully unlocked the app.
    case appUnlocked
    /// The user failed to unlock the app (or forgot their PIN).
    case forceLogout
}

struct AppLockScreenViewState: BindableState {
    private let maximumAttempts = 3
    
    /// The number of times the user attempted to enter their PIN.
    var numberOfPINAttempts = 0
    
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
    /// Attempt to unlock the app with the supplied PIN code.
    case submitPINCode
    /// Clears the PIN code after a failure animation.
    case clearPINCode
    /// The user didn't heed the warnings and can't remember their PIN.
    case forgotPIN
}

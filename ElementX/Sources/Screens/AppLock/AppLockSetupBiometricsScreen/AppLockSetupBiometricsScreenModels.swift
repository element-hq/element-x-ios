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

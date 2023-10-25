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

enum AppLockSetupPINScreenViewModelAction {
    /// The user succeeded PIN entry.
    case complete
    /// The user cancelled PIN entry.
    case cancel
}

enum AppLockSetupPINScreenMode {
    /// Creating a new PIN.
    case create
    /// Confirming the new PIN.
    case confirm
    /// Unlocking with the current PIN.
    case unlock
}

struct AppLockSetupPINScreenViewState: BindableState {
    /// The current mode that the screen is in.
    var mode: AppLockSetupPINScreenMode
    /// Whether the screen is mandatory or can be cancelled.
    let isMandatory: Bool
    
    var title: String {
        switch mode {
        case .create: return L10n.screenAppLockSetupChoosePin
        case .confirm: return L10n.screenAppLockSetupConfirmPin
        case .unlock: return L10n.commonEnterYourPin
        }
    }
    
    var subtitle: String? {
        switch mode {
        case .create, .confirm: return L10n.screenAppLockSetupPinContext(InfoPlistReader.main.bundleDisplayName)
        case .unlock: return nil
        }
    }
    
    var bindings: AppLockSetupPINScreenViewStateBindings
}

struct AppLockSetupPINScreenViewStateBindings {
    var pinCode: String
    var alertInfo: AlertInfo<AppLockSetupPINScreenAlertType>?
}

enum AppLockSetupPINScreenAlertType {
    /// The user entered a weak PIN and it has been rejected.
    case weakPIN
    /// The user entered the wrong PIN when confirming the creation.
    case pinMismatch
    /// An error occurred setting the PIN code in the App Lock service.
    case failedToSetPIN
}

enum AppLockSetupPINScreenViewAction {
    /// Confirm the entered PIN.
    case submitPINCode
    /// Stop entering a PIN.
    case cancel
}

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

import SwiftUI

typealias SoftLogoutScreenViewModelType = StateStoreViewModel<SoftLogoutScreenViewState, SoftLogoutScreenViewAction>

class SoftLogoutScreenViewModel: SoftLogoutScreenViewModelType, SoftLogoutScreenViewModelProtocol {
    var callback: (@MainActor (SoftLogoutScreenViewModelAction) -> Void)?

    init(credentials: SoftLogoutScreenCredentials,
         homeserver: LoginHomeserver,
         keyBackupNeeded: Bool,
         password: String = "") {
        let bindings = SoftLogoutScreenBindings(password: password)
        let viewState = SoftLogoutScreenViewState(credentials: credentials,
                                                  homeserver: homeserver,
                                                  keyBackupNeeded: keyBackupNeeded,
                                                  bindings: bindings)
        super.init(initialViewState: viewState)
    }
    
    override func process(viewAction: SoftLogoutScreenViewAction) {
        switch viewAction {
        case .login:
            callback?(.login(state.bindings.password))
        case .forgotPassword:
            callback?(.forgotPassword)
        case .clearAllData:
            callback?(.clearAllData)
        case .continueWithOIDC:
            callback?(.continueWithOIDC)
        case .updateWindow(let window):
            guard state.window != window else { return }
            Task { state.window = window }
        }
    }

    @MainActor func displayError(_ type: SoftLogoutScreenErrorType) {
        switch type {
        case .alert(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonError,
                                                 message: message)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
}

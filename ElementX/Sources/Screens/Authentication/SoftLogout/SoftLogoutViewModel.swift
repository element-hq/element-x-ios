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

typealias SoftLogoutViewModelType = StateStoreViewModel<SoftLogoutViewState, SoftLogoutViewAction>

class SoftLogoutViewModel: SoftLogoutViewModelType, SoftLogoutViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: (@MainActor (SoftLogoutViewModelAction) -> Void)?

    // MARK: - Setup

    init(credentials: SoftLogoutCredentials,
         homeserver: LoginHomeserver,
         keyBackupNeeded: Bool,
         password: String = "") {
        let bindings = SoftLogoutBindings(password: password)
        let viewState = SoftLogoutViewState(credentials: credentials,
                                            homeserver: homeserver,
                                            keyBackupNeeded: keyBackupNeeded,
                                            bindings: bindings)
        super.init(initialViewState: viewState)
    }

    // MARK: - Public
    
    override func process(viewAction: SoftLogoutViewAction) async {
        switch viewAction {
        case .login:
            callback?(.login(state.bindings.password))
        case .forgotPassword:
            callback?(.forgotPassword)
        case .clearAllData:
            callback?(.clearAllData)
        case .continueWithOIDC:
            callback?(.continueWithOIDC)
        }
    }

    @MainActor func displayError(_ type: SoftLogoutErrorType) {
        switch type {
        case .alert(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: ElementL10n.dialogTitleError,
                                                 message: message)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
}

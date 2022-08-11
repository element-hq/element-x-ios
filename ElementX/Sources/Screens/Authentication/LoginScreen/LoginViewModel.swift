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

typealias LoginViewModelType = StateStoreViewModel<LoginViewState, LoginViewAction>

class LoginViewModel: LoginViewModelType, LoginViewModelProtocol {
    // MARK: - Properties

    // MARK: Public

    var callback: (@MainActor (LoginViewModelAction) -> Void)?

    // MARK: - Setup

    init(homeserver: LoginHomeserver) {
        let bindings = LoginBindings()
        let viewState = LoginViewState(homeserver: homeserver, bindings: bindings)
        
        super.init(initialViewState: viewState)
    }
    
    // MARK: - Public

    override func process(viewAction: LoginViewAction) async {
        switch viewAction {
        case .selectServer:
            callback?(.selectServer)
        case .parseUsername:
            callback?(.parseUsername(state.bindings.username))
        case .forgotPassword:
            callback?(.forgotPassword)
        case .next:
            callback?(.login(username: state.bindings.username, password: state.bindings.password))
        case .continueWithOIDC:
            callback?(.continueWithOIDC)
        }
    }
    
    func update(isLoading: Bool) {
        guard state.isLoading != isLoading else { return }
        state.isLoading = isLoading
    }
    
    func update(homeserver: LoginHomeserver) {
        state.homeserver = homeserver
    }
    
    func displayError(_ type: LoginErrorType) {
        switch type {
        case .alert(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: ElementL10n.dialogTitleError,
                                                 message: message)
        case .invalidHomeserver:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: ElementL10n.dialogTitleError,
                                                 message: ElementL10n.loginSigninMatrixIdErrorInvalidMatrixId)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
}

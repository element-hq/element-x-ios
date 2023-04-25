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

typealias LoginScreenViewModelType = StateStoreViewModel<LoginScreenViewState, LoginScreenViewAction>

class LoginScreenViewModel: LoginScreenViewModelType, LoginScreenViewModelProtocol {
    var callback: (@MainActor (LoginScreenViewModelAction) -> Void)?

    init(homeserver: LoginHomeserver) {
        let bindings = LoginScreenBindings()
        let viewState = LoginScreenViewState(homeserver: homeserver, bindings: bindings)
        
        super.init(initialViewState: viewState)
    }

    override func process(viewAction: LoginScreenViewAction) {
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
    
    func displayError(_ type: LoginScreenErrorType) {
        switch type {
        case .alert(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonError,
                                                 message: message)
        case .invalidHomeserver:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonError,
                                                 message: L10n.screenLoginErrorInvalidUserId)
        case .slidingSyncAlert:
            let openURL = { UIApplication.shared.open(ServiceLocator.shared.settings.slidingSyncLearnMoreURL) }
            state.bindings.alertInfo = AlertInfo(id: .slidingSyncAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorNoSlidingSyncMessage,
                                                 primaryButton: .init(title: L10n.actionLearnMore, role: .cancel, action: openURL),
                                                 secondaryButton: .init(title: L10n.actionCancel, action: nil))
            
            // Clear out the invalid username to avoid an attempted login to matrix.org
            state.bindings.username = ""
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
}

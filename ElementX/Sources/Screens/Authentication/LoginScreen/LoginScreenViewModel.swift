//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias LoginScreenViewModelType = StateStoreViewModel<LoginScreenViewState, LoginScreenViewAction>

class LoginScreenViewModel: LoginScreenViewModelType, LoginScreenViewModelProtocol {
    private let slidingSyncLearnMoreURL: URL
    
    private var actionsSubject: PassthroughSubject<LoginScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<LoginScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(homeserver: LoginHomeserver, slidingSyncLearnMoreURL: URL) {
        self.slidingSyncLearnMoreURL = slidingSyncLearnMoreURL
        let bindings = LoginScreenBindings()
        let viewState = LoginScreenViewState(homeserver: homeserver, bindings: bindings)
        
        super.init(initialViewState: viewState)
    }

    override func process(viewAction: LoginScreenViewAction) {
        switch viewAction {
        case .parseUsername:
            actionsSubject.send(.parseUsername(state.bindings.username))
        case .forgotPassword:
            actionsSubject.send(.forgotPassword)
        case .next:
            actionsSubject.send(.login(username: state.bindings.username, password: state.bindings.password))
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
        case .invalidWellKnownAlert(let error):
            state.bindings.alertInfo = AlertInfo(id: .slidingSyncAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorInvalidWellKnown(error))
        case .slidingSyncAlert:
            let openURL = { UIApplication.shared.open(self.slidingSyncLearnMoreURL) }
            state.bindings.alertInfo = AlertInfo(id: .slidingSyncAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorNoSlidingSyncMessage,
                                                 primaryButton: .init(title: L10n.actionLearnMore, role: .cancel, action: openURL),
                                                 secondaryButton: .init(title: L10n.actionCancel, action: nil))
            
            // Clear out the invalid username to avoid an attempted login to matrix.org
            state.bindings.username = ""
        case .refreshTokenAlert:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenLoginErrorRefreshTokens)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias SoftLogoutScreenViewModelType = StateStoreViewModel<SoftLogoutScreenViewState, SoftLogoutScreenViewAction>

class SoftLogoutScreenViewModel: SoftLogoutScreenViewModelType, SoftLogoutScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<SoftLogoutScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<SoftLogoutScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

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
            actionsSubject.send(.login(state.bindings.password))
        case .forgotPassword:
            actionsSubject.send(.forgotPassword)
        case .clearAllData:
            actionsSubject.send(.clearAllData)
        case .continueWithOIDC:
            actionsSubject.send(.continueWithOIDC)
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
        case .refreshTokenAlert:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenLoginErrorRefreshTokens)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias AuthenticationStartScreenViewModelType = StateStoreViewModel<AuthenticationStartScreenViewState, AuthenticationStartScreenViewAction>

class AuthenticationStartScreenViewModel: AuthenticationStartScreenViewModelType, AuthenticationStartScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<AuthenticationStartScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<AuthenticationStartScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init() {
        super.init(initialViewState: AuthenticationStartScreenViewState())
        state.isQRCodeLoginEnabled = !ProcessInfo.processInfo.isiOSAppOnMac && AppSettings.isDevelopmentBuild
    }

    override func process(viewAction: AuthenticationStartScreenViewAction) {
        switch viewAction {
        case .loginManually:
            actionsSubject.send(.loginManually)
        case .loginWithQR:
            actionsSubject.send(.loginWithQR)
        case .reportProblem:
            actionsSubject.send(.reportProblem)
        }
    }
}

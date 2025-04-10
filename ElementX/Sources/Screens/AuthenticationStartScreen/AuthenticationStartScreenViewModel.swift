//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias AuthenticationStartScreenViewModelType = StateStoreViewModel<AuthenticationStartScreenViewState, AuthenticationStartScreenViewAction>

class AuthenticationStartScreenViewModel: AuthenticationStartScreenViewModelType, AuthenticationStartScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<AuthenticationStartScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<AuthenticationStartScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(showCreateAccountButton: Bool, isBugReportServiceEnabled: Bool) {
        super.init(initialViewState: AuthenticationStartScreenViewState(showCreateAccountButton: showCreateAccountButton,
                                                                        isQRCodeLoginEnabled: !ProcessInfo.processInfo.isiOSAppOnMac,
                                                                        isBugReportServiceEnabled: isBugReportServiceEnabled))
    }

    override func process(viewAction: AuthenticationStartScreenViewAction) {
        switch viewAction {
        case .loginManually:
            actionsSubject.send(.loginManually)
        case .loginWithQR:
            actionsSubject.send(.loginWithQR)
        case .register:
            actionsSubject.send(.register)
        case .reportProblem:
            actionsSubject.send(.reportProblem)
        }
    }
}

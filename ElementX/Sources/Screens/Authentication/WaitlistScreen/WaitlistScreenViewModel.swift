//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias WaitlistScreenViewModelType = StateStoreViewModel<WaitlistScreenViewState, WaitlistScreenViewAction>

class WaitlistScreenViewModel: WaitlistScreenViewModelType, WaitlistScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<WaitlistScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<WaitlistScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(homeserver: LoginHomeserver) {
        super.init(initialViewState: WaitlistScreenViewState(homeserver: homeserver))
    }
    
    // MARK: - Public
    
    override func process(viewAction: WaitlistScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.cancel)
        case .continue(let userSession):
            actionsSubject.send(.continue(userSession))
        }
    }
    
    func update(userSession: UserSessionProtocol) {
        state.userSession = userSession
    }
}

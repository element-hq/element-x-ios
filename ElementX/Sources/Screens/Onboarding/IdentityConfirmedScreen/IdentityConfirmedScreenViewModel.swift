//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias IdentityConfirmedScreenViewModelType = StateStoreViewModel<IdentityConfirmedScreenViewState, IdentityConfirmedScreenViewAction>

class IdentityConfirmedScreenViewModel: IdentityConfirmedScreenViewModelType, IdentityConfirmedScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<IdentityConfirmedScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<IdentityConfirmedScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init() {
        super.init(initialViewState: .init())
    }
    
    // MARK: - Public
    
    override func process(viewAction: IdentityConfirmedScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .done:
            actionsSubject.send(.done)
        }
    }
}

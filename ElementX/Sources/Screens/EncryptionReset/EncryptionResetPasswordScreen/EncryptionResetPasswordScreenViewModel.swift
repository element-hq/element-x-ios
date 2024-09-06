//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias EncryptionResetPasswordScreenViewModelType = StateStoreViewModel<EncryptionResetPasswordScreenViewState, EncryptionResetPasswordScreenViewAction>

class EncryptionResetPasswordScreenViewModel: EncryptionResetPasswordScreenViewModelType, EncryptionResetPasswordScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<EncryptionResetPasswordScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EncryptionResetPasswordScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init() {
        super.init(initialViewState: .init(bindings: .init(password: "")))
    }
    
    // MARK: - Public
    
    override func process(viewAction: EncryptionResetPasswordScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .resetIdentity:
            actionsSubject.send(.resetIdentity(state.bindings.password))
        }
    }
}

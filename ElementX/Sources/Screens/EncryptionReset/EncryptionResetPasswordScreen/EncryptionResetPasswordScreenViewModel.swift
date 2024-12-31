//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias EncryptionResetPasswordScreenViewModelType = StateStoreViewModel<EncryptionResetPasswordScreenViewState, EncryptionResetPasswordScreenViewAction>

class EncryptionResetPasswordScreenViewModel: EncryptionResetPasswordScreenViewModelType, EncryptionResetPasswordScreenViewModelProtocol {
    private let passwordPublisher: PassthroughSubject<String, Never>
    
    private let actionsSubject: PassthroughSubject<EncryptionResetPasswordScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EncryptionResetPasswordScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(passwordPublisher: PassthroughSubject<String, Never>) {
        self.passwordPublisher = passwordPublisher
        
        super.init(initialViewState: .init(bindings: .init(password: "")))
    }
    
    // MARK: - Public
    
    override func process(viewAction: EncryptionResetPasswordScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .submit:
            passwordPublisher.send(state.bindings.password)
            actionsSubject.send(.passwordEntered)
        }
    }
}

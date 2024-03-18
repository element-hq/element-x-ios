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

import Combine
import SwiftUI

typealias IdentityConfirmationScreenViewModelType = StateStoreViewModel<IdentityConfirmationScreenViewState, IdentityConfirmationScreenViewAction>

class IdentityConfirmationScreenViewModel: IdentityConfirmationScreenViewModelType, IdentityConfirmationScreenViewModelProtocol {
    private let userSession: UserSessionProtocol
    
    private let actionsSubject: PassthroughSubject<IdentityConfirmationScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<IdentityConfirmationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol) {
        self.userSession = userSession
        
        super.init(initialViewState: IdentityConfirmationScreenViewState())
        
        userSession.sessionSecurityStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                Task {
                    await self?.updateWithSessionSecurityState(state)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: IdentityConfirmationScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        switch viewAction {
        case .otherDevice:
            actionsSubject.send(.otherDevice)
        case .recoveryKey:
            actionsSubject.send(.recoveryKey)
        }
    }
    
    // MARK: - Private
    
    private func updateWithSessionSecurityState(_ sessionSecurityState: SessionSecurityState) async {
        guard sessionSecurityState.verificationState == .unverified else {
            return
        }
        
        guard case let .success(isOnlyDeviceLeft) = await userSession.clientProxy.isOnlyDeviceLeft() else {
            return
        }
        
        state.mode = isOnlyDeviceLeft ? .recoveryOnly : .recoveryAndVerification
    }
}

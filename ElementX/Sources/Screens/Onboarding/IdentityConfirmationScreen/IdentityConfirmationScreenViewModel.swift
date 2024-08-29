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
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<IdentityConfirmationScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<IdentityConfirmationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol, appSettings: AppSettings, userIndicatorController: UserIndicatorControllerProtocol) {
        self.userSession = userSession
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: IdentityConfirmationScreenViewState(learnMoreURL: appSettings.encryptionURL))
        
        userSession.sessionSecurityStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                Task {
                    await self?.updateWithSessionSecurityState(state)
                }
            }
            .store(in: &cancellables)
        
        Task {
            await updateWithSessionSecurityState(userSession.sessionSecurityStatePublisher.value)
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: IdentityConfirmationScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        switch viewAction {
        case .otherDevice:
            actionsSubject.send(.otherDevice)
        case .recoveryKey:
            actionsSubject.send(.recoveryKey)
        case .skip:
            actionsSubject.send(.skip)
        case .reset:
            actionsSubject.send(.reset)
        case .logout:
            actionsSubject.send(.logout)
        }
    }
    
    // MARK: - Private
    
    private func updateWithSessionSecurityState(_ sessionSecurityState: SessionSecurityState) async {
        if sessionSecurityState.verificationState == .unknown {
            showLoadingIndicator()
        } else {
            hideLoadingIndicator()
        }
        
        guard sessionSecurityState.verificationState == .unverified else {
            return
        }
        
        var availableActions: [IdentityConfirmationScreenViewState.AvailableActions] = []
        
        if case let .success(isOnlyDeviceLeft) = await userSession.clientProxy.isOnlyDeviceLeft(),
           !isOnlyDeviceLeft {
            availableActions.append(.interactiveVerification)
        }
        
        if sessionSecurityState.recoveryState == .enabled || sessionSecurityState.recoveryState == .incomplete {
            availableActions.append(.recovery)
        }
        
        state.availableActions = availableActions
    }
    
    private static let loadingIndicatorIdentifier = "\(IdentityConfirmationScreenViewModel.self)-Loading"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

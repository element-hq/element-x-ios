//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias IdentityConfirmationScreenViewModelType = StateStoreViewModelV2<IdentityConfirmationScreenViewState, IdentityConfirmationScreenViewAction>

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
        
        super.init(initialViewState: IdentityConfirmationScreenViewState(learnMoreURL: appSettings.deviceVerificationURL))
        
        Task { [weak self] in
            for await state in userSession.sessionSecurityStatePublisher.values {
                // We need to call this inside an AsyncSequence otherwise there's a race condition when the method suspends.
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
        case .skip:
            actionsSubject.send(.skip)
        case .reset:
            actionsSubject.send(.reset)
        case .logout:
            confirmLogout()
        }
    }
    
    // MARK: - Private
    
    private func updateWithSessionSecurityState(_ sessionSecurityState: SessionSecurityState) async {
        if sessionSecurityState.verificationState == .unknown {
            showLoadingIndicator()
        } else {
            hideLoadingIndicator()
        }
        
        // Note: Until the actions are unset, there's a disabled action button with a loading spinner.
        
        guard sessionSecurityState.verificationState == .unverified else {
            return
        }
        
        // Continue to show the loading action button until we know that there's a recovery set up.
        // https://github.com/element-hq/element-x-ios/issues/4699
        guard sessionSecurityState.recoveryState != .unknown else {
            return
        }
        
        var availableActions: [IdentityConfirmationScreenViewState.AvailableActions] = []
        
        if case let .success(hasDevicesToVerifyAgainst) = await userSession.clientProxy.hasDevicesToVerifyAgainst(),
           hasDevicesToVerifyAgainst {
            availableActions.append(.interactiveVerification)
        }
        
        if sessionSecurityState.recoveryState == .enabled || sessionSecurityState.recoveryState == .incomplete {
            availableActions.append(.recovery)
        }
        
        state.availableActions = availableActions
    }
    
    private func confirmLogout() {
        // We need to show the confirmation within this flow as letting the UserSession flow do it results in the
        // onboarding flow's modal being dismissed (by SwiftUI, not us). However we don't need any of the additional
        // checks made in the UserSession flow as the user's account isn't verified so there's no much they can do unless
        // they complete verification.
        state.bindings.alertInfo = .init(id: .logout,
                                         title: L10n.screenSignoutConfirmationDialogTitle,
                                         message: L10n.screenSignoutConfirmationDialogContent,
                                         primaryButton: .init(title: L10n.screenSignoutConfirmationDialogSubmit, role: .destructive) { [weak self] in
                                             self?.actionsSubject.send(.logoutConfirmed)
                                         })
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

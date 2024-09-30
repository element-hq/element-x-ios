//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias AppLockScreenViewModelType = StateStoreViewModel<AppLockScreenViewState, AppLockScreenViewAction>

class AppLockScreenViewModel: AppLockScreenViewModelType, AppLockScreenViewModelProtocol {
    private let appLockService: AppLockServiceProtocol
    private var actionsSubject: PassthroughSubject<AppLockScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<AppLockScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(appLockService: AppLockServiceProtocol) {
        self.appLockService = appLockService
        
        super.init(initialViewState: AppLockScreenViewState(bindings: .init()))
        
        appLockService.numberOfPINAttempts
            .weakAssign(to: \.state.numberOfPINAttempts, on: self)
            .store(in: &cancellables)
        
        context.$viewState
            .map(\.bindings.pinCode)
            .removeDuplicates()
            .debounce(for: 0.05, scheduler: DispatchQueue.main) // Allow the last digit to be briefly shown
            .sink { [weak self] pinCode in
                guard pinCode.count == 4 else { return }
                self?.submit(pinCode)
            }
            .store(in: &cancellables)
        
        showForceLogoutAlertIfNeeded()
    }
    
    // MARK: - Public
    
    override func process(viewAction: AppLockScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .clearPINCode:
            state.bindings.pinCode = ""
        case .forgotPIN:
            handleForgotPIN()
        }
    }
    
    // MARK: - Private
    
    private func submit(_ pinCode: String) {
        guard appLockService.unlock(with: pinCode) else {
            handleInvalidPIN()
            return
        }
        actionsSubject.send(.appUnlocked)
    }
    
    private func handleForgotPIN() {
        state.bindings.alertInfo = .init(id: .confirmResetPIN,
                                         title: L10n.screenAppLockSignoutAlertTitle,
                                         message: L10n.screenAppLockSignoutAlertMessage,
                                         primaryButton: .init(title: L10n.actionOk) { self.forceLogout() },
                                         secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
    }
    
    private func handleInvalidPIN() {
        MXLog.warning("Invalid PIN code entered.")
        showForceLogoutAlertIfNeeded()
    }
    
    private func showForceLogoutAlertIfNeeded() {
        if state.numberOfPINAttempts >= state.maximumAttempts {
            state.bindings.alertInfo = .init(id: .forcedLogout,
                                             title: L10n.screenAppLockSignoutAlertTitle,
                                             message: L10n.screenAppLockSignoutAlertMessage,
                                             primaryButton: .init(title: L10n.actionOk) { self.forceLogout() })
        }
    }
    
    private func forceLogout() {
        state.forcedLogoutIndicator = UserIndicator(type: .modal, title: L10n.commonSigningOut, persistent: true)
        actionsSubject.send(.forceLogout)
    }
}

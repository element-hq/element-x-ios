//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ClassicAppAccountConfirmationScreenViewModelType = StateStoreViewModelV2<ClassicAppAccountConfirmationScreenViewState, ClassicAppAccountConfirmationScreenViewAction>

class ClassicAppAccountConfirmationScreenViewModel: ClassicAppAccountConfirmationScreenViewModelType, ClassicAppAccountConfirmationScreenViewModelProtocol {
    let classicAppAccount: ClassicAppAccount
    let authenticationService: AuthenticationServiceProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<ClassicAppAccountConfirmationScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ClassicAppAccountConfirmationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(classicAppAccount: ClassicAppAccount,
         authenticationService: AuthenticationServiceProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.classicAppAccount = classicAppAccount
        self.authenticationService = authenticationService
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: ClassicAppAccountConfirmationScreenViewState(classicAppAccount: classicAppAccount))
    }
    
    // MARK: - Public
    
    override func process(viewAction: ClassicAppAccountConfirmationScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .continue:
            Task { await configureAccountProvider() }
        case .updateWindow(let window):
            guard state.window != window else { return }
            state.window = window
        }
    }
    
    // MARK: - Private
    
    private func configureAccountProvider() async {
        startLoading()
        defer { stopLoading() }
        
        guard case .success = await authenticationService.configure(for: classicAppAccount) else {
            // As the server was provisioned, we don't worry about the specifics and show a generic error to the user.
            displayError()
            return
        }
        
        let loginHint = "mxid:\(classicAppAccount.userID)"
        
        guard authenticationService.homeserver.value.loginMode.supportsOIDCFlow else {
            actionsSubject.send(.loginDirectlyWithPassword(loginHint: loginHint))
            return
        }
        
        guard let window = state.window else {
            displayError()
            return
        }
        
        switch await authenticationService.urlForOIDCLogin(loginHint: loginHint) {
        case .success(let oidcData):
            actionsSubject.send(.loginDirectlyWithOIDC(data: oidcData, window: window))
        case .failure:
            displayError()
        }
    }
    
    private var loadingIndicatorID: String {
        "\(Self.self)-Loading"
    }
    
    private func startLoading() {
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorID,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func stopLoading() {
        userIndicatorController.retractIndicatorWithId(loadingIndicatorID)
    }
    
    private func displayError() {
        #warning("We need specific messages here.")
        state.bindings.alertInfo = AlertInfo(id: .genericError)
    }
}

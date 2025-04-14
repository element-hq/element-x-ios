//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ServerConfirmationScreenViewModelType = StateStoreViewModel<ServerConfirmationScreenViewState, ServerConfirmationScreenViewAction>

class ServerConfirmationScreenViewModel: ServerConfirmationScreenViewModelType, ServerConfirmationScreenViewModelProtocol {
    let authenticationService: AuthenticationServiceProtocol
    let authenticationFlow: AuthenticationFlow
    let slidingSyncLearnMoreURL: URL
    let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<ServerConfirmationScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<ServerConfirmationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(authenticationService: AuthenticationServiceProtocol,
         authenticationFlow: AuthenticationFlow,
         slidingSyncLearnMoreURL: URL,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.authenticationService = authenticationService
        self.authenticationFlow = authenticationFlow
        self.slidingSyncLearnMoreURL = slidingSyncLearnMoreURL
        self.userIndicatorController = userIndicatorController
        
        let homeserver = authenticationService.homeserver.value
        super.init(initialViewState: ServerConfirmationScreenViewState(homeserverAddress: homeserver.address,
                                                                       authenticationFlow: authenticationFlow))
        
        authenticationService.homeserver
            .receive(on: DispatchQueue.main)
            .map(\.address)
            .weakAssign(to: \.state.homeserverAddress, on: self)
            .store(in: &cancellables)
    }
    
    override func process(viewAction: ServerConfirmationScreenViewAction) {
        switch viewAction {
        case .updateWindow(let window):
            guard state.window != window else { return }
            Task { state.window = window }
        case .confirm:
            Task { await confirmHomeserver() }
        case .changeServer:
            actionsSubject.send(.changeServer)
        }
    }
    
    // MARK: - Private
    
    private func confirmHomeserver() async {
        let homeserver = authenticationService.homeserver.value
        
        // If the login mode is unknown, the service hasn't be configured and we need to do it now.
        // Otherwise we can continue the flow as server selection has been performed and succeeded.
        guard homeserver.loginMode == .unknown || authenticationService.flow != authenticationFlow else {
            await fetchLoginURLIfNeededAndContinue()
            return
        }
        
        startLoading()
        defer { stopLoading() }
        
        switch await authenticationService.configure(for: homeserver.address, flow: authenticationFlow) {
        case .success:
            await fetchLoginURLIfNeededAndContinue()
        case .failure(let error):
            switch error {
            case .invalidServer, .invalidHomeserverAddress:
                displayError(.homeserverNotFound)
            case .invalidWellKnown(let error):
                displayError(.invalidWellKnown(error))
            case .slidingSyncNotAvailable:
                displayError(.slidingSync)
            case .loginNotSupported:
                displayError(.login)
            case .registrationNotSupported:
                displayError(.registration)
            default:
                displayError(.unknownError)
            }
        }
    }
    
    private func fetchLoginURLIfNeededAndContinue() async {
        guard authenticationService.homeserver.value.loginMode.supportsOIDCFlow else {
            actionsSubject.send(.continueWithPassword)
            return
        }
        
        guard let window = state.window else {
            displayError(.unknownError)
            return
        }
        
        startLoading() // Uses the same ID, so no need to worry if the indicator already exists
        defer { stopLoading() }
        
        switch await authenticationService.urlForOIDCLogin() {
        case .success(let oidcData):
            actionsSubject.send(.continueWithOIDC(data: oidcData, window: window))
        case .failure:
            displayError(.unknownError)
        }
    }
    
    private let loadingIndicatorID = "\(ServerConfirmationScreenViewModel.self)-Loading"
    
    private func startLoading() {
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorID,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func stopLoading() {
        userIndicatorController.retractIndicatorWithId(loadingIndicatorID)
    }
    
    private func displayError(_ type: ServerConfirmationScreenAlert) {
        switch type {
        case .homeserverNotFound:
            state.bindings.alertInfo = AlertInfo(id: .homeserverNotFound,
                                                 title: L10n.errorUnknown,
                                                 message: L10n.screenChangeServerErrorInvalidHomeserver)
        case .invalidWellKnown(let error):
            state.bindings.alertInfo = AlertInfo(id: .invalidWellKnown(error),
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorInvalidWellKnown(error))
        case .slidingSync:
            let openURL = { UIApplication.shared.open(self.slidingSyncLearnMoreURL) }
            state.bindings.alertInfo = AlertInfo(id: .slidingSync,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorNoSlidingSyncMessage,
                                                 primaryButton: .init(title: L10n.actionLearnMore, role: .cancel, action: openURL),
                                                 secondaryButton: .init(title: L10n.actionCancel, action: nil))
        case .login:
            state.bindings.alertInfo = AlertInfo(id: .login,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenLoginErrorUnsupportedAuthentication)
        case .registration:
            state.bindings.alertInfo = AlertInfo(id: .registration,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.errorAccountCreationNotPossible)
        case .unknownError:
            state.bindings.alertInfo = AlertInfo(id: .unknownError)
        }
    }
}

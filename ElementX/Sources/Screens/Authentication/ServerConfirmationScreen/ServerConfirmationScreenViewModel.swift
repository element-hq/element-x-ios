//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ServerConfirmationScreenViewModelType = StateStoreViewModelV2<ServerConfirmationScreenViewState, ServerConfirmationScreenViewAction>

class ServerConfirmationScreenViewModel: ServerConfirmationScreenViewModelType, ServerConfirmationScreenViewModelProtocol {
    let authenticationService: AuthenticationServiceProtocol
    let authenticationFlow: AuthenticationFlow
    let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<ServerConfirmationScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<ServerConfirmationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(authenticationService: AuthenticationServiceProtocol,
         mode: ServerConfirmationScreenMode,
         authenticationFlow: AuthenticationFlow,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.authenticationService = authenticationService
        self.authenticationFlow = authenticationFlow
        self.userIndicatorController = userIndicatorController
        
        let pickerSelection: String? = switch mode {
        case .picker(let providers): providers[0]
        case .confirmation: nil
        }
        
        super.init(initialViewState: ServerConfirmationScreenViewState(mode: mode,
                                                                       authenticationFlow: authenticationFlow,
                                                                       bindings: .init(pickerSelection: pickerSelection)))
        
        if case .confirmation = mode {
            authenticationService.homeserver
                .receive(on: DispatchQueue.main)
                .map { .confirmation($0.address) }
                .weakAssign(to: \.state.mode, on: self)
                .store(in: &cancellables)
        }
    }
    
    override func process(viewAction: ServerConfirmationScreenViewAction) {
        switch viewAction {
        case .updateWindow(let window):
            guard state.window != window else { return }
            Task { state.window = window }
        case .confirm:
            switch state.mode {
            case .confirmation: Task { await confirmServer() }
            case .picker: Task { await pickServer() }
            }
        case .changeServer:
            actionsSubject.send(.changeServer)
        }
    }
    
    // MARK: - Private
    
    private func confirmServer() async {
        let homeserver = authenticationService.homeserver.value
        
        // If the login mode is unknown, the service hasn't been configured and we need to do it now.
        // Otherwise we can continue the flow as server selection has been performed and succeeded.
        guard homeserver.loginMode == .unknown || authenticationService.flow != authenticationFlow else {
            await fetchLoginURLIfNeededAndContinue()
            return
        }
        
        // Note: We don't show the spinner until now as it isn't needed if the service is already
        // configured and we're about to use password based login
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
    
    private func pickServer() async {
        guard let accountProvider = state.bindings.pickerSelection else {
            fatalError("It shouldn't be possible to confirm without a selection.")
        }
        
        // Don't bother reconfiguring the service if it has already been done for the selected server.
        let homeserver = authenticationService.homeserver.value
        guard homeserver.loginMode == .unknown || homeserver.address != accountProvider else {
            await fetchLoginURLIfNeededAndContinue()
            return
        }
        
        // Note: We don't show the spinner until now as it isn't needed if the service is already
        // configured and we're about to use password based login
        startLoading()
        defer { stopLoading() }
        
        switch await authenticationService.configure(for: accountProvider, flow: authenticationFlow) {
        case .success:
            await fetchLoginURLIfNeededAndContinue()
        case .failure:
            // When the servers are hard-coded they should have a valid configuration, so show a generic error.
            displayError(.unknownError)
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
        
        switch await authenticationService.urlForOIDCLogin(loginHint: nil) {
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
            let nonBreakingAppName = InfoPlistReader.main.bundleDisplayName.replacingOccurrences(of: " ", with: "\u{00A0}")
            state.bindings.alertInfo = AlertInfo(id: .slidingSync,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorNoSlidingSyncMessage(nonBreakingAppName))
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

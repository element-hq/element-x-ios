//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ServerConfirmationScreenViewModelType = StateStoreViewModelV2<ServerConfirmationScreenViewState, ServerConfirmationScreenViewAction>

class ServerConfirmationScreenViewModel: ServerConfirmationScreenViewModelType, ServerConfirmationScreenViewModelProtocol {
    let authenticationService: AuthenticationServiceProtocol
    let authenticationFlow: AuthenticationFlow
    let appSettings: AppSettings
    let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<ServerConfirmationScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<ServerConfirmationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(authenticationService: AuthenticationServiceProtocol,
         mode: ServerConfirmationScreenMode,
         authenticationFlow: AuthenticationFlow,
         appSettings: AppSettings,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.authenticationService = authenticationService
        self.authenticationFlow = authenticationFlow
        self.appSettings = appSettings
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
            case .confirmation:
                startLoading()
                Task { await confirmServer() }
            case .picker:
                startLoading()
                Task { await pickServer() }
            }
        case .changeServer:
            actionsSubject.send(.changeServer)
        }
    }
    
    // MARK: - Private
    
    private func confirmServer() async {
        defer { stopLoading() }
        startLoading()
        
        let homeserver = authenticationService.homeserver.value
        
        // If the login mode is unknown, the service hasn't been configured and we need to do it now.
        // Otherwise we can continue the flow as server selection has been performed and succeeded.
        guard homeserver.loginMode == .unknown || authenticationService.flow != authenticationFlow else {
            await fetchLoginURLIfNeededAndContinue()
            return
        }
        
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
            case .elementProRequired(let serverName):
                displayError(.elementProRequired(serverName: serverName))
            default:
                displayError(.unknownError)
            }
        }
    }
    
    private func pickServer() async {
        defer { stopLoading() }
        startLoading()
        
        guard let accountProvider = state.bindings.pickerSelection else {
            fatalError("It shouldn't be possible to confirm without a selection.")
        }
        
        // Don't bother reconfiguring the service if it has already been done for the selected server.
        let homeserver = authenticationService.homeserver.value
        guard homeserver.loginMode == .unknown || homeserver.address != accountProvider else {
            await fetchLoginURLIfNeededAndContinue()
            return
        }
        
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
        case .elementProRequired(let serverName):
            state.bindings.alertInfo = AlertInfo(id: .elementProRequired(serverName: serverName),
                                                 title: L10n.screenChangeServerErrorElementProRequiredTitle,
                                                 message: L10n.screenChangeServerErrorElementProRequiredMessage(serverName),
                                                 primaryButton: .init(title: L10n.screenChangeServerErrorElementProRequiredActionIos) {
                                                     UIApplication.shared.open(self.appSettings.elementProAppStoreURL)
                                                 },
                                                 secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        case .unknownError:
            state.bindings.alertInfo = AlertInfo(id: .unknownError)
        }
    }
}

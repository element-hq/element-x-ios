//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
                                                                       authenticationFlow: authenticationFlow,
                                                                       homeserverSupportsRegistration: homeserver.supportsRegistration))
        
        authenticationService.homeserver
            .receive(on: DispatchQueue.main)
            .sink { [weak self] homeserver in
                guard let self else { return }
                state.homeserverAddress = homeserver.address
                state.homeserverSupportsRegistration = homeserver.supportsRegistration
            }
            .store(in: &cancellables)
    }
    
    override func process(viewAction: ServerConfirmationScreenViewAction) {
        switch viewAction {
        case .updateWindow(let window):
            guard state.window != window else { return }
            Task { state.window = window }
        case .confirm:
            Task { await configureAndContinue() }
        case .changeServer:
            actionsSubject.send(.changeServer)
        }
    }
    
    // MARK: - Private
    
    private func configureAndContinue() async {
        let homeserver = authenticationService.homeserver.value
        
        // If the login mode is unknown, the service hasn't be configured and we need to do it now.
        // Otherwise we can continue the flow as server selection has been performed and succeeded.
        guard homeserver.loginMode == .unknown || authenticationService.flow != authenticationFlow else {
            // TODO: [DOUG] Test this.
            actionsSubject.send(.confirm)
            return
        }
        
        startLoading()
        defer { stopLoading() }
        
        switch await authenticationService.configure(for: homeserver.address, flow: authenticationFlow) {
        case .success:
            actionsSubject.send(.confirm)
        case .failure(let error):
            switch error {
            case .invalidServer, .invalidHomeserverAddress:
                displayError(.homeserverNotFound)
            case .invalidWellKnown(let error):
                displayError(.invalidWellKnown(error))
            case .slidingSyncNotAvailable:
                displayError(.slidingSync)
            case .registrationNotSupported:
                displayError(.registration) // TODO: [DOUG] Test me!
            default:
                displayError(.unknownError)
            }
        }
    }
    
    private func startLoading(label: String = L10n.commonLoading) {
        userIndicatorController.submitIndicator(UserIndicator(type: .modal,
                                                              title: label,
                                                              persistent: true))
    }
    
    private func stopLoading() {
        userIndicatorController.retractAllIndicators()
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
        case .registration:
            state.bindings.alertInfo = AlertInfo(id: .registration,
                                                 title: L10n.errorUnknown,
                                                 message: L10n.errorAccountCreationNotPossible)
        case .unknownError:
            state.bindings.alertInfo = AlertInfo(id: .unknownError)
        }
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ServerSelectionScreenViewModelType = StateStoreViewModel<ServerSelectionScreenViewState, ServerSelectionScreenViewAction>

class ServerSelectionScreenViewModel: ServerSelectionScreenViewModelType, ServerSelectionScreenViewModelProtocol {
    private let authenticationService: AuthenticationServiceProtocol
    private let authenticationFlow: AuthenticationFlow
    private let slidingSyncLearnMoreURL: URL
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<ServerSelectionScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<ServerSelectionScreenViewModelAction, Never> {
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
        
        let bindings = ServerSelectionScreenBindings(homeserverAddress: authenticationService.homeserver.value.address)
        super.init(initialViewState: ServerSelectionScreenViewState(slidingSyncLearnMoreURL: slidingSyncLearnMoreURL, bindings: bindings))
    }
    
    override func process(viewAction: ServerSelectionScreenViewAction) {
        switch viewAction {
        case .confirm:
            configureHomeserver()
        case .dismiss:
            actionsSubject.send(.dismiss)
        case .clearFooterError:
            clearFooterError()
        }
    }
    
    // MARK: - Private
    
    /// Updates the login flow using the supplied homeserver address, or shows an error when this isn't possible.
    private func configureHomeserver() {
        let homeserverAddress = state.bindings.homeserverAddress
        startLoading()
        
        Task {
            switch await authenticationService.configure(for: homeserverAddress, flow: authenticationFlow) {
            case .success:
                MXLog.info("Selected homeserver: \(homeserverAddress)")
                actionsSubject.send(.updated)
                stopLoading()
            case .failure(let error):
                MXLog.info("Invalid homeserver: \(homeserverAddress)")
                stopLoading()
                handleError(error)
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
    
    /// Processes an error to either update the flow or display it to the user.
    private func handleError(_ error: AuthenticationServiceError) {
        switch error {
        case .invalidServer, .invalidHomeserverAddress:
            showFooterMessage(L10n.screenChangeServerErrorInvalidHomeserver)
        case .invalidWellKnown(let error):
            state.bindings.alertInfo = AlertInfo(id: .invalidWellKnownAlert(error),
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorInvalidWellKnown(error))
        case .slidingSyncNotAvailable:
            let openURL = { UIApplication.shared.open(self.slidingSyncLearnMoreURL) }
            state.bindings.alertInfo = AlertInfo(id: .slidingSyncAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorNoSlidingSyncMessage,
                                                 primaryButton: .init(title: L10n.actionLearnMore, role: .cancel, action: openURL),
                                                 secondaryButton: .init(title: L10n.actionCancel, action: nil))
        case .loginNotSupported:
            state.bindings.alertInfo = AlertInfo(id: .loginAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenLoginErrorUnsupportedAuthentication)
        case .registrationNotSupported:
            state.bindings.alertInfo = AlertInfo(id: .registrationAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.errorAccountCreationNotPossible)
        default:
            showFooterMessage(L10n.errorUnknown)
        }
    }
    
    /// Set a new error message to be shown in the text field footer.
    private func showFooterMessage(_ message: String) {
        withElementAnimation {
            state.footerErrorMessage = message
        }
    }
    
    /// Clear any errors shown in the text field footer.
    private func clearFooterError() {
        guard state.footerErrorMessage != nil else { return }
        withElementAnimation { state.footerErrorMessage = nil }
    }
}

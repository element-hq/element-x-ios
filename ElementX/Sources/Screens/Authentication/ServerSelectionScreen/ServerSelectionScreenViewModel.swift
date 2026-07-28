//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ServerSelectionScreenViewModelType = StateStoreViewModelV2<ServerSelectionScreenViewState, ServerSelectionScreenViewAction>

class ServerSelectionScreenViewModel: ServerSelectionScreenViewModelType, ServerSelectionScreenViewModelProtocol {
    private let authenticationService: AuthenticationServiceProtocol
    private let authenticationFlow: AuthenticationFlow
    private let appSettings: AppSettings
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    /// Debounces autocompletion from user input
    private var debouncedKeystrokeTask: Task<Void, Never>?
    
    private var actionsSubject: PassthroughSubject<ServerSelectionScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<ServerSelectionScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(authenticationService: AuthenticationServiceProtocol,
         mode: ServerSelectionScreenMode,
         authenticationFlow: AuthenticationFlow,
         appSettings: AppSettings,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.authenticationService = authenticationService
        self.authenticationFlow = authenticationFlow
        self.appSettings = appSettings
        self.userIndicatorController = userIndicatorController
        
        let homeserverAddress: String
        if case .picker(let providers) = mode {
            homeserverAddress = providers[0]
        } else {
            homeserverAddress = authenticationService.homeserver.value.address
        }
        let bindings = ServerSelectionScreenBindings(homeserverAddress: homeserverAddress)
        super.init(initialViewState: ServerSelectionScreenViewState(mode: mode, authenticationFlow: authenticationFlow, bindings: bindings))
        
        context.viewState.adapter.keystrokePublisher
            .sink { [weak self] in
                self?.didUpdateTextFromKeystroke(userProvidedString: $0)
            }
            .store(in: &cancellables)
    }
    
    override func process(viewAction: ServerSelectionScreenViewAction) {
        switch viewAction {
        case .updateWindow(let window):
            guard state.window != window else { return } // stop the infinite loop
            state.window = window
        case .updateTextField(let textField):
            guard state.textField != textField else { return } // stop the infinite loop
            state.textField = textField
        case .confirm:
            switch state.mode {
            case .userInput:
                Task { await configureHomeserver() }
            case .picker:
                Task { await pickServer() }
            }
        case .dismiss:
            actionsSubject.send(.dismiss)
        case .clearFooterError:
            clearFooterError()
        }
    }
    
    // MARK: - Private
    
    private func pickServer() async {
        let accountProvider = state.bindings.homeserverAddress
        guard accountProvider.isEmpty == false else {
            fatalError("It shouldn't be possible to confirm without a selection.")
        }
        
        startLoading()
        
        let homeserver = authenticationService.homeserver.value
        guard homeserver.loginMode == .unknown || homeserver.address != accountProvider else {
            await fetchLoginURLIfNeededAndContinue()
            stopLoading()
            return
        }
        
        switch await authenticationService.configure(for: accountProvider, flow: authenticationFlow) {
        case .success:
            await fetchLoginURLIfNeededAndContinue()
            stopLoading()
        case .failure:
            stopLoading()
            state.bindings.alertInfo = AlertInfo(id: .unknownError)
        }
    }
    
    /// Updates the login flow using the supplied homeserver address, or shows an error when this isn't possible.
    private func configureHomeserver() async {
        let homeserverAddress = state.bindings.homeserverAddress
        startLoading()
        
        switch await authenticationService.configure(for: homeserverAddress, flow: authenticationFlow) {
        case .success:
            MXLog.info("Selected homeserver: \(homeserverAddress)")
            await fetchLoginURLIfNeededAndContinue()
            stopLoading()
        case .failure(let error):
            MXLog.info("Invalid homeserver: \(homeserverAddress)")
            stopLoading()
            handleError(error)
        }
    }
    
    private func fetchLoginURLIfNeededAndContinue() async {
        guard authenticationService.homeserver.value.loginMode.supportsOAuthFlow else {
            actionsSubject.send(.continueWithPassword)
            return
        }
        
        guard let window = state.window else {
            showFooterMessage(L10n.errorUnknown)
            return
        }
        
        switch await authenticationService.urlForOAuthLogin(loginHint: nil) {
        case .success(let oAuthData):
            actionsSubject.send(.continueWithOAuth(data: oAuthData, window: window))
        case .failure:
            showFooterMessage(L10n.errorUnknown)
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
            let nonBreakingAppName = InfoPlistReader.main.bundleDisplayName.replacingOccurrences(of: " ", with: "\u{00A0}")
            state.bindings.alertInfo = AlertInfo(id: .slidingSyncAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenChangeServerErrorNoSlidingSyncMessage(nonBreakingAppName))
        case .loginNotSupported:
            state.bindings.alertInfo = AlertInfo(id: .loginAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.screenLoginErrorUnsupportedAuthentication)
        case .registrationNotSupported:
            state.bindings.alertInfo = AlertInfo(id: .registrationAlert,
                                                 title: L10n.commonServerNotSupported,
                                                 message: L10n.errorAccountCreationNotPossible)
        case .elementProRequired(let serverName):
            state.bindings.alertInfo = AlertInfo(id: .elementProAlert,
                                                 title: L10n.screenChangeServerErrorElementProRequiredTitle,
                                                 message: L10n.screenChangeServerErrorElementProRequiredMessage(serverName),
                                                 primaryButton: .init(title: L10n.screenChangeServerErrorElementProRequiredActionIos) {
                                                     UIApplication.shared.open(self.appSettings.elementProAppStoreURL)
                                                 },
                                                 secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
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
    
    /// temporary, sample matches for user server input
    private let matches = [
        "matrix.org",
        "foo.bar",
        "elemental.codes"
    ]
    
    /// Given the textfield's complete text from the user's latest keystroke, evaluate if it matches any historical
    /// server prefixes. If there's a match, update the text value with the complete server, highlighting the portion
    /// that was appended.
    private func didUpdateTextFromKeystroke(userProvidedString: String) {
        let new = userProvidedString
        let lowerNew = new.lowercased()
        
        guard
            lowerNew.isEmpty == false,
            let expectedMatch = matches.first(where: { $0.hasPrefix(lowerNew) }),
            lowerNew != expectedMatch
        else { return }
        
        let appendage = expectedMatch[lowerNew.endIndex..<expectedMatch.endIndex]
        let newInput = "\(new)\(appendage)"
        
        let selectionRange = newInput.index(newInput.startIndex, offsetBy: new.count)..<newInput.endIndex
        
        // debounce a delay to assure that we are not in the same swiftui update cycle
        debouncedKeystrokeTask?.cancel()
        debouncedKeystrokeTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(10))
            guard Task.isCancelled == false else { return }
            context.homeserverAddress = newInput
            context.viewState.textField?.text = newInput
            context.homeserverSelection = TextSelection(range: selectionRange)
        }
    }
}

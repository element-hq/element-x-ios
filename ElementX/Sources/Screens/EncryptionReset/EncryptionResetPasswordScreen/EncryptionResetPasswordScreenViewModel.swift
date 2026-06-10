//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias EncryptionResetPasswordScreenViewModelType = StateStoreViewModelV2<EncryptionResetPasswordScreenViewState, EncryptionResetPasswordScreenViewAction>

class EncryptionResetPasswordScreenViewModel: EncryptionResetPasswordScreenViewModelType, EncryptionResetPasswordScreenViewModelProtocol {
    private let passwordPublisher: PassthroughSubject<String, Never>
    private let clientProxy: ClientProxyProtocol?
    private let identityServiceClient: IdentityServiceClientProtocol?
    
    private var reauthToken: String?
    
    private let actionsSubject: PassthroughSubject<EncryptionResetPasswordScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EncryptionResetPasswordScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(passwordPublisher: PassthroughSubject<String, Never>,
         clientProxy: ClientProxyProtocol? = nil,
         identityServiceClient: IdentityServiceClientProtocol? = nil) {
        self.passwordPublisher = passwordPublisher
        self.clientProxy = clientProxy
        self.identityServiceClient = identityServiceClient
        
        let available = clientProxy != nil && identityServiceClient != nil
        super.init(initialViewState: .init(identityServiceAvailable: available,
                                           bindings: .init(password: "")))
    }
    
    // MARK: - Public
    
    override func process(viewAction: EncryptionResetPasswordScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .submit:
            passwordPublisher.send(state.bindings.password)
            actionsSubject.send(.passwordEntered)
        case .sendReauthCode:
            Task { await sendReauthCode() }
        case .verifyReauthCode:
            Task { await verifyAndForwardPassword() }
        }
    }
    
    // MARK: - Reauth via identity-service (UIA m.login.password proxied by /account/reset-identity-credentials)
    
    private func sendReauthCode() async {
        guard let identityServiceClient, let clientProxy, let accessToken = clientProxy.accessToken else {
            state.reauthPhase = .error(L10n.errorUnknown)
            return
        }
        state.reauthPhase = .sendingCode
        do {
            try await identityServiceClient.startAccountReauth(accessToken: accessToken,
                                                               language: Locale.current.identifier)
            state.reauthPhase = .awaitingCode
        } catch {
            MXLog.error("Failed to start account reauth: \(error)")
            state.reauthPhase = .error((error as? LocalizedError)?.errorDescription ?? L10n.errorUnknown)
        }
    }
    
    private func verifyAndForwardPassword() async {
        guard let identityServiceClient, let clientProxy, let accessToken = clientProxy.accessToken else {
            state.reauthPhase = .error(L10n.errorUnknown)
            return
        }
        let code = state.bindings.otpCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        state.reauthPhase = .verifyingCode
        do {
            let token = try await identityServiceClient.verifyAccountReauth(accessToken: accessToken, code: code)
            reauthToken = token
            state.reauthPhase = .resolving
            let credentials = try await identityServiceClient.resetIdentityCredentials(accessToken: accessToken,
                                                                                       reauthToken: token)
            // Forward the ephemeral password back to the EncryptionResetScreen view model, which
            // feeds it into `identityResetHandle.reset(auth: .password(...))`.
            passwordPublisher.send(credentials.password)
            actionsSubject.send(.passwordEntered)
        } catch IdentityServiceError.invalidOTP {
            state.reauthPhase = .error(L10n.screenOtpInvalidCode)
        } catch {
            MXLog.error("Failed reauth flow: \(error)")
            state.reauthPhase = .error((error as? LocalizedError)?.errorDescription ?? L10n.errorUnknown)
        }
    }
}

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias DeactivateAccountScreenViewModelType = StateStoreViewModelV2<DeactivateAccountScreenViewState, DeactivateAccountScreenViewAction>

class DeactivateAccountScreenViewModel: DeactivateAccountScreenViewModelType, DeactivateAccountScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let identityServiceClient: IdentityServiceClientProtocol?
    
    private var reauthToken: String?
    
    private let actionsSubject: PassthroughSubject<DeactivateAccountScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<DeactivateAccountScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(clientProxy: ClientProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         identityServiceClient: IdentityServiceClientProtocol? = nil) {
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        self.identityServiceClient = identityServiceClient
        
        super.init(initialViewState: DeactivateAccountScreenViewState(identityServiceAvailable: identityServiceClient != nil))
    }
    
    override func process(viewAction: DeactivateAccountScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .deactivate:
            showDeactivationConfirmation()
        case .sendReauthCode:
            Task { await sendReauthCode() }
        case .verifyReauthCode:
            Task { await verifyReauthCode() }
        }
    }
    
    // MARK: - Reauthentication
    
    private func sendReauthCode() async {
        guard let identityServiceClient, let accessToken = clientProxy.accessToken else {
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
    
    private func verifyReauthCode() async {
        guard let identityServiceClient, let accessToken = clientProxy.accessToken else {
            state.reauthPhase = .error(L10n.errorUnknown)
            return
        }
        let code = state.bindings.otpCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        state.reauthPhase = .verifyingCode
        do {
            reauthToken = try await identityServiceClient.verifyAccountReauth(accessToken: accessToken, code: code)
            state.reauthPhase = .verified
        } catch IdentityServiceError.invalidOTP {
            state.reauthPhase = .error(L10n.screenOtpInvalidCode)
        } catch {
            MXLog.error("Failed to verify reauth code: \(error)")
            state.reauthPhase = .error((error as? LocalizedError)?.errorDescription ?? L10n.errorUnknown)
        }
    }
    
    // MARK: - Deactivation
    
    private let deactivatingIndicatorID = "\(DeactivateAccountScreenViewModel.self)-Deactivating"
    
    func showDeactivationConfirmation() {
        state.bindings.alertInfo = .init(id: .confirmation,
                                         title: L10n.screenDeactivateAccountTitle,
                                         message: L10n.screenDeactivateAccountConfirmationDialogContent,
                                         primaryButton: .init(title: L10n.actionDeactivate) {
                                             Task { await self.deactivateAccount() }
                                         },
                                         secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
    }

    func deactivateAccount() async {
        userIndicatorController.submitIndicator(UserIndicator(id: deactivatingIndicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonPleaseWait,
                                                              persistent: true))
        defer { userIndicatorController.retractIndicatorWithId(deactivatingIndicatorID) }
        
        MXLog.warning("Deactivating account.")
        
        // Preferred path: identity-service OTP-reauth flow (the Gua app does not store user
        // passwords because sign-in is phone-OTP only). Falls back to the legacy SDK password
        // flow only when the identity-service client is unavailable.
        if let identityServiceClient,
           let reauthToken,
           let accessToken = clientProxy.accessToken {
            do {
                try await identityServiceClient.deactivateAccount(accessToken: accessToken,
                                                                  reauthToken: reauthToken,
                                                                  eraseData: state.bindings.eraseData)
                MXLog.info("Account deactivated via identity-service.")
                actionsSubject.send(.accountDeactivated)
                return
            } catch {
                MXLog.error("identity-service deactivate failed: \(error)")
                self.reauthToken = nil
                state.reauthPhase = .error((error as? LocalizedError)?.errorDescription ?? L10n.errorUnknown)
                state.bindings.alertInfo = .init(id: .deactivationFailed,
                                                 title: L10n.errorUnknown,
                                                 message: (error as? LocalizedError)?.errorDescription ?? String(describing: error))
                return
            }
        }
        
        // Legacy / dev fallback: attempt with no auth first, then with provided password.
        switch await clientProxy.deactivateAccount(password: nil, eraseData: state.bindings.eraseData) {
        case .success:
            MXLog.info("Account deactivated (no password needed).")
            actionsSubject.send(.accountDeactivated)
            return
        case .failure:
            MXLog.info("Request failed, including password.")
        }
        
        switch await clientProxy.deactivateAccount(password: state.bindings.password, eraseData: state.bindings.eraseData) {
        case .success:
            MXLog.info("Account deactivated.")
            actionsSubject.send(.accountDeactivated)
        case .failure(let failure):
            MXLog.info("Deactivation failed \(failure).")
            state.bindings.alertInfo = .init(id: .deactivationFailed,
                                             title: L10n.errorUnknown,
                                             message: String(describing: failure))
        }
    }
}

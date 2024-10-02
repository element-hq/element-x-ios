//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias EncryptionResetScreenViewModelType = StateStoreViewModel<EncryptionResetScreenViewState, EncryptionResetScreenViewAction>

class EncryptionResetScreenViewModel: EncryptionResetScreenViewModelType, EncryptionResetScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<EncryptionResetScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EncryptionResetScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var identityResetHandle: IdentityResetHandle?

    init(clientProxy: ClientProxyProtocol, userIndicatorController: UserIndicatorControllerProtocol) {
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: EncryptionResetScreenViewState(bindings: .init()))
    }
    
    // MARK: - Public
    
    override func process(viewAction: EncryptionResetScreenViewAction) {
        switch viewAction {
        case .reset:
            state.bindings.alertInfo = .init(id: UUID(),
                                             title: L10n.screenResetEncryptionConfirmationAlertTitle,
                                             message: L10n.screenResetEncryptionConfirmationAlertSubtitle,
                                             primaryButton: .init(title: L10n.screenResetEncryptionConfirmationAlertAction, role: .destructive, action: { [weak self] in
                                                 guard let self else { return }
                                                 Task { await self.startResetFlow() }
                                             }))
        case .cancel:
            actionsSubject.send(.cancel)
        }
    }
    
    func continueResetFlowWith(password: String) {
        Task {
            await resetWith(password: password)
        }
    }
    
    func stop() {
        Task {
            await identityResetHandle?.cancel()
        }
    }
    
    // MARK: - Private
    
    private func startResetFlow() async {
        showLoadingIndicator()
        
        defer {
            hideLoadingIndicator()
        }
        
        switch await clientProxy.resetIdentity() {
        case .success(let handle):
            // If the handle is missing then interactive authentication wasn't
            // necessary and the reset proceeded as normal
            guard let handle else {
                actionsSubject.send(.resetFinished)
                return
            }
            
            identityResetHandle = handle
            
            switch handle.authType() {
            case .uiaa:
                actionsSubject.send(.requestPassword)
            case .oidc(let oidcInfo):
                guard let url = URL(string: oidcInfo.approvalUrl) else {
                    fatalError("Invalid URL received through identity reset handle: \(oidcInfo.approvalUrl)")
                }
                
                hideLoadingIndicator()
                
                actionsSubject.send(.requestOIDCAuthorisation(url: url))
                
                await resetWithOIDCAuthorisation()
            }
        case .failure(let error):
            MXLog.error("Failed resetting encryption with error \(error)")
            showErrorToast()
        }
    }
    
    func resetWith(password: String) async {
        guard let identityResetHandle else {
            fatalError("Requested reset flow continuation without a stored handle")
        }
        
        showLoadingIndicator()
        
        defer {
            hideLoadingIndicator()
        }
        
        do {
            try await identityResetHandle.reset(auth: .password(passwordDetails: .init(identifier: clientProxy.userID, password: password)))
            actionsSubject.send(.resetFinished)
        } catch {
            MXLog.error("Failed resetting encryption with error \(error)")
            showErrorToast()
        }
    }
    
    private func resetWithOIDCAuthorisation() async {
        guard let identityResetHandle else {
            fatalError("Requested reset flow continuation without a stored handle")
        }
        
        do {
            try await identityResetHandle.reset(auth: nil)
            actionsSubject.send(.resetFinished)
        } catch {
            MXLog.error("Failed resetting encryption with error \(error)")
            showErrorToast()
        }
    }
    
    // MARK: Toasts and loading indicators
    
    private static let loadingIndicatorIdentifier = "\(EncryptionResetScreenViewModel.self)-Loading"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    private func showErrorToast() {
        userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
    }
}

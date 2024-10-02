//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias DeactivateAccountScreenViewModelType = StateStoreViewModel<DeactivateAccountScreenViewState, DeactivateAccountScreenViewAction>

class DeactivateAccountScreenViewModel: DeactivateAccountScreenViewModelType, DeactivateAccountScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<DeactivateAccountScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<DeactivateAccountScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(clientProxy: ClientProxyProtocol, userIndicatorController: UserIndicatorControllerProtocol) {
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: DeactivateAccountScreenViewState())
    }
    
    override func process(viewAction: DeactivateAccountScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .deactivate:
            showDeactivationConfirmation()
        }
    }
    
    // MARK: - Private
    
    private let deactivatingIndicatorID = "\(DeactivateAccountScreenViewModel.self)-Deactivating"
    
    func showDeactivationConfirmation() {
        state.bindings.alertInfo = .init(id: .confirmation,
                                         title: L10n.screenDeactivateAccountTitle,
                                         message: L10n.screenDeactivateAccountConfirmationDialogContent,
                                         primaryButton: .init(title: L10n.actionDeactivate, action: {
                                             Task { await self.deactivateAccount() }
                                         }),
                                         secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
    }

    func deactivateAccount() async {
        userIndicatorController.submitIndicator(UserIndicator(id: deactivatingIndicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonPleaseWait,
                                                              persistent: true))
        
        MXLog.warning("Deactivating account.")
        
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
            return
        case .failure(let failure):
            MXLog.info("Deactivation failed \(failure).")
            state.bindings.alertInfo = .init(id: .deactivationFailed,
                                             title: L10n.errorUnknown,
                                             message: String(describing: failure))
            userIndicatorController.retractIndicatorWithId(deactivatingIndicatorID)
        }
    }
}

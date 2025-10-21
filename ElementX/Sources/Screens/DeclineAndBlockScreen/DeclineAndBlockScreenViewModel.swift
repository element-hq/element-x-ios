//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias DeclineAndBlockScreenViewModelType = StateStoreViewModelV2<DeclineAndBlockScreenViewState, DeclineAndBlockScreenViewAction>

class DeclineAndBlockScreenViewModel: DeclineAndBlockScreenViewModelType, DeclineAndBlockScreenViewModelProtocol {
    let userID: String
    let roomID: String
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<DeclineAndBlockScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<DeclineAndBlockScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(userID: String,
         roomID: String,
         clientProxy: ClientProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.userID = userID
        self.roomID = roomID
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        super.init(initialViewState: DeclineAndBlockScreenViewState())
    }
    
    // MARK: - Public
    
    override func process(viewAction: DeclineAndBlockScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .dismiss:
            actionsSubject.send(.dismiss(hasDeclined: false))
        case .decline:
            Task { await decline() }
        }
    }
    
    private func decline() async {
        showLoadingIndicator()
        guard case let .invited(roomProxy) = await clientProxy.roomForIdentifier(roomID) else {
            MXLog.error("DeclineAndBlockScreenViewModel: Unable to find an invited room for identifier \(roomID)")
            hideLoadingIndicator()
            showTryAgainAlert { [weak self] in Task { await self?.decline() } }
            return
        }
        
        switch await roomProxy.rejectInvitation() {
        case .success:
            var shouldShowFailure = false
            if state.bindings.shouldReport {
                shouldShowFailure = await clientProxy.reportRoomForIdentifier(roomID, reason: state.bindings.reportReason).isFailure
            }
            
            if state.bindings.shouldBlockUser {
                shouldShowFailure = await clientProxy.ignoreUser(userID).isFailure
            }
            
            hideLoadingIndicator()
            if shouldShowFailure {
                showError()
            } else {
                showSuccess()
            }
            actionsSubject.send(.dismiss(hasDeclined: true))
        case .failure:
            hideLoadingIndicator()
            showTryAgainAlert { [weak self] in Task { await self?.decline() } }
        }
    }
    
    private static let loadingIndicator = "\(DeclineAndBlockScreenViewModel.self).loadingIndicator"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(.init(id: Self.loadingIndicator,
                                                      type: .modal(progress: .indeterminate,
                                                                   interactiveDismissDisabled: true,
                                                                   allowsInteraction: false),
                                                      title: L10n.commonLoading,
                                                      persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicator)
    }
    
    private func showError() {
        userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
    }
    
    private func showTryAgainAlert(retryAction: @escaping () -> Void) {
        state.bindings.alert = .init(id: .declineFailed,
                                     title: L10n.commonSomethingWentWrong,
                                     message: L10n.commonSomethingWentWrongMessage,
                                     primaryButton: .init(title: L10n.actionDismiss, role: .cancel, action: nil),
                                     secondaryButton: .init(title: L10n.actionTryAgain, action: retryAction))
    }
    
    private func showSuccess() {
        userIndicatorController.submitIndicator(.init(title: L10n.commonSuccess, iconName: "checkmark"))
    }
}

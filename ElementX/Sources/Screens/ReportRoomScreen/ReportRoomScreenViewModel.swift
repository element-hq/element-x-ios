//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ReportRoomScreenViewModelType = StateStoreViewModelV2<ReportRoomScreenViewState, ReportRoomScreenViewAction>

class ReportRoomScreenViewModel: ReportRoomScreenViewModelType, ReportRoomScreenViewModelProtocol {
    let roomProxy: JoinedRoomProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<ReportRoomScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ReportRoomScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomProxy: JoinedRoomProxyProtocol, userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        super.init(initialViewState: ReportRoomScreenViewState())
    }
    
    // MARK: - Public
    
    override func process(viewAction: ReportRoomScreenViewAction) {
        switch viewAction {
        case .report:
            Task { await report() }
        case .dismiss:
            actionsSubject.send(.dismiss(shouldLeaveRoom: false))
        }
    }
        
    private func report() async {
        showLoadingIndicator()
        let result = await roomProxy.reportRoom(reason: state.bindings.reason)
        
        switch result {
        case .success:
            if state.bindings.shouldLeaveRoom {
                await leaveRoom(showLoading: false)
            } else {
                hideLoadingIndicator()
                userIndicatorController.submitIndicator(.init(title: L10n.dialogRoomReported, iconName: "checkmark"))
                actionsSubject.send(.dismiss(shouldLeaveRoom: false))
            }
        case .failure:
            hideLoadingIndicator()
            state.bindings.alert = .init(id: .reportRoomFailed,
                                         title: L10n.commonSomethingWentWrong,
                                         message: L10n.commonSomethingWentWrongMessage,
                                         primaryButton: .init(title: L10n.actionDismiss, role: .cancel, action: nil),
                                         secondaryButton: .init(title: L10n.actionTryAgain) { [weak self] in Task { await self?.report() } })
        }
    }
    
    private func leaveRoom(showLoading: Bool) async {
        if showLoading {
            showLoadingIndicator()
        }
        
        let result = await roomProxy.leaveRoom()
        hideLoadingIndicator()
        
        switch result {
        case .success:
            userIndicatorController.submitIndicator(.init(title: L10n.dialogRoomReportedAndLeft, iconName: "checkmark"))
            actionsSubject.send(.dismiss(shouldLeaveRoom: true))
        case .failure:
            state.bindings.alert = .init(id: .leaveRoomFailed,
                                         title: L10n.screenReportRoomLeaveFailedAlertTitle,
                                         message: L10n.screenReportRoomLeaveFailedAlertMessage,
                                         primaryButton: .init(title: L10n.actionDismiss, role: .cancel) { [weak self] in self?.actionsSubject.send(.dismiss(shouldLeaveRoom: false)) },
                                         secondaryButton: .init(title: L10n.actionTryAgain) { [weak self] in Task { await self?.leaveRoom(showLoading: true) } })
        }
    }
    
    private static let loadingIndicatorIdentifier = "\(BugReportScreenCoordinator.self)-Loading"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}

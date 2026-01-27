//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias LeaveSpaceViewModelType = StateStoreViewModelV2<LeaveSpaceViewState, LeaveSpaceViewAction>

class LeaveSpaceViewModel: LeaveSpaceViewModelType {
    let actionsSubject = PassthroughSubject<LeaveSpaceViewModelAction, Never>()
    var actions: AnyPublisher<LeaveSpaceViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    private let userIndicatorController: UserIndicatorControllerProtocol
    private let mediaProvider: MediaProviderProtocol

    init(spaceName: String, canEditRolesAndPermissions: Bool, leaveHandle: LeaveSpaceHandleProxy, userIndicatorController: UserIndicatorControllerProtocol, mediaProvider: MediaProviderProtocol) {
        self.userIndicatorController = userIndicatorController
        self.mediaProvider = mediaProvider
        super.init(initialViewState: LeaveSpaceViewState(spaceName: spaceName, canEditRolesAndPermissions: canEditRolesAndPermissions, leaveHandle: leaveHandle), mediaProvider: mediaProvider)
    }
    
    override func process(viewAction: LeaveSpaceViewAction) {
        switch viewAction {
        case .confirmLeaveSpace:
            Task { await confirmLeaveSpace() }
        case .rolesAndPermissions:
            actionsSubject.send(.presentRolesAndPermissions)
        case .cancel:
            actionsSubject.send(.didCancel)
        case .deselectAll:
            state.leaveHandle.deselectAll()
        case .selectAll:
            state.leaveHandle.selectAll()
        case .toggleRoom(let roomID):
            withTransaction(\.disablesAnimations, true) { // The button is adding an unwanted animation.
                state.leaveHandle.toggleRoom(roomID: roomID)
            }
        case .transferOwnership:
            actionsSubject.send(.presentTransferOwnership)
        }
    }
    
    private func confirmLeaveSpace() async {
        showLeavingIndicator()
        defer { hideLeavingIndicator() }
        
        switch await state.leaveHandle.leave() {
        case .success:
            actionsSubject.send(.didLeaveSpace)
        case .failure:
            showFailureIndicator()
        }
    }
    
    private static var leavingIndicatorID: String {
        "\(Self.self)-Leaving"
    }

    private static var failureIndicatorID: String {
        "\(Self.self)-Failure"
    }
    
    private func showLeavingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.leavingIndicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonLeavingSpace))
    }
    
    private func hideLeavingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.leavingIndicatorID)
    }
    
    private func showFailureIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.failureIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
}

extension LeaveSpaceViewModel: Identifiable {
    var id: String {
        state.leaveHandle.id
    }
}

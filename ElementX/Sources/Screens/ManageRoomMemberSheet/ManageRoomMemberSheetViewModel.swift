//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftUI

typealias ManageRoomMemberSheetViewModelType = StateStoreViewModel<ManageRoomMemberSheetViewState, ManageRoomMemberSheetViewAction>

class ManageRoomMemberSheetViewModel: ManageRoomMemberSheetViewModelType, ManageRoomMemberSheetViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let analyticsService: AnalyticsService
    
    private var actionsSubject: PassthroughSubject<ManageRoomMemberSheetViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<ManageRoomMemberSheetViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(member: RoomMemberDetails,
         canKick: Bool,
         canBan: Bool,
         roomProxy: JoinedRoomProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         analyticsService: AnalyticsService,
         mediaProvider: MediaProviderProtocol) {
        self.userIndicatorController = userIndicatorController
        self.roomProxy = roomProxy
        self.analyticsService = analyticsService
        super.init(initialViewState: .init(member: member, canKick: canKick, canBan: canBan), mediaProvider: mediaProvider)
    }
    
    override func process(viewAction: ManageRoomMemberSheetViewAction) {
        switch viewAction {
        case .kick:
            displayAlert(.kick)
        case .ban:
            displayAlert(.ban)
        case .displayDetails:
            actionsSubject.send(.dismiss(shouldShowDetails: true))
        }
    }
    
    private func displayAlert(_ alertType: ManageRoomMemberSheetViewAlertType) {
        let member = state.member
        var reason: String?
        let binding: Binding<String> = .init(get: { reason ?? "" },
                                             set: { reason = $0.isBlank ? nil : $0 })
        switch alertType {
        case .kick:
            state.bindings.alertInfo = .init(id: alertType,
                                             title: L10n.screenBottomSheetManageRoomMemberKickMemberConfirmationTitle,
                                             message: L10n.screenBottomSheetManageRoomMemberKickMemberConfirmationDescription,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel) { },
                                             secondaryButton: .init(title: L10n.screenBottomSheetManageRoomMemberKickMemberConfirmationAction) { [weak self] in Task { await self?.kickMember(member, reason: reason) } },
                                             textFields: [.init(placeholder: L10n.commonReason,
                                                                text: binding,
                                                                autoCapitalization: .sentences,
                                                                autoCorrectionDisabled: false)])
        case .ban:
            state.bindings.alertInfo = .init(id: alertType,
                                             title: L10n.screenBottomSheetManageRoomMemberBanMemberConfirmationTitle,
                                             message: L10n.screenBottomSheetManageRoomMemberBanMemberConfirmationDescription,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel) { },
                                             secondaryButton: .init(title: L10n.screenBottomSheetManageRoomMemberBanMemberConfirmationAction) { [weak self] in Task { await self?.banMember(member, reason: reason) } },
                                             textFields: [.init(placeholder: L10n.commonReason,
                                                                text: binding,
                                                                autoCapitalization: .sentences,
                                                                autoCorrectionDisabled: false)])
        }
    }
    
    private func kickMember(_ member: RoomMemberDetails, reason: String?) async {
        let indicatorTitle = L10n.screenBottomSheetManageRoomMemberRemovingUser(member.name ?? member.id)
        showManageMemberIndicator(title: indicatorTitle)
        
        switch await roomProxy.kickUser(member.id, reason: reason) {
        case .success:
            hideManageMemberIndicator(title: indicatorTitle)
            analyticsService.trackRoomModeration(action: .KickMember, role: nil)
            actionsSubject.send(.dismiss(shouldShowDetails: false))
        case .failure:
            showManageMemberFailure(title: indicatorTitle)
        }
    }
    
    private func banMember(_ member: RoomMemberDetails, reason: String?) async {
        let indicatorTitle = L10n.screenBottomSheetManageRoomMemberBanningUser(member.name ?? member.id)
        showManageMemberIndicator(title: indicatorTitle)
        
        switch await roomProxy.banUser(member.id, reason: reason) {
        case .success:
            hideManageMemberIndicator(title: indicatorTitle)
            analyticsService.trackRoomModeration(action: .BanMember, role: nil)
            actionsSubject.send(.dismiss(shouldShowDetails: false))
        case .failure:
            showManageMemberFailure(title: indicatorTitle)
        }
    }
    
    private func showManageMemberIndicator(title: String) {
        userIndicatorController.submitIndicator(UserIndicator(id: title,
                                                              type: .toast(progress: .indeterminate),
                                                              title: title,
                                                              persistent: true))
    }
    
    private func hideManageMemberIndicator(title: String) {
        userIndicatorController.retractIndicatorWithId(title)
    }
    
    private func showManageMemberFailure(title: String) {
        userIndicatorController.retractIndicatorWithId(title)
        userIndicatorController.submitIndicator(UserIndicator(title: L10n.commonFailed, iconName: "xmark"))
    }
}

extension ManageRoomMemberSheetViewModel: Identifiable {
    var id: String { state.member.id }
}

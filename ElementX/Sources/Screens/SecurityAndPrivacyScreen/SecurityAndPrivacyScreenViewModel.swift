//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias SecurityAndPrivacyScreenViewModelType = StateStoreViewModel<SecurityAndPrivacyScreenViewState, SecurityAndPrivacyScreenViewAction>

class SecurityAndPrivacyScreenViewModel: SecurityAndPrivacyScreenViewModelType, SecurityAndPrivacyScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    
    private let actionsSubject: PassthroughSubject<SecurityAndPrivacyScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SecurityAndPrivacyScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomProxy: JoinedRoomProxyProtocol) {
        self.roomProxy = roomProxy
        super.init(initialViewState: SecurityAndPrivacyScreenViewState(accessType: roomProxy.infoPublisher.value.roomAccessType,
                                                                       isEncryptionEnabled: roomProxy.isEncrypted))
    }
    
    // MARK: - Public
    
    override func process(viewAction: SecurityAndPrivacyScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .save:
            actionsSubject.send(.done)
        case .tryUpdatingEncryption(let updatedValue):
            if updatedValue {
                state.bindings.alertInfo = .init(id: .enableEncryption,
                                                 title: L10n.screenSecurityAndPrivacyEnableEncryptionAlertTitle,
                                                 message: L10n.screenSecurityAndPrivacyEnableEncryptionAlertDescription,
                                                 primaryButton: .init(title: L10n.screenSecurityAndPrivacyEnableEncryptionAlertConfirmButtonTitle) { [weak self] in
                                                     self?.state.bindings.desiredSettings.isEncryptionEnabled = true
                                                 },
                                                 secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
            } else {
                state.bindings.desiredSettings.isEncryptionEnabled = false
            }
        }
    }
}

private extension RoomInfoProxy {
    var roomAccessType: SecurityAndPrivacyRoomAccessType {
        switch joinRule {
        case .invite, .restricted:
            return .inviteOnly
        case .knock, .knockRestricted:
            return .askToJoin
        default:
            return .anyone
        }
    }
}

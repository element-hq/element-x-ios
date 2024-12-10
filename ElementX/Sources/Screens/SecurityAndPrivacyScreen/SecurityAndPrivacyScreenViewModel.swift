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
        super.init(initialViewState: SecurityAndPrivacyScreenViewState(accessType: roomProxy.infoPublisher.value.roomAcessType,
                                                                       isEncryptionEnabled: roomProxy.isEncrypted))
    }
    
    // MARK: - Public
    
    override func process(viewAction: SecurityAndPrivacyScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .save:
            actionsSubject.send(.done)
        case .tryUpdatingEncryption(let updatedValue):
            // Once the room is encrypted it can never be turned off
            guard !roomProxy.isEncrypted else {
                return
            }
            // TODO: We probably want to display an alert in some cases?
        }
    }
}

private extension RoomInfoProxy {
    var roomAcessType: SecurityAndPrivacyRoomAccessType {
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

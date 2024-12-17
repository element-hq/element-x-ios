//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
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
                                                                       isEncryptionEnabled: roomProxy.isEncrypted,
                                                                       historyVisibility: roomProxy.infoPublisher.value.historyVisibility.toSecurityAndPrivacyHistoryVisibility))
        
        setupSubscriptions()
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
                                                 primaryButton: .init(title: L10n.screenSecurityAndPrivacyEnableEncryptionAlertConfirmButtonTitle) { [weak self] in self?.state.bindings.desiredSettings.isEncryptionEnabled = true },
                                                 secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
            } else {
                state.bindings.desiredSettings.isEncryptionEnabled = false
            }
        }
    }
    
    // MARK: - Private
    
    private func setupSubscriptions() {
        context.$viewState
            .map(\.bindings.desiredSettings.accessType)
            .removeDuplicates()
            // Use this otherwise the value won't update properly in the view
            .receive(on: DispatchQueue.main)
            .sink { [weak self] desiredAcessType in
                guard let self else { return }
                if (desiredAcessType == .anyone && !state.bindings.desiredSettings.historyVisibility.isAllowedInPublicRoom) ||
                    (desiredAcessType != .anyone && state.bindings.desiredSettings.historyVisibility == .anyone) {
                    self.state.bindings.desiredSettings.historyVisibility = .sinceSelection
                }
            }
            .store(in: &cancellables)
        
        context.$viewState
            .map(\.bindings.desiredSettings.isEncryptionEnabled)
            .removeDuplicates()
            // Use this otherwise the value won't update properly in the view
            .receive(on: DispatchQueue.main)
            .sink { [weak self] desiredIsEncryptionEnabled in
                guard let self else { return }
                if desiredIsEncryptionEnabled, state.bindings.desiredSettings.historyVisibility == .anyone {
                    self.state.bindings.desiredSettings.historyVisibility = .sinceSelection
                }
            }
            .store(in: &cancellables)
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

private extension RoomHistoryVisibility? {
    var toSecurityAndPrivacyHistoryVisibility: SecurityAndPrivacyHistoryVisibility {
        switch self {
        case .joined, .invited:
            return .sinceInvite
        case .shared, .custom, .none:
            return .sinceSelection
        case .worldReadable:
            return .anyone
        }
    }
}

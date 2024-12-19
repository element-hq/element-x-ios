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
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<SecurityAndPrivacyScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SecurityAndPrivacyScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomProxy: JoinedRoomProxyProtocol,
         clientProxy: ClientProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        let canonicalAlias = roomProxy.infoPublisher.value.canonicalAlias
        super.init(initialViewState: SecurityAndPrivacyScreenViewState(serverName: clientProxy.userIDServerName ?? "",
                                                                       accessType: roomProxy.infoPublisher.value.roomAccessType,
                                                                       isEncryptionEnabled: roomProxy.isEncrypted,
                                                                       historyVisibility: roomProxy.infoPublisher.value.historyVisibility.toSecurityAndPrivacyHistoryVisibility,
                                                                       canonicalAlias: canonicalAlias))
        
        setupRoomDirectoryVisibility()
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
        case .editAddress:
            // TODO: Implement navigation to a view that allows editing or adding an address
            break
        }
    }
    
    // MARK: - Private
    
    private func setupSubscriptions() {
        context.$viewState
            .map(\.availableVisibilityOptions)
            .removeDuplicates()
            // To allow the view to update properly
            .receive(on: DispatchQueue.main)
            // When the available options changes always default to `sinceSelection` if the currently selected option is not available
            .sink { [weak self] availableVisibilityOptions in
                guard let self else { return }
                let desiredHistoryVisbility = state.bindings.desiredSettings.historyVisibility
                if !availableVisibilityOptions.contains(desiredHistoryVisbility) {
                    state.bindings.desiredSettings.historyVisibility = desiredHistoryVisbility.fallbackOption
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupRoomDirectoryVisibility() {
        Task {
            switch await roomProxy.isVisibleInRoomDirectory() {
            case .success(let value):
                state.bindings.desiredSettings.isVisibileInRoomDirectory = value
                state.currentSettings.isVisibileInRoomDirectory = value
            case .failure:
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
                state.bindings.desiredSettings.isVisibileInRoomDirectory = false
                state.bindings.desiredSettings.isVisibileInRoomDirectory = false
            }
        }
    }
}

private extension RoomInfoProxy {
    var roomAccessType: SecurityAndPrivacyRoomAccessType {
        switch joinRule {
        case .invite:
            return .inviteOnly
        case .knock, .knockRestricted:
            return .askToJoin
        case .restricted:
            return .spaceUsers
        default:
            return .anyone
        }
    }
}

private extension RoomHistoryVisibility {
    var toSecurityAndPrivacyHistoryVisibility: SecurityAndPrivacyHistoryVisibility {
        switch self {
        case .joined, .invited:
            return .sinceInvite
        case .shared, .custom:
            return .sinceSelection
        case .worldReadable:
            return .anyone
        }
    }
}

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
        super.init(initialViewState: SecurityAndPrivacyScreenViewState(serverName: clientProxy.userIDServerName ?? "",
                                                                       accessType: roomProxy.infoPublisher.value.joinRule.toSecurityAndPrivacyRoomAccessType,
                                                                       isEncryptionEnabled: roomProxy.isEncrypted,
                                                                       historyVisibility: roomProxy.infoPublisher.value.historyVisibility.toSecurityAndPrivacyHistoryVisibility))
        
        setupRoomDirectoryVisibility()
        setupSubscriptions()
    }
    
    // MARK: - Public
    
    override func process(viewAction: SecurityAndPrivacyScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .save:
            Task {
                await saveDesiredSettings()
            }
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
            actionsSubject.send(.displayEditAddressScreen)
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
                let desiredHistoryVisibility = state.bindings.desiredSettings.historyVisibility
                if !availableVisibilityOptions.contains(desiredHistoryVisibility) {
                    state.bindings.desiredSettings.historyVisibility = desiredHistoryVisibility.fallbackOption
                }
            }
            .store(in: &cancellables)
        
        let userIDServerName = clientProxy.userIDServerName
        
        roomProxy.infoPublisher
            .compactMap { roomInfo in
                guard let userIDServerName else {
                    return nil
                }
                
                // Give priority to aliases from the current user's homeserver as remote ones
                // cannot be edited.
                return roomInfo.firstAliasMatching(serverName: userIDServerName, useFallback: true)
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.canonicalAlias, on: self)
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
                state.currentSettings.isVisibileInRoomDirectory = false
            }
        }
    }
    
    private func saveDesiredSettings() async {
        showLoadingIndicator()
        
        defer {
            hideLoadingIndicator()
        }
        
        if state.currentSettings.isEncryptionEnabled != state.bindings.desiredSettings.isEncryptionEnabled {
            switch await roomProxy.enableEncryption() {
            case .success:
                state.currentSettings.isEncryptionEnabled = state.bindings.desiredSettings.isEncryptionEnabled
            case .failure:
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            }
        }
        
        if state.currentSettings.historyVisibility != state.bindings.desiredSettings.historyVisibility {
            switch await roomProxy.updateHistoryVisibility(state.bindings.desiredSettings.historyVisibility.toRoomHistoryVisibility) {
            case .success:
                state.currentSettings.historyVisibility = state.bindings.desiredSettings.historyVisibility
            case .failure:
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            }
        }
        
        if state.currentSettings.accessType != state.bindings.desiredSettings.accessType {
            // When a user changes join rules to something other than knock or public,
            // the room should be automatically made invisible (private) in the room directory.
            if state.currentSettings.accessType != .askToJoin, state.currentSettings.accessType != .anyone {
                state.bindings.desiredSettings.isVisibileInRoomDirectory = false
            }
            
            switch await roomProxy.updateJoinRule(state.bindings.desiredSettings.accessType.toJoinRule) {
            case .success:
                state.currentSettings.accessType = state.bindings.desiredSettings.accessType
            case .failure:
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            }
        }
        
        if state.currentSettings.isVisibileInRoomDirectory != state.bindings.desiredSettings.isVisibileInRoomDirectory {
            let visibility: RoomVisibility = state.bindings.desiredSettings.isVisibileInRoomDirectory == true ? .public : .private
            
            switch await roomProxy.updateRoomDirectoryVisibility(visibility) {
            case .success:
                state.currentSettings.isVisibileInRoomDirectory = state.bindings.desiredSettings.isVisibileInRoomDirectory
            case .failure:
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            }
        }
    }
    
    private static let loadingIndicatorIdentifier = "\(EditRoomAddressScreenViewModel.self)-Loading"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}

private extension SecurityAndPrivacyRoomAccessType {
    var toJoinRule: JoinRule {
        switch self {
        case .inviteOnly:
            .invite
        case .askToJoin:
            .knock
        case .anyone:
            .public
        case .spaceUsers:
            fatalError("The user shouldn't be able to select this rule")
        }
    }
}

private extension Optional where Wrapped == JoinRule {
    var toSecurityAndPrivacyRoomAccessType: SecurityAndPrivacyRoomAccessType {
        switch self {
        case .none, .public:
            return .anyone
        case .invite:
            return .inviteOnly
        case .knock, .knockRestricted:
            return .askToJoin
        case .restricted:
            return .spaceUsers
        default:
            return .inviteOnly
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

private extension SecurityAndPrivacyHistoryVisibility {
    var toRoomHistoryVisibility: RoomHistoryVisibility {
        switch self {
        case .sinceSelection:
            return .shared
        case .sinceInvite:
            return .invited
        case .anyone:
            return .worldReadable
        }
    }
}

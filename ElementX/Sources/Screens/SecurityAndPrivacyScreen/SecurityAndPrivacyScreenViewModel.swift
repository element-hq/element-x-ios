//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
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
    private let appSettings: AppSettings
    
    private let actionsSubject: PassthroughSubject<SecurityAndPrivacyScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SecurityAndPrivacyScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomProxy: JoinedRoomProxyProtocol,
         clientProxy: ClientProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appSettings: AppSettings) {
        self.roomProxy = roomProxy
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        self.appSettings = appSettings
        
        super.init(initialViewState: SecurityAndPrivacyScreenViewState(serverName: clientProxy.userIDServerName ?? "",
                                                                       accessType: roomProxy.infoPublisher.value.joinRule.toSecurityAndPrivacyRoomAccessType,
                                                                       isEncryptionEnabled: roomProxy.infoPublisher.value.isEncrypted,
                                                                       historyVisibility: roomProxy.infoPublisher.value.historyVisibility.toSecurityAndPrivacyHistoryVisibility,
                                                                       isSpace: roomProxy.infoPublisher.value.isSpace,
                                                                       isKnockingEnabled: appSettings.knockingEnabled,
                                                                       isSpaceSettingsEnabled: appSettings.spaceSettingsEnabled))
        
        if let powerLevels = roomProxy.infoPublisher.value.powerLevels {
            setupPermissions(powerLevels: powerLevels)
        }
        
        setupRoomDirectoryVisibility()
        setupSubscriptions()
        Task {
            switch await clientProxy.spaceService.joinedParents(childID: roomProxy.id) {
            case .success(let joinedParentSpaces):
                state.joinedParentSpaces = joinedParentSpaces
            case .failure:
                break
            }
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: SecurityAndPrivacyScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .cancel:
            showUnsavedChangesAlert() // The cancel button is only shown when there are unsaved changes.
        case .save:
            Task { await saveDesiredSettings() }
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
        case .selectedSpaceMembersAccess:
            handleSelectedSpaceMembersAccess()
        case .manageSpaces:
            displayManageAuthorizedSpacesScreen()
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
        
        let infoPublisher = roomProxy.infoPublisher
        infoPublisher
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
        
        infoPublisher
            .compactMap(\.powerLevels)
            .removeDuplicates { $0.userPowerLevels == $1.userPowerLevels && $0.values == $1.values }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] powerLevels in
                self?.setupPermissions(powerLevels: powerLevels)
            }
            .store(in: &cancellables)
        
        infoPublisher
            .map(\.isSpace)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.isSpace, on: self)
            .store(in: &cancellables)
        
        appSettings.$knockingEnabled
            .weakAssign(to: \.state.isKnockingEnabled, on: self)
            .store(in: &cancellables)
        
        appSettings.$spaceSettingsEnabled
            .weakAssign(to: \.state.isSpaceSettingsEnabled, on: self)
            .store(in: &cancellables)
    }
    
    private func setupPermissions(powerLevels: RoomPowerLevelsProxyProtocol) {
        state.canEditAddress = powerLevels.canOwnUser(sendStateEvent: .roomAliases)
        state.canEditJoinRule = powerLevels.canOwnUser(sendStateEvent: .roomJoinRules)
        state.canEditHistoryVisibility = powerLevels.canOwnUser(sendStateEvent: .roomHistoryVisibility)
        state.canEnableEncryption = powerLevels.canOwnUser(sendStateEvent: .roomEncryption)
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
    
    private func showUnsavedChangesAlert() {
        state.bindings.alertInfo = .init(id: .unsavedChanges,
                                         title: L10n.dialogUnsavedChangesTitle,
                                         message: L10n.dialogUnsavedChangesDescription,
                                         primaryButton: .init(title: L10n.actionSave) { Task { await self.saveDesiredSettings(shouldDismiss: true) } },
                                         secondaryButton: .init(title: L10n.actionDiscard, role: .cancel) { self.actionsSubject.send(.dismiss) })
    }
    
    private func saveDesiredSettings(shouldDismiss: Bool = false) async {
        showLoadingIndicator()
        defer { hideLoadingIndicator() }
        
        var hasFailures = false
        
        if state.currentSettings.isEncryptionEnabled != state.bindings.desiredSettings.isEncryptionEnabled {
            switch await roomProxy.enableEncryption() {
            case .success:
                state.currentSettings.isEncryptionEnabled = state.bindings.desiredSettings.isEncryptionEnabled
            case .failure:
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
                hasFailures = true
            }
        }
        
        if state.currentSettings.historyVisibility != state.bindings.desiredSettings.historyVisibility {
            switch await roomProxy.updateHistoryVisibility(state.bindings.desiredSettings.historyVisibility.toRoomHistoryVisibility) {
            case .success:
                state.currentSettings.historyVisibility = state.bindings.desiredSettings.historyVisibility
            case .failure:
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
                hasFailures = true
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
                hasFailures = true
            }
        }
        
        if state.currentSettings.isVisibileInRoomDirectory != state.bindings.desiredSettings.isVisibileInRoomDirectory {
            let visibility: RoomVisibility = state.bindings.desiredSettings.isVisibileInRoomDirectory == true ? .public : .private
            
            switch await roomProxy.updateRoomDirectoryVisibility(visibility) {
            case .success:
                state.currentSettings.isVisibileInRoomDirectory = state.bindings.desiredSettings.isVisibileInRoomDirectory
            case .failure:
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
                hasFailures = true
            }
        }
        
        if shouldDismiss, !hasFailures {
            actionsSubject.send(.dismiss)
        }
    }
    
    private func handleSelectedSpaceMembersAccess() {
        guard !state.bindings.desiredSettings.accessType.isSpaceUsers else {
            // If the user is tapping the space members access again we do nothing
            return
        }
        
        switch state.spaceSelection {
        case .singleJoined(let joinedParent):
            state.bindings.desiredSettings.accessType = .spaceUsers(spaceIDs: [joinedParent.id])
        case .singleUnknown(let id):
            state.bindings.desiredSettings.accessType = .spaceUsers(spaceIDs: [id])
        case .multiple:
            displayManageAuthorizedSpacesScreen()
        }
    }
    
    private func displayManageAuthorizedSpacesScreen() {
        let joinedParentSpaces = state.joinedParentSpaces
        let unknownSpaceIDs = state.currentSettings.accessType.spaceIDs.filter { id in
            !joinedParentSpaces.contains { $0.id == id }
        }
        let selectedIDs = Set(state.bindings.desiredSettings.accessType.spaceIDs)
        let authorizedSpacesSelection = AuthorizedSpacesSelection(joinedParentSpaces: joinedParentSpaces,
                                                                  unknownSpacesIDs: unknownSpaceIDs,
                                                                  initialSelectedIDs: selectedIDs)
        authorizedSpacesSelection.selectedIDs
            .sink { [weak self] desiredSelectedIDs in
                self?.state.bindings.desiredSettings.accessType = .spaceUsers(spaceIDs: desiredSelectedIDs.sorted())
            }
            .store(in: &cancellables)
        
        actionsSubject.send(.displayManageAuthorizedSpacesScreen(authorizedSpacesSelection))
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
        case .spaceUsers(let spaceIDs):
            .restricted(rules: spaceIDs.map { .roomMembership(roomId: $0) })
        case .askToJoinWithSpaceUsers(let spaceIDs):
            .knockRestricted(rules: spaceIDs.map { .roomMembership(roomId: $0) })
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

private extension Optional where Wrapped == JoinRule {
    var toSecurityAndPrivacyRoomAccessType: SecurityAndPrivacyRoomAccessType {
        switch self {
        case .none, .public:
            return .anyone
        case .invite:
            return .inviteOnly
        case .knock, .knockRestricted:
            // TODO: Handle knock restricted with rules
            return .askToJoin
        case .restricted(let rules):
            let spaceIDs = rules.compactMap { rule in
                if case let .roomMembership(id) = rule {
                    id
                } else {
                    nil
                }
            }
            return .spaceUsers(spaceIDs: spaceIDs)
        default:
            return .inviteOnly
        }
    }
}

//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SpaceSettingsScreenViewModelType = StateStoreViewModelV2<SpaceSettingsScreenViewState, SpaceSettingsScreenViewAction>

class SpaceSettingsScreenViewModel: SpaceSettingsScreenViewModelType, SpaceSettingsScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let userSession: UserSessionProtocol
    
    private let actionsSubject: PassthroughSubject<SpaceSettingsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomProxy: JoinedRoomProxyProtocol, userSession: UserSessionProtocol) {
        self.roomProxy = roomProxy
        self.userSession = userSession
        
        super.init(initialViewState: .init(details: roomProxy.details,
                                           joinedMembersCount: roomProxy.infoPublisher.value.joinedMembersCount),
                   mediaProvider: userSession.mediaProvider)
        
        updateRoomInfo(roomProxy.infoPublisher.value)
        setupRoomSubscription()
        Task { await roomProxy.updateMembers() }
    }
    
    // MARK: - Public
    
    override func process(viewAction: SpaceSettingsScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .processTapEdit:
            break
        case .processTapSecurity:
            break
        case .processTapPeople:
            break
        case .processTapRolesAndPermissions:
            break
        case .processTapLeave:
            break
        }
    }
    
    private func updateRoomInfo(_ roomInfo: RoomInfoProxyProtocol) {
        state.joinedMembersCount = roomInfo.joinedMembersCount
        state.details = roomProxy.details
        
        if let powerLevels = roomInfo.powerLevels {
            state.canEditRolesOrPermissions = powerLevels.canOwnUserEditRolesAndPermissions()
            state.canEditBaseInfo = powerLevels.canOwnUserEditBaseInfo()
        }
    }
    
    private func setupRoomSubscription() {
        roomProxy.infoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomInfo in
                self?.updateRoomInfo(roomInfo)
            }
            .store(in: &cancellables)
        
        roomProxy.membersPublisher.combineLatest(roomProxy.identityStatusChangesPublisher)
            .sink { [weak self] _ in
                Task { await self?.updateMemberIdentityVerificationStates() }
            }
            .store(in: &cancellables)
    }
    
    private func updateMemberIdentityVerificationStates() async {
        guard roomProxy.infoPublisher.value.isEncrypted else {
            // We don't care about identity statuses on non-encrypted rooms
            return
        }
        
        for member in roomProxy.membersPublisher.value {
            if case let .success(userIdentity) = await userSession.clientProxy.userIdentity(for: member.userID) {
                if userIdentity?.verificationState == .verificationViolation {
                    state.hasMemberIdentityVerificationStateViolations = true
                    return
                }
            }
        }
        
        state.hasMemberIdentityVerificationStateViolations = false
    }
}

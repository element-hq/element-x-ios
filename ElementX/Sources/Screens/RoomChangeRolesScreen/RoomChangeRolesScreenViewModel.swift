//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import SwiftUI

typealias RoomChangeRolesScreenViewModelType = StateStoreViewModel<RoomChangeRolesScreenViewState, RoomChangeRolesScreenViewAction>

class RoomChangeRolesScreenViewModel: RoomChangeRolesScreenViewModelType, RoomChangeRolesScreenViewModelProtocol {
    private let roomProxy: RoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<RoomChangeRolesScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomChangeRolesScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(mode: RoomMemberDetails.Role, roomProxy: RoomProxyProtocol, userIndicatorController: UserIndicatorControllerProtocol) {
        guard mode != .user else { fatalError("Invalid screen configuration: \(mode)") }
        
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: RoomChangeRolesScreenViewState(mode: mode,
                                                                    members: [],
                                                                    bindings: .init()))
        
        roomProxy.membersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] members in
                self?.updateMembers(members)
            }
            .store(in: &cancellables)
        
        roomProxy.timeline.timelineProvider.membershipChangePublisher.sink { [roomProxy] in
            Task { await roomProxy.updateMembers() }
        }
        .store(in: &cancellables)
        
        updateMembers(roomProxy.membersPublisher.value)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomChangeRolesScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .toggleMember(let member):
            toggleMember(member)
        case .demoteMember(let member):
            demoteMember(member)
        case .save:
            Task { await save() }
        }
    }
    
    // MARK: - Private
    
    private func updateMembers(_ members: [RoomMemberProxyProtocol]) {
        state.members = members.sorted().compactMap { member in
            guard member.membership == .join, member.userID != roomProxy.ownUserID else { return nil }
            return RoomMemberDetails(withProxy: member)
        }
    }
    
    private func toggleMember(_ member: RoomMemberDetails) {
        if state.membersToPromote.contains(member) {
            state.membersToPromote.remove(member)
        } else if state.membersToDemote.contains(member) {
            state.membersToDemote.remove(member)
            state.lastPromotedMember = member
        } else if member.role == state.mode {
            state.membersToDemote.insert(member)
        } else {
            state.membersToPromote.insert(member)
            state.lastPromotedMember = member
        }
    }
    
    private func demoteMember(_ member: RoomMemberDetails) {
        if state.membersToPromote.contains(member) {
            state.membersToPromote.remove(member)
        } else {
            state.membersToDemote.insert(member)
        }
    }
    
    private func save() async {
        showSavingIndicator()
        
        defer {
            hideSavingIndicator()
        }
        
        let promotingUpdates = state.membersToPromote.map { ($0.id, state.mode.rustPowerLevel) }
        let demotingUpdates = state.membersToDemote.map { ($0.id, Int64(0)) }
        switch await roomProxy.updatePowerLevelsForUsers(promotingUpdates + demotingUpdates) {
        case .success:
            MXLog.info("Success")
        case .failure:
            context.alertInfo = AlertInfo(id: .generic)
        }
    }
    
    // MARK: Loading indicator
    
    private static let indicatorID = "SavingRoomRoles"
    
    private func showSavingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.indicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonSaving,
                                                              persistent: true))
    }
    
    private func hideSavingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.indicatorID)
    }
}

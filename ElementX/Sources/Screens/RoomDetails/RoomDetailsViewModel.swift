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

typealias RoomDetailsViewModelType = StateStoreViewModel<RoomDetailsViewState, RoomDetailsViewAction>

class RoomDetailsViewModel: RoomDetailsViewModelType, RoomDetailsViewModelProtocol {
    private let roomProxy: RoomProxyProtocol
    private var members: [RoomMemberProxyProtocol] = [] {
        didSet {
            state.members = members.map { RoomMemberDetails(withProxy: $0) }
        }
    }
    
    var callback: ((RoomDetailsViewModelAction) -> Void)?

    init(roomProxy: RoomProxyProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.roomProxy = roomProxy
        super.init(initialViewState: .init(roomId: roomProxy.id,
                                           canonicalAlias: roomProxy.canonicalAlias,
                                           isEncrypted: roomProxy.isEncrypted,
                                           isDirect: roomProxy.isDirect,
                                           title: roomProxy.displayName ?? roomProxy.name ?? "Unknown Room",
                                           topic: roomProxy.topic,
                                           avatarURL: roomProxy.avatarURL,
                                           permalink: roomProxy.permalink,
                                           bindings: .init()),
                   imageProvider: mediaProvider)

        roomProxy.membersPublisher.sink { [weak self] members in
            self?.members = members
        }
        .store(in: &cancellables)

        Task {
            await roomProxy.populateMembers()
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomDetailsViewAction) async {
        switch viewAction {
        case .processTapPeople:
            callback?(.requestMemberDetailsPresentation(members))
        case .processTapLeave:
            guard members.count > 1 else {
                state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(state: .empty)
                return
            }
            state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(state: roomProxy.isPublic ? .public : .private)
        case .confirmLeave:
            await leaveRoom()
        case .processTapIgnore:
            state.bindings.ignoreUserRoomAlertItem = .init(action: .ignore)
        case .processTapUnignore:
            state.bindings.ignoreUserRoomAlertItem = .init(action: .unignore)
        case .ignoreConfirmed:
            await ignore()
        case .unignoreConfirmed:
            await unignore()
        }
    }
    
    // MARK: - Private

    private static let leaveRoomLoadingID = "LeaveRoomLoading"

    private func leaveRoom() async {
        ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: Self.leaveRoomLoadingID, type: .modal, title: L10n.commonLoading, persistent: true))
        let result = await roomProxy.leaveRoom()
        ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(Self.leaveRoomLoadingID)
        switch result {
        case .failure:
            state.bindings.alertInfo = AlertInfo(id: .unknown)
        case .success:
            callback?(.leftRoom)
        }
    }

    private func ignore() async {
        guard let id = state.dmRecipient?.id,
              let member = members.first(where: { $0.userID == id }) else {
            return
        }
        state.isProcessingIgnoreRequest = true
        let result = await member.ignoreUser()
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            state.dmRecipient?.isIgnored = true
        case .failure:
            state.bindings.alertInfo = .init(id: .unknown)
        }
    }

    private func unignore() async {
        guard let id = state.dmRecipient?.id,
              let member = members.first(where: { $0.userID == id }) else {
            return
        }
        state.isProcessingIgnoreRequest = true
        let result = await member.unignoreUser()
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            state.dmRecipient?.isIgnored = false
        case .failure:
            state.bindings.alertInfo = .init(id: .unknown)
        }
    }
}

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

import SwiftUI

typealias RoomMembersViewModelType = StateStoreViewModel<RoomMembersViewState, RoomMembersViewAction>

class RoomMembersViewModel: RoomMembersViewModelType, RoomMembersViewModelProtocol {
    private let roomProxy: RoomProxyProtocol
    private let mediaProvider: MediaProviderProtocol

    var callback: ((RoomMembersViewModelAction) -> Void)?

    init(roomProxy: RoomProxyProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.roomProxy = roomProxy
        self.mediaProvider = mediaProvider
        super.init(initialViewState: .init(members: [],
                                           bindings: .init()))

        Task {
            switch await roomProxy.members() {
            case .success(let members):
                state.members = members.map { RoomDetailsMember(withProxy: $0) }
            case .failure(let error):
                MXLog.debug("Failed to retrieve room members: \(error)")
                state.bindings.alertInfo = AlertInfo(id: .alert(ElementL10n.unknownError))
            }
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomMembersViewAction) async {
        switch viewAction {
        case .selectMember(let id):
            MXLog.debug("Member selected: \(id)")
        case .loadMemberData(let id):
            await loadAvatar(forMember: id)
        case .cancel:
            callback?(.cancel)
        }
    }

    private func loadAvatar(forMember memberId: String) async {
        guard var member = state.members.first(where: { $0.id == memberId }) else {
            return
        }
        if member.avatar != nil {
            // already loaded
            return
        }
        guard let avatarUrl = member.avatarUrl else {
            // user has no avatar
            return
        }

        switch await mediaProvider.loadImageFromURLString(avatarUrl, avatarSize: .user(on: .roomDetails)) {
        case .success(let image):
            member.avatar = image
        case .failure(let error):
            MXLog.debug("Failed to retrieve room member avatar: \(error)")
        }
    }
}

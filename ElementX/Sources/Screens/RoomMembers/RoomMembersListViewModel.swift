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

typealias RoomMembersListViewModelType = StateStoreViewModel<RoomMembersListViewState, RoomMembersListViewAction>

class RoomMembersListViewModel: RoomMembersListViewModelType, RoomMembersListViewModelProtocol {
    private let mediaProvider: MediaProviderProtocol
    private let members: [RoomMemberProxyProtocol]
    
    var callback: ((RoomMembersListViewModelAction) -> Void)?

    init(mediaProvider: MediaProviderProtocol,
         members: [RoomMemberProxyProtocol]) {
        self.mediaProvider = mediaProvider
        self.members = members
        super.init(initialViewState: .init(members: members.map { RoomMemberDetails(withProxy: $0) },
                                           bindings: .init()),
                   imageProvider: mediaProvider)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomMembersListViewAction) {
        switch viewAction {
        case .selectMember(let id):
            guard let member = members.first(where: { $0.userID == id }) else {
                MXLog.error("Selected member \(id) not found")
                return
            }
            callback?(.selectMember(member))
        }
    }
}

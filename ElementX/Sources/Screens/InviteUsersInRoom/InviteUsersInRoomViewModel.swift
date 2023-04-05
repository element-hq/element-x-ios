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

typealias InviteUsersInRoomViewModelType = StateStoreViewModel<InviteUsersInRoomViewState, InviteUsersInRoomViewAction>

class InviteUsersInRoomViewModel: InviteUsersInRoomViewModelType, InviteUsersInRoomViewModelProtocol {
    var callback: ((InviteUsersInRoomViewModelAction) -> Void)?
    private let userSession: UserSessionProtocol
    
    init(userSession: UserSessionProtocol) {
        self.userSession = userSession
        super.init(initialViewState: InviteUsersInRoomViewState(), imageProvider: userSession.mediaProvider)
        
        fetchSuggestions()
    }
    
    // MARK: - Public
    
    override func process(viewAction: InviteUsersInRoomViewAction) async {
        switch viewAction {
        case .close:
            callback?(.close)
        case .proceed:
            break
        case .selectUser(let user):
            if let index = state.selectedUsers.firstIndex(where: { $0.userID == user.userID }) {
                state.selectedUsers.remove(at: index)
                state.scrollToLastIDPublisher = nil
            } else {
                state.selectedUsers.append(user)
                state.scrollToLastIDPublisher = user.userID
            }
        case .deselectUser(let user):
            if let index = state.selectedUsers.firstIndex(where: { $0.userID == user.userID }) {
                state.selectedUsers.remove(at: index)
                state.scrollToLastIDPublisher = nil
            }
        }
    }

    // MARK: - Private
    
    private func fetchSuggestions() {
        state.usersSection = .init(type: .suggestions, users: [.mockAlice, .mockBob, .mockCharlie])
    }
    }
}

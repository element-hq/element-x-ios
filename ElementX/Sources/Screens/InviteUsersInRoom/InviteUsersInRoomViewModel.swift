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

    init() {
        super.init(initialViewState: InviteUsersInRoomViewState())
        fetchSuggestion()
    }
    
    // MARK: - Public
    
    override func process(viewAction: InviteUsersInRoomViewAction) async {
        switch viewAction {
        case .close:
            callback?(.close)
        case .selectUser(let user):
            if let index = state.selectedUsers.firstIndex(where: { $0.userID == user.userID }) {
                state.selectedUsers.remove(at: index)
            } else {
                state.selectedUsers.append(user)
            }
        }
    }
    
    // MARK: - Private
    
    private func fetchSuggestion() {
        state.usersSection.type = .suggestions
        state.usersSection.users = [.mockAlice, .mockBob, .mockCharlie]
    }
}

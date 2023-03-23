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

typealias StartChatViewModelType = StateStoreViewModel<StartChatViewState, StartChatViewAction>

class StartChatViewModel: StartChatViewModelType, StartChatViewModelProtocol {
    private let userSession: UserSessionProtocol
    
    var callback: ((StartChatViewModelAction) -> Void)?

    init(userSession: UserSessionProtocol) {
        self.userSession = userSession
        super.init(initialViewState: StartChatViewState(suggestedUsers: [.mockAlice, .mockBob, .mockCharlie]), imageProvider: userSession.mediaProvider)
    }
    
    // MARK: - Public
    
    override func process(viewAction: StartChatViewAction) async {
        switch viewAction {
        case .close:
            callback?(.close)
        case .createRoom:
            callback?(.createRoom)
        case .inviteFriends:
            // TODO: start invite people flow
            break
        }
    }
}

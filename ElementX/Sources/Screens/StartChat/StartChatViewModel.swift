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

typealias StartChatViewModelType = StateStoreViewModel<StartChatViewState, StartChatViewAction>

class StartChatViewModel: StartChatViewModelType, StartChatViewModelProtocol {
    private let userSession: UserSessionProtocol
    
    var callback: ((StartChatViewModelAction) -> Void)?

    init(userSession: UserSessionProtocol) {
        self.userSession = userSession
        super.init(initialViewState: StartChatViewState(), imageProvider: userSession.mediaProvider)
        
        start()
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
        case .userSelected(let user):
            callback?(.userSelected(user))
        }
    }
    
    func displayError(_ type: ClientProxyError) {
        switch type {
        case .failedRetrievingDirectRoom:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: ElementL10n.dialogTitleError,
                                                 message: ElementL10n.retrievingDirectRoomError)
        case .failedCreatingRoom: // this will likely be in the Room's screen while sending the first message
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: ElementL10n.dialogTitleError,
                                                 message: ElementL10n.retrievingDirectRoomError)
        default:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
    
    // MARK: - Private
    
    private func start() {
        context.$viewState
            .map(\.bindings.searchQuery)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] searchQuery in
                if MatrixEntityRegex.isMatrixUserIdentifier(searchQuery) {
                    self?.state.searchedUsers = [.init(id: searchQuery)]
                } else {
                    self?.state.searchedUsers = []
                }
            })
            .store(in: &cancellables)
    }
}

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

typealias JoinRoomScreenViewModelType = StateStoreViewModel<JoinRoomScreenViewState, JoinRoomScreenViewAction>

class JoinRoomScreenViewModel: JoinRoomScreenViewModelType, JoinRoomScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    
    private let actionsSubject: PassthroughSubject<JoinRoomScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<JoinRoomScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomID: String, roomName: String, avatarURL: URL?, interaction: JoinRoomScreenInteraction, clientProxy: ClientProxyProtocol) {
        self.clientProxy = clientProxy
        
        super.init(initialViewState: JoinRoomScreenViewState(roomID: roomID,
                                                             roomName: roomName,
                                                             avatarURL: avatarURL,
                                                             interaction: interaction))
    }
    
    // MARK: - Public
    
    override func process(viewAction: JoinRoomScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .knock:
            break
        case .join:
            Task { await joinRoom() }
        case .acceptInvite:
            break
        case .declineInvite:
            break
        }
    }
    
    // MARK: - Private
    
    private func joinRoom() async {
        state.isJoining = true
        switch await clientProxy.joinRoom(state.roomID) {
        case .success:
            actionsSubject.send(.joined)
        case .failure:
            state.bindings.alertInfo = .init(id: .joinFailed)
        }
    }
}

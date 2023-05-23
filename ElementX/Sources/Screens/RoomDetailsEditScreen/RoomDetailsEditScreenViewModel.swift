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

typealias RoomDetailsEditScreenViewModelType = StateStoreViewModel<RoomDetailsEditScreenViewState, RoomDetailsEditScreenViewAction>

class RoomDetailsEditScreenViewModel: RoomDetailsEditScreenViewModelType, RoomDetailsEditScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<RoomDetailsEditScreenViewModelAction, Never> = .init()
    private let roomProxy: RoomProxyProtocol
    
    var actions: AnyPublisher<RoomDetailsEditScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(accountOwner: RoomMemberProxyProtocol, roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
        
        let roomName = roomProxy.name
        let roomTopic = roomProxy.topic
        
        super.init(initialViewState: RoomDetailsEditScreenViewState(initialName: roomName,
                                                                    initialTopic: roomTopic,
                                                                    canEditAvatar: accountOwner.canSendStateEvent(type: .roomAvatar),
                                                                    canEditName: accountOwner.canSendStateEvent(type: .roomName),
                                                                    canEditTopic: accountOwner.canSendStateEvent(type: .roomTopic),
                                                                    bindings: .init(name: roomName ?? "", topic: roomTopic ?? "")))
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomDetailsEditScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.cancel)
        case .save:
            break
        }
    }
}

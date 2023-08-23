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

typealias MessageForwardingScreenViewModelType = StateStoreViewModel<MessageForwardingScreenViewState, MessageForwardingScreenViewAction>

class MessageForwardingScreenViewModel: MessageForwardingScreenViewModelType, MessageForwardingScreenViewModelProtocol {
    private let roomSummaryProvider: RoomSummaryProviderProtocol?
    private let sourceRoomID: String
    
    private var actionsSubject: PassthroughSubject<MessageForwardingScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<MessageForwardingScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomSummaryProvider: RoomSummaryProviderProtocol,
         sourceRoomID: String) {
        self.roomSummaryProvider = roomSummaryProvider
        self.sourceRoomID = sourceRoomID
        
        super.init(initialViewState: MessageForwardingScreenViewState())
        
        roomSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRooms()
            }
            .store(in: &cancellables)
        
        updateRooms()
    }
    
    override func process(viewAction: MessageForwardingScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.dismiss)
        case .send:
            guard let roomID = state.selectedRoomID else {
                fatalError()
            }
            
            actionsSubject.send(.send(roomID: roomID))
        case .selectRoom(let roomID):
            state.selectedRoomID = roomID
        }
    }
    
    // MARK: - Private
    
    private func updateRooms() {
        guard let roomSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        MXLog.info("Updating rooms")
        
        var rooms = [MessageForwardingRoom]()
                
        for summary in roomSummaryProvider.roomListPublisher.value {
            switch summary {
            case .empty, .invalidated:
                continue
            case .filled(let details):
                if details.id == sourceRoomID {
                    continue
                }
                
                let room = MessageForwardingRoom(id: details.id, name: details.name, alias: details.canonicalAlias, avatarURL: details.avatarURL)
                rooms.append(room)
            }
        }
        
        state.rooms = rooms
        
        MXLog.info("Finished updating rooms")
    }
}

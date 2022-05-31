//
// Copyright 2021 New Vector Ltd
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
import Combine

typealias HomeScreenViewModelType = StateStoreViewModel<HomeScreenViewState, HomeScreenViewAction>

class HomeScreenViewModel: HomeScreenViewModelType, HomeScreenViewModelProtocol {
    
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    
    private var roomUpdateListeners = Set<AnyCancellable>()

    private var roomSummaries: [RoomSummaryProtocol]? {
        didSet {
            self.state.isLoadingRooms = (roomSummaries?.count ?? 0 == 0)
        }
    }
    
    var callback: ((HomeScreenViewModelAction) -> Void)?
    
    // MARK: - Setup
    
    init(attributedStringBuilder: AttributedStringBuilderProtocol) {
        self.attributedStringBuilder = attributedStringBuilder
        
        super.init(initialViewState: HomeScreenViewState(isLoadingRooms: true))
    }
    
    // MARK: - Public
    
    override func process(viewAction: HomeScreenViewAction) async {
        switch viewAction {
        case .logout:
            callback?(.logout)
        case .loadRoomData(let roomIdentifier):
            loadRoomDataForIdentifier(roomIdentifier)
        case .selectRoom(let roomIdentifier):
            callback?(.selectRoom(roomIdentifier: roomIdentifier))
        }
    }
    
    func updateWithRoomSummaries(_ roomSummaries: [RoomSummaryProtocol]) {
        self.roomSummaries = roomSummaries
        
        state.rooms = roomSummaries.map { roomSummary in
            buildOrUpdateRoomFromSummary(roomSummary)
        }
        
        roomUpdateListeners.removeAll()
        
        roomSummaries.forEach({ roomSummary  in
            roomSummary.callbacks
                .receive(on: DispatchQueue.main)
                .sink { [weak self] callback in
                    guard let self = self else {
                        return
                    }
                    
                    switch callback {
                    case .updatedData:
                        if let index = self.state.rooms.firstIndex(where: { $0.id == roomSummary.id }) {
                            self.state.rooms[index] = self.buildOrUpdateRoomFromSummary(roomSummary)
                        }
                    }
                }
                .store(in: &roomUpdateListeners)
        })
        
    }
    
    func updateWithUserAvatar(_ avatar: UIImage) {
        self.state.userAvatar = avatar
    }
    
    func updateWithUserDisplayName(_ displayName: String) {
        self.state.userDisplayName = displayName
    }
    
    // MARK: - Private
    
    private func loadRoomDataForIdentifier(_ roomIdentifier: String) {
        guard let roomSummary = roomSummaries?.first(where: { $0.id == roomIdentifier }) else {
            MXLog.error("Invalid room identifier")
            return
        }
        
        Task { await roomSummary.loadDetails() }
    }
    
    private func buildOrUpdateRoomFromSummary(_ roomSummary: RoomSummaryProtocol) -> HomeScreenRoom {
        let lastMessage = lastMessageFromEventBrief(roomSummary.lastMessage)
        
        guard var room = self.state.rooms.first(where: { $0.id == roomSummary.id }) else {
            return HomeScreenRoom(id: roomSummary.id,
                                  displayName: roomSummary.displayName,
                                  topic: roomSummary.topic,
                                  lastMessage: lastMessage,
                                  avatar: roomSummary.avatar,
                                  isDirect: roomSummary.isDirect,
                                  isEncrypted: roomSummary.isEncrypted,
                                  isSpace: roomSummary.isSpace,
                                  isTombstoned: roomSummary.isTombstoned)
        }
        
        room.avatar = roomSummary.avatar
        room.displayName = roomSummary.displayName
        room.lastMessage = lastMessage
        
        return room
    }
    
    private func lastMessageFromEventBrief(_ eventBrief: EventBrief?) -> String? {
        guard let eventBrief = eventBrief else {
            return nil
        }
        
        let senderDisplayName = senderDisplayNameForBrief(eventBrief)
        
        if let htmlBody = eventBrief.htmlBody,
           let lastMessageAttributedString = attributedStringBuilder.fromHTML(htmlBody) {
            return "\(senderDisplayName): \(String(lastMessageAttributedString.characters))"
        } else {
            return "\(senderDisplayName): \(eventBrief.body)"
        }
    }
    
    private func senderDisplayNameForBrief(_ brief: EventBrief) -> String {
        brief.senderDisplayName ?? brief.senderId
    }
}

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

@available(iOS 14, *)
typealias HomeScreenViewModelType = StateStoreViewModel<HomeScreenViewState,
                                                        Never,
                                                        HomeScreenViewAction>
@available(iOS 14, *)
class HomeScreenViewModel: HomeScreenViewModelType, HomeScreenViewModelProtocol {
    
    private let mediaProvider: MediaProviderProtocol
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    
    private var roomUpdateListeners = Set<AnyCancellable>()

    private var roomList: [RoomSummaryProtocol]? {
        didSet {
            self.state.isLoadingRooms = (roomList?.count ?? 0 == 0)
        }
    }

    var completion: ((HomeScreenViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(userDisplayName: String,
         userAvatarURL: String?,
         mediaProvider: MediaProviderProtocol,
         attributedStringBuilder: AttributedStringBuilderProtocol) {
        self.mediaProvider = mediaProvider
        self.attributedStringBuilder = attributedStringBuilder
        
        super.init(initialViewState: HomeScreenViewState(userDisplayName: userDisplayName, isLoadingRooms: true))
        
        if let userAvatarURL = userAvatarURL {
            mediaProvider.loadImageFromURL(userAvatarURL) { [weak self] result in
                if case let .success(avatar) =  result {
                    self?.state.userAvatar = avatar
                }
            }
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: HomeScreenViewAction) {
        switch viewAction {
        case .logout:
            self.completion?(.logout)
        case .loadRoomData(let roomIdentifier):
            self.loadRoomDataForIdentifier(roomIdentifier)
        case .selectRoom(let roomIdentifier):
            self.completion?(.selectRoom(roomIdentifier: roomIdentifier))
        }
    }
    
    func updateWithRoomList(_ roomList: [RoomSummaryProtocol]) {
        self.roomList = roomList
        
        state.rooms = roomList.map { roomSummary in
            buildOrUpdateRoomFromSummary(roomSummary)
        }
        
        roomUpdateListeners.removeAll()
        
        roomList.forEach({ roomSummary  in
            roomSummary.callbacks.sink { [weak self] callback in
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
    
    func updateWithUserAvatar(_ avatar: UIImage?) {
        self.state.userAvatar = avatar
    }
    
    // MARK: - Private
    
    private func loadRoomDataForIdentifier(_ roomIdentifier: String) {
        guard let roomSummary = roomList?.first(where: { $0.id == roomIdentifier }) else {
            MXLog.error("Invalid room identifier")
            return
        }
        
        roomSummary.loadData()
    }
    
    private func buildOrUpdateRoomFromSummary(_ roomSummary: RoomSummaryProtocol) -> HomeScreenRoom {
        let lastMessage = lastMessageFromEventBrief(roomSummary.lastMessage)
        
        guard var room = self.state.rooms.first(where: { $0.id == roomSummary.id }) else {
            return HomeScreenRoom(id: roomSummary.id,
                                  displayName: roomSummary.displayName ?? roomSummary.name,
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

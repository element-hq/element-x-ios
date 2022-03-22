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
    
    private var roomUpdateListeners = Set<AnyCancellable>()
    private var roomList: [RoomProxyProtocol]? {
        didSet {
            self.state.isLoadingRooms = (roomList?.count ?? 0 == 0)
        }
    }

    var completion: ((HomeScreenViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(userDisplayName: String, userAvatarURL: String?, mediaProvider: MediaProviderProtocol) {
        self.mediaProvider = mediaProvider
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
    
    func updateWithRoomList(_ roomList: [RoomProxyProtocol]) {
        self.roomList = roomList
        
        state.rooms = roomList.map { roomProxy in
            roomFromProxy(roomProxy)
        }
        
        roomUpdateListeners.removeAll()
        
        roomList.forEach({ roomProxy  in
            roomProxy.callbacks.sink { [weak self] callback in
                switch callback {
                case .updatedLastMessage:
                    self?.loadLastMessageForRoomWithIdentifier(roomProxy.id)
                default:
                    break
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
        loadAvatarForRoomWithIdentifier(roomIdentifier)
        loadRoomDisplayNameForRoomWithIdentifier(roomIdentifier)
        loadLastMessageForRoomWithIdentifier(roomIdentifier)
    }
    
    private func loadAvatarForRoomWithIdentifier(_ roomIdentifier: String) {
        guard let room = roomList?.filter({ $0.id == roomIdentifier }).first,
              let avatarURLString = room.avatarURL else {
                  return
              }
        
        mediaProvider.loadImageFromURL(avatarURLString) { [weak self] result in
            guard let self = self else { return }
            if case let .success(image) = result {
                self.updateAvatar(image, forRoomWithIdentifier: roomIdentifier)
            }
        }
    }
    
    private func updateAvatar(_ avatar: UIImage?, forRoomWithIdentifier roomIdentifier: String) {
        guard let index = self.state.rooms.firstIndex(where: { $0.id == roomIdentifier }) else {
            return
        }
        
        self.state.rooms[index].avatar = avatar
    }
    
    private func loadRoomDisplayNameForRoomWithIdentifier(_ roomIdentifier: String) {
        guard let room = roomList?.filter({ $0.id == roomIdentifier }).first else {
            return
        }
        
        room.displayName { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let displayName):
                self.updateDisplayName(displayName, forRoomWithIdentifier: roomIdentifier)
            default:
                break
            }
        }
    }
    
    private func updateDisplayName(_ displayName: String, forRoomWithIdentifier roomIdentifier: String) {
        guard let index = self.state.rooms.firstIndex(where: { $0.id == roomIdentifier }) else {
            return
        }
        
        self.state.rooms[index].displayName = displayName
    }
    
    private func loadLastMessageForRoomWithIdentifier(_ roomIdentifier: String) {
        guard let room = roomList?.filter({ $0.id == roomIdentifier }).first else {
            return
        }
        
        if let lastMessage = room.lastMessage {
            self.updateLastMessage(lastMessage, forRoomWithIdentifier: roomIdentifier)
        } else {
            room.paginateBackwards(count: 1) { result in
                switch result {
                case .success(let messages):
                    guard let lastMessage = messages.last else {
                        return
                    }
                    
                    self.updateLastMessage(lastMessage.body, forRoomWithIdentifier: roomIdentifier)
                default:
                    break
                }
            }
        }
    }
    
    private func updateLastMessage(_ lastMessage: String, forRoomWithIdentifier roomIdentifier: String) {
        guard let index = self.state.rooms.firstIndex(where: { $0.id == roomIdentifier }) else {
            return
        }
        
        self.state.rooms[index].lastMessage = lastMessage
    }
        
    private func roomFromProxy(_ roomProxy: RoomProxyProtocol) -> HomeScreenRoom {
        HomeScreenRoom(id: roomProxy.id,
                       displayName: roomProxy.name,
                       topic: roomProxy.topic,
                       lastMessage: roomProxy.lastMessage,
                       isDirect: roomProxy.isDirect,
                       isEncrypted: roomProxy.isEncrypted)
    }
}

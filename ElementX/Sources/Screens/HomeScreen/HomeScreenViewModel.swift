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

typealias HomeScreenViewModelType = StateStoreViewModel<HomeScreenViewState, HomeScreenViewAction>

class HomeScreenViewModel: HomeScreenViewModelType, HomeScreenViewModelProtocol {
    private let userSession: UserSessionProtocol
    private let roomSummaryProvider: RoomSummaryProviderProtocol
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    
    var callback: ((HomeScreenViewModelAction) -> Void)?
    
    // MARK: - Setup
    
    init(userSession: UserSessionProtocol, attributedStringBuilder: AttributedStringBuilderProtocol) {
        self.userSession = userSession
        roomSummaryProvider = userSession.clientProxy.roomSummaryProvider
        self.attributedStringBuilder = attributedStringBuilder
        
        super.init(initialViewState: HomeScreenViewState(userID: userSession.userID))
        
        userSession.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                switch callback {
                case .sessionVerificationNeeded:
                    self?.state.showSessionVerificationBanner = true
                case .didVerifySession:
                    self?.state.showSessionVerificationBanner = false
                default:
                    break
                }
            }.store(in: &cancellables)
        
        roomSummaryProvider.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                switch callback {
                case .updatedRoomSummaries:
                    Task {
                        await self?.updateRooms()
                    }
                }
            }.store(in: &cancellables)
        
        Task {
            if case let .success(userAvatarURLString) = await userSession.clientProxy.loadUserAvatarURLString() {
                if case let .success(avatar) = await userSession.mediaProvider.loadImageFromURLString(userAvatarURLString, size: .user(on: .home)) {
                    state.userAvatar = avatar
                }
            }

            if case let .success(userDisplayName) = await userSession.clientProxy.loadUserDisplayName() {
                state.userDisplayName = userDisplayName
            }
            
            await updateRooms()
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: HomeScreenViewAction) async {
        switch viewAction {
        case .loadRoomData(let roomIdentifier):
            loadDataForRoomIdentifier(roomIdentifier)
        case .selectRoom(let roomIdentifier):
            callback?(.selectRoom(roomIdentifier: roomIdentifier))
        case .userMenu(let action):
            callback?(.userMenu(action: action))
        case .verifySession:
            callback?(.verifySession)
        case .skipSessionVerification:
            state.showSessionVerificationBanner = false
        }
    }
    
    // MARK: - Private
    
    private func loadDataForRoomIdentifier(_ identifier: String) {
        guard let summary = roomSummaryProvider.roomSummaries.first(where: { $0.id == identifier }),
              var room = state.rooms.first(where: { $0.id == identifier }) else {
            return
        }
        
        if room.avatar != nil {
            return
        }
        
        if let avatarURLString = summary.avatarURLString {
            Task {
                if case let .success(image) = await userSession.mediaProvider.loadImageFromURLString(avatarURLString, size: .room(on: .home)) {
                    if let index = state.rooms.firstIndex(of: room) {
                        room.avatar = image
                        state.rooms[index] = room
                    }
                }
            }
        }
    }
    
    private func updateRooms() async {
        state.rooms = await Task.detached {
            var rooms = [HomeScreenRoom]()
            
            for summary in self.roomSummaryProvider.roomSummaries {
                let avatarImage = await self.userSession.mediaProvider.imageFromURLString(summary.avatarURLString, size: .room(on: .home))
                
                var timestamp: String?
                if let lastMessageTimestamp = summary.lastMessageTimestamp {
                    timestamp = lastMessageTimestamp.formatted(date: .omitted, time: .shortened)
                }
                
                rooms.append(HomeScreenRoom(id: summary.id,
                                            name: summary.name,
                                            hasUnreads: summary.unreadNotificationCount > 0,
                                            timestamp: timestamp,
                                            lastMessage: summary.lastMessage,
                                            avatar: avatarImage))
            }
            
            return rooms
        }.value
    }
}

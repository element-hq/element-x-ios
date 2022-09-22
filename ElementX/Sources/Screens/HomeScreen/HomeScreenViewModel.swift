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
    
    // swiftlint:disable:next function_body_length
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
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest3(roomSummaryProvider.stateUpdatePublisher,
                                  roomSummaryProvider.countUpdatePublisher,
                                  roomSummaryProvider.roomListUpdatePublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, totalCount, rooms in
                if state != .live {
                    if totalCount == 0 || rooms.count != totalCount {
                        self?.state.roomListMode = .skeletons
                    } else {
                        self?.state.roomListMode = .rooms
                    }
                } else if totalCount == 0 {
                    #warning("Empty state but it never happens because SS never goes into live for empty accounts")
                }
            }
            .store(in: &cancellables)
        
        roomSummaryProvider.roomListUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.updateRooms()
                }
            }
            .store(in: &cancellables)
        
        Task {
            if case let .success(userAvatarURLString) = await userSession.clientProxy.loadUserAvatarURLString() {
                if case let .success(avatar) = await userSession.mediaProvider.loadImageFromURLString(userAvatarURLString, avatarSize: .user(on: .home)) {
                    state.userAvatar = avatar
                }
            }
        }
        
        Task {
            if case let .success(userDisplayName) = await userSession.clientProxy.loadUserDisplayName() {
                state.userDisplayName = userDisplayName
            }
        }
        
        Task {
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
        guard let summary = roomSummaryProvider.roomListUpdatePublisher.value.first(where: { $0.asFilled?.id == identifier })?.asFilled,
              let homeRoomIndex = state.rooms.firstIndex(where: { $0.asFilled?.id == identifier }),
              var details = state.rooms[homeRoomIndex].asFilled,
              details.avatar == nil,
              let avatarURLString = summary.avatarURLString else {
            return
        }
        
        Task {
            if case let .success(image) = await userSession.mediaProvider.loadImageFromURLString(avatarURLString, avatarSize: .room(on: .home)) {
                details.avatar = image
                state.rooms[homeRoomIndex] = .filled(details)
            }
        }
    }
    
    private func updateRooms() async {
        state.rooms = await Task.detached {
            var rooms = [HomeScreenRoom]()
            
            for summary in self.roomSummaryProvider.roomListUpdatePublisher.value {
                switch summary {
                case .empty(let id):
                    rooms.append(HomeScreenRoom.empty(HomeScreenRoomDetails.placeholder(id: id)))
                    continue
                case .filled(let summary):
                    let avatarImage = await self.userSession.mediaProvider.imageFromURLString(summary.avatarURLString, avatarSize: .room(on: .home))
                    
                    var timestamp: String?
                    if let lastMessageTimestamp = summary.lastMessageTimestamp {
                        timestamp = lastMessageTimestamp.formatted(date: .omitted, time: .shortened)
                    }
                    
                    rooms.append(HomeScreenRoom.filled(HomeScreenRoomDetails(id: summary.id,
                                                                             name: summary.name,
                                                                             hasUnreads: summary.unreadNotificationCount > 0,
                                                                             timestamp: timestamp,
                                                                             lastMessage: summary.lastMessage,
                                                                             avatar: avatarImage)))
                }
            }
            
            return rooms
        }.value
    }
}

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
    private let roomSummaryProvider: RoomSummaryProviderProtocol?
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    private var roomsForIdentifiers = [String: HomeScreenRoom]()
    
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
        
        guard let roomSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        Publishers.CombineLatest3(roomSummaryProvider.statePublisher,
                                  roomSummaryProvider.countPublisher,
                                  roomSummaryProvider.roomListPublisher)
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
                } else {
                    self?.state.roomListMode = .rooms
                }
            }
            .store(in: &cancellables)
        
        roomSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRooms()
            }
            .store(in: &cancellables)
        
        updateRooms()
    }
    
    // MARK: - Public
    
    override func process(viewAction: HomeScreenViewAction) async {
        switch viewAction {
        case .loadRoomData(let roomIdentifier):
            if state.roomListMode != .skeletons {
                loadDataForRoomIdentifier(roomIdentifier)
            }
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
    
    func presentAlert(_ alertInfo: AlertInfo<UUID>) {
        state.bindings.alertInfo = alertInfo
    }
    
    // MARK: - Private
    
    private func loadDataForRoomIdentifier(_ identifier: String) {
        guard let roomSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        guard let roomSummary = roomSummaryProvider.roomListPublisher.value.first(where: { $0.asFilled?.id == identifier })?.asFilled,
              let roomIndex = state.rooms.firstIndex(where: { $0.id == identifier }) else {
            return
        }
        
        var room = state.rooms[roomIndex]
            
        guard room.avatar == nil,
              let avatarURLString = roomSummary.avatarURLString else {
            return
        }
        
        Task {
            if case let .success(image) = await userSession.mediaProvider.loadImageFromURLString(avatarURLString, avatarSize: .room(on: .home)) {
                room.avatar = image
                state.rooms[roomIndex] = room
                roomsForIdentifiers[roomSummary.id] = room
            }
        }
    }
    
    private func updateRooms() {
        guard let roomSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        var rooms = [HomeScreenRoom]()
        var newRoomsForIdentifiers = [String: HomeScreenRoom]()
        
        for summary in roomSummaryProvider.roomListPublisher.value {
            switch summary {
            case .empty(let id):
                rooms.append(HomeScreenRoom.placeholder(id: id))
            case .filled(let summary):
                let oldRoom = roomsForIdentifiers[summary.id]
                
                let avatarImage = userSession.mediaProvider.imageFromURLString(summary.avatarURLString, avatarSize: .room(on: .home))
                
                var timestamp: String?
                if let lastMessageTimestamp = summary.lastMessageTimestamp {
                    timestamp = lastMessageTimestamp.formatted(date: .omitted, time: .shortened)
                }
                
                let room = HomeScreenRoom(id: summary.id,
                                          name: summary.name,
                                          hasUnreads: summary.unreadNotificationCount > 0,
                                          timestamp: timestamp ?? oldRoom?.timestamp,
                                          lastMessage: summary.lastMessage ?? oldRoom?.lastMessage,
                                          avatar: avatarImage ?? oldRoom?.avatar)
                
                rooms.append(room)
                newRoomsForIdentifiers[summary.id] = room
            }
        }
        
        state.rooms = rooms
        roomsForIdentifiers = newRoomsForIdentifiers
    }
}

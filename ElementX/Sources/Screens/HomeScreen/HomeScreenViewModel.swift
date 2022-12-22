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
    private let visibleRoomsSummaryProvider: RoomSummaryProviderProtocol?
    private let allRoomsSummaryProvider: RoomSummaryProviderProtocol?
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    private var roomsForIdentifiers = [String: HomeScreenRoom]()
    
    var callback: ((HomeScreenViewModelAction) -> Void)?
    
    // MARK: - Setup
    
    // swiftlint:disable:next function_body_length
    init(userSession: UserSessionProtocol, attributedStringBuilder: AttributedStringBuilderProtocol) {
        self.userSession = userSession
        self.attributedStringBuilder = attributedStringBuilder
        
        visibleRoomsSummaryProvider = userSession.clientProxy.visibleRoomsSummaryProvider
        allRoomsSummaryProvider = userSession.clientProxy.allRoomsSummaryProvider
        
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
        
        guard let visibleRoomsSummaryProvider, let allRoomsSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        // Combine all 3 publishers to correctly compute the screen state
        Publishers.CombineLatest3(visibleRoomsSummaryProvider.statePublisher,
                                  visibleRoomsSummaryProvider.countPublisher,
                                  visibleRoomsSummaryProvider.roomListPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, totalCount, rooms in
                let isLoadingData = state != .live && (totalCount == 0 || rooms.count != totalCount)
                let hasNoRooms = state == .live && totalCount == 0
                
                if isLoadingData {
                    self?.state.roomListMode = .skeletons
                } else if hasNoRooms {
                    self?.state.roomListMode = .skeletons
                } else {
                    self?.state.roomListMode = .rooms
                }
            }
            .store(in: &cancellables)
        
        // Listen to changes from both roomSummaryProviders and update state accordingly
        
        visibleRoomsSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRooms()
            }
            .store(in: &cancellables)
        
        allRoomsSummaryProvider.roomListPublisher
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
        case .updatedVisibleItemIdentifiers(let identifiers):
            updateVisibleRange(visibleItemIdentifiers: identifiers)
        }
    }
    
    func presentAlert(_ alertInfo: AlertInfo<UUID>) {
        state.bindings.alertInfo = alertInfo
    }
    
    // MARK: - Private
    
    private func loadDataForRoomIdentifier(_ identifier: String) {
        guard let visibleRoomsSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        guard let roomSummary = visibleRoomsSummaryProvider.roomListPublisher.value.first(where: { $0.asFilled?.id == identifier })?.asFilled,
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
    
    /// This method will update all view state rooms by merging the data from both summary providers
    /// If a room is empty in the visible room summary provider it will try to get it from the allRooms one
    /// This ensures that we show as many room details as possible without loading up timelines
    private func updateRooms() {
        guard let visibleRoomsSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        var rooms = [HomeScreenRoom]()
        var newRoomsForIdentifiers = [String: HomeScreenRoom]()
        
        for (index, summary) in visibleRoomsSummaryProvider.roomListPublisher.value.enumerated() {
            switch summary {
            case .empty(let id):
                guard case let .filled(summary) = allRoomsSummaryProvider?.roomListPublisher.value[safe: index] else {
                    rooms.append(HomeScreenRoom.placeholder(id: id))
                    continue
                }
                
                let room = buildRoomForSummary(summary)
                rooms.append(room)
                newRoomsForIdentifiers[summary.id] = room
            case .filled(let summary):
                let room = buildRoomForSummary(summary)
                rooms.append(room)
                newRoomsForIdentifiers[summary.id] = room
            }
        }
        
        state.rooms = rooms
        roomsForIdentifiers = newRoomsForIdentifiers
    }
    
    private func buildRoomForSummary(_ summary: RoomSummaryDetails) -> HomeScreenRoom {
        let oldRoom = roomsForIdentifiers[summary.id]
        
        let avatarImage = userSession.mediaProvider.imageFromURLString(summary.avatarURLString, avatarSize: .room(on: .home))
        
        var timestamp: String?
        if let lastMessageTimestamp = summary.lastMessageTimestamp {
            timestamp = lastMessageTimestamp.formatted(date: .omitted, time: .shortened)
        }
        
        return HomeScreenRoom(id: summary.id,
                              name: summary.name,
                              hasUnreads: summary.unreadNotificationCount > 0,
                              timestamp: timestamp ?? oldRoom?.timestamp,
                              lastMessage: summary.lastMessage ?? oldRoom?.lastMessage,
                              avatar: avatarImage ?? oldRoom?.avatar)
    }
    
    private func updateVisibleRange(visibleItemIdentifiers items: Set<String>) {
        let result = items.compactMap { itemIdentifier in
            state.rooms.firstIndex { $0.id == itemIdentifier }
        }.sorted()
        
        guard !result.isEmpty else {
            return
        }
        
        guard let lowerBound = result.first, let upperBound = result.last else {
            return
        }
        
        visibleRoomsSummaryProvider?.updateVisibleRange(lowerBound...upperBound)
    }
}

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
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    
    private var roomUpdateListeners = Set<AnyCancellable>()
    private var roomsUpdateTask: Task<Void, Never>? {
        willSet {
            roomsUpdateTask?.cancel()
        }
    }

    private var roomSummaries: [RoomSummaryProtocol]? {
        didSet {
            state.isLoadingRooms = (roomSummaries?.count ?? 0 == 0)
        }
    }
    
    var callback: ((HomeScreenViewModelAction) -> Void)?
    
    // MARK: - Setup
    
    init(initialDisplayName: String, attributedStringBuilder: AttributedStringBuilderProtocol) {
        self.attributedStringBuilder = attributedStringBuilder
        
        super.init(initialViewState: HomeScreenViewState(userDisplayName: initialDisplayName,
                                                         isLoadingRooms: true))
    }
    
    // MARK: - Public
    
    override func process(viewAction: HomeScreenViewAction) async {
        switch viewAction {
        case .loadRoomData(let roomIdentifier):
            loadRoomDataForIdentifier(roomIdentifier)
        case .selectRoom(let roomIdentifier):
            callback?(.selectRoom(roomIdentifier: roomIdentifier))
        case .userMenu(let action):
            callback?(.userMenu(action: action))
        case .verifySession:
            callback?(.verifySession)
        }
    }
    
    func updateWithRoomSummaries(_ roomSummaries: [RoomSummaryProtocol]) {
        roomsUpdateTask = Task {
            await updateWithRoomSummaries(roomSummaries)
        }
    }
    
    private func updateWithRoomSummaries(_ roomSummaries: [RoomSummaryProtocol]) async {
        var rooms = [HomeScreenRoom]()
        for summary in roomSummaries {
            if Task.isCancelled {
                return
            }
            
            rooms.append(await buildOrUpdateRoomForSummary(summary))
        }
        
        if Task.isCancelled {
            return
        }
        
        state.rooms = rooms
        self.roomSummaries = roomSummaries
        
        roomUpdateListeners.removeAll()
        roomSummaries.forEach { roomSummary in
            roomSummary.callbacks
                .receive(on: DispatchQueue.main)
                .sink { [weak self] callback in
                    guard let self = self else {
                        return
                    }
                    
                    Task {
                        if let index = self.state.rooms.firstIndex(where: { $0.id == roomSummary.id }) {
                            switch callback {
                            case .updatedLastMessage:
                                var room = self.state.rooms[index]
                                room.lastMessage = await self.lastMessageFromEventBrief(roomSummary.lastMessage)
                                self.state.rooms[index] = room
                            default:
                                self.state.rooms[index] = await self.buildOrUpdateRoomForSummary(roomSummary)
                            }
                        }
                    }
                }
                .store(in: &roomUpdateListeners)
        }
    }
    
    func updateWithUserAvatar(_ avatar: UIImage) {
        state.userAvatar = avatar
    }
    
    func updateWithUserDisplayName(_ displayName: String) {
        state.userDisplayName = displayName
    }
    
    func showSessionVerificationBanner() {
        state.showSessionVerificationBanner = true
    }
    
    func hideSessionVerificationBanner() {
        state.showSessionVerificationBanner = false
    }
    
    // MARK: - Private
    
    private func loadRoomDataForIdentifier(_ roomIdentifier: String) {
        guard let roomSummary = roomSummaries?.first(where: { $0.id == roomIdentifier }) else {
            MXLog.error("Invalid room identifier")
            return
        }
        
        Task { await roomSummary.loadDetails() }
    }
    
    private func buildOrUpdateRoomForSummary(_ roomSummary: RoomSummaryProtocol) async -> HomeScreenRoom {
        guard var room = state.rooms.first(where: { $0.id == roomSummary.id }) else {
            return HomeScreenRoom(id: roomSummary.id,
                                  displayName: roomSummary.displayName,
                                  topic: roomSummary.topic,
                                  lastMessage: await lastMessageFromEventBrief(roomSummary.lastMessage),
                                  avatar: roomSummary.avatar,
                                  isDirect: roomSummary.isDirect,
                                  isEncrypted: roomSummary.isEncrypted,
                                  isSpace: roomSummary.isSpace,
                                  isTombstoned: roomSummary.isTombstoned)
        }
        
        room.avatar = roomSummary.avatar
        room.displayName = roomSummary.displayName
        room.topic = roomSummary.topic
                
        return room
    }
    
    private func lastMessageFromEventBrief(_ eventBrief: EventBrief?) async -> String? {
        guard let eventBrief = eventBrief else {
            return nil
        }
        
        let senderDisplayName = senderDisplayNameForBrief(eventBrief)
        
        if let htmlBody = eventBrief.htmlBody,
           let lastMessageAttributedString = await attributedStringBuilder.fromHTML(htmlBody) {
            return "\(senderDisplayName): \(String(lastMessageAttributedString.characters))"
        } else {
            return "\(senderDisplayName): \(eventBrief.body)"
        }
    }
    
    private func senderDisplayNameForBrief(_ brief: EventBrief) -> String {
        brief.senderDisplayName ?? brief.senderId
    }
}

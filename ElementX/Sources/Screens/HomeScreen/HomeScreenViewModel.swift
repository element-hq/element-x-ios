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
        
        super.init(initialViewState: HomeScreenViewState())
        
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
                    self?.updateRooms()
                }
            }.store(in: &cancellables)
        
        Task {
            if case let .success(userAvatarURLString) = await userSession.clientProxy.loadUserAvatarURLString() {
                if case let .success(avatar) = await userSession.mediaProvider.loadImageFromURLString(userAvatarURLString) {
                    state.userAvatar = avatar
                }
            }
        }
        
        updateRooms()
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
        guard let summary = roomSummaryProvider.roomSummaries.first(where: { $0.id == identifier }) else {
            return
        }
        
        if let avatarURLString = summary.avatarURLString {
            Task {
                let _ = await userSession.mediaProvider.loadImageFromURLString(avatarURLString)
                updateRooms()
            }
        }
    }
    
    private func updateRooms() {
        state.rooms = roomSummaryProvider.roomSummaries.map { summary in
            let avatarImage = userSession.mediaProvider.imageFromURLString(summary.avatarURLString)
            
            var lastMessage: AttributedString?
            if let message = summary.lastMessage {
                lastMessage = try? AttributedString(markdown: "**\(message.sender)**: \(message.body)")
            }
            
            return HomeScreenRoom(id: summary.id,
                                  name: summary.name,
                                  lastMessage: lastMessage,
                                  avatar: avatarImage,
                                  isDirect: summary.isDirect,
                                  unreadNotificationCount: summary.unreadNotificationCount)
        }
    }
}

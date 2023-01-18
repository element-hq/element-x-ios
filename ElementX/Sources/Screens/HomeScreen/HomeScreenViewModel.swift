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
    enum Constants {
        static let slidingWindowBoundsPadding = 5
    }
    
    private let userSession: UserSessionProtocol
    private let visibleRoomsSummaryProvider: RoomSummaryProviderProtocol?
    private let allRoomsSummaryProvider: RoomSummaryProviderProtocol?
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    
    private let visibleItemRangePublisher = CurrentValueSubject<Range<Int>, Never>(0..<0)
    
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
        
        visibleItemRangePublisher
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { range in
                self.updateVisibleRange(range)
            }
            .store(in: &cancellables)
        
        Task {
            if case let .success(url) = await userSession.clientProxy.loadUserAvatarURL() {
                if case let .success(avatar) = await userSession.mediaProvider.loadImageFromURL(url, avatarSize: .user(on: .home)) {
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
    
    // swiftlint:disable:next cyclomatic_complexity
    override func process(viewAction: HomeScreenViewAction) async {
        switch viewAction {
        case .loadRoomData(let roomIdentifier):
            if state.roomListMode != .skeletons {
                loadDataForRoomIdentifier(roomIdentifier)
            }
        case .selectRoom(let roomIdentifier):
            callback?(.presentRoom(roomIdentifier: roomIdentifier))
        case .userMenu(let action):
            switch action {
            case .feedback:
                callback?(.presentFeedbackScreen)
            case .settings:
                callback?(.presentSettingsScreen)
            case .inviteFriends:
                callback?(.presentInviteFriendsScreen)
            case .signOut:
                callback?(.signOut)
            }
        case .verifySession:
            callback?(.presentSessionVerificationScreen)
        case .skipSessionVerification:
            state.showSessionVerificationBanner = false
        case .updatedVisibleItemRange(let range):
            visibleItemRangePublisher.send(range)
        }
    }
    
    func presentCrashedLastRunAlert() {
        state.bindings.alertInfo = AlertInfo(id: UUID(),
                                             title: ElementL10n.sendBugReportAppCrashed,
                                             primaryButton: .init(title: ElementL10n.no, action: nil),
                                             secondaryButton: .init(title: ElementL10n.yes) { [weak self] in
                                                 self?.callback?(.presentFeedbackScreen)
                                             })
    }
    
    // MARK: - Private
    
    private func loadDataForRoomIdentifier(_ identifier: String) {
        guard let room = state.rooms.first(where: { $0.roomId == identifier }),
              room.avatar == nil,
              let avatarURL = room.avatarURL else {
            return
        }
        
        Task {
            if case let .success(image) = await userSession.mediaProvider.loadImageFromURL(avatarURL, avatarSize: .room(on: .home)) {
                guard let roomIndex = state.rooms.firstIndex(where: { $0.roomId == identifier }) else {
                    return
                }
                
                var room = state.rooms[roomIndex]
                room.avatar = image
                state.rooms[roomIndex] = room
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
        
        // Try merging together results from both the visibleRoomsSummaryProvider and the allRoomsSummaryProvider
        // Empty or invalidated items in the visibleRoomsSummaryProvider might have more details in the allRoomsSummaryProvider
        // If items are unavailable in the allRoomsSummaryProvider (hasn't be added to SS yet / cold cache) then use what's available
        for (index, summary) in visibleRoomsSummaryProvider.roomListPublisher.value.enumerated() {
            switch summary {
            case .empty, .invalidated:
                guard let allRoomsRoomSummary = allRoomsSummaryProvider?.roomListPublisher.value[safe: index] else {
                    if case let .invalidated(details) = summary {
                        rooms.append(buildRoom(with: details))
                    } else {
                        rooms.append(HomeScreenRoom.placeholder())
                    }
                    continue
                }

                switch allRoomsRoomSummary {
                case .empty:
                    rooms.append(HomeScreenRoom.placeholder())
                case .filled(let details), .invalidated(let details):
                    rooms.append(buildRoom(with: details))
                }
            case .filled(let details):
                rooms.append(buildRoom(with: details))
            }
        }
        
        state.rooms = rooms
    }
    
    private func buildRoom(with details: RoomSummaryDetails) -> HomeScreenRoom {
        let avatarImage = details.avatarURL.flatMap { userSession.mediaProvider.imageFromURL($0, avatarSize: .room(on: .home)) }
        
        var timestamp: String?
        if let lastMessageTimestamp = details.lastMessageTimestamp {
            timestamp = lastMessageTimestamp.formatted(date: .omitted, time: .shortened)
        }
        
        return HomeScreenRoom(id: details.id,
                              roomId: details.id,
                              name: details.name,
                              hasUnreads: details.unreadNotificationCount > 0,
                              timestamp: timestamp,
                              lastMessage: details.lastMessage,
                              avatarURL: details.avatarURL,
                              avatar: avatarImage)
    }
    
    private func updateVisibleRange(_ range: Range<Int>) {
        guard !range.isEmpty else { return }
        
        guard let visibleRoomsSummaryProvider else {
            MXLog.error("Visible rooms summary provider unavailable")
            return
        }
        
        let lowerBound = max(0, range.lowerBound - Constants.slidingWindowBoundsPadding)
        let upperBound = min(Int(visibleRoomsSummaryProvider.countPublisher.value), range.upperBound + Constants.slidingWindowBoundsPadding)
        
        visibleRoomsSummaryProvider.updateVisibleRange(lowerBound..<upperBound)
    }
}

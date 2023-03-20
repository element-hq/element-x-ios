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
    
    private var visibleItemRangeObservationToken: AnyCancellable?
    private let visibleItemRangePublisher = CurrentValueSubject<(range: Range<Int>, isScrolling: Bool), Never>((0..<0, false))
    
    var callback: ((HomeScreenViewModelAction) -> Void)?
    
    // swiftlint:disable:next function_body_length
    init(userSession: UserSessionProtocol, attributedStringBuilder: AttributedStringBuilderProtocol) {
        self.userSession = userSession
        self.attributedStringBuilder = attributedStringBuilder
        
        visibleRoomsSummaryProvider = userSession.clientProxy.visibleRoomsSummaryProvider
        allRoomsSummaryProvider = userSession.clientProxy.allRoomsSummaryProvider
        
        super.init(initialViewState: HomeScreenViewState(userID: userSession.userID),
                   imageProvider: userSession.mediaProvider)
        
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

        userSession.clientProxy.avatarURLPublisher
            .weakAssign(to: \.state.userAvatarURL, on: self)
            .store(in: &cancellables)
        
        guard let visibleRoomsSummaryProvider, let allRoomsSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        // Combine all 3 publishers to correctly compute the screen state
        Publishers.CombineLatest3(visibleRoomsSummaryProvider.statePublisher,
                                  visibleRoomsSummaryProvider.countPublisher,
                                  visibleRoomsSummaryProvider.roomListPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomSummaryProviderState, totalCount, rooms in
                guard let self else { return }
                
                let isLoadingData = roomSummaryProviderState != .live && (totalCount == 0 || rooms.count != totalCount)
                let hasNoRooms = roomSummaryProviderState == .live && totalCount == 0
                
                var roomListMode = self.state.roomListMode
                if isLoadingData {
                    roomListMode = .skeletons
                } else if hasNoRooms {
                    roomListMode = .skeletons
                } else {
                    roomListMode = .rooms
                }
                
                guard roomListMode != self.state.roomListMode else {
                    return
                }
                
                self.state.roomListMode = roomListMode
                
                MXLog.info("Received visibleRoomsSummaryProvider update, setting view room list mode to \"\(self.state.roomListMode)\"")
                
                // Delay user profile detail loading until after the initial room list loads
                if roomListMode == .rooms {
                    Task {
                        await userSession.clientProxy.loadUserAvatarURL()
                    }
                    
                    Task {
                        if case let .success(userDisplayName) = await userSession.clientProxy.loadUserDisplayName() {
                            self.state.userDisplayName = userDisplayName
                        }
                    }
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
            .dropFirst(1) // We don't care about its initial value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRooms()
                
                // Wait for the all rooms view to receive its first update before installing
                // dynamic timeline modifiers
                self?.installDynamicTimelineLimitModifiers()
            }
            .store(in: &cancellables)
        
        updateRooms()
    }
    
    // MARK: - Public
    
    override func process(viewAction: HomeScreenViewAction) async {
        switch viewAction {
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
        case .updateVisibleItemRange(let range, let isScrolling):
            visibleItemRangePublisher.send((range, isScrolling))
        case .startChat:
            callback?(.presentStartChatScreen)
        }
    }
    
    func presentCrashedLastRunAlert() {
        state.bindings.alertInfo = AlertInfo(id: UUID(),
                                             title: ElementL10n.sendBugReportAppCrashed,
                                             primaryButton: .init(title: ElementL10n.iosNo, action: nil),
                                             secondaryButton: .init(title: ElementL10n.iosYes) { [weak self] in
                                                 self?.callback?(.presentFeedbackScreen)
                                             })
    }
    
    // MARK: - Private
    
    /// We want the timeline limit to be set to 1 while scrolling the list so that last messages load up fast. We also want to set that back to 20 when the scrolling
    /// stops to load room history. Also we don't want this to be setup before the initial sync is over so we only call it when the allRoomsSummaryProvider
    /// first receives some changes
    private func installDynamicTimelineLimitModifiers() {
        guard visibleItemRangeObservationToken == nil else {
            return
        }
        
        visibleItemRangeObservationToken = visibleItemRangePublisher
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates(by: { $0.isScrolling == $1.isScrolling && $0.range == $1.range })
            .sink { [weak self] value in
                guard let self else { return }
                
                // Ignore scrolling while filtering rooms
                guard self.state.bindings.searchQuery.isEmpty else {
                    return
                }
                
                self.updateVisibleRange(value.range, timelineLimit: value.isScrolling ? SlidingSyncConstants.lastMessageTimelineLimit : SlidingSyncConstants.timelinePrecachingTimelineLimit)
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
        
        MXLog.info("Updating rooms")
        
        var rooms = [HomeScreenRoom]()
        var createdRoomIdentifiers = [String: Bool]()
        
        #warning("This works around duplicated room list items coming out of the SDK, remove once fixed")
        func appendRoom(_ room: HomeScreenRoom, allRoomsProvider: Bool) {
            guard createdRoomIdentifiers[room.id] == nil else {
                MXLog.error("Built duplicated room for identifier: \(room.id). AllRoomsSummaryProvider: \(allRoomsProvider). Ignoring")
                return
            }
            
            createdRoomIdentifiers[room.id] = true
            rooms.append(room)
        }
        
        // Try merging together results from both the visibleRoomsSummaryProvider and the allRoomsSummaryProvider
        // Empty or invalidated items in the visibleRoomsSummaryProvider might have more details in the allRoomsSummaryProvider
        // If items are unavailable in the allRoomsSummaryProvider (hasn't be added to SS yet / cold cache) then use what's available
        for (index, summary) in visibleRoomsSummaryProvider.roomListPublisher.value.enumerated() {
            switch summary {
            case .filled(let details):
                let room = buildRoom(with: details, invalidated: false, isLoading: false)
                appendRoom(room, allRoomsProvider: false)
            case .empty, .invalidated:
                // Try getting details from the allRoomsSummaryProvider
                guard let allRoomsRoomSummary = allRoomsSummaryProvider?.roomListPublisher.value[safe: index] else {
                    if case let .invalidated(details) = summary {
                        let room = buildRoom(with: details, invalidated: true, isLoading: false)
                        appendRoom(room, allRoomsProvider: true)
                    } else {
                        rooms.append(HomeScreenRoom.placeholder())
                    }
                    continue
                }

                switch allRoomsRoomSummary {
                case .empty:
                    rooms.append(HomeScreenRoom.placeholder())
                case .filled(let details):
                    let room = buildRoom(with: details, invalidated: false, isLoading: true)
                    appendRoom(room, allRoomsProvider: true)
                case .invalidated(let details):
                    let room = buildRoom(with: details, invalidated: true, isLoading: true)
                    appendRoom(room, allRoomsProvider: true)
                }
            }
        }
        
        state.rooms = rooms
        
        MXLog.info("Finished updating rooms")
    }
    
    private func buildRoom(with details: RoomSummaryDetails, invalidated: Bool, isLoading: Bool) -> HomeScreenRoom {
        let identifier = invalidated ? "invalidated-" + details.id : details.id
        
        return HomeScreenRoom(id: identifier,
                              roomId: details.id,
                              name: details.name,
                              hasUnreads: details.unreadNotificationCount > 0,
                              timestamp: details.lastMessageFormattedTimestamp,
                              lastMessage: .init(attributedString: details.lastMessage, isLoading: isLoading),
                              avatarURL: details.avatarURL)
    }
    
    private func updateVisibleRange(_ range: Range<Int>, timelineLimit: UInt) {
        guard visibleRoomsSummaryProvider?.statePublisher.value == .live,
              !range.isEmpty else { return }
        
        guard let visibleRoomsSummaryProvider else {
            MXLog.error("Visible rooms summary provider unavailable")
            return
        }
        
        visibleRoomsSummaryProvider.updateVisibleRange(range, timelineLimit: timelineLimit)
    }
}

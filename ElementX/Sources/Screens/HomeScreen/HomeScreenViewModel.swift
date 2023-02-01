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
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
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
        
        visibleItemRangePublisher
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] range in
                guard let self else { return }
                
                guard self.state.bindings.searchQuery.isEmpty else {
                    return
                }
                
                if self.state.bindings.isScrolling {
                    self.updateVisibleRange(range, timelineLimit: SlidingSyncConstants.lastMessageTimelineLimit)
                } else {
                    self.updateVisibleRange(range, timelineLimit: SlidingSyncConstants.timelinePrecachingTimelineLimit)
                }
            }
            .store(in: &cancellables)
        
        Task {
            if case let .success(url) = await userSession.clientProxy.loadUserAvatarURL() {
                state.userAvatarURL = url
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
                guard let self else { return }
                
                let isLoadingData = state != .live && (totalCount == 0 || rooms.count != totalCount)
                let hasNoRooms = state == .live && totalCount == 0
                
                var newState = self.state.roomListMode
                if isLoadingData {
                    newState = .skeletons
                } else if hasNoRooms {
                    newState = .skeletons
                } else {
                    newState = .rooms
                }
                
                guard newState != self.state.roomListMode else {
                    return
                }
                
                self.state.roomListMode = newState
                
                MXLog.info("Received visibleRoomsSummaryProvider update, setting view room list mode to \"\(self.state.roomListMode)\"")
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
        
        // Try merging together results from both the visibleRoomsSummaryProvider and the allRoomsSummaryProvider
        // Empty or invalidated items in the visibleRoomsSummaryProvider might have more details in the allRoomsSummaryProvider
        // If items are unavailable in the allRoomsSummaryProvider (hasn't be added to SS yet / cold cache) then use what's available
        for (index, summary) in visibleRoomsSummaryProvider.roomListPublisher.value.enumerated() {
            switch summary {
            case .empty, .invalidated:
                guard let allRoomsRoomSummary = allRoomsSummaryProvider?.roomListPublisher.value[safe: index] else {
                    if case let .invalidated(details) = summary {
                        rooms.append(buildRoom(with: details, invalidated: true))
                    } else {
                        rooms.append(HomeScreenRoom.placeholder())
                    }
                    continue
                }

                switch allRoomsRoomSummary {
                case .empty:
                    rooms.append(HomeScreenRoom.placeholder())
                case .filled(let details), .invalidated(let details):
                    rooms.append(buildRoom(with: details, invalidated: false))
                }
            case .filled(let details):
                rooms.append(buildRoom(with: details, invalidated: false))
            }
        }
        
        state.rooms = rooms
        
        MXLog.info("Finished updating rooms")
    }
    
    private func buildRoom(with details: RoomSummaryDetails, invalidated: Bool) -> HomeScreenRoom {
        let identifier = invalidated ? "invalidated-" + details.id : details.id
        
        return HomeScreenRoom(id: identifier,
                              roomId: details.id,
                              name: details.name,
                              hasUnreads: details.unreadNotificationCount > 0,
                              timestamp: details.lastMessageFormattedTimestamp,
                              lastMessage: details.lastMessage,
                              avatarURL: details.avatarURL)
    }
    
    private func updateVisibleRange(_ range: Range<Int>, timelineLimit: UInt) {
        guard visibleRoomsSummaryProvider?.statePublisher.value == .live,
              !range.isEmpty else { return }
        
        guard let visibleRoomsSummaryProvider else {
            MXLog.error("Visible rooms summary provider unavailable")
            return
        }
        
        let lowerBound = max(0, range.lowerBound - Constants.slidingWindowBoundsPadding)
        let upperBound = min(Int(visibleRoomsSummaryProvider.countPublisher.value), range.upperBound + Constants.slidingWindowBoundsPadding)
        
        visibleRoomsSummaryProvider.updateVisibleRange(lowerBound..<upperBound, timelineLimit: timelineLimit)
    }
}

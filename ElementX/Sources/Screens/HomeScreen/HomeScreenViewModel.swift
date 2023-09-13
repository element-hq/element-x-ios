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
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let roomSummaryProvider: RoomSummaryProviderProtocol?
    private let inviteSummaryProvider: RoomSummaryProviderProtocol?
    
    private var visibleItemRangeObservationToken: AnyCancellable?
    private let visibleItemRangePublisher = CurrentValueSubject<(range: Range<Int>, isScrolling: Bool), Never>((0..<0, false))
    
    var callback: ((HomeScreenViewModelAction) -> Void)?
    
    init(userSession: UserSessionProtocol,
         attributedStringBuilder: AttributedStringBuilderProtocol,
         selectedRoomPublisher: CurrentValuePublisher<String?, Never>,
         appSettings: AppSettings,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.userSession = userSession
        self.attributedStringBuilder = attributedStringBuilder
        self.appSettings = appSettings
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        
        roomSummaryProvider = userSession.clientProxy.roomSummaryProvider
        inviteSummaryProvider = userSession.clientProxy.inviteSummaryProvider
        
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
        
        selectedRoomPublisher
            .weakAssign(to: \.state.selectedRoomID, on: self)
            .store(in: &cancellables)
        
        context.$viewState
            .map(\.bindings.searchQuery)
            .debounceAndRemoveDuplicates()
            .sink { [weak self] searchQuery in
                self?.roomSummaryProvider?.updateFilterPattern(searchQuery)
            }
            .store(in: &cancellables)
        
        setupRoomSummaryProviderSubscriptions()
        
        updateRooms()
    }
    
    // MARK: - Public
    
    override func process(viewAction: HomeScreenViewAction) {
        switch viewAction {
        case .selectRoom(let roomIdentifier):
            callback?(.presentRoom(roomIdentifier: roomIdentifier))
        case .showRoomDetails(roomIdentifier: let roomIdentifier):
            callback?(.presentRoomDetails(roomIdentifier: roomIdentifier))
        case .leaveRoom(roomIdentifier: let roomIdentifier):
            startLeaveRoomProcess(roomId: roomIdentifier)
        case .confirmLeaveRoom(roomIdentifier: let roomIdentifier):
            leaveRoom(roomId: roomIdentifier)
        case .userMenu(let action):
            switch action {
            case .feedback:
                callback?(.presentFeedbackScreen)
            case .settings:
                callback?(.presentSettingsScreen)
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
        case .selectInvites:
            callback?(.presentInvitesScreen)
        }
    }
    
    func presentCrashedLastRunAlert() {
        state.bindings.alertInfo = AlertInfo(id: UUID(),
                                             title: L10n.crashDetectionDialogContent(InfoPlistReader.main.bundleDisplayName),
                                             primaryButton: .init(title: L10n.actionNo, action: nil),
                                             secondaryButton: .init(title: L10n.actionYes) { [weak self] in
                                                 self?.callback?(.presentFeedbackScreen)
                                             })
    }
    
    // MARK: - Private
    
    private func setupRoomSummaryProviderSubscriptions() {
        guard let roomSummaryProvider, let inviteSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        ServiceLocator.shared.analytics.signpost.beginFirstRooms()
        
        // Combine together the state and the room list to correctly compute the view state if
        // data is present in the room list "cold cache"
        Publishers.CombineLatest(roomSummaryProvider.statePublisher,
                                 roomSummaryProvider.roomListPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, rooms in
                guard let self else { return }
                
                // Rust sends back loaded even when no rooms are loaded yet, check room for empty to be sure
                let isLoadingData = !state.isLoaded || (state.totalNumberOfRooms != 0 && rooms.isEmpty)
                
                let hasNoRooms = state.isLoaded && state.totalNumberOfRooms == 0 && rooms.isEmpty
                
                var roomListMode = self.state.roomListMode
                if isLoadingData {
                    roomListMode = .skeletons
                } else if hasNoRooms {
                    roomListMode = .empty
                } else {
                    roomListMode = .rooms
                }
                
                guard roomListMode != self.state.roomListMode else {
                    return
                }
                
                if roomListMode == .rooms, self.state.roomListMode == .skeletons {
                    ServiceLocator.shared.analytics.signpost.endFirstRooms()
                }
                
                self.state.roomListMode = roomListMode
                
                MXLog.info("Received room summary provider update, setting view room list mode to \"\(self.state.roomListMode)\"")
                
                // Delay user profile detail loading until after the initial room list loads
                if roomListMode == .rooms {
                    Task {
                        await self.userSession.clientProxy.loadUserAvatarURL()
                    }
                    
                    Task {
                        if case let .success(userDisplayName) = await self.userSession.clientProxy.loadUserDisplayName() {
                            self.state.userDisplayName = userDisplayName
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        roomSummaryProvider.roomListPublisher
            .dropFirst(1) // We don't care about its initial value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRooms()
                
                // Wait for the all rooms view to receive its first update before installing
                // dynamic timeline modifiers
                self?.installListRangeModifiers()
            }
            .store(in: &cancellables)
        
        inviteSummaryProvider.roomListPublisher
            .combineLatest(appSettings.$seenInvites)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summaries, readInvites in
                self?.state.hasPendingInvitations = !summaries.isEmpty
                self?.state.hasUnreadPendingInvitations = summaries.contains(where: {
                    guard let roomId = $0.id else {
                        return false
                    }
                    return !readInvites.contains(roomId)
                })
            }
            .store(in: &cancellables)
    }
    
    private func installListRangeModifiers() {
        guard visibleItemRangeObservationToken == nil else {
            return
        }
        
        visibleItemRangeObservationToken = visibleItemRangePublisher
            .filter { $0.isScrolling == false }
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates(by: { $0.isScrolling == $1.isScrolling && $0.range == $1.range })
            .sink { [weak self] value in
                guard let self else { return }
                
                // Ignore scrolling while filtering rooms
                guard self.state.bindings.searchQuery.isEmpty else {
                    return
                }
                
                self.updateVisibleRange(value.range)
            }
    }
        
    private func updateRooms() {
        guard let roomSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        MXLog.verbose("Updating rooms")
        
        var rooms = [HomeScreenRoom]()
        
        for summary in roomSummaryProvider.roomListPublisher.value {
            switch summary {
            case .empty:
                rooms.append(HomeScreenRoom.placeholder())
            case .invalidated(let details):
                let room = buildRoom(with: details, invalidated: true)
                rooms.append(room)
            case .filled(let details):
                let room = buildRoom(with: details, invalidated: false)
                rooms.append(room)
            }
        }
        
        state.rooms = rooms
        
        MXLog.verbose("Finished updating rooms")
    }
    
    private func buildRoom(with details: RoomSummaryDetails, invalidated: Bool) -> HomeScreenRoom {
        let identifier = invalidated ? "invalidated-" + details.id : details.id
        
        let notificationMode = details.notificationMode == .allMessages ? nil : details.notificationMode
        
        return HomeScreenRoom(id: identifier,
                              roomId: details.id,
                              name: details.name,
                              hasUnreads: details.unreadNotificationCount > 0,
                              timestamp: details.lastMessageFormattedTimestamp,
                              lastMessage: .init(attributedString: details.lastMessage, isLoading: false),
                              avatarURL: details.avatarURL,
                              notificationMode: notificationMode)
    }
    
    private func updateVisibleRange(_ range: Range<Int>) {
        guard !range.isEmpty else {
            return
        }
        
        guard let roomSummaryProvider else {
            MXLog.error("Visible rooms summary provider unavailable")
            return
        }
        
        roomSummaryProvider.updateVisibleRange(range)
    }
    
    private static let leaveRoomLoadingID = "LeaveRoomLoading"
    
    private func startLeaveRoomProcess(roomId: String) {
        Task {
            defer {
                userIndicatorController.retractIndicatorWithId(Self.leaveRoomLoadingID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: Self.leaveRoomLoadingID, type: .modal, title: L10n.commonLoading, persistent: true))
            
            let room = await userSession.clientProxy.roomForIdentifier(roomId)
            
            guard let room else {
                state.bindings.alertInfo = AlertInfo(id: UUID(), title: L10n.errorUnknown)
                return
            }
            
            if room.isPublic {
                state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(roomId: roomId, state: .public)
            } else {
                state.bindings.leaveRoomAlertItem = room.joinedMembersCount > 1 ? LeaveRoomAlertItem(roomId: roomId, state: .private) : LeaveRoomAlertItem(roomId: roomId, state: .empty)
            }
        }
    }
    
    private func leaveRoom(roomId: String) {
        Task {
            defer {
                userIndicatorController.retractIndicatorWithId(Self.leaveRoomLoadingID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: Self.leaveRoomLoadingID, type: .modal, title: L10n.commonLeavingRoom, persistent: true))
            
            let room = await userSession.clientProxy.roomForIdentifier(roomId)
            let result = await room?.leaveRoom()
            
            switch result {
            case .none, .some(.failure):
                state.bindings.alertInfo = AlertInfo(id: UUID(), title: L10n.errorUnknown)
            case .some(.success):
                userIndicatorController.submitIndicator(UserIndicator(id: UUID().uuidString,
                                                                      type: .modal(progress: .none, interactiveDismissDisabled: false, allowsInteraction: false),
                                                                      title: L10n.commonCurrentUserLeftRoom,
                                                                      iconName: "checkmark"))
                callback?(.roomLeft(roomIdentifier: roomId))
            }
        }
    }
}

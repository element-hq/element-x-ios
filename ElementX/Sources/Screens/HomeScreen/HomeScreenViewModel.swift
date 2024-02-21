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
    private let analyticsService: AnalyticsService
    private let appSettings: AppSettings
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let roomSummaryProvider: RoomSummaryProviderProtocol?
    private let inviteSummaryProvider: RoomSummaryProviderProtocol?
    
    private var migrationCancellable: AnyCancellable?
    
    private var visibleItemRangeObservationToken: AnyCancellable?
    private let visibleItemRangePublisher = CurrentValueSubject<(range: Range<Int>, isScrolling: Bool), Never>((0..<0, false))
    
    private var actionsSubject: PassthroughSubject<HomeScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<HomeScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         analyticsService: AnalyticsService,
         appSettings: AppSettings,
         selectedRoomPublisher: CurrentValuePublisher<String?, Never>,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.userSession = userSession
        self.analyticsService = analyticsService
        self.appSettings = appSettings
        self.userIndicatorController = userIndicatorController
        
        roomSummaryProvider = userSession.clientProxy.roomSummaryProvider
        inviteSummaryProvider = userSession.clientProxy.inviteSummaryProvider
        
        super.init(initialViewState: .init(userID: userSession.userID),
                   imageProvider: userSession.mediaProvider)
        
        userSession.clientProxy.userAvatarURL
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userAvatarURL, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.userDisplayName
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userDisplayName, on: self)
            .store(in: &cancellables)
        
        userSession.sessionSecurityStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] securityState in
                guard let self else { return }
                
                switch (securityState.verificationState, securityState.recoveryState) {
                case (.unverified, _):
                    state.requiresExtraAccountSetup = true
                    if state.securityBannerMode != .dismissed {
                        state.securityBannerMode = .sessionVerification
                    }
                case (.unverifiedLastSession, .incomplete):
                    state.requiresExtraAccountSetup = true
                    if state.securityBannerMode != .dismissed {
                        state.securityBannerMode = .sessionVerification
                    }
                case (.verified, .disabled):
                    state.requiresExtraAccountSetup = true
                    state.securityBannerMode = .none
                case (.verified, .incomplete):
                    state.requiresExtraAccountSetup = true
                    
                    if state.securityBannerMode != .dismissed {
                        state.securityBannerMode = .recoveryKeyConfirmation
                    }
                default:
                    state.securityBannerMode = .none
                    state.requiresExtraAccountSetup = false
                }
            }
            .store(in: &cancellables)
        
        selectedRoomPublisher
            .weakAssign(to: \.state.selectedRoomID, on: self)
            .store(in: &cancellables)
        
        appSettings.$roomListFiltersEnabled
            .sink { [weak self] value in
                guard let self else {
                    return
                }
                if !value {
                    state.shouldShowFilters = false
                    state.bindings.filtersState.clearFilters()
                } else {
                    state.shouldShowFilters = true
                }
            }
            .store(in: &cancellables)
        
        appSettings.$markAsUnreadEnabled
            .weakAssign(to: \.state.markAsUnreadEnabled, on: self)
            .store(in: &cancellables)
        
        appSettings.$markAsFavouriteEnabled
            .weakAssign(to: \.state.markAsFavouriteEnabled, on: self)
            .store(in: &cancellables)
        
        appSettings.$hideUnreadMessagesBadge
            .sink { [weak self] _ in self?.updateRooms() }
            .store(in: &cancellables)
        
        let isSearchFieldFocused = context.$viewState.map(\.bindings.isSearchFieldFocused)
        let searchQuery = context.$viewState.map(\.bindings.searchQuery)
        let activeFilters = context.$viewState.map(\.bindings.filtersState.activeFilters)
        isSearchFieldFocused
            .combineLatest(searchQuery, activeFilters)
            .removeDuplicates { $0 == $1 }
            .sink { [weak self] isSearchFieldFocused, _, _ in
                guard let self else { return }
                // isSearchFieldFocused` is sometimes turning to true after cancelling the search. So to be extra sure we are updating the values correctly we read them directly in the next run loop, and we add a small delay if the value has changed
                let delay = isSearchFieldFocused == self.context.viewState.bindings.isSearchFieldFocused ? 0.0 : 0.05
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.updateFilter()
                }
            }
            .store(in: &cancellables)
        
        setupRoomListSubscriptions()
        
        updateRooms()
    }
    
    // MARK: - Public
    
    override func process(viewAction: HomeScreenViewAction) {
        switch viewAction {
        case .selectRoom(let roomIdentifier):
            actionsSubject.send(.presentRoom(roomIdentifier: roomIdentifier))
        case .showRoomDetails(roomIdentifier: let roomIdentifier):
            actionsSubject.send(.presentRoomDetails(roomIdentifier: roomIdentifier))
        case .leaveRoom(roomIdentifier: let roomIdentifier):
            startLeaveRoomProcess(roomId: roomIdentifier)
        case .confirmLeaveRoom(roomIdentifier: let roomIdentifier):
            leaveRoom(roomId: roomIdentifier)
        case .showSettings:
            actionsSubject.send(.presentSettingsScreen)
        case .verifySession:
            actionsSubject.send(.presentSessionVerificationScreen)
        case .confirmRecoveryKey:
            actionsSubject.send(.presentSecureBackupSettings)
        case .skipSessionVerification:
            state.securityBannerMode = .dismissed
        case .skipRecoveryKeyConfirmation:
            state.securityBannerMode = .dismissed
        case .updateVisibleItemRange(let range, let isScrolling):
            visibleItemRangePublisher.send((range, isScrolling))
        case .startChat:
            actionsSubject.send(.presentStartChatScreen)
        case .selectInvites:
            actionsSubject.send(.presentInvitesScreen)
        case .globalSearch:
            actionsSubject.send(.presentGlobalSearch)
        case .markRoomAsUnread(let roomIdentifier):
            Task {
                guard let roomProxy = await userSession.clientProxy.roomForIdentifier(roomIdentifier) else {
                    MXLog.error("Failed retrieving room for identifier: \(roomIdentifier)")
                    return
                }
                
                switch await roomProxy.flagAsUnread(true) {
                case .success:
                    analyticsService.trackInteraction(name: .MobileRoomListRoomContextMenuUnreadToggle)
                case .failure(let error):
                    MXLog.error("Failed marking room \(roomIdentifier) as unread with error: \(error)")
                }
            }
        case .markRoomAsRead(let roomIdentifier):
            Task {
                guard let roomProxy = await userSession.clientProxy.roomForIdentifier(roomIdentifier) else {
                    MXLog.error("Failed retrieving room for identifier: \(roomIdentifier)")
                    return
                }
                
                switch await roomProxy.flagAsUnread(false) {
                case .success:
                    analyticsService.trackInteraction(name: .MobileRoomListRoomContextMenuUnreadToggle)
                    
                    if case .failure(let error) = await roomProxy.markAsRead(receiptType: appSettings.sharePresence ? .read : .readPrivate) {
                        MXLog.error("Failed marking room \(roomIdentifier) as read with error: \(error)")
                    }
                case .failure(let error):
                    MXLog.error("Failed flagging room \(roomIdentifier) as read with error: \(error)")
                }
            }
        case .markRoomAsFavourite(let roomIdentifier, let isFavourite):
            Task {
                await markRoomAsFavourite(roomIdentifier, isFavourite: isFavourite)
            }
        }
    }
    
    // perphery: ignore - used in release mode
    func presentCrashedLastRunAlert() {
        state.bindings.alertInfo = AlertInfo(id: UUID(),
                                             title: L10n.crashDetectionDialogContent(InfoPlistReader.main.bundleDisplayName),
                                             primaryButton: .init(title: L10n.actionNo, action: nil),
                                             secondaryButton: .init(title: L10n.actionYes) { [weak self] in
                                                 self?.actionsSubject.send(.presentFeedbackScreen)
                                             })
    }
    
    // MARK: - Private
    
    private func updateFilter() {
        if state.shouldHideRoomList {
            roomSummaryProvider?.setFilter(.excludeAll)
        } else {
            if state.bindings.isSearchFieldFocused {
                roomSummaryProvider?.setFilter(.include(.init(query: state.bindings.searchQuery,
                                                              filters: state.bindings.filtersState.activeFilters)))
            } else {
                roomSummaryProvider?.setFilter(.include(.init(filters: state.bindings.filtersState.activeFilters)))
            }
        }
    }
    
    private func setupRoomListSubscriptions() {
        guard let roomSummaryProvider, let inviteSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        analyticsService.signpost.beginFirstRooms()
        
        let hasUserBeenMigrated = appSettings.migratedAccounts[userSession.userID] == true

        if !hasUserBeenMigrated {
            state.roomListMode = .migration
            
            MXLog.info("Account not migrated, setting view room list mode to \"\(state.roomListMode)\"")
            
            migrationCancellable = userSession.clientProxy.callbacks
                .receive(on: DispatchQueue.main)
                .sink { [weak self] callback in
                    guard let self, case .receivedSyncUpdate = callback else { return }
                    migrationCancellable = nil
                    appSettings.migratedAccounts[userSession.userID] = true
                    
                    MXLog.info("Received first sync response, updating room list mode")
                    
                    updateRoomListMode(with: roomSummaryProvider.statePublisher.value)
                }
        }
        
        roomSummaryProvider.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                
                updateRoomListMode(with: state)
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
    
    private func updateRoomListMode(with roomSummaryProviderState: RoomSummaryProviderState) {
        guard appSettings.migratedAccounts[userSession.userID] == true else {
            // Ignore room summary provider updates while "migrating"
            return
        }
        
        let isLoadingData = !roomSummaryProviderState.isLoaded
        let hasNoRooms = roomSummaryProviderState.isLoaded && roomSummaryProviderState.totalNumberOfRooms == 0
        
        var roomListMode = state.roomListMode
        if isLoadingData {
            roomListMode = .skeletons
        } else if hasNoRooms {
            roomListMode = .empty
        } else {
            roomListMode = .rooms
        }
        
        guard roomListMode != state.roomListMode else {
            return
        }
        
        if roomListMode == .rooms, state.roomListMode == .skeletons {
            analyticsService.signpost.endFirstRooms()
        }
        
        state.roomListMode = roomListMode
        
        MXLog.info("Received room summary provider update, setting view room list mode to \"\(state.roomListMode)\"")
        // Delay user profile detail loading until after the initial room list loads
        if roomListMode == .rooms {
            Task {
                await self.userSession.clientProxy.loadUserAvatarURL()
                await self.userSession.clientProxy.loadUserDisplayName()
            }
        }
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
            case .filled(let details):
                let room = HomeScreenRoom(details: details, invalidated: false, hideUnreadMessagesBadge: appSettings.hideUnreadMessagesBadge)
                rooms.append(room)
            case .invalidated(let details):
                let room = HomeScreenRoom(details: details, invalidated: true, hideUnreadMessagesBadge: appSettings.hideUnreadMessagesBadge)
                rooms.append(room)
            }
        }
        
        state.rooms = rooms
        
        MXLog.verbose("Finished updating rooms")
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
    
    private func markRoomAsFavourite(_ roomID: String, isFavourite: Bool) async {
        guard let roomProxy = await userSession.clientProxy.roomForIdentifier(roomID) else {
            MXLog.error("Failed retrieving room for identifier: \(roomID)")
            return
        }
        
        switch await roomProxy.flagAsFavourite(isFavourite) {
        case .success:
            analyticsService.trackInteraction(name: .MobileRoomListRoomContextMenuFavouriteToggle)
        case .failure(let error):
            MXLog.error("Failed marking room \(roomID) as favourite: \(isFavourite) with error: \(error)")
        }
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
                state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(roomID: roomId, isDM: room.isEncryptedOneToOneRoom, state: .public)
            } else {
                state.bindings.leaveRoomAlertItem = if room.joinedMembersCount > 1 {
                    LeaveRoomAlertItem(roomID: roomId, isDM: room.isEncryptedOneToOneRoom, state: .private)
                } else {
                    LeaveRoomAlertItem(roomID: roomId, isDM: room.isEncryptedOneToOneRoom, state: .empty)
                }
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
                actionsSubject.send(.roomLeft(roomIdentifier: roomId))
            }
        }
    }
}

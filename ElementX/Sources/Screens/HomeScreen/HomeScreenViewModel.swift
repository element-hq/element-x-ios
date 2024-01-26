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
         selectedRoomPublisher: CurrentValuePublisher<String?, Never>,
         appSettings: AppSettings,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.userSession = userSession
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
        
        userSession.sessionVerificationState
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.isSessionVerified, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.secureBackupController.recoveryKeyState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recoveryKeyState in
                guard let self else { return }
                
                let requiresSecureBackupSetup = recoveryKeyState == .disabled || recoveryKeyState == .incomplete
                state.requiresSecureBackupSetup = requiresSecureBackupSetup
                
                state.needsRecoveryKeyConfirmation = recoveryKeyState == .incomplete
            }
            .store(in: &cancellables)
        
        selectedRoomPublisher
            .weakAssign(to: \.state.selectedRoomID, on: self)
            .store(in: &cancellables)
        
        appSettings.$roomListFiltersEnabled
            .weakAssign(to: \.state.shouldShowFilters, on: self)
            .store(in: &cancellables)
        
        let isSearchFieldFocused = context.$viewState.map(\.bindings.isSearchFieldFocused)
        let searchQuery = context.$viewState.map(\.bindings.searchQuery)
        isSearchFieldFocused
            .combineLatest(searchQuery)
            .removeDuplicates { $0 == $1 }
            .map { _ in () }
            .sink { [weak self] in
                guard let self else { return }
                // Don't capture the values here as combine behaves incorrectly and `isSearchFieldFocused` is sometimes
                // turning to true after cancelling the search. Read them directly from the state in the updateFilter
                // method instead on the next run loop to make sure they're up to date.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
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
        case .userMenu(let action):
            switch action {
            case .settings:
                actionsSubject.send(.presentSettingsScreen)
            case .logout:
                actionsSubject.send(.logout)
            }
        case .verifySession:
            actionsSubject.send(.presentSessionVerificationScreen)
        case .confirmRecoveryKey:
            actionsSubject.send(.presentSecureBackupSettings)
        case .skipSessionVerification:
            state.hasSessionVerificationBannerBeenDismissed = true
        case .skipRecoveryKeyConfirmation:
            state.hasRecoveryKeyConfirmationBannerBeenDismissed = true
        case .updateVisibleItemRange(let range, let isScrolling):
            visibleItemRangePublisher.send((range, isScrolling))
        case .startChat:
            actionsSubject.send(.presentStartChatScreen)
        case .selectInvites:
            actionsSubject.send(.presentInvitesScreen)
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
            roomSummaryProvider?.setFilter(.none)
        } else {
            if state.bindings.isSearchFieldFocused {
                roomSummaryProvider?.setFilter(.normalizedMatchRoomName(state.bindings.searchQuery))
            } else {
                roomSummaryProvider?.setFilter(.all)
            }
        }
    }
    
    private func setupRoomListSubscriptions() {
        guard let roomSummaryProvider, let inviteSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        ServiceLocator.shared.analytics.signpost.beginFirstRooms()
        
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
            ServiceLocator.shared.analytics.signpost.endFirstRooms()
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
        
        return HomeScreenRoom(id: identifier,
                              roomId: details.id,
                              name: details.name,
                              hasUnreadMessages: details.unreadMessagesCount > 0,
                              hasUnreadMentions: details.unreadMentionsCount > 0,
                              hasUnreadNotifications: details.unreadNotificationsCount > 0,
                              hasOngoingCall: details.hasOngoingCall,
                              timestamp: details.lastMessageFormattedTimestamp,
                              lastMessage: details.lastMessage,
                              avatarURL: details.avatarURL,
                              notificationMode: details.notificationMode)
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
                state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(roomId: roomId, isDM: room.isEncryptedOneToOneRoom, state: .public)
            } else {
                state.bindings.leaveRoomAlertItem = if room.joinedMembersCount > 1 {
                    LeaveRoomAlertItem(roomId: roomId, isDM: room.isEncryptedOneToOneRoom, state: .private)
                } else {
                    LeaveRoomAlertItem(roomId: roomId, isDM: room.isEncryptedOneToOneRoom, state: .empty)
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

//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents
import Combine
import MatrixRustSDK
import SwiftUI

typealias HomeScreenViewModelType = StateStoreViewModel<HomeScreenViewState, HomeScreenViewAction>

class HomeScreenViewModel: HomeScreenViewModelType, HomeScreenViewModelProtocol {
    private let userSession: UserSessionProtocol
    private let analyticsService: AnalyticsService
    private let appSettings: AppSettings
    private let notificationManager: NotificationManagerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let roomSummaryProvider: RoomSummaryProviderProtocol?
    
    private var actionsSubject: PassthroughSubject<HomeScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<HomeScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         selectedRoomPublisher: CurrentValuePublisher<String?, Never>,
         appSettings: AppSettings,
         analyticsService: AnalyticsService,
         notificationManager: NotificationManagerProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.userSession = userSession
        self.analyticsService = analyticsService
        self.appSettings = appSettings
        self.notificationManager = notificationManager
        self.userIndicatorController = userIndicatorController
        
        roomSummaryProvider = userSession.clientProxy.roomSummaryProvider
        
        super.init(initialViewState: .init(userID: userSession.clientProxy.userID, isNewBloomEnabled: appSettings.isNewBloomEnabled),
                   mediaProvider: userSession.mediaProvider)
        
        userSession.clientProxy.userAvatarURLPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userAvatarURL, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.userDisplayNamePublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userDisplayName, on: self)
            .store(in: &cancellables)
        
        userSession.sessionSecurityStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] securityState in
                guard let self else { return }
                
                switch securityState.recoveryState {
                case .disabled:
                    state.requiresExtraAccountSetup = true
                    if !state.securityBannerMode.isDismissed {
                        state.securityBannerMode = .show(.setUpRecovery)
                    }
                case .incomplete:
                    state.requiresExtraAccountSetup = true
                    state.securityBannerMode = .show(.recoveryOutOfSync)
                default:
                    state.securityBannerMode = .none
                    state.requiresExtraAccountSetup = false
                }
            }
            .store(in: &cancellables)
        
        userSession.sessionSecurityStatePublisher
            .receive(on: DispatchQueue.main)
            .filter { state in
                state.verificationState != .unknown
                    && state.recoveryState != .settingUp
                    && state.recoveryState != .unknown
            }
            .sink { [weak self] state in
                guard let self else { return }
                
                self.analyticsService.updateUserProperties(AnalyticsEvent.newVerificationStateUserProperty(verificationState: state.verificationState, recoveryState: state.recoveryState))
                self.analyticsService.trackSessionSecurityState(state)
            }
            .store(in: &cancellables)
        
        selectedRoomPublisher
            .weakAssign(to: \.state.selectedRoomID, on: self)
            .store(in: &cancellables)
        
        appSettings.$hideUnreadMessagesBadge
            .sink { [weak self] _ in self?.updateRooms() }
            .store(in: &cancellables)
        
        appSettings.$seenInvites
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateRooms()
            }
            .store(in: &cancellables)
        
        userSession.clientProxy.hideInviteAvatarsPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.hideInviteAvatars, on: self)
            .store(in: &cancellables)
        
        Task {
            state.reportRoomEnabled = await userSession.clientProxy.isReportRoomSupported
        }
        
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
        
        Task {
            await checkSlidingSyncMigration()
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: HomeScreenViewAction) {
        switch viewAction {
        case .selectRoom(let roomIdentifier):
            actionsSubject.send(.presentRoom(roomIdentifier: roomIdentifier))
        case .showRoomDetails(let roomIdentifier):
            actionsSubject.send(.presentRoomDetails(roomIdentifier: roomIdentifier))
        case .leaveRoom(let roomIdentifier):
            startLeaveRoomProcess(roomID: roomIdentifier)
        case .confirmLeaveRoom(let roomIdentifier):
            Task { await leaveRoom(roomID: roomIdentifier) }
        case .reportRoom(let roomIdentifier):
            actionsSubject.send(.presentReportRoom(roomIdentifier: roomIdentifier))
        case .showSettings:
            actionsSubject.send(.presentSettingsScreen)
        case .setupRecovery:
            actionsSubject.send(.presentSecureBackupSettings)
        case .confirmRecoveryKey:
            actionsSubject.send(.presentRecoveryKeyScreen)
        case .resetEncryption:
            actionsSubject.send(.presentEncryptionResetScreen)
        case .skipRecoveryKeyConfirmation:
            state.securityBannerMode = .dismissed
        case .updateVisibleItemRange(let range):
            roomSummaryProvider?.updateVisibleRange(range)
        case .startChat:
            actionsSubject.send(.presentStartChatScreen)
        case .globalSearch:
            actionsSubject.send(.presentGlobalSearch)
        case .markRoomAsUnread(let roomIdentifier):
            Task {
                guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomIdentifier) else {
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
                guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomIdentifier) else {
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
        case .acceptInvite(let roomIdentifier):
            Task {
                await acceptInvite(roomID: roomIdentifier)
            }
        case .declineInvite(let roomIdentifier):
            Task { await showDeclineInviteConfirmationAlert(roomID: roomIdentifier) }
        }
    }
    
    // perphery: ignore - used in release mode
    func presentCrashedLastRunAlert() {
        // Delay setting the alert otherwise it automatically gets dismissed. Same as the force logout one.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.state.bindings.alertInfo = AlertInfo(id: UUID(),
                                                      title: L10n.crashDetectionDialogContent(InfoPlistReader.main.bundleDisplayName),
                                                      primaryButton: .init(title: L10n.actionNo, action: nil),
                                                      secondaryButton: .init(title: L10n.actionYes) { [weak self] in
                                                          self?.actionsSubject.send(.presentFeedbackScreen)
                                                      })
        }
    }
    
    // MARK: - Private
    
    private func updateFilter() {
        if state.shouldHideRoomList {
            roomSummaryProvider?.setFilter(.excludeAll)
        } else {
            if state.bindings.isSearchFieldFocused {
                roomSummaryProvider?.setFilter(.search(query: state.bindings.searchQuery))
            } else {
                roomSummaryProvider?.setFilter(.all(filters: state.bindings.filtersState.activeFilters.set))
            }
        }
    }
    
    private func setupRoomListSubscriptions() {
        guard let roomSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        analyticsService.signpost.beginFirstRooms()
                
        roomSummaryProvider.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                
                updateRoomListMode(with: state)
            }
            .store(in: &cancellables)
        
        roomSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRooms()
            }
            .store(in: &cancellables)
    }
    
    private func updateRoomListMode(with roomSummaryProviderState: RoomSummaryProviderState) {
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
        
    private func updateRooms() {
        guard let roomSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        var rooms = [HomeScreenRoom]()
        let seenInvites = appSettings.seenInvites
        
        for summary in roomSummaryProvider.roomListPublisher.value {
            let room = HomeScreenRoom(summary: summary,
                                      hideUnreadMessagesBadge: appSettings.hideUnreadMessagesBadge,
                                      seenInvites: seenInvites)
            rooms.append(room)
        }
        
        state.rooms = rooms
    }
    
    /// Check whether we can inform the user about potential migrations
    /// or have him logout as his proxy is no longer available
    private func checkSlidingSyncMigration() async {
        guard userSession.clientProxy.needsSlidingSyncMigration else {
            return
        }
        
        // The proxy is no longer supported so a logout is needed.
        // Delay setting the alert otherwise it automatically gets dismissed. Same as the crashed last run one
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.state.bindings.alertInfo = AlertInfo(id: UUID(),
                                                      title: L10n.bannerMigrateToNativeSlidingSyncAppForceLogoutTitle(InfoPlistReader.main.bundleDisplayName),
                                                      primaryButton: .init(title: L10n.bannerMigrateToNativeSlidingSyncAction) { [weak self] in
                                                          self?.actionsSubject.send(.logoutWithoutConfirmation)
                                                      })
        }
    }
    
    private func markRoomAsFavourite(_ roomID: String, isFavourite: Bool) async {
        guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
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
    
    private func startLeaveRoomProcess(roomID: String) {
        Task {
            defer {
                userIndicatorController.retractIndicatorWithId(Self.leaveRoomLoadingID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: Self.leaveRoomLoadingID, type: .modal, title: L10n.commonLoading, persistent: true))
            
            guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
                state.bindings.alertInfo = AlertInfo(id: UUID(), title: L10n.errorUnknown)
                return
            }
            
            if roomProxy.infoPublisher.value.isPublic {
                state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(roomID: roomID, isDM: roomProxy.isDirectOneToOneRoom, state: .public)
            } else {
                state.bindings.leaveRoomAlertItem = if roomProxy.infoPublisher.value.joinedMembersCount > 1 {
                    LeaveRoomAlertItem(roomID: roomID, isDM: roomProxy.isDirectOneToOneRoom, state: .private)
                } else {
                    LeaveRoomAlertItem(roomID: roomID, isDM: roomProxy.isDirectOneToOneRoom, state: .empty)
                }
            }
        }
    }
    
    private func leaveRoom(roomID: String) async {
        defer {
            userIndicatorController.retractIndicatorWithId(Self.leaveRoomLoadingID)
        }
        userIndicatorController.submitIndicator(UserIndicator(id: Self.leaveRoomLoadingID, type: .modal, title: L10n.commonLeavingRoom, persistent: true))
        
        guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID),
              case .success = await roomProxy.leaveRoom() else {
            state.bindings.alertInfo = AlertInfo(id: UUID(), title: L10n.errorUnknown)
            return
        }
        
        userIndicatorController.submitIndicator(UserIndicator(id: UUID().uuidString,
                                                              type: .toast,
                                                              title: L10n.commonCurrentUserLeftRoom,
                                                              iconName: "checkmark"))
        actionsSubject.send(.roomLeft(roomIdentifier: roomID))
    }
    
    // MARK: Invites
    
    private func acceptInvite(roomID: String) async {
        defer {
            userIndicatorController.retractIndicatorWithId(roomID)
        }
        
        userIndicatorController.submitIndicator(UserIndicator(id: roomID, type: .modal, title: L10n.commonLoading, persistent: true))
        
        guard case let .invited(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
            displayError()
            return
        }
        
        switch await userSession.clientProxy.joinRoom(roomID, via: []) {
        case .success:
            actionsSubject.send(.presentRoom(roomIdentifier: roomID))
            analyticsService.trackJoinedRoom(isDM: roomProxy.info.isDirect,
                                             isSpace: roomProxy.info.isSpace,
                                             activeMemberCount: UInt(roomProxy.info.activeMembersCount))
            appSettings.seenInvites.remove(roomID)
        case .failure(let error):
            switch error {
            case .invalidInvite:
                displayError(title: L10n.dialogTitleError, message: L10n.errorInvalidInvite)
            default:
                displayError()
            }
        }
    }
    
    private func showDeclineInviteConfirmationAlert(roomID: String) async {
        guard let room = state.rooms.first(where: { $0.id == roomID }) else {
            displayError()
            return
        }
        
        let roomPlaceholder = room.isDirect ? (room.inviter?.displayName ?? room.name) : room.name
        let title = room.isDirect ? L10n.screenInvitesDeclineDirectChatTitle : L10n.screenInvitesDeclineChatTitle
        let message = room.isDirect ? L10n.screenInvitesDeclineDirectChatMessage(roomPlaceholder) : L10n.screenInvitesDeclineChatMessage(roomPlaceholder)
        
        if await userSession.clientProxy.isReportRoomSupported, let userID = room.inviter?.id {
            state.bindings.alertInfo = .init(id: UUID(),
                                             title: title,
                                             message: message,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                             secondaryButton: .init(title: L10n.actionDeclineAndBlock, role: .destructive) { [weak self] in self?.declineAndBlockInvite(userID: userID, roomID: roomID) },
                                             verticalButtons: [.init(title: L10n.actionDecline) { [weak self] in Task { await self?.declineInvite(roomID: room.id) } }])
        } else {
            state.bindings.alertInfo = .init(id: UUID(),
                                             title: title,
                                             message: message,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                             secondaryButton: .init(title: L10n.actionDecline, role: .destructive) { [weak self] in Task { await self?.declineInvite(roomID: room.id) } })
        }
    }
    
    private func declineAndBlockInvite(userID: String, roomID: String) {
        actionsSubject.send(.presentDeclineAndBlock(userID: userID, roomID: roomID))
    }
    
    private func declineInvite(roomID: String) async {
        defer {
            userIndicatorController.retractIndicatorWithId(roomID)
        }
        
        userIndicatorController.submitIndicator(UserIndicator(id: roomID, type: .modal, title: L10n.commonLoading, persistent: true))
        
        guard case let .invited(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
            displayError()
            return
        }
        
        let result = await roomProxy.rejectInvitation()
        
        switch result {
        case .success:
            await notificationManager.removeDeliveredMessageNotifications(for: roomID) // Normally handled by the room flow, but that's never presented in this case.
            appSettings.seenInvites.remove(roomID)
        case .failure:
            displayError()
        }
    }
    
    private func displayError(title: String? = nil, message: String? = nil) {
        state.bindings.alertInfo = .init(id: UUID(),
                                         title: title ?? L10n.commonError,
                                         message: message ?? L10n.errorUnknown)
    }
}

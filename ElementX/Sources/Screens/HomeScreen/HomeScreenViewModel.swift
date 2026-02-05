//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents
import Combine
import MatrixRustSDK
import SwiftUI

typealias HomeScreenViewModelType = StateStoreViewModel<HomeScreenViewState, HomeScreenViewAction>

class HomeScreenViewModel: HomeScreenViewModelType, HomeScreenViewModelProtocol {
    private let userSession: UserSessionProtocol
    private let spaceFilterSubject: CurrentValueSubject<SpaceServiceFilter?, Never>
    private let analyticsService: AnalyticsService
    private let appSettings: AppSettings
    private let notificationManager: NotificationManagerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let roomSummaryProvider: RoomSummaryProviderProtocol?
    
    private var actionsSubject: PassthroughSubject<HomeScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<HomeScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    // swiftlint:disable:next function_body_length
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
        
        spaceFilterSubject = CurrentValueSubject<SpaceServiceFilter?, Never>(nil)
        
        roomSummaryProvider = userSession.clientProxy.roomSummaryProvider
        
        super.init(initialViewState: .init(userID: userSession.clientProxy.userID,
                                           spaceFiltersEnabled: appSettings.spaceFiltersEnabled,
                                           bindings: .init(filtersState: .init(appSettings: appSettings))),
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
        
        userSession.clientProxy.spaceService.spaceFilterPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] filters in
                guard let self else { return }
                
                state.shouldShowSpaceFilters = !filters.isEmpty
                
                if let selectedSpaceFilter = spaceFilterSubject.value,
                   !filters.contains(selectedSpaceFilter) {
                    // Clear the spaces filter if the space has been left.
                    spaceFilterSubject.send(nil)
                }
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
        
        appSettings.$hasSeenNewSoundBanner
            .sink { [weak self] hasSeenNewSoundBanner in
                self?.state.shouldShowNewSoundBanner = !hasSeenNewSoundBanner
            }
            .store(in: &cancellables)
        
        appSettings.$spaceFiltersEnabled
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.spaceFiltersEnabled, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.hideInviteAvatarsPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.hideInviteAvatars, on: self)
            .store(in: &cancellables)
        
        spaceFilterSubject
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.selectedSpaceFilter, on: self)
            .store(in: &cancellables)
        
        Task {
            state.reportRoomEnabled = await userSession.clientProxy.isReportRoomSupported
        }
        
        let isSearchFieldFocused = context.$viewState.map(\.bindings.isSearchFieldFocused)
        let searchQuery = context.$viewState.map(\.bindings.searchQuery)
        let activeFilters = context.$viewState.map(\.bindings.filtersState.activeFilters)
        isSearchFieldFocused
            .combineLatest(searchQuery, activeFilters, spaceFilterSubject)
            .removeDuplicates { $0 == $1 }
            .sink { [weak self] isSearchFieldFocused, _, _, _ in
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
        case .dismissNewSoundBanner:
            appSettings.hasSeenNewSoundBanner = true
        case .updateVisibleItemRange(let range):
            roomSummaryProvider?.updateVisibleRange(range)
        case .startChat:
            actionsSubject.send(.presentStartChatScreen)
        case .globalSearch:
            actionsSubject.send(.presentGlobalSearch)
        case .spaceFilters:
            if spaceFilterSubject.value != nil {
                spaceFilterSubject.send(nil)
            } else {
                state.bindings.spaceFiltersViewModel = ChatsSpaceFiltersScreenViewModel(spaceService: userSession.clientProxy.spaceService,
                                                                                        mediaProvider: userSession.mediaProvider)
                
                state.bindings.spaceFiltersViewModel?.actionsPublisher.sink { [weak self] action in
                    guard let self else { return }
                    
                    switch action {
                    case .confirm(let spaceServiceFilter):
                        spaceFilterSubject.send(spaceServiceFilter)
                        state.bindings.spaceFiltersViewModel = nil
                    case .cancel:
                        state.bindings.spaceFiltersViewModel = nil
                    }
                }
                .store(in: &cancellables)
            }
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
                if let spaceFilter = spaceFilterSubject.value {
                    roomSummaryProvider?.setFilter(.rooms(roomsIDs: spaceFilter.descendants,
                                                          filters: state.bindings.filtersState.activeFilters.set))
                } else {
                    roomSummaryProvider?.setFilter(.all(filters: state.bindings.filtersState.activeFilters.set))
                }
            }
        }
    }
    
    private func setupRoomListSubscriptions() {
        guard let roomSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
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
            analyticsService.signpost.finishTransaction(.cachedRoomList)
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
            
            guard roomProxy.infoPublisher.value.joinedMembersCount > 1 else {
                state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(roomID: roomID,
                                                                       isDM: roomProxy.isDirectOneToOneRoom,
                                                                       state: roomProxy.infoPublisher.value.isPrivate ?? true ? .empty : .public)
                return
            }
            
            if !roomProxy.isDirectOneToOneRoom {
                if case let .success(ownMember) = await roomProxy.getMember(userID: roomProxy.ownUserID),
                   ownMember.role.isOwner {
                    await roomProxy.updateMembers()
                    var isLastOwner = true
                    for member in roomProxy.membersPublisher.value where member.userID != roomProxy.ownUserID && member.membership == .join {
                        if member.role.isOwner {
                            isLastOwner = false
                            break
                        }
                    }
                    
                    if isLastOwner {
                        state.bindings.alertInfo = .init(id: UUID(),
                                                         title: L10n.leaveRoomAlertSelectNewOwnerTitle,
                                                         message: L10n.leaveRoomAlertSelectNewOwnerSubtitle,
                                                         primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                                         secondaryButton: .init(title: L10n.leaveRoomAlertSelectNewOwnerAction, role: .destructive) { [weak self] in
                                                             self?.actionsSubject.send(.transferOwnership(roomIdentifier: roomID))
                                                         })
                        return
                    }
                }
            }
            
            state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(roomID: roomID, isDM: roomProxy.isDirectOneToOneRoom, state: roomProxy.infoPublisher.value.isPrivate ?? true ? .private : .public)
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
            await finishAcceptInvite(roomProxy: roomProxy)
        case .failure(let error):
            switch error {
            case .invalidInvite:
                displayError(title: L10n.dialogTitleError, message: L10n.errorInvalidInvite)
            default:
                displayError()
            }
        }
    }
    
    private func finishAcceptInvite(roomProxy: InvitedRoomProxyProtocol) async {
        if roomProxy.info.isSpace {
            let spaceService = userSession.clientProxy.spaceService
            
            switch await spaceService.spaceRoomList(spaceID: roomProxy.id) {
            case .success(let spaceRoomListProxy):
                actionsSubject.send(.presentSpace(spaceRoomListProxy))
            case .failure(let error):
                MXLog.error("Failed to get the space room list after accepting invite: \(error)")
                displayError()
                return
            }
        } else {
            actionsSubject.send(.presentRoom(roomIdentifier: roomProxy.id))
        }
        
        analyticsService.trackJoinedRoom(isDM: roomProxy.info.isDirect,
                                         isSpace: roomProxy.info.isSpace,
                                         activeMemberCount: UInt(roomProxy.info.activeMembersCount))
        appSettings.seenInvites.remove(roomProxy.id)
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

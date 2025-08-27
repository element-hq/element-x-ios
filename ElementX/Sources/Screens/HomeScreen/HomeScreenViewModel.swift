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
import Kingfisher

typealias HomeScreenViewModelType = StateStoreViewModel<HomeScreenViewState, HomeScreenViewAction>

protocol RoomNotificationModeUpdatedProtocol {
    func onRoomNotificationModeUpdated(for roomId: String, mode: RoomNotificationModeProxy)
}

class HomeScreenViewModel: HomeScreenViewModelType, HomeScreenViewModelProtocol,
                           FeedProtocol, RoomNotificationModeUpdatedProtocol,
                           WalletTransactionProtocol, UserRewardsProtocol {
    private let userSession: UserSessionProtocol
    private let analyticsService: AnalyticsService
    private let appSettings: AppSettings
    private let notificationManager: NotificationManagerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let mediaProvider: MediaProviderProtocol
    
    private let roomSummaryProvider: RoomSummaryProviderProtocol?
    
    private var actionsSubject: PassthroughSubject<HomeScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<HomeScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private let HOME_SCREEN_POST_PAGE_COUNT = 10
    private var isFetchPostsInProgress = false
    
    private var channelRoomMap: [String: RoomInfoProxy] = [:]
    private var roomNotificationUpdateMap: [String: RoomNotificationModeProxy] = [:]
    
    private var feedMediaPreFetchService: FeedMediaPreFetchService? = nil
    
    private var isRoomUsersExtractionInProgress: Bool = false
    private var isRoomAutoJoinInProgress: Bool = false
    
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
        self.mediaProvider = userSession.mediaProvider
        
        roomSummaryProvider = userSession.clientProxy.roomSummaryProvider
        
        super.init(initialViewState: .init(userID: userSession.clientProxy.userID,
                                           bindings: .init(filtersState: .init(appSettings: appSettings))),
                   mediaProvider: userSession.mediaProvider)
        
        self.feedMediaPreFetchService = FeedMediaPreFetchService(mediaProtocol: .init(onMediaLoaded: { map in
            self.state.postMediaInfoMap = map
        }),
                                                                 clientProxy: userSession.clientProxy,
                                                                 loadInitialPosts: true)
        
        userSession.clientProxy.userAvatarURLPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userAvatarURL, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.userDisplayNamePublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userDisplayName, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.zeroCurrentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
                
                ZeroCustomEventService.shared.setup(userId: currentUser.id.rawValue, userName: currentUser.displayName)
                
                self?.state.currentUserZeroProfile = currentUser
                if ZeroFlaggedFeaturesService.shared.zeroWalletEnabled() {
                    self?.fetchWalletData()
                }
            }
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
        
        userSession.clientProxy.userRewardsPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userRewards, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.showNewUserRewardsIntimationPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.showNewUserRewardsIntimation, on: self)
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
        
        userSession.clientProxy.homeRoomSummariesUsersPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] users in
                self?.mapDirectChatUsersProBadgeStatus(users)
            }
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
        
        fetchZeroHomeScreenData()
        
    }
    
    // MARK: - Public
    
    override func process(viewAction: HomeScreenViewAction) {
        switch viewAction {
        case .onHomeTabChanged:
            onHomeTabChanged()
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
            actionsSubject.send(.presentSettingsScreen(userRewardsProtocol: self))
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
        case .newFeed:
            actionsSubject.send(.presentCreateFeedScreen(feedProtocol: self))
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
        case .loadRewards:
            loadUserRewards()
            checkAndUpdateRoomNotificationMode()
        case .rewardsIntimated:
            dismissNewRewardsIntimation()
        case .loadMoreAllPosts(let following):
            Task {
                await fetchPosts(followingOnly: following)
            }
        case .forceRefreshAllPosts(let followingOnly):
            Task {
                await fetchPosts(isForceRefresh: true, followingOnly: followingOnly)
            }
        case .loadMoreMyPosts, .forceRefreshMyPosts:
            break
        case .postTapped(let post):
            let mediaUrl = state.postMediaInfoMap[post.id]?.url
            let urlLinkPreview = state.postLinkPreviewsMap[post.id]
            actionsSubject.send(.postTapped(post.withUpdatedData(url: mediaUrl, urlLinkPreview: urlLinkPreview), feedProtocol: self))
        case .openArweaveLink(let post):
            openArweaveLink(post)
        case .addMeowToPost(let postId, let amount):
            addMeowToPost(postId, amount)
        case .forceRefreshChannels:
            Task { await fetchChannels(isForceRefresh: true) }
        case .channelTapped(let channel):
            joinZeroChannel(channel)
        case .openYoutubeLink(let url):
            openYoutubeLink(url)
        case .openPostUserProfile(let profile):
            actionsSubject.send(.openPostUserProfile(profile, feedProtocol: self))
        case .openUserProfile:
            let profile = ZPostUserProfile(userId: state.userID.matrixIdToCleanHex(),
                                           firstName: state.userDisplayName ?? "",
                                           profileImage: state.userAvatarURL?.absoluteString,
                                           primaryZid: state.currentUserZeroProfile?.primaryZID,
                                           publicAddress: state.currentUserZeroProfile?.publicWalletAddress,
                                           followersCount: state.currentUserZeroProfile?.followersCount,
                                           followingCount: state.currentUserZeroProfile?.followingCount,
                                           isZeroProSubscriber: state.currentUserZeroProfile?.subscriptions.zeroPro ?? false)
            actionsSubject.send(.openPostUserProfile(profile, feedProtocol: self))
        case .setNotificationFilter(let tab):
            applyCustomFilterToNotificationsList(tab)
        case .openMediaPreview(let mediaId, let key):
            displayFullScreenMedia(mediaId, key: key)
        case .toggleWalletBalance(let show):
            state.showWalletBalance = show
        case .loadMoreWalletTokens:
            loadMoreWalletTokenBalances()
        case .loadMoreWalletTransactions:
            loadMoreWalletTransactions()
        case .loadMoreWalletNFTs:
            loadMoreWalletNFTs()
        case .startWalletTransaction(let type):
            actionsSubject.send(.startWalletTransaction(self, type, state.meowPrice))
        case .reloadFeedMedia(let post):
            reloadFeedMedia(post)
        case .viewTransactionDetails(let walletTransactionId):
            viewWalletTransactionDetails(walletTransactionId)
        case .claimRewards(let trigger):
            if trigger {
                claimUserRewards()
            } else {
                state.claimRewardsState = .none
                state.bindings.showEarningsClaimedSheet = false
            }
        case .onStakePoolSelected(let stakePool):
            fetchStakeDataOfPool(stakePool)
        case .claimStakeRewards:
            claimStakeRewards()
        case .stakeAmount(let amount):
            stakeAmount(amount)
        case .unstakeAmount(let amount):
            unstakeAmount(amount)
        case .refreshWalletData:
            fetchWalletData()
        case .searchUser:
            actionsSubject.send(.searchUser)
        }
    }
    
    private func onHomeTabChanged() {
        Task.detached {
            await self.fetchPosts(isForceRefresh: true)
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
        userSession.clientProxy.setRoomNotificationModeProtocol(self)
        
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
        
        let matrixRoomSummaries = roomSummaryProvider.roomListPublisher.value
        for summary in matrixRoomSummaries {
            let room = HomeScreenRoom(summary: summary,
                                      hideUnreadMessagesBadge: appSettings.hideUnreadMessagesBadge,
                                      seenInvites: seenInvites)
            rooms.append(room)
        }
        
        // In case the list is updated through filters and there is `.room` filter applied, we need to filter out channels
        let activeFilters = state.bindings.filtersState.activeFilters
        if activeFilters.contains(.rooms) {
            rooms = rooms.filter { !$0.isAChannel }
        }
        
        state.rooms = rooms.uniqued(on: { $0.id })
        
        applyCustomFilterToNotificationsList(.all)
        extractAllRoomUsers(matrixRoomSummaries)
        autoJoinInvitedRooms(matrixRoomSummaries)
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
                    for member in roomProxy.membersPublisher.value where member.userID != roomProxy.ownUserID {
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
        
        //        guard case let .invited(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
        //            displayError()
        //            return
        //        }
        
        switch await userSession.clientProxy.joinRoom(roomID, via: []) {
        case .success:
            actionsSubject.send(.presentRoom(roomIdentifier: roomID))
            //            analyticsService.trackJoinedRoom(isDM: roomProxy.info.isDirect,
            //                                             isSpace: roomProxy.info.isSpace,
            //                                             activeMemberCount: UInt(roomProxy.info.activeMembersCount))
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
        //        let result = await userSession.clientProxy.leaveRoom(roomID)
        
        if case .failure = result {
            displayError()
        } else {
            await notificationManager.removeDeliveredMessageNotifications(for: roomID) // Normally handled by the room flow, but that's never presented in this case.
            appSettings.seenInvites.remove(roomID)
        }
    }
    
    private func displayError(title: String? = nil, message: String? = nil) {
        state.bindings.alertInfo = .init(id: UUID(),
                                         title: title ?? L10n.commonError,
                                         message: message ?? L10n.errorUnknown)
    }
    
    private func loadUserRewards() {
        Task.detached {
            try await Task.sleep(for: .seconds(2))
            _ = await self.userSession.clientProxy.getUserRewards(shouldCheckRewardsIntiamtion: true)
        }
    }
    
    private func dismissNewRewardsIntimation() {
        Task {
            try await Task.sleep(for: .seconds(4))
            state.showNewUserRewardsIntimation = false
        }
    }
    
    private func fetchZeroHomeScreenData() {
        Task {
            async let checkUser: () = userSession.clientProxy.checkAndLinkZeroUser()
            async let channels: () = fetchChannels()
//            async let posts: () = fetchPosts()
            _ = await (checkUser, channels)
        }
    }
    
    private func checkAndLinkZeroUser() async {
        await userSession.clientProxy.checkAndLinkZeroUser()
    }
    
    private func fetchPosts(isForceRefresh: Bool = false, followingOnly: Bool = true) async {
        guard !isFetchPostsInProgress else { return }
        isFetchPostsInProgress = true
        
//        defer { isFetchPostsInProgress = false } // Ensure flag is reset when the task completes
        
        if isForceRefresh {
            state.canLoadMorePosts = true
        }
        
        state.postListMode = state.posts.isEmpty ? .skeletons : .posts
        let skipItems = isForceRefresh ? 0 : state.posts.count
        let postsResult = await userSession.clientProxy.fetchZeroFeeds(channelZId: nil,
                                                                       following: followingOnly,
                                                                       limit: HOME_SCREEN_POST_PAGE_COUNT,
                                                                       skip: skipItems)
        switch postsResult {
        case .success(let posts):
            let hasNoPosts = posts.isEmpty
            if hasNoPosts {
                state.postListMode = state.posts.isEmpty ? .empty : .posts
                state.canLoadMorePosts = false
            } else {
                var homePosts: [HomeScreenPost] = isForceRefresh ? [] : state.posts
                for post in posts {
                    let homePost = HomeScreenPost(loggedInUserId: userSession.clientProxy.userID,
                                                  post: post,
                                                  rewardsDecimalPlaces: state.userRewards.decimals)
                    homePosts.append(homePost)
                }
                state.posts = homePosts.uniqued(on: \.id)
                state.postListMode = .posts
                isFetchPostsInProgress = false
                
                if isForceRefresh {
                    self.feedMediaPreFetchService?.forceRefreshHomeFeedMedia(following: followingOnly)
                }
                
                await loadPostContentConcurrently(for: state.posts, followingPosts: followingOnly)
            }
        case .failure(let error):
            MXLog.error("Failed to fetch zero posts: \(error)")
            state.postListMode = state.posts.isEmpty ? .empty : .posts
            switch error {
            case .postsLimitReached:
                state.canLoadMorePosts = false
            default:
                displayError()
            }
            isFetchPostsInProgress = false
        }
    }
    
    private func updatePostsVisibleRange(_ range: Range<Int>) {
        print("Update Posts Visible Range: Upper bound: \(range.upperBound), Lower bound: \(range.lowerBound)")
    }
    
    private func openArweaveLink(_ post: HomeScreenPost) {
        guard let arweaveUrl = post.getArweaveLink() else { return }
        UIApplication.shared.open(arweaveUrl)
    }
    
    private func openYoutubeLink(_ url: String) {
        guard let youtubeUrl = URL(string: url) else { return }
        UIApplication.shared.open(youtubeUrl)
    }
    
    private func addMeowToPost(_ postId: String, _ amount: Int) {
        Task {
            let addMeowResult = await userSession.clientProxy.addMeowsToFeed(feedId: postId, amount: amount)
            switch addMeowResult {
            case .success(let post):
                let homePost = HomeScreenPost(loggedInUserId: userSession.clientProxy.userID,
                                              post: post,
                                              rewardsDecimalPlaces: state.userRewards.decimals)
                if let index = state.posts.firstIndex(where: { $0.id == homePost.id }) {
                    state.posts[index] = homePost
                }
            case .failure(let error):
                MXLog.error("Failed to add meow: \(error)")
                displayError()
            }
        }
    }
    
    private func fetchChannels(isForceRefresh: Bool = false) async {
        state.channelsListMode = .skeletons
        let channelsResult = await userSession.clientProxy.fetchUserZIds()
        switch channelsResult {
        case .success(let zIds):
            if zIds.isEmpty {
                state.channelsListMode = .empty
            } else {
                let mappedChannels = zIds.sorted().map { HomeScreenChannel(channelZId: $0) }
                state.channels = mappedChannels.uniqued(on: \.id)
                state.channelsListMode = .channels
                mapChannelsToRoomInfo()
            }
        case .failure(let error):
            state.channelsListMode = .empty
            MXLog.error("Failed to fetch channels: \(error)")
            displayError()
        }
    }
    
    private func joinZeroChannel(_ channel: HomeScreenChannel) {
        if let channelRoom = channelRoomMap[channel.id] {
            actionsSubject.send(.presentRoom(roomIdentifier: channelRoom.id))
            markChannelRead(channel)
            return
        }
        
        Task {
            let userIndicatorID = UUID().uuidString
            defer {
                userIndicatorController.retractIndicatorWithId(userIndicatorID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID,
                                                                  type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                                  title: L10n.commonLoading,
                                                                  persistent: true))
            let roomAliasResult = await userSession.clientProxy.resolveRoomAlias(channel.id)
            switch roomAliasResult {
            case .success(let roomInfo):
                actionsSubject.send(.presentRoom(roomIdentifier: roomInfo.roomId))
                markChannelRead(channel)
                getRoomInfoFromAlias(channel.id)
            case .failure(let error):
                MXLog.error("Failed to resolve room alias: \(channel.id). Error: \(error)")
                let joinChannelResult = await userSession.clientProxy.joinChannel(roomAliasOrId: channel.id)
                switch joinChannelResult {
                case .success(let roomId):
                    actionsSubject.send(.presentRoom(roomIdentifier: roomId))
                    markChannelRead(channel)
                    getRoomInfoFromAlias(channel.id)
                case .failure(let failure):
                    MXLog.error("Failed to join channel: \(failure)")
                    displayError()
                }
            }
        }
    }
    
    private func getRoomInfoFromAlias(_ alias: String) {
        Task {
            if let roomInfo = await userSession.clientProxy.roomInfoForAlias(alias) {
                channelRoomMap[alias] = roomInfo
            }
        }
    }
    
    private func mapChannelsToRoomInfo() {
        Task {
            state.channels = await state.channels.asyncMap { homeChannel in
                var updatedChannel = homeChannel
                if let roomInfo = await self.userSession.clientProxy.roomInfoForAlias(homeChannel.id) {
                    self.channelRoomMap[homeChannel.id] = roomInfo
                    updatedChannel.notificationsCount = roomInfo.unreadMessagesCount
                }
                return updatedChannel
            }
        }
    }
    
    private func markChannelRead(_ channel: HomeScreenChannel) {
        var mChannel = channel
        mChannel.notificationsCount = 0
        if let index = state.channels.firstIndex(where: { $0.id == channel.id }) {
            state.channels[index] = mChannel
        }
    }
    
    private func checkAndUpdateRoomNotificationMode() {
        roomNotificationUpdateMap.forEach { roomId, mode in
            guard let roomSummary = state.rooms.first(where: { $0.roomID == roomId }) else { return }
            var mRoomSummary = roomSummary
            mRoomSummary.badges.isMuteShown = mode == .mute
            if let index = state.rooms.firstIndex(where: { $0.roomID == roomId }) {
                state.rooms[index] = mRoomSummary
            }
        }
        roomNotificationUpdateMap.removeAll()
    }
    
    private func loadPostContentConcurrently(for posts: [HomeScreenPost], followingPosts: Bool) async {
        async let nextPagePostsTask: () =  feedMediaPreFetchService?.loadHomePostsPage(following: followingPosts,
                                                                                       currentCount: posts.count) ?? ()
        async let linkPreviewTask: () = loadPostLinkPreviews(for: posts)
        _ = await (nextPagePostsTask, linkPreviewTask)
    }
    
    private func reloadFeedMedia(_ post: HomeScreenPost) {
        feedMediaPreFetchService?.reloadMedia(post) { mediaInfo in
            self.state.postMediaInfoMap[post.id] = mediaInfo
        }
    }
    
    private func loadPostLinkPreviews(for posts: [HomeScreenPost]) async {
        let postsToFetchLinkPreviews = posts.filter({
            LinkPreviewUtil.shared.firstAvailableYoutubeLink(from: $0.postText) != nil && state.postLinkPreviewsMap[$0.id] == nil
        })
        await withTaskGroup(of: (String, ZLinkPreview)?.self) { group in
            for post in postsToFetchLinkPreviews {
                guard let url = LinkPreviewUtil.shared.firstAvailableYoutubeLink(from: post.postText) else { continue }
                group.addTask {
                    if let previewResult = await withTimeout(seconds: 5, operation: {
                        await self.userSession.clientProxy.fetchYoutubeLinkMetaData(youtubrUrl: url)
                    }), case let .success(preview) = previewResult {
                        return (post.id, preview)
                    }
                    return nil
                }
            }
            for await item in group {
                guard let (postId, preview) = item else { continue }
                state.postLinkPreviewsMap[postId] = preview
            }
        }
    }
    
    private func applyCustomFilterToNotificationsList(_ tab: HomeNotificationsTab) {
        let filteredNotificationContent = state.visibleRooms.filter {
            switch $0.type {
            case .placeholder, .knock:
                return false
            default:
                switch tab {
                case .all:
                    return $0.badges.isDotShown
                case .highlighted:
                    return $0.badges.isMentionShown
                case .muted:
                    return $0.badges.isDotShown && $0.badges.isMuteShown
                }
            }
        }
        state.notificationsContent = filteredNotificationContent
    }
    
    private func displayFullScreenMedia(_ mediaId: String, key: String) {
        let loadingIndicatorIdentifier = "roomAvatarLoadingIndicator"
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
        
        Task {
            defer {
                userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier)
            }
            
            do {
                if case let .success(localUrl) = try await userSession.clientProxy.loadFileFromMediaId(mediaId, key: key) {
                    state.bindings.mediaPreviewItem = localUrl
                }
            } catch {
                MXLog.error("Failed to preview feed media: \(error)")
            }
        }
    }
    
    private func fetchWalletData(silentRefresh: Bool = false) {
        if let walletAddress = state.currentUserZeroProfile?.publicWalletAddress {
            state.walletContentListMode = silentRefresh ? state.walletContentListMode : .skeletons
            Task {
                async let meowPrice = userSession.clientProxy.getZeroMeowPrice()
                async let tokens = userSession.clientProxy.getWalletTokenBalances(walletAddress: walletAddress, nextPage: nil)
                async let transactions = userSession.clientProxy.getWalletTransactions(walletAddress: walletAddress, nextPage: nil)
                //                async let nfts = userSession.clientProxy.getWalletNFTs(walletAddress: walletAddress, nextPage: nil)
                
                let results = await (meowPrice, tokens, transactions)
                if case .success(let meowPrice) = results.0 {
                    state.meowPrice = meowPrice
                }
                if case .success(let walletTokenBalances) = results.1 {
                    var homeWalletContent: [HomeScreenWalletContent] = []
                    // set meow token balance amount for user
                    setUserWalletBalance(walletTokenBalances.tokens)
                    for token in walletTokenBalances.tokens {
                        let content = HomeScreenWalletContent(walletToken: token, meowPrice: state.meowPrice)
                        homeWalletContent.append(content)
                    }
                    state.walletTokens = homeWalletContent.uniqued(on: \.id)
                    state.walletTokenNextPageParams = walletTokenBalances.nextPageParams
                    
                    // fetch stake data
                    fetchStakingData(userWalletAddress: walletAddress, refreshAllData: silentRefresh)
                }
//                if case .success(let walletNFTs) = results.1 {
//                    var homeWalletContent: [HomeScreenWalletContent] = []
//                    for nft in walletNFTs.nfts {
//                        let content = HomeScreenWalletContent(walletNFT: nft)
//                        homeWalletContent.append(content)
//                    }
//                    state.walletNFTs = homeWalletContent.uniqued(on: \.id)
//                    state.walletNFTsNextPageParams = walletNFTs.nextPageParams
//                }
                if case .success(let walletTransactions) = results.2 {
                    var homeWalletContent: [HomeScreenWalletContent] = []
                    for transaction in walletTransactions.transactions {
                        let content = HomeScreenWalletContent(walletTransaction: transaction, meowPrice: state.meowPrice)
                        homeWalletContent.append(content)
                    }
                    state.walletTransactions = homeWalletContent.uniqued(on: \.id)
                    state.walletTransactionsNextPageParams = walletTransactions.nextPageParams
                }
                state.walletContentListMode = .content
            }
        }
    }
    
    private func loadMoreWalletTokenBalances() {
        if let nextPageParams = state.walletTokenNextPageParams,
           let walletAddress = state.currentUserZeroProfile?.publicWalletAddress {
            Task {
                let result = await userSession.clientProxy.getWalletTokenBalances(walletAddress: walletAddress, nextPage: nextPageParams)
                if case .success(let walletTokenBalances) = result {
                    var homeWalletContent: [HomeScreenWalletContent] = state.walletTokens
                    for token in walletTokenBalances.tokens {
                        let content = HomeScreenWalletContent(walletToken: token, meowPrice: state.meowPrice)
                        homeWalletContent.append(content)
                    }
                    state.walletTokens = homeWalletContent.uniqued(on: \.id)
                    state.walletTokenNextPageParams = walletTokenBalances.nextPageParams
                }
            }
        }
    }
    
    private func loadMoreWalletNFTs() {
        if let nextPageParams = state.walletTokenNextPageParams,
           let walletAddress = state.currentUserZeroProfile?.publicWalletAddress {
            Task {
                let result = await userSession.clientProxy.getWalletNFTs(walletAddress: walletAddress, nextPage: nextPageParams)
                if case .success(let walletNFTs) = result {
                    var homeWalletContent: [HomeScreenWalletContent] = state.walletNFTs
                    for nft in walletNFTs.nfts {
                        let content = HomeScreenWalletContent(walletNFT: nft)
                        homeWalletContent.append(content)
                    }
                    state.walletNFTs = homeWalletContent.uniqued(on: \.id)
                    state.walletNFTsNextPageParams = walletNFTs.nextPageParams
                }
            }
        }
    }
    
    private func loadMoreWalletTransactions() {
        if let nextPageParams = state.walletTransactionsNextPageParams,
           let walletAddress = state.currentUserZeroProfile?.publicWalletAddress {
            Task {
                let result = await userSession.clientProxy.getWalletTransactions(walletAddress: walletAddress, nextPage: nextPageParams)
                if case .success(let walletTransactions) = result {
                    var homeWalletContent: [HomeScreenWalletContent] = state.walletTransactions
                    for transaction in walletTransactions.transactions {
                        let content = HomeScreenWalletContent(walletTransaction: transaction, meowPrice: state.meowPrice)
                        homeWalletContent.append(content)
                    }
                    state.walletTransactions = homeWalletContent.uniqued(on: \.id)
                    state.walletTransactionsNextPageParams = walletTransactions.nextPageParams
                }
            }
        }
    }
    
    private func setUserWalletBalance(_ tokens: [ZWalletToken]) {
        let totalAmount = tokens.filter { $0.isClaimableToken }
            .reduce(Decimal(0)) { partialResult, token in
                guard let amountDecimal = Decimal(string: token.amount) else {
                    return partialResult
                }
                return partialResult + amountDecimal
            }
        state.walletBalance = ZeroWalletUtil.shared.meowPrice(tokenAmount: totalAmount.description, refPrice: state.meowPrice)
    }
    
    private func viewWalletTransactionDetails(_ walletTransactionId: String) {
        Task {
            let userIndicatorID = UUID().uuidString
            defer {
                userIndicatorController.retractIndicatorWithId(userIndicatorID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID,
                                                                  type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                                  title: L10n.commonLoading,
                                                                  persistent: true))
            if case .success(let receipt) = await userSession.clientProxy.getTransactionReceipt(transactionHash: walletTransactionId),
               let link = URL(string: receipt.blockExplorerUrl) {
                await UIApplication.shared.open(link)
            }
        }
    }
    
    private func fetchStakingData(userWalletAddress: String, refreshAllData: Bool = false) {
        let poolAddress = ZeroContants.ZERO_WALLET_MEOW_POOL_ADDRESS
        Task.detached {
            async let totalStaked = self.userSession.clientProxy.getTotalStaked(poolAddress: poolAddress)
            async let config = self.userSession.clientProxy.getStakingConfig(poolAddress: poolAddress)
            async let stakerStatus = self.userSession.clientProxy.getStakerStatusInfo(userWalletAddress: userWalletAddress,
                                                                                      poolAddress: poolAddress)
            async let stakeRewards = self.userSession.clientProxy.getStakeRewardsInfo(userWalletAddress: userWalletAddress,
                                                                                      poolAddress: poolAddress)
            let results = await (totalStaked, config, stakerStatus, stakeRewards)
            await MainActor.run {
                if case .success(let totalStaked) = results.0,
                   case .success(let stakingConfig) = results.1,
                   case .success(let stakerStatus) = results.2,
                   case .success(let stakeRewards) = results.3 {
                    let pool = HomeScreenWalletStakingContent(meowPrice: self.state.meowPrice, userWalletAddress: userWalletAddress,
                                                              poolAddress: poolAddress, totalStaked: totalStaked, stakingConfig: stakingConfig,
                                                              stakerStatus: stakerStatus, stakeRewards: stakeRewards)
                    self.state.walletStakings = [pool]
                    if refreshAllData {
                        self.fetchStakeDataOfPool(pool, silentRefresh: refreshAllData)
                    }
                }
            }
        }
    }
    
    private func fetchStakeDataOfPool(_ pool: HomeScreenWalletStakingContent, silentRefresh: Bool = false) {
        Task {
            let userIndicatorID = UUID().uuidString
            if !silentRefresh {
                userIndicatorController.submitIndicator(
                    UserIndicator(
                        id: userIndicatorID,
                        type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                        title: L10n.commonLoading,
                        persistent: true
                    )
                )
            }
            
            func fetchTokenData(tokenAddress: String) async -> (ZWalletTokenInfo?, ZWalletTokenBalance?) {
                async let tokenInfo = userSession.clientProxy.getTokenInfo(tokenAddress: tokenAddress)
                async let tokenBalance = userSession.clientProxy.getTokenBalance(userWalletAddress: pool.userWalletAddress,
                                                                                 tokenAddress: tokenAddress)
                return (try? await tokenInfo.get(), try? await tokenBalance.get())
            }
            
            async let stakingTokenResult = userSession.clientProxy.getStakingToken(poolAddress: pool.poolAddress)
            async let rewardTokenResult = userSession.clientProxy.getRewardsToken(poolAddress: pool.poolAddress)
            
            var stakeTokenInfo: ZWalletTokenInfo?
            var stakeTokenBalance: ZWalletTokenBalance?
            var rewardTokenInfo: ZWalletTokenInfo?
            var rewardTokenBalance: ZWalletTokenBalance?
            
            let (stakingTokenResponse, rewardTokenResponse) = await (stakingTokenResult, rewardTokenResult)
            if case .success(let stakingToken) = stakingTokenResponse {
                (stakeTokenInfo, stakeTokenBalance) = await fetchTokenData(tokenAddress: stakingToken.stakingTokenAddress)
            }
            if case .success(let rewardsToken) = rewardTokenResponse {
                (rewardTokenInfo, rewardTokenBalance) = await fetchTokenData(tokenAddress: rewardsToken.rewardsTokenAddress)
            }
            state.selectedStakePool = .init(
                pool: pool,
                stakeToken: stakeTokenInfo,
                stakeTokenBalance: stakeTokenBalance,
                rewardToken: rewardTokenInfo,
                rewardTokenBalance: rewardTokenBalance
            )
            userIndicatorController.retractIndicatorWithId(userIndicatorID)
            if !silentRefresh {
                state.bindings.stakePoolViewState = .details
                state.bindings.showStakePoolSheet = true
            }
        }
    }
    
    private func claimStakeRewards() {
        guard let selectedPool = state.selectedStakePool else { return }
        Task {
            let userIndicatorID = UUID().uuidString
            defer {
                userIndicatorController.retractIndicatorWithId(userIndicatorID)
            }
            userIndicatorController.submitIndicator(
                UserIndicator(
                    id: userIndicatorID,
                    type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                    title: L10n.commonLoading,
                    persistent: true
                )
            )
            let result = await userSession.clientProxy.claimStakeRewards(walletAddress: selectedPool.pool.userWalletAddress,
                                                                         poolAddress: selectedPool.pool.poolAddress)
            switch result {
            case .success(_):
                try? await Task.sleep(for: .seconds(1))
                fetchStakingData(userWalletAddress: selectedPool.pool.userWalletAddress, refreshAllData: true)
            case .failure(let error):
                displayError(message: error.localizedDescription)
            }
        }
    }
    
    private func stakeAmount(_ amount: String) {
        guard let selectedPool = state.selectedStakePool else { return }
        guard let token = selectedPool.stakeToken else { return }
        let stakeAmount = Double(amount) ?? 0
        guard stakeAmount > 0 else { return }
        
        let actualStakeAmount = toSmallestUnit(amount: stakeAmount, decimals: token.decimals)
        
        Task {
            state.bindings.stakePoolViewState = .inProgress
            let result = await userSession.clientProxy.stakeAmount(walletAddress: selectedPool.pool.userWalletAddress,
                                                                   poolAddress: selectedPool.pool.poolAddress,
                                                                   tokenAddress: token.address,
                                                                   amount: actualStakeAmount)
            switch result {
            case .success(_):
                state.bindings.stakePoolViewState = .success
                fetchWalletData(silentRefresh: true)
                fetchStakeDataOfPool(selectedPool.pool, silentRefresh: true)
            case .failure(let error):
                state.bindings.stakePoolViewState = .failure
            }
        }
    }
    
    private func unstakeAmount(_ amount: String) {
        guard let selectedPool = state.selectedStakePool else { return }
        guard let token = selectedPool.stakeToken else { return }
        let unstakeAmount = Double(amount) ?? 0
        guard unstakeAmount > 0 else { return }
        
        let actualUnstakeAmount = toSmallestUnit(amount: unstakeAmount, decimals: token.decimals)
        
        Task {
            state.bindings.stakePoolViewState = .inProgress
            let result = await userSession.clientProxy.unstakeAmount(walletAddress: selectedPool.pool.userWalletAddress,
                                                                   poolAddress: selectedPool.pool.poolAddress,
                                                                   amount: actualUnstakeAmount)
            switch result {
            case .success(_):
                state.bindings.stakePoolViewState = .success
                fetchWalletData(silentRefresh: true)
            case .failure(let error):
                state.bindings.stakePoolViewState = .failure
            }
        }
    }
    
    private func toSmallestUnit(amount: Double, decimals: Int) -> String {
        let decimalValue = Decimal(amount) * pow(Decimal(10), decimals)
        return NSDecimalNumber(decimal: decimalValue).stringValue
    }
    
    private func extractAllRoomUsers(_ rooms: [RoomSummary]) {
        if !isRoomUsersExtractionInProgress {
            isRoomUsersExtractionInProgress = true
            ZeroCustomEventService.shared.logEvent("HOME", category: "SCREEN", parameters: [
                "request_type": "load_room_users",
                "status": "in_progress",
            ])
            Task.detached {
                let heroUserIds = rooms.flatMap { $0.heroes.compactMap(\.userID) }
                var userIds = Set(heroUserIds)
                // Add current logged-in user as well
                await userIds.insert(self.userSession.clientProxy.userID)
                
                await self.userSession.clientProxy.zeroProfiles(userIds: userIds)
            }
        }
    }
    
    private func autoJoinInvitedRooms(_ rooms: [RoomSummary]) {
        if !isRoomAutoJoinInProgress {
            isRoomAutoJoinInProgress = true
            Task.detached {
                let roomsToBeJoined = rooms.compactMap { roomSummary in
                    if case .invited = roomSummary.room.membership() {
                        roomSummary.id
                    } else {
                        nil
                    }
                }
                if !roomsToBeJoined.isEmpty {
                    await withTaskGroup(of: Result<Void, ClientProxyError>.self) { group in
                        for roomId in roomsToBeJoined {
                            group.addTask {
                                await self.userSession.clientProxy.joinRoom(roomId, via: [])
                            }
                        }
                        for await item in group {
                            if case .success = item { MXLog.debug("Successfully joined room") }
                            else { MXLog.debug("Failed to join room") }
                        }
                        await MainActor.run { self.isRoomAutoJoinInProgress = false }
                    }
                } else {
                    await MainActor.run { self.isRoomAutoJoinInProgress = false }
                }
            }
        }
    }
    
    private func mapDirectChatUsersProBadgeStatus(_ zeroProfiles: [ZMatrixUser]) {
        guard let roomSummaryProvider else {
            isRoomUsersExtractionInProgress = false
            return
        }
        guard !zeroProfiles.isEmpty else {
            isRoomUsersExtractionInProgress = false
            return
        }
        let currentUserId = userSession.clientProxy.userID
        Task.detached {
            let directChatRooms = roomSummaryProvider.roomListPublisher.value.filter(\.isDirectOneToOneRoom)
            let userStatusMap: [String: Bool] = directChatRooms.reduce(into: [:]) { result, room in
                let directUser = if let hero = room.heroes.first, hero.userID != currentUserId {
                    zeroProfiles.first { $0.matrixId == hero.userID }
                } else {
                    zeroProfiles.first {
                        $0.displayName.caseInsensitiveCompare(room.name) == .orderedSame ||
                        $0.id.rawValue.caseInsensitiveCompare(room.name) == .orderedSame
                    }
                }
                if let user = directUser {
                    result[room.id] = user.subscriptions?.zeroPro ?? false
                }
            }

            await MainActor.run {
                self.isRoomUsersExtractionInProgress = false
                self.state.directRoomsUserStatusMap = userStatusMap
            }
        }
    }
    
    // MARK: Zero Protcol Functions
    
    func onFeedUpdated(_ feedId: String) {
        Task {
            let feedDetailsResult = await userSession.clientProxy.fetchFeedDetails(feedId: feedId)
            switch feedDetailsResult {
            case .success(let post):
                let homePost = HomeScreenPost(loggedInUserId: userSession.clientProxy.userID,
                                              post: post,
                                              rewardsDecimalPlaces: state.userRewards.decimals)
                if let index = state.posts.firstIndex(where: { $0.id == homePost.id }) {
                    state.posts[index] = homePost
                }
            case .failure(let error):
                MXLog.error("Failed to fetch updated feed details: \(error)")
            }
        }
    }
    
    func onNewFeedPosted() {
        Task {
            await (fetchPosts(isForceRefresh: true))
        }
    }
    
    func onRoomNotificationModeUpdated(for roomId: String, mode: RoomNotificationModeProxy) {
        roomNotificationUpdateMap[roomId] = mode
    }
    
    func onTransactionCompleted() {
        fetchWalletData(silentRefresh: true)
    }
    
    func claimUserRewards() {
        if let walletAddress = state.currentUserZeroProfile?.publicWalletAddress {
            state.claimRewardsState = .claiming
            state.bindings.showEarningsClaimedSheet = true
            state.claimableUserRewards = state.userRewards
            Task {
                let result = await userSession.clientProxy.claimRewards(userWalletAddress: walletAddress)
                switch result {
                case .success(let transactionHash):
                    state.claimRewardsState = .success(transactionHash)
                    loadUserRewards()
                    try? await Task.sleep(for: .seconds(1))
                    fetchWalletData(silentRefresh: true)
                case .failure(_):
                    state.claimRewardsState = .failure
                }
            }
        }
    }
}

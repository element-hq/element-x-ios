//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomDetailsScreenViewModelType = StateStoreViewModel<RoomDetailsScreenViewState, RoomDetailsScreenViewAction>

class RoomDetailsScreenViewModel: RoomDetailsScreenViewModelType, RoomDetailsScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let clientProxy: ClientProxyProtocol
    private let analyticsService: AnalyticsService
    private let mediaProvider: MediaProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let notificationSettingsProxy: NotificationSettingsProxyProtocol
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    private let appSettings: AppSettings

    private var dmRecipient: RoomMemberProxyProtocol?
    private var pinnedEventsTimelineProvider: RoomTimelineProviderProtocol? {
        didSet {
            guard let pinnedEventsTimelineProvider else {
                return
            }
            
            state.pinnedEventsActionState = .loaded(numberOfItems: pinnedEventsTimelineProvider.itemProxies.filter(\.isEvent).count)
            
            pinnedEventsTimelineProvider.updatePublisher
                // When pinning or unpinning an item, the timeline might return empty for a short while, so we need to debounce it to prevent weird UI behaviours like the banner disappearing
                .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
                .sink { [weak self] updatedItems, _ in
                    self?.state.pinnedEventsActionState = .loaded(numberOfItems: updatedItems.filter(\.isEvent).count)
                }
                .store(in: &cancellables)
        }
    }
    
    private var actionsSubject: PassthroughSubject<RoomDetailsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<RoomDetailsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomProxy: JoinedRoomProxyProtocol,
         clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         analyticsService: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol,
         notificationSettingsProxy: NotificationSettingsProxyProtocol,
         attributedStringBuilder: AttributedStringBuilderProtocol,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings) {
        self.roomProxy = roomProxy
        self.clientProxy = clientProxy
        self.mediaProvider = mediaProvider
        self.analyticsService = analyticsService
        self.userIndicatorController = userIndicatorController
        self.notificationSettingsProxy = notificationSettingsProxy
        self.attributedStringBuilder = attributedStringBuilder
        self.appSettings = appSettings
        
        let topic = attributedStringBuilder.fromPlain(roomProxy.infoPublisher.value.topic)
        
        super.init(initialViewState: .init(details: roomProxy.details,
                                           isEncrypted: roomProxy.isEncrypted,
                                           isDirect: roomProxy.infoPublisher.value.isDirect,
                                           topic: topic,
                                           topicSummary: topic?.unattributedStringByReplacingNewlinesWithSpaces(),
                                           joinedMembersCount: roomProxy.infoPublisher.value.joinedMembersCount,
                                           notificationSettingsState: .loading,
                                           bindings: .init()),
                   mediaProvider: mediaProvider)
        
        appSettings.$knockingEnabled
            .weakAssign(to: \.state.knockingEnabled, on: self)
            .store(in: &cancellables)
        
        appMediator.networkMonitor.reachabilityPublisher
            .filter { $0 == .reachable }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupPinnedEventsTimelineProviderIfNeeded()
            }
            .store(in: &cancellables)
        
        Task {
            let userID = roomProxy.ownUserID
            if case let .success(permission) = await roomProxy.canUserJoinCall(userID: userID) {
                state.canJoinCall = permission
            }
        }
        
        Task {
            if case let .success(permalinkURL) = await roomProxy.matrixToPermalink() {
                state.permalink = permalinkURL
            }
        }
        
        updateRoomInfo(roomProxy.infoPublisher.value)
        Task { await updatePowerLevelPermissions() }
                
        setupRoomSubscription()
        Task { await fetchMembersIfNeeded() }
        
        setupNotificationSettingsSubscription()
        fetchNotificationSettings()
    }
    
    // MARK: - Public
    
    func stop() {
        // Work around QLPreviewController dismissal issues, see the InteractiveQuickLookModifier.
        state.bindings.mediaPreviewItem = nil
    }
    
    override func process(viewAction: RoomDetailsScreenViewAction) {
        switch viewAction {
        case .processTapPeople:
            actionsSubject.send(.requestMemberDetailsPresentation)
        case .processTapInvite:
            actionsSubject.send(.requestInvitePeoplePresentation)
        case .processTapLeave:
            guard state.joinedMembersCount > 1 else {
                state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(roomID: roomProxy.id, isDM: roomProxy.isDirectOneToOneRoom, state: .empty)
                return
            }
            state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(roomID: roomProxy.id,
                                                                   isDM: roomProxy.isDirectOneToOneRoom,
                                                                   state: roomProxy.infoPublisher.value.isPublic ? .public : .private)
        case .confirmLeave:
            Task { await leaveRoom() }
        case .processTapIgnore:
            state.bindings.ignoreUserRoomAlertItem = .init(action: .ignore)
        case .processTapUnignore:
            state.bindings.ignoreUserRoomAlertItem = .init(action: .unignore)
        case .processTapEdit, .processTapAddTopic:
            actionsSubject.send(.requestEditDetailsPresentation)
        case .ignoreConfirmed:
            Task { await ignore() }
        case .unignoreConfirmed:
            Task { await unignore() }
        case .processTapNotifications:
            if state.notificationSettingsState.isError {
                fetchNotificationSettings()
            } else {
                actionsSubject.send(.requestNotificationSettingsPresentation)
            }
        case .processToggleMuteNotifications:
            Task { await toggleMuteNotifications() }
        case .displayAvatar(let url):
            displayFullScreenAvatar(url)
        case .processTapPolls:
            actionsSubject.send(.requestPollsHistoryPresentation)
        case .toggleFavourite(let isFavourite):
            Task { await toggleFavourite(isFavourite) }
        case .processTapRolesAndPermissions:
            actionsSubject.send(.requestRolesAndPermissionsPresentation)
        case .processTapCall:
            actionsSubject.send(.startCall)
        case .processTapPinnedEvents:
            analyticsService.trackInteraction(name: .PinnedMessageRoomInfoButton)
            actionsSubject.send(.displayPinnedEventsTimeline)
        case .processTapMediaEvents:
            actionsSubject.send(.displayMediaEventsTimeline)
        case .processTapRequestsToJoin:
            actionsSubject.send(.displayKnockingRequests)
        case .processTapSecurityAndPrivacy:
            actionsSubject.send(.displaySecurityAndPrivacy)
        }
    }
    
    // MARK: - Private
    
    private func setupRoomSubscription() {
        roomProxy.infoPublisher
            .throttle(for: .milliseconds(200), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] roomInfo in
                self?.updateRoomInfo(roomInfo)
                Task { await self?.updatePowerLevelPermissions() }
            }
            .store(in: &cancellables)
        
        roomProxy.knockRequestsStatePublisher
            .map { requestsState in
                guard case let .loaded(requests) = requestsState else {
                    return 0
                }
                return requests.count
            }
            .removeDuplicates()
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .weakAssign(to: \.state.knockRequestsCount, on: self)
            .store(in: &cancellables)
    }
    
    private func updateRoomInfo(_ roomInfo: RoomInfoProxy) {
        state.details = roomProxy.details
        
        let topic = attributedStringBuilder.fromPlain(roomInfo.topic)
        state.topic = topic
        state.topicSummary = topic?.unattributedStringByReplacingNewlinesWithSpaces()
        state.joinedMembersCount = roomInfo.joinedMembersCount
        state.bindings.isFavourite = roomInfo.isFavourite
        switch roomInfo.joinRule {
        case .knock, .knockRestricted:
            state.isKnockableRoom = true
        default:
            state.isKnockableRoom = false
        }
    }
    
    private func fetchMembersIfNeeded() async {
        // We need to fetch members just in 1-to-1 chat to get the member object for the other person
        guard roomProxy.isDirectOneToOneRoom else {
            return
        }
        
        roomProxy.membersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self, ownUserID = roomProxy.ownUserID] members in
                guard let self else { return }
                let accountOwner = members.first { $0.userID == ownUserID }
                let dmRecipient = members.first { $0.userID != ownUserID }
                self.dmRecipient = dmRecipient
                self.state.dmRecipient = dmRecipient.map(RoomMemberDetails.init(withProxy:))
                self.state.accountOwner = accountOwner.map(RoomMemberDetails.init(withProxy:))
            }
            .store(in: &cancellables)
        
        await roomProxy.updateMembers()
    }
    
    private func updatePowerLevelPermissions() async {
        state.canEditRoomName = await (try? roomProxy.canUser(userID: roomProxy.ownUserID, sendStateEvent: .roomName).get()) == true
        state.canEditRoomTopic = await (try? roomProxy.canUser(userID: roomProxy.ownUserID, sendStateEvent: .roomTopic).get()) == true
        state.canEditRoomAvatar = await (try? roomProxy.canUser(userID: roomProxy.ownUserID, sendStateEvent: .roomAvatar).get()) == true
        state.canEditRolesOrPermissions = await (try? roomProxy.suggestedRole(for: roomProxy.ownUserID).get()) == .administrator
        state.canInviteUsers = await (try? roomProxy.canUserInvite(userID: roomProxy.ownUserID).get()) == true
        state.canKickUsers = await (try? roomProxy.canUserKick(userID: roomProxy.ownUserID).get()) == true
        state.canBanUsers = await (try? roomProxy.canUserBan(userID: roomProxy.ownUserID).get()) == true
    }
    
    private func setupNotificationSettingsSubscription() {
        notificationSettingsProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                
                switch callback {
                case .settingsDidChange:
                    self.fetchNotificationSettings()
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchNotificationSettings() {
        Task {
            await fetchRoomNotificationSettings()
        }
    }
    
    private func fetchRoomNotificationSettings() async {
        do {
            let notificationMode = try await notificationSettingsProxy.getNotificationSettings(roomId: roomProxy.id,
                                                                                               isEncrypted: roomProxy.isEncrypted,
                                                                                               isOneToOne: roomProxy.infoPublisher.value.activeMembersCount == 2)
            state.notificationSettingsState = .loaded(settings: notificationMode)
        } catch {
            state.notificationSettingsState = .error
            state.bindings.alertInfo = AlertInfo(id: .alert,
                                                 title: L10n.commonError,
                                                 message: L10n.screenRoomDetailsErrorLoadingNotificationSettings)
        }
    }
    
    private func toggleMuteNotifications() async {
        guard case .loaded(let notificationMode) = state.notificationSettingsState else { return }
        state.isProcessingMuteToggleAction = true
        switch notificationMode.mode {
        case .mute:
            do {
                try await notificationSettingsProxy.unmuteRoom(roomId: roomProxy.id,
                                                               isEncrypted: roomProxy.isEncrypted,
                                                               isOneToOne: roomProxy.infoPublisher.value.activeMembersCount == 2)
            } catch {
                state.bindings.alertInfo = AlertInfo(id: .alert,
                                                     title: L10n.commonError,
                                                     message: L10n.screenRoomDetailsErrorUnmuting)
            }
        default:
            do {
                try await notificationSettingsProxy.setNotificationMode(roomId: roomProxy.id, mode: .mute)
            } catch {
                state.bindings.alertInfo = AlertInfo(id: .alert,
                                                     title: L10n.commonError,
                                                     message: L10n.screenRoomDetailsErrorMuting)
            }
        }
        state.isProcessingMuteToggleAction = false
    }
    
    private func toggleFavourite(_ isFavourite: Bool) async {
        if case let .failure(error) = await roomProxy.flagAsFavourite(isFavourite) {
            MXLog.error("Failed flagging room as favourite with error: \(error)")
            state.bindings.isFavourite = !isFavourite
        } else {
            analyticsService.trackInteraction(name: .MobileRoomFavouriteToggle)
        }
    }

    private static let leaveRoomLoadingID = "LeaveRoomLoading"

    private func leaveRoom() async {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.leaveRoomLoadingID, type: .modal, title: L10n.commonLeavingRoom, persistent: true))
        let result = await roomProxy.leaveRoom()
        userIndicatorController.retractIndicatorWithId(Self.leaveRoomLoadingID)
        switch result {
        case .failure:
            state.bindings.alertInfo = AlertInfo(id: .unknown)
        case .success:
            actionsSubject.send(.leftRoom)
        }
    }

    private func ignore() async {
        guard let dmUserID = dmRecipient?.userID else {
            MXLog.error("Attempting to ignore a nil DM Recipient")
            state.bindings.alertInfo = .init(id: .unknown)
            return
        }
        
        state.isProcessingIgnoreRequest = true
        let result = await clientProxy.ignoreUser(dmUserID)
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            // Mutating the optional in place when built for Release crashes 🤷‍♂️
            var dmRecipient = state.dmRecipient
            dmRecipient?.isIgnored = true
            state.dmRecipient = dmRecipient
        case .failure:
            state.bindings.alertInfo = .init(id: .unknown)
        }
    }

    private func unignore() async {
        guard let dmUserID = dmRecipient?.userID else {
            MXLog.error("Attempting to unignore a nil DM Recipient")
            state.bindings.alertInfo = .init(id: .unknown)
            return
        }
        
        state.isProcessingIgnoreRequest = true
        let result = await clientProxy.unignoreUser(dmUserID)
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            // Mutating the optional in place when built for Release crashes 🤷‍♂️
            var dmRecipient = state.dmRecipient
            dmRecipient?.isIgnored = false
            state.dmRecipient = dmRecipient
        case .failure:
            state.bindings.alertInfo = .init(id: .unknown)
        }
    }
    
    private func displayFullScreenAvatar(_ url: URL) {
        let loadingIndicatorIdentifier = "roomAvatarLoadingIndicator"
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
        
        Task {
            defer {
                userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier)
            }
            
            // We don't actually know the mime type here, assume it's an image.
            if let mediaSource = try? MediaSourceProxy(url: url, mimeType: "image/jpeg"),
               case let .success(file) = await mediaProvider.loadFileFromSource(mediaSource) {
                state.bindings.mediaPreviewItem = MediaPreviewItem(file: file, title: roomProxy.infoPublisher.value.displayName)
            }
        }
    }
    
    private func setupPinnedEventsTimelineProviderIfNeeded() {
        guard pinnedEventsTimelineProvider == nil else {
            return
        }
        
        Task {
            guard let timelineProvider = await roomProxy.pinnedEventsTimeline?.timelineProvider else {
                return
            }
            
            if pinnedEventsTimelineProvider == nil {
                pinnedEventsTimelineProvider = timelineProvider
            }
        }
    }
}

private extension AttributedString {
    /// Returns a new string without attributes and in which newlines are replaced with spaces
    func unattributedStringByReplacingNewlinesWithSpaces() -> AttributedString {
        AttributedString(characters.map { $0.isNewline ? " " : $0 })
    }
}

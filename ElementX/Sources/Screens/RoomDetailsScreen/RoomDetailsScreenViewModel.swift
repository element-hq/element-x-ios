//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomDetailsScreenViewModelType = StateStoreViewModelV2<RoomDetailsScreenViewState, RoomDetailsScreenViewAction>

class RoomDetailsScreenViewModel: RoomDetailsScreenViewModelType, RoomDetailsScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let userSession: UserSessionProtocol
    private let analyticsService: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let notificationSettingsProxy: NotificationSettingsProxyProtocol
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    private let appSettings: AppSettings

    private var pinnedEventsTimelineItemProvider: TimelineItemProviderProtocol? {
        didSet {
            guard let pinnedEventsTimelineItemProvider else {
                return
            }
            
            state.pinnedEventsActionState = .loaded(numberOfItems: pinnedEventsTimelineItemProvider.itemProxies.filter(\.isEvent).count)
            
            pinnedEventsTimelineItemProvider.updatePublisher
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
         userSession: UserSessionProtocol,
         analyticsService: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol,
         notificationSettingsProxy: NotificationSettingsProxyProtocol,
         attributedStringBuilder: AttributedStringBuilderProtocol,
         appSettings: AppSettings) {
        self.roomProxy = roomProxy
        self.userSession = userSession
        self.analyticsService = analyticsService
        self.userIndicatorController = userIndicatorController
        self.notificationSettingsProxy = notificationSettingsProxy
        self.attributedStringBuilder = attributedStringBuilder
        self.appSettings = appSettings
        
        let topic = attributedStringBuilder.fromPlain(roomProxy.infoPublisher.value.topic)
        
        // Clear details.historySharingState manually while we are still behind a feature flag.
        var details = roomProxy.details
        if !appSettings.enableKeyShareOnInvite {
            details.historySharingState = nil
        }
        
        super.init(initialViewState: .init(details: details,
                                           isEncrypted: roomProxy.infoPublisher.value.isEncrypted,
                                           isDirect: roomProxy.infoPublisher.value.isDirect,
                                           topic: topic,
                                           topicSummary: topic?.unattributedStringByReplacingNewlinesWithSpaces(),
                                           joinedMembersCount: roomProxy.infoPublisher.value.joinedMembersCount,
                                           notificationSettingsState: .loading,
                                           bindings: .init()),
                   mediaProvider: userSession.mediaProvider)
        
        appSettings.$knockingEnabled
            .weakAssign(to: \.state.knockingEnabled, on: self)
            .store(in: &cancellables)
        
        Task {
            state.reportRoomEnabled = await userSession.clientProxy.isReportRoomSupported
        }
        
        userSession.clientProxy.homeserverReachabilityPublisher
            .filter { $0 == .reachable }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupPinnedEventsTimelineItemProviderIfNeeded()
            }
            .store(in: &cancellables)
        
        Task {
            if case let .success(permalinkURL) = await roomProxy.matrixToPermalink() {
                state.permalink = permalinkURL
            }
        }
        
        updateRoomInfo(roomProxy.infoPublisher.value)
                
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
            processTapToLeave()
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
        case .processTapRecipientProfile:
            guard let userID = state.dmRecipientInfo?.member.id else {
                return
            }
            actionsSubject.send(.requestRecipientDetailsPresentation(userID: userID))
        case .processTapReport:
            actionsSubject.send(.displayReportRoom)
        }
    }
    
    // MARK: - Private
    
    private func processTapToLeave() {
        guard !roomProxy.infoPublisher.value.isSpace else {
            Task { await processLeaveSpace() }
            return
        }
        
        guard state.joinedMembersCount > 1 else {
            state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(roomID: roomProxy.id,
                                                                   isDM: roomProxy.isDirectOneToOneRoom,
                                                                   state: roomProxy.infoPublisher.value.isPrivate ?? true ? .empty : .public)
            return
        }
        
        if !roomProxy.isDirectOneToOneRoom, state.accountOwner?.role.isOwner == true {
            var isLastOwner = true
            for member in roomProxy.membersPublisher.value where member.userID != roomProxy.ownUserID && member.membership == .join {
                if member.role.isOwner {
                    isLastOwner = false
                    break
                }
            }
            
            if isLastOwner {
                state.bindings.alertInfo = .init(id: .lastOwner,
                                                 title: L10n.leaveRoomAlertSelectNewOwnerTitle,
                                                 message: L10n.leaveRoomAlertSelectNewOwnerSubtitle,
                                                 primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                                 secondaryButton: .init(title: L10n.leaveRoomAlertSelectNewOwnerAction, role: .destructive) { [weak self] in
                                                     self?.actionsSubject.send(.transferOwnership)
                                                 })
                return
            }
        }
        
        state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(roomID: roomProxy.id,
                                                               isDM: roomProxy.isDirectOneToOneRoom,
                                                               state: roomProxy.infoPublisher.value.isPrivate ?? true ? .private : .public)
    }
    
    private func processLeaveSpace() async {
        switch await userSession.clientProxy.spaceService.leaveSpace(spaceID: roomProxy.id) {
        case .success(let leaveHandle):
            let leaveSpaceViewModel = LeaveSpaceViewModel(spaceName: state.details.name ?? state.details.id,
                                                          canEditRolesAndPermissions: state.canEditRolesOrPermissions,
                                                          leaveHandle: leaveHandle,
                                                          userIndicatorController: userIndicatorController,
                                                          mediaProvider: userSession.mediaProvider)
            leaveSpaceViewModel.actions.sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .didCancel:
                    state.bindings.leaveSpaceViewModel = nil
                case .presentRolesAndPermissions:
                    state.bindings.leaveSpaceViewModel = nil
                    actionsSubject.send(.requestRolesAndPermissionsPresentation)
                case .didLeaveSpace:
                    state.bindings.leaveSpaceViewModel = nil
                    actionsSubject.send(.leftRoom)
                case .presentTransferOwnership:
                    state.bindings.leaveSpaceViewModel = nil
                    actionsSubject.send(.transferOwnership)
                }
            }
            .store(in: &cancellables)
            
            state.bindings.leaveSpaceViewModel = leaveSpaceViewModel
        case .failure:
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
        }
    }
    
    private func setupRoomSubscription() {
        roomProxy.infoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomInfo in
                self?.updateRoomInfo(roomInfo)
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
        
        roomProxy.membersPublisher.combineLatest(roomProxy.identityStatusChangesPublisher)
            .sink { [weak self] _ in
                Task { await self?.updateMemberIdentityVerificationStates() }
            }
            .store(in: &cancellables)
    }
    
    private func updateRoomInfo(_ roomInfo: RoomInfoProxyProtocol) {
        state.isEncrypted = roomInfo.isEncrypted
        state.isDirect = roomInfo.isDirect
        state.bindings.isFavourite = roomInfo.isFavourite
        
        state.joinedMembersCount = roomInfo.joinedMembersCount
        
        state.details = roomProxy.details
        
        // Set state.details.historySharingState manually while we are still behind
        // a feature flag.
        if appSettings.enableKeyShareOnInvite {
            state.details.historySharingState = roomInfo.historySharingState
        } else {
            state.details.historySharingState = nil
        }
        
        let topic = attributedStringBuilder.fromPlain(roomInfo.topic)
        state.topic = topic
        state.topicSummary = topic?.unattributedStringByReplacingNewlinesWithSpaces()
        
        switch roomInfo.joinRule {
        case .knock, .knockRestricted:
            state.isKnockableRoom = true
        default:
            state.isKnockableRoom = false
        }
        
        if let powerLevels = roomInfo.powerLevels {
            state.canEditRoomName = powerLevels.canOwnUser(sendStateEvent: .roomName)
            state.canEditRoomTopic = powerLevels.canOwnUser(sendStateEvent: .roomTopic)
            state.canEditRoomAvatar = powerLevels.canOwnUser(sendStateEvent: .roomAvatar)
            state.canInviteUsers = powerLevels.canOwnUserInvite()
            state.canKickUsers = powerLevels.canOwnUserKick()
            state.canBanUsers = powerLevels.canOwnUserBan()
            state.canJoinCall = powerLevels.canOwnUserJoinCall()
            state.canEditRolesOrPermissions = powerLevels.canOwnUserEditRolesAndPermissions()
            state.canEditSecurityAndPrivacy = powerLevels.canOwnUserEditSecurityAndPrivacy(isSpace: roomInfo.isSpace,
                                                                                           joinRule: roomInfo.joinRule)
        }
    }
    
    private func fetchMembersIfNeeded() async {
        roomProxy.membersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self, ownUserID = roomProxy.ownUserID] members in
                guard let self else { return }
                
                if let accountOwner = members.first(where: { $0.userID == ownUserID }) {
                    self.state.accountOwner = .init(withProxy: accountOwner)
                }
                
                guard roomProxy.isDirectOneToOneRoom else {
                    return
                }
                
                if let dmRecipient = members.first(where: { $0.userID != ownUserID }) {
                    self.state.dmRecipientInfo = .init(member: .init(withProxy: dmRecipient))
                    
                    Task { await self.updateMemberIdentityVerificationStates() }
                }
            }
            .store(in: &cancellables)
        
        await roomProxy.updateMembers()
    }
    
    private func updateMemberIdentityVerificationStates() async {
        guard roomProxy.infoPublisher.value.isEncrypted else {
            // We don't care about identity statuses on non-encrypted rooms
            return
        }
        
        if roomProxy.isDirectOneToOneRoom {
            if var dmRecipientInfo = state.dmRecipientInfo {
                if case let .success(userIdentity) = await userSession.clientProxy.userIdentity(for: dmRecipientInfo.member.id, fallBackToServer: true) {
                    dmRecipientInfo.verificationState = userIdentity?.verificationState
                    state.dmRecipientInfo = dmRecipientInfo
                }
            }
        } else {
            for member in roomProxy.membersPublisher.value {
                if case let .success(userIdentity) = await userSession.clientProxy.userIdentity(for: member.userID, fallBackToServer: false) {
                    if userIdentity?.verificationState == .verificationViolation {
                        state.hasMemberIdentityVerificationStateViolations = true
                        return
                    }
                }
            }
            
            state.hasMemberIdentityVerificationStateViolations = false
        }
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
                                                                                               isEncrypted: roomProxy.infoPublisher.value.isEncrypted,
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
                                                               isEncrypted: roomProxy.infoPublisher.value.isEncrypted,
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
        guard let dmUserID = state.dmRecipientInfo?.member.id else {
            MXLog.error("Attempting to ignore a nil DM Recipient")
            state.bindings.alertInfo = .init(id: .unknown)
            return
        }
        
        state.isProcessingIgnoreRequest = true
        let result = await userSession.clientProxy.ignoreUser(dmUserID)
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            // Mutating the optional in place when built for Release crashes 🤷‍♂️
            var dmRecipientInfo = state.dmRecipientInfo
            dmRecipientInfo?.member.isIgnored = true
            state.dmRecipientInfo = dmRecipientInfo
        case .failure:
            state.bindings.alertInfo = .init(id: .unknown)
        }
    }

    private func unignore() async {
        guard let dmUserID = state.dmRecipientInfo?.member.id else {
            MXLog.error("Attempting to unignore a nil DM Recipient")
            state.bindings.alertInfo = .init(id: .unknown)
            return
        }
        
        state.isProcessingIgnoreRequest = true
        let result = await userSession.clientProxy.unignoreUser(dmUserID)
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            // Mutating the optional in place when built for Release crashes 🤷‍♂️
            var dmRecipientInfo = state.dmRecipientInfo
            dmRecipientInfo?.member.isIgnored = false
            state.dmRecipientInfo = dmRecipientInfo
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
               case let .success(file) = await userSession.mediaProvider.loadFileFromSource(mediaSource) {
                state.bindings.mediaPreviewItem = MediaPreviewItem(file: file, title: roomProxy.infoPublisher.value.displayName)
            }
        }
    }
    
    private func setupPinnedEventsTimelineItemProviderIfNeeded() {
        guard pinnedEventsTimelineItemProvider == nil else {
            return
        }
        
        Task {
            guard case let .success(pinnedEventsTimeline) = await roomProxy.pinnedEventsTimeline() else {
                return
            }
            
            if pinnedEventsTimelineItemProvider == nil {
                pinnedEventsTimelineItemProvider = pinnedEventsTimeline.timelineItemProvider
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

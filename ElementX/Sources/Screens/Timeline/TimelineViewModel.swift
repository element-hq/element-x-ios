//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Algorithms
import Combine
import MatrixRustSDK
import OrderedCollections
import SwiftUI

typealias TimelineViewModelType = StateStoreViewModel<TimelineViewState, TimelineViewAction>

class TimelineViewModel: TimelineViewModelType, TimelineViewModelProtocol {
    private enum Constants {
        static let paginationEventLimit: UInt16 = 20
        static let detachedTimelineSize: UInt16 = 100
        static let focusTimelineToastIndicatorID = "RoomScreenFocusTimelineToastIndicator"
        static let toastErrorID = "RoomScreenToastError"
    }

    private let roomProxy: JoinedRoomProxyProtocol
    private let timelineController: TimelineControllerProtocol
    private let mediaProvider: MediaProviderProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let analyticsService: AnalyticsService
    private let emojiProvider: EmojiProviderProtocol
    private let timelineControllerFactory: TimelineControllerFactoryProtocol
    private let clientProxy: ClientProxyProtocol
    
    private let timelineInteractionHandler: TimelineInteractionHandler
    
    private let composerFocusedSubject = PassthroughSubject<Bool, Never>()
    
    private let actionsSubject: PassthroughSubject<TimelineViewModelAction, Never> = .init()
    var actions: AnyPublisher<TimelineViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var currentUserProxy: RoomMemberProxyProtocol?
    
    private var paginateBackwardsTask: Task<Void, Never>?
    private var paginateForwardsTask: Task<Void, Never>?

    init(roomProxy: JoinedRoomProxyProtocol,
         focussedEventID: String? = nil,
         timelineController: TimelineControllerProtocol,
         mediaProvider: MediaProviderProtocol,
         mediaPlayerProvider: MediaPlayerProviderProtocol,
         voiceMessageMediaManager: VoiceMessageMediaManagerProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         analyticsService: AnalyticsService,
         emojiProvider: EmojiProviderProtocol,
         timelineControllerFactory: TimelineControllerFactoryProtocol,
         clientProxy: ClientProxyProtocol) {
        self.timelineController = timelineController
        self.mediaProvider = mediaProvider
        self.mediaPlayerProvider = mediaPlayerProvider
        self.roomProxy = roomProxy
        self.appSettings = appSettings
        self.analyticsService = analyticsService
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        self.emojiProvider = emojiProvider
        self.timelineControllerFactory = timelineControllerFactory
        self.clientProxy = clientProxy
        
        let voiceMessageRecorder = VoiceMessageRecorder(audioRecorder: AudioRecorder(), mediaPlayerProvider: mediaPlayerProvider)
        
        timelineInteractionHandler = TimelineInteractionHandler(roomProxy: roomProxy,
                                                                timelineController: timelineController,
                                                                mediaProvider: mediaProvider,
                                                                mediaPlayerProvider: mediaPlayerProvider,
                                                                voiceMessageMediaManager: voiceMessageMediaManager,
                                                                voiceMessageRecorder: voiceMessageRecorder,
                                                                userIndicatorController: userIndicatorController,
                                                                appMediator: appMediator,
                                                                appSettings: appSettings,
                                                                analyticsService: analyticsService,
                                                                emojiProvider: emojiProvider,
                                                                timelineControllerFactory: timelineControllerFactory,
                                                                clientProxy: clientProxy)
        
        let hideTimelineMedia = switch clientProxy.timelineMediaVisibilityPublisher.value {
        case .always:
            false
        case .privateOnly:
            !(roomProxy.infoPublisher.value.isPrivate ?? true)
        case .never:
            true
        }
        super.init(initialViewState: TimelineViewState(timelineKind: timelineController.timelineKind,
                                                       roomID: roomProxy.id,
                                                       isDirectOneToOneRoom: roomProxy.isDirectOneToOneRoom,
                                                       timelineState: TimelineState(focussedEvent: focussedEventID.map { .init(eventID: $0, appearance: .immediate) }),
                                                       ownUserID: roomProxy.ownUserID,
                                                       isViewSourceEnabled: appSettings.viewSourceEnabled,
                                                       areThreadsEnabled: appSettings.threadsEnabled,
                                                       hideTimelineMedia: hideTimelineMedia,
                                                       hasPredecessor: roomProxy.predecessorRoom != nil,
                                                       pinnedEventIDs: roomProxy.infoPublisher.value.pinnedEventIDs,
                                                       emojiProvider: emojiProvider,
                                                       mapTilerConfiguration: appSettings.mapTilerConfiguration,
                                                       bindings: .init(reactionsCollapsed: [:])),
                   mediaProvider: mediaProvider)
        
        if focussedEventID != nil {
            // The timeline controller will start loading a detached timeline.
            showFocusLoadingIndicator()
        }
        
        setupSubscriptions()
        setupDirectRoomSubscriptionsIfNeeded()
        
        state.audioPlayerStateProvider = { [weak self] itemID -> AudioPlayerState? in
            guard let self else {
                return nil
            }
            
            return self.timelineInteractionHandler.audioPlayerState(for: itemID)
        }
        
        state.pillContextUpdater = { [weak self] pillContext in
            self?.pillContextUpdater(pillContext)
        }
        
        state.roomNameForIDResolver = { [weak self] roomID in
            self?.clientProxy.roomSummaryForIdentifier(roomID)?.name
        }
        
        state.roomNameForAliasResolver = { [weak self] alias in
            self?.clientProxy.roomSummaryForAlias(alias)?.name
        }
        
        state.timelineState.paginationState = timelineController.paginationState
        buildTimelineViews(timelineItems: timelineController.timelineItems)
        
        updateRoomInfo(roomProxy.infoPublisher.value)
        updateMembers(roomProxy.membersPublisher.value)

        // Note: beware if we get to e.g. restore a reply / edit,
        // maybe we are tracking a non-needed first initial state
        trackComposerMode(.default)
    }
    
    // MARK: - Public
    
    override func process(viewAction: TimelineViewAction) {
        switch viewAction {
        case .itemAppeared(let id):
            Task { await timelineController.processItemAppearance(id) }
        case .itemDisappeared(let id):
            Task { await timelineController.processItemDisappearance(id) }
        case .mediaTapped(let id):
            Task { await handleMediaTapped(with: id) }
        case .itemSendInfoTapped(let itemID):
            handleItemSendInfoTapped(itemID: itemID)
        case .toggleReaction(let emoji, let itemID):
            emojiProvider.markEmojiAsFrequentlyUsed(emoji)
            
            guard case let .event(_, eventOrTransactionID) = itemID else {
                fatalError()
            }
            
            Task { await timelineController.toggleReaction(emoji, to: eventOrTransactionID) }
        case .sendReadReceiptIfNeeded(let lastVisibleItemID):
            Task { await sendReadReceiptIfNeeded(for: lastVisibleItemID) }
        case .paginateBackwards:
            paginateBackwards()
        case .paginateForwards:
            paginateForwards()
        case .scrollToBottom:
            scrollToBottom()
        case .displayTimelineItemMenu(let itemID):
            timelineInteractionHandler.displayTimelineItemActionMenu(for: itemID)
        case .handleTimelineItemMenuAction(let itemID, let action):
            timelineInteractionHandler.handleTimelineItemMenuAction(action, itemID: itemID)
        case .tappedOnSenderDetails(let sender):
            handleTappedOnSenderDetails(sender: sender)
        case .displayEmojiPicker(let itemID):
            timelineInteractionHandler.displayEmojiPicker(for: itemID)
        case .displayReactionSummary(let itemID, let key):
            displayReactionSummary(for: itemID, selectedKey: key)
        case .displayReadReceipts(let itemID):
            displayReadReceipts(for: itemID)
        case .displayThread(let itemID):
            actionsSubject.send(.displayThread(itemID: itemID))
        case .handlePasteOrDrop(let provider):
            timelineInteractionHandler.handlePasteOrDrop(provider)
        case .handlePollAction(let pollAction):
            handlePollAction(pollAction)
        case .handleAudioPlayerAction(let audioPlayerAction):
            handleAudioPlayerAction(audioPlayerAction)
        case .focusOnEventID(let eventID):
            Task { await focusOnEvent(eventID: eventID) }
        case .focusLive:
            focusLive()
        case .scrolledToFocussedItem:
            didScrollToFocussedItem()
        case .hasSwitchedTimeline:
            Task { state.timelineState.isSwitchingTimelines = false }
        case let .hasScrolled(direction):
            actionsSubject.send(.hasScrolled(direction: direction))
        case .setOpenURLAction(let action):
            state.openURL = action
        case .displayPredecessorRoom:
            guard let predecessorID = roomProxy.predecessorRoom?.roomId else {
                fatalError("Predecessor room should exist if this action is triggered.")
            }
            actionsSubject.send(.displayRoom(roomID: predecessorID))
        }
    }

    func process(composerAction: ComposerToolbarViewModelAction) {
        switch composerAction {
        case .sendMessage(let message, let html, let mode, let intentionalMentions):
            Task {
                await sendCurrentMessage(message,
                                         html: html,
                                         mode: mode,
                                         intentionalMentions: intentionalMentions)
            }
        case .editLastMessage:
            editLastMessage()
        case .attach(let attachment):
            attach(attachment)
        case .handlePasteOrDrop(let provider):
            timelineInteractionHandler.handlePasteOrDrop(provider)
        case .composerModeChanged(mode: let mode):
            trackComposerMode(mode)
        case .composerFocusedChanged(isFocused: let isFocused):
            composerFocusedSubject.send(isFocused)
        case .voiceMessage(let voiceMessageAction):
            processVoiceMessageAction(voiceMessageAction)
        case .contentChanged(let isEmpty):
            guard appSettings.sharePresence else {
                return
            }
            
            Task {
                await roomProxy.sendTypingNotification(isTyping: !isEmpty)
            }
        }
    }
    
    func focusOnEvent(eventID: String) async {
        if state.timelineState.hasLoadedItem(with: eventID) {
            state.timelineState.focussedEvent = .init(eventID: eventID, appearance: .animated)
            return
        }
        
        showFocusLoadingIndicator()
        defer { hideFocusLoadingIndicator() }
        
        switch await timelineController.focusOnEvent(eventID, timelineSize: Constants.detachedTimelineSize) {
        case .success:
            state.timelineState.focussedEvent = .init(eventID: eventID, appearance: .immediate)
        case .failure(let error):
            MXLog.error("Failed to focus on event \(eventID)")
            
            if case .eventNotFound = error {
                displayErrorToast(L10n.errorMessageNotFound)
            } else {
                displayErrorToast(L10n.commonFailed)
            }
        }
    }
    
    // MARK: - Private
    
    private func handleTappedOnSenderDetails(sender: TimelineItemSender) {
        let memberDetails: ManageRoomMemberDetails = if let memberProxy = roomProxy.membersPublisher.value.first(where: { $0.userID == sender.id }) {
            .memberDetails(roomMember: .init(withProxy: memberProxy))
        } else {
            .loadingMemberDetails(sender: sender)
        }
        
        let viewModel = ManageRoomMemberSheetViewModel(memberDetails: memberDetails,
                                                       permissions: .init(canKick: state.canCurrentUserKick,
                                                                          canBan: state.canCurrentUserBan,
                                                                          ownPowerLevel: currentUserProxy?.powerLevel ?? 0),
                                                       roomProxy: roomProxy,
                                                       userIndicatorController: userIndicatorController,
                                                       analyticsService: analyticsService,
                                                       mediaProvider: mediaProvider)
        
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss(let shouldShowDetails):
                state.bindings.manageMemberViewModel = nil
                if shouldShowDetails {
                    actionsSubject.send(.displaySenderDetails(userID: sender.id))
                }
            }
        }
        .store(in: &cancellables)
        state.bindings.manageMemberViewModel = viewModel
    }
    
    private func focusLive() {
        timelineController.focusLive()
    }
    
    private func didScrollToFocussedItem() {
        if var focussedEvent = state.timelineState.focussedEvent {
            focussedEvent.appearance = .hasAppeared
            state.timelineState.focussedEvent = focussedEvent
            hideFocusLoadingIndicator()
        }
    }
    
    private func editLastMessage() {
        guard let item = timelineController.timelineItems.reversed().first(where: {
            guard let item = $0 as? EventBasedMessageTimelineItemProtocol else {
                return false
            }
            
            return item.sender.id == roomProxy.ownUserID && item.isEditable
        }) else {
            return
        }
        
        timelineInteractionHandler.handleTimelineItemMenuAction(.edit, itemID: item.id)
    }
    
    private func attach(_ attachment: ComposerAttachmentType) {
        switch attachment {
        case .camera:
            actionsSubject.send(.displayCameraPicker)
        case .photoLibrary:
            actionsSubject.send(.displayMediaPicker)
        case .file:
            actionsSubject.send(.displayDocumentPicker)
        case .location:
            actionsSubject.send(.displayLocationPicker)
        case .poll:
            actionsSubject.send(.displayPollForm(mode: .new))
        }
    }
    
    private func handlePollAction(_ action: TimelineViewPollAction) {
        switch action {
        case let .selectOption(pollStartID, optionID):
            timelineInteractionHandler.sendPollResponse(pollStartID: pollStartID, optionID: optionID)
        case let .end(pollStartID):
            displayAlert(.pollEndConfirmation(pollStartID))
        case .edit(let pollStartID, let poll):
            actionsSubject.send(.displayPollForm(mode: .edit(eventID: pollStartID, poll: poll)))
        }
    }
    
    private func handleAudioPlayerAction(_ action: TimelineAudioPlayerAction) {
        switch action {
        case .playPause(let itemID):
            Task { await timelineInteractionHandler.playPauseAudio(for: itemID) }
        case .seek(let itemID, let progress):
            Task { await timelineInteractionHandler.seekAudio(for: itemID, progress: progress) }
        }
    }
    
    private func processVoiceMessageAction(_ action: ComposerToolbarVoiceMessageAction) {
        switch action {
        case .startRecording:
            Task {
                await mediaPlayerProvider.detachAllStates(except: nil)
                await timelineInteractionHandler.startRecordingVoiceMessage()
            }
        case .stopRecording:
            Task { await timelineInteractionHandler.stopRecordingVoiceMessage() }
        case .cancelRecording:
            Task { await timelineInteractionHandler.cancelRecordingVoiceMessage() }
        case .deleteRecording:
            Task { await timelineInteractionHandler.deleteCurrentVoiceMessage() }
        case .send:
            Task { await timelineInteractionHandler.sendCurrentVoiceMessage() }
        case .startPlayback:
            Task { await timelineInteractionHandler.startPlayingRecordedVoiceMessage() }
        case .pausePlayback:
            timelineInteractionHandler.pausePlayingRecordedVoiceMessage()
        case .seekPlayback(let progress):
            Task { await timelineInteractionHandler.seekRecordedVoiceMessage(to: progress) }
        case .scrubPlayback(let scrubbing):
            Task { await timelineInteractionHandler.scrubVoiceMessagePlayback(scrubbing: scrubbing) }
        }
    }
    
    private func updateMembers(_ members: [RoomMemberProxyProtocol]) {
        state.members = members.reduce(into: [String: RoomMemberState]()) { dictionary, member in
            dictionary[member.userID] = RoomMemberState(displayName: member.displayName, avatarURL: member.avatarURL)
            if member.userID == roomProxy.ownUserID {
                currentUserProxy = member
            }
        }
    }
    
    private func updateRoomInfo(_ roomInfo: RoomInfoProxyProtocol) {
        state.pinnedEventIDs = roomInfo.pinnedEventIDs
        
        if let powerLevels = roomInfo.powerLevels {
            state.canCurrentUserSendMessage = powerLevels.canOwnUser(sendMessage: .roomMessage)
            state.canCurrentUserRedactOthers = powerLevels.canOwnUserRedactOther()
            state.canCurrentUserRedactSelf = powerLevels.canOwnUserRedactOwn()
            state.canCurrentUserPin = powerLevels.canOwnUserPinOrUnpin()
            state.canCurrentUserKick = powerLevels.canOwnUserKick()
            state.canCurrentUserBan = powerLevels.canOwnUserBan()
        }
    }
    
    private func setupSubscriptions() {
        timelineController.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }

                switch callback {
                case .updatedTimelineItems(let updatedItems, let isSwitchingTimelines):
                    buildTimelineViews(timelineItems: updatedItems, isSwitchingTimelines: isSwitchingTimelines)
                case .paginationState(let paginationState):
                    if state.timelineState.paginationState != paginationState {
                        state.timelineState.paginationState = paginationState
                    }
                case .isLive(let isLive):
                    if state.timelineState.isLive != isLive {
                        state.timelineState.isLive = isLive
                        
                        // Remove the event highlight *only* when transitioning from non-live to live.
                        if isLive, state.timelineState.focussedEvent != nil {
                            state.timelineState.focussedEvent = nil
                        }
                    }
                }
            }
            .store(in: &cancellables)

        roomProxy.infoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomInfo in
                self?.updateRoomInfo(roomInfo)
            }
            .store(in: &cancellables)
        
        setupAppSettingsSubscriptions()
        
        roomProxy.membersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateMembers($0) }
            .store(in: &cancellables)
        
        roomProxy.typingMembersPublisher
            .receive(on: DispatchQueue.main)
            .filter { [weak self] _ in self?.appSettings.sharePresence ?? false }
            .weakAssign(to: \.state.typingMembers, on: self)
            .store(in: &cancellables)
        
        timelineInteractionHandler.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .composer(let action):
                    actionsSubject.send(.composer(action: action))
                case .displayAudioRecorderPermissionError:
                    displayAlert(.audioRecodingPermissionError)
                case .displayErrorToast(let title):
                    displayErrorToast(title)
                case .displayEmojiPicker(let itemID, let selectedEmojis):
                    actionsSubject.send(.displayEmojiPicker(itemID: itemID, selectedEmojis: selectedEmojis))
                case .displayMessageForwarding(let itemID):
                    Task { await self.forwardMessage(itemID: itemID) }
                case .displayPollForm(let mode):
                    actionsSubject.send(.displayPollForm(mode: mode))
                case .displayReportContent(let itemID, let senderID):
                    actionsSubject.send(.displayReportContent(itemID: itemID, senderID: senderID))
                case .displayMediaUploadPreviewScreen(let url):
                    actionsSubject.send(.displayMediaUploadPreviewScreen(url: url))
                case .showActionMenu(let actionMenuInfo):
                    self.state.bindings.actionMenuInfo = actionMenuInfo
                case .showDebugInfo(let debugInfo):
                    state.bindings.debugInfo = debugInfo
                case .viewInRoomTimeline(let eventID):
                    actionsSubject.send(.viewInRoomTimeline(eventID: eventID))
                case .displayThread(let itemID):
                    actionsSubject.send(.displayThread(itemID: itemID))
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupAppSettingsSubscriptions() {
        appSettings.$sharePresence
            .weakAssign(to: \.state.showReadReceipts, on: self)
            .store(in: &cancellables)
        
        appSettings.$viewSourceEnabled
            .weakAssign(to: \.state.isViewSourceEnabled, on: self)
            .store(in: &cancellables)
        
        appSettings.$threadsEnabled
            .weakAssign(to: \.state.areThreadsEnabled, on: self)
            .store(in: &cancellables)
        
        clientProxy.timelineMediaVisibilityPublisher
            .removeDuplicates()
            .flatMap { [weak self] timelineMediaVisibility -> AnyPublisher<Bool, Never> in
                switch timelineMediaVisibility {
                case .always:
                    return Just(false).eraseToAnyPublisher()
                case .never:
                    return Just(true).eraseToAnyPublisher()
                case .privateOnly:
                    guard let self else { return Just(false).eraseToAnyPublisher() }
                    return roomProxy.infoPublisher
                        .map { !($0.isPrivate ?? false) }
                        .removeDuplicates()
                        .eraseToAnyPublisher()
                }
            }
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.hideTimelineMedia, on: self)
            .store(in: &cancellables)
    }

    private func setupDirectRoomSubscriptionsIfNeeded() {
        guard roomProxy.infoPublisher.value.isDirect else {
            return
        }

        let shouldShowInviteAlert = composerFocusedSubject
            .removeDuplicates()
            .map { [weak self] isFocused in
                guard let self else { return false }

                return isFocused && self.roomProxy.infoPublisher.value.isUserAloneInDirectRoom
            }
            // We want to show the alert just once, so we are taking the first "true" emitted
            .first { $0 }

        shouldShowInviteAlert
            .sink { [weak self] _ in
                self?.showInviteAlert()
            }
            .store(in: &cancellables)
    }

    private func paginateBackwards() {
        guard paginateBackwardsTask == nil else {
            return
        }

        paginateBackwardsTask = Task { [weak self] in
            guard let self else {
                return
            }

            switch await timelineController.paginateBackwards(requestSize: Constants.paginationEventLimit) {
            case .failure:
                displayErrorToast(L10n.errorFailedLoadingMessages)
            default:
                break
            }
            paginateBackwardsTask = nil
        }
    }
    
    private func paginateForwards() {
        guard paginateForwardsTask == nil else {
            return
        }

        paginateForwardsTask = Task { [weak self] in
            guard let self else {
                return
            }

            switch await timelineController.paginateForwards(requestSize: Constants.paginationEventLimit) {
            case .failure:
                displayErrorToast(L10n.errorFailedLoadingMessages)
            default:
                break
            }
            
            if state.timelineState.paginationState.forward == .timelineEndReached {
                focusLive()
            }
            
            paginateForwardsTask = nil
        }
    }
    
    private func scrollToBottom() {
        if state.timelineState.isLive {
            state.timelineState.scrollToBottomPublisher.send(())
        } else {
            focusLive()
        }
    }
    
    private func sendReadReceiptIfNeeded(for lastVisibleItemID: TimelineItemIdentifier) async {
        guard appMediator.appState == .active else { return }
                
        await timelineController.sendReadReceipt(for: lastVisibleItemID)
    }

    private func handleMediaTapped(with itemID: TimelineItemIdentifier) async {
        state.showLoading = true
        let action = await timelineInteractionHandler.processItemTap(itemID)
        
        switch action {
        case .displayMediaPreview(let item, let timelineViewModelKind):
            actionsSubject.send(.composer(action: .removeFocus)) // Hide the keyboard otherwise a big white space is sometimes shown when dismissing the preview.
            
            let mediaPreviewViewModel = makeMediaPreviewViewModel(item: item, timelineViewModelKind: timelineViewModelKind)
            actionsSubject.send(.displayMediaPreview(mediaPreviewViewModel))
        case .displayLocation(let body, let geoURI, let description):
            actionsSubject.send(.displayLocation(body: body, geoURI: geoURI, description: description))
        case .none:
            break
        }
        state.showLoading = false
    }
    
    private func handleItemSendInfoTapped(itemID: TimelineItemIdentifier) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID) else {
            MXLog.warning("Couldn't find timeline item.")
            return
        }
        
        guard let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            fatalError("Only events can have send info.")
        }
        
        if case .sendingFailed(.unknown) = eventTimelineItem.properties.deliveryStatus {
            displayAlert(.sendingFailed)
        } else if case let .sendingFailed(.verifiedUser(failure)) = eventTimelineItem.properties.deliveryStatus {
            guard let sendHandle = timelineController.sendHandle(for: itemID) else {
                MXLog.error("Cannot find send handle for \(itemID).")
                return
            }
            
            actionsSubject.send(.displayResolveSendFailure(failure: failure,
                                                           sendHandle: sendHandle))
            
        } else if let authenticityMessage = eventTimelineItem.properties.encryptionAuthenticity?.message {
            displayAlert(.encryptionAuthenticity(authenticityMessage))
        }
    }
    
    private func slashCommand(message: String) -> SlashCommand? {
        for command in SlashCommand.allCases where message.starts(with: command.rawValue) {
            return command
        }
        return nil
    }

    private func handleJoinCommand(message: String) {
        guard let alias = String(message.dropFirst(SlashCommand.join.rawValue.count))
            .components(separatedBy: .whitespacesAndNewlines)
            .first,
            let urlString = try? matrixToRoomAliasPermalink(roomAlias: alias),
            let url = URL(string: urlString) else {
            return
        }
        state.openURL?(url)
    }
    
    private func sendCurrentMessage(_ message: String, html: String?, mode: ComposerMode, intentionalMentions: IntentionalMentions) async {
        guard !message.isEmpty else {
            fatalError("This message should never be empty")
        }

        actionsSubject.send(.composer(action: .clear))
        
        switch mode {
        case .reply(let eventID, _, _):
            await timelineController.sendMessage(message,
                                                 html: html,
                                                 inReplyToEventID: eventID,
                                                 intentionalMentions: intentionalMentions)
        case .edit(let originalEventOrTransactionID, .default):
            await timelineController.edit(originalEventOrTransactionID,
                                          message: message,
                                          html: html,
                                          intentionalMentions: intentionalMentions)
        case .edit(let originalEventOrTransactionID, .addCaption),
             .edit(let originalEventOrTransactionID, .editCaption):
            await timelineController.editCaption(originalEventOrTransactionID,
                                                 message: message,
                                                 html: html,
                                                 intentionalMentions: intentionalMentions)
        case .default:
            switch slashCommand(message: message) {
            case .join:
                handleJoinCommand(message: message)
            case .none:
                await timelineController.sendMessage(message,
                                                     html: html,
                                                     inReplyToEventID: nil,
                                                     intentionalMentions: intentionalMentions)
            }
        case .recordVoiceMessage, .previewVoiceMessage:
            fatalError("invalid composer mode.")
        }
        
        scrollToBottom()
    }
        
    private func trackComposerMode(_ mode: ComposerMode) {
        var isEdit = false
        var isReply = false
        switch mode {
        case .edit:
            isEdit = true
        case .reply:
            isReply = true
        default:
            break
        }
        
        analyticsService.trackComposer(inThread: false, isEditing: isEdit, isReply: isReply, startsThread: nil)
    }
    
    private func makeMediaPreviewViewModel(item: EventBasedMessageTimelineItemProtocol,
                                           timelineViewModelKind: TimelineControllerAction.TimelineViewModelKind) -> TimelineMediaPreviewViewModel {
        let timelineViewModel = switch timelineViewModelKind {
        case .active: self
        case .new(let newViewModel): newViewModel
        }
        
        return TimelineMediaPreviewViewModel(initialItem: item,
                                             timelineViewModel: timelineViewModel,
                                             mediaProvider: mediaProvider,
                                             photoLibraryManager: PhotoLibraryManager(),
                                             userIndicatorController: userIndicatorController,
                                             appMediator: appMediator)
    }
    
    // MARK: - Timeline Item Building
    
    private func buildTimelineViews(timelineItems: [RoomTimelineItemProtocol], isSwitchingTimelines: Bool = false) {
        var timelineItemsDictionary = OrderedDictionary<TimelineItemIdentifier.UniqueID, RoomTimelineItemViewState>()
        
        timelineItems.filter { $0 is RedactedRoomTimelineItem }.forEach { timelineItem in
            // Stops the audio player when a voice message is redacted.
            guard let playerState = mediaPlayerProvider.playerState(for: .timelineItemIdentifier(timelineItem.id)) else {
                return
            }
            
            Task { @MainActor in
                playerState.detachAudioPlayer()
                mediaPlayerProvider.unregister(audioPlayerState: playerState)
            }
        }

        let itemsGroupedByTimelineDisplayStyle = timelineItems.chunked { current, next in
            canGroupItem(timelineItem: current, with: next)
        }
        
        for itemGroup in itemsGroupedByTimelineDisplayStyle {
            guard !itemGroup.isEmpty else {
                MXLog.error("Found empty item group")
                continue
            }
            
            if itemGroup.count == 1 {
                if let firstItem = itemGroup.first {
                    timelineItemsDictionary.updateValue(updateViewState(item: firstItem, groupStyle: .single),
                                                        forKey: firstItem.id.uniqueID)
                }
            } else {
                for (index, item) in itemGroup.enumerated() {
                    if index == 0 {
                        timelineItemsDictionary.updateValue(updateViewState(item: item, groupStyle: state.timelineKind == .pinned ? .single : .first),
                                                            forKey: item.id.uniqueID)
                    } else if index == itemGroup.count - 1 {
                        timelineItemsDictionary.updateValue(updateViewState(item: item, groupStyle: state.timelineKind == .pinned ? .single : .last),
                                                            forKey: item.id.uniqueID)
                    } else {
                        timelineItemsDictionary.updateValue(updateViewState(item: item, groupStyle: state.timelineKind == .pinned ? .single : .middle),
                                                            forKey: item.id.uniqueID)
                    }
                }
            }
        }
        
        if isSwitchingTimelines {
            state.timelineState.isSwitchingTimelines = true
        }
        
        state.timelineState.itemsDictionary = timelineItemsDictionary
    }

    private func updateViewState(item: RoomTimelineItemProtocol, groupStyle: TimelineGroupStyle) -> RoomTimelineItemViewState {
        if let timelineItemViewState = state.timelineState.itemsDictionary[item.id.uniqueID] {
            timelineItemViewState.groupStyle = groupStyle
            timelineItemViewState.type = .init(item: item)
            return timelineItemViewState
        } else {
            return RoomTimelineItemViewState(item: item, groupStyle: groupStyle)
        }
    }

    private func canGroupItem(timelineItem: RoomTimelineItemProtocol, with otherTimelineItem: RoomTimelineItemProtocol) -> Bool {
        if timelineItem is CollapsibleTimelineItem || otherTimelineItem is CollapsibleTimelineItem {
            return false
        }
        
        guard let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol,
              let otherEventTimelineItem = otherTimelineItem as? EventBasedTimelineItemProtocol else {
            return false
        }
        
        // State events aren't rendered as messages so shouldn't be grouped.
        if eventTimelineItem is StateRoomTimelineItem || otherEventTimelineItem is StateRoomTimelineItem {
            return false
        }
        
        return eventTimelineItem.sender == otherEventTimelineItem.sender
            && eventTimelineItem.properties.reactions.isEmpty // Reactions break the grouping.
            && otherEventTimelineItem.timestamp.timeIntervalSince(eventTimelineItem.timestamp) < 5 * 60 // As does the passage of time.
    }

    // MARK: - Direct chats logics

    private func showInviteAlert() {
        userIndicatorController.alertInfo = .init(id: .init(),
                                                  title: L10n.screenRoomInviteAgainAlertTitle,
                                                  message: L10n.screenRoomInviteAgainAlertMessage,
                                                  primaryButton: .init(title: L10n.actionInvite) { [weak self] in self?.inviteOtherDMUserBack() },
                                                  secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
    }

    private let inviteLoadingIndicatorID = UUID().uuidString

    private func inviteOtherDMUserBack() {
        guard roomProxy.infoPublisher.value.isUserAloneInDirectRoom else {
            userIndicatorController.alertInfo = .init(id: .init(), title: L10n.commonError)
            return
        }

        Task {
            userIndicatorController.submitIndicator(.init(id: inviteLoadingIndicatorID, type: .toast, title: L10n.commonLoading))
            defer {
                userIndicatorController.retractIndicatorWithId(inviteLoadingIndicatorID)
            }

            guard
                let members = await roomProxy.members(),
                members.count == 2,
                let otherPerson = members.first(where: { $0.userID != roomProxy.ownUserID && $0.membership == .leave })
            else {
                userIndicatorController.alertInfo = .init(id: .init(), title: L10n.commonError)
                return
            }

            switch await roomProxy.invite(userID: otherPerson.userID) {
            case .success:
                break
            case .failure:
                userIndicatorController.alertInfo = .init(id: .init(),
                                                          title: L10n.commonUnableToInviteTitle,
                                                          message: L10n.commonUnableToInviteMessage)
            }
        }
    }
    
    // MARK: - Reactions
        
    private func displayReactionSummary(for itemID: TimelineItemIdentifier, selectedKey: String) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        state.bindings.reactionSummaryInfo = .init(reactions: eventTimelineItem.properties.reactions, selectedKey: selectedKey)
    }
    
    // MARK: - Read Receipts

    private func displayReadReceipts(for itemID: TimelineItemIdentifier) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        state.bindings.readReceiptsSummaryInfo = .init(orderedReceipts: eventTimelineItem.properties.orderedReadReceipts, id: eventTimelineItem.id)
    }
        
    // MARK: - Message forwarding
    
    private func forwardMessage(itemID: TimelineItemIdentifier) async {
        guard let content = await timelineController.messageEventContent(for: itemID) else { return }
        actionsSubject.send(.displayMessageForwarding(forwardingItem: .init(id: itemID, roomID: roomProxy.id, content: content)))
    }
    
    // MARK: Pills
    
    private func pillContextUpdater(_ pillContext: PillContext) {
        switch pillContext.data.type {
        case let .user(id):
            let isOwnMention = id == state.ownUserID
            if let profile = state.members[id] {
                pillContext.viewState = .mention(isOwnMention: isOwnMention, displayText: PillUtilities.userPillDisplayText(username: profile.displayName, userID: id))
            } else {
                pillContext.viewState = .mention(isOwnMention: isOwnMention, displayText: id)
                pillContext.cancellable = context.$viewState
                    .compactMap { $0.members[id] }
                    .sink { [weak pillContext] profile in
                        guard let pillContext else {
                            return
                        }
                        pillContext.viewState = .mention(isOwnMention: isOwnMention, displayText: PillUtilities.userPillDisplayText(username: profile.displayName, userID: id))
                        pillContext.cancellable = nil
                    }
            }
        case .allUsers:
            pillContext.viewState = .mention(isOwnMention: true, displayText: PillUtilities.atRoom)
        case .event(let room):
            let pillViewState: PillViewState
            switch room {
            case .roomAlias(let alias):
                let roomSummary = clientProxy.roomSummaryForAlias(alias)
                pillViewState = .reference(displayText: PillUtilities.eventPillDisplayText(roomName: roomSummary?.name, rawRoomText: alias))
            case .roomID(let id):
                let roomSummary = clientProxy.roomSummaryForIdentifier(id)
                pillViewState = .reference(displayText: PillUtilities.eventPillDisplayText(roomName: roomSummary?.name, rawRoomText: id))
            }
            pillContext.viewState = pillViewState
        case .roomAlias(let alias):
            let roomSummary = clientProxy.roomSummaryForAlias(alias)
            pillContext.viewState = .reference(displayText: PillUtilities.roomPillDisplayText(roomName: roomSummary?.name, rawRoomText: alias))
        case .roomID(let id):
            let roomSummary = clientProxy.roomSummaryForIdentifier(id)
            pillContext.viewState = .reference(displayText: PillUtilities.roomPillDisplayText(roomName: roomSummary?.name, rawRoomText: id))
        }
    }
    
    // MARK: - User Indicators
    
    private func showFocusLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Constants.focusTimelineToastIndicatorID,
                                                              type: .toast(progress: .indeterminate),
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func hideFocusLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Constants.focusTimelineToastIndicatorID)
    }
    
    private func displayAlert(_ type: TimelineAlertInfoType) {
        switch type {
        case .audioRecodingPermissionError:
            state.bindings.alertInfo = .init(id: type,
                                             title: L10n.dialogPermissionMicrophoneTitleIos(InfoPlistReader.main.bundleDisplayName),
                                             message: L10n.dialogPermissionMicrophoneDescriptionIos,
                                             primaryButton: .init(title: L10n.commonSettings) { [weak self] in self?.appMediator.openAppSettings() },
                                             secondaryButton: .init(title: L10n.actionNotNow, role: .cancel, action: nil))
        case .pollEndConfirmation(let pollStartID):
            state.bindings.alertInfo = .init(id: type,
                                             title: L10n.actionEndPoll,
                                             message: L10n.commonPollEndConfirmation,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                             secondaryButton: .init(title: L10n.actionOk) { self.timelineInteractionHandler.endPoll(pollStartID: pollStartID) })
        case .sendingFailed:
            state.bindings.alertInfo = .init(id: type,
                                             title: L10n.commonSendingFailed,
                                             primaryButton: .init(title: L10n.actionOk, action: nil))
        case .encryptionAuthenticity(let message):
            state.bindings.alertInfo = .init(id: type,
                                             title: message,
                                             primaryButton: .init(title: L10n.actionOk, action: nil))
        }
    }
    
    private func displayErrorToast(_ title: String) {
        userIndicatorController.submitIndicator(UserIndicator(id: Constants.toastErrorID,
                                                              type: .toast,
                                                              title: title,
                                                              iconName: "xmark"))
    }
}

// MARK: - Mocks

extension TimelineViewModel {
    static let mock = mock(timelineKind: .live)
    
    static func mock(timelineKind: TimelineKind = .live, timelineController: MockTimelineController? = nil, hasPredecessor: Bool = false) -> TimelineViewModel {
        let clientProxyMock = ClientProxyMock(.init())
        clientProxyMock.roomSummaryForAliasReturnValue = .mock(id: "!room:matrix.org", name: "Room")
        clientProxyMock.roomSummaryForIdentifierReturnValue = .mock(id: "!room:matrix.org", name: "Room", canonicalAlias: "#room:matrix.org")
        let roomProxy = JoinedRoomProxyMock(.init(name: "Preview room", predecessor: hasPredecessor ? .init(roomId: UUID().uuidString, lastEventId: UUID().uuidString) : nil))
        return TimelineViewModel(roomProxy: roomProxy,
                                 focussedEventID: nil,
                                 timelineController: timelineController ?? MockTimelineController(timelineKind: timelineKind),
                                 mediaProvider: MediaProviderMock(configuration: .init()),
                                 mediaPlayerProvider: MediaPlayerProviderMock(),
                                 voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                 userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                 appMediator: AppMediatorMock.default,
                                 appSettings: ServiceLocator.shared.settings,
                                 analyticsService: ServiceLocator.shared.analytics,
                                 emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                 timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                 clientProxy: clientProxyMock)
    }
}

extension EnvironmentValues {
    /// Used to access and inject the room context without observing it
    @Entry var timelineContext: TimelineViewModel.Context?
    /// An event ID which will be non-nil when a timeline item should show as focussed.
    @Entry var focussedEventID: String?
}

private enum SlashCommand: String, CaseIterable {
    case join = "/join "
}

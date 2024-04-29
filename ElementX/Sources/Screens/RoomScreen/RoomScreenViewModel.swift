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

import Algorithms
import Combine
import OrderedCollections
import SwiftUI

typealias RoomScreenViewModelType = StateStoreViewModel<RoomScreenViewState, RoomScreenViewAction>

class RoomScreenViewModel: RoomScreenViewModelType, RoomScreenViewModelProtocol {
    private enum Constants {
        static let paginationEventLimit: UInt16 = 20
        static let detachedTimelineSize: UInt16 = 100
        static let focusTimelineToastIndicatorID = "RoomScreenFocusTimelineToastIndicator"
        static let toastErrorID = "RoomScreenToastError"
    }

    private let roomProxy: RoomProxyProtocol
    private let timelineController: RoomTimelineControllerProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let analyticsService: AnalyticsService
    private let notificationCenter: NotificationCenterProtocol
    
    private let roomScreenInteractionHandler: RoomScreenInteractionHandler
    
    private let composerFocusedSubject = PassthroughSubject<Bool, Never>()
    
    private let actionsSubject: PassthroughSubject<RoomScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<RoomScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var paginateBackwardsTask: Task<Void, Never>?
    private var paginateForwardsTask: Task<Void, Never>?

    init(roomProxy: RoomProxyProtocol,
         focussedEventID: String? = nil,
         timelineController: RoomTimelineControllerProtocol,
         mediaProvider: MediaProviderProtocol,
         mediaPlayerProvider: MediaPlayerProviderProtocol,
         voiceMessageMediaManager: VoiceMessageMediaManagerProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         analyticsService: AnalyticsService,
         notificationCenter: NotificationCenterProtocol) {
        self.timelineController = timelineController
        self.mediaPlayerProvider = mediaPlayerProvider
        self.roomProxy = roomProxy
        self.appSettings = appSettings
        self.analyticsService = analyticsService
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        self.notificationCenter = notificationCenter
        
        let voiceMessageRecorder = VoiceMessageRecorder(audioRecorder: AudioRecorder(), mediaPlayerProvider: mediaPlayerProvider)
        
        roomScreenInteractionHandler = RoomScreenInteractionHandler(roomProxy: roomProxy,
                                                                    timelineController: timelineController,
                                                                    mediaProvider: mediaProvider,
                                                                    mediaPlayerProvider: mediaPlayerProvider,
                                                                    voiceMessageMediaManager: voiceMessageMediaManager,
                                                                    voiceMessageRecorder: voiceMessageRecorder,
                                                                    userIndicatorController: userIndicatorController,
                                                                    appMediator: appMediator,
                                                                    appSettings: appSettings,
                                                                    analyticsService: analyticsService)
        
        super.init(initialViewState: RoomScreenViewState(roomID: timelineController.roomID,
                                                         roomTitle: roomProxy.roomTitle,
                                                         roomAvatarURL: roomProxy.avatarURL,
                                                         timelineStyle: appSettings.timelineStyle,
                                                         isEncryptedOneToOneRoom: roomProxy.isEncryptedOneToOneRoom,
                                                         timelineViewState: TimelineViewState(focussedEventID: focussedEventID,
                                                                                              focussedEventNeedsDisplay: focussedEventID != nil),
                                                         ownUserID: roomProxy.ownUserID,
                                                         hasOngoingCall: roomProxy.hasOngoingCall,
                                                         bindings: .init(reactionsCollapsed: [:])),
                   imageProvider: mediaProvider)
        
        // This may change to load the detached timeline directly.
        if let focussedEventID {
            Task { await focusOnEvent(eventID: focussedEventID) }
        }
        
        setupSubscriptions()
        setupDirectRoomSubscriptionsIfNeeded()
        
        state.timelineItemMenuActionProvider = { [weak self] itemId -> TimelineItemMenuActions? in
            guard let self else {
                return nil
            }
            
            return self.roomScreenInteractionHandler.timelineItemMenuActionsForItemId(itemId)
        }

        state.audioPlayerStateProvider = { [weak self] itemId -> AudioPlayerState? in
            guard let self else {
                return nil
            }
            
            return self.roomScreenInteractionHandler.audioPlayerState(for: itemId)
        }
        
        buildTimelineViews()
        
        updateMembers(roomProxy.membersPublisher.value)

        // Note: beware if we get to e.g. restore a reply / edit,
        // maybe we are tracking a non-needed first initial state
        trackComposerMode(.default)
        
        Task {
            let userID = roomProxy.ownUserID
            if case let .success(permission) = await roomProxy.canUserJoinCall(userID: userID) {
                state.canJoinCall = permission
            }
        }
    }
    
    // MARK: - Public
    
    func stop() {
        // Work around QLPreviewController dismissal issues, see the InteractiveQuickLookModifier.
        state.bindings.mediaPreviewItem = nil
    }
    
    override func process(viewAction: RoomScreenViewAction) {
        switch viewAction {
        case .displayRoomDetails:
            actionsSubject.send(.displayRoomDetails)
        case .itemAppeared(let id):
            Task { await timelineController.processItemAppearance(id) }
        case .itemDisappeared(let id):
            Task { await timelineController.processItemDisappearance(id) }
        case .itemTapped(let id):
            Task { await handleItemTapped(with: id) }
        case .toggleReaction(let emoji, let itemId):
            Task { await timelineController.toggleReaction(emoji, to: itemId) }
        case .sendReadReceiptIfNeeded(let lastVisibleItemID):
            Task { await sendReadReceiptIfNeeded(for: lastVisibleItemID) }
        case .timelineItemMenu(let itemID):
            roomScreenInteractionHandler.showTimelineItemActionMenu(for: itemID)
        case .timelineItemMenuAction(let itemID, let action):
            roomScreenInteractionHandler.processTimelineItemMenuAction(action, itemID: itemID)
        case .handlePasteOrDrop(let provider):
            roomScreenInteractionHandler.handlePasteOrDrop(provider)
        case .tappedOnUser(userID: let userID):
            Task { await roomScreenInteractionHandler.handleTappedUser(userID: userID) }
        case .displayEmojiPicker(let itemID):
            roomScreenInteractionHandler.showEmojiPicker(for: itemID)
        case .reactionSummary(let itemID, let key):
            showReactionSummary(for: itemID, selectedKey: key)
        case .retrySend(let itemID):
            Task { await timelineController.retrySending(itemID: itemID) }
        case .cancelSend(let itemID):
            Task { await timelineController.cancelSending(itemID: itemID) }
        case .paginateBackwards:
            paginateBackwards()
        case .paginateForwards:
            paginateForwards()
        case .poll(let pollAction):
            processPollAction(pollAction)
        case .audio(let audioAction):
            processAudioAction(audioAction)
        case .presentCall:
            actionsSubject.send(.displayCallScreen)
        case .showReadReceipts(itemID: let itemID):
            showReadReceipts(for: itemID)
        case .focusOnEventID(let eventID):
            Task { await focusOnEvent(eventID: eventID) }
        case .focusLive:
            focusLive()
        case .scrolledToFocussedItem:
            // Use a Task to mutate view state after the current view update.
            Task { state.timelineViewState.focussedEventNeedsDisplay = false }
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
        case .attach(let attachment):
            attach(attachment)
        case .handlePasteOrDrop(let provider):
            roomScreenInteractionHandler.handlePasteOrDrop(provider)
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
        if state.timelineViewState.hasLoadedItem(with: eventID) {
            state.timelineViewState.focussedEventID = eventID
            return
        }
        
        showFocusLoadingIndicator()
        defer { hideFocusLoadingIndicator() }
        
        switch await timelineController.focusOnEvent(eventID, timelineSize: Constants.detachedTimelineSize) {
        case .success:
            state.timelineViewState.focussedEventID = eventID
        case .failure(let error):
            MXLog.error("Failed to focus on event \(eventID)")
            
            if case .eventNotFound = error {
                displayError(.toast(L10n.errorMessageNotFound))
            } else {
                displayError(.toast(L10n.commonFailed))
            }
        }
    }
    
    // MARK: - Private
    
    private func focusLive() {
        timelineController.focusLive()
        state.timelineViewState.focussedEventID = nil
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
    
    private func processPollAction(_ action: RoomScreenViewPollAction) {
        switch action {
        case let .selectOption(pollStartID, optionID):
            roomScreenInteractionHandler.sendPollResponse(pollStartID: pollStartID, optionID: optionID)
        case let .end(pollStartID):
            state.bindings.confirmationAlertInfo = .init(id: .init(),
                                                         title: L10n.actionEndPoll,
                                                         message: L10n.commonPollEndConfirmation,
                                                         primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                                         secondaryButton: .init(title: L10n.actionOk, action: { self.roomScreenInteractionHandler.endPoll(pollStartID: pollStartID) }))
        case .edit(let pollStartID, let poll):
            actionsSubject.send(.displayPollForm(mode: .edit(eventID: pollStartID, poll: poll)))
        }
    }
    
    private func processAudioAction(_ action: RoomScreenViewAudioAction) {
        switch action {
        case .playPause(let itemID):
            Task { await roomScreenInteractionHandler.playPauseAudio(for: itemID) }
        case .seek(let itemID, let progress):
            Task { await roomScreenInteractionHandler.seekAudio(for: itemID, progress: progress) }
        }
    }
    
    private func processVoiceMessageAction(_ action: ComposerToolbarVoiceMessageAction) {
        switch action {
        case .startRecording:
            Task {
                await mediaPlayerProvider.detachAllStates(except: nil)
                await roomScreenInteractionHandler.startRecordingVoiceMessage()
            }
        case .stopRecording:
            Task { await roomScreenInteractionHandler.stopRecordingVoiceMessage() }
        case .cancelRecording:
            Task { await roomScreenInteractionHandler.cancelRecordingVoiceMessage() }
        case .deleteRecording:
            Task { await roomScreenInteractionHandler.deleteCurrentVoiceMessage() }
        case .send:
            Task { await roomScreenInteractionHandler.sendCurrentVoiceMessage() }
        case .startPlayback:
            Task { await roomScreenInteractionHandler.startPlayingRecordedVoiceMessage() }
        case .pausePlayback:
            roomScreenInteractionHandler.pausePlayingRecordedVoiceMessage()
        case .seekPlayback(let progress):
            Task { await roomScreenInteractionHandler.seekRecordedVoiceMessage(to: progress) }
        case .scrubPlayback(let scrubbing):
            Task { await roomScreenInteractionHandler.scrubVoiceMessagePlayback(scrubbing: scrubbing) }
        }
    }
    
    private func updateMembers(_ members: [RoomMemberProxyProtocol]) {
        state.members = members.reduce(into: [String: RoomMemberState]()) { dictionary, member in
            dictionary[member.userID] = RoomMemberState(displayName: member.displayName, avatarURL: member.avatarURL)
        }
    }
    
    private func setupSubscriptions() {
        timelineController.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }

                switch callback {
                case .updatedTimelineItems:
                    buildTimelineViews()
                case .paginationState(let paginationState):
                    if state.timelineViewState.paginationState != paginationState {
                        state.timelineViewState.paginationState = paginationState
                    }
                case .isLive(let isLive):
                    if state.timelineViewState.isLive != isLive {
                        state.timelineViewState.isLive = isLive
                        
                        // Remove the event highlight *only* when transitioning from non-live to live.
                        if isLive, state.timelineViewState.focussedEventID != nil {
                            state.timelineViewState.focussedEventID = nil
                        }
                    }
                }
            }
            .store(in: &cancellables)

        roomProxy
            .actionsPublisher
            .filter { $0 == .roomInfoUpdate }
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                self.state.roomTitle = roomProxy.roomTitle
                self.state.roomAvatarURL = roomProxy.avatarURL
                self.state.hasOngoingCall = roomProxy.hasOngoingCall
            }
            .store(in: &cancellables)
        
        roomProxy.timeline.actions
            .filter { $0 == .sentMessage }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.state.timelineViewState.scrollToBottomPublisher.send(())
            }
            .store(in: &cancellables)

        appSettings.$timelineStyle
            .weakAssign(to: \.state.timelineStyle, on: self)
            .store(in: &cancellables)
        
        appSettings.$sharePresence
            .weakAssign(to: \.state.showReadReceipts, on: self)
            .store(in: &cancellables)
        
        roomProxy.membersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateMembers($0) }
            .store(in: &cancellables)
        
        roomProxy.typingMembersPublisher
            .receive(on: DispatchQueue.main)
            .filter { [weak self] _ in self?.appSettings.sharePresence ?? false }
            .weakAssign(to: \.state.typingMembers, on: self)
            .store(in: &cancellables)
        
        roomScreenInteractionHandler.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .composer(let action):
                    actionsSubject.send(.composer(action: action))
                case .displayError(let type):
                    displayError(type)
                case .displayEmojiPicker(let itemID, let selectedEmojis):
                    actionsSubject.send(.displayEmojiPicker(itemID: itemID, selectedEmojis: selectedEmojis))
                case .displayMessageForwarding(let itemID):
                    actionsSubject.send(.displayMessageForwarding(itemID: itemID))
                case .displayPollForm(let mode):
                    actionsSubject.send(.displayPollForm(mode: mode))
                case .displayReportContent(let itemID, let senderID):
                    actionsSubject.send(.displayReportContent(itemID: itemID, senderID: senderID))
                case .displayMediaUploadPreviewScreen(let url):
                    actionsSubject.send(.displayMediaUploadPreviewScreen(url: url))
                case .displayRoomMemberDetails(userID: let userID):
                    actionsSubject.send(.displayRoomMemberDetails(userID: userID))
                case .showActionMenu(let actionMenuInfo):
                    state.bindings.actionMenuInfo = actionMenuInfo
                case .showDebugInfo(let debugInfo):
                    state.bindings.debugInfo = debugInfo
                case .showConfirmationAlert(let alertInfo):
                    state.bindings.confirmationAlertInfo = alertInfo
                }
            }
            .store(in: &cancellables)
    }

    private func setupDirectRoomSubscriptionsIfNeeded() {
        guard roomProxy.isDirect else {
            return
        }

        let shouldShowInviteAlert = composerFocusedSubject
            .removeDuplicates()
            .map { [weak self] isFocused in
                guard let self else { return false }

                return isFocused && self.roomProxy.isUserAloneInDirectRoom
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
                displayError(.toast(L10n.errorFailedLoadingMessages))
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
                displayError(.toast(L10n.errorFailedLoadingMessages))
            default:
                break
            }
            
            if state.timelineViewState.paginationState.forward == .timelineEndReached {
                focusLive()
            }
            
            paginateForwardsTask = nil
        }
    }
    
    private func sendReadReceiptIfNeeded(for lastVisibleItemID: TimelineItemIdentifier) async {
        guard appMediator.appState == .active else { return }
                
        await timelineController.sendReadReceipt(for: lastVisibleItemID)
    }

    private func handleItemTapped(with itemID: TimelineItemIdentifier) async {
        state.showLoading = true
        let action = await roomScreenInteractionHandler.processItemTap(itemID)

        switch action {
        case .displayMediaFile(let file, let title):
            actionsSubject.send(.composer(action: .removeFocus)) // Hide the keyboard otherwise a big white space is sometimes shown when dismissing the preview.
            state.bindings.mediaPreviewItem = MediaPreviewItem(file: file, title: title)
        case .displayLocation(let body, let geoURI, let description):
            actionsSubject.send(.displayLocation(body: body, geoURI: geoURI, description: description))
        case .none:
            break
        }
        state.showLoading = false
    }

    private func sendCurrentMessage(_ message: String, html: String?, mode: RoomScreenComposerMode, intentionalMentions: IntentionalMentions) async {
        guard !message.isEmpty else {
            fatalError("This message should never be empty")
        }

        actionsSubject.send(.composer(action: .clear))

        switch mode {
        case .reply(let itemId, _, _):
            await timelineController.sendMessage(message,
                                                 html: html,
                                                 inReplyTo: itemId,
                                                 intentionalMentions: intentionalMentions)
        case .edit(let originalItemId):
            await timelineController.editMessage(message,
                                                 html: html,
                                                 original: originalItemId,
                                                 intentionalMentions: intentionalMentions)
        case .default:
            await timelineController.sendMessage(message,
                                                 html: html,
                                                 intentionalMentions: intentionalMentions)
        case .recordVoiceMessage, .previewVoiceMessage:
            fatalError("invalid composer mode.")
        }
    }
        
    private func trackComposerMode(_ mode: RoomScreenComposerMode) {
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
    
    // MARK: - Timeline Item Building
    
    private func buildTimelineViews() {
        var timelineItemsDictionary = OrderedDictionary<String, RoomTimelineItemViewState>()
        
        timelineController.timelineItems.filter { $0 is RedactedRoomTimelineItem }.forEach { timelineItem in
            // Stops the audio player when a voice message is redacted.
            guard let playerState = mediaPlayerProvider.playerState(for: .timelineItemIdentifier(timelineItem.id)) else {
                return
            }
            
            Task { @MainActor in
                playerState.detachAudioPlayer()
                mediaPlayerProvider.unregister(audioPlayerState: playerState)
            }
        }

        let itemsGroupedByTimelineDisplayStyle = timelineController.timelineItems.chunked { current, next in
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
                                                        forKey: firstItem.id.timelineID)
                }
            } else {
                for (index, item) in itemGroup.enumerated() {
                    if index == 0 {
                        timelineItemsDictionary.updateValue(updateViewState(item: item, groupStyle: .first),
                                                            forKey: item.id.timelineID)
                    } else if index == itemGroup.count - 1 {
                        timelineItemsDictionary.updateValue(updateViewState(item: item, groupStyle: .last),
                                                            forKey: item.id.timelineID)
                    } else {
                        timelineItemsDictionary.updateValue(updateViewState(item: item, groupStyle: .middle),
                                                            forKey: item.id.timelineID)
                    }
                }
            }
        }
        
        state.timelineViewState.itemsDictionary = timelineItemsDictionary
    }

    private func updateViewState(item: RoomTimelineItemProtocol, groupStyle: TimelineGroupStyle) -> RoomTimelineItemViewState {
        if let timelineItemViewState = state.timelineViewState.itemsDictionary[item.id.timelineID] {
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
        
        //  can be improved by adding a date threshold
        return eventTimelineItem.properties.reactions.isEmpty && eventTimelineItem.sender == otherEventTimelineItem.sender
    }

    // MARK: - Direct chats logics

    private func showInviteAlert() {
        userIndicatorController.alertInfo = .init(id: .init(),
                                                  title: L10n.screenRoomInviteAgainAlertTitle,
                                                  message: L10n.screenRoomInviteAgainAlertMessage,
                                                  primaryButton: .init(title: L10n.actionInvite, action: { [weak self] in self?.inviteOtherDMUserBack() }),
                                                  secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
    }

    private let inviteLoadingIndicatorID = UUID().uuidString

    private func inviteOtherDMUserBack() {
        guard roomProxy.isUserAloneInDirectRoom else {
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
        
    private func showReactionSummary(for itemID: TimelineItemIdentifier, selectedKey: String) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        state.bindings.reactionSummaryInfo = .init(reactions: eventTimelineItem.properties.reactions, selectedKey: selectedKey)
    }
    
    // MARK: - Read Receipts

    private func showReadReceipts(for itemID: TimelineItemIdentifier) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        state.bindings.readReceiptsSummaryInfo = .init(orderedReceipts: eventTimelineItem.properties.orderedReadReceipts, id: eventTimelineItem.id)
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
    
    private func displayError(_ type: RoomScreenErrorType) {
        switch type {
        case .alert(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonError,
                                                 message: message)
        case .toast(let message):
            userIndicatorController.submitIndicator(UserIndicator(id: Constants.toastErrorID,
                                                                  type: .toast,
                                                                  title: message,
                                                                  iconName: "xmark"))
        }
    }
}

private extension RoomProxyProtocol {
    /// Checks if the other person left the room in a direct chat
    var isUserAloneInDirectRoom: Bool {
        isDirect && activeMembersCount == 1
    }
}

// MARK: - Mocks

extension RoomScreenViewModel {
    static let mock = RoomScreenViewModel(roomProxy: RoomProxyMock(with: .init(name: "Preview room")),
                                          focussedEventID: nil,
                                          timelineController: MockRoomTimelineController(),
                                          mediaProvider: MockMediaProvider(),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics,
                                          notificationCenter: NotificationCenterMock())
}

private struct RoomContextKey: EnvironmentKey {
    @MainActor static let defaultValue = RoomScreenViewModel.mock.context
}

private struct FocussedEventID: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    /// Used to access and inject the room context without observing it
    var roomContext: RoomScreenViewModel.Context {
        get { self[RoomContextKey.self] }
        set { self[RoomContextKey.self] = newValue }
    }
    
    /// An event ID which will be non-nil when a timeline item should show as focussed.
    var focussedEventID: String? {
        get { self[FocussedEventID.self] }
        set { self[FocussedEventID.self] = newValue }
    }
}

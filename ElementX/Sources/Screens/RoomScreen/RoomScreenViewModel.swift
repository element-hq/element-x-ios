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
         analyticsService: AnalyticsService) {
        self.timelineController = timelineController
        self.mediaPlayerProvider = mediaPlayerProvider
        self.roomProxy = roomProxy
        self.appSettings = appSettings
        self.analyticsService = analyticsService
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        
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
        
        super.init(initialViewState: RoomScreenViewState(roomID: roomProxy.id,
                                                         roomTitle: roomProxy.roomTitle,
                                                         roomAvatar: roomProxy.avatar,
                                                         isEncryptedOneToOneRoom: roomProxy.isEncryptedOneToOneRoom,
                                                         timelineViewState: TimelineViewState(focussedEvent: focussedEventID.map { .init(eventID: $0, appearance: .immediate) }),
                                                         ownUserID: roomProxy.ownUserID,
                                                         isViewSourceEnabled: appSettings.viewSourceEnabled,
                                                         hasOngoingCall: roomProxy.hasOngoingCall,
                                                         bindings: .init(reactionsCollapsed: [:])),
                   imageProvider: mediaProvider)
        
        if focussedEventID != nil {
            // The timeline controller will start loading a detached timeline.
            showFocusLoadingIndicator()
        }
        
        setupSubscriptions()
        setupDirectRoomSubscriptionsIfNeeded()
        
        // Set initial values for redacting from the macOS context menu.
        Task { await updatePermissions() }

        state.audioPlayerStateProvider = { [weak self] itemID -> AudioPlayerState? in
            guard let self else {
                return nil
            }
            
            return self.roomScreenInteractionHandler.audioPlayerState(for: itemID)
        }
        
        buildTimelineViews(timelineItems: timelineController.timelineItems)
        
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
    
    func loadDraft() {
        actionsSubject.send(.composer(action: .loadDraft))
    }
    
    func stop() {
        // Work around QLPreviewController dismissal issues, see the InteractiveQuickLookModifier.
        state.bindings.mediaPreviewItem = nil
    }
    
    func saveDraft() {
        actionsSubject.send(.composer(action: .saveDraft))
    }
    
    override func process(viewAction: RoomScreenViewAction) {
        switch viewAction {
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
        case .paginateBackwards:
            paginateBackwards()
        case .paginateForwards:
            paginateForwards()
        case .scrollToBottom:
            scrollToBottom()
            
        case .displayTimelineItemMenu(let itemID):
            roomScreenInteractionHandler.displayTimelineItemActionMenu(for: itemID)
        case .handleTimelineItemMenuAction(let itemID, let action):
            roomScreenInteractionHandler.handleTimelineItemMenuAction(action, itemID: itemID)
            
        case .displayRoomDetails:
            actionsSubject.send(.displayRoomDetails)
        case .displayRoomMemberDetails(userID: let userID):
            Task { await roomScreenInteractionHandler.displayRoomMemberDetails(userID: userID) }
        case .displayEmojiPicker(let itemID):
            roomScreenInteractionHandler.displayEmojiPicker(for: itemID)
        case .displayReactionSummary(let itemID, let key):
            displayReactionSummary(for: itemID, selectedKey: key)
        case .displayReadReceipts(itemID: let itemID):
            displayReadReceipts(for: itemID)
        case .displayCall:
            actionsSubject.send(.displayCallScreen)
            analyticsService.trackInteraction(name: .MobileRoomCallButton)
        case .handlePasteOrDrop(let provider):
            roomScreenInteractionHandler.handlePasteOrDrop(provider)
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
            Task { state.timelineViewState.isSwitchingTimelines = false }
        case let .hasScrolled(direction):
            state.lastScrollDirection = direction
        case .tappedPinBanner:
            if let eventID = state.pinnedEventsState.selectedPinEventID {
                Task { await focusOnEvent(eventID: eventID) }
            }
            state.pinnedEventsState.nextPin()
        case .viewAllPins:
            // TODO: Implement
            break
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
            state.timelineViewState.focussedEvent = .init(eventID: eventID, appearance: .animated)
            return
        }
        
        showFocusLoadingIndicator()
        defer { hideFocusLoadingIndicator() }
        
        switch await timelineController.focusOnEvent(eventID, timelineSize: Constants.detachedTimelineSize) {
        case .success:
            state.timelineViewState.focussedEvent = .init(eventID: eventID, appearance: .immediate)
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
    
    private func focusLive() {
        timelineController.focusLive()
    }
    
    private func didScrollToFocussedItem() {
        if var focussedEvent = state.timelineViewState.focussedEvent {
            focussedEvent.appearance = .hasAppeared
            state.timelineViewState.focussedEvent = focussedEvent
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
        
        roomScreenInteractionHandler.handleTimelineItemMenuAction(.edit, itemID: item.id)
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
    
    private func handlePollAction(_ action: RoomScreenViewPollAction) {
        switch action {
        case let .selectOption(pollStartID, optionID):
            roomScreenInteractionHandler.sendPollResponse(pollStartID: pollStartID, optionID: optionID)
        case let .end(pollStartID):
            displayAlert(.pollEndConfirmation(pollStartID))
        case .edit(let pollStartID, let poll):
            actionsSubject.send(.displayPollForm(mode: .edit(eventID: pollStartID, poll: poll)))
        }
    }
    
    private func handleAudioPlayerAction(_ action: RoomScreenAudioPlayerAction) {
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
    
    private func updatePermissions() async {
        if case let .success(value) = await roomProxy.canUserRedactOther(userID: roomProxy.ownUserID) {
            state.canCurrentUserRedactOthers = value
        } else {
            state.canCurrentUserRedactOthers = false
        }
        
        if case let .success(value) = await roomProxy.canUserRedactOwn(userID: roomProxy.ownUserID) {
            state.canCurrentUserRedactSelf = value
        } else {
            state.canCurrentUserRedactSelf = false
        }
        
        if state.isPinningEnabled,
           case let .success(value) = await roomProxy.canUserPinOrUnpin(userID: roomProxy.ownUserID) {
            state.canCurrentUserPin = value
        } else {
            state.canCurrentUserPin = false
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
                    if state.timelineViewState.paginationState != paginationState {
                        state.timelineViewState.paginationState = paginationState
                    }
                case .isLive(let isLive):
                    if state.timelineViewState.isLive != isLive {
                        state.timelineViewState.isLive = isLive
                        
                        // Remove the event highlight *only* when transitioning from non-live to live.
                        if isLive, state.timelineViewState.focussedEvent != nil {
                            state.timelineViewState.focussedEvent = nil
                        }
                    }
                }
            }
            .store(in: &cancellables)

        let roomInfoSubscription = roomProxy
            .actionsPublisher
            .filter { $0 == .roomInfoUpdate }
        
        roomInfoSubscription
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                state.roomTitle = roomProxy.roomTitle
                state.roomAvatar = roomProxy.avatar
                state.hasOngoingCall = roomProxy.hasOngoingCall
            }
            .store(in: &cancellables)
        
        Task { [weak self] in
            guard let self else {
                return
            }
            // If the subscription has sent a value before the Task has started it might be lost, so before entering the loop we always do an update.
            await state.pinnedEventsState.pinnedEventIDs = .init(roomProxy.pinnedEventIDs)
            for await _ in roomInfoSubscription.receive(on: DispatchQueue.main).values {
                guard !Task.isCancelled else {
                    return
                }
                await state.pinnedEventsState.pinnedEventIDs = .init(roomProxy.pinnedEventIDs)
            }
        }
        .store(in: &cancellables)
        
        appSettings.$sharePresence
            .weakAssign(to: \.state.showReadReceipts, on: self)
            .store(in: &cancellables)
        
        appSettings.$viewSourceEnabled
            .weakAssign(to: \.state.isViewSourceEnabled, on: self)
            .store(in: &cancellables)
        
        appSettings.$pinningEnabled
            .weakAssign(to: \.state.isPinningEnabled, on: self)
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
                case .displayRoomMemberDetails(userID: let userID):
                    actionsSubject.send(.displayRoomMemberDetails(userID: userID))
                case .showActionMenu(let actionMenuInfo):
                    Task {
                        await self.updatePermissions()
                        self.state.bindings.actionMenuInfo = actionMenuInfo
                    }
                case .showDebugInfo(let debugInfo):
                    state.bindings.debugInfo = debugInfo
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
            
            if state.timelineViewState.paginationState.forward == .timelineEndReached {
                focusLive()
            }
            
            paginateForwardsTask = nil
        }
    }
    
    private func scrollToBottom() {
        if state.timelineViewState.isLive {
            state.timelineViewState.scrollToBottomPublisher.send(())
        } else {
            focusLive()
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
            await timelineController.edit(originalItemId,
                                          message: message,
                                          html: html,
                                          intentionalMentions: intentionalMentions)
        case .default:
            await timelineController.sendMessage(message,
                                                 html: html,
                                                 intentionalMentions: intentionalMentions)
        case .recordVoiceMessage, .previewVoiceMessage:
            fatalError("invalid composer mode.")
        }
        
        scrollToBottom()
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
    
    private func buildTimelineViews(timelineItems: [RoomTimelineItemProtocol], isSwitchingTimelines: Bool = false) {
        var timelineItemsDictionary = OrderedDictionary<String, RoomTimelineItemViewState>()
        
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
        
        if isSwitchingTimelines {
            state.timelineViewState.isSwitchingTimelines = true
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
    
    private func displayAlert(_ type: RoomScreenAlertInfoType) {
        switch type {
        case .audioRecodingPermissionError:
            state.bindings.alertInfo = .init(id: type,
                                             title: L10n.dialogPermissionMicrophoneTitleIos(InfoPlistReader.main.bundleDisplayName),
                                             message: L10n.dialogPermissionMicrophoneDescriptionIos,
                                             primaryButton: .init(title: L10n.commonSettings, action: { [weak self] in self?.appMediator.openAppSettings() }),
                                             secondaryButton: .init(title: L10n.actionNotNow, role: .cancel, action: nil))
        case .pollEndConfirmation(let pollStartID):
            state.bindings.alertInfo = .init(id: type,
                                             title: L10n.actionEndPoll,
                                             message: L10n.commonPollEndConfirmation,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                             secondaryButton: .init(title: L10n.actionOk, action: { self.roomScreenInteractionHandler.endPoll(pollStartID: pollStartID) }))
        }
    }
    
    private func displayErrorToast(_ title: String) {
        userIndicatorController.submitIndicator(UserIndicator(id: Constants.toastErrorID,
                                                              type: .toast,
                                                              title: title,
                                                              iconName: "xmark"))
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
    static let mock = RoomScreenViewModel(roomProxy: RoomProxyMock(.init(name: "Preview room")),
                                          focussedEventID: nil,
                                          timelineController: MockRoomTimelineController(),
                                          mediaProvider: MockMediaProvider(),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                          appMediator: AppMediatorMock.default,
                                          appSettings: ServiceLocator.shared.settings,
                                          analyticsService: ServiceLocator.shared.analytics)
}

private struct RoomContextKey: EnvironmentKey {
    @MainActor static let defaultValue: RoomScreenViewModel.Context? = nil
}

private struct FocussedEventID: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    /// Used to access and inject the room context without observing it
    var roomContext: RoomScreenViewModel.Context? {
        get { self[RoomContextKey.self] }
        set { self[RoomContextKey.self] = newValue }
    }

    /// An event ID which will be non-nil when a timeline item should show as focussed.
    var focussedEventID: String? {
        get { self[FocussedEventID.self] }
        set { self[FocussedEventID.self] = newValue }
    }
}

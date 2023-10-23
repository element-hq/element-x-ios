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
        static let backPaginationEventLimit: UInt = 20
        static let backPaginationPageSize: UInt = 50
        static let toastErrorID = "RoomScreenToastError"
    }

    private let timelineController: RoomTimelineControllerProtocol
    private let roomProxy: RoomProxyProtocol
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    private unowned let userIndicatorController: UserIndicatorControllerProtocol
    private let notificationCenterProtocol: NotificationCenterProtocol
    private let voiceMessageRecorder: VoiceMessageRecorderProtocol
    private let composerFocusedSubject = PassthroughSubject<Bool, Never>()
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    private let actionsSubject: PassthroughSubject<RoomScreenViewModelAction, Never> = .init()
    private var canCurrentUserRedact = false
    private var paginateBackwardsTask: Task<Void, Never>?

    init(timelineController: RoomTimelineControllerProtocol,
         mediaProvider: MediaProviderProtocol,
         mediaPlayerProvider: MediaPlayerProviderProtocol,
         roomProxy: RoomProxyProtocol,
         appSettings: AppSettings,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol,
         notificationCenterProtocol: NotificationCenterProtocol = NotificationCenter.default) {
        self.roomProxy = roomProxy
        self.timelineController = timelineController
        self.appSettings = appSettings
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        self.notificationCenterProtocol = notificationCenterProtocol
        self.mediaPlayerProvider = mediaPlayerProvider
        voiceMessageRecorder = VoiceMessageRecorder(audioRecorder: AudioRecorder(), mediaPlayerProvider: mediaPlayerProvider)
        
        super.init(initialViewState: RoomScreenViewState(roomID: timelineController.roomID,
                                                         roomTitle: roomProxy.roomTitle,
                                                         roomAvatarURL: roomProxy.avatarURL,
                                                         timelineStyle: appSettings.timelineStyle,
                                                         readReceiptsEnabled: appSettings.readReceiptsEnabled,
                                                         isEncryptedOneToOneRoom: roomProxy.isEncryptedOneToOneRoom,
                                                         ownUserID: roomProxy.ownUserID,
                                                         isCallOngoing: roomProxy.isCallOngoing,
                                                         bindings: .init(reactionsCollapsed: [:])),
                   imageProvider: mediaProvider)
        
        setupSubscriptions()
        setupDirectRoomSubscriptionsIfNeeded()

        state.timelineItemMenuActionProvider = { [weak self] itemId -> TimelineItemMenuActions? in
            guard let self else {
                return nil
            }
            
            return self.timelineItemMenuActionsForItemId(itemId)
        }

        state.audioPlayerStateProvider = { [weak self] itemId -> AudioPlayerState? in
            guard let self else {
                return nil
            }
            
            return self.audioPlayerState(for: itemId)
        }
        
        buildTimelineViews()

        // Note: beware if we get to e.g. restore a reply / edit,
        // maybe we are tracking a non-needed first initial state
        trackComposerMode(.default)
    }
    
    // MARK: - Public

    var actions: AnyPublisher<RoomScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
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
            Task { await itemTapped(with: id) }
        case .toggleReaction(let emoji, let itemId):
            Task { await timelineController.toggleReaction(emoji, to: itemId) }
        case .sendReadReceiptIfNeeded(let lastVisibleItemID):
            Task { await sendReadReceiptIfNeeded(for: lastVisibleItemID) }
        case .timelineItemMenu(let itemID):
            Task {
                if case let .success(value) = await roomProxy.canUserRedact(userID: roomProxy.ownUserID) {
                    canCurrentUserRedact = value
                } else {
                    canCurrentUserRedact = false
                }
                showTimelineItemActionMenu(for: itemID)
            }
        case .timelineItemMenuAction(let itemID, let action):
            processTimelineItemMenuAction(action, itemID: itemID)
        case .handlePasteOrDrop(let provider):
            handlePasteOrDrop(provider)
        case .tappedOnUser(userID: let userID):
            Task { await handleTappedUser(userID: userID) }
        case .displayEmojiPicker(let itemID):
            showEmojiPicker(for: itemID)
        case .reactionSummary(let itemID, let key):
            showReactionSummary(for: itemID, selectedKey: key)
        case .retrySend(let itemID):
            Task { await handleRetrySend(itemID: itemID) }
        case .cancelSend(let itemID):
            Task { await handleCancelSend(itemID: itemID) }
        case .paginateBackwards:
            paginateBackwards()
        case .scrolledToBottom:
            if state.swiftUITimelineEnabled {
                renderPendingTimelineItems()
            }
        case let .selectedPollOption(pollStartID, optionID):
            sendPollResponse(pollStartID: pollStartID, optionID: optionID)
        case .playPauseAudio(let itemID):
            Task { await timelineController.playPauseAudio(for: itemID) }
        case .seekAudio(let itemID, let progress):
            Task { await timelineController.seekAudio(for: itemID, progress: progress) }
        case .enableLongPress(let itemID):
            guard state.longPressDisabledItemID == itemID else { return }
            state.longPressDisabledItemID = nil
        case .disableLongPress(let itemID):
            state.longPressDisabledItemID = itemID
        case let .endPoll(pollStartID):
            state.bindings.confirmationAlertInfo = .init(id: .init(),
                                                         title: L10n.actionEndPoll,
                                                         message: L10n.commonPollEndConfirmation,
                                                         primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                                         secondaryButton: .init(title: L10n.actionOk, action: { self.endPoll(pollStartID: pollStartID) }))
        case .presentCall:
            actionsSubject.send(.displayCallScreen)
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
        case .displayCameraPicker:
            actionsSubject.send(.displayCameraPicker)
        case .displayMediaPicker:
            actionsSubject.send(.displayMediaPicker)
        case .displayDocumentPicker:
            actionsSubject.send(.displayDocumentPicker)
        case .displayLocationPicker:
            actionsSubject.send(.displayLocationPicker)
        case .displayPollForm:
            actionsSubject.send(.displayPollForm)
        case .handlePasteOrDrop(let provider):
            handlePasteOrDrop(provider)
        case .composerModeChanged(mode: let mode):
            trackComposerMode(mode)
        case .composerFocusedChanged(isFocused: let isFocused):
            composerFocusedSubject.send(isFocused)
        case .startVoiceMessageRecording:
            Task {
                await mediaPlayerProvider.detachAllStates(except: nil)
                await startRecordingVoiceMessage()
            }
        case .stopVoiceMessageRecording:
            Task { await stopRecordingVoiceMessage() }
        case .cancelVoiceMessageRecording:
            Task { await cancelRecordingVoiceMessage() }
        case .deleteVoiceMessageRecording:
            Task { await deleteCurrentVoiceMessage() }
        case .sendVoiceMessage:
            Task { await sendCurrentVoiceMessage() }
        case .startVoiceMessagePlayback:
            Task {
                await mediaPlayerProvider.detachAllStates(except: voiceMessageRecorder.previewAudioPlayerState)
                await startPlayingRecordedVoiceMessage()
            }
        case .pauseVoiceMessagePlayback:
            pausePlayingRecordedVoiceMessage()
        case .seekVoiceMessagePlayback(let progress):
            Task { await seekRecordedVoiceMessage(to: progress) }
        }
    }
    
    // MARK: - Private

    private func setupSubscriptions() {
        appSettings.$swiftUITimelineEnabled
            .weakAssign(to: \.state.swiftUITimelineEnabled, on: self)
            .store(in: &cancellables)

        timelineController.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }

                switch callback {
                case .updatedTimelineItems:
                    self.buildTimelineViews()
                case .canBackPaginate(let canBackPaginate):
                    if self.state.timelineViewState.canBackPaginate != canBackPaginate {
                        self.state.timelineViewState.canBackPaginate = canBackPaginate
                    }
                case .isBackPaginating(let isBackPaginating):
                    if self.state.timelineViewState.isBackPaginating != isBackPaginating {
                        self.state.timelineViewState.isBackPaginating = isBackPaginating
                    }
                }
            }
            .store(in: &cancellables)

        roomProxy
            .stateUpdatesPublisher
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                self.state.roomTitle = roomProxy.roomTitle
                self.state.roomAvatarURL = roomProxy.avatarURL
            }
            .store(in: &cancellables)

        appSettings.$timelineStyle
            .weakAssign(to: \.state.timelineStyle, on: self)
            .store(in: &cancellables)

        appSettings.$readReceiptsEnabled
            .weakAssign(to: \.state.readReceiptsEnabled, on: self)
            .store(in: &cancellables)
        
        appSettings.$elementCallEnabled
            .weakAssign(to: \.state.showCallButton, on: self)
            .store(in: &cancellables)
        
        roomProxy.members
            .map { members in
                members.reduce(into: [String: RoomMemberState]()) { dictionary, member in
                    dictionary[member.userID] = RoomMemberState(displayName: member.displayName, avatarURL: member.avatarURL)
                }
            }
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.members, on: self)
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

            switch await timelineController.paginateBackwards(requestSize: Constants.backPaginationEventLimit, untilNumberOfItems: Constants.backPaginationPageSize) {
            case .failure:
                displayError(.toast(L10n.errorFailedLoadingMessages))
            default:
                break
            }
            paginateBackwardsTask = nil
        }
    }
    
    /// The ID of the newest item in the room that the user has seen.
    /// This includes both event based items and virtual items.
    private var lastReadItemID: TimelineItemIdentifier?
    private func sendReadReceiptIfNeeded(for lastVisibleItemID: TimelineItemIdentifier) async -> Result<Void, RoomTimelineControllerError> {
        guard lastReadItemID != lastVisibleItemID,
              let eventItemID = eventBasedItem(nearest: lastVisibleItemID)
        else { return .success(()) }
        
        // Make sure the item is newer than the item that was last marked as read.
        if let lastReadItemIndex = state.timelineViewState.timelineIDs.firstIndex(of: lastReadItemID?.timelineID ?? ""),
           let lastVisibleItemIndex = state.timelineViewState.timelineIDs.firstIndex(of: eventItemID.timelineID),
           lastReadItemIndex > lastVisibleItemIndex {
            return .success(())
        }
        
        // Update the last read item ID to avoid attempting duplicate requests.
        lastReadItemID = lastVisibleItemID
        
        // Clear any notifications from notification center.
        if lastVisibleItemID.timelineID == state.timelineViewState.timelineIDs.last {
            notificationCenterProtocol.post(name: .roomMarkedAsRead, object: roomProxy.id)
        }
        
        switch await timelineController.sendReadReceipt(for: eventItemID) {
        case .success:
            return .success(())
        case .failure:
            return .failure(.generic)
        }
    }
    
    /// Returns the first item ID that contains an `eventID` starting from the supplied ID, working backwards through the timeline.
    private func eventBasedItem(nearest itemID: TimelineItemIdentifier) -> TimelineItemIdentifier? {
        guard itemID.eventID == nil else { return itemID }
        
        let timelineIDs = state.timelineViewState.itemViewStates.map(\.identifier)
        guard let index = timelineIDs.firstIndex(of: itemID) else { return nil }
        
        let nearestItemID = timelineIDs[..<index].last(where: { $0.eventID != nil })
        return nearestItemID
    }

    private func itemTapped(with itemID: TimelineItemIdentifier) async {
        state.showLoading = true
        let action = await timelineController.processItemTap(itemID)

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
        
    private func buildTimelineViews() {
        var timelineItemsDictionary = OrderedDictionary<String, RoomTimelineItemViewState>()

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
        
        // The SwiftUI scroll view needs special handling, see `selectivelyUpdateTimelineItems`
        if state.swiftUITimelineEnabled {
            selectivelyUpdateTimelineItems(timelineItemsDictionary: timelineItemsDictionary)
        } else {
            state.timelineViewState.itemsDictionary = timelineItemsDictionary
            state.timelineViewState.renderedTimelineIDs = Array(timelineItemsDictionary.keys)
        }
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
    
    /// With the timeline scroll being reversed, introducing items at it's top (i.e. bottom now) will make the content move upwards, which is unwanted when
    /// reading history. Delay rendering new items until it reaches the bottom again.
    private func selectivelyUpdateTimelineItems(timelineItemsDictionary: OrderedDictionary<String, RoomTimelineItemViewState>) {
        var timelineViewState = state.timelineViewState
        
        let newItemIdentifiers = Array(timelineItemsDictionary.keys)
        
        if !state.bindings.isScrolledToBottom,
           let lastItemIdentifier = state.timelineViewState.renderedTimelineIDs.last,
           let newLastItemIdentifierIndex = newItemIdentifiers.firstIndex(where: { $0 == lastItemIdentifier }) {
            timelineViewState.pendingTimelineIDs = Array(newItemIdentifiers.dropFirst(newLastItemIdentifierIndex + 1))
            timelineViewState.renderedTimelineIDs = Array(newItemIdentifiers.dropLast(newItemIdentifiers.count - (newLastItemIdentifierIndex + 1)))
        } else {
            // Otherwise just render everything normally
            timelineViewState.renderedTimelineIDs = Array(timelineItemsDictionary.keys)
        }
        
        timelineViewState.itemsDictionary = timelineItemsDictionary
        
        state.timelineViewState = timelineViewState
    }
    
    private func renderPendingTimelineItems() {
        // Render pending timeline items when the scroll view reaches the bottom again
        guard state.bindings.isScrolledToBottom,
              state.timelineViewState.pendingTimelineIDs.count > 0 else {
            return
        }
        
        var newTimelineViewState = state.timelineViewState
        newTimelineViewState.renderedTimelineIDs = state.timelineViewState.renderedTimelineIDs + state.timelineViewState.pendingTimelineIDs
        newTimelineViewState.pendingTimelineIDs = []
        state.timelineViewState = newTimelineViewState
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

        analytics.trackComposer(inThread: false, isEditing: isEdit, isReply: isReply, startsThread: nil)
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
    
    // MARK: TimelineItemActionMenu
    
    private func showTimelineItemActionMenu(for itemID: TimelineItemIdentifier) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            // Don't show a menu for non-event based items.
            return
        }

        actionsSubject.send(.composer(action: .removeFocus))
        state.bindings.actionMenuInfo = .init(item: eventTimelineItem)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func timelineItemMenuActionsForItemId(_ itemID: TimelineItemIdentifier) -> TimelineItemMenuActions? {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              let item = timelineItem as? EventBasedTimelineItemProtocol else {
            // Don't show a context menu for non-event based items.
            return nil
        }

        if timelineItem is StateRoomTimelineItem {
            // Don't show a context menu for state events.
            return nil
        }

        var debugActions: [TimelineItemMenuAction] = []
        if appSettings.canShowDeveloperOptions || appSettings.viewSourceEnabled {
            debugActions.append(.viewSource)
        }

        if let encryptedItem = timelineItem as? EncryptedRoomTimelineItem {
            switch encryptedItem.encryptionType {
            case .megolmV1AesSha2(let sessionID):
                debugActions.append(.retryDecryption(sessionID: sessionID))
            default:
                break
            }
            
            return .init(actions: [.copyPermalink], debugActions: debugActions)
        }
        
        var actions: [TimelineItemMenuAction] = []

        if item.canBeRepliedTo {
            if let messageItem = item as? EventBasedMessageTimelineItemProtocol {
                actions.append(.reply(isThread: messageItem.isThreaded))
            } else {
                actions.append(.reply(isThread: false))
            }
        }
        
        if item.isRemoteMessage {
            actions.append(.forward(itemID: itemID))
        }

        if item.isEditable {
            actions.append(.edit)
        }

        if item.isCopyable {
            actions.append(.copy)
        }
        
        actions.append(.copyPermalink)

        if canRedactItem(item), let poll = item.pollIfAvailable, !poll.hasEnded, let eventID = itemID.eventID {
            actions.append(.endPoll(pollStartID: eventID))
        }
        
        if canRedactItem(item) {
            actions.append(.redact)
        }

        if !item.isOutgoing {
            actions.append(.report)
        }

        if item.hasFailedToSend {
            actions = actions.filter(\.canAppearInFailedEcho)
        }

        if item.isRedacted {
            actions = actions.filter(\.canAppearInRedacted)
        }

        return .init(actions: actions, debugActions: debugActions)
    }

    private func canRedactItem(_ item: EventBasedTimelineItemProtocol) -> Bool {
        item.isOutgoing || (canCurrentUserRedact && !roomProxy.isDirect)
    }
    
    private func processTimelineItemMenuAction(_ action: TimelineItemMenuAction, itemID: TimelineItemIdentifier) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        switch action {
        case .copy:
            guard let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol else {
                return
            }
            
            UIPasteboard.general.string = messageTimelineItem.body
        case .edit:
            guard let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol else {
                return
            }

            let text: String
            switch messageTimelineItem.contentType {
            case .text(let textItem):
                if ServiceLocator.shared.settings.richTextEditorEnabled, let formattedBodyHTMLString = textItem.formattedBodyHTMLString {
                    text = formattedBodyHTMLString
                } else {
                    text = messageTimelineItem.body
                }
            case .emote(let emoteItem):
                if ServiceLocator.shared.settings.richTextEditorEnabled, let formattedBodyHTMLString = emoteItem.formattedBodyHTMLString {
                    text = "/me " + formattedBodyHTMLString
                } else {
                    text = "/me " + messageTimelineItem.body
                }
            default:
                text = messageTimelineItem.body
            }
            
            actionsSubject.send(.composer(action: .setText(text: text)))
            actionsSubject.send(.composer(action: .setMode(mode: .edit(originalItemId: messageTimelineItem.id))))
        case .copyPermalink:
            do {
                guard let eventID = eventTimelineItem.id.eventID else {
                    displayError(.alert(L10n.errorFailedCreatingThePermalink))
                    break
                }

                let permalink = try PermalinkBuilder.permalinkTo(eventIdentifier: eventID, roomIdentifier: timelineController.roomID,
                                                                 baseURL: appSettings.permalinkBaseURL)
                UIPasteboard.general.url = permalink
            } catch {
                displayError(.alert(L10n.errorFailedCreatingThePermalink))
            }
        case .redact:
            Task {
                if eventTimelineItem.hasFailedToSend {
                    await timelineController.cancelSend(itemID)
                } else {
                    await timelineController.redact(itemID)
                }
            }
        case .reply:
            let replyInfo = buildReplyInfo(for: eventTimelineItem)
            let replyDetails = TimelineItemReplyDetails.loaded(sender: eventTimelineItem.sender, contentType: replyInfo.type)

            actionsSubject.send(.composer(action: .setMode(mode: .reply(itemID: eventTimelineItem.id, replyDetails: replyDetails, isThread: replyInfo.isThread))))
        case .forward(let itemID):
            actionsSubject.send(.displayMessageForwarding(itemID: itemID))
        case .viewSource:
            let debugInfo = timelineController.debugInfo(for: eventTimelineItem.id)
            MXLog.info(debugInfo)
            state.bindings.debugInfo = debugInfo
        case .retryDecryption(let sessionID):
            Task {
                await timelineController.retryDecryption(for: sessionID)
            }
        case .report:
            actionsSubject.send(.displayReportContent(itemID: itemID, senderID: eventTimelineItem.sender.id))
        case .react:
            showEmojiPicker(for: itemID)
        case .endPoll(let pollStartID):
            endPoll(pollStartID: pollStartID)
        }
        
        if action.switchToDefaultComposer {
            actionsSubject.send(.composer(action: .setMode(mode: .default)))
        }
    }
    
    // Pasting and dropping
    
    private func handlePasteOrDrop(_ provider: NSItemProvider) {
        guard let contentType = provider.preferredContentType,
              let preferredExtension = contentType.preferredFilenameExtension else {
            MXLog.error("Invalid NSItemProvider: \(provider)")
            displayError(.toast(L10n.screenRoomErrorFailedProcessingMedia))
            return
        }
        
        let providerSuggestedName = provider.suggestedName
        let providerDescription = provider.description
        
        _ = provider.loadDataRepresentation(for: contentType) { data, error in
            Task { @MainActor in
                let loadingIndicatorIdentifier = UUID().uuidString
                self.userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
                defer {
                    self.userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier)
                }

                if let error {
                    self.displayError(.toast(L10n.screenRoomErrorFailedProcessingMedia))
                    MXLog.error("Failed processing NSItemProvider: \(providerDescription) with error: \(error)")
                    return
                }

                guard let data else {
                    self.displayError(.toast(L10n.screenRoomErrorFailedProcessingMedia))
                    MXLog.error("Invalid NSItemProvider data: \(providerDescription)")
                    return
                }

                do {
                    let url = try await Task.detached {
                        if let filename = providerSuggestedName {
                            let hasExtension = !(filename as NSString).pathExtension.isEmpty
                            let filename = hasExtension ? filename : "\(filename).\(preferredExtension)"
                            return try FileManager.default.writeDataToTemporaryDirectory(data: data, fileName: filename)
                        } else {
                            let filename = "\(UUID().uuidString).\(preferredExtension)"
                            return try FileManager.default.writeDataToTemporaryDirectory(data: data, fileName: filename)
                        }
                    }.value

                    self.actionsSubject.send(.displayMediaUploadPreviewScreen(url: url))
                } catch {
                    self.displayError(.toast(L10n.screenRoomErrorFailedProcessingMedia))
                    MXLog.error("Failed storing NSItemProvider data \(providerDescription) with error: \(error)")
                }
            }
        }
    }
    
    private func buildReplyInfo(for item: EventBasedTimelineItemProtocol) -> ReplyInfo {
        guard let messageItem = item as? EventBasedMessageTimelineItemProtocol else {
            return .init(type: .text(.init(body: item.body)), isThread: false)
        }
        
        return .init(type: messageItem.contentType, isThread: messageItem.isThreaded)
    }

    private func handleTappedUser(userID: String) async {
        // This is generally fast but it could take some time for rooms with thousands of users on first load
        // Show a loader only if it takes more than 0.1 seconds
        showLoadingIndicator(with: .milliseconds(100))
        let result = await roomProxy.getMember(userID: userID)
        hideLoadingIndicator()
        
        switch result {
        case .success(let member):
            actionsSubject.send(.displayRoomMemberDetails(member: member))
        case .failure(let error):
            displayError(.alert(L10n.screenRoomErrorFailedRetrievingUserDetails))
            MXLog.error("Failed retrieving the user given the following id \(userID) with error: \(error)")
        }
    }

    private func handleRetrySend(itemID: TimelineItemIdentifier) async {
        guard let transactionID = itemID.transactionID else {
            MXLog.error("Failed Retry Send: missing transaction ID")
            return
        }

        await roomProxy.retrySend(transactionID: transactionID)
    }

    private func handleCancelSend(itemID: TimelineItemIdentifier) async {
        guard let transactionID = itemID.transactionID else {
            MXLog.error("Failed Cancel Send: missing transaction ID")
            return
        }

        await roomProxy.cancelSend(transactionID: transactionID)
    }

    private static let loadingIndicatorIdentifier = "RoomScreenLoadingIndicator"

    private func showLoadingIndicator(with delay: Duration) {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: delay)
    }

    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
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
                let otherPerson = members.first(where: { !$0.isAccountOwner && $0.membership == .leave })
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
    
    private func showEmojiPicker(for itemID: TimelineItemIdentifier) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              timelineItem.isReactable,
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        let selectedEmojis = Set(eventTimelineItem.properties.reactions.compactMap { $0.isHighlighted ? $0.key : nil })
        actionsSubject.send(.displayEmojiPicker(itemID: itemID, selectedEmojis: selectedEmojis))
    }
    
    private func showReactionSummary(for itemID: TimelineItemIdentifier, selectedKey: String) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        state.bindings.reactionSummaryInfo = .init(reactions: eventTimelineItem.properties.reactions, selectedKey: selectedKey)
    }

    // MARK: - Polls

    private func sendPollResponse(pollStartID: String, optionID: String) {
        Task {
            let sendPollResponseResult = await roomProxy.sendPollResponse(pollStartID: pollStartID, answers: [optionID])
            analytics.trackPollVote()

            switch sendPollResponseResult {
            case .success:
                break
            case .failure:
                displayError(.toast(L10n.errorUnknown))
            }
        }
    }

    private func endPoll(pollStartID: String) {
        Task {
            let endPollResult = await roomProxy.endPoll(pollStartID: pollStartID,
                                                        text: "The poll with event id: \(pollStartID) has ended")
            analytics.trackPollEnd()
            switch endPollResult {
            case .success:
                break
            case .failure:
                displayError(.toast(L10n.errorUnknown))
            }
        }
    }
    
    // MARK: - Audio
    
    private func audioPlayerState(for itemID: TimelineItemIdentifier) -> AudioPlayerState {
        timelineController.audioPlayerState(for: itemID)
    }
    
    // MARK: - Voice message
    
    private func stopVoiceMessageRecorder() async {
        _ = await voiceMessageRecorder.stopRecording()
        await voiceMessageRecorder.stopPlayback()
    }
    
    private func startRecordingVoiceMessage() async {
        let audioRecordState = AudioRecorderState()
        audioRecordState.attachAudioRecorder(voiceMessageRecorder.audioRecorder)
        
        switch await voiceMessageRecorder.startRecording() {
        case .success:
            actionsSubject.send(.composer(action: .setMode(mode: .recordVoiceMessage(state: audioRecordState))))
        case .failure(let error):
            switch error {
            case .audioRecorderError(.recordPermissionNotGranted):
                state.bindings.confirmationAlertInfo = .init(id: .init(),
                                                             title: "",
                                                             message: L10n.dialogPermissionMicrophone,
                                                             primaryButton: .init(title: L10n.actionOpenSettings, action: { [weak self] in self?.openSystemSettings() }),
                                                             secondaryButton: .init(title: L10n.actionNotNow, role: .cancel, action: nil))
            default:
                MXLog.error("failed to start voice message recording: \(error)")
            }
        }
    }
    
    private func stopRecordingVoiceMessage() async {
        if case .failure(let error) = await voiceMessageRecorder.stopRecording() {
            MXLog.error("failed to stop the recording", context: error)
            return
        }

        guard let audioPlayerState = voiceMessageRecorder.previewAudioPlayerState else {
            MXLog.error("the recorder preview is missing after the recording has been stopped")
            return
        }
        
        guard let recordingURL = voiceMessageRecorder.recordingURL else {
            MXLog.error("the recording URL is missing after the recording has been stopped")
            return
        }
        
        mediaPlayerProvider.register(audioPlayerState: audioPlayerState)
        actionsSubject.send(.composer(action: .setMode(mode: .previewVoiceMessage(state: audioPlayerState, waveform: .url(recordingURL)))))
    }
    
    private func cancelRecordingVoiceMessage() async {
        await voiceMessageRecorder.cancelRecording()
        actionsSubject.send(.composer(action: .setMode(mode: .default)))
    }
    
    private func deleteCurrentVoiceMessage() async {
        await voiceMessageRecorder.deleteRecording()
        actionsSubject.send(.composer(action: .setMode(mode: .default)))
    }
    
    private func sendCurrentVoiceMessage() async {
        await voiceMessageRecorder.stopPlayback()
        switch await voiceMessageRecorder.sendVoiceMessage(inRoom: roomProxy, audioConverter: AudioConverter()) {
        case .success:
            await deleteCurrentVoiceMessage()
        case .failure(let error):
            MXLog.error("failed to send the voice message", context: error)
        }
    }
    
    private func startPlayingRecordedVoiceMessage() async {
        if case .failure(let error) = await voiceMessageRecorder.startPlayback() {
            MXLog.error("failed to play recorded voice message", context: error)
        }
    }
    
    private func pausePlayingRecordedVoiceMessage() {
        voiceMessageRecorder.pausePlayback()
    }
    
    private func seekRecordedVoiceMessage(to progress: Double) async {
        await voiceMessageRecorder.seekPlayback(to: progress)
    }
    
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private extension RoomProxyProtocol {
    /// Checks if the other person left the room in a direct chat
    var isUserAloneInDirectRoom: Bool {
        isDirect && activeMembersCount == 1
    }
}

extension RoomScreenViewModel.Context {
    /// A function to make it easier to bind to reactions expand/collapsed state
    /// - Parameter itemID: The id of the timeline item the reacted to
    /// - Returns: Wether the reactions should show in the collapsed state, true by default.
    func reactionsCollapsedBinding(for itemID: TimelineItemIdentifier) -> Binding<Bool> {
        Binding(get: {
            self.reactionsCollapsed[itemID] ?? true
        }, set: {
            self.reactionsCollapsed[itemID] = $0
        })
    }
}

// MARK: - Mocks

extension RoomScreenViewModel {
    static let mock = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                          mediaProvider: MockMediaProvider(),
                                          mediaPlayerProvider: MediaPlayerProviderMock(),
                                          roomProxy: RoomProxyMock(with: .init(displayName: "Preview room")),
                                          appSettings: ServiceLocator.shared.settings,
                                          analytics: ServiceLocator.shared.analytics,
                                          userIndicatorController: ServiceLocator.shared.userIndicatorController)
}

private struct ReplyInfo {
    let type: EventBasedMessageTimelineItemContentType
    let isThread: Bool
}

private struct RoomContextKey: EnvironmentKey {
    @MainActor
    static let defaultValue = RoomScreenViewModel.mock.context
}

extension EnvironmentValues {
    /// Used to access and inject and access the room context without observing it
    var roomContext: RoomScreenViewModel.Context {
        get { self[RoomContextKey.self] }
        set { self[RoomContextKey.self] = newValue }
    }
}

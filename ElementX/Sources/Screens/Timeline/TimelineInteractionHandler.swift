//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import UIKit

enum TimelineInteractionHandlerAction {
    case composer(action: TimelineComposerAction)
    
    case displayEmojiPicker(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>)
    case displayReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case displayMessageForwarding(itemID: TimelineItemIdentifier)
    case displayMediaUploadPreviewScreen(mediaURLs: [URL])
    case displayPollForm(mode: PollFormMode)
    
    case showActionMenu(TimelineItemActionMenuInfo)
    case showDebugInfo(TimelineItemDebugInfo)
    
    case displayAudioRecorderPermissionError
    case displayErrorToast(String)
    
    case viewInRoomTimeline(eventID: String)
    case displayThread(itemID: TimelineItemIdentifier)
    case showTranslation(text: String)
}

/// The interaction handler groups logic for dealing with various actions the user can take on a timeline's
/// view that would've normally been part of the ``TimelineViewModel``
@MainActor
class TimelineInteractionHandler {
    private let roomProxy: JoinedRoomProxyProtocol
    private let timelineController: TimelineControllerProtocol
    private let userSession: UserSessionProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    private let voiceMessageRecorder: VoiceMessageRecorderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let analyticsService: AnalyticsService
    private let emojiProvider: EmojiProviderProtocol
    private let linkMetadataProvider: LinkMetadataProviderProtocol
    private let timelineControllerFactory: TimelineControllerFactoryProtocol
    private let pollInteractionHandler: PollInteractionHandlerProtocol
    
    private let actionsSubject: PassthroughSubject<TimelineInteractionHandlerAction, Never> = .init()
    var actions: AnyPublisher<TimelineInteractionHandlerAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var voiceMessageRecorderObserver: AnyCancellable? {
        didSet {
            appMediator.setIdleTimerDisabled(voiceMessageRecorderObserver != nil)
        }
    }
    
    private var resumeVoiceMessagePlaybackAfterScrubbing = false
    
    init(roomProxy: JoinedRoomProxyProtocol,
         timelineController: TimelineControllerProtocol,
         userSession: UserSessionProtocol,
         mediaPlayerProvider: MediaPlayerProviderProtocol,
         voiceMessageRecorder: VoiceMessageRecorderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         analyticsService: AnalyticsService,
         emojiProvider: EmojiProviderProtocol,
         linkMetadataProvider: LinkMetadataProviderProtocol,
         timelineControllerFactory: TimelineControllerFactoryProtocol) {
        self.roomProxy = roomProxy
        self.timelineController = timelineController
        self.userSession = userSession
        self.mediaPlayerProvider = mediaPlayerProvider
        self.voiceMessageRecorder = voiceMessageRecorder
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        self.appSettings = appSettings
        self.analyticsService = analyticsService
        self.emojiProvider = emojiProvider
        self.linkMetadataProvider = linkMetadataProvider
        self.timelineControllerFactory = timelineControllerFactory
        
        pollInteractionHandler = PollInteractionHandler(analyticsService: analyticsService,
                                                        timelineController: timelineController)
    }
    
    // MARK: Timeline Item Action Menu
    
    func displayTimelineItemActionMenu(for itemID: TimelineItemIdentifier) {
        Task {
            guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
                  let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
                // Don't show a menu for non-event based items.
                return
            }

            actionsSubject.send(.composer(action: .removeFocus))
            actionsSubject.send(.showActionMenu(.init(item: eventTimelineItem)))
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func handleTimelineItemMenuAction(_ action: TimelineItemMenuAction, itemID: TimelineItemIdentifier) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        switch action {
        case .copy:
            guard let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol else { return }
            UIPasteboard.general.string = messageTimelineItem.body
        case .copyCaption:
            guard let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol,
                  let caption = messageTimelineItem.mediaCaption else {
                return
            }
            UIPasteboard.general.string = caption
        case .edit, .addCaption, .editCaption, .editPoll:
            switch timelineItem {
            case let messageTimelineItem as EventBasedMessageTimelineItemProtocol:
                processEditMessageEvent(messageTimelineItem)
            case let pollTimelineItem as PollRoomTimelineItem:
                guard let eventID = pollTimelineItem.id.eventID else {
                    MXLog.error("Cannot edit poll with id: \(timelineItem.id)")
                    return
                }
                actionsSubject.send(.displayPollForm(mode: .edit(eventID: eventID, poll: pollTimelineItem.poll)))
            default:
                MXLog.error("Cannot edit item with id: \(timelineItem.id)")
            }
        case .removeCaption:
            guard case let .event(_, eventOrTransactionID) = timelineItem.id else {
                MXLog.error("Failed removing caption, missing event ID")
                return
            }
            Task { await timelineController.removeCaption(eventOrTransactionID) }
        case .copyPermalink:
            guard let eventID = eventTimelineItem.id.eventID else {
                actionsSubject.send(.displayErrorToast(L10n.errorFailedCreatingThePermalink))
                return
            }
            
            Task {
                guard case let .success(permalinkURL) = await roomProxy.matrixToEventPermalink(eventID) else {
                    actionsSubject.send(.displayErrorToast(L10n.errorFailedCreatingThePermalink))
                    return
                }
                
                UIPasteboard.general.url = permalinkURL
            }
        case .redact:
            guard case let .event(_, eventOrTransactionID) = itemID else { fatalError() }
            Task { await timelineController.redact(eventOrTransactionID) }
        case .reply:
            guard let eventID = eventTimelineItem.id.eventID else { return }
            
            let replyInfo = buildReplyInfo(for: eventTimelineItem)
            let replyDetails = TimelineItemReplyDetails.loaded(sender: eventTimelineItem.sender, eventID: eventID, eventContent: replyInfo.type)
            
            actionsSubject.send(.composer(action: .setMode(mode: .reply(eventID: eventID, replyDetails: replyDetails, isThread: replyInfo.isThread))))
        case .replyInThread:
            actionsSubject.send(.displayThread(itemID: eventTimelineItem.id))
        case .forward(let itemID):
            actionsSubject.send(.displayMessageForwarding(itemID: itemID))
        case .viewSource:
            let debugInfo = timelineController.debugInfo(for: eventTimelineItem.id)
            MXLog.info("Showing debug info for \(eventTimelineItem.id)")
            actionsSubject.send(.showDebugInfo(debugInfo))
        case .report:
            actionsSubject.send(.displayReportContent(itemID: itemID, senderID: eventTimelineItem.sender.id))
        case .react:
            displayEmojiPicker(for: itemID)
        case .toggleReaction(let key):
            guard case let .event(_, eventOrTransactionID) = itemID else { fatalError() }
            Task { await timelineController.toggleReaction(key, to: eventOrTransactionID) }
        case .endPoll(let pollStartID):
            endPoll(pollStartID: pollStartID)
        case .pin:
            analyticsService.trackPinUnpinEvent(.init(from: timelineController.timelineKind == .pinned ? .MessagePinningList : .Timeline,
                                                      kind: .Pin))
            guard let eventID = itemID.eventID else { return }
            Task { await timelineController.pin(eventID: eventID) }
        case .unpin:
            analyticsService.trackPinUnpinEvent(.init(from: timelineController.timelineKind == .pinned ? .MessagePinningList : .Timeline,
                                                      kind: .Unpin))
            guard let eventID = itemID.eventID else { return }
            Task { await timelineController.unpin(eventID: eventID) }
        case .viewInRoomTimeline:
            analyticsService.trackInteraction(name: .PinnedMessageListViewTimeline)
            guard let eventID = itemID.eventID else { return }
            actionsSubject.send(.viewInRoomTimeline(eventID: eventID))
        case .share:
            break // Handled inline in the media preview screen with a ShareLink.
        case .save:
            break // Handled inline in the media preview screen.
        case .translate:
            guard let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol else { return }
            actionsSubject.send(.showTranslation(text: messageTimelineItem.body))
        }
        
        if action.switchToDefaultComposer {
            actionsSubject.send(.composer(action: .setMode(mode: .default)))
        }
    }
    
    private func processEditMessageEvent(_ messageTimelineItem: EventBasedMessageTimelineItemProtocol) {
        guard case let .event(_, eventOrTransactionID) = messageTimelineItem.id else {
            MXLog.error("Failed editing message, missing event id")
            return
        }
        
        let text: String
        var htmlText: String?
        var editType = ComposerMode.EditType.default
        switch messageTimelineItem.contentType {
        case .text(let content):
            text = content.body
            htmlText = content.formattedBodyHTMLString
        case .emote(let content):
            text = "/me " + content.body
        case .audio(let content):
            text = content.caption ?? ""
            htmlText = content.formattedCaptionHTMLString
            editType = text.isEmpty ? .addCaption : .editCaption
        case .file(let content):
            text = content.caption ?? ""
            htmlText = content.formattedCaptionHTMLString
            editType = text.isEmpty ? .addCaption : .editCaption
        case .image(let content):
            text = content.caption ?? ""
            htmlText = content.formattedCaptionHTMLString
            editType = text.isEmpty ? .addCaption : .editCaption
        case .video(let content):
            text = content.caption ?? ""
            htmlText = content.formattedCaptionHTMLString
            editType = text.isEmpty ? .addCaption : .editCaption
        default:
            text = messageTimelineItem.body
        }
        
        // Always update the mode first and then the text so that the composer has time to save the text draft
        actionsSubject.send(.composer(action: .setMode(mode: .edit(originalEventOrTransactionID: eventOrTransactionID, type: editType))))
        actionsSubject.send(.composer(action: .setText(plainText: text, htmlText: htmlText)))
    }
    
    // MARK: Polls

    func sendPollResponse(pollStartID: String, optionID: String) {
        Task {
            let sendPollResponseResult = await pollInteractionHandler.sendPollResponse(pollStartID: pollStartID, optionID: optionID)
            
            switch sendPollResponseResult {
            case .success:
                break
            case .failure:
                actionsSubject.send(.displayErrorToast(L10n.errorUnknown))
            }
        }
    }
    
    func endPoll(pollStartID: String) {
        Task {
            let endPollResult = await pollInteractionHandler.endPoll(pollStartID: pollStartID)
            
            switch endPollResult {
            case .success:
                break
            case .failure:
                actionsSubject.send(.displayErrorToast(L10n.errorUnknown))
            }
        }
    }
    
    // MARK: Pasting and dropping
    
    func handlePasteOrDrop(_ providers: [NSItemProvider]) {
        Task {
            let loadingIndicatorIdentifier = UUID().uuidString
            self.userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
            defer {
                self.userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier)
            }
            
            var mediaURLs = [URL]()
            for provider in providers {
                if let fileURL = await provider.storeData() {
                    mediaURLs.append(fileURL)
                } else {
                    MXLog.error("Failed storing NSItemProvider data \(provider)")
                    self.actionsSubject.send(.displayErrorToast(L10n.screenRoomErrorFailedProcessingMedia))
                }
            }
            
            if !mediaURLs.isEmpty {
                self.actionsSubject.send(.displayMediaUploadPreviewScreen(mediaURLs: mediaURLs))
            }
        }
    }
    
    // MARK: Voice messages
    
    private func handleVoiceMessageRecorderAction(_ action: VoiceMessageRecorderAction) {
        MXLog.debug("handling voice recorder action: \(action) - (audio)")
        switch action {
        case .didStartRecording(let audioRecorder):
            let audioRecordState = AudioRecorderState()
            audioRecordState.attachAudioRecorder(audioRecorder)
            actionsSubject.send(.composer(action: .setMode(mode: .recordVoiceMessage(state: audioRecordState))))
        case .didStopRecording(let previewAudioPlayerState, let url):
            actionsSubject.send(.composer(action: .setMode(mode: .previewVoiceMessage(state: previewAudioPlayerState, waveform: .url(url), isUploading: false))))
            voiceMessageRecorderObserver = nil
        case .didFailWithError(let error):
            switch error {
            case .audioRecorderError(.recordPermissionNotGranted):
                MXLog.info("permission to record audio has not been granted.")
                actionsSubject.send(.displayAudioRecorderPermissionError)
            default:
                MXLog.error("failed to start voice message recording. \(error)")
                actionsSubject.send(.composer(action: .setMode(mode: .default)))
            }
        }
    }
    
    func startRecordingVoiceMessage() async {
        voiceMessageRecorderObserver = voiceMessageRecorder.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                self?.handleVoiceMessageRecorderAction(action)
            }
        
        await voiceMessageRecorder.startRecording()
    }
    
    func stopRecordingVoiceMessage() async {
        await voiceMessageRecorder.stopRecording()
    }
    
    func cancelRecordingVoiceMessage() async {
        await voiceMessageRecorder.cancelRecording()
        voiceMessageRecorderObserver = nil
        actionsSubject.send(.composer(action: .setMode(mode: .default)))
    }
    
    func deleteCurrentVoiceMessage() async {
        if voiceMessageRecorder.isRecording {
            await voiceMessageRecorder.cancelRecording()
        } else {
            await voiceMessageRecorder.deleteRecording()
        }
        
        voiceMessageRecorderObserver = nil
        actionsSubject.send(.composer(action: .setMode(mode: .default)))
    }
    
    func sendCurrentVoiceMessage() async {
        guard let audioPlayerState = voiceMessageRecorder.previewAudioPlayerState, let recordingURL = voiceMessageRecorder.recordingURL else {
            actionsSubject.send(.displayErrorToast(L10n.errorFailedUploadingVoiceMessage))
            return
        }
        
        analyticsService.trackComposer(inThread: false,
                                       isEditing: false,
                                       isReply: false,
                                       messageType: .VoiceMessage,
                                       startsThread: nil)

        actionsSubject.send(.composer(action: .setMode(mode: .previewVoiceMessage(state: audioPlayerState, waveform: .url(recordingURL), isUploading: true))))
        await voiceMessageRecorder.stopPlayback()
        
        switch await voiceMessageRecorder.sendVoiceMessage(timelineController: timelineController, audioConverter: AudioConverter()) {
        case .success:
            await deleteCurrentVoiceMessage()
        case .failure(let error):
            MXLog.error("failed to send the voice message. \(error)")
            actionsSubject.send(.composer(action: .setMode(mode: .previewVoiceMessage(state: audioPlayerState, waveform: .url(recordingURL), isUploading: false))))
            actionsSubject.send(.displayErrorToast(L10n.errorFailedUploadingVoiceMessage))
        }
    }
    
    func startPlayingRecordedVoiceMessage() async {
        await mediaPlayerProvider.detachAllStates(except: voiceMessageRecorder.previewAudioPlayerState)
        if case .failure(let error) = await voiceMessageRecorder.startPlayback() {
            MXLog.error("failed to play recorded voice message. \(error)")
        }
    }
    
    func pausePlayingRecordedVoiceMessage() {
        voiceMessageRecorder.pausePlayback()
    }
    
    func seekRecordedVoiceMessage(to progress: Double) async {
        await mediaPlayerProvider.detachAllStates(except: voiceMessageRecorder.previewAudioPlayerState)
        await voiceMessageRecorder.seekPlayback(to: progress)
    }
    
    func scrubVoiceMessagePlayback(scrubbing: Bool) async {
        guard let audioPlayerState = voiceMessageRecorder.previewAudioPlayerState else {
            return
        }
        if scrubbing {
            if audioPlayerState.playbackState == .playing {
                resumeVoiceMessagePlaybackAfterScrubbing = true
                pausePlayingRecordedVoiceMessage()
            }
        } else {
            if resumeVoiceMessagePlaybackAfterScrubbing {
                resumeVoiceMessagePlaybackAfterScrubbing = false
                await startPlayingRecordedVoiceMessage()
            }
        }
    }
    
    // MARK: Audio Playback
    
    func playPauseAudio(for itemID: TimelineItemIdentifier) async {
        MXLog.info("Toggle play/pause audio for itemID \(itemID)")
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID) else {
            fatalError("TimelineItem \(itemID) not found")
        }
        
        guard let voiceMessageRoomTimelineItem = timelineItem as? VoiceMessageRoomTimelineItem else {
            fatalError("Invalid TimelineItem type for itemID \(itemID) (expecting `VoiceMessageRoomTimelineItem` but found \(type(of: timelineItem)) instead")
        }
        
        guard let source = voiceMessageRoomTimelineItem.content.source else {
            MXLog.error("Cannot start voice message playback, source is not defined for itemID \(itemID)")
            return
        }
        
        let audioPlayer = mediaPlayerProvider.player

        // Stop any recording in progress
        if voiceMessageRecorder.isRecording {
            await voiceMessageRecorder.stopRecording()
        }

        guard let audioPlayerState = audioPlayerState(for: itemID) else {
            fatalError("Audio player state not found for \(itemID)")
        }
        
        // Ensure this one is attached
        if !audioPlayerState.isAttached {
            audioPlayerState.attachAudioPlayer(audioPlayer)
        }

        // Detach all other states
        await mediaPlayerProvider.detachAllStates(except: audioPlayerState)

        guard audioPlayer.sourceURL == source.url, audioPlayer.state != .error else {
            // Load content
            do {
                MXLog.info("Loading voice message audio content from source for itemID \(itemID)")
                let url = try await userSession.voiceMessageMediaManager.loadVoiceMessageFromSource(source, body: nil)

                // Make sure that the player is still attached, as it may have been detached while waiting for the voice message to be loaded.
                if audioPlayerState.isAttached {
                    audioPlayer.load(sourceURL: source.url, playbackURL: url, autoplay: true)
                }
            } catch {
                MXLog.error("Failed to load voice message: \(error)")
                audioPlayerState.reportError()
            }
            
            return
        }
        
        if audioPlayer.state == .playing {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
    }
        
    func seekAudio(for itemID: TimelineItemIdentifier, progress: Double) async {
        guard let playerState = mediaPlayerProvider.playerState(for: .timelineItemIdentifier(itemID)) else {
            return
        }
        await mediaPlayerProvider.detachAllStates(except: playerState)
        await playerState.updateState(progress: progress)
    }
    
    func audioPlayerState(for itemID: TimelineItemIdentifier) -> AudioPlayerState? {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID) else {
            MXLog.error("TimelineItem \(itemID) not found")
            return nil
        }
        
        guard let voiceMessageRoomTimelineItem = timelineItem as? VoiceMessageRoomTimelineItem else {
            MXLog.error("Invalid TimelineItem type (expecting `VoiceMessageRoomTimelineItem` but found \(type(of: timelineItem)) instead")
            return nil
        }
        
        if let playerState = mediaPlayerProvider.playerState(for: .timelineItemIdentifier(itemID)) {
            return playerState
        }
        
        let playerState = AudioPlayerState(id: .timelineItemIdentifier(itemID),
                                           title: L10n.commonVoiceMessage,
                                           duration: voiceMessageRoomTimelineItem.content.duration,
                                           waveform: voiceMessageRoomTimelineItem.content.waveform)
        mediaPlayerProvider.register(audioPlayerState: playerState)
        return playerState
    }
    
    // MARK: Other
    
    func displayEmojiPicker(for itemID: TimelineItemIdentifier) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              timelineItem.isReactable,
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        let selectedEmojis = Set(eventTimelineItem.properties.reactions.compactMap { $0.isHighlighted ? $0.key : nil })
        actionsSubject.send(.displayEmojiPicker(itemID: itemID, selectedEmojis: selectedEmojis))
    }
    
    func processItemTap(_ itemID: TimelineItemIdentifier) async -> TimelineControllerAction {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID) as? EventBasedMessageTimelineItemProtocol else {
            return .none
        }
        
        switch timelineItem {
        case let item as LocationRoomTimelineItem:
            guard let geoURI = item.content.geoURI else { return .none }
            return .displayLocation(body: item.content.body, geoURI: geoURI, description: item.content.description)
        case is ImageRoomTimelineItem,
             is VideoRoomTimelineItem:
            return await mediaPreviewAction(for: timelineItem, messageTypes: [.image, .video])
        case is AudioRoomTimelineItem,
             is FileRoomTimelineItem:
            return await mediaPreviewAction(for: timelineItem, messageTypes: [.audio, .file])
        default:
            return .none
        }
    }
    
    // MARK: - Private
    
    private func buildReplyInfo(for item: EventBasedTimelineItemProtocol) -> ReplyInfo {
        switch item {
        case let messageItem as EventBasedMessageTimelineItemProtocol:
            return .init(type: .message(messageItem.contentType), isThread: messageItem.properties.isThreaded)
        case let pollItem as PollRoomTimelineItem:
            return .init(type: .poll(question: pollItem.poll.question), isThread: false)
        default:
            return .init(type: .message(.text(.init(body: item.body))), isThread: false)
        }
    }
    
    private func mediaPreviewAction(for item: EventBasedMessageTimelineItemProtocol, messageTypes: [TimelineAllowedMessageType]) async -> TimelineControllerAction {
        var newTimelineFocus: TimelineFocus?
        var newTimelinePresentation: TimelineKind.MediaPresentation?
        switch timelineController.timelineKind {
        case .live:
            newTimelineFocus = .live
            newTimelinePresentation = .roomScreenLive
        case .detached:
            guard case let .event(_, eventOrTransactionID: .eventID(eventID)) = item.id else {
                MXLog.error("Unexpected event type on a detached timeline.")
                return .none
            }
            newTimelineFocus = .eventID(eventID)
            newTimelinePresentation = .roomScreenDetached
        case .pinned:
            newTimelineFocus = .pinned
            newTimelinePresentation = .pinnedEventsScreen
        case .media, .thread:
            break // We don't need to create a new timeline as it is already filtered.
        }
        
        if let newTimelineFocus, let newTimelinePresentation {
            let timelineItemFactory = RoomTimelineItemFactory(userID: roomProxy.ownUserID,
                                                              attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                              stateEventStringBuilder: RoomStateEventStringBuilder(userID: roomProxy.ownUserID))
            
            guard case let .success(timelineController) = await timelineControllerFactory.buildMessageFilteredTimelineController(focus: newTimelineFocus,
                                                                                                                                 allowedMessageTypes: messageTypes,
                                                                                                                                 presentation: newTimelinePresentation,
                                                                                                                                 roomProxy: roomProxy,
                                                                                                                                 timelineItemFactory: timelineItemFactory,
                                                                                                                                 mediaProvider: userSession.mediaProvider) else {
                MXLog.error("Failed presenting media timeline")
                return .none
            }
            
            let timelineViewModel = TimelineViewModel(roomProxy: roomProxy,
                                                      timelineController: timelineController,
                                                      userSession: userSession,
                                                      mediaPlayerProvider: mediaPlayerProvider,
                                                      userIndicatorController: userIndicatorController,
                                                      appMediator: appMediator,
                                                      appSettings: appSettings,
                                                      analyticsService: analyticsService,
                                                      emojiProvider: emojiProvider,
                                                      linkMetadataProvider: linkMetadataProvider,
                                                      timelineControllerFactory: timelineControllerFactory)
            
            return .displayMediaPreview(item: item, timelineViewModel: .new(timelineViewModel))
        } else {
            return .displayMediaPreview(item: item, timelineViewModel: .active)
        }
    }
}

private struct ReplyInfo {
    let type: TimelineEventContent
    let isThread: Bool
}

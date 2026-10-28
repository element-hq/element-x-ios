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
    
    case displayEmojiPicker(selectedEmojis: Set<String>, continuation: EmojiPickerScreenContinuation)
    case displayReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case displayMessageForwarding(itemID: TimelineItemIdentifier)
    case displayMediaUploadPreviewScreen(mediaURLs: [URL])
    case displayEditPollForm(eventID: String, poll: Poll)
    
    case showActionMenu(TimelineItemActionMenuInfo)
    case showRedactConfirmation(itemID: TimelineItemIdentifier)
    case showDebugInfo(TimelineItemDebugInfo)
    
    case displayAudioRecorderPermissionError
    case displayErrorToast(String)
    case displayA2UIVideo(A2UIVideoPlayback)
    case displayA2UIImagePreview(MediaPreviewItem)
    
    case viewInRoomTimeline(eventID: String)
    case displayThread(itemID: TimelineItemIdentifier)
    case showTranslation(text: String)
}

/// The interaction handler groups logic for dealing with various actions the user can take on a timeline's
/// view that would've normally been part of the ``TimelineViewModel``
class TimelineInteractionHandler {
    private let roomProxy: JoinedRoomProxyProtocol
    private let timelineController: TimelineControllerProtocol
    private let userSession: UserSessionProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    private let voiceMessageRecorder: VoiceMessageRecorderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appMediator: AppMediatorProtocol
    private let userSettings: UserSettings
    private let analyticsService: AnalyticsServiceProtocol
    private let emojiProvider: EmojiProviderProtocol
    private let linkMetadataProvider: LinkMetadataProviderProtocol
    private let timelineControllerFactory: TimelineControllerFactoryProtocol
    private let pollInteractionHandler: PollInteractionHandlerProtocol
    private let a2uiSurfaceStore = A2UISurfaceStore()
    
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
    
    /// The voice message playback that was last asked for, and whether the player has begun it.
    private enum VoiceMessagePlayback {
        case requested(TimelineItemIdentifier)
        case playing(TimelineItemIdentifier)
    }
    
    private var voiceMessagePlayback: VoiceMessagePlayback?
    private var audioPlayerActionsCancellable: AnyCancellable?
    
    private var emojiPickerCancellable: AnyCancellable?
    
    init(roomProxy: JoinedRoomProxyProtocol,
         timelineController: TimelineControllerProtocol,
         userSession: UserSessionProtocol,
         mediaPlayerProvider: MediaPlayerProviderProtocol,
         voiceMessageRecorder: VoiceMessageRecorderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol,
         analyticsService: AnalyticsServiceProtocol,
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
        userSettings = userSession.userSettings
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
    
    func redact(_ itemID: TimelineItemIdentifier, reason: String?) {
        // Redacting needs the event alone, so it works even when the item isn't part of this timeline,
        // such as one held by a media preview that was built from a different one.
        guard case let .event(_, eventOrTransactionID) = itemID else { fatalError() }
        Task { await timelineController.redact(eventOrTransactionID, reason: reason) }
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    func handleTimelineItemMenuAction(_ action: TimelineItemMenuAction, itemID: TimelineItemIdentifier) {
        if case .redact = action {
            // An unsent message is only dropped from the send queue. No redaction event reaches
            // the server, so there is nothing to attach a reason to, and asking for one would
            // only delay the abort while the message might still go out.
            if case .event(_, .eventID) = itemID {
                actionsSubject.send(.showRedactConfirmation(itemID: itemID))
            } else {
                redact(itemID, reason: nil)
            }
            return
        }
        
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
                actionsSubject.send(.displayEditPollForm(eventID: eventID, poll: pollTimelineItem.poll))
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
            break // Handled above, before the timeline item is looked up.
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
        case .downloadMedia:
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
        case .gallery(let content):
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
    
    // MARK: - A2UI
    
    /// The live surfaces of an A2UI message, created on first use and brought up to date with the item.
    func a2uiSurfaces(for item: A2UIRoomTimelineItem) -> A2UIMessageSurfaces? {
        a2uiSurfaceStore.surfaces(for: item)
    }
    
    /// Keeps the surfaces of every A2UI message in step with the latest items, ahead of the views reading them.
    func updateA2UISurfaces(with timelineItems: [RoomTimelineItemProtocol], isSwitchingTimelines: Bool) {
        if isSwitchingTimelines {
            a2uiSurfaceStore.removeAll()
        }
        a2uiSurfaceStore.update(with: timelineItems)
    }
    
    /// Reports a button press to the agent as an `io.element.a2ui.action` event related to the message.
    func triggerA2UIAction(itemID: TimelineItemIdentifier, surfaceID: String, key: A2UINodeKey) {
        guard let eventID = itemID.eventID,
              let surfaces = a2uiSurfaceStore.surfaces(forEventID: eventID),
              let resolved = surfaces.resolveAction(surfaceID: surfaceID, key: key) else {
            MXLog.error("Unable to resolve the A2UI action for item: \(itemID)")
            return
        }
        
        let content = A2UIEvent.actionContent(referencing: eventID,
                                              surfaceID: surfaceID,
                                              action: resolved.action,
                                              dataModel: resolved.dataModel)
        surfaces.isSendingAction = true
        surfaces.sendFailureMessage = nil
        
        Task {
            if case .failure(let error) = await roomProxy.sendEvent(type: A2UIEvent.actionEventType, content: content) {
                MXLog.error("Failed sending the A2UI action with error: \(error)")
                surfaces.sendFailureMessage = UntranslatedL10n.screenRoomA2uiSendFailed
            }
            surfaces.isSendingAction = false
        }
    }
    
    /// Plays a video from an A2UI surface full screen. Web videos stream straight into the
    /// player, Matrix media is downloaded through the media provider first.
    func playA2UIVideo(url: URL) {
        guard url.scheme?.lowercased() == "mxc" else {
            actionsSubject.send(.displayA2UIVideo(.init(url: url, fileHandle: nil)))
            return
        }
        
        Task {
            let indicatorID = "A2UIVideoLoadingIndicator"
            userIndicatorController.submitIndicator(UserIndicator(id: indicatorID, type: .modal, title: L10n.commonLoading, persistent: true))
            defer { userIndicatorController.retractIndicatorWithId(indicatorID) }
            
            guard let source = try? MediaSourceProxy(url: url, mimeType: nil),
                  case .success(let fileHandle) = await userSession.mediaProvider.loadFileFromSource(source),
                  let fileURL = fileHandle.url else {
                actionsSubject.send(.displayErrorToast(L10n.errorUnknown))
                return
            }
            
            actionsSubject.send(.displayA2UIVideo(.init(url: fileURL, fileHandle: fileHandle)))
        }
    }
    
    /// Previews an image from an A2UI surface with Quick Look, like image attachments. Quick Look
    /// needs a local file, so web images are downloaded to a temporary file first.
    func previewA2UIImage(url: URL, title: String?) {
        Task {
            let indicatorID = "A2UIImageLoadingIndicator"
            userIndicatorController.submitIndicator(UserIndicator(id: indicatorID, type: .modal, title: L10n.commonLoading, persistent: true))
            defer { userIndicatorController.retractIndicatorWithId(indicatorID) }
            
            let previewItem = if url.scheme?.lowercased() == "mxc" {
                await MediaPreviewItem.load(from: url, title: title, using: userSession.mediaProvider)
            } else {
                await downloadedPreviewItem(from: url, title: title)
            }
            
            guard let previewItem else {
                actionsSubject.send(.displayErrorToast(L10n.errorUnknown))
                return
            }
            actionsSubject.send(.displayA2UIImagePreview(previewItem))
        }
    }
    
    private func downloadedPreviewItem(from url: URL, title: String?) async -> MediaPreviewItem? {
        guard let (downloadURL, _) = try? await URLSession.shared.download(from: url) else { return nil }
        
        // The download is deleted as soon as this returns, so keep a copy that also has the original name for Quick Look to type it.
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent(url.lastPathComponent)
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.moveItem(at: downloadURL, to: fileURL)
        } catch {
            MXLog.error("Failed storing the downloaded image: \(error)")
            return nil
        }
        return MediaPreviewItem(file: .unmanaged(url: fileURL), title: title)
    }
    
    // MARK: - Polls
    
    func sendPollResponse(pollStartID: String, answerIDs: [String]) {
        Task {
            let sendPollResponseResult = await pollInteractionHandler.sendPollResponse(pollStartID: pollStartID, answerIDs: answerIDs)
            
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
    
    /// Stops the recording when one is in progress, moving the composer to the preview state.
    func stopRecordingVoiceMessageIfNeeded() async {
        guard voiceMessageRecorder.isRecording else { return }
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
        } else if resumeVoiceMessagePlaybackAfterScrubbing {
            resumeVoiceMessagePlaybackAfterScrubbing = false
            await startPlayingRecordedVoiceMessage()
        }
    }
    
    // MARK: Audio Playback
    
    func changePlaybackSpeed(for itemID: TimelineItemIdentifier) {
        let nextSpeed = userSettings.app.voiceMessagePlaybackSpeed.next
        userSettings.app.voiceMessagePlaybackSpeed = nextSpeed
        audioPlayerState(for: itemID)?.setPlaybackSpeed(nextSpeed)
    }
    
    // swiftlint:disable:next cyclomatic_complexity
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
        
        // Loading a new message tears the player down, which cancels any autoplay that was pending for the previous one.
        voiceMessagePlayback = .requested(itemID)
        
        let audioPlayer = mediaPlayerProvider.player
        
        // Observe the player lazily so that the mocks used by the previews and the UI tests don't need one.
        if audioPlayerActionsCancellable == nil {
            audioPlayerActionsCancellable = audioPlayer.actions
                .sink { [weak self] action in
                    Task { await self?.handleAudioPlayerAction(action) }
                }
        }
        
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
    
    private func handleAudioPlayerAction(_ action: AudioPlayerAction) async {
        switch action {
        case .didStartPlaying:
            if case .requested(let itemID) = voiceMessagePlayback {
                voiceMessagePlayback = .playing(itemID)
            }
        case .didFinishPlaying:
            // Anything else means the player was torn down to play something different
            // rather than reaching the end of the message it had started.
            guard case .playing(let finishedItemID) = voiceMessagePlayback else { return }
            voiceMessagePlayback = nil
            await autoplayVoiceMessage(following: finishedItemID)
        case .didStartLoading, .didFinishLoading, .didPausePlaying, .didStopPlaying, .didFailWithError:
            break
        }
    }
    
    /// Plays the voice message directly following the given one.
    private func autoplayVoiceMessage(following finishedItemID: TimelineItemIdentifier) async {
        // The playback may have been taken over by another player state, such as the recorder's preview.
        guard audioPlayerState(for: finishedItemID)?.isAttached == true,
              let nextVoiceMessage = timelineController.timelineItems.voiceMessageDirectlyFollowing(finishedItemID) else {
            return
        }
        
        MXLog.info("Autoplaying the voice message following itemID \(finishedItemID)")
        mediaPlayerProvider.play(soundEffect: .tink)
        await playPauseAudio(for: nextVoiceMessage.id)
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
                                           waveform: voiceMessageRoomTimelineItem.content.waveform,
                                           playbackSpeed: userSettings.app.voiceMessagePlaybackSpeed,
                                           playbackSpeedPublisher: userSettings.app.voiceMessagePlaybackSpeedPublisher)
        mediaPlayerProvider.register(audioPlayerState: playerState)
        return playerState
    }
    
    // MARK: Other
    
    func displayEmojiPicker(for itemID: TimelineItemIdentifier) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              timelineItem.isReactable,
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol,
              case let .event(_, eventOrTransactionID) = itemID else {
            return
        }
        let selectedEmojis = Set(eventTimelineItem.properties.reactions.compactMap { $0.isHighlighted ? $0.key : nil })
        
        let (stream, continuation) = AsyncStream<String>.makeStream()
        actionsSubject.send(.displayEmojiPicker(selectedEmojis: selectedEmojis, continuation: continuation))
        
        emojiPickerCancellable = Task { [weak self] in
            for await emoji in stream {
                await self?.timelineController.toggleReaction(emoji, to: eventOrTransactionID)
            }
        }
        .asCancellable()
    }
    
    func processItemTap(_ itemID: TimelineItemIdentifier) async -> TimelineControllerAction {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID) as? EventBasedTimelineItemProtocol else {
            return .none
        }
        
        switch timelineItem {
        case let item as LocationRoomTimelineItem:
            guard let geoURI = item.content.geoURI else { return .none }
            return .displayLocation(.init(sender: item.sender,
                                          geoURI: geoURI,
                                          kind: item.content.kind,
                                          timestamp: item.timestamp))
        case let item as LiveLocationRoomTimelineItem:
            guard let geoURI = item.content.lastGeoURI else { return .none }
            let initialLiveLocationShare = LiveLocationShare(userID: item.sender.id,
                                                             geoURI: geoURI,
                                                             timestamp: item.timestamp,
                                                             timeoutDate: item.content.timeoutDate)
            return .displayLiveLocation(sender: item.sender, initialLiveLocationShare: initialLiveLocationShare)
        // Galleries are included so that their attachments can be browsed as individual media.
        case let item as ImageRoomTimelineItem:
            return await mediaPreviewAction(for: item, messageTypes: [.image, .video, .gallery])
        case let item as VideoRoomTimelineItem:
            return await mediaPreviewAction(for: item, messageTypes: [.image, .video, .gallery])
        case let item as AudioRoomTimelineItem:
            return await mediaPreviewAction(for: item, messageTypes: [.audio, .file, .gallery])
        case let item as FileRoomTimelineItem:
            return await mediaPreviewAction(for: item, messageTypes: [.audio, .file, .gallery])
        case let item as GalleryRoomTimelineItem:
            // Only galleries are needed as the preview is scoped to the attachments of the tapped one.
            return await mediaPreviewAction(for: item, messageTypes: [.gallery])
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
        case .thread(let rootEventID):
            newTimelineFocus = .thread(eventID: rootEventID)
            newTimelinePresentation = .roomScreenThread
        case .media:
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
                                                      analyticsService: analyticsService,
                                                      emojiProvider: emojiProvider,
                                                      linkMetadataProvider: linkMetadataProvider,
                                                      timelineControllerFactory: timelineControllerFactory)
            
            return previewAction(for: item, timelineViewModel: .new(timelineViewModel))
        } else {
            return previewAction(for: item, timelineViewModel: .active)
        }
    }
    
    /// A gallery is previewed scoped to its own attachments rather than the wider timeline's media.
    private func previewAction(for item: EventBasedMessageTimelineItemProtocol,
                               timelineViewModel: TimelineControllerAction.TimelineViewModelKind) -> TimelineControllerAction {
        guard let galleryItem = item as? GalleryRoomTimelineItem else {
            return .displayMediaPreview(item: item, timelineViewModel: timelineViewModel)
        }
        
        return .displayGalleryPreview(galleryItem: galleryItem, timelineViewModel: timelineViewModel)
    }
}

private struct ReplyInfo {
    let type: TimelineEventContent
    let isThread: Bool
}

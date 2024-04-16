//
// Copyright 2023 New Vector Ltd
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

import Combine
import UIKit

enum RoomScreenInteractionHandlerAction {
    case composer(action: RoomScreenComposerAction)
    case displayError(RoomScreenErrorType)
    case displayEmojiPicker(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>)
    case displayReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case displayMessageForwarding(itemID: TimelineItemIdentifier)
    case displayMediaUploadPreviewScreen(url: URL)
    case displayPollForm(mode: PollFormMode)
    case displayRoomMemberDetails(userID: String)
    case showActionMenu(TimelineItemActionMenuInfo)
    case showDebugInfo(TimelineItemDebugInfo)
    case showConfirmationAlert(AlertInfo<UUID>)
}

@MainActor
class RoomScreenInteractionHandler {
    private let roomProxy: RoomProxyProtocol
    private let timelineController: RoomTimelineControllerProtocol
    private let mediaProvider: MediaProviderProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    private let voiceMessageRecorder: VoiceMessageRecorderProtocol
    private let voiceMessageMediaManager: VoiceMessageMediaManagerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let application: ApplicationProtocol
    private let appSettings: AppSettings
    private let analyticsService: AnalyticsService
    private let pollInteractionHandler: PollInteractionHandlerProtocol
    
    private let actionsSubject: PassthroughSubject<RoomScreenInteractionHandlerAction, Never> = .init()
    var actions: AnyPublisher<RoomScreenInteractionHandlerAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var voiceMessageRecorderObserver: AnyCancellable?
    private var canCurrentUserRedactOthers = false
    private var canCurrentUserRedactSelf = false
    private var resumeVoiceMessagePlaybackAfterScrubbing = false
    
    init(roomProxy: RoomProxyProtocol,
         timelineController: RoomTimelineControllerProtocol,
         mediaProvider: MediaProviderProtocol,
         mediaPlayerProvider: MediaPlayerProviderProtocol,
         voiceMessageMediaManager: VoiceMessageMediaManagerProtocol,
         voiceMessageRecorder: VoiceMessageRecorderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         application: ApplicationProtocol,
         appSettings: AppSettings,
         analyticsService: AnalyticsService) {
        self.roomProxy = roomProxy
        self.timelineController = timelineController
        self.mediaProvider = mediaProvider
        self.mediaPlayerProvider = mediaPlayerProvider
        self.voiceMessageMediaManager = voiceMessageMediaManager
        self.voiceMessageRecorder = voiceMessageRecorder
        self.userIndicatorController = userIndicatorController
        self.application = application
        self.appSettings = appSettings
        self.analyticsService = analyticsService
        pollInteractionHandler = PollInteractionHandler(analyticsService: analyticsService, roomProxy: roomProxy)
    }
    
    // MARK: Timeline Item Action Menu
    
    func showTimelineItemActionMenu(for itemID: TimelineItemIdentifier) {
        Task {
            if case let .success(value) = await roomProxy.canUserRedactOther(userID: roomProxy.ownUserID) {
                canCurrentUserRedactOthers = value
            } else {
                canCurrentUserRedactOthers = false
            }
            
            if case let .success(value) = await roomProxy.canUserRedactOwn(userID: roomProxy.ownUserID) {
                canCurrentUserRedactSelf = value
            } else {
                canCurrentUserRedactSelf = false
            }
         
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
    func timelineItemMenuActionsForItemId(_ itemID: TimelineItemIdentifier) -> TimelineItemMenuActions? {
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
        if appSettings.isDevelopmentBuild || appSettings.viewSourceEnabled {
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
        
        if item.isForwardable {
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

    func processTimelineItemMenuAction(_ action: TimelineItemMenuAction, itemID: TimelineItemIdentifier) {
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
        case .copyPermalink:
            guard let eventID = eventTimelineItem.id.eventID else {
                actionsSubject.send(.displayError(.alert(L10n.errorFailedCreatingThePermalink)))
                return
            }
            
            Task {
                guard case let .success(permalinkURL) = await roomProxy.matrixToEventPermalink(eventID) else {
                    actionsSubject.send(.displayError(.alert(L10n.errorFailedCreatingThePermalink)))
                    return
                }
                
                UIPasteboard.general.url = permalinkURL
            }
        case .redact:
            Task {
                if eventTimelineItem.hasFailedToSend {
                    await timelineController.cancelSending(itemID: itemID)
                } else {
                    await timelineController.redact(itemID)
                }
            }
        case .reply:
            guard let eventID = eventTimelineItem.id.eventID else {
                return
            }
            
            let replyInfo = buildReplyInfo(for: eventTimelineItem)
            let replyDetails = TimelineItemReplyDetails.loaded(sender: eventTimelineItem.sender, eventID: eventID, eventContent: replyInfo.type)
            
            actionsSubject.send(.composer(action: .setMode(mode: .reply(itemID: eventTimelineItem.id, replyDetails: replyDetails, isThread: replyInfo.isThread))))
        case .forward(let itemID):
            actionsSubject.send(.displayMessageForwarding(itemID: itemID))
        case .viewSource:
            let debugInfo = timelineController.debugInfo(for: eventTimelineItem.id)
            MXLog.info("Showing debug info for \(eventTimelineItem.id)")
            actionsSubject.send(.showDebugInfo(debugInfo))
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
    
    private func processEditMessageEvent(_ messageTimelineItem: EventBasedMessageTimelineItemProtocol) {
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
    }
    
    // MARK: Polls

    func sendPollResponse(pollStartID: String, optionID: String) {
        Task {
            let sendPollResponseResult = await pollInteractionHandler.sendPollResponse(pollStartID: pollStartID, optionID: optionID)
            
            switch sendPollResponseResult {
            case .success:
                break
            case .failure:
                actionsSubject.send(.displayError(.toast(L10n.errorUnknown)))
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
                actionsSubject.send(.displayError(.toast(L10n.errorUnknown)))
            }
        }
    }
    
    // MARK: Pasting and dropping
    
    func handlePasteOrDrop(_ provider: NSItemProvider) {
        guard let contentType = provider.preferredContentType,
              let preferredExtension = contentType.preferredFilenameExtension else {
            MXLog.error("Invalid NSItemProvider: \(provider)")
            actionsSubject.send(.displayError(.toast(L10n.screenRoomErrorFailedProcessingMedia)))
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
                    self.actionsSubject.send(.displayError(.toast(L10n.screenRoomErrorFailedProcessingMedia)))
                    MXLog.error("Failed processing NSItemProvider: \(providerDescription) with error: \(error)")
                    return
                }

                guard let data else {
                    self.actionsSubject.send(.displayError(.toast(L10n.screenRoomErrorFailedProcessingMedia)))
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
                    self.actionsSubject.send(.displayError(.toast(L10n.screenRoomErrorFailedProcessingMedia)))
                    MXLog.error("Failed storing NSItemProvider data \(providerDescription) with error: \(error)")
                }
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
        case .didFailWithError(let error):
            switch error {
            case .audioRecorderError(.recordPermissionNotGranted):
                MXLog.info("permission to record audio has not been granted.")
                actionsSubject.send(.showConfirmationAlert(.init(id: .init(),
                                                                 title: L10n.dialogPermissionMicrophoneTitleIos(InfoPlistReader.main.bundleDisplayName),
                                                                 message: L10n.dialogPermissionMicrophoneDescriptionIos,
                                                                 primaryButton: .init(title: L10n.commonSettings, action: { [weak self] in self?.openSystemSettings() }),
                                                                 secondaryButton: .init(title: L10n.actionNotNow, role: .cancel, action: nil))))
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
            actionsSubject.send(.displayError(.alert(L10n.errorFailedUploadingVoiceMessage)))
            return
        }
        
        analyticsService.trackComposer(inThread: false,
                                       isEditing: false,
                                       isReply: false,
                                       messageType: .VoiceMessage,
                                       startsThread: nil)

        actionsSubject.send(.composer(action: .setMode(mode: .previewVoiceMessage(state: audioPlayerState, waveform: .url(recordingURL), isUploading: true))))
        await voiceMessageRecorder.stopPlayback()
        switch await voiceMessageRecorder.sendVoiceMessage(inRoom: roomProxy, audioConverter: AudioConverter()) {
        case .success:
            await deleteCurrentVoiceMessage()
        case .failure(let error):
            MXLog.error("failed to send the voice message. \(error)")
            actionsSubject.send(.composer(action: .setMode(mode: .previewVoiceMessage(state: audioPlayerState, waveform: .url(recordingURL), isUploading: false))))
            actionsSubject.send(.displayError(.alert(L10n.errorFailedUploadingVoiceMessage)))
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
        
        guard case .success(let mediaPlayer) = mediaPlayerProvider.player(for: source), let audioPlayer = mediaPlayer as? AudioPlayerProtocol else {
            MXLog.error("Cannot play a voice message without an audio player")
            return
        }

        // Stop any recording in progress
        if voiceMessageRecorder.isRecording {
            await voiceMessageRecorder.stopRecording()
        }

        guard let audioPlayerState = audioPlayerState(for: itemID) else {
            fatalError("Audio player not found for \(itemID)")
        }
        
        // Ensure this one is attached
        if !audioPlayerState.isAttached {
            audioPlayerState.attachAudioPlayer(audioPlayer)
        }

        // Detach all other states
        await mediaPlayerProvider.detachAllStates(except: audioPlayerState)

        guard audioPlayer.mediaSource == source, audioPlayer.state != .error else {
            // Load content
            do {
                MXLog.info("Loading voice message audio content from source for itemID \(itemID)")
                let url = try await voiceMessageMediaManager.loadVoiceMessageFromSource(source, body: nil)

                // Make sure that the player is still attached, as it may have been detached while waiting for the voice message to be loaded.
                if audioPlayerState.isAttached {
                    audioPlayer.load(mediaSource: source, using: url, autoplay: true)
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
                                           duration: voiceMessageRoomTimelineItem.content.duration,
                                           waveform: voiceMessageRoomTimelineItem.content.waveform)
        mediaPlayerProvider.register(audioPlayerState: playerState)
        return playerState
    }
    
    // MARK: Other
    
    func showEmojiPicker(for itemID: TimelineItemIdentifier) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              timelineItem.isReactable,
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        let selectedEmojis = Set(eventTimelineItem.properties.reactions.compactMap { $0.isHighlighted ? $0.key : nil })
        actionsSubject.send(.displayEmojiPicker(itemID: itemID, selectedEmojis: selectedEmojis))
    }
    
    func handleTappedUser(userID: String) async {
        actionsSubject.send(.displayRoomMemberDetails(userID: userID))
    }
    
    func processItemTap(_ itemID: TimelineItemIdentifier) async -> RoomTimelineControllerAction {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID) else {
            return .none
        }
        
        switch timelineItem {
        case let item as LocationRoomTimelineItem:
            guard let geoURI = item.content.geoURI else { return .none }
            return .displayLocation(body: item.content.body, geoURI: geoURI, description: item.content.description)
        default:
            return await displayMediaActionIfPossible(timelineItem: timelineItem)
        }
    }
    
    // MARK: - Private
    
    private func canRedactItem(_ item: EventBasedTimelineItemProtocol) -> Bool {
        item.isOutgoing ? canCurrentUserRedactSelf : canCurrentUserRedactOthers && !roomProxy.isDirect
    }
    
    private func buildReplyInfo(for item: EventBasedTimelineItemProtocol) -> ReplyInfo {
        switch item {
        case let messageItem as EventBasedMessageTimelineItemProtocol:
            return .init(type: .message(messageItem.contentType), isThread: messageItem.isThreaded)
        case let pollItem as PollRoomTimelineItem:
            return .init(type: .poll(question: pollItem.poll.question), isThread: false)
        default:
            return .init(type: .message(.text(.init(body: item.body))), isThread: false)
        }
    }
    
    private func openSystemSettings() {
        application.openAppSettings()
    }
    
    private func displayMediaActionIfPossible(timelineItem: RoomTimelineItemProtocol) async -> RoomTimelineControllerAction {
        var source: MediaSourceProxy?
        var body: String
        
        switch timelineItem {
        case let item as ImageRoomTimelineItem:
            source = item.content.source
            body = item.content.body
        case let item as VideoRoomTimelineItem:
            source = item.content.source
            body = item.content.body
        case let item as FileRoomTimelineItem:
            source = item.content.source
            body = item.content.body
        case let item as AudioRoomTimelineItem:
            // For now we are just displaying audio messages with the File preview until we create a timeline player for them.
            source = item.content.source
            body = item.content.body
        default:
            return .none
        }

        guard let source else { return .none }
        switch await mediaProvider.loadFileFromSource(source, body: body) {
        case .success(let file):
            return .displayMediaFile(file: file, title: body)
        case .failure:
            return .none
        }
    }
}

private struct ReplyInfo {
    let type: TimelineEventContent
    let isThread: Bool
}

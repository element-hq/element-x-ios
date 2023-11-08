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
    case showActionMenu(TimelineItemActionMenuInfo)
    case showDebugInfo(TimelineItemDebugInfo)
    case showConfirmationAlert(AlertInfo<UUID>)
}

@MainActor
class RoomScreenInteractionHandler {
    private let roomProxy: RoomProxyProtocol
    private let timelineController: RoomTimelineControllerProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    private let voiceMessageRecorder: VoiceMessageRecorderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let application: ApplicationProtocol
    private let appSettings: AppSettings
    private let analyticsService: AnalyticsService
    
    private let actionsSubject: PassthroughSubject<RoomScreenInteractionHandlerAction, Never> = .init()
    var actions: AnyPublisher<RoomScreenInteractionHandlerAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var voiceMessageRecorderObserver: AnyCancellable?
    private var canCurrentUserRedact = false
    private var resumeVoiceMessagePlaybackAfterScrubbing = false
    
    init(roomProxy: RoomProxyProtocol,
         timelineController: RoomTimelineControllerProtocol,
         mediaPlayerProvider: MediaPlayerProviderProtocol,
         voiceMessageRecorder: VoiceMessageRecorderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         application: ApplicationProtocol,
         appSettings: AppSettings,
         analyticsService: AnalyticsService) {
        self.roomProxy = roomProxy
        self.timelineController = timelineController
        self.mediaPlayerProvider = mediaPlayerProvider
        self.voiceMessageRecorder = voiceMessageRecorder
        self.userIndicatorController = userIndicatorController
        self.application = application
        self.appSettings = appSettings
        self.analyticsService = analyticsService
    }
    
    func showTimelineItemActionMenu(for itemID: TimelineItemIdentifier) {
        Task {
            if case let .success(value) = await roomProxy.canUserRedact(userID: roomProxy.ownUserID) {
                canCurrentUserRedact = value
            } else {
                canCurrentUserRedact = false
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
                    actionsSubject.send(.displayError(.alert(L10n.errorFailedCreatingThePermalink)))
                    break
                }

                let permalink = try PermalinkBuilder.permalinkTo(eventIdentifier: eventID, roomIdentifier: timelineController.roomID,
                                                                 baseURL: appSettings.permalinkBaseURL)
                UIPasteboard.general.url = permalink
            } catch {
                actionsSubject.send(.displayError(.alert(L10n.errorFailedCreatingThePermalink)))
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
    
    func showEmojiPicker(for itemID: TimelineItemIdentifier) {
        guard let timelineItem = timelineController.timelineItems.firstUsingStableID(itemID),
              timelineItem.isReactable,
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        let selectedEmojis = Set(eventTimelineItem.properties.reactions.compactMap { $0.isHighlighted ? $0.key : nil })
        actionsSubject.send(.displayEmojiPicker(itemID: itemID, selectedEmojis: selectedEmojis))
    }
    
    // MARK: Polls

    func sendPollResponse(pollStartID: String, optionID: String) {
        Task {
            let sendPollResponseResult = await roomProxy.sendPollResponse(pollStartID: pollStartID, answers: [optionID])
            analyticsService.trackPollVote()

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
            let endPollResult = await roomProxy.endPoll(pollStartID: pollStartID,
                                                        text: "The poll with event id: \(pollStartID) has ended")
            analyticsService.trackPollEnd()
            switch endPollResult {
            case .success:
                break
            case .failure:
                actionsSubject.send(.displayError(.toast(L10n.errorUnknown)))
            }
        }
    }
    
    // MARK: - Pasting and dropping
    
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
    
    // MARK: - Voice message
    
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
        await voiceMessageRecorder.deleteRecording()
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
                                       messageType: .voiceMessage,
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
    
    // MARK: - Private
    
    private func canRedactItem(_ item: EventBasedTimelineItemProtocol) -> Bool {
        item.isOutgoing || (canCurrentUserRedact && !roomProxy.isDirect)
    }
    
    private func buildReplyInfo(for item: EventBasedTimelineItemProtocol) -> ReplyInfo {
        guard let messageItem = item as? EventBasedMessageTimelineItemProtocol else {
            return .init(type: .text(.init(body: item.body)), isThread: false)
        }
        
        return .init(type: messageItem.contentType, isThread: messageItem.isThreaded)
    }
    
    private struct ReplyInfo {
        let type: EventBasedMessageTimelineItemContentType
        let isThread: Bool
    }
    
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        application.open(url)
    }
}

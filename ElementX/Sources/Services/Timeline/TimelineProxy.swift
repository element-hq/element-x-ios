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
import Foundation
import MatrixRustSDK

final class TimelineProxy: TimelineProxyProtocol {
    private let timeline: Timeline
    
    private var backPaginationStatusObservationToken: TaskHandle?
    private var roomTimelineObservationToken: TaskHandle?
    
    // periphery:ignore - retaining purpose
    private var timelineListener: RoomTimelineListener?
    
    private let backPaginationSubscriptionSubject = CurrentValueSubject<PaginationStatus, Never>(.idle)
    private let forwardPaginationStatusSubject = CurrentValueSubject<PaginationStatus, Never>(.timelineEndReached)
    private let timelineUpdatesSubject = PassthroughSubject<[TimelineDiff], Never>()
    
    let isLive: Bool
   
    private var innerTimelineProvider: RoomTimelineProviderProtocol!
    var timelineProvider: RoomTimelineProviderProtocol {
        innerTimelineProvider
    }
    
    deinit {
        backPaginationStatusObservationToken?.cancel()
        roomTimelineObservationToken?.cancel()
    }
    
    init(timeline: Timeline, isLive: Bool) {
        self.timeline = timeline
        self.isLive = isLive
    }
    
    func subscribeForUpdates() async {
        guard innerTimelineProvider == nil else {
            MXLog.warning("Timeline already subscribed for updates")
            return
        }
        
        let timelineListener = RoomTimelineListener { [weak self] timelineDiffs in
            self?.timelineUpdatesSubject.send(timelineDiffs)
        }
        
        self.timelineListener = timelineListener
        
        let result = await timeline.addListener(listener: timelineListener)
        roomTimelineObservationToken = result.itemsStream
        
        let paginationStatePublisher = backPaginationSubscriptionSubject
            .combineLatest(forwardPaginationStatusSubject)
            .map { PaginationState(backward: $0.0, forward: $0.1) }
            .eraseToAnyPublisher()
        
        await subscribeToPagination()
        
        innerTimelineProvider = await RoomTimelineProvider(currentItems: result.items,
                                                           isLive: isLive,
                                                           updatePublisher: timelineUpdatesSubject.eraseToAnyPublisher(),
                                                           paginationStatePublisher: paginationStatePublisher)
    }
    
    func fetchDetails(for eventID: String) {
        Task {
            do {
                MXLog.info("Fetching event details for \(eventID)")
                try await self.timeline.fetchDetailsForEvent(eventId: eventID)
                MXLog.info("Finished fetching event details for eventID: \(eventID)")
            } catch {
                MXLog.error("Failed fetching event details for eventID: \(eventID) with error: \(error)")
            }
        }
    }
    
    func messageEventContent(for timelineItemID: TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation? {
        await timelineProvider.itemProxies.firstEventTimelineItemUsingID(timelineItemID)?.content().asMessage()?.content()
    }
    
    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Paginating backwards")
        
        do {
            let _ = try await timeline.paginateBackwards(numEvents: requestSize)
            MXLog.info("Finished paginating backwards")
            
            return .success(())
        } catch {
            MXLog.error("Failed paginating backwards with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func paginateForwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
        // This extra check is necessary as forwards pagination status doesn't support subscribing.
        // We need it to make sure we send a valid status after a failure.
        guard forwardPaginationStatusSubject.value == .idle else {
            MXLog.error("Attempting to paginate forwards when already at the end.")
            return .failure(.failedPaginatingEndReached)
        }

        MXLog.info("Paginating forwards")
        forwardPaginationStatusSubject.send(.paginating)

        do {
            let timelineEndReached = try await timeline.focusedPaginateForwards(numEvents: requestSize)
            MXLog.info("Finished paginating forwards")

            forwardPaginationStatusSubject.send(timelineEndReached ? .timelineEndReached : .idle)
            return .success(())
        } catch {
            MXLog.error("Failed paginating forwards with error: \(error)")
            forwardPaginationStatusSubject.send(.idle)
            return .failure(.sdkError(error))
        }
    }
    
    func retryDecryption(for sessionID: String) async {
        MXLog.info("Retrying decryption for sessionID: \(sessionID)")
        
        await Task.dispatch(on: .global()) { [weak self] in
            self?.timeline.retryDecryption(sessionIds: [sessionID])
            MXLog.info("Finished retrying decryption for sessionID: \(sessionID)")
        }
    }
    
    func edit(_ timelineItemID: TimelineItemIdentifier,
              message: String, html: String?,
              intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Editing timeline item: \(timelineItemID)")
        
        guard let eventTimelineItem = await timelineProvider.itemProxies.firstEventTimelineItemUsingID(timelineItemID) else {
            MXLog.error("Unknown timeline item: \(timelineItemID)")
            return .failure(.failedEditing)
        }
        
        let messageContent = buildMessageContentFor(message,
                                                    html: html,
                                                    intentionalMentions: intentionalMentions.toRustMentions())
        
        do {
            try await timeline.edit(newContent: messageContent, editItem: eventTimelineItem)
            
            MXLog.info("Finished editing timeline item: \(timelineItemID)")
            
            return .success(())
        } catch {
            MXLog.error("Failed editing timeline item: \(timelineItemID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func redact(_ timelineItemID: TimelineItemIdentifier, reason: String?) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Redacting timeline item: \(timelineItemID)")
        
        guard let eventTimelineItem = await timelineProvider.itemProxies.firstEventTimelineItemUsingID(timelineItemID) else {
            MXLog.error("Unknown timeline item: \(timelineItemID)")
            return .failure(.failedRedacting)
        }
        
        do {
            let success = try await timeline.redactEvent(item: eventTimelineItem, reason: reason)
            
            guard success else {
                MXLog.error("Failed redacting timeline item: \(timelineItemID)")
                return .failure(.failedRedacting)
            }
            
            MXLog.info("Redacted timeline item: \(timelineItemID)")
            
            return .success(())
        } catch {
            MXLog.error("Failed redacting timeline item: \(timelineItemID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Sending
    
    func sendAudio(url: URL,
                   audioInfo: AudioInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending audio")
        
        let handle = timeline.sendAudio(url: url.path(percentEncoded: false), audioInfo: audioInfo, caption: nil, formattedCaption: nil, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
            MXLog.info("Finished sending audio")
        } catch {
            MXLog.error("Failed sending audio with error: \(error)")
            return .failure(.sdkError(error))
        }
        
        return .success(())
    }
    
    func sendFile(url: URL,
                  fileInfo: FileInfo,
                  progressSubject: CurrentValueSubject<Double, Never>?,
                  requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending file")
        
        let handle = timeline.sendFile(url: url.path(percentEncoded: false), fileInfo: fileInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
            MXLog.info("Finished sending file")
        } catch {
            MXLog.error("Failed sending file with error: \(error)")
            return .failure(.sdkError(error))
        }
        
        return .success(())
    }
    
    func sendImage(url: URL,
                   thumbnailURL: URL,
                   imageInfo: ImageInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending image")
        
        let handle = timeline.sendImage(url: url.path(percentEncoded: false), thumbnailUrl: thumbnailURL.path(percentEncoded: false), imageInfo: imageInfo, caption: nil, formattedCaption: nil, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
            MXLog.info("Finished sending image")
        } catch {
            MXLog.error("Failed sending image with error: \(error)")
            return .failure(.sdkError(error))
        }
        
        return .success(())
    }
    
    func sendLocation(body: String,
                      geoURI: GeoURI,
                      description: String?,
                      zoomLevel: UInt8?,
                      assetType: AssetType?) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending location")
        
        await timeline.sendLocation(body: body,
                                    geoUri: geoURI.string,
                                    description: description,
                                    zoomLevel: zoomLevel,
                                    assetType: assetType)
        
        MXLog.info("Finished sending location")
        
        return .success(())
    }
    
    func sendVideo(url: URL,
                   thumbnailURL: URL,
                   videoInfo: VideoInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending video")
        
        let handle = timeline.sendVideo(url: url.path(percentEncoded: false), thumbnailUrl: thumbnailURL.path(percentEncoded: false), videoInfo: videoInfo, caption: nil, formattedCaption: nil, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
            MXLog.info("Finished sending video")
        } catch {
            MXLog.error("Failed sending video with error: \(error)")
            return .failure(.sdkError(error))
        }
        
        return .success(())
    }
    
    func sendVoiceMessage(url: URL,
                          audioInfo: AudioInfo,
                          waveform: [UInt16],
                          progressSubject: CurrentValueSubject<Double, Never>?,
                          requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending voice message")
        
        let handle = timeline.sendVoiceMessage(url: url.path(percentEncoded: false), audioInfo: audioInfo, waveform: waveform, caption: nil, formattedCaption: nil, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
            MXLog.info("Finished sending voice message")
        } catch {
            MXLog.error("Failed sending vocie message with error: \(error)")
            return .failure(.sdkError(error))
        }
        
        return .success(())
    }
    
    func sendMessage(_ message: String,
                     html: String?,
                     inReplyTo eventID: String? = nil,
                     intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError> {
        if let eventID {
            MXLog.info("Sending reply to eventID: \(eventID)")
        } else {
            MXLog.info("Sending message")
        }
        
        let messageContent = buildMessageContentFor(message,
                                                    html: html,
                                                    intentionalMentions: intentionalMentions.toRustMentions())
        
        do {
            if let eventID {
                let replyItem = try await timeline.getEventTimelineItemByEventId(eventId: eventID)
                try await timeline.sendReply(msg: messageContent, replyItem: replyItem)
                MXLog.info("Finished sending reply to eventID: \(eventID)")
            } else {
                _ = try await timeline.send(msg: messageContent)
                MXLog.info("Finished sending message")
            }
        } catch {
            if let eventID {
                MXLog.error("Failed sending reply to eventID: \(eventID) with error: \(error)")
            } else {
                MXLog.error("Failed sending message with error: \(error)")
            }
                
            return .failure(.sdkError(error))
        }
            
        return .success(())
    }
    
    func sendMessageEventContent(_ messageContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending message content")
        
        do {
            _ = try await timeline.send(msg: messageContent)
        } catch {
            MXLog.error("Failed sending message with error: \(error)")
        }
        
        MXLog.info("Finished sending message content")
        
        return .success(())
    }
    
    func sendReadReceipt(for eventID: String, type: ReceiptType) async -> Result<Void, TimelineProxyError> {
        MXLog.verbose("Sending read receipt for eventID: \(eventID)")
        
        do {
            try await timeline.sendReadReceipt(receiptType: type, eventId: eventID)
            MXLog.info("Finished sending read receipt for eventID: \(eventID)")
            return .success(())
        } catch {
            MXLog.error("Failed sending read receipt for eventID: \(eventID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func toggleReaction(_ reaction: String, to eventID: String) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Toggling reaction for eventID: \(eventID)")
        
        do {
            try await timeline.toggleReaction(eventId: eventID, key: reaction)
            MXLog.info("Finished toggling reaction for eventID: \(eventID)")
            return .success(())
        } catch {
            MXLog.error("Failed toggling reaction for eventID: \(eventID)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Polls

    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Creating poll")
        
        do {
            try await timeline.createPoll(question: question, answers: answers, maxSelections: 1, pollKind: .init(pollKind: pollKind))
            
            MXLog.info("Finished creating poll")
            
            return .success(())
        } catch {
            MXLog.error("Failed creating poll with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func editPoll(original eventID: String,
                  question: String,
                  answers: [String],
                  pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Editing poll with eventID: \(eventID)")
        
        do {
            let originalEvent = try await timeline.getEventTimelineItemByEventId(eventId: eventID)
            
            try await timeline.editPoll(question: question, answers: answers, maxSelections: 1, pollKind: .init(pollKind: pollKind), editItem: originalEvent)
            
            MXLog.info("Finished editing poll with eventID: \(eventID)")
            
            return .success(())
        } catch {
            MXLog.error("Failed editing poll with eventID: \(eventID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func endPoll(pollStartID: String, text: String) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Ending poll with eventID: \(pollStartID)")
        
        return await Task.dispatch(on: .global()) {
            do {
                try self.timeline.endPoll(pollStartId: pollStartID, text: text)
                
                MXLog.info("Finished ending poll with eventID: \(pollStartID)")
                
                return .success(())
            } catch {
                MXLog.error("Failed ending poll with eventID: \(pollStartID) with error: \(error)")
                return .failure(.sdkError(error))
            }
        }
    }

    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending response for poll with eventID: \(pollStartID)")
        
        do {
            try await timeline.sendPollResponse(pollStartId: pollStartID, answers: answers)
            
            MXLog.info("Finished sending response for poll with eventID: \(pollStartID)")
            
            return .success(())
        } catch {
            MXLog.error("Failed sending response for poll with eventID: \(pollStartID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Private
    
    private func buildMessageContentFor(_ message: String,
                                        html: String?,
                                        intentionalMentions: Mentions) -> RoomMessageEventContentWithoutRelation {
        let emoteSlashCommand = "/me "
        let isEmote: Bool = message.starts(with: emoteSlashCommand)
        
        let content: RoomMessageEventContentWithoutRelation
        if isEmote {
            let emoteMessage = String(message.dropFirst(emoteSlashCommand.count))
            
            var emoteHtml: String?
            if let html {
                emoteHtml = String(html.dropFirst(emoteSlashCommand.count))
            }
            content = buildEmoteMessageContentFor(emoteMessage, html: emoteHtml)
        } else {
            if let html {
                content = messageEventContentFromHtml(body: message, htmlBody: html)
            } else {
                content = messageEventContentFromMarkdown(md: message)
            }
        }
        return content.withMentions(mentions: intentionalMentions)
    }
    
    private func buildEmoteMessageContentFor(_ message: String, html: String?) -> RoomMessageEventContentWithoutRelation {
        if let html {
            return messageEventContentFromHtmlAsEmote(body: message, htmlBody: html)
        } else {
            return messageEventContentFromMarkdownAsEmote(md: message)
        }
    }
    
    private func subscribeToPagination() async {
        let backPaginationListener = RoomPaginationStatusListener { [weak self] status in
            guard let self else {
                return
            }
            
            switch status {
            case .idle(let hitStartOfTimeline):
                backPaginationSubscriptionSubject.send(hitStartOfTimeline ? .timelineEndReached : .idle)
            case .paginating:
                backPaginationSubscriptionSubject.send(.paginating)
            }
        }
        
        do {
            backPaginationStatusObservationToken = try await timeline.subscribeToBackPaginationStatus(listener: backPaginationListener)
        } catch {
            MXLog.error("Failed to subscribe to back pagination status with error: \(error)")
        }
        
        // Forward pagination doesn't support observation, set the initial state ourself.
        forwardPaginationStatusSubject.send(isLive ? .timelineEndReached : .idle)
    }
}

private final class RoomTimelineListener: TimelineListener {
    private let onUpdateClosure: ([TimelineDiff]) -> Void
   
    init(_ onUpdateClosure: @escaping ([TimelineDiff]) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(diff: [TimelineDiff]) {
        onUpdateClosure(diff)
    }
}

private final class RoomPaginationStatusListener: PaginationStatusListener {
    private let onUpdateClosure: (LiveBackPaginationStatus) -> Void

    init(_ onUpdateClosure: @escaping (LiveBackPaginationStatus) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }

    func onUpdate(status: LiveBackPaginationStatus) {
        onUpdateClosure(status)
    }
}

private final class UploadProgressListener: ProgressWatcher {
    private let onUpdateClosure: (Double) -> Void
    
    init(_ onUpdateClosure: @escaping (Double) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func transmissionProgress(progress: TransmissionProgress) {
        DispatchQueue.main.async { [weak self] in
            self?.onUpdateClosure(Double(progress.current) / Double(progress.total))
        }
    }
}

private extension MatrixRustSDK.PollKind {
    init(pollKind: Poll.Kind) {
        switch pollKind {
        case .disclosed:
            self = .disclosed
        case .undisclosed:
            self = .undisclosed
        }
    }
}

extension Array where Element == TimelineItemProxy {
    func firstEventTimelineItemUsingID(_ id: TimelineItemIdentifier) -> EventTimelineItem? {
        var eventTimelineItemProxy: EventTimelineItemProxy?
        
        for item in self {
            if case let .event(eventTimelineItem) = item {
                if eventTimelineItem.id == id {
                    eventTimelineItemProxy = eventTimelineItem
                    break
                }
            }
        }
        
        return eventTimelineItemProxy?.item
    }
}

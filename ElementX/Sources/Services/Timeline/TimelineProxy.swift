//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

final class TimelineProxy: TimelineProxyProtocol {
    private let timeline: Timeline
    
    private var backPaginationStatusObservationToken: TaskHandle?
    
    // The default values don't matter here, they will be updated when calling subscribeToPagination.
    private let backPaginationStatusSubject = CurrentValueSubject<PaginationStatus, Never>(.timelineEndReached)
    private let forwardPaginationStatusSubject = CurrentValueSubject<PaginationStatus, Never>(.timelineEndReached)
    
    private let kind: TimelineKind
   
    private var innerTimelineProvider: RoomTimelineProviderProtocol!
    var timelineProvider: RoomTimelineProviderProtocol {
        innerTimelineProvider
    }
    
    deinit {
        backPaginationStatusObservationToken?.cancel()
    }
    
    init(timeline: Timeline, kind: TimelineKind) {
        self.timeline = timeline
        self.kind = kind
    }
    
    func subscribeForUpdates() async {
        guard innerTimelineProvider == nil else {
            MXLog.warning("Timeline already subscribed for updates")
            return
        }
        
        let paginationStatePublisher = backPaginationStatusSubject
            .combineLatest(forwardPaginationStatusSubject)
            .map { PaginationState(backward: $0.0, forward: $0.1) }
            .eraseToAnyPublisher()
        
        await subscribeToPagination()
        
        let provider = await RoomTimelineProvider(timeline: timeline, kind: kind, paginationStatePublisher: paginationStatePublisher)
        // Make sure the existing items are built so that we have content in the timeline before
        // determining whether or not the timeline should paginate to load more items.
        await provider.waitForInitialItems()
        
        innerTimelineProvider = provider
        
        Task {
            await timeline.fetchMembers()
        }
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
        await timelineProvider.itemProxies.firstEventTimelineItemUsingStableID(timelineItemID)?.content().asMessage()?.content()
    }
    
    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
        // We can't subscribe to back pagination on detached timelines and as live timelines
        // can be shared between multiple instances of the same room on the stack, it is
        // safer to still use the subscription logic for back pagination when live.
        switch kind {
        case .live:
            return await paginateBackwardsOnLive(requestSize: requestSize)
        case .detached:
            return await focussedPaginate(.backwards, requestSize: requestSize)
        case .pinned:
            return .success(())
        }
    }
    
    func paginateForwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
        guard kind != .pinned else {
            return .success(())
        }
        return await focussedPaginate(.forwards, requestSize: requestSize)
    }
    
    /// Paginate backwards using the subscription from Rust to drive the pagination state.
    private func paginateBackwardsOnLive(requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
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
    
    /// Paginate forward or backwards using our own logic to drive the pagination state as the
    /// Rust subscription isn't allowed on focussed/detached timelines.
    private func focussedPaginate(_ direction: PaginationDirection, requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
        let subject = switch direction {
        case .backwards: backPaginationStatusSubject
        case .forwards: forwardPaginationStatusSubject
        }
        
        // This extra check is necessary as detached timelines don't support subscribing to pagination status.
        // We need it to make sure we send a valid status after a failure.
        guard subject.value == .idle else {
            MXLog.error("Attempting to paginate \(direction.rawValue) when already at the end.")
            return .failure(.failedPaginatingEndReached)
        }
        
        MXLog.info("Paginating \(direction.rawValue)")
        subject.send(.paginating)
        
        do {
            let timelineEndReached = try await switch direction {
            case .backwards: timeline.paginateBackwards(numEvents: requestSize)
            case .forwards: timeline.focusedPaginateForwards(numEvents: requestSize)
            }
            MXLog.info("Finished paginating \(direction.rawValue)")

            subject.send(timelineEndReached ? .timelineEndReached : .idle)
            return .success(())
        } catch {
            MXLog.error("Failed paginating \(direction.rawValue) with error: \(error)")
            subject.send(.idle)
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
    
    func edit(_ timelineItem: EventTimelineItem, newContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError> {
        do {
            guard try await timeline.edit(item: timelineItem, newContent: .roomMessage(content: newContent)) == true else {
                return .failure(.failedEditing)
            }
            
            MXLog.info("Finished editing timeline item: \(timelineItem.eventId() ?? timelineItem.transactionId() ?? "unknown")")
            
            return .success(())
        } catch {
            MXLog.error("Failed editing timeline item: \(timelineItem.eventId() ?? timelineItem.transactionId() ?? "unknown") with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func redact(_ timelineItemID: TimelineItemIdentifier, reason: String?) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Redacting timeline item: \(timelineItemID)")
        
        guard let eventTimelineItem = await timelineProvider.itemProxies.firstEventTimelineItemUsingStableID(timelineItemID) else {
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
    
    func getLoadedReplyDetails(eventID: String) async -> Result<InReplyToDetails, TimelineProxyError> {
        do {
            return try await .success(timeline.loadReplyDetails(eventIdStr: eventID))
        } catch {
            MXLog.error("Failed getting reply details for event \(eventID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func pin(eventID: String) async -> Result<Bool, TimelineProxyError> {
        do {
            return try await .success(timeline.pinEvent(eventId: eventID))
        } catch {
            MXLog.error("Failed to pin the event \(eventID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func unpin(eventID: String) async -> Result<Bool, TimelineProxyError> {
        do {
            return try await .success(timeline.unpinEvent(eventId: eventID))
        } catch {
            MXLog.error("Failed to unpin the event \(eventID) with error: \(error)")
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
                try await timeline.sendReply(msg: messageContent, eventId: eventID)
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
        MXLog.info("Sending read receipt for eventID: \(eventID)")
        
        do {
            try await timeline.sendReadReceipt(receiptType: type, eventId: eventID)
            MXLog.info("Finished sending read receipt for eventID: \(eventID)")
            return .success(())
        } catch {
            MXLog.error("Failed sending read receipt for eventID: \(eventID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func toggleReaction(_ reaction: String, to itemID: TimelineItemIdentifier) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Toggling reaction for event: \(itemID)")
        
        do {
            try await timeline.toggleReaction(uniqueId: itemID.timelineID, key: reaction)
            MXLog.info("Finished toggling reaction for event: \(itemID)")
            return .success(())
        } catch {
            MXLog.error("Failed toggling reaction for event: \(itemID)")
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
            
            guard try await timeline.edit(item: originalEvent,
                                          newContent: .pollStart(pollData: .init(question: question,
                                                                                 answers: answers,
                                                                                 maxSelections: 1,
                                                                                 pollKind: .init(pollKind: pollKind)))) else {
                return .failure(.failedEditing)
            }
            
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
        
    func buildMessageContentFor(_ message: String,
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
    
    // MARK: - Private
    
    private func buildEmoteMessageContentFor(_ message: String, html: String?) -> RoomMessageEventContentWithoutRelation {
        if let html {
            return messageEventContentFromHtmlAsEmote(body: message, htmlBody: html)
        } else {
            return messageEventContentFromMarkdownAsEmote(md: message)
        }
    }
    
    private func subscribeToPagination() async {
        switch kind {
        case .live:
            let backPaginationListener = RoomPaginationStatusListener { [weak self] status in
                guard let self else {
                    return
                }
                
                switch status {
                case .idle(let hitStartOfTimeline):
                    backPaginationStatusSubject.send(hitStartOfTimeline ? .timelineEndReached : .idle)
                case .paginating:
                    backPaginationStatusSubject.send(.paginating)
                }
            }
            
            do {
                backPaginationStatusObservationToken = try await timeline.subscribeToBackPaginationStatus(listener: backPaginationListener)
            } catch {
                MXLog.error("Failed to subscribe to back pagination status with error: \(error)")
            }
            forwardPaginationStatusSubject.send(.timelineEndReached)
        case .detached:
            // Detached timelines don't support observation, set the initial state ourself.
            backPaginationStatusSubject.send(.idle)
            forwardPaginationStatusSubject.send(.idle)
        case .pinned:
            backPaginationStatusSubject.send(.timelineEndReached)
            forwardPaginationStatusSubject.send(.timelineEndReached)
        }
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
    func firstEventTimelineItemUsingStableID(_ id: TimelineItemIdentifier) -> EventTimelineItem? {
        for item in self {
            if case let .event(eventTimelineItem) = item {
                if eventTimelineItem.id.timelineID == id.timelineID {
                    return eventTimelineItem.item
                }
            }
        }
        
        return nil
    }
}

//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

final class TimelineProxy: TimelineProxyProtocol {
    private let timeline: Timeline
    
    private var backPaginationStateObservationToken: TaskHandle?
    
    // The default values shouldn't matter here as they will be updated when calling subscribeToPagination
    // but empirically we randomly see the timeline start virtual item when we shouldn't.
    // We believe there's a race condition between the default values the status publisher
    // so we're going to default the backwards one to .idle. Worst case it's going to do
    // one extra back pagination.
    private let backPaginationStateSubject = CurrentValueSubject<PaginationState, Never>(.idle)
    private let forwardPaginationStateSubject = CurrentValueSubject<PaginationState, Never>(.endReached)
    
    private let kind: TimelineKind
   
    private var innerTimelineItemProvider: TimelineItemProviderProtocol!
    var timelineItemProvider: TimelineItemProviderProtocol {
        innerTimelineItemProvider
    }
    
    deinit {
        backPaginationStateObservationToken?.cancel()
    }
    
    init(timeline: Timeline, kind: TimelineKind) {
        self.timeline = timeline
        self.kind = kind
    }
    
    func subscribeForUpdates() async {
        guard innerTimelineItemProvider == nil else {
            MXLog.warning("Timeline already subscribed for updates")
            return
        }
        
        let paginationStatePublisher = backPaginationStateSubject
            .combineLatest(forwardPaginationStateSubject)
            .map { TimelinePaginationState(backward: $0.0, forward: $0.1) }
            .eraseToAnyPublisher()
        
        await subscribeToPagination()
        
        let provider = await TimelineItemProvider(timeline: timeline, kind: kind, paginationStatePublisher: paginationStatePublisher)
        // Make sure the existing items are built so that we have content in the timeline before
        // determining whether or not the timeline should paginate to load more items.
        await provider.waitForInitialItems()
        
        innerTimelineItemProvider = provider
        
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
        guard let content = await timelineItemProvider.itemProxies.firstEventTimelineItemUsingStableID(timelineItemID)?.content,
              case let .msgLike(messageLikeContent) = content,
              case let .message(messageContent) = messageLikeContent.kind else {
            return nil
        }
        
        do {
            return try contentWithoutRelationFromMessage(message: messageContent)
        } catch {
            MXLog.error("Failed retrieving message event content for timelineItemID=\(timelineItemID)")
            return nil
        }
    }
    
    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
        // We can't subscribe to back pagination on detached timelines and as live timelines
        // can be shared between multiple instances of the same room on the stack, it is
        // safer to still use the subscription logic for back pagination when live.
        switch kind {
        case .live:
            return await paginateBackwardsOnLive(requestSize: requestSize)
        case .detached, .media, .thread:
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
        case .backwards: backPaginationStateSubject
        case .forwards: forwardPaginationStateSubject
        }
        
        // This extra check is necessary as detached timelines don't support subscribing to pagination status.
        guard subject.value == .idle else {
            return .success(())
        }
        
        MXLog.info("Paginating \(direction.rawValue)")
        subject.send(.paginating)
        
        do {
            let timelineEndReached = switch direction {
            case .backwards: try await timeline.paginateBackwards(numEvents: requestSize)
            case .forwards: try await timeline.paginateForwards(numEvents: requestSize)
            }
            MXLog.info("Finished paginating \(direction.rawValue)")

            subject.send(timelineEndReached ? .endReached : .idle)
            return .success(())
        } catch {
            MXLog.error("Failed paginating \(direction.rawValue) with error: \(error)")
            subject.send(.idle)
            return .failure(.sdkError(error))
        }
    }
    
    func retryDecryption(sessionIDs: [String]?) {
        let sessionIDs = sessionIDs ?? []
        
        MXLog.info("Retrying decryption for sessionIDs: \(sessionIDs)")
        
        timeline.retryDecryption(sessionIds: sessionIDs)
        MXLog.info("Finished retrying decryption for sessionID: \(sessionIDs)")
    }
    
    func edit(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, newContent: EditedContent) async -> Result<Void, TimelineProxyError> {
        do {
            try await timeline.edit(eventOrTransactionId: eventOrTransactionID.rustValue, newContent: newContent)
            
            MXLog.info("Finished editing timeline item: \(eventOrTransactionID)")

            return .success(())
        } catch {
            MXLog.error("Failed editing timeline item: \(eventOrTransactionID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func redact(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, reason: String?) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Redacting timeline item: \(eventOrTransactionID)")
        
        do {
            try await timeline.redactEvent(eventOrTransactionId: eventOrTransactionID.rustValue, reason: reason)
            
            MXLog.info("Redacted timeline item: \(eventOrTransactionID)")
            
            return .success(())
        } catch {
            MXLog.error("Failed redacting timeline item: \(eventOrTransactionID) with error: \(error)")
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
                   caption: String?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending audio")
        
        do {
            let handle = try timeline.sendAudio(params: .init(source: .file(filename: url.path(percentEncoded: false)),
                                                              caption: caption,
                                                              formattedCaption: nil, // Rust will build this from the caption's markdown.
                                                              mentions: nil,
                                                              inReplyTo: nil),
                                                audioInfo: audioInfo)
            
            await requestHandle(handle)
            
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
                  caption: String?,
                  requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending file")
        
        do {
            let handle = try timeline.sendFile(params: .init(source: .file(filename: url.path(percentEncoded: false)),
                                                             caption: caption,
                                                             formattedCaption: nil, // Rust will build this from the caption's markdown.
                                                             mentions: nil,
                                                             inReplyTo: nil),
                                               fileInfo: fileInfo)
            
            await requestHandle(handle)
            
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
                   caption: String?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending image")
        
        do {
            let handle = try timeline.sendImage(params: .init(source: .file(filename: url.path(percentEncoded: false)),
                                                              caption: caption,
                                                              formattedCaption: nil, // Rust will build this from the caption's markdown.
                                                              mentions: nil,
                                                              inReplyTo: nil),
                                                thumbnailSource: .file(filename: thumbnailURL.path(percentEncoded: false)),
                                                imageInfo: imageInfo)
            
            await requestHandle(handle)
            
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
        
        do {
            try await timeline.sendLocation(body: body,
                                            geoUri: geoURI.string,
                                            description: description,
                                            zoomLevel: zoomLevel,
                                            assetType: assetType,
                                            repliedToEventId: nil)
            
            MXLog.info("Finished sending location")
        } catch {
            MXLog.error("Failed sending location with error: \(error)")
            return .failure(.sdkError(error))
        }
        
        return .success(())
    }
    
    func sendVideo(url: URL,
                   thumbnailURL: URL,
                   videoInfo: VideoInfo,
                   caption: String?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending video")
        
        do {
            let handle = try timeline.sendVideo(params: .init(source: .file(filename: url.path(percentEncoded: false)),
                                                              caption: caption,
                                                              formattedCaption: nil,
                                                              mentions: nil,
                                                              inReplyTo: nil),
                                                thumbnailSource: .file(filename: thumbnailURL.path(percentEncoded: false)),
                                                videoInfo: videoInfo)
            
            await requestHandle(handle)
            
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
                          waveform: [Float],
                          requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending voice message")
        
        do {
            let handle = try timeline.sendVoiceMessage(params: .init(source: .file(filename: url.path(percentEncoded: false)),
                                                                     caption: nil,
                                                                     formattedCaption: nil,
                                                                     mentions: nil,
                                                                     inReplyTo: nil),
                                                       audioInfo: audioInfo,
                                                       waveform: waveform)
            
            await requestHandle(handle)
            
            try await handle.join()
            MXLog.info("Finished sending voice message")
        } catch {
            MXLog.error("Failed sending vocie message with error: \(error)")
            return .failure(.sdkError(error))
        }
        
        return .success(())
    }
    
    /// Send a message within a room. If `inReplyToEventID` is specified then it will be sent as a reply
    /// to that particular message. This works for both normal and threaded timelines with the relation and
    /// fallback logic being handled SDK side based on the timeline instance focus mode.
    func sendMessage(_ message: String,
                     html: String?,
                     inReplyToEventID: String? = nil,
                     intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError> {
        if let inReplyToEventID {
            MXLog.info("Sending reply to eventID: \(inReplyToEventID)")
        } else {
            MXLog.info("Sending message")
        }
        
        let messageContent = buildMessageContentFor(message,
                                                    html: html,
                                                    intentionalMentions: intentionalMentions.toRustMentions())
        
        do {
            if let inReplyToEventID {
                try await timeline.sendReply(msg: messageContent, eventId: inReplyToEventID)
                MXLog.info("Finished sending reply to eventID: \(inReplyToEventID)")
            } else {
                _ = try await timeline.send(msg: messageContent)
                MXLog.info("Finished sending message")
            }
        } catch {
            if let inReplyToEventID {
                MXLog.error("Failed sending reply to eventID: \(inReplyToEventID) with error: \(error)")
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
    
    func markAsRead(receiptType: ReceiptType) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Marking as \(receiptType)")
        
        do {
            try await timeline.markAsRead(receiptType: receiptType)
            MXLog.info("Finished marking as read")
            return .success(())
        } catch {
            MXLog.error("Failed marking as \(receiptType) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func toggleReaction(_ reaction: String, to eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Toggling reaction \(reaction) for event: \(eventOrTransactionID)")
        
        do {
            _ = try await timeline.toggleReaction(itemId: eventOrTransactionID.rustValue, key: reaction)
            MXLog.info("Finished toggling reaction for event: \(eventOrTransactionID)")
            return .success(())
        } catch {
            MXLog.error("Failed toggling reaction for event: \(eventOrTransactionID)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Polls

    func createPoll(question: String, answers: [String],
                    pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
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
            
            try await timeline.edit(eventOrTransactionId: originalEvent.eventOrTransactionId,
                                    newContent: .pollStart(pollData: .init(question: question,
                                                                           answers: answers,
                                                                           maxSelections: 1,
                                                                           pollKind: .init(pollKind: pollKind))))
            
            MXLog.info("Finished editing poll with eventID: \(eventID)")
            
            return .success(())
        } catch {
            MXLog.error("Failed editing poll with eventID: \(eventID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func endPoll(pollStartID: String, text: String) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Ending poll with eventID: \(pollStartID)")
        
        do {
            try await timeline.endPoll(pollStartEventId: pollStartID, text: text)
            
            MXLog.info("Finished ending poll with eventID: \(pollStartID)")
            
            return .success(())
        } catch {
            MXLog.error("Failed ending poll with eventID: \(pollStartID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }

    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, TimelineProxyError> {
        MXLog.info("Sending response for poll with eventID: \(pollStartID)")
        
        do {
            try await timeline.sendPollResponse(pollStartEventId: pollStartID, answers: answers)
            
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
            let backPaginationListener = SDKListener<RoomPaginationStatus> { [weak self] status in
                guard let self else {
                    return
                }
                
                switch status {
                case .idle(let hitStartOfTimeline):
                    backPaginationStateSubject.send(hitStartOfTimeline ? .endReached : .idle)
                case .paginating:
                    backPaginationStateSubject.send(.paginating)
                }
            }
            
            do {
                backPaginationStateObservationToken = try await timeline.subscribeToBackPaginationStatus(listener: backPaginationListener)
            } catch {
                MXLog.error("Failed to subscribe to back pagination status with error: \(error)")
            }
            forwardPaginationStateSubject.send(.endReached)
        case .detached, .thread:
            // Detached timelines don't support observation, set the initial state ourself.
            backPaginationStateSubject.send(.idle)
            forwardPaginationStateSubject.send(.idle)
        case .media(let presentation):
            backPaginationStateSubject.send(presentation == .pinnedEventsScreen ? .endReached : .idle)
            forwardPaginationStateSubject.send(presentation == .roomScreenDetached ? .idle : .endReached)
        case .pinned:
            backPaginationStateSubject.send(.endReached)
            forwardPaginationStateSubject.send(.endReached)
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
                if eventTimelineItem.id.uniqueID == id.uniqueID {
                    return eventTimelineItem.item
                }
            }
        }
        
        return nil
    }
    
    func firstEventTimelineItemUsingEventOrTransactionID(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) -> EventTimelineItem? {
        for item in self {
            if case let .event(eventTimelineItem) = item,
               case let .event(_, identifier) = eventTimelineItem.id,
               identifier == eventOrTransactionID {
                return eventTimelineItem.item
            }
        }
        
        return nil
    }
}

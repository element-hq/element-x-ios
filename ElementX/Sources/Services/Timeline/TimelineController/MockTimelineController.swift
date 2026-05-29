//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all

import Combine
import Foundation
import MatrixRustSDK

class MockTimelineController: TimelineControllerProtocol {
    private let lastInsertedMessageID: TimelineItemIdentifier = .event(uniqueID: .init("last_message"),
                                                                       eventOrTransactionID: .eventID("last_message"))
    
    private var roomProxy: JoinedRoomProxyProtocol?
    private var timelineProxy: TimelineProxyProtocol?
    
    var roomID: String {
        roomProxy?.id ?? "MockRoomIdentifier"
    }
    
    private(set) var timelineKind: TimelineKind
    
    let callbacks = PassthroughSubject<TimelineControllerCallback, Never>()
    
    private(set) var timelineItems: [RoomTimelineItemProtocol] = RoomTimelineItemFixtures.default {
        didSet {
            callbacks.send(.updatedTimelineItems(timelineItems: timelineItems, isSwitchingTimelines: false))
        }
    }
    
    private let timelineItemsTimestamps: [TimelineItemIdentifier: Date]
    
    /// An array of timeline item arrays that will be inserted in order for each back pagination request.
    var backPaginationResponses: [[RoomTimelineItemProtocol]] = []
    
    var paginationState: TimelinePaginationState = .initial {
        didSet {
            callbacks.send(.paginationState(paginationState))
        }
    }
    
    static var mediaGallery: MockTimelineController {
        MockTimelineController(timelineKind: .media(.mediaFilesScreen), timelineItems: (0..<5).reduce([]) { partialResult, _ in
            partialResult + [RoomTimelineItemFixtures.separator] + RoomTimelineItemFixtures.mediaChunk
        })
    }
    
    static var emptyMediaGallery: MockTimelineController {
        let mock = MockTimelineController(timelineKind: .media(.mediaFilesScreen))
        mock.paginationState = TimelinePaginationState(backward: .endReached, forward: .endReached)
        return mock
    }
    
    init(roomProxy: JoinedRoomProxyProtocol? = nil,
         timelineKind: TimelineKind = .live,
         timelineItems: [RoomTimelineItemProtocol] = RoomTimelineItemFixtures.default,
         timelineProxy: TimelineProxyProtocol? = nil,
         timelineItemsTimestamps: [TimelineItemIdentifier: Date] = [TimelineItemIdentifier: Date]()) {
        self.roomProxy = roomProxy
        self.timelineKind = timelineKind
        self.timelineItems = timelineItems
        self.timelineProxy = timelineProxy
        self.timelineItemsTimestamps = timelineItemsTimestamps
        
        callbacks.send(.paginationState(paginationState))
        callbacks.send(.isLive(true))
    }
    
    private(set) var focusOnEventCallCount = 0
    func focusOnEvent(_ eventID: String, timelineSize: UInt16) async -> Result<Void, TimelineControllerError> {
        focusOnEventCallCount += 1
        callbacks.send(.isLive(false))
        return .success(())
    }
    
    private(set) var focusLiveCallCount = 0
    func focusLive() {
        focusLiveCallCount += 1
        callbacks.send(.isLive(true))
    }
    
    private(set) var paginateBackwardsCallCount = 0
    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineControllerError> {
        paginateBackwardsCallCount += 1
        paginationState = TimelinePaginationState(backward: .paginating, forward: .endReached)
        simulateBackPagination()
        return .success(())
    }
    
    private func simulateBackPagination() {
        defer {
            paginationState = TimelinePaginationState(backward: backPaginationResponses.isEmpty ? .endReached : .idle,
                                                      forward: .endReached)
        }
        
        guard !backPaginationResponses.isEmpty else { return }
        
        let newItems = backPaginationResponses.removeFirst()
        timelineItems.insert(contentsOf: newItems, at: 0)
    }
    
    private(set) var paginateForwardsCallCount = 0
    func paginateForwards(requestSize: UInt16) async -> Result<Void, TimelineControllerError> {
        paginateForwardsCallCount += 1
        return .success(())
    }
    
    func sendReadReceipt(for itemID: TimelineItemIdentifier) async {
        guard let roomProxy, let eventID = itemID.eventID else { return }
        _ = await roomProxy.timeline.sendReadReceipt(for: eventID, type: .read)
    }
    
    func processItemAppearance(_ itemID: TimelineItemIdentifier) async { }
    
    func processItemDisappearance(_ itemID: TimelineItemIdentifier) async { }
    
    func toggleReaction(_ reaction: String, to eventID: TimelineItemIdentifier.EventOrTransactionID) async {
        if let timelineProxy {
            _ = await timelineProxy.toggleReaction(reaction, to: eventID)
        }
    }
    
    func edit(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID,
              message: String,
              html: String?,
              intentionalMentions: IntentionalMentions) async {
        callbacks.send(.messageSentOrEdited)
        
        timelineItems[timelineItems.endIndex - 1] = TextRoomTimelineItem(id: lastInsertedMessageID,
                                                                         timestamp: .distantFuture,
                                                                         isOutgoing: true,
                                                                         isEditable: true,
                                                                         canBeRepliedTo: true,
                                                                         sender: .test,
                                                                         content: .init(body: message),
                                                                         properties: .init(isEdited: true))
    }
    
    func editCaption(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID,
                     message: String,
                     html: String?,
                     intentionalMentions: IntentionalMentions) async { }
    
    func removeCaption(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async { }
    
    private(set) var redactCalled = false
    func redact(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async {
        if let timelineProxy {
            _ = await timelineProxy.redact(eventOrTransactionID, reason: nil)
        }
        redactCalled = true
    }
    
    func pin(eventID: String) async { }
    
    func unpin(eventID: String) async { }
    
    func messageEventContent(for itemID: TimelineItemIdentifier) -> RoomMessageEventContentWithoutRelation? {
        .init(noHandle: .init())
    }
    
    func debugInfo(for itemID: TimelineItemIdentifier) -> TimelineItemDebugInfo {
        .init(model: "Mock debug description", originalJSON: nil, latestEditJSON: nil)
    }
    
    func sendHandle(for itemID: TimelineItemIdentifier) -> SendHandleProxy? {
        nil
    }
    
    func eventTimestamp(for itemID: TimelineItemIdentifier) -> Date? {
        timelineItemsTimestamps[itemID] ?? .now
    }
    
    // MARK: - Sending
    
    func sendMessage(_ message: String,
                     html: String?,
                     inReplyToEventID: String?,
                     intentionalMentions: IntentionalMentions) async {
        callbacks.send(.messageSentOrEdited)
        
        timelineItems.append(TextRoomTimelineItem(id: lastInsertedMessageID,
                                                  timestamp: .distantFuture,
                                                  isOutgoing: true,
                                                  isEditable: true,
                                                  canBeRepliedTo: true,
                                                  sender: .test,
                                                  content: .init(body: message)))
    }
    
    func sendAudio(url: URL,
                   audioInfo: MatrixRustSDK.AudioInfo,
                   caption: String?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError> {
        callbacks.send(.messageSentOrEdited)
        
        if let timelineProxy {
            return await timelineProxy.sendAudio(url: url,
                                                 audioInfo: audioInfo,
                                                 caption: caption,
                                                 requestHandle: requestHandle).mapError(TimelineControllerError.timelineProxyError)
        }
        
        return .success(())
    }
    
    func sendFile(url: URL,
                  fileInfo: MatrixRustSDK.FileInfo,
                  caption: String?,
                  requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError> {
        callbacks.send(.messageSentOrEdited)
        
        if let timelineProxy {
            return await timelineProxy.sendFile(url: url,
                                                fileInfo: fileInfo,
                                                caption: caption,
                                                requestHandle: requestHandle).mapError(TimelineControllerError.timelineProxyError)
        }
        
        return .success(())
    }
    
    func sendImage(url: URL,
                   thumbnailURL: URL,
                   imageInfo: MatrixRustSDK.ImageInfo,
                   caption: String?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError> {
        callbacks.send(.messageSentOrEdited)
        
        if let timelineProxy {
            return await timelineProxy.sendImage(url: url,
                                                 thumbnailURL: thumbnailURL,
                                                 imageInfo: imageInfo,
                                                 caption: caption,
                                                 requestHandle: requestHandle).mapError(TimelineControllerError.timelineProxyError)
        }
        
        return .success(())
    }
    
    func sendLocation(body: String,
                      geoURI: GeoURI,
                      description: String?,
                      zoomLevel: UInt8?,
                      assetType: MatrixRustSDK.AssetType?) async -> Result<Void, TimelineControllerError> {
        callbacks.send(.messageSentOrEdited)
        
        if let timelineProxy {
            return await timelineProxy.sendLocation(body: body,
                                                    geoURI: geoURI,
                                                    description: description,
                                                    zoomLevel: zoomLevel,
                                                    assetType: assetType).mapError(TimelineControllerError.timelineProxyError)
        }
        
        return .success(())
    }
    
    func sendVideo(url: URL,
                   thumbnailURL: URL,
                   videoInfo: MatrixRustSDK.VideoInfo,
                   caption: String?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError> {
        callbacks.send(.messageSentOrEdited)
        
        if let timelineProxy {
            return await timelineProxy.sendVideo(url: url,
                                                 thumbnailURL: thumbnailURL,
                                                 videoInfo: videoInfo,
                                                 caption: caption,
                                                 requestHandle: requestHandle).mapError(TimelineControllerError.timelineProxyError)
        }
        
        return .success(())
    }
    
    func sendVoiceMessage(url: URL,
                          audioInfo: MatrixRustSDK.AudioInfo,
                          waveform: [Float],
                          requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError> {
        callbacks.send(.messageSentOrEdited)
        
        if let timelineProxy {
            return await timelineProxy.sendVoiceMessage(url: url,
                                                        audioInfo: audioInfo,
                                                        waveform: waveform,
                                                        requestHandle: requestHandle).mapError(TimelineControllerError.timelineProxyError)
        }
        
        return .success(())
    }
    
    // MARK: - Polls
    
    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineControllerError> {
        callbacks.send(.messageSentOrEdited)
        
        if let timelineProxy {
            _ = await timelineProxy.createPoll(question: question, answers: answers, pollKind: pollKind)
        }
        return .success(())
    }
    
    func editPoll(original eventID: String, question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineControllerError> {
        if let timelineProxy {
            _ = await timelineProxy.editPoll(original: eventID, question: question, answers: answers, pollKind: pollKind)
        }
        return .success(())
    }
    
    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, TimelineControllerError> {
        if let timelineProxy {
            _ = await timelineProxy.sendPollResponse(pollStartID: pollStartID, answers: answers)
        }
        return .success(())
    }
    
    func endPoll(pollStartID: String, text: String) async -> Result<Void, TimelineControllerError> {
        if let timelineProxy {
            _ = await timelineProxy.endPoll(pollStartID: pollStartID, text: text)
        }
        return .success(())
    }
}

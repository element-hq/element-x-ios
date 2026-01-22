//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

enum TimelineControllerCallback {
    case updatedTimelineItems(timelineItems: [RoomTimelineItemProtocol], isSwitchingTimelines: Bool)
    case paginationState(TimelinePaginationState)
    case isLive(Bool)
}

enum TimelineControllerAction {
    enum TimelineViewModelKind {
        /// Use the active timeline view model.
        case active
        /// Use the newly generated view model provided.
        case new(TimelineViewModel)
    }
    
    case displayMediaPreview(item: EventBasedMessageTimelineItemProtocol, timelineViewModel: TimelineViewModelKind)
    case displayLocation(body: String, geoURI: GeoURI, description: String?)
    case none
}

enum TimelineControllerError: Error {
    case generic
    case eventNotFound
    case timelineProxyError(TimelineProxyError)
}

/// This protocol is a high level abstraction on top of the ``TimelineProxyProtocol``
/// and its ``TimelineItemProviderProtocol`` that offers an UI layer oriented interface for dealing
/// with Room timelines.
/// It, for example, permits switching from a live timeline to an event focused one, building view specific
/// timeline items, grouping together state events, donating intents to the larger system etc.
@MainActor
protocol TimelineControllerProtocol {
    var roomID: String { get }
    var timelineKind: TimelineKind { get }
    
    /// The currently known items, use only for setting up the intial state.
    var timelineItems: [RoomTimelineItemProtocol] { get }
    
    /// The current pagination state, use only for setting up the intial state
    var paginationState: TimelinePaginationState { get }
    
    var callbacks: PassthroughSubject<TimelineControllerCallback, Never> { get }
    
    func processItemAppearance(_ itemID: TimelineItemIdentifier) async
    
    func processItemDisappearance(_ itemID: TimelineItemIdentifier) async
    
    func focusOnEvent(_ eventID: String, timelineSize: UInt16) async -> Result<Void, TimelineControllerError>
    func focusLive()
    
    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineControllerError>
    func paginateForwards(requestSize: UInt16) async -> Result<Void, TimelineControllerError>
    
    func sendReadReceipt(for itemID: TimelineItemIdentifier) async
    
    func edit(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID,
              message: String,
              html: String?,
              intentionalMentions: IntentionalMentions) async
    
    func editCaption(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID,
                     message: String,
                     html: String?,
                     intentionalMentions: IntentionalMentions) async
    
    func removeCaption(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async
    
    func toggleReaction(_ reaction: String, to eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async

    func redact(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async
    
    func pin(eventID: String) async
    
    func unpin(eventID: String) async
    
    func messageEventContent(for itemID: TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation?
    
    func debugInfo(for itemID: TimelineItemIdentifier) -> TimelineItemDebugInfo
    
    func sendHandle(for itemID: TimelineItemIdentifier) -> SendHandleProxy?
    
    func eventTimestamp(for itemID: TimelineItemIdentifier) -> Date?
    
    // MARK: - Sending
    
    func sendMessage(_ message: String,
                     html: String?,
                     inReplyToEventID: String?,
                     intentionalMentions: IntentionalMentions) async
    
    func sendAudio(url: URL,
                   audioInfo: AudioInfo,
                   caption: String?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError>
    
    func sendFile(url: URL,
                  fileInfo: FileInfo,
                  caption: String?,
                  requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError>
    
    func sendImage(url: URL,
                   thumbnailURL: URL,
                   imageInfo: ImageInfo,
                   caption: String?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError>
    
    func sendLocation(body: String,
                      geoURI: GeoURI,
                      description: String?,
                      zoomLevel: UInt8?,
                      assetType: AssetType?) async -> Result<Void, TimelineControllerError>
    
    func sendVideo(url: URL,
                   thumbnailURL: URL,
                   videoInfo: VideoInfo,
                   caption: String?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError>
    
    func sendVoiceMessage(url: URL,
                          audioInfo: AudioInfo,
                          waveform: [Float],
                          requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineControllerError>
    
    // MARK: - Poll
    
    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineControllerError>
    
    func editPoll(original eventID: String,
                  question: String,
                  answers: [String],
                  pollKind: Poll.Kind) async -> Result<Void, TimelineControllerError>
    
    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, TimelineControllerError>
    
    func endPoll(pollStartID: String, text: String) async -> Result<Void, TimelineControllerError>
}

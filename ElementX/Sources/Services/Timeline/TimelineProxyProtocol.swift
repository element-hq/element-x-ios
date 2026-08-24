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

nonisolated enum TimelineKind: Equatable {
    case live
    case detached
    case pinned
    case thread(rootEventID: String)
    
    enum MediaPresentation { case roomScreenLive, roomScreenDetached, roomScreenThread, pinnedEventsScreen, mediaFilesScreen }
    case media(MediaPresentation)
    
    var isThread: Bool {
        threadRootEventID != nil
    }
    
    var threadRootEventID: String? {
        switch self {
        case .thread(let rootEventID):
            rootEventID
        default:
            nil
        }
    }
}

enum TimelineFocus {
    case live
    case eventID(String)
    case thread(eventID: String)
    case pinned
    /// Only the messages of the allowed types, served from the SDK's event cache index
    /// (instant for a cached room, no history walk), with the room's gaps as spinner items.
    /// Shows the newest page, or a page around the given event to paginate from both ways.
    case messageTypes(aroundEventID: String? = nil)
}

enum TimelineAllowedMessageType {
    case audio, file, image, video, gallery
    
    /// The gallery attachments this type allows, so that a gallery event's attachments can be
    /// filtered client side to match. A gallery can't contain another gallery, hence the `nil`.
    var allowedGalleryItemType: TimelineAllowedGalleryItemType? {
        switch self {
        case .audio: .audio
        case .file: .file
        case .image: .image
        case .video: .video
        case .gallery: nil
        }
    }
}

/// The gallery attachments a timeline allows, mirroring the message types it is filtered to. The SDK can
/// only filter whole events, so a gallery's attachments are filtered by these client side. Unlike a
/// message type there's no gallery case, as a gallery can't contain another one.
enum TimelineAllowedGalleryItemType {
    case audio, file, image, video
}

extension [TimelineAllowedMessageType] {
    /// The gallery attachments these types allow, or `nil` when they place no restriction on them,
    /// which is the case for a timeline made up of galleries alone.
    var allowedGalleryItemTypes: [TimelineAllowedGalleryItemType]? {
        let types = compactMap(\.allowedGalleryItemType)
        return types.isEmpty ? nil : types
    }
}

enum TimelineProxyError: Error {
    case sdkError(Error)
}

/// Element X proxies generally wrap the counterpart RustSDK objects while providing platform specific
/// interfaces. In this case it composes methods for interacting with a room's timeline and should be used alongside
/// the ``TimelineItemProviderProtocol`` which offers a reactive interface to timeline changes.
protocol TimelineProxyProtocol: Sendable {
    var timelineItemProvider: TimelineItemProviderProtocol { get }
    
    func subscribeForUpdates() async
    
    func fetchDetails(for eventID: String)
    
    func messageEventContent(for timelineItemID: TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation?
    
    func retryDecryption(sessionIDs: [String]?)
    
    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError>
    func paginateForwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError>
    
    func resolveGap(prevToken: String, requestSize: UInt16) async -> Result<Void, TimelineProxyError>
    
    func edit(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID,
              newContent: EditedContent) async -> Result<Void, TimelineProxyError>
    
    func redact(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID,
                reason: String?) async -> Result<Void, TimelineProxyError>
    
    func pin(eventID: String) async -> Result<Bool, TimelineProxyError>
    
    func unpin(eventID: String) async -> Result<Bool, TimelineProxyError>
    
    // MARK: - Sending
    
    func sendAudio(url: URL,
                   audioInfo: AudioInfo,
                   caption: String?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>
    
    func sendFile(url: URL,
                  fileInfo: FileInfo,
                  caption: String?,
                  requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>
    
    func sendImage(url: URL,
                   thumbnailURL: URL,
                   imageInfo: ImageInfo,
                   caption: String?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>
    
    func sendLocation(body: String,
                      geoURI: GeoURI,
                      description: String?,
                      zoomLevel: UInt8?,
                      assetType: AssetType?) async -> Result<Void, TimelineProxyError>
    
    func sendVideo(url: URL,
                   thumbnailURL: URL,
                   videoInfo: VideoInfo,
                   caption: String?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>
    
    func sendVoiceMessage(url: URL,
                          audioInfo: AudioInfo,
                          waveform: [Float],
                          requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>
    
    func sendGallery(itemInfos: [GalleryItemInfo],
                     caption: String?,
                     inReplyToEventID: String?) async -> Result<Void, TimelineProxyError>
    
    func sendReadReceipt(for eventID: String, type: ReceiptType) async -> Result<Void, TimelineProxyError>
    func markAsRead(receiptType: ReceiptType) async -> Result<Void, TimelineProxyError>
    
    func sendMessageEventContent(_ messageContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError>
    
    func sendMessage(_ message: String,
                     html: String?,
                     inReplyToEventID: String?,
                     intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError>
    
    func toggleReaction(_ reaction: String, to eventID: TimelineItemIdentifier.EventOrTransactionID) async -> Result<Void, TimelineProxyError>
    
    func createPoll(question: String, answers: [String], maxSelections: Int, pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError>
    
    func editPoll(original eventID: String,
                  question: String,
                  answers: [String],
                  maxSelections: Int,
                  pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError>
    
    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, TimelineProxyError>
    
    func endPoll(pollStartID: String, text: String) async -> Result<Void, TimelineProxyError>
    
    func getLoadedReplyDetails(eventID: String) async -> Result<InReplyToDetails, TimelineProxyError>
    
    func buildMessageContentFor(_ message: String,
                                html: String?,
                                intentionalMentions: Mentions) -> RoomMessageEventContentWithoutRelation
}

// sourcery: AutoMockable
extension TimelineProxyProtocol { }

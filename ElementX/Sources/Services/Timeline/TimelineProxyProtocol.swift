//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

enum TimelineKind {
    case live
    case detached
    case pinned
}

enum TimelineProxyError: Error {
    case sdkError(Error)
    
    case failedEditing
    case failedRedacting
    case failedPaginatingEndReached
}

// sourcery: AutoMockable
protocol TimelineProxyProtocol {
    var timelineProvider: RoomTimelineProviderProtocol { get }
    
    func subscribeForUpdates() async
    
    func fetchDetails(for eventID: String)
    
    func messageEventContent(for timelineItemID: TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation?
    
    func retryDecryption(for sessionID: String) async
    
    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError>
    func paginateForwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError>
    
    func edit(_ timelineItem: EventTimelineItem, newContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError>
    
    func redact(_ timelineItemID: TimelineItemIdentifier,
                reason: String?) async -> Result<Void, TimelineProxyError>
    
    func pin(eventID: String) async -> Result<Bool, TimelineProxyError>
    
    func unpin(eventID: String) async -> Result<Bool, TimelineProxyError>
    
    // MARK: - Sending
    
    func sendAudio(url: URL,
                   audioInfo: AudioInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>
    
    func sendFile(url: URL,
                  fileInfo: FileInfo,
                  progressSubject: CurrentValueSubject<Double, Never>?,
                  requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>
    
    func sendImage(url: URL,
                   thumbnailURL: URL,
                   imageInfo: ImageInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>
    
    func sendLocation(body: String,
                      geoURI: GeoURI,
                      description: String?,
                      zoomLevel: UInt8?,
                      assetType: AssetType?) async -> Result<Void, TimelineProxyError>
    
    func sendVideo(url: URL,
                   thumbnailURL: URL,
                   videoInfo: VideoInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>
    
    func sendVoiceMessage(url: URL,
                          audioInfo: AudioInfo,
                          waveform: [UInt16],
                          progressSubject: CurrentValueSubject<Double, Never>?,
                          requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError>
    
    func sendReadReceipt(for eventID: String, type: ReceiptType) async -> Result<Void, TimelineProxyError>
    
    func sendMessageEventContent(_ messageContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError>
    
    func sendMessage(_ message: String,
                     html: String?,
                     inReplyTo eventID: String?,
                     intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError>
    
    func toggleReaction(_ reaction: String, to itemID: TimelineItemIdentifier) async -> Result<Void, TimelineProxyError>
    
    // Polls
    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError>
    
    func editPoll(original eventID: String,
                  question: String,
                  answers: [String],
                  pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError>
    
    func endPoll(pollStartID: String, text: String) async -> Result<Void, TimelineProxyError>
    
    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, TimelineProxyError>
    
    func getLoadedReplyDetails(eventID: String) async -> Result<InReplyToDetails, TimelineProxyError>
    
    func buildMessageContentFor(_ message: String,
                                html: String?,
                                intentionalMentions: Mentions) -> RoomMessageEventContentWithoutRelation
}

extension TimelineProxyProtocol {
    func sendMessage(_ message: String,
                     html: String?,
                     intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError> {
        await sendMessage(message,
                          html: html,
                          inReplyTo: nil,
                          intentionalMentions: intentionalMentions)
    }
}

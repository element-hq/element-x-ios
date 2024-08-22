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
    var kind: TimelineKind { get }
    
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
    
    func toggleReaction(_ reaction: String, to eventID: String) async -> Result<Void, TimelineProxyError>
    
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

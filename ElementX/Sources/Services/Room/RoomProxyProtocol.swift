//
// Copyright 2022 New Vector Ltd
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

enum RoomProxyError: Error, Equatable {
    case noMoreMessagesToBackPaginate
    case failedPaginatingBackwards
    case failedRetrievingMemberAvatarURL
    case failedRetrievingMemberDisplayName
    case failedSendingReadReceipt
    case failedSendingMessage
    case failedSendingReaction
    case failedSendingMedia
    case failedEditingMessage
    case failedRedactingEvent
    case failedReportingContent
    case failedAddingTimelineListener
    case failedRetrievingMembers
    case failedRetrievingMember
    case failedLeavingRoom
    case failedAcceptingInvite
    case failedRejectingInvite
    case failedInvitingUser
    case failedSettingRoomName
    case failedSettingRoomTopic
    case failedRemovingAvatar
    case failedUploadingAvatar
    case failedCheckingPermission
    case failedCreatingPoll
    case failedSendingPollResponse
    case failedEndingPoll
}

// sourcery: AutoMockable
protocol RoomProxyProtocol {
    var id: String { get }
    var isDirect: Bool { get }
    var isPublic: Bool { get }
    var isSpace: Bool { get }
    var isEncrypted: Bool { get }
    var isTombstoned: Bool { get }
    var canonicalAlias: String? { get }
    var alternativeAliases: [String] { get }
    var hasUnreadNotifications: Bool { get }
    var ownUserID: String { get }
    
    var name: String? { get }
    var displayName: String? { get }
    
    var topic: String? { get }
    
    var avatarURL: URL? { get }

    var members: CurrentValuePublisher<[RoomMemberProxyProtocol], Never> { get }
    
    var invitedMembersCount: Int { get }
    
    var joinedMembersCount: Int { get }
    
    var activeMembersCount: Int { get }
    
    /// Publishes room state updates
    /// The thread on which this publisher sends the output isn't defined.
    var stateUpdatesPublisher: AnyPublisher<Void, Never> { get }
    
    var timelineProvider: RoomTimelineProviderProtocol { get }
    
    func subscribeForUpdates() async

    func loadAvatarURLForUserId(_ userId: String) async -> Result<URL?, RoomProxyError>
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError>
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomProxyError>
    
    func sendReadReceipt(for eventID: String) async -> Result<Void, RoomProxyError>
    
    func messageEventContent(for eventID: String) -> RoomMessageEventContentWithoutRelation?
    
    func sendMessageEventContent(_ messageContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, RoomProxyError>
    
    func sendMessage(_ message: String, html: String?, inReplyTo eventID: String?) async -> Result<Void, RoomProxyError>
    
    func toggleReaction(_ reaction: String, to eventID: String) async -> Result<Void, RoomProxyError>
    
    func sendImage(url: URL,
                   thumbnailURL: URL,
                   imageInfo: ImageInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>
    
    func sendVideo(url: URL,
                   thumbnailURL: URL,
                   videoInfo: VideoInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>
    
    func sendAudio(url: URL,
                   audioInfo: AudioInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>

    func sendFile(url: URL,
                  fileInfo: FileInfo,
                  progressSubject: CurrentValueSubject<Double, Never>?,
                  requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError>

    func sendLocation(body: String,
                      geoURI: GeoURI,
                      description: String?,
                      zoomLevel: UInt8?,
                      assetType: AssetType?) async -> Result<Void, RoomProxyError>

    /// Retries sending a failed message given its transaction ID
    func retrySend(transactionID: String) async

    /// Cancels  a failed message given its transaction ID from the timeline
    func cancelSend(transactionID: String) async

    func editMessage(_ newMessage: String, html: String?, original eventID: String) async -> Result<Void, RoomProxyError>
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError>
    
    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError>
    
    func ignoreUser(_ userID: String) async -> Result<Void, RoomProxyError>
    
    func retryDecryption(for sessionID: String) async

    func leaveRoom() async -> Result<Void, RoomProxyError>
    
    func updateMembers() async

    func getMember(userID: String) async -> Result<RoomMemberProxyProtocol, RoomProxyError>

    func inviter() async -> RoomMemberProxyProtocol?
    
    func rejectInvitation() async -> Result<Void, RoomProxyError>
    
    func acceptInvitation() async -> Result<Void, RoomProxyError>
    
    func fetchDetails(for eventID: String)
    
    func invite(userID: String) async -> Result<Void, RoomProxyError>
    
    func setName(_ name: String) async -> Result<Void, RoomProxyError>
    
    func setTopic(_ topic: String) async -> Result<Void, RoomProxyError>
    
    func removeAvatar() async -> Result<Void, RoomProxyError>
    
    func uploadAvatar(media: MediaInfo) async -> Result<Void, RoomProxyError>

    func canUserRedact(userID: String) async -> Result<Bool, RoomProxyError>
    
    func canUserTriggerRoomNotification(userID: String) async -> Result<Bool, RoomProxyError>

    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, RoomProxyError>

    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, RoomProxyError>

    func endPoll(pollStartID: String, text: String) async -> Result<Void, RoomProxyError>
}

extension RoomProxyProtocol {
    var permalink: URL? {
        if let canonicalAlias, let link = try? PermalinkBuilder.permalinkTo(roomAlias: canonicalAlias,
                                                                            baseURL: ServiceLocator.shared.settings.permalinkBaseURL) {
            return link
        } else if let link = try? PermalinkBuilder.permalinkTo(roomIdentifier: id,
                                                               baseURL: ServiceLocator.shared.settings.permalinkBaseURL) {
            return link
        } else {
            MXLog.error("Failed to build permalink for Room: \(id)")
            return nil
        }
    }
    
    func sendMessage(_ message: String, html: String?) async -> Result<Void, RoomProxyError> {
        await sendMessage(message, html: html, inReplyTo: nil)
    }
    
    // Avoids to duplicate the same logic around in the app
    // Probably this should be done in rust.
    var roomTitle: String {
        displayName ?? name ?? "Unknown room 💥"
    }
    
    var isEncryptedOneToOneRoom: Bool {
        isDirect && isEncrypted && activeMembersCount <= 2
    }

    func members() async -> [RoomMemberProxyProtocol]? {
        await updateMembers()
        return members.value
    }
}

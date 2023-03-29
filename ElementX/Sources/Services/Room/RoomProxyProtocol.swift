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

enum RoomProxyError: Error {
    case noMoreMessagesToBackPaginate
    case failedPaginatingBackwards
    case failedRetrievingMemberAvatarURL
    case failedRetrievingMemberDisplayName
    case failedSendingReadReceipt
    case failedSendingMessage
    case failedSendingReaction
    case failedEditingMessage
    case failedRedactingEvent
    case failedReportingContent
    case failedAddingTimelineListener
    case failedRetrievingMembers
    case failedLeavingRoom
}

@MainActor
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
    
    var name: String? { get }
    var displayName: String? { get }
    
    var topic: String? { get }
    
    var avatarURL: URL? { get }

    var membersPublisher: AnyPublisher<[RoomMemberProxyProtocol], Never> { get }

    func loadAvatarURLForUserId(_ userId: String) async -> Result<URL?, RoomProxyError>
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError>
    
    func addTimelineListener(listener: TimelineListener) -> Result<[TimelineItem], RoomProxyError>
    
    func removeTimelineListener()
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomProxyError>
    
    func sendReadReceipt(for eventID: String) async -> Result<Void, RoomProxyError>
    
    func sendMessage(_ message: String, inReplyTo eventID: String?) async -> Result<Void, RoomProxyError>
    
    func sendReaction(_ reaction: String, to eventID: String) async -> Result<Void, RoomProxyError>

    func editMessage(_ newMessage: String, original eventID: String) async -> Result<Void, RoomProxyError>
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError>

    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError>
    
    func retryDecryption(for sessionID: String) async

    func leaveRoom() async -> Result<Void, RoomProxyError>
    
    func populateMembers() async
}

extension RoomProxyProtocol {
    var permalink: URL? {
        if let canonicalAlias, let link = try? PermalinkBuilder.permalinkTo(roomAlias: canonicalAlias) {
            return link
        } else if let link = try? PermalinkBuilder.permalinkTo(roomIdentifier: id) {
            return link
        } else {
            MXLog.error("Failed to build permalink for Room: \(id)")
            return nil
        }
    }
    
    func sendMessage(_ message: String) async -> Result<Void, RoomProxyError> {
        await sendMessage(message, inReplyTo: nil)
    }
}

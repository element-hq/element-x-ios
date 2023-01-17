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
    case failedAddingTimelineListener
    case failedRetrievingMembers
}

@MainActor
protocol RoomProxyProtocol {
    var id: String { get }
    var isDirect: Bool { get }
    var isPublic: Bool { get }
    var isSpace: Bool { get }
    var isEncrypted: Bool { get }
    var isTombstoned: Bool { get }
    var hasUnreadNotifications: Bool { get }
    
    var name: String? { get }
    var displayName: String? { get }
    
    var topic: String? { get }
    
    var avatarURL: URL? { get }
    
    func avatarURLForUserId(_ userId: String) -> URL?
    
    func loadAvatarURLForUserId(_ userId: String) async -> Result<URL?, RoomProxyError>
    
    func displayNameForUserId(_ userId: String) -> String?
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError>
    
    func addTimelineListener(listener: TimelineListener) -> Result<Void, RoomProxyError>
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomProxyError>
    
    func sendReadReceipt(for eventID: String) async -> Result<Void, RoomProxyError>
    
    func sendMessage(_ message: String, inReplyToEventId: String?) async -> Result<Void, RoomProxyError>
    
    func sendReaction(_ reaction: String, for eventId: String) async -> Result<Void, RoomProxyError>

    func editMessage(_ newMessage: String, originalEventId: String) async -> Result<Void, RoomProxyError>
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError>

    func members() async -> Result<[RoomMemberProxy], RoomProxyError>
    
    func retryDecryption(forSessionId sessionId: String) async
}

extension RoomProxyProtocol {
    func sendMessage(_ message: String) async -> Result<Void, RoomProxyError> {
        await sendMessage(message, inReplyToEventId: nil)
    }
}

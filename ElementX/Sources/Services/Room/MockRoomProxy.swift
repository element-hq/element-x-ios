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

struct MockRoomProxy: RoomProxyProtocol {
    var id = UUID().uuidString
    let name: String? = nil
    let displayName: String?
    var topic: String?
    var avatarURL: URL?
    var isDirect = Bool.random()
    var isSpace = Bool.random()
    var isPublic = Bool.random()
    var isEncrypted = Bool.random()
    var isTombstoned = Bool.random()
    var canonicalAlias: String?
    var alternativeAliases: [String] = []
    var hasUnreadNotifications = Bool.random()
    var members: [RoomMemberProxy]?
    
    let timelineProvider: RoomTimelineProviderProtocol = MockRoomTimelineProvider()
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        .failure(.failedRetrievingMemberDisplayName)
    }
    
    func loadAvatarURLForUserId(_ userId: String) async -> Result<URL?, RoomProxyError> {
        .failure(.failedRetrievingMemberAvatarURL)
    }
    
    func startLiveEventListener() { }
    
    func addTimelineListener(listener: TimelineListener) -> Result<[TimelineItem], RoomProxyError> {
        .failure(.failedAddingTimelineListener)
    }
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomProxyError> {
        .failure(.failedPaginatingBackwards)
    }
    
    func sendReadReceipt(for eventID: String) async -> Result<Void, RoomProxyError> {
        .failure(.failedSendingReadReceipt)
    }
        
    func sendMessage(_ message: String, inReplyTo eventID: String? = nil) async -> Result<Void, RoomProxyError> {
        .failure(.failedSendingMessage)
    }
    
    func sendReaction(_ reaction: String, to eventID: String) async -> Result<Void, RoomProxyError> {
        .failure(.failedSendingMessage)
    }

    func editMessage(_ newMessage: String, original eventID: String) async -> Result<Void, RoomProxyError> {
        .failure(.failedSendingMessage)
    }
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError> {
        .failure(.failedRedactingEvent)
    }

    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError> {
        .failure(.failedReportingContent)
    }

    func members() async -> Result<[RoomMemberProxy], RoomProxyError> {
        if let members {
            return .success(members)
        }
        return .failure(.failedRetrievingMembers)
    }
    
    func retryDecryption(for sessionID: String) async { }
}

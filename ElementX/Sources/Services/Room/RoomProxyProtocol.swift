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
import UIKit

enum RoomProxyError: Error {
    case failedRetrievingDisplayName
    case failedRetrievingAvatar
    case backwardStreamNotAvailable
    case failedRetrievingMemberAvatarURL
    case failedRetrievingMemberDisplayName
    case failedSendingMessage
    case failedRedactingEvent
}

enum RoomProxyCallback {
    case updatedMessages
}

protocol RoomProxyProtocol {
    var id: String { get }
    var isDirect: Bool { get }
    var isPublic: Bool { get }
    var isSpace: Bool { get }
    var isEncrypted: Bool { get }
    var isTombstoned: Bool { get }
    
    var name: String? { get }
    var displayName: String? { get }
    
    var topic: String? { get }
    var messages: [RoomMessageProtocol] { get }
    
    var avatarURL: String? { get }
    
    func loadAvatarURLForUserId(_ userId: String) async -> Result<String?, RoomProxyError>
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError>
    
    func loadDisplayName() async -> Result<String, RoomProxyError>
    
    func paginateBackwards(count: UInt) async -> Result<Void, RoomProxyError>
    
    func sendMessage(_ message: String) async -> Result<Void, RoomProxyError>
    
    func redactItem(_ itemId: String) async -> Result<Void, RoomProxyError>
    
    var callbacks: PassthroughSubject<RoomProxyCallback, Never> { get }
}

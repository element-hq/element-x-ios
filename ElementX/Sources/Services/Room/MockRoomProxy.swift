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
import UIKit

struct MockRoomProxy: RoomProxyProtocol {
    let id = UUID().uuidString
    let name: String? = nil
    let displayName: String?
    
    let topic: String? = nil
    let messages: [RoomMessageProtocol] = []
    
    let avatarURL: String? = nil
    
    let isDirect = Bool.random()
    let isSpace = Bool.random()
    let isPublic = Bool.random()
    let isEncrypted = Bool.random()
    let isTombstoned = Bool.random()
    
    var callbacks = PassthroughSubject<RoomProxyCallback, Never>()
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        .failure(.failedRetrievingMemberDisplayName)
    }
    
    func loadAvatarURLForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        .failure(.failedRetrievingMemberAvatarURL)
    }
    
    func loadDisplayName() async -> Result<String, RoomProxyError> {
        .failure(.failedRetrievingDisplayName)
    }
    
    func startLiveEventListener() { }
    
    func paginateBackwards(count: UInt) async -> Result<Void, RoomProxyError> {
        .failure(.backwardStreamNotAvailable)
    }
        
    func sendMessage(_ message: String) async -> Result<Void, RoomProxyError> {
        .failure(.failedSendingMessage)
    }
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError> {
        .failure(.failedRedactingEvent)
    }
}

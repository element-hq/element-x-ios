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

import Foundation
import MatrixRustSDK

struct RoomMemberDetails: Identifiable, Hashable {
    let id: String
    let name: String?
    let avatarURL: URL?
    let permalink: URL?
    
    var isInvited: Bool
    var isIgnored: Bool
    var isBanned: Bool
    
    enum Role { case administrator, moderator, user }
    let role: Role
    
    func matches(searchQuery: String) -> Bool {
        guard !searchQuery.isEmpty else { return true }
        return id.localizedStandardContains(searchQuery) || name?.localizedStandardContains(searchQuery) == true
    }
}

extension RoomMemberDetails {
    init(withProxy proxy: RoomMemberProxyProtocol) {
        id = proxy.userID
        name = proxy.displayName
        avatarURL = proxy.avatarURL
        permalink = proxy.permalink
        
        isInvited = proxy.membership == .invite
        isIgnored = proxy.isIgnored
        isBanned = proxy.membership == .ban
        role = .init(proxy.role)
    }
}

extension RoomMemberDetails.Role {
    init(_ role: RoomMemberRole) {
        self = switch role {
        case .administrator: .administrator
        case .moderator: .moderator
        case .user: .user
        }
    }
}

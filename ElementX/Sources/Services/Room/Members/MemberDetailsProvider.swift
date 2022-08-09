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

import Foundation

class MemberDetailProvider: MemberDetailProviderProtocol {
    private let roomProxy: RoomProxyProtocol
    private var memberAvatars = [String: String]()
    private var memberDisplayNames = [String: String]()
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
    }
    
    func avatarURLStringForUserId(_ userId: String) -> String? {
        memberAvatars[userId]
    }
    
    func loadAvatarURLStringForUserId(_ userId: String) async -> Result<String?, MemberDetailProviderError> {
        if let avatarURL = avatarURLStringForUserId(userId) {
            return .success(avatarURL)
        }
        
        switch await roomProxy.loadAvatarURLForUserId(userId) {
        case .success(let avatarURL):
            memberAvatars[userId] = avatarURL
            return .success(avatarURL)
        case .failure:
            return .failure(.failedRetrievingUserAvatarURL)
        }
    }
        
    func displayNameForUserId(_ userId: String) -> String? {
        memberDisplayNames[userId]
    }
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, MemberDetailProviderError> {
        if let displayName = displayNameForUserId(userId) {
            return .success(displayName)
        }
        
        switch await roomProxy.loadDisplayNameForUserId(userId) {
        case .success(let displayName):
            memberDisplayNames[userId] = displayName
            return .success(displayName)
        case .failure:
            return .failure(.failedRetrievingUserDisplayName)
        }
    }
}

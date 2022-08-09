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

enum MemberDetailProviderError: Error {
    case invalidRoomProxy
    case failedRetrievingUserAvatarURL
    case failedRetrievingUserDisplayName
}

@MainActor
protocol MemberDetailProviderProtocol {
    func avatarURLStringForUserId(_ userId: String) -> String?
    func loadAvatarURLStringForUserId(_ userId: String) async -> Result<String?, MemberDetailProviderError>
    
    func displayNameForUserId(_ userId: String) -> String?
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, MemberDetailProviderError>
}

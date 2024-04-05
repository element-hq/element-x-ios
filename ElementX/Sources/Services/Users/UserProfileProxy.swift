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

struct UserProfileProxy: Equatable, Hashable {
    let userID: String
    let displayName: String?
    let avatarURL: URL?
    
    init(userID: String, displayName: String? = nil, avatarURL: URL? = nil) {
        self.userID = userID
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
    
    init(sdkUserProfile: MatrixRustSDK.UserProfile) {
        userID = sdkUserProfile.userId
        displayName = sdkUserProfile.displayName
        avatarURL = sdkUserProfile.avatarUrl.flatMap(URL.init(string:))
    }
    
    /// A user is meant to be "verified" when the GET profile returns back either the display name or the avatar
    /// If isn't we aren't sure that the related matrix id really exists.
    var isVerified: Bool {
        displayName != nil || avatarURL != nil
    }
}

struct SearchUsersResultsProxy {
    let results: [UserProfileProxy]
    let limited: Bool
}

extension SearchUsersResultsProxy {
    init(sdkResults: MatrixRustSDK.SearchUsersResults) {
        results = sdkResults.results.map(UserProfileProxy.init)
        limited = sdkResults.limited
    }
}

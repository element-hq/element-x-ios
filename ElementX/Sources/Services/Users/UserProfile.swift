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

struct UserProfileProxy {
    let userID: String
    let displayName: String?
    let avatarURL: URL?
    
    init(userID: String, displayName: String?, avatarURL: URL?) {
        self.userID = userID
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
    
    init(userProfile: UserProfile) {
        userID = userProfile.userId
        displayName = userProfile.displayName
        avatarURL = userProfile.avatarUrl.flatMap(URL.init(string:))
    }
}

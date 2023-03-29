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

struct RoomMemberDetails: Identifiable, Equatable {
    let id: String
    let name: String?
    let avatarURL: URL?
    let permalink: URL?
    let isAccountOwner: Bool
    var isIgnored: Bool

    @MainActor
    init(withProxy proxy: RoomMemberProxyProtocol) {
        id = proxy.userID
        name = proxy.displayName
        avatarURL = proxy.avatarURL
        permalink = proxy.permalink
        isAccountOwner = proxy.isAccountOwner
        isIgnored = proxy.isIgnored
    }
}

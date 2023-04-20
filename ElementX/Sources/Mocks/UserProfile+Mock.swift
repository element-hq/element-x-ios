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

extension UserProfile {
    // Mocks
    static var mockAlice: UserProfile {
        .init(userID: "@alice:matrix.org", displayName: "Alice", avatarURL: URL(staticString: "mxc://matrix.org/UcCimidcvpFvWkPzvjXMQPHA"))
    }

    static var mockBob: UserProfile {
        .init(userID: "@bob:matrix.org", displayName: "Bob", avatarURL: nil)
    }

    static var mockBobby: UserProfile {
        .init(userID: "@bobby:matrix.org", displayName: "Bobby", avatarURL: nil)
    }

    static var mockCharlie: UserProfile {
        .init(userID: "@charlie:matrix.org", displayName: "Charlie", avatarURL: nil)
    }
}

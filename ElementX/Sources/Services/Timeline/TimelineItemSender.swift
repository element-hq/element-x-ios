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

import UIKit

#warning("This could be replaced by RoomMemberProxy if Rust includes a RoomMember.")
struct TimelineItemSender: Identifiable, Hashable {
    let id: String
    
    // Lazy loaded properties, displayName and avatarURL will be come lets.
    var displayName: String?
    var avatarURL: URL?
    var avatar: UIImage?
}

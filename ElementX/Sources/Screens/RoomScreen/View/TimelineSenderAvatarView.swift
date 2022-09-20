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
import SwiftUI

struct TimelineSenderAvatarView: View {
    let timelineItem: EventBasedTimelineItemProtocol

    @ScaledMetric private var avatarSize = 32

    var body: some View {
        ZStack(alignment: .center) {
            if let avatar = timelineItem.senderAvatar {
                Image(uiImage: avatar)
                    .resizable()
                    .scaledToFill()
                    .overlay(Circle().stroke(Color.element.accent))
            } else {
                PlaceholderAvatarImage(text: timelineItem.senderDisplayName ?? timelineItem.senderId)
            }
        }
        .clipShape(Circle())
        .frame(width: avatarSize, height: avatarSize)
        .overlay(
            Circle()
                .stroke(Color.element.background, lineWidth: 3)
        )

        .animation(.elementDefault, value: timelineItem.senderAvatar)
    }
}

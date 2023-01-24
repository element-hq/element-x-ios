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
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    @ScaledMetric private var avatarSize = AvatarSize.user(on: .timeline).value
    
    let timelineItem: EventBasedTimelineItemProtocol
        
    var body: some View {
        LoadableAvatarImage(imageProvider: context.imageProvider,
                            url: timelineItem.sender.avatarURL,
                            avatarSize: .user(on: .timeline),
                            text: timelineItem.sender.displayName ?? timelineItem.sender.id,
                            contentID: timelineItem.sender.id)
            .overlay(
                Circle().stroke(Color.element.background, lineWidth: 3)
            )
    }
}

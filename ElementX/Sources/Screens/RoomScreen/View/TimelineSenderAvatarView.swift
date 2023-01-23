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
    private let timelineItem: EventBasedTimelineItemProtocol
    private let imageProvider: ImageProviderProtocol?

    @ScaledMetric private var avatarSize = AvatarSize.user(on: .timeline).value
    @State private var avatarImage: UIImage?
    
    init(timelineItem: EventBasedTimelineItemProtocol,
         imageProvider: ImageProviderProtocol?) {
        self.timelineItem = timelineItem
        self.imageProvider = imageProvider
        
        _avatarImage = State(initialValue: imageProvider?.imageFromURL(timelineItem.sender.avatarURL, avatarSize: .room(on: .timeline)))
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            if let avatar = avatarImage {
                Image(uiImage: avatar)
                    .resizable()
                    .scaledToFill()
                    .overlay(Circle().stroke(Color.element.accent))
            } else {
                PlaceholderAvatarImage(text: timelineItem.sender.displayName ?? timelineItem.sender.id,
                                       contentId: timelineItem.sender.id)
            }
        }
        .clipShape(Circle())
        .frame(width: avatarSize, height: avatarSize)
        .overlay(
            Circle()
                .stroke(Color.element.background, lineWidth: 3)
        )
        .animation(.elementDefault, value: avatarImage)
        .task {
            guard avatarImage == nil, let avatarURL = timelineItem.sender.avatarURL else { return }
            
            if case let .success(image) = await imageProvider?.loadImageFromURL(avatarURL, avatarSize: .room(on: .timeline)) {
                avatarImage = image
            }
        }
    }
}

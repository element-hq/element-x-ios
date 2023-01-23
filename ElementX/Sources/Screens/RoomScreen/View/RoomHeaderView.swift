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

import Combine
import Foundation
import SwiftUI

import Introspect

struct RoomHeaderView: View {
    @ObservedObject var context: RoomScreenViewModel.Context
    @State var avatarImage: UIImage?

    var body: some View {
        HStack(spacing: 8) {
            roomAvatar
                .accessibilityHidden(true)
            Text(context.viewState.roomTitle)
                .font(.element.headline)
                .accessibilityIdentifier("roomNameLabel")
        }
        // Using a button stops is from getting truncated in the navigation bar
        .onTapGesture {
            context.send(viewAction: .displayRoomDetails)
        }
        .task {
            guard avatarImage == nil, let avatarURL = context.viewState.roomAvatarURL else { return }
            
            if case let .success(image) = await context.imageProvider?.loadImageFromURL(avatarURL, avatarSize: .room(on: .timeline)) {
                avatarImage = image
            }
        }
    }

    @ViewBuilder private var roomAvatar: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarImageView
                .clipShape(Circle())
        }
        .frame(width: AvatarSize.room(on: .timeline).value, height: AvatarSize.room(on: .timeline).value)
    }
    
    @ViewBuilder private var avatarImageView: some View {
        if let avatar = avatarImage {
            Image(uiImage: avatar)
                .resizable()
                .scaledToFill()
                .accessibilityIdentifier("roomAvatarImage")
        } else {
            PlaceholderAvatarImage(text: context.viewState.roomTitle,
                                   contentId: context.viewState.roomId)
                .accessibilityIdentifier("roomAvatarPlaceholderImage")
        }
    }
}

struct RoomHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        bodyPlain
        bodyEncrypted
    }

    @ViewBuilder
    static var bodyPlain: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            mediaProvider: MockMediaProvider(),
                                            roomName: "Some Room name",
                                            roomAvatarUrl: URL.picturesDirectory)

        RoomHeaderView(context: viewModel.context)
            .previewLayout(.sizeThatFits)
            .padding()
    }

    @ViewBuilder
    static var bodyEncrypted: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            mediaProvider: MockMediaProvider(),
                                            roomName: "Some Room name",
                                            roomAvatarUrl: nil)

        RoomHeaderView(context: viewModel.context)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

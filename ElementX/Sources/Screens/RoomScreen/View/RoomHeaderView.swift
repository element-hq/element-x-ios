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

    var body: some View {
        HStack(spacing: 8) {
            roomAvatar
                .accessibilityHidden(true)
            Text(context.viewState.roomTitle)
                .font(.element.headline)
                .accessibilityIdentifier("roomNameLabel")
        }
        .onTapGesture {
            context.send(viewAction: .headerTapped)
        }
    }

    @ViewBuilder private var roomAvatar: some View {
        ZStack(alignment: .bottomTrailing) {
            roomAvatarImage
                .clipShape(Circle())
        }
        .frame(width: AvatarSize.room(on: .timeline).value, height: AvatarSize.room(on: .timeline).value)
    }

    @ViewBuilder private var roomAvatarImage: some View {
        if let avatar = context.viewState.roomAvatar {
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
        bodyPlain.preferredColorScheme(.light)
        bodyPlain.preferredColorScheme(.dark)
        bodyEncrypted.preferredColorScheme(.light)
        bodyEncrypted.preferredColorScheme(.dark)
    }

    @ViewBuilder
    static var bodyPlain: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            mediaProvider: MockMediaProvider(),
                                            roomName: "Some Room name",
                                            roomAvatarUrl: "mock_url")

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

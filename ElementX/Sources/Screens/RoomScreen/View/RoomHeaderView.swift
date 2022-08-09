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
            Text(context.viewState.roomTitle)
                .font(.element.headline)
                .accessibilityIdentifier("roomNameLabel")
        }
    }

    @ViewBuilder private var roomAvatar: some View {
        ZStack(alignment: .bottomTrailing) {
            roomAvatarImage
                .clipShape(Circle())

            if let encryptionBadge = context.viewState.roomEncryptionBadge {
                Image(uiImage: encryptionBadge)
                    .accessibilityIdentifier("encryptionBadgeIcon")
            }
        }
        .frame(width: 32.0, height: 32.0)
    }

    @ViewBuilder private var roomAvatarImage: some View {
        if let avatar = context.viewState.roomAvatar {
            Image(uiImage: avatar)
                .resizable()
                .scaledToFill()
                .accessibilityIdentifier("roomAvatarImage")
        } else {
            PlaceholderAvatarImage(text: context.viewState.roomTitle)
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
                                            roomName: "Some Room name",
                                            roomAvatar: Asset.Images.appLogo.image)

        RoomHeaderView(context: viewModel.context)
            .previewLayout(.sizeThatFits)
            .padding()
    }

    @ViewBuilder
    static var bodyEncrypted: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            roomName: "Some Room name",
                                            roomAvatar: nil,
                                            roomEncryptionBadge: Asset.Images.encryptionTrusted.image)

        RoomHeaderView(context: viewModel.context)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

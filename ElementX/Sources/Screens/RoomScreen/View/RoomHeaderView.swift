//
//  RoomHeaderView.swift
//  ElementX
//
//  Created by Ismail on 21.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

import Introspect

struct RoomHeaderView: View {

    @ObservedObject var context: RoomScreenViewModel.Context

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            roomAvatar
            Text(context.viewState.roomTitle)
                .font(.element.headline)
                .accessibilityIdentifier("roomNameLabel")
        }
    }

    @ViewBuilder private var roomAvatar: some View {
        ZStack {
            roomAvatarImage
                .clipShape(Circle())

            if let encryptionBadge = context.viewState.roomEncryptionBadge {
                Image(uiImage: encryptionBadge)
                    .offset(x: 10, y: 10)
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
            PlaceholderAvatarImage(firstCharacter: String(context.viewState.roomTitle.first ?? Character("")))
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
                                            roomAvatar: Asset.Images.appLogo.image
        )

        RoomHeaderView(context: viewModel.context)
            .previewLayout(.sizeThatFits)
            .padding()
    }

    @ViewBuilder
    static var bodyEncrypted: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            roomName: "Some Room name",
                                            roomAvatar: Asset.Images.appLogo.image,
                                            roomEncryptionBadge: Asset.Images.encryptionTrusted.image
        )

        RoomHeaderView(context: viewModel.context)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

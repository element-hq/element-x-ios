//
//  TimelineSenderAvatarView.swift
//  ElementX
//
//  Created by Ismail on 24.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct TimelineSenderAvatarView: View {
    let timelineItem: EventBasedTimelineItemProtocol

    @ScaledMetric private var avatarSize = 26

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
                .stroke(Color.element.background, lineWidth: 2)
        )

        .animation(.elementDefault, value: timelineItem.senderAvatar)
    }
}

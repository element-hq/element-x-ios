//
//  TimelineItemStyleView.swift
//  ElementX
//
//  Created by Ismail on 21.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

import Introspect

struct TimelineItemPlainStylerView<Content: View>: View {

    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content

    @ScaledMetric private var avatarSize = 26

    var body: some View {
        VStack(alignment: .leading) {
            header
            content()
        }
    }

    @ViewBuilder
    private var header: some View {
        if timelineItem.shouldShowSenderDetails {
            HStack {
                senderAvatar
                Text(timelineItem.senderDisplayName ?? timelineItem.senderId)
                    .font(.body)
                    .foregroundColor(.element.primaryContent)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(timelineItem.timestamp)
                    .foregroundColor(Color.element.tertiaryContent)
                    .font(.element.caption2)
            }
        }
    }

    @ViewBuilder
    private var senderAvatar: some View {
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

        .animation(.default, value: timelineItem.senderAvatar)
    }
}

struct TimelineItemPlainStylerView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }

    @ViewBuilder
    static var body: some View {
        VStack(alignment: .leading) {
            TimelineItemPlainStylerView(timelineItem: item1) {
                Text(item1.text)
            }
            TimelineItemPlainStylerView(timelineItem: item2) {
                Text(item2.text)
            }
            TimelineItemPlainStylerView(timelineItem: item3) {
                Text(item3.text)
            }
            TimelineItemPlainStylerView(timelineItem: item4) {
                Text(item4.text)
            }
        }
        .padding(.horizontal, 8)
        .frame(maxHeight: 400)
        .previewLayout(.sizeThatFits)
    }

    private static var item1: TextRoomTimelineItem {
        return TextRoomTimelineItem(id: UUID().uuidString,
                                    text: "Short 1",
                                    timestamp: "07:05",
                                    shouldShowSenderDetails: true,
                                    isOutgoing: false,
                                    senderId: "Bob")
    }

    private static var item2: TextRoomTimelineItem {
        return TextRoomTimelineItem(id: UUID().uuidString,
                                    text: "Short loin ground round tongue hamburger, fatback salami shoulder.",
                                    timestamp: "08:05",
                                    shouldShowSenderDetails: true,
                                    isOutgoing: false,
                                    senderId: "Bob")
    }

    private static var item3: TextRoomTimelineItem {
        return TextRoomTimelineItem(id: UUID().uuidString,
                                    text: "Short loin ground round tongue hamburger, fatback salami shoulder 2.",
                                    timestamp: "08:07",
                                    shouldShowSenderDetails: false,
                                    isOutgoing: true,
                                    senderId: "Bob")
    }

    private static var item4: TextRoomTimelineItem {
        return TextRoomTimelineItem(id: UUID().uuidString,
                                    text: "Short 2",
                                    timestamp: "08:08",
                                    shouldShowSenderDetails: false,
                                    isOutgoing: true,
                                    senderId: "Bob")
    }
}

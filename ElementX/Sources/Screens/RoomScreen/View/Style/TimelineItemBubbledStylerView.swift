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

struct TimelineItemBubbledStylerView<Content: View>: View {

    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric private var minBubbleWidth = 44
    @ScaledMetric private var avatarSize = 26

    var body: some View {
        VStack(alignment: timelineItem.isOutgoing ? .trailing : .leading, spacing: -5) {
            if !timelineItem.isOutgoing {
                header
                    .zIndex(1)
            }
            if timelineItem.isOutgoing {
                HStack {
                    Spacer()
                    styledContent
                }
                .padding(.trailing, 16)
                .padding(.leading, 51)
            } else {
                styledContent
                    .padding(.leading, 16)
                    .padding(.trailing, 51)
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if timelineItem.shouldShowSenderDetails {
            VStack {
                Spacer()
                    .frame(height: 8)
                HStack(alignment: .top, spacing: 4) {
                    senderAvatar
                    Text(timelineItem.senderDisplayName ?? timelineItem.senderId)
                        .font(.body)
                        .foregroundColor(.element.primaryContent)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
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

    @ViewBuilder
    var styledContent: some View {
        if shouldAvoidBubbling {
            ZStack(alignment: .bottomTrailing) {
                content()
                    .clipped()
                    .cornerRadius(8)
                Text(timelineItem.timestamp)
                    .foregroundColor(.global.white)
                    .font(.element.caption2)
                    .padding(4)
                    .background(Color(white: 0, opacity: 0.7))
                    .clipped()
                    .cornerRadius(8)
                    .offset(x: -8, y: -8)
            }
        } else {
            VStack(alignment: .trailing, spacing: 4) {
                content()
                    .frame(minWidth: minBubbleWidth, alignment: .leading)

                Text(timelineItem.timestamp)
                    .foregroundColor(Color.element.tertiaryContent)
                    .font(.element.caption2)
            }
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 4, trailing: 8))
            .clipped()
            .background(bubbleColor)
            .cornerRadius(12)
        }
    }

    private var shouldAvoidBubbling: Bool {
        return timelineItem is ImageRoomTimelineItem
    }

    private var bubbleColor: Color {
        let opacity = colorScheme == .light ? 0.06 : 0.15
        return timelineItem.isOutgoing ? .element.accent.opacity(opacity) : .element.system
    }

}

struct TimelineItemBubbledStylerView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }

    @ViewBuilder
    static var body: some View {
        VStack(alignment: .leading) {
            TimelineItemBubbledStylerView(timelineItem: item1) {
                Text(item1.text)
            }
            TimelineItemBubbledStylerView(timelineItem: item2) {
                Text(item2.text)
            }
            TimelineItemBubbledStylerView(timelineItem: item3) {
                Text(item3.text)
            }
            TimelineItemBubbledStylerView(timelineItem: item4) {
                Text(item4.text)
            }
        }
        .padding(.horizontal, 8)
        .frame(maxHeight: 400)
        .previewLayout(.sizeThatFits)
    }

    private static var item1: TextRoomTimelineItem {
        return TextRoomTimelineItem(id: UUID().uuidString,
                                    text: "Short",
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
                                    text: "Short loin ground round tongue hamburger, fatback salami shoulder.",
                                    timestamp: "08:07",
                                    shouldShowSenderDetails: false,
                                    isOutgoing: true,
                                    senderId: "Bob")
    }

    private static var item4: TextRoomTimelineItem {
        return TextRoomTimelineItem(id: UUID().uuidString,
                                    text: "Short",
                                    timestamp: "08:08",
                                    shouldShowSenderDetails: false,
                                    isOutgoing: true,
                                    senderId: "Bob")
    }
}

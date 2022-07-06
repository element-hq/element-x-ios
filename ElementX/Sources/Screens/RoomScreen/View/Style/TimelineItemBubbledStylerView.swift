//
//  TimelineItemStyleView.swift
//  ElementX
//
//  Created by Ismail on 21.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct TimelineItemBubbledStylerView<Content: View>: View {

    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric private var minBubbleWidth = 44

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
                    TimelineSenderAvatarView(timelineItem: timelineItem)
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
        timelineItem is ImageRoomTimelineItem
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
            ForEach(1..<MockRoomTimelineController().timelineItems.count, id: \.self) { index in
                let item = MockRoomTimelineController().timelineItems[index]
                RoomTimelineViewFactory().buildTimelineViewFor(timelineItem: item)
            }
        }
        .timelineStyle(.bubbles)
        .padding(.horizontal, 8)
        .previewLayout(.sizeThatFits)
    }
}

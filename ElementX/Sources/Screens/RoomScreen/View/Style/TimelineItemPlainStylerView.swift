//
//  TimelineItemStyleView.swift
//  ElementX
//
//  Created by Ismail on 21.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct TimelineItemPlainStylerView<Content: View>: View {

    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content

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
                TimelineSenderAvatarView(timelineItem: timelineItem)
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
}

struct TimelineItemPlainStylerView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }

    @ViewBuilder
    static var body: some View {
        VStack(alignment: .leading) {
            ForEach((1..<MockRoomTimelineController().timelineItems.count), id: \.self) { index in
                let item = MockRoomTimelineController().timelineItems[index]
                RoomTimelineViewFactory().buildTimelineViewFor(timelineItem: item)
            }
        }
        .timelineStyle(.plain)
        .padding(.horizontal, 8)
        .previewLayout(.sizeThatFits)
    }
}

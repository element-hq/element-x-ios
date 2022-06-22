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

struct TimelineItemStylerView<Content: View>: View {

    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            content()
            Text(timelineItem.timestamp)
                .font(.caption2)
        }
        .padding(8)
        .clipped()
        .background(Color.element.system)
        .cornerRadius(8)
    }

}

struct TimelineItemStylerView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }

    @ViewBuilder
    static var body: some View {
        TimelineItemStylerView(timelineItem: item1) {
            TextRoomTimelineView(timelineItem: item1)
        }
    }

    private static var item1: TextRoomTimelineItem {
        return TextRoomTimelineItem(id: UUID().uuidString,
                                    text: "Short loin ground round tongue hamburger, fatback salami shoulder. Beef turkey sausage kielbasa strip steak. Alcatra capicola pig tail pancetta chislic.",
                                    timestamp: "08:05",
                                    shouldShowSenderDetails: true,
                                    senderId: "Bob")
    }
}

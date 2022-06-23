//
//  EventBasedTimelineSenderView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 18/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct EventBasedTimelineSenderView: View {
    let timelineItem: EventBasedTimelineItemProtocol

    @ScaledMetric private var avatarSize = 26
    
    var body: some View {
        if timelineItem.shouldShowSenderDetails {
            VStack {
                Spacer()
                HStack(alignment: .top, spacing: 4) {
                    avatar
                    Text(timelineItem.senderDisplayName ?? timelineItem.senderId)
                        .font(.body)
                        .foregroundColor(.element.primaryContent)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
            }
        }
    }
    
    @ViewBuilder private var avatar: some View {
        ZStack(alignment: .center) {
            if let avatar = timelineItem.senderAvatar {
                Image(uiImage: avatar)
                    .resizable()
                    .scaledToFill()
                    .overlay(Circle().stroke(Color.element.accent))
            } else {
                PlaceholderAvatarImage(firstCharacter: String(firstLetter))
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
    
    private var firstLetter: String {
        if let senderDisplayName = timelineItem.senderDisplayName {
            return senderDisplayName.prefix(1).uppercased()
        } else {
            return timelineItem.senderId.prefix(2).suffix(1).uppercased()
        }
    }
}

struct EventBasedTimelineSenderView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            EventBasedTimelineSenderView(timelineItem: item1)
            
            EventBasedTimelineSenderView(timelineItem: item2)
        }
        .frame(maxHeight: 160)
        .previewLayout(.sizeThatFits)
    }

    private static var item1: EventBasedTimelineItemProtocol {
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "Some text",
                             timestamp: "",
                             shouldShowSenderDetails: true,
                             isOutgoing: false,
                             senderId: "",
                             senderDisplayName: "Bob")
    }

    private static var item2: EventBasedTimelineItemProtocol {
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "Some text",
                             timestamp: "",
                             shouldShowSenderDetails: true,
                             isOutgoing: false,
                             senderId: "",
                             senderDisplayName: "Some long display name for a user")
    }

}

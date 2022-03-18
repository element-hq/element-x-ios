//
//  EventBasedTimelineView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 18/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct EventBasedTimelineView: View {
    let timelineItem: EventBasedTimelineItemProtocol
    
    var body: some View {
        if timelineItem.shouldShowSenderDetails {
            HStack {
                avatar
                Text(timelineItem.sender)
                    .font(.footnote)
                    .bold()
                Spacer()
                Text(timelineItem.timestamp)
                    .font(.footnote)
            }
            Divider()
        }
    }
    
    @ViewBuilder private var avatar: some View {
        ZStack(alignment: .center) {
            if let avatar = timelineItem.senderAvatar {
                Image(uiImage: avatar)
                    .resizable()
                    .scaledToFill()
                    .overlay(Circle().stroke(Color(.sRGB, red: 0.05, green: 0.74, blue: 0.55, opacity: 1.0)))
            } else {
                PlaceholderAvatarImage(firstCharacter: String(timelineItem.sender.prefix(2).suffix(1)).uppercased())
            }
        }
        .clipShape(Circle())
        .frame(width: 44.0, height: 44.0)
    }
}

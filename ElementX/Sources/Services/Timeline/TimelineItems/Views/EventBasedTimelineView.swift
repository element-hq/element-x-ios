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
                Text(timelineItem.senderDisplayName ?? timelineItem.senderId)
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
                    .overlay(Circle().stroke(Color.elementGreen))
            } else {
                PlaceholderAvatarImage(firstCharacter: String(firstLetter))
            }
        }
        .clipShape(Circle())
        .frame(width: 44.0, height: 44.0)
    }
    
    private var firstLetter: String {
        if let senderDisplayName = timelineItem.senderDisplayName {
            return senderDisplayName.prefix(1).uppercased()
        } else {
            return timelineItem.senderId.prefix(2).suffix(1).uppercased()
        }
    }
}

//
//  TextRoomTimelineView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct TextRoomTimelineView: View {
    let timelineItem: TextRoomTimelineItem
    
    var body: some View {
        VStack(alignment: .leading) {
            if timelineItem.shouldShowSenderDetails {
                HStack {
                    Text(timelineItem.senderDisplayName)
                        .font(.footnote)
                        .bold()
                    Spacer()
                    Text(timelineItem.timestamp)
                        .font(.footnote)
                }
                Divider()
                Spacer()
            }
            Text(timelineItem.text)
        }
        .id(timelineItem.id)
    }
}

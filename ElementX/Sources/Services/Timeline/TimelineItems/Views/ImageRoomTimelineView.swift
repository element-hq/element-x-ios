//
//  ImageRoomTimelineView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct ImageRoomTimelineView: View {
    let timelineItem: ImageRoomTimelineItem
    
    var body: some View {
        if let image = timelineItem.image {
            VStack(alignment: .leading) {
                EventBasedTimelineView(timelineItem: timelineItem)
                Text(timelineItem.text)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        } else {
            VStack(alignment: .center) {
                HStack {
                    Text(timelineItem.text)
                    Spacer()
                }
                ProgressView("Loading")
            }
        }
    }
}

struct ImageRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let timelineItem = ImageRoomTimelineItem(id: UUID().uuidString,
                                                     text: "Some image",
                                                     timestamp: "Now",
                                                     shouldShowSenderDetails: false,
                                                     sender: "Bob",
                                                     url: nil,
                                                     image: UIImage(systemName: "photo"))
            ImageRoomTimelineView(timelineItem: timelineItem)
            
            let timelineItem = ImageRoomTimelineItem(id: UUID().uuidString,
                                                     text: "Some other image",
                                                     timestamp: "Now",
                                                     shouldShowSenderDetails: false,
                                                     sender: "Bob",
                                                     url: nil,
                                                     image: nil)
            ImageRoomTimelineView(timelineItem: timelineItem)
        }
    }
}

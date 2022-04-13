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
        if timelineItem.image != nil || timelineItem.blurhash != nil { // Fixes view heights after loading finishes
            VStack(alignment: .leading) {
                EventBasedTimelineView(timelineItem: timelineItem)
                Text(timelineItem.text)
                if let image = timelineItem.image {
                    if let aspectRatio = timelineItem.aspectRatio {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(aspectRatio, contentMode: .fit)
                    } else {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                } else if let blurhash = timelineItem.blurhash,
                          // Build a small blurhash image so that it's fast
                          let image = UIImage(blurHash: blurhash, size: .init(width: 10.0, height: 10.0)) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(timelineItem.aspectRatio, contentMode: .fit)
                }
            }
            .animation(.easeInOut, value: timelineItem.image)
            .frame(maxHeight: 1000.0)
        } else {
            VStack(alignment: .leading) {
                EventBasedTimelineView(timelineItem: timelineItem)
                Text(timelineItem.text)
                HStack {
                    Spacer()
                    ProgressView("Loading")
                    Spacer()
                }
            }
        }
    }
}

struct ImageRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
     
    @ViewBuilder
    static var body: some View {
        VStack(spacing: 20.0) {
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: UUID().uuidString,
                                                                      text: "Some image",
                                                                      timestamp: "Now",
                                                                      shouldShowSenderDetails: false,
                                                                      senderId: "Bob",
                                                                      source: nil,
                                                                      image: UIImage(systemName: "photo")))

            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: UUID().uuidString,
                                                                      text: "Some other image",
                                                                      timestamp: "Now",
                                                                      shouldShowSenderDetails: false,
                                                                      senderId: "Bob",
                                                                      source: nil,
                                                                      image: nil))
            
            ImageRoomTimelineView(timelineItem: ImageRoomTimelineItem(id: UUID().uuidString,
                                                                      text: "Blurhashed image",
                                                                      timestamp: "Now",
                                                                      shouldShowSenderDetails: false,
                                                                      senderId: "Bob",
                                                                      source: nil,
                                                                      image: nil,
                                                                      aspectRatio: 0.7,
                                                                      blurhash: "L%KUc%kqS$RP?Ks,WEf8OlrqaekW"))
        }
    }
}

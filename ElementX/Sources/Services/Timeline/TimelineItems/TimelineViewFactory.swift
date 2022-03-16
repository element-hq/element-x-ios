//
//  TimelineViewFactory.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct TimelineViewFactory {
    func buildTimelineViewFor(_ timelineItem: TimelineItemProtocol) -> RoomTimelineViewProvider {
        switch timelineItem {
        case let textItem as TextRoomTimelineItem:
            return .text(textItem)
        case let imageItem as ImageRoomTimelineItem:
            return .image(imageItem)
        default:
            fatalError("Unknown timeline item")
        }
    }
}

//
//  TimelineViewFactory.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct RoomTimelineViewFactory {
    func buildTimelineViewFor(_ timelineItem: RoomTimelineItemProtocol) -> RoomTimelineViewProvider {
        switch timelineItem {
        case let item as TextRoomTimelineItem:
            return .text(item)
        case let item as ImageRoomTimelineItem:
            return .image(item)
        case let item as SeparatorRoomTimelineItem:
            return .separator(item)
        default:
            fatalError("Unknown timeline item")
        }
    }
}

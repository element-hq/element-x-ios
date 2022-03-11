//
//  TextRoomTimelineItem.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

enum RoomTimelineViewProvider: Identifiable, Equatable {
    case text(TextRoomTimelineItem)
    case separator(SeparatorRoomTimelineItem)
    case image(ImageRoomTimelineItem)
    
    var id: String {
        switch self {
        case .text(let item):
            return item.id
        case .separator(let item):
            return item.id
        case .image(let item):
            return item.id
        }
    }
}

extension RoomTimelineViewProvider: View {
    @ViewBuilder var body: some View {
        switch self {
        case .text(let item):
            TextRoomTimelineView(timelineItem: item)
        case .separator(let item):
            SeparatorRoomTimelineView(timelineItem: item)
        case .image(let item):
            ImageRoomTimelineView(timelineItem: item)
        }
    }
}

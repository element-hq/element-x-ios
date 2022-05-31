//
//  RoomTimelineViewFactoryProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 26/05/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

@MainActor
protocol RoomTimelineViewFactoryProtocol {
    func buildTimelineViewFor(timelineItem: RoomTimelineItemProtocol) -> RoomTimelineViewProvider
}

//
//  RoomTimelineControllerProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine

protocol RoomTimelineControllerProtocol {
    var timelineItems: [RoomTimelineItem] { get }
    var callbacks: PassthroughSubject<RoomTimelineControllerCallback, Never> { get }
    
    func paginateBackwards(_ count: UInt)
}

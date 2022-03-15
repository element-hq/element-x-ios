//
//  RoomTimelineControllerProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine

enum RoomTimelineControllerCallback {
    case updatedTimelineItems
}

enum RoomTimelineControllerError: Error {
    case generic
}

protocol RoomTimelineControllerProtocol {
    var timelineItems: [RoomTimelineViewProvider] { get }
    var callbacks: PassthroughSubject<RoomTimelineControllerCallback, Never> { get }
    
    func paginateBackwards(_ count: UInt, callback: @escaping ((Result<Void, RoomTimelineControllerError>) -> Void))
}

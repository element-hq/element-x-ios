//
//  RoomTimelineProviderProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 18/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine

enum RoomTimelineCallback {
    case addedMessage
}

enum RoomTimelineError: Error {
    case generic
}

protocol RoomTimelineProviderProtocol {
    var callbacks: PassthroughSubject<RoomTimelineCallback, Never> { get }
    
    var messages: [RoomMessageProtocol] { get }
    
    func paginateBackwards(_ count: UInt, callback: ((Result<([RoomMessageProtocol]), RoomTimelineError>) -> Void)?)
}

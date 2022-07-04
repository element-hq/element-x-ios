//
//  RoomTimelineProviderProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 18/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine

enum RoomTimelineProviderCallback {
    case updatedMessages
}

enum RoomTimelineProviderError: Error {
    case failedSendingMessage
    case generic
}

@MainActor
protocol RoomTimelineProviderProtocol {
    var callbacks: PassthroughSubject<RoomTimelineProviderCallback, Never> { get }
    
    var messages: [RoomMessageProtocol] { get }
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineProviderError>
    
    func sendMessage(_ message: String) async -> Result<Void, RoomTimelineProviderError>
}

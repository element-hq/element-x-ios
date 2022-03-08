//
//  RoomTimeline.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine
import MatrixRustSDK

enum RoomTimelineCallback {
    case updatedMessages
}

class RoomTimelineProvider {
    private let roomProxy: RoomProxyProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private var paginationCounter: UInt = 0
    private var isWaitingPaginationResponse = false
    
    let callbacks = PassthroughSubject<RoomTimelineCallback, Never>()
    private(set) var messages = [Message]()
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
        
        self.roomProxy.startLiveEventListener()
        
        self.roomProxy.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            
            switch callback {
            case .addedMessage(let message):
                self.messages.append(message)
            case .prependedMessages(let messages):
                self.messages.insert(contentsOf: messages.reversed(), at: 0)
                self.isWaitingPaginationResponse = false
            case .updatedLastMessage:
                break
            }
            
            self.callbacks.send(.updatedMessages)
            
        }.store(in: &cancellables)
    }
    
    func paginateBackwards(_ count: UInt) {
        if isWaitingPaginationResponse {
            return
        }
        
        self.roomProxy.paginateBackwards(start: paginationCounter, finish: count)
        isWaitingPaginationResponse = true
        
        // This is not in any way correct but it will do for now.
        self.paginationCounter += count
    }
}

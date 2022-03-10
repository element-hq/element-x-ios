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
    
    let callbacks = PassthroughSubject<RoomTimelineCallback, Never>()
    private(set) var messages = [Message]()
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
        
        self.roomProxy.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            
            switch callback {
            case .addedMessage(let message):
                self.messages.append(message)
            case .updatedLastMessage:
                break
            }
            
            self.callbacks.send(.updatedMessages)
            
        }.store(in: &cancellables)
    }
    
    func paginateBackwards(_ count: UInt) {
        self.roomProxy.paginateBackwards(count: count) { result in
            switch result {
            case .success(let messages):
                self.messages.insert(contentsOf: messages.reversed(), at: 0)
                self.callbacks.send(.updatedMessages)
            case .failure(let error):
                MXLog.debug("Failed paginating backwards with error: \(error)")
                self.callbacks.send(.updatedMessages)
            }
        }
    }
}

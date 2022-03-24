//
//  RoomTimeline.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine

class RoomTimelineProvider: RoomTimelineProviderProtocol {
    private let roomProxy: RoomProxyProtocol
    private var cancellables = Set<AnyCancellable>()
    
    let callbacks = PassthroughSubject<RoomTimelineCallback, Never>()
    private(set) var messages = [RoomMessageProtocol]()
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
        
        self.roomProxy.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            
            switch callback {
            case .addedMessage(let message):
                self.messages.append(message)
                self.callbacks.send(.addedMessage)
            case .updatedLastMessage:
                break
            }
        }.store(in: &cancellables)
    }
    
    func paginateBackwards(_ count: UInt, callback: ((Result<([RoomMessageProtocol]), RoomTimelineError>) -> Void)?) {
        self.roomProxy.paginateBackwards(count: count) { result in
            switch result {
            case .success(let messages):
                self.messages.insert(contentsOf: messages, at: 0)
                callback?(.success((self.messages)))
            case .failure:
                callback?(.failure(.generic))
            }
        }
    }
}

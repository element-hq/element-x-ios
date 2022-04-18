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
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
        
        self.roomProxy.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            
            switch callback {
            case .updatedMessages:
                self.callbacks.send(.updatedMessages)
            }
        }.store(in: &cancellables)
    }
    
    var messages: [RoomMessageProtocol] {
        roomProxy.messages
    }
    
    func paginateBackwards(_ count: UInt, callback: ((Result<Void, RoomTimelineError>) -> Void)?) {
        self.roomProxy.paginateBackwards(count: count) { result in
            switch result {
            case .success:
                callback?(.success(()))
            case .failure:
                callback?(.failure(.generic))
            }
        }
    }
    
    func sendMessage(_ message: String) {
        roomProxy.sendMessage(message) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                MXLog.error("Failed sending message with error: \(error)")
            }
        }
    }
}

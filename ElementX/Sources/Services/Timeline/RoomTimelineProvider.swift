//
//  RoomTimeline.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Combine
import Foundation

class RoomTimelineProvider: RoomTimelineProviderProtocol {
    private let roomProxy: RoomProxyProtocol
    private var cancellables = Set<AnyCancellable>()
    
    let callbacks = PassthroughSubject<RoomTimelineProviderCallback, Never>()
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
        
        self.roomProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
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
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineProviderError> {
        switch await roomProxy.paginateBackwards(count: count) {
        case .success:
            return .success(())
        case .failure:
            return .failure(.generic)
        }
    }
    
    func sendMessage(_ message: String) async -> Result<Void, RoomTimelineProviderError> {
        switch await roomProxy.sendMessage(message) {
        case .success:
            return .success(())
        case .failure:
            return .failure(.failedSendingMessage)
        }
    }
}

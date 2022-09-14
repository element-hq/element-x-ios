//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
    
    func redactItem(_ itemID: String) async -> Result<Void, RoomTimelineProviderError> {
        switch await roomProxy.redactItem(itemID) {
        case .success:
            return .success(())
        case .failure:
            return .failure(.failedRedactingItem)
        }
    }
}

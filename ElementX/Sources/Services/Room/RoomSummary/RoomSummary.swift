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
import UIKit

class RoomSummary: RoomSummaryProtocol {
    private let roomProxy: RoomProxyProtocol
    private let mediaProvider: MediaProviderProtocol
    private let eventBriefFactory: EventBriefFactoryProtocol
    
    private var hasLoadedData = false
    private var roomUpdateListeners = Set<AnyCancellable>()
    
    var id: String {
        roomProxy.id
    }
    
    var name: String? {
        roomProxy.name
    }
    
    var topic: String? {
        roomProxy.topic
    }
    
    var isDirect: Bool {
        roomProxy.isDirect
    }
    
    var isEncrypted: Bool {
        roomProxy.isEncrypted
    }
    
    var isSpace: Bool {
        roomProxy.isSpace
    }
    
    var isTombstoned: Bool {
        roomProxy.isTombstoned
    }
    
    private(set) var avatar: UIImage? {
        didSet {
            callbacks.send(.updatedAvatar)
        }
    }
    
    private(set) var displayName: String? {
        didSet {
            callbacks.send(.updatedDisplayName)
        }
    }
    
    private(set) var lastMessage: EventBrief? {
        didSet {
            callbacks.send(.updatedLastMessage)
        }
    }
    
    let callbacks = PassthroughSubject<RoomSummaryCallback, Never>()
    
    init(roomProxy: RoomProxyProtocol, mediaProvider: MediaProviderProtocol, eventBriefFactory: EventBriefFactoryProtocol) {
        self.roomProxy = roomProxy
        self.mediaProvider = mediaProvider
        self.eventBriefFactory = eventBriefFactory
        
        Task {
            lastMessage = await self.lastRoomMessageBrief()
        }
    }
    
    func loadDetails() async {
        if hasLoadedData {
            return
        }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadDisplayName()
            }
            group.addTask {
                await self.loadAvatar()
            }
            group.addTask {
                await self.loadLastMessage()
            }
        }
        
        hasLoadedData = true
    }
    
    // MARK: - Private
    
    private func loadDisplayName() async {
        switch await roomProxy.loadDisplayName() {
        case .success(let displayName):
            self.displayName = displayName
        case .failure(let error):
            MXLog.error("Failed fetching room display name with error: \(error)")
        }
    }
    
    private func loadAvatar() async {
        guard let avatarURLString = roomProxy.avatarURL else {
            return
        }
        
        switch await mediaProvider.loadImageFromURLString(avatarURLString) {
        case .success(let avatar):
            self.avatar = avatar
        case .failure(let error):
            MXLog.error("Failed fetching room avatar with error: \(error)")
        }
    }
    
    private func loadLastMessage() async {
        #warning("No op whilst waiting for sliding sync.")
    }
    
    private func lastRoomMessageBrief() async -> EventBrief? {
        return nil
    }
}

//
//  RoomSummary.swift
//  ElementX
//
//  Created by Stefan Ceriu on 01/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import UIKit
import Combine

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
    
    private(set) var displayName: String? {
        didSet {
            callbacks.send(.updatedData)
        }
    }
    
    private(set) var lastMessage: EventBrief? {
        didSet {
            callbacks.send(.updatedData)
        }
    }
    
    private(set) var avatar: UIImage? {
        didSet {
            callbacks.send(.updatedData)
        }
    }
    
    let callbacks = PassthroughSubject<RoomSummaryCallback, Never>()
    
    init(roomProxy: RoomProxyProtocol, mediaProvider: MediaProviderProtocol, eventBriefFactory: EventBriefFactoryProtocol) {
        self.roomProxy = roomProxy
        self.mediaProvider = mediaProvider
        self.eventBriefFactory = eventBriefFactory
        
        Task {
            lastMessage = await eventBriefFactory.buildEventBriefFor(message: roomProxy.messages.last)
        }
        
        roomProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self = self else {
                    return
                }
                
                switch callback {
                case .updatedMessages:
                    Task {
                        self.lastMessage = await eventBriefFactory.buildEventBriefFor(message: roomProxy.messages.last)
                    }
                }
            }
            .store(in: &roomUpdateListeners)
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
        guard roomProxy.messages.last == nil else {
            return
        }
        
        switch await roomProxy.paginateBackwards(count: 1) {
        case .success:
            lastMessage = await eventBriefFactory.buildEventBriefFor(message: roomProxy.messages.last)
        case .failure(let error):
            MXLog.error("Failed back paginating with error: \(error)")
        }
    }
}

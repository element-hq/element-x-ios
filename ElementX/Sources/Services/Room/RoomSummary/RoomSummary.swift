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
            self.callbacks.send(.updatedData)
        }
    }
    
    private(set) var lastMessage: EventBrief? {
        didSet {
            self.callbacks.send(.updatedData)
        }
    }
    
    private(set) var avatar: UIImage? {
        didSet {
            self.callbacks.send(.updatedData)
        }
    }
    
    let callbacks = PassthroughSubject<RoomSummaryCallback, Never>()
    
    init(roomProxy: RoomProxyProtocol, mediaProvider: MediaProviderProtocol, eventBriefFactory: EventBriefFactoryProtocol) {
        self.roomProxy = roomProxy
        self.mediaProvider = mediaProvider
        self.eventBriefFactory = eventBriefFactory
        
        eventBriefFactory.eventBriefForMessage(roomProxy.messages.last) { [weak self] result in
            self?.lastMessage = result
        }
        
        roomProxy.callbacks.sink { [weak self] callback in
            guard let self = self else {
                return
            }
            
            switch callback {
            case .updatedMessages:
                self.eventBriefFactory.eventBriefForMessage(self.roomProxy.messages.last) { [weak self] result in
                    self?.lastMessage = result
                }
            }
        }
        .store(in: &roomUpdateListeners)
    }
    
    func loadData() {
        if hasLoadedData {
            return
        }
        
        loadDisplayName()
        loadLastMessage()
        loadAvatar()
        
        hasLoadedData = true
    }
    
    // MARK: - Private
    
    private func loadDisplayName() {
        roomProxy.displayName { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let displayName):
                self.displayName = displayName
            case .failure(let error):
                MXLog.error("Failed fetching room display name with error: \(error)")
            }
        }
    }
    
    private func loadLastMessage() {
        if roomProxy.messages.last == nil {
            roomProxy.paginateBackwards(count: 1) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.eventBriefFactory.eventBriefForMessage(self.roomProxy.messages.last) { [weak self] result in
                        self?.lastMessage = result
                    }
                case .failure(let error):
                    MXLog.error("Failed back paginating with error: \(error)")
                }
            }
        }
    }
    
    private func loadAvatar() {
        if let avatarURL = roomProxy.avatarURL {
            mediaProvider.loadImageFromURL(avatarURL) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let image):
                    self.avatar = image
                case .failure(let error):
                    MXLog.error("Failed fetching room avatar with error: \(error)")
                }
            }
        }
    }
}
